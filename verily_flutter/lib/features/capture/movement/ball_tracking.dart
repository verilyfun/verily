import 'dart:math' as math;

import 'package:mp_core/mp_core.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';

/// Ball detector identity included in ball-skill tracker versions.
const ballModelVersion = 'effdet0-v1';

/// A detected ball in upright, unmirrored, normalized image coordinates.
final class BallObservation {
  const BallObservation({
    required this.x,
    required this.y,
    required this.radius,
    required this.score,
  });

  final double x;
  final double y;

  /// Half the larger box side, as a fraction of the image height.
  final double radius;
  final double score;
}

/// The body part that sent the ball back up.
enum MovementLimb { leftLeg, rightLeg, leftArm, rightArm, head, chest }

/// One counted touch, used to drive the touch effects.
final class BallTouch {
  const BallTouch({
    required this.timestampMs,
    required this.x,
    required this.y,
    required this.limb,
  });

  final int timestampMs;
  final double x;
  final double y;
  final MovementLimb limb;
}

typedef _Reversal = ({
  double x,
  double y,
  double radius,
  int timestampMs,
  List<NormalizedLandmark> pose,
  double aspectRatio,
});

typedef _Leg = ({
  MovementLimb limb,
  int hip,
  int knee,
  int ankle,
  int toe,
  int otherAnkle,
});

/// Counts consecutive touches that keep a ball in the air.
///
/// A touch is the moment the ball stops falling and starts rising while it
/// is next to a body part allowed for the skill. A reversal anywhere else —
/// the floor, a table, a wall — ends the run, as does losing sight of the
/// ball or the ball coming to rest. The progress count is the current run,
/// and the progress best is the longest run in the set.
final class BallTouchTracker implements MovementTracker {
  BallTouchTracker(this.kind)
    : assert(
        kind == ActionMovementKind.footballKickUps ||
            kind == ActionMovementKind.tableTennisBounces,
        '$kind is not a ball skill',
      );

  final ActionMovementKind kind;

  /// Losing the ball for this long ends the run.
  static const lostAfterMs = 900;

  /// A ball that has not changed direction for this long has been caught or
  /// has come to rest.
  static const stalledAfterMs = 2000;

  int _run = 0;
  int _best = 0;
  int? _lastSeenMs;
  int? _lastReversalMs;
  int? _lastTimestamp;
  double? _previousY;
  bool _falling = false;
  _Reversal? _lowest;
  BallTouch? _touch;
  bool _dropped = false;
  MovementProgress _progress = MovementProgress.initial;

  bool get _football => kind == ActionMovementKind.footballKickUps;

  int get _minimumTouchGapMs => _football ? 250 : 150;

  @override
  String get version =>
      '$poseModelVersion.$ballModelVersion.'
      '${_football ? 'football-kick-ups' : 'table-tennis-bounces'}-v1';

  @override
  MovementProgress get progress => _progress;

  @override
  MovementProgress update(MovementObservation observation) {
    final timestamp = observation.timestampMs;
    final previous = _lastTimestamp;
    if (previous != null && timestamp <= previous) return _progress;
    _lastTimestamp = timestamp;

    final ball = observation.ball;
    final hasPose = observation.pose.length >= PoseJoint.count;
    if (ball == null) {
      if (_lastSeenMs case final seen? when timestamp - seen > lostAfterMs) {
        _endRun();
        _previousY = null;
        _falling = false;
        _lowest = null;
      }
      return _publish(hasPose: hasPose, hasBall: false);
    }
    _lastSeenMs = timestamp;
    _lastReversalMs ??= timestamp;
    if (timestamp - _lastReversalMs! > stalledAfterMs) {
      _endRun();
      _lastReversalMs = timestamp;
    }

    final rise = math.max(ball.radius * 0.6, 0.012);
    final previousY = _previousY;
    _previousY = ball.y;
    if (previousY != null && ball.y > previousY + 0.002) {
      _falling = true;
    }
    final lowest = _lowest;
    if (_falling && (lowest == null || ball.y >= lowest.y)) {
      // Keep the body as it was at the lowest point: by the time the rise
      // is confirmed, the kicking foot has already moved away.
      _lowest = (
        x: ball.x,
        y: ball.y,
        radius: ball.radius,
        timestampMs: timestamp,
        pose: observation.pose,
        aspectRatio: observation.aspectRatio,
      );
    } else if (_falling && lowest != null && ball.y < lowest.y - rise) {
      // The fall turned into a rise at the lowest point.
      _falling = false;
      _lowest = null;
      _lastReversalMs = timestamp;
      final limb = lowest.pose.length >= PoseJoint.count
          ? _contact(lowest)
          : null;
      if (limb == null) {
        _endRun();
      } else if (_touch == null ||
          lowest.timestampMs - _touch!.timestampMs >= _minimumTouchGapMs) {
        _run++;
        _best = math.max(_best, _run);
        _dropped = false;
        _touch = BallTouch(
          timestampMs: lowest.timestampMs,
          x: lowest.x,
          y: lowest.y,
          limb: limb,
        );
      }
    }
    return _publish(hasPose: hasPose, hasBall: true);
  }

  @override
  void interrupt() {
    _endRun();
    _previousY = null;
    _falling = false;
    _lowest = null;
    _lastSeenMs = null;
    _lastReversalMs = null;
    _publish(hasPose: false, hasBall: false);
  }

  void _endRun() {
    if (_run > 0) _dropped = true;
    _run = 0;
  }

  MovementProgress _publish({required bool hasPose, required bool hasBall}) {
    return _progress = MovementProgress(
      count: _run,
      best: _best,
      depth: 0,
      tracking: hasPose && hasBall,
      cue: !hasPose
          ? MovementCue.stepIntoFrame
          : !hasBall
          ? MovementCue.showBall
          : _dropped && _run == 0
          ? MovementCue.dropped
          : MovementCue.perform,
      touch: _touch,
    );
  }

  /// The allowed body part nearest the reversal point, if it was close
  /// enough to have touched the ball.
  ///
  /// Feet and shins only count while that foot is lifted clear of the
  /// standing foot: a ball bouncing off the floor beside a planted foot is
  /// a drop, not a kick-up. Thighs, chest, and head always count.
  MovementLimb? _contact(_Reversal ball) {
    final pose = ball.pose;
    final aspect = ball.aspectRatio;
    bool visible(int joint) => (pose[joint].visibility ?? 0) >= 0.5;
    math.Point<double> at(int joint) =>
        math.Point(pose[joint].x * aspect, pose[joint].y);
    final point = math.Point(ball.x * aspect, ball.y);
    final scale = _bodyScale(visible, at);
    if (scale == null) return null;

    MovementLimb? nearest;
    var nearestDistance = double.infinity;
    void consider(
      MovementLimb limb,
      math.Point<double> a,
      math.Point<double> b,
    ) {
      final distance = _segmentDistance(point, a, b);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = limb;
      }
    }

    if (_football) {
      for (final leg in _legs) {
        if (visible(leg.hip) && visible(leg.knee)) {
          consider(leg.limb, at(leg.hip), at(leg.knee));
        }
        final lifted =
            visible(leg.ankle) &&
            visible(leg.otherAnkle) &&
            pose[leg.ankle].y < pose[leg.otherAnkle].y - scale * 0.15;
        if (!lifted || !visible(leg.knee)) continue;
        consider(leg.limb, at(leg.knee), at(leg.ankle));
        if (visible(leg.toe)) consider(leg.limb, at(leg.ankle), at(leg.toe));
      }
      if (visible(PoseJoint.leftShoulder) && visible(PoseJoint.rightShoulder)) {
        consider(
          MovementLimb.chest,
          at(PoseJoint.leftShoulder),
          at(PoseJoint.rightShoulder),
        );
      }
      if (visible(PoseJoint.nose)) {
        consider(MovementLimb.head, at(PoseJoint.nose), at(PoseJoint.nose));
      }
    } else {
      for (final (limb, wrist, index) in const [
        (MovementLimb.leftArm, PoseJoint.leftWrist, PoseJoint.leftIndex),
        (MovementLimb.rightArm, PoseJoint.rightWrist, PoseJoint.rightIndex),
      ]) {
        if (!visible(wrist) || !visible(index)) continue;
        // The bat face sits beyond the hand, along the line of the fingers.
        final hand = at(index) - at(wrist);
        consider(limb, at(wrist), at(index) + hand * 2.5);
      }
    }
    final reach = ball.radius + scale * (_football ? 0.35 : 0.3);
    return nearestDistance <= reach ? nearest : null;
  }

  static double? _bodyScale(
    bool Function(int) visible,
    math.Point<double> Function(int) at,
  ) {
    for (final (shoulder, hip) in const [
      (PoseJoint.leftShoulder, PoseJoint.leftHip),
      (PoseJoint.rightShoulder, PoseJoint.rightHip),
    ]) {
      if (visible(shoulder) && visible(hip)) {
        return at(shoulder).distanceTo(at(hip));
      }
    }
    return null;
  }

  static double _segmentDistance(
    math.Point<double> point,
    math.Point<double> start,
    math.Point<double> end,
  ) {
    final segment = end - start;
    final lengthSquared = segment.x * segment.x + segment.y * segment.y;
    if (lengthSquared == 0) return point.distanceTo(start);
    final t =
        (((point - start).x * segment.x + (point - start).y * segment.y) /
                lengthSquared)
            .clamp(0.0, 1.0);
    return point.distanceTo(start + segment * t);
  }

  static const List<_Leg> _legs = [
    (
      limb: MovementLimb.leftLeg,
      hip: PoseJoint.leftHip,
      knee: PoseJoint.leftKnee,
      ankle: PoseJoint.leftAnkle,
      toe: PoseJoint.leftFootIndex,
      otherAnkle: PoseJoint.rightAnkle,
    ),
    (
      limb: MovementLimb.rightLeg,
      hip: PoseJoint.rightHip,
      knee: PoseJoint.rightKnee,
      ankle: PoseJoint.rightAnkle,
      toe: PoseJoint.rightFootIndex,
      otherAnkle: PoseJoint.leftAnkle,
    ),
  ];
}
