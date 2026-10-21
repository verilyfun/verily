import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_models.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_replay.dart';
import 'package:verily_server/src/action_verification/local_check/mp_local_check_replayer.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/action_verification/openrouter_media_evidence_verifier.dart';
import 'package:verily_server/src/action_verification/production_ai_deployment.dart';
import 'package:verily_server/src/evidence_storage/evidence_integrity_policy.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/inference/inference_reservation_service.dart';

/// Builds the verifier for one job. [reserveCall] must be invoked before
/// each external model request.
typedef MediaVerifierFactory = MediaEvidenceVerifier Function(
  Session session,
  ReserveVerificationCall reserveCall,
  http.Client httpClient,
);

/// Runs one durable media verification job and then completes the attempt.
///
/// The decision and its model votes commit in one transaction with the job's
/// completion. Completion runs afterwards on the participant's behalf, so a
/// verified recording finishes its attempt (and reserves any payout) without
/// the participant coming back. A completion that cannot run yet, for example
/// under a safety hold, is retried by the recovery sweep; the decision itself
/// is never lost.
class EvidenceVerificationWorker {
  EvidenceVerificationWorker({
    MediaVerifierFactory? verifierFactory,
    InferenceReservationService? reservations,
    ActionVerificationService? actions,
    LocalCheckReplayer? localCheckReplayer,
    LocalCheckEvidenceReader? readLocalCheckEvidence,
    DateTime Function()? clock,
  }) : verifierFactory = verifierFactory ?? configuredMediaVerifier,
       localCheckReplayer =
           localCheckReplayer ??
           MpLocalCheckReplayer.fromEnvironment(Platform.environment),
       readLocalCheckEvidence = readLocalCheckEvidence ?? readPinnedEvidence,
       reservations =
           reservations ??
           InferenceReservationService(
             policy: productionInferenceCostPolicyFromEnvironment(
               Platform.environment,
             ),
           ),
       actions = actions ?? ActionVerificationService(),
       clock = clock ?? (() => DateTime.now().toUtc());

  final MediaVerifierFactory verifierFactory;
  final InferenceReservationService reservations;
  final ActionVerificationService actions;

  /// Replays phone-only local checks with the pinned MediaPipe model.
  final LocalCheckReplayer localCheckReplayer;
  final LocalCheckEvidenceReader readLocalCheckEvidence;
  final DateTime Function() clock;

  Future<void> verify(Session session, UuidValue evidenceId) async {
    final job = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final current = await EvidenceVerificationJob.db.findFirstRow(
          session,
          where: (table) => table.evidenceId.equals(evidenceId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (current == null ||
            current.status == EvidenceVerificationJobStatus.completed) {
          return null;
        }
        final now = clock().toUtc();
        return EvidenceVerificationJob.db.updateRow(
          session,
          current.copyWith(
            status: EvidenceVerificationJobStatus.running,
            attemptCount: current.attemptCount + 1,
            startedAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    if (job == null) return;

    final ActionEvidence evidence;
    try {
      final loaded = await ActionEvidence.db.findById(session, evidenceId);
      if (loaded == null) throw StateError('Evidence was not found.');
      evidence = loaded;
      final result = await _verify(session, evidence, job);
      await _commit(session, job: job, evidence: evidence, result: result);
    } on Object catch (error, stackTrace) {
      session.log(
        'Media verification job failed for $evidenceId.',
        level: LogLevel.error,
        exception: error,
        stackTrace: stackTrace,
      );
      await EvidenceVerificationJob.db.updateRow(
        session,
        job.copyWith(
          status: EvidenceVerificationJobStatus.failed,
          updatedAt: clock().toUtc(),
          lastErrorCode: 'verification_worker_failed',
        ),
      );
      return;
    }
    await actions.completeIfReady(session, attemptId: evidence.attemptId);
  }

  Future<MediaEvidenceVerification> _verify(
    Session session,
    ActionEvidence evidence,
    EvidenceVerificationJob job,
  ) async {
    final attempt = await ActionAttempt.db.findById(
      session,
      evidence.attemptId,
    );
    if (attempt == null) throw StateError('Action attempt was not found.');
    final mediaKind = mediaKindOf(evidence.kind);
    if (mediaKind == null) throw StateError('Evidence is not media.');
    // The persisted identity must still match the server-derived path and
    // the reservation's type and size before any verifier sees it.
    final seal = const EvidenceIntegrityPolicy().validatePersistedBinding(
      expectation: EvidenceIntegrityExpectation(
        authUserId: attempt.participantAuthUserId.toString(),
        attemptId: evidence.attemptId.toString(),
        requirementId: evidence.requirementId.toString(),
        kind: mediaKind,
        contentType: evidence.mimeType ?? '',
        byteLength: evidence.byteLength ?? 0,
      ),
      storagePath: evidence.storagePath ?? '',
      storageVersionId: evidence.storageVersionId ?? '',
      sha256Digest: evidence.sha256Digest ?? '',
      byteLength: evidence.byteLength ?? 0,
      contentType: evidence.mimeType ?? '',
    );
    final rule = await ActionMediaRule.db.findFirstRow(
      session,
      where: (table) => table.requirementId.equals(evidence.requirementId),
    );
    if (rule == null) throw StateError('Media verification policy is missing.');
    if (rule.spokenChallengeRequired &&
        (evidence.spokenChallengeWord?.isEmpty ?? true)) {
      throw StateError('The proof lost its challenge word.');
    }

    // A local check is replayed first with the pinned model. It decides on
    // its own unless a spoken word must also be heard; when it cannot run,
    // the AI policy decides. The phone's own result is never consulted.
    final localCheck = localCheckOf(rule);
    final localModel = localCheck?.task.model;
    final replay = localCheck == null
        ? null
        : await _replayLocalCheck(session, localCheck, localModel!, seal);
    if (replay != null) {
      final decided = decideLocalCheck(
        model: localModel!,
        check: localCheck!,
        replay: replay,
        spokenChallengeRequired: rule.spokenChallengeRequired,
      );
      if (decided != null) return decided;
    }

    var callSequence = 0;
    Future<void> reserveCall(String modelId) {
      final sequence = callSequence++;
      // Commits before network I/O. Retries and council members share the
      // attempt's caps but each holds its own durable reservation.
      return reservations.reserve(
        session,
        actionAttemptId: evidence.attemptId,
        callReference: '${job.id}:${job.attemptCount}:$sequence',
        modelId: modelId,
      );
    }

    final httpClient = http.Client();
    try {
      final decision = await verifierFactory(session, reserveCall, httpClient)
          .verify(
            session,
            MediaVerificationRequest(
              rule: rule,
              storagePath: seal.storagePath,
              storageVersionId: seal.storageVersionId,
              mimeType: seal.contentType,
              sha256Digest: seal.sha256Digest,
              byteLength: seal.byteLength,
              durationSeconds: evidence.durationSeconds,
              capturedAt: evidence.capturedAt,
              spokenChallengeWord: rule.spokenChallengeRequired
                  ? evidence.spokenChallengeWord
                  : null,
            ),
          );
      return replay == null
          ? decision
          : withLocalCheckReplay(
              decision,
              model: localModel!,
              check: localCheck!,
              replay: replay,
            );
    } finally {
      httpClient.close();
    }
  }

  /// Reads the sealed evidence bytes and replays [check] over them. Every
  /// failure becomes [LocalCheckReplayUnavailable], so the AI policy decides.
  Future<LocalCheckReplay> _replayLocalCheck(
    Session session,
    ActionLocalCheck check,
    LocalCheckModel model,
    EvidenceIntegritySeal seal,
  ) async {
    try {
      final bytes = await readLocalCheckEvidence(
        session,
        storagePath: seal.storagePath,
        sha256Digest: seal.sha256Digest,
        byteLength: seal.byteLength,
      );
      return await localCheckReplayer.replay(
        check: check,
        model: model,
        media: bytes,
        mimeType: seal.contentType,
      );
    } on LocalCheckUnavailableException catch (error) {
      return LocalCheckReplayUnavailable(error.code);
    } on Object catch (error, stackTrace) {
      session.log(
        'Local check replay failed for ${seal.storagePath}.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
      return const LocalCheckReplayUnavailable(
        LocalCheckUnavailableCode.replayFailed,
      );
    }
  }

  Future<void> _commit(
    Session session, {
    required EvidenceVerificationJob job,
    required ActionEvidence evidence,
    required MediaEvidenceVerification result,
  }) {
    final now = clock().toUtc();
    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final locked = await EvidenceVerificationJob.db.findFirstRow(
          session,
          where: (table) => table.id.equals(job.id),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (locked == null ||
            locked.status == EvidenceVerificationJobStatus.completed) {
          return;
        }
        final decision = await EvidenceDecision.db.insertRow(
          session,
          EvidenceDecision(
            evidenceId: evidence.id!,
            status: result.status,
            verifierType: result.verifierType,
            modelName: result.modelName,
            modelVersion: result.modelVersion,
            confidence: result.confidence,
            reasonCode: result.reasonCode,
            summary: result.summary,
            createdAt: now,
          ),
          transaction: transaction,
        );
        if (result.votes.isNotEmpty) {
          await EvidenceVerificationVote.db.insert(
            session,
            [
              for (final vote in result.votes)
                EvidenceVerificationVote(
                  decisionId: decision.id!,
                  evidenceId: evidence.id!,
                  modelId: vote.modelId,
                  resolvedModelId: vote.resolvedModelId,
                  providerName: vote.providerName,
                  responseId: vote.responseId,
                  verdict: vote.verdict.name,
                  spokenChallengeVerdict: vote.spokenChallengeVerdict?.name,
                  confidence: vote.confidence,
                  latencyMilliseconds: vote.latencyMilliseconds,
                  inputTokens: vote.inputTokens,
                  outputTokens: vote.outputTokens,
                  costCredits: vote.costCredits,
                  errorCode: vote.errorCode,
                  createdAt: now,
                ),
            ],
            transaction: transaction,
          );
        }
        await EvidenceVerificationJob.db.updateRow(
          session,
          locked.copyWith(
            status: EvidenceVerificationJobStatus.completed,
            completedAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
  }
}

/// The verifier selected by `VERILY_MEDIA_VERIFIER_MODE`. Cloud and
/// OpenRouter modes need the private storage to mint pinned review links.
MediaEvidenceVerifier configuredMediaVerifier(
  Session session,
  ReserveVerificationCall reserveCall,
  http.Client httpClient,
) {
  final configuration = MediaEvidenceVerifierConfiguration.fromEnvironment(
    Platform.environment,
    token: session.serverpod.getPassword('mediaVerifierToken'),
    openRouterApiKey: session.serverpod.getPassword('openRouterApiKey'),
  );
  if (configuration.mode == mediaVerifierManualMode) {
    return const ManualReviewMediaEvidenceVerifier();
  }
  final storage = session.serverpod.storage[evidenceStorageId];
  if (storage is! EvidenceObjectAccess) {
    throw StateError(
      'Private evidence storage is unavailable to the verifier.',
    );
  }
  final access = storage! as EvidenceObjectAccess;
  return configuration.usesOpenRouterVerifier
      ? OpenRouterMediaEvidenceVerifier(
          configuration: configuration,
          storage: access,
          httpClient: httpClient,
          reserveCall: reserveCall,
        )
      : CloudMediaEvidenceVerifier(
          configuration: configuration,
          storage: access,
          httpClient: httpClient,
          reserveCall: reserveCall,
        );
}
