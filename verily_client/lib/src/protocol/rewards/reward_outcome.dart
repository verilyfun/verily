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

/// What a verified completion earned from the action's reward pool.
enum RewardOutcome implements _isc.SerializableModel {
  /// A payout index was reserved for this completion.
  won,

  /// Every payout in the pool is already reserved.
  poolEmpty,

  /// This account already holds the most payouts the pool allows one account.
  accountLimitReached,

  /// The pool expired or was ended before this completion.
  poolEnded;

  static RewardOutcome fromJson(String name) {
    switch (name) {
      case 'won':
        return RewardOutcome.won;
      case 'poolEmpty':
        return RewardOutcome.poolEmpty;
      case 'accountLimitReached':
        return RewardOutcome.accountLimitReached;
      case 'poolEnded':
        return RewardOutcome.poolEnded;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "RewardOutcome"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
