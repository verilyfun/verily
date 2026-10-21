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

/// The strongest capture provenance the server verified for one proof.
enum EvidenceProvenanceLevel implements _isc.SerializableModel {
  /// Bound to a fresh capture challenge only.
  basic,

  /// Play Integrity vouched for the app and device.
  appAttested,

  /// A device key signed the capture, but its attestation was not trusted
  /// (only when VERILY_CAPTURE_SIGNATURE_MODE is optional).
  deviceSigned,

  /// A fresh key, attested by Google's chain to live in the TEE or StrongBox
  /// of a locked, verified device running Verily's signed app, and created
  /// for this capture's challenge, signed the capture.
  hardwareAttested;

  static EvidenceProvenanceLevel fromJson(String name) {
    switch (name) {
      case 'basic':
        return EvidenceProvenanceLevel.basic;
      case 'appAttested':
        return EvidenceProvenanceLevel.appAttested;
      case 'deviceSigned':
        return EvidenceProvenanceLevel.deviceSigned;
      case 'hardwareAttested':
        return EvidenceProvenanceLevel.hardwareAttested;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "EvidenceProvenanceLevel"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
