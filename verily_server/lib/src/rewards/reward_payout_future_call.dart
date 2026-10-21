import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';

/// Releases one reserved payout. Idempotent: see [RewardPayoutService.release].
class RewardPayoutFutureCall extends FutureCall<RewardPayoutTask> {
  Future<void> release(Session session, RewardPayoutTask task) {
    return RewardPayoutService().release(session, task.payoutId);
  }
}
