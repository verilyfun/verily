import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:verily_brand/src/geometry.dart';
import 'package:verily_brand/src/ink.dart';

/// Paints a [BrandGlyph] fitted into its canvas, drawn part by part.
///
/// [progress] runs through the glyph in drawing order: each shape presses in,
/// each knockout cuts along its length, each stroke draws on along its length
/// with a short lift between strokes, and each dot is pressed last. A stroke
/// that lies along a knockout (the mark's flick) draws as the cutting pen
/// passes over it, so the cut and the flick are one gesture. At 0 nothing is
/// painted; at 1 the glyph is complete.
///
/// Shapes and knockouts are painted in a layer of their own, so a knockout is
/// truly transparent over any background and never cuts the strokes, the
/// dots, or anything else on the canvas.
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

  /// The shapes, knockouts, strokes, and dots to draw.
  final BrandGlyph glyph;

  /// The part of the artboard that fills the canvas, centred and contained.
  final BrandBox box;

  /// The colour of [BrandInk.accent] shapes, strokes, and dots.
  final Color accentColor;

  /// The colour of [BrandInk.body] shapes, strokes, and dots.
  final Color bodyColor;

  /// How much of the glyph is drawn, from 0 to 1.
  final double progress;

  /// Scales every knockout's and stroke's width. Shapes and dots keep their
  /// size.
  final double weight;

  /// Whether to ink in the seeded Skribble hand or as clean vectors.
  final bool rough;

  /// The hand: the same seed always draws the same wobble.
  final int seed;

  /// The parts of [progress] each shape, knockout, stroke, and dot occupies,
  /// in that order.
  ///
  /// Parts are timed by how far the pen travels: a stroke or knockout by its
  /// length, a dot by a few of its radii, and a shape by its height, as if the
  /// pen pressed it in from top to point. The pen lifts for about two pen
  /// widths between strokes; the first cut follows the press directly.
  static List<(double, double)> timeline(BrandGlyph glyph) =>
      _planOf(glyph).slots;

  /// Whether each of [glyph]'s strokes lies along one of its knockouts, as
  /// the mark's flick does. Such a stroke is drawn as the cutting pen passes
  /// over it, with the cutting pen ([verilyMarkPen]).
  static List<bool> ridesKnockout(BrandGlyph glyph) => _planOf(glyph).riding;

  static final Expando<_Plan> _plans = Expando<_Plan>();

  static _Plan _planOf(BrandGlyph glyph) => _plans[glyph] ??= _plan(glyph);

  static _Plan _plan(BrandGlyph glyph) {
    final firstPen = [...glyph.knockouts, ...glyph.strokes].firstOrNull;
    final lift = firstPen == null ? 0.0 : firstPen.width * 2;
    final slots = <(double, double)>[];
    final riding = <bool>[];
    var at = 0.0;
    for (final shape in glyph.shapes) {
      final cost = shape.bounds.height;
      slots.add((at, at + cost));
      at += cost;
    }
    final cuts = <(BrandStroke, double)>[];
    for (final (index, knockout) in glyph.knockouts.indexed) {
      if (index > 0) at += lift;
      final cost = BrandInkPainter.lengthOf(knockout);
      slots.add((at, at + cost));
      cuts.add((knockout, at));
      at += cost;
    }
    var lifted = glyph.knockouts.isNotEmpty;
    for (final stroke in glyph.strokes) {
      final along = _riding(stroke, cuts);
      riding.add(along != null);
      if (along != null) {
        slots.add(along);
        continue;
      }
      if (lifted) at += lift;
      final cost = BrandInkPainter.lengthOf(stroke);
      slots.add((at, at + cost));
      at += cost;
      lifted = true;
    }
    for (final dot in glyph.dots) {
      if (lifted) at += lift;
      final cost = dot.radius * 6;
      slots.add((at, at + cost));
      at += cost;
      lifted = true;
    }
    final total = slots.fold<double>(0, (end, slot) => math.max(end, slot.$2));
    return _Plan(
      slots: total <= 0
          ? [for (final _ in slots) (0.0, 1.0)]
          : [for (final (start, end) in slots) (start / total, end / total)],
      riding: riding,
    );
  }

  /// The slot of a [stroke] that lies along one of [cuts]: the part of the
  /// knockout's pen travel that passes over it, or null when it lies along
  /// none.
  static (double, double)? _riding(
    BrandStroke stroke,
    List<(BrandStroke, double)> cuts,
  ) {
    for (final (knockout, at) in cuts) {
      final tolerance = knockout.width * 0.02;
      final start = knockout.locate(stroke.start);
      final end = knockout.locate(stroke.curves.last.end);
      if (start.off <= tolerance &&
          end.off <= tolerance &&
          end.along > start.along) {
        return (at + start.along, at + end.along);
      }
    }
    return null;
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
    final plan = _planOf(glyph);
    final slots = plan.slots;
    double local(int slot) {
      if (p >= 1) return 1;
      final (start, end) = slots[slot];
      if (end <= start) return p >= end ? 1 : 0;
      return ((p - start) / (end - start)).clamp(0.0, 1.0);
    }

    _paintShapes(canvas, local);
    final offset = glyph.shapes.length + glyph.knockouts.length;
    for (final (index, stroke) in glyph.strokes.indexed) {
      BrandInkPainter.paint(
        canvas,
        stroke,
        color: _colorOf(stroke.ink),
        progress: local(offset + index),
        weight: weight,
        rough: rough,
        seed: seed * 31 + index,
        pen: plan.riding[index] ? verilyMarkPen : verilyBrandPen,
      );
    }
    for (final (index, dot) in glyph.dots.indexed) {
      BrandInkPainter.paintDot(
        canvas,
        dot,
        color: _colorOf(dot.ink),
        progress: Curves.easeOutBack.transform(
          local(offset + glyph.strokes.length + index),
        ),
        rough: rough,
        seed: seed * 53 + index,
      );
    }
    canvas.restore();
  }

  /// Presses in the shapes and cuts the knockouts out of them, in a layer of
  /// their own.
  void _paintShapes(Canvas canvas, double Function(int slot) local) {
    if (glyph.shapes.isEmpty || local(0) <= 0) return;
    var bounds = Rect.largest;
    for (final (index, shape) in glyph.shapes.indexed) {
      final box = shape.bounds.inflate(shape.bounds.height * 0.05);
      final rect = Rect.fromLTWH(box.left, box.top, box.width, box.height);
      bounds = index == 0 ? rect : bounds.expandToInclude(rect);
    }
    canvas.saveLayer(bounds, Paint());
    for (final (index, shape) in glyph.shapes.indexed) {
      final t = local(index);
      if (t <= 0) continue;
      final color = _colorOf(shape.ink);
      if (t >= 1) {
        BrandInkPainter.paintShape(
          canvas,
          shape,
          color: color,
          rough: rough,
          seed: seed * 41 + index,
        );
        continue;
      }
      // The shape presses in: it fades up and grows from its lowest point,
      // overshooting a touch before it settles, like a pin pushed into a map.
      final box = shape.bounds;
      final pivot = Offset(box.center.x, box.bottom);
      final grow = 0.55 + 0.45 * Curves.easeOutBack.transform(t);
      final opacity = Curves.easeOut.transform(math.min(1, t * 1.6));
      canvas
        ..saveLayer(
          bounds,
          // Only the layer paint's alpha is used.
          Paint()..color = color.withValues(alpha: opacity),
        )
        ..translate(pivot.dx, pivot.dy)
        ..scale(grow)
        ..translate(-pivot.dx, -pivot.dy);
      BrandInkPainter.paintShape(
        canvas,
        shape,
        color: color,
        rough: rough,
        seed: seed * 41 + index,
      );
      canvas.restore();
    }
    for (final (index, knockout) in glyph.knockouts.indexed) {
      BrandInkPainter.cut(
        canvas,
        knockout,
        progress: local(glyph.shapes.length + index),
        weight: weight,
        rough: rough,
        seed: seed * 37 + index,
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

/// A glyph's timeline, worked out once.
final class _Plan {
  const _Plan({required this.slots, required this.riding});

  /// The parts of progress each shape, knockout, stroke, and dot occupies.
  final List<(double, double)> slots;

  /// Whether each stroke lies along a knockout.
  final List<bool> riding;
}
