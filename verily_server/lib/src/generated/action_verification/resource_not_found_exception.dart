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

import '../action_verification/missing_resource.dart' as _ip6hy6rf;

/// The thing asked for does not exist or is not visible to the caller. The
/// message is safe to show; it never says which of the two applies.
abstract class ResourceNotFoundException
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  ResourceNotFoundException._({
    required this.resource,
    required this.message,
  });

  factory ResourceNotFoundException({
    required _ip6hy6rf.MissingResource resource,
    required String message,
  }) = _ResourceNotFoundExceptionImpl;

  factory ResourceNotFoundException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ResourceNotFoundException(
      resource: _ip6hy6rf.MissingResource.fromJson(
        (jsonSerialization['resource'] as String),
      ),
      message: jsonSerialization['message'] as String,
    );
  }

  _ip6hy6rf.MissingResource resource;

  String message;

  /// Returns a shallow copy of this [ResourceNotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ResourceNotFoundException copyWith({
    _ip6hy6rf.MissingResource? resource,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResourceNotFoundException',
      'resource': resource.toJson(),
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ResourceNotFoundException',
      'resource': resource.toJson(),
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ResourceNotFoundException(resource: $resource, message: $message)';
  }
}

class _ResourceNotFoundExceptionImpl extends ResourceNotFoundException {
  _ResourceNotFoundExceptionImpl({
    required _ip6hy6rf.MissingResource resource,
    required String message,
  }) : super._(
         resource: resource,
         message: message,
       );

  /// Returns a shallow copy of this [ResourceNotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ResourceNotFoundException copyWith({
    _ip6hy6rf.MissingResource? resource,
    String? message,
  }) {
    return ResourceNotFoundException(
      resource: resource ?? this.resource,
      message: message ?? this.message,
    );
  }
}
