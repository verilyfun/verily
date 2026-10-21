import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/local_check/local_check_tally.dart';

ActionLocalCheck _check({double minScore = 0.6, int minFrames = 3}) =>
    ActionLocalCheck(
      task: LocalCheckTask.gesture,
      label: 'Thumb_Up',
      minScore: minScore,
      minFrames: minFrames,
    );

const _match = LocalCheckFrame(score: 0.8, subjectSeen: true);
const _miss = LocalCheckFrame(score: 0);

void main() {
  group('a recording', () {
    test('passes once enough frames reach the score', () {
      final tally = LocalCheckTally(_check(), photo: false)
        ..add(_match)
        ..add(_match);
      expect(tally.passed, isFalse);

      tally.add(_match);
      expect(tally.matched, 3);
      expect(tally.passed, isTrue);
      expect(tally.guidance, LocalCheckGuidance.passed);
    });

    test('a score under the minimum never counts', () {
      final tally = LocalCheckTally(_check(), photo: false);
      for (var index = 0; index < 10; index++) {
        tally.add(const LocalCheckFrame(score: 0.59));
      }
      expect(tally.matched, 0);
      expect(tally.passed, isFalse);
      expect(tally.bestScore, 0.59);
      expect(tally.guidance, LocalCheckGuidance.almost);
    });

    test('a score at the minimum counts', () {
      final tally = LocalCheckTally(_check(minFrames: 1), photo: false)
        ..add(const LocalCheckFrame(score: 0.6));
      expect(tally.passed, isTrue);
    });

    test('needs the share of matching frames the replay would sample', () {
      // Three matches among 40 frames is 7.5%: the server's 30 evenly spaced
      // samples would likely miss them, so this is not enough yet.
      final tally = LocalCheckTally(_check(), photo: false);
      for (var index = 0; index < 37; index++) {
        tally.add(_miss);
      }
      tally
        ..add(_match)
        ..add(_match)
        ..add(_match);
      expect(tally.matched, 3);
      expect(tally.passed, isFalse);

      // One match in ten frames (minFrames out of 30) is enough.
      tally.add(_match);
      expect(tally.matched, 4);
      expect(tally.analysed, 41);
      expect(tally.passed, isFalse);
      for (var index = 0; index < 10; index++) {
        tally.add(_match);
      }
      expect(tally.passed, isTrue);
    });
  });

  group('a photo', () {
    test('passes only while the label holds for a few frames in a row', () {
      final tally = LocalCheckTally(_check(minFrames: 1), photo: true)
        ..add(_match)
        ..add(_match)
        ..add(_miss)
        ..add(_match)
        ..add(_match);
      expect(tally.passed, isFalse);

      tally.add(_match);
      expect(tally.passed, isTrue);

      tally.add(_miss);
      expect(tally.passed, isFalse);
    });
  });

  group('guidance', () {
    test('starts with nothing seen', () {
      expect(
        LocalCheckTally(_check(), photo: false).guidance,
        LocalCheckGuidance.notSeen,
      );
    });

    test('a hand without the gesture asks for the gesture', () {
      final tally = LocalCheckTally(_check(), photo: false)
        ..add(const LocalCheckFrame(score: 0, subjectSeen: true));
      expect(tally.guidance, LocalCheckGuidance.subjectSeen);
    });

    test('keeps "hold it" through a blink, then lets go', () {
      final tally = LocalCheckTally(_check(minFrames: 30), photo: false)
        ..add(_match);
      expect(tally.guidance, LocalCheckGuidance.holding);

      tally
        ..add(_miss)
        ..add(_miss);
      expect(tally.guidance, LocalCheckGuidance.holding);

      tally.add(_miss);
      expect(tally.guidance, LocalCheckGuidance.notSeen);
    });
  });
}
