import 'package:mp_core/mp_core.dart';

import 'package:verily_flutter/features/capture/models/pinned_model.dart';

/// Live on-device checks run only in the Android app.
class PinnedModelStore {
  Future<ModelAsset> load(PinnedModel model) {
    throw UnsupportedError('On-device models are not available on web.');
  }
}
