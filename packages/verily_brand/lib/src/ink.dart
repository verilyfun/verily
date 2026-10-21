import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:skribble/skribble.dart';

import 'package:verily_brand/src/geometry.dart';

/// The pen every brand stroke is inked with.
///
/// A steadier cousin of Skribble's dip pen: a short touchdown, a slight
/// thinning as the pen lifts, barely any swell, and a lighter, partial second
/// pass. Lengths are in pen widths, so the character holds at any weight.
const RoughPen verilyBrandPen = RoughPen(
  startWidth: 0.62,
  endWidth: 0.55,
  taperIn: 1.1,
  taperOut: 1.8,
  pressure: 0.035,
  pressureWavelength: 220,
  repeatWidth: 0.7,
  repeatCoverage: 0.6,
  closure: 0,
  closureDrift: 0,
);

/// Inks [BrandStroke]s in the Skribble hand.
///
/// A rough stroke is drawn twice, each pass wandering from the clean
/// centreline by a seeded amount, and laid down with [verilyBrandPen]. The
/// same seed always draws the same line, so an animated stroke never re-rolls
/// its wobble from frame to frame. A clean stroke is the exact centreline with
/// round caps and joins, as in the exported SVG files.
abstract final class BrandInkPainter {
  static const int _cacheCapacity = 192;
  static final LinkedHashMap<Object, List<RoughDrawing>> _rough =
      LinkedHashMap<Object, List<RoughDrawing>>();
  static final Expando<_CleanStroke> _clean = Expando<_CleanStroke>();

  /// The stroke's clean centreline as a Flutter path.
  static Path pathOf(BrandStroke stroke) => _cleanOf(stroke).path;

  /// The length of [stroke]'s clean centreline.
  static double lengthOf(BrandStroke stroke) => _cleanOf(stroke).length;

  /// Paints [stroke] in [color], drawn from its start up to [progress] (0 to
  /// 1) of its length.
  ///
  /// [weight] scales the stroke's own width. [seed] picks the hand; strokes
  /// drawn together should use different seeds so they do not wobble in step.
  static void paint(
    Canvas canvas,
    BrandStroke stroke, {
    required Color color,
    double progress = 1,
    double weight = 1,
    bool rough = true,
    int seed = 1,
  }) {
    final p = progress.isFinite ? progress.clamp(0.0, 1.0) : 1.0;
    if (p <= 0 || color.a == 0 || weight <= 0) return;
    final width = stroke.width * weight;
    if (!rough) {
      _paintClean(canvas, stroke, color: color, width: width, progress: p);
      return;
    }
    final key = (stroke, width, color.toARGB32(), seed);
    final drawings = _rough.remove(key) ?? _prepare(stroke, width, color, seed);
    _rough[key] = drawings;
    if (_rough.length > _cacheCapacity) _rough.remove(_rough.keys.first);
    // RoughDrawing finishes its outline at 65% of its progress, then spends
    // the rest on fills, which strokes do not have.
    for (final drawing in drawings) {
      drawing.paint(canvas, progress: p * 0.65);
    }
  }

  /// Paints [dot] in [color], grown to [progress] (0 to 1) of its radius.
  ///
  /// A rough dot is a seeded, slightly lumpy blob, like a pen pressed down
  /// and lifted; a clean dot is an exact circle.
  static void paintDot(
    Canvas canvas,
    BrandDot dot, {
    required Color color,
    double progress = 1,
    bool rough = true,
    int seed = 1,
  }) {
    final p = progress.isFinite ? progress.clamp(0.0, 1.0) : 1.0;
    if (p <= 0 || color.a == 0) return;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final center = Offset(dot.center.x, dot.center.y);
    final radius = dot.radius * p;
    if (!rough) {
      canvas.drawCircle(center, radius, paint);
      return;
    }
    final random = Randomizer(seed: seed * 7919 + 17);
    const lobes = 9;
    final points = [
      for (var i = 0; i < lobes; i++)
        () {
          final angle = i / lobes * math.pi * 2 + random.next() * 0.3;
          final r = radius * (0.93 + random.next() * 0.14);
          return center + Offset(math.cos(angle), math.sin(angle)) * r;
        }(),
    ];
    canvas.drawPath(_closedCatmullRom(points), paint);
  }

  static void _paintClean(
    Canvas canvas,
    BrandStroke stroke, {
    required Color color,
    required double width,
    required double progress,
  }) {
    final clean = _cleanOf(stroke);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    if (progress >= 1) {
      canvas.drawPath(clean.path, paint);
      return;
    }
    var remaining = clean.length * progress;
    final partial = Path();
    for (final metric in clean.metrics) {
      if (remaining <= 0) break;
      partial.addPath(
        metric.extractPath(0, math.min(remaining, metric.length)),
        Offset.zero,
      );
      remaining -= metric.length;
    }
    canvas.drawPath(partial, paint);
  }

  static _CleanStroke _cleanOf(BrandStroke stroke) =>
      _clean[stroke] ??= _CleanStroke(stroke);

  /// Two seeded passes over [stroke], each its own drawing so both are inked
  /// together as the stroke draws on.
  static List<RoughDrawing> _prepare(
    BrandStroke stroke,
    double width,
    Color color,
    int seed,
  ) {
    final config = DrawConfig.build(seed: seed, pen: verilyBrandPen);
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0)
      ..style = PaintingStyle.fill;
    return [
      for (var pass = 0; pass < 2; pass++)
        RoughDrawing(
          Drawable(
            shape: 'brandStroke',
            options: config,
            sets: [
              OpSet(
                type: OpSetType.path,
                ops: _roughPass(stroke, width: width, seed: seed, pass: pass),
              ),
            ],
          ),
          border,
          fill,
        ),
    ];
  }

  /// One pass of a hand retracing [stroke].
  ///
  /// Each curve is split into pieces a few pen widths long, and every anchor
  /// wanders by a seeded amount. A curve's control points travel with their
  /// anchor, so smooth joins stay smooth and the sharp vertex of a check stays
  /// sharp; the line bends gently between anchors instead of jittering.
  static List<Op> _roughPass(
    BrandStroke stroke, {
    required double width,
    required int seed,
    required int pass,
  }) {
    final random = Randomizer(seed: seed * 104729 + pass * 1301 + 7);
    // How far the hand strays: a sliver of the pen's width, a little more on
    // the second pass. The ends stray least, so a stroke that starts or ends
    // on another (the mark's loop starts on its own arm) stays tucked in.
    final reach = width * (pass == 0 ? 0.045 : 0.07);
    PointD wander(BrandPoint point, {double amount = 1}) {
      final angle = random.next() * math.pi * 2;
      final distance = reach * amount * (0.35 + random.next() * 0.65);
      return PointD(
        point.x + math.cos(angle) * distance,
        point.y + math.sin(angle) * distance,
      );
    }

    final pieces = _split(stroke, maxLength: width * 6);
    var anchor = pieces.first.$1;
    var moved = wander(anchor, amount: 0.2);
    final ops = <Op>[Op.move(moved, pass: pass)];
    for (final (index, (from, curve)) in pieces.indexed) {
      assert(
        from.x == anchor.x && from.y == anchor.y,
        'pieces must be contiguous',
      );
      final last = index == pieces.length - 1;
      final next = wander(curve.end, amount: last ? 0.2 : 1);
      final startShift = PointD(moved.x - from.x, moved.y - from.y);
      final endShift = PointD(next.x - curve.end.x, next.y - curve.end.y);
      ops.add(
        Op.curveTo(
          PointD(
            curve.control1.x + startShift.x,
            curve.control1.y + startShift.y,
          ),
          PointD(curve.control2.x + endShift.x, curve.control2.y + endShift.y),
          next,
        ),
      );
      anchor = curve.end;
      moved = next;
    }
    return ops;
  }

  /// [stroke]'s curves split into pieces no longer than about [maxLength],
  /// each paired with the point it starts from.
  static List<(BrandPoint, BrandCubic)> _split(
    BrandStroke stroke, {
    required double maxLength,
  }) {
    final pieces = <(BrandPoint, BrandCubic)>[];
    var from = stroke.start;
    for (final curve in stroke.curves) {
      final length = BrandStroke(
        start: from,
        curves: [curve],
        width: stroke.width,
      ).length;
      final count = math.max(1, (length / maxLength).ceil());
      var rest = curve;
      var restFrom = from;
      for (var i = count; i > 1; i--) {
        final (head, tail) = _subdivide(restFrom, rest, 1 / i);
        pieces.add((restFrom, head));
        restFrom = head.end;
        rest = tail;
      }
      pieces.add((restFrom, rest));
      from = curve.end;
    }
    return pieces;
  }

  /// Splits [curve] (starting at [from]) at [t] with de Casteljau's method.
  static (BrandCubic, BrandCubic) _subdivide(
    BrandPoint from,
    BrandCubic curve,
    double t,
  ) {
    BrandPoint lerp(BrandPoint a, BrandPoint b) =>
        BrandPoint(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
    final ab = lerp(from, curve.control1);
    final bc = lerp(curve.control1, curve.control2);
    final cd = lerp(curve.control2, curve.end);
    final abc = lerp(ab, bc);
    final bcd = lerp(bc, cd);
    final mid = lerp(abc, bcd);
    return (BrandCubic(ab, abc, mid), BrandCubic(bcd, cd, curve.end));
  }

  static Path _closedCatmullRom(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    final n = points.length;
    for (var i = 0; i < n; i++) {
      final p0 = points[(i - 1 + n) % n];
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      final p3 = points[(i + 2) % n];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path..close();
  }
}

/// A stroke's clean centreline, measured once.
final class _CleanStroke {
  _CleanStroke(BrandStroke stroke) : path = _pathOf(stroke) {
    metrics = path.computeMetrics().toList(growable: false);
    length = metrics.fold(0, (sum, metric) => sum + metric.length);
  }

  final Path path;
  late final List<PathMetric> metrics;
  late final double length;

  static Path _pathOf(BrandStroke stroke) {
    final path = Path()..moveTo(stroke.start.x, stroke.start.y);
    for (final curve in stroke.curves) {
      path.cubicTo(
        curve.control1.x,
        curve.control1.y,
        curve.control2.x,
        curve.control2.y,
        curve.end.x,
        curve.end.y,
      );
    }
    return path;
  }
}
