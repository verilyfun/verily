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

import '../action_verification/action_attempt_status.dart' as _i8xrgke5;
import '../apps/app_confirmation_outcome.dart' as _isxmw90h;

/// Creator-facing delivery log row. The participant subject is deliberately omitted.
abstract class AppConfirmationView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AppConfirmationView._({
    required this.id,
    required this.eventId,
    required this.actionKey,
    required this.outcome,
    required this.reasonCode,
    required this.occurredAt,
    required this.receivedAt,
    this.attemptStatus,
  });

  factory AppConfirmationView({
    required _isc.UuidValue id,
    required String eventId,
    required String actionKey,
    required _isxmw90h.AppConfirmationOutcome outcome,
    required String reasonCode,
    required DateTime occurredAt,
    required DateTime receivedAt,
    _i8xrgke5.ActionAttemptStatus? attemptStatus,
  }) = _AppConfirmationViewImpl;

  factory AppConfirmationView.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppConfirmationView(
      id: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      eventId: jsonSerialization['eventId'] as String,
      actionKey: jsonSerialization['actionKey'] as String,
      outcome: _isxmw90h.AppConfirmationOutcome.fromJson(
        (jsonSerialization['outcome'] as String),
      ),
      reasonCode: jsonSerialization['reasonCode'] as String,
      occurredAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['occurredAt'],
      ),
      receivedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['receivedAt'],
      ),
      attemptStatus: jsonSerialization['attemptStatus'] == null
          ? null
          : _i8xrgke5.ActionAttemptStatus.fromJson(
              (jsonSerialization['attemptStatus'] as String),
            ),
    );
  }

  _isc.UuidValue id;

  String eventId;

  String actionKey;

  _isxmw90h.AppConfirmationOutcome outcome;

  String reasonCode;

  DateTime occurredAt;

  DateTime receivedAt;

  _i8xrgke5.ActionAttemptStatus? attemptStatus;

  /// Returns a shallow copy of this [AppConfirmationView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AppConfirmationView copyWith({
    _isc.UuidValue? id,
    String? eventId,
    String? actionKey,
    _isxmw90h.AppConfirmationOutcome? outcome,
    String? reasonCode,
    DateTime? occurredAt,
    DateTime? receivedAt,
    _i8xrgke5.ActionAttemptStatus? attemptStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppConfirmationView',
      'id': id.toJson(),
      'eventId': eventId,
      'actionKey': actionKey,
      'outcome': outcome.toJson(),
      'reasonCode': reasonCode,
      'occurredAt': occurredAt.toJson(),
      'receivedAt': receivedAt.toJson(),
      if (attemptStatus != null) 'attemptStatus': attemptStatus?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppConfirmationView',
      'id': id.toJson(),
      'eventId': eventId,
      'actionKey': actionKey,
      'outcome': outcome.toJson(),
      'reasonCode': reasonCode,
      'occurredAt': occurredAt.toJson(),
      'receivedAt': receivedAt.toJson(),
      if (attemptStatus != null) 'attemptStatus': attemptStatus?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppConfirmationViewImpl extends AppConfirmationView {
  _AppConfirmationViewImpl({
    required _isc.UuidValue id,
    required String eventId,
    required String actionKey,
    required _isxmw90h.AppConfirmationOutcome outcome,
    required String reasonCode,
    required DateTime occurredAt,
    required DateTime receivedAt,
    _i8xrgke5.ActionAttemptStatus? attemptStatus,
  }) : super._(
         id: id,
         eventId: eventId,
         actionKey: actionKey,
         outcome: outcome,
         reasonCode: reasonCode,
         occurredAt: occurredAt,
         receivedAt: receivedAt,
         attemptStatus: attemptStatus,
       );

  /// Returns a shallow copy of this [AppConfirmationView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AppConfirmationView copyWith({
    _isc.UuidValue? id,
    String? eventId,
    String? actionKey,
    _isxmw90h.AppConfirmationOutcome? outcome,
    String? reasonCode,
    DateTime? occurredAt,
    DateTime? receivedAt,
    Object? attemptStatus = _Undefined,
  }) {
    return AppConfirmationView(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      actionKey: actionKey ?? this.actionKey,
      outcome: outcome ?? this.outcome,
      reasonCode: reasonCode ?? this.reasonCode,
      occurredAt: occurredAt ?? this.occurredAt,
      receivedAt: receivedAt ?? this.receivedAt,
      attemptStatus: attemptStatus is _i8xrgke5.ActionAttemptStatus?
          ? attemptStatus
          : this.attemptStatus,
    );
  }
}
