import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';
import 'package:verily_server/src/rewards/reward_pool_service.dart';

/// Escrowed rewards: creator funding and ending, participant payouts.
///
/// Creator methods re-derive ownership from the authenticated account and
/// the action id. Funding is confirmed from chain state, never from the
/// client's word.
class RewardsEndpoint extends Endpoint {
  RewardsEndpoint({
    RewardPoolService? poolService,
    RewardPayoutService? payoutService,
  }) : poolService = poolService ?? RewardPoolService(),
       payoutService = payoutService ?? RewardPayoutService();

  final RewardPoolService poolService;
  final RewardPayoutService payoutService;

  @override
  bool get requireLogin => true;

  /// The creator's view of an action's reward; null when it has none.
  Future<RewardPoolView?> getRewardPool(
    Session session, {
    required UuidValue actionId,
  }) {
    return poolService.getPool(
      session,
      creatorAuthUserId: session.authenticated!.authUserId,
      actionId: actionId,
    );
  }

  /// Freezes the reward terms and returns the transaction the creator's
  /// linked payout wallet signs to open the escrow.
  Future<RewardFundingPlan> prepareRewardFunding(
    Session session, {
    required UuidValue actionId,
  }) {
    return poolService.prepareFunding(
      session,
      creatorAuthUserId: session.authenticated!.authUserId,
      actionId: actionId,
    );
  }

  /// Verifies the escrow on chain and marks the reward funded.
  Future<RewardPoolView> confirmRewardFunding(
    Session session, {
    required UuidValue actionId,
    required String signature,
  }) {
    return poolService.confirmFunding(
      session,
      creatorAuthUserId: session.authenticated!.authUserId,
      actionId: actionId,
      signature: signature,
    );
  }

  /// Stops new payouts now; reserved payouts still release.
  Future<RewardEndPlan> endRewardEarly(
    Session session, {
    required UuidValue actionId,
  }) {
    return poolService.endEarly(
      session,
      creatorAuthUserId: session.authenticated!.authUserId,
      actionId: actionId,
    );
  }

  /// The caller's own payouts, newest first.
  Future<List<RewardPayoutView>> listMyPayouts(
    Session session, {
    int limit = 50,
  }) {
    return payoutService.listMine(
      session,
      authUserId: session.authenticated!.authUserId,
      limit: limit,
    );
  }
}
