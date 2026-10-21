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

abstract class RewardPayoutTask
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RewardPayoutTask._({required this.payoutId});

  factory RewardPayoutTask({required _is.UuidValue payoutId}) =
      _RewardPayoutTaskImpl;

  factory RewardPayoutTask.fromJson(Map<String, dynamic> jsonSerialization) {
    return RewardPayoutTask(
      payoutId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['payoutId'],
      ),
    );
  }

  _is.UuidValue payoutId;

  /// Returns a shallow copy of this [RewardPayoutTask]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RewardPayoutTask copyWith({_is.UuidValue? payoutId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RewardPayoutTask',
      'payoutId': payoutId.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RewardPayoutTask',
      'payoutId': payoutId.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RewardPayoutTaskImpl extends RewardPayoutTask {
  _RewardPayoutTaskImpl({required _is.UuidValue payoutId})
    : super._(payoutId: payoutId);

  /// Returns a shallow copy of this [RewardPayoutTask]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RewardPayoutTask copyWith({_is.UuidValue? payoutId}) {
    return RewardPayoutTask(payoutId: payoutId ?? this.payoutId);
  }
}
