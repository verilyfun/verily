import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/features/capture/capture_models.dart';
import 'package:verily_flutter/features/capture/capture_providers.dart';
import 'package:verily_flutter/features/capture/widgets/viewfinder.dart';
import 'package:verily_flutter/features/evidence/captured_media.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Shows a capture back before it is sent: play it, retake it, or send it.
///
/// A recording outside the requirement's length cannot be sent; the person
/// retakes it rather than finding out from the server.
class CaptureReviewView extends ConsumerWidget {
  const CaptureReviewView({
    required this.requirement,
    required this.media,
    required this.sending,
    required this.onRetake,
    required this.onSend,
    this.problem,
    this.retrying = false,
    super.key,
  });

  final ActionRequirementView requirement;
  final CapturedMedia media;

  /// Whether the capture is on its way to the server.
  final bool sending;
  final VoidCallback onRetake;
  final VoidCallback onSend;

  /// What went wrong with the last send, and its next step.
  final Widget? problem;

  /// Whether the last send failed, so sending again is the next step.
  final bool retrying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final recording = media.kind != MediaEvidenceKind.photo;
    final minimum = minimumRecording(requirement);
    final maximum = maximumRecording(requirement);
    final tooShort = recording && media.durationSeconds < minimum.inSeconds;
    final tooLong = recording && media.durationSeconds > maximum.inSeconds;
    final word = media.spokenChallengeWord;
    final count = media.deviceRepetitionCount;
    final notes = theme.textTheme.bodyMedium?.copyWith(color: palette.ink);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            VerilyAppHeader(
              title: l10n.captureReviewTitle,
              subtitle: requirement.title,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: ref.watch(capturePreviewBuilderProvider)(
                        context,
                        media,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    recording
                        ? l10n.captureReviewRecordingBody
                        : l10n.captureReviewPhotoBody,
                    style: notes,
                  ),
                  if (word != null) ...[
                    const SizedBox(height: 8),
                    Text(l10n.captureReviewWordCheck(word), style: notes),
                  ],
                  if (recording) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.captureReviewDuration(media.durationSeconds),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.mutedInk,
                      ),
                    ),
                  ],
                  if (count != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.captureReviewDeviceCount(count),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.mutedInk,
                      ),
                    ),
                  ],
                  if (tooShort || tooLong) ...[
                    const SizedBox(height: 12),
                    Text(
                      tooShort
                          ? l10n.captureMinimumHint(minimum.inSeconds)
                          : l10n.captureReviewTooLong(clockLabel(maximum)),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                  ],
                  if (problem case final panel?) ...[
                    const SizedBox(height: 16),
                    panel,
                  ],
                  const SizedBox(height: 16),
                  Text(
                    l10n.captureReviewPrivacy,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          l10n.captureSending,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.mutedInk,
                          ),
                        ),
                      ),
                    ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        VerilyActionButton(
                          key: VerilyTestKeys.captureReviewRetake,
                          label: l10n.captureReviewRetake,
                          tone: VerilyActionTone.secondary,
                          expand: false,
                          onPressed: sending ? null : onRetake,
                        ),
                        VerilyActionButton(
                          key: retrying
                              ? VerilyTestKeys.captureSendAgain
                              : VerilyTestKeys.captureReviewSend,
                          label: retrying
                              ? l10n.captureSendAgain
                              : l10n.captureReviewSend,
                          expand: false,
                          isLoading: sending,
                          onPressed: tooShort || tooLong ? null : onSend,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
