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

/// Staff-facing durable device restrictions. Raw DeviceCheck tokens are never stored.
abstract class DeviceCheckBits
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DeviceCheckBits._({
    required this.banned,
    required this.reviewRequired,
  });

  factory DeviceCheckBits({
    required bool banned,
    required bool reviewRequired,
  }) = _DeviceCheckBitsImpl;

  factory DeviceCheckBits.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceCheckBits(
      banned: _is.BoolJsonExtension.fromJson(jsonSerialization['banned']),
      reviewRequired: _is.BoolJsonExtension.fromJson(
        jsonSerialization['reviewRequired'],
      ),
    );
  }

  bool banned;

  bool reviewRequired;

  /// Returns a shallow copy of this [DeviceCheckBits]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DeviceCheckBits copyWith({
    bool? banned,
    bool? reviewRequired,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceCheckBits',
      'banned': banned,
      'reviewRequired': reviewRequired,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeviceCheckBits',
      'banned': banned,
      'reviewRequired': reviewRequired,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DeviceCheckBitsImpl extends DeviceCheckBits {
  _DeviceCheckBitsImpl({
    required bool banned,
    required bool reviewRequired,
  }) : super._(
         banned: banned,
         reviewRequired: reviewRequired,
       );

  /// Returns a shallow copy of this [DeviceCheckBits]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DeviceCheckBits copyWith({
    bool? banned,
    bool? reviewRequired,
  }) {
    return DeviceCheckBits(
      banned: banned ?? this.banned,
      reviewRequired: reviewRequired ?? this.reviewRequired,
    );
  }
}
