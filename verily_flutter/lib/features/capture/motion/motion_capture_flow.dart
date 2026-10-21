import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredCircularProgress, WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_fitted_text.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/capture/capture_providers.dart';
import 'package:verily_flutter/features/capture/widgets/capture_problem_panel.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/motion_capture_service.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Waits between countdown steps; replaced in tests.
typedef MotionCaptureDelay = Future<void> Function(Duration duration);

/// Measures a phone movement, then sends the sensor trace.
///
/// The phone's own reading only guides the person: the server recomputes the
/// analysis from the trace. Pops with the server's result once the trace is
/// sent, or null when the person closes.
class MotionCaptureFlow extends HookConsumerWidget {
  const MotionCaptureFlow({
    required this.attempt,
    required this.requirement,
    this.delay,
    super.key,
  });

  final ActionAttemptView attempt;
  final ActionRequirementView requirement;

  /// Replaces real waiting in tests.
  final MotionCaptureDelay? delay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final stage = useState(_MotionStage.ready);
    final countdown = useState(3);
    final progress = useState(0.0);
    final result = useState<CapturedMotion?>(null);
    final failure = useState<MotionCaptureFailure?>(null);
    final sendProblem = useState<(String, String)?>(null);
    final cancellation = useRef<MotionCaptureCancellation?>(null);
    final run = useRef(0);

    useEffect(() {
      return () {
        run.value += 1;
        cancellation.value?.cancel();
      };
    }, const []);

    Future<void> begin() async {
      final currentRun = ++run.value;
      cancellation.value?.cancel();
      cancellation.value = MotionCaptureCancellation();
      result.value = null;
      failure.value = null;
      sendProblem.value = null;
      progress.value = 0;
      stage.value = _MotionStage.countdown;
      final wait = delay ?? Future<void>.delayed;
      for (var remaining = 3; remaining >= 1; remaining -= 1) {
        countdown.value = remaining;
        await wait(const Duration(seconds: 1));
        if (!context.mounted || run.value != currentRun) return;
      }
      stage.value = _MotionStage.capturing;
      try {
        final captured = await ref.read(motionCaptureCallbackProvider)(
          requirement: requirement,
          cancellation: cancellation.value,
          onProgress: (value) {
            if (context.mounted && run.value == currentRun) {
              progress.value = value;
            }
          },
        );
        if (!context.mounted || run.value != currentRun) return;
        result.value = captured;
        stage.value = captured.analysis.accepted
            ? _MotionStage.matched
            : _MotionStage.notMatched;
      } on MotionCaptureException catch (error) {
        if (!context.mounted || run.value != currentRun) return;
        if (error.failure == MotionCaptureFailure.cancelled) return;
        failure.value = error.failure;
        stage.value = _MotionStage.failed;
      } on Object catch (error) {
        debugPrint('Motion capture failed: $error');
        if (!context.mounted || run.value != currentRun) return;
        failure.value = MotionCaptureFailure.interrupted;
        stage.value = _MotionStage.failed;
      }
    }

    Future<void> send() async {
      final motion = result.value;
      if (motion == null) return;
      stage.value = _MotionStage.sending;
      sendProblem.value = null;
      try {
        final submitted = await ref
            .read(evidenceServiceProvider)
            .submitMotion(
              attempt: attempt,
              requirement: requirement,
              motion: motion,
            );
        if (context.mounted) Navigator.of(context).pop(submitted);
      } on CaptureIntegrityException catch (error) {
        debugPrint('Capture integrity unavailable: $error');
        if (!context.mounted) return;
        sendProblem.value = (
          l10n.captureIntegrityTitle,
          l10n.captureIntegrityBody,
        );
        stage.value = _MotionStage.matched;
      } on Object catch (error) {
        debugPrint('Motion proof was not accepted: $error');
        if (!context.mounted) return;
        sendProblem.value = switch (userMessageFor(l10n, error)) {
          final message when message != l10n.errorGeneric => (
            l10n.captureProblemTitle,
            message,
          ),
          _ => (l10n.captureSendFailedTitle, l10n.captureSendFailedBody),
        };
        stage.value = _MotionStage.matched;
      }
    }

    void cancel() {
      run.value += 1;
      cancellation.value?.cancel();
      Navigator.of(context).pop();
    }

    final type = requirement.motionType;
    final status = _statusCopy(
      l10n,
      stage.value,
      countdown: countdown.value,
      progress: progress.value,
      result: result.value,
      failure: failure.value,
    );
    final primaryAction = switch (stage.value) {
      _MotionStage.ready => VerilyActionButton(
        key: VerilyTestKeys.captureMotionBegin,
        label: l10n.captureMotionBegin,
        onPressed: begin,
        leading: const SkribbleIcon(data: VerilyIcons.play),
      ),
      _MotionStage.notMatched || _MotionStage.failed => VerilyActionButton(
        key: VerilyTestKeys.captureMotionRetry,
        label: l10n.captureMotionRetry,
        onPressed: begin,
        leading: const SkribbleIcon(data: VerilyIcons.replay),
      ),
      _MotionStage.matched => VerilyActionButton(
        key: VerilyTestKeys.captureMotionUse,
        label: sendProblem.value == null
            ? l10n.captureMotionUseProof
            : l10n.captureSendAgain,
        onPressed: () => unawaited(send()),
        leading: const SkribbleIcon(data: VerilyIcons.check),
      ),
      // The action keeps its place and outline while the phone is measured,
      // so nothing under the person's thumb moves mid-capture.
      _MotionStage.countdown || _MotionStage.capturing => VerilyActionButton(
        label: l10n.captureMotionRecording,
        onPressed: null,
        isLoading: true,
      ),
      _MotionStage.sending => VerilyActionButton(
        key: VerilyTestKeys.captureMotionUse,
        label: l10n.captureMotionSending,
        onPressed: null,
        isLoading: true,
      ),
    };

    return PopScope(
      canPop: stage.value != _MotionStage.sending,
      child: Scaffold(
        backgroundColor: palette.canvas,
        appBar: AppBar(
          backgroundColor: palette.canvas,
          leading: IconButton(
            key: VerilyTestKeys.captureMotionCancel,
            tooltip: l10n.captureClose,
            onPressed: stage.value == _MotionStage.sending ? null : cancel,
            icon: const SkribbleIcon(data: VerilyIcons.close),
          ),
          title: VerilyFittedText(l10n.captureMotionTitle),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 40).clamp(
                      0,
                      double.infinity,
                    ),
                    maxWidth: 620,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        requirement.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        requirement.instructions,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.mutedInk,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _MotionTargetCard(requirement: requirement),
                      if (type == ActionMotionType.phoneToss) ...[
                        const SizedBox(height: 12),
                        const _GentleTossWarning(),
                      ],
                      const SizedBox(height: 26),
                      _MotionMeter(
                        stage: stage.value,
                        countdown: countdown.value,
                        progress: progress.value,
                        icon: _motionIcon(type),
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          status.$1,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        status.$2,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.mutedInk,
                          height: 1.4,
                        ),
                      ),
                      if (sendProblem.value case (
                        final title,
                        final message,
                      )) ...[
                        const SizedBox(height: 16),
                        CaptureProblemPanel.inline(
                          title: title,
                          message: message,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SkribbleIcon(
                            data: VerilyIcons.lock,
                            size: 16,
                            color: palette.mutedInk,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l10n.captureMotionPrivacy,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.mutedInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: primaryAction,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MotionTargetCard extends StatelessWidget {
  const _MotionTargetCard({required this.requirement});

  final ActionRequirementView requirement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final target = switch (requirement.motionType) {
      ActionMotionType.phoneToss => l10n.captureMotionTargetToss,
      ActionMotionType.rotation => l10n.captureMotionTargetRotation(
        requirement.targetRepetitions ?? 1,
        _axisLabel(l10n, requirement.motionAxis),
      ),
      ActionMotionType.shake => l10n.captureMotionTargetShake(
        requirement.targetRepetitions ?? 1,
      ),
      ActionMotionType.stillness => l10n.captureMotionTargetStillness(
        motionCaptureDuration(requirement).inSeconds,
      ),
      null => l10n.captureMotionTargetUnavailable,
    };
    // The requirement is the thing the capture is checked against, so it sits
    // on quiet paper rather than a bright field.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.quietPen,
        seed: 71,
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 44,
            child: Center(
              child: SkribbleIcon(
                data: VerilyIcons.rotatePhone,
                size: 28,
                color: palette.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.captureMotionTargetLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  target,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GentleTossWarning extends StatelessWidget {
  const _GentleTossWarning();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: VerilyTestKeys.captureMotionSafetyWarning,
      padding: const EdgeInsets.all(16),
      // A safety warning carries its own wording; the error pen marks it as
      // one without relying on the fill alone.
      decoration: VerilyRoughDecoration(
        color: colors.errorContainer,
        outline: colors.error,
        seed: 73,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkribbleIcon(data: VerilyIcons.hand, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.captureMotionTossSafetyTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.captureMotionTossSafetyBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MotionMeter extends StatelessWidget {
  const _MotionMeter({
    required this.stage,
    required this.countdown,
    required this.progress,
    required this.icon,
  });

  final _MotionStage stage;
  final int countdown;
  final double progress;
  final WiredSvgIconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final meterValue = switch (stage) {
      _MotionStage.ready => 0.0,
      _MotionStage.countdown => (4 - countdown) / 3,
      _MotionStage.capturing => progress,
      _MotionStage.matched || _MotionStage.sending => 1.0,
      _MotionStage.notMatched || _MotionStage.failed => 0.0,
    };
    final center = switch (stage) {
      _MotionStage.countdown => Text(
        context.l10n.captureMotionCountdownNumber(countdown),
        style: theme.textTheme.displayMedium?.copyWith(color: palette.ink),
      ),
      _MotionStage.matched || _MotionStage.sending => SkribbleIcon(
        data: VerilyIcons.check,
        size: 62,
        color: palette.ink,
      ),
      _MotionStage.failed || _MotionStage.notMatched => SkribbleIcon(
        data: VerilyIcons.replay,
        size: 58,
        color: palette.ink,
      ),
      _ => SkribbleIcon(data: icon, size: 62, color: palette.ink),
    };
    return Center(
      child: Semantics(
        value: context.l10n.captureMotionProgress((meterValue * 100).round()),
        child: SizedBox.square(
          dimension: 176,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Inked like every other line: progress reads from the heavy
              // stroke over the thin ring, not from a colour.
              WiredCircularProgress(
                value: meterValue,
                size: 176,
                strokeWidth: 9,
              ),
              Container(
                width: 124,
                height: 124,
                alignment: Alignment.center,
                decoration: VerilyRoughDecoration(
                  color: palette.surface,
                  outline: palette.quietPen,
                  radius: 62,
                  seed: 79,
                ),
                child: center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MotionStage {
  ready,
  countdown,
  capturing,
  matched,
  notMatched,
  failed,
  sending,
}

(String, String) _statusCopy(
  AppLocalizations l10n,
  _MotionStage stage, {
  required int countdown,
  required double progress,
  required CapturedMotion? result,
  required MotionCaptureFailure? failure,
}) {
  return switch (stage) {
    _MotionStage.ready => (
      l10n.captureMotionReady,
      l10n.captureMotionReadyBody,
    ),
    _MotionStage.countdown => (
      l10n.captureMotionCountdown(countdown),
      l10n.captureMotionCountdownBody,
    ),
    _MotionStage.capturing => (
      l10n.captureMotionRecording,
      l10n.captureMotionProgress((progress * 100).round()),
    ),
    _MotionStage.matched || _MotionStage.sending => (
      l10n.captureMotionMatched,
      l10n.captureMotionMatchedBody(result?.analysis.repetitionCount ?? 0),
    ),
    _MotionStage.notMatched => (
      l10n.captureMotionNotMatched,
      _analysisFailureCopy(l10n, result?.analysis.reasonCode),
    ),
    _MotionStage.failed => switch (failure) {
      MotionCaptureFailure.unavailable => (
        l10n.captureMotionNoSensor,
        l10n.captureMotionNoSensorBody,
      ),
      MotionCaptureFailure.invalidRule => (
        l10n.captureMotionUnavailable,
        l10n.captureMotionUnavailableBody,
      ),
      MotionCaptureFailure.cancelled ||
      MotionCaptureFailure.interrupted ||
      null => (
        l10n.captureMotionInterrupted,
        l10n.captureMotionInterruptedBody,
      ),
    },
  };
}

String _analysisFailureCopy(AppLocalizations l10n, String? reasonCode) {
  return switch (reasonCode) {
    'motion_rotation_too_fast' => l10n.captureMotionFailureTooFast,
    'motion_rotation_wrong_axis' => l10n.captureMotionFailureWrongAxis,
    'motion_rotation_too_slow' => l10n.captureMotionFailureTooSlow,
    'motion_rotation_count_not_met' => l10n.captureMotionFailureCount,
    'motion_toss_impact_too_high' => l10n.captureMotionFailureImpact,
    'motion_toss_air_time_not_met' => l10n.captureMotionFailureAirTime,
    'motion_toss_impulses_not_detected' => l10n.captureMotionFailureToss,
    'motion_shake_force_too_high' => l10n.captureMotionFailureImpact,
    'motion_shake_count_not_met' => l10n.captureMotionFailureCount,
    'motion_not_steady' => l10n.captureMotionFailureStillness,
    'motion_duration_out_of_range' => l10n.captureMotionFailureDuration,
    _ => l10n.captureMotionFailureGeneric,
  };
}

String _axisLabel(AppLocalizations l10n, ActionMotionAxis? axis) {
  return switch (axis) {
    ActionMotionAxis.yaw => l10n.captureMotionAxisYaw,
    ActionMotionAxis.pitch => l10n.captureMotionAxisPitch,
    ActionMotionAxis.roll => l10n.captureMotionAxisRoll,
    ActionMotionAxis.any || null => l10n.captureMotionAxisAny,
  };
}

WiredSvgIconData _motionIcon(ActionMotionType? type) {
  return switch (type) {
    ActionMotionType.phoneToss => VerilyIcons.toss,
    ActionMotionType.rotation => VerilyIcons.spin,
    ActionMotionType.shake => VerilyIcons.vibrate,
    ActionMotionType.stillness => VerilyIcons.tap,
    null => VerilyIcons.rotatePhone,
  };
}
