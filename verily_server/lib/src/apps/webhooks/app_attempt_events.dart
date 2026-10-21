import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/app_subjects.dart';
import 'package:verily_server/src/apps/webhooks/app_event_outbox.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/verification_requests/verification_request_settlement.dart';

/// Every reaction to an attempt reaching a status, run inside the
/// transaction that settled it.
class AttemptSettlementHooks {
  const AttemptSettlementHooks({
    this.appEvents = const AppAttemptEvents(),
    this.verificationRequests = const VerificationRequestSettlement(),
  });

  final AppAttemptEvents appEvents;
  final VerificationRequestSettlement verificationRequests;

  /// Returns the ids of App events queued in [transaction].
  Future<List<UuidValue>> onAttemptSettled(
    Session session, {
    required ActionAttempt attempt,
    required DateTime now,
    required Transaction transaction,
  }) async => [
    ...await appEvents.onAttemptSettled(
      session,
      attempt: attempt,
      now: now,
      transaction: transaction,
    ),
    ...await verificationRequests.onAttemptSettled(
      session,
      attempt: attempt,
      now: now,
      transaction: transaction,
    ),
  ];
}

/// Queues `attempt.verified` and `attempt.rejected` for the App that
/// confirms an action's `externalApp` requirement.
///
/// The event names the attempt, the action key and revision, the
/// participant's pairwise subject, and the outcome. It never carries
/// evidence, places, wallets, or account ids.
class AppAttemptEvents {
  const AppAttemptEvents({this.outbox = const AppEventOutbox()});

  final AppEventOutbox outbox;

  Future<List<UuidValue>> onAttemptSettled(
    Session session, {
    required ActionAttempt attempt,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final type = switch (attempt.status) {
      ActionAttemptStatus.verified => AppEventType.attemptVerified,
      ActionAttemptStatus.rejected => AppEventType.attemptRejected,
      _ => null,
    };
    if (type == null) return const [];
    final app = await appForAction(
      session,
      actionDefinitionId: attempt.actionDefinitionId,
      transaction: transaction,
    );
    if (app == null) return const [];
    final action = await ActionDefinition.db.findById(
      session,
      attempt.actionDefinitionId,
      transaction: transaction,
    );
    if (action == null) return const [];
    final link = await appLinkFor(
      session,
      appId: app.id!,
      authUserId: attempt.participantAuthUserId,
      now: now,
      transaction: transaction,
    );
    final event = await outbox.enqueue(
      session,
      app: app,
      type: type,
      dedupeKey: '$type:${attempt.id}',
      data: {
        'attempt': attempt.id.toString(),
        'action': action.actionKey,
        'revision': action.revision,
        'subject': link.subject,
        'period': attempt.periodKey,
        'status': attempt.status.name,
        if (attempt.status == ActionAttemptStatus.rejected)
          'reason': attempt.rejectionCode,
        'settledAt': (attempt.verifiedAt ?? attempt.updatedAt)
            .toUtc()
            .toIso8601String(),
      },
      now: now,
      transaction: transaction,
    );
    return [?event?.id];
  }
}

/// Queues `payout.released` for the App whose action the payout rewarded.
///
/// The event carries the amount and mint but never the recipient wallet or
/// the release signature: either would let the App link a pairwise subject
/// to an on-chain identity.
class AppPayoutEvents {
  const AppPayoutEvents({this.outbox = const AppEventOutbox()});

  final AppEventOutbox outbox;

  Future<List<UuidValue>> onPayoutReleased(
    Session session, {
    required RewardPayout payout,
    required RewardPool pool,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final attempt = await ActionAttempt.db.findById(
      session,
      payout.attemptId,
      transaction: transaction,
    );
    if (attempt == null) return const [];
    final app = await appForAction(
      session,
      actionDefinitionId: attempt.actionDefinitionId,
      transaction: transaction,
    );
    if (app == null) return const [];
    final link = await appLinkFor(
      session,
      appId: app.id!,
      authUserId: attempt.participantAuthUserId,
      now: now,
      transaction: transaction,
    );
    final event = await outbox.enqueue(
      session,
      app: app,
      type: AppEventType.payoutReleased,
      dedupeKey: '${AppEventType.payoutReleased}:${payout.id}',
      data: {
        'payout': payout.id.toString(),
        'attempt': attempt.id.toString(),
        'action': pool.actionKey,
        'subject': link.subject,
        'amountAtoms': payout.amount.toString(),
        'mint': pool.mint,
        'releasedAt': now.toUtc().toIso8601String(),
      },
      now: now,
      transaction: transaction,
    );
    return [?event?.id];
  }
}

/// The App bound to an action through its `externalApp` requirement, if any.
Future<VerilyApp?> appForAction(
  Session session, {
  required UuidValue actionDefinitionId,
  Transaction? transaction,
}) async {
  final requirements = await ActionRequirement.db.find(
    session,
    where: (table) =>
        table.actionDefinitionId.equals(actionDefinitionId) &
        table.kind.equals(ActionRequirementKind.externalApp),
    transaction: transaction,
  );
  if (requirements.isEmpty) return null;
  final rule = await ActionExternalRule.db.findFirstRow(
    session,
    where: (table) => table.requirementId.inSet(<UuidValue>{
      for (final requirement in requirements) requirement.id!,
    }),
    transaction: transaction,
  );
  if (rule == null) return null;
  return VerilyApp.db.findById(session, rule.appId, transaction: transaction);
}
