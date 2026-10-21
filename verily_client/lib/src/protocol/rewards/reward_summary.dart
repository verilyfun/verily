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

import '../rewards/reward_cluster.dart' as _ifrvw135;
import '../rewards/reward_pool_status.dart' as _i2n7u226;

/// The public, checkable facts about an action's reward.
abstract class RewardSummary
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RewardSummary._({
    required this.cluster,
    required this.mint,
    required this.tokenSymbol,
    required this.decimals,
    required this.amountPerPayout,
    required this.maxPayouts,
    required this.payoutsRemaining,
    required this.maxWinsPerAccount,
    required this.myWins,
    required this.status,
    required this.expiresAt,
    this.escrowAddress,
  });

  factory RewardSummary({
    required _ifrvw135.RewardCluster cluster,
    required String mint,
    required String tokenSymbol,
    required int decimals,
    required int amountPerPayout,
    required int maxPayouts,
    required int payoutsRemaining,
    required int maxWinsPerAccount,
    required int myWins,
    required _i2n7u226.RewardPoolStatus status,
    required DateTime expiresAt,
    String? escrowAddress,
  }) = _RewardSummaryImpl;

  factory RewardSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return RewardSummary(
      cluster: _ifrvw135.RewardCluster.fromJson(
        (jsonSerialization['cluster'] as String),
      ),
      mint: jsonSerialization['mint'] as String,
      tokenSymbol: jsonSerialization['tokenSymbol'] as String,
      decimals: jsonSerialization['decimals'] as int,
      amountPerPayout: jsonSerialization['amountPerPayout'] as int,
      maxPayouts: jsonSerialization['maxPayouts'] as int,
      payoutsRemaining: jsonSerialization['payoutsRemaining'] as int,
      maxWinsPerAccount: jsonSerialization['maxWinsPerAccount'] as int,
      myWins: jsonSerialization['myWins'] as int,
      status: _i2n7u226.RewardPoolStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      escrowAddress: jsonSerialization['escrowAddress'] as String?,
    );
  }

  _ifrvw135.RewardCluster cluster;

  String mint;

  String tokenSymbol;

  int decimals;

  int amountPerPayout;

  int maxPayouts;

  int payoutsRemaining;

  int maxWinsPerAccount;

  /// Payouts the viewing account already holds from this pool.
  int myWins;

  _i2n7u226.RewardPoolStatus status;

  DateTime expiresAt;

  /// Anyone can read this escrow on chain; null until funding starts.
  String? escrowAddress;

  /// Returns a shallow copy of this [RewardSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RewardSummary copyWith({
    _ifrvw135.RewardCluster? cluster,
    String? mint,
    String? tokenSymbol,
    int? decimals,
    int? amountPerPayout,
    int? maxPayouts,
    int? payoutsRemaining,
    int? maxWinsPerAccount,
    int? myWins,
    _i2n7u226.RewardPoolStatus? status,
    DateTime? expiresAt,
    String? escrowAddress,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RewardSummary',
      'cluster': cluster.toJson(),
      'mint': mint,
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'amountPerPayout': amountPerPayout,
      'maxPayouts': maxPayouts,
      'payoutsRemaining': payoutsRemaining,
      'maxWinsPerAccount': maxWinsPerAccount,
      'myWins': myWins,
      'status': status.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (escrowAddress != null) 'escrowAddress': escrowAddress,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RewardSummary',
      'cluster': cluster.toJson(),
      'mint': mint,
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'amountPerPayout': amountPerPayout,
      'maxPayouts': maxPayouts,
      'payoutsRemaining': payoutsRemaining,
      'maxWinsPerAccount': maxWinsPerAccount,
      'myWins': myWins,
      'status': status.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (escrowAddress != null) 'escrowAddress': escrowAddress,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RewardSummaryImpl extends RewardSummary {
  _RewardSummaryImpl({
    required _ifrvw135.RewardCluster cluster,
    required String mint,
    required String tokenSymbol,
    required int decimals,
    required int amountPerPayout,
    required int maxPayouts,
    required int payoutsRemaining,
    required int maxWinsPerAccount,
    required int myWins,
    required _i2n7u226.RewardPoolStatus status,
    required DateTime expiresAt,
    String? escrowAddress,
  }) : super._(
         cluster: cluster,
         mint: mint,
         tokenSymbol: tokenSymbol,
         decimals: decimals,
         amountPerPayout: amountPerPayout,
         maxPayouts: maxPayouts,
         payoutsRemaining: payoutsRemaining,
         maxWinsPerAccount: maxWinsPerAccount,
         myWins: myWins,
         status: status,
         expiresAt: expiresAt,
         escrowAddress: escrowAddress,
       );

  /// Returns a shallow copy of this [RewardSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RewardSummary copyWith({
    _ifrvw135.RewardCluster? cluster,
    String? mint,
    String? tokenSymbol,
    int? decimals,
    int? amountPerPayout,
    int? maxPayouts,
    int? payoutsRemaining,
    int? maxWinsPerAccount,
    int? myWins,
    _i2n7u226.RewardPoolStatus? status,
    DateTime? expiresAt,
    Object? escrowAddress = _Undefined,
  }) {
    return RewardSummary(
      cluster: cluster ?? this.cluster,
      mint: mint ?? this.mint,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      decimals: decimals ?? this.decimals,
      amountPerPayout: amountPerPayout ?? this.amountPerPayout,
      maxPayouts: maxPayouts ?? this.maxPayouts,
      payoutsRemaining: payoutsRemaining ?? this.payoutsRemaining,
      maxWinsPerAccount: maxWinsPerAccount ?? this.maxWinsPerAccount,
      myWins: myWins ?? this.myWins,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      escrowAddress: escrowAddress is String?
          ? escrowAddress
          : this.escrowAddress,
    );
  }
}
