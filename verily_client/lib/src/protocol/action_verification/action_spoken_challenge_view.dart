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

/// What the app shows before recording: "Say 'pelican' while you record".
abstract class ActionSpokenChallengeView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActionSpokenChallengeView._({
    required this.id,
    required this.word,
    required this.expiresAt,
  });

  factory ActionSpokenChallengeView({
    required _isc.UuidValue id,
    required String word,
    required DateTime expiresAt,
  }) = _ActionSpokenChallengeViewImpl;

  factory ActionSpokenChallengeView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionSpokenChallengeView(
      id: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      word: jsonSerialization['word'] as String,
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  _isc.UuidValue id;

  String word;

  DateTime expiresAt;

  /// Returns a shallow copy of this [ActionSpokenChallengeView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionSpokenChallengeView copyWith({
    _isc.UuidValue? id,
    String? word,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionSpokenChallengeView',
      'id': id.toJson(),
      'word': word,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionSpokenChallengeView',
      'id': id.toJson(),
      'word': word,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ActionSpokenChallengeViewImpl extends ActionSpokenChallengeView {
  _ActionSpokenChallengeViewImpl({
    required _isc.UuidValue id,
    required String word,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         word: word,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [ActionSpokenChallengeView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActionSpokenChallengeView copyWith({
    _isc.UuidValue? id,
    String? word,
    DateTime? expiresAt,
  }) {
    return ActionSpokenChallengeView(
      id: id ?? this.id,
      word: word ?? this.word,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
