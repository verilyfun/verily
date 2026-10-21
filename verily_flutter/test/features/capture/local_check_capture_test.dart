import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/capture/models/pinned_model.dart';
import 'package:verily_flutter/features/local_check/local_check_tally.dart';
import 'package:verily_flutter/features/local_check/local_check_vision.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../support/test_app.dart';
import 'support/fakes.dart';

const _match = LocalCheckFrame(score: 0.82, subjectSeen: true);
const _hand = LocalCheckFrame(score: 0, subjectSeen: true);

ActionRequirementView _gestureVideo({bool word = false}) => testRequirement(
  ActionRequirementKind.video,
  spokenChallengeRequired: word,
  minDurationSeconds: 3,
  localCheck: thumbsUpCheck(),
  localCheckModel: testGestureModel,
);

void main() {
  group('a gesture check on video', () {
    testWidgets('guides live, stops by itself, and sends the advice', (
      tester,
    ) async {
      final harness = CaptureHarness();
      final results = await _open(tester, harness, _gestureVideo());

      expect(harness.camera.analyseFrames, isTrue);
      expect(harness.visionRequests.single.$1.label, 'Thumb_Up');
      expect(harness.visionRequests.single.$2, same(testGestureModel));
      expect(find.text('Quick check: Thumbs up'), findsOneWidget);
      expect(find.text("We can't see your “Thumbs up” yet"), findsOneWidget);

      harness.vision.frames.add(_hand);
      await harness.camera.deliverFrames(1);
      await tester.pump();
      expect(
        find.text('We can see your hand. Now show “Thumbs up”'),
        findsOneWidget,
      );

      // Framing the shot never counts towards the recording.
      harness.vision.frames.addAll([_match, _match, _match]);
      await harness.camera.deliverFrames(3);
      await tester.pump();
      expect(find.text("Start recording when you're ready"), findsOneWidget);

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pump();
      expect(harness.camera.recordingsStarted, 1);

      harness.vision.frames.addAll([_match, _match, _match]);
      await harness.camera.deliverFrames(3);
      await tester.pump();
      expect(find.text('Keep going a moment'), findsOneWidget);
      expect(
        harness.camera.recordingsStopped,
        0,
        reason: 'the recording is shorter than the action asks',
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(harness.camera.recordingsStopped, 1);
      expect(find.text('Check your proof'), findsOneWidget);
      expect(
        find.text(
          "The phone's quick check is only a guide. Verily checks your "
          'proof again before it counts.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      final advice = harness.gateway.confirmed.single.deviceLocalCheck!;
      expect(advice.modelId, testGestureModel.modelId);
      expect(advice.modelSha256, testGestureModel.sha256);
      expect(advice.label, 'Thumb_Up');
      expect(advice.score, 0.82);
      expect(advice.matchedFrames, 3);
      expect(results.single, same(harness.gateway.result));
    });

    testWidgets('never cuts off a spoken word', (tester) async {
      final harness = CaptureHarness();
      await _open(tester, harness, _gestureVideo(word: true));

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pump();
      harness.vision.frames.addAll([_match, _match, _match]);
      await harness.camera.deliverFrames(3);
      await tester.pump(const Duration(seconds: 4));

      expect(harness.camera.recordingsStopped, 0);
      expect(find.text('Say your word, then stop'), findsOneWidget);

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStop));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();
      expect(
        harness.gateway.confirmed.single.deviceLocalCheck?.matchedFrames,
        3,
      );
    });

    testWidgets('a model that will not load still lets the person record', (
      tester,
    ) async {
      final harness = CaptureHarness(
        visionFailure: PinnedModelException(
          LocalCheckPinnedModel(testGestureModel),
          'digest mismatch',
        ),
      );
      await _open(tester, harness, _gestureVideo());
      expect(tester.takeException(), isA<PinnedModelException>());

      expect(
        find.text('Verily checks for “Thumbs up” after you finish'),
        findsOneWidget,
      );
      expect(harness.camera.analyser, isNull);

      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byKey(VerilyTestKeys.captureRecordStop));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();

      expect(harness.gateway.confirmed.single.deviceLocalCheck, isNull);
    });

    testWidgets('a phone without the runtime records a plain video', (
      tester,
    ) async {
      final harness = CaptureHarness(localCheckSupported: false);
      await _open(tester, harness, _gestureVideo());

      expect(harness.camera.analyseFrames, isFalse);
      expect(harness.visionRequests, isEmpty);
      expect(
        find.text('Verily checks for “Thumbs up” after you finish'),
        findsOneWidget,
      );
    });
  });

  group('an object check on a photo', () {
    testWidgets('takes the photo once the thing holds in view', (
      tester,
    ) async {
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
      );

      harness.vision.frames.add(const LocalCheckFrame(score: 0.3));
      await harness.camera.deliverFrames(1);
      await tester.pump();
      expect(
        find.text('Almost. Bring “Cup” closer or into better light'),
        findsOneWidget,
      );

      harness.vision.frames.addAll([
        const LocalCheckFrame(score: 0.7),
        const LocalCheckFrame(score: 0.75),
      ]);
      await harness.camera.deliverFrames(2);
      await tester.pump();
      expect(find.text('Got it, hold it there'), findsOneWidget);
      expect(harness.camera.photosTaken, 0);

      harness.vision.frames.add(const LocalCheckFrame(score: 0.72));
      await harness.camera.deliverFrames(1);
      await tester.pumpAndSettle();

      expect(harness.camera.photosTaken, 1);
      await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
      await tester.pumpAndSettle();
      final advice = harness.gateway.confirmed.single.deviceLocalCheck!;
      expect(advice.label, 'cup');
      expect(advice.modelId, testObjectModel.modelId);
      expect(advice.score, 0.75);
      expect(advice.matchedFrames, 3);
    });
  });

  group('a sound check', () {
    testWidgets(
      'says Verily listens after the recording, and sends no advice',
      (
        tester,
      ) async {
        final harness = CaptureHarness();
        await _open(
          tester,
          harness,
          testRequirement(
            ActionRequirementKind.audio,
            minDurationSeconds: 3,
            localCheck: ActionLocalCheck(
              task: LocalCheckTask.sound,
              label: 'Clapping',
              minScore: 0.4,
              minFrames: 2,
            ),
            localCheckModel: testSoundModel,
          ),
        );

        expect(harness.visionRequests, isEmpty);
        expect(
          find.text('Verily listens for “Clapping” after you finish'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));
        await tester.tap(find.byKey(VerilyTestKeys.captureRecordStop));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
        await tester.pumpAndSettle();

        expect(harness.gateway.confirmed.single.deviceLocalCheck, isNull);
      },
    );
  });

  testWidgets('a proof without a quick check sends no advice', (tester) async {
    final harness = CaptureHarness();
    await _open(
      tester,
      harness,
      testRequirement(ActionRequirementKind.video, minDurationSeconds: 3),
    );

    expect(harness.camera.analyseFrames, isFalse);
    expect(find.byKey(VerilyTestKeys.captureLocalCheckGuide), findsNothing);
    await tester.tap(find.byKey(VerilyTestKeys.captureRecordStart));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byKey(VerilyTestKeys.captureRecordStop));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(VerilyTestKeys.captureReviewSend));
    await tester.pumpAndSettle();

    expect(harness.gateway.confirmed.single.deviceLocalCheck, isNull);
  });
}

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
