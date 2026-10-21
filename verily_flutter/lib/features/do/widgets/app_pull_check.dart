import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredLoadingIndicator, WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/features/evidence/proof_reasons.dart';
import 'package:verily_flutter/features/apps/app_platform_messages.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Where a participant's "I did it" stands with a pull-verified App, as far
/// as the server's public reasons tell it.
enum AppPullPhase {
  /// Nothing asked yet.
  ready,

  /// Verily asked and the App has not decided yet (`app_checking`); it
  /// confirms on its own later, or Verily keeps asking.
  waiting,

  /// Verily could not reach the App and stopped trying for now
  /// (`app_unreachable`); the person may ask again.
  failed,

  /// The App confirmed it.
  accepted,

  /// The App said no (`app_not_confirmed`).
  rejected,

  /// The App never answered within a day (`app_no_answer`).
  unanswered;

  /// Whether the App is still deciding, so the page keeps checking.
  bool get isOpen => this == waiting;

  /// Whether the person can tap "I did it" (again).
  bool get canAsk => this == ready || this == failed;
}

/// The phase the server's answer to `requestAppVerification` describes.
AppPullPhase appPullPhaseOf(EvidenceSubmissionResult result) =>
    switch ((result.status, result.reasonCode)) {
      (EvidenceDecisionStatus.accepted, _) => AppPullPhase.accepted,
      (EvidenceDecisionStatus.rejected, ProofReason.appNoAnswer) =>
        AppPullPhase.unanswered,
      (EvidenceDecisionStatus.rejected, _) => AppPullPhase.rejected,
      (_, ProofReason.appUnreachable) => AppPullPhase.failed,
      _ => AppPullPhase.waiting,
    };

/// "I did it" for a proof the App checks when asked: an optional note for
/// the App (a username or an order number), the button, and where the check
/// stands.
///
/// The note is checked on the phone with the server's own rule, so a refusal
/// is explained before anything is sent.
class AppPullCheck extends HookWidget {
  const AppPullCheck({
    required this.requirement,
    required this.appName,
    required this.phase,
    required this.asking,
    required this.onAsk,
    super.key,
  });

  final ActionRequirementView requirement;
  final String appName;
  final AppPullPhase phase;

  /// Whether a request to the App is on its way.
  final bool asking;

  /// Asks the App, with the trimmed note or null.
  final ValueChanged<String?>? onAsk;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final reference = useTextEditingController();
    final invalid = useState(false);
    final key = requirement.requirementKey;

    void ask() {
      final String? note;
      try {
        note = normalizePullReference(reference.text);
      } on FormatException {
        invalid.value = true;
        return;
      }
      invalid.value = false;
      onAsk?.call(note);
    }

    if (!phase.canAsk) {
      return _PullStatus(
        key: VerilyTestKeys.actionPullStatus(key),
        phase: phase,
        appName: appName,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (phase == AppPullPhase.failed) ...[
          _PullStatus(
            key: VerilyTestKeys.actionPullStatus(key),
            phase: phase,
            appName: appName,
          ),
          const SizedBox(height: 12),
        ],
        // After an unanswered call, the status above already says what to
        // do; the introduction is for the first ask.
        if (phase == AppPullPhase.ready) ...[
          Text(
            l10n.actionPullIntro(appName),
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: VerilyTestKeys.actionPullReference(key),
          controller: reference,
          enabled: !asking && onAsk != null,
          maxLength: 120,
          // The helper says what fits; a counter would squeeze it.
          buildCounter: (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => null,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (invalid.value) invalid.value = false;
          },
          onSubmitted: (_) => ask(),
          decoration: InputDecoration(
            labelText: l10n.actionPullReferenceLabel,
            hintText: l10n.actionPullReferenceHint,
            helperText: l10n.actionPullReferenceHelp(appName),
            helperMaxLines: 3,
            errorText: invalid.value ? l10n.actionPullReferenceInvalid : null,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: 12),
        VerilyActionButton(
          key: VerilyTestKeys.actionPullAsk(key),
          label: phase == AppPullPhase.failed
              ? l10n.actionPullAskAgain
              : l10n.actionPullAsk,
          isLoading: asking,
          leading: const SkribbleIcon(data: VerilyIcons.hand),
          onPressed: onAsk == null ? null : ask,
        ),
      ],
    );
  }
}

/// Where the App's check stands, in words with an icon, never colour alone.
class _PullStatus extends StatelessWidget {
  const _PullStatus({
    required this.phase,
    required this.appName,
    super.key,
  });

  final AppPullPhase phase;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final (WiredSvgIconData icon, String title, String body) = switch (phase) {
      AppPullPhase.ready || AppPullPhase.waiting => (
        VerilyIcons.hourglass,
        l10n.actionPullWaitingTitle(appName),
        l10n.actionPullWaitingBody(appName),
      ),
      AppPullPhase.failed => (
        VerilyIcons.cloudOff,
        l10n.actionPullFailedTitle(appName),
        l10n.actionPullFailedBody,
      ),
      AppPullPhase.accepted => (
        VerilyIcons.circleCheck,
        l10n.actionAppConfirmed(appName),
        l10n.actionPullAcceptedBody,
      ),
      AppPullPhase.rejected => (
        VerilyIcons.close,
        l10n.actionPullRejectedTitle(appName),
        l10n.actionPullRejectedBody(appName),
      ),
      AppPullPhase.unanswered => (
        VerilyIcons.close,
        l10n.actionPullUnansweredTitle(appName),
        l10n.actionPullRejectedBody(appName),
      ),
    };
    final busy = phase.isOpen;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: VerilyRoughDecoration(
          color: palette.surface,
          outline: palette.quietPen,
          radius: VerilyRadius.control,
          strokeWidth: 2,
          seed: 311 + phase.index,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (busy)
              WiredLoadingIndicator(color: palette.ink)
            else
              SkribbleIcon(data: icon, size: 22, color: palette.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.mutedInk,
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
