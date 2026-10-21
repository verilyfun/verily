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

/// A participant's own subject for one App, to paste into that App.
abstract class VerilyAppLinkView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  VerilyAppLinkView._({
    required this.appId,
    required this.appName,
    required this.subject,
    required this.createdAt,
  });

  factory VerilyAppLinkView({
    required _is.UuidValue appId,
    required String appName,
    required String subject,
    required DateTime createdAt,
  }) = _VerilyAppLinkViewImpl;

  factory VerilyAppLinkView.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerilyAppLinkView(
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      appName: jsonSerialization['appName'] as String,
      subject: jsonSerialization['subject'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  _is.UuidValue appId;

  String appName;

  String subject;

  DateTime createdAt;

  /// Returns a shallow copy of this [VerilyAppLinkView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerilyAppLinkView copyWith({
    _is.UuidValue? appId,
    String? appName,
    String? subject,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyAppLinkView',
      'appId': appId.toJson(),
      'appName': appName,
      'subject': subject,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerilyAppLinkView',
      'appId': appId.toJson(),
      'appName': appName,
      'subject': subject,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _VerilyAppLinkViewImpl extends VerilyAppLinkView {
  _VerilyAppLinkViewImpl({
    required _is.UuidValue appId,
    required String appName,
    required String subject,
    required DateTime createdAt,
  }) : super._(
         appId: appId,
         appName: appName,
         subject: subject,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [VerilyAppLinkView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerilyAppLinkView copyWith({
    _is.UuidValue? appId,
    String? appName,
    String? subject,
    DateTime? createdAt,
  }) {
    return VerilyAppLinkView(
      appId: appId ?? this.appId,
      appName: appName ?? this.appName,
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
