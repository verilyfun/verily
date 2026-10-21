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

/// collectingEvidence: proof still missing. verifying: every required proof
/// arrived and automated verification is still running; the worker completes
/// the attempt without the participant coming back. pendingReview: a person
/// decides. verified, rejected, capacityReached: final.
enum ActionAttemptStatus implements _isc.SerializableModel {
  collectingEvidence,
  verifying,
  pendingReview,
  verified,
  rejected,
  capacityReached;

  static ActionAttemptStatus fromJson(String name) {
    switch (name) {
      case 'collectingEvidence':
        return ActionAttemptStatus.collectingEvidence;
      case 'verifying':
        return ActionAttemptStatus.verifying;
      case 'pendingReview':
        return ActionAttemptStatus.pendingReview;
      case 'verified':
        return ActionAttemptStatus.verified;
      case 'rejected':
        return ActionAttemptStatus.rejected;
      case 'capacityReached':
        return ActionAttemptStatus.capacityReached;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ActionAttemptStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
