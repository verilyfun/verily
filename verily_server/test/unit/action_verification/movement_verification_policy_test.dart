import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/action_draft_refusal.dart';
import 'package:verily_server/src/action_verification/model_input_security.dart';
import 'package:verily_server/src/action_verification/movement_verification_policy.dart';
import 'package:verily_server/src/generated/protocol.dart';

final Matcher _refused = throwsA(isA<ActionDraftRefusal>());

void main() {
  group('movementVerificationPrompt', () {
    test('produces a safe, bounded prompt for every movement', () {
      for (final kind in ActionMovementKind.values) {
        final prompt = movementVerificationPrompt(kind, 12);

        expect(ModelInputSecurity.isSafeVerificationPolicy(prompt), isTrue);
        expect(prompt, contains('at least 12 complete'));
        expect(prompt, contains('single continuous recording'));
      }
    });

    test('requires ball skills to be one unbroken run', () {
      for (final kind in [
        ActionMovementKind.footballKickUps,
        ActionMovementKind.tableTennisBounces,
      ]) {
        expect(movementVerificationPrompt(kind, 20), contains('consecutive'));
      }
      expect(
        movementVerificationPrompt(ActionMovementKind.squats, 20),
        isNot(contains('consecutive')),
      );
    });

    test('defines a complete repetition, not just a name', () {
      expect(
        movementVerificationPrompt(ActionMovementKind.pressUps, 10),
        contains('until the arms are straight'),
      );
      expect(
        movementVerificationPrompt(ActionMovementKind.footballKickUps, 10),
        contains('never the hands or arms'),
      );
    });
  });

  group('validateMovementTarget', () {
    test('accepts a target that fits the recording limit', () {
      expect(
        () => validateMovementTarget(ActionMovementKind.squats, 10, 120),
        returnsNormally,
      );
      expect(
        () => validateMovementTarget(
          ActionMovementKind.footballKickUps,
          100,
          60,
        ),
        returnsNormally,
      );
    });

    test('rejects missing, empty, and oversized targets', () {
      for (final target in [null, 0, -3, maximumMovementRepetitions + 1]) {
        expect(
          () => validateMovementTarget(ActionMovementKind.squats, target, 300),
          _refused,
        );
      }
    });

    test('rejects targets that cannot be finished in time', () {
      // Burpees need at least 2.5 seconds each.
      expect(
        () => validateMovementTarget(ActionMovementKind.burpees, 50, 120),
        _refused,
      );
      expect(
        () => validateMovementTarget(ActionMovementKind.burpees, 48, 120),
        returnsNormally,
      );
    });
  });
}
