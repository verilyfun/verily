import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/core/token_amount.dart';

void main() {
  TokenAmount usdc(int atoms) =>
      TokenAmount(atoms: atoms, decimals: 6, symbol: 'USDC');

  test('formats whole and fractional amounts without trailing zeros', () {
    expect(usdc(5000000).format('en'), '5 USDC');
    expect(usdc(250000).format('en'), '0.25 USDC');
    expect(usdc(1).format('en'), '0.000001 USDC');
    expect(usdc(1234500000).format('en'), '1,234.5 USDC');
  });

  test('a budget is the payout times the number of payouts', () {
    expect((usdc(2500000) * 20).format('en'), '50 USDC');
  });

  test('parses what a creator types into exact atoms', () {
    TokenAmount? parse(String text) =>
        TokenAmount.tryParse(text, decimals: 6, symbol: 'USDC');

    expect(parse('5'), usdc(5000000));
    expect(parse(' 0.25 '), usdc(250000));
    expect(parse('1,000.5'), usdc(1000500000));
    expect(parse('0.000001'), usdc(1));
  });

  test('refuses anything that is not a positive amount it can hold', () {
    TokenAmount? parse(String text) =>
        TokenAmount.tryParse(text, decimals: 6, symbol: 'USDC');

    for (final text in ['', '0', '0.0', '-1', '1.0000001', 'five', '1e3']) {
      expect(parse(text), isNull, reason: text);
    }
  });
}
