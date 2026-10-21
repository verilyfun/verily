import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';

const rewardPayoutRecoveryIdentifier = 'reward-payout-recovery';

/// Recurring sweep that keeps reward pools and payouts moving.
/// See [RewardPayoutService.recover].
class RewardPayoutRecoveryFutureCall
    extends FutureCall<RewardPayoutRecoveryTask> {
  Future<void> recover(Session session, RewardPayoutRecoveryTask task) {
    return RewardPayoutService().recover(session, batchSize: task.batchSize);
  }
}
