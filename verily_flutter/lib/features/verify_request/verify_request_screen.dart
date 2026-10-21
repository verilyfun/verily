import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/external_url_launcher.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/do/do_providers.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/verify_request/verification_request_repository.dart';
import 'package:verily_flutter/features/verify_request/verify_request_flow.dart';
import 'package:verily_flutter/features/verify_request/widgets/deep_link_page.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Answers a verification request another App opened Verily with.
///
/// The page shows who is asking, for what, and exactly what they will get,
/// before anything is captured. Accepting runs the same live capture as an
/// action page; declining or finishing hands the person back to the App.
class VerifyRequestScreen extends HookConsumerWidget {
  const VerifyRequestScreen({required this.requestId, super.key});

  /// The id from the link, unchecked.
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final flow = useMemoized(
      () => VerifyRequestFlow(
        requestId: requestId,
        requests: ref.read(verificationRequestRepositoryProvider),
        actions: ref.read(actionRepositoryProvider),
        evidence: ref.read(evidenceServiceProvider),
        location: ref.read(locationServiceProvider),
        openExternal: ref.read(externalUrlLauncherProvider),
      ),
      [requestId],
    );
    useEffect(() {
      unawaited(flow.load());
      return flow.dispose;
    }, [flow]);
    useListenable(flow);
    final state = flow.state;

    final (title, subtitle) = switch (state) {
      VerifyRequestConsent(:final view) => (
        l10n.verifyRequestHeaderTitle,
        _from(l10n, view),
      ),
      VerifyRequestProof(:final view) => (
        l10n.verifyRequestProofTitle(view.appName),
        null,
      ),
      _ => (l10n.verifyRequestHeaderTitle, null),
    };

    return DeepLinkPage(
      title: title,
      subtitle: subtitle,
      closeKey: VerilyTestKeys.verifyRequestClose,
      children: switch (state) {
        VerifyRequestLoading() => [
          VerilyLoadingPanel(label: l10n.verifyRequestLoading),
        ],
        VerifyRequestUnavailable() => [
          _UnavailablePanel(state: state, onRetry: flow.load),
        ],
        VerifyRequestConsent() => _consent(context, flow, state),
        VerifyRequestProof() => _proof(context, ref, flow, state),
        VerifyRequestReturning() => [
          ReturningPanel(
            title: switch (state.reason) {
              ReturnReason.finished => l10n.verifyRequestReturningTitle(
                state.appName,
              ),
              ReturnReason.declined => l10n.verifyRequestDeclinedTitle,
            },
            message: switch ((state.reason, state.outcome)) {
              (ReturnReason.declined, _) => l10n.verifyRequestDeclinedBody(
                state.appName,
              ),
              (_, ProofOutcome.passed) => l10n.verifyRequestReturningPassed,
              (_, ProofOutcome.failed) => l10n.verifyRequestReturningFailed(
                state.appName,
              ),
              (_, ProofOutcome.checking || null) =>
                l10n.verifyRequestReturningChecking(state.appName),
            },
            appName: state.appName,
            opened: state.opened,
            onOpenApp: () => unawaited(flow.openApp()),
          ),
        ],
      },
    );
  }

  List<Widget> _consent(
    BuildContext context,
    VerifyRequestFlow flow,
    VerifyRequestConsent state,
  ) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final view = state.view;
    final kind = view.kind.name;
    final isMedia = view.kind != VerificationRequestKind.location;
    final instructions = view.instructions?.trim();
    final expiresAt = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(view.expiresAt.toLocal()));
    final busy = state.answering != null;

    return [
      Semantics(
        key: VerilyTestKeys.verifyRequestConsent,
        header: true,
        child: Text(
          l10n.verifyRequestAsks(view.appName, kind),
          style: theme.textTheme.headlineSmall?.copyWith(color: palette.ink),
        ),
      ),
      if (instructions != null && instructions.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          l10n.verifyRequestTheirWords,
          style: theme.textTheme.labelLarge?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: 6),
        // The App's own words, quoted so they never read as Verily's.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: VerilyRoughDecoration(
            color: palette.highlight,
            outline: palette.quietPen,
            radius: VerilyRadius.control,
            strokeWidth: 2,
            seed: 181,
          ),
          child: Text(
            l10n.verifyRequestInstructions(instructions),
            style: theme.textTheme.bodyLarge?.copyWith(color: palette.ink),
          ),
        ),
      ],
      const SizedBox(height: 16),
      DeepLinkSection(
        heading: l10n.verifyRequestHowHeading,
        seed: 191,
        children: [
          DeepLinkLine(
            icon: _kindIcon(view.kind),
            text: l10n.verifyRequestHowCapture(kind),
          ),
          if (view.spokenChallenge)
            DeepLinkLine(
              icon: VerilyIcons.chat,
              text: l10n.verifyRequestHowWord,
            ),
          if (isMedia && view.checksPlace)
            DeepLinkLine(
              icon: VerilyIcons.mapPin,
              text: l10n.verifyRequestHowPlace,
            ),
          if (isMedia)
            DeepLinkLine(
              icon: VerilyIcons.shieldCheck,
              text: view.check == VerificationRequestCheck.content
                  ? l10n.verifyRequestHowContent
                  : l10n.verifyRequestHowCaptureOnly,
            ),
        ],
      ),
      const SizedBox(height: 12),
      DeepLinkSection(
        heading: l10n.verifyRequestSharedHeading(view.appName),
        seed: 193,
        children: [
          DeepLinkLine(
            icon: VerilyIcons.circleCheck,
            text: l10n.verifyRequestSharesResult,
          ),
          if (view.checksPlace)
            DeepLinkLine(
              icon: VerilyIcons.mapPin,
              text: l10n.verifyRequestSharesPlace,
            ),
          if (isMedia && view.shareEvidence)
            DeepLinkLine(
              icon: VerilyIcons.eye,
              text: l10n.verifyRequestSharesMedia(kind),
              emphasized: true,
            )
          else if (isMedia)
            DeepLinkLine(
              icon: VerilyIcons.lock,
              text: l10n.verifyRequestKeepsMedia(kind),
            ),
          DeepLinkLine(
            icon: VerilyIcons.user,
            text: l10n.verifyRequestSharesSubject(view.appName),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          ExcludeSemantics(
            child: SkribbleIcon(
              data: VerilyIcons.clock,
              size: 18,
              color: palette.mutedInk,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.verifyRequestExpires(expiresAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          ),
        ],
      ),
      if (state.problem != null) ...[
        const SizedBox(height: 16),
        DeepLinkNotice(text: l10n.errorGeneric),
      ],
      const SizedBox(height: 20),
      VerilyActionButton(
        key: VerilyTestKeys.verifyRequestAccept,
        label: l10n.verifyRequestAccept,
        isLoading: state.answering == ReturnReason.finished,
        leading: const SkribbleIcon(data: VerilyIcons.check),
        onPressed: busy ? null : () => unawaited(flow.accept()),
      ),
      const SizedBox(height: 12),
      VerilyActionButton(
        key: VerilyTestKeys.verifyRequestDecline,
        label: l10n.verifyRequestDecline,
        tone: VerilyActionTone.secondary,
        isLoading: state.answering == ReturnReason.declined,
        onPressed: busy ? null : () => unawaited(flow.decline()),
      ),
    ];
  }

  List<Widget> _proof(
    BuildContext context,
    WidgetRef ref,
    VerifyRequestFlow flow,
    VerifyRequestProof state,
  ) {
    final l10n = context.l10n;
    final appName = state.view.appName;
    final place = state.place;
    final media = state.media;
    final busy = state.working || state.finishing;

    Future<EvidenceSubmissionResult?> launch(
      ActionAttemptView attempt,
      ActionRequirementView requirement,
    ) => ref.read(evidenceCaptureLauncherProvider)(
      context,
      attempt: attempt,
      requirement: requirement,
    );

    return [
      if (state.proofIn)
        _ProofInCard(
          appName: appName,
          finishing: state.finishing,
          onReturn: () => unawaited(flow.finish()),
        )
      else ...[
        if (place != null)
          _StepCard(
            icon: VerilyIcons.mapPin,
            title: l10n.verifyRequestStepPlace,
            body: l10n.verifyRequestStepPlaceBody(appName),
            done: state.placeDone,
            doneLabel: state.placeSkipped
                ? l10n.verifyRequestPlaceSkipped(appName)
                : l10n.verifyRequestPlaceSent,
            actions: [
              VerilyActionButton(
                key: VerilyTestKeys.verifyRequestSharePlace,
                label: l10n.verifyRequestSharePlace,
                isLoading: state.working && !state.placeDone,
                leading: const SkribbleIcon(data: VerilyIcons.myLocation),
                onPressed: busy ? null : () => unawaited(flow.sharePlace()),
              ),
              if (state.placeOptional && state.notice != null)
                TextButton(
                  key: VerilyTestKeys.verifyRequestSkipPlace,
                  onPressed: busy ? null : flow.skipPlace,
                  child: Text(l10n.verifyRequestSkipPlace),
                ),
            ],
          ),
        if (place != null && media != null) const SizedBox(height: 12),
        if (media != null)
          _StepCard(
            icon: _kindIcon(state.view.kind),
            title: l10n.verifyRequestStepMedia(state.view.kind.name),
            body: state.placeDone
                ? l10n.verifyRequestStepMediaBody
                : l10n.verifyRequestPlaceFirst,
            done: state.mediaDone,
            doneLabel: l10n.verifyRequestMediaSent,
            actions: [
              VerilyActionButton(
                key: VerilyTestKeys.verifyRequestCapture,
                label: l10n.verifyRequestOpenCapture(state.view.kind.name),
                isLoading: state.working && state.placeDone,
                leading: const SkribbleIcon(data: VerilyIcons.camera),
                onPressed: busy || !state.placeDone
                    ? null
                    : () => unawaited(flow.capture(launch)),
              ),
            ],
          ),
      ],
      if (state.notice case final notice?) ...[
        const SizedBox(height: 16),
        DeepLinkNotice(text: _noticeText(l10n, notice, appName)),
      ],
      if (!state.proofIn) ...[
        const SizedBox(height: 16),
        TextButton(
          key: VerilyTestKeys.verifyRequestDeclineInstead,
          onPressed: busy ? null : () => unawaited(flow.decline()),
          child: Text(l10n.verifyRequestDeclineInstead),
        ),
      ],
    ];
  }

  static String? _from(AppLocalizations l10n, VerificationRequestView view) {
    final host = Uri.tryParse(view.appWebsiteUrl ?? '')?.host ?? '';
    return host.isEmpty
        ? l10n.verifyRequestFrom(view.appName)
        : l10n.verifyRequestFromWebsite(view.appName, host);
  }

  static String _noticeText(
    AppLocalizations l10n,
    ProofNotice notice,
    String appName,
  ) => switch (notice) {
    ProofNotice.locationServicesOff => l10n.actionLocationServicesOff,
    ProofNotice.locationDenied => l10n.actionLocationDenied,
    ProofNotice.locationBlocked => l10n.actionLocationBlocked,
    ProofNotice.locationTimedOut => l10n.actionLocationTimedOut,
    ProofNotice.integrityUnavailable => l10n.actionIntegrityUnavailable,
    ProofNotice.signatureUnavailable => l10n.actionSignatureUnavailable,
    ProofNotice.uploadFailed => l10n.actionUploadFailed,
    ProofNotice.placeNotConfirmed => l10n.verifyRequestPlaceNotConfirmed(
      appName,
    ),
    ProofNotice.proofMissing => l10n.verifyRequestProofMissing(appName),
    ProofNotice.generic => l10n.errorGeneric,
  };
}

WiredSvgIconData _kindIcon(VerificationRequestKind kind) => switch (kind) {
  VerificationRequestKind.video => VerilyIcons.video,
  VerificationRequestKind.photo => VerilyIcons.photo,
  VerificationRequestKind.audio => VerilyIcons.microphone,
  VerificationRequestKind.location => VerilyIcons.mapPin,
};

/// One step of the proof: what it is, and its action or its tick.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.done,
    required this.doneLabel,
    required this.actions,
  });

  final WiredSvgIconData icon;
  final String title;
  final String body;
  final bool done;
  final String doneLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: done ? palette.quietPen : palette.ink,
        seed: 197 + title.length,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: SkribbleIcon(
                  data: done ? VerilyIcons.circleCheck : icon,
                  color: palette.ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            done ? doneLabel : body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
          if (!done) ...[
            const SizedBox(height: 14),
            ...actions,
          ],
        ],
      ),
    );
  }
}

/// Every step is done; the way back to the App.
class _ProofInCard extends StatelessWidget {
  const _ProofInCard({
    required this.appName,
    required this.finishing,
    required this.onReturn,
  });

  final String appName;
  final bool finishing;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.ink,
        seed: 211,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: SkribbleIcon(
                  data: VerilyIcons.circleCheck,
                  color: palette.ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.verifyRequestProofIn,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          VerilyActionButton(
            key: VerilyTestKeys.verifyRequestReturn,
            label: l10n.verifyRequestReturn(appName),
            isLoading: finishing,
            leading: const SkribbleIcon(data: VerilyIcons.externalLink),
            onPressed: onReturn,
          ),
        ],
      ),
    );
  }
}

/// Why the request cannot be answered, in plain words, with the way out.
class _UnavailablePanel extends StatelessWidget {
  const _UnavailablePanel({required this.state, required this.onRetry});

  final VerifyRequestUnavailable state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final app = state.appName ?? l10n.verifyRequestTheApp;
    final backToVerily = VerilyStateAction(
      label: l10n.verifyRequestBackToVerily,
      onPressed: () => context.goNamed(VerilyRouteNames.doTab),
    );
    final panel = switch (state.problem) {
      RequestProblem.notFound => VerilyStatePanel.empty(
        title: l10n.verifyRequestNotFoundTitle,
        message: l10n.verifyRequestNotFoundBody,
        action: backToVerily,
      ),
      RequestProblem.expired => VerilyStatePanel.empty(
        title: l10n.verifyRequestExpiredTitle,
        message: l10n.verifyRequestExpiredBody(app),
        action: backToVerily,
      ),
      RequestProblem.taken => VerilyStatePanel.empty(
        title: l10n.verifyRequestTakenTitle,
        message: l10n.verifyRequestTakenBody(app),
        action: backToVerily,
      ),
      RequestProblem.declined => VerilyStatePanel.empty(
        title: l10n.verifyRequestYouDeclinedTitle,
        message: l10n.verifyRequestYouDeclinedBody(app),
        action: backToVerily,
      ),
      RequestProblem.closed => VerilyStatePanel.empty(
        title: l10n.verifyRequestClosedTitle,
        message: l10n.verifyRequestClosedBody(app),
        action: backToVerily,
      ),
      RequestProblem.rateLimited => VerilyStatePanel.empty(
        title: l10n.verifyRequestRateLimitedTitle,
        message: l10n.verifyRequestRateLimitedBody(app),
        action: backToVerily,
      ),
      RequestProblem.appUnavailable => VerilyStatePanel.problem(
        title: l10n.verifyRequestAppUnavailableTitle(app),
        message: state.message,
        action: backToVerily,
      ),
      RequestProblem.generic => VerilyStatePanel.problem(
        title: l10n.verifyRequestLoadFailedTitle,
        message: l10n.errorGeneric,
        action: VerilyStateAction(
          label: l10n.verifyRequestTryAgain,
          onPressed: () => unawaited(onRetry()),
        ),
        secondaryAction: backToVerily,
      ),
    };
    return KeyedSubtree(key: VerilyTestKeys.deepLinkUnavailable, child: panel);
  }
}
