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

abstract class VerilyAppKeyView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  VerilyAppKeyView._({
    required this.keyId,
    required this.createdAt,
    this.lastUsedAt,
    this.revokedAt,
  });

  factory VerilyAppKeyView({
    required String keyId,
    required DateTime createdAt,
    DateTime? lastUsedAt,
    DateTime? revokedAt,
  }) = _VerilyAppKeyViewImpl;

  factory VerilyAppKeyView.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerilyAppKeyView(
      keyId: jsonSerialization['keyId'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastUsedAt: jsonSerialization['lastUsedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['lastUsedAt']),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
    );
  }

  String keyId;

  DateTime createdAt;

  DateTime? lastUsedAt;

  DateTime? revokedAt;

  /// Returns a shallow copy of this [VerilyAppKeyView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerilyAppKeyView copyWith({
    String? keyId,
    DateTime? createdAt,
    DateTime? lastUsedAt = const _is.$UndefinedDateTime(),
    DateTime? revokedAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyAppKeyView',
      'keyId': keyId,
      'createdAt': createdAt.toJson(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt?.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerilyAppKeyView',
      'keyId': keyId,
      'createdAt': createdAt.toJson(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt?.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _VerilyAppKeyViewImpl extends VerilyAppKeyView {
  _VerilyAppKeyViewImpl({
    required String keyId,
    required DateTime createdAt,
    DateTime? lastUsedAt,
    DateTime? revokedAt,
  }) : super._(
         keyId: keyId,
         createdAt: createdAt,
         lastUsedAt: lastUsedAt,
         revokedAt: revokedAt,
       );

  /// Returns a shallow copy of this [VerilyAppKeyView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerilyAppKeyView copyWith({
    String? keyId,
    DateTime? createdAt,
    DateTime? lastUsedAt = const _is.$UndefinedDateTime(),
    DateTime? revokedAt = const _is.$UndefinedDateTime(),
  }) {
    return VerilyAppKeyView(
      keyId: keyId ?? this.keyId,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt is _is.UndefinedSentinel
          ? this.lastUsedAt
          : lastUsedAt,
      revokedAt: revokedAt is _is.UndefinedSentinel
          ? this.revokedAt
          : revokedAt,
    );
  }
}
