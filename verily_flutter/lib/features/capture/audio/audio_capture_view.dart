import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredProgress, WiredTheme, WiredThemeScope;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/capture/capture_models.dart';
import 'package:verily_flutter/features/capture/capture_providers.dart';
import 'package:verily_flutter/features/capture/widgets/capture_problem_panel.dart';
import 'package:verily_flutter/features/capture/widgets/spoken_challenge_bubble.dart';
import 'package:verily_flutter/features/capture/widgets/viewfinder.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

enum _AudioPhase { idle, recording, denied, failed }

/// Records audio proof from the microphone, live.
///
/// There is no file picker: the only way in is the record button. When the
/// action asks for a spoken word, it is shown before and while recording.
class AudioCaptureView extends HookConsumerWidget {
  const AudioCaptureView({
    required this.requirement,
    required this.onCaptured,
    required this.onClose,
    this.spokenWord,
    super.key,
  });

  final ActionRequirementView requirement;
  final ValueChanged<RawCapture> onCaptured;
  final VoidCallback onClose;

  /// The server's word for this recording, or null when none is needed.
  final String? spokenWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final minimum = minimumRecording(requirement);
    final maximum = maximumRecording(requirement);
    final word = spokenWord;

    final recorder = useMemoized(
      () => ref.read(captureRecorderFactoryProvider)(),
    );
    useEffect(
      () =>
          () => unawaited(recorder.dispose()),
      [recorder],
    );

    final phase = useState(_AudioPhase.idle);
    final elapsed = useState(Duration.zero);
    final level = useState(0.0);
    final interrupted = useState(false);
    final limitReached = useState(false);
    final busy = useState(false);
    final recording = phase.value == _AudioPhase.recording;

    Future<void> start() async {
      if (busy.value) return;
      busy.value = true;
      interrupted.value = false;
      limitReached.value = false;
      elapsed.value = Duration.zero;
      level.value = 0;
      try {
        if (!await recorder.requestPermission()) {
          if (context.mounted) phase.value = _AudioPhase.denied;
          return;
        }
        await recorder.start();
        if (context.mounted) phase.value = _AudioPhase.recording;
      } on Object catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'capture',
            context: ErrorDescription('while starting an audio recording'),
          ),
        );
        if (context.mounted) phase.value = _AudioPhase.failed;
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    Future<void> stop({bool atLimit = false}) async {
      if (busy.value || !recording) return;
      busy.value = true;
      final measured = elapsed.value;
      try {
        final clip = await recorder.stop();
        if (!context.mounted) return;
        phase.value = _AudioPhase.idle;
        limitReached.value = atLimit;
        if (clip == null) {
          phase.value = _AudioPhase.failed;
          return;
        }
        onCaptured(
          RawCapture(
            file: clip,
            capturedAt: clock.now().toUtc(),
            measuredDuration: measured,
          ),
        );
      } on Object catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'capture',
            context: ErrorDescription('while stopping an audio recording'),
          ),
        );
        if (context.mounted) phase.value = _AudioPhase.failed;
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    useOnAppLifecycleStateChange((_, current) {
      if (current != AppLifecycleState.paused &&
          current != AppLifecycleState.hidden) {
        return;
      }
      if (phase.value != _AudioPhase.recording) return;
      // A recording that left the app is not one continuous capture.
      interrupted.value = true;
      phase.value = _AudioPhase.idle;
      unawaited(recorder.cancel());
    });

    useEffect(() {
      if (!recording) return null;
      final watch = clock.stopwatch()..start();
      final timer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => elapsed.value = watch.elapsed,
      );
      final levels = recorder.levels().listen((value) => level.value = value);
      return () {
        timer.cancel();
        unawaited(levels.cancel());
      };
    }, [recording]);

    final overLimit =
        recording && elapsed.value >= maximum - recordingLimitMargin;
    useEffect(() {
      if (overLimit) unawaited(stop(atLimit: true));
      return null;
    }, [overLimit]);

    final retry = CaptureProblemAction(
      label: l10n.movementCaptureTryAgain,
      onPressed: () => phase.value = _AudioPhase.idle,
    );
    final status = switch (phase.value) {
      _AudioPhase.recording => l10n.captureElapsed(
        clockLabel(elapsed.value),
        clockLabel(maximum),
      ),
      _ when interrupted.value => l10n.movementCaptureInterrupted,
      _ when limitReached.value => l10n.captureLimitReached(
        clockLabel(maximum),
      ),
      _ => l10n.captureAudioHint,
    };

    return Scaffold(
      backgroundColor: VerilyColors.movementScrim,
      body: SafeArea(
        child: switch (phase.value) {
          _AudioPhase.denied => CaptureProblemPanel(
            title: l10n.captureMicrophonePermissionTitle,
            message: l10n.captureMicrophonePermissionBody,
            action: CaptureProblemAction(
              key: VerilyTestKeys.captureOpenSettings,
              label: l10n.captureOpenSettings,
              onPressed: () => unawaited(ref.read(openAppSettingsProvider)()),
            ),
            secondaryAction: retry,
          ),
          _AudioPhase.failed => CaptureProblemPanel(
            title: l10n.movementCaptureRecordingFailed,
            message: l10n.movementCaptureRecordingFailedBody,
            action: retry,
            secondaryAction: CaptureProblemAction(
              label: l10n.captureClose,
              onPressed: onClose,
            ),
          ),
          _AudioPhase.idle || _AudioPhase.recording => Column(
            children: [
              ViewfinderTopBar(
                title: requirement.title,
                close: HudIconButton(
                  key: VerilyTestKeys.captureClose,
                  tooltip: l10n.captureClose,
                  icon: VerilyIcons.close,
                  onPressed: onClose,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: LiveBadge(recording: recording),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _Microphone(
                      recording: recording,
                      level: level.value,
                    ),
                  ),
                ),
              ),
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
                    if (recording)
                      ViewfinderButton(
                        key: VerilyTestKeys.captureRecordStop,
                        label: l10n.captureRecordStop,
                        icon: VerilyIcons.stop,
                        emphasis: false,
                        onPressed: busy.value ? null : () => unawaited(stop()),
                      )
                    else
                      ViewfinderButton(
                        key: VerilyTestKeys.captureRecordStart,
                        label: l10n.captureRecordStart,
                        icon: VerilyIcons.microphone,
                        onPressed: busy.value ? null : () => unawaited(start()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

/// A sketched microphone with the input level beneath it.
class _Microphone extends StatelessWidget {
  const _Microphone({required this.recording, required this.level});

  final bool recording;
  final double level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 132,
          height: 132,
          alignment: Alignment.center,
          decoration: VerilyRoughDecoration(
            color: recording
                ? VerilyColors.movementHudAccent
                : VerilyColors.movementScrim,
            outline: VerilyColors.movementHudInk,
            radius: 66,
            seed: 413,
          ),
          child: SkribbleIcon(
            data: VerilyIcons.microphone,
            size: 64,
            color: recording
                ? VerilyColors.movementOutline
                : VerilyColors.movementHudInk,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          recording ? l10n.captureAudioRecording : l10n.captureAudioTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: VerilyColors.movementHudInk,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Semantics(
            label: l10n.captureAudioLevelSemantics((level * 100).round()),
            excludeSemantics: true,
            child: WiredThemeScope(
              data: WiredTheme.of(context).copyWith(
                borderColor: VerilyColors.movementHudInk,
                markerColor: VerilyColors.movementHudAccent,
              ),
              child: WiredProgress(
                key: VerilyTestKeys.captureAudioLevel,
                value: recording ? level : 0,
                height: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
