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

abstract class ModerationAuditView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ModerationAuditView._({
    this.actorAuthUserId,
    required this.event,
    required this.note,
    required this.pauseActive,
    required this.createdAt,
  });

  factory ModerationAuditView({
    _isc.UuidValue? actorAuthUserId,
    required String event,
    required String note,
    required bool pauseActive,
    required DateTime createdAt,
  }) = _ModerationAuditViewImpl;

  factory ModerationAuditView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ModerationAuditView(
      actorAuthUserId: jsonSerialization['actorAuthUserId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['actorAuthUserId'],
            ),
      event: jsonSerialization['event'] as String,
      note: jsonSerialization['note'] as String,
      pauseActive: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['pauseActive'],
      ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  _isc.UuidValue? actorAuthUserId;

  String event;

  String note;

  bool pauseActive;

  DateTime createdAt;

  /// Returns a shallow copy of this [ModerationAuditView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ModerationAuditView copyWith({
    _isc.UuidValue? actorAuthUserId = const _isc.$UndefinedUuidValue(),
    String? event,
    String? note,
    bool? pauseActive,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ModerationAuditView',
      if (actorAuthUserId != null) 'actorAuthUserId': actorAuthUserId?.toJson(),
      'event': event,
      'note': note,
      'pauseActive': pauseActive,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ModerationAuditView',
      if (actorAuthUserId != null) 'actorAuthUserId': actorAuthUserId?.toJson(),
      'event': event,
      'note': note,
      'pauseActive': pauseActive,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ModerationAuditViewImpl extends ModerationAuditView {
  _ModerationAuditViewImpl({
    _isc.UuidValue? actorAuthUserId,
    required String event,
    required String note,
    required bool pauseActive,
    required DateTime createdAt,
  }) : super._(
         actorAuthUserId: actorAuthUserId,
         event: event,
         note: note,
         pauseActive: pauseActive,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ModerationAuditView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ModerationAuditView copyWith({
    _isc.UuidValue? actorAuthUserId = const _isc.$UndefinedUuidValue(),
    String? event,
    String? note,
    bool? pauseActive,
    DateTime? createdAt,
  }) {
    return ModerationAuditView(
      actorAuthUserId: actorAuthUserId is _isc.UndefinedSentinel
          ? this.actorAuthUserId
          : actorAuthUserId,
      event: event ?? this.event,
      note: note ?? this.note,
      pauseActive: pauseActive ?? this.pauseActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
