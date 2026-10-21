/// The drawing kit Verily's launch reel and cover share: timing helpers, the
/// field-notebook paper, type, and the sketched props (a phone, a map with a
/// hatched radius, a stick figure, coins, the escrow jar, ticks, bubbles).
///
/// Everything is drawn with Skribble's seeded rough engine and is a pure
/// function of its inputs, so a frame renders the same way every time.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:skribble/skribble.dart';
import 'package:verily_brand/verily_brand.dart';

// ---------------------------------------------------------------------------
// Timing
// ---------------------------------------------------------------------------

/// 0→1 over [start, end] seconds.
double span(double t, double start, double end) =>
    ((t - start) / (end - start)).clamp(0.0, 1.0);

/// Fades in over [fade] seconds from [start] and out before [end].
double presence(double t, double start, double end, {double fade = .35}) {
  if (t < start || t > end) return 0;
  return math.min(span(t, start, start + fade), 1 - span(t, end - fade, end));
}

/// Eases in and out over 0→1.
double easeInOut(double t) => Curves.easeInOutCubic.transform(t.clamp(0, 1));

/// Eases out over 0→1.
double easeOut(double t) => Curves.easeOutCubic.transform(t.clamp(0, 1));

/// Overshoots a little over 0→1, for things that pop into place.
double popIn(double t) => Curves.easeOutBack.transform(t.clamp(0, 1));

// ---------------------------------------------------------------------------
// Type and theme
// ---------------------------------------------------------------------------

/// The reel and cover's type: Skribble's playful hand for display, its
/// linear sibling for small text.
abstract final class PromoType {
  /// The package the Skribble typefaces ship in.
  static const String package = 'skribble_font_recursive';

  /// The display face.
  static const String display = 'SkribblePlayful';

  /// The text face for small sizes.
  static const String text = 'SkribbleLinearPlayful';

  /// A display style: heavy, tight, and hand-lettered.
  static TextStyle headline(
    double size, {
    Color color = VerilyBrandColors.ink,
    FontWeight weight = FontWeight.w800,
  }) => TextStyle(
    fontFamily: display,
    package: package,
    fontSize: size,
    fontWeight: weight,
    height: 1.08,
    color: color,
    decoration: TextDecoration.none,
  );

  /// A text style for labels and phone UI.
  static TextStyle body(
    double size, {
    Color color = VerilyBrandColors.ink,
    FontWeight weight = FontWeight.w600,
  }) => TextStyle(
    fontFamily: text,
    package: package,
    fontSize: size,
    fontWeight: weight,
    height: 1.2,
    color: color,
    decoration: TextDecoration.none,
  );
}

/// The Skribble theme on Verily's paper.
WiredThemeData promoTheme({bool night = false}) => WiredThemeData(
  borderColor: night ? VerilyBrandColors.paper : VerilyBrandColors.ink,
  textColor: night ? VerilyBrandColors.paper : VerilyBrandColors.ink,
  disabledTextColor: night
      ? VerilyBrandColors.mutedPaper
      : VerilyBrandColors.mutedInk,
  fillColor: night ? VerilyBrandColors.night : VerilyBrandColors.paper,
  markerColor: VerilyBrandColors.rewardWash,
  strokeWidth: 2.6,
);

/// The paper, theme, and default type a promo scene draws on.
class PromoStage extends StatelessWidget {
  /// Draws [child] on the field notebook's dotted paper.
  const PromoStage({required this.child, this.night = false, super.key});

  /// Whether to draw on night paper.
  final bool night;

  /// The scene.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = promoTheme(night: night);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: WiredTheme(
        data: theme,
        child: DefaultTextStyle(
          style: PromoType.body(22, color: theme.textColor),
          child: CustomPaint(
            painter: _DottedPaperPainter(night: night),
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}

class _DottedPaperPainter extends CustomPainter {
  const _DottedPaperPainter({required this.night});

  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = night ? VerilyBrandColors.night : VerilyBrandColors.paper,
    );
    final dot = Paint()
      ..color = (night ? VerilyBrandColors.paper : VerilyBrandColors.ink)
          .withValues(alpha: night ? 0.1 : 0.13);
    const gap = 24.0;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DottedPaperPainter oldDelegate) =>
      oldDelegate.night != night;
}

// ---------------------------------------------------------------------------
// The sketching pen
// ---------------------------------------------------------------------------

/// Draws rough shapes with Skribble's playful pen.
///
/// Every shape takes a seed: the same seed always draws the same wobble, so a
/// prop that moves between frames keeps its hand.
final class SketchPen {
  /// A pen drawing on [canvas].
  const SketchPen(this.canvas);

  /// The canvas being drawn on.
  final Canvas canvas;

  static DrawConfig _config(int seed, {double roughness = 1.1}) =>
      DrawConfig.build(
        seed: seed,
        roughness: roughness,
        maxRandomnessOffset: 1.2,
        lineWobble: 0.35,
        pen: RoughPen.ink,
      );

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Paint _fill(Color? fill, {bool hatched = false, double width = 1.6}) =>
      Paint()
        ..color = fill ?? VerilyBrandColors.paper.withValues(alpha: 0)
        ..style = hatched ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = width;

  static Filler _filler(
    DrawConfig config, {
    required bool solid,
    required bool hatched,
    double gap = 8,
    double angle = -41,
  }) {
    final fillerConfig = FillerConfig.build(
      drawConfig: config,
      hachureGap: gap,
      hachureAngle: angle,
    );
    if (hatched) return HachureFiller(fillerConfig);
    if (solid) return SolidFiller(fillerConfig);
    return NoFiller(fillerConfig);
  }

  void _draw(
    Drawable drawable,
    Paint border,
    Paint fill, {
    double progress = 1,
  }) {
    if (progress <= 0) return;
    RoughDrawing(drawable, border, fill).paint(canvas, progress: progress);
  }

  /// A straight stroke from [a] to [b].
  void line(
    Offset a,
    Offset b, {
    required Color color,
    double width = 2.6,
    int seed = 1,
    double progress = 1,
  }) {
    final config = _config(seed);
    _draw(
      Generator(config, NoFiller()).line(a.dx, a.dy, b.dx, b.dy),
      _stroke(color, width),
      _fill(null),
      progress: progress * 0.65,
    );
  }

  /// A smooth stroke through [points].
  void curve(
    List<Offset> points, {
    required Color color,
    double width = 2.6,
    int seed = 1,
    double progress = 1,
  }) {
    final config = _config(seed);
    _draw(
      Generator(
        config,
        NoFiller(),
      ).curvePath([for (final p in points) PointD(p.dx, p.dy)]),
      _stroke(color, width),
      _fill(null),
      progress: progress * 0.65,
    );
  }

  /// An ellipse filling [rect], optionally washed with [fill] or hatched
  /// with [hatch].
  void ellipse(
    Rect rect, {
    required Color color,
    double width = 2.6,
    Color? fill,
    Color? hatch,
    double hatchGap = 8,
    double hatchAngle = -41,
    int seed = 1,
    double progress = 1,
  }) {
    final config = _config(seed);
    final hatched = hatch != null;
    _draw(
      Generator(
        config,
        _filler(
          config,
          solid: fill != null,
          hatched: hatched,
          gap: hatchGap,
          angle: hatchAngle,
        ),
      ).ellipse(rect.center.dx, rect.center.dy, rect.width, rect.height),
      _stroke(color, width),
      _fill(hatch ?? fill, hatched: hatched),
      progress: progress,
    );
  }

  /// A rounded rectangle filling [rect], optionally washed or hatched.
  void roundedRect(
    Rect rect, {
    required Color color,
    double radius = 12,
    double width = 2.6,
    Color? fill,
    Color? hatch,
    double hatchGap = 8,
    int seed = 1,
    double progress = 1,
  }) {
    final config = _config(seed);
    final hatched = hatch != null;
    _draw(
      Generator(
        config,
        _filler(config, solid: fill != null, hatched: hatched, gap: hatchGap),
      ).roundedRectangle(
        rect.left,
        rect.top,
        rect.width,
        rect.height,
        radius,
        radius,
        radius,
        radius,
      ),
      _stroke(color, width),
      _fill(hatch ?? fill, hatched: hatched),
      progress: progress,
    );
  }

  /// A closed polygon through [points], optionally washed or hatched.
  void polygon(
    List<Offset> points, {
    required Color color,
    double width = 2.6,
    Color? fill,
    Color? hatch,
    double hatchGap = 8,
    int seed = 1,
  }) {
    final config = _config(seed);
    final hatched = hatch != null;
    _draw(
      Generator(
        config,
        _filler(config, solid: fill != null, hatched: hatched, gap: hatchGap),
      ).polygon([for (final p in points) PointD(p.dx, p.dy)]),
      _stroke(color, width),
      _fill(hatch ?? fill, hatched: hatched),
    );
  }
}

/// A [CustomPaint] that draws with a [SketchPen].
class Sketch extends StatelessWidget {
  /// Paints [draw] in a canvas of [size] (or the parent's size).
  const Sketch({required this.draw, this.size = Size.zero, super.key});

  /// What to draw.
  final void Function(SketchPen pen, Size size) draw;

  /// The canvas size; zero takes the parent's size.
  final Size size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: size, painter: _SketchPainter(draw));
}

class _SketchPainter extends CustomPainter {
  _SketchPainter(this.draw);

  final void Function(SketchPen pen, Size size) draw;

  @override
  void paint(Canvas canvas, Size size) => draw(SketchPen(canvas), size);

  @override
  bool shouldRepaint(_SketchPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Writing on
// ---------------------------------------------------------------------------

/// Reveals [child] from left to right as [progress] goes from 0 to 1, with a
/// soft leading edge, the way a line of handwriting appears.
class WriteOn extends StatelessWidget {
  /// Writes [child] on.
  const WriteOn({required this.progress, required this.child, super.key});

  /// How much is written, from 0 to 1.
  final double progress;

  /// The writing.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    if (p >= 1) return child;
    if (p <= 0) return Opacity(opacity: 0, child: child);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          VerilyBrandColors.ink,
          VerilyBrandColors.ink.withValues(alpha: 0),
        ],
        stops: [math.max(0, p * 1.06 - 0.06), p * 1.06],
      ).createShader(bounds),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Props
// ---------------------------------------------------------------------------

/// A hand-drawn phone whose screen shows [child].
class PhoneSketch extends StatelessWidget {
  /// Draws a phone [size] with [child] on its screen.
  const PhoneSketch({
    required this.child,
    this.size = const Size(280, 500),
    this.night = false,
    this.seed = 21,
    super.key,
  });

  /// The phone's outer size.
  final Size size;

  /// What the screen shows.
  final Widget child;

  /// Whether the phone sits on night paper.
  final bool night;

  /// The hand.
  final int seed;

  /// The gap between the phone's edge and its screen.
  static const EdgeInsets bezel = EdgeInsets.fromLTRB(12, 34, 12, 18);

  @override
  Widget build(BuildContext context) {
    final ink = night ? VerilyBrandColors.paper : VerilyBrandColors.ink;
    final paper = night ? VerilyBrandColors.night : VerilyBrandColors.paper;
    return SizedBox.fromSize(
      size: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Sketch(
              draw: (pen, size) {
                pen
                  ..roundedRect(
                    (Offset.zero & size).deflate(3),
                    color: ink,
                    radius: 34,
                    width: 3.2,
                    fill: paper,
                    seed: seed,
                  )
                  ..line(
                    Offset(size.width / 2 - 22, 17),
                    Offset(size.width / 2 + 22, 17),
                    color: ink,
                    width: 3,
                    seed: seed + 1,
                  );
              },
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: bezel,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A coin of [diameter] with its amount on its face.
class CoinSketch extends StatelessWidget {
  /// Draws a gold coin.
  const CoinSketch({this.diameter = 44, this.label = '5', super.key});

  /// The coin's diameter.
  final double diameter;

  /// What is written on the coin.
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: diameter,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Sketch(
            draw: (pen, size) {
              final rect = (Offset.zero & size).deflate(2);
              pen
                ..ellipse(
                  rect,
                  color: VerilyBrandColors.reward,
                  fill: VerilyBrandColors.rewardWash,
                  seed: 31,
                )
                ..ellipse(
                  rect.deflate(diameter * 0.14),
                  color: VerilyBrandColors.reward,
                  width: 1.4,
                  seed: 32,
                );
            },
          ),
        ),
        Text(
          label,
          style: PromoType.headline(
            diameter * 0.42,
            color: VerilyBrandColors.reward,
            weight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

/// The escrow jar: the reward sits in it, locked, before anyone starts.
class EscrowJar extends StatelessWidget {
  /// Draws the jar holding [coins] coins, its lid [closed] (0 to 1) and its
  /// padlock [locked] (0 to 1).
  const EscrowJar({
    this.size = const Size(130, 160),
    this.coins = 0,
    this.closed = 1,
    this.locked = 1,
    this.label = 'escrow',
    super.key,
  });

  /// The jar's size.
  final Size size;

  /// How many coins are inside.
  final int coins;

  /// How far the lid has come down, from 0 (off) to 1 (on).
  final double closed;

  /// How far the padlock has snapped shut, from 0 to 1.
  final double locked;

  /// The label on the jar.
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: Stack(
      children: [
        Positioned.fill(
          child: Sketch(draw: _paint),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: size.height * 0.44,
          child: Center(
            child: Text(
              label,
              style: PromoType.body(size.width * 0.15, weight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );

  void _paint(SketchPen pen, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Rect.fromLTWH(w * 0.08, h * 0.2, w * 0.84, h * 0.78);
    // Coins stacked inside, drawn first so the glass outline sits on top.
    for (var i = 0; i < coins; i++) {
      final row = i ~/ 3;
      final column = i % 3;
      final center = Offset(
        body.left + body.width * (0.25 + 0.25 * column) + (row.isOdd ? 8 : 0),
        body.bottom - 12 - row * 11,
      );
      pen.ellipse(
        Rect.fromCenter(center: center, width: w * 0.24, height: 11),
        color: VerilyBrandColors.reward,
        width: 2,
        fill: VerilyBrandColors.rewardWash,
        seed: 40 + i,
      );
    }
    pen
      ..roundedRect(
        body,
        color: VerilyBrandColors.ink,
        radius: 22,
        width: 3,
        seed: 51,
      )
      // The glint on the glass.
      ..curve(
        [
          Offset(body.left + 12, body.top + 22),
          Offset(body.left + 10, body.top + 44),
          Offset(body.left + 12, body.top + 64),
        ],
        color: VerilyBrandColors.mutedInk.withValues(alpha: 0.5),
        width: 2.2,
        seed: 52,
      );
    // The lid comes down from above.
    final open = 1 - closed.clamp(0.0, 1.0);
    final lid = Rect.fromLTWH(
      w * 0.02 + open * w * 0.1,
      h * 0.08 - open * h * 0.12,
      w * 0.96,
      h * 0.13,
    );
    pen.canvas
      ..save()
      ..translate(lid.center.dx, lid.center.dy)
      ..rotate(-0.35 * open)
      ..translate(-lid.center.dx, -lid.center.dy);
    pen.roundedRect(
      lid,
      color: VerilyBrandColors.ink,
      radius: 6,
      width: 3,
      fill: VerilyBrandColors.rewardWash,
      seed: 53,
    );
    pen.canvas.restore();
    // The padlock hangs from the front of the lid.
    if (closed >= 1) {
      final lock = Rect.fromLTWH(w * 0.39, h * 0.22, w * 0.22, h * 0.13);
      final shackleDrop = (1 - locked.clamp(0.0, 1.0)) * 8;
      pen
        ..curve(
          [
            Offset(lock.left + lock.width * 0.2, lock.top + 2),
            Offset(lock.left + lock.width * 0.2, lock.top - 9 - shackleDrop),
            Offset(lock.center.dx, lock.top - 14 - shackleDrop),
            Offset(lock.right - lock.width * 0.2, lock.top - 9 - shackleDrop),
            Offset(lock.right - lock.width * 0.2, lock.top + 2 - shackleDrop),
          ],
          color: VerilyBrandColors.reward,
          width: 3,
          seed: 54,
        )
        ..roundedRect(
          lock,
          color: VerilyBrandColors.reward,
          radius: 4,
          fill: VerilyBrandColors.rewardWash,
          seed: 55,
        );
    }
  }
}

/// A stick figure seen from the side, facing right, for squats and cheers.
class StickFigure extends StatelessWidget {
  /// Draws the figure [height] tall.
  const StickFigure({
    this.height = 160,
    this.squat = 0,
    this.cheer = 0,
    this.hop = 0,
    this.color = VerilyBrandColors.ink,
    this.background = VerilyBrandColors.paper,
    this.seed = 61,
    super.key,
  });

  /// The paper behind the figure; its head is filled with it so lines
  /// behind the figure do not show through.
  final Color background;

  /// The figure's standing height, feet to crown.
  final double height;

  /// How deep the squat is, from 0 (standing) to 1 (thighs level).
  final double squat;

  /// How far the arms are raised in celebration, from 0 to 1.
  final double cheer;

  /// How high the figure is jumping, from 0 to 1.
  final double hop;

  /// The ink.
  final Color color;

  /// The hand.
  final int seed;

  @override
  Widget build(BuildContext context) => Sketch(
    size: Size(height * 128 / 170, height),
    draw: _paint,
  );

  void _paint(SketchPen pen, Size size) {
    // Joints are laid out on a 128 x 170 grid, feet at the bottom, facing
    // right, then scaled to the figure's height.
    final s = size.height / 170;
    final d = Curves.easeInOutSine.transform(squat.clamp(0.0, 1.0));
    final c = cheer.clamp(0.0, 1.0);
    final lift = hop.clamp(0.0, 1.0) * 14;
    Offset at(Offset joint) => Offset(joint.dx * s, (joint.dy - lift) * s);
    const thigh = 38.0;
    const shin = 38.0;
    const ankle = Offset(58, 164);
    // The hips sink and travel back as the knees bend.
    final hip = Offset(58 - 30 * d, 89 + 40 * d);
    // The knee, from the two leg lengths, bends forward (to the right).
    final toHip = hip - ankle;
    final reach = toHip.distance.clamp(1.0, thigh + shin - 0.01);
    final along = (shin * shin - thigh * thigh + reach * reach) / (2 * reach);
    final across = math.sqrt(math.max(0, shin * shin - along * along));
    final unit = toHip / toHip.distance;
    final forward = Offset(-unit.dy, unit.dx);
    final knee = ankle + unit * along + forward * across;
    // The torso leans forward to keep balance.
    final lean = 0.55 * d;
    final up = Offset(math.sin(lean), -math.cos(lean));
    final shoulder = hip + up * 44;
    final head = shoulder + up * 19;
    // Arms: hanging, reaching forward in the squat, or up in a cheer.
    final rest = 2.75 - 1.2 * d;
    final arm = rest + (0.3 - rest) * c;
    Offset hand(double angle, double length) =>
        shoulder + Offset(math.sin(angle), -math.cos(angle)) * length;
    final width = 3.4 * s;

    void limb(Offset a, Offset b, int i) =>
        pen.line(at(a), at(b), color: color, width: width, seed: seed + i);

    limb(hip, knee, 0);
    limb(knee, ankle, 1);
    limb(ankle, ankle + const Offset(15, 0), 2);
    limb(hip, shoulder, 3);
    limb(shoulder, hand(arm - 0.25 - 0.45 * c, 40), 4);
    limb(shoulder, hand(arm + 0.12 + 0.3 * c, 42), 5);
    pen.ellipse(
      Rect.fromCircle(center: at(head), radius: 13 * s),
      color: color,
      fill: background,
      width: width,
      seed: seed + 6,
    );
  }
}

/// A tick box: a Skribble box with the brand's vermilion check drawn into
/// it as [progress] goes from 0 to 1.
class ProofTick extends StatelessWidget {
  /// Draws the box, [size] square, ticked [progress] of the way.
  const ProofTick({required this.progress, this.size = 30, super.key});

  /// How much of the check is drawn.
  final double progress;

  /// The box's side.
  final double size;

  @override
  Widget build(BuildContext context) => Sketch(
    size: Size.square(size),
    draw: (pen, size) {
      pen.roundedRect(
        (Offset.zero & size).deflate(2),
        color: WiredTheme.of(context).borderColor,
        radius: 5,
        width: 2.4,
        seed: 71 + size.width.round(),
      );
      if (progress <= 0) return;
      // The check's centre sits a little low in the box, and its long arm
      // reaches past the top edge, the way a quick tick does.
      const check = VerilyGeometry.checkV;
      final scale = size.height * 1.1 / 116;
      pen.canvas
        ..save()
        ..translate(
          size.width * 0.52 - 54 * scale,
          size.height * 0.5 - 142 * scale,
        )
        ..scale(scale);
      BrandInkPainter.paint(
        pen.canvas,
        check,
        color: VerilyBrandColors.stamp,
        progress: easeOut(progress),
        weight: 1.15,
        seed: 7,
      );
      pen.canvas.restore();
    },
  );
}

/// A speech bubble with a tail pointing down and to the left.
class SpeechBubble extends StatelessWidget {
  /// Wraps [child] in a bubble.
  const SpeechBubble({
    required this.child,
    this.fill = VerilyBrandColors.paper,
    this.tailOnLeft = true,
    this.seed = 81,
    super.key,
  });

  /// What is said.
  final Widget child;

  /// The bubble's wash.
  final Color fill;

  /// Whether the tail sits at the bottom left (or right).
  final bool tailOnLeft;

  /// The hand.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final ink = WiredTheme.of(context).borderColor;
    return CustomPaint(
      painter: _BubblePainter(
        ink: ink,
        fill: fill,
        tailOnLeft: tailOnLeft,
        seed: seed,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({
    required this.ink,
    required this.fill,
    required this.tailOnLeft,
    required this.seed,
  });

  final Color ink;
  final Color fill;
  final bool tailOnLeft;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = SketchPen(canvas);
    final body = Rect.fromLTWH(2, 2, size.width - 4, size.height - 14);
    final x = tailOnLeft ? body.left + 22 : body.right - 22;
    final tip = Offset(tailOnLeft ? x - 10 : x + 10, size.height);
    pen
      ..polygon(
        [Offset(x - 10, body.bottom - 4), tip, Offset(x + 10, body.bottom - 4)],
        color: ink,
        fill: fill,
        seed: seed + 1,
      )
      ..roundedRect(
        body,
        color: ink,
        radius: 14,
        fill: fill,
        seed: seed,
      );
    // Paper over the seam so the tail joins the bubble.
    canvas.drawLine(
      Offset(x - 7, body.bottom - 1),
      Offset(x + 7, body.bottom - 1),
      Paint()
        ..color = fill
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.fill != fill ||
      oldDelegate.tailOnLeft != tailOnLeft ||
      oldDelegate.seed != seed;
}

/// A map pin in place green, drawn as a teardrop with a hole.
void drawPlacePin(
  SketchPen pen,
  Offset point, {
  double size = 34,
  int seed = 91,
}) {
  final head = Offset(point.dx, point.dy - size * 0.72);
  final r = size * 0.36;
  pen
    ..polygon(
      [
        point,
        head + Offset(-r * 0.92, r * 0.42),
        head + Offset(-r, -r * 0.1),
        head + Offset(-r * 0.7, -r * 0.72),
        head + Offset(0, -r),
        head + Offset(r * 0.7, -r * 0.72),
        head + Offset(r, -r * 0.1),
        head + Offset(r * 0.92, r * 0.42),
      ],
      color: VerilyBrandColors.place,
      fill: VerilyBrandColors.place,
      width: 2.4,
      seed: seed,
    )
    ..ellipse(
      Rect.fromCircle(center: head, radius: r * 0.38),
      color: VerilyBrandColors.paper,
      fill: VerilyBrandColors.paper,
      width: 1.6,
      seed: seed + 1,
    );
}

/// A sketched park map: a street, the park and its trees, the action's
/// hatched radius, and its pin on the bandstand.
class SketchMap extends StatelessWidget {
  /// Draws the map with the radius drawn [radius] of the way (0 to 1), the
  /// pin dropped [pin] of the way, and, when [you] is set, the participant's
  /// dot pulsing at [pulse] seconds.
  const SketchMap({
    this.radius = 1,
    this.pin = 1,
    this.you,
    this.pulse = 0,
    super.key,
  });

  /// How much of the radius circle is drawn.
  final double radius;

  /// How far the pin has dropped, from 0 (above) to 1 (planted).
  final double pin;

  /// Where the participant is, as a fraction of the map's size.
  final Offset? you;

  /// Time for the participant dot's pulse, in seconds.
  final double pulse;

  @override
  Widget build(BuildContext context) => Sketch(draw: _paint);

  void _paint(SketchPen pen, Size size) {
    final w = size.width;
    final h = size.height;
    const street = VerilyBrandColors.mutedInk;
    final faint = street.withValues(alpha: 0.55);
    // The park.
    pen
      ..polygon(
        [
          Offset(w * 0.12, h * 0.16),
          Offset(w * 0.82, h * 0.1),
          Offset(w * 0.9, h * 0.78),
          Offset(w * 0.2, h * 0.88),
        ],
        color: VerilyBrandColors.place.withValues(alpha: 0.5),
        fill: VerilyBrandColors.placeWash,
        width: 2,
        seed: 101,
      )
      // A street along the bottom, and a path across the park.
      ..line(
        Offset(0, h * 0.95),
        Offset(w, h * 0.86),
        color: faint,
        width: 5,
        seed: 102,
      )
      ..curve(
        [
          Offset(w * 0.1, h * 0.7),
          Offset(w * 0.32, h * 0.6),
          Offset(w * 0.5, h * 0.48),
          Offset(w * 0.72, h * 0.3),
          Offset(w * 0.86, h * 0.22),
        ],
        color: faint,
        width: 2.4,
        seed: 104,
      );
    // Trees.
    for (final (i, tree) in const [
      Offset(0.22, 0.28),
      Offset(0.3, 0.8),
      Offset(0.78, 0.68),
      Offset(0.72, 0.18),
    ].indexed) {
      pen.ellipse(
        Rect.fromCircle(center: Offset(w * tree.dx, h * tree.dy), radius: 9),
        color: VerilyBrandColors.place.withValues(alpha: 0.75),
        hatch: VerilyBrandColors.place.withValues(alpha: 0.45),
        hatchGap: 4,
        width: 1.8,
        seed: 110 + i,
      );
    }
    final center = Offset(w * 0.5, h * 0.48);
    // The action's radius: a hatched sage circle in place green.
    if (radius > 0) {
      final rect = Rect.fromCircle(center: center, radius: w * 0.27);
      pen.ellipse(
        rect,
        color: VerilyBrandColors.place,
        width: 2.4,
        hatch: VerilyBrandColors.place.withValues(alpha: 0.35),
        hatchGap: 7,
        seed: 121,
        progress: radius,
      );
    }
    // The participant, pulsing inside the radius.
    if (you case final spot?) {
      final dot = Offset(w * spot.dx, h * spot.dy);
      final phase = (pulse % 1.1) / 1.1;
      pen.canvas.drawCircle(
        dot,
        8 + 18 * phase,
        Paint()
          ..color = VerilyBrandColors.place.withValues(
            alpha: 0.35 * (1 - phase),
          ),
      );
      pen.ellipse(
        Rect.fromCircle(center: dot, radius: 7),
        color: VerilyBrandColors.paper,
        fill: VerilyBrandColors.place,
        width: 2.4,
        seed: 141,
      );
    }
    // The pin drops onto the bandstand.
    if (pin > 0) {
      final drop = Curves.bounceOut.transform(pin.clamp(0.0, 1.0));
      drawPlacePin(pen, center + Offset(0, 12 - 70 * (1 - drop)), size: 44);
    }
  }
}
