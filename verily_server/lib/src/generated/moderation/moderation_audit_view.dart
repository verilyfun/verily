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

abstract class ModerationAuditView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ModerationAuditView._({
    this.actorAuthUserId,
    required this.event,
    required this.note,
    required this.pauseActive,
    required this.createdAt,
  });

  factory ModerationAuditView({
    _is.UuidValue? actorAuthUserId,
    required String event,
    required String note,
    required bool pauseActive,
    required DateTime createdAt,
  }) = _ModerationAuditViewImpl;

  factory ModerationAuditView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ModerationAuditView(
      actorAuthUserId: jsonSerialization['actorAuthUserId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['actorAuthUserId'],
            ),
      event: jsonSerialization['event'] as String,
      note: jsonSerialization['note'] as String,
      pauseActive: _is.BoolJsonExtension.fromJson(
        jsonSerialization['pauseActive'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  _is.UuidValue? actorAuthUserId;

  String event;

  String note;

  bool pauseActive;

  DateTime createdAt;

  /// Returns a shallow copy of this [ModerationAuditView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ModerationAuditView copyWith({
    _is.UuidValue? actorAuthUserId,
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
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ModerationAuditViewImpl extends ModerationAuditView {
  _ModerationAuditViewImpl({
    _is.UuidValue? actorAuthUserId,
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
  @_is.useResult
  @override
  ModerationAuditView copyWith({
    Object? actorAuthUserId = _Undefined,
    String? event,
    String? note,
    bool? pauseActive,
    DateTime? createdAt,
  }) {
    return ModerationAuditView(
      actorAuthUserId: actorAuthUserId is _is.UuidValue?
          ? actorAuthUserId
          : this.actorAuthUserId,
      event: event ?? this.event,
      note: note ?? this.note,
      pauseActive: pauseActive ?? this.pauseActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
