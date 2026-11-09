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

import '../action_verification/action_attempt_view.dart' as _ia5uqadz;
import '../action_verification/action_definition_status.dart' as _irpnjpe3;
import '../action_verification/action_recurrence.dart' as _ivhzgwse;
import '../action_verification/action_requirement_view.dart' as _if4hgiwe;
import '../rewards/reward_summary.dart' as _ifzz09nq;

abstract class ActionOpportunity
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ActionOpportunity._({
    required this.id,
    required this.creatorDisplayName,
    required this.viewerIsCreator,
    required this.actionKey,
    required this.revision,
    required this.status,
    required this.title,
    required this.description,
    required this.recurrence,
    required this.timeZone,
    this.maxVerifiedCompletions,
    required this.verifiedCompletions,
    this.opensAt,
    this.closesAt,
    this.publishedAt,
    required this.updatedAt,
    required this.requirements,
    this.myAttempt,
    this.reward,
  });

  factory ActionOpportunity({
    required _is.UuidValue id,
    required String creatorDisplayName,
    required bool viewerIsCreator,
    required String actionKey,
    required int revision,
    required _irpnjpe3.ActionDefinitionStatus status,
    required String title,
    required String description,
    required _ivhzgwse.ActionRecurrence recurrence,
    required String timeZone,
    int? maxVerifiedCompletions,
    required int verifiedCompletions,
    DateTime? opensAt,
    DateTime? closesAt,
    DateTime? publishedAt,
    required DateTime updatedAt,
    required List<_if4hgiwe.ActionRequirementView> requirements,
    _ia5uqadz.ActionAttemptView? myAttempt,
    _ifzz09nq.RewardSummary? reward,
  }) = _ActionOpportunityImpl;

  factory ActionOpportunity.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionOpportunity(
      id: _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      creatorDisplayName: jsonSerialization['creatorDisplayName'] as String,
      viewerIsCreator: _is.BoolJsonExtension.fromJson(
        jsonSerialization['viewerIsCreator'],
      ),
      actionKey: jsonSerialization['actionKey'] as String,
      revision: jsonSerialization['revision'] as int,
      status: _irpnjpe3.ActionDefinitionStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String,
      recurrence: _ivhzgwse.ActionRecurrence.fromJson(
        (jsonSerialization['recurrence'] as String),
      ),
      timeZone: jsonSerialization['timeZone'] as String,
      maxVerifiedCompletions:
          jsonSerialization['maxVerifiedCompletions'] as int?,
      verifiedCompletions: jsonSerialization['verifiedCompletions'] as int,
      opensAt: jsonSerialization['opensAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['opensAt']),
      closesAt: jsonSerialization['closesAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['closesAt']),
      publishedAt: jsonSerialization['publishedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['publishedAt'],
            ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      requirements: _itf691yl.Protocol()
          .deserialize<List<_if4hgiwe.ActionRequirementView>>(
            jsonSerialization['requirements'],
          ),
      myAttempt: jsonSerialization['myAttempt'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_ia5uqadz.ActionAttemptView>(
              jsonSerialization['myAttempt'],
            ),
      reward: jsonSerialization['reward'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_ifzz09nq.RewardSummary>(
              jsonSerialization['reward'],
            ),
    );
  }

  _is.UuidValue id;

  String creatorDisplayName;

  /// Whether the signed-in account created this action.
  bool viewerIsCreator;

  String actionKey;

  int revision;

  _irpnjpe3.ActionDefinitionStatus status;

  String title;

  String description;

  _ivhzgwse.ActionRecurrence recurrence;

  String timeZone;

  int? maxVerifiedCompletions;

  int verifiedCompletions;

  DateTime? opensAt;

  DateTime? closesAt;

  DateTime? publishedAt;

  DateTime updatedAt;

  List<_if4hgiwe.ActionRequirementView> requirements;

  _ia5uqadz.ActionAttemptView? myAttempt;

  _ifzz09nq.RewardSummary? reward;

  /// Returns a shallow copy of this [ActionOpportunity]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionOpportunity copyWith({
    _is.UuidValue? id,
    String? creatorDisplayName,
    bool? viewerIsCreator,
    String? actionKey,
    int? revision,
    _irpnjpe3.ActionDefinitionStatus? status,
    String? title,
    String? description,
    _ivhzgwse.ActionRecurrence? recurrence,
    String? timeZone,
    int? maxVerifiedCompletions,
    int? verifiedCompletions,
    DateTime? opensAt = const _is.$UndefinedDateTime(),
    DateTime? closesAt = const _is.$UndefinedDateTime(),
    DateTime? publishedAt = const _is.$UndefinedDateTime(),
    DateTime? updatedAt,
    List<_if4hgiwe.ActionRequirementView>? requirements,
    _ia5uqadz.ActionAttemptView? myAttempt =
        const _UndefinedActionOpportunity$myAttempt(),
    _ifzz09nq.RewardSummary? reward =
        const _UndefinedActionOpportunity$reward(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionOpportunity',
      'id': id.toJson(),
      'creatorDisplayName': creatorDisplayName,
      'viewerIsCreator': viewerIsCreator,
      'actionKey': actionKey,
      'revision': revision,
      'status': status.toJson(),
      'title': title,
      'description': description,
      'recurrence': recurrence.toJson(),
      'timeZone': timeZone,
      if (maxVerifiedCompletions != null)
        'maxVerifiedCompletions': maxVerifiedCompletions,
      'verifiedCompletions': verifiedCompletions,
      if (opensAt != null) 'opensAt': opensAt?.toJson(),
      if (closesAt != null) 'closesAt': closesAt?.toJson(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
      'requirements': requirements.toJson(valueToJson: (v) => v.toJson()),
      if (myAttempt != null) 'myAttempt': myAttempt?.toJson(),
      if (reward != null) 'reward': reward?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionOpportunity',
      'id': id.toJson(),
      'creatorDisplayName': creatorDisplayName,
      'viewerIsCreator': viewerIsCreator,
      'actionKey': actionKey,
      'revision': revision,
      'status': status.toJson(),
      'title': title,
      'description': description,
      'recurrence': recurrence.toJson(),
      'timeZone': timeZone,
      if (maxVerifiedCompletions != null)
        'maxVerifiedCompletions': maxVerifiedCompletions,
      'verifiedCompletions': verifiedCompletions,
      if (opensAt != null) 'opensAt': opensAt?.toJson(),
      if (closesAt != null) 'closesAt': closesAt?.toJson(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
      'requirements': requirements.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      if (myAttempt != null) 'myAttempt': myAttempt?.toJsonForProtocol(),
      if (reward != null) 'reward': reward?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedActionOpportunity$myAttempt extends _is.UndefinedSentinel
    implements _ia5uqadz.ActionAttemptView {
  const _UndefinedActionOpportunity$myAttempt();
}

class _UndefinedActionOpportunity$reward extends _is.UndefinedSentinel
    implements _ifzz09nq.RewardSummary {
  const _UndefinedActionOpportunity$reward();
}

class _ActionOpportunityImpl extends ActionOpportunity {
  _ActionOpportunityImpl({
    required _is.UuidValue id,
    required String creatorDisplayName,
    required bool viewerIsCreator,
    required String actionKey,
    required int revision,
    required _irpnjpe3.ActionDefinitionStatus status,
    required String title,
    required String description,
    required _ivhzgwse.ActionRecurrence recurrence,
    required String timeZone,
    int? maxVerifiedCompletions,
    required int verifiedCompletions,
    DateTime? opensAt,
    DateTime? closesAt,
    DateTime? publishedAt,
    required DateTime updatedAt,
    required List<_if4hgiwe.ActionRequirementView> requirements,
    _ia5uqadz.ActionAttemptView? myAttempt,
    _ifzz09nq.RewardSummary? reward,
  }) : super._(
         id: id,
         creatorDisplayName: creatorDisplayName,
         viewerIsCreator: viewerIsCreator,
         actionKey: actionKey,
         revision: revision,
         status: status,
         title: title,
         description: description,
         recurrence: recurrence,
         timeZone: timeZone,
         maxVerifiedCompletions: maxVerifiedCompletions,
         verifiedCompletions: verifiedCompletions,
         opensAt: opensAt,
         closesAt: closesAt,
         publishedAt: publishedAt,
         updatedAt: updatedAt,
         requirements: requirements,
         myAttempt: myAttempt,
         reward: reward,
       );

  /// Returns a shallow copy of this [ActionOpportunity]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionOpportunity copyWith({
    _is.UuidValue? id,
    String? creatorDisplayName,
    bool? viewerIsCreator,
    String? actionKey,
    int? revision,
    _irpnjpe3.ActionDefinitionStatus? status,
    String? title,
    String? description,
    _ivhzgwse.ActionRecurrence? recurrence,
    String? timeZone,
    Object? maxVerifiedCompletions = _Undefined,
    int? verifiedCompletions,
    DateTime? opensAt = const _is.$UndefinedDateTime(),
    DateTime? closesAt = const _is.$UndefinedDateTime(),
    DateTime? publishedAt = const _is.$UndefinedDateTime(),
    DateTime? updatedAt,
    List<_if4hgiwe.ActionRequirementView>? requirements,
    _ia5uqadz.ActionAttemptView? myAttempt =
        const _UndefinedActionOpportunity$myAttempt(),
    _ifzz09nq.RewardSummary? reward =
        const _UndefinedActionOpportunity$reward(),
  }) {
    return ActionOpportunity(
      id: id ?? this.id,
      creatorDisplayName: creatorDisplayName ?? this.creatorDisplayName,
      viewerIsCreator: viewerIsCreator ?? this.viewerIsCreator,
      actionKey: actionKey ?? this.actionKey,
      revision: revision ?? this.revision,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      recurrence: recurrence ?? this.recurrence,
      timeZone: timeZone ?? this.timeZone,
      maxVerifiedCompletions: maxVerifiedCompletions is int?
          ? maxVerifiedCompletions
          : this.maxVerifiedCompletions,
      verifiedCompletions: verifiedCompletions ?? this.verifiedCompletions,
      opensAt: opensAt is _is.UndefinedSentinel ? this.opensAt : opensAt,
      closesAt: closesAt is _is.UndefinedSentinel ? this.closesAt : closesAt,
      publishedAt: publishedAt is _is.UndefinedSentinel
          ? this.publishedAt
          : publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requirements:
          requirements ?? this.requirements.map((e0) => e0.copyWith()).toList(),
      myAttempt: myAttempt is _is.UndefinedSentinel
          ? this.myAttempt?.copyWith()
          : myAttempt,
      reward: reward is _is.UndefinedSentinel
          ? this.reward?.copyWith()
          : reward,
    );
  }
}
