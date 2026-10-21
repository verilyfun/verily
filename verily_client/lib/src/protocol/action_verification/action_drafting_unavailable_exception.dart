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

/// AI-assisted drafting is not available right now (no AI key configured,
/// AI paused, or the daily allowance is used). Templates still work.
abstract class ActionDraftingUnavailableException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  ActionDraftingUnavailableException._({required this.message});

  factory ActionDraftingUnavailableException({required String message}) =
      _ActionDraftingUnavailableExceptionImpl;

  factory ActionDraftingUnavailableException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionDraftingUnavailableException(
      message: jsonSerialization['message'] as String,
    );
  }

  String message;

  /// Returns a shallow copy of this [ActionDraftingUnavailableException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionDraftingUnavailableException copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionDraftingUnavailableException',
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionDraftingUnavailableException',
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ActionDraftingUnavailableException(message: $message)';
  }
}

class _ActionDraftingUnavailableExceptionImpl
    extends ActionDraftingUnavailableException {
  _ActionDraftingUnavailableExceptionImpl({required String message})
    : super._(message: message);

  /// Returns a shallow copy of this [ActionDraftingUnavailableException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActionDraftingUnavailableException copyWith({String? message}) {
    return ActionDraftingUnavailableException(message: message ?? this.message);
  }
}
