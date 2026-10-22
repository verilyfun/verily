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

import '../../action_verification/app_attest/app_attest_problem.dart'
    as _i2pqp85k;

/// A refused App Attest registration. The message is safe to show.
abstract class AppAttestException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  AppAttestException._({
    required this.problem,
    required this.message,
  });

  factory AppAttestException({
    required _i2pqp85k.AppAttestProblem problem,
    required String message,
  }) = _AppAttestExceptionImpl;

  factory AppAttestException.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppAttestException(
      problem: _i2pqp85k.AppAttestProblem.fromJson(
        (jsonSerialization['problem'] as String),
      ),
      message: jsonSerialization['message'] as String,
    );
  }

  _i2pqp85k.AppAttestProblem problem;

  String message;

  /// Returns a shallow copy of this [AppAttestException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AppAttestException copyWith({
    _i2pqp85k.AppAttestProblem? problem,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppAttestException',
      'problem': problem.toJson(),
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppAttestException',
      'problem': problem.toJson(),
      'message': message,
    };
  }

  @override
  String toString() {
    return 'AppAttestException(problem: $problem, message: $message)';
  }
}

class _AppAttestExceptionImpl extends AppAttestException {
  _AppAttestExceptionImpl({
    required _i2pqp85k.AppAttestProblem problem,
    required String message,
  }) : super._(
         problem: problem,
         message: message,
       );

  /// Returns a shallow copy of this [AppAttestException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AppAttestException copyWith({
    _i2pqp85k.AppAttestProblem? problem,
    String? message,
  }) {
    return AppAttestException(
      problem: problem ?? this.problem,
      message: message ?? this.message,
    );
  }
}
