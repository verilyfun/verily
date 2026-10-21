/// Verily's 30-second launch reel, drawn entirely with Skribble widgets and
/// the brand's own marks.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:skribble/skribble.dart';
import 'package:skribble_emoji/skribble_emoji.dart';
import 'package:verily_brand/promo/promo_kit.dart';
import 'package:verily_brand/promo/promo_timeline.dart';
import 'package:verily_brand/verily_brand.dart';

export 'package:verily_brand/promo/promo_timeline.dart';

typedef _T = PromoTimeline;

/// The reel's stage, in logical pixels. It renders at 2x for 1920×1080.
const Size kPromoStage = Size(960, 540);

// Where the props stand on the stage.
const Offset _phoneAt = Offset(640, 20);
const Size _phoneSize = Size(270, 500);
final Offset _screenAt =
    _phoneAt + Offset(PhoneSketch.bezel.left, PhoneSketch.bezel.top);
const Offset _jarAt = Offset(448, 330);
const Size _jarSize = Size(148, 184);
const Offset _captionAt = Offset(64, 58);

/// Verily's launch reel: post an action, do it live, prove it, get paid.
///
/// The reel is a pure function of [time]: it renders identically frame by
/// frame (`tool/render_promo_test.dart`, then `tool/render_promo.dart`), and
/// every beat comes from [PromoTimeline], which also scores the sound bed.
class PromoReel extends StatelessWidget {
  /// Draws the reel at [time] seconds from its start.
  const PromoReel({required this.time, super.key});

  /// Seconds since the reel began, from 0 to [PromoTimeline.duration].
  final double time;

  @override
  Widget build(BuildContext context) {
    final t = time;
    // The stamp lands hard enough to nudge the page.
    final since = t - _T.stampImpact;
    final shake = since < 0 || since > .25
        ? Offset.zero
        : Offset(0, 5 * math.sin(since * 60) * (1 - since / .25));
    return PromoStage(
      child: FittedBox(
        child: SizedBox.fromSize(
          size: kPromoStage,
          child: Transform.translate(
            offset: shake,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _scene(t, _T.hook, _Hook(t)),
                _scene(t, _T.create, _CreateCaption(t)),
                _scene(t, _T.doIt, _DoCaption(t)),
                _scene(t, _T.prove, _ProveCaption(t)),
                _scene(t, _T.paid, _PaidCaption(t)),
                _Jar(t),
                _Phone(t),
                _Stamp(t),
                _CreateCoins(t),
                _Payout(t),
                // The end card stays up to the last frame, which players
                // often keep as the poster.
                _scene(
                  t,
                  PromoCue(_T.end.start, _T.duration + 1),
                  _EndCard(t),
                  fade: .45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _scene(
    double t,
    PromoCue cue,
    Widget child, {
    double fade = .3,
  }) {
    final p = presence(t, cue.start, cue.end, fade: fade);
    if (p <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: Opacity(
        opacity: p,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - p)),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

/// A line of display text that writes itself on behind a pencil.
class _Written extends StatelessWidget {
  const _Written(
    this.text, {
    required this.style,
    required this.progress,
    this.strike,
    this.strikeProgress = 0,
  });

  final String text;
  final TextStyle style;
  final double progress;

  /// A word to strike through in vermilion, and how far the pen has gone.
  final String? strike;
  final double strikeProgress;

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final size = painter.size;
    Rect? struck;
    final word = strike;
    if (word != null) {
      final index = text.indexOf(word);
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: index, extentOffset: index + word.length),
      );
      struck = boxes
          .map((box) => box.toRect())
          .reduce((a, b) => a.expandToInclude(b));
    }
    painter.dispose();

    final fadeWord = struck == null
        ? 1.0
        : 1 - 0.55 * span(strikeProgress, .6, 1);
    final spans = <InlineSpan>[];
    if (word != null) {
      final index = text.indexOf(word);
      spans
        ..add(TextSpan(text: text.substring(0, index)))
        ..add(
          TextSpan(
            text: word,
            style: TextStyle(
              color: style.color!.withValues(alpha: fadeWord),
            ),
          ),
        )
        ..add(TextSpan(text: text.substring(index + word.length)));
    } else {
      spans.add(TextSpan(text: text));
    }

    const pencil = 64.0;
    final writing = progress > 0 && progress < 1;
    return SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          WriteOn(
            progress: progress,
            child: Text.rich(TextSpan(style: style, children: spans)),
          ),
          if (struck case final rect? when strikeProgress > 0)
            Positioned.fill(
              child: Sketch(
                draw: (pen, _) {
                  final y = rect.center.dy + rect.height * 0.04;
                  pen
                    ..curve(
                      [
                        Offset(rect.left - 8, y + 4),
                        Offset(rect.left + rect.width * .35, y - 1),
                        Offset(rect.left + rect.width * .7, y + 2),
                        Offset(rect.right + 8, y - 5),
                      ],
                      color: VerilyBrandColors.stamp,
                      width: 6,
                      seed: 201,
                      progress: span(strikeProgress, 0, .6),
                    )
                    ..curve(
                      [
                        Offset(rect.right + 6, y + 3),
                        Offset(rect.left + rect.width * .5, y + 8),
                        Offset(rect.left - 4, y + 9),
                      ],
                      color: VerilyBrandColors.stamp,
                      width: 4.5,
                      seed: 202,
                      progress: span(strikeProgress, .55, 1),
                    );
                },
              ),
            ),
          if (writing)
            Positioned(
              left: size.width * progress - pencil * .1,
              top: size.height * .62 - pencil * .9,
              child: const WiredEmoji('✏️', size: pencil),
            ),
        ],
      ),
    );
  }
}

/// A headline that writes on, with sub-lines that fade in after it.
class _Caption extends StatelessWidget {
  const _Caption({
    required this.t,
    required this.headline,
    required this.write,
    this.lines = const [],
    this.below,
  });

  final double t;
  final String headline;
  final PromoCue write;
  final List<(double, String)> lines;
  final Widget? below;

  @override
  Widget build(BuildContext context) => Positioned(
    left: _captionAt.dx,
    top: _captionAt.dy,
    width: 540,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Written(
          headline,
          style: PromoType.headline(64),
          progress: easeInOut(span(t, write.start, write.end)),
        ),
        const SizedBox(height: 18),
        for (final (at, line) in lines)
          _FadeUp(
            progress: span(t, at, at + .35),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: PromoType.headline(29, weight: FontWeight.w600),
              ),
            ),
          ),
        ?below,
      ],
    ),
  );
}

class _FadeUp extends StatelessWidget {
  const _FadeUp({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: progress.clamp(0.0, 1.0),
    child: Transform.translate(
      offset: Offset(0, 12 * (1 - easeOut(progress))),
      child: child,
    ),
  );
}

/// Scales [child] in with a pop from [at].
Widget _popAt(double t, double at, Widget child, {double length = .4}) {
  final p = span(t, at, at + length);
  if (p <= 0) return const SizedBox.shrink();
  return Opacity(
    opacity: span(t, at, at + .12),
    child: Transform.scale(scale: popIn(p), child: child),
  );
}

// ---------------------------------------------------------------------------
// Hook: Pics, or it didn't happen.
// ---------------------------------------------------------------------------

class _Hook extends StatelessWidget {
  const _Hook(this.t);

  final double t;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        left: 0,
        right: 0,
        // Alone, the line sits mid-page; it rises to make room for the name.
        top:
            206 -
            88 * easeInOut(span(t, _T.strike.end, _T.hookLockup.start + .3)),
        child: Center(
          child: _Written(
            "Pics, or it didn't happen.",
            style: PromoType.headline(58),
            progress: span(t, _T.hookWrite.start, _T.hookWrite.end),
            strike: "didn't",
            strikeProgress: span(t, _T.strike.start, _T.strike.end),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 262,
        child: Center(
          child: VerilyLockup(
            height: 150,
            progress: span(t, _T.hookLockup.start, _T.hookLockup.end),
          ),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Captions
// ---------------------------------------------------------------------------

class _CreateCaption extends StatelessWidget {
  const _CreateCaption(this.t);

  final double t;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _Caption(
        t: t,
        headline: 'Post an action',
        write: _T.createHeadline,
        lines: [
          (_T.pinDrop.start, 'Pin a real place.'),
          (_T.rewardChip, 'Lock the reward first.'),
          (_T.lockSnap, 'Nobody works for a promise.'),
        ],
      ),
      // A doodled arrow from the reward line down to the jar.
      Positioned.fill(
        child: Sketch(
          draw: (pen, _) {
            final p = easeOut(span(t, _T.rewardChip + .25, _T.rewardChip + .8));
            pen
              ..curve(
                const [
                  Offset(414, 200),
                  Offset(474, 208),
                  Offset(512, 246),
                  Offset(524, 312),
                ],
                color: VerilyBrandColors.ink,
                width: 3,
                seed: 341,
                progress: p,
              )
              ..curve(
                const [
                  Offset(508, 296),
                  Offset(516, 306),
                  Offset(524, 314),
                  Offset(536, 298),
                ],
                color: VerilyBrandColors.ink,
                width: 3,
                seed: 342,
                progress: span(p, .85, 1),
              );
          },
        ),
      ),
    ],
  );
}

class _DoCaption extends StatelessWidget {
  const _DoCaption(this.t);

  final double t;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _Caption(
        t: t,
        headline: 'Do it, live.',
        write: _T.doHeadline,
        lines: [
          (_T.doHeadline.end, 'No upload button.'),
          (_T.doHeadline.end + .5, 'The camera is the only way in.'),
          (_T.challenge + .2, 'A fresh word, every try.'),
        ],
      ),
    ],
  );
}

const List<String> _checklist = [
  'Filmed live in Verily',
  'Signed by this phone',
  'Inside the place',
  'Challenge spoken',
  'Checked by Verily',
];

class _ProveCaption extends StatelessWidget {
  const _ProveCaption(this.t);

  final double t;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _Caption(
        t: t,
        headline: 'Prove it.',
        write: _T.proveHeadline,
        below: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, line) in _checklist.indexed)
              _FadeUp(
                progress: span(t, _T.ticks[i] - .35, _T.ticks[i]),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      ProofTick(
                        progress: span(t, _T.ticks[i], _T.ticks[i] + .3),
                        size: 34,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        line,
                        style: PromoType.headline(30, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      // The margin note: the seal you cannot see, pointing at the clip.
      Positioned(
        left: 404,
        top: 60,
        child: _FadeUp(
          progress: span(t, _T.sealNote, _T.sealNote + .4),
          child: SizedBox(
            width: 250,
            height: 150,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 40,
                  top: 0,
                  child: Text(
                    'Sealed.\nInvisibly.',
                    textAlign: TextAlign.right,
                    style: PromoType.headline(
                      32,
                      color: VerilyBrandColors.stamp,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Sketch(
                    draw: (pen, size) {
                      final p = easeOut(
                        span(t, _T.sealNote + .15, _T.sealNote + .6),
                      );
                      pen
                        ..curve(
                          const [
                            Offset(130, 92),
                            Offset(176, 116),
                            Offset(224, 122),
                            Offset(270, 110),
                          ],
                          color: VerilyBrandColors.stamp,
                          width: 3.2,
                          seed: 211,
                          progress: p,
                        )
                        ..line(
                          const Offset(270, 110),
                          const Offset(254, 100),
                          color: VerilyBrandColors.stamp,
                          width: 3.2,
                          seed: 212,
                          progress: span(p, .85, 1),
                        )
                        ..line(
                          const Offset(270, 110),
                          const Offset(256, 122),
                          color: VerilyBrandColors.stamp,
                          width: 3.2,
                          seed: 213,
                          progress: span(p, .85, 1),
                        );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _PaidCaption extends StatelessWidget {
  const _PaidCaption(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final arrive = _T.payout.end;
    final arrived = span(t, arrive - .05, arrive + .25);
    final cheer = easeOut(span(t, arrive - .1, arrive + .25));
    final since = t - arrive;
    final hop = since <= 0
        ? 0.0
        : math.sin(since * math.pi * 2.6).abs() *
              (1 - span(t, arrive, arrive + 1.6));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _Caption(
          t: t,
          headline: 'Get paid.',
          write: _T.paidHeadline,
          lines: [(_T.stampImpact + .2, 'The reward was in escrow all along.')],
        ),
        Positioned(
          left: 150,
          top: 270,
          child: StickFigure(height: 240, cheer: cheer, hop: hop),
        ),
        // A little party when the coin lands.
        for (final (i, (emoji, angle)) in const [
          ('🎉', -2.3),
          ('✨', -1.6),
          ('🎉', -0.9),
        ].indexed)
          if (t > arrive && t < arrive + 1.4)
            () {
              final p = span(t, arrive + i * .06, arrive + 1.2 + i * .06);
              final reach = 30 + 70 * easeOut(p);
              final at =
                  const Offset(236, 300) +
                  Offset(math.cos(angle), math.sin(angle)) * reach;
              return Positioned(
                left: at.dx - 20,
                top: at.dy - 20,
                child: Opacity(
                  opacity: 1 - span(p, .6, 1),
                  child: Transform.scale(
                    scale: popIn(span(p, 0, .3)),
                    child: WiredEmoji(emoji, size: 40),
                  ),
                ),
              );
            }(),
        Positioned(
          left: 300,
          top: 318 - 24 * easeOut(arrived),
          child: Opacity(
            opacity: arrived,
            child: Text(
              '+5 USDC',
              style: PromoType.headline(44, color: VerilyBrandColors.reward),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The phone and its screens
// ---------------------------------------------------------------------------

/// Where the phone is and how visible, as it slides in and away.
({Offset at, double opacity}) _phoneFrame(double t) {
  final opacity = presence(t, _T.phone.start, _T.phone.end, fade: .4);
  final enter = easeOut(span(t, _T.phone.start, _T.phone.start + .55));
  final leave = span(t, _T.phone.end - .4, _T.phone.end);
  return (
    at: _phoneAt + Offset(0, 60 * (1 - enter) + 40 * leave),
    opacity: opacity,
  );
}

class _Phone extends StatelessWidget {
  const _Phone(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final frame = _phoneFrame(t);
    if (frame.opacity <= 0) return const SizedBox.shrink();
    return Positioned(
      left: frame.at.dx,
      top: frame.at.dy,
      child: Opacity(
        opacity: frame.opacity,
        child: PhoneSketch(
          size: _phoneSize,
          child: Stack(
            children: [
              // Screens push in from the right, like an app moving on.
              _screen(t, null, _T.doIt.start, _CreateScreen(t)),
              _screen(t, _T.doIt.start, _T.prove.start, _DoScreen(t)),
              _screen(t, _T.prove.start, null, _ProofScreen(t)),
            ],
          ),
        ),
      ),
    );
  }

  /// How long one screen takes to push the last one away.
  static const double _push = .4;

  /// A screen that pushes in at [arrive] (or is there from the start when
  /// null) and is pushed out at [leave] (or stays when null).
  static Widget _screen(
    double t,
    double? arrive,
    double? leave,
    Widget child,
  ) {
    if (leave != null && t > leave + _push) return const SizedBox.shrink();
    if (arrive != null && t < arrive) return const SizedBox.shrink();
    final enter = arrive == null
        ? 1.0
        : easeInOut(span(t, arrive, arrive + _push));
    final exit = leave == null ? 0.0 : easeInOut(span(t, leave, leave + _push));
    return Positioned.fill(
      child: FractionalTranslation(
        translation: Offset((1 - enter) - exit, 0),
        child: child,
      ),
    );
  }
}

/// The verified stamp, slammed onto the proof on the phone. It lives outside
/// the phone's screen so it can overhang the phone's edge as it lands.
class _Stamp extends StatelessWidget {
  const _Stamp(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final pressed = span(t, _T.stamp.start, _T.stamp.end);
    final frame = _phoneFrame(t);
    if (pressed <= 0 || frame.opacity <= 0) return const SizedBox.shrink();
    const size = 150.0;
    final at = frame.at + _screenAt - _phoneAt + const Offset(96, 96);
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: Opacity(
        opacity: frame.opacity,
        child: VerifiedStamp(size: size, pressed: pressed),
      ),
    );
  }
}

class _CreateScreen extends StatelessWidget {
  const _CreateScreen(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final live = span(t, _T.lockSnap, _T.lockSnap + .3);
    return ColoredBox(
      color: VerilyBrandColors.paper,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 14,
            top: 8,
            child: Text(
              'New action',
              style: PromoType.headline(21),
            ),
          ),
          Positioned(
            left: 8,
            top: 44,
            width: 230,
            child: _popAt(
              t,
              _T.actionCard,
              WiredCard(
                height: null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Row(
                    children: [
                      const WiredEmoji('🎺', size: 38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '10 squats at the bandstand',
                          style: PromoType.body(17, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 128,
            width: 230,
            height: 188,
            child: Opacity(
              opacity: span(t, _T.pinDrop.start - .3, _T.pinDrop.start),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SketchMap(
                        radius: easeInOut(
                          span(t, _T.radius.start, _T.radius.end),
                        ),
                        pin: span(t, _T.pinDrop.start, _T.pinDrop.end),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Sketch(
                      draw: (pen, size) => pen.roundedRect(
                        (Offset.zero & size).deflate(2),
                        color: VerilyBrandColors.ink,
                        seed: 221,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 322,
            child: Opacity(
              opacity: span(t, _T.radius.end - .2, _T.radius.end + .2),
              child: Text(
                'The bandstand · 40 m',
                style: PromoType.body(15, color: VerilyBrandColors.place),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 352,
            width: 230,
            height: 50,
            child: _popAt(t, _T.rewardChip, const _RewardChip()),
          ),
          Positioned(
            left: 14,
            top: 412,
            child: Opacity(
              opacity: live,
              child: Row(
                children: [
                  Sketch(
                    size: const Size(14, 14),
                    draw: (pen, size) => pen.ellipse(
                      Offset.zero & size,
                      color: VerilyBrandColors.place,
                      fill: VerilyBrandColors.place,
                      width: 1.6,
                      seed: 231,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Funded. Live now.',
                    style: PromoType.body(
                      16,
                      color: VerilyBrandColors.place,
                      weight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: Sketch(
          draw: (pen, size) => pen.roundedRect(
            (Offset.zero & size).deflate(2),
            color: VerilyBrandColors.reward,
            radius: 14,
            fill: VerilyBrandColors.rewardWash,
            seed: 241,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(
              '5 USDC × 50',
              style: PromoType.body(17, weight: FontWeight.w800),
            ),
            const Spacer(),
            Text('in escrow', style: PromoType.body(14)),
            const SizedBox(width: 4),
            const WiredEmoji('🔒', size: 20),
          ],
        ),
      ),
    ],
  );
}

/// The live camera: a squatting figure at the bandstand, counted rep by rep.
class _DoScreen extends StatelessWidget {
  const _DoScreen(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final phase = ((t - _T.repsStart) / _T.repPeriod).clamp(
      0.0,
      _T.reps.toDouble(),
    );
    final squat = math.pow(math.sin(phase * math.pi), 2).toDouble();
    final count = phase.floor();
    final sinceCount = phase - count;
    final done = t >= _T.repsStart + _T.repPeriod * _T.reps;
    final cheer = done
        ? math.sin(span(t, _T.repTimes.last, _T.repTimes.last + .9) * math.pi)
        : 0.0;
    final challenge = presence(
      t,
      _T.challenge,
      _T.repTimes.last + .3,
      fade: .2,
    );
    final heard = span(t, _T.spoken.start + .6, _T.spoken.start + .9);
    const paper = VerilyBrandColors.paper;
    return ColoredBox(
      color: VerilyBrandColors.night,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The scene: the bandstand behind, the ground, and the brackets.
          Positioned.fill(
            child: Sketch(
              draw: (pen, size) {
                final faint = paper.withValues(alpha: .4);
                const c = Offset(166, 226);
                pen
                  ..polygon(
                    [
                      c + const Offset(-56, 0),
                      c + const Offset(0, -34),
                      c + const Offset(56, 0),
                    ],
                    color: faint,
                    fill: VerilyBrandColors.dusk,
                    width: 2.4,
                    seed: 251,
                  )
                  ..line(
                    c + const Offset(-46, 0),
                    c + const Offset(-46, 84),
                    color: faint,
                    seed: 252,
                  )
                  ..line(
                    c + const Offset(46, 0),
                    c + const Offset(46, 84),
                    color: faint,
                    seed: 253,
                  )
                  ..line(
                    c + const Offset(-15, 0),
                    c + const Offset(-15, 84),
                    color: faint,
                    seed: 254,
                  )
                  ..line(
                    c + const Offset(15, 0),
                    c + const Offset(15, 84),
                    color: faint,
                    seed: 255,
                  )
                  ..line(
                    c + const Offset(-62, 84),
                    c + const Offset(62, 83),
                    color: faint,
                    seed: 257,
                  )
                  ..line(
                    const Offset(8, 372),
                    Offset(size.width - 8, 368),
                    color: faint,
                    seed: 256,
                  );
                for (final (i, corner) in [
                  (const Offset(14, 14), const Offset(1, 1)),
                  (Offset(size.width - 14, 14), const Offset(-1, 1)),
                  (Offset(14, size.height - 14), const Offset(1, -1)),
                  (
                    Offset(size.width - 14, size.height - 14),
                    const Offset(-1, -1),
                  ),
                ].indexed) {
                  final (at, d) = corner;
                  pen
                    ..line(
                      at,
                      at + Offset(26 * d.dx, 0),
                      color: paper,
                      width: 3,
                      seed: 260 + i,
                    )
                    ..line(
                      at,
                      at + Offset(0, 26 * d.dy),
                      color: paper,
                      width: 3,
                      seed: 270 + i,
                    );
                }
              },
            ),
          ),
          // A pigeon on the roof, nodding along.
          Positioned(
            left: 150,
            top: 164,
            child: Transform.rotate(
              angle: -0.18 * squat,
              alignment: Alignment.bottomCenter,
              child: const WiredEmoji('🐦', size: 34),
            ),
          ),
          Positioned(
            left: 30,
            top: 150,
            child: StickFigure(
              height: 222,
              squat: squat,
              cheer: cheer,
              hop: cheer,
              color: paper,
              background: VerilyBrandColors.night,
            ),
          ),
          if (count >= 7 && !done)
            Positioned(
              left: 112 + 24 * squat,
              top: 146 + 42 * squat,
              child: const WiredEmoji('💦'),
            ),
          // Live.
          Positioned(
            left: 24,
            top: 22,
            child: Row(
              children: [
                Sketch(
                  size: const Size(12, 12),
                  draw: (pen, size) => pen.ellipse(
                    Offset.zero & size,
                    color: VerilyBrandColors.stampOnNight,
                    fill: VerilyBrandColors.stampOnNight,
                    width: 1.4,
                    seed: 281,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live',
                  style: PromoType.body(
                    16,
                    color: paper,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // The rep counter.
          Positioned(
            right: 34,
            top: 18,
            child: Opacity(
              opacity: span(t, _T.repsStart - .3, _T.repsStart),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Transform.scale(
                    scale: count == 0
                        ? 1
                        : 1 + .25 * (1 - popIn(sinceCount * 3)),
                    child: Text(
                      '$count',
                      style: PromoType.headline(46, color: paper),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ 10',
                    style: PromoType.body(
                      17,
                      color: VerilyBrandColors.mutedPaper,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The live challenge.
          if (challenge > 0)
            Positioned(
              left: 26,
              top: 74,
              child: Opacity(
                opacity: challenge,
                child: Transform.scale(
                  alignment: Alignment.bottomLeft,
                  scale: popIn(span(t, _T.challenge, _T.challenge + .4)),
                  child: SpeechBubble(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Say '),
                              TextSpan(
                                text: '“pelican”',
                                style: PromoType.body(
                                  19,
                                  weight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          style: PromoType.body(19),
                        ),
                        if (heard > 0) ...[
                          const SizedBox(width: 6),
                          ProofTick(progress: heard, size: 22),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // The participant says it.
          Positioned(
            left: 118,
            top: 132,
            child: Opacity(
              opacity: presence(t, _T.spoken.start, _T.spoken.end, fade: .15),
              child: Transform.scale(
                alignment: Alignment.bottomLeft,
                scale: popIn(span(t, _T.spoken.start, _T.spoken.start + .35)),
                child: SpeechBubble(
                  seed: 291,
                  child: Text('pelican!', style: PromoType.headline(19)),
                ),
              ),
            ),
          ),
          // Where you are: inside the radius.
          Positioned(
            right: 22,
            bottom: 24,
            child: _PlaceChip(t),
          ),
        ],
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip(this.t);

  final double t;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 64,
    child: Sketch(
      draw: (pen, size) {
        final rect = (Offset.zero & size).deflate(4);
        pen.ellipse(
          rect,
          color: VerilyBrandColors.placeOnNight,
          width: 2.2,
          hatch: VerilyBrandColors.placeOnNight.withValues(alpha: .45),
          hatchGap: 6,
          seed: 301,
        );
        final dot = rect.center + const Offset(6, 4);
        final phase = (t % 1.1) / 1.1;
        pen.canvas.drawCircle(
          dot,
          5 + 14 * phase,
          Paint()
            ..color = VerilyBrandColors.placeOnNight.withValues(
              alpha: .5 * (1 - phase),
            ),
        );
        pen.ellipse(
          Rect.fromCircle(center: dot, radius: 6),
          color: VerilyBrandColors.night,
          fill: VerilyBrandColors.placeOnNight,
          width: 2,
          seed: 302,
        );
      },
    ),
  );
}

/// The proof: the clip, sealed and then stamped.
class _ProofScreen extends StatelessWidget {
  const _ProofScreen(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final checking = t < _T.ticks.last + .3;
    final sealed = t >= _T.seal.end - .2;
    final stamped = t >= _T.stampImpact;
    final paid = t >= _T.payout.end;
    final status = paid
        ? 'Paid · 5 USDC'
        : stamped
        ? 'Verified'
        : sealed
        ? 'Sealed'
        : checking
        ? 'Checking${'.' * (1 + ((t * 3).floor() % 3))}'
        : 'Checked';
    final statusColor = stamped && !paid
        ? VerilyBrandColors.stamp
        : paid
        ? VerilyBrandColors.reward
        : VerilyBrandColors.mutedInk;
    return ColoredBox(
      color: VerilyBrandColors.paper,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 14,
            top: 8,
            child: Text('Your proof', style: PromoType.headline(21)),
          ),
          Positioned(
            left: 8,
            top: 44,
            width: 230,
            height: 176,
            child: _Clip(t),
          ),
          Positioned(
            left: 12,
            top: 232,
            width: 220,
            child: Text(
              '10 squats at the bandstand',
              style: PromoType.body(18, weight: FontWeight.w700),
            ),
          ),
          Positioned(
            left: 12,
            top: 290,
            child: Text(
              status,
              style: PromoType.body(
                20,
                color: statusColor,
                weight: FontWeight.w800,
              ),
            ),
          ),
          const Positioned(
            left: 12,
            top: 330,
            width: 222,
            child: WiredDivider(),
          ),
          Positioned(
            left: 12,
            top: 346,
            child: Row(
              children: [
                const CoinSketch(diameter: 30),
                const SizedBox(width: 10),
                Text(
                  paid ? '5 USDC is yours' : '5 USDC in escrow',
                  style: PromoType.body(17, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A frozen frame of the capture, with the seal's hatch sweeping over it.
class _Clip extends StatelessWidget {
  const _Clip(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final sweep = span(t, _T.seal.start, _T.seal.end);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: VerilyBrandColors.night,
        child: Stack(
          children: [
            Positioned.fill(
              child: Sketch(
                draw: (pen, size) {
                  final faint = VerilyBrandColors.paper.withValues(alpha: .45);
                  const c = Offset(150, 70);
                  pen
                    ..polygon(
                      [
                        c + const Offset(-52, 0),
                        c + const Offset(0, -30),
                        c + const Offset(52, 0),
                      ],
                      color: faint,
                      fill: VerilyBrandColors.dusk,
                      width: 2,
                      seed: 311,
                    )
                    ..line(
                      c + const Offset(-42, 0),
                      c + const Offset(-42, 80),
                      color: faint,
                      width: 2,
                      seed: 312,
                    )
                    ..line(
                      c + const Offset(42, 0),
                      c + const Offset(42, 80),
                      color: faint,
                      width: 2,
                      seed: 313,
                    )
                    ..line(
                      const Offset(6, 152),
                      Offset(size.width - 6, 150),
                      color: faint,
                      width: 2,
                      seed: 314,
                    )
                    // Play.
                    ..polygon(
                      const [Offset(16, 132), Offset(16, 160), Offset(40, 146)],
                      color: VerilyBrandColors.paper,
                      fill: VerilyBrandColors.paper,
                      width: 2,
                      seed: 315,
                    );
                },
              ),
            ),
            const Positioned(
              left: 44,
              top: 22,
              child: StickFigure(
                height: 130,
                cheer: 1,
                color: VerilyBrandColors.paper,
                background: VerilyBrandColors.night,
              ),
            ),
            Positioned(
              right: 12,
              bottom: 10,
              child: Text(
                '0:06',
                style: PromoType.body(14, color: VerilyBrandColors.mutedPaper),
              ),
            ),
            if (sweep > 0 && sweep < 1)
              Positioned.fill(child: _SealSweep(progress: sweep)),
          ],
        ),
      ),
    );
  }
}

/// The invisible seal, made visible for a moment: a band of vermilion hatch
/// sweeps across the clip and fades to nothing.
class _SealSweep extends StatelessWidget {
  const _SealSweep({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => Sketch(
    draw: (pen, size) {
      final front = size.width * 1.4 * easeInOut(progress) - size.width * .2;
      final fade = 1 - span(progress, .55, 1);
      final band = Rect.fromLTRB(-20, -10, front, size.height + 10);
      pen.canvas
        ..save()
        ..clipRect(band);
      pen.roundedRect(
        Rect.fromLTWH(-30, -20, size.width + 60, size.height + 40),
        color: VerilyBrandColors.stampOnNight.withValues(alpha: 0),
        hatch: VerilyBrandColors.stampOnNight.withValues(alpha: .55 * fade),
        hatchGap: 9,
        seed: 321,
      );
      pen.canvas.restore();
    },
  );
}

// ---------------------------------------------------------------------------
// Money: the escrow jar, the coins going in, and the payout
// ---------------------------------------------------------------------------

class _Jar extends StatelessWidget {
  const _Jar(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final appear = _T.coinDrops.first - .45;
    final p = presence(t, appear, _T.phone.end);
    if (p <= 0) return const SizedBox.shrink();
    final landed = _T.coinLandings.where((at) => t >= at).length;
    final paidOut = t >= _T.payout.start ? 1 : 0;
    return Positioned(
      left: _jarAt.dx,
      top: _jarAt.dy,
      child: Opacity(
        opacity: p,
        child: EscrowJar(
          size: _jarSize,
          coins: 2 + landed * 2 - paidOut,
          closed: span(t, _T.lid.start, _T.lid.end),
          locked: span(t, _T.lockSnap, _T.lockSnap + .12),
        ),
      ),
    );
  }
}

Offset _quadratic(Offset a, Offset control, Offset b, double t) {
  final u = 1 - t;
  return a * (u * u) + control * (2 * u * t) + b * (t * t);
}

class _CreateCoins extends StatelessWidget {
  const _CreateCoins(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final from = _screenAt + const Offset(28, 378);
    final mouth = _jarAt + Offset(_jarSize.width / 2, _jarSize.height * .5);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (i, drop) in _T.coinDrops.indexed)
          if (t >= drop && t < drop + _T.coinFall)
            () {
              final p = span(t, drop, drop + _T.coinFall);
              final start = from + Offset(i * 6.0, 0);
              final end = mouth + Offset((i - 1) * 14.0, 6);
              final at = _quadratic(
                start,
                Offset((start.dx + end.dx) / 2, start.dy - 120),
                end,
                Curves.easeIn.transform(p),
              );
              return Positioned(
                left: at.dx - 17,
                top: at.dy - 17,
                child: Transform.rotate(
                  angle: p * 3,
                  child: const CoinSketch(diameter: 34),
                ),
              );
            }(),
      ],
    );
  }
}

class _Payout extends StatelessWidget {
  const _Payout(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    if (t < _T.payout.start || t >= _T.payout.end) {
      return const SizedBox.shrink();
    }
    final p = span(t, _T.payout.start, _T.payout.end);
    final start = _jarAt + Offset(_jarSize.width / 2, 24);
    const end = Offset(240, 292);
    final at = _quadratic(start, const Offset(380, 150), end, easeInOut(p));
    return Positioned(
      left: at.dx - 21,
      top: at.dy - 21,
      child: Transform.scale(
        scale: popIn(span(p, 0, .25)),
        child: Transform.rotate(
          angle: -p * 5,
          child: const CoinSketch(diameter: 42),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// End card
// ---------------------------------------------------------------------------

class _EndCard extends StatelessWidget {
  const _EndCard(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final tagline = span(t, _T.tagline, _T.tagline + .4);
    final url = span(t, _T.url, _T.url + .4);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VerilyLockup(
            height: 140,
            progress: span(t, _T.endLockup.start, _T.endLockup.end),
          ),
          const SizedBox(height: 30),
          _FadeUp(
            progress: tagline,
            child: Text(
              'Do it. Prove it. Get paid.',
              style: PromoType.headline(48),
            ),
          ),
          const SizedBox(height: 18),
          _FadeUp(
            progress: url,
            child: Column(
              children: [
                Text(
                  'verily.fun',
                  style: PromoType.headline(34, color: VerilyBrandColors.stamp),
                ),
                Sketch(
                  size: const Size(170, 12),
                  draw: (pen, size) => pen.curve(
                    [
                      const Offset(4, 8),
                      const Offset(60, 4),
                      const Offset(120, 6),
                      Offset(size.width - 4, 3),
                    ],
                    color: VerilyBrandColors.stamp,
                    width: 3.4,
                    seed: 331,
                    progress: easeOut(span(t, _T.url + .2, _T.url + .7)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
