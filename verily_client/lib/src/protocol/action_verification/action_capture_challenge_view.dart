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

/// Opens a capture window before the camera, microphone, or sensors start.
abstract class ActionCaptureChallengeView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActionCaptureChallengeView._({
    required this.id,
    required this.captureChallenge,
    required this.issuedAt,
    required this.expiresAt,
    required this.integrityRequired,
    bool? signatureRequired,
  }) : signatureRequired = signatureRequired ?? false;

  factory ActionCaptureChallengeView({
    required _isc.UuidValue id,
    required String captureChallenge,
    required DateTime issuedAt,
    required DateTime expiresAt,
    required bool integrityRequired,
    bool? signatureRequired,
  }) = _ActionCaptureChallengeViewImpl;

  factory ActionCaptureChallengeView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionCaptureChallengeView(
      id: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      captureChallenge: jsonSerialization['captureChallenge'] as String,
      issuedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['issuedAt'],
      ),
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

  /// 32 random bytes, unpadded base64url. The app generates a fresh capture
  /// key whose attestation challenge is SHA-256(these bytes ‖ attemptId).
  String captureChallenge;

  DateTime issuedAt;

  DateTime expiresAt;

  bool integrityRequired;

  bool signatureRequired;

  /// Returns a shallow copy of this [ActionCaptureChallengeView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionCaptureChallengeView copyWith({
    _isc.UuidValue? id,
    String? captureChallenge,
    DateTime? issuedAt,
    DateTime? expiresAt,
    bool? integrityRequired,
    bool? signatureRequired,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionCaptureChallengeView',
      'id': id.toJson(),
      'captureChallenge': captureChallenge,
      'issuedAt': issuedAt.toJson(),
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
      'captureChallenge': captureChallenge,
      'issuedAt': issuedAt.toJson(),
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
    required String captureChallenge,
    required DateTime issuedAt,
    required DateTime expiresAt,
    required bool integrityRequired,
    bool? signatureRequired,
  }) : super._(
         id: id,
         captureChallenge: captureChallenge,
         issuedAt: issuedAt,
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
    String? captureChallenge,
    DateTime? issuedAt,
    DateTime? expiresAt,
    bool? integrityRequired,
    bool? signatureRequired,
  }) {
    return ActionCaptureChallengeView(
      id: id ?? this.id,
      captureChallenge: captureChallenge ?? this.captureChallenge,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      integrityRequired: integrityRequired ?? this.integrityRequired,
      signatureRequired: signatureRequired ?? this.signatureRequired,
    );
  }
}
