import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_brand/src/colors.dart';
import 'package:verily_brand/src/geometry.dart';
import 'package:verily_brand/src/ink.dart';
import 'package:verily_brand/src/stamp_motion.dart';

/// The verified stamp: a hand-pressed double ring in vermilion with the
/// brand's check inside, turned a little, the way a stamp lands.
///
/// It marks proof that passed verification, and nothing else. It is a UI
/// element, not the logo.
///
/// [pressed] runs the stamp-slam from 0 (in the air, unseen) to 1 (settled
/// on the page). The stamp meets the paper at [impact].
class VerifiedStamp extends StatelessWidget {
  /// Stamps a [size] square.
  const VerifiedStamp({
    super.key,
    this.size = 96,
    this.color = VerilyBrandColors.stamp,
    this.pressed = 1,
    this.rough = true,
    this.seed = 4,
    this.semanticLabel = 'Verified',
  });

  /// When the stamp meets the paper, as a fraction of [pressed].
  static const double impact = StampMotion.impact;

  /// The side of the stamp's square, in logical pixels. The slam briefly
  /// draws beyond it.
  final double size;

  /// The stamp's ink. Use [VerilyBrandColors.stampOnNight] on night paper.
  final Color color;

  /// How far through the slam the stamp is, from 0 to 1.
  ///
  /// When the platform or a `WiredMotion` ancestor turns motion off, the
  /// stamp skips the slam: it is absent before [impact] and settled after.
  final double pressed;

  /// Whether to ink in the seeded hand with a rubber-stamp texture, or as
  /// clean vectors.
  final bool rough;

  /// The hand and the texture: the same seed always presses the same stamp.
  final int seed;

  /// The label read by screen readers, or null when it is decoration.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final still = !WiredMotion.enabledOf(context);
    final paint = CustomPaint(
      size: Size.square(size),
      painter: VerifiedStampPainter(
        color: color,
        pressed: still ? (pressed < impact ? 0 : 1) : pressed,
        rough: rough,
        seed: seed,
      ),
    );
    final label = semanticLabel;
    if (label == null || pressed < impact) {
      return ExcludeSemantics(child: paint);
    }
    return Semantics(label: label, image: true, child: paint);
  }
}

/// Paints the [VerifiedStamp], centred in its canvas.
class VerifiedStampPainter extends CustomPainter {
  /// Paints the stamp [pressed] of the way through its slam.
  VerifiedStampPainter({
    this.color = VerilyBrandColors.stamp,
    this.pressed = 1,
    this.rough = true,
    this.seed = 4,
  });

  /// The stamp's ink.
  final Color color;

  /// How far through the slam the stamp is, from 0 to 1.
  final double pressed;

  /// Whether to ink in the seeded hand with a texture.
  final bool rough;

  /// The hand and the texture.
  final int seed;

  /// The radius the stamp fills, in stamp units, including the outer pen.
  static const double extent =
      VerilyGeometry.stampOuterRadius +
      VerilyGeometry.stampOuterWeight / 2 +
      10;

  static const int _cacheCapacity = 24;
  static final LinkedHashMap<Object, List<RoughDrawing>> _rings =
      LinkedHashMap<Object, List<RoughDrawing>>();

  @override
  void paint(Canvas canvas, Size size) {
    final p = pressed.isFinite ? pressed.clamp(0.0, 1.0) : 1.0;
    if (p <= 0 || size.isEmpty) return;
    const impact = VerifiedStamp.impact;
    final unit = size.shortestSide / (extent * 2);

    // In the air: the stamp drops from above, turning into place.
    final fall = Curves.easeInCubic.transform((p / impact).clamp(0.0, 1.0));
    // On the paper: a squash on impact, a small rebound, then rest.
    final after = ((p - impact) / (1 - impact)).clamp(0.0, 1.0);
    final landed = p >= impact;
    final double scale;
    if (!landed) {
      scale = 1.9 - 0.9 * fall;
    } else {
      final rebound = (after / 0.45).clamp(0.0, 1.0);
      scale = 0.92 + 0.08 * Curves.easeOutBack.transform(rebound);
    }
    final tilt =
        (VerilyGeometry.stampTilt + (landed ? 0 : -14 * (1 - fall))) *
        math.pi /
        180;
    final opacity = landed ? 1.0 : 0.15 + 0.35 * fall;

    final center = size.center(Offset.zero);
    canvas
      ..save()
      ..translate(center.dx, center.dy);

    // The shock of landing: a thin ring that spreads and fades.
    if (landed && after < 0.5) {
      final spread = Curves.easeOutCubic.transform(after / 0.5);
      canvas.drawCircle(
        Offset.zero,
        (extent + 6 + 60 * spread) * unit,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (5 * (1 - spread) + 1) * unit
          ..color = color.withValues(alpha: 0.5 * (1 - spread)),
      );
    }

    canvas
      ..rotate(tilt)
      ..scale(unit * scale);

    // Fresh ink bleeds a little, then settles.
    final bleed = landed ? 1 - Curves.easeOut.transform(after) : 0.0;
    if (bleed > 0) {
      _paintInk(
        canvas,
        color.withValues(alpha: 0.28 * bleed * opacity),
        blur: 6,
      );
    }

    final bounds = Rect.fromCircle(center: Offset.zero, radius: extent + 4);
    // Only the layer paint's alpha matters here.
    canvas.saveLayer(bounds, Paint()..color = color.withValues(alpha: opacity));
    _paintInk(canvas, color);
    if (rough) _paintTexture(canvas);
    canvas
      ..restore()
      ..restore();
  }

  void _paintInk(Canvas canvas, Color ink, {double blur = 0}) {
    if (!rough || blur > 0) {
      final paint = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke;
      if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas
        ..drawCircle(
          Offset.zero,
          VerilyGeometry.stampOuterRadius,
          paint..strokeWidth = VerilyGeometry.stampOuterWeight,
        )
        ..drawCircle(
          Offset.zero,
          VerilyGeometry.stampInnerRadius,
          paint..strokeWidth = VerilyGeometry.stampInnerWeight,
        );
      if (blur > 0) {
        canvas.drawPath(
          BrandInkPainter.pathOf(VerilyGeometry.stampCheck),
          paint
            ..strokeWidth = VerilyGeometry.stampCheck.width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
        return;
      }
    } else {
      for (final ring in _ringsFor(ink)) {
        ring.paint(canvas);
      }
    }
    BrandInkPainter.paint(
      canvas,
      VerilyGeometry.stampCheck,
      color: ink,
      rough: rough,
      seed: seed * 13 + 5,
    );
  }

  List<RoughDrawing> _ringsFor(Color ink) {
    final key = (ink.toARGB32(), seed);
    final rings = _rings.remove(key) ?? _prepareRings(ink);
    _rings[key] = rings;
    if (_rings.length > _cacheCapacity) _rings.remove(_rings.keys.first);
    return rings;
  }

  List<RoughDrawing> _prepareRings(Color ink) {
    RoughDrawing ring(double radius, double width, int ringSeed) {
      final config = DrawConfig.build(
        seed: ringSeed,
        roughness: 2.4,
        maxRandomnessOffset: 2.2,
        curveStepCount: 16,
        pen: const RoughPen(
          startWidth: 0.55,
          endWidth: 0.45,
          taperIn: 2,
          taperOut: 3,
          pressure: 0.12,
          pressureWavelength: 160,
          repeatCoverage: 0.55,
          closureDrift: 0.8,
        ),
      );
      return RoughDrawing(
        Generator(config, NoFiller()).circle(0, 0, radius * 2),
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
        Paint()
          ..color = ink.withValues(alpha: 0)
          ..style = PaintingStyle.fill,
      );
    }

    return [
      ring(
        VerilyGeometry.stampOuterRadius,
        VerilyGeometry.stampOuterWeight,
        seed * 7 + 1,
      ),
      ring(
        VerilyGeometry.stampInnerRadius,
        VerilyGeometry.stampInnerWeight,
        seed * 7 + 2,
      ),
    ];
  }

  /// Knocks seeded specks out of the ink, like a rubber stamp that did not
  /// quite meet the paper everywhere.
  void _paintTexture(Canvas canvas) {
    final random = Randomizer(seed: seed * 9973 + 3);
    // Knock-outs use only their alpha; the colour is irrelevant.
    final knock = Paint()..blendMode = BlendMode.dstOut;
    for (var i = 0; i < 170; i++) {
      final angle = random.next() * math.pi * 2;
      final distance = math.sqrt(random.next()) * extent;
      final radius = 1.2 + random.next() * random.next() * 4.5;
      knock.color = color.withValues(alpha: 0.45 + random.next() * 0.55);
      canvas.drawCircle(
        Offset(math.cos(angle), math.sin(angle)) * distance,
        radius,
        knock,
      );
    }
    // A worn edge: one side of the stamp pressed a little lighter.
    canvas.drawCircle(
      const Offset(extent * 0.55, extent * 0.5),
      extent * 0.75,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..color = color.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
  }

  @override
  bool shouldRepaint(VerifiedStampPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.pressed != pressed ||
      oldDelegate.rough != rough ||
      oldDelegate.seed != seed;
}
