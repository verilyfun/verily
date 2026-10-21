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
import 'package:serverpod/serverpod.dart' as _is;

/// Private, bounded inertial observation. The server never trusts client summaries.
abstract class ActionMotionSample
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ActionMotionSample._({
    required this.elapsedMicroseconds,
    required this.gyroscopeX,
    required this.gyroscopeY,
    required this.gyroscopeZ,
    required this.accelerationX,
    required this.accelerationY,
    required this.accelerationZ,
  });

  factory ActionMotionSample({
    required int elapsedMicroseconds,
    required double gyroscopeX,
    required double gyroscopeY,
    required double gyroscopeZ,
    required double accelerationX,
    required double accelerationY,
    required double accelerationZ,
  }) = _ActionMotionSampleImpl;

  factory ActionMotionSample.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionMotionSample(
      elapsedMicroseconds: jsonSerialization['elapsedMicroseconds'] as int,
      gyroscopeX: (jsonSerialization['gyroscopeX'] as num).toDouble(),
      gyroscopeY: (jsonSerialization['gyroscopeY'] as num).toDouble(),
      gyroscopeZ: (jsonSerialization['gyroscopeZ'] as num).toDouble(),
      accelerationX: (jsonSerialization['accelerationX'] as num).toDouble(),
      accelerationY: (jsonSerialization['accelerationY'] as num).toDouble(),
      accelerationZ: (jsonSerialization['accelerationZ'] as num).toDouble(),
    );
  }

  int elapsedMicroseconds;

  double gyroscopeX;

  double gyroscopeY;

  double gyroscopeZ;

  double accelerationX;

  double accelerationY;

  double accelerationZ;

  /// Returns a shallow copy of this [ActionMotionSample]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionMotionSample copyWith({
    int? elapsedMicroseconds,
    double? gyroscopeX,
    double? gyroscopeY,
    double? gyroscopeZ,
    double? accelerationX,
    double? accelerationY,
    double? accelerationZ,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionMotionSample',
      'elapsedMicroseconds': elapsedMicroseconds,
      'gyroscopeX': gyroscopeX,
      'gyroscopeY': gyroscopeY,
      'gyroscopeZ': gyroscopeZ,
      'accelerationX': accelerationX,
      'accelerationY': accelerationY,
      'accelerationZ': accelerationZ,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionMotionSample',
      'elapsedMicroseconds': elapsedMicroseconds,
      'gyroscopeX': gyroscopeX,
      'gyroscopeY': gyroscopeY,
      'gyroscopeZ': gyroscopeZ,
      'accelerationX': accelerationX,
      'accelerationY': accelerationY,
      'accelerationZ': accelerationZ,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ActionMotionSampleImpl extends ActionMotionSample {
  _ActionMotionSampleImpl({
    required int elapsedMicroseconds,
    required double gyroscopeX,
    required double gyroscopeY,
    required double gyroscopeZ,
    required double accelerationX,
    required double accelerationY,
    required double accelerationZ,
  }) : super._(
         elapsedMicroseconds: elapsedMicroseconds,
         gyroscopeX: gyroscopeX,
         gyroscopeY: gyroscopeY,
         gyroscopeZ: gyroscopeZ,
         accelerationX: accelerationX,
         accelerationY: accelerationY,
         accelerationZ: accelerationZ,
       );

  /// Returns a shallow copy of this [ActionMotionSample]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionMotionSample copyWith({
    int? elapsedMicroseconds,
    double? gyroscopeX,
    double? gyroscopeY,
    double? gyroscopeZ,
    double? accelerationX,
    double? accelerationY,
    double? accelerationZ,
  }) {
    return ActionMotionSample(
      elapsedMicroseconds: elapsedMicroseconds ?? this.elapsedMicroseconds,
      gyroscopeX: gyroscopeX ?? this.gyroscopeX,
      gyroscopeY: gyroscopeY ?? this.gyroscopeY,
      gyroscopeZ: gyroscopeZ ?? this.gyroscopeZ,
      accelerationX: accelerationX ?? this.accelerationX,
      accelerationY: accelerationY ?? this.accelerationY,
      accelerationZ: accelerationZ ?? this.accelerationZ,
    );
  }
}
