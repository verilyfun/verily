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

/// The creator's reward terms. The token, its decimals, the cluster, and the
/// arbiter come from server configuration, never from this draft.
abstract class RewardTermsDraft
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RewardTermsDraft._({
    required this.amountPerPayout,
    required this.maxPayouts,
    int? maxWinsPerAccount,
    required this.expiresAt,
    int? refundDelayDays,
  }) : maxWinsPerAccount = maxWinsPerAccount ?? 1,
       refundDelayDays = refundDelayDays ?? 7;

  factory RewardTermsDraft({
    required int amountPerPayout,
    required int maxPayouts,
    int? maxWinsPerAccount,
    required DateTime expiresAt,
    int? refundDelayDays,
  }) = _RewardTermsDraftImpl;

  factory RewardTermsDraft.fromJson(Map<String, dynamic> jsonSerialization) {
    return RewardTermsDraft(
      amountPerPayout: jsonSerialization['amountPerPayout'] as int,
      maxPayouts: jsonSerialization['maxPayouts'] as int,
      maxWinsPerAccount: jsonSerialization['maxWinsPerAccount'] as int?,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      refundDelayDays: jsonSerialization['refundDelayDays'] as int?,
    );
  }

  /// Token atoms paid per verified completion.
  int amountPerPayout;

  /// How many completions can be paid (1 to 2048).
  int maxPayouts;

  /// Most payouts one account can receive (1 to 365).
  int maxWinsPerAccount;

  /// No new completions are paid after this instant.
  DateTime expiresAt;

  /// Days after expiry before the creator can reclaim the rest (3 to 30).
  int refundDelayDays;

  /// Returns a shallow copy of this [RewardTermsDraft]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RewardTermsDraft copyWith({
    int? amountPerPayout,
    int? maxPayouts,
    int? maxWinsPerAccount,
    DateTime? expiresAt,
    int? refundDelayDays,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RewardTermsDraft',
      'amountPerPayout': amountPerPayout,
      'maxPayouts': maxPayouts,
      'maxWinsPerAccount': maxWinsPerAccount,
      'expiresAt': expiresAt.toJson(),
      'refundDelayDays': refundDelayDays,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RewardTermsDraft',
      'amountPerPayout': amountPerPayout,
      'maxPayouts': maxPayouts,
      'maxWinsPerAccount': maxWinsPerAccount,
      'expiresAt': expiresAt.toJson(),
      'refundDelayDays': refundDelayDays,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RewardTermsDraftImpl extends RewardTermsDraft {
  _RewardTermsDraftImpl({
    required int amountPerPayout,
    required int maxPayouts,
    int? maxWinsPerAccount,
    required DateTime expiresAt,
    int? refundDelayDays,
  }) : super._(
         amountPerPayout: amountPerPayout,
         maxPayouts: maxPayouts,
         maxWinsPerAccount: maxWinsPerAccount,
         expiresAt: expiresAt,
         refundDelayDays: refundDelayDays,
       );

  /// Returns a shallow copy of this [RewardTermsDraft]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RewardTermsDraft copyWith({
    int? amountPerPayout,
    int? maxPayouts,
    int? maxWinsPerAccount,
    DateTime? expiresAt,
    int? refundDelayDays,
  }) {
    return RewardTermsDraft(
      amountPerPayout: amountPerPayout ?? this.amountPerPayout,
      maxPayouts: maxPayouts ?? this.maxPayouts,
      maxWinsPerAccount: maxWinsPerAccount ?? this.maxWinsPerAccount,
      expiresAt: expiresAt ?? this.expiresAt,
      refundDelayDays: refundDelayDays ?? this.refundDelayDays,
    );
  }
}
