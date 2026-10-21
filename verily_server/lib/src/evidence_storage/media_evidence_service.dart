import 'package:serverpod/serverpod.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/evidence_storage/evidence_integrity_policy.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/evidence_storage/evidence_upload_service.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/moderation/moderation_gate.dart';

/// The private upload flow for video, photo, and audio proof.
///
/// The server derives every object path from authenticated state, signs one
/// short-lived upload for the exact type and size, then reads the stored
/// object end to end to hash it, check its container, and pin its immutable
/// version before the proof is accepted for verification.
class MediaEvidenceService {
  MediaEvidenceService({
    ActionVerificationService? actions,
    EvidenceUploadService? uploads,
    ModerationGate? moderationGate,
    DateTime Function()? clock,
  }) : actions = actions ?? ActionVerificationService(clock: clock),
       uploads = uploads ?? EvidenceUploadService(clock: clock),
       moderationGate = moderationGate ?? const ModerationGate();

  final ActionVerificationService actions;
  final EvidenceUploadService uploads;
  final ModerationGate moderationGate;

  /// Returns a serialized upload description for Serverpod's `FileUploader`.
  ///
  /// A requirement that uses the live challenge word must already have one
  /// issued; the reservation binds that word to this recording.
  Future<String> requestUpload(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String contentType,
    required int byteLength,
  }) async {
    final target = await _ownedMediaRequirement(
      session,
      authUserId: authUserId,
      attemptId: attemptId,
      requirementId: requirementId,
    );
    final type = validatedEvidenceMediaType(
      kind: target.kind,
      contentType: contentType,
      byteLength: byteLength,
    );
    await AccountAccess.requireActive(session, authUserId);
    await moderationGate.preflightAction(
      session,
      target.attempt.actionDefinitionId,
    );
    final path = evidenceStoragePath(
      authUserId: authUserId.toString(),
      attemptId: attemptId.toString(),
      requirementId: requirementId.toString(),
      type: type,
    );
    await uploads.reserve(
      session,
      authUserId: authUserId,
      attemptId: attemptId,
      requirementId: requirementId,
      kind: target.requirement.kind,
      storagePath: path,
      contentType: type.contentType,
      byteLength: byteLength,
      requireSpokenChallenge: target.rule.spokenChallengeRequired,
    );
    // Backblaze versions every PUT and does not implement If-None-Match.
    // Confirmation pins the exact version returned by the inspected read.
    return session.storage.createUploadDescription(
      storageId: evidenceStorageId,
      path: path,
      options: UploadOptions(
        expirationDuration: evidenceUploadUrlLifetime,
        maxFileSize: maxEvidenceBytesFor(target.kind),
        contentLength: byteLength,
        metadata: FileMetadata(contentType: type.contentType),
      ),
    );
  }

  /// Inspects a completed upload and submits its server-measured identity to
  /// the evidence pipeline.
  Future<EvidenceSubmissionResult> confirmUpload(
    Session session, {
    required UuidValue authUserId,
    required MediaUploadConfirmation confirmation,
  }) async {
    final target = await _ownedMediaRequirement(
      session,
      authUserId: authUserId,
      attemptId: confirmation.attemptId,
      requirementId: confirmation.requirementId,
    );
    final type = validatedEvidenceMediaType(
      kind: target.kind,
      contentType: confirmation.contentType,
      byteLength: confirmation.byteLength,
    );
    final reservation = await uploads.reservationForConfirmation(
      session,
      authUserId: authUserId,
      attemptId: confirmation.attemptId,
      requirementId: confirmation.requirementId,
      contentType: type.contentType,
      byteLength: confirmation.byteLength,
    );
    var confirmed = false;
    try {
      final storage = session.serverpod.storage[evidenceStorageId];
      if (storage is! EvidenceObjectAccess) {
        throw StateError('Private evidence storage is not available.');
      }
      final inspection = await (storage! as EvidenceObjectAccess)
          .inspectAndHash(session, reservation.storagePath);
      if (inspection == null) {
        throw StateError('The upload could not be found. Upload it again.');
      }
      if (inspection.byteLength != confirmation.byteLength ||
          !inspection.matchesContentType(type.contentType)) {
        await session.storage.deleteFile(
          storageId: evidenceStorageId,
          path: reservation.storagePath,
        );
        throw StateError('The uploaded file did not match the request.');
      }
      final seal = const EvidenceIntegrityPolicy().sealInspection(
        expectation: EvidenceIntegrityExpectation(
          authUserId: authUserId.toString(),
          attemptId: confirmation.attemptId.toString(),
          requirementId: confirmation.requirementId.toString(),
          kind: target.kind,
          contentType: type.contentType,
          byteLength: confirmation.byteLength,
        ),
        storagePath: reservation.storagePath,
        inspection: inspection,
      );
      final result = await actions.submitMediaEvidence(
        session,
        authUserId: authUserId,
        reservation: reservation,
        seal: seal,
        confirmation: confirmation,
      );
      await uploads.markConfirmed(
        session,
        reservationId: reservation.id!,
        confirmationAttemptCount: reservation.confirmationAttemptCount,
        storageVersionId: seal.storageVersionId,
      );
      confirmed = true;
      return result;
    } finally {
      if (!confirmed) {
        try {
          await uploads.releaseConfirmation(
            session,
            reservationId: reservation.id!,
            confirmationAttemptCount: reservation.confirmationAttemptCount,
          );
        } on Object catch (error, stackTrace) {
          session.log(
            'Failed to release evidence confirmation ${reservation.id}.',
            level: LogLevel.warning,
            exception: error,
            stackTrace: stackTrace,
          );
        }
      }
    }
  }

  Future<_MediaTarget> _ownedMediaRequirement(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) async {
    final attempt = await ActionAttempt.db.findById(session, attemptId);
    if (attempt == null || attempt.participantAuthUserId != authUserId) {
      throw StateError('The action attempt was not found.');
    }
    if (attempt.status != ActionAttemptStatus.collectingEvidence) {
      throw StateError('This action attempt no longer accepts proof.');
    }
    final requirement = await ActionRequirement.db.findById(
      session,
      requirementId,
    );
    final kind = requirement == null ? null : mediaKindOf(requirement.kind);
    if (requirement == null ||
        kind == null ||
        requirement.actionDefinitionId != attempt.actionDefinitionId) {
      throw StateError('The media requirement was not found.');
    }
    final rule = await ActionMediaRule.db.findFirstRow(
      session,
      where: (table) => table.requirementId.equals(requirementId),
    );
    if (rule == null) throw StateError('Media rule is missing.');
    return _MediaTarget(
      attempt: attempt,
      requirement: requirement,
      rule: rule,
      kind: kind,
    );
  }
}

final class _MediaTarget {
  const _MediaTarget({
    required this.attempt,
    required this.requirement,
    required this.rule,
    required this.kind,
  });

  final ActionAttempt attempt;
  final ActionRequirement requirement;
  final ActionMediaRule rule;
  final MediaEvidenceKind kind;
}
