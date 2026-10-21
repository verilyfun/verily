import 'package:flutter/services.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';

/// Loads the Skribble faces the theme letters with, so a test can measure
/// with the metrics a phone uses rather than the square test font.
Future<void> loadSkribbleFaces() async {
  const package = 'packages/skribble_font_recursive/assets/fonts';
  for (final (family, typeface, weights) in [
    (
      verilyDisplayFontFamily,
      verilyDisplayTypeface,
      ['Regular', 'Bold', 'ExtraBold'],
    ),
    (verilyTextFontFamily, verilyTextTypeface, ['Medium', 'Bold']),
    (verilyNumeralFontFamily, verilyNumeralTypeface, ['SemiBold']),
  ]) {
    final loader = FontLoader(family);
    for (final weight in weights) {
      loader.addFont(rootBundle.load('$package/$typeface-$weight.ttf'));
    }
    await loader.load();
  }
}
