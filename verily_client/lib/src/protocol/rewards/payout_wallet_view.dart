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

abstract class PayoutWalletView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PayoutWalletView._({
    required this.walletAddress,
    required this.label,
    required this.linkedAt,
  });

  factory PayoutWalletView({
    required String walletAddress,
    required String label,
    required DateTime linkedAt,
  }) = _PayoutWalletViewImpl;

  factory PayoutWalletView.fromJson(Map<String, dynamic> jsonSerialization) {
    return PayoutWalletView(
      walletAddress: jsonSerialization['walletAddress'] as String,
      label: jsonSerialization['label'] as String,
      linkedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['linkedAt'],
      ),
    );
  }

  String walletAddress;

  String label;

  DateTime linkedAt;

  /// Returns a shallow copy of this [PayoutWalletView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PayoutWalletView copyWith({
    String? walletAddress,
    String? label,
    DateTime? linkedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PayoutWalletView',
      'walletAddress': walletAddress,
      'label': label,
      'linkedAt': linkedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PayoutWalletView',
      'walletAddress': walletAddress,
      'label': label,
      'linkedAt': linkedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _PayoutWalletViewImpl extends PayoutWalletView {
  _PayoutWalletViewImpl({
    required String walletAddress,
    required String label,
    required DateTime linkedAt,
  }) : super._(walletAddress: walletAddress, label: label, linkedAt: linkedAt);

  /// Returns a shallow copy of this [PayoutWalletView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PayoutWalletView copyWith({
    String? walletAddress,
    String? label,
    DateTime? linkedAt,
  }) {
    return PayoutWalletView(
      walletAddress: walletAddress ?? this.walletAddress,
      label: label ?? this.label,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }
}
