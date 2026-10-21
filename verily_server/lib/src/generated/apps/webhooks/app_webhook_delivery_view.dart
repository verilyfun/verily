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

import '../../apps/webhooks/app_event_status.dart' as _i9zhna0j;

/// One outbound webhook call, as the App's creator sees it.
abstract class AppWebhookDeliveryView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AppWebhookDeliveryView._({
    required this.id,
    required this.eventId,
    required this.eventType,
    required this.attemptNumber,
    required this.requestedAt,
    required this.durationMilliseconds,
    this.statusCode,
    this.errorCode,
    required this.succeeded,
    this.eventStatus,
  });

  factory AppWebhookDeliveryView({
    required _is.UuidValue id,
    required String eventId,
    required String eventType,
    required int attemptNumber,
    required DateTime requestedAt,
    required int durationMilliseconds,
    int? statusCode,
    String? errorCode,
    required bool succeeded,
    _i9zhna0j.AppEventStatus? eventStatus,
  }) = _AppWebhookDeliveryViewImpl;

  factory AppWebhookDeliveryView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AppWebhookDeliveryView(
      id: _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      eventId: jsonSerialization['eventId'] as String,
      eventType: jsonSerialization['eventType'] as String,
      attemptNumber: jsonSerialization['attemptNumber'] as int,
      requestedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['requestedAt'],
      ),
      durationMilliseconds: jsonSerialization['durationMilliseconds'] as int,
      statusCode: jsonSerialization['statusCode'] as int?,
      errorCode: jsonSerialization['errorCode'] as String?,
      succeeded: _is.BoolJsonExtension.fromJson(jsonSerialization['succeeded']),
      eventStatus: jsonSerialization['eventStatus'] == null
          ? null
          : _i9zhna0j.AppEventStatus.fromJson(
              (jsonSerialization['eventStatus'] as String),
            ),
    );
  }

  _is.UuidValue id;

  String eventId;

  String eventType;

  int attemptNumber;

  DateTime requestedAt;

  int durationMilliseconds;

  int? statusCode;

  String? errorCode;

  bool succeeded;

  /// The event's current state; null for pull verification calls.
  _i9zhna0j.AppEventStatus? eventStatus;

  /// Returns a shallow copy of this [AppWebhookDeliveryView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppWebhookDeliveryView copyWith({
    _is.UuidValue? id,
    String? eventId,
    String? eventType,
    int? attemptNumber,
    DateTime? requestedAt,
    int? durationMilliseconds,
    int? statusCode,
    String? errorCode,
    bool? succeeded,
    _i9zhna0j.AppEventStatus? eventStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppWebhookDeliveryView',
      'id': id.toJson(),
      'eventId': eventId,
      'eventType': eventType,
      'attemptNumber': attemptNumber,
      'requestedAt': requestedAt.toJson(),
      'durationMilliseconds': durationMilliseconds,
      if (statusCode != null) 'statusCode': statusCode,
      if (errorCode != null) 'errorCode': errorCode,
      'succeeded': succeeded,
      if (eventStatus != null) 'eventStatus': eventStatus?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppWebhookDeliveryView',
      'id': id.toJson(),
      'eventId': eventId,
      'eventType': eventType,
      'attemptNumber': attemptNumber,
      'requestedAt': requestedAt.toJson(),
      'durationMilliseconds': durationMilliseconds,
      if (statusCode != null) 'statusCode': statusCode,
      if (errorCode != null) 'errorCode': errorCode,
      'succeeded': succeeded,
      if (eventStatus != null) 'eventStatus': eventStatus?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppWebhookDeliveryViewImpl extends AppWebhookDeliveryView {
  _AppWebhookDeliveryViewImpl({
    required _is.UuidValue id,
    required String eventId,
    required String eventType,
    required int attemptNumber,
    required DateTime requestedAt,
    required int durationMilliseconds,
    int? statusCode,
    String? errorCode,
    required bool succeeded,
    _i9zhna0j.AppEventStatus? eventStatus,
  }) : super._(
         id: id,
         eventId: eventId,
         eventType: eventType,
         attemptNumber: attemptNumber,
         requestedAt: requestedAt,
         durationMilliseconds: durationMilliseconds,
         statusCode: statusCode,
         errorCode: errorCode,
         succeeded: succeeded,
         eventStatus: eventStatus,
       );

  /// Returns a shallow copy of this [AppWebhookDeliveryView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppWebhookDeliveryView copyWith({
    _is.UuidValue? id,
    String? eventId,
    String? eventType,
    int? attemptNumber,
    DateTime? requestedAt,
    int? durationMilliseconds,
    Object? statusCode = _Undefined,
    Object? errorCode = _Undefined,
    bool? succeeded,
    Object? eventStatus = _Undefined,
  }) {
    return AppWebhookDeliveryView(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      requestedAt: requestedAt ?? this.requestedAt,
      durationMilliseconds: durationMilliseconds ?? this.durationMilliseconds,
      statusCode: statusCode is int? ? statusCode : this.statusCode,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      succeeded: succeeded ?? this.succeeded,
      eventStatus: eventStatus is _i9zhna0j.AppEventStatus?
          ? eventStatus
          : this.eventStatus,
    );
  }
}
