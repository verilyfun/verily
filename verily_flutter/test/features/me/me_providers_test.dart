import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/me/me_providers.dart';

import 'support/fakes.dart';

void main() {
  group('joinAttemptsWithPayouts', () {
    test('pairs each attempt with the payout it won', () {
      final won = fakeAttempt(id: 1, actionId: 10);
      final payout = fakePayout(
        id: 40,
        actionTitle: 'Squats',
        status: RewardPayoutStatus.released,
      ).copyWith(attemptId: won.id);

      final joined = joinAttemptsWithPayouts([won], [payout]);

      expect(joined.single.attempt, same(won));
      expect(joined.single.payout, same(payout));
    });

    test('leaves the payout empty for an attempt that won none', () {
      final attempt = fakeAttempt(id: 2, actionId: 11);

      final joined = joinAttemptsWithPayouts(
        [attempt],
        [
          fakePayout(
            id: 41,
            actionTitle: 'Another action',
            status: RewardPayoutStatus.released,
          ),
        ],
      );

      expect(joined.single.payout, isNull);
    });
  });
}
