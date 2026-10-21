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

/// What the Verily app shows before a person links their account to an App.
abstract class AppLinkRequestView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AppLinkRequestView._({
    required this.appId,
    required this.appName,
    this.websiteUrl,
    required this.redirectUri,
    required this.alreadyLinked,
  });

  factory AppLinkRequestView({
    required _isc.UuidValue appId,
    required String appName,
    String? websiteUrl,
    required String redirectUri,
    required bool alreadyLinked,
  }) = _AppLinkRequestViewImpl;

  factory AppLinkRequestView.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppLinkRequestView(
      appId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      appName: jsonSerialization['appName'] as String,
      websiteUrl: jsonSerialization['websiteUrl'] as String?,
      redirectUri: jsonSerialization['redirectUri'] as String,
      alreadyLinked: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['alreadyLinked'],
      ),
    );
  }

  _isc.UuidValue appId;

  String appName;

  String? websiteUrl;

  String redirectUri;

  /// Whether this account is already linked to the App.
  bool alreadyLinked;

  /// Returns a shallow copy of this [AppLinkRequestView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AppLinkRequestView copyWith({
    _isc.UuidValue? appId,
    String? appName,
    String? websiteUrl,
    String? redirectUri,
    bool? alreadyLinked,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppLinkRequestView',
      'appId': appId.toJson(),
      'appName': appName,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
      'redirectUri': redirectUri,
      'alreadyLinked': alreadyLinked,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppLinkRequestView',
      'appId': appId.toJson(),
      'appName': appName,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
      'redirectUri': redirectUri,
      'alreadyLinked': alreadyLinked,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppLinkRequestViewImpl extends AppLinkRequestView {
  _AppLinkRequestViewImpl({
    required _isc.UuidValue appId,
    required String appName,
    String? websiteUrl,
    required String redirectUri,
    required bool alreadyLinked,
  }) : super._(
         appId: appId,
         appName: appName,
         websiteUrl: websiteUrl,
         redirectUri: redirectUri,
         alreadyLinked: alreadyLinked,
       );

  /// Returns a shallow copy of this [AppLinkRequestView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AppLinkRequestView copyWith({
    _isc.UuidValue? appId,
    String? appName,
    Object? websiteUrl = _Undefined,
    String? redirectUri,
    bool? alreadyLinked,
  }) {
    return AppLinkRequestView(
      appId: appId ?? this.appId,
      appName: appName ?? this.appName,
      websiteUrl: websiteUrl is String? ? websiteUrl : this.websiteUrl,
      redirectUri: redirectUri ?? this.redirectUri,
      alreadyLinked: alreadyLinked ?? this.alreadyLinked,
    );
  }
}
