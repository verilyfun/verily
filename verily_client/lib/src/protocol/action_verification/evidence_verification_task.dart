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

abstract class EvidenceVerificationTask
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  EvidenceVerificationTask._({required this.evidenceId});

  factory EvidenceVerificationTask({required _isc.UuidValue evidenceId}) =
      _EvidenceVerificationTaskImpl;

  factory EvidenceVerificationTask.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EvidenceVerificationTask(
      evidenceId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['evidenceId'],
      ),
    );
  }

  _isc.UuidValue evidenceId;

  /// Returns a shallow copy of this [EvidenceVerificationTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  EvidenceVerificationTask copyWith({_isc.UuidValue? evidenceId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceVerificationTask',
      'evidenceId': evidenceId.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'EvidenceVerificationTask',
      'evidenceId': evidenceId.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _EvidenceVerificationTaskImpl extends EvidenceVerificationTask {
  _EvidenceVerificationTaskImpl({required _isc.UuidValue evidenceId})
    : super._(evidenceId: evidenceId);

  /// Returns a shallow copy of this [EvidenceVerificationTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  EvidenceVerificationTask copyWith({_isc.UuidValue? evidenceId}) {
    return EvidenceVerificationTask(evidenceId: evidenceId ?? this.evidenceId);
  }
}
