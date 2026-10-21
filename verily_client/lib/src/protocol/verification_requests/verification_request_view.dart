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

import '../action_verification/action_opportunity.dart' as _iwflznil;
import '../verification_requests/verification_request_check.dart' as _imw473lb;
import '../verification_requests/verification_request_kind.dart' as _ix1e7zpf;
import '../verification_requests/verification_request_status.dart' as _icvl19bi;

/// What the Verily app shows before a person accepts a verification request:
/// who is asking, for what, and exactly what will be shared.
abstract class VerificationRequestView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  VerificationRequestView._({
    required this.id,
    required this.appId,
    required this.appName,
    this.appWebsiteUrl,
    required this.kind,
    this.instructions,
    required this.check,
    required this.checksPlace,
    required this.spokenChallenge,
    required this.shareEvidence,
    required this.status,
    bool? declinedByViewer,
    required this.expiresAt,
    this.action,
  }) : declinedByViewer = declinedByViewer ?? false;

  factory VerificationRequestView({
    required _isc.UuidValue id,
    required _isc.UuidValue appId,
    required String appName,
    String? appWebsiteUrl,
    required _ix1e7zpf.VerificationRequestKind kind,
    String? instructions,
    required _imw473lb.VerificationRequestCheck check,
    required bool checksPlace,
    required bool spokenChallenge,
    required bool shareEvidence,
    required _icvl19bi.VerificationRequestStatus status,
    bool? declinedByViewer,
    required DateTime expiresAt,
    _iwflznil.ActionOpportunity? action,
  }) = _VerificationRequestViewImpl;

  factory VerificationRequestView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return VerificationRequestView(
      id: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      appId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      appName: jsonSerialization['appName'] as String,
      appWebsiteUrl: jsonSerialization['appWebsiteUrl'] as String?,
      kind: _ix1e7zpf.VerificationRequestKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      instructions: jsonSerialization['instructions'] as String?,
      check: _imw473lb.VerificationRequestCheck.fromJson(
        (jsonSerialization['check'] as String),
      ),
      checksPlace: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['checksPlace'],
      ),
      spokenChallenge: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['spokenChallenge'],
      ),
      shareEvidence: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['shareEvidence'],
      ),
      status: _icvl19bi.VerificationRequestStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      declinedByViewer: jsonSerialization['declinedByViewer'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['declinedByViewer'],
            ),
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      action: jsonSerialization['action'] == null
          ? null
          : _iop4qpu5.Protocol().deserialize<_iwflznil.ActionOpportunity>(
              jsonSerialization['action'],
            ),
    );
  }

  _isc.UuidValue id;

  _isc.UuidValue appId;

  String appName;

  String? appWebsiteUrl;

  _ix1e7zpf.VerificationRequestKind kind;

  String? instructions;

  _imw473lb.VerificationRequestCheck check;

  /// Whether the receipt will say inside or outside the App's place. The
  /// place itself is never shown to the App or in the receipt.
  bool checksPlace;

  bool spokenChallenge;

  /// Whether the App asks to download the capture.
  bool shareEvidence;

  _icvl19bi.VerificationRequestStatus status;

  /// Whether the signed-in person is the one who declined it. Anyone else
  /// sees a declined request as answered by someone else.
  bool declinedByViewer;

  DateTime expiresAt;

  /// The private action to capture against, once accepted by this account.
  _iwflznil.ActionOpportunity? action;

  /// Returns a shallow copy of this [VerificationRequestView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  VerificationRequestView copyWith({
    _isc.UuidValue? id,
    _isc.UuidValue? appId,
    String? appName,
    String? appWebsiteUrl,
    _ix1e7zpf.VerificationRequestKind? kind,
    String? instructions,
    _imw473lb.VerificationRequestCheck? check,
    bool? checksPlace,
    bool? spokenChallenge,
    bool? shareEvidence,
    _icvl19bi.VerificationRequestStatus? status,
    bool? declinedByViewer,
    DateTime? expiresAt,
    _iwflznil.ActionOpportunity? action,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerificationRequestView',
      'id': id.toJson(),
      'appId': appId.toJson(),
      'appName': appName,
      if (appWebsiteUrl != null) 'appWebsiteUrl': appWebsiteUrl,
      'kind': kind.toJson(),
      if (instructions != null) 'instructions': instructions,
      'check': check.toJson(),
      'checksPlace': checksPlace,
      'spokenChallenge': spokenChallenge,
      'shareEvidence': shareEvidence,
      'status': status.toJson(),
      'declinedByViewer': declinedByViewer,
      'expiresAt': expiresAt.toJson(),
      if (action != null) 'action': action?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerificationRequestView',
      'id': id.toJson(),
      'appId': appId.toJson(),
      'appName': appName,
      if (appWebsiteUrl != null) 'appWebsiteUrl': appWebsiteUrl,
      'kind': kind.toJson(),
      if (instructions != null) 'instructions': instructions,
      'check': check.toJson(),
      'checksPlace': checksPlace,
      'spokenChallenge': spokenChallenge,
      'shareEvidence': shareEvidence,
      'status': status.toJson(),
      'declinedByViewer': declinedByViewer,
      'expiresAt': expiresAt.toJson(),
      if (action != null) 'action': action?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VerificationRequestViewImpl extends VerificationRequestView {
  _VerificationRequestViewImpl({
    required _isc.UuidValue id,
    required _isc.UuidValue appId,
    required String appName,
    String? appWebsiteUrl,
    required _ix1e7zpf.VerificationRequestKind kind,
    String? instructions,
    required _imw473lb.VerificationRequestCheck check,
    required bool checksPlace,
    required bool spokenChallenge,
    required bool shareEvidence,
    required _icvl19bi.VerificationRequestStatus status,
    bool? declinedByViewer,
    required DateTime expiresAt,
    _iwflznil.ActionOpportunity? action,
  }) : super._(
         id: id,
         appId: appId,
         appName: appName,
         appWebsiteUrl: appWebsiteUrl,
         kind: kind,
         instructions: instructions,
         check: check,
         checksPlace: checksPlace,
         spokenChallenge: spokenChallenge,
         shareEvidence: shareEvidence,
         status: status,
         declinedByViewer: declinedByViewer,
         expiresAt: expiresAt,
         action: action,
       );

  /// Returns a shallow copy of this [VerificationRequestView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  VerificationRequestView copyWith({
    _isc.UuidValue? id,
    _isc.UuidValue? appId,
    String? appName,
    Object? appWebsiteUrl = _Undefined,
    _ix1e7zpf.VerificationRequestKind? kind,
    Object? instructions = _Undefined,
    _imw473lb.VerificationRequestCheck? check,
    bool? checksPlace,
    bool? spokenChallenge,
    bool? shareEvidence,
    _icvl19bi.VerificationRequestStatus? status,
    bool? declinedByViewer,
    DateTime? expiresAt,
    Object? action = _Undefined,
  }) {
    return VerificationRequestView(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      appName: appName ?? this.appName,
      appWebsiteUrl: appWebsiteUrl is String?
          ? appWebsiteUrl
          : this.appWebsiteUrl,
      kind: kind ?? this.kind,
      instructions: instructions is String? ? instructions : this.instructions,
      check: check ?? this.check,
      checksPlace: checksPlace ?? this.checksPlace,
      spokenChallenge: spokenChallenge ?? this.spokenChallenge,
      shareEvidence: shareEvidence ?? this.shareEvidence,
      status: status ?? this.status,
      declinedByViewer: declinedByViewer ?? this.declinedByViewer,
      expiresAt: expiresAt ?? this.expiresAt,
      action: action is _iwflznil.ActionOpportunity?
          ? action
          : this.action?.copyWith(),
    );
  }
}
