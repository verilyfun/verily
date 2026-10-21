import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/appeals/evidence_appeal_repository.dart';
import 'package:verily_flutter/features/rewards/reward_repository.dart';

/// One of the caller's attempts with the action it belongs to, when that
/// action is still listed.
@immutable
class MyAttempt {
  const MyAttempt({required this.attempt, this.action});

  final ActionAttemptView attempt;

  /// Null when the action has ended, been paused, or fallen out of the list:
  /// the attempt view itself carries no title.
  final ActionOpportunity? action;
}

/// Matches each attempt to its action. Actions carry the caller's attempt for
/// the current period, and every attempt names the action revision it
/// belongs to, so both are tried.
List<MyAttempt> joinAttemptsWithActions(
  List<ActionAttemptView> attempts,
  List<ActionOpportunity> actions,
) {
  final byAttemptId = {
    for (final action in actions)
      if (action.myAttempt case final attempt?) attempt.id: action,
  };
  final byRevisionId = {for (final action in actions) action.id: action};
  return [
    for (final attempt in attempts)
      MyAttempt(
        attempt: attempt,
        action:
            byAttemptId[attempt.id] ?? byRevisionId[attempt.actionDefinitionId],
      ),
  ];
}

final FutureProvider<List<MyAttempt>> myAttemptsProvider =
    FutureProvider.autoDispose<List<MyAttempt>>((
      ref,
    ) async {
      final actions = ref.watch(actionRepositoryProvider);
      final (attempts, available) = await (
        actions.listMyAttempts(),
        actions.listAvailable(),
      ).wait;
      return joinAttemptsWithActions(attempts, available);
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
