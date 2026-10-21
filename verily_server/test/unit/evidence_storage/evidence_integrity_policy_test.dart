import 'package:test/test.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/evidence_storage/evidence_integrity_policy.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';

void main() {
  const policy = EvidenceIntegrityPolicy();

  EvidenceIntegrityExpectation expectationFor({
    MediaEvidenceKind kind = MediaEvidenceKind.video,
    String contentType = 'video/mp4',
    String requirementId = _requirementId,
    int byteLength = 24,
  }) => EvidenceIntegrityExpectation(
    authUserId: _authUserId,
    attemptId: _attemptId,
    requirementId: requirementId,
    kind: kind,
    contentType: contentType,
    byteLength: byteLength,
  );

  group('Given a video upload expectation', () {
    late EvidenceIntegrityExpectation expectation;

    setUp(() => expectation = expectationFor());

    test('when the inspection matches then the seal pins path, version, '
        'digest, size, and type', () {
      final seal = policy.sealInspection(
        expectation: expectation,
        storagePath: expectation.storagePath,
        inspection: _inspection(),
      );

      expect(
        seal.storagePath,
        'action-evidence/$_authUserId/$_attemptId/$_requirementId.mp4',
      );
      expect(seal.storageVersionId, '4_z0123456789abcdef');
      expect(seal.sha256Digest, _digest);
      expect(seal.contentType, 'video/mp4');
      expect(seal.bindingDigest, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('when the path names another account then sealing is refused', () {
      final replayedPath = expectation.storagePath.replaceFirst(
        _authUserId,
        _otherAuthUserId,
      );

      expect(
        () => policy.sealInspection(
          expectation: expectation,
          storagePath: replayedPath,
          inspection: _inspection(),
        ),
        throwsStateError,
      );
    });

    test('when the stored size differs then sealing is refused', () {
      expect(
        () => policy.sealInspection(
          expectation: expectation,
          storagePath: expectation.storagePath,
          inspection: _inspection(byteLength: 23),
        ),
        throwsStateError,
      );
    });

    test('when the container does not match the claimed type then sealing '
        'is refused', () {
      expect(
        () => policy.sealInspection(
          expectation: expectation,
          storagePath: expectation.storagePath,
          inspection: _inspection(compatible: const {'image/jpeg'}),
        ),
        throwsStateError,
      );
      expect(
        () => policy.sealInspection(
          expectation: expectation,
          storagePath: expectation.storagePath,
          inspection: _inspection(contentType: 'video/webm'),
        ),
        throwsStateError,
      );
    });

    test('when the version or checksum is not canonical then sealing is '
        'refused', () {
      expect(
        () => policy.sealInspection(
          expectation: expectation,
          storagePath: expectation.storagePath,
          inspection: _inspection(versionId: 'version%26other=latest'),
        ),
        throwsStateError,
      );
      expect(
        () => policy.sealInspection(
          expectation: expectation,
          storagePath: expectation.storagePath,
          inspection: _inspection(sha256Digest: _digest.toUpperCase()),
        ),
        throwsStateError,
      );
    });

    test('when the object is reinspected after mutation then every change '
        'is detected', () {
      final sealed = policy.sealInspection(
        expectation: expectation,
        storagePath: expectation.storagePath,
        inspection: _inspection(),
      );

      for (final changed in [
        _inspection(versionId: '4_zfedcba9876543210'),
        _inspection(sha256Digest: 'b' * 64),
        _inspection(byteLength: 23),
        _inspection(
          contentType: 'video/webm',
          compatible: const {'video/webm', 'audio/webm'},
        ),
      ]) {
        expect(
          () => policy.assertReinspectionMatches(
            sealed: sealed,
            inspection: changed,
          ),
          throwsStateError,
        );
      }
      expect(
        () => policy.assertReinspectionMatches(
          sealed: sealed,
          inspection: _inspection(),
        ),
        returnsNormally,
      );
    });

    test('when persisted evidence is checked against another requirement '
        'then it is refused', () {
      expect(
        () => policy.validatePersistedBinding(
          expectation: expectationFor(requirementId: _otherRequirementId),
          storagePath: expectation.storagePath,
          storageVersionId: '4_z0123456789abcdef',
          sha256Digest: _digest,
          byteLength: 24,
          contentType: 'video/mp4',
        ),
        throwsStateError,
      );
    });
  });

  group('Given photo and audio expectations', () {
    test('when a photo is sealed then its path and binding commit to the '
        'photo digest', () {
      final expectation = expectationFor(
        kind: MediaEvidenceKind.photo,
        contentType: 'image/jpeg',
      );
      final seal = policy.sealInspection(
        expectation: expectation,
        storagePath: expectation.storagePath,
        inspection: _inspection(
          contentType: 'image/jpeg',
          compatible: const {'image/jpeg'},
        ),
      );
      final otherDigest = policy.sealInspection(
        expectation: expectation,
        storagePath: expectation.storagePath,
        inspection: _inspection(
          contentType: 'image/jpeg',
          compatible: const {'image/jpeg'},
          sha256Digest: 'c' * 64,
        ),
      );

      expect(seal.storagePath, endsWith('.jpg'));
      expect(seal.bindingDigest, isNot(otherDigest.bindingDigest));
    });

    test('when audio is sealed then it uses the m4a path and pins its '
        'digest', () {
      final expectation = expectationFor(
        kind: MediaEvidenceKind.audio,
        contentType: 'audio/mp4',
      );
      final seal = policy.sealInspection(
        expectation: expectation,
        storagePath: expectation.storagePath,
        inspection: _inspection(
          contentType: 'audio/mp4',
        ),
      );

      expect(seal.storagePath, endsWith('.m4a'));
      expect(seal.sha256Digest, _digest);
    });

    test('when a type belongs to another media kind then the expectation is '
        'refused', () {
      for (final (kind, contentType) in [
        (MediaEvidenceKind.photo, 'video/mp4'),
        (MediaEvidenceKind.audio, 'image/png'),
        (MediaEvidenceKind.video, 'audio/webm'),
      ]) {
        expect(
          () => expectationFor(kind: kind, contentType: contentType),
          throwsArgumentError,
          reason: '$kind $contentType',
        );
      }
    });

    test('when a photo exceeds 20 MiB then the expectation is refused', () {
      expect(
        () => expectationFor(
          kind: MediaEvidenceKind.photo,
          contentType: 'image/png',
          byteLength: 20 * 1024 * 1024 + 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => expectationFor(
          kind: MediaEvidenceKind.photo,
          contentType: 'image/png',
          byteLength: 20 * 1024 * 1024,
        ),
        returnsNormally,
      );
    });
  });

  group('Given non-canonical identity input', () {
    test('when an id or type is not canonical then the expectation is '
        'refused', () {
      expect(
        () => EvidenceIntegrityExpectation(
          authUserId: _authUserId.toUpperCase(),
          attemptId: _attemptId,
          requirementId: _requirementId,
          kind: MediaEvidenceKind.video,
          contentType: 'video/mp4',
          byteLength: 24,
        ),
        throwsArgumentError,
      );
      expect(
        () => expectationFor(contentType: 'video/mp4; charset=binary'),
        throwsArgumentError,
      );
      expect(() => expectationFor(byteLength: 0), throwsArgumentError);
    });
  });
}

EvidenceObjectInspection _inspection({
  int byteLength = 24,
  String contentType = 'video/mp4',
  Set<String> compatible = const {'video/mp4', 'audio/mp4'},
  String versionId = '4_z0123456789abcdef',
  String sha256Digest = _digest,
}) => EvidenceObjectInspection(
  byteLength: byteLength,
  contentType: contentType,
  compatibleContentTypes: compatible,
  versionId: versionId,
  sha256Digest: sha256Digest,
);

const _authUserId = '018f0000-0000-7000-8000-000000000001';
const _otherAuthUserId = '018f0000-0000-7000-8000-000000000002';
const _attemptId = '018f0000-0000-7000-8000-000000000003';
const _requirementId = '018f0000-0000-7000-8000-000000000004';
const _otherRequirementId = '018f0000-0000-7000-8000-000000000005';
const _digest =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
