import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/features/evidence/capture_provenance_service.dart';
import 'package:verily_flutter/features/evidence/captured_media.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';

final _attemptId = UuidValue.fromString('00000000-0000-4000-8000-0000000000c1');
final _requirementId = UuidValue.fromString(
  '00000000-0000-4000-8000-0000000000d1',
);
final _challengeId = UuidValue.fromString(
  '00000000-0000-4000-8000-0000000000e1',
);
const _requestHash = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

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
  reasonCode: 'queued',
  summary: 'Checking your proof.',
);

class _Gateway implements EvidenceGateway {
  _Gateway({this.integrityRequired = false, this.signatureRequired = false});

  final bool integrityRequired;
  final bool signatureRequired;
  bool uploadSucceeds = true;
  final calls = <String>[];
  final bindingHashes = <String>[];
  ActionEvidenceInput? submitted;
  MediaUploadConfirmation? confirmed;

  @override
  Future<ActionCaptureChallengeView> createCaptureChallenge({
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String evidenceBindingHash,
  }) async {
    calls.add('challenge');
    bindingHashes.add(evidenceBindingHash);
    return ActionCaptureChallengeView(
      id: _challengeId,
      requestHash: _requestHash,
      expiresAt: DateTime.utc(2026, 10, 21, 0, 5),
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

const _proof = CaptureProvenanceProof(
  manifest: 'bWFuaWZlc3Q=',
  signature: 'c2lnbmF0dXJl',
  publicKey: 'cHVibGlj',
  keyId: 'key-id',
  keyStorage: 'strongBox',
);

Future<CaptureProvenanceProof?> _signs({
  required String attemptId,
  required String requirementId,
  required String requestHash,
  required String evidenceBindingHash,
}) async => _proof;

Future<CaptureProvenanceProof?> _cannotSign({
  required String attemptId,
  required String requirementId,
  required String requestHash,
  required String evidenceBindingHash,
}) async => null;

void main() {
  final fix = LocationFix(
    latitude: 51.5007,
    longitude: -0.1246,
    accuracyMeters: 8,
    capturedAt: DateTime.utc(2026, 10, 21, 9, 30),
  );

  test('a location proof is bound to that exact reading and device', () async {
    final gateway = _Gateway();
    final service = EvidenceService(
      gateway: gateway,
      deviceIntegrity: (hash) async => 'token-for-$hash',
      signCapture: _signs,
    );

    await service.submitLocation(
      attempt: _attempt(),
      requirement: _requirement(ActionRequirementKind.location),
      fix: fix,
    );

    expect(
      gateway.bindingHashes.single,
      locationEvidenceBindingHash(
        capturedAt: fix.capturedAt,
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracyMeters: fix.accuracyMeters,
      ),
    );
    final input = gateway.submitted!;
    expect(input.captureChallengeId, _challengeId);
    expect(input.deviceIntegrityToken, 'token-for-$_requestHash');
    expect(input.captureSignature, _proof.signature);
    expect(input.captureKeyStorage, 'strongBox');
    expect(input.latitude, fix.latitude);
  });

  test('refuses to send when the server needs a token the phone lacks', () {
    final gateway = _Gateway(integrityRequired: true);
    final service = EvidenceService(
      gateway: gateway,
      deviceIntegrity: (hash) async => null,
      signCapture: _signs,
    );

    expect(
      service.submitQrCode(
        attempt: _attempt(),
        requirement: _requirement(ActionRequirementKind.qrCode),
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
  });

  test('refuses to send when the server needs a device signature', () async {
    final gateway = _Gateway(signatureRequired: true);
    final service = EvidenceService(
      gateway: gateway,
      deviceIntegrity: (hash) async => 'token',
      signCapture: _cannotSign,
    );

    await expectLater(
      service.submitQrCode(
        attempt: _attempt(),
        requirement: _requirement(ActionRequirementKind.qrCode),
        code: 'verily:v1:abc',
      ),
      throwsA(isA<CaptureIntegrityException>()),
    );
    expect(gateway.calls, ['challenge']);
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

    test('uploads, then binds the challenge to the uploaded bytes', () async {
      final gateway = _Gateway();
      final service = EvidenceService(
        gateway: gateway,
        deviceIntegrity: (hash) async => 'token',
        signCapture: _signs,
      );
      final media = await audio();

      await service.uploadMedia(
        attempt: _attempt(),
        requirement: _requirement(ActionRequirementKind.audio),
        media: media,
      );

      expect(gateway.calls, [
        'request-upload',
        'upload',
        'challenge',
        'confirm',
      ]);
      expect(media.sha256Digest, await sha256Stream(Stream.value(bytes)));
      expect(
        gateway.bindingHashes.single,
        mediaEvidenceBindingHash(
          kind: MediaEvidenceKind.audio,
          capturedAt: media.capturedAt,
          sha256Digest: media.sha256Digest,
          byteLength: bytes.length,
          durationSeconds: 12,
          contentType: 'audio/mp4',
        ),
      );
      final confirmation = gateway.confirmed!;
      expect(confirmation.byteLength, bytes.length);
      expect(confirmation.durationSeconds, 12);
      expect(confirmation.contentType, 'audio/mp4');
      expect(confirmation.captureChallengeId, _challengeId);
    });

    test('a photo carries no duration', () async {
      final gateway = _Gateway();
      final service = EvidenceService(
        gateway: gateway,
        deviceIntegrity: (hash) async => null,
        signCapture: _cannotSign,
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
        media: photo,
      );

      expect(photo.durationSeconds, 0);
      expect(gateway.confirmed!.durationSeconds, isNull);
    });

    test('a failed upload stops before anything is confirmed', () async {
      final gateway = _Gateway()..uploadSucceeds = false;
      final service = EvidenceService(
        gateway: gateway,
        deviceIntegrity: (hash) async => null,
        signCapture: _cannotSign,
      );

      await expectLater(
        service.uploadMedia(
          attempt: _attempt(),
          requirement: _requirement(ActionRequirementKind.audio),
          media: await audio(),
        ),
        throwsA(isA<MediaUploadException>()),
      );
      expect(gateway.calls, ['request-upload', 'upload']);
    });
  });
}
