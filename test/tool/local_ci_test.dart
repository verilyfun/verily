import 'dart:io';

import 'package:test/test.dart';

import '../../tool/local_ci.dart';

/// The script names a devenv script's `exec` block runs, one per line.
List<String> _devenvScriptCalls(String script) {
  final devenv = File('devenv.nix').readAsLinesSync();
  final start = devenv.indexOf('    "$script" = {');
  expect(start, isNot(-1), reason: '$script is not in devenv.nix');
  final end = devenv.indexOf("      '';", start);
  return [
    for (final line in devenv.sublist(start + 2, end))
      if (line.trim() case final call when call != 'set -e') call,
  ];
}

void main() {
  group('options', () {
    test('default to every lane that is not opt-in, and posting', () {
      final options = LocalCiOptions.parse(const [])!;
      expect(options.lanes.map((lane) => lane.script), [
        'lint:all',
        'test:tools',
        'test:lints',
        'test:flutter',
        'test:server',
        'test:escrow',
      ]);
      expect(options.alsoShas, isEmpty);
      expect(options.post, isTrue);
    });

    test('run only the named lanes, in lane order, opt-in ones included', () {
      final options = LocalCiOptions.parse(const [
        '--lane=test:escrow:e2e',
        '--lane=test:server',
        '--also=0123abc',
        '--no-post',
      ])!;
      expect(options.lanes.map((lane) => lane.script), [
        'test:server',
        'test:escrow:e2e',
      ]);
      expect(options.alsoShas, ['0123abc']);
      expect(options.post, isFalse);
    });

    test('reject unknown lanes, malformed shas, and stray arguments', () {
      for (final args in [
        ['--lane=deploy'],
        ['--lane=test:all'],
        ['--also=main'],
        ['--also=0123abc; rm -rf /'],
        ['test:server'],
      ]) {
        expect(LocalCiOptions.parse(args), isNull, reason: '$args');
      }
    });
  });

  test('github repositories are read from ssh and https remotes', () {
    expect(
      githubRepository('git@github.com:verilyfun/verily.git'),
      'verilyfun/verily',
    );
    expect(
      githubRepository('https://github.com/verilyfun/verily'),
      'verilyfun/verily',
    );
    expect(githubRepository('https://gitlab.com/a/b.git'), isNull);
  });

  test('status descriptions fit GitHub limits', () {
    expect(statusDescription('short'), 'short');
    expect(statusDescription('x' * 200), hasLength(140));
  });

  test('the default lanes cover lint:all and everything test:all runs', () {
    final defaults = LocalCiOptions.parse(const [])!.lanes
        .map((lane) => lane.script)
        .toSet();
    final testAll = _devenvScriptCalls('test:all');

    expect(testAll, isNotEmpty);
    expect(defaults, containsAll(['lint:all', ...testAll]));
  });

  test('every lane is a devenv script', () {
    final scripts = {
      for (final line in File('devenv.nix').readAsLinesSync())
        ?RegExp(r'^    "([^"]+)" = \{$').firstMatch(line)?[1],
    };
    for (final lane in localCiLanes) {
      expect(scripts, contains(lane.script));
    }
  });
}
