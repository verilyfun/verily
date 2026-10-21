import 'package:flutter_test/flutter_test.dart';
import 'package:mp_core/mp_core.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_flutter/features/capture/movement/ball_tracking.dart';
import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';

const List<ActionMovementKind> _exercises = [
  ActionMovementKind.squats,
  ActionMovementKind.lunges,
  ActionMovementKind.pressUps,
  ActionMovementKind.bicepsCurls,
  ActionMovementKind.lateralRaises,
  ActionMovementKind.highKnees,
  ActionMovementKind.sitUps,
  ActionMovementKind.sideBends,
  ActionMovementKind.starJumps,
];

void main() {
  test('every movement has a live tracker', () {
    for (final kind in ActionMovementKind.values) {
      expect(
        movementTrackerFor(kind),
        kind.isBallSkill
            ? isA<BallTouchTracker>()
            : isNot(isA<BallTouchTracker>()),
        reason: '$kind',
      );
    }
  });

  test('tracker versions satisfy the server evidence contract', () {
    final pattern = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');
    for (final kind in ActionMovementKind.values) {
      final version = movementTrackerFor(kind).version;
      expect(pattern.hasMatch(version), isTrue, reason: version);
    }
    expect(
      movementTrackerFor(ActionMovementKind.pressUps).version,
      'pose-lite-v1.press-ups-v1',
    );
    expect(
      movementTrackerFor(ActionMovementKind.footballKickUps).version,
      'pose-lite-v1.effdet0-v1.football-kick-ups-v1',
    );
  });

  for (final kind in _exercises) {
    test('$kind counts one complete landmark-driven cycle', () {
      final rest = _rest(kind);
      final active = _active(kind);
      expect(movementDepth(kind, rest, 1), lessThan(0.2));
      expect(movementDepth(kind, active, 1), greaterThan(0.8));
      final tracker = movementTrackerFor(kind);

      for (final (timestamp, pose) in [
        (0, rest),
        (200, rest),
        (500, active),
        (700, active),
        (1000, rest),
        (1200, rest),
      ]) {
        tracker.update(_observe(pose, timestamp));
      }

      expect(tracker.progress.count, 1);
      tracker.update(_observe(rest, 1400));
      expect(
        tracker.progress.count,
        1,
        reason: 'Holding the start position cannot count twice',
      );
    });
  }

  test('cues guide the participant through one repetition', () {
    final tracker = movementTrackerFor(ActionMovementKind.squats);
    expect(tracker.progress.cue, MovementCue.stepIntoFrame);
    tracker.update(_observe(_rest(ActionMovementKind.squats), 0));
    expect(tracker.progress.cue, MovementCue.getIntoPosition);
    tracker.update(_observe(_rest(ActionMovementKind.squats), 200));
    expect(tracker.progress.cue, MovementCue.perform);
    tracker
      ..update(_observe(_active(ActionMovementKind.squats), 400))
      ..update(_observe(_active(ActionMovementKind.squats), 600));
    expect(tracker.progress.cue, MovementCue.returnToStart);
    expect(tracker.progress.atDepth, isTrue);
  });

  test('a side view counts squats when the far leg is hidden', () {
    final rest = _hideRightSide(_rest(ActionMovementKind.squats));
    final active = _hideRightSide(_active(ActionMovementKind.squats));
    final tracker = movementTrackerFor(ActionMovementKind.squats);

    for (final (timestamp, pose) in [
      (0, rest),
      (200, rest),
      (500, active),
      (700, active),
      (1000, rest),
      (1200, rest),
    ]) {
      tracker.update(_observe(pose, timestamp));
    }

    expect(tracker.progress.count, 1);
  });

  test('lunges and star jumps still need both sides', () {
    for (final kind in [
      ActionMovementKind.lunges,
      ActionMovementKind.starJumps,
    ]) {
      expect(movementDepth(kind, _hideRightSide(_rest(kind)), 1), isNull);
    }
  });

  test('fast high knees count at a brisk cadence', () {
    final rest = _rest(ActionMovementKind.highKnees);
    final active = _active(ActionMovementKind.highKnees);
    final tracker = movementTrackerFor(ActionMovementKind.highKnees)
      ..update(_observe(rest, 0))
      ..update(_observe(rest, 100));
    // Five knee raises at 2.5 per second.
    for (var rep = 0; rep < 5; rep++) {
      final start = 100 + rep * 400;
      tracker
        ..update(_observe(active, start + 100))
        ..update(_observe(active, start + 200))
        ..update(_observe(rest, start + 300))
        ..update(_observe(rest, start + 400));
    }

    expect(tracker.progress.count, 5);
  });

  test('jitter, missing joints, and stale frames never add a repetition', () {
    final counter = RepetitionCounter()
      ..update(0, 0)
      ..update(0, 200)
      ..update(1, 500)
      ..update(0, 550)
      ..update(0, 750);
    expect(counter.count, 0, reason: 'too short to be a repetition');
    counter
      ..update(1, 1000)
      ..update(1, 1200)
      ..update(null, 1400)
      ..update(0, 1600)
      ..update(0, 1800);
    expect(counter.count, 0, reason: 'tracking loss discards the cycle');
    counter
      ..update(1, 1900)
      ..update(1, 2100)
      ..update(0, 4000)
      ..update(0, 4200);
    expect(counter.count, 0, reason: 'a long frame gap discards the cycle');
    counter.update(1, 100);
    expect(counter.depth, 0, reason: 'out-of-order frames are ignored');
  });

  test('a starting position must come before the first repetition', () {
    final counter = RepetitionCounter()
      ..update(1, 0)
      ..update(1, 200)
      ..update(0, 800)
      ..update(0, 1000);
    expect(counter.count, 0);
  });

  test('occluded, out-of-frame, and nonfinite joints are rejected', () {
    for (final kind in _exercises) {
      for (final broken in const [
        NormalizedLandmark(x: 0.5, y: 0.5, z: 0, visibility: 0.1),
        NormalizedLandmark(x: double.nan, y: 0.5, z: 0, visibility: 1),
        NormalizedLandmark(x: 1.2, y: 0.5, z: 0, visibility: 1),
      ]) {
        final pose = _rest(kind);
        for (final joint in [
          PoseJoint.leftShoulder,
          PoseJoint.rightShoulder,
          PoseJoint.leftHip,
          PoseJoint.rightHip,
          PoseJoint.leftKnee,
          PoseJoint.rightKnee,
          PoseJoint.leftElbow,
          PoseJoint.rightElbow,
          PoseJoint.leftWrist,
          PoseJoint.rightWrist,
          PoseJoint.leftAnkle,
          PoseJoint.rightAnkle,
        ]) {
          pose[joint] = broken;
        }
        expect(movementDepth(kind, pose, 1), isNull, reason: '$kind');
      }
    }
    expect(movementDepth(ActionMovementKind.squats, const [], 1), isNull);
    expect(
      movementDepth(
        ActionMovementKind.squats,
        _rest(ActionMovementKind.squats),
        0,
      ),
      isNull,
    );
  });

  test('portrait frames measure the same joint angles', () {
    final square = _active(ActionMovementKind.squats);
    final portrait = [
      for (final point in square)
        NormalizedLandmark(
          x: (point.x - 0.5) / 0.75 + 0.5,
          y: point.y,
          z: point.z,
          visibility: 1,
        ),
    ];
    expect(
      movementDepth(ActionMovementKind.squats, portrait, 0.75),
      closeTo(movementDepth(ActionMovementKind.squats, square, 1)!, 0.0001),
    );
  });

  test('press-ups are ignored unless the body is horizontal', () {
    final upright = _rest(ActionMovementKind.squats);
    expect(movementDepth(ActionMovementKind.pressUps, upright, 1), isNull);
  });

  test('burpees need a plank, return crouch, jump, and landing', () {
    final tracker = movementTrackerFor(ActionMovementKind.burpees);
    final stand = _rest(ActionMovementKind.burpees);
    final crouch = _active(ActionMovementKind.squats);
    final plank = _rest(ActionMovementKind.burpees);
    for (final side in [0, 1]) {
      _set(plank, PoseJoint.leftShoulder + side, 0.2, 0.5);
      _set(plank, PoseJoint.leftHip + side, 0.45, 0.5);
      _set(plank, PoseJoint.leftKnee + side, 0.65, 0.5);
      _set(plank, PoseJoint.leftAnkle + side, 0.85, 0.5);
    }
    final jump = [
      for (final point in stand)
        NormalizedLandmark(x: point.x, y: point.y - 0.08, z: 0, visibility: 1),
    ];

    tracker
      ..update(_observe(stand, 0))
      ..update(_observe(crouch, 300))
      ..update(_observe(stand, 600));
    expect(tracker.progress.count, 0, reason: 'a squat is not a burpee');
    expect(tracker.progress.cue, MovementCue.plank);
    tracker
      ..update(_observe(plank, 900))
      ..update(_observe(crouch, 1200))
      ..update(_observe(jump, 1500));
    expect(tracker.progress.count, 0);
    expect(tracker.progress.cue, MovementCue.land);
    tracker.update(_observe(stand, 1800));
    expect(tracker.progress.count, 1);
    tracker
      ..update(_observe(crouch, 2000))
      ..update(_observe(const [], 2200));
    expect(tracker.progress.cue, MovementCue.stepIntoFrame);
    expect(tracker.progress.count, 1, reason: 'tracking loss keeps reps');
  });
}

MovementObservation _observe(List<NormalizedLandmark> pose, int timestamp) {
  return MovementObservation(
    pose: pose,
    aspectRatio: 1,
    timestampMs: timestamp,
  );
}

List<NormalizedLandmark> _rest(ActionMovementKind kind) {
  final pose = List<NormalizedLandmark>.filled(
    PoseJoint.count,
    const NormalizedLandmark(x: 0.5, y: 0.2, z: 0, visibility: 1, presence: 1),
  );
  for (final side in [0, 1]) {
    final x = 0.4 + 0.2 * side;
    _set(pose, PoseJoint.leftShoulder + side, x, 0.3);
    _set(pose, PoseJoint.leftElbow + side, x, 0.42);
    _set(pose, PoseJoint.leftWrist + side, x, 0.55);
    _set(pose, PoseJoint.leftHip + side, x, 0.5);
    _set(pose, PoseJoint.leftKnee + side, x, 0.7);
    _set(pose, PoseJoint.leftAnkle + side, x, 0.9);

    if (kind == ActionMovementKind.pressUps) {
      _set(pose, PoseJoint.leftShoulder + side, 0.2, 0.5);
      _set(pose, PoseJoint.leftElbow + side, 0.2, 0.65);
      _set(pose, PoseJoint.leftWrist + side, 0.2, 0.8);
      _set(pose, PoseJoint.leftHip + side, 0.5, 0.5);
    }
    if (kind == ActionMovementKind.sitUps) {
      _set(pose, PoseJoint.leftShoulder + side, 0.2, 0.5);
      _set(pose, PoseJoint.leftHip + side, 0.4, 0.5);
      _set(pose, PoseJoint.leftKnee + side, 0.65, 0.65);
    }
  }
  return pose;
}

List<NormalizedLandmark> _active(ActionMovementKind kind) {
  final pose = _rest(kind);
  for (final side in [0, 1]) {
    final x = 0.4 + 0.2 * side;
    switch (kind) {
      case ActionMovementKind.squats ||
          ActionMovementKind.lunges ||
          ActionMovementKind.burpees:
        _set(pose, PoseJoint.leftAnkle + side, x + 0.2, 0.7);
      case ActionMovementKind.pressUps:
        _set(pose, PoseJoint.leftWrist + side, 0.35, 0.65);
      case ActionMovementKind.bicepsCurls:
        _set(pose, PoseJoint.leftWrist + side, x + 0.02, 0.31);
      case ActionMovementKind.lateralRaises:
        _set(pose, PoseJoint.leftElbow + side, side == 0 ? 0.2 : 0.8, 0.3);
      case ActionMovementKind.highKnees:
        _set(pose, PoseJoint.leftKnee + side, x + 0.2, 0.5);
      case ActionMovementKind.sitUps:
        _set(pose, PoseJoint.leftShoulder + side, 0.55, 0.35);
      case ActionMovementKind.sideBends:
        _set(pose, PoseJoint.leftShoulder + side, x + 0.13, 0.3);
      case ActionMovementKind.starJumps:
        _set(pose, PoseJoint.leftWrist + side, x, 0.05);
        _set(pose, PoseJoint.leftAnkle + side, side == 0 ? 0.15 : 0.85, 0.9);
      case ActionMovementKind.footballKickUps ||
          ActionMovementKind.tableTennisBounces:
        throw ArgumentError.value(kind);
    }
  }
  return pose;
}

List<NormalizedLandmark> _hideRightSide(List<NormalizedLandmark> pose) {
  final hidden = [...pose];
  for (final joint in [
    PoseJoint.rightShoulder,
    PoseJoint.rightElbow,
    PoseJoint.rightWrist,
    PoseJoint.rightHip,
    PoseJoint.rightKnee,
    PoseJoint.rightAnkle,
  ]) {
    final point = hidden[joint];
    hidden[joint] = NormalizedLandmark(
      x: point.x,
      y: point.y,
      z: 0,
      visibility: 0.2,
    );
  }
  return hidden;
}

void _set(List<NormalizedLandmark> pose, int index, double x, double y) {
  pose[index] = NormalizedLandmark(
    x: x,
    y: y,
    z: 0,
    visibility: 1,
    presence: 1,
  );
}
