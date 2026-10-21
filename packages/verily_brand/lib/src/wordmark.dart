import 'package:flutter/widgets.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_brand/src/colors.dart';
import 'package:verily_brand/src/geometry.dart';
import 'package:verily_brand/src/glyph_painter.dart';

/// The ✓erily wordmark: the "v" is a vermilion check, "erily" is written in
/// plum ink, and the i is dotted in vermilion, last.
///
/// The wordmark is [height] tall from the top of the l to the tail of the y,
/// and as wide as its letters need.
class VerilyWordmark extends StatelessWidget {
  /// Writes the wordmark at [height].
  const VerilyWordmark({
    super.key,
    this.height = 48,
    this.accentColor = VerilyBrandColors.stamp,
    this.inkColor = VerilyBrandColors.ink,
    this.progress = 1,
    this.rough = true,
    this.seed = 2,
    this.semanticLabel = 'Verily',
  });

  /// The wordmark's height, in logical pixels.
  final double height;

  /// The check and the i's dot. Use [VerilyBrandColors.stampOnNight] on night
  /// paper.
  final Color accentColor;

  /// The letters "erily". Use [VerilyBrandColors.paper] on night paper.
  final Color inkColor;

  /// How much of the word is written, from 0 (nothing) to 1 (dotted).
  ///
  /// When the platform or a `WiredMotion` ancestor turns motion off, the word
  /// is always written in full.
  final double progress;

  /// Whether to ink in the seeded Skribble hand or as clean vectors.
  final bool rough;

  /// The hand: the same seed always writes the same word.
  final int seed;

  /// The label read by screen readers, or null when it is decoration.
  final String? semanticLabel;

  /// The wordmark's width for [height].
  static double widthFor(double height) {
    final box = VerilyGeometry.wordmarkBox;
    return height * box.width / box.height;
  }

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size(widthFor(height), height),
      painter: BrandGlyphPainter(
        glyph: VerilyGeometry.wordmark,
        box: VerilyGeometry.wordmarkBox,
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
