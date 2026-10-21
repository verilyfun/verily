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

abstract class ActionQrChallengeCleanupTask
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ActionQrChallengeCleanupTask._({required this.batchSize});

  factory ActionQrChallengeCleanupTask({required int batchSize}) =
      _ActionQrChallengeCleanupTaskImpl;

  factory ActionQrChallengeCleanupTask.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionQrChallengeCleanupTask(
      batchSize: jsonSerialization['batchSize'] as int,
    );
  }

  int batchSize;

  /// Returns a shallow copy of this [ActionQrChallengeCleanupTask]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionQrChallengeCleanupTask copyWith({int? batchSize});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionQrChallengeCleanupTask',
      'batchSize': batchSize,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionQrChallengeCleanupTask',
      'batchSize': batchSize,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ActionQrChallengeCleanupTaskImpl extends ActionQrChallengeCleanupTask {
  _ActionQrChallengeCleanupTaskImpl({required int batchSize})
    : super._(batchSize: batchSize);

  /// Returns a shallow copy of this [ActionQrChallengeCleanupTask]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionQrChallengeCleanupTask copyWith({int? batchSize}) {
    return ActionQrChallengeCleanupTask(batchSize: batchSize ?? this.batchSize);
  }
}
