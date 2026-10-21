import 'package:mp_camera/mp_camera.dart';
import 'package:mp_core/mp_core.dart';
import 'package:mp_vision/mp_vision.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/capture/models/pinned_model.dart';
import 'package:verily_flutter/features/capture/models/pinned_model_store.dart';
import 'package:verily_flutter/features/capture/movement/movement_vision.dart'
    show uprightImage;
import 'package:verily_flutter/features/local_check/local_check_tally.dart';

/// Scores camera frames for one quick check's label.
abstract interface class LocalCheckVision {
  Future<LocalCheckFrame> observe(MpCameraFrame frame);

  Future<void> close();
}

/// Creates the vision for a check and the model the server pinned for it;
/// replaced in tests.
typedef LocalCheckVisionFactory = Future<LocalCheckVision> Function(
  ActionLocalCheck check,
  LocalCheckModelView model,
);

/// The server's model pin, checked before anything is downloaded.
///
/// The SHA-256 the server sends is what the bytes are verified against. On
/// top of that the phone only fetches over https from Google's versioned
/// MediaPipe model bucket, and never more than [maxByteLength] bytes, so a
/// bad pin cannot point the phone anywhere else or fill its storage.
final class LocalCheckPinnedModel implements PinnedModel {
  LocalCheckPinnedModel(this.view) {
    final uri = Uri.tryParse(view.url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'storage.googleapis.com' ||
        !uri.path.startsWith('/mediapipe-models/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw PinnedModelException(this, 'model URL is not allowed');
    }
    if (!_sha256Hex.hasMatch(view.sha256)) {
      throw PinnedModelException(this, 'model digest is malformed');
    }
    if (view.byteLength <= 0 || view.byteLength > maxByteLength) {
      throw PinnedModelException(this, 'model size is out of bounds');
    }
  }

  /// Comfortably above the largest pinned model (about 8.4 MB).
  static const int maxByteLength = 32 * 1024 * 1024;

  static final RegExp _sha256Hex = RegExp(r'^[0-9a-f]{64}$');

  final LocalCheckModelView view;

  @override
  String get url => view.url;

  @override
  String get sha256 => view.sha256;

  @override
  int get byteLength => view.byteLength;
}

/// On-device MediaPipe recognition in video mode, configured the way the
/// server's replay runs the same model: the canned gesture classifier or the
/// object detector, each limited to the check's label.
///
/// Frames are rotated upright before inference, as for movement tracking.
final class MediaPipeLocalCheckVision implements LocalCheckVision {
  MediaPipeLocalCheckVision._({
    required this.label,
    this._gestures,
    this._objects,
  });

  static Future<LocalCheckVision> create(
    PinnedModelStore models,
    ActionLocalCheck check,
    LocalCheckModelView model,
  ) async {
    final asset = await models.load(LocalCheckPinnedModel(model));
    final labels = ClassifierOptions(categoryAllowlist: [check.label]);
    return switch (check.task) {
      LocalCheckTask.gesture => MediaPipeLocalCheckVision._(
        label: check.label,
        gestures: await GestureRecognizer.create(
          GestureRecognizerOptions(
            baseOptions: BaseOptions(modelAsset: asset),
            runningMode: VisionRunningMode.video,
            numHands: 2,
            cannedGesturesClassifierOptions: labels,
          ),
        ),
      ),
      LocalCheckTask.object => MediaPipeLocalCheckVision._(
        label: check.label,
        objects: await ObjectDetector.create(
          ObjectDetectorOptions(
            baseOptions: BaseOptions(modelAsset: asset),
            runningMode: VisionRunningMode.video,
            classifierOptions: ClassifierOptions(
              maxResults: 5,
              categoryAllowlist: [check.label],
            ),
          ),
        ),
      ),
      LocalCheckTask.sound => throw UnsupportedError(
        'Sound checks do not run on camera frames.',
      ),
    };
  }

  final String label;
  final GestureRecognizer? _gestures;
  final ObjectDetector? _objects;

  @override
  Future<LocalCheckFrame> observe(MpCameraFrame frame) async {
    final source = frame.image;
    if (source is! MpImageUint8) {
      throw UnsupportedError('Camera frames must be 8-bit RGB or RGBA.');
    }
    final image = uprightImage(
      source,
      frame.processingOptions.rotationDegrees,
    );
    if (_gestures case final gestures?) {
      final result = await gestures.recognizeForVideo(image, frame.timestampMs);
      return LocalCheckFrame(
        score: bestLabelScore(result.gestures.expand((hand) => hand), label),
        subjectSeen: result.landmarks.isNotEmpty,
      );
    }
    final result = await _objects!.detectForVideo(image, frame.timestampMs);
    return LocalCheckFrame(
      score: bestLabelScore(
        result.detections.expand((detection) => detection.categories),
        label,
      ),
    );
  }

  @override
  Future<void> close() async {
    await Future.wait([?_gestures?.close(), ?_objects?.close()]);
  }
}

/// The best score for [label] among [categories], as the server's replay
/// computes it; zero when the label is absent.
double bestLabelScore(Iterable<Category> categories, String label) {
  var best = 0.0;
  for (final category in categories) {
    if (category.categoryName == label && category.score > best) {
      best = category.score;
    }
  }
  return best;
}
