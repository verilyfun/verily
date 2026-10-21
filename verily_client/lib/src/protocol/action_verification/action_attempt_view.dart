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
import 'package:verily_client/src/protocol/protocol.dart' as _iop4qpu5;

import '../action_verification/action_attempt_status.dart' as _i8xrgke5;
import '../rewards/reward_outcome.dart' as _ilgf73sw;
import '../rewards/reward_payout_status.dart' as _i8tvbfry;

abstract class ActionAttemptView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActionAttemptView._({
    required this.id,
    required this.actionDefinitionId,
    required this.periodKey,
    required this.status,
    this.verificationScore,
    this.verifiedRank,
    this.rejectionCode,
    required this.startedAt,
    this.submittedAt,
    this.verifiedAt,
    required this.updatedAt,
    this.rewardOutcome,
    this.payoutStatus,
    this.acceptedRequirementIds,
    bool? rewardValueReview,
  }) : rewardValueReview = rewardValueReview ?? false;

  factory ActionAttemptView({
    required _isc.UuidValue id,
    required _isc.UuidValue actionDefinitionId,
    required String periodKey,
    required _i8xrgke5.ActionAttemptStatus status,
    double? verificationScore,
    int? verifiedRank,
    String? rejectionCode,
    required DateTime startedAt,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    required DateTime updatedAt,
    _ilgf73sw.RewardOutcome? rewardOutcome,
    _i8tvbfry.RewardPayoutStatus? payoutStatus,
    List<_isc.UuidValue>? acceptedRequirementIds,
    bool? rewardValueReview,
  }) = _ActionAttemptViewImpl;

  factory ActionAttemptView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionAttemptView(
      id: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      actionDefinitionId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['actionDefinitionId'],
      ),
      periodKey: jsonSerialization['periodKey'] as String,
      status: _i8xrgke5.ActionAttemptStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      verificationScore: (jsonSerialization['verificationScore'] as num?)
          ?.toDouble(),
      verifiedRank: jsonSerialization['verifiedRank'] as int?,
      rejectionCode: jsonSerialization['rejectionCode'] as String?,
      startedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['startedAt'],
      ),
      submittedAt: jsonSerialization['submittedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['submittedAt'],
            ),
      verifiedAt: jsonSerialization['verifiedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['verifiedAt'],
            ),
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      rewardOutcome: jsonSerialization['rewardOutcome'] == null
          ? null
          : _ilgf73sw.RewardOutcome.fromJson(
              (jsonSerialization['rewardOutcome'] as String),
            ),
      payoutStatus: jsonSerialization['payoutStatus'] == null
          ? null
          : _i8tvbfry.RewardPayoutStatus.fromJson(
              (jsonSerialization['payoutStatus'] as String),
            ),
      acceptedRequirementIds:
          jsonSerialization['acceptedRequirementIds'] == null
          ? null
          : _iop4qpu5.Protocol().deserialize<List<_isc.UuidValue>>(
              jsonSerialization['acceptedRequirementIds'],
            ),
      rewardValueReview: jsonSerialization['rewardValueReview'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['rewardValueReview'],
            ),
    );
  }

  _isc.UuidValue id;

  _isc.UuidValue actionDefinitionId;

  String periodKey;

  _i8xrgke5.ActionAttemptStatus status;

  double? verificationScore;

  int? verifiedRank;

  String? rejectionCode;

  DateTime startedAt;

  DateTime? submittedAt;

  DateTime? verifiedAt;

  DateTime updatedAt;

  /// Whether the verified attempt won a payout, or why not; null when the
  /// action carries no reward.
  _ilgf73sw.RewardOutcome? rewardOutcome;

  /// The won payout's state, when there is one.
  _i8tvbfry.RewardPayoutStatus? payoutStatus;

  /// Requirements whose latest proof was accepted; null when not loaded.
  List<_isc.UuidValue>? acceptedRequirementIds;

  /// Whether a person checks this attempt because its payout is above the
  /// automatic-release threshold. The payout is reserved after that check.
  bool rewardValueReview;

  /// Returns a shallow copy of this [ActionAttemptView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionAttemptView copyWith({
    _isc.UuidValue? id,
    _isc.UuidValue? actionDefinitionId,
    String? periodKey,
    _i8xrgke5.ActionAttemptStatus? status,
    double? verificationScore,
    int? verifiedRank,
    String? rejectionCode,
    DateTime? startedAt,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    DateTime? updatedAt,
    _ilgf73sw.RewardOutcome? rewardOutcome,
    _i8tvbfry.RewardPayoutStatus? payoutStatus,
    List<_isc.UuidValue>? acceptedRequirementIds,
    bool? rewardValueReview,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionAttemptView',
      'id': id.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      'periodKey': periodKey,
      'status': status.toJson(),
      if (verificationScore != null) 'verificationScore': verificationScore,
      if (verifiedRank != null) 'verifiedRank': verifiedRank,
      if (rejectionCode != null) 'rejectionCode': rejectionCode,
      'startedAt': startedAt.toJson(),
      if (submittedAt != null) 'submittedAt': submittedAt?.toJson(),
      if (verifiedAt != null) 'verifiedAt': verifiedAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (rewardOutcome != null) 'rewardOutcome': rewardOutcome?.toJson(),
      if (payoutStatus != null) 'payoutStatus': payoutStatus?.toJson(),
      if (acceptedRequirementIds != null)
        'acceptedRequirementIds': acceptedRequirementIds?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      'rewardValueReview': rewardValueReview,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionAttemptView',
      'id': id.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      'periodKey': periodKey,
      'status': status.toJson(),
      if (verificationScore != null) 'verificationScore': verificationScore,
      if (verifiedRank != null) 'verifiedRank': verifiedRank,
      if (rejectionCode != null) 'rejectionCode': rejectionCode,
      'startedAt': startedAt.toJson(),
      if (submittedAt != null) 'submittedAt': submittedAt?.toJson(),
      if (verifiedAt != null) 'verifiedAt': verifiedAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (rewardOutcome != null) 'rewardOutcome': rewardOutcome?.toJson(),
      if (payoutStatus != null) 'payoutStatus': payoutStatus?.toJson(),
      if (acceptedRequirementIds != null)
        'acceptedRequirementIds': acceptedRequirementIds?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      'rewardValueReview': rewardValueReview,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionAttemptViewImpl extends ActionAttemptView {
  _ActionAttemptViewImpl({
    required _isc.UuidValue id,
    required _isc.UuidValue actionDefinitionId,
    required String periodKey,
    required _i8xrgke5.ActionAttemptStatus status,
    double? verificationScore,
    int? verifiedRank,
    String? rejectionCode,
    required DateTime startedAt,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    required DateTime updatedAt,
    _ilgf73sw.RewardOutcome? rewardOutcome,
    _i8tvbfry.RewardPayoutStatus? payoutStatus,
    List<_isc.UuidValue>? acceptedRequirementIds,
    bool? rewardValueReview,
  }) : super._(
         id: id,
         actionDefinitionId: actionDefinitionId,
         periodKey: periodKey,
         status: status,
         verificationScore: verificationScore,
         verifiedRank: verifiedRank,
         rejectionCode: rejectionCode,
         startedAt: startedAt,
         submittedAt: submittedAt,
         verifiedAt: verifiedAt,
         updatedAt: updatedAt,
         rewardOutcome: rewardOutcome,
         payoutStatus: payoutStatus,
         acceptedRequirementIds: acceptedRequirementIds,
         rewardValueReview: rewardValueReview,
       );

  /// Returns a shallow copy of this [ActionAttemptView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActionAttemptView copyWith({
    _isc.UuidValue? id,
    _isc.UuidValue? actionDefinitionId,
    String? periodKey,
    _i8xrgke5.ActionAttemptStatus? status,
    Object? verificationScore = _Undefined,
    Object? verifiedRank = _Undefined,
    Object? rejectionCode = _Undefined,
    DateTime? startedAt,
    Object? submittedAt = _Undefined,
    Object? verifiedAt = _Undefined,
    DateTime? updatedAt,
    Object? rewardOutcome = _Undefined,
    Object? payoutStatus = _Undefined,
    Object? acceptedRequirementIds = _Undefined,
    bool? rewardValueReview,
  }) {
    return ActionAttemptView(
      id: id ?? this.id,
      actionDefinitionId: actionDefinitionId ?? this.actionDefinitionId,
      periodKey: periodKey ?? this.periodKey,
      status: status ?? this.status,
      verificationScore: verificationScore is double?
          ? verificationScore
          : this.verificationScore,
      verifiedRank: verifiedRank is int? ? verifiedRank : this.verifiedRank,
      rejectionCode: rejectionCode is String?
          ? rejectionCode
          : this.rejectionCode,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt is DateTime? ? submittedAt : this.submittedAt,
      verifiedAt: verifiedAt is DateTime? ? verifiedAt : this.verifiedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rewardOutcome: rewardOutcome is _ilgf73sw.RewardOutcome?
          ? rewardOutcome
          : this.rewardOutcome,
      payoutStatus: payoutStatus is _i8tvbfry.RewardPayoutStatus?
          ? payoutStatus
          : this.payoutStatus,
      acceptedRequirementIds: acceptedRequirementIds is List<_isc.UuidValue>?
          ? acceptedRequirementIds
          : this.acceptedRequirementIds?.map((e0) => e0).toList(),
      rewardValueReview: rewardValueReview ?? this.rewardValueReview,
    );
  }
}
