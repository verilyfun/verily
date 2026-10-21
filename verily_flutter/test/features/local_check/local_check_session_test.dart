import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/capture/models/pinned_model.dart';
import 'package:verily_flutter/features/local_check/local_check_session.dart';
import 'package:verily_flutter/features/local_check/local_check_tally.dart';
import 'package:verily_flutter/features/local_check/local_check_vision.dart';

import '../capture/support/fakes.dart';

LocalCheckSession _session(
  FakeLocalCheckVision vision, {
  bool photo = false,
  int minFrames = 2,
}) => LocalCheckSession(
  check: thumbsUpCheck(minFrames: minFrames),
  model: testGestureModel,
  photo: photo,
  vision: (check, model) async => vision,
);

final class _FailingVision implements LocalCheckVision {
  int calls = 0;

  @override
  Future<LocalCheckFrame> observe(_) async {
    calls++;
    throw StateError('inference failed');
  }

  @override
  Future<void> close() async {}
}

void main() {
  group('LocalCheckSession', () {
    test('loads the model, then scores frames', () async {
      final vision = FakeLocalCheckVision();
      final session = _session(vision);
      addTearDown(session.dispose);
      expect(session.availability, LocalCheckAvailability.loading);

      await session.start();
      expect(session.availability, LocalCheckAvailability.active);

      vision.frames.addAll([
        const LocalCheckFrame(score: 0.9),
        const LocalCheckFrame(score: 0.7),
      ]);
      await session.analyse(testCameraFrame(1));
      await session.analyse(testCameraFrame(2));

      expect(session.tally.matched, 2);
      expect(session.passed, isTrue);
    });

    test(
      'a model that will not load leaves capture without the check',
      () async {
        final session = LocalCheckSession(
          check: thumbsUpCheck(),
          model: testGestureModel,
          photo: false,
          vision: (check, model) async => throw PinnedModelException(
            LocalCheckPinnedModel(model),
            'digest mismatch',
          ),
        );
        addTearDown(session.dispose);
        final reported = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = reported.add;
        addTearDown(() => FlutterError.onError = previous);

        await session.start();

        expect(session.availability, LocalCheckAvailability.unavailable);
        expect(session.passed, isFalse);
        expect(session.advisory(), isNull);
        expect(reported, hasLength(1));
      },
    );

    test(
      'a recording counts from zero and the preview is not counted',
      () async {
        final vision = FakeLocalCheckVision();
        final session = _session(vision);
        addTearDown(session.dispose);
        await session.start();
        vision.frames.addAll([
          const LocalCheckFrame(score: 0.9),
          const LocalCheckFrame(score: 0.9),
        ]);
        await session.analyse(testCameraFrame(1));
        await session.analyse(testCameraFrame(2));
        expect(session.passed, isTrue);

        session.startRecording();
        expect(session.recording, isTrue);
        expect(session.tally.analysed, 0);
        expect(session.passed, isFalse);
        expect(session.advisory(), isNull);
      },
    );

    test('the advisory carries the pinned model and the best score', () async {
      final vision = FakeLocalCheckVision();
      final session = _session(vision);
      addTearDown(session.dispose);
      await session.start();
      session.startRecording();
      vision.frames.addAll([
        const LocalCheckFrame(score: 0.2),
        const LocalCheckFrame(score: 0.83),
        const LocalCheckFrame(score: 0.7),
      ]);
      for (var index = 0; index < 3; index++) {
        await session.analyse(testCameraFrame(index));
      }

      final advice = session.advisory()!;
      expect(advice.modelId, testGestureModel.modelId);
      expect(advice.modelSha256, testGestureModel.sha256);
      expect(advice.label, 'Thumb_Up');
      expect(advice.score, 0.83);
      expect(advice.matchedFrames, 2);
    });

    test('repeated frame failures stop the live check', () async {
      final vision = _FailingVision();
      final session = LocalCheckSession(
        check: thumbsUpCheck(),
        model: testGestureModel,
        photo: false,
        vision: (check, model) async => vision,
      );
      addTearDown(session.dispose);
      final previous = FlutterError.onError;
      FlutterError.onError = (_) {};
      addTearDown(() => FlutterError.onError = previous);
      await session.start();

      for (var index = 0; index < 4; index++) {
        await session.analyse(testCameraFrame(index));
      }
      expect(session.availability, LocalCheckAvailability.active);

      await session.analyse(testCameraFrame(5));
      expect(session.availability, LocalCheckAvailability.unavailable);

      await session.analyse(testCameraFrame(6));
      expect(vision.calls, 5, reason: 'no frames are scored after it stops');
    });

    test('closing releases the model', () async {
      final vision = FakeLocalCheckVision();
      final session = _session(vision);
      await session.start();
      session.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(vision.closed, isTrue);
    });
  });

  group('LocalCheckPinnedModel', () {
    test('accepts the server pins', () {
      for (final model in [testGestureModel, testObjectModel, testSoundModel]) {
        expect(LocalCheckPinnedModel(model).sha256, model.sha256);
      }
    });

    LocalCheckModelView pin({
      String? url,
      String? sha256,
      int? byteLength,
    }) => testGestureModel.copyWith(
      url: url,
      sha256: sha256,
      byteLength: byteLength,
    );

    for (final (reason, model) in [
      (
        'plain http',
        pin(url: testGestureModel.url.replaceFirst('https', 'http')),
      ),
      ('another host', pin(url: 'https://example.com/mediapipe-models/x.task')),
      (
        'outside the model bucket',
        pin(url: 'https://storage.googleapis.com/other-bucket/x.task'),
      ),
      ('a query', pin(url: '${testGestureModel.url}?v=2')),
      ('a short digest', pin(sha256: 'abc123')),
      (
        'an uppercase digest',
        pin(sha256: testGestureModel.sha256.toUpperCase()),
      ),
      ('no size', pin(byteLength: 0)),
      ('a huge size', pin(byteLength: 64 * 1024 * 1024)),
    ]) {
      test('refuses $reason before downloading', () {
        expect(
          () => LocalCheckPinnedModel(model),
          throwsA(isA<PinnedModelException>()),
        );
      });
    }
  });
}
