/// Verily's 1280×800 launch cover for Slopper.
library;

import 'package:flutter/widgets.dart';
import 'package:skribble/skribble.dart';
import 'package:skribble_emoji/skribble_emoji.dart';
import 'package:verily_brand/promo/promo_kit.dart';
import 'package:verily_brand/verily_brand.dart';

/// The cover's size, in logical pixels.
const Size kLaunchCoverSize = Size(1280, 800);

/// The launch cover: the promise on the left, a stamped proof on the right.
///
/// [night] draws it on night paper.
class LaunchCover extends StatelessWidget {
  /// Draws the cover.
  const LaunchCover({this.night = false, super.key});

  /// Whether to draw on night paper.
  final bool night;

  @override
  Widget build(BuildContext context) {
    final ink = night ? VerilyBrandColors.paper : VerilyBrandColors.ink;
    final muted = night
        ? VerilyBrandColors.mutedPaper
        : VerilyBrandColors.mutedInk;
    final accent = night
        ? VerilyBrandColors.stampOnNight
        : VerilyBrandColors.stamp;
    final reward = night
        ? VerilyBrandColors.rewardOnNight
        : VerilyBrandColors.reward;
    return PromoStage(
      night: night,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: kLaunchCoverSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 76,
                top: 62,
                child: VerilyLockup(
                  height: 70,
                  accentColor: accent,
                  inkColor: ink,
                ),
              ),
              Positioned(
                left: 80,
                top: 186,
                child: Text(
                  'Real things, done in real places',
                  style: PromoType.body(
                    25,
                    color: accent,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                left: 76,
                top: 226,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Do it.', style: PromoType.headline(104, color: ink)),
                    _Underlined(
                      color: accent,
                      child: Text(
                        'Prove it.',
                        style: PromoType.headline(104, color: ink),
                      ),
                    ),
                    _Marked(
                      color: night
                          ? VerilyBrandColors.dusk
                          : VerilyBrandColors.rewardWash,
                      child: Text(
                        'Get paid.',
                        style: PromoType.headline(104, color: ink),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 80,
                top: 604,
                width: 640,
                child: Text(
                  'Post an action at a real place. Do it live, on your '
                  'phone’s camera. The reward sits in escrow before anyone '
                  'starts.',
                  style: PromoType.body(
                    25,
                    color: muted,
                    weight: FontWeight.w500,
                  ).copyWith(height: 1.4),
                ),
              ),
              Positioned(
                left: 80,
                top: 718,
                child: Text(
                  'verily.fun',
                  style: PromoType.headline(30, color: accent),
                ),
              ),
              Positioned(
                left: 836,
                top: 64,
                child: PhoneSketch(
                  size: const Size(340, 676),
                  night: night,
                  seed: 401,
                  child: _CoverScreen(night: night, reward: reward),
                ),
              ),
              // The stamp lands on the proof, over the phone's edge.
              Positioned(
                left: 1004,
                top: 520,
                child: VerifiedStamp(size: 200, color: accent, seed: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The phone's screen: an action, its place, its escrowed reward, and the
/// proof that passed.
class _CoverScreen extends StatelessWidget {
  const _CoverScreen({required this.night, required this.reward});

  final bool night;
  final Color reward;

  @override
  Widget build(BuildContext context) {
    final ink = night ? VerilyBrandColors.paper : VerilyBrandColors.ink;
    final paper = night ? VerilyBrandColors.night : VerilyBrandColors.paper;
    final place = night
        ? VerilyBrandColors.placeOnNight
        : VerilyBrandColors.place;
    return ColoredBox(
      color: paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Action', style: PromoType.headline(26, color: ink)),
            const SizedBox(height: 10),
            WiredCard(
              height: null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    const WiredEmoji('🎺', size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '10 squats at the bandstand',
                        style: PromoType.body(
                          21,
                          color: ink,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 178,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: const ColoredBox(
                        color: VerilyBrandColors.paper,
                        child: SketchMap(),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Sketch(
                      draw: (pen, size) => pen.roundedRect(
                        (Offset.zero & size).deflate(2),
                        color: ink,
                        radius: 14,
                        seed: 411,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The bandstand · 40 m',
              style: PromoType.body(18, color: place, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 58,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Sketch(
                      draw: (pen, size) => pen.roundedRect(
                        (Offset.zero & size).deflate(2),
                        color: reward,
                        radius: 16,
                        fill: night
                            ? VerilyBrandColors.dusk
                            : VerilyBrandColors.rewardWash,
                        seed: 412,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const CoinSketch(diameter: 30),
                        const SizedBox(width: 8),
                        Text(
                          '5 USDC × 50',
                          style: PromoType.body(
                            19,
                            color: ink,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'in escrow',
                          style: PromoType.body(
                            16,
                            color: ink,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const WiredEmoji('🔒', size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Your proof', style: PromoType.headline(22, color: ink)),
            const SizedBox(height: 8),
            Expanded(child: _CoverClip(night: night)),
          ],
        ),
      ),
    );
  }
}

class _CoverClip extends StatelessWidget {
  const _CoverClip({required this.night});

  final bool night;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: ColoredBox(
      color: night ? VerilyBrandColors.dusk : VerilyBrandColors.night,
      child: Stack(
        children: [
          Positioned.fill(
            child: Sketch(
              draw: (pen, size) {
                final faint = VerilyBrandColors.paper.withValues(alpha: .45);
                final c = Offset(size.width * .64, size.height * .42);
                pen
                  ..polygon(
                    [
                      c + const Offset(-50, 0),
                      c + const Offset(0, -30),
                      c + const Offset(50, 0),
                    ],
                    color: faint,
                    fill: night
                        ? VerilyBrandColors.night
                        : VerilyBrandColors.dusk,
                    width: 2,
                    seed: 421,
                  )
                  ..line(
                    c + const Offset(-40, 0),
                    c + const Offset(-40, 60),
                    color: faint,
                    width: 2,
                    seed: 422,
                  )
                  ..line(
                    c + const Offset(40, 0),
                    c + const Offset(40, 60),
                    color: faint,
                    width: 2,
                    seed: 423,
                  )
                  ..line(
                    Offset(8, size.height - 16),
                    Offset(size.width - 8, size.height - 18),
                    color: faint,
                    width: 2,
                    seed: 424,
                  );
              },
            ),
          ),
          Positioned(
            left: 36,
            bottom: 10,
            child: StickFigure(
              height: 118,
              cheer: 1,
              color: VerilyBrandColors.paper,
              background: night
                  ? VerilyBrandColors.dusk
                  : VerilyBrandColors.night,
            ),
          ),
        ],
      ),
    ),
  );
}

/// A vermilion underline drawn under [child] by hand.
class _Underlined extends StatelessWidget {
  const _Underlined({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _UnderlinePainter(color),
    child: child,
  );
}

class _UnderlinePainter extends CustomPainter {
  _UnderlinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * .9;
    SketchPen(canvas).curve(
      [
        Offset(6, y + 2),
        Offset(size.width * .35, y - 3),
        Offset(size.width * .7, y + 1),
        Offset(size.width - 18, y - 6),
      ],
      color: color,
      width: 7,
      seed: 431,
    );
  }

  @override
  bool shouldRepaint(_UnderlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A marker swipe behind [child], held at a slight slant.
class _Marked extends StatelessWidget {
  const _Marked({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _MarkerPainter(color),
    child: child,
  );
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final top = size.height * .42;
    final bottom = size.height * .98;
    final path = Path()
      ..moveTo(-8, top + 6)
      ..quadraticBezierTo(size.width * .5, top - 4, size.width + 10, top - 2)
      ..lineTo(size.width + 6, bottom - 8)
      ..quadraticBezierTo(size.width * .5, bottom + 2, -4, bottom)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MarkerPainter oldDelegate) => oldDelegate.color != color;
}
