import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/evidence_verification_queue.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/generated/protocol.dart';

const evidenceVerificationRecoveryIdentifier = 'evidence-verification-recovery';
const evidenceVerificationMaximumAttempts = 3;
const _staleAfter = Duration(minutes: 5);

/// Recurring sweep that keeps media verification and completion moving.
///
/// Stale jobs are re-queued; a job that exhausted its retries routes the
/// proof to a person instead; and attempts left in `verifying` after their
/// decisions landed are completed, so a crash between the decision and the
/// completion can never strand a participant.
class EvidenceVerificationRecoveryFutureCall
    extends FutureCall<EvidenceVerificationRecoveryTask> {
  EvidenceVerificationRecoveryFutureCall({
    ActionVerificationService? actions,
    EvidenceVerificationQueue? queue,
    DateTime Function()? clock,
  }) : actions = actions ?? ActionVerificationService(),
       queue = queue ?? const EvidenceVerificationQueue(),
       clock = clock ?? (() => DateTime.now().toUtc());

  final ActionVerificationService actions;
  final EvidenceVerificationQueue queue;
  final DateTime Function() clock;

  Future<void> recover(
    Session session,
    EvidenceVerificationRecoveryTask task,
  ) async {
    if (task.batchSize < 1 || task.batchSize > 500) {
      throw ArgumentError.value(
        task.batchSize,
        'batchSize',
        'Recovery batch size must be between 1 and 500.',
      );
    }
    final now = clock().toUtc();
    final staleBefore = now.subtract(_staleAfter);
    final jobs = await EvidenceVerificationJob.db.find(
      session,
      where: (table) =>
          table.status.inSet({
            EvidenceVerificationJobStatus.queued,
            EvidenceVerificationJobStatus.running,
            EvidenceVerificationJobStatus.failed,
          }) &
          (table.updatedAt < staleBefore),
      orderBy: (table) => table.updatedAt,
      limit: task.batchSize,
    );

    for (final job in jobs) {
      if (job.attemptCount >= evidenceVerificationMaximumAttempts) {
        final routed = await _routeToManualReview(session, job, now);
        if (routed != null) await _complete(session, routed);
        continue;
      }
      final queued = await DatabaseUtil.runInTransactionOrSavepoint(
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
              locked.status == EvidenceVerificationJobStatus.completed ||
              locked.updatedAt.isAfter(staleBefore)) {
            return null;
          }
          return EvidenceVerificationJob.db.updateRow(
            session,
            locked.copyWith(
              status: EvidenceVerificationJobStatus.queued,
              updatedAt: now,
            ),
            transaction: transaction,
          );
        },
      );
      if (queued == null) continue;
      await queue.schedule(
        session,
        evidenceId: queued.evidenceId,
        attempt: queued.attemptCount + 1,
      );
    }

    final stranded = await ActionAttempt.db.find(
      session,
      where: (table) =>
          table.status.equals(ActionAttemptStatus.verifying) &
          (table.updatedAt < staleBefore),
      orderBy: (table) => table.updatedAt,
      limit: task.batchSize,
    );
    for (final attempt in stranded) {
      await _complete(session, attempt.id!);
    }
  }

  /// Completes one attempt the sweep found. A failure is logged as an error
  /// and the sweep moves on, so one broken attempt cannot hold up the rest of
  /// the batch on every run.
  Future<void> _complete(Session session, UuidValue attemptId) async {
    try {
      await actions.completeIfReady(session, attemptId: attemptId);
    } on Object catch (error, stackTrace) {
      session.log(
        'Recovery could not complete attempt $attemptId.',
        level: LogLevel.error,
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Returns the attempt id when this call routed the job.
  Future<UuidValue?> _routeToManualReview(
    Session session,
    EvidenceVerificationJob job,
    DateTime now,
  ) {
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
            locked.status == EvidenceVerificationJobStatus.completed ||
            locked.updatedAt.isAfter(now.subtract(_staleAfter))) {
          return null;
        }
        final evidence = await ActionEvidence.db.findById(
          session,
          locked.evidenceId,
          transaction: transaction,
        );
        await EvidenceDecision.db.insertRow(
          session,
          EvidenceDecision(
            evidenceId: locked.evidenceId,
            status: EvidenceDecisionStatus.manualReview,
            verifierType: 'media-verification-recovery',
            reasonCode: MediaVerificationReason.retryExhausted,
            summary: needsReviewSummary,
            createdAt: now,
          ),
          transaction: transaction,
        );
        await EvidenceVerificationJob.db.updateRow(
          session,
          locked.copyWith(
            status: EvidenceVerificationJobStatus.completed,
            completedAt: now,
            updatedAt: now,
            lastErrorCode: MediaVerificationReason.retryExhausted,
          ),
          transaction: transaction,
        );
        return evidence?.attemptId;
      },
    );
  }
}
