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
import '../action_verification/evidence_decision_status.dart' as _ir3rpfcs;
import '../action_verification/evidence_provenance_level.dart' as _ijbfcz4y;

abstract class EvidenceSubmissionResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  EvidenceSubmissionResult._({
    required this.attempt,
    required this.requirementId,
    this.status,
    this.confidence,
    required this.reasonCode,
    required this.summary,
    _ijbfcz4y.EvidenceProvenanceLevel? provenanceLevel,
  }) : provenanceLevel =
           provenanceLevel ?? _ijbfcz4y.EvidenceProvenanceLevel.basic;

  factory EvidenceSubmissionResult({
    required _ia5uqadz.ActionAttemptView attempt,
    required _is.UuidValue requirementId,
    _ir3rpfcs.EvidenceDecisionStatus? status,
    double? confidence,
    required String reasonCode,
    required String summary,
    _ijbfcz4y.EvidenceProvenanceLevel? provenanceLevel,
  }) = _EvidenceSubmissionResultImpl;

  factory EvidenceSubmissionResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EvidenceSubmissionResult(
      attempt: _itf691yl.Protocol().deserialize<_ia5uqadz.ActionAttemptView>(
        jsonSerialization['attempt'],
      ),
      requirementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      status: jsonSerialization['status'] == null
          ? null
          : _ir3rpfcs.EvidenceDecisionStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      confidence: (jsonSerialization['confidence'] as num?)?.toDouble(),
      reasonCode: jsonSerialization['reasonCode'] as String,
      summary: jsonSerialization['summary'] as String,
      provenanceLevel: jsonSerialization['provenanceLevel'] == null
          ? null
          : _ijbfcz4y.EvidenceProvenanceLevel.fromJson(
              (jsonSerialization['provenanceLevel'] as String),
            ),
    );
  }

  _ia5uqadz.ActionAttemptView attempt;

  _is.UuidValue requirementId;

  /// The verdict so far; null while uploaded media waits for automated
  /// verification, which completes the attempt on its own.
  _ir3rpfcs.EvidenceDecisionStatus? status;

  double? confidence;

  String reasonCode;

  String summary;

  _ijbfcz4y.EvidenceProvenanceLevel provenanceLevel;

  /// Returns a shallow copy of this [EvidenceSubmissionResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  EvidenceSubmissionResult copyWith({
    _ia5uqadz.ActionAttemptView? attempt,
    _is.UuidValue? requirementId,
    _ir3rpfcs.EvidenceDecisionStatus? status,
    double? confidence,
    String? reasonCode,
    String? summary,
    _ijbfcz4y.EvidenceProvenanceLevel? provenanceLevel,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceSubmissionResult',
      'attempt': attempt.toJson(),
      'requirementId': requirementId.toJson(),
      if (status != null) 'status': status?.toJson(),
      if (confidence != null) 'confidence': confidence,
      'reasonCode': reasonCode,
      'summary': summary,
      'provenanceLevel': provenanceLevel.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'EvidenceSubmissionResult',
      'attempt': attempt.toJsonForProtocol(),
      'requirementId': requirementId.toJson(),
      if (status != null) 'status': status?.toJson(),
      if (confidence != null) 'confidence': confidence,
      'reasonCode': reasonCode,
      'summary': summary,
      'provenanceLevel': provenanceLevel.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EvidenceSubmissionResultImpl extends EvidenceSubmissionResult {
  _EvidenceSubmissionResultImpl({
    required _ia5uqadz.ActionAttemptView attempt,
    required _is.UuidValue requirementId,
    _ir3rpfcs.EvidenceDecisionStatus? status,
    double? confidence,
    required String reasonCode,
    required String summary,
    _ijbfcz4y.EvidenceProvenanceLevel? provenanceLevel,
  }) : super._(
         attempt: attempt,
         requirementId: requirementId,
         status: status,
         confidence: confidence,
         reasonCode: reasonCode,
         summary: summary,
         provenanceLevel: provenanceLevel,
       );

  /// Returns a shallow copy of this [EvidenceSubmissionResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  EvidenceSubmissionResult copyWith({
    _ia5uqadz.ActionAttemptView? attempt,
    _is.UuidValue? requirementId,
    Object? status = _Undefined,
    Object? confidence = _Undefined,
    String? reasonCode,
    String? summary,
    _ijbfcz4y.EvidenceProvenanceLevel? provenanceLevel,
  }) {
    return EvidenceSubmissionResult(
      attempt: attempt ?? this.attempt.copyWith(),
      requirementId: requirementId ?? this.requirementId,
      status: status is _ir3rpfcs.EvidenceDecisionStatus?
          ? status
          : this.status,
      confidence: confidence is double? ? confidence : this.confidence,
      reasonCode: reasonCode ?? this.reasonCode,
      summary: summary ?? this.summary,
      provenanceLevel: provenanceLevel ?? this.provenanceLevel,
    );
  }
}
