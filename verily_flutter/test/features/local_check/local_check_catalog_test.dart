import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/features/local_check/local_check_catalog.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';

void main() {
  test('every task runs one shared pinned model', () {
    expect(
      LocalCheckTask.values.map((task) => task.model),
      unorderedEquals(LocalCheckModel.values),
    );
  });

  test('names every label for people', () {
    final l10n = AppLocalizationsEn();
    for (final task in LocalCheckTask.values) {
      for (final label in task.model.labels) {
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
      expect(task.model.labels, contains(defaultLocalCheckLabel(task)));
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
