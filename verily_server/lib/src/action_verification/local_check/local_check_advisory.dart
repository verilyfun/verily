import 'package:verily_server/src/generated/protocol.dart';

/// The phone's own local-check result, bounded for storage.
///
/// It is advisory only: kept on the evidence row for calibration, never sent
/// to a verifier, and never read when a proof is decided. The server replays
/// the pinned model itself.
final class AdvisoryLocalCheck {
  const AdvisoryLocalCheck({
    required this.modelId,
    required this.modelSha256,
    required this.label,
    required this.score,
    required this.matchedFrames,
  });

  final String modelId;
  final String modelSha256;
  final String label;
  final double score;
  final int matchedFrames;
}

final _sha256Hex = RegExp(r'^[0-9a-f]{64}$');

/// Validates [result] for a proof under [rule]. Returns null when the rule
/// has no local check (the result is ignored entirely) or nothing was sent.
/// Throws [ArgumentError] when a sent result is out of bounds, like every
/// other malformed confirmation field.
AdvisoryLocalCheck? advisoryLocalCheck(
  ActionMediaRule rule,
  DeviceLocalCheckResult? result,
) {
  if (result == null || rule.localCheckTask == null) return null;
  final modelId = result.modelId.trim();
  final label = result.label.trim();
  if (modelId.isEmpty ||
      modelId.length > 128 ||
      !_sha256Hex.hasMatch(result.modelSha256) ||
      label.isEmpty ||
      label.length > 64 ||
      !result.score.isFinite ||
      result.score < 0 ||
      result.score > 1 ||
      result.matchedFrames < 0 ||
      result.matchedFrames > 10000) {
    throw ArgumentError('The device local-check result is invalid.');
  }
  return AdvisoryLocalCheck(
    modelId: modelId,
    modelSha256: result.modelSha256,
    label: label,
    score: result.score,
    matchedFrames: result.matchedFrames,
  );
}
