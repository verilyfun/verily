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

import '../action_verification/create_action_definition_request.dart'
    as _i74ezup0;

/// An AI-assisted draft. It never carries a reward: money terms are set by
/// the creator, not proposed by a model.
abstract class ActionDraftProposal
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ActionDraftProposal._({
    required this.action,
    required this.safetyNotes,
    required this.assumptions,
  });

  factory ActionDraftProposal({
    required _i74ezup0.CreateActionDefinitionRequest action,
    required List<String> safetyNotes,
    required List<String> assumptions,
  }) = _ActionDraftProposalImpl;

  factory ActionDraftProposal.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionDraftProposal(
      action: _itf691yl.Protocol()
          .deserialize<_i74ezup0.CreateActionDefinitionRequest>(
            jsonSerialization['action'],
          ),
      safetyNotes: _itf691yl.Protocol().deserialize<List<String>>(
        jsonSerialization['safetyNotes'],
      ),
      assumptions: _itf691yl.Protocol().deserialize<List<String>>(
        jsonSerialization['assumptions'],
      ),
    );
  }

  _i74ezup0.CreateActionDefinitionRequest action;

  List<String> safetyNotes;

  List<String> assumptions;

  /// Returns a shallow copy of this [ActionDraftProposal]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionDraftProposal copyWith({
    _i74ezup0.CreateActionDefinitionRequest? action,
    List<String>? safetyNotes,
    List<String>? assumptions,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionDraftProposal',
      'action': action.toJson(),
      'safetyNotes': safetyNotes.toJson(),
      'assumptions': assumptions.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionDraftProposal',
      'action': action.toJsonForProtocol(),
      'safetyNotes': safetyNotes.toJson(),
      'assumptions': assumptions.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ActionDraftProposalImpl extends ActionDraftProposal {
  _ActionDraftProposalImpl({
    required _i74ezup0.CreateActionDefinitionRequest action,
    required List<String> safetyNotes,
    required List<String> assumptions,
  }) : super._(
         action: action,
         safetyNotes: safetyNotes,
         assumptions: assumptions,
       );

  /// Returns a shallow copy of this [ActionDraftProposal]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionDraftProposal copyWith({
    _i74ezup0.CreateActionDefinitionRequest? action,
    List<String>? safetyNotes,
    List<String>? assumptions,
  }) {
    return ActionDraftProposal(
      action: action ?? this.action.copyWith(),
      safetyNotes: safetyNotes ?? this.safetyNotes.map((e0) => e0).toList(),
      assumptions: assumptions ?? this.assumptions.map((e0) => e0).toList(),
    );
  }
}
