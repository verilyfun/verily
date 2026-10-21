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

import '../moderation/moderation_audit_view.dart' as _iowanuij;
import '../moderation/moderation_case_status_view.dart' as _iej8j8rg;

abstract class ModerationCaseReviewView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ModerationCaseReviewView._({
    required this.status,
    required this.details,
    this.appealReason,
    required this.audit,
  });

  factory ModerationCaseReviewView({
    required _iej8j8rg.ModerationCaseStatusView status,
    required String details,
    String? appealReason,
    required List<_iowanuij.ModerationAuditView> audit,
  }) = _ModerationCaseReviewViewImpl;

  factory ModerationCaseReviewView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ModerationCaseReviewView(
      status: _itf691yl.Protocol()
          .deserialize<_iej8j8rg.ModerationCaseStatusView>(
            jsonSerialization['status'],
          ),
      details: jsonSerialization['details'] as String,
      appealReason: jsonSerialization['appealReason'] as String?,
      audit: _itf691yl.Protocol()
          .deserialize<List<_iowanuij.ModerationAuditView>>(
            jsonSerialization['audit'],
          ),
    );
  }

  _iej8j8rg.ModerationCaseStatusView status;

  String details;

  String? appealReason;

  List<_iowanuij.ModerationAuditView> audit;

  /// Returns a shallow copy of this [ModerationCaseReviewView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ModerationCaseReviewView copyWith({
    _iej8j8rg.ModerationCaseStatusView? status,
    String? details,
    String? appealReason,
    List<_iowanuij.ModerationAuditView>? audit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ModerationCaseReviewView',
      'status': status.toJson(),
      'details': details,
      if (appealReason != null) 'appealReason': appealReason,
      'audit': audit.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ModerationCaseReviewView',
      'status': status.toJsonForProtocol(),
      'details': details,
      if (appealReason != null) 'appealReason': appealReason,
      'audit': audit.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ModerationCaseReviewViewImpl extends ModerationCaseReviewView {
  _ModerationCaseReviewViewImpl({
    required _iej8j8rg.ModerationCaseStatusView status,
    required String details,
    String? appealReason,
    required List<_iowanuij.ModerationAuditView> audit,
  }) : super._(
         status: status,
         details: details,
         appealReason: appealReason,
         audit: audit,
       );

  /// Returns a shallow copy of this [ModerationCaseReviewView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ModerationCaseReviewView copyWith({
    _iej8j8rg.ModerationCaseStatusView? status,
    String? details,
    Object? appealReason = _Undefined,
    List<_iowanuij.ModerationAuditView>? audit,
  }) {
    return ModerationCaseReviewView(
      status: status ?? this.status.copyWith(),
      details: details ?? this.details,
      appealReason: appealReason is String? ? appealReason : this.appealReason,
      audit: audit ?? this.audit.map((e0) => e0.copyWith()).toList(),
    );
  }
}
