import 'package:flutter/rendering.dart';
import 'package:mp_core/mp_core.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';

/// Outlines the participant's body over the camera preview.
///
/// Landmarks are upright and unmirrored, normalized to the analysed frame;
/// the painter must be laid out in the same box as the preview. Bones glow
/// in the depth colour once a repetition reaches the depth that counts, so
/// the participant can see it from across the room.
class MovementBodyPainter extends CustomPainter {
  const MovementBodyPainter({
    required this.pose,
    required this.mirrored,
    required this.atDepth,
  });

  final List<NormalizedLandmark> pose;
  final bool mirrored;
  final bool atDepth;

  static const List<(int, int)> _bones = [
    (PoseJoint.leftShoulder, PoseJoint.rightShoulder),
    (PoseJoint.leftShoulder, PoseJoint.leftElbow),
    (PoseJoint.leftElbow, PoseJoint.leftWrist),
    (PoseJoint.rightShoulder, PoseJoint.rightElbow),
    (PoseJoint.rightElbow, PoseJoint.rightWrist),
    (PoseJoint.leftShoulder, PoseJoint.leftHip),
    (PoseJoint.rightShoulder, PoseJoint.rightHip),
    (PoseJoint.leftHip, PoseJoint.rightHip),
    (PoseJoint.leftHip, PoseJoint.leftKnee),
    (PoseJoint.leftKnee, PoseJoint.leftAnkle),
    (PoseJoint.rightHip, PoseJoint.rightKnee),
    (PoseJoint.rightKnee, PoseJoint.rightAnkle),
    (PoseJoint.leftAnkle, PoseJoint.leftFootIndex),
    (PoseJoint.rightAnkle, PoseJoint.rightFootIndex),
  ];

  static const List<int> _joints = [
    PoseJoint.leftShoulder,
    PoseJoint.rightShoulder,
    PoseJoint.leftElbow,
    PoseJoint.rightElbow,
    PoseJoint.leftWrist,
    PoseJoint.rightWrist,
    PoseJoint.leftHip,
    PoseJoint.rightHip,
    PoseJoint.leftKnee,
    PoseJoint.rightKnee,
    PoseJoint.leftAnkle,
    PoseJoint.rightAnkle,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (pose.length < PoseJoint.count) return;
    if (mirrored) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    Offset at(int joint) =>
        Offset(pose[joint].x * size.width, pose[joint].y * size.height);
    bool visible(int joint) => (pose[joint].visibility ?? 0) >= 0.5;

    // Dusk at rest, paper at depth: the body lights up as the rep counts.
    final glowColor = atDepth
        ? VerilyColors.movementHudInk
        : VerilyColors.movementHudWash;
    final shoulderSpan =
        visible(PoseJoint.leftShoulder) && visible(PoseJoint.rightShoulder)
        ? (at(PoseJoint.leftShoulder) - at(PoseJoint.rightShoulder)).distance
        : size.shortestSide * 0.18;
    final width = (shoulderSpan * 0.09).clamp(4.0, 16.0);

    _paintTorso(canvas, at, visible, glowColor);

    final glow = Paint()
      ..color = glowColor.withValues(alpha: 0.45)
      ..strokeWidth = width * 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final outline = Paint()
      ..color = VerilyColors.movementOutline
      ..strokeWidth = width + 5
      ..strokeCap = StrokeCap.round;
    final bone = Paint()
      ..color = VerilyColors.movementBone
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final visibleBones = [
      for (final (a, b) in _bones)
        if (visible(a) && visible(b)) (at(a), at(b)),
    ];
    // Glows first, then outlines, then fills, so crossings stay clean.
    for (final paint in [glow, outline, bone]) {
      for (final (start, end) in visibleBones) {
        canvas.drawLine(start, end, paint);
      }
    }

    if (visible(PoseJoint.nose) &&
        visible(PoseJoint.leftShoulder) &&
        visible(PoseJoint.rightShoulder)) {
      final head = at(PoseJoint.nose);
      final radius = shoulderSpan * 0.32;
      canvas
        ..drawCircle(
          head,
          radius,
          Paint()
            ..color = glowColor.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = width * 2.4
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        )
        ..drawCircle(
          head,
          radius,
          Paint()
            ..color = VerilyColors.movementBone
            ..style = PaintingStyle.stroke
            ..strokeWidth = width * 0.7,
        );
    }

    final joint = Paint()..color = glowColor;
    final jointOutline = Paint()..color = VerilyColors.movementOutline;
    for (final index in _joints) {
      if (!visible(index)) continue;
      canvas
        ..drawCircle(at(index), width * 0.85 + 2.5, jointOutline)
        ..drawCircle(at(index), width * 0.85, joint);
    }
  }

  void _paintTorso(
    Canvas canvas,
    Offset Function(int) at,
    bool Function(int) visible,
    Color glowColor,
  ) {
    const corners = [
      PoseJoint.leftShoulder,
      PoseJoint.rightShoulder,
      PoseJoint.rightHip,
      PoseJoint.leftHip,
    ];
    if (!corners.every(visible)) return;
    final torso = Path()..addPolygon([for (final c in corners) at(c)], true);
    canvas.drawPath(torso, Paint()..color = glowColor.withValues(alpha: 0.16));
  }

  @override
  bool shouldRepaint(MovementBodyPainter oldDelegate) {
    return !identical(pose, oldDelegate.pose) ||
        mirrored != oldDelegate.mirrored ||
        atDepth != oldDelegate.atDepth;
  }
}
