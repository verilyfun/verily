import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show WiredLoadingIndicator;
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/capture/audio/audio_capture_view.dart';
import 'package:verily_flutter/features/capture/camera/camera_capture_view.dart';
import 'package:verily_flutter/features/capture/capture_models.dart';
import 'package:verily_flutter/features/capture/capture_providers.dart';
import 'package:verily_flutter/features/capture/movement/movement_tracking_providers.dart';
import 'package:verily_flutter/features/capture/movement/recording_files.dart';
import 'package:verily_flutter/features/capture/movement/widgets/movement_capture_view.dart';
import 'package:verily_flutter/features/capture/review/capture_review_view.dart';
import 'package:verily_flutter/features/capture/widgets/capture_problem_panel.dart';
import 'package:verily_flutter/features/evidence/captured_media.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Why the last send did not go through.
sealed class _SendProblem {
  const _SendProblem();
}

/// The upload did not complete; the capture is kept to send again.
final class _UploadFailed extends _SendProblem {
  const _UploadFailed();
}

/// This phone could not vouch for the capture.
final class _IntegrityFailed extends _SendProblem {
  const _IntegrityFailed();
}

/// The server refused the proof with words meant for people.
final class _Refused extends _SendProblem {
  const _Refused(this.message);

  final String message;
}

/// Captures, reviews, and sends one photo, video, or audio proof.
///
/// When the requirement asks for a spoken word, the word is fetched from the
/// server before any capture view appears, so nothing records without it.
/// Pops with the server's result once the proof is sent, or null when the
/// person closes.
class MediaCaptureFlow extends HookConsumerWidget {
  const MediaCaptureFlow({
    required this.attempt,
    required this.requirement,
    this.movementDelay,
    super.key,
  });

  final ActionAttemptView attempt;
  final ActionRequirementView requirement;

  /// Replaces the movement countdown's real waiting in tests.
  final MovementCaptureDelay? movementDelay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kind = mediaKindOf(requirement.kind)!;
    final needsWord =
        kind != MediaEvidenceKind.photo && requirement.spokenChallengeRequired;

    final challenge = useState<ActionSpokenChallengeView?>(null);
    final challengeFailed = useState(false);
    final challengeRun = useRef(0);
    final media = useState<CapturedMedia?>(null);
    final preparing = useState(false);
    final captureProblem = useState<CaptureProblem?>(null);
    final sending = useState(false);
    final sendProblem = useState<_SendProblem?>(null);
    final captureRun = useState(0);

    Future<void> fetchWord() async {
      final run = ++challengeRun.value;
      challenge.value = null;
      challengeFailed.value = false;
      try {
        final issued = await ref
            .read(actionRepositoryProvider)
            .issueSpokenChallenge(
              attemptId: attempt.id,
              requirementId: requirement.id,
            );
        if (!context.mounted || run != challengeRun.value) return;
        challenge.value = issued;
      } on Object catch (error) {
        debugPrint('Spoken challenge request failed: $error');
        if (!context.mounted || run != challengeRun.value) return;
        challengeFailed.value = true;
      }
    }

    useEffect(() {
      if (needsWord) unawaited(fetchWord());
      return null;
    }, const []);

    // Whatever is still on the phone when the flow closes was never sent.
    final latest = useRef<CapturedMedia?>(null)..value = media.value;
    final sent = useRef(false);
    useEffect(
      () => () {
        if (latest.value case final left? when !sent.value) {
          unawaited(deleteRecording(left.file));
        }
      },
      const [],
    );

    void close() => Navigator.of(context).pop();

    Future<void> captured(RawCapture raw) async {
      preparing.value = true;
      try {
        final prepared = await prepareCapture(
          raw,
          requirement: requirement,
          probe: ref.read(mediaDurationProbeProvider),
          spokenChallengeWord: challenge.value?.word,
        );
        if (!context.mounted) return;
        media.value = prepared;
      } on CaptureProblemException catch (error) {
        unawaited(deleteRecording(raw.file));
        if (context.mounted) captureProblem.value = error.problem;
      } finally {
        if (context.mounted) preparing.value = false;
      }
    }

    void retake() {
      if (media.value case final discarded?) {
        unawaited(deleteRecording(discarded.file));
      }
      media.value = null;
      sendProblem.value = null;
      captureProblem.value = null;
      captureRun.value++;
      // The server hands back the same word while it is live; a new one is
      // needed only once it has expired.
      if (challenge.value case final word?
          when !word.expiresAt.isAfter(clock.now())) {
        unawaited(fetchWord());
      }
    }

    Future<void> send() async {
      final current = media.value;
      if (current == null || sending.value) return;
      sending.value = true;
      sendProblem.value = null;
      try {
        final result = await ref
            .read(evidenceServiceProvider)
            .uploadMedia(
              attempt: attempt,
              requirement: requirement,
              media: current,
            );
        // The server holds the original now; the phone's copy goes.
        sent.value = true;
        unawaited(deleteRecording(current.file));
        if (context.mounted) Navigator.of(context).pop(result);
      } on MediaUploadException {
        sendProblem.value = const _UploadFailed();
      } on CaptureIntegrityException catch (error) {
        debugPrint('Capture integrity unavailable: $error');
        sendProblem.value = const _IntegrityFailed();
      } on Object catch (error) {
        debugPrint('Media proof was not accepted: $error');
        sendProblem.value = _Refused(userMessageFor(l10n, error));
      } finally {
        if (context.mounted) sending.value = false;
      }
    }

    final Widget page;
    if (needsWord && challenge.value == null) {
      page = _ChallengeGate(
        failed: challengeFailed.value,
        onRetry: () => unawaited(fetchWord()),
        onClose: close,
      );
    } else if (captureProblem.value case final problem?) {
      page = _NightPage(
        child: CaptureProblemPanel(
          title: switch (problem) {
            CaptureProblem.unsupportedFormat =>
              l10n.captureUnsupportedFormatTitle,
            CaptureProblem.tooLarge => l10n.captureTooLargeTitle,
          },
          message: switch (problem) {
            CaptureProblem.unsupportedFormat =>
              l10n.captureUnsupportedFormatBody,
            CaptureProblem.tooLarge => l10n.captureTooLargeBody,
          },
          action: CaptureProblemAction(
            key: VerilyTestKeys.captureReviewRetake,
            label: l10n.captureReviewRetake,
            onPressed: retake,
          ),
          secondaryAction: CaptureProblemAction(
            label: l10n.captureClose,
            onPressed: close,
          ),
        ),
      );
    } else if (media.value case final ready?) {
      page = CaptureReviewView(
        requirement: requirement,
        media: ready,
        sending: sending.value,
        retrying: sendProblem.value is _UploadFailed,
        onRetake: retake,
        onSend: () => unawaited(send()),
        problem: switch (sendProblem.value) {
          null => null,
          _UploadFailed() => CaptureProblemPanel.inline(
            title: l10n.captureSendFailedTitle,
            message: l10n.captureSendFailedBody,
          ),
          _IntegrityFailed() => CaptureProblemPanel.inline(
            title: l10n.captureIntegrityTitle,
            message: l10n.captureIntegrityBody,
          ),
          _Refused(:final message) => CaptureProblemPanel.inline(
            title: l10n.captureProblemTitle,
            message: message,
          ),
        },
      );
    } else if (preparing.value) {
      page = _NightPage(
        child: _NightWait(label: l10n.movementCaptureSaving),
      );
    } else {
      final word = challenge.value?.word;
      final key = ValueKey(captureRun.value);
      final movement = requirement.movementKind;
      page = switch (kind) {
        MediaEvidenceKind.photo => CameraCaptureView(
          key: key,
          requirement: requirement,
          mode: CameraCaptureMode.photo,
          onCaptured: (raw) => unawaited(captured(raw)),
          onClose: close,
        ),
        MediaEvidenceKind.audio => AudioCaptureView(
          key: key,
          requirement: requirement,
          spokenWord: word,
          onCaptured: (raw) => unawaited(captured(raw)),
          onClose: close,
        ),
        MediaEvidenceKind.video
            when movement != null &&
                ref.watch(movementTrackingSupportedProvider) =>
          MovementCaptureView(
            key: key,
            requirement: requirement,
            spokenWord: word,
            delay: movementDelay,
            onRecorded: (raw) => unawaited(captured(raw)),
            onClose: close,
          ),
        MediaEvidenceKind.video => CameraCaptureView(
          key: key,
          requirement: requirement,
          mode: CameraCaptureMode.video,
          spokenWord: word,
          onCaptured: (raw) => unawaited(captured(raw)),
          onClose: close,
        ),
      };
    }

    return PopScope(
      // Back from the review returns to the camera; nothing leaves while it
      // is sending.
      canPop: media.value == null && !sending.value,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !sending.value) retake();
      },
      child: page,
    );
  }
}

/// Waits for the server's word, or explains why it could not be fetched.
class _ChallengeGate extends StatelessWidget {
  const _ChallengeGate({
    required this.failed,
    required this.onRetry,
    required this.onClose,
  });

  final bool failed;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _NightPage(
      child: failed
          ? CaptureProblemPanel(
              title: l10n.captureChallengeFailedTitle,
              message: l10n.captureChallengeFailedBody,
              action: CaptureProblemAction(
                key: VerilyTestKeys.captureChallengeRetry,
                label: l10n.movementCaptureTryAgain,
                onPressed: onRetry,
              ),
              secondaryAction: CaptureProblemAction(
                key: VerilyTestKeys.captureClose,
                label: l10n.captureClose,
                onPressed: onClose,
              ),
            )
          : _NightWait(label: l10n.captureChallengeLoading),
    );
  }
}

class _NightPage extends StatelessWidget {
  const _NightPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: VerilyColors.movementScrim,
    body: SafeArea(child: child),
  );
}

/// A labelled wait on the night viewfinder.
class _NightWait extends StatelessWidget {
  const _NightWait({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WiredLoadingIndicator(
              size: 28,
              color: VerilyColors.movementHudInk,
              strokeWidth: 2.4,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: VerilyColors.movementHudInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
