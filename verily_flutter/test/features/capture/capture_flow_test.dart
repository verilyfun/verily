import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/features/capture/camera/capture_camera.dart';
import 'package:verily_flutter/features/capture/movement/movement_capture_controller.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../support/test_app.dart';
import 'support/fakes.dart';

void main() {
  group('spoken challenge', () {
    testWidgets('fetches the word before the camera opens and shows it', (
      tester,
    ) async {
      final harness = CaptureHarness();
      final results = await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.video,
          spokenChallengeRequired: true,
        ),
      );

      expect(harness.actions.requestedFor, [testRequirementId]);
      expect(harness.cameraRequests, [
        (recordAudio: true, lens: CaptureLens.back),
      ]);
      expect(find.byKey(VerilyTestKeys.captureChallengeWord), findsOneWidget);
      expect(find.text('Say “pelican”'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Say the word pelican while you record'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pump();
      expect(harness.camera.recordingsStarted, 1);
      expect(
        find.text('Say “pelican”'),
        findsOneWidget,
        reason: 'the word stays up while recording',
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStop));
      await tester.pumpAndSettle();

      expect(find.text('Check your proof'), findsOneWidget);
      expect(
        find.text(
          'Did you say “pelican”? It needs to be heard in the recording.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      expect(harness.gateway.requestedContentTypes, ['video/mp4']);
      expect(harness.gateway.confirmed.single.durationSeconds, 12);
      expect(results.single, same(harness.gateway.result));
    });

    testWidgets('never opens the camera when the word cannot be fetched', (
      tester,
    ) async {
      final harness = CaptureHarness(
        words: [Exception('offline'), 'pelican'],
      );
      await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.video,
          spokenChallengeRequired: true,
        ),
      );

      expect(find.text("We couldn't get your word"), findsOneWidget);
      expect(harness.cameraRequests, isEmpty);
      expect(find.byKey(VerilyTestKeys.captureRecordStart), findsNothing);

      await tester.tap(find.byKey(VerilyTestKeys.captureChallengeRetry));
      await tester.pumpAndSettle();

      expect(harness.actions.requestedFor, hasLength(2));
      expect(find.text('Say “pelican”'), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.captureRecordStart), findsOneWidget);
    });

    testWidgets('closing from a failed fetch returns nothing', (tester) async {
      final harness = CaptureHarness(words: [Exception('offline')]);
      final results = await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.audio,
          spokenChallengeRequired: true,
        ),
      );

      await tester.tap(find.byKey(VerilyTestKeys.captureClose));
      await tester.pumpAndSettle();

      expect(results, [null]);
      expect(harness.recorder.started, 0);
    });

    testWidgets('a photo never asks for a word', (tester) async {
      final harness = CaptureHarness();
      await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.photo,
          spokenChallengeRequired: true,
        ),
      );

      expect(harness.actions.requestedFor, isEmpty);
      expect(find.byKey(VerilyTestKeys.captureChallengeWord), findsNothing);
      expect(find.byKey(VerilyTestKeys.captureShutter), findsOneWidget);
    });
  });

  group('capture window', () {
    testWidgets('opens before the camera and binds the proof sent from it', (
      tester,
    ) async {
      final harness = CaptureHarness();
      await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.photo),
      );

      expect(harness.gateway.windowsOpened, 1);
      expect(harness.cameraRequests, hasLength(1));

      await tester.tap(find.byKey(VerilyTestKeys.captureShutter));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      expect(
        harness.gateway.confirmed.single.captureChallengeId,
        FakeEvidenceGateway.windowId,
      );
      expect(harness.gateway.windowsOpened, 1);
    });

    testWidgets('never opens the camera while the window cannot open', (
      tester,
    ) async {
      final harness = CaptureHarness(
        gateway: FakeEvidenceGateway(windowFailures: 1),
      );
      await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.photo),
      );

      expect(find.text("We couldn't start the capture"), findsOneWidget);
      expect(harness.cameraRequests, isEmpty);
      expect(find.byKey(VerilyTestKeys.captureShutter), findsNothing);

      await tester.tap(find.byKey(VerilyTestKeys.captureChallengeRetry));
      await tester.pumpAndSettle();

      expect(harness.gateway.windowsOpened, 1);
      expect(find.byKey(VerilyTestKeys.captureShutter), findsOneWidget);
    });

    testWidgets('a recording waits for both the window and its word', (
      tester,
    ) async {
      final harness = CaptureHarness(
        gateway: FakeEvidenceGateway(windowFailures: 1),
      );
      await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.video,
          spokenChallengeRequired: true,
        ),
      );

      expect(find.text("We couldn't start the capture"), findsOneWidget);
      expect(harness.cameraRequests, isEmpty);

      await tester.tap(find.byKey(VerilyTestKeys.captureChallengeRetry));
      await tester.pumpAndSettle();

      expect(find.text('Say “pelican”'), findsOneWidget);
      expect(harness.actions.requestedFor, hasLength(1));
    });
  });

  group('photo', () {
    testWidgets('takes a still, reviews it, and sends it', (tester) async {
      final harness = CaptureHarness();
      final results = await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.photo),
      );

      expect(harness.cameraRequests.single.recordAudio, isFalse);
      expect(find.text('Live'), findsOneWidget);

      await tester.tap(find.byKey(VerilyTestKeys.captureShutter));
      await tester.pumpAndSettle();

      expect(harness.camera.photosTaken, 1);
      expect(
        find.text('Make sure the photo shows the action clearly.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fake-capture-preview')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      expect(harness.gateway.requestedContentTypes, ['image/jpeg']);
      expect(harness.gateway.confirmed.single.durationSeconds, isNull);
      expect(results.single, isNotNull);
    });

    testWidgets('refuses a format the requirement does not take', (
      tester,
    ) async {
      final harness = CaptureHarness();
      await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.photo,
          acceptedContentTypes: const ['image/heic'],
        ),
      );

      await tester.tap(find.byKey(VerilyTestKeys.captureShutter));
      await tester.pumpAndSettle();

      expect(
        find.text("This action can't take what this phone recorded"),
        findsOneWidget,
      );
      expect(harness.gateway.uploaded, isEmpty);

      await tester.tap(find.byKey(VerilyTestKeys.captureReviewRetake));
      await tester.pumpAndSettle();
      expect(find.byKey(VerilyTestKeys.captureShutter), findsOneWidget);
    });

    testWidgets('explains denied camera access and opens settings', (
      tester,
    ) async {
      final harness = CaptureHarness(
        cameraFailure: CaptureCameraFailure.cameraPermissionDenied,
      );
      await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.photo),
      );

      expect(find.text('Camera access is off'), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.captureShutter), findsNothing);

      await tester.tap(find.byKey(VerilyTestKeys.captureOpenSettings));
      await tester.pump();
      expect(harness.settingsOpened, 1);
    });
  });

  group('audio', () {
    testWidgets('records m4a with a level meter and sends audio/mp4', (
      tester,
    ) async {
      final harness = CaptureHarness();
      final results = await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.audio,
          spokenChallengeRequired: true,
        ),
      );

      expect(find.text('Say “pelican”'), findsOneWidget);
      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pump();
      expect(harness.recorder.started, 1);

      harness.recorder.emitLevel(0.5);
      await tester.pump(const Duration(seconds: 2));
      expect(find.bySemanticsLabel('Sound level 50%'), findsOneWidget);
      expect(find.text('0:02 of 5:00'), findsOneWidget);

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStop));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      expect(harness.gateway.requestedContentTypes, ['audio/mp4']);
      expect(harness.gateway.uploaded.single.spokenChallengeWord, 'pelican');
      expect(results.single, isNotNull);
    });

    testWidgets('explains denied microphone access', (tester) async {
      final harness = CaptureHarness(
        recorder: FakeCaptureRecorder(permission: false),
      );
      await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.audio),
      );

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pumpAndSettle();

      expect(find.text('Microphone access is off'), findsOneWidget);
      expect(harness.recorder.started, 0);
      await tester.tap(find.byKey(VerilyTestKeys.captureOpenSettings));
      await tester.pump();
      expect(harness.settingsOpened, 1);
    });
  });

  group('video', () {
    testWidgets('retake discards the clip and records again', (tester) async {
      final harness = CaptureHarness();
      final results = await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.video),
      );

      await _record(tester, const Duration(seconds: 3));
      expect(find.text('12 seconds recorded'), findsOneWidget);

      await tester.tap(find.byKey(VerilyTestKeys.captureReviewRetake));
      await tester.pumpAndSettle();
      expect(find.byKey(VerilyTestKeys.captureRecordStart), findsOneWidget);
      expect(harness.gateway.uploaded, isEmpty);

      await _record(tester, const Duration(seconds: 4));
      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      expect(harness.cameras, hasLength(2));
      expect(harness.cameras.first.disposed, isTrue);
      expect(harness.gateway.uploaded.single.file.name, 'camera2-clip-1.mp4');
      expect(results.single, isNotNull);
    });

    testWidgets('back from the review returns to the camera', (tester) async {
      final harness = CaptureHarness();
      final results = await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.video),
      );
      await _record(tester, const Duration(seconds: 2));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(VerilyTestKeys.captureRecordStart), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets('a recording under the minimum cannot be sent', (
      tester,
    ) async {
      final harness = CaptureHarness(duration: const Duration(seconds: 3));
      await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.video, minDurationSeconds: 5),
      );

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pump();
      expect(find.text('Record at least 5 seconds'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStop));
      await tester.pumpAndSettle();

      expect(find.text('Record at least 5 seconds'), findsOneWidget);
      expect(_action(tester, VerilyTestKeys.captureReviewSend).onPressed, null);
    });

    testWidgets('a recording past the maximum cannot be sent', (tester) async {
      final harness = CaptureHarness(duration: const Duration(seconds: 9));
      await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.video, maxDurationSeconds: 60),
      );
      harness.duration = const Duration(seconds: 61);

      await _record(tester, const Duration(seconds: 2));

      expect(
        find.text(
          'This recording runs past the 1:00 limit. Retake a shorter one.',
        ),
        findsOneWidget,
      );
      expect(_action(tester, VerilyTestKeys.captureReviewSend).onPressed, null);
    });

    testWidgets('stops on its own just before the maximum', (tester) async {
      final harness = CaptureHarness(duration: const Duration(seconds: 3));
      await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.video, maxDurationSeconds: 3),
      );

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(harness.camera.recordingsStopped, 0);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(harness.camera.recordingsStopped, 1);
      expect(find.text('Check your proof'), findsOneWidget);
    });

    testWidgets('leaving the app mid-recording discards it', (tester) async {
      final harness = CaptureHarness();
      await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.video),
      );

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(harness.camera.closes, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(harness.camera.opened, 2);
      expect(
        find.text(
          "Recording stopped when you left the app. Start again when you're ready.",
        ),
        findsOneWidget,
      );
    });
  });

  group('sending', () {
    testWidgets('a failed upload keeps the capture and sends it again', (
      tester,
    ) async {
      final harness = CaptureHarness(
        gateway: FakeEvidenceGateway(uploads: [false, true]),
      );
      final results = await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.video),
      );
      await _record(tester, const Duration(seconds: 2));

      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      expect(find.text("Your proof didn't send"), findsOneWidget);
      expect(find.text('Check your proof'), findsOneWidget);
      expect(results, isEmpty);

      await tester.tap(find.byKey(VerilyTestKeys.captureSendAgain));
      await tester.pumpAndSettle();

      expect(harness.gateway.uploaded, hasLength(2));
      expect(
        harness.gateway.uploaded.first.sha256Digest,
        harness.gateway.uploaded.last.sha256Digest,
        reason: 'the same capture is sent again',
      );
      expect(harness.camera.recordingsStarted, 1);
      expect(results.single, isNotNull);
    });

    testWidgets('a phone that cannot vouch for the capture is told plainly', (
      tester,
    ) async {
      final harness = CaptureHarness(
        gateway: FakeEvidenceGateway(integrityRequired: true),
      );
      final results = await _open(
        tester,
        harness,
        testRequirement(ActionRequirementKind.photo),
      );
      await tester.tap(find.byKey(VerilyTestKeys.captureShutter));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      expect(
        find.text("This phone couldn't vouch for the capture"),
        findsOneWidget,
      );
      expect(harness.gateway.confirmed, isEmpty);
      expect(results, isEmpty);
    });
  });

  group('movement', () {
    testWidgets('counts reps live and sends the advisory count', (
      tester,
    ) async {
      final harness = CaptureHarness();
      final results = await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.video,
          spokenChallengeRequired: true,
          movementKind: ActionMovementKind.squats,
          targetRepetitions: 10,
        ),
      );

      final controller = harness.movementControllers.single;
      expect(controller.recordAudio, isTrue);
      expect(harness.cameraRequests, isEmpty);
      expect(find.text('Say “pelican”'), findsOneWidget);

      controller.emit(
        const MovementCaptureState(
          phase: MovementCapturePhase.ready,
          liveCounting: MovementLiveCounting.active,
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(VerilyTestKeys.movementCaptureStart));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(controller.started, 1);

      await tester.pump(const Duration(seconds: 2));
      controller.emit(recordingState(count: 10));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Check your proof'), findsOneWidget);
      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      final confirmation = harness.gateway.confirmed.single;
      expect(confirmation.deviceRepetitionCount, 10);
      expect(confirmation.deviceTrackerVersion, 'pose-lite-v1.squats-v1');
      expect(results.single, isNotNull);
    });

    testWidgets('falls back to a plain recording without live tracking', (
      tester,
    ) async {
      final harness = CaptureHarness(trackingSupported: false);
      await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.video,
          movementKind: ActionMovementKind.squats,
          targetRepetitions: 10,
        ),
      );

      expect(harness.movementControllers, isEmpty);
      expect(find.byKey(VerilyTestKeys.captureRecordStart), findsOneWidget);
    });
  });

  group('fits a Seeker at large text', () {
    for (final kind in [
      ActionRequirementKind.video,
      ActionRequirementKind.audio,
    ]) {
      testWidgets('${kind.name} capture with the challenge bubble', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final harness = CaptureHarness();
        await _open(
          tester,
          harness,
          testRequirement(
            kind,
            spokenChallengeRequired: true,
            minDurationSeconds: 5,
          ),
        );

        _expectOnScreen(
          tester,
          find.byKey(VerilyTestKeys.captureChallengeWord),
        );
        _expectOnScreen(tester, find.byKey(VerilyTestKeys.captureRecordStart));

        await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        _expectOnScreen(
          tester,
          find.byKey(VerilyTestKeys.captureChallengeWord),
        );
        _expectOnScreen(tester, find.text('Record at least 5 seconds'));
        _expectOnScreen(tester, find.byKey(VerilyTestKeys.captureRecordStop));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('movement capture with the word and a cue', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final harness = CaptureHarness();
      await _open(
        tester,
        harness,
        testRequirement(
          ActionRequirementKind.video,
          spokenChallengeRequired: true,
          movementKind: ActionMovementKind.burpees,
          targetRepetitions: 10,
        ),
      );
      harness.movementControllers.single.emit(recordingState(count: 3));
      await tester.pump();

      _expectOnScreen(tester, find.byKey(VerilyTestKeys.captureChallengeWord));
      _expectOnScreen(tester, find.byKey(VerilyTestKeys.movementCaptureCount));
      _expectOnScreen(tester, find.byKey(VerilyTestKeys.movementCaptureStop));
      expect(tester.takeException(), isNull);
    });

    testWidgets('review with the word check and a send problem', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
      );
      await _record(tester, const Duration(seconds: 2));
      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      _expectOnScreen(tester, find.byKey(VerilyTestKeys.captureReviewRetake));
      _expectOnScreen(tester, find.byKey(VerilyTestKeys.captureSendAgain));
      expect(tester.takeException(), isNull);
    });
  });
}

/// Pumps a launcher, opens the capture for [requirement], and collects
/// what it returns.
Future<List<EvidenceSubmissionResult?>> _open(
  WidgetTester tester,
  CaptureHarness harness,
  ActionRequirementView requirement,
) async {
  final results = <EvidenceSubmissionResult?>[];
  await pumpVerilyPage(
    tester,
    CaptureLauncher(requirement: requirement, onResult: results.add),
    overrides: harness.overrides,
    physicalSize: const Size(1080, 2400),
    devicePixelRatio: 2.625,
  );
  await openCapture(tester);
  return results;
}

Future<void> _record(WidgetTester tester, Duration length) async {
  await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
  await tester.pump();
  await tester.pump(length);
  await tester.tap(find.byKey(VerilyTestKeys.captureRecordStop));
  await tester.pumpAndSettle();
}

VerilyActionButton _action(WidgetTester tester, Key key) =>
    tester.widget<VerilyActionButton>(find.byKey(key));

void _expectOnScreen(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final screen =
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
  final rect = tester.getRect(finder);
  expect(
    screen.contains(rect.topLeft) && screen.contains(rect.bottomRight),
    isTrue,
    reason: '$finder at $rect is outside $screen',
  );
}
