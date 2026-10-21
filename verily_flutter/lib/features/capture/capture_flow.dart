import 'package:flutter/material.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/capture/media_capture_flow.dart';
import 'package:verily_flutter/features/capture/motion/motion_capture_flow.dart';

/// Captures proof for one camera, microphone, motion, or movement
/// requirement, uploads or submits it, and returns the server's result, or
/// null when the person backed out.
///
/// Handles `video`, `photo`, `audio`, and `motion` requirements (a `video`
/// requirement with a movement kind counts reps live while recording).
/// Every capture is live: there is no gallery or file picker.
Future<EvidenceSubmissionResult?> captureEvidence(
  BuildContext context, {
  required ActionAttemptView attempt,
  required ActionRequirementView requirement,
}) {
  final Widget flow = switch (requirement.kind) {
    ActionRequirementKind.video ||
    ActionRequirementKind.photo ||
    ActionRequirementKind.audio => MediaCaptureFlow(
      attempt: attempt,
      requirement: requirement,
    ),
    ActionRequirementKind.motion => MotionCaptureFlow(
      attempt: attempt,
      requirement: requirement,
    ),
    ActionRequirementKind.location ||
    ActionRequirementKind.qrCode ||
    ActionRequirementKind.externalApp => throw ArgumentError.value(
      requirement.kind,
      'requirement.kind',
      'Not a capture requirement',
    ),
  };
  return Navigator.of(context).push<EvidenceSubmissionResult>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => flow),
  );
}
