import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/widgets/verily_fitted_text.dart';
import 'package:verily_flutter/features/capture/capture_models.dart';
import 'package:verily_flutter/features/capture/movement/movement_copy.dart';
import 'package:verily_flutter/features/capture/movement/recording_files.dart';
import 'package:verily_flutter/features/capture/movement/widgets/movement_capture_view.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// Debug-only harness for tuning live movement tracking on a device.
///
/// It opens the real movement capture for any movement without a server,
/// account, or action, reports what the tracker counted, and discards the
/// recording.
class MovementTrackingPreviewScreen extends StatelessWidget {
  const MovementTrackingPreviewScreen({this.delay, super.key});

  /// Replaces the countdown's real waiting in tests.
  final MovementCaptureDelay? delay;

  static const _target = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    Future<void> open(ActionMovementKind kind) async {
      final requirement = ActionRequirementView(
        id: UuidValue.fromString('00000000-0000-4000-8000-000000000000'),
        requirementKey: 'developer-preview',
        kind: ActionRequirementKind.video,
        title: movementName(l10n, kind),
        instructions: movementGuide(l10n, kind),
        position: 0,
        isRequired: true,
        minDurationSeconds: 3,
        maxDurationSeconds: 120,
        movementKind: kind,
        targetRepetitions: _target,
      );
      final recording = await Navigator.of(context).push<RawCapture>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => MovementCaptureView(
            requirement: requirement,
            delay: delay,
            onRecorded: (raw) => Navigator.of(context).pop(raw),
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      );
      if (recording == null) return;
      unawaited(deleteRecording(recording.file));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.movementPreviewResult(
              recording.repetitions ?? 0,
              recording.trackerVersion ?? '-',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: VerilyFittedText(l10n.developerMovementPreview)),
      body: ListView(
        children: [
          for (final kind in ActionMovementKind.values)
            ListTile(
              title: Text(movementName(l10n, kind)),
              subtitle: Text(movementGuide(l10n, kind)),
              trailing: const SkribbleIcon(data: VerilyIcons.chevronRight),
              onTap: () => unawaited(open(kind)),
            ),
        ],
      ),
    );
  }
}
