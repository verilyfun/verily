import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/features/local_check/local_check_catalog.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';

/// The server's allow-list, read from its source so the app's copy cannot
/// drift unnoticed. The server should expose or share this list; until it
/// does, this test is the contract.
final _serverCatalog = File(
  '../verily_server/lib/src/action_verification/local_check/'
  'local_check_catalog.dart',
);

Map<LocalCheckTask, Set<String>> _serverLabels() {
  final source = _serverCatalog.readAsStringSync();
  final start = source.indexOf('const localCheckLabels');
  expect(start, isNot(-1), reason: 'the server catalog moved');
  final block = source.substring(start, source.indexOf('};', start));
  final sets = <LocalCheckTask, Set<String>>{};
  for (final match in RegExp(
    r'LocalCheckTask\.(\w+): \{(.*?)\}',
    dotAll: true,
  ).allMatches(block)) {
    sets[LocalCheckTask.values.byName(match.group(1)!)] = {
      for (final label in RegExp("'([^']*)'").allMatches(match.group(2)!))
        label.group(1)!,
    };
  }
  return sets;
}

double _serverBound(String name) {
  final match = RegExp(
    'static const $name = ([0-9.]+);',
  ).firstMatch(_serverCatalog.readAsStringSync());
  expect(match, isNotNull, reason: 'the server bound $name moved');
  return double.parse(match!.group(1)!);
}

void main() {
  test('offers exactly the labels the server accepts', () {
    final server = _serverLabels();
    expect(server.keys, unorderedEquals(LocalCheckTask.values));
    for (final task in LocalCheckTask.values) {
      expect(
        localCheckLabels[task]!.toSet(),
        server[task],
        reason: 'the ${task.name} labels drifted from the server',
      );
    }
  });

  test('uses the server bounds', () {
    expect(LocalCheckBounds.minScore, _serverBound('minScore'));
    expect(LocalCheckBounds.maxScore, _serverBound('maxScore'));
    expect(LocalCheckBounds.minFrames, _serverBound('minFrames'));
    expect(LocalCheckBounds.maxFrames, _serverBound('maxFrames'));
  });

  test('names every label for people', () {
    final l10n = AppLocalizationsEn();
    for (final task in LocalCheckTask.values) {
      for (final label in localCheckLabels[task]!) {
        expect(
          knownLocalCheckLabelName(l10n, task, label),
          isNotNull,
          reason: '$label has no name',
        );
      }
    }
    expect(
      localCheckLabelName(l10n, LocalCheckTask.gesture, 'Thumb_Up'),
      'Thumbs up',
    );
    // A label the app does not know yet still reads as words.
    expect(
      localCheckLabelName(l10n, LocalCheckTask.gesture, 'New_Gesture'),
      'New Gesture',
    );
  });

  test('defaults are allowed labels for their task', () {
    for (final task in LocalCheckTask.values) {
      expect(localCheckLabels[task], contains(defaultLocalCheckLabel(task)));
    }
  });

  test('sound runs on audio, sight on photos and video', () {
    expect(localCheckTasksFor(MediaEvidenceKind.audio), [LocalCheckTask.sound]);
    expect(localCheckTasksFor(MediaEvidenceKind.photo), [
      LocalCheckTask.gesture,
      LocalCheckTask.object,
    ]);
    expect(localCheckTasksFor(MediaEvidenceKind.video), [
      LocalCheckTask.gesture,
      LocalCheckTask.object,
    ]);
  });
}
