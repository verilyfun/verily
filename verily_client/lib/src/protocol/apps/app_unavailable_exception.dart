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

/// The action's App was revoked, so it cannot start or be linked.
abstract class AppUnavailableException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  AppUnavailableException._({
    required this.appName,
    required this.message,
  });

  factory AppUnavailableException({
    required String appName,
    required String message,
  }) = _AppUnavailableExceptionImpl;

  factory AppUnavailableException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AppUnavailableException(
      appName: jsonSerialization['appName'] as String,
      message: jsonSerialization['message'] as String,
    );
  }

  String appName;

  String message;

  /// Returns a shallow copy of this [AppUnavailableException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AppUnavailableException copyWith({
    String? appName,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppUnavailableException',
      'appName': appName,
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppUnavailableException',
      'appName': appName,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'AppUnavailableException(appName: $appName, message: $message)';
  }
}

class _AppUnavailableExceptionImpl extends AppUnavailableException {
  _AppUnavailableExceptionImpl({
    required String appName,
    required String message,
  }) : super._(
         appName: appName,
         message: message,
       );

  /// Returns a shallow copy of this [AppUnavailableException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AppUnavailableException copyWith({
    String? appName,
    String? message,
  }) {
    return AppUnavailableException(
      appName: appName ?? this.appName,
      message: message ?? this.message,
    );
  }
}
