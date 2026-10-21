import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';

const evidenceIntegrityContractVersion = 'verily.evidence-integrity.v1';

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);
final _versionPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{7,255}$');
final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

/// Server-owned identity for one immutable evidence upload.
///
/// Every path component comes from authenticated database state. Constructing
/// this object validates the identity before any storage response is trusted.
class EvidenceIntegrityExpectation {
  EvidenceIntegrityExpectation({
    required String authUserId,
    required String attemptId,
    required String requirementId,
    required this.kind,
    required String contentType,
    required this.byteLength,
  }) : authUserId = _validatedUuid(authUserId, 'authUserId'),
       attemptId = _validatedUuid(attemptId, 'attemptId'),
       requirementId = _validatedUuid(requirementId, 'requirementId'),
       mediaType = _validatedMediaType(contentType, kind) {
    if (byteLength <= 0 || byteLength > maxEvidenceBytesFor(kind)) {
      throw ArgumentError.value(
        byteLength,
        'byteLength',
        'Evidence size must be within the upload limit.',
      );
    }
  }

  final String authUserId;
  final String attemptId;
  final String requirementId;
  final MediaEvidenceKind kind;
  final EvidenceMediaType mediaType;
  final int byteLength;

  String get contentType => mediaType.contentType;

  String get storagePath => evidenceStoragePath(
    authUserId: authUserId,
    attemptId: attemptId,
    requirementId: requirementId,
    type: mediaType,
  );
}

/// A validated, version-pinned evidence identity safe to pass between trusted
/// server components. It contains no media bytes or signed review URL.
class EvidenceIntegritySeal {
  const EvidenceIntegritySeal._({
    required this.storagePath,
    required this.storageVersionId,
    required this.sha256Digest,
    required this.byteLength,
    required this.contentType,
    required this.bindingDigest,
  });

  final String storagePath;
  final String storageVersionId;
  final String sha256Digest;
  final int byteLength;
  final String contentType;

  /// Digest over the canonical identity, not a replacement for the media hash.
  final String bindingDigest;
}

/// Validates the storage response against the reservation and detects any
/// subsequent path, version, checksum, size, or type substitution.
class EvidenceIntegrityPolicy {
  const EvidenceIntegrityPolicy();

  EvidenceIntegritySeal sealInspection({
    required EvidenceIntegrityExpectation expectation,
    required String storagePath,
    required EvidenceObjectInspection inspection,
  }) {
    if (storagePath != expectation.storagePath) {
      throw StateError('Evidence storage path did not match its reservation.');
    }
    if (inspection.byteLength != expectation.byteLength) {
      throw StateError('Evidence byte length did not match its reservation.');
    }
    if (!inspection.matchesContentType(expectation.contentType)) {
      throw StateError('Evidence content type did not match its reservation.');
    }

    return _seal(
      storagePath: storagePath,
      storageVersionId: inspection.versionId,
      sha256Digest: inspection.sha256Digest,
      byteLength: inspection.byteLength,
      contentType: expectation.contentType,
    );
  }

  EvidenceIntegritySeal validatePersistedBinding({
    required EvidenceIntegrityExpectation expectation,
    required String storagePath,
    required String storageVersionId,
    required String sha256Digest,
    required int byteLength,
    required String contentType,
  }) {
    if (storagePath != expectation.storagePath ||
        byteLength != expectation.byteLength ||
        contentType != expectation.contentType) {
      throw StateError(
        'Persisted evidence did not match its trusted identity.',
      );
    }

    return _seal(
      storagePath: storagePath,
      storageVersionId: storageVersionId,
      sha256Digest: sha256Digest,
      byteLength: byteLength,
      contentType: contentType,
    );
  }

  void assertReinspectionMatches({
    required EvidenceIntegritySeal sealed,
    required EvidenceObjectInspection inspection,
  }) {
    final reinspected = _seal(
      storagePath: sealed.storagePath,
      storageVersionId: inspection.versionId,
      sha256Digest: inspection.sha256Digest,
      byteLength: inspection.byteLength,
      contentType: sealed.contentType,
    );
    if (!inspection.matchesContentType(sealed.contentType) ||
        reinspected.bindingDigest != sealed.bindingDigest) {
      throw StateError('The immutable evidence version changed after sealing.');
    }
  }

  EvidenceIntegritySeal _seal({
    required String storagePath,
    required String storageVersionId,
    required String sha256Digest,
    required int byteLength,
    required String contentType,
  }) {
    final version = _validatedVersion(storageVersionId);
    final digest = _validatedSha256(sha256Digest);
    final normalizedContentType = contentType.trim().toLowerCase();
    if (normalizedContentType != contentType ||
        !evidenceMediaTypes.containsKey(normalizedContentType)) {
      throw StateError('Evidence content type was not an approved type.');
    }
    if (byteLength <= 0 || byteLength > maximumEvidenceByteLength) {
      throw StateError('Evidence byte length was outside the trusted range.');
    }

    final canonicalBinding = <String>[
      evidenceIntegrityContractVersion,
      storagePath,
      version,
      digest,
      byteLength.toString(),
      normalizedContentType,
    ].join('\n');
    final bindingDigest = sha256
        .convert(utf8.encode(canonicalBinding))
        .toString();

    return EvidenceIntegritySeal._(
      storagePath: storagePath,
      storageVersionId: version,
      sha256Digest: digest,
      byteLength: byteLength,
      contentType: normalizedContentType,
      bindingDigest: bindingDigest,
    );
  }
}

String _validatedUuid(String value, String name) {
  final normalized = value.trim();
  if (normalized != value || !_uuidPattern.hasMatch(normalized)) {
    throw ArgumentError.value(value, name, 'A canonical UUID is required.');
  }
  return normalized;
}

EvidenceMediaType _validatedMediaType(
  String value,
  MediaEvidenceKind kind,
) {
  final normalized = value.trim().toLowerCase();
  final type = evidenceMediaTypes[normalized];
  if (normalized != value || type == null || type.kind != kind) {
    throw ArgumentError.value(
      value,
      'contentType',
      'An approved canonical evidence type is required.',
    );
  }
  return type;
}

String _validatedVersion(String value) {
  if (value.trim() != value || !_versionPattern.hasMatch(value)) {
    throw StateError('Evidence storage version was not canonical.');
  }
  return value;
}

String _validatedSha256(String value) {
  if (!_sha256Pattern.hasMatch(value)) {
    throw StateError('Evidence SHA-256 digest was not canonical.');
  }
  return value;
}
