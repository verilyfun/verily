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

enum RewardProblem implements _isc.SerializableModel {
  /// Escrowed rewards are not available on this server.
  rewardsUnavailable,

  /// The action has no reward.
  poolNotFound,

  /// Link a payout wallet first; funding and refunds use it.
  payoutWalletRequired,

  /// Funding is not in a state that allows this step.
  poolNotAwaitingFunding,

  /// The escrow is not on chain yet, or not finalized.
  escrowNotFound,

  /// The escrow on chain does not match the reward terms.
  escrowMismatch,

  /// The pool has already ended.
  poolEnded;

  static RewardProblem fromJson(String name) {
    switch (name) {
      case 'rewardsUnavailable':
        return RewardProblem.rewardsUnavailable;
      case 'poolNotFound':
        return RewardProblem.poolNotFound;
      case 'payoutWalletRequired':
        return RewardProblem.payoutWalletRequired;
      case 'poolNotAwaitingFunding':
        return RewardProblem.poolNotAwaitingFunding;
      case 'escrowNotFound':
        return RewardProblem.escrowNotFound;
      case 'escrowMismatch':
        return RewardProblem.escrowMismatch;
      case 'poolEnded':
        return RewardProblem.poolEnded;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "RewardProblem"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
