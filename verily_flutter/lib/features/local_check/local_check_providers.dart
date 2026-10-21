import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/features/capture/models/pinned_model_providers.dart';
import 'package:verily_flutter/features/local_check/local_check_vision.dart';

/// Whether this platform runs quick checks live on camera frames.
///
/// The MediaPipe runtime ships for Android. Elsewhere the proof is captured
/// as usual and Verily checks it after it is sent.
final Provider<bool> localCheckSupportedProvider = Provider(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);

/// Loads the pinned model for a check and builds its vision.
final Provider<LocalCheckVisionFactory> localCheckVisionFactoryProvider =
    Provider((ref) {
      final models = ref.watch(pinnedModelStoreProvider);
      return (check, model) =>
          MediaPipeLocalCheckVision.create(models, check, model);
    });
