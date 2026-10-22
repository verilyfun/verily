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

/// Why an App Attest registration was refused.
enum AppAttestProblem implements _isc.SerializableModel {
  /// This server does not accept App Attest keys; do not retry.
  unavailable,

  /// Too many registration challenges this hour.
  rateLimited,

  /// The challenge expired, was used, or belongs to someone else; ask for a
  /// new one.
  challengeInvalid,

  /// The attestation did not verify, or the key belongs to another account;
  /// generate a new key before trying again.
  keyRejected;

  static AppAttestProblem fromJson(String name) {
    switch (name) {
      case 'unavailable':
        return AppAttestProblem.unavailable;
      case 'rateLimited':
        return AppAttestProblem.rateLimited;
      case 'challengeInvalid':
        return AppAttestProblem.challengeInvalid;
      case 'keyRejected':
        return AppAttestProblem.keyRejected;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "AppAttestProblem"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
