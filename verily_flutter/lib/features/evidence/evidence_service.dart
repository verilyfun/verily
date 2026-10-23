import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/core/api_client.dart';
import 'package:verily_flutter/features/evidence/capture_provenance_service.dart';
import 'package:verily_flutter/features/evidence/captured_media.dart';
import 'package:verily_flutter/features/evidence/device_integrity_service.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/features/evidence/motion_capture_service.dart';

/// Why a capture could not be vouched for by this device.
enum CaptureIntegrityFailure {
  /// The server requires a Play Integrity token and the device gave none.
  integrityUnavailable,

  /// The server requires a device signature and the device could not sign.
  signatureUnavailable,
}

class CaptureIntegrityException implements Exception {
  const CaptureIntegrityException(this.failure);

  final CaptureIntegrityFailure failure;

  @override
  String toString() => 'CaptureIntegrityException(${failure.name})';
}

/// The upload did not reach storage. The capture is still on the device and
/// can be sent again.
class MediaUploadException implements Exception {
  const MediaUploadException();
}

/// The narrow slice of the server the evidence pipeline needs. The Serverpod
/// client implements it directly; tests fake it.
abstract interface class EvidenceGateway {
  Future<ActionCaptureChallengeView> beginCapture({
    required UuidValue attemptId,
    required UuidValue requirementId,
  });
  Future<EvidenceSubmissionResult> submitEvidence(ActionEvidenceInput input);

  /// Returns the upload description for [uploadMedia].
  Future<String> requestMediaUpload({
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String contentType,
    required int byteLength,
  });
  Future<bool> uploadMedia(String uploadDescription, CapturedMedia media);
  Future<EvidenceSubmissionResult> confirmMediaUpload(
    MediaUploadConfirmation confirmation,
  );
}

class ServerpodEvidenceGateway implements EvidenceGateway {
  const ServerpodEvidenceGateway(this._client);

  final Client _client;

  @override
  Future<ActionCaptureChallengeView> beginCapture({
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) => _client.actionVerification.beginCapture(
    attemptId: attemptId,
    requirementId: requirementId,
  );

  @override
  Future<EvidenceSubmissionResult> submitEvidence(ActionEvidenceInput input) =>
      _client.actionVerification.submitEvidence(input);

  @override
  Future<String> requestMediaUpload({
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String contentType,
    required int byteLength,
  }) => _client.actionVerification.requestMediaUpload(
    attemptId: attemptId,
    requirementId: requirementId,
    contentType: contentType,
    byteLength: byteLength,
  );

  @override
  Future<bool> uploadMedia(String uploadDescription, CapturedMedia media) =>
      FileUploader(
        uploadDescription,
      ).upload(media.file.openRead(), media.byteLength);

  @override
  Future<EvidenceSubmissionResult> confirmMediaUpload(
    MediaUploadConfirmation confirmation,
  ) => _client.actionVerification.confirmMediaUpload(confirmation);
}

/// A capture window the server opened before anything was recorded, and
/// the device key being readied for it.
class CaptureSession {
  const CaptureSession._({
    required this.attemptId,
    required this.requirementId,
    required this.challenge,
    required this._keyReady,
  });

  final UuidValue attemptId;
  final UuidValue requirementId;
  final ActionCaptureChallengeView challenge;
  final Future<bool> _keyReady;

  /// Whether the window has closed; proof captured in it can no longer be
  /// sent, so the person captures again in a new one.
  bool isExpiredAt(DateTime now) => !challenge.expiresAt.isAfter(now);
}

/// Sends proof to the server, bound to this device.
///
/// Before anything is captured, [beginCapture] asks the server to open a
/// capture window and readies the device key: a fresh attested key on
/// Android, the account's registered App Attest key on iOS. Every submission
/// then attaches a Play Integrity token and a signature from that key, both
/// committing to the window and the exact evidence fingerprint. A token or
/// signature for one capture can never vouch for another, nor for anything
/// recorded before the window opened.
class EvidenceService {
  const EvidenceService({
    required this._gateway,
    required this._captureKeys,
    this._deviceIntegrity = requestPlayIntegrityToken,
  });

  final EvidenceGateway _gateway;
  final DeviceIntegrityTokenSource _deviceIntegrity;
  final CaptureKeyStore _captureKeys;

  /// Opens a capture window for [requirement]. Call it before the camera,
  /// microphone, sensors, or scanner start; the key is readied while they
  /// warm up.
  Future<CaptureSession> beginCapture({
    required ActionAttemptView attempt,
    required ActionRequirementView requirement,
  }) async {
    final challenge = await _gateway.beginCapture(
      attemptId: attempt.id,
      requirementId: requirement.id,
    );
    return CaptureSession._(
      attemptId: attempt.id,
      requirementId: requirement.id,
      challenge: challenge,
      keyReady: _captureKeys.prepare(
        captureId: challenge.id.toString(),
        attestationChallenge: captureKeyAttestationChallenge(
          captureChallenge: challenge.captureChallenge,
          attemptId: attempt.id.toString(),
        ),
      ),
    );
  }

  /// Proves presence at a location requirement's place with [fix], taken
  /// inside [session].
  Future<EvidenceSubmissionResult> submitLocation({
    required ActionAttemptView attempt,
    required ActionRequirementView requirement,
    required CaptureSession session,
    required LocationFix fix,
  }) async {
    final integrity = await _bind(
      attempt,
      requirement,
      session,
      locationEvidenceBindingHash(
        capturedAt: fix.capturedAt,
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracyMeters: fix.accuracyMeters,
      ),
    );
    return _gateway.submitEvidence(
      ActionEvidenceInput(
        attemptId: attempt.id,
        requirementId: requirement.id,
        capturedAt: fix.capturedAt,
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracyMeters: fix.accuracyMeters,
        captureChallengeId: integrity.challengeId,
        deviceIntegrityToken: integrity.token,
        captureManifest: integrity.provenance?.manifest,
        captureSignature: integrity.provenance?.signature,
        captureCertificateChain: integrity.provenance?.certificateChain,
        captureAppAttestKeyId: integrity.provenance?.appAttestKeyId,
        captureDeviceCheckToken: integrity.provenance?.deviceCheckToken,
      ),
    );
  }

  /// Proves a venue visit with the [code] scanned inside [session].
  Future<EvidenceSubmissionResult> submitQrCode({
    required ActionAttemptView attempt,
    required ActionRequirementView requirement,
    required CaptureSession session,
    required String code,
    DateTime? scannedAt,
  }) async {
    final capturedAt = (scannedAt ?? DateTime.now()).toUtc();
    final integrity = await _bind(
      attempt,
      requirement,
      session,
      qrEvidenceBindingHash(capturedAt: capturedAt, code: code),
    );
    return _gateway.submitEvidence(
      ActionEvidenceInput(
        attemptId: attempt.id,
        requirementId: requirement.id,
        capturedAt: capturedAt,
        qrCode: code,
        captureChallengeId: integrity.challengeId,
        deviceIntegrityToken: integrity.token,
        captureManifest: integrity.provenance?.manifest,
        captureSignature: integrity.provenance?.signature,
        captureCertificateChain: integrity.provenance?.certificateChain,
        captureAppAttestKeyId: integrity.provenance?.appAttestKeyId,
        captureDeviceCheckToken: integrity.provenance?.deviceCheckToken,
      ),
    );
  }

  /// Sends a phone-motion trace measured inside [session]; the server
  /// recomputes the analysis.
  Future<EvidenceSubmissionResult> submitMotion({
    required ActionAttemptView attempt,
    required ActionRequirementView requirement,
    required CaptureSession session,
    required CapturedMotion motion,
  }) async {
    final integrity = await _bind(
      attempt,
      requirement,
      session,
      motionEvidenceBindingHash(
        capturedAt: motion.capturedAt,
        traceSha256: motion.traceSha256,
        sampleCount: motion.samples.length,
        durationMilliseconds: motion.analysis.durationMilliseconds,
      ),
    );
    return _gateway.submitEvidence(
      ActionEvidenceInput(
        attemptId: attempt.id,
        requirementId: requirement.id,
        capturedAt: motion.capturedAt,
        motionSamples: [
          for (final sample in motion.samples)
            ActionMotionSample(
              elapsedMicroseconds: sample.elapsedMicroseconds,
              gyroscopeX: sample.gyroscopeX,
              gyroscopeY: sample.gyroscopeY,
              gyroscopeZ: sample.gyroscopeZ,
              accelerationX: sample.accelerationX,
              accelerationY: sample.accelerationY,
              accelerationZ: sample.accelerationZ,
            ),
        ],
        captureChallengeId: integrity.challengeId,
        deviceIntegrityToken: integrity.token,
        captureManifest: integrity.provenance?.manifest,
        captureSignature: integrity.provenance?.signature,
        captureCertificateChain: integrity.provenance?.certificateChain,
        captureAppAttestKeyId: integrity.provenance?.appAttestKeyId,
        captureDeviceCheckToken: integrity.provenance?.deviceCheckToken,
      ),
    );
  }

  /// Uploads a photo, video, or audio capture and queues it for checking.
  ///
  /// The returned result usually has a null `status`: the server's worker
  /// decides the proof and completes the attempt on its own, so the screen
  /// shows that the proof is being checked and refreshes the attempt.
  Future<EvidenceSubmissionResult> uploadMedia({
    required ActionAttemptView attempt,
    required ActionRequirementView requirement,
    required CaptureSession session,
    required CapturedMedia media,
  }) async {
    final description = await _gateway.requestMediaUpload(
      attemptId: attempt.id,
      requirementId: requirement.id,
      contentType: media.contentType,
      byteLength: media.byteLength,
    );
    if (!await _gateway.uploadMedia(description, media)) {
      throw const MediaUploadException();
    }
    final integrity = await _bind(
      attempt,
      requirement,
      session,
      mediaEvidenceBindingHash(
        kind: media.kind,
        capturedAt: media.capturedAt,
        sha256Digest: media.sha256Digest,
        byteLength: media.byteLength,
        durationSeconds: media.durationSeconds,
        contentType: media.contentType,
      ),
    );
    return _gateway.confirmMediaUpload(
      MediaUploadConfirmation(
        attemptId: attempt.id,
        requirementId: requirement.id,
        contentType: media.contentType,
        byteLength: media.byteLength,
        durationSeconds: media.kind == MediaEvidenceKind.photo
            ? null
            : media.durationSeconds,
        capturedAt: media.capturedAt,
        deviceRepetitionCount: media.deviceRepetitionCount,
        deviceTrackerVersion: media.deviceTrackerVersion,
        // The phone's quick-check result is advice for calibration, and the
        // server ignores it for a rule without a quick check.
        deviceLocalCheck: requirement.localCheck == null
            ? null
            : media.deviceLocalCheck,
        captureChallengeId: integrity.challengeId,
        deviceIntegrityToken: integrity.token,
        captureManifest: integrity.provenance?.manifest,
        captureSignature: integrity.provenance?.signature,
        captureCertificateChain: integrity.provenance?.certificateChain,
        captureAppAttestKeyId: integrity.provenance?.appAttestKeyId,
        captureDeviceCheckToken: integrity.provenance?.deviceCheckToken,
      ),
    );
  }

  Future<_CaptureIntegrity> _bind(
    ActionAttemptView attempt,
    ActionRequirementView requirement,
    CaptureSession session,
    String evidenceBindingHash,
  ) async {
    if (session.attemptId != attempt.id ||
        session.requirementId != requirement.id) {
      throw ArgumentError.value(
        session,
        'session',
        'Belongs to another proof.',
      );
    }
    final challenge = session.challenge;
    final requestHash = captureIntegrityRequestHash(
      attemptId: attempt.id.toString(),
      requirementId: requirement.id.toString(),
      captureChallenge: challenge.captureChallenge,
      evidenceBindingHash: evidenceBindingHash,
    );
    final token = await _deviceIntegrity(requestHash);
    if (challenge.integrityRequired && (token == null || token.isEmpty)) {
      throw const CaptureIntegrityException(
        CaptureIntegrityFailure.integrityUnavailable,
      );
    }
    final provenance = await session._keyReady
        ? await _captureKeys.sign(
            captureId: challenge.id.toString(),
            manifest: captureProvenanceManifest(
              attemptId: attempt.id.toString(),
              requirementId: requirement.id.toString(),
              requestHash: requestHash,
              evidenceBindingHash: evidenceBindingHash,
            ),
          )
        : null;
    if (challenge.signatureRequired && provenance == null) {
      throw const CaptureIntegrityException(
        CaptureIntegrityFailure.signatureUnavailable,
      );
    }
    return _CaptureIntegrity(
      challengeId: challenge.id,
      token: token,
      provenance: provenance,
    );
  }
}

class _CaptureIntegrity {
  const _CaptureIntegrity({
    required this.challengeId,
    required this.token,
    required this.provenance,
  });

  final UuidValue challengeId;
  final String? token;
  final CaptureProvenanceProof? provenance;
}

final evidenceServiceProvider = Provider<EvidenceService>(
  (ref) => EvidenceService(
    gateway: ServerpodEvidenceGateway(ref.watch(verilyClientProvider)),
    captureKeys: ref.watch(captureKeyStoreProvider),
  ),
);

/// The device's capture signer: per-window attested keys on Android, the
/// account's App Attest key on iOS, and none elsewhere.
final captureKeyStoreProvider = Provider<CaptureKeyStore>((ref) {
  if (kIsWeb) return const UnavailableCaptureKeyStore();
  final client = ref.watch(verilyClientProvider);
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => const AndroidCaptureKeyStore(),
    TargetPlatform.iOS => AppAttestCaptureKeyStore(
      registrar: ServerpodAppAttestRegistrar(client),
      currentAccount: () => client.auth.authInfo?.authUserId,
    ),
    _ => const UnavailableCaptureKeyStore(),
  };
});

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);
