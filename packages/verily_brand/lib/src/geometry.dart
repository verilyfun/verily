/// Verily's drawn geometry, as plain path data.
///
/// This is the only place the mark, the wordmark, and the stamp are defined.
/// The Flutter painters, the launch reel, and the SVG exporter all read it, so
/// the app, the video, and the committed files can never drift apart. It has
/// no Flutter dependency, which keeps it usable from command-line tooling.
library;

import 'dart:math' as math;

/// A point in a glyph's artboard units.
final class BrandPoint {
  /// A point at ([x], [y]).
  const BrandPoint(this.x, this.y);

  /// Distance from the left of the artboard.
  final double x;

  /// Distance from the top of the artboard.
  final double y;

  /// This point moved by ([dx], [dy]) after scaling by [scale].
  BrandPoint transform({double scale = 1, double dx = 0, double dy = 0}) =>
      BrandPoint(x * scale + dx, y * scale + dy);

  @override
  String toString() => 'BrandPoint($x, $y)';
}

/// A cubic Bézier curve continuing a [BrandStroke] to [end].
final class BrandCubic {
  /// A curve pulled towards [control1] and [control2] that lands on [end].
  const BrandCubic(this.control1, this.control2, this.end);

  /// The first control point.
  final BrandPoint control1;

  /// The second control point.
  final BrandPoint control2;

  /// Where the curve lands.
  final BrandPoint end;

  /// This curve with every point transformed by [BrandPoint.transform].
  BrandCubic transform({double scale = 1, double dx = 0, double dy = 0}) =>
      BrandCubic(
        control1.transform(scale: scale, dx: dx, dy: dy),
        control2.transform(scale: scale, dx: dx, dy: dy),
        end.transform(scale: scale, dx: dx, dy: dy),
      );
}

/// Which brand ink a stroke or dot is drawn in.
enum BrandInk {
  /// Stamp vermilion: the check, the mark, and the i-dot.
  accent,

  /// Plum ink: the letters "erily".
  body,
}

/// One continuous pen stroke: where the pen lands, then the curves it draws
/// without lifting.
final class BrandStroke {
  /// A stroke from [start] through [curves], drawn in [ink] at [width].
  const BrandStroke({
    required this.start,
    required this.curves,
    required this.width,
    this.ink = BrandInk.accent,
  });

  /// Where the pen touches down.
  final BrandPoint start;

  /// The curves the pen draws, in order.
  final List<BrandCubic> curves;

  /// The pen's width, in artboard units.
  final double width;

  /// The ink it is drawn in.
  final BrandInk ink;

  /// This stroke drawn at [width] instead.
  BrandStroke withWidth(double width) =>
      BrandStroke(start: start, curves: curves, width: width, ink: ink);

  /// This stroke scaled by [scale] and then moved by ([dx], [dy]). The width
  /// scales with it.
  BrandStroke transform({double scale = 1, double dx = 0, double dy = 0}) =>
      BrandStroke(
        start: start.transform(scale: scale, dx: dx, dy: dy),
        curves: [
          for (final curve in curves)
            curve.transform(scale: scale, dx: dx, dy: dy),
        ],
        width: width * scale,
        ink: ink,
      );

  /// The stroke's centreline as SVG path data (`M … C …`).
  String get pathData {
    final data = StringBuffer('M ${svgNumber(start.x)} ${svgNumber(start.y)}');
    for (final curve in curves) {
      data.write(
        ' C ${svgNumber(curve.control1.x)} ${svgNumber(curve.control1.y)}'
        ' ${svgNumber(curve.control2.x)} ${svgNumber(curve.control2.y)}'
        ' ${svgNumber(curve.end.x)} ${svgNumber(curve.end.y)}',
      );
    }
    return data.toString();
  }

  /// Points along the centreline, [perCurve] to a curve, starting at [start].
  List<BrandPoint> sample({int perCurve = 48}) {
    final points = [start];
    var from = start;
    for (final curve in curves) {
      for (var i = 1; i <= perCurve; i++) {
        points.add(cubicPoint(from, curve, i / perCurve));
      }
      from = curve.end;
    }
    return points;
  }

  /// The approximate length of the centreline.
  double get length {
    final points = sample(perCurve: 64);
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += math.sqrt(
        math.pow(points[i].x - points[i - 1].x, 2) +
            math.pow(points[i].y - points[i - 1].y, 2),
      );
    }
    return total;
  }
}

/// A filled dot, such as the i's tittle.
final class BrandDot {
  /// A dot of [radius] at [center] in [ink].
  const BrandDot({
    required this.center,
    required this.radius,
    this.ink = BrandInk.accent,
  });

  /// The dot's centre.
  final BrandPoint center;

  /// The dot's radius, in artboard units.
  final double radius;

  /// The ink it is drawn in.
  final BrandInk ink;
}

/// An axis-aligned box in artboard units.
final class BrandBox {
  /// A box from ([left], [top]) of [width] by [height].
  const BrandBox(this.left, this.top, this.width, this.height);

  /// The box's left edge.
  final double left;

  /// The box's top edge.
  final double top;

  /// The box's width.
  final double width;

  /// The box's height.
  final double height;

  /// The box's right edge.
  double get right => left + width;

  /// The box's bottom edge.
  double get bottom => top + height;

  /// The box's centre.
  BrandPoint get center => BrandPoint(left + width / 2, top + height / 2);

  /// This box grown by [margin] on every side.
  BrandBox inflate(double margin) => BrandBox(
    left - margin,
    top - margin,
    width + margin * 2,
    height + margin * 2,
  );

  /// The SVG `viewBox` attribute for this box.
  String get viewBox =>
      '${svgNumber(left)} ${svgNumber(top)} ${svgNumber(width)} ${svgNumber(height)}';
}

/// A drawing made of pen strokes and dots, in writing order.
final class BrandGlyph {
  /// A glyph of [strokes] followed by [dots].
  const BrandGlyph({required this.strokes, this.dots = const []});

  /// The strokes, in the order a pen draws them.
  final List<BrandStroke> strokes;

  /// Dots, placed after every stroke (the i is dotted last).
  final List<BrandDot> dots;

  /// The box the ink covers, including each stroke's round caps.
  BrandBox get inkBounds {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;
    for (final stroke in strokes) {
      final half = stroke.width / 2;
      for (final point in stroke.sample()) {
        left = math.min(left, point.x - half);
        top = math.min(top, point.y - half);
        right = math.max(right, point.x + half);
        bottom = math.max(bottom, point.y + half);
      }
    }
    for (final dot in dots) {
      left = math.min(left, dot.center.x - dot.radius);
      top = math.min(top, dot.center.y - dot.radius);
      right = math.max(right, dot.center.x + dot.radius);
      bottom = math.max(bottom, dot.center.y + dot.radius);
    }
    return BrandBox(left, top, right - left, bottom - top);
  }

  /// This glyph with every stroke and dot scaled by [scale] and moved by
  /// ([dx], [dy]).
  BrandGlyph transform({double scale = 1, double dx = 0, double dy = 0}) =>
      BrandGlyph(
        strokes: [
          for (final stroke in strokes)
            stroke.transform(scale: scale, dx: dx, dy: dy),
        ],
        dots: [
          for (final dot in dots)
            BrandDot(
              center: dot.center.transform(scale: scale, dx: dx, dy: dy),
              radius: dot.radius * scale,
              ink: dot.ink,
            ),
        ],
      );
}

/// The point [t] of the way along [curve], which starts at [from].
BrandPoint cubicPoint(BrandPoint from, BrandCubic curve, double t) {
  final u = 1 - t;
  final a = u * u * u;
  final b = 3 * u * u * t;
  final c = 3 * u * t * t;
  final d = t * t * t;
  return BrandPoint(
    a * from.x + b * curve.control1.x + c * curve.control2.x + d * curve.end.x,
    a * from.y + b * curve.control1.y + c * curve.control2.y + d * curve.end.y,
  );
}

/// Verily's geometry: the pin-check mark, the ✓erily wordmark, and the
/// verified stamp.
abstract final class VerilyGeometry {
  /// The side of the square artboard the mark is drawn on.
  static const double markArtboard = 512;

  /// The mark's pen width for ordinary use, from 48 logical pixels up.
  static const double markWeight = 36;

  /// The heavier pen used on the app icon, where the mark sits on colour.
  static const double iconWeight = 44;

  /// The heaviest pen, for the mark at 32 logical pixels and below, so the
  /// loop stays open and the line stays visible at 24 pixels.
  static const double smallWeight = 52;

  /// The pin-check: ONE continuous stroke.
  ///
  /// The pen lands on the centreline of the check's long arm and leaves it
  /// heading straight up. It loops over the pin's round head, falls down the
  /// pin's left side to its point, and that point is the vertex of a check:
  /// the long arm rises up and to the right, crossing the head's right side
  /// exactly where the loop began, and flicks out past the head. It reads as
  /// both a location pin and a tick: verified, here.
  ///
  /// The vertex at the pin's point is a sharp corner; the other joins are
  /// smooth.
  static const BrandStroke mark = BrandStroke(
    start: BrandPoint(307, 268),
    curves: [
      // Up from the arm and over the head's right shoulder.
      BrandCubic(
        BrandPoint(308, 232),
        BrandPoint(340, 86),
        BrandPoint(222, 76),
      ),
      // Across the top and round the head's left side.
      BrandCubic(BrandPoint(126, 68), BrandPoint(74, 142), BrandPoint(82, 212)),
      // Down the pin's left flank to its point.
      BrandCubic(
        BrandPoint(90, 282),
        BrandPoint(158, 348),
        BrandPoint(222, 458),
      ),
      // The check's long arm: up through the loop's start and out.
      BrandCubic(
        BrandPoint(280, 318),
        BrandPoint(340, 188),
        BrandPoint(430, 54),
      ),
    ],
    width: markWeight,
  );

  /// The mark as a glyph.
  static const BrandGlyph markGlyph = BrandGlyph(strokes: [mark]);

  /// The square the mark is centred in, at [markArtboard] units.
  static const BrandBox markBox = BrandBox(0, 0, markArtboard, markArtboard);

  /// The check that is the "v" of ✓erily, in vermilion.
  static const BrandStroke checkV = BrandStroke(
    start: BrandPoint(8, 138),
    curves: [
      BrandCubic(BrandPoint(20, 157), BrandPoint(32, 178), BrandPoint(44, 200)),
      BrandCubic(BrandPoint(62, 158), BrandPoint(80, 120), BrandPoint(100, 84)),
    ],
    width: 18,
  );

  /// The handwritten "erily", in plum ink, in writing order.
  static const List<BrandStroke> erily = [
    // e: the crossbar, then round the bowl and out.
    BrandStroke(
      start: BrandPoint(122, 160),
      curves: [
        BrandCubic(
          BrandPoint(145, 160),
          BrandPoint(168, 158),
          BrandPoint(190, 154),
        ),
        BrandCubic(
          BrandPoint(192, 122),
          BrandPoint(172, 102),
          BrandPoint(150, 103),
        ),
        BrandCubic(
          BrandPoint(124, 105),
          BrandPoint(114, 134),
          BrandPoint(116, 160),
        ),
        BrandCubic(
          BrandPoint(118, 190),
          BrandPoint(140, 203),
          BrandPoint(162, 201),
        ),
        BrandCubic(
          BrandPoint(177, 199),
          BrandPoint(187, 193),
          BrandPoint(194, 183),
        ),
      ],
      width: 16,
      ink: BrandInk.body,
    ),
    // r: the stem.
    BrandStroke(
      start: BrandPoint(216, 106),
      curves: [
        BrandCubic(
          BrandPoint(216, 140),
          BrandPoint(215, 172),
          BrandPoint(216, 200),
        ),
      ],
      width: 16,
      ink: BrandInk.body,
    ),
    // r: the shoulder, kept short so it never crowds the i.
    BrandStroke(
      start: BrandPoint(216, 148),
      curves: [
        BrandCubic(
          BrandPoint(221, 122),
          BrandPoint(238, 106),
          BrandPoint(259, 110),
        ),
      ],
      width: 16,
      ink: BrandInk.body,
    ),
    // i: the stem. Its dot comes last, in vermilion.
    BrandStroke(
      start: BrandPoint(282, 110),
      curves: [
        BrandCubic(
          BrandPoint(282, 142),
          BrandPoint(281, 172),
          BrandPoint(283, 200),
        ),
      ],
      width: 16,
      ink: BrandInk.body,
    ),
    // l: the ascender and its little kick.
    BrandStroke(
      start: BrandPoint(312, 26),
      curves: [
        BrandCubic(
          BrandPoint(307, 86),
          BrandPoint(305, 146),
          BrandPoint(309, 186),
        ),
        BrandCubic(
          BrandPoint(311, 201),
          BrandPoint(322, 205),
          BrandPoint(334, 197),
        ),
      ],
      width: 16,
      ink: BrandInk.body,
    ),
    // y: the cup.
    BrandStroke(
      start: BrandPoint(352, 108),
      curves: [
        BrandCubic(
          BrandPoint(353, 152),
          BrandPoint(362, 192),
          BrandPoint(385, 193),
        ),
        BrandCubic(
          BrandPoint(406, 194),
          BrandPoint(416, 156),
          BrandPoint(418, 108),
        ),
      ],
      width: 16,
      ink: BrandInk.body,
    ),
    // y: the tail.
    BrandStroke(
      start: BrandPoint(418, 108),
      curves: [
        BrandCubic(
          BrandPoint(418, 160),
          BrandPoint(418, 196),
          BrandPoint(415, 232),
        ),
        BrandCubic(
          BrandPoint(412, 262),
          BrandPoint(386, 272),
          BrandPoint(360, 254),
        ),
      ],
      width: 16,
      ink: BrandInk.body,
    ),
  ];

  /// The i's dot: a vermilion full stop over the i, dotted last.
  static const BrandDot iDot = BrandDot(
    center: BrandPoint(283, 72),
    radius: 11,
  );

  /// The ✓erily wordmark, in writing order.
  static const BrandGlyph wordmark = BrandGlyph(
    strokes: [checkV, ...erily],
    dots: [iDot],
  );

  /// Where the wordmark's letters sit: the baseline.
  static const double wordmarkBaseline = 200;

  /// The top of the wordmark's lowercase letters.
  static const double wordmarkXHeight = 106;

  /// The box the wordmark's ink covers.
  static final BrandBox wordmarkBox = wordmark.inkBounds;

  /// The horizontal lockup: the mark as tall as the wordmark from ascender
  /// to descender, its pen as heavy as the check-v, a short gap, then the
  /// wordmark.
  static final BrandGlyph horizontalLockup = BrandGlyph(
    strokes: [
      _placeMark(
        height: wordmarkBox.height * 1.04,
        weight: checkV.width,
        centerY: wordmarkBox.center.y,
        right: wordmarkBox.left - wordmarkBox.height * 0.17,
      ),
      ...wordmark.strokes,
    ],
    dots: wordmark.dots,
  );

  /// The box the horizontal lockup's ink covers.
  static final BrandBox horizontalLockupBox = horizontalLockup.inkBounds;

  /// The stacked lockup: the mark centred over the wordmark.
  static final BrandGlyph stackedLockup = BrandGlyph(
    strokes: [
      _placeMark(
        height: wordmarkBox.height * 1.3,
        weight: checkV.width * 1.2,
        centerX: wordmarkBox.center.x,
        bottom: wordmarkBox.top - wordmarkBox.height * 0.2,
      ),
      ...wordmark.strokes,
    ],
    dots: wordmark.dots,
  );

  /// The box the stacked lockup's ink covers.
  static final BrandBox stackedLockupBox = stackedLockup.inkBounds;

  /// The side of the app icon's square artboard.
  static const double appIconArtboard = 1024;

  /// The corner radius of the rounded square in the app icon preview.
  /// Launchers apply their own mask, so the launcher PNG is full-bleed.
  static const double appIconCornerRadius = 228;

  /// The app icon's mark: paper ink at [iconWeight], 60% of the icon tall,
  /// centred on its ink.
  static final BrandStroke appIconMark = _placeMark(
    height: appIconArtboard * 0.6,
    weight: iconWeight * appIconArtboard * 0.6 / 440,
    centerX: appIconArtboard / 2,
    centerY: appIconArtboard / 2,
  );

  /// The side of an Android adaptive icon's artboard, in dp.
  static const double adaptiveIconArtboard = 108;

  /// The radius of the circle every launcher mask keeps, in dp.
  static const double adaptiveIconSafeRadius = 33;

  /// The adaptive icon's foreground mark: the app icon's proportions, shrunk
  /// until every bit of ink sits inside [adaptiveIconSafeRadius] with a
  /// little air to spare.
  static final BrandStroke adaptiveIconMark = () {
    const center = BrandPoint(
      adaptiveIconArtboard / 2,
      adaptiveIconArtboard / 2,
    );
    const allowed = adaptiveIconSafeRadius - 1.5;
    final unit = appIconMark.transform(
      scale: 1 / appIconArtboard,
      dx: -0.5,
      dy: -0.5,
    );
    var reach = 0.0;
    for (final point in unit.sample()) {
      reach = math.max(reach, math.sqrt(point.x * point.x + point.y * point.y));
    }
    reach += unit.width / 2;
    return unit.transform(
      scale: allowed / reach,
      dx: center.x,
      dy: center.y,
    );
  }();

  /// The mark scaled so its ink is [height] tall with a pen [weight] wide
  /// after scaling, then placed by its ink box.
  static BrandStroke _placeMark({
    required double height,
    required double weight,
    double? centerX,
    double? centerY,
    double? right,
    double? bottom,
  }) {
    // The ink box depends on the pen width, which depends on the scale, so
    // settle the two together.
    var ink = markGlyph.inkBounds;
    var scale = height / ink.height;
    for (var i = 0; i < 4; i++) {
      ink = BrandGlyph(strokes: [mark.withWidth(weight / scale)]).inkBounds;
      scale = height / ink.height;
    }
    final scaled = BrandBox(
      ink.left * scale,
      ink.top * scale,
      ink.width * scale,
      ink.height * scale,
    );
    final dx = centerX != null
        ? centerX - scaled.center.x
        : right! - scaled.right;
    final dy = centerY != null
        ? centerY - scaled.center.y
        : bottom! - scaled.bottom;
    return mark
        .withWidth(weight / scale)
        .transform(scale: scale, dx: dx, dy: dy);
  }

  /// The radius of the stamp's heavy outer ring, in stamp units around the
  /// stamp's centre.
  static const double stampOuterRadius = 196;

  /// The outer ring's pen width.
  static const double stampOuterWeight = 16;

  /// The radius of the stamp's fine inner ring.
  static const double stampInnerRadius = 160;

  /// The inner ring's pen width.
  static const double stampInnerWeight = 7;

  /// How far the stamp is turned, in degrees: it is pressed by hand.
  static const double stampTilt = -8;

  /// The stamp's check: the wordmark's check-v, scaled up and centred in the
  /// inner ring, so there is one check in the whole brand.
  ///
  /// The check's box is centred a little left of and below the ring's centre,
  /// where its weight sits, with air between every end and the inner ring.
  static final BrandStroke stampCheck = checkV.transform(
    scale: _stampCheckScale,
    dx: -6 - 54 * _stampCheckScale,
    dy: 8 - 142 * _stampCheckScale,
  );

  static const double _stampCheckScale = 2.05;
}

/// Formats [value] for SVG: at most two decimals, no trailing zeros.
String svgNumber(double value) {
  final fixed = value.toStringAsFixed(2);
  if (!fixed.contains('.')) return fixed;
  final trimmed = fixed.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.endsWith('.')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
