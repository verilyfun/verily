import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import 'support/editor_harness.dart';
import 'support/fakes.dart';

/// The Solana Seeker's portrait viewport: 1080 × 2400 physical pixels.
const _seekerPhysicalSize = Size(1080, 2400);
const _seekerPixelRatio = 2.625;

Future<void> _pumpOnSeeker(
  WidgetTester tester,
  EditorFakes fakes, {
  Brightness brightness = Brightness.light,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpEditor(
    tester,
    fakes,
    physicalSize: _seekerPhysicalSize,
    devicePixelRatio: _seekerPixelRatio,
    brightness: brightness,
  );
}

void main() {
  for (final brightness in Brightness.values) {
    group('on a Seeker at 1.3× text (${brightness.name})', () {
      testWidgets('the starting choices fit', (tester) async {
        await _pumpOnSeeker(
          tester,
          EditorFakes(
            actions: FakeActionRepository(
              templates: [walkTemplate(), venueTemplate()],
            ),
          ),
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(VerilyTestKeys.editorStartBlank),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('a full action with a reward fits', (tester) async {
        final fakes = EditorFakes(
          actions: FakeActionRepository(templates: [walkTemplate()]),
          apps: FakeAppsRepository(apps: [appFixture()]),
        );
        await _pumpOnSeeker(tester, fakes, brightness: brightness);
        await scrollAndTap(
          tester,
          find.byKey(VerilyTestKeys.editorTemplate('morning-walk')),
        );
        for (final kind in [
          ProofKind.venueCode,
          ProofKind.movementReps,
          ProofKind.motion,
        ]) {
          await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorAddProof));
          await scrollAndTap(
            tester,
            find.byKey(VerilyTestKeys.editorAddProofKind(kind.name)),
          );
        }
        await scrollAndTap(
          tester,
          find.byKey(VerilyTestKeys.editorMoreChecks('view')),
        );
        await scrollAndTap(
          tester,
          find.byKey(VerilyTestKeys.editorPlaceCoordinates('park')),
        );
        await scrollAndTap(
          tester,
          find.byKey(VerilyTestKeys.editorRewardToggle),
        );
        await scrollAndEnter(
          tester,
          find.byKey(VerilyTestKeys.editorRewardAmount),
          '2.5',
        );
        // Validation messages are the longest the form gets.
        await scrollAndEnter(
          tester,
          find.byKey(VerilyTestKeys.editorRewardMaxPayouts),
          '99999',
        );
        await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));

        for (final key in [
          VerilyTestKeys.editorTitle,
          VerilyTestKeys.editorRequirement('park'),
          VerilyTestKeys.editorRequirement('movement-reps'),
          VerilyTestKeys.editorRequirement('motion'),
          VerilyTestKeys.editorRecurrence,
          VerilyTestKeys.editorRewardBudget,
          VerilyTestKeys.editorPreview,
        ]) {
          await tester.ensureVisible(find.byKey(key));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$key');
        }

        // The add-proof sheet at the same size.
        await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorAddProof));
        expect(tester.takeException(), isNull);
      });
    });
  }
}
