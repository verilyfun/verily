import 'package:flutter/widgets.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_brand/src/colors.dart';
import 'package:verily_brand/src/geometry.dart';
import 'package:verily_brand/src/glyph_painter.dart';

/// The pin-check: Verily's mark, one continuous stroke that is both a map
/// pin and a tick.
///
/// The mark fills a [size] square. By default it is inked in the seeded
/// Skribble hand; pass `rough: false` for the exact vector line used by the
/// exported files.
///
/// ```dart
/// const VerilyMark(size: 96)
/// VerilyMark(size: 160, progress: drawOn.value) // draws itself in one stroke
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

  /// The pen width in artboard units, where the artboard is
  /// [VerilyGeometry.markArtboard] wide. Defaults to [weightFor] [size].
  final double? strokeWidth;

  /// How much of the stroke is drawn, from 0 (nothing) to 1 (the whole mark).
  ///
  /// When the platform or a `WiredMotion` ancestor turns motion off, the mark
  /// is always drawn complete.
  final double progress;

  /// Whether to ink in the seeded Skribble hand (the default) or as the clean
  /// vector line.
  final bool rough;

  /// The hand: the same seed always draws the same line.
  final int seed;

  /// The label read by screen readers, or null when the mark is decoration
  /// beside the name.
  final String? semanticLabel;

  /// The optical pen width for a mark [size] logical pixels wide.
  ///
  /// Small marks need a heavier line to stay open and visible: the pen is
  /// [VerilyGeometry.smallWeight] at 32 pixels and below,
  /// [VerilyGeometry.markWeight] from 64 pixels up, and blends in between.
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

/// Paints the pin-check mark, centred in its canvas.
class VerilyMarkPainter extends BrandGlyphPainter {
  /// Paints the mark in [color] at [strokeWidth] artboard units.
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
         weight: strokeWidth / VerilyGeometry.mark.width,
       );
}
