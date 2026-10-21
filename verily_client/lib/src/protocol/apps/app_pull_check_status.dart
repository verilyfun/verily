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

enum AppPullCheckStatus implements _isc.SerializableModel {
  /// A verification call is due or running.
  calling,

  /// The App answered `pending`; a push confirmation for this attempt settles it.
  waiting,

  /// The last call failed; another is scheduled with backoff.
  retrying,
  accepted,
  rejected,

  /// Calls ran out or the App cannot be reached.
  failed,

  /// No answer within 24 hours.
  expired;

  static AppPullCheckStatus fromJson(String name) {
    switch (name) {
      case 'calling':
        return AppPullCheckStatus.calling;
      case 'waiting':
        return AppPullCheckStatus.waiting;
      case 'retrying':
        return AppPullCheckStatus.retrying;
      case 'accepted':
        return AppPullCheckStatus.accepted;
      case 'rejected':
        return AppPullCheckStatus.rejected;
      case 'failed':
        return AppPullCheckStatus.failed;
      case 'expired':
        return AppPullCheckStatus.expired;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "AppPullCheckStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
