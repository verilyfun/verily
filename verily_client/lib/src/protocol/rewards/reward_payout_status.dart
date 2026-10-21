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

/// reserved: queued for release. awaitingWallet: the winner has not linked a
/// payout wallet yet. heldForReview: a person must look before release.
/// releasing: a release is in flight to the frozen recipient wallet.
/// released: paid on chain. failed: release stopped and needs an operator.
/// expired: the refund window closed before the payout could be released.
enum RewardPayoutStatus implements _isc.SerializableModel {
  reserved,
  awaitingWallet,
  heldForReview,
  releasing,
  released,
  failed,
  expired;

  static RewardPayoutStatus fromJson(String name) {
    switch (name) {
      case 'reserved':
        return RewardPayoutStatus.reserved;
      case 'awaitingWallet':
        return RewardPayoutStatus.awaitingWallet;
      case 'heldForReview':
        return RewardPayoutStatus.heldForReview;
      case 'releasing':
        return RewardPayoutStatus.releasing;
      case 'released':
        return RewardPayoutStatus.released;
      case 'failed':
        return RewardPayoutStatus.failed;
      case 'expired':
        return RewardPayoutStatus.expired;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "RewardPayoutStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
