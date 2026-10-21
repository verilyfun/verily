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

/// draft: terms editable. awaitingFunding: terms frozen, escrow address
/// derived, creator signing. funded: escrow verified on chain, action may
/// publish. ended: no new payouts reserved; reserved ones still release until
/// the refund window. closed: the refund window has passed.
enum RewardPoolStatus implements _is.SerializableModel {
  draft,
  awaitingFunding,
  funded,
  ended,
  closed;

  static RewardPoolStatus fromJson(String name) {
    switch (name) {
      case 'draft':
        return RewardPoolStatus.draft;
      case 'awaitingFunding':
        return RewardPoolStatus.awaitingFunding;
      case 'funded':
        return RewardPoolStatus.funded;
      case 'ended':
        return RewardPoolStatus.ended;
      case 'closed':
        return RewardPoolStatus.closed;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "RewardPoolStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
