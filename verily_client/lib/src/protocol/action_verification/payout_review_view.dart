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

/// What a reviewer sees about proof held because its payout needs a person.
abstract class PayoutReviewView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PayoutReviewView._({
    required this.amountPerPayout,
    required this.tokenSymbol,
    required this.decimals,
    required this.thresholdAtoms,
  });

  factory PayoutReviewView({
    required int amountPerPayout,
    required String tokenSymbol,
    required int decimals,
    required int thresholdAtoms,
  }) = _PayoutReviewViewImpl;

  factory PayoutReviewView.fromJson(Map<String, dynamic> jsonSerialization) {
    return PayoutReviewView(
      amountPerPayout: jsonSerialization['amountPerPayout'] as int,
      tokenSymbol: jsonSerialization['tokenSymbol'] as String,
      decimals: jsonSerialization['decimals'] as int,
      thresholdAtoms: jsonSerialization['thresholdAtoms'] as int,
    );
  }

  int amountPerPayout;

  String tokenSymbol;

  int decimals;

  int thresholdAtoms;

  /// Returns a shallow copy of this [PayoutReviewView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PayoutReviewView copyWith({
    int? amountPerPayout,
    String? tokenSymbol,
    int? decimals,
    int? thresholdAtoms,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PayoutReviewView',
      'amountPerPayout': amountPerPayout,
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'thresholdAtoms': thresholdAtoms,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PayoutReviewView',
      'amountPerPayout': amountPerPayout,
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'thresholdAtoms': thresholdAtoms,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _PayoutReviewViewImpl extends PayoutReviewView {
  _PayoutReviewViewImpl({
    required int amountPerPayout,
    required String tokenSymbol,
    required int decimals,
    required int thresholdAtoms,
  }) : super._(
         amountPerPayout: amountPerPayout,
         tokenSymbol: tokenSymbol,
         decimals: decimals,
         thresholdAtoms: thresholdAtoms,
       );

  /// Returns a shallow copy of this [PayoutReviewView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PayoutReviewView copyWith({
    int? amountPerPayout,
    String? tokenSymbol,
    int? decimals,
    int? thresholdAtoms,
  }) {
    return PayoutReviewView(
      amountPerPayout: amountPerPayout ?? this.amountPerPayout,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      decimals: decimals ?? this.decimals,
      thresholdAtoms: thresholdAtoms ?? this.thresholdAtoms,
    );
  }
}
