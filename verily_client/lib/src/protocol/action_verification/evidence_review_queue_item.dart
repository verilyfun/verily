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

import '../action_verification/action_requirement_kind.dart' as _iws572ni;
import '../action_verification/payout_review_view.dart' as _iimxtm94;

abstract class EvidenceReviewQueueItem
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  EvidenceReviewQueueItem._({
    required this.evidenceId,
    required this.attemptId,
    required this.actionDefinitionId,
    required this.creatorDisplayName,
    required this.actionTitle,
    required this.requirementTitle,
    required this.requirementKind,
    this.mimeType,
    this.byteLength,
    this.durationSeconds,
    required this.capturedAt,
    required this.submittedAt,
    required this.reviewReasonCode,
    required this.reviewSummary,
    this.mediaUrl,
    this.spokenChallengeWord,
    this.payoutReview,
  });

  factory EvidenceReviewQueueItem({
    required _isc.UuidValue evidenceId,
    required _isc.UuidValue attemptId,
    required _isc.UuidValue actionDefinitionId,
    required String creatorDisplayName,
    required String actionTitle,
    required String requirementTitle,
    required _iws572ni.ActionRequirementKind requirementKind,
    String? mimeType,
    int? byteLength,
    int? durationSeconds,
    required DateTime capturedAt,
    required DateTime submittedAt,
    required String reviewReasonCode,
    required String reviewSummary,
    String? mediaUrl,
    String? spokenChallengeWord,
    _iimxtm94.PayoutReviewView? payoutReview,
  }) = _EvidenceReviewQueueItemImpl;

  factory EvidenceReviewQueueItem.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EvidenceReviewQueueItem(
      evidenceId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['evidenceId'],
      ),
      attemptId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      actionDefinitionId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['actionDefinitionId'],
      ),
      creatorDisplayName: jsonSerialization['creatorDisplayName'] as String,
      actionTitle: jsonSerialization['actionTitle'] as String,
      requirementTitle: jsonSerialization['requirementTitle'] as String,
      requirementKind: _iws572ni.ActionRequirementKind.fromJson(
        (jsonSerialization['requirementKind'] as String),
      ),
      mimeType: jsonSerialization['mimeType'] as String?,
      byteLength: jsonSerialization['byteLength'] as int?,
      durationSeconds: jsonSerialization['durationSeconds'] as int?,
      capturedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['capturedAt'],
      ),
      submittedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['submittedAt'],
      ),
      reviewReasonCode: jsonSerialization['reviewReasonCode'] as String,
      reviewSummary: jsonSerialization['reviewSummary'] as String,
      mediaUrl: jsonSerialization['mediaUrl'] as String?,
      spokenChallengeWord: jsonSerialization['spokenChallengeWord'] as String?,
      payoutReview: jsonSerialization['payoutReview'] == null
          ? null
          : _iop4qpu5.Protocol().deserialize<_iimxtm94.PayoutReviewView>(
              jsonSerialization['payoutReview'],
            ),
    );
  }

  _isc.UuidValue evidenceId;

  _isc.UuidValue attemptId;

  _isc.UuidValue actionDefinitionId;

  String creatorDisplayName;

  String actionTitle;

  String requirementTitle;

  _iws572ni.ActionRequirementKind requirementKind;

  String? mimeType;

  int? byteLength;

  int? durationSeconds;

  DateTime capturedAt;

  DateTime submittedAt;

  String reviewReasonCode;

  String reviewSummary;

  /// Short-lived private playback link pinned to the immutable version.
  String? mediaUrl;

  /// The word the participant was asked to say, when one was issued.
  String? spokenChallengeWord;

  /// Set when the proof is held because its payout is above the automatic
  /// release threshold, rather than because the proof needs a decision.
  _iimxtm94.PayoutReviewView? payoutReview;

  /// Returns a shallow copy of this [EvidenceReviewQueueItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  EvidenceReviewQueueItem copyWith({
    _isc.UuidValue? evidenceId,
    _isc.UuidValue? attemptId,
    _isc.UuidValue? actionDefinitionId,
    String? creatorDisplayName,
    String? actionTitle,
    String? requirementTitle,
    _iws572ni.ActionRequirementKind? requirementKind,
    String? mimeType,
    int? byteLength,
    int? durationSeconds,
    DateTime? capturedAt,
    DateTime? submittedAt,
    String? reviewReasonCode,
    String? reviewSummary,
    String? mediaUrl,
    String? spokenChallengeWord,
    _iimxtm94.PayoutReviewView? payoutReview =
        const _UndefinedEvidenceReviewQueueItem$payoutReview(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceReviewQueueItem',
      'evidenceId': evidenceId.toJson(),
      'attemptId': attemptId.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      'creatorDisplayName': creatorDisplayName,
      'actionTitle': actionTitle,
      'requirementTitle': requirementTitle,
      'requirementKind': requirementKind.toJson(),
      if (mimeType != null) 'mimeType': mimeType,
      if (byteLength != null) 'byteLength': byteLength,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'capturedAt': capturedAt.toJson(),
      'submittedAt': submittedAt.toJson(),
      'reviewReasonCode': reviewReasonCode,
      'reviewSummary': reviewSummary,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (spokenChallengeWord != null)
        'spokenChallengeWord': spokenChallengeWord,
      if (payoutReview != null) 'payoutReview': payoutReview?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'EvidenceReviewQueueItem',
      'evidenceId': evidenceId.toJson(),
      'attemptId': attemptId.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      'creatorDisplayName': creatorDisplayName,
      'actionTitle': actionTitle,
      'requirementTitle': requirementTitle,
      'requirementKind': requirementKind.toJson(),
      if (mimeType != null) 'mimeType': mimeType,
      if (byteLength != null) 'byteLength': byteLength,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'capturedAt': capturedAt.toJson(),
      'submittedAt': submittedAt.toJson(),
      'reviewReasonCode': reviewReasonCode,
      'reviewSummary': reviewSummary,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (spokenChallengeWord != null)
        'spokenChallengeWord': spokenChallengeWord,
      if (payoutReview != null)
        'payoutReview': payoutReview?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedEvidenceReviewQueueItem$payoutReview
    extends _isc.UndefinedSentinel
    implements _iimxtm94.PayoutReviewView {
  const _UndefinedEvidenceReviewQueueItem$payoutReview();
}

class _EvidenceReviewQueueItemImpl extends EvidenceReviewQueueItem {
  _EvidenceReviewQueueItemImpl({
    required _isc.UuidValue evidenceId,
    required _isc.UuidValue attemptId,
    required _isc.UuidValue actionDefinitionId,
    required String creatorDisplayName,
    required String actionTitle,
    required String requirementTitle,
    required _iws572ni.ActionRequirementKind requirementKind,
    String? mimeType,
    int? byteLength,
    int? durationSeconds,
    required DateTime capturedAt,
    required DateTime submittedAt,
    required String reviewReasonCode,
    required String reviewSummary,
    String? mediaUrl,
    String? spokenChallengeWord,
    _iimxtm94.PayoutReviewView? payoutReview,
  }) : super._(
         evidenceId: evidenceId,
         attemptId: attemptId,
         actionDefinitionId: actionDefinitionId,
         creatorDisplayName: creatorDisplayName,
         actionTitle: actionTitle,
         requirementTitle: requirementTitle,
         requirementKind: requirementKind,
         mimeType: mimeType,
         byteLength: byteLength,
         durationSeconds: durationSeconds,
         capturedAt: capturedAt,
         submittedAt: submittedAt,
         reviewReasonCode: reviewReasonCode,
         reviewSummary: reviewSummary,
         mediaUrl: mediaUrl,
         spokenChallengeWord: spokenChallengeWord,
         payoutReview: payoutReview,
       );

  /// Returns a shallow copy of this [EvidenceReviewQueueItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  EvidenceReviewQueueItem copyWith({
    _isc.UuidValue? evidenceId,
    _isc.UuidValue? attemptId,
    _isc.UuidValue? actionDefinitionId,
    String? creatorDisplayName,
    String? actionTitle,
    String? requirementTitle,
    _iws572ni.ActionRequirementKind? requirementKind,
    Object? mimeType = _Undefined,
    Object? byteLength = _Undefined,
    Object? durationSeconds = _Undefined,
    DateTime? capturedAt,
    DateTime? submittedAt,
    String? reviewReasonCode,
    String? reviewSummary,
    Object? mediaUrl = _Undefined,
    Object? spokenChallengeWord = _Undefined,
    _iimxtm94.PayoutReviewView? payoutReview =
        const _UndefinedEvidenceReviewQueueItem$payoutReview(),
  }) {
    return EvidenceReviewQueueItem(
      evidenceId: evidenceId ?? this.evidenceId,
      attemptId: attemptId ?? this.attemptId,
      actionDefinitionId: actionDefinitionId ?? this.actionDefinitionId,
      creatorDisplayName: creatorDisplayName ?? this.creatorDisplayName,
      actionTitle: actionTitle ?? this.actionTitle,
      requirementTitle: requirementTitle ?? this.requirementTitle,
      requirementKind: requirementKind ?? this.requirementKind,
      mimeType: mimeType is String? ? mimeType : this.mimeType,
      byteLength: byteLength is int? ? byteLength : this.byteLength,
      durationSeconds: durationSeconds is int?
          ? durationSeconds
          : this.durationSeconds,
      capturedAt: capturedAt ?? this.capturedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewReasonCode: reviewReasonCode ?? this.reviewReasonCode,
      reviewSummary: reviewSummary ?? this.reviewSummary,
      mediaUrl: mediaUrl is String? ? mediaUrl : this.mediaUrl,
      spokenChallengeWord: spokenChallengeWord is String?
          ? spokenChallengeWord
          : this.spokenChallengeWord,
      payoutReview: payoutReview is _isc.UndefinedSentinel
          ? this.payoutReview?.copyWith()
          : payoutReview,
    );
  }
}
