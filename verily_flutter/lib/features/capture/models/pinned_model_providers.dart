import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/features/capture/models/pinned_model_store.dart';

/// The one cache of verified MediaPipe models, shared by movement tracking
/// and quick checks.
final Provider<PinnedModelStore> pinnedModelStoreProvider = Provider(
  (ref) => PinnedModelStore(),
);
