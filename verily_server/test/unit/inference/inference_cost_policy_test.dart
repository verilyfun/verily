import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/inference/inference_cost_policy.dart';

const _policy = InferenceCostPolicy(
  version: 'rates:2026-10-21',
  maxMicrosPerAttempt: 3000,
  maxCallsPerAttempt: 3,
  modelMaxCostMicros: {
    openRouterGeminiFlashLiteModel: 1000,
    openRouterGemmaModel: 1200,
  },
);

Matcher _budgetError(String reasonCode) => throwsA(
  isA<InferenceBudgetExhaustedException>().having(
    (error) => error.reasonCode,
    'reasonCode',
    reasonCode,
  ),
);

void main() {
  group('Given the disabled cost policy', () {
    test('when any model is priced then no call is approved', () {
      const policy = InferenceCostPolicy.disabled();

      expect(policy.isDisabled, isTrue);
      expect(
        () => policy.costFor(openRouterGeminiFlashLiteModel),
        _budgetError('verification_budget_unapproved'),
      );
    });
  });

  group('Given an approved cost policy', () {
    test('when a pinned model is priced then its approved worst case is '
        'returned', () {
      expect(_policy.costFor(openRouterGeminiFlashLiteModel), 1000);
      expect(_policy.costFor(openRouterGemmaModel), 1200);
    });

    test('when an unpriced model is asked for then it is not approved', () {
      expect(
        () => _policy.costFor(openRouterGlmFlashModel),
        _budgetError('verification_budget_unapproved'),
      );
      expect(
        () => _policy.costFor('attacker/model'),
        _budgetError('verification_budget_unapproved'),
      );
    });

    test('when the next call fits both caps then it may be reserved', () {
      expect(
        () => _policy.checkReservation(
          reservedMicros: 1000,
          calls: 1,
          nextCostMicros: 1200,
        ),
        returnsNormally,
      );
    });

    test('when the next call would exceed the spend cap then it is '
        'refused', () {
      expect(
        () => _policy.checkReservation(
          reservedMicros: 2000,
          calls: 2,
          nextCostMicros: 1200,
        ),
        _budgetError('verification_budget_exhausted'),
      );
    });

    test('when the call cap is reached then even a cheap call is refused', () {
      expect(
        () => _policy.checkReservation(
          reservedMicros: 0,
          calls: 3,
          nextCostMicros: 1,
        ),
        _budgetError('verification_budget_exhausted'),
      );
    });

    test('when the bookkeeping is negative or the cost is not positive then '
        'it is refused', () {
      for (final (reserved, calls, next) in [
        (-1, 0, 10),
        (0, -1, 10),
        (0, 0, 0),
      ]) {
        expect(
          () => _policy.checkReservation(
            reservedMicros: reserved,
            calls: calls,
            nextCostMicros: next,
          ),
          _budgetError('verification_budget_exhausted'),
        );
      }
    });
  });

  group('Given a cost policy outside the reviewed ceilings', () {
    test('when a model costs more than one attempt may spend then it is '
        'not approved', () {
      const policy = InferenceCostPolicy(
        version: 'rates:2026-10-21',
        maxMicrosPerAttempt: 1000,
        maxCallsPerAttempt: 3,
        modelMaxCostMicros: {openRouterGeminiFlashLiteModel: 1001},
      );

      expect(
        () => policy.costFor(openRouterGeminiFlashLiteModel),
        _budgetError('verification_budget_unapproved'),
      );
    });

    test('when the per-attempt or call ceilings exceed the absolute limits '
        'then nothing is approved', () {
      for (final policy in const [
        InferenceCostPolicy(
          version: 'rates:2026-10-21',
          maxMicrosPerAttempt: maxInferenceMicrosPerAttempt + 1,
          maxCallsPerAttempt: 3,
          modelMaxCostMicros: {openRouterGeminiFlashLiteModel: 1000},
        ),
        InferenceCostPolicy(
          version: 'rates:2026-10-21',
          maxMicrosPerAttempt: 3000,
          maxCallsPerAttempt: maxInferenceCallsPerAttempt + 1,
          modelMaxCostMicros: {openRouterGeminiFlashLiteModel: 1000},
        ),
        InferenceCostPolicy(
          version: '',
          maxMicrosPerAttempt: 3000,
          maxCallsPerAttempt: 3,
          modelMaxCostMicros: {openRouterGeminiFlashLiteModel: 1000},
        ),
      ]) {
        expect(
          () => policy.costFor(openRouterGeminiFlashLiteModel),
          _budgetError('verification_budget_unapproved'),
        );
      }
    });
  });
}
