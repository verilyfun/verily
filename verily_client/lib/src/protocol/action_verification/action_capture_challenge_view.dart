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

abstract class ActionCaptureChallengeView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActionCaptureChallengeView._({
    required this.id,
    required this.requestHash,
    required this.expiresAt,
    required this.integrityRequired,
    bool? signatureRequired,
  }) : signatureRequired = signatureRequired ?? false;

  factory ActionCaptureChallengeView({
    required _isc.UuidValue id,
    required String requestHash,
    required DateTime expiresAt,
    required bool integrityRequired,
    bool? signatureRequired,
  }) = _ActionCaptureChallengeViewImpl;

  factory ActionCaptureChallengeView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionCaptureChallengeView(
      id: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      requestHash: jsonSerialization['requestHash'] as String,
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      integrityRequired: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['integrityRequired'],
      ),
      signatureRequired: jsonSerialization['signatureRequired'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['signatureRequired'],
            ),
    );
  }

  _isc.UuidValue id;

  String requestHash;

  DateTime expiresAt;

  bool integrityRequired;

  bool signatureRequired;

  /// Returns a shallow copy of this [ActionCaptureChallengeView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionCaptureChallengeView copyWith({
    _isc.UuidValue? id,
    String? requestHash,
    DateTime? expiresAt,
    bool? integrityRequired,
    bool? signatureRequired,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionCaptureChallengeView',
      'id': id.toJson(),
      'requestHash': requestHash,
      'expiresAt': expiresAt.toJson(),
      'integrityRequired': integrityRequired,
      'signatureRequired': signatureRequired,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionCaptureChallengeView',
      'id': id.toJson(),
      'requestHash': requestHash,
      'expiresAt': expiresAt.toJson(),
      'integrityRequired': integrityRequired,
      'signatureRequired': signatureRequired,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ActionCaptureChallengeViewImpl extends ActionCaptureChallengeView {
  _ActionCaptureChallengeViewImpl({
    required _isc.UuidValue id,
    required String requestHash,
    required DateTime expiresAt,
    required bool integrityRequired,
    bool? signatureRequired,
  }) : super._(
         id: id,
         requestHash: requestHash,
         expiresAt: expiresAt,
         integrityRequired: integrityRequired,
         signatureRequired: signatureRequired,
       );

  /// Returns a shallow copy of this [ActionCaptureChallengeView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActionCaptureChallengeView copyWith({
    _isc.UuidValue? id,
    String? requestHash,
    DateTime? expiresAt,
    bool? integrityRequired,
    bool? signatureRequired,
  }) {
    return ActionCaptureChallengeView(
      id: id ?? this.id,
      requestHash: requestHash ?? this.requestHash,
      expiresAt: expiresAt ?? this.expiresAt,
      integrityRequired: integrityRequired ?? this.integrityRequired,
      signatureRequired: signatureRequired ?? this.signatureRequired,
    );
  }
}
