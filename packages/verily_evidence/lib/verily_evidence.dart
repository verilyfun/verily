/// Canonical, privacy-preserving fingerprints for Verily action evidence,
/// and the pinned local-check models and labels both sides run.
///
/// The app and Serverpod compute these values independently. The server never
/// trusts a client-computed fingerprint; it recomputes each one from the
/// evidence it actually accepted and compares.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

export 'src/local_check_catalog.dart';
export 'src/motion_evidence.dart';

final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
final RegExp _requestHashPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');
final RegExp _captureChallengePattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// Domain separators. Changing one invalidates every outstanding challenge, so
/// a change is a protocol version bump on both the app and the server.
const _requestHashDomain = 'verily-capture-request-v2';
const _manifestDomain = 'verily-capture-manifest-v1';
const _bindingDomain = 'verily-evidence-binding-v1';

/// The captured media families Verily accepts through private uploads.
enum MediaEvidenceKind { video, photo, audio }

/// Streams [chunks] through SHA-256 without buffering an entire recording.
Future<String> sha256Stream(Stream<List<int>> chunks) async {
  return (await sha256.bind(chunks).single).toString();
}

/// Creates the Play Integrity request hash for one capture.
///
/// [captureChallenge] is the nonce the server issued before capture began and
/// [evidenceBindingHash] fingerprints what was captured, so a token can only
/// vouch for this capture. The app computes it to request the token; the
/// server recomputes it from the challenge it stored and the evidence it
/// accepted.
String captureIntegrityRequestHash({
  required String attemptId,
  required String requirementId,
  required String captureChallenge,
  required String evidenceBindingHash,
}) {
  final normalizedBindingHash = normalizeEvidenceBindingHash(
    evidenceBindingHash,
  );
  final normalizedChallenge = normalizeCaptureChallenge(captureChallenge);
  final normalizedAttemptId = _canonicalIdentifier(attemptId, 'attemptId');
  final normalizedRequirementId = _canonicalIdentifier(
    requirementId,
    'requirementId',
  );
  return base64Url
      .encode(
        sha256
            .convert(
              utf8.encode(
                [
                  _requestHashDomain,
                  normalizedAttemptId,
                  normalizedRequirementId,
                  normalizedBindingHash,
                  normalizedChallenge,
                ].join('|'),
              ),
            )
            .bytes,
      )
      .replaceAll('=', '');
}

/// The Android Key Attestation challenge for one capture key:
/// `SHA-256(captureChallenge ‖ attemptId)`, where `captureChallenge` is the
/// nonce's 32 raw bytes and `attemptId` its UTF-8 text.
///
/// The app generates a fresh key with this challenge before recording starts,
/// so the key's certificate chain proves it was created after the server
/// issued [captureChallenge] for this attempt.
List<int> captureKeyAttestationChallenge({
  required String captureChallenge,
  required String attemptId,
}) {
  final nonce = base64Url.decode(
    base64Url.normalize(normalizeCaptureChallenge(captureChallenge)),
  );
  return sha256.convert([
    ...nonce,
    ...utf8.encode(_canonicalIdentifier(attemptId, 'attemptId')),
  ]).bytes;
}

/// The `clientDataHash` an iPhone passes to App Attest's `attestKey` when it
/// registers its key: SHA-256 of the registration challenge's 32 raw bytes.
///
/// The server issues [registrationChallenge] before the phone asks Apple to
/// attest the key, so the attestation proves it was made for this request.
List<int> appAttestRegistrationClientDataHash(String registrationChallenge) {
  return sha256
      .convert(
        base64Url.decode(
          base64Url.normalize(normalizeCaptureChallenge(registrationChallenge)),
        ),
      )
      .bytes;
}

/// The `clientDataHash` an iPhone passes to App Attest's `generateAssertion`
/// for one capture: SHA-256 of the canonical [manifest] bytes from
/// [captureProvenanceManifest].
///
/// The manifest commits to the capture window and the evidence fingerprint,
/// so an assertion over it can vouch for this capture only.
List<int> appAttestAssertionClientDataHash(List<int> manifest) {
  if (manifest.isEmpty) {
    throw ArgumentError.value(manifest, 'manifest', 'Must not be empty.');
  }
  return sha256.convert(manifest).bytes;
}

/// Binds the ephemeral DeviceCheck token to this manifest's App Attest
/// assertion. Length-prefixing avoids ambiguity; only the token hash is signed.
/// This prevents token substitution, but Apple exposes no cryptographic link
/// proving a DeviceCheck token and App Attest key came from the same phone.
List<int> appAttestDeviceClientData(
  List<int> manifest,
  String deviceCheckToken,
) => [
  ...utf8.encode('verily-apple-device-v1|${manifest.length}|'),
  ...manifest,
  ...sha256.convert(utf8.encode(deviceCheckToken)).bytes,
];

/// Validates a server capture challenge: 32 random bytes, unpadded base64url.
String normalizeCaptureChallenge(String value) {
  final normalized = value.trim();
  // 43 unpadded base64url characters always decode to exactly 32 bytes.
  if (!_captureChallengePattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'captureChallenge',
      'Must be 32 bytes as unpadded base64url.',
    );
  }
  return normalized;
}

/// Creates the canonical bytes signed by an app-controlled capture key.
///
/// The manifest binds one device signature to the server-issued challenge and
/// the exact evidence fingerprint. It intentionally contains no media, QR
/// payload, or location coordinates.
List<int> captureProvenanceManifest({
  required String attemptId,
  required String requirementId,
  required String requestHash,
  required String evidenceBindingHash,
}) {
  final normalizedRequestHash = requestHash.trim();
  if (!_requestHashPattern.hasMatch(normalizedRequestHash)) {
    throw ArgumentError.value(
      requestHash,
      'requestHash',
      'Must be an unpadded base64url SHA-256 digest.',
    );
  }
  final normalizedAttemptId = _canonicalIdentifier(attemptId, 'attemptId');
  final normalizedRequirementId = _canonicalIdentifier(
    requirementId,
    'requirementId',
  );
  final normalizedBindingHash = normalizeEvidenceBindingHash(
    evidenceBindingHash,
  );

  return utf8.encode(
    [
      _manifestDomain,
      'attemptId=$normalizedAttemptId',
      'requirementId=$normalizedRequirementId',
      'requestHash=$normalizedRequestHash',
      'evidenceBindingHash=$normalizedBindingHash',
    ].join('\n'),
  );
}

/// Returns the stable identifier for an encoded capture public key.
String capturePublicKeyId(List<int> publicKeyBytes) {
  if (publicKeyBytes.isEmpty) {
    throw ArgumentError.value(
      publicKeyBytes,
      'publicKeyBytes',
      'Must not be empty.',
    );
  }
  return sha256.convert(publicKeyBytes).toString();
}

/// Binds a capture challenge to one normalized location observation.
String locationEvidenceBindingHash({
  required DateTime capturedAt,
  required double latitude,
  required double longitude,
  required double accuracyMeters,
}) {
  if (!latitude.isFinite || latitude < -90 || latitude > 90) {
    throw ArgumentError.value(
      latitude,
      'latitude',
      'Must be between -90 and 90.',
    );
  }
  if (!longitude.isFinite || longitude < -180 || longitude > 180) {
    throw ArgumentError.value(
      longitude,
      'longitude',
      'Must be between -180 and 180.',
    );
  }
  if (!accuracyMeters.isFinite || accuracyMeters < 0) {
    throw ArgumentError.value(
      accuracyMeters,
      'accuracyMeters',
      'Must be a finite, non-negative number.',
    );
  }

  return _canonicalHash([
    _bindingDomain,
    'kind=location',
    'capturedAtMs=${capturedAt.toUtc().millisecondsSinceEpoch}',
    'latitude=${latitude.toStringAsFixed(7)}',
    'longitude=${longitude.toStringAsFixed(7)}',
    'accuracyMm=${(accuracyMeters * 1000).round()}',
  ]);
}

/// Binds a capture challenge to one QR payload without exposing the payload.
String qrEvidenceBindingHash({
  required DateTime capturedAt,
  required String code,
}) {
  final normalizedCode = code.trim();
  if (normalizedCode.isEmpty) {
    throw ArgumentError.value(code, 'code', 'Must not be empty.');
  }

  return _canonicalHash([
    _bindingDomain,
    'kind=qrCode',
    'capturedAtMs=${capturedAt.toUtc().millisecondsSinceEpoch}',
    'codeSha256=${sha256.convert(utf8.encode(normalizedCode))}',
  ]);
}

/// Binds a capture challenge to the bytes and capture metadata of one
/// uploaded photo, video, or audio recording.
///
/// [durationSeconds] must be zero for a photo and positive for a recording, so
/// one fingerprint can never be replayed as evidence of a different kind.
String mediaEvidenceBindingHash({
  required MediaEvidenceKind kind,
  required DateTime capturedAt,
  required String sha256Digest,
  required int byteLength,
  required int durationSeconds,
  required String contentType,
}) {
  final normalizedDigest = _normalizedSha256(
    sha256Digest,
    parameterName: 'sha256Digest',
  );
  final normalizedContentType = contentType.trim().toLowerCase();
  if (byteLength <= 0) {
    throw ArgumentError.value(byteLength, 'byteLength', 'Must be positive.');
  }
  final durationValid = switch (kind) {
    MediaEvidenceKind.photo => durationSeconds == 0,
    MediaEvidenceKind.video || MediaEvidenceKind.audio => durationSeconds > 0,
  };
  if (!durationValid) {
    throw ArgumentError.value(
      durationSeconds,
      'durationSeconds',
      kind == MediaEvidenceKind.photo
          ? 'A photo has no duration; pass zero.'
          : 'A recording needs a positive duration.',
    );
  }
  if (normalizedContentType.isEmpty) {
    throw ArgumentError.value(contentType, 'contentType', 'Must not be empty.');
  }

  return _canonicalHash([
    _bindingDomain,
    'kind=${kind.name}',
    'capturedAtMs=${capturedAt.toUtc().millisecondsSinceEpoch}',
    'sha256=$normalizedDigest',
    'byteLength=$byteLength',
    'durationSeconds=$durationSeconds',
    'contentType=$normalizedContentType',
  ]);
}

/// Binds a capture challenge to one canonical device-motion trace.
String motionEvidenceBindingHash({
  required DateTime capturedAt,
  required String traceSha256,
  required int sampleCount,
  required int durationMilliseconds,
}) {
  final normalizedDigest = _normalizedSha256(
    traceSha256,
    parameterName: 'traceSha256',
  );
  if (sampleCount <= 0 || sampleCount > 1000) {
    throw ArgumentError.value(
      sampleCount,
      'sampleCount',
      'Must be between 1 and 1000.',
    );
  }
  if (durationMilliseconds <= 0 || durationMilliseconds > 30000) {
    throw ArgumentError.value(
      durationMilliseconds,
      'durationMilliseconds',
      'Must be between 1 and 30000.',
    );
  }

  return _canonicalHash([
    _bindingDomain,
    'kind=motion',
    'capturedAtMs=${capturedAt.toUtc().millisecondsSinceEpoch}',
    'traceSha256=$normalizedDigest',
    'sampleCount=$sampleCount',
    'durationMilliseconds=$durationMilliseconds',
  ]);
}

/// Validates and normalizes a SHA-256 binding supplied over the API boundary.
String normalizeEvidenceBindingHash(String value) {
  return _normalizedSha256(value, parameterName: 'evidenceBindingHash');
}

String _canonicalHash(List<String> fields) {
  return sha256.convert(utf8.encode(fields.join('\n'))).toString();
}

String _normalizedSha256(String value, {required String parameterName}) {
  final normalized = value.trim().toLowerCase();
  if (!_sha256Pattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      parameterName,
      'Must be a 64-character hexadecimal SHA-256 digest.',
    );
  }
  return normalized;
}

String _canonicalIdentifier(String value, String parameterName) {
  final normalized = value.trim();
  if (normalized.isEmpty ||
      normalized.contains('\n') ||
      normalized.contains('\r') ||
      normalized.contains('=')) {
    throw ArgumentError.value(
      value,
      parameterName,
      'Must be a non-empty single-line identifier without equals signs.',
    );
  }
  return normalized;
}
