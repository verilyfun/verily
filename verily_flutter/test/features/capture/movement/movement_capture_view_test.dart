import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/capture/capture_models.dart';
import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';
import 'package:verily_flutter/features/capture/movement/movement_capture_controller.dart';
import 'package:verily_flutter/features/capture/movement/movement_tracking_providers.dart';
import 'package:verily_flutter/features/capture/movement/widgets/movement_capture_view.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../../support/test_app.dart';
import '../support/fakes.dart';

void main() {
  testWidgets('counts down hands-free, then records a fresh set', (
    tester,
  ) async {
    final controller = FakeMovementCaptureController();
    await _pumpView(tester, controller);

    expect(controller.opened, 1);
    expect(find.text('10 squats'), findsOneWidget);
    expect(
      find.text('Side view · keep your hips, knees and ankles in frame'),
      findsOneWidget,
    );
    expect(find.text('Bend your knees'), findsNothing);

    controller.emit(
      const MovementCaptureState(
        phase: MovementCapturePhase.ready,
        liveCounting: MovementLiveCounting.active,
        progress: MovementProgress(
          count: 0,
          best: 0,
          depth: 0,
          tracking: true,
          cue: MovementCue.perform,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Bend your knees'), findsOneWidget);

    await tester.tap(find.byKey(VerilyTestKeys.movementCaptureStart));
    await tester.pump();
    expect(find.byKey(VerilyTestKeys.movementCaptureCountdown), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('2'), findsOneWidget);
    expect(controller.started, 0);

    await tester.pump(const Duration(seconds: 2));
    expect(controller.started, 1);
    expect(find.byKey(VerilyTestKeys.movementCaptureCountdown), findsNothing);
  });

  testWidgets('shows the live count and stops once the target is reached', (
    tester,
  ) async {
    final controller = FakeMovementCaptureController();
    RawCapture? result;
    await _pumpView(tester, controller, onResult: (value) => result = value);
    controller.emit(recordingState(count: 7));
    await tester.pump();

    expect(find.byKey(VerilyTestKeys.movementCaptureCount), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('of 10 · 3 to go'), findsOneWidget);
    expect(find.bySemanticsLabel('7 of 10 counted'), findsOneWidget);
    expect(
      find.byKey(VerilyTestKeys.movementCaptureDepthMeter),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    controller.emit(recordingState(count: 10));
    await tester.pump();
    expect(find.text('Target reached!'), findsOneWidget);
    expect(controller.stopped, 0, reason: 'the celebration holds first');

    await tester.pump(MovementCaptureView.targetHold);
    await tester.pumpAndSettle();
    expect(controller.stopped, 1);
    expect(result?.repetitions, 10);
    expect(result?.trackerVersion, 'pose-lite-v1.squats-v1');
    expect(result?.measuredDuration, greaterThan(const Duration(seconds: 3)));
    expect(find.byType(MovementCaptureView), findsNothing);
  });

  testWidgets('keeps recording until the minimum duration has passed', (
    tester,
  ) async {
    final controller = FakeMovementCaptureController();
    await _pumpView(tester, controller, minimumSeconds: 8);
    controller.emit(recordingState(count: 0));
    await tester.pump();

    expect(find.text('Keep recording'), findsOneWidget);
    expect(_button(tester, VerilyTestKeys.movementCaptureStop).onPressed, null);

    // Reaching the target early waits for the minimum before stopping.
    controller.emit(recordingState(count: 10));
    await tester.pump(const Duration(seconds: 3));
    expect(controller.stopped, 0);
    await tester.pump(const Duration(seconds: 6));
    expect(controller.stopped, 1);
  });

  testWidgets('stops on its own just before the maximum duration', (
    tester,
  ) async {
    final controller = FakeMovementCaptureController();
    RawCapture? result;
    await _pumpView(
      tester,
      controller,
      maximumSeconds: 6,
      onResult: (value) => result = value,
    );
    controller.emit(recordingState(count: 2));
    await tester.pump();

    await tester.pump(const Duration(seconds: 5));
    expect(controller.stopped, 0);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(controller.stopped, 1);
    expect(result?.measuredDuration, lessThan(const Duration(seconds: 6)));
  });

  testWidgets('a manual stop after the minimum returns the recording', (
    tester,
  ) async {
    final controller = FakeMovementCaptureController();
    RawCapture? result;
    await _pumpView(tester, controller, onResult: (value) => result = value);
    controller.emit(recordingState(count: 4));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Stop recording'), findsOneWidget);
    await tester.tap(find.byKey(VerilyTestKeys.movementCaptureStop));
    await tester.pumpAndSettle();

    expect(controller.stopped, 1);
    expect(result?.repetitions, 4);
  });

  testWidgets('records without live counting when tracking is unavailable', (
    tester,
  ) async {
    final controller = FakeMovementCaptureController();
    await _pumpView(tester, controller);
    controller.emit(
      const MovementCaptureState(
        phase: MovementCapturePhase.ready,
        liveCounting: MovementLiveCounting.unavailable,
      ),
    );
    await tester.pump();

    expect(
      find.text(
        "Live counting isn't available here. Record your set and it will be "
        'checked after you submit.',
      ),
      findsOneWidget,
    );
    expect(
      _button(tester, VerilyTestKeys.movementCaptureStart).onPressed,
      isNotNull,
    );

    controller.emit(
      const MovementCaptureState(
        phase: MovementCapturePhase.recording,
        liveCounting: MovementLiveCounting.unavailable,
      ),
    );
    await tester.pump();
    expect(find.byKey(VerilyTestKeys.movementCaptureCount), findsNothing);
  });

  testWidgets('explains camera failures and retries', (tester) async {
    final controller = FakeMovementCaptureController();
    await _pumpView(tester, controller);
    controller.emit(
      const MovementCaptureState(
        phase: MovementCapturePhase.failed,
        failure: MovementCaptureFailure.permissionDenied,
      ),
    );
    await tester.pump();

    expect(find.text('Camera access is off'), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.captureOpenSettings), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.movementCaptureStart), findsNothing);
    await tester.tap(find.byKey(VerilyTestKeys.movementCaptureRetry));
    await tester.pump();
    expect(controller.opened, 2);
  });

  testWidgets('asks for the microphone when the word must be heard', (
    tester,
  ) async {
    final controller = FakeMovementCaptureController();
    await _pumpView(tester, controller, spokenWord: 'pelican');
    controller.emit(
      const MovementCaptureState(
        phase: MovementCapturePhase.failed,
        failure: MovementCaptureFailure.microphonePermissionDenied,
      ),
    );
    await tester.pump();

    expect(find.text('Microphone access is off'), findsOneWidget);
  });

  testWidgets('shows the spoken word before and while recording', (
    tester,
  ) async {
    final controller = FakeMovementCaptureController();
    await _pumpView(tester, controller, spokenWord: 'pelican');
    controller.emit(
      const MovementCaptureState(
        phase: MovementCapturePhase.ready,
        liveCounting: MovementLiveCounting.active,
      ),
    );
    await tester.pump();
    expect(find.text('Say “pelican”'), findsOneWidget);
    expect(find.text('When you record, say this word clearly'), findsOneWidget);

    controller.emit(recordingState(count: 1));
    await tester.pump();
    expect(find.text('Say “pelican”'), findsOneWidget);
  });

  testWidgets('ball skills show the current and best runs', (tester) async {
    final controller = FakeMovementCaptureController();
    await _pumpView(
      tester,
      controller,
      kind: ActionMovementKind.footballKickUps,
    );
    expect(find.text('10 kick-ups'), findsOneWidget);

    controller.emit(
      const MovementCaptureState(
        phase: MovementCapturePhase.recording,
        liveCounting: MovementLiveCounting.active,
        progress: MovementProgress(
          count: 3,
          best: 7,
          depth: 0,
          tracking: true,
          cue: MovementCue.perform,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('Best run: 7'), findsOneWidget);
    expect(find.text('Keep the ball up'), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.movementCaptureDepthMeter), findsNothing);
  });

  testWidgets('closing leaves without a recording', (tester) async {
    final controller = FakeMovementCaptureController();
    var closedWith = const Object();
    await _pumpView(
      tester,
      controller,
      onResult: (value) => closedWith = value ?? 'none',
    );

    await tester.tap(find.byKey(VerilyTestKeys.movementCaptureClose));
    await tester.pumpAndSettle();

    expect(closedWith, 'none');
    expect(controller.disposed, isTrue);
  });
}

ButtonStyleButton _button(WidgetTester tester, Key key) =>
    tester.widget<ButtonStyleButton>(
      find.descendant(
        of: find.byKey(key),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );

Future<void> _pumpView(
  WidgetTester tester,
  FakeMovementCaptureController controller, {
  int minimumSeconds = 3,
  int maximumSeconds = 120,
  String? spokenWord,
  ActionMovementKind kind = ActionMovementKind.squats,
  void Function(RawCapture?)? onResult,
}) async {
  final requirement = testRequirement(
    ActionRequirementKind.video,
    minDurationSeconds: minimumSeconds,
    maxDurationSeconds: maximumSeconds,
    movementKind: kind,
    targetRepetitions: 10,
  );
  await pumpVerilyPage(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute<RawCapture>(
                builder: (context) => MovementCaptureView(
                  requirement: requirement,
                  spokenWord: spokenWord,
                  onRecorded: (raw) => Navigator.of(context).pop(raw),
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
            );
            onResult?.call(result);
          },
          child: const Text('open'),
        ),
      ),
    ),
    physicalSize: const Size(1080, 2400),
    devicePixelRatio: 3,
    overrides: [
      movementCaptureControllerFactoryProvider.overrideWithValue(
        (kind, {required recordAudio}) => controller,
      ),
    ],
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
