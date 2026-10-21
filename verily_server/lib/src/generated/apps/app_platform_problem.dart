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

/// Stable, product-safe reasons an App platform call was refused.
enum AppPlatformProblem implements _is.SerializableModel {
  invalidWebhookUrl,
  webhooksUnavailable,
  invalidRedirectUri,
  tooManyRedirectUris,
  linkRequestInvalid,
  linkCodeInvalid,
  pullVerificationUnavailable,
  invalidReference,
  verificationRequestNotFound,
  verificationRequestExpired,
  verificationRequestTaken,
  verificationRequestClosed,

  /// The person has not sent the proof the request asks for yet.
  verificationRequestProofMissing,
  rateLimited;

  static AppPlatformProblem fromJson(String name) {
    switch (name) {
      case 'invalidWebhookUrl':
        return AppPlatformProblem.invalidWebhookUrl;
      case 'webhooksUnavailable':
        return AppPlatformProblem.webhooksUnavailable;
      case 'invalidRedirectUri':
        return AppPlatformProblem.invalidRedirectUri;
      case 'tooManyRedirectUris':
        return AppPlatformProblem.tooManyRedirectUris;
      case 'linkRequestInvalid':
        return AppPlatformProblem.linkRequestInvalid;
      case 'linkCodeInvalid':
        return AppPlatformProblem.linkCodeInvalid;
      case 'pullVerificationUnavailable':
        return AppPlatformProblem.pullVerificationUnavailable;
      case 'invalidReference':
        return AppPlatformProblem.invalidReference;
      case 'verificationRequestNotFound':
        return AppPlatformProblem.verificationRequestNotFound;
      case 'verificationRequestExpired':
        return AppPlatformProblem.verificationRequestExpired;
      case 'verificationRequestTaken':
        return AppPlatformProblem.verificationRequestTaken;
      case 'verificationRequestClosed':
        return AppPlatformProblem.verificationRequestClosed;
      case 'verificationRequestProofMissing':
        return AppPlatformProblem.verificationRequestProofMissing;
      case 'rateLimited':
        return AppPlatformProblem.rateLimited;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "AppPlatformProblem"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
