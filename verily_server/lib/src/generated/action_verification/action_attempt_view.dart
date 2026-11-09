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
import 'package:verily_server/src/generated/protocol.dart' as _itf691yl;

import '../action_verification/action_attempt_status.dart' as _i8xrgke5;
import '../rewards/reward_outcome.dart' as _ilgf73sw;
import '../rewards/reward_payout_status.dart' as _i8tvbfry;

abstract class ActionAttemptView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ActionAttemptView._({
    required this.id,
    required this.actionDefinitionId,
    this.actionTitle,
    this.actionKey,
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
    required _is.UuidValue id,
    required _is.UuidValue actionDefinitionId,
    String? actionTitle,
    String? actionKey,
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
    List<_is.UuidValue>? acceptedRequirementIds,
    bool? rewardValueReview,
  }) = _ActionAttemptViewImpl;

  factory ActionAttemptView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionAttemptView(
      id: _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      actionDefinitionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['actionDefinitionId'],
      ),
      actionTitle: jsonSerialization['actionTitle'] as String?,
      actionKey: jsonSerialization['actionKey'] as String?,
      periodKey: jsonSerialization['periodKey'] as String,
      status: _i8xrgke5.ActionAttemptStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      verificationScore: (jsonSerialization['verificationScore'] as num?)
          ?.toDouble(),
      verifiedRank: jsonSerialization['verifiedRank'] as int?,
      rejectionCode: jsonSerialization['rejectionCode'] as String?,
      startedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['startedAt'],
      ),
      submittedAt: jsonSerialization['submittedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['submittedAt'],
            ),
      verifiedAt: jsonSerialization['verifiedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['verifiedAt']),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
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
          : _itf691yl.Protocol().deserialize<List<_is.UuidValue>>(
              jsonSerialization['acceptedRequirementIds'],
            ),
      rewardValueReview: jsonSerialization['rewardValueReview'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['rewardValueReview'],
            ),
    );
  }

  _is.UuidValue id;

  _is.UuidValue actionDefinitionId;

  /// The action's title and key, so lists of attempts need no lookup.
  String? actionTitle;

  String? actionKey;

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
  List<_is.UuidValue>? acceptedRequirementIds;

  /// Whether a person checks this attempt because its payout is above the
  /// automatic-release threshold. The payout is reserved after that check.
  bool rewardValueReview;

  /// Returns a shallow copy of this [ActionAttemptView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionAttemptView copyWith({
    _is.UuidValue? id,
    _is.UuidValue? actionDefinitionId,
    String? actionTitle,
    String? actionKey,
    String? periodKey,
    _i8xrgke5.ActionAttemptStatus? status,
    double? verificationScore,
    int? verifiedRank,
    String? rejectionCode,
    DateTime? startedAt,
    DateTime? submittedAt = const _is.$UndefinedDateTime(),
    DateTime? verifiedAt = const _is.$UndefinedDateTime(),
    DateTime? updatedAt,
    _ilgf73sw.RewardOutcome? rewardOutcome,
    _i8tvbfry.RewardPayoutStatus? payoutStatus,
    List<_is.UuidValue>? acceptedRequirementIds =
        const _is.$UndefinedList<_is.UuidValue>(),
    bool? rewardValueReview,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionAttemptView',
      'id': id.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      if (actionTitle != null) 'actionTitle': actionTitle,
      if (actionKey != null) 'actionKey': actionKey,
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
      if (actionTitle != null) 'actionTitle': actionTitle,
      if (actionKey != null) 'actionKey': actionKey,
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
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionAttemptViewImpl extends ActionAttemptView {
  _ActionAttemptViewImpl({
    required _is.UuidValue id,
    required _is.UuidValue actionDefinitionId,
    String? actionTitle,
    String? actionKey,
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
    List<_is.UuidValue>? acceptedRequirementIds,
    bool? rewardValueReview,
  }) : super._(
         id: id,
         actionDefinitionId: actionDefinitionId,
         actionTitle: actionTitle,
         actionKey: actionKey,
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
  @_is.useResult
  @override
  ActionAttemptView copyWith({
    _is.UuidValue? id,
    _is.UuidValue? actionDefinitionId,
    Object? actionTitle = _Undefined,
    Object? actionKey = _Undefined,
    String? periodKey,
    _i8xrgke5.ActionAttemptStatus? status,
    Object? verificationScore = _Undefined,
    Object? verifiedRank = _Undefined,
    Object? rejectionCode = _Undefined,
    DateTime? startedAt,
    DateTime? submittedAt = const _is.$UndefinedDateTime(),
    DateTime? verifiedAt = const _is.$UndefinedDateTime(),
    DateTime? updatedAt,
    Object? rewardOutcome = _Undefined,
    Object? payoutStatus = _Undefined,
    List<_is.UuidValue>? acceptedRequirementIds =
        const _is.$UndefinedList<_is.UuidValue>(),
    bool? rewardValueReview,
  }) {
    return ActionAttemptView(
      id: id ?? this.id,
      actionDefinitionId: actionDefinitionId ?? this.actionDefinitionId,
      actionTitle: actionTitle is String? ? actionTitle : this.actionTitle,
      actionKey: actionKey is String? ? actionKey : this.actionKey,
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
      submittedAt: submittedAt is _is.UndefinedSentinel
          ? this.submittedAt
          : submittedAt,
      verifiedAt: verifiedAt is _is.UndefinedSentinel
          ? this.verifiedAt
          : verifiedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rewardOutcome: rewardOutcome is _ilgf73sw.RewardOutcome?
          ? rewardOutcome
          : this.rewardOutcome,
      payoutStatus: payoutStatus is _i8tvbfry.RewardPayoutStatus?
          ? payoutStatus
          : this.payoutStatus,
      acceptedRequirementIds: acceptedRequirementIds is _is.UndefinedSentinel
          ? this.acceptedRequirementIds?.map((e0) => e0).toList()
          : acceptedRequirementIds,
      rewardValueReview: rewardValueReview ?? this.rewardValueReview,
    );
  }
}
