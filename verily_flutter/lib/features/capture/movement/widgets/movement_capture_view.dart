import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/capture/capture_models.dart';
import 'package:verily_flutter/features/capture/capture_providers.dart';
import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';
import 'package:verily_flutter/features/capture/movement/movement_capture_controller.dart';
import 'package:verily_flutter/features/capture/movement/movement_copy.dart';
import 'package:verily_flutter/features/capture/movement/movement_tracking_providers.dart';
import 'package:verily_flutter/features/capture/movement/widgets/ball_fire_effects.dart';
import 'package:verily_flutter/features/capture/movement/widgets/movement_body_painter.dart';
import 'package:verily_flutter/features/capture/widgets/capture_problem_panel.dart';
import 'package:verily_flutter/features/capture/widgets/spoken_challenge_bubble.dart';
import 'package:verily_flutter/features/capture/widgets/viewfinder.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Waits between countdown steps; replaced in tests.
typedef MovementCaptureDelay = Future<void> Function(Duration duration);

/// Full-screen camera with a body outline and a count readable from across
/// the room.
///
/// The phone is usually propped up a few metres away, so the flow is
/// hands-free after one tap: a countdown to step back, live counting, and an
/// automatic stop once the target is reached. The count is advisory; the
/// server checks the recording.
class MovementCaptureView extends HookConsumerWidget {
  const MovementCaptureView({
    required this.requirement,
    required this.onRecorded,
    required this.onClose,
    this.spokenWord,
    this.delay,
    super.key,
  });

  final ActionRequirementView requirement;
  final ValueChanged<RawCapture> onRecorded;
  final VoidCallback onClose;

  /// The server's word for this recording, or null when none is needed.
  final String? spokenWord;

  /// Replaces real waiting in tests.
  final MovementCaptureDelay? delay;

  static const countdownSeconds = 5;

  /// How long the celebration shows before the recording stops.
  static const targetHold = Duration(milliseconds: 1500);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kind = requirement.movementKind!;
    final target = math.max(requirement.targetRepetitions ?? 1, 1);
    final minimum = minimumRecording(requirement);
    final maximum = maximumRecording(requirement);
    final word = spokenWord;

    final controller = useMemoized(
      () => ref.read(movementCaptureControllerFactoryProvider)(
        kind,
        recordAudio: word != null,
      ),
    );
    useEffect(() {
      unawaited(controller.open());
      return controller.dispose;
    }, [controller]);
    useListenable(controller);
    final state = controller.state;

    final countdown = useState<int?>(null);
    final elapsed = useState(Duration.zero);
    final interrupted = useState(false);
    final stopping = useRef(false);
    final backgrounded = useRef(false);
    final run = useRef(0);
    final recording = state.phase == MovementCapturePhase.recording;
    final counting =
        recording && state.liveCounting == MovementLiveCounting.active;
    final reached = counting && state.progress.count >= target;

    Future<void> finish() async {
      if (stopping.value) return;
      stopping.value = true;
      final measured = elapsed.value;
      final result = await controller.stopRecording();
      if (!context.mounted) return;
      stopping.value = false;
      if (result == null) return;
      onRecorded(
        RawCapture(
          file: result.file,
          capturedAt: clock.now().toUtc(),
          measuredDuration: measured,
          repetitions: result.repetitions,
          trackerVersion: result.trackerVersion,
        ),
      );
    }

    Future<void> begin() async {
      final current = ++run.value;
      interrupted.value = false;
      elapsed.value = Duration.zero;
      final wait = delay ?? Future<void>.delayed;
      for (var remaining = countdownSeconds; remaining >= 1; remaining--) {
        countdown.value = remaining;
        await wait(const Duration(seconds: 1));
        if (!context.mounted || run.value != current) return;
      }
      countdown.value = null;
      await controller.startRecording();
    }

    useOnAppLifecycleStateChange((_, current) {
      switch (current) {
        case AppLifecycleState.hidden || AppLifecycleState.paused:
          if (backgrounded.value) return;
          backgrounded.value = true;
          // Leaving mid-attempt discards it; a resumed set would not be one
          // continuous recording.
          if (recording || countdown.value != null) interrupted.value = true;
          run.value++;
          countdown.value = null;
          stopping.value = false;
          unawaited(controller.close());
        case AppLifecycleState.resumed:
          if (!backgrounded.value) return;
          backgrounded.value = false;
          unawaited(controller.open());
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
      if (overLimit) unawaited(finish());
      return null;
    }, [overLimit]);

    useEffect(() {
      if (!reached) return null;
      final remainingMinimum = minimum - elapsed.value;
      final timer = Timer(
        remainingMinimum > targetHold ? remainingMinimum : targetHold,
        () => unawaited(finish()),
      );
      return timer.cancel;
    }, [reached]);

    final canStop = recording && elapsed.value >= minimum && !stopping.value;

    return Scaffold(
      backgroundColor: VerilyColors.movementScrim,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Viewfinder(
            preview: controller.buildPreview(),
            aspectRatio: state.aspectRatio,
            overlay: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: MovementBodyPainter(
                      pose: state.pose,
                      mirrored: state.mirrored,
                      atDepth: state.progress.atDepth,
                    ),
                  ),
                ),
                if (kind.isBallSkill) _BallFireLayer(state: state),
              ],
            ),
          ),
          const ViewfinderScrims(),
          SafeArea(
            child: Column(
              children: [
                ViewfinderTopBar(
                  title: movementName(l10n, kind),
                  close: HudIconButton(
                    key: VerilyTestKeys.movementCaptureClose,
                    tooltip: l10n.movementCaptureClose,
                    icon: VerilyIcons.close,
                    onPressed: onClose,
                  ),
                  trailing:
                      state.canFlip &&
                          state.phase == MovementCapturePhase.ready &&
                          countdown.value == null
                      ? HudIconButton(
                          key: VerilyTestKeys.movementCaptureFlip,
                          tooltip: l10n.movementCaptureFlip,
                          icon: VerilyIcons.cameraSwitch,
                          onPressed: () => unawaited(controller.flipCamera()),
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: LiveBadge(recording: recording),
                  ),
                ),
                if (recording)
                  _CountHud(
                    count: state.progress.count,
                    best: state.progress.best,
                    target: target,
                    counting: counting,
                    reached: reached,
                  )
                else
                  _TargetHeader(kind: kind, target: target),
                const Expanded(child: ViewfinderBrackets()),
                if (state.phase != MovementCapturePhase.failed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _BottomPanel(
                      kind: kind,
                      state: state,
                      spokenWord: word,
                      countingDown: countdown.value != null,
                      interrupted: interrupted.value,
                      elapsed: elapsed.value,
                      maximum: maximum,
                      canStop: canStop,
                      onStart: () => unawaited(begin()),
                      onStop: () => unawaited(finish()),
                    ),
                  ),
              ],
            ),
          ),
          if (counting && state.progress.tracking && !kind.isBallSkill)
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(
                child: _DepthMeter(
                  key: VerilyTestKeys.movementCaptureDepthMeter,
                  progress: state.progress,
                ),
              ),
            ),
          if (countdown.value case final seconds?) _Countdown(seconds: seconds),
          if (state.phase == MovementCapturePhase.failed)
            SafeArea(
              child: _FailurePanel(
                failure: state.failure,
                onRetry: () => unawaited(controller.open()),
                onClose: onClose,
              ),
            ),
        ],
      ),
    );
  }
}

/// Sets the ball alight and powers up the limb that touched it.
///
/// The simulation advances every display frame, between the 10–20
/// detections a second, so the flames keep moving.
class _BallFireLayer extends HookWidget {
  const _BallFireLayer({required this.state});

  final MovementCaptureState state;

  @override
  Widget build(BuildContext context) {
    final effects = useMemoized(BallFireEffects.new);
    useEffect(() => effects.dispose, [effects]);
    final vsync = useSingleTickerProvider();
    useEffect(() {
      Duration? last;
      final ticker = vsync.createTicker((elapsed) {
        final previous = last;
        last = elapsed;
        if (previous != null) {
          effects.advance((elapsed - previous).inMicroseconds / 1e6);
        }
      })..start();
      return ticker.dispose;
    }, [effects]);
    useEffect(() {
      effects.observe(
        ball: state.ball,
        pose: state.pose,
        touch: state.progress.touch,
        running: state.progress.count > 0,
      );
      return null;
    }, [state]);
    return RepaintBoundary(
      child: CustomPaint(
        painter: BallFirePainter(
          effects: effects,
          mirrored: state.mirrored,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
        ),
      ),
    );
  }
}

/// Before recording: what the participant is about to do.
class _TargetHeader extends StatelessWidget {
  const _TargetHeader({required this.kind, required this.target});

  final ActionMovementKind kind;
  final int target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            movementTarget(l10n, kind, target),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: VerilyColors.movementHudInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movementGuide(l10n, kind),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: VerilyColors.movementHudInk.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// The live count, sized to read from a few metres away.
class _CountHud extends StatelessWidget {
  const _CountHud({
    required this.count,
    required this.best,
    required this.target,
    required this.counting,
    required this.reached,
  });

  final int count;

  /// The longest run so far; shown when a ball skill run has dropped.
  final int best;
  final int target;
  final bool counting;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    if (!counting) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Reaching the target is said in words and a bigger count, not a colour.
    const color = VerilyColors.movementHudInk;
    final shadow = [
      Shadow(
        color: VerilyColors.movementScrim.withValues(alpha: 0.7),
        blurRadius: 18,
      ),
    ];
    return Semantics(
      liveRegion: true,
      label: l10n.movementCaptureCountSemantics(count, target),
      child: ExcludeSemantics(
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(count),
              tween: Tween(begin: reduceMotion ? 1 : 1.35, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                l10n.movementCaptureCount(count),
                key: VerilyTestKeys.movementCaptureCount,
                textScaler: TextScaler.noScaling,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: color,
                  fontSize: 112,
                  height: 1,
                  shadows: shadow,
                ),
              ),
            ),
            Text(
              reached
                  ? l10n.movementCaptureTargetReached
                  : l10n.movementCaptureRemaining(target - count, target),
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                shadows: shadow,
              ),
            ),
            if (best > count && !reached)
              Text(
                l10n.movementCaptureBest(best),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: VerilyColors.movementHudMuted,
                  shadows: shadow,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.kind,
    required this.state,
    required this.spokenWord,
    required this.countingDown,
    required this.interrupted,
    required this.elapsed,
    required this.maximum,
    required this.canStop,
    required this.onStart,
    required this.onStop,
  });

  final ActionMovementKind kind;
  final MovementCaptureState state;
  final String? spokenWord;
  final bool countingDown;
  final bool interrupted;
  final Duration elapsed;
  final Duration maximum;
  final bool canStop;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final recording = state.phase == MovementCapturePhase.recording;
    final live = state.liveCounting == MovementLiveCounting.active;
    final status = switch (state.phase) {
      MovementCapturePhase.opening => l10n.movementCaptureOpening,
      MovementCapturePhase.saving => l10n.movementCaptureSaving,
      MovementCapturePhase.recording => l10n.movementCaptureElapsed(
        clockLabel(elapsed),
        clockLabel(maximum),
      ),
      _ when interrupted => l10n.movementCaptureInterrupted,
      _ => switch (state.liveCounting) {
        MovementLiveCounting.loading => l10n.movementCaptureCoachLoading,
        MovementLiveCounting.active => l10n.movementCaptureAdvisory,
        MovementLiveCounting.unavailable =>
          l10n.movementCaptureCoachUnavailable,
      },
    };
    final showCue =
        live &&
        !countingDown &&
        (state.phase == MovementCapturePhase.ready || recording);
    final word = spokenWord;
    final button = recording
        ? ViewfinderButton(
            key: VerilyTestKeys.movementCaptureStop,
            label: canStop
                ? l10n.movementCaptureStop
                : l10n.movementCaptureKeepGoing,
            icon: VerilyIcons.stop,
            onPressed: canStop ? onStop : null,
          )
        : ViewfinderButton(
            key: VerilyTestKeys.movementCaptureStart,
            label: l10n.movementCaptureStart,
            icon: VerilyIcons.record,
            onPressed:
                state.phase == MovementCapturePhase.ready && !countingDown
                ? onStart
                : null,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (word != null) ...[
          SpokenChallengeBubble(word: word, intro: !recording),
          const SizedBox(height: 12),
        ],
        if (showCue) ...[
          _CueBanner(
            text: movementCue(l10n, kind, state.progress.cue),
            highlighted: state.progress.atDepth,
          ),
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
        const SizedBox(height: 14),
        button,
      ],
    );
  }
}

class _CueBanner extends StatelessWidget {
  const _CueBanner({required this.text, required this.highlighted});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: highlighted
              ? VerilyColors.movementHudInk
              : VerilyColors.movementScrim.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(VerilyRadius.chip),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: highlighted
                ? VerilyColors.movementOutline
                : VerilyColors.movementHudInk,
          ),
        ),
      ),
    );
  }
}

/// A tall gauge of how far into the current repetition the body is, with a
/// notch where it starts to count.
class _DepthMeter extends StatelessWidget {
  const _DepthMeter({required this.progress, super.key});

  final MovementProgress progress;

  static const _height = 240.0;

  @override
  Widget build(BuildContext context) {
    final fill = progress.atDepth
        ? VerilyColors.movementHudInk
        : VerilyColors.movementHudMuted;
    return Semantics(
      value: context.l10n.movementCaptureDepthSemantics(
        (progress.depth * 100).round(),
      ),
      child: Container(
        width: 22,
        height: _height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: VerilyColors.movementScrim.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(VerilyRadius.chip),
          border: Border.all(color: VerilyColors.movementHudInk, width: 2),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            FractionallySizedBox(
              heightFactor: progress.depth.clamp(0.04, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(VerilyRadius.chip),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: (_height - 10) * RepetitionCounter.extendedThreshold,
              child: Container(height: 3, color: VerilyColors.movementHudInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ColoredBox(
      color: VerilyColors.movementScrim.withValues(alpha: 0.45),
      child: Center(
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.movementCaptureCountdown(seconds),
                key: VerilyTestKeys.movementCaptureCountdown,
                textScaler: TextScaler.noScaling,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: VerilyColors.movementHudInk,
                  fontSize: 160,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.movementCaptureStepBack,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: VerilyColors.movementHudInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailurePanel extends ConsumerWidget {
  const _FailurePanel({
    required this.failure,
    required this.onRetry,
    required this.onClose,
  });

  final MovementCaptureFailure? failure;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final retry = CaptureProblemAction(
      key: VerilyTestKeys.movementCaptureRetry,
      label: l10n.movementCaptureTryAgain,
      onPressed: onRetry,
    );
    final openSettings = CaptureProblemAction(
      key: VerilyTestKeys.captureOpenSettings,
      label: l10n.captureOpenSettings,
      onPressed: () => unawaited(ref.read(openAppSettingsProvider)()),
    );
    final close = CaptureProblemAction(
      label: l10n.captureClose,
      onPressed: onClose,
    );
    return switch (failure) {
      MovementCaptureFailure.permissionDenied => CaptureProblemPanel(
        title: l10n.captureCameraPermissionTitle,
        message: l10n.captureCameraPermissionBody,
        action: openSettings,
        secondaryAction: retry,
      ),
      MovementCaptureFailure.microphonePermissionDenied => CaptureProblemPanel(
        title: l10n.captureMicrophonePermissionTitle,
        message: l10n.captureMicrophonePermissionBody,
        action: openSettings,
        secondaryAction: retry,
      ),
      MovementCaptureFailure.noCamera => CaptureProblemPanel(
        title: l10n.movementCaptureNoCamera,
        message: l10n.movementCaptureNoCameraBody,
        action: close,
      ),
      MovementCaptureFailure.recordingFailed => CaptureProblemPanel(
        title: l10n.movementCaptureRecordingFailed,
        message: l10n.movementCaptureRecordingFailedBody,
        action: retry,
        secondaryAction: close,
      ),
      MovementCaptureFailure.cameraUnavailable || null => CaptureProblemPanel(
        title: l10n.movementCaptureUnavailable,
        message: l10n.movementCaptureUnavailableBody,
        action: retry,
        secondaryAction: close,
      ),
    };
  }
}
