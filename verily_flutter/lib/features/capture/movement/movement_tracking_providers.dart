import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';
import 'package:verily_flutter/features/capture/movement/movement_capture_controller.dart';
import 'package:verily_flutter/features/capture/models/pinned_model_providers.dart';
import 'package:verily_flutter/features/capture/movement/movement_vision.dart';

/// Whether this platform can count movements live while recording.
///
/// The MediaPipe runtime ships for Android. Other platforms record a plain
/// video, and the server still verifies the recording.
final Provider<bool> movementTrackingSupportedProvider = Provider(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);

final Provider<MovementCaptureControllerFactory>
movementCaptureControllerFactoryProvider = Provider((ref) {
  final models = ref.watch(pinnedModelStoreProvider);
  return (kind, {required recordAudio}) => CameraMovementCaptureController(
    kind: kind,
    recordAudio: recordAudio,
    vision: () =>
        MediaPipeMovementVision.create(models, detectBall: kind.isBallSkill),
  );
});
