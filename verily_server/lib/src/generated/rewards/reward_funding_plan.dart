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

import '../rewards/reward_cluster.dart' as _ifrvw135;

/// What the creator's wallet signs to open the escrow.
abstract class RewardFundingPlan
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RewardFundingPlan._({
    required this.poolId,
    required this.cluster,
    required this.escrowAddress,
    required this.creatorWallet,
    required this.arbiterAddress,
    required this.mint,
    required this.tokenSymbol,
    required this.decimals,
    required this.totalAtoms,
    required this.expiresAt,
    required this.refundAfter,
    required this.unsignedTransaction,
  });

  factory RewardFundingPlan({
    required _is.UuidValue poolId,
    required _ifrvw135.RewardCluster cluster,
    required String escrowAddress,
    required String creatorWallet,
    required String arbiterAddress,
    required String mint,
    required String tokenSymbol,
    required int decimals,
    required int totalAtoms,
    required DateTime expiresAt,
    required DateTime refundAfter,
    required String unsignedTransaction,
  }) = _RewardFundingPlanImpl;

  factory RewardFundingPlan.fromJson(Map<String, dynamic> jsonSerialization) {
    return RewardFundingPlan(
      poolId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['poolId']),
      cluster: _ifrvw135.RewardCluster.fromJson(
        (jsonSerialization['cluster'] as String),
      ),
      escrowAddress: jsonSerialization['escrowAddress'] as String,
      creatorWallet: jsonSerialization['creatorWallet'] as String,
      arbiterAddress: jsonSerialization['arbiterAddress'] as String,
      mint: jsonSerialization['mint'] as String,
      tokenSymbol: jsonSerialization['tokenSymbol'] as String,
      decimals: jsonSerialization['decimals'] as int,
      totalAtoms: jsonSerialization['totalAtoms'] as int,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      refundAfter: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['refundAfter'],
      ),
      unsignedTransaction: jsonSerialization['unsignedTransaction'] as String,
    );
  }

  _is.UuidValue poolId;

  _ifrvw135.RewardCluster cluster;

  String escrowAddress;

  String creatorWallet;

  String arbiterAddress;

  String mint;

  String tokenSymbol;

  int decimals;

  int totalAtoms;

  DateTime expiresAt;

  DateTime refundAfter;

  /// Base64 unsigned transaction for the creator's wallet to sign and send.
  String unsignedTransaction;

  /// Returns a shallow copy of this [RewardFundingPlan]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RewardFundingPlan copyWith({
    _is.UuidValue? poolId,
    _ifrvw135.RewardCluster? cluster,
    String? escrowAddress,
    String? creatorWallet,
    String? arbiterAddress,
    String? mint,
    String? tokenSymbol,
    int? decimals,
    int? totalAtoms,
    DateTime? expiresAt,
    DateTime? refundAfter,
    String? unsignedTransaction,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RewardFundingPlan',
      'poolId': poolId.toJson(),
      'cluster': cluster.toJson(),
      'escrowAddress': escrowAddress,
      'creatorWallet': creatorWallet,
      'arbiterAddress': arbiterAddress,
      'mint': mint,
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'totalAtoms': totalAtoms,
      'expiresAt': expiresAt.toJson(),
      'refundAfter': refundAfter.toJson(),
      'unsignedTransaction': unsignedTransaction,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RewardFundingPlan',
      'poolId': poolId.toJson(),
      'cluster': cluster.toJson(),
      'escrowAddress': escrowAddress,
      'creatorWallet': creatorWallet,
      'arbiterAddress': arbiterAddress,
      'mint': mint,
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'totalAtoms': totalAtoms,
      'expiresAt': expiresAt.toJson(),
      'refundAfter': refundAfter.toJson(),
      'unsignedTransaction': unsignedTransaction,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RewardFundingPlanImpl extends RewardFundingPlan {
  _RewardFundingPlanImpl({
    required _is.UuidValue poolId,
    required _ifrvw135.RewardCluster cluster,
    required String escrowAddress,
    required String creatorWallet,
    required String arbiterAddress,
    required String mint,
    required String tokenSymbol,
    required int decimals,
    required int totalAtoms,
    required DateTime expiresAt,
    required DateTime refundAfter,
    required String unsignedTransaction,
  }) : super._(
         poolId: poolId,
         cluster: cluster,
         escrowAddress: escrowAddress,
         creatorWallet: creatorWallet,
         arbiterAddress: arbiterAddress,
         mint: mint,
         tokenSymbol: tokenSymbol,
         decimals: decimals,
         totalAtoms: totalAtoms,
         expiresAt: expiresAt,
         refundAfter: refundAfter,
         unsignedTransaction: unsignedTransaction,
       );

  /// Returns a shallow copy of this [RewardFundingPlan]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RewardFundingPlan copyWith({
    _is.UuidValue? poolId,
    _ifrvw135.RewardCluster? cluster,
    String? escrowAddress,
    String? creatorWallet,
    String? arbiterAddress,
    String? mint,
    String? tokenSymbol,
    int? decimals,
    int? totalAtoms,
    DateTime? expiresAt,
    DateTime? refundAfter,
    String? unsignedTransaction,
  }) {
    return RewardFundingPlan(
      poolId: poolId ?? this.poolId,
      cluster: cluster ?? this.cluster,
      escrowAddress: escrowAddress ?? this.escrowAddress,
      creatorWallet: creatorWallet ?? this.creatorWallet,
      arbiterAddress: arbiterAddress ?? this.arbiterAddress,
      mint: mint ?? this.mint,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      decimals: decimals ?? this.decimals,
      totalAtoms: totalAtoms ?? this.totalAtoms,
      expiresAt: expiresAt ?? this.expiresAt,
      refundAfter: refundAfter ?? this.refundAfter,
      unsignedTransaction: unsignedTransaction ?? this.unsignedTransaction,
    );
  }
}
