import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_advisory.dart';
import 'package:verily_server/src/generated/protocol.dart';

final String _digest = 'a' * 64;

ActionMediaRule _rule({bool withLocalCheck = true}) => ActionMediaRule(
  requirementId: UuidValue.withValidation(
    '0198bc26-4be5-7ca0-94d2-000000000001',
  ),
  kind: ActionRequirementKind.photo,
  verificationPrompt: 'Verify that a real hand clearly shows a thumbs up.',
  minConfidence: 0.8,
  localCheckTask: withLocalCheck ? LocalCheckTask.gesture : null,
  localCheckLabel: withLocalCheck ? 'Thumb_Up' : null,
  localCheckMinScore: withLocalCheck ? 0.6 : null,
  localCheckMinFrames: withLocalCheck ? 1 : null,
);

DeviceLocalCheckResult _result({
  String modelId = 'mediapipe/gesture_recognizer/float16/1',
  String? modelSha256,
  String label = 'Thumb_Up',
  double score = 0.91,
  int matchedFrames = 3,
}) => DeviceLocalCheckResult(
  modelId: modelId,
  modelSha256: modelSha256 ?? _digest,
  label: label,
  score: score,
  matchedFrames: matchedFrames,
);

void main() {
  group('Given a device local-check result', () {
    test('when the rule has a local check then a bounded copy is kept', () {
      final kept = advisoryLocalCheck(_rule(), _result())!;

      expect(kept.modelId, 'mediapipe/gesture_recognizer/float16/1');
      expect(kept.modelSha256, _digest);
      expect(kept.label, 'Thumb_Up');
      expect(kept.score, 0.91);
      expect(kept.matchedFrames, 3);
    });

    test('when the rule has no local check then it is ignored entirely', () {
      expect(
        advisoryLocalCheck(_rule(withLocalCheck: false), _result()),
        isNull,
      );
      // Even malformed data is ignored rather than refused there.
      expect(
        advisoryLocalCheck(
          _rule(withLocalCheck: false),
          _result(modelSha256: 'not-a-digest', score: 7),
        ),
        isNull,
      );
    });

    test('when nothing was sent then nothing is stored', () {
      expect(advisoryLocalCheck(_rule(), null), isNull);
    });

    test(
      'when any field is out of bounds then the confirmation is refused',
      () {
        final invalid = [
          _result(modelId: ''),
          _result(modelId: 'm' * 129),
          _result(modelSha256: 'A' * 64),
          _result(modelSha256: 'a' * 63),
          _result(label: ''),
          _result(label: 'l' * 65),
          _result(score: -0.01),
          _result(score: 1.01),
          _result(score: double.nan),
          _result(matchedFrames: -1),
          _result(matchedFrames: 10001),
        ];
        for (var index = 0; index < invalid.length; index += 1) {
          expect(
            () => advisoryLocalCheck(_rule(), invalid[index]),
            throwsArgumentError,
            reason: 'case $index',
          );
        }
      },
    );
  });
}
