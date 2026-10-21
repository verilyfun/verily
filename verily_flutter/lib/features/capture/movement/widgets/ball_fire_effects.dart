import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:mp_core/mp_core.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/capture/movement/ball_tracking.dart';
import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';

/// Fire trail, ball glow, touch bursts, and powered-up limbs for ball skills.
///
/// Detections arrive 10–20 times a second, but [advance] runs every display
/// frame so the flames keep moving between them. All positions are
/// normalized image coordinates, like the pose and ball observations.
final class BallFireEffects extends ChangeNotifier {
  BallFireEffects({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  /// How long a trail point stays visible, in seconds.
  static const trailSeconds = 0.55;

  /// How long a touch powers up the limb that made it, in seconds.
  static const powerSeconds = 0.8;

  static const _maximumEmbers = 160;

  final List<Ember> _embers = [];
  final ListQueue<TrailPoint> _trail = ListQueue();
  double _now = 0;
  BallObservation? _ball;
  List<NormalizedLandmark> _pose = const [];
  BallTouch? _touch;
  double? _touchedAt;
  double _heat = 0;
  bool _running = false;

  List<Ember> get embers => _embers;
  Iterable<TrailPoint> get trail => _trail;
  BallObservation? get ball => _ball;
  List<NormalizedLandmark> get pose => _pose;
  BallTouch? get touch => _touch;

  /// How hot the ball burns, from 0 (just glowing) to 1 (just kicked).
  double get heat => _heat;

  /// 1 at the moment of a touch, falling to 0 after [powerSeconds].
  double get power => switch (_touchedAt) {
    final at? => (1 - (_now - at) / powerSeconds).clamp(0.0, 1.0),
    null => 0,
  };

  /// Seconds since the latest touch, for the shockwave ring.
  double? get sinceTouch => _touchedAt == null ? null : _now - _touchedAt!;

  /// Records the latest detection. A new [touch] ignites the ball.
  void observe({
    required BallObservation? ball,
    required List<NormalizedLandmark> pose,
    required BallTouch? touch,
    required bool running,
  }) {
    _ball = ball;
    _pose = pose;
    _running = running;
    if (ball != null) {
      _trail.addLast(TrailPoint(ball.x, ball.y, ball.radius, _now));
    }
    if (touch != null && !identical(touch, _touch)) {
      _touch = touch;
      _touchedAt = _now;
      _heat = 1;
      _burst(touch, ball?.radius ?? 0.02);
    }
  }

  /// Steps the simulation by [seconds] of display time.
  void advance(double seconds) {
    final dt = seconds.clamp(0.0, 0.1);
    _now += dt;
    // A live run keeps the ball smouldering; heat spikes on each touch.
    final floor = _running ? 0.35 : 0.0;
    _heat = math.max(floor, _heat - dt * 0.7);
    while (_trail.isNotEmpty && _now - _trail.first.at > trailSeconds) {
      _trail.removeFirst();
    }
    if (_ball case final ball? when _heat > 0) {
      final count = (dt * 160 * _heat).ceil();
      for (var i = 0; i < count; i++) {
        _spawn(ball.x, ball.y, ball.radius, spread: 0.6, lift: 0.35);
      }
    }
    if (power > 0) _sparkLimb();
    for (final ember in _embers) {
      ember
        ..x += ember.vx * dt
        ..y += ember.vy * dt
        ..vy -= 0.25 * dt
        ..age += dt;
    }
    _embers.removeWhere((ember) => ember.age >= ember.life);
    if (_embers.length > _maximumEmbers) {
      _embers.removeRange(0, _embers.length - _maximumEmbers);
    }
    notifyListeners();
  }

  void _burst(BallTouch touch, double radius) {
    for (var i = 0; i < 22; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 0.25 + _random.nextDouble() * 0.45;
      _embers.add(
        Ember(
          x: touch.x,
          y: touch.y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 0.2,
          size: radius * (0.25 + _random.nextDouble() * 0.35),
          life: 0.3 + _random.nextDouble() * 0.35,
          hue: _random.nextDouble(),
        ),
      );
    }
  }

  void _spawn(
    double x,
    double y,
    double radius, {
    required double spread,
    required double lift,
  }) {
    _embers.add(
      Ember(
        x: x + (_random.nextDouble() - 0.5) * radius * spread * 2,
        y: y + (_random.nextDouble() - 0.5) * radius * spread * 2,
        vx: (_random.nextDouble() - 0.5) * 0.12,
        vy: -lift * (0.4 + _random.nextDouble()),
        size: radius * (0.35 + _random.nextDouble() * 0.45),
        life: 0.25 + _random.nextDouble() * 0.35,
        hue: _random.nextDouble(),
      ),
    );
  }

  /// Sparks rise from the limb that made the last touch.
  void _sparkLimb() {
    final touch = _touch;
    if (touch == null || _pose.length < PoseJoint.count) return;
    final segments = limbSegments(touch.limb);
    if (segments.isEmpty || _random.nextDouble() > power) return;
    final (a, b) = segments[_random.nextInt(segments.length)];
    final t = _random.nextDouble();
    final x = _pose[a].x + (_pose[b].x - _pose[a].x) * t;
    final y = _pose[a].y + (_pose[b].y - _pose[a].y) * t;
    _spawn(x, y, 0.02, spread: 0.5, lift: 0.25);
  }
}

/// Pose segments drawn as the powered-up limb for each touch.
List<(int, int)> limbSegments(MovementLimb limb) => switch (limb) {
  MovementLimb.leftLeg => const [
    (PoseJoint.leftHip, PoseJoint.leftKnee),
    (PoseJoint.leftKnee, PoseJoint.leftAnkle),
    (PoseJoint.leftAnkle, PoseJoint.leftFootIndex),
  ],
  MovementLimb.rightLeg => const [
    (PoseJoint.rightHip, PoseJoint.rightKnee),
    (PoseJoint.rightKnee, PoseJoint.rightAnkle),
    (PoseJoint.rightAnkle, PoseJoint.rightFootIndex),
  ],
  MovementLimb.leftArm => const [
    (PoseJoint.leftShoulder, PoseJoint.leftElbow),
    (PoseJoint.leftElbow, PoseJoint.leftWrist),
  ],
  MovementLimb.rightArm => const [
    (PoseJoint.rightShoulder, PoseJoint.rightElbow),
    (PoseJoint.rightElbow, PoseJoint.rightWrist),
  ],
  MovementLimb.chest => const [
    (PoseJoint.leftShoulder, PoseJoint.rightShoulder),
  ],
  MovementLimb.head => const [],
};

/// One flame particle.
final class Ember {
  Ember({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.hue,
  });

  double x;
  double y;
  double vx;
  double vy;
  double age = 0;
  final double size;
  final double life;

  /// 0 burns hot yellow, 1 burns deep red.
  final double hue;
}

/// A past ball position in the trail.
final class TrailPoint {
  const TrailPoint(this.x, this.y, this.radius, this.at);

  final double x;
  final double y;
  final double radius;
  final double at;
}

/// Paints [BallFireEffects] in the same box as the camera preview.
class BallFirePainter extends CustomPainter {
  BallFirePainter({
    required this.effects,
    required this.mirrored,
    required this.reduceMotion,
  }) : super(repaint: effects);

  final BallFireEffects effects;
  final bool mirrored;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (mirrored) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    Offset at(double x, double y) => Offset(x * size.width, y * size.height);
    final height = size.height;

    _paintLimb(canvas, size, at);
    if (!reduceMotion) {
      _paintTrail(canvas, at, height);
      _paintEmbers(canvas, at, height);
    }
    _paintBall(canvas, at, height);
    _paintShockwave(canvas, at, height);
  }

  /// A comet tail along the recent path: a red-orange flame body with a
  /// yellow-white core that only burns near the ball.
  void _paintTrail(
    Canvas canvas,
    Offset Function(double, double) at,
    double h,
  ) {
    final points = effects.trail.toList();
    final heat = effects.heat;
    if (points.length < 2 || heat <= 0) return;
    final newest = points.last.at;
    final body = Paint();
    final core = Paint()..blendMode = BlendMode.plus;
    for (var i = 1; i < points.length; i++) {
      final from = points[i - 1];
      final to = points[i];
      final start = at(from.x, from.y);
      final end = at(to.x, to.y);
      final radius = to.radius * h;
      // Fill gaps between detections so the tail reads as one ribbon.
      final steps = math.max(
        1,
        ((end - start).distance / (radius * 0.4)).ceil(),
      );
      for (var step = 0; step < steps; step++) {
        final t = step / steps;
        final age =
            ((newest - (from.at + (to.at - from.at) * t)) /
                    BallFireEffects.trailSeconds)
                .clamp(0.0, 1.0);
        final fade = (1 - age) * heat;
        if (fade <= 0.02) continue;
        final center = Offset.lerp(start, end, t)!;
        final width = radius * (0.3 + 1.1 * (1 - age));
        body
          ..color = _flame(0.45 + age * 0.55).withValues(alpha: 0.28 * fade)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.7);
        canvas.drawCircle(center, width * 1.2, body);
        if (age < 0.35) {
          core
            ..color = _flame(age).withValues(alpha: 0.22 * fade)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.3);
          canvas.drawCircle(center, width * 0.55, core);
        }
      }
    }
  }

  /// Embers cool from white through yellow and orange to red as they rise.
  void _paintEmbers(
    Canvas canvas,
    Offset Function(double, double) at,
    double h,
  ) {
    final paint = Paint();
    for (final ember in effects.embers) {
      final life = (ember.age / ember.life).clamp(0.0, 1.0);
      // Only fresh embers glow additively; cooling ones keep their colour.
      paint.blendMode = life < 0.3 ? BlendMode.plus : BlendMode.srcOver;
      final size = math.max(ember.size * h * (1 - life * 0.75), 0.5);
      paint
        ..color = _flame(life * 0.85 + ember.hue * 0.15).withValues(
          alpha: (1 - life) * 0.85,
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.5);
      canvas.drawCircle(at(ember.x, ember.y), size, paint);
    }
  }

  void _paintBall(Canvas canvas, Offset Function(double, double) at, double h) {
    final ball = effects.ball;
    if (ball == null) return;
    final center = at(ball.x, ball.y);
    final radius = ball.radius * h;
    final glow = radius * (2.2 + effects.heat * 1.4);
    canvas
      ..drawCircle(
        center,
        glow,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              VerilyColors.movementFlameCore.withValues(alpha: 0.5),
              VerilyColors.movementFlameHot.withValues(
                alpha: 0.25 + effects.heat * 0.25,
              ),
              VerilyColors.movementFlameWarm.withValues(
                alpha: 0.15 + effects.heat * 0.25,
              ),
              VerilyColors.movementFlameEdge.withValues(alpha: 0.12),
              VerilyColors.movementFlameEdge.withValues(alpha: 0),
            ],
            stops: const [0, 0.3, 0.55, 0.8, 1],
          ).createShader(Rect.fromCircle(center: center, radius: glow)),
      )
      ..drawCircle(
        center,
        radius * 1.08,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(radius * 0.14, 2)
          ..color = VerilyColors.movementFlameCore.withValues(alpha: 0.9),
      );
  }

  void _paintShockwave(
    Canvas canvas,
    Offset Function(double, double) at,
    double h,
  ) {
    final touch = effects.touch;
    final since = effects.sinceTouch;
    if (touch == null || since == null || since > 0.4) return;
    final progress = since / 0.4;
    canvas.drawCircle(
      at(touch.x, touch.y),
      h * (0.02 + progress * 0.12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * (1 - progress) + 1
        ..color = VerilyColors.movementFlameHot.withValues(
          alpha: 1 - progress,
        ),
    );
  }

  /// The limb that touched the ball catches the same fire.
  void _paintLimb(
    Canvas canvas,
    Size size,
    Offset Function(double, double) at,
  ) {
    final touch = effects.touch;
    final power = effects.power;
    final pose = effects.pose;
    if (touch == null || power <= 0 || pose.length < PoseJoint.count) return;
    final width = size.shortestSide * 0.035;
    final halo = Paint()
      ..blendMode = BlendMode.plus
      ..color = VerilyColors.movementFlameWarm.withValues(alpha: 0.45 * power)
      ..strokeWidth = width * 4.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 2.2);
    final aura = Paint()
      ..blendMode = BlendMode.plus
      ..color = VerilyColors.movementFlameHot.withValues(alpha: 0.85 * power)
      ..strokeWidth = width * 2.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.8);
    final core = Paint()
      ..blendMode = BlendMode.plus
      ..color = VerilyColors.movementFlameCore.withValues(alpha: power)
      ..strokeWidth = width * 0.6
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in limbSegments(touch.limb)) {
      final start = at(pose[a].x, pose[a].y);
      final end = at(pose[b].x, pose[b].y);
      canvas
        ..drawLine(start, end, halo)
        ..drawLine(start, end, aura)
        ..drawLine(start, end, core);
    }
  }

  /// White-hot at 0, through yellow and orange, to deep red at 1.
  static Color _flame(double t) {
    const stops = [
      VerilyColors.movementFlameCore,
      VerilyColors.movementFlameHot,
      VerilyColors.movementFlameWarm,
      VerilyColors.movementFlameEdge,
    ];
    final scaled = t.clamp(0.0, 1.0) * (stops.length - 1);
    final index = scaled.floor().clamp(0, stops.length - 2);
    return Color.lerp(stops[index], stops[index + 1], scaled - index)!;
  }

  @override
  bool shouldRepaint(BallFirePainter oldDelegate) =>
      mirrored != oldDelegate.mirrored ||
      reduceMotion != oldDelegate.reduceMotion ||
      !identical(effects, oldDelegate.effects);
}
