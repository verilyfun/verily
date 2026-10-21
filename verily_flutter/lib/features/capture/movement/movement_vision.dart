import 'dart:typed_data';

import 'package:mp_camera/mp_camera.dart';
import 'package:mp_core/mp_core.dart';
import 'package:mp_vision/mp_vision.dart';

import 'package:verily_flutter/features/capture/movement/ball_tracking.dart';
import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';
import 'package:verily_flutter/features/capture/movement/movement_model_store.dart';
import 'package:verily_flutter/features/capture/movement/movement_models.dart';

/// Turns camera frames into upright pose observations.
abstract interface class MovementVision {
  Future<MovementObservation> observe(MpCameraFrame frame);

  Future<void> close();
}

/// Creates the vision pipeline; replaced in tests.
typedef MovementVisionFactory = Future<MovementVision> Function();

/// On-device MediaPipe pose landmarking, plus ball detection for ball
/// skills, in video mode.
///
/// Frames are rotated upright before inference so landmarks, joint angles,
/// and the preview share one coordinate space on every device. Each task
/// runs on its own isolate, so pose and ball detection run in parallel.
final class MediaPipeMovementVision implements MovementVision {
  MediaPipeMovementVision._(this._pose, this._objects);

  static Future<MovementVision> create(
    MovementModelStore models, {
    required bool detectBall,
  }) async {
    final pose = await PoseLandmarker.create(
      PoseLandmarkerOptions(
        baseOptions: BaseOptions(
          modelAsset: await models.load(MovementModel.pose),
        ),
        runningMode: VisionRunningMode.video,
      ),
    );
    if (!detectBall) return MediaPipeMovementVision._(pose, null);
    try {
      final objects = await ObjectDetector.create(
        ObjectDetectorOptions(
          baseOptions: BaseOptions(
            modelAsset: await models.load(MovementModel.objects),
          ),
          runningMode: VisionRunningMode.video,
          classifierOptions: ClassifierOptions(
            categoryAllowlist: const ['sports ball'],
            scoreThreshold: 0.2,
            maxResults: 3,
          ),
        ),
      );
      return MediaPipeMovementVision._(pose, objects);
    } on Object {
      await pose.close();
      rethrow;
    }
  }

  final PoseLandmarker _pose;
  final ObjectDetector? _objects;

  @override
  Future<MovementObservation> observe(MpCameraFrame frame) async {
    final source = frame.image;
    if (source is! MpImageUint8) {
      throw UnsupportedError('Camera frames must be 8-bit RGB or RGBA.');
    }
    final image = uprightImage(
      source,
      frame.processingOptions.rotationDegrees,
    );
    final objects = _objects;
    final (pose, detections) = await (
      _pose.detectForVideo(image, frame.timestampMs),
      objects == null
          ? Future<DetectionResult?>.value()
          : objects.detectForVideo(image, frame.timestampMs),
    ).wait;
    return MovementObservation(
      pose: pose.landmarks.firstOrNull ?? const [],
      aspectRatio: image.width / image.height,
      timestampMs: frame.timestampMs,
      ball: detections == null
          ? null
          : strongestBall(detections, image.width, image.height),
    );
  }

  @override
  Future<void> close() async {
    await Future.wait([_pose.close(), ?_objects?.close()]);
  }
}

/// The highest-scoring ball in [result], normalized to the image.
BallObservation? strongestBall(DetectionResult result, int width, int height) {
  Detection? strongest;
  var strongestScore = 0.0;
  for (final detection in result.detections) {
    final score = detection.categories.firstOrNull?.score ?? 0;
    if (score > strongestScore) {
      strongest = detection;
      strongestScore = score;
    }
  }
  if (strongest == null) return null;
  final box = strongest.boundingBox;
  return BallObservation(
    x: (box.left + box.width / 2) / width,
    y: (box.top + box.height / 2) / height,
    radius: (box.width > box.height ? box.width : box.height) / 2 / height,
    score: strongestScore,
  );
}

/// Rotates [image] clockwise by [rotationDegrees] into a new buffer.
///
/// This runs on the UI isolate for every analysed frame, so it writes bytes
/// directly instead of allocating per pixel.
MpImageUint8 uprightImage(MpImageUint8 image, int rotationDegrees) {
  if (rotationDegrees == 0) return image;
  if (rotationDegrees != 90 &&
      rotationDegrees != 180 &&
      rotationDegrees != 270) {
    throw ArgumentError.value(rotationDegrees, 'rotationDegrees');
  }
  final width = image.width;
  final height = image.height;
  final channels = image.format.channels;
  final source = image.data;
  final target = Uint8List(source.length);
  final swap = rotationDegrees != 180;
  final outWidth = swap ? height : width;

  var read = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = switch (rotationDegrees) {
        90 => x * outWidth + (height - 1 - y),
        180 => (height - 1 - y) * width + (width - 1 - x),
        _ => (width - 1 - x) * outWidth + y,
      };
      var write = pixel * channels;
      for (var channel = 0; channel < channels; channel++) {
        target[write++] = source[read++];
      }
    }
  }

  return MpImageUint8.adopt(
    width: outWidth,
    height: swap ? width : height,
    format: image.format,
    data: target,
  );
}
