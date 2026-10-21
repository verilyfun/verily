// Renders the quick-check screens at the Solana Seeker's portrait size with
// the real Skribble faces, in light and dark: the live gesture guide (not
// seen, a hand without the gesture, seen while recording), an object check
// on a photo, the sound check, and the editor's quick-check settings.
//
// Every run asserts the screens lay out without errors. To also write PNGs
// for review into `.screenshots/phase-c/` (ignored by git):
//
//   flutter test --dart-define=VERILY_SCREENSHOTS=true \
//     test/screenshots/phase_c_local_checks_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/local_check/local_check_tally.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../features/capture/support/fakes.dart';
import '../features/create/editor/support/editor_harness.dart';
import '../features/create/editor/support/fakes.dart' as editor;
import '../support/skribble_faces.dart';
import '../support/test_app.dart';

const _writeScreenshots = bool.fromEnvironment('VERILY_SCREENSHOTS');
const _outputDirectory = '.screenshots/phase-c';
const _seekerPhysicalSize = Size(1080, 2400);
const _seekerPixelRatio = 2.625;

const _hand = LocalCheckFrame(score: 0, subjectSeen: true);
const _match = LocalCheckFrame(score: 0.84, subjectSeen: true);

void main() {
  setUpAll(loadSkribbleFaces);

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('gesture guide on video ($theme)', (tester) async {
      final harness = CaptureHarness();
      await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.video,
          minDurationSeconds: 5,
          localCheck: thumbsUpCheck(),
          localCheckModel: testGestureModel,
        ),
        brightness: brightness,
      );
      await _capture(tester, 'gesture-not-seen-$theme');

      harness.vision.frames.add(_hand);
      await harness.camera.deliverFrames(1);
      await tester.pump();
      await _capture(tester, 'gesture-hand-seen-$theme');

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pump();
      harness.vision.frames.addAll([_match, _match, _match]);
      await harness.camera.deliverFrames(3);
      await tester.pump(const Duration(seconds: 2));
      await _capture(tester, 'gesture-seen-recording-$theme');
    });

    testWidgets('object check on a photo ($theme)', (tester) async {
      final harness = CaptureHarness();
      await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.photo,
          localCheck: ActionLocalCheck(
            task: LocalCheckTask.object,
            label: 'cup',
            minScore: 0.5,
            minFrames: 1,
          ),
          localCheckModel: testObjectModel,
        ),
        brightness: brightness,
      );
      harness.vision.frames.add(const LocalCheckFrame(score: 0.3));
      await harness.camera.deliverFrames(1);
      await tester.pump();
      await _capture(tester, 'object-almost-$theme');
    });

    testWidgets('sound check ($theme)', (tester) async {
      final harness = CaptureHarness();
      await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.audio,
          minDurationSeconds: 5,
          localCheck: ActionLocalCheck(
            task: LocalCheckTask.sound,
            label: 'Clapping',
            minScore: 0.4,
            minFrames: 2,
          ),
          localCheckModel: testSoundModel,
        ),
        brightness: brightness,
      );
      await _capture(tester, 'sound-$theme');
    });

    testWidgets('editor quick check ($theme)', (tester) async {
      final fakes = editor.EditorFakes(
        actions: editor.FakeActionRepository(
          templates: [editor.walkTemplate()],
        ),
      );
      await pumpEditor(tester, fakes, brightness: brightness);
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorTemplate('morning-walk')),
      );
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorQuickCheckAdd('view')),
      );
      // The section's top: its heading, the choices, and the gestures.
      await Scrollable.ensureVisible(
        tester.element(
          find.byKey(VerilyTestKeys.editorQuickCheckRemove('view')),
        ),
        alignment: 0.1,
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'editor-quick-check-$theme');

      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorQuickCheckTask('view', 'object')),
      );
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorQuickCheckPickLabel('view')),
      );
      await _capture(tester, 'editor-pick-thing-$theme');
    });
  }

  testWidgets('gesture guide fits at 1.3x text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final harness = CaptureHarness();
    await _open(
      tester,
      harness,
      testRequirement(
        ActionRequirementKind.video,
        spokenChallengeRequired: true,
        minDurationSeconds: 5,
        localCheck: thumbsUpCheck(),
        localCheckModel: testGestureModel,
      ),
    );
    harness.vision.frames.add(_hand);
    await harness.camera.deliverFrames(1);
    await tester.pump();
    await _capture(tester, 'gesture-with-word-1.3x');
  });
}

Future<void> _open(
  WidgetTester tester,
  CaptureHarness harness,
  ActionRequirementView requirement, {
  Brightness brightness = Brightness.light,
}) async {
  await pumpVerilyPage(
    tester,
    CaptureLauncher(requirement: requirement, onResult: (_) {}),
    overrides: harness.overrides,
    brightness: brightness,
    physicalSize: _seekerPhysicalSize,
    devicePixelRatio: _seekerPixelRatio,
    useAppTypeface: true,
  );
  await tester.tap(find.byKey(CaptureLauncher.openKey));
  await tester.pump();
  for (var step = 0; step < 4; step++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  if (!_writeScreenshots) return;

  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    // The root layer already scales by the device pixel ratio.
    final image = await layer.toImage(Offset.zero & tester.view.physicalSize);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_outputDirectory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}
