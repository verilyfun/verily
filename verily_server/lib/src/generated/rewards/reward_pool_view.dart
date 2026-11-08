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
import '../rewards/reward_pool_status.dart' as _i2n7u226;

/// The creator's view of their action's reward.
abstract class RewardPoolView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RewardPoolView._({
    required this.poolId,
    required this.status,
    required this.cluster,
    required this.mint,
    required this.tokenSymbol,
    required this.decimals,
    required this.amountPerPayout,
    required this.maxPayouts,
    required this.maxWinsPerAccount,
    required this.payoutsReserved,
    required this.payoutsReleased,
    required this.expiresAt,
    required this.refundAfter,
    this.creatorWallet,
    this.escrowAddress,
    this.fundingSignature,
    this.fundedAt,
  });

  factory RewardPoolView({
    required _is.UuidValue poolId,
    required _i2n7u226.RewardPoolStatus status,
    required _ifrvw135.RewardCluster cluster,
    required String mint,
    required String tokenSymbol,
    required int decimals,
    required int amountPerPayout,
    required int maxPayouts,
    required int maxWinsPerAccount,
    required int payoutsReserved,
    required int payoutsReleased,
    required DateTime expiresAt,
    required DateTime refundAfter,
    String? creatorWallet,
    String? escrowAddress,
    String? fundingSignature,
    DateTime? fundedAt,
  }) = _RewardPoolViewImpl;

  factory RewardPoolView.fromJson(Map<String, dynamic> jsonSerialization) {
    return RewardPoolView(
      poolId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['poolId']),
      status: _i2n7u226.RewardPoolStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      cluster: _ifrvw135.RewardCluster.fromJson(
        (jsonSerialization['cluster'] as String),
      ),
      mint: jsonSerialization['mint'] as String,
      tokenSymbol: jsonSerialization['tokenSymbol'] as String,
      decimals: jsonSerialization['decimals'] as int,
      amountPerPayout: jsonSerialization['amountPerPayout'] as int,
      maxPayouts: jsonSerialization['maxPayouts'] as int,
      maxWinsPerAccount: jsonSerialization['maxWinsPerAccount'] as int,
      payoutsReserved: jsonSerialization['payoutsReserved'] as int,
      payoutsReleased: jsonSerialization['payoutsReleased'] as int,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      refundAfter: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['refundAfter'],
      ),
      creatorWallet: jsonSerialization['creatorWallet'] as String?,
      escrowAddress: jsonSerialization['escrowAddress'] as String?,
      fundingSignature: jsonSerialization['fundingSignature'] as String?,
      fundedAt: jsonSerialization['fundedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['fundedAt']),
    );
  }

  _is.UuidValue poolId;

  _i2n7u226.RewardPoolStatus status;

  _ifrvw135.RewardCluster cluster;

  String mint;

  String tokenSymbol;

  int decimals;

  int amountPerPayout;

  int maxPayouts;

  int maxWinsPerAccount;

  int payoutsReserved;

  int payoutsReleased;

  DateTime expiresAt;

  DateTime refundAfter;

  String? creatorWallet;

  String? escrowAddress;

  String? fundingSignature;

  DateTime? fundedAt;

  /// Returns a shallow copy of this [RewardPoolView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RewardPoolView copyWith({
    _is.UuidValue? poolId,
    _i2n7u226.RewardPoolStatus? status,
    _ifrvw135.RewardCluster? cluster,
    String? mint,
    String? tokenSymbol,
    int? decimals,
    int? amountPerPayout,
    int? maxPayouts,
    int? maxWinsPerAccount,
    int? payoutsReserved,
    int? payoutsReleased,
    DateTime? expiresAt,
    DateTime? refundAfter,
    String? creatorWallet,
    String? escrowAddress,
    String? fundingSignature,
    DateTime? fundedAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RewardPoolView',
      'poolId': poolId.toJson(),
      'status': status.toJson(),
      'cluster': cluster.toJson(),
      'mint': mint,
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'amountPerPayout': amountPerPayout,
      'maxPayouts': maxPayouts,
      'maxWinsPerAccount': maxWinsPerAccount,
      'payoutsReserved': payoutsReserved,
      'payoutsReleased': payoutsReleased,
      'expiresAt': expiresAt.toJson(),
      'refundAfter': refundAfter.toJson(),
      if (creatorWallet != null) 'creatorWallet': creatorWallet,
      if (escrowAddress != null) 'escrowAddress': escrowAddress,
      if (fundingSignature != null) 'fundingSignature': fundingSignature,
      if (fundedAt != null) 'fundedAt': fundedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RewardPoolView',
      'poolId': poolId.toJson(),
      'status': status.toJson(),
      'cluster': cluster.toJson(),
      'mint': mint,
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'amountPerPayout': amountPerPayout,
      'maxPayouts': maxPayouts,
      'maxWinsPerAccount': maxWinsPerAccount,
      'payoutsReserved': payoutsReserved,
      'payoutsReleased': payoutsReleased,
      'expiresAt': expiresAt.toJson(),
      'refundAfter': refundAfter.toJson(),
      if (creatorWallet != null) 'creatorWallet': creatorWallet,
      if (escrowAddress != null) 'escrowAddress': escrowAddress,
      if (fundingSignature != null) 'fundingSignature': fundingSignature,
      if (fundedAt != null) 'fundedAt': fundedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RewardPoolViewImpl extends RewardPoolView {
  _RewardPoolViewImpl({
    required _is.UuidValue poolId,
    required _i2n7u226.RewardPoolStatus status,
    required _ifrvw135.RewardCluster cluster,
    required String mint,
    required String tokenSymbol,
    required int decimals,
    required int amountPerPayout,
    required int maxPayouts,
    required int maxWinsPerAccount,
    required int payoutsReserved,
    required int payoutsReleased,
    required DateTime expiresAt,
    required DateTime refundAfter,
    String? creatorWallet,
    String? escrowAddress,
    String? fundingSignature,
    DateTime? fundedAt,
  }) : super._(
         poolId: poolId,
         status: status,
         cluster: cluster,
         mint: mint,
         tokenSymbol: tokenSymbol,
         decimals: decimals,
         amountPerPayout: amountPerPayout,
         maxPayouts: maxPayouts,
         maxWinsPerAccount: maxWinsPerAccount,
         payoutsReserved: payoutsReserved,
         payoutsReleased: payoutsReleased,
         expiresAt: expiresAt,
         refundAfter: refundAfter,
         creatorWallet: creatorWallet,
         escrowAddress: escrowAddress,
         fundingSignature: fundingSignature,
         fundedAt: fundedAt,
       );

  /// Returns a shallow copy of this [RewardPoolView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RewardPoolView copyWith({
    _is.UuidValue? poolId,
    _i2n7u226.RewardPoolStatus? status,
    _ifrvw135.RewardCluster? cluster,
    String? mint,
    String? tokenSymbol,
    int? decimals,
    int? amountPerPayout,
    int? maxPayouts,
    int? maxWinsPerAccount,
    int? payoutsReserved,
    int? payoutsReleased,
    DateTime? expiresAt,
    DateTime? refundAfter,
    Object? creatorWallet = _Undefined,
    Object? escrowAddress = _Undefined,
    Object? fundingSignature = _Undefined,
    DateTime? fundedAt = const _is.$UndefinedDateTime(),
  }) {
    return RewardPoolView(
      poolId: poolId ?? this.poolId,
      status: status ?? this.status,
      cluster: cluster ?? this.cluster,
      mint: mint ?? this.mint,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      decimals: decimals ?? this.decimals,
      amountPerPayout: amountPerPayout ?? this.amountPerPayout,
      maxPayouts: maxPayouts ?? this.maxPayouts,
      maxWinsPerAccount: maxWinsPerAccount ?? this.maxWinsPerAccount,
      payoutsReserved: payoutsReserved ?? this.payoutsReserved,
      payoutsReleased: payoutsReleased ?? this.payoutsReleased,
      expiresAt: expiresAt ?? this.expiresAt,
      refundAfter: refundAfter ?? this.refundAfter,
      creatorWallet: creatorWallet is String?
          ? creatorWallet
          : this.creatorWallet,
      escrowAddress: escrowAddress is String?
          ? escrowAddress
          : this.escrowAddress,
      fundingSignature: fundingSignature is String?
          ? fundingSignature
          : this.fundingSignature,
      fundedAt: fundedAt is _is.UndefinedSentinel ? this.fundedAt : fundedAt,
    );
  }
}
