import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/features/evidence/capture_provenance_service.dart';
import 'package:verily_flutter/features/evidence/captured_media.dart';
import 'package:verily_flutter/features/evidence/device_integrity_service.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';

final _attemptId = UuidValue.fromString('00000000-0000-4000-8000-0000000000c1');
final _requirementId = UuidValue.fromString(
  '00000000-0000-4000-8000-0000000000d1',
);
final _challengeId = UuidValue.fromString(
  '00000000-0000-4000-8000-0000000000e1',
);
// 32 bytes, unpadded base64url, as the server issues it.
const _captureChallenge = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

ActionAttemptView _attempt() => ActionAttemptView(
  id: _attemptId,
  actionDefinitionId: UuidValue.fromString(
    '00000000-0000-4000-8000-0000000000f1',
  ),
  periodKey: 'once',
  status: ActionAttemptStatus.collectingEvidence,
  startedAt: DateTime.utc(2026, 10, 21),
  updatedAt: DateTime.utc(2026, 10, 21),
);

ActionRequirementView _requirement(ActionRequirementKind kind) =>
    ActionRequirementView(
      id: _requirementId,
      requirementKey: 'proof',
      kind: kind,
      title: 'Proof',
      instructions: 'Do the thing.',
      position: 0,
      isRequired: true,
      spokenChallengeRequired: false,
    );

EvidenceSubmissionResult _result() => EvidenceSubmissionResult(
  attempt: _attempt(),
  requirementId: _requirementId,
  reasonCode: 'checking',
  summary: 'Checking your proof.',
);

class _Gateway implements EvidenceGateway {
  _Gateway({this.integrityRequired = false, this.signatureRequired = false});

  final bool integrityRequired;
  final bool signatureRequired;
  bool uploadSucceeds = true;
  final calls = <String>[];
  ActionEvidenceInput? submitted;
  MediaUploadConfirmation? confirmed;

  @override
  Future<ActionCaptureChallengeView> beginCapture({
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) async {
    calls.add('begin');
    return ActionCaptureChallengeView(
      id: _challengeId,
      captureChallenge: _captureChallenge,
      issuedAt: DateTime.utc(2026, 10, 21),
      expiresAt: DateTime.utc(2026, 10, 21, 0, 30),
      integrityRequired: integrityRequired,
      signatureRequired: signatureRequired,
    );
  }

  @override
  Future<EvidenceSubmissionResult> submitEvidence(
    ActionEvidenceInput input,
  ) async {
    calls.add('submit');
    submitted = input;
    return _result();
  }

  @override
  Future<String> requestMediaUpload({
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String contentType,
    required int byteLength,
  }) async {
    calls.add('request-upload');
    return 'upload-description';
  }

  @override
  Future<bool> uploadMedia(
    String uploadDescription,
    CapturedMedia media,
  ) async {
    calls.add('upload');
    return uploadSucceeds;
  }

  @override
  Future<EvidenceSubmissionResult> confirmMediaUpload(
    MediaUploadConfirmation confirmation,
  ) async {
    calls.add('confirm');
    confirmed = confirmation;
    return _result();
  }
}

const _proof = CaptureProvenanceProof.keystore(
  manifest: 'bWFuaWZlc3Q=',
  signature: 'c2lnbmF0dXJl',
  certificateChain: ['bGVhZg==', 'cm9vdA=='],
);

/// A key store that records what it was asked to attest and sign.
class _Keys implements CaptureKeyStore {
  _Keys({this.available = true});

  final bool available;
  final prepared = <String, List<int>>{};
  final signed = <List<int>>[];

  @override
  Future<bool> prepare({
    required String captureId,
    required List<int> attestationChallenge,
  }) async {
    if (!available) return false;
    prepared[captureId] = attestationChallenge;
    return true;
  }

  @override
  Future<CaptureProvenanceProof?> sign({
    required String captureId,
    required List<int> manifest,
  }) async {
    if (!prepared.containsKey(captureId)) return null;
    signed.add(manifest);
    return _proof;
  }
}

String _requestHash(String bindingHash) => captureIntegrityRequestHash(
  attemptId: _attemptId.toString(),
  requirementId: _requirementId.toString(),
  captureChallenge: _captureChallenge,
  evidenceBindingHash: bindingHash,
);

void main() {
  final fix = LocationFix(
    latitude: 51.5007,
    longitude: -0.1246,
    accuracyMeters: 8,
    capturedAt: DateTime.utc(2026, 10, 21, 9, 30),
  );

  test('a capture window opens before capture and generates a key that '
      'attests it', () async {
    final gateway = _Gateway();
    final keys = _Keys();
    final service = EvidenceService(
      gateway: gateway,
      deviceIntegrity: (hash) async => null,
      captureKeys: keys,
    );

    final session = await service.beginCapture(
      attempt: _attempt(),
      requirement: _requirement(ActionRequirementKind.location),
    );

    expect(gateway.calls, ['begin']);
    expect(session.challenge.id, _challengeId);
    expect(keys.prepared[_challengeId.toString()], [
      ...captureKeyAttestationChallenge(
        captureChallenge: _captureChallenge,
        attemptId: _attemptId.toString(),
      ),
    ]);
    expect(session.isExpiredAt(DateTime.utc(2026, 10, 21, 0, 29)), isFalse);
    expect(session.isExpiredAt(DateTime.utc(2026, 10, 21, 0, 30)), isTrue);
  });

  test('a location proof is bound to that exact reading, window, and '
      'device', () async {
    final gateway = _Gateway();
    final keys = _Keys();
    final service = EvidenceService(
      gateway: gateway,
      deviceIntegrity: (hash) async => 'token-for-$hash',
      captureKeys: keys,
    );
    final requirement = _requirement(ActionRequirementKind.location);
    final session = await service.beginCapture(
      attempt: _attempt(),
      requirement: requirement,
    );

    await service.submitLocation(
      attempt: _attempt(),
      requirement: requirement,
      session: session,
      fix: fix,
    );

    final binding = locationEvidenceBindingHash(
      capturedAt: fix.capturedAt,
      latitude: fix.latitude,
      longitude: fix.longitude,
      accuracyMeters: fix.accuracyMeters,
    );
    final input = gateway.submitted!;
    expect(input.captureChallengeId, _challengeId);
    expect(input.deviceIntegrityToken, 'token-for-${_requestHash(binding)}');
    expect(keys.signed.single, [
      ...captureProvenanceManifest(
        attemptId: _attemptId.toString(),
        requirementId: _requirementId.toString(),
        requestHash: _requestHash(binding),
        evidenceBindingHash: binding,
      ),
    ]);
    expect(input.captureSignature, _proof.signature);
    expect(input.captureCertificateChain, _proof.certificateChain);
    expect(input.latitude, fix.latitude);
  });

  test(
    'refuses to send when the server needs a token the phone lacks',
    () async {
      final gateway = _Gateway(integrityRequired: true);
      final service = EvidenceService(
        gateway: gateway,
        deviceIntegrity: (hash) async => null,
        captureKeys: _Keys(),
      );
      final requirement = _requirement(ActionRequirementKind.qrCode);
      final session = await service.beginCapture(
        attempt: _attempt(),
        requirement: requirement,
      );

      expect(
        service.submitQrCode(
          attempt: _attempt(),
          requirement: requirement,
          session: session,
          code: 'verily:v1:abc',
        ),
        throwsA(
          isA<CaptureIntegrityException>().having(
            (error) => error.failure,
            'failure',
            CaptureIntegrityFailure.integrityUnavailable,
          ),
        ),
      );
    },
  );

  test('refuses to send when the server needs a signature the phone cannot '
      'make', () async {
    final gateway = _Gateway(signatureRequired: true);
    final service = EvidenceService(
      gateway: gateway,
      deviceIntegrity: (hash) async => 'token',
      captureKeys: _Keys(available: false),
    );
    final requirement = _requirement(ActionRequirementKind.qrCode);
    final session = await service.beginCapture(
      attempt: _attempt(),
      requirement: requirement,
    );

    await expectLater(
      service.submitQrCode(
        attempt: _attempt(),
        requirement: requirement,
        session: session,
        code: 'verily:v1:abc',
      ),
      throwsA(
        isA<CaptureIntegrityException>().having(
          (error) => error.failure,
          'failure',
          CaptureIntegrityFailure.signatureUnavailable,
        ),
      ),
    );
    expect(gateway.calls, ['begin']);
  });

  test('refuses a window opened for another proof', () async {
    final gateway = _Gateway();
    final service = EvidenceService(
      gateway: gateway,
      deviceIntegrity: (hash) async => null,
      captureKeys: _Keys(),
    );
    final session = await service.beginCapture(
      attempt: _attempt(),
      requirement: _requirement(ActionRequirementKind.qrCode),
    );
    final other = ActionRequirementView(
      id: UuidValue.fromString('00000000-0000-4000-8000-0000000000d2'),
      requirementKey: 'other',
      kind: ActionRequirementKind.location,
      title: 'Other',
      instructions: 'Somewhere else.',
      position: 1,
      isRequired: true,
      spokenChallengeRequired: false,
    );

    await expectLater(
      service.submitLocation(
        attempt: _attempt(),
        requirement: other,
        session: session,
        fix: fix,
      ),
      throwsArgumentError,
    );
    expect(gateway.calls, ['begin']);
  });

  group('media', () {
    final bytes = Uint8List.fromList(utf8.encode('fake m4a bytes'));

    Future<CapturedMedia> audio() => describeCapturedMedia(
      XFile.fromData(bytes, name: 'proof.m4a', mimeType: 'audio/mp4'),
      kind: MediaEvidenceKind.audio,
      contentType: 'audio/mp4',
      capturedAt: DateTime.utc(2026, 10, 21, 9, 31),
      durationSeconds: 12,
      spokenChallengeWord: 'pelican',
    );

    Future<(EvidenceService, CaptureSession)> opened(
      _Gateway gateway,
      ActionRequirementKind kind, {
      DeviceIntegrityTokenSource? deviceIntegrity,
    }) async {
      final service = EvidenceService(
        gateway: gateway,
        deviceIntegrity: deviceIntegrity ?? (hash) async => null,
        captureKeys: _Keys(available: false),
      );
      final session = await service.beginCapture(
        attempt: _attempt(),
        requirement: _requirement(kind),
      );
      return (service, session);
    }

    test('uploads, then binds the window to the uploaded bytes', () async {
      final gateway = _Gateway();
      final (service, session) = await opened(
        gateway,
        ActionRequirementKind.audio,
        deviceIntegrity: (hash) async => 'token-for-$hash',
      );
      final media = await audio();

      await service.uploadMedia(
        attempt: _attempt(),
        requirement: _requirement(ActionRequirementKind.audio),
        session: session,
        media: media,
      );

      expect(gateway.calls, ['begin', 'request-upload', 'upload', 'confirm']);
      expect(media.sha256Digest, await sha256Stream(Stream.value(bytes)));
      final binding = mediaEvidenceBindingHash(
        kind: MediaEvidenceKind.audio,
        capturedAt: media.capturedAt,
        sha256Digest: media.sha256Digest,
        byteLength: bytes.length,
        durationSeconds: 12,
        contentType: 'audio/mp4',
      );
      expect(
        gateway.confirmed!.deviceIntegrityToken,
        'token-for-${_requestHash(binding)}',
      );
      final confirmation = gateway.confirmed!;
      expect(confirmation.byteLength, bytes.length);
      expect(confirmation.durationSeconds, 12);
      expect(confirmation.contentType, 'audio/mp4');
      expect(confirmation.captureChallengeId, _challengeId);
    });

    test('a photo carries no duration', () async {
      final gateway = _Gateway();
      final (service, session) = await opened(
        gateway,
        ActionRequirementKind.photo,
      );
      final photo = await describeCapturedMedia(
        XFile.fromData(bytes, name: 'proof.jpg', mimeType: 'image/jpeg'),
        kind: MediaEvidenceKind.photo,
        contentType: 'image/jpeg',
        capturedAt: DateTime.utc(2026, 10, 21, 9, 32),
        durationSeconds: 7,
      );

      await service.uploadMedia(
        attempt: _attempt(),
        requirement: _requirement(ActionRequirementKind.photo),
        session: session,
        media: photo,
      );

      expect(photo.durationSeconds, 0);
      expect(gateway.confirmed!.durationSeconds, isNull);
    });

    test('a failed upload stops before anything is confirmed', () async {
      final gateway = _Gateway()..uploadSucceeds = false;
      final (service, session) = await opened(
        gateway,
        ActionRequirementKind.audio,
      );

      await expectLater(
        service.uploadMedia(
          attempt: _attempt(),
          requirement: _requirement(ActionRequirementKind.audio),
          session: session,
          media: await audio(),
        ),
        throwsA(isA<MediaUploadException>()),
      );
      expect(gateway.calls, ['begin', 'request-upload', 'upload']);
    });
  });
}
