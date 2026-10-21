import 'dart:io';
import 'dart:typed_data';

import 'package:mp_audio/mp_audio.dart';
import 'package:mp_core/mp_core.dart';
import 'package:mp_vision/mp_vision.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_media.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_models.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_replay.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Replays a local check with the same pinned MediaPipe model the phone ran,
/// through the MP Dart packages (`mp_vision`, `mp_audio`).
///
/// The model file is verified against its pinned SHA-256 before every run.
/// Each task is created for one replay and closed afterwards. Any failure to
/// load the native runtime, fetch the model, or decode the media is reported
/// as [LocalCheckReplayUnavailable], never as a verdict.
class MpLocalCheckReplayer implements LocalCheckReplayer {
  MpLocalCheckReplayer({
    required this.models,
    this.decoder = const FfmpegLocalCheckMediaDecoder(),
    this.maxAudioSeconds = 300,
  });

  /// The production replayer: models cached per `VERILY_LOCAL_CHECK_MODEL_CACHE`
  /// and ffmpeg per `VERILY_FFMPEG_PATH` / `VERILY_FFPROBE_PATH`.
  factory MpLocalCheckReplayer.fromEnvironment(
    Map<String, String> environment,
  ) => MpLocalCheckReplayer(
    models: PinnedLocalCheckModelStore.fromEnvironment(environment),
    decoder: FfmpegLocalCheckMediaDecoder.fromEnvironment(environment),
  );

  final LocalCheckModelSource models;
  final LocalCheckMediaDecoder decoder;
  final int maxAudioSeconds;

  @override
  Future<LocalCheckReplay> replay({
    required ActionLocalCheck check,
    required LocalCheckModel model,
    required Uint8List media,
    required String mimeType,
  }) async {
    if (model.task != check.task) {
      throw ArgumentError.value(model, 'model', 'does not run this task');
    }
    final stopwatch = Stopwatch()..start();
    try {
      final file = await models.load(model);
      final scores = switch (check.task) {
        LocalCheckTask.gesture => await _gestures(
          file,
          check,
          await decoder.frames(
            media,
            mimeType: mimeType,
            maxFrames: LocalCheckBounds.maxFrames,
          ),
        ),
        LocalCheckTask.object => await _objects(
          file,
          check,
          await decoder.frames(
            media,
            mimeType: mimeType,
            maxFrames: LocalCheckBounds.maxFrames,
          ),
        ),
        LocalCheckTask.sound => await _sounds(
          file,
          check,
          await decoder.audio(
            media,
            mimeType: mimeType,
            maxSeconds: maxAudioSeconds,
          ),
        ),
      };
      return LocalCheckReplayScores(scores, latency: stopwatch.elapsed);
    } on LocalCheckUnavailableException catch (error) {
      return LocalCheckReplayUnavailable(error.code);
    } on _RuntimeUnavailable {
      return const LocalCheckReplayUnavailable(
        LocalCheckUnavailableCode.runtimeUnavailable,
      );
    } on Object {
      return const LocalCheckReplayUnavailable(
        LocalCheckUnavailableCode.replayFailed,
      );
    }
  }

  Future<List<double>> _gestures(
    File model,
    ActionLocalCheck check,
    List<DecodedFrame> frames,
  ) async {
    final recognizer = await _create(
      () => GestureRecognizer.create(
        GestureRecognizerOptions(
          baseOptions: BaseOptions(modelAsset: ModelAsset.path(model.path)),
          numHands: 2,
          cannedGesturesClassifierOptions: ClassifierOptions(
            categoryAllowlist: [check.label],
          ),
        ),
      ),
    );
    try {
      return [
        for (final frame in frames)
          _bestScore(
            (await recognizer.recognize(_image(frame))).gestures.expand(
              (hand) => hand,
            ),
            check.label,
          ),
      ];
    } finally {
      await recognizer.close();
    }
  }

  Future<List<double>> _objects(
    File model,
    ActionLocalCheck check,
    List<DecodedFrame> frames,
  ) async {
    final detector = await _create(
      () => ObjectDetector.create(
        ObjectDetectorOptions(
          baseOptions: BaseOptions(modelAsset: ModelAsset.path(model.path)),
          classifierOptions: ClassifierOptions(
            maxResults: 5,
            categoryAllowlist: [check.label],
          ),
        ),
      ),
    );
    try {
      return [
        for (final frame in frames)
          _bestScore(
            (await detector.detect(_image(frame))).detections.expand(
              (detection) => detection.categories,
            ),
            check.label,
          ),
      ];
    } finally {
      await detector.close();
    }
  }

  Future<List<double>> _sounds(
    File model,
    ActionLocalCheck check,
    DecodedAudio audio,
  ) async {
    final classifier = await _create(
      () => AudioClassifier.create(
        AudioClassifierOptions(
          baseOptions: BaseOptions(modelAsset: ModelAsset.path(model.path)),
          classifierOptions: ClassifierOptions(
            categoryAllowlist: [check.label],
          ),
        ),
      ),
    );
    try {
      final result = await classifier.classify(
        AudioData(
          channelCount: 1,
          sampleRateHz: audio.sampleRateHz.toDouble(),
          samples: audio.samples,
        ),
      );
      return [
        for (final window in result.classifications)
          _bestScore(
            window.classifications.expand((head) => head.categories),
            check.label,
          ),
      ];
    } finally {
      await classifier.close();
    }
  }

  /// Creating a task is where a missing native runtime shows up: the MP
  /// packages throw from their native loader, so any failure here means the
  /// runtime (or the model inside it) cannot run on this host.
  Future<T> _create<T>(Future<T> Function() create) async {
    try {
      return await create();
    } on Object {
      throw const _RuntimeUnavailable();
    }
  }
}

MpImage _image(DecodedFrame frame) => MpImage.uint8(
  width: frame.width,
  height: frame.height,
  format: MpImageFormat.srgb,
  data: frame.rgb,
);

double _bestScore(Iterable<Category> categories, String label) {
  var best = 0.0;
  for (final category in categories) {
    if (category.categoryName == label && category.score > best) {
      best = category.score;
    }
  }
  return best;
}

final class _RuntimeUnavailable implements Exception {
  const _RuntimeUnavailable();
}
