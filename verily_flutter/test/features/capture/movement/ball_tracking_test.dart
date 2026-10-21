import 'package:flutter_test/flutter_test.dart';
import 'package:mp_core/mp_core.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_flutter/features/capture/movement/ball_tracking.dart';
import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';

void main() {
  group('football kick-ups', () {
    test('count consecutive touches off a lifted foot', () {
      final tracker = BallTouchTracker(ActionMovementKind.footballKickUps);
      _play(tracker, _kickUps(bounces: 3));

      expect(tracker.progress.count, 3);
      expect(tracker.progress.best, 3);
      expect(tracker.progress.touch?.limb, MovementLimb.rightLeg);
      expect(tracker.progress.cue, MovementCue.perform);
    });

    test('a bounce off the floor beside planted feet ends the run', () {
      final tracker = BallTouchTracker(ActionMovementKind.footballKickUps);
      _play(tracker, _kickUps(bounces: 3));
      _play(
        tracker,
        _bounces(
          pose: _standing(),
          bounces: 1,
          x: 0.6,
          bottom: 0.88,
          top: 0.6,
          radius: 0.03,
          startMs: 3000,
        ),
      );

      expect(tracker.progress.count, 0);
      expect(tracker.progress.best, 3, reason: 'the best run is kept');
      expect(tracker.progress.cue, MovementCue.dropped);
    });

    test('losing sight of the ball ends the run', () {
      final tracker = BallTouchTracker(ActionMovementKind.footballKickUps);
      _play(tracker, _kickUps(bounces: 2));
      for (var t = 2000; t <= 3200; t += 100) {
        tracker.update(
          MovementObservation(
            pose: _kicking(),
            aspectRatio: 1,
            timestampMs: t,
          ),
        );
      }

      expect(tracker.progress.count, 0);
      expect(tracker.progress.best, 2);
      expect(tracker.progress.cue, MovementCue.showBall);
    });

    test('a ball held still is not a touch and stalls the run', () {
      final tracker = BallTouchTracker(ActionMovementKind.footballKickUps);
      _play(tracker, _kickUps(bounces: 2));
      for (var t = 2000; t <= 5000; t += 66) {
        tracker.update(
          _observe(_kicking(), t, x: 0.64, y: 0.74 + (t % 2) * 0.004),
        );
      }

      expect(tracker.progress.count, 0);
      expect(tracker.progress.best, 2);
    });

    test('a ball touching only the air is never counted', () {
      final tracker = BallTouchTracker(ActionMovementKind.footballKickUps);
      // Bounces far from the body, as if thrown against a wall.
      _play(
        tracker,
        _bounces(
          pose: _kicking(),
          bounces: 4,
          x: 0.95,
          bottom: 0.5,
          top: 0.2,
          radius: 0.03,
        ),
      );

      expect(tracker.progress.best, 0);
    });

    test('needs a body in frame before it can coach', () {
      final tracker = BallTouchTracker(ActionMovementKind.footballKickUps)
        ..update(
          const MovementObservation(pose: [], aspectRatio: 1, timestampMs: 0),
        );
      expect(tracker.progress.cue, MovementCue.stepIntoFrame);
    });
  });

  group('table tennis bounces', () {
    test('count bounces off the bat', () {
      final tracker = BallTouchTracker(ActionMovementKind.tableTennisBounces);
      _play(
        tracker,
        _bounces(
          pose: _batRaised(),
          bounces: 5,
          x: 0.65,
          bottom: 0.4,
          top: 0.2,
          radius: 0.012,
          periodMs: 600,
          stepMs: 50,
        ),
      );

      expect(tracker.progress.count, 5);
      expect(tracker.progress.touch?.limb, MovementLimb.rightArm);
    });

    test('a bounce off the floor is not a bat bounce', () {
      final tracker = BallTouchTracker(ActionMovementKind.tableTennisBounces);
      _play(
        tracker,
        _bounces(
          pose: _batRaised(),
          bounces: 3,
          x: 0.65,
          bottom: 0.92,
          top: 0.75,
          radius: 0.012,
          periodMs: 600,
          stepMs: 50,
        ),
      );

      expect(tracker.progress.best, 0);
    });
  });

  test('tracker versions name both models', () {
    expect(
      BallTouchTracker(ActionMovementKind.tableTennisBounces).version,
      'pose-lite-v1.effdet0-v1.table-tennis-bounces-v1',
    );
  });
}

void _play(MovementTracker tracker, Iterable<MovementObservation> frames) {
  frames.forEach(tracker.update);
}

Iterable<MovementObservation> _kickUps({required int bounces}) {
  return _bounces(
    pose: _kicking(),
    bounces: bounces,
    x: 0.64,
    bottom: 0.74,
    top: 0.45,
    radius: 0.03,
  );
}

/// A ball dropping onto [bottom] and rising to [top] once per [periodMs],
/// sampled every [stepMs] like a camera. The first rise is the toss, so the
/// trajectory touches [bounces] times.
Iterable<MovementObservation> _bounces({
  required List<NormalizedLandmark> pose,
  required int bounces,
  required double x,
  required double bottom,
  required double top,
  required double radius,
  int periodMs = 800,
  int stepMs = 66,
  int startMs = 0,
}) sync* {
  final end = bounces * periodMs + periodMs ~/ 3;
  for (var t = 0; t <= end; t += stepMs) {
    final phase = (t % periodMs) / periodMs;
    final y = bottom - (bottom - top) * 4 * phase * (1 - phase);
    yield _observe(pose, startMs + t, x: x, y: y, radius: radius);
  }
}

MovementObservation _observe(
  List<NormalizedLandmark> pose,
  int timestamp, {
  required double x,
  required double y,
  double radius = 0.03,
}) {
  return MovementObservation(
    pose: pose,
    aspectRatio: 1,
    timestampMs: timestamp,
    ball: BallObservation(x: x, y: y, radius: radius, score: 0.9),
  );
}

/// Facing the camera, both feet planted, arms by the sides.
List<NormalizedLandmark> _standing() {
  final pose = List<NormalizedLandmark>.filled(
    33,
    const NormalizedLandmark(x: 0.5, y: 0.2, z: 0, visibility: 1),
  );
  void set(int joint, double x, double y) =>
      pose[joint] = NormalizedLandmark(x: x, y: y, z: 0, visibility: 1);
  set(PoseJoint.nose, 0.5, 0.2);
  set(PoseJoint.leftShoulder, 0.45, 0.3);
  set(PoseJoint.rightShoulder, 0.55, 0.3);
  set(PoseJoint.leftElbow, 0.43, 0.42);
  set(PoseJoint.rightElbow, 0.57, 0.42);
  set(PoseJoint.leftWrist, 0.42, 0.55);
  set(PoseJoint.rightWrist, 0.58, 0.55);
  set(PoseJoint.leftIndex, 0.42, 0.58);
  set(PoseJoint.rightIndex, 0.58, 0.58);
  set(PoseJoint.leftHip, 0.46, 0.5);
  set(PoseJoint.rightHip, 0.54, 0.5);
  set(PoseJoint.leftKnee, 0.46, 0.7);
  set(PoseJoint.rightKnee, 0.54, 0.7);
  set(PoseJoint.leftAnkle, 0.46, 0.9);
  set(PoseJoint.rightAnkle, 0.54, 0.9);
  set(PoseJoint.leftFootIndex, 0.44, 0.93);
  set(PoseJoint.rightFootIndex, 0.56, 0.93);
  return pose;
}

/// The right foot lifted to keep the ball up.
List<NormalizedLandmark> _kicking() {
  final pose = _standing();
  pose[PoseJoint.rightKnee] = const NormalizedLandmark(
    x: 0.57,
    y: 0.66,
    z: 0,
    visibility: 1,
  );
  pose[PoseJoint.rightAnkle] = const NormalizedLandmark(
    x: 0.62,
    y: 0.78,
    z: 0,
    visibility: 1,
  );
  pose[PoseJoint.rightFootIndex] = const NormalizedLandmark(
    x: 0.66,
    y: 0.79,
    z: 0,
    visibility: 1,
  );
  return pose;
}

/// The right hand holding a bat out in front, fingers pointing up and out.
List<NormalizedLandmark> _batRaised() {
  final pose = _standing();
  pose[PoseJoint.rightWrist] = const NormalizedLandmark(
    x: 0.6,
    y: 0.5,
    z: 0,
    visibility: 1,
  );
  pose[PoseJoint.rightIndex] = const NormalizedLandmark(
    x: 0.62,
    y: 0.47,
    z: 0,
    visibility: 1,
  );
  return pose;
}
