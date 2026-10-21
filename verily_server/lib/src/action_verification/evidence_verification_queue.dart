import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/future_calls.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Durable outbox for media verification.
///
/// The job row is inserted in the same transaction as its evidence, so a
/// committed proof always has a job. The future call is scheduled only after
/// that commit; if scheduling fails, the recovery sweep re-queues the job.
class EvidenceVerificationQueue {
  const EvidenceVerificationQueue();

  Future<EvidenceVerificationJob> insertJob(
    Session session, {
    required UuidValue evidenceId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final inserted = await EvidenceVerificationJob.db.insert(
      session,
      [
        EvidenceVerificationJob(
          evidenceId: evidenceId,
          status: EvidenceVerificationJobStatus.queued,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      transaction: transaction,
      ignoreConflicts: true,
    );
    final job =
        inserted.firstOrNull ??
        await EvidenceVerificationJob.db.findFirstRow(
          session,
          where: (table) => table.evidenceId.equals(evidenceId),
          transaction: transaction,
        );
    if (job == null) {
      throw StateError('Media verification could not be queued.');
    }
    return job;
  }

  Future<void> schedule(
    Session session, {
    required UuidValue evidenceId,
    int attempt = 1,
  }) async {
    try {
      await session.serverpod.futureCalls
          .callWithDelay(
            Duration.zero,
            identifier: 'evidence-verification:$evidenceId:$attempt',
          )
          .evidenceVerification
          .verify(EvidenceVerificationTask(evidenceId: evidenceId));
    } on Object catch (error, stackTrace) {
      session.log(
        'Failed to schedule media verification for $evidenceId.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }
}
