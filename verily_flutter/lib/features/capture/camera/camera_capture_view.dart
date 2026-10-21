import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/capture/camera/capture_camera.dart';
import 'package:verily_flutter/features/capture/capture_models.dart';
import 'package:verily_flutter/features/capture/capture_providers.dart';
import 'package:verily_flutter/features/capture/widgets/capture_problem_panel.dart';
import 'package:verily_flutter/features/capture/widgets/spoken_challenge_bubble.dart';
import 'package:verily_flutter/features/capture/widgets/viewfinder.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// What the camera captures.
enum CameraCaptureMode { photo, video }

/// The live viewfinder for photo and video proof.
///
/// There is no gallery and no file picker: the only way in is the shutter
/// or the record button, at the moment the action happens. When the action
/// asks for a spoken word, it is shown before and while recording.
class CameraCaptureView extends HookConsumerWidget {
  const CameraCaptureView({
    required this.requirement,
    required this.mode,
    required this.onCaptured,
    required this.onClose,
    this.spokenWord,
    super.key,
  });

  final ActionRequirementView requirement;
  final CameraCaptureMode mode;
  final ValueChanged<RawCapture> onCaptured;
  final VoidCallback onClose;

  /// The server's word for this recording, or null when none is needed.
  final String? spokenWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final video = mode == CameraCaptureMode.video;
    final minimum = minimumRecording(requirement);
    final maximum = maximumRecording(requirement);

    final camera = useMemoized(
      () => ref.read(captureCameraFactoryProvider)(
        recordAudio: video,
        initialLens: CaptureLens.back,
      ),
    );
    useEffect(() {
      unawaited(camera.open());
      return camera.dispose;
    }, [camera]);
    useListenable(camera);
    final state = camera.state;
    final recording = state.phase == CaptureCameraPhase.recording;
    final ready = state.phase == CaptureCameraPhase.ready;

    final elapsed = useState(Duration.zero);
    final interrupted = useState(false);
    final limitReached = useState(false);
    final busy = useState(false);
    final backgrounded = useRef(false);

    Future<void> stop({bool atLimit = false}) async {
      if (busy.value) return;
      busy.value = true;
      final measured = elapsed.value;
      final clip = await camera.stopRecording();
      if (!context.mounted) return;
      busy.value = false;
      limitReached.value = atLimit;
      if (clip == null) return;
      onCaptured(
        RawCapture(
          file: clip,
          capturedAt: clock.now().toUtc(),
          measuredDuration: measured,
        ),
      );
    }

    Future<void> start() async {
      interrupted.value = false;
      limitReached.value = false;
      elapsed.value = Duration.zero;
      await camera.startRecording();
    }

    Future<void> shoot() async {
      if (busy.value) return;
      busy.value = true;
      final photo = await camera.takePhoto();
      if (!context.mounted) return;
      busy.value = false;
      if (photo == null) return;
      onCaptured(RawCapture(file: photo, capturedAt: clock.now().toUtc()));
    }

    useOnAppLifecycleStateChange((_, current) {
      switch (current) {
        case AppLifecycleState.hidden || AppLifecycleState.paused:
          if (backgrounded.value) return;
          backgrounded.value = true;
          // A recording that left the app is not one continuous capture.
          if (recording) interrupted.value = true;
          busy.value = false;
          unawaited(camera.close());
        case AppLifecycleState.resumed:
          if (!backgrounded.value) return;
          backgrounded.value = false;
          unawaited(camera.open());
        case AppLifecycleState.detached || AppLifecycleState.inactive:
          break;
      }
    });

    useEffect(() {
      if (!recording) return null;
      final watch = clock.stopwatch()..start();
      final timer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => elapsed.value = watch.elapsed,
      );
      return timer.cancel;
    }, [recording]);

    final overLimit =
        recording && elapsed.value >= maximum - recordingLimitMargin;
    useEffect(() {
      if (overLimit) unawaited(stop(atLimit: true));
      return null;
    }, [overLimit]);

    final status = switch (state.phase) {
      CaptureCameraPhase.opening => l10n.movementCaptureOpening,
      CaptureCameraPhase.recording => l10n.captureElapsed(
        clockLabel(elapsed.value),
        clockLabel(maximum),
      ),
      _ when interrupted.value => l10n.movementCaptureInterrupted,
      _ when limitReached.value => l10n.captureLimitReached(
        clockLabel(maximum),
      ),
      _ => requirement.instructions,
    };
    final word = spokenWord;

    final Widget button;
    if (!video) {
      button = ViewfinderButton(
        key: VerilyTestKeys.captureShutter,
        label: l10n.captureTakePhoto,
        icon: VerilyIcons.camera,
        onPressed: ready && !busy.value ? () => unawaited(shoot()) : null,
      );
    } else if (recording) {
      button = ViewfinderButton(
        key: VerilyTestKeys.captureRecordStop,
        label: l10n.captureRecordStop,
        icon: VerilyIcons.stop,
        emphasis: false,
        onPressed: busy.value ? null : () => unawaited(stop()),
      );
    } else {
      button = ViewfinderButton(
        key: VerilyTestKeys.captureRecordStart,
        label: l10n.captureRecordStart,
        icon: VerilyIcons.record,
        onPressed: ready ? () => unawaited(start()) : null,
      );
    }

    return Scaffold(
      backgroundColor: VerilyColors.movementScrim,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Viewfinder(
            preview: camera.buildPreview(),
            aspectRatio: state.previewAspectRatio,
          ),
          const ViewfinderScrims(),
          SafeArea(
            child: Column(
              children: [
                ViewfinderTopBar(
                  title: requirement.title,
                  close: HudIconButton(
                    key: VerilyTestKeys.captureClose,
                    tooltip: l10n.captureClose,
                    icon: VerilyIcons.close,
                    onPressed: onClose,
                  ),
                  trailing: state.canFlip
                      ? HudIconButton(
                          key: VerilyTestKeys.captureFlip,
                          tooltip: l10n.captureFlipCamera,
                          icon: VerilyIcons.cameraSwitch,
                          onPressed: ready
                              ? () => unawaited(camera.flip())
                              : null,
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: LiveBadge(recording: recording),
                  ),
                ),
                const Expanded(child: ViewfinderBrackets()),
                if (state.phase != CaptureCameraPhase.failed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (word != null) ...[
                          SpokenChallengeBubble(word: word, intro: !recording),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          status,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: VerilyColors.movementHudInk,
                          ),
                        ),
                        if (recording && elapsed.value < minimum) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.captureMinimumHint(minimum.inSeconds),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: VerilyColors.movementHudAccent,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        button,
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (state.phase == CaptureCameraPhase.failed)
            _CameraFailure(
              failure: state.failure,
              onRetry: () => unawaited(camera.open()),
              onClose: onClose,
            ),
        ],
      ),
    );
  }
}

class _CameraFailure extends ConsumerWidget {
  const _CameraFailure({
    required this.failure,
    required this.onRetry,
    required this.onClose,
  });

  final CaptureCameraFailure? failure;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final openSettings = CaptureProblemAction(
      key: VerilyTestKeys.captureOpenSettings,
      label: l10n.captureOpenSettings,
      onPressed: () => unawaited(ref.read(openAppSettingsProvider)()),
    );
    final retry = CaptureProblemAction(
      label: l10n.movementCaptureTryAgain,
      onPressed: onRetry,
    );
    final close = CaptureProblemAction(
      label: l10n.captureClose,
      onPressed: onClose,
    );
    return SafeArea(
      child: switch (failure) {
        CaptureCameraFailure.cameraPermissionDenied => CaptureProblemPanel(
          title: l10n.captureCameraPermissionTitle,
          message: l10n.captureCameraPermissionBody,
          action: openSettings,
          secondaryAction: retry,
        ),
        CaptureCameraFailure.microphonePermissionDenied => CaptureProblemPanel(
          title: l10n.captureMicrophonePermissionTitle,
          message: l10n.captureMicrophonePermissionBody,
          action: openSettings,
          secondaryAction: retry,
        ),
        CaptureCameraFailure.noCamera => CaptureProblemPanel(
          title: l10n.movementCaptureNoCamera,
          message: l10n.movementCaptureNoCameraBody,
          action: close,
        ),
        CaptureCameraFailure.recordingFailed => CaptureProblemPanel(
          title: l10n.movementCaptureRecordingFailed,
          message: l10n.movementCaptureRecordingFailedBody,
          action: retry,
          secondaryAction: close,
        ),
        CaptureCameraFailure.unavailable || null => CaptureProblemPanel(
          title: l10n.movementCaptureUnavailable,
          message: l10n.movementCaptureUnavailableBody,
          action: retry,
          secondaryAction: close,
        ),
      },
    );
  }
}
