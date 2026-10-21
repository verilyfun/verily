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

import '../rewards/reward_problem.dart' as _iy4kq0ps;

/// A reward operation was refused for a reason the app explains in product
/// language. [message] is developer-facing English.
abstract class RewardException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  RewardException._({
    required this.problem,
    required this.message,
  });

  factory RewardException({
    required _iy4kq0ps.RewardProblem problem,
    required String message,
  }) = _RewardExceptionImpl;

  factory RewardException.fromJson(Map<String, dynamic> jsonSerialization) {
    return RewardException(
      problem: _iy4kq0ps.RewardProblem.fromJson(
        (jsonSerialization['problem'] as String),
      ),
      message: jsonSerialization['message'] as String,
    );
  }

  _iy4kq0ps.RewardProblem problem;

  String message;

  /// Returns a shallow copy of this [RewardException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RewardException copyWith({
    _iy4kq0ps.RewardProblem? problem,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RewardException',
      'problem': problem.toJson(),
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RewardException',
      'problem': problem.toJson(),
      'message': message,
    };
  }

  @override
  String toString() {
    return 'RewardException(problem: $problem, message: $message)';
  }
}

class _RewardExceptionImpl extends RewardException {
  _RewardExceptionImpl({
    required _iy4kq0ps.RewardProblem problem,
    required String message,
  }) : super._(
         problem: problem,
         message: message,
       );

  /// Returns a shallow copy of this [RewardException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RewardException copyWith({
    _iy4kq0ps.RewardProblem? problem,
    String? message,
  }) {
    return RewardException(
      problem: problem ?? this.problem,
      message: message ?? this.message,
    );
  }
}
