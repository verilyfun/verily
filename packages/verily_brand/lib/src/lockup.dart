import 'package:flutter/widgets.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_brand/src/colors.dart';
import 'package:verily_brand/src/geometry.dart';
import 'package:verily_brand/src/glyph_painter.dart';

/// How the mark and the wordmark sit together.
enum VerilyLockupLayout {
  /// The mark beside the wordmark, as tall as the letters.
  horizontal,

  /// The mark centred above the wordmark.
  stacked,
}

/// The pin-check and ✓erily together, positioned by the brand geometry.
///
/// [progress] draws the mark first, then writes the word.
class VerilyLockup extends StatelessWidget {
  /// Draws the lockup [height] tall.
  const VerilyLockup({
    super.key,
    this.layout = VerilyLockupLayout.horizontal,
    this.height = 48,
    this.accentColor = VerilyBrandColors.stamp,
    this.inkColor = VerilyBrandColors.ink,
    this.progress = 1,
    this.rough = true,
    this.seed = 3,
    this.semanticLabel = 'Verily',
  });

  /// Side by side or stacked.
  final VerilyLockupLayout layout;

  /// The lockup's height, in logical pixels.
  final double height;

  /// The mark, the check, and the i's dot.
  final Color accentColor;

  /// The letters "erily".
  final Color inkColor;

  /// How much is drawn, from 0 (nothing) to 1 (complete).
  ///
  /// When the platform or a `WiredMotion` ancestor turns motion off, the
  /// lockup is always drawn complete.
  final double progress;

  /// Whether to ink in the seeded Skribble hand or as clean vectors.
  final bool rough;

  /// The hand: the same seed always draws the same lines.
  final int seed;

  /// The label read by screen readers, or null when it is decoration.
  final String? semanticLabel;

  /// The glyph for [layout].
  static BrandGlyph glyphOf(VerilyLockupLayout layout) => switch (layout) {
    VerilyLockupLayout.horizontal => VerilyGeometry.horizontalLockup,
    VerilyLockupLayout.stacked => VerilyGeometry.stackedLockup,
  };

  /// The ink box for [layout].
  static BrandBox boxOf(VerilyLockupLayout layout) => switch (layout) {
    VerilyLockupLayout.horizontal => VerilyGeometry.horizontalLockupBox,
    VerilyLockupLayout.stacked => VerilyGeometry.stackedLockupBox,
  };

  /// The lockup's width for [height] in [layout].
  static double widthFor(double height, VerilyLockupLayout layout) {
    final box = boxOf(layout);
    return height * box.width / box.height;
  }

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size(widthFor(height, layout), height),
      painter: BrandGlyphPainter(
        glyph: glyphOf(layout),
        box: boxOf(layout),
        accentColor: accentColor,
        bodyColor: inkColor,
        progress: WiredMotion.enabledOf(context) ? progress : 1,
        rough: rough,
        seed: seed,
      ),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: paint);
    return Semantics(label: label, image: true, child: paint);
  }
}
