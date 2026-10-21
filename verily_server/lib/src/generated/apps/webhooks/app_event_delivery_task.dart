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

abstract class AppEventDeliveryTask
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AppEventDeliveryTask._({required this.eventId});

  factory AppEventDeliveryTask({required _is.UuidValue eventId}) =
      _AppEventDeliveryTaskImpl;

  factory AppEventDeliveryTask.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AppEventDeliveryTask(
      eventId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['eventId'],
      ),
    );
  }

  _is.UuidValue eventId;

  /// Returns a shallow copy of this [AppEventDeliveryTask]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppEventDeliveryTask copyWith({_is.UuidValue? eventId});
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
    return _is.SerializationManager.encode(this);
  }
}

class _AppEventDeliveryTaskImpl extends AppEventDeliveryTask {
  _AppEventDeliveryTaskImpl({required _is.UuidValue eventId})
    : super._(eventId: eventId);

  /// Returns a shallow copy of this [AppEventDeliveryTask]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppEventDeliveryTask copyWith({_is.UuidValue? eventId}) {
    return AppEventDeliveryTask(eventId: eventId ?? this.eventId);
  }
}
