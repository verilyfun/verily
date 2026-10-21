/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// The phone's own local-check result. Advisory only: it is stored for
/// calibration and never decides anything.
abstract class DeviceLocalCheckResult
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DeviceLocalCheckResult._({
    required this.modelId,
    required this.modelSha256,
    required this.label,
    required this.score,
    required this.matchedFrames,
  });

  factory DeviceLocalCheckResult({
    required String modelId,
    required String modelSha256,
    required String label,
    required double score,
    required int matchedFrames,
  }) = _DeviceLocalCheckResultImpl;

  factory DeviceLocalCheckResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeviceLocalCheckResult(
      modelId: jsonSerialization['modelId'] as String,
      modelSha256: jsonSerialization['modelSha256'] as String,
      label: jsonSerialization['label'] as String,
      score: (jsonSerialization['score'] as num).toDouble(),
      matchedFrames: jsonSerialization['matchedFrames'] as int,
    );
  }

  String modelId;

  String modelSha256;

  String label;

  double score;

  int matchedFrames;

  /// Returns a shallow copy of this [DeviceLocalCheckResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DeviceLocalCheckResult copyWith({
    String? modelId,
    String? modelSha256,
    String? label,
    double? score,
    int? matchedFrames,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceLocalCheckResult',
      'modelId': modelId,
      'modelSha256': modelSha256,
      'label': label,
      'score': score,
      'matchedFrames': matchedFrames,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeviceLocalCheckResult',
      'modelId': modelId,
      'modelSha256': modelSha256,
      'label': label,
      'score': score,
      'matchedFrames': matchedFrames,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _DeviceLocalCheckResultImpl extends DeviceLocalCheckResult {
  _DeviceLocalCheckResultImpl({
    required String modelId,
    required String modelSha256,
    required String label,
    required double score,
    required int matchedFrames,
  }) : super._(
         modelId: modelId,
         modelSha256: modelSha256,
         label: label,
         score: score,
         matchedFrames: matchedFrames,
       );

  /// Returns a shallow copy of this [DeviceLocalCheckResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DeviceLocalCheckResult copyWith({
    String? modelId,
    String? modelSha256,
    String? label,
    double? score,
    int? matchedFrames,
  }) {
    return DeviceLocalCheckResult(
      modelId: modelId ?? this.modelId,
      modelSha256: modelSha256 ?? this.modelSha256,
      label: label ?? this.label,
      score: score ?? this.score,
      matchedFrames: matchedFrames ?? this.matchedFrames,
    );
  }
}
