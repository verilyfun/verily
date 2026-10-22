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

enum ActionAuthoringProblem implements _isc.SerializableModel {
  /// This creator already uses the action key for another action.
  actionKeyTaken,

  /// An external requirement names a revoked App or another creator's App.
  appUnavailable,

  /// App confirmations cannot be combined with phone-verified proof in v1.
  externalProofMixed,

  /// A rewarded action must be saved as a draft and funded before it goes live.
  rewardNeedsDraft,

  /// The reward's escrow is not funded and verified yet.
  rewardNotFunded,

  /// Reward terms cannot change once funding has started.
  rewardTermsLocked,

  /// The action or one of its proofs breaks an authoring rule, such as a
  /// missing title, an out-of-range radius, or a duplicate requirement key.
  invalidRequest,

  /// Some text is refused at the model boundary (ModelInputSecurity).
  unsafeText;

  static ActionAuthoringProblem fromJson(String name) {
    switch (name) {
      case 'actionKeyTaken':
        return ActionAuthoringProblem.actionKeyTaken;
      case 'appUnavailable':
        return ActionAuthoringProblem.appUnavailable;
      case 'externalProofMixed':
        return ActionAuthoringProblem.externalProofMixed;
      case 'rewardNeedsDraft':
        return ActionAuthoringProblem.rewardNeedsDraft;
      case 'rewardNotFunded':
        return ActionAuthoringProblem.rewardNotFunded;
      case 'rewardTermsLocked':
        return ActionAuthoringProblem.rewardTermsLocked;
      case 'invalidRequest':
        return ActionAuthoringProblem.invalidRequest;
      case 'unsafeText':
        return ActionAuthoringProblem.unsafeText;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ActionAuthoringProblem"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
