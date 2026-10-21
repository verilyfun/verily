import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/local_check/local_check_catalog.dart';
import 'package:verily_flutter/features/local_check/local_check_session.dart';
import 'package:verily_flutter/features/local_check/local_check_tally.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Where the capture is, for what the guide says once the phone sees the
/// label.
enum LocalCheckMoment {
  /// Framing a video before recording.
  preview,

  /// Recording, but not yet as long as the action asks.
  recordingTooShort,

  /// Recording with a spoken word still to say: the person stops it.
  recordingWithWord,

  /// The phone is stopping the recording or taking the photo itself.
  finishing,
}

/// How the guide reads: searching, nearly there, or seen.
enum LocalCheckTone { neutral, almost, seen }

/// What the live guide says, for one state of the check.
@immutable
final class LocalCheckGuideCopy {
  const LocalCheckGuideCopy({
    required this.title,
    required this.message,
    required this.tone,
    required this.icon,
  });

  final String title;
  final String message;
  final LocalCheckTone tone;
  final WiredSvgIconData icon;
}

/// The guide's words for [check]. [availability] is null when the phone
/// does not run the check live at all (a sound check, or a platform without
/// the runtime): the person learns Verily checks it after they finish.
LocalCheckGuideCopy localCheckGuideCopy(
  AppLocalizations l10n, {
  required ActionLocalCheck check,
  required LocalCheckAvailability? availability,
  LocalCheckGuidance guidance = LocalCheckGuidance.notSeen,
  LocalCheckMoment moment = LocalCheckMoment.preview,
}) {
  final label = localCheckLabelName(l10n, check.task, check.label);
  final title = l10n.localCheckGuideTitle(label);
  LocalCheckGuideCopy copy(
    String message,
    WiredSvgIconData icon, [
    LocalCheckTone tone = LocalCheckTone.neutral,
  ]) => LocalCheckGuideCopy(
    title: title,
    message: message,
    tone: tone,
    icon: icon,
  );

  if (availability == null ||
      availability == LocalCheckAvailability.unavailable) {
    return copy(
      check.task == LocalCheckTask.sound
          ? l10n.localCheckAfterFinishListen(label)
          : l10n.localCheckAfterFinishLook(label),
      VerilyIcons.info,
    );
  }
  if (availability == LocalCheckAvailability.loading) {
    return copy(l10n.localCheckPreparing, VerilyIcons.hourglass);
  }
  final gesture = check.task == LocalCheckTask.gesture;
  return switch (guidance) {
    LocalCheckGuidance.notSeen => copy(
      gesture
          ? l10n.localCheckGestureNotSeen(label)
          : l10n.localCheckObjectNotSeen(label),
      VerilyIcons.scan,
    ),
    LocalCheckGuidance.subjectSeen => copy(
      l10n.localCheckGestureHandSeen(label),
      VerilyIcons.hand,
      LocalCheckTone.almost,
    ),
    LocalCheckGuidance.almost => copy(
      gesture
          ? l10n.localCheckGestureHandSeen(label)
          : l10n.localCheckObjectAlmost(label),
      gesture ? VerilyIcons.hand : VerilyIcons.eye,
      LocalCheckTone.almost,
    ),
    LocalCheckGuidance.holding => copy(
      l10n.localCheckHolding,
      VerilyIcons.eye,
      LocalCheckTone.seen,
    ),
    LocalCheckGuidance.passed => copy(
      switch (moment) {
        LocalCheckMoment.preview => l10n.localCheckReadyToRecord,
        LocalCheckMoment.recordingTooShort => l10n.localCheckKeepGoing,
        LocalCheckMoment.recordingWithWord => l10n.localCheckSayWordThenStop,
        LocalCheckMoment.finishing => l10n.localCheckFinishing,
      },
      VerilyIcons.check,
      LocalCheckTone.seen,
    ),
  };
}

/// The live quick-check guide over the viewfinder: what the phone looks or
/// listens for, and what to do next.
///
/// It speaks only of what the phone sees; it never says the proof passed,
/// because Verily checks the proof again after it is sent.
class LocalCheckGuide extends StatelessWidget {
  const LocalCheckGuide({required this.copy, super.key});

  final LocalCheckGuideCopy copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The tone is told by the words and the icon. Seeing the label is also
    // inked on paper, the HUD's emphasis, and never in a role colour: the
    // phone has not verified anything.
    final seen = copy.tone == LocalCheckTone.seen;
    final fill = seen
        ? VerilyColors.movementHudInk
        : VerilyColors.movementScrim;
    final ink = seen
        ? VerilyColors.movementOutline
        : VerilyColors.movementHudInk;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${copy.title}. ${copy.message}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            key: VerilyTestKeys.captureLocalCheckGuide,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: VerilyRoughDecoration(
              color: fill,
              outline: ink,
              seed: 433,
            ),
            child: Row(
              children: [
                SkribbleIcon(data: copy.icon, size: 26, color: ink),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        copy.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        copy.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
