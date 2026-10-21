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

abstract class AppEventDeliveryTask
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AppEventDeliveryTask._({required this.eventId});

  factory AppEventDeliveryTask({required _isc.UuidValue eventId}) =
      _AppEventDeliveryTaskImpl;

  factory AppEventDeliveryTask.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AppEventDeliveryTask(
      eventId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['eventId'],
      ),
    );
  }

  _isc.UuidValue eventId;

  /// Returns a shallow copy of this [AppEventDeliveryTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AppEventDeliveryTask copyWith({_isc.UuidValue? eventId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppEventDeliveryTask',
      'eventId': eventId.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppEventDeliveryTask',
      'eventId': eventId.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _AppEventDeliveryTaskImpl extends AppEventDeliveryTask {
  _AppEventDeliveryTaskImpl({required _isc.UuidValue eventId})
    : super._(eventId: eventId);

  /// Returns a shallow copy of this [AppEventDeliveryTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AppEventDeliveryTask copyWith({_isc.UuidValue? eventId}) {
    return AppEventDeliveryTask(eventId: eventId ?? this.eventId);
  }
}
