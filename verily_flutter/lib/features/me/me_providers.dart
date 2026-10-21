import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/appeals/evidence_appeal_repository.dart';
import 'package:verily_flutter/features/rewards/reward_repository.dart';

/// One of the caller's attempts with the payout it won, if any.
@immutable
class MyAttempt {
  const MyAttempt({required this.attempt, this.payout});

  final ActionAttemptView attempt;

  /// The payout this attempt won; null when it won none or the action
  /// carries no reward.
  final RewardPayoutView? payout;
}

/// Matches each attempt to the payout it won, by attempt id.
List<MyAttempt> joinAttemptsWithPayouts(
  List<ActionAttemptView> attempts,
  List<RewardPayoutView> payouts,
) {
  final byAttempt = {for (final payout in payouts) payout.attemptId: payout};
  return [
    for (final attempt in attempts)
      MyAttempt(attempt: attempt, payout: byAttempt[attempt.id]),
  ];
}

final FutureProvider<List<MyAttempt>> myAttemptsProvider =
    FutureProvider.autoDispose<List<MyAttempt>>((ref) async {
      final (attempts, payouts) = await (
        ref.watch(actionRepositoryProvider).listMyAttempts(),
        ref.watch(myPayoutsProvider.future),
      ).wait;
      return joinAttemptsWithPayouts(attempts, payouts);
    });

final FutureProvider<List<RewardPayoutView>> myPayoutsProvider =
    FutureProvider.autoDispose<List<RewardPayoutView>>(
      (ref) => ref.watch(rewardRepositoryProvider).listMyPayouts(),
    );

final FutureProvider<PayoutWalletView?> myPayoutWalletProvider =
    FutureProvider.autoDispose<PayoutWalletView?>(
      (ref) => ref.watch(payoutWalletRepositoryProvider).getMine(),
    );

/// The caller's appeal on a rejected attempt, or null when there is none.
final FutureProviderFamily<EvidenceAppealView?, UuidValue> myAppealProvider =
    FutureProvider.autoDispose.family<EvidenceAppealView?, UuidValue>(
      (ref, attemptId) =>
          ref.watch(evidenceAppealRepositoryProvider).getMine(attemptId),
    );
