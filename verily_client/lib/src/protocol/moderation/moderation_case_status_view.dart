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

abstract class ModerationCaseStatusView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ModerationCaseStatusView._({
    required this.caseId,
    required this.actionDefinitionId,
    required this.category,
    required this.status,
    required this.pauseActive,
    required this.createdAt,
    required this.canAppeal,
  });

  factory ModerationCaseStatusView({
    required _isc.UuidValue caseId,
    required _isc.UuidValue actionDefinitionId,
    required String category,
    required String status,
    required bool pauseActive,
    required DateTime createdAt,
    required bool canAppeal,
  }) = _ModerationCaseStatusViewImpl;

  factory ModerationCaseStatusView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ModerationCaseStatusView(
      caseId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['caseId']),
      actionDefinitionId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['actionDefinitionId'],
      ),
      category: jsonSerialization['category'] as String,
      status: jsonSerialization['status'] as String,
      pauseActive: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['pauseActive'],
      ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      canAppeal: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canAppeal'],
      ),
    );
  }

  _isc.UuidValue caseId;

  _isc.UuidValue actionDefinitionId;

  String category;

  String status;

  bool pauseActive;

  DateTime createdAt;

  bool canAppeal;

  /// Returns a shallow copy of this [ModerationCaseStatusView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ModerationCaseStatusView copyWith({
    _isc.UuidValue? caseId,
    _isc.UuidValue? actionDefinitionId,
    String? category,
    String? status,
    bool? pauseActive,
    DateTime? createdAt,
    bool? canAppeal,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ModerationCaseStatusView',
      'caseId': caseId.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      'category': category,
      'status': status,
      'pauseActive': pauseActive,
      'createdAt': createdAt.toJson(),
      'canAppeal': canAppeal,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ModerationCaseStatusView',
      'caseId': caseId.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      'category': category,
      'status': status,
      'pauseActive': pauseActive,
      'createdAt': createdAt.toJson(),
      'canAppeal': canAppeal,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ModerationCaseStatusViewImpl extends ModerationCaseStatusView {
  _ModerationCaseStatusViewImpl({
    required _isc.UuidValue caseId,
    required _isc.UuidValue actionDefinitionId,
    required String category,
    required String status,
    required bool pauseActive,
    required DateTime createdAt,
    required bool canAppeal,
  }) : super._(
         caseId: caseId,
         actionDefinitionId: actionDefinitionId,
         category: category,
         status: status,
         pauseActive: pauseActive,
         createdAt: createdAt,
         canAppeal: canAppeal,
       );

  /// Returns a shallow copy of this [ModerationCaseStatusView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ModerationCaseStatusView copyWith({
    _isc.UuidValue? caseId,
    _isc.UuidValue? actionDefinitionId,
    String? category,
    String? status,
    bool? pauseActive,
    DateTime? createdAt,
    bool? canAppeal,
  }) {
    return ModerationCaseStatusView(
      caseId: caseId ?? this.caseId,
      actionDefinitionId: actionDefinitionId ?? this.actionDefinitionId,
      category: category ?? this.category,
      status: status ?? this.status,
      pauseActive: pauseActive ?? this.pauseActive,
      createdAt: createdAt ?? this.createdAt,
      canAppeal: canAppeal ?? this.canAppeal,
    );
  }
}
