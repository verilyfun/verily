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
import 'package:verily_server/src/generated/protocol.dart' as _itf691yl;

import '../apps/verily_app_view.dart' as _ihuwd3rm;

/// Returned exactly once when a key is created. Verily keeps only its hash.
abstract class VerilyAppCredential
    implements _is.SerializableModel, _is.ProtocolSerialization {
  VerilyAppCredential._({
    required this.app,
    required this.keyId,
    required this.secret,
  });

  factory VerilyAppCredential({
    required _ihuwd3rm.VerilyAppView app,
    required String keyId,
    required String secret,
  }) = _VerilyAppCredentialImpl;

  factory VerilyAppCredential.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerilyAppCredential(
      app: _itf691yl.Protocol().deserialize<_ihuwd3rm.VerilyAppView>(
        jsonSerialization['app'],
      ),
      keyId: jsonSerialization['keyId'] as String,
      secret: jsonSerialization['secret'] as String,
    );
  }

  _ihuwd3rm.VerilyAppView app;

  String keyId;

  /// Complete bearer credential (`vly_<keyId>.<secret>`).
  String secret;

  /// Returns a shallow copy of this [VerilyAppCredential]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerilyAppCredential copyWith({
    _ihuwd3rm.VerilyAppView? app,
    String? keyId,
    String? secret,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyAppCredential',
      'app': app.toJson(),
      'keyId': keyId,
      'secret': secret,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerilyAppCredential',
      'app': app.toJsonForProtocol(),
      'keyId': keyId,
      'secret': secret,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _VerilyAppCredentialImpl extends VerilyAppCredential {
  _VerilyAppCredentialImpl({
    required _ihuwd3rm.VerilyAppView app,
    required String keyId,
    required String secret,
  }) : super._(
         app: app,
         keyId: keyId,
         secret: secret,
       );

  /// Returns a shallow copy of this [VerilyAppCredential]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerilyAppCredential copyWith({
    _ihuwd3rm.VerilyAppView? app,
    String? keyId,
    String? secret,
  }) {
    return VerilyAppCredential(
      app: app ?? this.app.copyWith(),
      keyId: keyId ?? this.keyId,
      secret: secret ?? this.secret,
    );
  }
}
