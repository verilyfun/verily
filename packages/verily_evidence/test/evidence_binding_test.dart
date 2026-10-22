import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:verily_evidence/verily_evidence.dart';

void main() {
  final capturedAt = DateTime.utc(2026, 8, 27, 12, 34, 56, 789);

  group('Given location evidence', () {
    test('when the same instant is expressed in another zone then the '
        'binding is stable', () {
      final first = locationEvidenceBindingHash(
        capturedAt: capturedAt,
        latitude: 51.5074,
        longitude: -0.1278,
        accuracyMeters: 8.25,
      );
      final second = locationEvidenceBindingHash(
        capturedAt: capturedAt.toLocal(),
        latitude: 51.5074,
        longitude: -0.1278,
        accuracyMeters: 8.25,
      );

      expect(first, hasLength(64));
      expect(second, first);
    });

    test('when the coordinates change then the binding changes', () {
      final first = locationEvidenceBindingHash(
        capturedAt: capturedAt,
        latitude: 51.5074,
        longitude: -0.1278,
        accuracyMeters: 8.25,
      );
      final second = locationEvidenceBindingHash(
        capturedAt: capturedAt,
        latitude: 48.8566,
        longitude: 2.3522,
        accuracyMeters: 8.25,
      );

      expect(second, isNot(first));
    });

    test('when a coordinate is out of range then it is refused', () {
      expect(
        () => locationEvidenceBindingHash(
          capturedAt: capturedAt,
          latitude: 95,
          longitude: 0,
          accuracyMeters: 5,
        ),
        throwsArgumentError,
      );
    });
  });

  test('Given a QR code when padded then the binding trims and never exposes '
      'the code', () {
    const secretCode = 'venue-secret-2026';
    final trimmed = qrEvidenceBindingHash(
      capturedAt: capturedAt,
      code: secretCode,
    );
    final padded = qrEvidenceBindingHash(
      capturedAt: capturedAt,
      code: '  $secretCode  ',
    );

    expect(trimmed, padded);
    expect(trimmed, isNot(contains(secretCode)));
  });

  group('Given media evidence', () {
    String binding({
      MediaEvidenceKind kind = MediaEvidenceKind.video,
      String digest =
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      int byteLength = 4096,
      int durationSeconds = 12,
      String contentType = 'video/mp4',
    }) => mediaEvidenceBindingHash(
      kind: kind,
      capturedAt: capturedAt,
      sha256Digest: digest,
      byteLength: byteLength,
      durationSeconds: durationSeconds,
      contentType: contentType,
    );

    test('when the uploaded bytes change then the binding changes', () {
      expect(binding(digest: 'c' * 64), isNot(binding()));
    });

    test('when only the media kind differs then the bindings differ', () {
      final video = binding(contentType: 'audio/mp4');
      final audio = binding(
        kind: MediaEvidenceKind.audio,
        contentType: 'audio/mp4',
      );

      expect(audio, isNot(video));
    });

    test('when a photo carries a duration then it is refused', () {
      expect(
        () => binding(
          kind: MediaEvidenceKind.photo,
          contentType: 'image/jpeg',
        ),
        throwsArgumentError,
      );
      expect(
        binding(
          kind: MediaEvidenceKind.photo,
          durationSeconds: 0,
          contentType: 'image/jpeg',
        ),
        hasLength(64),
      );
    });

    test('when a recording has no duration then it is refused', () {
      expect(
        () => binding(kind: MediaEvidenceKind.audio, durationSeconds: 0),
        throwsArgumentError,
      );
    });

    test('when the content type differs only in case then the binding is '
        'stable', () {
      expect(binding(contentType: 'VIDEO/MP4'), binding());
    });
  });

  test('Given chunked bytes when hashed as a stream then no contiguous buffer '
      'is needed', () async {
    final digest = await sha256Stream(
      Stream<List<int>>.fromIterable([
        utf8.encode('recording-'),
        utf8.encode('bytes'),
      ]),
    );

    expect(
      digest,
      '1a656a301805a7df373828a001d069b7da8442a1428e756de4f8226a821f81ae',
    );
  });

  test('Given a malformed hash when normalized then it is refused before it '
      'crosses the trust boundary', () {
    expect(
      () => normalizeEvidenceBindingHash('not-a-sha256'),
      throwsArgumentError,
    );
  });

  // 32 bytes, unpadded base64url: the shape of a server capture challenge.
  final challenge = base64Url
      .encode(List<int>.generate(32, (index) => index))
      .replaceAll('=', '');

  test('Given two bindings when hashed into integrity requests then each '
      'request commits to its own binding', () {
    final first = captureIntegrityRequestHash(
      attemptId: 'attempt',
      requirementId: 'requirement',
      captureChallenge: challenge,
      evidenceBindingHash: 'a' * 64,
    );
    final second = captureIntegrityRequestHash(
      attemptId: 'attempt',
      requirementId: 'requirement',
      captureChallenge: challenge,
      evidenceBindingHash: 'b' * 64,
    );

    expect(first, hasLength(43));
    expect(first, isNot(contains('=')));
    expect(second, isNot(first));
  });

  test('Given two capture challenges when hashed into integrity requests then '
      'each request commits to its own challenge', () {
    final other = base64Url.encode(List<int>.filled(32, 7)).replaceAll('=', '');

    expect(
      captureIntegrityRequestHash(
        attemptId: 'attempt',
        requirementId: 'requirement',
        captureChallenge: challenge,
        evidenceBindingHash: 'a' * 64,
      ),
      isNot(
        captureIntegrityRequestHash(
          attemptId: 'attempt',
          requirementId: 'requirement',
          captureChallenge: other,
          evidenceBindingHash: 'a' * 64,
        ),
      ),
    );
  });

  group('Given a capture key attestation challenge', () {
    test('when derived then it is SHA-256 of the raw challenge and the '
        'attempt id', () {
      final derived = captureKeyAttestationChallenge(
        captureChallenge: challenge,
        attemptId: 'attempt',
      );

      expect(
        derived,
        sha256.convert([
          ...List<int>.generate(32, (index) => index),
          ...utf8.encode('attempt'),
        ]).bytes,
      );
      expect(derived, hasLength(32));
    });

    test('when the attempt changes then the challenge changes', () {
      expect(
        captureKeyAttestationChallenge(
          captureChallenge: challenge,
          attemptId: 'attempt',
        ),
        isNot(
          captureKeyAttestationChallenge(
            captureChallenge: challenge,
            attemptId: 'other-attempt',
          ),
        ),
      );
    });

    test('when the capture challenge is malformed then it is refused', () {
      for (final malformed in ['', 'short', '${challenge}A', '$challenge=']) {
        expect(
          () => captureKeyAttestationChallenge(
            captureChallenge: malformed,
            attemptId: 'attempt',
          ),
          throwsArgumentError,
          reason: malformed,
        );
      }
    });
  });

  group('Given App Attest client data', () {
    test('when registering then it is SHA-256 of the raw challenge', () {
      expect(
        appAttestRegistrationClientDataHash(challenge),
        sha256.convert(List<int>.generate(32, (index) => index)).bytes,
      );
    });

    test('when registering with a malformed challenge then it is refused', () {
      for (final malformed in ['', 'short', '$challenge=']) {
        expect(
          () => appAttestRegistrationClientDataHash(malformed),
          throwsArgumentError,
          reason: malformed,
        );
      }
    });

    test('when asserting then it is SHA-256 of the manifest bytes', () {
      final manifest = utf8.encode('verily-capture-manifest-v1\nattempt');

      expect(
        appAttestAssertionClientDataHash(manifest),
        sha256.convert(manifest).bytes,
      );
      expect(() => appAttestAssertionClientDataHash([]), throwsArgumentError);
    });
  });

  group('Given a capture manifest', () {
    test('when built then it commits one signature to one challenge and '
        'proof', () {
      final requestHash = captureIntegrityRequestHash(
        attemptId: 'attempt',
        requirementId: 'requirement',
        captureChallenge: challenge,
        evidenceBindingHash: 'a' * 64,
      );
      final manifest = utf8.decode(
        captureProvenanceManifest(
          attemptId: 'attempt',
          requirementId: 'requirement',
          requestHash: requestHash,
          evidenceBindingHash: 'a' * 64,
        ),
      );

      expect(
        manifest,
        [
          'verily-capture-manifest-v1',
          'attemptId=attempt',
          'requirementId=requirement',
          'requestHash=$requestHash',
          'evidenceBindingHash=${'a' * 64}',
        ].join('\n'),
      );
    });

    test('when an identifier smuggles another field then it is refused', () {
      expect(
        () => captureProvenanceManifest(
          attemptId: 'attempt\nrequirementId=other',
          requirementId: 'requirement',
          requestHash: 'a' * 43,
          evidenceBindingHash: 'b' * 64,
        ),
        throwsArgumentError,
      );
    });
  });

  test('Given an encoded public key when identified then the id is its '
      'SHA-256', () {
    expect(capturePublicKeyId([1, 2, 3]), hasLength(64));
    expect(() => capturePublicKeyId(const []), throwsArgumentError);
  });
}
