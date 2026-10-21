// The scheduler seam has one operation; generated copyWith clears nullable
// fields with an explicit null.
// ignore_for_file: one_member_abstracts, avoid_redundant_argument_values

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/apps/webhooks/app_attempt_events.dart';
import 'package:verily_server/src/apps/webhooks/app_event_outbox.dart';
import 'package:verily_server/src/generated/future_calls.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';

/// Retries of one payout before it stops and waits for an operator.
const rewardPayoutMaxAttempts = 6;

/// A release that has been in flight this long is presumed lost and retried.
/// Retrying is safe: the escrow pays each index at most once.
const rewardPayoutReleaseLease = Duration(minutes: 10);

/// What a verified completion earns from its action key's reward pool.
final class RewardPoolDecision {
  const RewardPoolDecision({required this.pool, required this.outcome});

  /// No reward applies: no pool, or one that never got funded.
  const RewardPoolDecision.none() : pool = null, outcome = null;

  /// The locked pool row; null when no reward applies.
  final RewardPool? pool;
  final RewardOutcome? outcome;
}

/// Schedules the durable release of one payout.
abstract interface class RewardPayoutScheduler {
  Future<void> schedule(
    Session session,
    UuidValue payoutId, {
    Duration delay = Duration.zero,
  });
}

/// Production scheduler: one Serverpod future call per release attempt.
class FutureCallRewardPayoutScheduler implements RewardPayoutScheduler {
  const FutureCallRewardPayoutScheduler();

  @override
  Future<void> schedule(
    Session session,
    UuidValue payoutId, {
    Duration delay = Duration.zero,
  }) async {
    try {
      await session.serverpod.futureCalls
          .callWithDelay(delay)
          .rewardPayout
          .release(RewardPayoutTask(payoutId: payoutId));
    } on Object catch (error, stackTrace) {
      // The recovery sweep schedules any reserved payout that missed its
      // call, so a scheduling failure delays a payout but never loses it.
      session.log(
        'Failed to schedule reward payout $payoutId.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Reserves payout indexes inside attempt completion and releases them
/// through the escrow gateway as a durable, idempotent job.
///
/// Lock order is the pool row, then payout rows. The release job never locks
/// an account or attempt, so it cannot deadlock with completion, which locks
/// the participant's account, the attempt, the action key, and then the pool.
class RewardPayoutService {
  RewardPayoutService({
    this._configuration,
    RewardPayoutScheduler? scheduler,
    this.appPayoutEvents = const AppPayoutEvents(),
    this.appEventOutbox = const AppEventOutbox(),
    DateTime Function()? clock,
  }) : scheduler = scheduler ?? const FutureCallRewardPayoutScheduler(),
       clock = clock ?? (() => DateTime.now().toUtc());

  /// Queues `payout.released` for the App behind the rewarded action.
  final AppPayoutEvents appPayoutEvents;
  final AppEventOutbox appEventOutbox;

  final RewardConfiguration? _configuration;
  final RewardPayoutScheduler scheduler;
  final DateTime Function() clock;

  RewardConfiguration get configuration =>
      _configuration ?? RewardRuntime.current;

  /// Locks the action key's pool and decides what a completion by
  /// [participantAuthUserId] would earn, without reserving anything.
  Future<RewardPoolDecision> evaluate(
    Session session, {
    required ActionDefinition action,
    required UuidValue participantAuthUserId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final pool = await RewardPool.db.findFirstRow(
      session,
      where: (table) =>
          table.creatorAuthUserId.equals(action.creatorAuthUserId) &
          table.actionKey.equals(action.actionKey),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (pool == null ||
        pool.status == RewardPoolStatus.draft ||
        pool.status == RewardPoolStatus.awaitingFunding) {
      return const RewardPoolDecision.none();
    }
    if (pool.status != RewardPoolStatus.funded ||
        !now.isBefore(pool.expiresAt)) {
      return RewardPoolDecision(pool: pool, outcome: RewardOutcome.poolEnded);
    }
    final wins = await RewardPayout.db.count(
      session,
      where: (table) =>
          table.poolId.equals(pool.id) &
          table.recipientAuthUserId.equals(participantAuthUserId),
      transaction: transaction,
    );
    if (wins >= pool.maxWinsPerAccount) {
      return RewardPoolDecision(
        pool: pool,
        outcome: RewardOutcome.accountLimitReached,
      );
    }
    if (pool.payoutsReserved >= pool.maxPayouts) {
      return RewardPoolDecision(pool: pool, outcome: RewardOutcome.poolEmpty);
    }
    return RewardPoolDecision(pool: pool, outcome: RewardOutcome.won);
  }

  /// Whether a payout from [pool] needs proof a person accepted.
  bool requiresPersonReview(RewardPool pool) =>
      pool.amountPerPayout > configuration.reviewThresholdAtoms;

  /// Reserves the next payout index for [attempt]. The caller holds the pool
  /// row lock from [evaluate] in the same transaction, so two completions
  /// can never take the same index.
  Future<RewardPayout> reserve(
    Session session, {
    required RewardPool pool,
    required ActionAttempt attempt,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final wallet = await PayoutWallet.db.findFirstRow(
      session,
      where: (table) => table.authUserId.equals(attempt.participantAuthUserId),
      transaction: transaction,
    );
    final payout = await RewardPayout.db.insertRow(
      session,
      RewardPayout(
        poolId: pool.id!,
        attemptId: attempt.id!,
        recipientAuthUserId: attempt.participantAuthUserId,
        payoutIndex: pool.payoutsReserved,
        amount: pool.amountPerPayout,
        status: wallet == null
            ? RewardPayoutStatus.awaitingWallet
            : RewardPayoutStatus.reserved,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await RewardPool.db.updateRow(
      session,
      pool.copyWith(payoutsReserved: pool.payoutsReserved + 1, updatedAt: now),
      transaction: transaction,
    );
    return payout;
  }

  /// Schedules the release of [attemptId]'s payout, if it has one waiting.
  /// Call after the reserving transaction commits.
  Future<void> scheduleForAttempt(
    Session session, {
    required UuidValue attemptId,
  }) async {
    final payout = await RewardPayout.db.findFirstRow(
      session,
      where: (table) => table.attemptId.equals(attemptId),
    );
    if (payout?.status == RewardPayoutStatus.reserved) {
      await scheduler.schedule(session, payout!.id!);
    }
  }

  /// Releases one payout. Safe to run any number of times, concurrently or
  /// after a crash: a claimed release freezes its recipient, and a retry of
  /// the same index is either paid or resolved from the released bitmap.
  Future<void> release(Session session, UuidValue payoutId) async {
    final claim = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) => _claim(session, payoutId, transaction),
    );
    if (claim == null) return;

    final gateway = configuration.gateway;
    final RewardReleaseOutcome outcome;
    try {
      outcome = claim.checkBitmapOnly
          ? (await gateway.isPayoutReleased(
                  pool: claim.pool,
                  payoutIndex: claim.payout.payoutIndex,
                )
                ? const RewardAlreadyReleased()
                : const RewardReleaseFailed(
                    'refund_window_reached',
                    retryable: false,
                  ))
          : await gateway.releasePayout(
              pool: claim.pool,
              payoutIndex: claim.payout.payoutIndex,
              recipientWallet: claim.payout.recipientWallet!,
            );
    } on Object catch (error, stackTrace) {
      session.log(
        'Reward release for payout $payoutId failed in the gateway.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
      // An unreadable bitmap proves nothing: keep the lease so recovery asks
      // again instead of expiring a payout that may have landed.
      if (claim.checkBitmapOnly) return;
      await _settle(
        session,
        claim,
        const RewardReleaseFailed('escrow_gateway_error', retryable: true),
      );
      return;
    }
    await _settle(session, claim, outcome);
  }

  Future<_ReleaseClaim?> _claim(
    Session session,
    UuidValue payoutId,
    Transaction transaction,
  ) async {
    final initial = await RewardPayout.db.findById(
      session,
      payoutId,
      transaction: transaction,
    );
    if (initial == null) return null;
    final pool = await RewardPool.db.findFirstRow(
      session,
      where: (table) => table.id.equals(initial.poolId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final payout = await RewardPayout.db.findFirstRow(
      session,
      where: (table) => table.id.equals(payoutId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (pool == null || payout == null) return null;
    final now = clock().toUtc();
    final staleRelease =
        payout.status == RewardPayoutStatus.releasing &&
        (payout.releaseStartedAt == null ||
            !payout.releaseStartedAt!.isAfter(
              now.subtract(rewardPayoutReleaseLease),
            ));
    if (payout.status != RewardPayoutStatus.reserved && !staleRelease) {
      return null;
    }
    final cutoff = pool.refundAfter.subtract(RewardBounds.releaseSafetyMargin);
    if (!now.isBefore(cutoff)) {
      if (staleRelease) {
        // A lost release may still have landed; only the bitmap can say.
        return _ReleaseClaim(pool: pool, payout: payout, checkBitmapOnly: true);
      }
      await _update(session, payout, now, transaction, (current) {
        return current.copyWith(
          status: RewardPayoutStatus.expired,
          lastErrorCode: 'refund_window_reached',
        );
      });
      return null;
    }
    // A plain read: locking the account here would invert the lock order of
    // attempt completion, which locks the account before the pool.
    final account = await AuthUser.db.findById(
      session,
      payout.recipientAuthUserId,
      transaction: transaction,
    );
    if (account == null || account.blocked) {
      await _update(session, payout, now, transaction, (current) {
        return current.copyWith(
          status: RewardPayoutStatus.heldForReview,
          lastErrorCode: 'recipient_inactive',
        );
      });
      return null;
    }
    var recipientWallet = payout.recipientWallet;
    if (recipientWallet == null) {
      final wallet = await PayoutWallet.db.findFirstRow(
        session,
        where: (table) => table.authUserId.equals(payout.recipientAuthUserId),
        transaction: transaction,
      );
      if (wallet == null) {
        await _update(session, payout, now, transaction, (current) {
          return current.copyWith(status: RewardPayoutStatus.awaitingWallet);
        });
        return null;
      }
      recipientWallet = wallet.walletAddress;
    }
    final claimed = await RewardPayout.db.updateRow(
      session,
      payout.copyWith(
        status: RewardPayoutStatus.releasing,
        recipientWallet: recipientWallet,
        attemptCount: payout.attemptCount + 1,
        releaseStartedAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    return _ReleaseClaim(pool: pool, payout: claimed, checkBitmapOnly: false);
  }

  Future<void> _settle(
    Session session,
    _ReleaseClaim claim,
    RewardReleaseOutcome outcome,
  ) async {
    var retryDelay = Duration.zero;
    var retry = false;
    final appEventIds = <UuidValue>[];
    await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final pool = await RewardPool.db.findFirstRow(
          session,
          where: (table) => table.id.equals(claim.pool.id),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        final payout = await RewardPayout.db.findFirstRow(
          session,
          where: (table) => table.id.equals(claim.payout.id),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        // Another worker re-claimed this payout; its own settle decides.
        if (pool == null ||
            payout == null ||
            payout.status != RewardPayoutStatus.releasing ||
            payout.attemptCount != claim.payout.attemptCount) {
          return;
        }
        final now = clock().toUtc();
        switch (outcome) {
          case RewardReleased(:final signature):
            appEventIds.addAll(
              await _markReleased(session, pool, payout, now, transaction, (
                signature: signature,
              )),
            );
          case RewardAlreadyReleased():
            appEventIds.addAll(
              await _markReleased(session, pool, payout, now, transaction, (
                signature: payout.releaseSignature,
              )),
            );
          case RewardReleaseFailed(:final code, :final retryable):
            final exhausted =
                !retryable || payout.attemptCount >= rewardPayoutMaxAttempts;
            await RewardPayout.db.updateRow(
              session,
              payout.copyWith(
                status: claim.checkBitmapOnly
                    ? RewardPayoutStatus.expired
                    : exhausted
                    ? RewardPayoutStatus.failed
                    : RewardPayoutStatus.reserved,
                lastErrorCode: code,
                updatedAt: now,
              ),
              transaction: transaction,
            );
            if (!exhausted && !claim.checkBitmapOnly) {
              retry = true;
              retryDelay = Duration(
                seconds: 15 * (1 << (payout.attemptCount - 1).clamp(0, 6)),
              );
            }
        }
      },
    );
    if (retry) {
      await scheduler.schedule(session, claim.payout.id!, delay: retryDelay);
    }
    for (final eventId in appEventIds) {
      await appEventOutbox.schedule(session, eventId);
    }
  }

  /// Marks the payout released and returns the App events it queued.
  Future<List<UuidValue>> _markReleased(
    Session session,
    RewardPool pool,
    RewardPayout payout,
    DateTime now,
    Transaction transaction,
    ({String? signature}) release,
  ) async {
    final released = await RewardPayout.db.updateRow(
      session,
      payout.copyWith(
        status: RewardPayoutStatus.released,
        releaseSignature: release.signature,
        releasedAt: now,
        lastErrorCode: null,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await RewardPool.db.updateRow(
      session,
      pool.copyWith(payoutsReleased: pool.payoutsReleased + 1, updatedAt: now),
      transaction: transaction,
    );
    return appPayoutEvents.onPayoutReleased(
      session,
      payout: released,
      pool: pool,
      now: now,
      transaction: transaction,
    );
  }

  Future<void> _update(
    Session session,
    RewardPayout payout,
    DateTime now,
    Transaction transaction,
    RewardPayout Function(RewardPayout current) change,
  ) {
    return RewardPayout.db.updateRow(
      session,
      change(payout).copyWith(updatedAt: now),
      transaction: transaction,
    );
  }

  /// Moves every payout waiting on [authUserId]'s wallet back to the release
  /// queue and schedules it. Called right after a wallet is linked.
  Future<int> releaseAwaitingWallet(
    Session session, {
    required UuidValue authUserId,
  }) async {
    final now = clock().toUtc();
    final waiting = await RewardPayout.db.updateWhere(
      session,
      columnValues: (table) => [
        table.status(RewardPayoutStatus.reserved),
        table.updatedAt(now),
      ],
      where: (table) =>
          table.recipientAuthUserId.equals(authUserId) &
          table.status.equals(RewardPayoutStatus.awaitingWallet),
    );
    for (final payout in waiting) {
      await scheduler.schedule(session, payout.id!);
    }
    return waiting.length;
  }

  /// Bounded maintenance: ends and closes pools whose windows passed,
  /// expires payouts that can no longer be paid, re-queues payouts that
  /// missed their call or lost their release, and wakes payouts whose
  /// recipient has since linked a wallet.
  Future<void> recover(Session session, {required int batchSize}) async {
    if (batchSize < 1 || batchSize > 500) {
      throw ArgumentError.value(
        batchSize,
        'batchSize',
        'Recovery batch size must be between 1 and 500.',
      );
    }
    final now = clock().toUtc();
    await RewardPool.db.updateWhere(
      session,
      columnValues: (table) => [
        table.status(RewardPoolStatus.ended),
        table.endedAt(now),
        table.updatedAt(now),
      ],
      where: (table) =>
          table.status.equals(RewardPoolStatus.funded) &
          (table.expiresAt <= now),
    );
    final closing = await RewardPool.db.find(
      session,
      where: (table) =>
          table.status.inSet({
            RewardPoolStatus.funded,
            RewardPoolStatus.ended,
          }) &
          (table.refundAfter <= now),
      limit: batchSize,
    );
    for (final pool in closing) {
      await DatabaseUtil.runInTransactionOrSavepoint(
        session.db,
        null,
        (transaction) async {
          final locked = await RewardPool.db.findFirstRow(
            session,
            where: (table) => table.id.equals(pool.id),
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          );
          if (locked == null || locked.status == RewardPoolStatus.closed) {
            return;
          }
          await RewardPayout.db.updateWhere(
            session,
            columnValues: (table) => [
              table.status(RewardPayoutStatus.expired),
              table.lastErrorCode('refund_window_reached'),
              table.updatedAt(now),
            ],
            where: (table) =>
                table.poolId.equals(locked.id) &
                table.status.inSet({
                  RewardPayoutStatus.reserved,
                  RewardPayoutStatus.awaitingWallet,
                  RewardPayoutStatus.heldForReview,
                  RewardPayoutStatus.failed,
                }),
            transaction: transaction,
          );
          await RewardPool.db.updateRow(
            session,
            locked.copyWith(
              status: RewardPoolStatus.closed,
              closedAt: now,
              updatedAt: now,
            ),
            transaction: transaction,
          );
        },
      );
    }

    final linkedRecipients = await session.db.unsafeQuery(
      '''
SELECT DISTINCT p."recipientAuthUserId"::text
FROM "verily_reward_payout" AS p
JOIN "verily_payout_wallet" AS w ON w."authUserId" = p."recipientAuthUserId"
WHERE p."status" = @awaitingWallet
LIMIT @limit;
''',
      parameters: QueryParameters.named({
        'awaitingWallet': RewardPayoutStatus.awaitingWallet.name,
        'limit': batchSize,
      }),
    );
    for (final row in linkedRecipients) {
      await releaseAwaitingWallet(
        session,
        authUserId: UuidValue.withValidation(row[0]! as String),
      );
    }

    final due = await RewardPayout.db.find(
      session,
      where: (table) =>
          (table.status.equals(RewardPayoutStatus.reserved) &
              (table.updatedAt < now.subtract(const Duration(minutes: 2)))) |
          (table.status.equals(RewardPayoutStatus.releasing) &
              (table.releaseStartedAt <
                  now.subtract(rewardPayoutReleaseLease))),
      orderBy: (table) => table.updatedAt,
      limit: batchSize,
    );
    for (final payout in due) {
      await scheduler.schedule(session, payout.id!);
    }
  }

  Future<List<RewardPayoutView>> listMine(
    Session session, {
    required UuidValue authUserId,
    int limit = 50,
  }) async {
    final payouts = await RewardPayout.db.find(
      session,
      where: (table) => table.recipientAuthUserId.equals(authUserId),
      orderBy: (table) => table.createdAt.desc(),
      limit: limit.clamp(1, 100),
    );
    if (payouts.isEmpty) return const [];
    final pools = await RewardPool.db.find(
      session,
      where: (table) => table.id.inSet(<UuidValue>{
        for (final payout in payouts) payout.poolId,
      }),
    );
    final attempts = await ActionAttempt.db.find(
      session,
      where: (table) => table.id.inSet(<UuidValue>{
        for (final payout in payouts) payout.attemptId,
      }),
    );
    final actions = await ActionDefinition.db.find(
      session,
      where: (table) => table.id.inSet(<UuidValue>{
        for (final attempt in attempts) attempt.actionDefinitionId,
      }),
    );
    final poolById = {for (final pool in pools) pool.id!: pool};
    final attemptById = {for (final attempt in attempts) attempt.id!: attempt};
    final actionById = {for (final action in actions) action.id!: action};
    return [
      for (final payout in payouts)
        if (poolById[payout.poolId] case final pool?)
          RewardPayoutView(
            id: payout.id!,
            attemptId: payout.attemptId,
            actionTitle:
                actionById[attemptById[payout.attemptId]?.actionDefinitionId]
                    ?.title ??
                '',
            cluster: pool.cluster,
            tokenSymbol: pool.tokenSymbol,
            decimals: pool.decimals,
            amount: payout.amount,
            status: payout.status,
            recipientWallet: payout.recipientWallet,
            releaseSignature: payout.releaseSignature,
            createdAt: payout.createdAt,
            updatedAt: payout.updatedAt,
            payableUntil: pool.refundAfter.subtract(
              RewardBounds.releaseSafetyMargin,
            ),
          ),
    ];
  }
}

final class _ReleaseClaim {
  const _ReleaseClaim({
    required this.pool,
    required this.payout,
    required this.checkBitmapOnly,
  });

  final RewardPool pool;
  final RewardPayout payout;

  /// The refund window has opened on a lost release: only read the bitmap.
  final bool checkBitmapOnly;
}
