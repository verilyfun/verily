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

/// A new `whsec_` signing secret, returned once when it is rotated.
abstract class VerilyAppWebhookSecret
    implements _is.SerializableModel, _is.ProtocolSerialization {
  VerilyAppWebhookSecret._({
    required this.appId,
    required this.version,
    required this.secret,
    this.previousSecretValidUntil,
  });

  factory VerilyAppWebhookSecret({
    required _is.UuidValue appId,
    required int version,
    required String secret,
    DateTime? previousSecretValidUntil,
  }) = _VerilyAppWebhookSecretImpl;

  factory VerilyAppWebhookSecret.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return VerilyAppWebhookSecret(
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      version: jsonSerialization['version'] as int,
      secret: jsonSerialization['secret'] as String,
      previousSecretValidUntil:
          jsonSerialization['previousSecretValidUntil'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['previousSecretValidUntil'],
            ),
    );
  }

  _is.UuidValue appId;

  int version;

  String secret;

  /// Until this instant events are also signed with the previous secret.
  DateTime? previousSecretValidUntil;

  /// Returns a shallow copy of this [VerilyAppWebhookSecret]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerilyAppWebhookSecret copyWith({
    _is.UuidValue? appId,
    int? version,
    String? secret,
    DateTime? previousSecretValidUntil = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyAppWebhookSecret',
      'appId': appId.toJson(),
      'version': version,
      'secret': secret,
      if (previousSecretValidUntil != null)
        'previousSecretValidUntil': previousSecretValidUntil?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerilyAppWebhookSecret',
      'appId': appId.toJson(),
      'version': version,
      'secret': secret,
      if (previousSecretValidUntil != null)
        'previousSecretValidUntil': previousSecretValidUntil?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _VerilyAppWebhookSecretImpl extends VerilyAppWebhookSecret {
  _VerilyAppWebhookSecretImpl({
    required _is.UuidValue appId,
    required int version,
    required String secret,
    DateTime? previousSecretValidUntil,
  }) : super._(
         appId: appId,
         version: version,
         secret: secret,
         previousSecretValidUntil: previousSecretValidUntil,
       );

  /// Returns a shallow copy of this [VerilyAppWebhookSecret]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerilyAppWebhookSecret copyWith({
    _is.UuidValue? appId,
    int? version,
    String? secret,
    DateTime? previousSecretValidUntil = const _is.$UndefinedDateTime(),
  }) {
    return VerilyAppWebhookSecret(
      appId: appId ?? this.appId,
      version: version ?? this.version,
      secret: secret ?? this.secret,
      previousSecretValidUntil:
          previousSecretValidUntil is _is.UndefinedSentinel
          ? this.previousSecretValidUntil
          : previousSecretValidUntil,
    );
  }
}
