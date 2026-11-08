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

/// Where the Verily app sends the person after they approve or decline.
abstract class AppLinkRedirect
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AppLinkRedirect._({
    required this.redirectUrl,
    this.codeExpiresAt,
  });

  factory AppLinkRedirect({
    required String redirectUrl,
    DateTime? codeExpiresAt,
  }) = _AppLinkRedirectImpl;

  factory AppLinkRedirect.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppLinkRedirect(
      redirectUrl: jsonSerialization['redirectUrl'] as String,
      codeExpiresAt: jsonSerialization['codeExpiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['codeExpiresAt'],
            ),
    );
  }

  String redirectUrl;

  /// When the one-time code in the URL stops working; null after a decline.
  DateTime? codeExpiresAt;

  /// Returns a shallow copy of this [AppLinkRedirect]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppLinkRedirect copyWith({
    String? redirectUrl,
    DateTime? codeExpiresAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppLinkRedirect',
      'redirectUrl': redirectUrl,
      if (codeExpiresAt != null) 'codeExpiresAt': codeExpiresAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppLinkRedirect',
      'redirectUrl': redirectUrl,
      if (codeExpiresAt != null) 'codeExpiresAt': codeExpiresAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _AppLinkRedirectImpl extends AppLinkRedirect {
  _AppLinkRedirectImpl({
    required String redirectUrl,
    DateTime? codeExpiresAt,
  }) : super._(
         redirectUrl: redirectUrl,
         codeExpiresAt: codeExpiresAt,
       );

  /// Returns a shallow copy of this [AppLinkRedirect]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppLinkRedirect copyWith({
    String? redirectUrl,
    DateTime? codeExpiresAt = const _is.$UndefinedDateTime(),
  }) {
    return AppLinkRedirect(
      redirectUrl: redirectUrl ?? this.redirectUrl,
      codeExpiresAt: codeExpiresAt is _is.UndefinedSentinel
          ? this.codeExpiresAt
          : codeExpiresAt,
    );
  }
}
