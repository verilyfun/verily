import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/spoken_challenge_words.dart';

void main() {
  group('Given the server-owned challenge word list', () {
    test('when counted then it has at least 200 unique words', () {
      expect(spokenChallengeWords.length, greaterThanOrEqualTo(200));
      expect(
        spokenChallengeWords.toSet(),
        hasLength(spokenChallengeWords.length),
      );
    });

    test('when inspected then every word is a short lowercase single word', () {
      for (final word in spokenChallengeWords) {
        expect(word, matches(RegExp(r'^[a-z]{3,12}$')), reason: word);
      }
    });

    test('when inspected then no word reads as an instruction or verdict', () {
      const forbidden = {
        'accept',
        'admin',
        'allow',
        'approve',
        'assistant',
        'confirm',
        'execute',
        'grant',
        'ignore',
        'model',
        'override',
        'pass',
        'prompt',
        'reject',
        'system',
        'true',
        'false',
        'valid',
        'verified',
        'verify',
        'yes',
        'no',
      };
      expect(
        spokenChallengeWords.where(forbidden.contains),
        isEmpty,
      );
    });

    test('when inspected then no word is a prefix of another, so a clipped '
        'recording cannot satisfy a longer word', () {
      final prefixes = [
        for (final short in spokenChallengeWords)
          for (final long in spokenChallengeWords)
            if (short != long && long.startsWith(short)) '$short/$long',
      ];
      expect(prefixes, isEmpty);
    });
  });

  group('Given a word picker', () {
    test('when given the same seeded source then it picks the same words', () {
      final first = [
        for (var index = 0; index < 20; index += 1)
          pickSpokenChallengeWord(math.Random(11)),
      ];
      final seeded = math.Random(11);
      final second = pickSpokenChallengeWord(seeded);

      expect(first.toSet(), hasLength(1));
      expect(second, first.first);
    });

    test('when drawn many times then every word stays reachable and none '
        'dominates', () {
      final random = math.Random(42);
      final counts = <String, int>{};
      final draws = spokenChallengeWords.length * 200;
      for (var index = 0; index < draws; index += 1) {
        final word = pickSpokenChallengeWord(random);
        counts[word] = (counts[word] ?? 0) + 1;
      }

      expect(counts.keys.toSet(), spokenChallengeWords.toSet());
      // Expected 200 per word; a uniform picker stays well inside 2x.
      expect(counts.values.reduce(math.max), lessThan(400));
      expect(counts.values.reduce(math.min), greaterThan(100));
    });

    test('when called without a source then it uses the secure default', () {
      expect(spokenChallengeWords, contains(pickSpokenChallengeWord()));
    });
  });
}
