import 'package:flutter/material.dart';

import 'package:skribble/skribble.dart';
import 'package:verily_brand/verily_brand.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_pen.dart';
import 'package:verily_flutter/app/theme/verily_rough_border.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';

/// Every colour the theme draws with.
///
/// Brand colours come from `VerilyBrandColors` in `package:verily_brand`, the
/// one place they are written down (with their roles and contrast ratios).
/// The theme adds only what the brand does not define: Skribble's peach wash
/// for quiet daytime selections, and the scrim black and clear needed by
/// Material. Every pair that carries text is checked against WCAG 2.2 AA in the
/// theme tests. Nothing outside this file names a colour value.
abstract final class _Swatch {
  static const Color paper = VerilyBrandColors.paper;
  static const Color night = VerilyBrandColors.night;
  static const Color ink = VerilyBrandColors.ink;
  static const Color mutedInk = VerilyBrandColors.mutedInk;
  static const Color mutedPaper = VerilyBrandColors.mutedPaper;
  static const Color dusk = VerilyBrandColors.dusk;
  static const Color stamp = VerilyBrandColors.stamp;
  static const Color stampOnNight = VerilyBrandColors.stampOnNight;
  static const Color place = VerilyBrandColors.place;
  static const Color placeWash = VerilyBrandColors.placeWash;
  static const Color placeOnNight = VerilyBrandColors.placeOnNight;
  static const Color reward = VerilyBrandColors.reward;
  static const Color rewardWash = VerilyBrandColors.rewardWash;
  static const Color rewardOnNight = VerilyBrandColors.rewardOnNight;
  static const Color review = VerilyBrandColors.review;
  static const Color reviewWash = VerilyBrandColors.reviewWash;
  static const Color reviewOnNight = VerilyBrandColors.reviewOnNight;

  /// Skribble's peach: the quiet daytime wash for selections and active
  /// tracks. Not a brand colour, so it is not in `VerilyBrandColors`.
  static const Color peach = WiredPalette.peach;

  static const black = Color(0xFF000000);
  static const clear = Color(0x00000000);
}

/// Colours that stay the same in light and dark mode.
///
/// App code reaches for these only when a colour must not follow the theme:
/// the movement HUD draws over live camera footage rather than a themed
/// surface. Everything else reads `Theme.of(context).verily` or the
/// Material `colorScheme`.
abstract final class VerilyColors {
  static const Color transparent = _Swatch.clear;

  /// Modal scrims. Verily draws no shadows.
  static const Color shadow = _Swatch.black;

  // Live movement capture. These draw over camera footage rather than a
  // themed surface, so they stay fixed in light and dark mode. Vermilion is
  // kept for the verified stamp, so the HUD uses the night role inks.
  static const Color movementBone = _Swatch.paper;
  static const Color movementOutline = _Swatch.ink;
  static const Color movementJoint = _Swatch.placeOnNight;
  static const Color movementAtDepth = _Swatch.rewardOnNight;
  static const Color movementScrim = _Swatch.night;
  static const Color movementHudInk = _Swatch.paper;
  static const Color movementHudAccent = _Swatch.rewardOnNight;

  // Ball-skill fire effects, hottest first, plus the powered-up limb glow.
  static const Color movementFlameCore = _Swatch.paper;
  static const Color movementFlameHot = _Swatch.rewardWash;
  static const Color movementFlameWarm = _Swatch.rewardOnNight;
  static const Color movementFlameEdge = _Swatch.reward;
  static const Color movementPower = _Swatch.placeOnNight;
}

/// A meaning Verily gives a colour.
///
/// Each tone has a hue for icons, figures, and short labels on the page, and
/// a wash for fields that carry [VerilyPalette.ink]. Colour is never the only
/// signal: a toned element also names itself in words and a shape.
///
/// The stamp is not a tone. It marks verified proof and the brand only.
enum VerilyTone {
  /// No role: ink on the quiet highlight wash.
  neutral,

  /// Where an action happens: pins, radii, "inside the place".
  place,

  /// A reward and its escrow.
  reward,

  /// Proof waiting for a person, appeals, and anything a human decides.
  review,
}

/// Verily's semantic colour roles for the active brightness.
///
/// Read it with `Theme.of(context).verily`. Roles are named by purpose, so a
/// widget written against them follows light and dark mode without knowing
/// either palette.
///
/// Light mode is Skribble's paper with plum ink. Dark mode is Skribble's
/// night with paper ink; there every role takes its night ink and every wash
/// is dusk, the one fill on night paper.
@immutable
class VerilyPalette extends ThemeExtension<VerilyPalette> {
  const VerilyPalette({
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.mutedInk,
    required this.line,
    required this.action,
    required this.onAction,
    required this.highlight,
    required this.accent,
    required this.onAccent,
    required this.place,
    required this.placeWash,
    required this.reward,
    required this.rewardWash,
    required this.review,
    required this.reviewWash,
  });

  /// The light theme: Skribble paper.
  const VerilyPalette.paper()
    : canvas = _Swatch.paper,
      surface = _Swatch.paper,
      ink = _Swatch.ink,
      mutedInk = _Swatch.mutedInk,
      line = _Swatch.mutedPaper,
      action = _Swatch.ink,
      onAction = _Swatch.paper,
      highlight = _Swatch.peach,
      accent = _Swatch.stamp,
      onAccent = _Swatch.paper,
      place = _Swatch.place,
      placeWash = _Swatch.placeWash,
      reward = _Swatch.reward,
      rewardWash = _Swatch.rewardWash,
      review = _Swatch.review,
      reviewWash = _Swatch.reviewWash;

  /// The dark theme: Skribble night.
  const VerilyPalette.night()
    : canvas = _Swatch.night,
      surface = _Swatch.night,
      ink = _Swatch.paper,
      mutedInk = _Swatch.mutedPaper,
      line = _Swatch.dusk,
      action = _Swatch.paper,
      onAction = _Swatch.night,
      highlight = _Swatch.dusk,
      accent = _Swatch.stampOnNight,
      onAccent = _Swatch.night,
      place = _Swatch.placeOnNight,
      placeWash = _Swatch.dusk,
      reward = _Swatch.rewardOnNight,
      rewardWash = _Swatch.dusk,
      review = _Swatch.reviewOnNight,
      reviewWash = _Swatch.dusk;

  /// The page behind everything.
  final Color canvas;

  /// Cards, sheets, fields, and bars. Verily draws them on the same paper as
  /// the page and lets the pen outline separate them.
  final Color surface;

  /// Text, icons, and outlines. Readable on [canvas], [surface], and every
  /// wash.
  final Color ink;

  /// Secondary text. At least 4.5:1 on [surface].
  final Color mutedInk;

  /// Dividers and the outline of a disabled control. Decorative only.
  final Color line;

  /// The fill of the one deliberate next step on a page: inked, never
  /// vermilion.
  final Color action;

  /// Text and icons on an [action] fill.
  final Color onAction;

  /// The quiet wash under selections, active tracks, progress fills, and
  /// neutral invitations. Carries [ink].
  final Color highlight;

  /// The stamp: verified proof and the brand, and nothing else. Never an
  /// error, a warning, a promotion, or a button.
  final Color accent;

  /// Text and icons on an [accent] fill, such as a stamped badge.
  final Color onAccent;

  /// The place ink: pins, radii, and "inside the place".
  final Color place;

  final Color placeWash;

  /// The reward ink: escrowed amounts, coins, and payouts. On its wash it is
  /// for icons and large amounts; text there is [ink].
  final Color reward;

  final Color rewardWash;

  /// The review ink: proof with a person, appeals, and reviewer notes.
  final Color review;

  final Color reviewWash;

  /// The ink of [tone], for icons, figures, and short labels on the page.
  Color hue(VerilyTone tone) => switch (tone) {
    VerilyTone.neutral => ink,
    VerilyTone.place => place,
    VerilyTone.reward => reward,
    VerilyTone.review => review,
  };

  /// The wash of [tone]. Text on a wash uses [ink].
  Color wash(VerilyTone tone) => switch (tone) {
    VerilyTone.neutral => highlight,
    VerilyTone.place => placeWash,
    VerilyTone.reward => rewardWash,
    VerilyTone.review => reviewWash,
  };

  /// Whether this is the night palette.
  bool get isNight => surface.computeLuminance() < 0.3;

  /// The quiet pen around fields, quiet choices, and secondary controls.
  ///
  /// Strong enough to mark a control's edge at 3:1 on [surface] in both
  /// modes.
  Color get quietPen => ink.withValues(alpha: isNight ? 0.5 : 0.56);

  /// The firm pen around sheets, menus, and selected markers.
  Color get firmPen => ink.withValues(alpha: 0.78);

  /// [color] when it is readable as text on [surface], otherwise [ink].
  Color readableAccent(Color color) =>
      verilyContrastRatio(color, surface) >= 4.5 ? color : ink;

  @override
  VerilyPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? ink,
    Color? mutedInk,
    Color? line,
    Color? action,
    Color? onAction,
    Color? highlight,
    Color? accent,
    Color? onAccent,
    Color? place,
    Color? placeWash,
    Color? reward,
    Color? rewardWash,
    Color? review,
    Color? reviewWash,
  }) {
    return VerilyPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      mutedInk: mutedInk ?? this.mutedInk,
      line: line ?? this.line,
      action: action ?? this.action,
      onAction: onAction ?? this.onAction,
      highlight: highlight ?? this.highlight,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      place: place ?? this.place,
      placeWash: placeWash ?? this.placeWash,
      reward: reward ?? this.reward,
      rewardWash: rewardWash ?? this.rewardWash,
      review: review ?? this.review,
      reviewWash: reviewWash ?? this.reviewWash,
    );
  }

  @override
  VerilyPalette lerp(ThemeExtension<VerilyPalette>? other, double t) {
    if (other is! VerilyPalette) {
      return this;
    }

    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return VerilyPalette(
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      ink: mix(ink, other.ink),
      mutedInk: mix(mutedInk, other.mutedInk),
      line: mix(line, other.line),
      action: mix(action, other.action),
      onAction: mix(onAction, other.onAction),
      highlight: mix(highlight, other.highlight),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      place: mix(place, other.place),
      placeWash: mix(placeWash, other.placeWash),
      reward: mix(reward, other.reward),
      rewardWash: mix(rewardWash, other.rewardWash),
      review: mix(review, other.review),
      reviewWash: mix(reviewWash, other.reviewWash),
    );
  }
}

extension VerilyThemeX on ThemeData {
  /// The active [VerilyPalette]. Every theme built by [buildVerilyTheme]
  /// carries one.
  VerilyPalette get verily =>
      extension<VerilyPalette>() ??
      (brightness == Brightness.dark
          ? const VerilyPalette.night()
          : const VerilyPalette.paper());
}

/// Corner radii from `DESIGN.md`. The pen draws every one by hand.
abstract final class VerilyRadius {
  /// Buttons, fields, and other controls.
  static const double control = 6;

  /// Cards and panels.
  static const double card = 12;

  /// Chips and compact choices.
  static const double chip = 14;

  /// Sheets and dialogs.
  static const double sheet = 24;
}

/// The hand-lettered face for display lines, headlines, and titles.
const verilyDisplayTypeface = 'SkribblePlayful';

/// The calmer linear sibling for body text and labels.
const verilyTextTypeface = 'SkribbleLinearPlayful';

/// The monospaced sibling for amounts, codes, and counters.
const verilyNumeralTypeface = 'SkribbleMonoPlayful';

const _fontPackage = 'packages/skribble_font_recursive';

/// [verilyDisplayTypeface] in Flutter's resolved `packages/<package>/<family>`
/// form, ready for a [TextStyle.fontFamily].
const verilyDisplayFontFamily = '$_fontPackage/$verilyDisplayTypeface';

/// [verilyTextTypeface] in resolved form.
const verilyTextFontFamily = '$_fontPackage/$verilyTextTypeface';

/// [verilyNumeralTypeface] in resolved form. Material has no numeral role, so
/// amounts and codes apply it themselves.
const verilyNumeralFontFamily = '$_fontPackage/$verilyNumeralTypeface';

/// The type scale from `DESIGN.md`.
///
/// Display (800, 40–48, 1.08), headline (800, 24–32, 1.1), and title (700,
/// 18–22, 1.2) are hand-lettered; body (500, 16, 1.45) and label (700,
/// 13–15, 1.2) use the linear sibling so small text stays calm.
TextTheme _typeScale(TextTheme base, {required bool useAppTypeface}) {
  TextStyle? role(
    TextStyle? style, {
    required String family,
    required double size,
    required double height,
    required FontWeight weight,
  }) => style?.copyWith(
    fontFamily: useAppTypeface ? family : null,
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: 0,
  );

  TextStyle? display(TextStyle? style, double size) => role(
    style,
    family: verilyDisplayFontFamily,
    size: size,
    height: 1.08,
    weight: FontWeight.w800,
  );
  TextStyle? headline(TextStyle? style, double size) => role(
    style,
    family: verilyDisplayFontFamily,
    size: size,
    height: 1.1,
    weight: FontWeight.w800,
  );
  TextStyle? title(TextStyle? style, double size) => role(
    style,
    family: verilyDisplayFontFamily,
    size: size,
    height: 1.2,
    weight: FontWeight.w700,
  );
  TextStyle? body(TextStyle? style, double size) => role(
    style,
    family: verilyTextFontFamily,
    size: size,
    height: 1.45,
    weight: FontWeight.w500,
  );
  TextStyle? label(TextStyle? style, double size) => role(
    style,
    family: verilyTextFontFamily,
    size: size,
    height: 1.2,
    weight: FontWeight.w700,
  );

  return base.copyWith(
    displayLarge: display(base.displayLarge, 48),
    displayMedium: display(base.displayMedium, 44),
    displaySmall: display(base.displaySmall, 40),
    headlineLarge: headline(base.headlineLarge, 32),
    headlineMedium: headline(base.headlineMedium, 28),
    headlineSmall: headline(base.headlineSmall, 24),
    titleLarge: title(base.titleLarge, 22),
    titleMedium: title(base.titleMedium, 20),
    titleSmall: title(base.titleSmall, 18),
    bodyLarge: body(base.bodyLarge, 16),
    bodyMedium: body(base.bodyMedium, 16),
    bodySmall: body(base.bodySmall, 14),
    labelLarge: label(base.labelLarge, 15),
    labelMedium: label(base.labelMedium, 14),
    labelSmall: label(base.labelSmall, 13),
  );
}

/// Material's colour roles, mapped one by one from [palette].
///
/// Nothing is derived by `ColorScheme.fromSeed`: tonal guessing mutes the
/// paper and night and invents greys the design never draws. Primary is the
/// inked action, not the stamp, and problems are ink too: anything that wants
/// attention without being verified uses ink, weight, or a wash.
ColorScheme _colorScheme(VerilyPalette palette, Brightness brightness) {
  final inverse = brightness == Brightness.dark
      ? const VerilyPalette.paper()
      : const VerilyPalette.night();
  return ColorScheme(
    brightness: brightness,
    primary: palette.action,
    onPrimary: palette.onAction,
    primaryContainer: palette.highlight,
    onPrimaryContainer: palette.ink,
    secondary: palette.place,
    onSecondary: palette.surface,
    secondaryContainer: palette.placeWash,
    onSecondaryContainer: palette.ink,
    tertiary: palette.review,
    onTertiary: palette.surface,
    tertiaryContainer: palette.reviewWash,
    onTertiaryContainer: palette.ink,
    error: palette.ink,
    onError: palette.surface,
    errorContainer: palette.highlight,
    onErrorContainer: palette.ink,
    surface: palette.surface,
    onSurface: palette.ink,
    onSurfaceVariant: palette.mutedInk,
    surfaceDim: palette.surface,
    surfaceBright: palette.surface,
    surfaceContainerLowest: palette.canvas,
    surfaceContainerLow: palette.surface,
    surfaceContainer: palette.surface,
    surfaceContainerHigh: palette.surface,
    surfaceContainerHighest: palette.highlight,
    outline: palette.mutedInk,
    outlineVariant: palette.line,
    shadow: VerilyColors.shadow,
    scrim: VerilyColors.shadow,
    inverseSurface: inverse.surface,
    onInverseSurface: inverse.ink,
    inversePrimary: inverse.action,
    surfaceTint: VerilyColors.transparent,
  );
}

/// Builds Verily's paper (light) or night (dark) theme.
///
/// [useAppTypeface] applies the Skribble faces. Widget tests that measure
/// text pass `false` so Flutter's test font keeps metrics deterministic.
ThemeData buildVerilyTheme({
  Brightness brightness = Brightness.light,
  bool useAppTypeface = true,
}) {
  final palette = brightness == Brightness.dark
      ? const VerilyPalette.night()
      : const VerilyPalette.paper();
  final colorScheme = _colorScheme(palette, brightness);
  final baseTheme = ThemeData(colorScheme: colorScheme, useMaterial3: true);
  final textTheme = _typeScale(
    baseTheme.textTheme,
    useAppTypeface: useAppTypeface,
  );
  // Controls are lettered in the label role.
  final actionText = textTheme.labelLarge!;

  // Cards and panels take the full ink pen; fields and quiet controls the
  // quiet pen. Each role keeps its own seed, so a card and a chip of the same
  // size still wobble differently, and neither changes between frames.
  final cardPen = BorderSide(color: palette.ink, width: VerilyPen.strokeWidth);
  final quietPen = BorderSide(color: palette.quietPen, width: 2);
  final firmPen = BorderSide(
    color: palette.firmPen,
    width: VerilyPen.strokeWidth,
  );
  final fieldBorder = VerilyRoughInputBorder(borderSide: quietPen);

  return baseTheme.copyWith(
    brightness: brightness,
    scaffoldBackgroundColor: palette.canvas,
    canvasColor: palette.surface,
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: palette.canvas,
      foregroundColor: palette.ink,
      surfaceTintColor: VerilyColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    // Back, close, and menu buttons draw Skribble's own glyphs instead of the
    // Material font, so navigation chrome matches every other icon.
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) =>
          const SkribbleIcon(data: VerilyIcons.back),
      closeButtonIconBuilder: (context) =>
          const SkribbleIcon(data: VerilyIcons.close),
      drawerButtonIconBuilder: (context) =>
          const SkribbleIcon(data: SkribbleGlyphs.menu),
      endDrawerButtonIconBuilder: (context) =>
          const SkribbleIcon(data: SkribbleGlyphs.menu),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: VerilyRoughBorder(
        side: cardPen,
        radius: VerilyRadius.card,
        seed: 7,
      ),
    ),
    // Material buttons share the pen outline and 56-unit target with
    // VerilyActionButton, so screens that still use them read as the same
    // family of controls.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.action,
        foregroundColor: palette.onAction,
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const VerilyRoughBorder(),
        textStyle: actionText,
      ).copyWith(side: _penOutline(palette, enabledAlpha: 1)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: palette.surface,
        foregroundColor: palette.ink,
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const VerilyRoughBorder(),
        textStyle: actionText,
      ).copyWith(side: _penOutline(palette, enabledAlpha: 0.56)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.ink,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: const VerilyRoughBorder(seed: 29),
        textStyle: actionText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.ink,
        minimumSize: const Size(48, 48),
        shape: const VerilyRoughBorder(seed: 31),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.action,
      foregroundColor: palette.onAction,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: VerilyRoughBorder(
        side: firmPen,
        radius: VerilyRadius.card,
        seed: 37,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(VerilyRoughBorder(seed: 41)),
        side: WidgetStatePropertyAll(quietPen),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        textStyle: WidgetStatePropertyAll(actionText),
        // Selection is a wash under ink, never colour alone: the selected
        // segment also carries a check.
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.highlight
              : palette.surface,
        ),
        foregroundColor: WidgetStatePropertyAll(palette.ink),
      ),
      selectedIcon: const SkribbleIcon(data: VerilyIcons.check, size: 18),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surface,
      selectedColor: palette.highlight,
      checkmarkColor: palette.ink,
      side: quietPen,
      shape: VerilyRoughBorder(
        side: quietPen,
        radius: VerilyRadius.chip,
        seed: 13,
      ),
      labelStyle: actionText.copyWith(color: palette.ink),
      secondaryLabelStyle: actionText.copyWith(color: palette.ink),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      iconTheme: IconThemeData(color: palette.ink, size: 18),
    ),
    // A focused or invalid field draws a heavier ink pen; the error message
    // under it says what is wrong.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      disabledBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: palette.line, width: 2),
      ),
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: palette.ink, width: 3),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: palette.ink, width: 3),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: palette.ink, width: 3.4),
      ),
      errorStyle: textTheme.bodySmall?.copyWith(color: palette.ink),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: VerilyColors.transparent,
      elevation: 0,
      shape: VerilyRoughBorder(
        side: firmPen,
        radius: VerilyRadius.sheet,
        seed: 17,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: VerilyColors.transparent,
      showDragHandle: false,
      elevation: 0,
      shape: VerilyRoughBorder(
        side: firmPen,
        radius: VerilyRadius.sheet,
        seed: 19,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surface,
      surfaceTintColor: VerilyColors.transparent,
      elevation: 0,
      textStyle: actionText.copyWith(color: palette.ink),
      shape: VerilyRoughBorder(
        side: firmPen,
        radius: VerilyRadius.card,
        seed: 43,
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(palette.surface),
        surfaceTintColor: const WidgetStatePropertyAll(
          VerilyColors.transparent,
        ),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          VerilyRoughBorder(
            side: firmPen,
            radius: VerilyRadius.card,
            seed: 43,
          ),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: VerilyRoughDecoration(
        color: palette.ink,
        outline: palette.ink,
        radius: VerilyRadius.control,
        strokeWidth: 1.6,
        seed: 47,
      ),
      textStyle: actionText.copyWith(color: palette.canvas),
    ),
    // A snack bar inverts the page: paper on night, night on paper.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.canvas),
      actionTextColor: palette.canvas,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: VerilyRoughBorder(
        side: BorderSide(
          color: palette.canvas.withValues(alpha: 0.7),
          width: 2,
        ),
        radius: VerilyRadius.card,
        seed: 23,
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      shape: VerilyRoughBorder(
        side: quietPen,
        radius: VerilyRadius.card,
        seed: 53,
      ),
      collapsedShape: VerilyRoughBorder(
        side: quietPen,
        radius: VerilyRadius.card,
        seed: 53,
      ),
      iconColor: palette.ink,
      collapsedIconColor: palette.mutedInk,
    ),
    dividerTheme: DividerThemeData(color: palette.line, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.ink,
      linearTrackColor: palette.highlight,
      circularTrackColor: VerilyColors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.highlight,
      indicatorShape: VerilyRoughBorder(
        side: firmPen,
        radius: VerilyRadius.chip,
        seed: 59,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.highlight,
      indicatorShape: VerilyRoughBorder(
        side: firmPen,
        radius: VerilyRadius.chip,
        seed: 59,
      ),
    ),
    textTheme: textTheme,
  );
}

/// The pen outline for themed buttons. A disabled control keeps its shape but
/// drops to the quiet line colour, so it never reads as a doubled border.
WidgetStateProperty<BorderSide> _penOutline(
  VerilyPalette palette, {
  required double enabledAlpha,
}) => WidgetStateProperty.resolveWith(
  (states) => BorderSide(
    color: states.contains(WidgetState.disabled)
        ? palette.line
        : palette.ink.withValues(alpha: enabledAlpha),
    width: VerilyPen.strokeWidth,
  ),
);

/// The WCAG 2.2 contrast ratio between two opaque colours, from 1 to 21.
double verilyContrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
