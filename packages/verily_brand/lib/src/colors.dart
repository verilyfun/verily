import 'package:flutter/painting.dart';

import 'package:verily_brand/src/geometry.dart';

/// Verily's colour tokens: the only place brand colours are written down.
///
/// Paper, night, ink, and the washes are Skribble's own, so Verily sits on
/// the same paper as every Skribble widget. Stamp vermilion is Verily's: the
/// ink of the check, the mark, and the verified stamp. Each role accent has a
/// wash for the surfaces behind it.
///
/// Contrast ratios are WCAG 2.2 against the surface named. Accents that fall
/// below 4.5:1 on a surface are for large text, icons, and strokes there, not
/// body text.
abstract final class VerilyBrandColors {
  /// Light paper, `#FFFAF0`: the field notebook's page and every light
  /// surface.
  static const Color paper = Color(0xFFFFFAF0);

  /// Night paper, `#292331`: the dark-mode page. Paper on night is 14.64:1.
  static const Color night = Color(0xFF292331);

  /// Plum ink, `#34283F`: text and outlines on paper (13.27:1), and the
  /// letters "erily" in the wordmark.
  static const Color ink = Color(0xFF34283F);

  /// Muted ink, `#736678`: secondary text on paper (5.17:1).
  static const Color mutedInk = Color(0xFF736678);

  /// Muted paper, `#B9ACBF`: secondary text on night (7.05:1).
  static const Color mutedPaper = Color(0xFFB9ACBF);

  /// Dusk, `#4A3B5E`: Skribble's evening wash for fills and selections on
  /// night paper.
  static const Color dusk = Color(0xFF4A3B5E);

  /// Stamp vermilion, `#D13F22`: the check, the mark, the i-dot, and the
  /// verified stamp. 4.54:1 on paper, and paper on vermilion is the same, so
  /// it passes AA for text both ways. Reserved for verification and the brand;
  /// never for errors.
  static const Color stamp = Color(0xFFD13F22);

  /// Night vermilion, `#F2856A`: stamp vermilion on night paper (6.05:1).
  /// Plain vermilion is only 3.22:1 there.
  static const Color stampOnNight = Color(0xFFF2856A);

  /// Place green, `#2F6B4F`: pins, radius circles, and "inside the place"
  /// (6.05:1 on paper, 5.05:1 on [placeWash]).
  static const Color place = Color(0xFF2F6B4F);

  /// Sage wash, `#DDEAD9`: the hatched radius and place chips. Ink on sage is
  /// 11.07:1.
  static const Color placeWash = Color(0xFFDDEAD9);

  /// Place green on night, `#86C7A0` (7.75:1).
  static const Color placeOnNight = Color(0xFF86C7A0);

  /// Reward gold, `#9A6A12`: escrowed rewards, coins, and the jar (4.54:1 on
  /// paper). On [rewardWash] it is 3.84:1, so put ink text on the wash and
  /// keep gold for the coin, icons, and large amounts.
  static const Color reward = Color(0xFF9A6A12);

  /// Butter wash, `#F6E8AF`: reward chips and the escrow jar. Ink on butter
  /// is 11.23:1.
  static const Color rewardWash = Color(0xFFF6E8AF);

  /// Reward gold on night, `#E6BC5C` (8.49:1).
  static const Color rewardOnNight = Color(0xFFE6BC5C);

  /// Review violet, `#6B4FA0`: proof waiting for a person, and appeals
  /// (6.21:1 on paper, 4.92:1 on [reviewWash]).
  static const Color review = Color(0xFF6B4FA0);

  /// Lilac wash, `#E5DDF4`: review chips and selection markers. Ink on lilac
  /// is 10.50:1.
  static const Color reviewWash = Color(0xFFE5DDF4);

  /// Review violet on night, `#BBA6EC` (7.09:1).
  static const Color reviewOnNight = Color(0xFFBBA6EC);

  /// The brand ink for [ink] on light paper.
  static Color onPaper(BrandInk ink) => switch (ink) {
    BrandInk.accent => stamp,
    BrandInk.body => VerilyBrandColors.ink,
  };

  /// The brand ink for [ink] on night paper.
  static Color onNight(BrandInk ink) => switch (ink) {
    BrandInk.accent => stampOnNight,
    BrandInk.body => paper,
  };
}
