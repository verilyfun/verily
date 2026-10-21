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

abstract class ActionTemplate
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ActionTemplate._({
    required this.templateKey,
    required this.title,
    required this.description,
    required this.suggestedRecurrence,
    required this.requirements,
  });

  factory ActionTemplate({
    required String templateKey,
    required String title,
    required String description,
    required _ivhzgwse.ActionRecurrence suggestedRecurrence,
    required List<_igizvm0h.ActionRequirementDraft> requirements,
  }) = _ActionTemplateImpl;

  factory ActionTemplate.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionTemplate(
      templateKey: jsonSerialization['templateKey'] as String,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String,
      suggestedRecurrence: _ivhzgwse.ActionRecurrence.fromJson(
        (jsonSerialization['suggestedRecurrence'] as String),
      ),
      requirements: _itf691yl.Protocol()
          .deserialize<List<_igizvm0h.ActionRequirementDraft>>(
            jsonSerialization['requirements'],
          ),
    );
  }

  String templateKey;

  String title;

  String description;

  _ivhzgwse.ActionRecurrence suggestedRecurrence;

  List<_igizvm0h.ActionRequirementDraft> requirements;

  /// Returns a shallow copy of this [ActionTemplate]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionTemplate copyWith({
    String? templateKey,
    String? title,
    String? description,
    _ivhzgwse.ActionRecurrence? suggestedRecurrence,
    List<_igizvm0h.ActionRequirementDraft>? requirements,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionTemplate',
      'templateKey': templateKey,
      'title': title,
      'description': description,
      'suggestedRecurrence': suggestedRecurrence.toJson(),
      'requirements': requirements.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionTemplate',
      'templateKey': templateKey,
      'title': title,
      'description': description,
      'suggestedRecurrence': suggestedRecurrence.toJson(),
      'requirements': requirements.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ActionTemplateImpl extends ActionTemplate {
  _ActionTemplateImpl({
    required String templateKey,
    required String title,
    required String description,
    required _ivhzgwse.ActionRecurrence suggestedRecurrence,
    required List<_igizvm0h.ActionRequirementDraft> requirements,
  }) : super._(
         templateKey: templateKey,
         title: title,
         description: description,
         suggestedRecurrence: suggestedRecurrence,
         requirements: requirements,
       );

  /// Returns a shallow copy of this [ActionTemplate]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionTemplate copyWith({
    String? templateKey,
    String? title,
    String? description,
    _ivhzgwse.ActionRecurrence? suggestedRecurrence,
    List<_igizvm0h.ActionRequirementDraft>? requirements,
  }) {
    return ActionTemplate(
      templateKey: templateKey ?? this.templateKey,
      title: title ?? this.title,
      description: description ?? this.description,
      suggestedRecurrence: suggestedRecurrence ?? this.suggestedRecurrence,
      requirements:
          requirements ?? this.requirements.map((e0) => e0.copyWith()).toList(),
    );
  }
}
