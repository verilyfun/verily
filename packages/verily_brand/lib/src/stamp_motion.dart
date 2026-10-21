/// The verified stamp's slam, as shares of its `pressed` progress.
///
/// Kept free of Flutter so the reel's sound bed can land its thunk on the
/// same frame the stamp lands.
abstract final class StampMotion {
  /// When the stamp meets the paper.
  static const double impact = 0.5;
}
