import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// A MediaPipe model a local check runs, on the phone and on the server.
///
/// URLs are immutable, versioned paths in Google's public model bucket. The
/// SHA-256 digest is the trust anchor: bytes that do not match are discarded,
/// never loaded, on either side.
enum LocalCheckModel {
  /// MediaPipe gesture recognizer (float16, version 1): seven canned hand
  /// gestures.
  gestureRecognizer(
    task: LocalCheckTask.gesture,
    modelId: 'mediapipe/gesture_recognizer/float16/1',
    url:
        'https://storage.googleapis.com/mediapipe-models/gesture_recognizer/'
        'gesture_recognizer/float16/1/gesture_recognizer.task',
    sha256: '97952348cf6a6a4915c2ea1496b4b37ebabc50cbbf80571435643c455f2b0482',
    byteLength: 8373440,
  ),

  /// EfficientDet-Lite0 (int8, version 1): the 80 COCO object classes.
  objectDetector(
    task: LocalCheckTask.object,
    modelId: 'mediapipe/efficientdet_lite0/int8/1',
    url:
        'https://storage.googleapis.com/mediapipe-models/object_detector/'
        'efficientdet_lite0/int8/1/efficientdet_lite0.tflite',
    sha256: '0720bf247bd76e6594ea28fa9c6f7c5242be774818997dbbeffc4da460c723bb',
    byteLength: 4602795,
  ),

  /// YAMNet (float32, version 1): AudioSet sound classes.
  audioClassifier(
    task: LocalCheckTask.sound,
    modelId: 'mediapipe/yamnet/float32/1',
    url:
        'https://storage.googleapis.com/mediapipe-models/audio_classifier/'
        'yamnet/float32/1/yamnet.tflite',
    sha256: '4d8b4a53282dc83ef04e3e7dbc4fbc98082e34e44ed798e16c3a0cdd4c584faf',
    byteLength: 4126810,
  );

  const LocalCheckModel({
    required this.task,
    required this.modelId,
    required this.url,
    required this.sha256,
    required this.byteLength,
  });

  final LocalCheckTask task;
  final String modelId;
  final String url;
  final String sha256;

  /// Exact size of the pinned file, used to bound the download.
  final int byteLength;

  static LocalCheckModel forTask(LocalCheckTask task) =>
      values.firstWhere((model) => model.task == task);

  LocalCheckModelView get view => LocalCheckModelView(
    modelId: modelId,
    url: url,
    byteLength: byteLength,
    sha256: sha256,
  );
}

/// Labels a creator may ask for, per task. Each is the model's own category
/// name, so the phone and the server compare like with like.
const localCheckLabels = <LocalCheckTask, Set<String>>{
  LocalCheckTask.gesture: {
    'Closed_Fist',
    'Open_Palm',
    'Pointing_Up',
    'Thumb_Down',
    'Thumb_Up',
    'Victory',
    'ILoveYou',
  },
  // COCO classes, as EfficientDet-Lite0 names them.
  LocalCheckTask.object: {
    'person',
    'bicycle',
    'car',
    'motorcycle',
    'airplane',
    'bus',
    'train',
    'truck',
    'boat',
    'traffic light',
    'fire hydrant',
    'stop sign',
    'parking meter',
    'bench',
    'bird',
    'cat',
    'dog',
    'horse',
    'sheep',
    'cow',
    'elephant',
    'bear',
    'zebra',
    'giraffe',
    'backpack',
    'umbrella',
    'handbag',
    'tie',
    'suitcase',
    'frisbee',
    'skis',
    'snowboard',
    'sports ball',
    'kite',
    'baseball bat',
    'baseball glove',
    'skateboard',
    'surfboard',
    'tennis racket',
    'bottle',
    'wine glass',
    'cup',
    'fork',
    'knife',
    'spoon',
    'bowl',
    'banana',
    'apple',
    'sandwich',
    'orange',
    'broccoli',
    'carrot',
    'hot dog',
    'pizza',
    'donut',
    'cake',
    'chair',
    'couch',
    'potted plant',
    'bed',
    'dining table',
    'toilet',
    'tv',
    'laptop',
    'mouse',
    'remote',
    'keyboard',
    'cell phone',
    'microwave',
    'oven',
    'toaster',
    'sink',
    'refrigerator',
    'book',
    'clock',
    'vase',
    'scissors',
    'teddy bear',
    'hair drier',
    'toothbrush',
  },
  // A reviewed subset of YAMNet's AudioSet classes: distinct, everyday
  // sounds a person can make or find. Speech and music genres are excluded.
  LocalCheckTask.sound: {
    'Clapping',
    'Finger snapping',
    'Whistling',
    'Applause',
    'Laughter',
    'Cough',
    'Sneeze',
    'Bell',
    'Doorbell',
    'Knock',
    'Dog',
    'Bark',
    'Cat',
    'Meow',
    'Bird',
    'Chirp, tweet',
    'Crowing, cock-a-doodle-doo',
    'Siren',
    'Alarm clock',
    'Typing',
    'Water tap, faucet',
    'Guitar',
    'Piano',
    'Drum',
    'Whistle',
  },
};

/// Bounds shared by validation, the schema, and the replay verifier.
abstract final class LocalCheckBounds {
  static const minScore = 0.3;
  static const maxScore = 0.99;
  static const minFrames = 1;
  static const maxFrames = 30;
}

/// The task that can run on [kind]: sound on audio, gesture and object on
/// photos and video.
bool localCheckFitsKind(LocalCheckTask task, MediaEvidenceKind kind) =>
    switch (task) {
      LocalCheckTask.sound => kind == MediaEvidenceKind.audio,
      LocalCheckTask.gesture ||
      LocalCheckTask.object => kind != MediaEvidenceKind.audio,
    };

/// Validates a creator's local check for a [kind] proof. Throws
/// [ArgumentError] with product-safe text, like every authoring rule.
ActionLocalCheck validateLocalCheck(
  ActionLocalCheck check,
  MediaEvidenceKind kind,
) {
  if (!localCheckFitsKind(check.task, kind)) {
    throw ArgumentError(
      check.task == LocalCheckTask.sound
          ? 'Sound checks need an audio proof.'
          : 'Gesture and object checks need a photo or video proof.',
    );
  }
  if (!(localCheckLabels[check.task]?.contains(check.label) ?? false)) {
    throw ArgumentError('Choose a label from the list for this check.');
  }
  final score = check.minScore;
  if (!score.isFinite ||
      score < LocalCheckBounds.minScore ||
      score > LocalCheckBounds.maxScore) {
    throw ArgumentError('Local check scores must be between 0.3 and 0.99.');
  }
  final frames = check.minFrames;
  if (frames < LocalCheckBounds.minFrames ||
      frames > LocalCheckBounds.maxFrames ||
      (kind == MediaEvidenceKind.photo && frames != 1)) {
    throw ArgumentError(
      kind == MediaEvidenceKind.photo
          ? 'A photo is checked as one frame.'
          : 'Local checks need between 1 and 30 matching frames.',
    );
  }
  return check;
}

/// The server-written verifier text for a local check, used when the AI
/// policy decides (the replay is unavailable, or a word must be heard).
/// Labels come from the allow-list, so no creator text reaches the model.
String localCheckVerificationPrompt(ActionLocalCheck check) {
  final label = check.label.replaceAll('_', ' ').toLowerCase();
  return switch (check.task) {
    LocalCheckTask.gesture =>
      'Verify that a real hand clearly makes the "$label" gesture in this '
          'live capture.',
    LocalCheckTask.object =>
      'Verify that a real $label is clearly visible in this live capture.',
    LocalCheckTask.sound =>
      'Verify that this live recording clearly contains the sound: $label.',
  };
}
