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

/// The exact text the wallet must sign.
abstract class PayoutWalletLinkChallengeView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PayoutWalletLinkChallengeView._({
    required this.walletAddress,
    required this.message,
    required this.nonce,
    required this.expiresAt,
  });

  factory PayoutWalletLinkChallengeView({
    required String walletAddress,
    required String message,
    required String nonce,
    required DateTime expiresAt,
  }) = _PayoutWalletLinkChallengeViewImpl;

  factory PayoutWalletLinkChallengeView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PayoutWalletLinkChallengeView(
      walletAddress: jsonSerialization['walletAddress'] as String,
      message: jsonSerialization['message'] as String,
      nonce: jsonSerialization['nonce'] as String,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  String walletAddress;

  String message;

  String nonce;

  DateTime expiresAt;

  /// Returns a shallow copy of this [PayoutWalletLinkChallengeView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PayoutWalletLinkChallengeView copyWith({
    String? walletAddress,
    String? message,
    String? nonce,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PayoutWalletLinkChallengeView',
      'walletAddress': walletAddress,
      'message': message,
      'nonce': nonce,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PayoutWalletLinkChallengeView',
      'walletAddress': walletAddress,
      'message': message,
      'nonce': nonce,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PayoutWalletLinkChallengeViewImpl extends PayoutWalletLinkChallengeView {
  _PayoutWalletLinkChallengeViewImpl({
    required String walletAddress,
    required String message,
    required String nonce,
    required DateTime expiresAt,
  }) : super._(
         walletAddress: walletAddress,
         message: message,
         nonce: nonce,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [PayoutWalletLinkChallengeView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PayoutWalletLinkChallengeView copyWith({
    String? walletAddress,
    String? message,
    String? nonce,
    DateTime? expiresAt,
  }) {
    return PayoutWalletLinkChallengeView(
      walletAddress: walletAddress ?? this.walletAddress,
      message: message ?? this.message,
      nonce: nonce ?? this.nonce,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
