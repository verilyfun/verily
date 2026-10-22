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

/// The challenge an iPhone attests its App Attest key against.
abstract class AppAttestChallengeView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AppAttestChallengeView._({
    required this.id,
    required this.challenge,
    required this.expiresAt,
  });

  factory AppAttestChallengeView({
    required _is.UuidValue id,
    required String challenge,
    required DateTime expiresAt,
  }) = _AppAttestChallengeViewImpl;

  factory AppAttestChallengeView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AppAttestChallengeView(
      id: _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      challenge: jsonSerialization['challenge'] as String,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  _is.UuidValue id;

  /// 32 random bytes, unpadded base64url. Pass `SHA-256(these bytes)` to
  /// `attestKey` as `clientDataHash`.
  String challenge;

  DateTime expiresAt;

  /// Returns a shallow copy of this [AppAttestChallengeView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppAttestChallengeView copyWith({
    _is.UuidValue? id,
    String? challenge,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppAttestChallengeView',
      'id': id.toJson(),
      'challenge': challenge,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppAttestChallengeView',
      'id': id.toJson(),
      'challenge': challenge,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _AppAttestChallengeViewImpl extends AppAttestChallengeView {
  _AppAttestChallengeViewImpl({
    required _is.UuidValue id,
    required String challenge,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         challenge: challenge,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [AppAttestChallengeView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppAttestChallengeView copyWith({
    _is.UuidValue? id,
    String? challenge,
    DateTime? expiresAt,
  }) {
    return AppAttestChallengeView(
      id: id ?? this.id,
      challenge: challenge ?? this.challenge,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
