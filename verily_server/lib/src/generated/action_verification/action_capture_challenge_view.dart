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

abstract class ActionCaptureChallengeView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ActionCaptureChallengeView._({
    required this.id,
    required this.requestHash,
    required this.expiresAt,
    required this.integrityRequired,
    bool? signatureRequired,
  }) : signatureRequired = signatureRequired ?? false;

  factory ActionCaptureChallengeView({
    required _is.UuidValue id,
    required String requestHash,
    required DateTime expiresAt,
    required bool integrityRequired,
    bool? signatureRequired,
  }) = _ActionCaptureChallengeViewImpl;

  factory ActionCaptureChallengeView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionCaptureChallengeView(
      id: _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      requestHash: jsonSerialization['requestHash'] as String,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      integrityRequired: _is.BoolJsonExtension.fromJson(
        jsonSerialization['integrityRequired'],
      ),
      signatureRequired: jsonSerialization['signatureRequired'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['signatureRequired'],
            ),
    );
  }

  _is.UuidValue id;

  String requestHash;

  DateTime expiresAt;

  bool integrityRequired;

  bool signatureRequired;

  /// Returns a shallow copy of this [ActionCaptureChallengeView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionCaptureChallengeView copyWith({
    _is.UuidValue? id,
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
    return _is.SerializationManager.encode(this);
  }
}

class _ActionCaptureChallengeViewImpl extends ActionCaptureChallengeView {
  _ActionCaptureChallengeViewImpl({
    required _is.UuidValue id,
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
  @_is.useResult
  @override
  ActionCaptureChallengeView copyWith({
    _is.UuidValue? id,
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
