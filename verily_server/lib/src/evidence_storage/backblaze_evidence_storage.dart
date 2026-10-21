import 'dart:async';
import 'dart:typed_data';

import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_cloud_storage_s3_compat/serverpod_cloud_storage_s3_compat.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';

typedef PasswordReader = String? Function(String alias);

/// The five Backblaze values the evidence bucket needs, read from Serverpod
/// password aliases that Monosecret injected.
class BackblazeEvidenceStorageConfiguration {
  const BackblazeEvidenceStorageConfiguration({
    required this.endpoint,
    required this.region,
    required this.bucket,
    required this.keyId,
    required this.applicationKey,
  });

  factory BackblazeEvidenceStorageConfiguration.fromPasswords(
    PasswordReader readPassword,
  ) {
    final endpoint = _requiredPassword(readPassword, 'evidenceB2S3Endpoint');
    final endpointUri = Uri.tryParse(endpoint);
    if (endpointUri == null ||
        endpointUri.scheme != 'https' ||
        !endpointUri.host.endsWith('.backblazeb2.com') ||
        endpointUri.path != '') {
      throw StateError(
        'VERILY_EVIDENCE_B2_S3_ENDPOINT must be a Backblaze HTTPS origin.',
      );
    }

    final bucket = _requiredPassword(readPassword, 'evidenceB2BucketName');
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{4,61}[a-z0-9]$').hasMatch(bucket)) {
      throw StateError('VERILY_EVIDENCE_B2_BUCKET_NAME is invalid.');
    }

    return BackblazeEvidenceStorageConfiguration(
      endpoint: endpointUri,
      region: _requiredPassword(readPassword, 'evidenceB2Region'),
      bucket: bucket,
      keyId: _requiredPassword(readPassword, 'evidenceB2KeyId'),
      applicationKey: _requiredPassword(
        readPassword,
        'evidenceB2ApplicationKey',
      ),
    );
  }

  /// Password aliases that together configure Backblaze evidence storage.
  static const passwordAliases = [
    'evidenceB2S3Endpoint',
    'evidenceB2Region',
    'evidenceB2BucketName',
    'evidenceB2KeyId',
    'evidenceB2ApplicationKey',
  ];

  final Uri endpoint;
  final String region;
  final String bucket;
  final String keyId;
  final String applicationKey;

  BackblazeEvidenceStorage createStorage() {
    return BackblazeEvidenceStorage(
      endpoint: endpoint,
      region: region,
      bucket: bucket,
      keyId: keyId,
      applicationKey: applicationKey,
    );
  }
}

/// Private S3-compatible storage for short-lived verification media.
///
/// Upload bytes go directly from the client to Backblaze. Confirmation streams
/// the object through SHA-256 without buffering the full object in memory.
/// Backblaze versions every PUT and does not implement `If-None-Match`, so
/// every reader is pinned to the exact `x-amz-version-id` that was hashed.
class BackblazeEvidenceStorage extends S3CompatCloudStorage
    implements EvidenceObjectAccess {
  factory BackblazeEvidenceStorage({
    required Uri endpoint,
    required String region,
    required String bucket,
    required String keyId,
    required String applicationKey,
    http.Client? httpClient,
  }) {
    final endpoints = CustomEndpointConfig(
      baseUri: endpoint,
      serviceName: 'Backblaze B2',
    );
    return BackblazeEvidenceStorage._(
      region: region,
      bucket: bucket,
      keyId: keyId,
      applicationKey: applicationKey,
      endpoints: endpoints,
      inspectorClient: S3Client(
        accessKey: keyId,
        secretKey: applicationKey,
        bucket: bucket,
        region: region,
        endpoints: endpoints,
      ),
      reviewUrlSigner: _S3ReviewUrlSigner(
        accessKey: keyId,
        secretKey: applicationKey,
        bucket: bucket,
        region: region,
        endpoints: endpoints,
      ),
      httpClient: httpClient ?? http.Client(),
    );
  }

  // Explicit names keep the Backblaze credential mapping visible here.
  // ignore: use_super_parameters
  BackblazeEvidenceStorage._({
    required String region,
    required String bucket,
    required String keyId,
    required String applicationKey,
    required CustomEndpointConfig endpoints,
    required this._inspectorClient,
    required this._reviewUrlSigner,
    required this._httpClient,
  }) : super(
         storageId: evidenceStorageId,
         accessKey: keyId,
         secretKey: applicationKey,
         bucket: bucket,
         region: region,
         public: false,
         endpoints: endpoints,
         uploadStrategy: PresignedPutUploadStrategy(),
       );

  final S3Client _inspectorClient;
  final _S3ReviewUrlSigner _reviewUrlSigner;
  final http.Client _httpClient;

  @override
  Future<EvidenceObjectInspection?> inspectAndHash(
    Session session,
    String path,
  ) async {
    validateEvidencePath(path);

    final signed = _inspectorClient.buildSignedParams(key: path);
    final request = http.Request('GET', signed.uri)
      ..headers.addAll(signed.headers);
    final response = await _httpClient.send(request);
    if (response.statusCode == 404) {
      await response.stream.drain<void>();
      return null;
    }
    if (response.statusCode != 200) {
      await response.stream.drain<void>();
      throw CloudStorageException(
        'Backblaze rejected evidence integrity inspection '
        '(HTTP ${response.statusCode}).',
      );
    }
    final expectedLength = int.tryParse(
      response.headers['content-length'] ?? '',
    );
    final versionId = response.headers['x-amz-version-id']?.trim() ?? '';
    if (expectedLength == null || expectedLength < 0 || versionId.isEmpty) {
      await response.stream.drain<void>();
      throw CloudStorageException(
        'Backblaze evidence metadata was incomplete.',
      );
    }

    final digestSink = _DigestSink();
    final digestInput = sha256.startChunkedConversion(digestSink);
    final signatureBytes = BytesBuilder(copy: false);
    var streamedLength = 0;
    await for (final chunk in response.stream) {
      streamedLength += chunk.length;
      if (streamedLength > expectedLength) {
        digestInput.close();
        throw CloudStorageException(
          'Backblaze returned more evidence bytes than declared.',
        );
      }
      digestInput.add(chunk);
      if (signatureBytes.length < mediaSignatureLimit) {
        final remaining = mediaSignatureLimit - signatureBytes.length;
        signatureBytes.add(
          chunk.length <= remaining ? chunk : chunk.sublist(0, remaining),
        );
      }
    }
    digestInput.close();
    if (streamedLength != expectedLength || digestSink.value == null) {
      throw CloudStorageException(
        'Backblaze evidence size changed during integrity inspection.',
      );
    }

    return EvidenceObjectInspection(
      byteLength: streamedLength,
      contentType: response.headers['content-type'],
      compatibleContentTypes: compatibleEvidenceContentTypes(
        signatureBytes.takeBytes(),
      ),
      versionId: versionId,
      sha256Digest: digestSink.value.toString(),
    );
  }

  @override
  Future<Uri> createReviewUrl(
    Session session,
    String path, {
    required String versionId,
    Duration expiration = const Duration(minutes: 5),
  }) async {
    validateEvidencePath(path);
    _validateVersionId(versionId);
    validateReviewExpiration(expiration);
    return _reviewUrlSigner.create(
      path: path,
      versionId: versionId,
      expiration: expiration,
    );
  }

  @override
  void close() {
    _inspectorClient.close();
    _httpClient.close();
    super.close();
  }
}

/// Signs a GET for one path and version. The version is part of the signed
/// canonical query, so the link can never be redirected to newer bytes.
class _S3ReviewUrlSigner {
  const _S3ReviewUrlSigner({
    required this.accessKey,
    required this.secretKey,
    required this.bucket,
    required this.region,
    required this.endpoints,
  });

  final String accessKey;
  final String secretKey;
  final String bucket;
  final String region;
  final S3EndpointConfig endpoints;

  Uri create({
    required String path,
    required String versionId,
    required Duration expiration,
  }) {
    final bucketUri = endpoints.buildBucketUri(bucket, region);
    final objectPath = bucketUri.path.endsWith('/')
        ? '${bucketUri.path}$path'
        : '${bucketUri.path}/$path';
    final datetime = SigV4.generateDatetime();
    final credentialScope = SigV4.buildCredentialScope(datetime, region, 's3');
    final host =
        bucketUri.hasPort &&
            !((bucketUri.scheme == 'https' && bucketUri.port == 443) ||
                (bucketUri.scheme == 'http' && bucketUri.port == 80))
        ? '${bucketUri.host}:${bucketUri.port}'
        : bucketUri.host;
    final query = <String, String>{
      'versionId': versionId,
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': '$accessKey/$credentialScope',
      'X-Amz-Date': datetime,
      'X-Amz-Expires': expiration.inSeconds.toString(),
      'X-Amz-SignedHeaders': 'host',
    };
    final canonicalPath = objectPath
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    final canonicalRequest =
        '''
GET
$canonicalPath
${SigV4.buildCanonicalQueryString(query)}
host:$host

host
UNSIGNED-PAYLOAD''';
    final stringToSign = SigV4.buildStringToSign(
      datetime,
      credentialScope,
      SigV4.hashCanonicalRequest(canonicalRequest),
    );
    final signingKey = SigV4.calculateSigningKey(
      secretKey,
      datetime,
      region,
      's3',
    );
    query['X-Amz-Signature'] = SigV4.calculateSignature(
      signingKey,
      stringToSign,
    );
    return Uri(
      scheme: bucketUri.scheme,
      host: bucketUri.host,
      port: bucketUri.port,
      path: objectPath,
      queryParameters: query,
    );
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    if (value != null) {
      throw StateError('SHA-256 emitted more than one digest.');
    }
    value = data;
  }

  @override
  void close() {}
}

String _requiredPassword(PasswordReader readPassword, String alias) {
  final value = readPassword(alias)?.trim() ?? '';
  if (value.isEmpty) {
    throw StateError('Missing Serverpod password alias: $alias.');
  }
  return value;
}

void _validateVersionId(String versionId) {
  final normalized = versionId.trim();
  if (normalized.isEmpty ||
      normalized.length > 1024 ||
      normalized.contains(RegExp(r'[\u0000-\u001f\u007f]'))) {
    throw ArgumentError.value(
      versionId,
      'versionId',
      'Invalid evidence object version.',
    );
  }
}
