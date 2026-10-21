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

/// The pool stops reserving payouts immediately. The creator's wallet signs
/// the returned transaction to move the on-chain expiry to match.
abstract class RewardEndPlan
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RewardEndPlan._({
    required this.poolId,
    required this.expiresAt,
    required this.refundAfter,
    required this.unsignedTransaction,
  });

  factory RewardEndPlan({
    required _isc.UuidValue poolId,
    required DateTime expiresAt,
    required DateTime refundAfter,
    required String unsignedTransaction,
  }) = _RewardEndPlanImpl;

  factory RewardEndPlan.fromJson(Map<String, dynamic> jsonSerialization) {
    return RewardEndPlan(
      poolId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['poolId']),
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      refundAfter: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['refundAfter'],
      ),
      unsignedTransaction: jsonSerialization['unsignedTransaction'] as String,
    );
  }

  _isc.UuidValue poolId;

  DateTime expiresAt;

  DateTime refundAfter;

  String unsignedTransaction;

  /// Returns a shallow copy of this [RewardEndPlan]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RewardEndPlan copyWith({
    _isc.UuidValue? poolId,
    DateTime? expiresAt,
    DateTime? refundAfter,
    String? unsignedTransaction,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RewardEndPlan',
      'poolId': poolId.toJson(),
      'expiresAt': expiresAt.toJson(),
      'refundAfter': refundAfter.toJson(),
      'unsignedTransaction': unsignedTransaction,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RewardEndPlan',
      'poolId': poolId.toJson(),
      'expiresAt': expiresAt.toJson(),
      'refundAfter': refundAfter.toJson(),
      'unsignedTransaction': unsignedTransaction,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _RewardEndPlanImpl extends RewardEndPlan {
  _RewardEndPlanImpl({
    required _isc.UuidValue poolId,
    required DateTime expiresAt,
    required DateTime refundAfter,
    required String unsignedTransaction,
  }) : super._(
         poolId: poolId,
         expiresAt: expiresAt,
         refundAfter: refundAfter,
         unsignedTransaction: unsignedTransaction,
       );

  /// Returns a shallow copy of this [RewardEndPlan]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RewardEndPlan copyWith({
    _isc.UuidValue? poolId,
    DateTime? expiresAt,
    DateTime? refundAfter,
    String? unsignedTransaction,
  }) {
    return RewardEndPlan(
      poolId: poolId ?? this.poolId,
      expiresAt: expiresAt ?? this.expiresAt,
      refundAfter: refundAfter ?? this.refundAfter,
      unsignedTransaction: unsignedTransaction ?? this.unsignedTransaction,
    );
  }
}
