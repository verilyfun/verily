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

import '../apps/app_platform_problem.dart' as _ioz2x0qq;

/// A refused App platform call. The message is safe to show.
abstract class AppPlatformException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  AppPlatformException._({
    required this.problem,
    required this.message,
  });

  factory AppPlatformException({
    required _ioz2x0qq.AppPlatformProblem problem,
    required String message,
  }) = _AppPlatformExceptionImpl;

  factory AppPlatformException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AppPlatformException(
      problem: _ioz2x0qq.AppPlatformProblem.fromJson(
        (jsonSerialization['problem'] as String),
      ),
      message: jsonSerialization['message'] as String,
    );
  }

  _ioz2x0qq.AppPlatformProblem problem;

  String message;

  /// Returns a shallow copy of this [AppPlatformException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AppPlatformException copyWith({
    _ioz2x0qq.AppPlatformProblem? problem,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppPlatformException',
      'problem': problem.toJson(),
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppPlatformException',
      'problem': problem.toJson(),
      'message': message,
    };
  }

  @override
  String toString() {
    return 'AppPlatformException(problem: $problem, message: $message)';
  }
}

class _AppPlatformExceptionImpl extends AppPlatformException {
  _AppPlatformExceptionImpl({
    required _ioz2x0qq.AppPlatformProblem problem,
    required String message,
  }) : super._(
         problem: problem,
         message: message,
       );

  /// Returns a shallow copy of this [AppPlatformException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AppPlatformException copyWith({
    _ioz2x0qq.AppPlatformProblem? problem,
    String? message,
  }) {
    return AppPlatformException(
      problem: problem ?? this.problem,
      message: message ?? this.message,
    );
  }
}
