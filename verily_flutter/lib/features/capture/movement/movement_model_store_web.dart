import 'package:mp_core/mp_core.dart';

import 'package:verily_flutter/features/capture/movement/movement_models.dart';

/// Live movement tracking runs only in the Android app.
class MovementModelStore {
  Future<ModelAsset> load(MovementModel model) {
    throw UnsupportedError('Live movement tracking is not available on web.');
  }
}
