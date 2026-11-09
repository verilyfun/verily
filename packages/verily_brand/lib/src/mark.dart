import 'package:flutter/widgets.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_brand/src/colors.dart';
import 'package:verily_brand/src/geometry.dart';
import 'package:verily_brand/src/glyph_painter.dart';

/// The pin-check: Verily's mark, a solid map pin with a check knocked out of
/// its head, the check's long arm breaking through the rim and flicking out
/// past it.
///
/// The mark fills a [size] square. By default it is inked in the seeded
/// Skribble hand; pass `rough: false` for the exact vector shape used by the
/// exported files. The check is cut clean through the pin, so whatever is
/// behind the mark shows through it.
///
/// ```dart
/// const VerilyMark(size: 96)
/// VerilyMark(size: 160, progress: drawOn.value) // presses in, then is ticked
/// ```
class VerilyMark extends StatelessWidget {
  /// Draws the mark in a [size] square.
  const VerilyMark({
    super.key,
    this.size = 48,
    this.color = VerilyBrandColors.stamp,
    this.strokeWidth,
    this.progress = 1,
    this.rough = true,
    this.seed = 1,
    this.semanticLabel = 'Verily',
  });

  /// The side of the square the mark fills, in logical pixels.
  final double size;

  /// The ink. Use [VerilyBrandColors.stampOnNight] on night paper and
  /// [VerilyBrandColors.paper] on vermilion.
  final Color color;

  /// The width of the check and the flick in artboard units, where the
  /// artboard is [VerilyGeometry.markArtboard] wide. Defaults to [weightFor]
  /// [size].
  final double? strokeWidth;

  /// How much of the mark is drawn, from 0 (nothing) to 1 (the whole mark).
  ///
  /// The pin presses in over the first half or so, then the check is cut
  /// through it, and the flick draws as the cut runs out past the rim. When
  /// the platform or a `WiredMotion` ancestor turns motion off, the mark is
  /// always drawn complete.
  final double progress;

  /// Whether to ink in the seeded Skribble hand (the default) or as the clean
  /// vector shape.
  final bool rough;

  /// The hand: the same seed always draws the same mark.
  final int seed;

  /// The label read by screen readers, or null when the mark is decoration
  /// beside the name.
  final String? semanticLabel;

  /// The optical width of the check and flick for a mark [size] logical
  /// pixels wide.
  ///
  /// Small marks need a wider cut to stay open and a heavier flick to stay
  /// visible: the width is [VerilyGeometry.smallWeight] at 32 pixels and
  /// below, [VerilyGeometry.markWeight] from 64 pixels up, and blends in
  /// between.
  static double weightFor(double size) {
    const small = 32.0;
    const regular = 64.0;
    if (size <= small) return VerilyGeometry.smallWeight;
    if (size >= regular) return VerilyGeometry.markWeight;
    final t = (size - small) / (regular - small);
    return VerilyGeometry.smallWeight +
        (VerilyGeometry.markWeight - VerilyGeometry.smallWeight) * t;
  }

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size.square(size),
      painter: VerilyMarkPainter(
        color: color,
        strokeWidth: strokeWidth ?? weightFor(size),
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

/// Paints the pin-check mark on its square artboard, fitted to its canvas.
class VerilyMarkPainter extends BrandGlyphPainter {
  /// Paints the mark in [color], its check and flick [strokeWidth] artboard
  /// units wide.
  VerilyMarkPainter({
    super.progress,
    super.rough,
    super.seed,
    Color color = VerilyBrandColors.stamp,
    double strokeWidth = VerilyGeometry.markWeight,
  }) : super(
         glyph: VerilyGeometry.markGlyph,
         box: VerilyGeometry.markBox,
         accentColor: color,
         bodyColor: color,
         weight: strokeWidth / VerilyGeometry.markWeight,
       );
}
