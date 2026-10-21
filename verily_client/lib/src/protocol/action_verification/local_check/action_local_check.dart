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

import '../../action_verification/local_check/local_check_task.dart'
    as _ingnm0df;

/// What a local check looks for. The label comes from the server allow-list
/// for the task; the thresholds are bounded server-side.
abstract class ActionLocalCheck
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActionLocalCheck._({
    required this.task,
    required this.label,
    required this.minScore,
    required this.minFrames,
  });

  factory ActionLocalCheck({
    required _ingnm0df.LocalCheckTask task,
    required String label,
    required double minScore,
    required int minFrames,
  }) = _ActionLocalCheckImpl;

  factory ActionLocalCheck.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionLocalCheck(
      task: _ingnm0df.LocalCheckTask.fromJson(
        (jsonSerialization['task'] as String),
      ),
      label: jsonSerialization['label'] as String,
      minScore: (jsonSerialization['minScore'] as num).toDouble(),
      minFrames: jsonSerialization['minFrames'] as int,
    );
  }

  _ingnm0df.LocalCheckTask task;

  String label;

  /// Lowest model score that counts as a detection (0.3 to 0.99).
  double minScore;

  /// Sampled video frames or audio windows that must match (1 to 30); 1 for a
  /// photo.
  int minFrames;

  /// Returns a shallow copy of this [ActionLocalCheck]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionLocalCheck copyWith({
    _ingnm0df.LocalCheckTask? task,
    String? label,
    double? minScore,
    int? minFrames,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionLocalCheck',
      'task': task.toJson(),
      'label': label,
      'minScore': minScore,
      'minFrames': minFrames,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionLocalCheck',
      'task': task.toJson(),
      'label': label,
      'minScore': minScore,
      'minFrames': minFrames,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ActionLocalCheckImpl extends ActionLocalCheck {
  _ActionLocalCheckImpl({
    required _ingnm0df.LocalCheckTask task,
    required String label,
    required double minScore,
    required int minFrames,
  }) : super._(
         task: task,
         label: label,
         minScore: minScore,
         minFrames: minFrames,
       );

  /// Returns a shallow copy of this [ActionLocalCheck]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActionLocalCheck copyWith({
    _ingnm0df.LocalCheckTask? task,
    String? label,
    double? minScore,
    int? minFrames,
  }) {
    return ActionLocalCheck(
      task: task ?? this.task,
      label: label ?? this.label,
      minScore: minScore ?? this.minScore,
      minFrames: minFrames ?? this.minFrames,
    );
  }
}
