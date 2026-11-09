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

import '../action_verification/action_requirement_kind.dart' as _iws572ni;
import '../action_verification/evidence_appeal_status.dart' as _i246oa84;

abstract class EvidenceAppealView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  EvidenceAppealView._({
    required this.id,
    required this.evidenceId,
    required this.attemptId,
    required this.actionTitle,
    required this.requirementTitle,
    required this.requirementKind,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.resolutionNote,
    this.resolvedAt,
    this.mediaUrl,
    this.spokenChallengeWord,
  });

  factory EvidenceAppealView({
    required _is.UuidValue id,
    required _is.UuidValue evidenceId,
    required _is.UuidValue attemptId,
    required String actionTitle,
    required String requirementTitle,
    required _iws572ni.ActionRequirementKind requirementKind,
    required String reason,
    required _i246oa84.EvidenceAppealStatus status,
    required DateTime createdAt,
    String? resolutionNote,
    DateTime? resolvedAt,
    String? mediaUrl,
    String? spokenChallengeWord,
  }) = _EvidenceAppealViewImpl;

  factory EvidenceAppealView.fromJson(Map<String, dynamic> jsonSerialization) {
    return EvidenceAppealView(
      id: _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      evidenceId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['evidenceId'],
      ),
      attemptId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      actionTitle: jsonSerialization['actionTitle'] as String,
      requirementTitle: jsonSerialization['requirementTitle'] as String,
      requirementKind: _iws572ni.ActionRequirementKind.fromJson(
        (jsonSerialization['requirementKind'] as String),
      ),
      reason: jsonSerialization['reason'] as String,
      status: _i246oa84.EvidenceAppealStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      resolutionNote: jsonSerialization['resolutionNote'] as String?,
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
      mediaUrl: jsonSerialization['mediaUrl'] as String?,
      spokenChallengeWord: jsonSerialization['spokenChallengeWord'] as String?,
    );
  }

  _is.UuidValue id;

  _is.UuidValue evidenceId;

  _is.UuidValue attemptId;

  String actionTitle;

  String requirementTitle;

  _iws572ni.ActionRequirementKind requirementKind;

  String reason;

  _i246oa84.EvidenceAppealStatus status;

  DateTime createdAt;

  String? resolutionNote;

  DateTime? resolvedAt;

  /// Short-lived private playback link, only for the creator resolving it.
  String? mediaUrl;

  String? spokenChallengeWord;

  /// Returns a shallow copy of this [EvidenceAppealView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  EvidenceAppealView copyWith({
    _is.UuidValue? id,
    _is.UuidValue? evidenceId,
    _is.UuidValue? attemptId,
    String? actionTitle,
    String? requirementTitle,
    _iws572ni.ActionRequirementKind? requirementKind,
    String? reason,
    _i246oa84.EvidenceAppealStatus? status,
    DateTime? createdAt,
    String? resolutionNote,
    DateTime? resolvedAt = const _is.$UndefinedDateTime(),
    String? mediaUrl,
    String? spokenChallengeWord,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceAppealView',
      'id': id.toJson(),
      'evidenceId': evidenceId.toJson(),
      'attemptId': attemptId.toJson(),
      'actionTitle': actionTitle,
      'requirementTitle': requirementTitle,
      'requirementKind': requirementKind.toJson(),
      'reason': reason,
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
      if (resolutionNote != null) 'resolutionNote': resolutionNote,
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (spokenChallengeWord != null)
        'spokenChallengeWord': spokenChallengeWord,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'EvidenceAppealView',
      'id': id.toJson(),
      'evidenceId': evidenceId.toJson(),
      'attemptId': attemptId.toJson(),
      'actionTitle': actionTitle,
      'requirementTitle': requirementTitle,
      'requirementKind': requirementKind.toJson(),
      'reason': reason,
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
      if (resolutionNote != null) 'resolutionNote': resolutionNote,
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (spokenChallengeWord != null)
        'spokenChallengeWord': spokenChallengeWord,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EvidenceAppealViewImpl extends EvidenceAppealView {
  _EvidenceAppealViewImpl({
    required _is.UuidValue id,
    required _is.UuidValue evidenceId,
    required _is.UuidValue attemptId,
    required String actionTitle,
    required String requirementTitle,
    required _iws572ni.ActionRequirementKind requirementKind,
    required String reason,
    required _i246oa84.EvidenceAppealStatus status,
    required DateTime createdAt,
    String? resolutionNote,
    DateTime? resolvedAt,
    String? mediaUrl,
    String? spokenChallengeWord,
  }) : super._(
         id: id,
         evidenceId: evidenceId,
         attemptId: attemptId,
         actionTitle: actionTitle,
         requirementTitle: requirementTitle,
         requirementKind: requirementKind,
         reason: reason,
         status: status,
         createdAt: createdAt,
         resolutionNote: resolutionNote,
         resolvedAt: resolvedAt,
         mediaUrl: mediaUrl,
         spokenChallengeWord: spokenChallengeWord,
       );

  /// Returns a shallow copy of this [EvidenceAppealView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  EvidenceAppealView copyWith({
    _is.UuidValue? id,
    _is.UuidValue? evidenceId,
    _is.UuidValue? attemptId,
    String? actionTitle,
    String? requirementTitle,
    _iws572ni.ActionRequirementKind? requirementKind,
    String? reason,
    _i246oa84.EvidenceAppealStatus? status,
    DateTime? createdAt,
    Object? resolutionNote = _Undefined,
    DateTime? resolvedAt = const _is.$UndefinedDateTime(),
    Object? mediaUrl = _Undefined,
    Object? spokenChallengeWord = _Undefined,
  }) {
    return EvidenceAppealView(
      id: id ?? this.id,
      evidenceId: evidenceId ?? this.evidenceId,
      attemptId: attemptId ?? this.attemptId,
      actionTitle: actionTitle ?? this.actionTitle,
      requirementTitle: requirementTitle ?? this.requirementTitle,
      requirementKind: requirementKind ?? this.requirementKind,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolutionNote: resolutionNote is String?
          ? resolutionNote
          : this.resolutionNote,
      resolvedAt: resolvedAt is _is.UndefinedSentinel
          ? this.resolvedAt
          : resolvedAt,
      mediaUrl: mediaUrl is String? ? mediaUrl : this.mediaUrl,
      spokenChallengeWord: spokenChallengeWord is String?
          ? spokenChallengeWord
          : this.spokenChallengeWord,
    );
  }
}
