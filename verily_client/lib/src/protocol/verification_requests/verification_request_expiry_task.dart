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

abstract class VerificationRequestExpiryTask
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  VerificationRequestExpiryTask._({required this.batchSize});

  factory VerificationRequestExpiryTask({required int batchSize}) =
      _VerificationRequestExpiryTaskImpl;

  factory VerificationRequestExpiryTask.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return VerificationRequestExpiryTask(
      batchSize: jsonSerialization['batchSize'] as int,
    );
  }

  int batchSize;

  /// Returns a shallow copy of this [VerificationRequestExpiryTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  VerificationRequestExpiryTask copyWith({int? batchSize});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerificationRequestExpiryTask',
      'batchSize': batchSize,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerificationRequestExpiryTask',
      'batchSize': batchSize,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _VerificationRequestExpiryTaskImpl extends VerificationRequestExpiryTask {
  _VerificationRequestExpiryTaskImpl({required int batchSize})
    : super._(batchSize: batchSize);

  /// Returns a shallow copy of this [VerificationRequestExpiryTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  VerificationRequestExpiryTask copyWith({int? batchSize}) {
    return VerificationRequestExpiryTask(
      batchSize: batchSize ?? this.batchSize,
    );
  }
}
