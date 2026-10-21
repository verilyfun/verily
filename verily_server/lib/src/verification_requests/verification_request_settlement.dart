import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/webhooks/app_event_outbox.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/verification_requests/verification_receipts.dart';

/// Reacts when the attempt behind a verification request settles: marks the
/// request completed and queues its `verification_request.completed` event
/// in the same transaction.
class VerificationRequestSettlement {
  const VerificationRequestSettlement({
    this.outbox = const AppEventOutbox(),
  });

  final AppEventOutbox outbox;

  /// Returns the ids of App events queued in [transaction], so the caller can
  /// schedule them after commit.
  ///
  /// Runs inside attempt completion, after the account, attempt, and
  /// action-key locks, so the request row is locked last.
  Future<List<UuidValue>> onAttemptSettled(
    Session session, {
    required ActionAttempt attempt,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final settled = switch (attempt.status) {
      ActionAttemptStatus.verified ||
      ActionAttemptStatus.rejected ||
      ActionAttemptStatus.capacityReached => true,
      _ => false,
    };
    if (!settled) return const [];
    var request = await VerificationRequest.db.findFirstRow(
      session,
      where: (table) => table.attemptId.equals(attempt.id),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (request == null) return const [];
    if (request.status == VerificationRequestStatus.accepted) {
      request = await VerificationRequest.db.updateRow(
        session,
        request.copyWith(
          status: VerificationRequestStatus.completed,
          completedAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    } else if (request.status != VerificationRequestStatus.completed) {
      // A declined or expired request keeps its final status.
      return const [];
    }
    return queueCompletion(
      session,
      request: request,
      attempt: attempt,
      now: now,
      transaction: transaction,
    );
  }

  /// Queues `verification_request.completed` with the final receipt.
  ///
  /// One event per request and outcome: if an appeal later turns a rejection
  /// into a verification, the App hears about the new outcome too.
  Future<List<UuidValue>> queueCompletion(
    Session session, {
    required VerificationRequest request,
    required ActionAttempt? attempt,
    required DateTime now,
    required Transaction transaction,
    VerilyApp? app,
  }) async {
    final target =
        app ??
        await VerilyApp.db.findById(
          session,
          request.appId,
          transaction: transaction,
        );
    if (target == null) return const [];
    final receipt = await issueReceipt(
      session,
      request: request,
      attempt: attempt,
      now: now,
      transaction: transaction,
    );
    if (!receiptStatusIsFinal(receipt.status)) return const [];
    final event = await outbox.enqueue(
      session,
      app: target,
      type: AppEventType.verificationRequestCompleted,
      dedupeKey:
          '${AppEventType.verificationRequestCompleted}:${request.id}:'
          '${receipt.status}',
      data: {
        'request': request.id.toString(),
        'status': receipt.status,
        // Absent only when this server has no receipt key; the App can fetch
        // the receipt once it does.
        'receipt': ?receipt.token,
      },
      now: now,
      transaction: transaction,
    );
    return [?event?.id];
  }
}
