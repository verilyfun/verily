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

abstract class ModerationCaseStatusView
    implements _is.SerializableModel, _is.ProtocolSerialization {
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
    required _is.UuidValue caseId,
    required _is.UuidValue actionDefinitionId,
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
      caseId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['caseId']),
      actionDefinitionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['actionDefinitionId'],
      ),
      category: jsonSerialization['category'] as String,
      status: jsonSerialization['status'] as String,
      pauseActive: _is.BoolJsonExtension.fromJson(
        jsonSerialization['pauseActive'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      canAppeal: _is.BoolJsonExtension.fromJson(jsonSerialization['canAppeal']),
    );
  }

  _is.UuidValue caseId;

  _is.UuidValue actionDefinitionId;

  String category;

  String status;

  bool pauseActive;

  DateTime createdAt;

  bool canAppeal;

  /// Returns a shallow copy of this [ModerationCaseStatusView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ModerationCaseStatusView copyWith({
    _is.UuidValue? caseId,
    _is.UuidValue? actionDefinitionId,
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
    return _is.SerializationManager.encode(this);
  }
}

class _ModerationCaseStatusViewImpl extends ModerationCaseStatusView {
  _ModerationCaseStatusViewImpl({
    required _is.UuidValue caseId,
    required _is.UuidValue actionDefinitionId,
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
  @_is.useResult
  @override
  ModerationCaseStatusView copyWith({
    _is.UuidValue? caseId,
    _is.UuidValue? actionDefinitionId,
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
