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

/// Which App Attest service attested a key. Keys from one environment never
/// work in the other.
enum AppAttestEnvironment implements _is.SerializableModel {
  /// Builds from the App Store, TestFlight, or an enterprise program
  /// (`aaguid` is `appattest` and seven zero bytes).
  production,

  /// Apple's sandbox, which development builds use by default
  /// (`aaguid` is `appattestdevelop`).
  development;

  static AppAttestEnvironment fromJson(String name) {
    switch (name) {
      case 'production':
        return AppAttestEnvironment.production;
      case 'development':
        return AppAttestEnvironment.development;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "AppAttestEnvironment"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
