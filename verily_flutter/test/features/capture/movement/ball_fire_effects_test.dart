import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mp_core/mp_core.dart';
import 'package:verily_flutter/features/capture/movement/ball_tracking.dart';
import 'package:verily_flutter/features/capture/movement/widgets/ball_fire_effects.dart';

void main() {
  const ball = BallObservation(x: 0.5, y: 0.5, radius: 0.03, score: 0.9);
  const touch = BallTouch(
    timestampMs: 100,
    x: 0.5,
    y: 0.7,
    limb: MovementLimb.rightLeg,
  );

  test('a touch ignites the ball, bursts embers, and powers the limb', () {
    final effects = BallFireEffects(random: math.Random(1))
      ..observe(ball: ball, pose: _pose, touch: touch, running: true);

    expect(effects.heat, 1);
    expect(effects.power, 1);
    expect(effects.sinceTouch, 0);
    expect(effects.embers.length, greaterThanOrEqualTo(22));

    effects.observe(ball: ball, pose: _pose, touch: touch, running: true);
    final burst = effects.embers.length;
    effects.observe(ball: ball, pose: _pose, touch: touch, running: true);
    expect(effects.embers.length, burst, reason: 'one touch bursts once');
  });

  test('heat smoulders during a run and dies out after it', () {
    final effects = BallFireEffects(random: math.Random(2))
      ..observe(ball: ball, pose: _pose, touch: touch, running: true);
    for (var frame = 0; frame < 120; frame++) {
      effects.advance(1 / 60);
    }
    expect(effects.heat, closeTo(0.35, 0.001));
    expect(effects.power, 0);

    effects.observe(ball: ball, pose: _pose, touch: touch, running: false);
    for (var frame = 0; frame < 60; frame++) {
      effects.advance(1 / 60);
    }
    expect(effects.heat, 0);
  });

  test('embers and the trail fade instead of piling up', () {
    final effects = BallFireEffects(random: math.Random(3));
    for (var frame = 0; frame < 240; frame++) {
      effects
        ..observe(
          ball: BallObservation(
            x: 0.5,
            y: 0.3 + 0.4 * (frame % 30) / 30,
            radius: 0.03,
            score: 0.9,
          ),
          pose: _pose,
          touch: BallTouch(
            timestampMs: frame ~/ 30,
            x: 0.5,
            y: 0.7,
            limb: MovementLimb.leftLeg,
          ),
          running: true,
        )
        ..advance(1 / 60);
    }
    expect(effects.embers.length, lessThanOrEqualTo(160));
    final trail = effects.trail.toList();
    expect(
      trail.last.at - trail.first.at,
      lessThanOrEqualTo(BallFireEffects.trailSeconds),
    );
  });

  testWidgets('paints flames, trail, and a powered limb', (tester) async {
    final effects = BallFireEffects(random: math.Random(4))
      ..observe(ball: ball, pose: _pose, touch: touch, running: true)
      ..advance(0.05);
    for (final reduceMotion in [false, true]) {
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 300,
            height: 450,
            child: CustomPaint(
              painter: BallFirePainter(
                effects: effects,
                mirrored: true,
                reduceMotion: reduceMotion,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}

final List<NormalizedLandmark> _pose = List.filled(
  33,
  const NormalizedLandmark(x: 0.5, y: 0.6, z: 0, visibility: 1),
);
