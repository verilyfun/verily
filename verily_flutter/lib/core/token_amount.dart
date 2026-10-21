import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// An amount of a reward token, kept in its smallest unit ("atoms").
///
/// Rewards are paid in an SPL token (USDC by default, 6 decimals). Amounts
/// travel as integers so nothing is lost to floating point; they are only
/// turned into decimal text for display or parsed from what a creator typed.
@immutable
class TokenAmount {
  const TokenAmount({
    required this.atoms,
    required this.decimals,
    required this.symbol,
  }) : assert(atoms >= 0, 'atoms must not be negative'),
       assert(decimals >= 0 && decimals <= 18, 'decimals out of range');

  final int atoms;
  final int decimals;
  final String symbol;

  /// The amount as plain decimal text with no trailing zeros, such as `5` or
  /// `0.25`, in [locale]'s number format.
  String formatValue(String locale) {
    final format = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = decimals;
    return format.format(_asDecimal);
  }

  /// The amount with its symbol, such as `5 USDC`.
  String format(String locale) => '${formatValue(locale)} $symbol';

  TokenAmount operator *(int count) =>
      TokenAmount(atoms: atoms * count, decimals: decimals, symbol: symbol);

  // Integer and fractional parts are combined as text so large amounts keep
  // every digit; num.parse of the result is exact for display purposes.
  num get _asDecimal {
    if (decimals == 0) return atoms;
    final digits = atoms.toString().padLeft(decimals + 1, '0');
    final whole = digits.substring(0, digits.length - decimals);
    final fraction = digits.substring(digits.length - decimals);
    return num.parse('$whole.$fraction');
  }

  /// Parses what a person typed (`5`, `0.25`, `1,000.5` in English) into
  /// atoms. Returns null when the text is not a positive amount with at most
  /// [decimals] places.
  static TokenAmount? tryParse(
    String text, {
    required int decimals,
    required String symbol,
    String locale = 'en',
  }) {
    final symbols = NumberFormat.decimalPattern(locale).symbols;
    final cleaned = text
        .trim()
        .replaceAll(symbols.GROUP_SEP, '')
        .replaceAll(symbols.DECIMAL_SEP, '.');
    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(cleaned);
    if (match == null) return null;
    final whole = match.group(1)!;
    final fraction = match.group(2) ?? '';
    if (fraction.length > decimals) return null;
    final atoms = int.tryParse(
      '$whole${fraction.padRight(decimals, '0')}',
    );
    if (atoms == null || atoms <= 0) return null;
    return TokenAmount(atoms: atoms, decimals: decimals, symbol: symbol);
  }

  @override
  bool operator ==(Object other) =>
      other is TokenAmount &&
      other.atoms == atoms &&
      other.decimals == decimals &&
      other.symbol == symbol;

  @override
  int get hashCode => Object.hash(atoms, decimals, symbol);

  @override
  String toString() => 'TokenAmount($atoms, $decimals, $symbol)';
}

/// The reward token new actions use until the server says otherwise.
abstract final class DefaultRewardToken {
  static const symbol = 'USDC';
  static const decimals = 6;
}
