import 'package:verily_evidence/verily_evidence.dart' show LocalCheckModel;

import 'package:verily_flutter/features/capture/models/pinned_model.dart';

/// A MediaPipe model live movement tracking runs.
///
/// URLs are immutable, versioned paths in Google's public model bucket. The
/// SHA-256 digest is the trust anchor: bytes that do not match are discarded,
/// never loaded.
enum MovementModel implements PinnedModel {
  /// BlazePose GHUM lite: 33 body landmarks per frame, about 5.8 MB.
  pose,

  /// EfficientDet-Lite0 (int8, COCO), used to find a "sports ball". It is
  /// the quick check's object detector, so it shares that pin.
  objects;

  @override
  String get url => switch (this) {
    pose =>
      'https://storage.googleapis.com/mediapipe-models/pose_landmarker/'
          'pose_landmarker_lite/float16/1/pose_landmarker_lite.task',
    objects => LocalCheckModel.objectDetector.url,
  };

  @override
  String get sha256 => switch (this) {
    pose => '59929e1d1ee95287735ddd833b19cf4ac46d29bc7afddbbf6753c459690d574a',
    objects => LocalCheckModel.objectDetector.sha256,
  };

  /// Exact size of the pinned file, used to bound the download.
  @override
  int get byteLength => switch (this) {
    pose => 5777746,
    objects => LocalCheckModel.objectDetector.byteLength,
  };
}
