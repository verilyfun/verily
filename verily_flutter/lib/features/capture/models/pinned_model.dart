/// A MediaPipe model the app downloads once, verifies, and caches.
///
/// The SHA-256 digest is the trust anchor: bytes that do not match it, or
/// the pinned length, are discarded and never handed to MediaPipe.
abstract interface class PinnedModel {
  /// Where the model is fetched from.
  String get url;

  /// The lowercase hex SHA-256 of the exact file.
  String get sha256;

  /// Exact size of the pinned file, used to bound the download.
  int get byteLength;
}

/// The pinned model could not be fetched or did not match its pin.
class PinnedModelException implements Exception {
  const PinnedModelException(this.model, this.reason);

  final PinnedModel model;
  final String reason;

  @override
  String toString() => 'PinnedModelException(${model.url}): $reason';
}
