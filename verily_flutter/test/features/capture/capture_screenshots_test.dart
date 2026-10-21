// Renders the capture screens at the Solana Seeker's portrait size with the
// real Skribble faces at 1.3× text, so layout is checked against true font
// metrics rather than the square test font.
//
// Every run asserts the screens lay out without errors. To also write PNGs
// for review into `.screenshots/capture/` (ignored by git):
//
//   flutter test --dart-define=VERILY_SCREENSHOTS=true \
//     test/features/capture/capture_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/capture/camera/capture_camera.dart';
import 'package:verily_flutter/features/capture/movement/movement_capture_controller.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../support/test_app.dart';
import 'support/fakes.dart';
import '../../support/skribble_faces.dart';

const _writeScreenshots = bool.fromEnvironment('VERILY_SCREENSHOTS');
const _outputDirectory = '.screenshots/capture';
const _seekerPhysicalSize = Size(1080, 2400);
const _seekerPixelRatio = 2.625;

void main() {
  setUpAll(loadSkribbleFaces);

  testWidgets('video viewfinder with the word', (tester) async {
    final harness = CaptureHarness();
    await _open(
      tester,
      harness,
      testRequirement(
        ActionRequirementKind.video,
        spokenChallengeRequired: true,
        minDurationSeconds: 5,
      ),
    );
    await _capture(tester, 'video-ready');

    await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _capture(tester, 'video-recording');
  });

  testWidgets('photo viewfinder', (tester) async {
    await _open(
      tester,
      CaptureHarness(),
      testRequirement(ActionRequirementKind.photo),
    );
    await _capture(tester, 'photo-ready');
  });

  testWidgets('audio recording with the word', (tester) async {
    final harness = CaptureHarness();
    await _open(
      tester,
      harness,
      testRequirement(
        ActionRequirementKind.audio,
        spokenChallengeRequired: true,
        minDurationSeconds: 5,
      ),
    );
    await _capture(tester, 'audio-ready');

    await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
    await tester.pump();
    harness.recorder.emitLevel(0.62);
    await tester.pump(const Duration(seconds: 2));
    expect(find.bySemanticsLabel('Sound level 62%'), findsOneWidget);
    // Lets the meter ease to the new level.
    await tester.pump(const Duration(milliseconds: 400));
    await _capture(tester, 'audio-recording');
  });

  testWidgets('movement counting with the word', (tester) async {
    final harness = CaptureHarness();
    await _open(
      tester,
      harness,
      testRequirement(
        ActionRequirementKind.video,
        spokenChallengeRequired: true,
        movementKind: ActionMovementKind.squats,
        targetRepetitions: 10,
      ),
    );
    final controller = harness.movementControllers.single
      ..emit(
        const MovementCaptureState(
          phase: MovementCapturePhase.ready,
          liveCounting: MovementLiveCounting.active,
        ),
      );
    await tester.pump();
    await _capture(tester, 'movement-ready');

    controller.emit(recordingState(count: 6));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await _capture(tester, 'movement-recording');
  });

  for (final brightness in Brightness.values) {
    testWidgets('review after a failed send, ${brightness.name}', (
      tester,
    ) async {
      final harness = CaptureHarness(
        gateway: FakeEvidenceGateway(uploads: [false]),
      );
      await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.video,
          spokenChallengeRequired: true,
        ),
        brightness: brightness,
      );
      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStop));
      await _settle(tester);
      await _capture(tester, 'review-${brightness.name}');

      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await _settle(tester);
      await _capture(tester, 'review-send-failed-${brightness.name}');
    });

    testWidgets('motion toss, ${brightness.name}', (tester) async {
      await _open(
        tester,
        CaptureHarness(),
        testRequirement(
          ActionRequirementKind.motion,
          motionType: ActionMotionType.phoneToss,
        ),
        brightness: brightness,
      );
      await _capture(tester, 'motion-toss-${brightness.name}');
    });
  }

  testWidgets('word could not be fetched', (tester) async {
    await _open(
      tester,
      CaptureHarness(words: [Exception('offline')]),
      testRequirement(
        ActionRequirementKind.video,
        spokenChallengeRequired: true,
      ),
    );
    await _capture(tester, 'challenge-failed');
  });

  testWidgets('camera access is off', (tester) async {
    await _open(
      tester,
      CaptureHarness(
        cameraFailure: CaptureCameraFailure.cameraPermissionDenied,
      ),
      testRequirement(ActionRequirementKind.photo),
    );
    await _capture(tester, 'camera-permission');
  });
}

Future<void> _open(
  WidgetTester tester,
  CaptureHarness harness,
  ActionRequirementView requirement, {
  Brightness brightness = Brightness.light,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
  await _settle(tester);
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

/// Lets ink motion, async work, and route transitions finish. Loading
/// indicators spin forever, so this pumps fixed steps instead of settling.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var step = 0; step < 4; step++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}
