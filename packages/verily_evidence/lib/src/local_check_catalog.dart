import 'package:verily_evidence/verily_evidence.dart' show MediaEvidenceKind;

/// A MediaPipe model a local check runs, on the phone and on the server,
/// with the labels a creator may ask it for.
///
/// URLs are immutable, versioned paths in Google's public model bucket. The
/// SHA-256 digest is the trust anchor: bytes that do not match are discarded,
/// never loaded, on either side.
///
/// Each label is the model's own category name, so the phone, the server's
/// replay, and the editor compare like with like. The server validates every
/// saved check against these lists; the app offers and names them.
enum LocalCheckModel {
  /// MediaPipe gesture recognizer (float16, version 1): seven canned hand
  /// gestures.
  gestureRecognizer(
    modelId: 'mediapipe/gesture_recognizer/float16/1',
    url:
        'https://storage.googleapis.com/mediapipe-models/gesture_recognizer/'
        'gesture_recognizer/float16/1/gesture_recognizer.task',
    sha256: '97952348cf6a6a4915c2ea1496b4b37ebabc50cbbf80571435643c455f2b0482',
    byteLength: 8373440,
    media: {MediaEvidenceKind.photo, MediaEvidenceKind.video},
    labels: _gestureLabels,
  ),

  /// EfficientDet-Lite0 (int8, version 1): the 80 COCO object classes.
  objectDetector(
    modelId: 'mediapipe/efficientdet_lite0/int8/1',
    url:
        'https://storage.googleapis.com/mediapipe-models/object_detector/'
        'efficientdet_lite0/int8/1/efficientdet_lite0.tflite',
    sha256: '0720bf247bd76e6594ea28fa9c6f7c5242be774818997dbbeffc4da460c723bb',
    byteLength: 4602795,
    media: {MediaEvidenceKind.photo, MediaEvidenceKind.video},
    labels: _objectLabels,
  ),

  /// YAMNet (float32, version 1): AudioSet sound classes.
  audioClassifier(
    modelId: 'mediapipe/yamnet/float32/1',
    url:
        'https://storage.googleapis.com/mediapipe-models/audio_classifier/'
        'yamnet/float32/1/yamnet.tflite',
    sha256: '4d8b4a53282dc83ef04e3e7dbc4fbc98082e34e44ed798e16c3a0cdd4c584faf',
    byteLength: 4126810,
    media: {MediaEvidenceKind.audio},
    labels: _soundLabels,
  );

  const LocalCheckModel({
    required this.modelId,
    required this.url,
    required this.sha256,
    required this.byteLength,
    required this.media,
    required this.labels,
  });

  final String modelId;
  final String url;

  /// The lowercase hex SHA-256 of the exact file.
  final String sha256;

  /// Exact size of the pinned file, used to bound the download.
  final int byteLength;

  /// The categories a creator may ask for, in the order the editor offers
  /// them.
  final List<String> labels;

  /// The proofs it can check: sound on audio, gestures and objects on
  /// photos and video.
  final Set<MediaEvidenceKind> media;
}

/// Bounds shared by the editor, validation, the schema, and the replay.
abstract final class LocalCheckBounds {
  static const minScore = 0.3;
  static const maxScore = 0.99;
  static const minFrames = 1;

  /// Also the number of frames the server samples from a video to replay.
  static const maxFrames = 30;
}

const _gestureLabels = [
  'Closed_Fist',
  'Open_Palm',
  'Pointing_Up',
  'Thumb_Down',
  'Thumb_Up',
  'Victory',
  'ILoveYou',
];

// COCO classes, as EfficientDet-Lite0 names them.
const _objectLabels = [
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
];

// A reviewed subset of YAMNet's AudioSet classes: distinct, everyday sounds
// a person can make or find. Speech and music genres are excluded.
const _soundLabels = [
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
];
