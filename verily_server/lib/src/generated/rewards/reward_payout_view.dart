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
import '../rewards/reward_payout_status.dart' as _i8tvbfry;

abstract class RewardPayoutView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RewardPayoutView._({
    required this.id,
    required this.attemptId,
    required this.actionTitle,
    required this.cluster,
    required this.tokenSymbol,
    required this.decimals,
    required this.amount,
    required this.status,
    this.recipientWallet,
    this.releaseSignature,
    required this.createdAt,
    required this.updatedAt,
    required this.payableUntil,
  });

  factory RewardPayoutView({
    required _is.UuidValue id,
    required _is.UuidValue attemptId,
    required String actionTitle,
    required _ifrvw135.RewardCluster cluster,
    required String tokenSymbol,
    required int decimals,
    required int amount,
    required _i8tvbfry.RewardPayoutStatus status,
    String? recipientWallet,
    String? releaseSignature,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime payableUntil,
  }) = _RewardPayoutViewImpl;

  factory RewardPayoutView.fromJson(Map<String, dynamic> jsonSerialization) {
    return RewardPayoutView(
      id: _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      attemptId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      actionTitle: jsonSerialization['actionTitle'] as String,
      cluster: _ifrvw135.RewardCluster.fromJson(
        (jsonSerialization['cluster'] as String),
      ),
      tokenSymbol: jsonSerialization['tokenSymbol'] as String,
      decimals: jsonSerialization['decimals'] as int,
      amount: jsonSerialization['amount'] as int,
      status: _i8tvbfry.RewardPayoutStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      recipientWallet: jsonSerialization['recipientWallet'] as String?,
      releaseSignature: jsonSerialization['releaseSignature'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      payableUntil: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['payableUntil'],
      ),
    );
  }

  _is.UuidValue id;

  _is.UuidValue attemptId;

  String actionTitle;

  _ifrvw135.RewardCluster cluster;

  String tokenSymbol;

  int decimals;

  int amount;

  _i8tvbfry.RewardPayoutStatus status;

  String? recipientWallet;

  String? releaseSignature;

  DateTime createdAt;

  DateTime updatedAt;

  /// After this instant an unreleased payout can no longer be paid.
  DateTime payableUntil;

  /// Returns a shallow copy of this [RewardPayoutView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RewardPayoutView copyWith({
    _is.UuidValue? id,
    _is.UuidValue? attemptId,
    String? actionTitle,
    _ifrvw135.RewardCluster? cluster,
    String? tokenSymbol,
    int? decimals,
    int? amount,
    _i8tvbfry.RewardPayoutStatus? status,
    String? recipientWallet,
    String? releaseSignature,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? payableUntil,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RewardPayoutView',
      'id': id.toJson(),
      'attemptId': attemptId.toJson(),
      'actionTitle': actionTitle,
      'cluster': cluster.toJson(),
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'amount': amount,
      'status': status.toJson(),
      if (recipientWallet != null) 'recipientWallet': recipientWallet,
      if (releaseSignature != null) 'releaseSignature': releaseSignature,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'payableUntil': payableUntil.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RewardPayoutView',
      'id': id.toJson(),
      'attemptId': attemptId.toJson(),
      'actionTitle': actionTitle,
      'cluster': cluster.toJson(),
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'amount': amount,
      'status': status.toJson(),
      if (recipientWallet != null) 'recipientWallet': recipientWallet,
      if (releaseSignature != null) 'releaseSignature': releaseSignature,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'payableUntil': payableUntil.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RewardPayoutViewImpl extends RewardPayoutView {
  _RewardPayoutViewImpl({
    required _is.UuidValue id,
    required _is.UuidValue attemptId,
    required String actionTitle,
    required _ifrvw135.RewardCluster cluster,
    required String tokenSymbol,
    required int decimals,
    required int amount,
    required _i8tvbfry.RewardPayoutStatus status,
    String? recipientWallet,
    String? releaseSignature,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime payableUntil,
  }) : super._(
         id: id,
         attemptId: attemptId,
         actionTitle: actionTitle,
         cluster: cluster,
         tokenSymbol: tokenSymbol,
         decimals: decimals,
         amount: amount,
         status: status,
         recipientWallet: recipientWallet,
         releaseSignature: releaseSignature,
         createdAt: createdAt,
         updatedAt: updatedAt,
         payableUntil: payableUntil,
       );

  /// Returns a shallow copy of this [RewardPayoutView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RewardPayoutView copyWith({
    _is.UuidValue? id,
    _is.UuidValue? attemptId,
    String? actionTitle,
    _ifrvw135.RewardCluster? cluster,
    String? tokenSymbol,
    int? decimals,
    int? amount,
    _i8tvbfry.RewardPayoutStatus? status,
    Object? recipientWallet = _Undefined,
    Object? releaseSignature = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? payableUntil,
  }) {
    return RewardPayoutView(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      actionTitle: actionTitle ?? this.actionTitle,
      cluster: cluster ?? this.cluster,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      decimals: decimals ?? this.decimals,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      recipientWallet: recipientWallet is String?
          ? recipientWallet
          : this.recipientWallet,
      releaseSignature: releaseSignature is String?
          ? releaseSignature
          : this.releaseSignature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payableUntil: payableUntil ?? this.payableUntil,
    );
  }
}
