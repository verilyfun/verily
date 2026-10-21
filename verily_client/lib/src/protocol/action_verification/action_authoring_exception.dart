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

import '../action_verification/action_authoring_problem.dart' as _i4svfrok;

/// An action draft or publication was refused for a reason the creator can
/// fix. Clients show their own localized copy for [reason]; [message] is a
/// developer-facing English summary.
abstract class ActionAuthoringException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  ActionAuthoringException._({required this.reason, required this.message});

  factory ActionAuthoringException({
    required _i4svfrok.ActionAuthoringProblem reason,
    required String message,
  }) = _ActionAuthoringExceptionImpl;

  factory ActionAuthoringException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionAuthoringException(
      reason: _i4svfrok.ActionAuthoringProblem.fromJson(
        (jsonSerialization['reason'] as String),
      ),
      message: jsonSerialization['message'] as String,
    );
  }

  _i4svfrok.ActionAuthoringProblem reason;

  String message;

  /// Returns a shallow copy of this [ActionAuthoringException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionAuthoringException copyWith({
    _i4svfrok.ActionAuthoringProblem? reason,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionAuthoringException',
      'reason': reason.toJson(),
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionAuthoringException',
      'reason': reason.toJson(),
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ActionAuthoringException(reason: $reason, message: $message)';
  }
}

class _ActionAuthoringExceptionImpl extends ActionAuthoringException {
  _ActionAuthoringExceptionImpl({
    required _i4svfrok.ActionAuthoringProblem reason,
    required String message,
  }) : super._(reason: reason, message: message);

  /// Returns a shallow copy of this [ActionAuthoringException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActionAuthoringException copyWith({
    _i4svfrok.ActionAuthoringProblem? reason,
    String? message,
  }) {
    return ActionAuthoringException(
      reason: reason ?? this.reason,
      message: message ?? this.message,
    );
  }
}
