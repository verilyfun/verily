import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:pointycastle/export.dart';
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_verifier.dart';
import 'package:verily_server/src/action_verification/key_attestation/der.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Neither configuration failures nor Apple outages are clean device signals.
final class AppleDeviceUnavailable implements Exception {
  const AppleDeviceUnavailable();
}

/// Apple's two durable flags. Bit 0 is an active abuse ban; bit 1 requires
/// review following suspected abuse. Only scoped operators may change them.
final class AppleDeviceBits {
  const AppleDeviceBits({required this.banned, required this.reviewRequired});
  final bool banned;
  final bool reviewRequired;
}

/// Server-owned Apple APIs; tests inject a fake rather than calling Apple.
abstract interface class AppleDeviceClient {
  Future<String> refreshReceipt(Session session, String receipt);
  Future<AppleDeviceBits> queryBits(Session session, String deviceToken);
  Future<void> updateBits(
    Session session,
    String deviceToken,
    AppleDeviceBits bits,
  );
}

/// App Attest and DeviceCheck share an ES256 DeviceCheck key, resolved once by
/// Monosecret at bootstrap. No request can supply credentials or a destination.
class HttpAppleDeviceClient implements AppleDeviceClient {
  HttpAppleDeviceClient({
    required this.policy,
    required this.keyId,
    this.client,
    String? Function(Session)? privateKeyReader,
    DateTime Function()? clock,
  }) : privateKeyReader = privateKeyReader ?? _readPrivateKey,
       clock = clock ?? (() => DateTime.now().toUtc());

  factory HttpAppleDeviceClient.fromEnvironment(AppAttestPolicy policy) =>
      HttpAppleDeviceClient(
        policy: policy,
        keyId: Platform.environment['VERILY_DEVICE_CHECK_KEY_ID'] ?? '',
      );

  final AppAttestPolicy policy;
  final String keyId;
  final http.Client? client;
  final DateTime Function() clock;
  final String? Function(Session) privateKeyReader;

  bool get _development =>
      policy.environment == AppAttestEnvironment.development;

  @override
  Future<String> refreshReceipt(Session session, String receipt) async {
    final response = await _post(
      session,
      host: _development
          ? 'data-development.appattest.apple.com'
          : 'data.appattest.apple.com',
      path: '/v1/attestationData',
      body: receipt,
      bearer: false,
    );
    if (response.isEmpty || response.length > 48 * 1024) {
      throw const AppleDeviceUnavailable();
    }
    return response.trim();
  }

  @override
  Future<AppleDeviceBits> queryBits(Session session, String deviceToken) async {
    final response = await _deviceCheck(session, 'query_two_bits', deviceToken);
    // Apple returns this exact 200 body when no bits have ever been set.
    if (response.trim() == 'Bit State Not Found') {
      return const AppleDeviceBits(banned: false, reviewRequired: false);
    }
    try {
      final json = jsonDecode(response);
      if (json case {'bit0': final bool banned, 'bit1': final bool review}) {
        return AppleDeviceBits(banned: banned, reviewRequired: review);
      }
      throw const AppleDeviceUnavailable();
    } on FormatException {
      throw const AppleDeviceUnavailable();
    }
  }

  @override
  Future<void> updateBits(
    Session session,
    String deviceToken,
    AppleDeviceBits bits,
  ) async {
    await _deviceCheck(session, 'update_two_bits', deviceToken, bits: bits);
  }

  Future<String> _deviceCheck(
    Session session,
    String operation,
    String token, {
    AppleDeviceBits? bits,
  }) {
    if (!validDeviceCheckToken(token)) throw const AppleDeviceUnavailable();
    return _post(
      session,
      host: _development
          ? 'api.development.devicecheck.apple.com'
          : 'api.devicecheck.apple.com',
      path: '/v1/$operation',
      bearer: true,
      body: jsonEncode({
        'device_token': token,
        'transaction_id': const Uuid().v4(),
        'timestamp': clock().millisecondsSinceEpoch,
        if (bits != null) ...{'bit0': bits.banned, 'bit1': bits.reviewRequired},
      }),
    );
  }

  Future<String> _post(
    Session session, {
    required String host,
    required String path,
    required String body,
    required bool bearer,
  }) async {
    final pem = privateKeyReader(session);
    if (pem == null || !RegExp(r'^[A-Z0-9]{10}$').hasMatch(keyId)) {
      throw const AppleDeviceUnavailable();
    }
    final token = deviceCheckJwt(
      pem: pem,
      keyId: keyId,
      teamId: policy.teamId,
      now: clock(),
    );
    final transport = client ?? IOClient(HttpClient()..userAgent = 'Verily');
    try {
      final request = http.Request('POST', Uri.https(host, path))
        ..followRedirects = false
        ..headers.addAll({
          'authorization': bearer ? 'Bearer $token' : token,
          'content-type': bearer
              ? 'application/json'
              : 'application/octet-stream',
        })
        ..body = body;
      return await (() async {
        final response = await transport.send(request);
        if (response.statusCode != 200) throw const AppleDeviceUnavailable();
        final bytes = <int>[];
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > 48 * 1024) {
            throw const AppleDeviceUnavailable();
          }
          bytes.addAll(chunk);
        }
        return utf8.decode(bytes);
      })().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const AppleDeviceUnavailable();
    } on http.ClientException {
      throw const AppleDeviceUnavailable();
    } on IOException {
      throw const AppleDeviceUnavailable();
    } on FormatException {
      throw const AppleDeviceUnavailable();
    } finally {
      if (client == null) transport.close();
    }
  }
}

String? _readPrivateKey(Session session) =>
    session.server.serverpod.getPassword('deviceCheckPrivateKey');

/// Bounded single-line base64. Tokens are ephemeral, never logged or persisted.
bool validDeviceCheckToken(String token) {
  if (token.isEmpty ||
      token.length > 8192 ||
      !RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(token)) {
    return false;
  }
  try {
    return base64Decode(token).isNotEmpty;
  } on FormatException {
    return false;
  }
}

/// APNs-style ES256 JWT using Apple's PKCS#8 P-256 .p8 key. The signature is
/// JOSE's fixed-width r || s, not an ASN.1 signature. Key bytes stay server-side.
String deviceCheckJwt({
  required String pem,
  required String keyId,
  required String teamId,
  required DateTime now,
}) {
  try {
    final encoded = pem
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s+'), '');
    final pkcs8 = parseDer(base64Decode(encoded)).sequence;
    if (pkcs8.length != 3 || pkcs8[0].smallInteger != 0) {
      throw const AppleDeviceUnavailable();
    }
    final algorithm = pkcs8[1].sequence;
    if (algorithm.length != 2 ||
        algorithm[0].objectIdentifier != X509Oid.ecPublicKey ||
        algorithm[1].objectIdentifier != X509Oid.secp256r1) {
      throw const AppleDeviceUnavailable();
    }
    final sec1 = parseDer(pkcs8[2].octets).sequence;
    if (sec1.length < 2 ||
        sec1[0].smallInteger != 1 ||
        sec1[1].octets.length != 32) {
      throw const AppleDeviceUnavailable();
    }
    final curve = ECCurve_secp256r1();
    final scalar = unsignedBigInt(sec1[1].octets);
    if (scalar <= BigInt.zero || scalar >= curve.n) {
      throw const AppleDeviceUnavailable();
    }
    String encode(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final message =
        '${encode({'alg': 'ES256', 'kid': keyId, 'typ': 'JWT'})}.${encode({'iss': teamId, 'iat': now.millisecondsSinceEpoch ~/ 1000})}';
    final signer = Signer('SHA-256/DET-ECDSA')
      ..init(
        true,
        PrivateKeyParameter<ECPrivateKey>(ECPrivateKey(scalar, curve)),
      );
    final signature = signer.generateSignature(
      Uint8List.fromList(ascii.encode(message)),
    ) as ECSignature;
    List<int> fixed(BigInt value) {
      final hex = value.toRadixString(16).padLeft(64, '0');
      return [
        for (var i = 0; i < 64; i += 2)
          int.parse(hex.substring(i, i + 2), radix: 16),
      ];
    }

    return '$message.${base64Url.encode([...fixed(signature.r), ...fixed(signature.s)]).replaceAll('=', '')}';
  } on FormatException {
    throw const AppleDeviceUnavailable();
  }
}
