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

import '../action_verification/action_recurrence.dart' as _ivhzgwse;
import '../action_verification/action_requirement_draft.dart' as _igizvm0h;
import '../rewards/reward_terms_draft.dart' as _ixpcxx5a;

abstract class CreateActionDefinitionRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CreateActionDefinitionRequest._({
    required this.actionKey,
    required this.title,
    required this.description,
    required this.recurrence,
    required this.timeZone,
    this.maxVerifiedCompletions,
    this.opensAt,
    this.closesAt,
    required this.requirements,
    this.reward,
  });

  factory CreateActionDefinitionRequest({
    required String actionKey,
    required String title,
    required String description,
    required _ivhzgwse.ActionRecurrence recurrence,
    required String timeZone,
    int? maxVerifiedCompletions,
    DateTime? opensAt,
    DateTime? closesAt,
    required List<_igizvm0h.ActionRequirementDraft> requirements,
    _ixpcxx5a.RewardTermsDraft? reward,
  }) = _CreateActionDefinitionRequestImpl;

  factory CreateActionDefinitionRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CreateActionDefinitionRequest(
      actionKey: jsonSerialization['actionKey'] as String,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String,
      recurrence: _ivhzgwse.ActionRecurrence.fromJson(
        (jsonSerialization['recurrence'] as String),
      ),
      timeZone: jsonSerialization['timeZone'] as String,
      maxVerifiedCompletions:
          jsonSerialization['maxVerifiedCompletions'] as int?,
      opensAt: jsonSerialization['opensAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['opensAt']),
      closesAt: jsonSerialization['closesAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['closesAt']),
      requirements: _itf691yl.Protocol()
          .deserialize<List<_igizvm0h.ActionRequirementDraft>>(
            jsonSerialization['requirements'],
          ),
      reward: jsonSerialization['reward'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_ixpcxx5a.RewardTermsDraft>(
              jsonSerialization['reward'],
            ),
    );
  }

  String actionKey;

  String title;

  String description;

  _ivhzgwse.ActionRecurrence recurrence;

  String timeZone;

  int? maxVerifiedCompletions;

  DateTime? opensAt;

  DateTime? closesAt;

  List<_igizvm0h.ActionRequirementDraft> requirements;

  /// Optional escrowed reward. Terms can change only until funding starts.
  _ixpcxx5a.RewardTermsDraft? reward;

  /// Returns a shallow copy of this [CreateActionDefinitionRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CreateActionDefinitionRequest copyWith({
    String? actionKey,
    String? title,
    String? description,
    _ivhzgwse.ActionRecurrence? recurrence,
    String? timeZone,
    int? maxVerifiedCompletions,
    DateTime? opensAt,
    DateTime? closesAt,
    List<_igizvm0h.ActionRequirementDraft>? requirements,
    _ixpcxx5a.RewardTermsDraft? reward,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateActionDefinitionRequest',
      'actionKey': actionKey,
      'title': title,
      'description': description,
      'recurrence': recurrence.toJson(),
      'timeZone': timeZone,
      if (maxVerifiedCompletions != null)
        'maxVerifiedCompletions': maxVerifiedCompletions,
      if (opensAt != null) 'opensAt': opensAt?.toJson(),
      if (closesAt != null) 'closesAt': closesAt?.toJson(),
      'requirements': requirements.toJson(valueToJson: (v) => v.toJson()),
      if (reward != null) 'reward': reward?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CreateActionDefinitionRequest',
      'actionKey': actionKey,
      'title': title,
      'description': description,
      'recurrence': recurrence.toJson(),
      'timeZone': timeZone,
      if (maxVerifiedCompletions != null)
        'maxVerifiedCompletions': maxVerifiedCompletions,
      if (opensAt != null) 'opensAt': opensAt?.toJson(),
      if (closesAt != null) 'closesAt': closesAt?.toJson(),
      'requirements': requirements.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      if (reward != null) 'reward': reward?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CreateActionDefinitionRequestImpl extends CreateActionDefinitionRequest {
  _CreateActionDefinitionRequestImpl({
    required String actionKey,
    required String title,
    required String description,
    required _ivhzgwse.ActionRecurrence recurrence,
    required String timeZone,
    int? maxVerifiedCompletions,
    DateTime? opensAt,
    DateTime? closesAt,
    required List<_igizvm0h.ActionRequirementDraft> requirements,
    _ixpcxx5a.RewardTermsDraft? reward,
  }) : super._(
         actionKey: actionKey,
         title: title,
         description: description,
         recurrence: recurrence,
         timeZone: timeZone,
         maxVerifiedCompletions: maxVerifiedCompletions,
         opensAt: opensAt,
         closesAt: closesAt,
         requirements: requirements,
         reward: reward,
       );

  /// Returns a shallow copy of this [CreateActionDefinitionRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CreateActionDefinitionRequest copyWith({
    String? actionKey,
    String? title,
    String? description,
    _ivhzgwse.ActionRecurrence? recurrence,
    String? timeZone,
    Object? maxVerifiedCompletions = _Undefined,
    Object? opensAt = _Undefined,
    Object? closesAt = _Undefined,
    List<_igizvm0h.ActionRequirementDraft>? requirements,
    Object? reward = _Undefined,
  }) {
    return CreateActionDefinitionRequest(
      actionKey: actionKey ?? this.actionKey,
      title: title ?? this.title,
      description: description ?? this.description,
      recurrence: recurrence ?? this.recurrence,
      timeZone: timeZone ?? this.timeZone,
      maxVerifiedCompletions: maxVerifiedCompletions is int?
          ? maxVerifiedCompletions
          : this.maxVerifiedCompletions,
      opensAt: opensAt is DateTime? ? opensAt : this.opensAt,
      closesAt: closesAt is DateTime? ? closesAt : this.closesAt,
      requirements:
          requirements ?? this.requirements.map((e0) => e0.copyWith()).toList(),
      reward: reward is _ixpcxx5a.RewardTermsDraft?
          ? reward
          : this.reward?.copyWith(),
    );
  }
}
