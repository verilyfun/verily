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

abstract class ActionCaptureChallengeCleanupTask
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActionCaptureChallengeCleanupTask._({required this.batchSize});

  factory ActionCaptureChallengeCleanupTask({required int batchSize}) =
      _ActionCaptureChallengeCleanupTaskImpl;

  factory ActionCaptureChallengeCleanupTask.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionCaptureChallengeCleanupTask(
      batchSize: jsonSerialization['batchSize'] as int,
    );
  }

  int batchSize;

  /// Returns a shallow copy of this [ActionCaptureChallengeCleanupTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionCaptureChallengeCleanupTask copyWith({int? batchSize});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionCaptureChallengeCleanupTask',
      'batchSize': batchSize,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionCaptureChallengeCleanupTask',
      'batchSize': batchSize,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ActionCaptureChallengeCleanupTaskImpl
    extends ActionCaptureChallengeCleanupTask {
  _ActionCaptureChallengeCleanupTaskImpl({required int batchSize})
    : super._(batchSize: batchSize);

  /// Returns a shallow copy of this [ActionCaptureChallengeCleanupTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActionCaptureChallengeCleanupTask copyWith({int? batchSize}) {
    return ActionCaptureChallengeCleanupTask(
      batchSize: batchSize ?? this.batchSize,
    );
  }
}
