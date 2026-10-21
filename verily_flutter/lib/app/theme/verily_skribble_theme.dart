import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';

/// Binds Skribble's hand-drawn components to the active Verily palette.
///
/// Wired components read their ink, surface, marker, and muted-ink roles from
/// the resolved [VerilyPalette], so hand-drawn controls follow light and dark
/// switches without raw colours reaching widgets. Their lettering is the
/// linear Skribble face the Material label role uses.
abstract final class VerilySkribbleTheme {
  /// The label typeface's family inside `skribble_font_recursive`.
  static const String fontFamily = verilyTextTypeface;

  /// Resolves the wired theme for [context]'s Verily palette.
  ///
  /// [roughnessLevel] selects the coordinated border preset. Decorative ink
  /// motion is disabled when the platform requests reduced animations; the
  /// final rough shape then appears immediately.
  static WiredThemeData of(
    BuildContext context, {
    WiredRoughness roughnessLevel = WiredRoughness.playful,
  }) {
    final palette = Theme.of(context).verily;

    return WiredThemeData(
      borderColor: palette.ink,
      textColor: palette.ink,
      disabledTextColor: palette.mutedInk,
      fillColor: palette.surface,
      // Progress fills, slider and switch tracks, and selections take the
      // quiet highlight; ink draws the shape and the value on top.
      markerColor: palette.highlight,
      roughnessLevel: roughnessLevel,
      fontFamily: fontFamily,
      motionEnabled: !MediaQuery.of(context).disableAnimations,
    );
  }
}
