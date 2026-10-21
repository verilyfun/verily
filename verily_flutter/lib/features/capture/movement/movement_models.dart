import 'package:verily_flutter/features/capture/models/pinned_model.dart';

/// A MediaPipe model live movement tracking runs.
///
/// URLs are immutable, versioned paths in Google's public model bucket. The
/// SHA-256 digest is the trust anchor: bytes that do not match are discarded,
/// never loaded.
enum MovementModel implements PinnedModel {
  /// BlazePose GHUM lite: 33 body landmarks per frame, about 5.8 MB.
  pose(
    url:
        'https://storage.googleapis.com/mediapipe-models/pose_landmarker/'
        'pose_landmarker_lite/float16/1/pose_landmarker_lite.task',
    sha256: '59929e1d1ee95287735ddd833b19cf4ac46d29bc7afddbbf6753c459690d574a',
    byteLength: 5777746,
  ),

  /// EfficientDet-Lite0 (int8, COCO), used to find a "sports ball".
  objects(
    url:
        'https://storage.googleapis.com/mediapipe-models/object_detector/'
        'efficientdet_lite0/int8/1/efficientdet_lite0.tflite',
    sha256: '0720bf247bd76e6594ea28fa9c6f7c5242be774818997dbbeffc4da460c723bb',
    byteLength: 4602795,
  );

  const MovementModel({
    required this.url,
    required this.sha256,
    required this.byteLength,
  });

  @override
  final String url;
  @override
  final String sha256;

  /// Exact size of the pinned file, used to bound the download.
  @override
  final int byteLength;
}
