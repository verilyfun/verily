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

/// Where the Verily app returns the person: the App's exact redirect URI with
/// `request_id`, `state`, and either `code` or `status=declined`.
abstract class VerificationRequestRedirect
    implements _is.SerializableModel, _is.ProtocolSerialization {
  VerificationRequestRedirect._({
    required this.redirectUrl,
    this.codeExpiresAt,
  });

  factory VerificationRequestRedirect({
    required String redirectUrl,
    DateTime? codeExpiresAt,
  }) = _VerificationRequestRedirectImpl;

  factory VerificationRequestRedirect.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return VerificationRequestRedirect(
      redirectUrl: jsonSerialization['redirectUrl'] as String,
      codeExpiresAt: jsonSerialization['codeExpiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['codeExpiresAt'],
            ),
    );
  }

  String redirectUrl;

  DateTime? codeExpiresAt;

  /// Returns a shallow copy of this [VerificationRequestRedirect]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerificationRequestRedirect copyWith({
    String? redirectUrl,
    DateTime? codeExpiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerificationRequestRedirect',
      'redirectUrl': redirectUrl,
      if (codeExpiresAt != null) 'codeExpiresAt': codeExpiresAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerificationRequestRedirect',
      'redirectUrl': redirectUrl,
      if (codeExpiresAt != null) 'codeExpiresAt': codeExpiresAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VerificationRequestRedirectImpl extends VerificationRequestRedirect {
  _VerificationRequestRedirectImpl({
    required String redirectUrl,
    DateTime? codeExpiresAt,
  }) : super._(
         redirectUrl: redirectUrl,
         codeExpiresAt: codeExpiresAt,
       );

  /// Returns a shallow copy of this [VerificationRequestRedirect]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerificationRequestRedirect copyWith({
    String? redirectUrl,
    Object? codeExpiresAt = _Undefined,
  }) {
    return VerificationRequestRedirect(
      redirectUrl: redirectUrl ?? this.redirectUrl,
      codeExpiresAt: codeExpiresAt is DateTime?
          ? codeExpiresAt
          : this.codeExpiresAt,
    );
  }
}
