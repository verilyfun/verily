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
import 'package:verily_client/src/protocol/protocol.dart' as _iop4qpu5;

import '../apps/verily_app_key_view.dart' as _is0b8866;
import '../apps/verily_app_status.dart' as _i0paxa5b;

/// Creator-facing App summary. Never contains a secret or a secret hash.
abstract class VerilyAppView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  VerilyAppView._({
    required this.id,
    required this.name,
    this.websiteUrl,
    required this.status,
    required this.keys,
    required this.boundActionCount,
    this.webhookUrl,
    int? webhookSecretVersion,
    required this.redirectUris,
    required this.createdAt,
    this.revokedAt,
  }) : webhookSecretVersion = webhookSecretVersion ?? 0;

  factory VerilyAppView({
    required _isc.UuidValue id,
    required String name,
    String? websiteUrl,
    required _i0paxa5b.VerilyAppStatus status,
    required List<_is0b8866.VerilyAppKeyView> keys,
    required int boundActionCount,
    String? webhookUrl,
    int? webhookSecretVersion,
    required List<String> redirectUris,
    required DateTime createdAt,
    DateTime? revokedAt,
  }) = _VerilyAppViewImpl;

  factory VerilyAppView.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerilyAppView(
      id: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      websiteUrl: jsonSerialization['websiteUrl'] as String?,
      status: _i0paxa5b.VerilyAppStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      keys: _iop4qpu5.Protocol().deserialize<List<_is0b8866.VerilyAppKeyView>>(
        jsonSerialization['keys'],
      ),
      boundActionCount: jsonSerialization['boundActionCount'] as int,
      webhookUrl: jsonSerialization['webhookUrl'] as String?,
      webhookSecretVersion: jsonSerialization['webhookSecretVersion'] as int?,
      redirectUris: _iop4qpu5.Protocol().deserialize<List<String>>(
        jsonSerialization['redirectUris'],
      ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
    );
  }

  _isc.UuidValue id;

  String name;

  String? websiteUrl;

  _i0paxa5b.VerilyAppStatus status;

  List<_is0b8866.VerilyAppKeyView> keys;

  /// Live or draft action revisions whose proof this App confirms.
  int boundActionCount;

  String? webhookUrl;

  /// 0 until a signing secret has been issued.
  int webhookSecretVersion;

  List<String> redirectUris;

  DateTime createdAt;

  DateTime? revokedAt;

  /// Returns a shallow copy of this [VerilyAppView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  VerilyAppView copyWith({
    _isc.UuidValue? id,
    String? name,
    String? websiteUrl,
    _i0paxa5b.VerilyAppStatus? status,
    List<_is0b8866.VerilyAppKeyView>? keys,
    int? boundActionCount,
    String? webhookUrl,
    int? webhookSecretVersion,
    List<String>? redirectUris,
    DateTime? createdAt,
    DateTime? revokedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyAppView',
      'id': id.toJson(),
      'name': name,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
      'status': status.toJson(),
      'keys': keys.toJson(valueToJson: (v) => v.toJson()),
      'boundActionCount': boundActionCount,
      if (webhookUrl != null) 'webhookUrl': webhookUrl,
      'webhookSecretVersion': webhookSecretVersion,
      'redirectUris': redirectUris.toJson(),
      'createdAt': createdAt.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerilyAppView',
      'id': id.toJson(),
      'name': name,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
      'status': status.toJson(),
      'keys': keys.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'boundActionCount': boundActionCount,
      if (webhookUrl != null) 'webhookUrl': webhookUrl,
      'webhookSecretVersion': webhookSecretVersion,
      'redirectUris': redirectUris.toJson(),
      'createdAt': createdAt.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VerilyAppViewImpl extends VerilyAppView {
  _VerilyAppViewImpl({
    required _isc.UuidValue id,
    required String name,
    String? websiteUrl,
    required _i0paxa5b.VerilyAppStatus status,
    required List<_is0b8866.VerilyAppKeyView> keys,
    required int boundActionCount,
    String? webhookUrl,
    int? webhookSecretVersion,
    required List<String> redirectUris,
    required DateTime createdAt,
    DateTime? revokedAt,
  }) : super._(
         id: id,
         name: name,
         websiteUrl: websiteUrl,
         status: status,
         keys: keys,
         boundActionCount: boundActionCount,
         webhookUrl: webhookUrl,
         webhookSecretVersion: webhookSecretVersion,
         redirectUris: redirectUris,
         createdAt: createdAt,
         revokedAt: revokedAt,
       );

  /// Returns a shallow copy of this [VerilyAppView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  VerilyAppView copyWith({
    _isc.UuidValue? id,
    String? name,
    Object? websiteUrl = _Undefined,
    _i0paxa5b.VerilyAppStatus? status,
    List<_is0b8866.VerilyAppKeyView>? keys,
    int? boundActionCount,
    Object? webhookUrl = _Undefined,
    int? webhookSecretVersion,
    List<String>? redirectUris,
    DateTime? createdAt,
    Object? revokedAt = _Undefined,
  }) {
    return VerilyAppView(
      id: id ?? this.id,
      name: name ?? this.name,
      websiteUrl: websiteUrl is String? ? websiteUrl : this.websiteUrl,
      status: status ?? this.status,
      keys: keys ?? this.keys.map((e0) => e0.copyWith()).toList(),
      boundActionCount: boundActionCount ?? this.boundActionCount,
      webhookUrl: webhookUrl is String? ? webhookUrl : this.webhookUrl,
      webhookSecretVersion: webhookSecretVersion ?? this.webhookSecretVersion,
      redirectUris: redirectUris ?? this.redirectUris.map((e0) => e0).toList(),
      createdAt: createdAt ?? this.createdAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
    );
  }
}
