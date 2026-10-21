import 'dart:math' as math;

import 'package:mp_core/mp_core.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/capture/movement/ball_tracking.dart';

/// MediaPipe BlazePose landmark indices used by the movement trackers.
abstract final class PoseJoint {
  static const nose = 0;
  static const leftShoulder = 11;
  static const rightShoulder = 12;
  static const leftElbow = 13;
  static const rightElbow = 14;
  static const leftWrist = 15;
  static const rightWrist = 16;
  static const leftIndex = 19;
  static const rightIndex = 20;
  static const leftHip = 23;
  static const rightHip = 24;
  static const leftKnee = 25;
  static const rightKnee = 26;
  static const leftAnkle = 27;
  static const rightAnkle = 28;
  static const leftFootIndex = 31;
  static const rightFootIndex = 32;

  /// Landmarks in one complete pose.
  static const count = 33;
}

/// What the camera saw in one analysed frame.
///
/// Coordinates are upright and unmirrored, normalized to the image, so x and
/// y are both in `0..1` regardless of the frame's aspect ratio.
final class MovementObservation {
  const MovementObservation({
    required this.pose,
    required this.aspectRatio,
    required this.timestampMs,
    this.ball,
  });

  /// All 33 pose landmarks, or empty when nobody was found.
  final List<NormalizedLandmark> pose;

  /// The ball, for ball skills, when one was detected.
  final BallObservation? ball;

  /// Image width divided by height, used to measure true angles.
  final double aspectRatio;

  /// Strictly increasing capture time in milliseconds.
  final int timestampMs;
}

/// The next thing the participant should do, localized by the UI.
enum MovementCue {
  /// Required joints are not visible.
  stepIntoFrame,

  /// Visible, but no stable starting position yet.
  getIntoPosition,

  /// Ready for the working part of the movement.
  perform,

  /// The movement reached depth; return to the start to count it.
  returnToStart,

  /// Burpee stages, in order.
  crouch,
  plank,
  feetForward,
  jump,
  land,

  /// Ball skills: the ball is not in view.
  showBall,

  /// Ball skills: the run just ended; start another.
  dropped,
}

/// Live, advisory progress for one movement.
final class MovementProgress {
  const MovementProgress({
    required this.count,
    required this.best,
    required this.depth,
    required this.tracking,
    required this.cue,
    this.touch,
  });

  static const initial = MovementProgress(
    count: 0,
    best: 0,
    depth: 0,
    tracking: false,
    cue: MovementCue.stepIntoFrame,
  );

  /// Completed repetitions in this set, or the current unbroken run of
  /// touches for a ball skill.
  final int count;

  /// The result to report for the set: the count for exercises, and the
  /// longest run for ball skills.
  final int best;

  /// The latest ball touch, which drives the touch effects.
  final BallTouch? touch;

  /// Progress through the current repetition, from 0 (start) to 1 (depth).
  final double depth;

  /// Whether the body was measurable in the latest frame.
  final bool tracking;

  final MovementCue cue;

  /// Whether the current repetition has reached the depth that counts.
  bool get atDepth => depth >= RepetitionCounter.extendedThreshold;
}

/// Turns camera observations into live coaching for one movement.
///
/// Counts are guidance for the participant, not proof: the server verifies
/// the recording independently and never trusts this number.
abstract interface class MovementTracker {
  /// Identifies the model and counting rules, stored with the evidence.
  String get version;

  MovementProgress get progress;

  MovementProgress update(MovementObservation observation);

  /// Discards a partial repetition while keeping completed ones.
  void interrupt();
}

/// Pose model identity included in every tracker version.
const poseModelVersion = 'pose-lite-v1';

extension MovementKindTraits on ActionMovementKind {
  /// Ball skills track a ball as well as the body.
  bool get isBallSkill =>
      this == ActionMovementKind.footballKickUps ||
      this == ActionMovementKind.tableTennisBounces;
}

/// Returns the live tracker for [kind].
MovementTracker movementTrackerFor(ActionMovementKind kind) {
  return switch (kind) {
    ActionMovementKind.burpees => BurpeeTracker(),
    ActionMovementKind.footballKickUps ||
    ActionMovementKind.tableTennisBounces => BallTouchTracker(kind),
    _ => RepetitionTracker(kind),
  };
}

/// Counts cyclic exercises from a single joint-angle measurement.
final class RepetitionTracker implements MovementTracker {
  RepetitionTracker(this.kind)
    : assert(
        kind != ActionMovementKind.burpees &&
            kind != ActionMovementKind.footballKickUps &&
            kind != ActionMovementKind.tableTennisBounces,
        '$kind is not a single-angle exercise',
      ),
      _counter = RepetitionCounter(
        dwellMs: _timing(kind).dwellMs,
        minimumCycleMs: _timing(kind).minimumCycleMs,
      );

  final ActionMovementKind kind;
  final RepetitionCounter _counter;
  MovementProgress _progress = MovementProgress.initial;

  @override
  String get version => '$poseModelVersion.${_versionName(kind)}-v1';

  @override
  MovementProgress get progress => _progress;

  @override
  MovementProgress update(MovementObservation observation) {
    _counter.update(
      movementDepth(kind, observation.pose, observation.aspectRatio),
      observation.timestampMs,
    );
    return _progress = MovementProgress(
      count: _counter.count,
      best: _counter.count,
      depth: _counter.depth,
      tracking: _counter.tracking,
      cue: _counter.cue,
    );
  }

  @override
  void interrupt() {
    _counter.interrupt();
    _progress = MovementProgress(
      count: _counter.count,
      best: _counter.count,
      depth: 0,
      tracking: false,
      cue: MovementCue.stepIntoFrame,
    );
  }
}

/// Normalized movement depth for a single-angle exercise.
///
/// Returns null when the joints the measurement needs are not reliably
/// visible. Angles are measured after stretching x by [aspectRatio], so a
/// portrait frame does not distort them.
double? movementDepth(
  ActionMovementKind kind,
  List<NormalizedLandmark> pose,
  double aspectRatio,
) {
  if (pose.length < PoseJoint.count ||
      !aspectRatio.isFinite ||
      aspectRatio <= 0) {
    return null;
  }
  final body = _Body(pose, aspectRatio);
  final depth = switch (kind) {
    ActionMovementKind.squats => _scale(body.knees(), from: 170, span: 75),
    ActionMovementKind.lunges => _scale(
      body.bothSides(_Limb.knee, math.min),
      from: 165,
      span: 70,
    ),
    ActionMovementKind.pressUps =>
      body.torsoHorizontal()
          ? _scale(body.elbows(), from: 170, span: 80)
          : null,
    ActionMovementKind.bicepsCurls =>
      body.torsoUpright() ? _scale(body.elbows(), from: 165, span: 110) : null,
    ActionMovementKind.sitUps => _scale(body.hips(), from: 115, span: 45),
    ActionMovementKind.highKnees => _scale(
      body.bothSides(_Limb.hip, math.min),
      from: 170,
      span: 85,
    ),
    ActionMovementKind.lateralRaises => switch (body.bothSides(
      _Limb.shoulder,
      (left, right) => (left + right) / 2,
    )) {
      final abduction? => (abduction - 15) / 70,
      null => null,
    },
    ActionMovementKind.sideBends => body.sideLean(),
    ActionMovementKind.starJumps => body.starSpread(),
    ActionMovementKind.burpees => _scale(body.knees(), from: 170, span: 75),
    ActionMovementKind.footballKickUps ||
    ActionMovementKind.tableTennisBounces => throw ArgumentError.value(
      kind,
      'kind',
      'Ball skills are not measured from one joint angle.',
    ),
  };
  if (depth == null || !depth.isFinite) return null;
  return depth.clamp(0.0, 1.0);
}

double? _scale(double? angle, {required double from, required double span}) {
  return angle == null ? null : (from - angle) / span;
}

/// Counts stable rest → depth → rest cycles.
///
/// Hysteresis zones, a minimum dwell in each zone, and a minimum cycle time
/// reject jitter and short pulses. Losing tracking, or a gap between frames,
/// discards the partial repetition but keeps completed ones.
final class RepetitionCounter {
  RepetitionCounter({this.dwellMs = 150, this.minimumCycleMs = 700});

  /// Depth below which the body is back at the start.
  static const restThreshold = 0.2;

  /// Depth above which the working part of the movement is complete.
  static const extendedThreshold = 0.8;

  /// A longer gap between frames than this discards the partial repetition.
  static const maximumFrameGapMs = 700;

  final int dwellMs;
  final int minimumCycleMs;

  int count = 0;
  double depth = 0;
  bool tracking = false;
  bool _armed = false;
  bool _extended = false;
  int? _candidateSince;
  int? _cycleSince;
  int? _lastTimestamp;
  int _candidate = -1;

  MovementCue get cue {
    if (!tracking) return MovementCue.stepIntoFrame;
    if (!_armed) return MovementCue.getIntoPosition;
    return _extended ? MovementCue.returnToStart : MovementCue.perform;
  }

  /// Consumes a depth sample, or null when the body was not measurable.
  void update(double? value, int timestampMs) {
    final previous = _lastTimestamp;
    if (previous != null && timestampMs <= previous) return;
    _lastTimestamp = timestampMs;
    if (value == null ||
        !value.isFinite ||
        (previous != null && timestampMs - previous > maximumFrameGapMs)) {
      interrupt();
      return;
    }

    tracking = true;
    depth = value.clamp(0.0, 1.0);
    final zone = depth < restThreshold
        ? 0
        : depth > extendedThreshold
        ? 1
        : -1;
    if (zone != _candidate) {
      _candidate = zone;
      _candidateSince = timestampMs;
    }
    if (zone == -1 || timestampMs - _candidateSince! < dwellMs) return;

    if (zone == 0) {
      if (_armed && _extended && timestampMs - _cycleSince! >= minimumCycleMs) {
        count++;
      }
      _armed = true;
      _extended = false;
      _cycleSince = timestampMs;
    } else if (_armed) {
      _extended = true;
    }
  }

  /// Discards a partial repetition while keeping completed ones.
  void interrupt() {
    tracking = false;
    depth = 0;
    _armed = false;
    _extended = false;
    _candidate = -1;
    _candidateSince = null;
    _cycleSince = null;
  }
}

/// Stages of a complete burpee, in order.
enum BurpeeStage { ready, crouch, plank, returnCrouch, jump, land }

/// Counts burpees as an ordered sequence, so a squat alone never counts.
///
/// The jump is measured against the standing ankle height, which assumes the
/// camera stays still for the whole set.
final class BurpeeTracker implements MovementTracker {
  int _count = 0;
  BurpeeStage stage = BurpeeStage.ready;
  double? _floor;
  int? _lastTimestamp;
  int? _stageSince;
  MovementProgress _progress = MovementProgress.initial;

  @override
  String get version => '$poseModelVersion.burpees-v1';

  @override
  MovementProgress get progress => _progress;

  @override
  MovementProgress update(MovementObservation observation) {
    final timestamp = observation.timestampMs;
    final previous = _lastTimestamp;
    if (previous != null && timestamp <= previous) return _progress;
    _lastTimestamp = timestamp;
    final pose = observation.pose;
    final aspect = observation.aspectRatio;
    final bend = movementDepth(ActionMovementKind.burpees, pose, aspect);
    final gap =
        previous != null &&
        timestamp - previous > RepetitionCounter.maximumFrameGapMs;
    // The jump baseline reads both ankles, so every stage joint must be seen.
    final body = _Body(pose, aspect);
    final torso = bend == null || !body._allVisible(_burpeeJoints)
        ? null
        : body.torso();
    if (bend == null || gap || torso == null) {
      interrupt();
      return _progress;
    }

    final ankleY =
        (pose[PoseJoint.leftAnkle].y + pose[PoseJoint.rightAnkle].y) / 2;
    final upright = torso.hipY - torso.shoulderY > torso.horizontal;
    final standing = upright && bend < 0.2;
    final crouched = bend > 0.8;
    final plank =
        !upright &&
        (torso.shoulderY - torso.hipY).abs() < torso.horizontal * 0.6 &&
        bend < 0.25;

    if (_stageSince == null || timestamp - _stageSince! >= 100) {
      final advance = switch (stage) {
        BurpeeStage.ready => standing,
        BurpeeStage.crouch || BurpeeStage.returnCrouch => crouched,
        BurpeeStage.plank => plank,
        BurpeeStage.jump => standing && ankleY < _floor! - 0.045,
        BurpeeStage.land => standing && (ankleY - _floor!).abs() < 0.025,
      };
      if (advance) {
        if (stage == BurpeeStage.ready) _floor = ankleY;
        if (stage == BurpeeStage.land) {
          _count++;
          stage = BurpeeStage.crouch;
          _floor = ankleY;
        } else {
          stage = BurpeeStage.values[stage.index + 1];
        }
        _stageSince = timestamp;
      }
    }
    return _progress = MovementProgress(
      count: _count,
      best: _count,
      depth: stage.index / (BurpeeStage.values.length - 1),
      tracking: true,
      cue: switch (stage) {
        BurpeeStage.ready => MovementCue.getIntoPosition,
        BurpeeStage.crouch => MovementCue.crouch,
        BurpeeStage.plank => MovementCue.plank,
        BurpeeStage.returnCrouch => MovementCue.feetForward,
        BurpeeStage.jump => MovementCue.jump,
        BurpeeStage.land => MovementCue.land,
      },
    );
  }

  @override
  void interrupt() {
    stage = BurpeeStage.ready;
    _floor = null;
    _stageSince = null;
    _progress = MovementProgress(
      count: _count,
      best: _count,
      depth: 0,
      tracking: false,
      cue: MovementCue.stepIntoFrame,
    );
  }
}

const List<int> _burpeeJoints = [
  PoseJoint.leftShoulder,
  PoseJoint.rightShoulder,
  PoseJoint.leftHip,
  PoseJoint.rightHip,
  PoseJoint.leftKnee,
  PoseJoint.rightKnee,
  PoseJoint.leftAnkle,
  PoseJoint.rightAnkle,
];

typedef _Timing = ({int dwellMs, int minimumCycleMs});

/// Fast, alternating movements need shorter dwell and cycle limits.
_Timing _timing(ActionMovementKind kind) => switch (kind) {
  ActionMovementKind.highKnees => (dwellMs: 60, minimumCycleMs: 300),
  ActionMovementKind.starJumps => (dwellMs: 80, minimumCycleMs: 450),
  ActionMovementKind.sitUps => (dwellMs: 150, minimumCycleMs: 800),
  _ => (dwellMs: 150, minimumCycleMs: 700),
};

String _versionName(ActionMovementKind kind) => kind.name
    .replaceAllMapped(RegExp('[A-Z]'), (match) => '-${match[0]}')
    .toLowerCase();

enum _Limb { shoulder, elbow, hip, knee }

typedef _Torso = ({double shoulderY, double hipY, double horizontal});

/// Aspect-corrected geometry over one pose.
final class _Body {
  _Body(this.pose, this.aspect);

  static const _minimumVisibility = 0.6;

  final List<NormalizedLandmark> pose;
  final double aspect;

  /// Joint triples for each limb angle, measured at the middle joint.
  static const Map<_Limb, (int, int, int)> _left = {
    _Limb.shoulder: (
      PoseJoint.leftHip,
      PoseJoint.leftShoulder,
      PoseJoint.leftElbow,
    ),
    _Limb.elbow: (
      PoseJoint.leftShoulder,
      PoseJoint.leftElbow,
      PoseJoint.leftWrist,
    ),
    _Limb.hip: (PoseJoint.leftShoulder, PoseJoint.leftHip, PoseJoint.leftKnee),
    _Limb.knee: (PoseJoint.leftHip, PoseJoint.leftKnee, PoseJoint.leftAnkle),
  };
  static const Map<_Limb, (int, int, int)> _right = {
    _Limb.shoulder: (
      PoseJoint.rightHip,
      PoseJoint.rightShoulder,
      PoseJoint.rightElbow,
    ),
    _Limb.elbow: (
      PoseJoint.rightShoulder,
      PoseJoint.rightElbow,
      PoseJoint.rightWrist,
    ),
    _Limb.hip: (
      PoseJoint.rightShoulder,
      PoseJoint.rightHip,
      PoseJoint.rightKnee,
    ),
    _Limb.knee: (PoseJoint.rightHip, PoseJoint.rightKnee, PoseJoint.rightAnkle),
  };

  double? knees() => _eitherSide(_Limb.knee);
  double? elbows() => _eitherSide(_Limb.elbow);
  double? hips() => _eitherSide(_Limb.hip);

  /// Mean angle over the visible sides. Side-on exercises often hide one
  /// side behind the other, so one fully visible side is enough.
  double? _eitherSide(_Limb limb) {
    final left = _angle(_left[limb]!);
    final right = _angle(_right[limb]!);
    if (left == null) return right;
    if (right == null) return left;
    return (left + right) / 2;
  }

  /// Combines both sides; null unless both are visible.
  double? bothSides(_Limb limb, double Function(double, double) combine) {
    final left = _angle(_left[limb]!);
    final right = _angle(_right[limb]!);
    return left == null || right == null ? null : combine(left, right);
  }

  /// Shoulder and hip heights plus their horizontal offset, from the visible
  /// joints on either side.
  _Torso? torso() {
    final shoulder = _mean(PoseJoint.leftShoulder, PoseJoint.rightShoulder);
    final hip = _mean(PoseJoint.leftHip, PoseJoint.rightHip);
    if (shoulder == null || hip == null) return null;
    return (
      shoulderY: shoulder.$2,
      hipY: hip.$2,
      horizontal: ((shoulder.$1 - hip.$1) * aspect).abs(),
    );
  }

  /// A press-up needs a roughly horizontal body.
  bool torsoHorizontal() {
    final torso = this.torso();
    return torso != null &&
        (torso.shoulderY - torso.hipY).abs() <= torso.horizontal * 0.6;
  }

  /// A curl must not be faked by bending at the waist.
  bool torsoUpright() {
    final torso = this.torso();
    return torso != null &&
        (torso.shoulderY - torso.hipY).abs() >= torso.horizontal;
  }

  /// Sideways shoulder displacement over the hips, relative to torso height.
  double? sideLean() {
    if (!_allVisible(const [
      PoseJoint.leftShoulder,
      PoseJoint.rightShoulder,
      PoseJoint.leftHip,
      PoseJoint.rightHip,
    ])) {
      return null;
    }
    final torso = this.torso()!;
    final height = math.max((torso.shoulderY - torso.hipY).abs(), 0.01);
    return (torso.horizontal / height - 0.08) / 0.4;
  }

  /// Arms overhead and feet wider than the shoulders, both at once.
  double? starSpread() {
    if (!_allVisible(const [
      PoseJoint.leftShoulder,
      PoseJoint.rightShoulder,
      PoseJoint.leftWrist,
      PoseJoint.rightWrist,
      PoseJoint.leftHip,
      PoseJoint.rightHip,
      PoseJoint.leftAnkle,
      PoseJoint.rightAnkle,
    ])) {
      return null;
    }
    double y(int joint) => pose[joint].y;
    double x(int joint) => pose[joint].x;
    final torso = this.torso()!;
    final height = math.max((torso.shoulderY - torso.hipY).abs(), 0.01);
    final shoulderWidth = math.max(
      (x(PoseJoint.leftShoulder) - x(PoseJoint.rightShoulder)).abs(),
      0.01,
    );
    final armsUp =
        ((y(PoseJoint.leftShoulder) +
                    y(PoseJoint.rightShoulder) -
                    y(PoseJoint.leftWrist) -
                    y(PoseJoint.rightWrist)) /
                2 /
                height +
            0.4) /
        0.9;
    final feetApart =
        ((x(PoseJoint.leftAnkle) - x(PoseJoint.rightAnkle)).abs() /
                shoulderWidth -
            1) /
        0.9;
    return math.min(armsUp, feetApart);
  }

  double? _angle((int, int, int) joints) {
    final (a, b, c) = joints;
    if (!_allVisible([a, b, c])) return null;
    final ax = (pose[a].x - pose[b].x) * aspect;
    final ay = pose[a].y - pose[b].y;
    final cx = (pose[c].x - pose[b].x) * aspect;
    final cy = pose[c].y - pose[b].y;
    final length = math.sqrt((ax * ax + ay * ay) * (cx * cx + cy * cy));
    if (length < 0.00001) return null;
    final cosine = ((ax * cx + ay * cy) / length).clamp(-1.0, 1.0);
    return math.acos(cosine) * 180 / math.pi;
  }

  (double, double)? _mean(int left, int right) {
    final visible = [left, right].where(_visible).toList();
    if (visible.isEmpty) return null;
    final x = visible.map((joint) => pose[joint].x).reduce((a, b) => a + b);
    final y = visible.map((joint) => pose[joint].y).reduce((a, b) => a + b);
    return (x / visible.length, y / visible.length);
  }

  bool _allVisible(List<int> joints) => joints.every(_visible);

  bool _visible(int joint) {
    final point = pose[joint];
    return point.x.isFinite &&
        point.y.isFinite &&
        (point.visibility ?? 0) >= _minimumVisibility &&
        (point.presence ?? 1) >= _minimumVisibility &&
        point.x >= 0 &&
        point.x <= 1 &&
        point.y >= 0 &&
        point.y <= 1;
  }
}
