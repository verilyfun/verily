import 'package:hooks_riverpod/hooks_riverpod.dart';
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
  Future<ActionCaptureChallengeView> createCaptureChallenge({
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String evidenceBindingHash,
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
  Future<ActionCaptureChallengeView> createCaptureChallenge({
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String evidenceBindingHash,
  }) => _client.actionVerification.createCaptureChallenge(
    attemptId: attemptId,
    requirementId: requirementId,
    evidenceBindingHash: evidenceBindingHash,
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

/// Sends proof to the server, bound to this device.
///
/// Every submission first asks the server for a capture challenge bound to
/// the evidence fingerprint, then attaches a Play Integrity token and a
/// device signature that both commit to that exact fingerprint. A token or
/// signature for one capture can never vouch for another.
class EvidenceService {
  const EvidenceService({
    required this._gateway,
    this._deviceIntegrity = requestPlayIntegrityToken,
    this._signCapture = signWithAndroidKeystore,
  });

  final EvidenceGateway _gateway;
  final DeviceIntegrityTokenSource _deviceIntegrity;
  final CaptureSigner _signCapture;

  /// Proves presence at a location requirement's place with [fix].
  Future<EvidenceSubmissionResult> submitLocation({
    required ActionAttemptView attempt,
    required ActionRequirementView requirement,
    required LocationFix fix,
  }) async {
    final integrity = await _bind(
      attempt,
      requirement,
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
        capturePublicKey: integrity.provenance?.publicKey,
        captureKeyId: integrity.provenance?.keyId,
        captureKeyStorage: integrity.provenance?.keyStorage,
      ),
    );
  }

  /// Proves a venue visit with the scanned [code].
  Future<EvidenceSubmissionResult> submitQrCode({
    required ActionAttemptView attempt,
    required ActionRequirementView requirement,
    required String code,
    DateTime? scannedAt,
  }) async {
    final capturedAt = (scannedAt ?? DateTime.now()).toUtc();
    final integrity = await _bind(
      attempt,
      requirement,
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
        capturePublicKey: integrity.provenance?.publicKey,
        captureKeyId: integrity.provenance?.keyId,
        captureKeyStorage: integrity.provenance?.keyStorage,
      ),
    );
  }

  /// Sends a phone-motion trace; the server recomputes the analysis.
  Future<EvidenceSubmissionResult> submitMotion({
    required ActionAttemptView attempt,
    required ActionRequirementView requirement,
    required CapturedMotion motion,
  }) async {
    final integrity = await _bind(
      attempt,
      requirement,
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
        capturePublicKey: integrity.provenance?.publicKey,
        captureKeyId: integrity.provenance?.keyId,
        captureKeyStorage: integrity.provenance?.keyStorage,
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
        capturePublicKey: integrity.provenance?.publicKey,
        captureKeyId: integrity.provenance?.keyId,
        captureKeyStorage: integrity.provenance?.keyStorage,
      ),
    );
  }

  Future<_CaptureIntegrity> _bind(
    ActionAttemptView attempt,
    ActionRequirementView requirement,
    String evidenceBindingHash,
  ) async {
    final challenge = await _gateway.createCaptureChallenge(
      attemptId: attempt.id,
      requirementId: requirement.id,
      evidenceBindingHash: evidenceBindingHash,
    );
    final token = await _deviceIntegrity(challenge.requestHash);
    if (challenge.integrityRequired && (token == null || token.isEmpty)) {
      throw const CaptureIntegrityException(
        CaptureIntegrityFailure.integrityUnavailable,
      );
    }
    final provenance = await _signCapture(
      attemptId: attempt.id.toString(),
      requirementId: requirement.id.toString(),
      requestHash: challenge.requestHash,
      evidenceBindingHash: evidenceBindingHash,
    );
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
  ),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);
