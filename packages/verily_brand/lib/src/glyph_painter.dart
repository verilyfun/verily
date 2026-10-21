import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:verily_brand/src/geometry.dart';
import 'package:verily_brand/src/ink.dart';

/// Paints a [BrandGlyph] fitted into its canvas, written stroke by stroke.
///
/// [progress] runs the pen through the glyph in writing order: each stroke
/// draws on along its length, with a short lift between strokes, and each dot
/// is pressed last. At 0 nothing is painted; at 1 the glyph is complete.
class BrandGlyphPainter extends CustomPainter {
  /// Paints [glyph], fitting [box] (artboard units) inside the canvas.
  BrandGlyphPainter({
    required this.glyph,
    required this.box,
    required this.accentColor,
    required this.bodyColor,
    this.progress = 1,
    this.weight = 1,
    this.rough = true,
    this.seed = 1,
  });

  /// The strokes and dots to draw.
  final BrandGlyph glyph;

  /// The part of the artboard that fills the canvas, centred and contained.
  final BrandBox box;

  /// The colour of [BrandInk.accent] strokes and dots.
  final Color accentColor;

  /// The colour of [BrandInk.body] strokes and dots.
  final Color bodyColor;

  /// How much of the glyph is written, from 0 to 1.
  final double progress;

  /// Scales every stroke's width.
  final double weight;

  /// Whether to ink in the seeded Skribble hand or as clean vectors.
  final bool rough;

  /// The hand: the same seed always draws the same wobble.
  final int seed;

  /// The parts of [progress] each stroke and dot occupies, in order.
  static List<(double, double)> timeline(BrandGlyph glyph) {
    final costs = <double>[];
    for (final stroke in glyph.strokes) {
      costs.add(BrandInkPainter.lengthOf(stroke));
    }
    for (final dot in glyph.dots) {
      costs.add(dot.radius * 6);
    }
    // The pen lifts between strokes for about two pen widths of travel.
    final lift = glyph.strokes.isEmpty ? 0 : glyph.strokes.first.width * 2;
    final total =
        costs.fold<double>(0, (sum, cost) => sum + cost) +
        lift * math.max(0, costs.length - 1);
    final slots = <(double, double)>[];
    double at = 0;
    for (final cost in costs) {
      slots.add((at / total, (at + cost) / total));
      at += cost + lift;
    }
    return slots;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.isFinite ? progress.clamp(0.0, 1.0) : 1.0;
    if (p <= 0 || size.isEmpty) return;
    final scale = math.min(size.width / box.width, size.height / box.height);
    canvas
      ..save()
      ..translate(
        (size.width - box.width * scale) / 2,
        (size.height - box.height * scale) / 2,
      )
      ..scale(scale)
      ..translate(-box.left, -box.top);
    final slots = timeline(glyph);
    for (final (index, stroke) in glyph.strokes.indexed) {
      final (start, end) = slots[index];
      BrandInkPainter.paint(
        canvas,
        stroke,
        color: _colorOf(stroke.ink),
        progress: p >= 1 ? 1 : (p - start) / (end - start),
        weight: weight,
        rough: rough,
        seed: seed * 31 + index,
      );
    }
    for (final (index, dot) in glyph.dots.indexed) {
      final (start, end) = slots[glyph.strokes.length + index];
      final local = p >= 1 ? 1.0 : ((p - start) / (end - start));
      BrandInkPainter.paintDot(
        canvas,
        dot,
        color: _colorOf(dot.ink),
        progress: Curves.easeOutBack.transform(local.clamp(0.0, 1.0)),
        rough: rough,
        seed: seed * 53 + index,
      );
    }
    canvas.restore();
  }

  Color _colorOf(BrandInk ink) => switch (ink) {
    BrandInk.accent => accentColor,
    BrandInk.body => bodyColor,
  };

  @override
  bool shouldRepaint(BrandGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.box != box ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.progress != progress ||
      oldDelegate.weight != weight ||
      oldDelegate.rough != rough ||
      oldDelegate.seed != seed;
}
