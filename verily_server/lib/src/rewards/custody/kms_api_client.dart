import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'package:http/http.dart' as http;
import 'package:verily_server/src/rewards/custody/kms_ed25519_public_key.dart';

const cloudKmsScope = 'https://www.googleapis.com/auth/cloudkms';
const cloudKmsApiRoot = 'https://cloudkms.googleapis.com/v1/';
const kmsEd25519Algorithm = 'EC_SIGN_ED25519';

/// Where the Cloud KMS service-account key comes from.
///
/// Exactly one source is configured. A file suits hosts that can mount an
/// owner-only secret file; inline JSON suits platforms that deliver secrets
/// only as environment variables. Both are parsed and validated identically.
sealed class KmsCredentialsSource {
  const KmsCredentialsSource();
}

/// An owner-only (`0600`) service-account JSON file.
final class KmsCredentialsFile extends KmsCredentialsSource {
  const KmsCredentialsFile(this.path);

  final String path;

  @override
  String toString() => 'KmsCredentialsFile($path)';
}

/// Service-account JSON delivered inline through the environment.
///
/// The value is a credential: it is never logged, and [toString] redacts it.
final class KmsCredentialsJson extends KmsCredentialsSource {
  const KmsCredentialsJson(this.json);

  final String json;

  @override
  String toString() => 'KmsCredentialsJson(<redacted>)';
}

/// A Cloud KMS Ed25519 signing key as observed from the KMS API.
final class KmsEd25519KeyView {
  const KmsEd25519KeyView({
    required this.keyVersionName,
    required this.algorithm,
    required this.protectionLevel,
    required this.publicKeyBytes,
  });

  final String keyVersionName;
  final String algorithm;
  final String protectionLevel;
  final Uint8List publicKeyBytes;
}

/// Remote Cloud KMS signing boundary.
///
/// Private key material never crosses this interface in either direction:
/// keys live inside Cloud KMS and only public metadata, raw signing requests,
/// and raw signatures pass through. Production uses [GoogleCloudKmsClient];
/// tests inject a fake.
abstract interface class KmsApiClient {
  Future<KmsEd25519KeyView> readEd25519Key(String keyVersionName);
  Future<Uint8List> sign(String keyVersionName, Uint8List messageBytes);
  void close();
}

/// Google Cloud KMS REST client authenticated with a service account.
final class GoogleCloudKmsClient implements KmsApiClient {
  /// The `client` must already carry Cloud KMS scope authentication (see
  /// [fromCredentials]); requests send no credentials of their own.
  GoogleCloudKmsClient(this._client);

  final http.Client _client;

  /// Creates a client from the configured credential source.
  static Future<GoogleCloudKmsClient> fromCredentials(
    KmsCredentialsSource source, {
    http.Client? baseClient,
  }) => switch (source) {
    KmsCredentialsFile(:final path) => fromCredentialsFile(
      path,
      baseClient: baseClient,
    ),
    KmsCredentialsJson(:final json) => fromCredentialsJson(
      json,
      baseClient: baseClient,
    ),
  };

  /// Creates a client from a service-account JSON credentials file.
  ///
  /// The file must already exist and be owner-only (`0600`): it grants the
  /// power to sign with every key the service account may use.
  static Future<GoogleCloudKmsClient> fromCredentialsFile(
    String credentialsPath, {
    http.Client? baseClient,
  }) async {
    final file = File(credentialsPath);
    final stat = file.statSync();
    if (stat.type != FileSystemEntityType.file) {
      throw StateError('The Cloud KMS credentials path is not a file.');
    }
    // 0x3F is 0o077: any group or other permission bit must be clear.
    if ((stat.mode & 0x3F) != 0) {
      throw StateError(
        'Cloud KMS credentials must be readable only by their owner (0600).',
      );
    }
    final String contents;
    try {
      contents = file.readAsStringSync();
    } on FileSystemException {
      throw StateError('The Cloud KMS credentials file could not be read.');
    }
    return fromCredentialsJson(contents, baseClient: baseClient);
  }

  /// Creates a client from service-account JSON held in memory.
  ///
  /// Applies the same validation as [fromCredentialsFile]. Error messages
  /// never include the JSON, and the decoded key is not retained beyond the
  /// authenticated client.
  static Future<GoogleCloudKmsClient> fromCredentialsJson(
    String credentialsJson, {
    http.Client? baseClient,
  }) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(credentialsJson);
    } on FormatException {
      throw StateError('The Cloud KMS credentials are not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw StateError('The Cloud KMS credentials are not a JSON object.');
    }
    final gauth.ServiceAccountCredentials credentials;
    try {
      credentials = gauth.ServiceAccountCredentials.fromJson(decoded);
    } on Object {
      throw StateError(
        'The Cloud KMS credentials are not a service-account key.',
      );
    }
    final client = await gauth.clientViaServiceAccount(
      credentials,
      const [cloudKmsScope],
      baseClient: baseClient,
    );
    return GoogleCloudKmsClient(client);
  }

  @override
  Future<KmsEd25519KeyView> readEd25519Key(String keyVersionName) async {
    final body = await _respond(
      await _client.get(
        Uri.parse('$cloudKmsApiRoot$keyVersionName:getPublicKey'),
      ),
      'public key request',
    );
    final pem = _requiredString(body, 'pem');
    final algorithm = _requiredString(body, 'algorithm');
    if (algorithm != kmsEd25519Algorithm) {
      throw StateError('The Cloud KMS key is not an Ed25519 signing key.');
    }
    final Uint8List publicKeyBytes;
    try {
      publicKeyBytes = parseEd25519PublicKeyPem(pem);
    } on FormatException {
      throw StateError('Cloud KMS returned a malformed public key.');
    }
    return KmsEd25519KeyView(
      keyVersionName: keyVersionName,
      algorithm: algorithm,
      protectionLevel: _optionalString(body, 'protectionLevel') ?? 'UNKNOWN',
      publicKeyBytes: publicKeyBytes,
    );
  }

  @override
  Future<Uint8List> sign(String keyVersionName, Uint8List messageBytes) async {
    final body = await _respond(
      await _client.post(
        Uri.parse('$cloudKmsApiRoot$keyVersionName:asymmetricSign'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({'data': base64Encode(messageBytes)}),
      ),
      'signing request',
    );
    try {
      return base64Decode(_requiredString(body, 'signature'));
    } on FormatException {
      throw StateError('Cloud KMS returned an unparsable signature.');
    }
  }

  @override
  void close() => _client.close();

  Future<Map<String, dynamic>> _respond(
    http.Response response,
    String operation,
  ) async {
    if (response.statusCode != 200) {
      // Never surface the response body: it may echo request or account
      // identifiers, and provider failures are not product diagnostics.
      throw StateError('Cloud KMS rejected the $operation.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw StateError('Cloud KMS returned an unexpected $operation response.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Cloud KMS returned an unexpected $operation response.');
    }
    return decoded;
  }
}

String _requiredString(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value is! String || value.isEmpty) {
    throw StateError('Cloud KMS response is missing a valid `$key` field.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value is! String || value.isEmpty) return null;
  return value;
}
