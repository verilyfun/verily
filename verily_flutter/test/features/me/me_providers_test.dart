import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/features/me/me_providers.dart';

import 'support/fakes.dart';

void main() {
  group('joinAttemptsWithActions', () {
    test("finds an attempt's action by the action's current attempt", () {
      final attempt = fakeAttempt(id: 1, actionId: 99);
      final action = fakeAction(id: 10, title: 'Squats', myAttempt: attempt);

      final joined = joinAttemptsWithActions([attempt], [action]);

      expect(joined.single.action, same(action));
    });

    test('falls back to the action revision the attempt names', () {
      final attempt = fakeAttempt(id: 2, actionId: 11);
      final action = fakeAction(id: 11, title: 'Check in at the café');

      final joined = joinAttemptsWithActions([attempt], [action]);

      expect(joined.single.action, same(action));
    });

    test('leaves the action empty when it is no longer listed', () {
      final attempt = fakeAttempt(id: 3, actionId: 12);

      final joined = joinAttemptsWithActions(
        [
          attempt,
        ],
        [fakeAction(id: 13, title: 'Another action')],
      );

      expect(joined.single.attempt, same(attempt));
      expect(joined.single.action, isNull);
    });
  });
}
