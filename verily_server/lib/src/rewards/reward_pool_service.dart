import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/action_key_lock.dart';
import 'package:verily_server/src/auth/solana_auth_verify.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';

/// Validated reward terms, normalized the way the escrow stores them.
final class ValidatedRewardTerms {
  const ValidatedRewardTerms({
    required this.amountPerPayout,
    required this.maxPayouts,
    required this.maxWinsPerAccount,
    required this.expiresAt,
    required this.refundDelaySeconds,
  });

  final int amountPerPayout;
  final int maxPayouts;
  final int maxWinsPerAccount;

  /// Whole seconds, because the escrow stores unix seconds.
  final DateTime expiresAt;
  final int refundDelaySeconds;

  DateTime get refundAfter =>
      expiresAt.add(Duration(seconds: refundDelaySeconds));
}

/// The escrowed reward of a creator's action key: terms, funding, and the
/// public summary. Payout reservation and release live in the payout service.
class RewardPoolService {
  RewardPoolService({
    this._configuration,
    DateTime Function()? clock,
  }) : clock = clock ?? (() => DateTime.now().toUtc());

  final RewardConfiguration? _configuration;
  final DateTime Function() clock;

  RewardConfiguration get configuration =>
      _configuration ?? RewardRuntime.current;

  /// Validates a creator's terms against the escrow program's bounds.
  ValidatedRewardTerms validateTerms(RewardTermsDraft draft, DateTime now) {
    if (draft.amountPerPayout < 1 ||
        draft.amountPerPayout > RewardBounds.maxAmountPerPayoutAtoms) {
      throw ArgumentError.value(
        draft.amountPerPayout,
        'amountPerPayout',
        'Each payout must be between 1 atom and 1,000,000 USDC.',
      );
    }
    if (draft.maxPayouts < 1 || draft.maxPayouts > RewardBounds.maxPayouts) {
      throw ArgumentError.value(
        draft.maxPayouts,
        'maxPayouts',
        'A reward pays between 1 and ${RewardBounds.maxPayouts} completions.',
      );
    }
    if (draft.maxWinsPerAccount < 1 ||
        draft.maxWinsPerAccount > RewardBounds.maxWinsPerAccount) {
      throw ArgumentError.value(
        draft.maxWinsPerAccount,
        'maxWinsPerAccount',
        'One account can win between 1 and '
            '${RewardBounds.maxWinsPerAccount} payouts.',
      );
    }
    if (draft.refundDelayDays < RewardBounds.minRefundDelayDays ||
        draft.refundDelayDays > RewardBounds.maxRefundDelayDays) {
      throw ArgumentError.value(
        draft.refundDelayDays,
        'refundDelayDays',
        'The refund delay must be between ${RewardBounds.minRefundDelayDays} '
            'and ${RewardBounds.maxRefundDelayDays} days.',
      );
    }
    final expiresAt = _wholeSeconds(draft.expiresAt);
    if (expiresAt.isBefore(now.add(RewardBounds.minLifetime)) ||
        expiresAt.isAfter(now.add(RewardBounds.maxLifetime))) {
      throw ArgumentError.value(
        draft.expiresAt,
        'expiresAt',
        'A reward must stay open for between an hour and a year.',
      );
    }
    return ValidatedRewardTerms(
      amountPerPayout: draft.amountPerPayout,
      maxPayouts: draft.maxPayouts,
      maxWinsPerAccount: draft.maxWinsPerAccount,
      expiresAt: expiresAt,
      refundDelaySeconds: draft.refundDelayDays * Duration.secondsPerDay,
    );
  }

  /// The pool for one creator's action key, locked when [lock] is set.
  Future<RewardPool?> poolFor(
    Session session, {
    required UuidValue creatorAuthUserId,
    required String actionKey,
    Transaction? transaction,
    bool lock = false,
  }) {
    return RewardPool.db.findFirstRow(
      session,
      where: (table) =>
          table.creatorAuthUserId.equals(creatorAuthUserId) &
          table.actionKey.equals(actionKey),
      transaction: transaction,
      lockMode: lock ? LockMode.forUpdate : null,
    );
  }

  /// Applies a saved draft's reward terms. Callers hold the action-key lock.
  ///
  /// Terms stay editable only while the pool is a draft. Once funding starts
  /// they are frozen: a draft may repeat them, but never change them. Saving
  /// a revision without terms removes an unfunded draft reward and keeps a
  /// funded one, because a funded escrow cannot be withdrawn by a draft.
  Future<void> applyDraftTerms(
    Session session, {
    required UuidValue creatorAuthUserId,
    required String actionKey,
    required ValidatedRewardTerms? terms,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final pool = await poolFor(
      session,
      creatorAuthUserId: creatorAuthUserId,
      actionKey: actionKey,
      transaction: transaction,
      lock: true,
    );
    if (terms == null) {
      if (pool != null && pool.status == RewardPoolStatus.draft) {
        await RewardPool.db.deleteRow(session, pool, transaction: transaction);
      }
      return;
    }
    if (pool == null) {
      final token = configuration.token;
      await RewardPool.db.insertRow(
        session,
        RewardPool(
          creatorAuthUserId: creatorAuthUserId,
          actionKey: actionKey,
          cluster: configuration.cluster,
          mint: token.mint,
          tokenSymbol: token.symbol,
          decimals: token.decimals,
          amountPerPayout: terms.amountPerPayout,
          maxPayouts: terms.maxPayouts,
          maxWinsPerAccount: terms.maxWinsPerAccount,
          expiresAt: terms.expiresAt,
          refundDelaySeconds: terms.refundDelaySeconds,
          refundAfter: terms.refundAfter,
          status: RewardPoolStatus.draft,
          createdAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      return;
    }
    if (pool.status == RewardPoolStatus.draft) {
      final token = configuration.token;
      await RewardPool.db.updateRow(
        session,
        pool.copyWith(
          cluster: configuration.cluster,
          mint: token.mint,
          tokenSymbol: token.symbol,
          decimals: token.decimals,
          amountPerPayout: terms.amountPerPayout,
          maxPayouts: terms.maxPayouts,
          maxWinsPerAccount: terms.maxWinsPerAccount,
          expiresAt: terms.expiresAt,
          refundDelaySeconds: terms.refundDelaySeconds,
          refundAfter: terms.refundAfter,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      return;
    }
    final unchanged =
        pool.amountPerPayout == terms.amountPerPayout &&
        pool.maxPayouts == terms.maxPayouts &&
        pool.maxWinsPerAccount == terms.maxWinsPerAccount &&
        pool.refundDelaySeconds == terms.refundDelaySeconds &&
        _wholeSeconds(pool.expiresAt) == terms.expiresAt;
    if (!unchanged) {
      throw ActionAuthoringException(
        reason: ActionAuthoringProblem.rewardTermsLocked,
        message: 'Reward terms cannot change once funding has started.',
      );
    }
  }

  /// Refuses publication while the action key's reward is not funded and
  /// verified. A pool that ended or closed no longer blocks: the action keeps
  /// running and completions record that the reward has ended.
  Future<void> assertPublishable(
    Session session, {
    required UuidValue creatorAuthUserId,
    required String actionKey,
    required Transaction transaction,
  }) async {
    final pool = await poolFor(
      session,
      creatorAuthUserId: creatorAuthUserId,
      actionKey: actionKey,
      transaction: transaction,
    );
    if (pool == null) return;
    if (pool.status == RewardPoolStatus.draft ||
        pool.status == RewardPoolStatus.awaitingFunding) {
      throw ActionAuthoringException(
        reason: ActionAuthoringProblem.rewardNotFunded,
        message: 'Fund and verify the reward escrow before publishing.',
      );
    }
  }

  /// Freezes the terms, derives the escrow, and returns the unsigned
  /// `OpenEscrow` transaction for the creator's linked payout wallet.
  Future<RewardFundingPlan> prepareFunding(
    Session session, {
    required UuidValue creatorAuthUserId,
    required UuidValue actionId,
  }) async {
    final gateway = configuration.gateway;
    if (!gateway.isAvailable) throw _rewardsUnavailable();
    final now = clock().toUtc();
    final pool = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          creatorAuthUserId,
          transaction: transaction,
        );
        final action = await _ownedAction(
          session,
          creatorAuthUserId: creatorAuthUserId,
          actionId: actionId,
          transaction: transaction,
        );
        await ActionKeyLock.acquire(
          session,
          creatorAuthUserId: creatorAuthUserId,
          actionKey: action.actionKey,
          transaction: transaction,
        );
        final pool = await _requiredPool(
          session,
          creatorAuthUserId: creatorAuthUserId,
          actionKey: action.actionKey,
          transaction: transaction,
        );
        if (pool.status == RewardPoolStatus.awaitingFunding) return pool;
        if (pool.status != RewardPoolStatus.draft) {
          throw RewardException(
            problem: RewardProblem.poolNotAwaitingFunding,
            message: 'This reward is already funded or has ended.',
          );
        }
        if (!pool.expiresAt.isAfter(now.add(RewardBounds.minLifetime))) {
          throw RewardException(
            problem: RewardProblem.poolEnded,
            message: 'Choose a later end time before funding.',
          );
        }
        final wallet = await PayoutWallet.db.findFirstRow(
          session,
          where: (table) => table.authUserId.equals(creatorAuthUserId),
          transaction: transaction,
        );
        if (wallet == null) {
          throw RewardException(
            problem: RewardProblem.payoutWalletRequired,
            message: 'Link a payout wallet to fund rewards and get refunds.',
          );
        }
        return RewardPool.db.updateRow(
          session,
          pool.copyWith(
            status: RewardPoolStatus.awaitingFunding,
            creatorWallet: wallet.walletAddress,
            arbiterAddress: gateway.arbiterAddress(pool.cluster),
            escrowAddress: gateway.deriveEscrowAddress(
              cluster: pool.cluster,
              creatorWallet: wallet.walletAddress,
              poolId: pool.id!,
            ),
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    return RewardFundingPlan(
      poolId: pool.id!,
      cluster: pool.cluster,
      escrowAddress: pool.escrowAddress!,
      creatorWallet: pool.creatorWallet!,
      arbiterAddress: pool.arbiterAddress!,
      mint: pool.mint,
      tokenSymbol: pool.tokenSymbol,
      decimals: pool.decimals,
      totalAtoms: pool.amountPerPayout * pool.maxPayouts,
      expiresAt: pool.expiresAt,
      refundAfter: pool.refundAfter,
      unsignedTransaction: await gateway.buildOpenEscrowTransaction(pool),
    );
  }

  /// Marks the pool funded only after reading the escrow from chain state
  /// and matching every field. [signature] is kept for audit; it is not the
  /// trust anchor.
  Future<RewardPoolView> confirmFunding(
    Session session, {
    required UuidValue creatorAuthUserId,
    required UuidValue actionId,
    required String signature,
  }) async {
    final gateway = configuration.gateway;
    if (!gateway.isAvailable) throw _rewardsUnavailable();
    final normalizedSignature = signature.trim();
    try {
      decodeBase58Signature(normalizedSignature);
    } on FormatException {
      throw ArgumentError.value(
        signature,
        'signature',
        'Send the base58 signature of the funding transaction.',
      );
    }
    await AccountAccess.requireActive(session, creatorAuthUserId);
    final action = await _ownedAction(
      session,
      creatorAuthUserId: creatorAuthUserId,
      actionId: actionId,
    );
    final candidate = await _requiredPool(
      session,
      creatorAuthUserId: creatorAuthUserId,
      actionKey: action.actionKey,
    );
    if (candidate.status == RewardPoolStatus.funded) {
      return _poolView(candidate);
    }
    if (candidate.status != RewardPoolStatus.awaitingFunding) {
      throw RewardException(
        problem: RewardProblem.poolNotAwaitingFunding,
        message: 'Prepare funding before confirming it.',
      );
    }
    // Chain I/O happens outside the transaction; terms are frozen while the
    // pool awaits funding, so the row cannot change meaning meanwhile.
    final state = await gateway.readEscrow(candidate);
    if (state == null) {
      throw RewardException(
        problem: RewardProblem.escrowNotFound,
        message: 'The escrow is not on chain yet. Try again in a moment.',
      );
    }
    final mismatches = rewardEscrowMismatches(candidate, state);
    if (mismatches.isNotEmpty) {
      session.log(
        'Reward escrow ${candidate.escrowAddress} did not match pool '
        '${candidate.id}: ${mismatches.join(', ')}.',
        level: LogLevel.warning,
      );
      throw RewardException(
        problem: RewardProblem.escrowMismatch,
        message: 'The escrow on chain does not match these reward terms.',
      );
    }
    final now = clock().toUtc();
    final funded = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await ActionKeyLock.acquire(
          session,
          creatorAuthUserId: creatorAuthUserId,
          actionKey: action.actionKey,
          transaction: transaction,
        );
        final pool = await _requiredPool(
          session,
          creatorAuthUserId: creatorAuthUserId,
          actionKey: action.actionKey,
          transaction: transaction,
        );
        if (pool.status == RewardPoolStatus.funded) return pool;
        if (pool.status != RewardPoolStatus.awaitingFunding ||
            pool.escrowAddress != candidate.escrowAddress) {
          throw RewardException(
            problem: RewardProblem.poolNotAwaitingFunding,
            message: 'This reward changed. Refresh and try again.',
          );
        }
        return RewardPool.db.updateRow(
          session,
          pool.copyWith(
            status: RewardPoolStatus.funded,
            fundingSignature: normalizedSignature,
            fundedAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    return _poolView(funded);
  }

  /// Stops new payouts now and returns the creator-signed `EndEarly`
  /// transaction. Reserved payouts still release until the refund window.
  Future<RewardEndPlan> endEarly(
    Session session, {
    required UuidValue creatorAuthUserId,
    required UuidValue actionId,
  }) async {
    final gateway = configuration.gateway;
    if (!gateway.isAvailable) throw _rewardsUnavailable();
    final now = _wholeSeconds(clock().toUtc());
    final ended = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          creatorAuthUserId,
          transaction: transaction,
        );
        final action = await _ownedAction(
          session,
          creatorAuthUserId: creatorAuthUserId,
          actionId: actionId,
          transaction: transaction,
        );
        await ActionKeyLock.acquire(
          session,
          creatorAuthUserId: creatorAuthUserId,
          actionKey: action.actionKey,
          transaction: transaction,
        );
        final pool = await _requiredPool(
          session,
          creatorAuthUserId: creatorAuthUserId,
          actionKey: action.actionKey,
          transaction: transaction,
        );
        if (pool.status != RewardPoolStatus.funded) {
          throw RewardException(
            problem: RewardProblem.poolEnded,
            message: 'Only a funded, running reward can end early.',
          );
        }
        // The program moves expiry to min(expiry, chain now) and recomputes
        // the refund window. The server's clock reads earlier than the chain
        // will, so the stored window is never later than the chain's.
        final expiresAt = pool.expiresAt.isBefore(now) ? pool.expiresAt : now;
        return RewardPool.db.updateRow(
          session,
          pool.copyWith(
            status: RewardPoolStatus.ended,
            expiresAt: expiresAt,
            refundAfter: expiresAt.add(
              Duration(seconds: pool.refundDelaySeconds),
            ),
            endedAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    return RewardEndPlan(
      poolId: ended.id!,
      expiresAt: ended.expiresAt,
      refundAfter: ended.refundAfter,
      unsignedTransaction: await gateway.buildEndEarlyTransaction(ended),
    );
  }

  Future<RewardPoolView?> getPool(
    Session session, {
    required UuidValue creatorAuthUserId,
    required UuidValue actionId,
  }) async {
    final action = await _ownedAction(
      session,
      creatorAuthUserId: creatorAuthUserId,
      actionId: actionId,
    );
    final pool = await poolFor(
      session,
      creatorAuthUserId: creatorAuthUserId,
      actionKey: action.actionKey,
    );
    return pool == null ? null : _poolView(pool);
  }

  /// Public summaries for [actions], keyed by action id. Unfunded draft
  /// rewards are visible only to their creator.
  Future<Map<UuidValue, RewardSummary>> summaries(
    Session session, {
    required List<ActionDefinition> actions,
    required UuidValue viewerAuthUserId,
  }) async {
    if (actions.isEmpty) return const {};
    final creatorIds = {for (final action in actions) action.creatorAuthUserId};
    final keys = {for (final action in actions) action.actionKey};
    final pools = await RewardPool.db.find(
      session,
      where: (table) =>
          table.creatorAuthUserId.inSet(creatorIds) &
          table.actionKey.inSet(keys),
    );
    if (pools.isEmpty) return const {};
    final poolByKey = {
      for (final pool in pools) (pool.creatorAuthUserId, pool.actionKey): pool,
    };
    final viewerPayouts = await RewardPayout.db.find(
      session,
      where: (table) =>
          table.poolId.inSet({for (final pool in pools) pool.id!}) &
          table.recipientAuthUserId.equals(viewerAuthUserId),
    );
    final winsByPool = <UuidValue, int>{};
    for (final payout in viewerPayouts) {
      winsByPool.update(payout.poolId, (wins) => wins + 1, ifAbsent: () => 1);
    }
    return {
      for (final action in actions)
        if (poolByKey[(action.creatorAuthUserId, action.actionKey)]
            case final pool?
            when pool.status != RewardPoolStatus.draft &&
                    pool.status != RewardPoolStatus.awaitingFunding ||
                action.creatorAuthUserId == viewerAuthUserId)
          action.id!: RewardSummary(
            cluster: pool.cluster,
            mint: pool.mint,
            tokenSymbol: pool.tokenSymbol,
            decimals: pool.decimals,
            amountPerPayout: pool.amountPerPayout,
            maxPayouts: pool.maxPayouts,
            payoutsRemaining: pool.maxPayouts - pool.payoutsReserved,
            maxWinsPerAccount: pool.maxWinsPerAccount,
            myWins: winsByPool[pool.id] ?? 0,
            status: pool.status,
            expiresAt: pool.expiresAt,
            escrowAddress: pool.escrowAddress,
          ),
    };
  }

  Future<ActionDefinition> _ownedAction(
    Session session, {
    required UuidValue creatorAuthUserId,
    required UuidValue actionId,
    Transaction? transaction,
  }) async {
    final action = await ActionDefinition.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(actionId) &
          table.creatorAuthUserId.equals(creatorAuthUserId),
      transaction: transaction,
    );
    if (action == null) {
      throw StateError('Only the creator can manage this reward.');
    }
    return action;
  }

  Future<RewardPool> _requiredPool(
    Session session, {
    required UuidValue creatorAuthUserId,
    required String actionKey,
    Transaction? transaction,
  }) async {
    final pool = await poolFor(
      session,
      creatorAuthUserId: creatorAuthUserId,
      actionKey: actionKey,
      transaction: transaction,
      lock: transaction != null,
    );
    if (pool == null) {
      throw RewardException(
        problem: RewardProblem.poolNotFound,
        message: 'This action has no reward.',
      );
    }
    return pool;
  }
}

RewardException _rewardsUnavailable() => RewardException(
  problem: RewardProblem.rewardsUnavailable,
  message: 'Escrowed rewards are not available on this server yet.',
);

RewardPoolView _poolView(RewardPool pool) => RewardPoolView(
  poolId: pool.id!,
  status: pool.status,
  cluster: pool.cluster,
  mint: pool.mint,
  tokenSymbol: pool.tokenSymbol,
  decimals: pool.decimals,
  amountPerPayout: pool.amountPerPayout,
  maxPayouts: pool.maxPayouts,
  maxWinsPerAccount: pool.maxWinsPerAccount,
  payoutsReserved: pool.payoutsReserved,
  payoutsReleased: pool.payoutsReleased,
  expiresAt: pool.expiresAt,
  refundAfter: pool.refundAfter,
  creatorWallet: pool.creatorWallet,
  escrowAddress: pool.escrowAddress,
  fundingSignature: pool.fundingSignature,
  fundedAt: pool.fundedAt,
);

DateTime _wholeSeconds(DateTime value) {
  final utc = value.toUtc();
  return DateTime.fromMillisecondsSinceEpoch(
    utc.millisecondsSinceEpoch -
        utc.millisecondsSinceEpoch % Duration.millisecondsPerSecond,
    isUtc: true,
  );
}
