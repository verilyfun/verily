import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredLoadingIndicator, WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/reward_chip.dart';
import 'package:verily_flutter/app/widgets/trust_label.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/app_platform_messages.dart';
import 'package:verily_flutter/features/create/venue_code/venue_code_sheet.dart';
import 'package:verily_flutter/features/do/do_providers.dart';
import 'package:verily_flutter/features/do/widgets/app_confirmation_card.dart';
import 'package:verily_flutter/features/do/widgets/app_pull_check.dart';
import 'package:verily_flutter/features/do/widgets/appeal_section.dart';
import 'package:verily_flutter/features/do/widgets/place_preview.dart';
import 'package:verily_flutter/features/do/widgets/proof_checklist.dart';
import 'package:verily_flutter/features/do/widgets/verified_outcome.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/features/evidence/proof_reasons.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// One action: what it asks, where, the reward, and doing it.
class ActionScreen extends ConsumerWidget {
  const ActionScreen({required this.actionId, super.key});

  /// The action's id, from `/actions/:actionId`.
  final String actionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = Theme.of(context).verily;
    final detail = ref.watch(actionDetailProvider(actionId));

    Widget panel(Widget child) => ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [child],
    );

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(leading: const _BackOrHome()),
      body: SafeArea(
        top: false,
        child: detail.when(
          loading: () => panel(VerilyLoadingPanel(label: l10n.actionLoading)),
          error: (error, stackTrace) {
            debugPrint('Action failed to load: $error');
            return panel(
              VerilyStatePanel.problem(
                title: l10n.actionLoadFailedTitle,
                message: userMessageFor(l10n, error),
                action: VerilyStateAction(
                  label: l10n.dialogRetry,
                  onPressed: () =>
                      ref.invalidate(actionDetailProvider(actionId)),
                ),
              ),
            );
          },
          data: (action) => action == null
              ? panel(
                  VerilyStatePanel.problem(
                    key: VerilyTestKeys.actionNotFound,
                    title: l10n.actionNotFoundTitle,
                    message: l10n.errorNotFound,
                    action: VerilyStateAction(
                      label: l10n.navigationFindActions,
                      onPressed: () => context.go(VerilyRoutePaths.doTab),
                    ),
                  ),
                )
              : _ActionPage(key: ValueKey(action.id), action: action),
        ),
      ),
    );
  }
}

/// Back when there is somewhere to go back to; otherwise (a deep link
/// opened this page) a way home to Do.
class _BackOrHome extends StatelessWidget {
  const _BackOrHome();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? false;
    return IconButton(
      tooltip: canPop ? l10n.actionBack : l10n.navigationFindActions,
      icon: SkribbleIcon(data: canPop ? VerilyIcons.back : VerilyIcons.close),
      onPressed: () => canPop
          ? context.pop()
          : GoRouter.maybeOf(context)?.go(VerilyRoutePaths.doTab),
    );
  }
}

/// A notice under the checklist: what just happened, in plain words.
@immutable
class _Notice {
  const _Notice(
    this.message, {
    this.problem = false,
    this.openSettings = false,
  });

  final String message;

  /// Whether it explains something that went wrong.
  final bool problem;

  /// Whether the fix is in the system settings.
  final bool openSettings;
}

class _ActionPage extends HookConsumerWidget {
  const _ActionPage({required this.action, super.key});

  final ActionOpportunity action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final attempt = useState(action.myAttempt);
    final submitted = useState<Set<UuidValue>>(const {});
    final working = useState<UuidValue?>(null);
    final starting = useState(false);
    final completing = useState(false);
    final notice = useState<_Notice?>(null);
    // Why the last proof sent from this page was not accepted.
    final lastReason = useState<String?>(null);
    // Only a verification that arrives while this page is open earns the
    // stamp slam; a restored result shows it settled.
    final celebrate = useState(false);
    final scroll = useScrollController();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final requirements = [...action.requirements]
      ..sort((a, b) => a.position.compareTo(b.position));
    final appRequirements = [
      for (final requirement in requirements)
        if (requirement.kind == ActionRequirementKind.externalApp) requirement,
    ];
    final appConfirmed = appRequirements.isNotEmpty;
    final accepted = {...?attempt.value?.acceptedRequirementIds};
    // The App's last answer to "I did it", per pull-checked requirement.
    final pullResults = useState<Map<UuidValue, EvidenceSubmissionResult>>(
      const {},
    );
    final askingApp = useState<UuidValue?>(null);

    AppPullPhase pullPhaseOf(ActionRequirementView requirement) {
      if (accepted.contains(requirement.id)) return AppPullPhase.accepted;
      final result = pullResults.value[requirement.id];
      if (result == null) {
        // Until the page reads the check, a turned-down attempt still says
        // so rather than offering to ask again.
        return attempt.value?.status == ActionAttemptStatus.rejected
            ? AppPullPhase.rejected
            : AppPullPhase.ready;
      }
      final phase = appPullPhaseOf(result);
      final status = attempt.value?.status;
      if (phase.isOpen &&
          status != null &&
          status != ActionAttemptStatus.collectingEvidence) {
        // The App decided while the page was checking: its verdict settled
        // the attempt.
        return status == ActionAttemptStatus.rejected
            ? AppPullPhase.rejected
            : AppPullPhase.accepted;
      }
      return phase;
    }

    final pullRequirements = [
      for (final requirement in appRequirements)
        if (requirement.appVerificationMode == AppVerificationMode.pull)
          requirement,
    ];
    final pullOpen = pullRequirements.any(
      (requirement) => pullPhaseOf(requirement).isOpen,
    );

    /// Reads where each "I did it" stands on the server, so a page opened
    /// later, or left open while the App decides, shows the App's answer
    /// instead of starting over. [openOnly] skips checks already settled.
    Future<void> readPullChecks({bool openOnly = false}) async {
      final current = attempt.value;
      if (current == null || action.viewerIsCreator) return;
      final repository = ref.read(actionRepositoryProvider);
      for (final requirement in pullRequirements) {
        final known = pullResults.value[requirement.id];
        if (openOnly && (known == null || !appPullPhaseOf(known).isOpen)) {
          continue;
        }
        try {
          final result = await repository.getAppVerification(
            attemptId: current.id,
            requirementId: requirement.id,
          );
          if (!context.mounted) return;
          // An ask under way answers with fresher news than this read.
          if (result == null || askingApp.value != null) continue;
          pullResults.value = {...pullResults.value, requirement.id: result};
        } on Exception catch (error) {
          // The card keeps what it last knew; the next read tries again.
          debugPrint('Reading the App check failed: $error');
        }
      }
    }

    useEffect(() {
      unawaited(readPullChecks());
      return null;
    }, const []);

    void adopt(ActionAttemptView next) {
      final wasVerified = attempt.value?.status == ActionAttemptStatus.verified;
      final wasCollecting =
          attempt.value?.status == ActionAttemptStatus.collectingEvidence;
      attempt.value = next;
      if (wasCollecting &&
          next.status != ActionAttemptStatus.collectingEvidence) {
        // The outcome sits at the top of the page, and the person is at the
        // bottom where they finished, so bring them to it.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!scroll.hasClients) return;
          if (reduceMotion) {
            scroll.jumpTo(0);
          } else {
            scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
      if (next.status == ActionAttemptStatus.verified && !wasVerified) {
        celebrate.value = true;
      }
      if (next.status != ActionAttemptStatus.collectingEvidence) {
        // The feed shows the attempt's status, so it is now stale.
        ref.invalidate(actionFeedProvider);
      }
    }

    Future<void> refreshAttempt() async {
      final current = attempt.value;
      if (current == null) return;
      try {
        final attempts = await ref
            .read(actionRepositoryProvider)
            .listMyAttempts();
        if (!context.mounted) return;
        for (final candidate in attempts) {
          if (candidate.id == current.id) {
            adopt(candidate);
            return;
          }
        }
      } on Exception catch (error) {
        // A missed check is retried on the next tick; nothing to show.
        debugPrint('Checking the attempt failed: $error');
      }
    }

    final pollInterval = ref.watch(attemptPollIntervalProvider);
    final status = attempt.value?.status;
    // Proof being checked, or an App still deciding on "I did it".
    final polling = status == ActionAttemptStatus.verifying || pullOpen;
    useEffect(() {
      if (!polling) return null;
      var cancelled = false;
      var elapsed = Duration.zero;
      Timer? timer;
      void schedule() {
        final interval = pollInterval(elapsed);
        timer = Timer(interval, () async {
          elapsed += interval;
          if (cancelled || !context.mounted) return;
          final onScreen = ModalRoute.of(context)?.isCurrent ?? true;
          final lifecycle = WidgetsBinding.instance.lifecycleState;
          final foreground =
              lifecycle == null || lifecycle == AppLifecycleState.resumed;
          if (onScreen && foreground) {
            await refreshAttempt();
            await readPullChecks(openOnly: true);
          }
          if (!cancelled) schedule();
        });
      }

      schedule();
      final lifecycle = AppLifecycleListener(
        onResume: () {
          unawaited(refreshAttempt());
          unawaited(readPullChecks(openOnly: true));
        },
      );
      return () {
        cancelled = true;
        timer?.cancel();
        lifecycle.dispose();
      };
    }, [polling, attempt.value?.id]);

    bool allRequiredAccepted(ActionAttemptView current) {
      final done = {...?current.acceptedRequirementIds};
      return requirements
          .where((requirement) => requirement.isRequired)
          .every((requirement) => done.contains(requirement.id));
    }

    Future<void> complete(ActionAttemptView current) async {
      completing.value = true;
      try {
        final result = await ref
            .read(actionRepositoryProvider)
            .completeAttempt(current.id);
        if (!context.mounted) return;
        adopt(result);
        notice.value = null;
      } on Exception catch (error) {
        debugPrint('Completing the attempt failed: $error');
        if (context.mounted) {
          notice.value = _Notice(userMessageFor(l10n, error), problem: true);
        }
      } finally {
        if (context.mounted) completing.value = false;
      }
    }

    /// "I did it" on a pull-checked App proof. Opens the attempt first when
    /// there is none, since the App is asked about one attempt.
    Future<void> askApp(
      ActionRequirementView requirement,
      String? reference,
    ) async {
      askingApp.value = requirement.id;
      notice.value = null;
      try {
        final repository = ref.read(actionRepositoryProvider);
        var current = attempt.value;
        if (current == null) {
          current = await repository.beginAttempt(action.id);
          if (!context.mounted) return;
          adopt(current);
        }
        final result = await repository.requestAppVerification(
          attemptId: current.id,
          requirementId: requirement.id,
          reference: reference,
        );
        if (!context.mounted) return;
        pullResults.value = {...pullResults.value, requirement.id: result};
        adopt(result.attempt);
      } on Exception catch (error) {
        debugPrint('Asking the App to confirm failed: $error');
        if (context.mounted) {
          notice.value = _Notice(
            appPlatformMessage(l10n, error, appName: requirement.appName),
            problem: true,
          );
        }
      } finally {
        if (context.mounted) askingApp.value = null;
      }
    }

    Future<void> start() async {
      starting.value = true;
      notice.value = null;
      try {
        final begun = await ref
            .read(actionRepositoryProvider)
            .beginAttempt(action.id);
        if (context.mounted) adopt(begun);
      } on Exception catch (error) {
        debugPrint('Starting the action failed: $error');
        if (context.mounted) {
          notice.value = _Notice(userMessageFor(l10n, error), problem: true);
        }
      } finally {
        if (context.mounted) starting.value = false;
      }
    }

    Future<void> prove(ActionRequirementView requirement) async {
      final current = attempt.value;
      if (current == null) return;
      working.value = requirement.id;
      notice.value = null;
      try {
        final evidence = ref.read(evidenceServiceProvider);
        final EvidenceSubmissionResult? result;
        switch (requirement.kind) {
          case ActionRequirementKind.location:
            final fix = await ref
                .read(locationServiceProvider)
                .precisePosition();
            result = await evidence.submitLocation(
              attempt: current,
              requirement: requirement,
              fix: fix,
            );
          case ActionRequirementKind.qrCode:
            final code = await ref.read(venueCodeScannerProvider)(context);
            if (code == null || !context.mounted) return;
            result = await evidence.submitQrCode(
              attempt: current,
              requirement: requirement,
              code: code,
            );
          case ActionRequirementKind.video ||
              ActionRequirementKind.photo ||
              ActionRequirementKind.audio ||
              ActionRequirementKind.motion:
            result = await ref.read(evidenceCaptureLauncherProvider)(
              context,
              attempt: current,
              requirement: requirement,
            );
            if (result != null) {
              submitted.value = {...submitted.value, requirement.id};
            }
          case ActionRequirementKind.externalApp:
            // The App confirms its own step, server to server.
            result = null;
        }
        if (result == null || !context.mounted) return;
        adopt(result.attempt);
        lastReason.value = result.reasonCode;
        notice.value = _Notice(
          _resultMessage(l10n, result),
          problem: result.status == EvidenceDecisionStatus.rejected,
        );
        final next = result.attempt;
        if (next.status == ActionAttemptStatus.collectingEvidence &&
            allRequiredAccepted(next)) {
          await complete(next);
        }
      } on LocationException catch (error) {
        if (context.mounted) notice.value = _locationNotice(l10n, error);
      } on CaptureIntegrityException catch (error) {
        if (context.mounted) {
          notice.value = _Notice(
            switch (error.failure) {
              CaptureIntegrityFailure.integrityUnavailable =>
                l10n.actionIntegrityUnavailable,
              CaptureIntegrityFailure.signatureUnavailable =>
                l10n.actionSignatureUnavailable,
            },
            problem: true,
          );
        }
      } on MediaUploadException {
        if (context.mounted) {
          notice.value = _Notice(l10n.actionUploadFailed, problem: true);
        }
      } on Exception catch (error) {
        debugPrint('Sending proof failed: $error');
        if (context.mounted) {
          notice.value = _Notice(userMessageFor(l10n, error), problem: true);
        }
      } finally {
        if (context.mounted) working.value = null;
      }
    }

    ProofState stateOf(ActionRequirementView requirement) {
      if (accepted.contains(requirement.id)) return ProofState.accepted;
      if (working.value == requirement.id) return ProofState.working;
      final current = attempt.value;
      final isMedia = switch (requirement.kind) {
        ActionRequirementKind.video ||
        ActionRequirementKind.photo ||
        ActionRequirementKind.audio => true,
        _ => false,
      };
      if (current?.status == ActionAttemptStatus.pendingReview) {
        return ProofState.withReviewer;
      }
      if (current?.status == ActionAttemptStatus.verifying &&
          (submitted.value.contains(requirement.id) ||
              (isMedia && submitted.value.isEmpty))) {
        return ProofState.checking;
      }
      return ProofState.open;
    }

    final current = attempt.value;
    final collecting =
        current?.status == ActionAttemptStatus.collectingEvidence;
    final reward = action.reward;
    final fundedReward =
        reward != null && reward.status == RewardPoolStatus.funded
        ? reward
        : null;
    final place = placeOf(action);
    final canStart =
        current == null &&
        !action.viewerIsCreator &&
        !appConfirmed &&
        action.status == ActionDefinitionStatus.active;

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(
          l10n.doCreatorBy(action.creatorDisplayName),
          style: theme.textTheme.labelMedium?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(
            action.title,
            style: theme.textTheme.headlineSmall?.copyWith(color: palette.ink),
          ),
        ),
        if (action.description.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            action.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TrustLabel(action: action),
        // A finished attempt leads with its outcome; while proof is being
        // collected there is none yet.
        if (current != null &&
            current.status != ActionAttemptStatus.collectingEvidence) ...[
          const SizedBox(height: 16),
          switch (current.status) {
            ActionAttemptStatus.verified => VerifiedOutcome(
              attempt: current,
              reward: reward,
              celebrate: celebrate.value,
            ),
            ActionAttemptStatus.verifying => _StatusBox(
              key: VerilyTestKeys.actionCheckingOutcome,
              icon: VerilyIcons.hourglass,
              title: l10n.attemptStatusVerifying,
              body: l10n.actionCheckingBody,
              busy: true,
            ),
            ActionAttemptStatus.pendingReview => _StatusBox(
              key: VerilyTestKeys.actionReviewOutcome,
              icon: VerilyIcons.review,
              title: l10n.attemptStatusPendingReview,
              body: current.rewardValueReview
                  ? l10n.actionReviewValueBody
                  : l10n.actionReviewBody,
              tone: VerilyTone.review,
            ),
            ActionAttemptStatus.rejected => AppealSection(
              attempt: current,
              reasonCode: lastReason.value,
            ),
            ActionAttemptStatus.capacityReached => _StatusBox(
              key: VerilyTestKeys.actionCapacityOutcome,
              icon: VerilyIcons.flag,
              title: l10n.attemptStatusCapacityReached,
              body: l10n.actionCapacityBody,
            ),
            ActionAttemptStatus.collectingEvidence => const SizedBox.shrink(),
          },
        ],
        if (fundedReward != null) ...[
          const SizedBox(height: 16),
          _RewardBlock(reward: fundedReward),
        ],
        if (place != null) ...[
          const SizedBox(height: 16),
          PlacePreview(place: place),
        ],
        if (action.viewerIsCreator) ...[
          const SizedBox(height: 24),
          _CreatorPanel(action: action),
        ] else if (action.status != ActionDefinitionStatus.active &&
            current == null) ...[
          const SizedBox(height: 24),
          VerilyStatePanel.problem(
            title: l10n.actionNotLiveTitle,
            message: l10n.actionNotLiveBody,
          ),
        ],
        for (final requirement in appRequirements) ...[
          const SizedBox(height: 16),
          AppConfirmationCard(
            requirement: requirement,
            confirmed: accepted.contains(requirement.id),
            showLinkCode:
                requirement.appVerificationMode != AppVerificationMode.pull ||
                pullPhaseOf(requirement).canAsk,
            pullCheck:
                requirement.appVerificationMode == AppVerificationMode.pull &&
                    !action.viewerIsCreator
                ? AppPullCheck(
                    requirement: requirement,
                    appName: requirement.appName ?? l10n.actionAppUnnamed,
                    phase: pullPhaseOf(requirement),
                    asking: askingApp.value == requirement.id,
                    onAsk:
                        action.status == ActionDefinitionStatus.active &&
                            (current == null || collecting) &&
                            askingApp.value == null &&
                            (requirement.appAvailable ?? true)
                        ? (reference) =>
                              unawaited(askApp(requirement, reference))
                        : null,
                  )
                : null,
          ),
        ],
        if (!appConfirmed) ...[
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              current == null ? l10n.actionProofHeading : l10n.actionYourProof,
              style: theme.textTheme.titleMedium?.copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            current == null ? l10n.actionProofIntro : l10n.actionProofTapHint,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: 12),
          for (final requirement in requirements) ...[
            ProofRow(
              requirement: requirement,
              state: stateOf(requirement),
              onTap:
                  collecting &&
                      working.value == null &&
                      !completing.value &&
                      !accepted.contains(requirement.id)
                  ? () => unawaited(prove(requirement))
                  : null,
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (canStart) ...[
          const SizedBox(height: 4),
          VerilyActionButton(
            key: VerilyTestKeys.actionStart,
            label: l10n.actionStart,
            isLoading: starting.value,
            leading: const SkribbleIcon(data: VerilyIcons.play),
            onPressed: () => unawaited(start()),
          ),
        ],
        if (current != null &&
            collecting &&
            allRequiredAccepted(current) &&
            !appConfirmed) ...[
          const SizedBox(height: 4),
          VerilyActionButton(
            key: VerilyTestKeys.actionFinish,
            label: l10n.actionFinish,
            isLoading: completing.value,
            leading: const SkribbleIcon(data: VerilyIcons.check),
            onPressed: () => unawaited(complete(current)),
          ),
        ],
        if (completing.value && !collecting) ...[
          const SizedBox(height: 16),
          VerilyLoadingPanel(label: l10n.actionFinishing),
        ],
        if (notice.value case final shown?) ...[
          const SizedBox(height: 16),
          _NoticeBox(notice: shown),
        ],
      ],
    );
  }
}

String _resultMessage(
  AppLocalizations l10n,
  EvidenceSubmissionResult result,
) => switch (result.status) {
  EvidenceDecisionStatus.accepted => l10n.actionProofAccepted,
  EvidenceDecisionStatus.manualReview => l10n.actionProofWithReviewer,
  EvidenceDecisionStatus.rejected => proofReasonMessage(
    l10n,
    result.reasonCode,
  ),
  null => l10n.actionProofSent,
};

_Notice _locationNotice(AppLocalizations l10n, LocationException error) =>
    switch (error.failure) {
      LocationFailure.servicesOff => _Notice(
        l10n.actionLocationServicesOff,
        problem: true,
      ),
      LocationFailure.denied => _Notice(
        l10n.actionLocationDenied,
        problem: true,
      ),
      LocationFailure.deniedForever => _Notice(
        l10n.actionLocationBlocked,
        problem: true,
        openSettings: true,
      ),
      LocationFailure.timedOut => _Notice(
        l10n.actionLocationTimedOut,
        problem: true,
      ),
    };

class _NoticeBox extends ConsumerWidget {
  const _NoticeBox({required this.notice});

  final _Notice notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: VerilyTestKeys.actionNotice,
        padding: const EdgeInsets.all(12),
        decoration: VerilyRoughDecoration(
          color: notice.problem ? palette.surface : palette.highlight,
          outline: notice.problem ? palette.ink : palette.quietPen,
          strokeWidth: notice.problem ? 2.6 : 2,
          radius: VerilyRadius.chip,
          seed: 283,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkribbleIcon(
                  data: notice.problem ? VerilyIcons.warning : VerilyIcons.info,
                  size: 20,
                  color: palette.ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notice.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
              ],
            ),
            if (notice.openSettings) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => unawaited(
                    ref.read(locationServiceProvider).openSettings(),
                  ),
                  child: Text(l10n.doOpenSettings),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.icon,
    required this.title,
    required this.body,
    this.busy = false,
    this.tone = VerilyTone.neutral,
    super.key,
  });

  final WiredSvgIconData icon;
  final String title;
  final String body;
  final bool busy;
  final VerilyTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: VerilyRoughDecoration(
          color: palette.wash(tone),
          outline: palette.ink,
          seed: 293,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (busy)
              WiredLoadingIndicator(color: palette.ink)
            else
              SkribbleIcon(data: icon, size: 24, color: palette.hue(tone)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.ink,
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

class _RewardBlock extends StatelessWidget {
  const _RewardBlock({required this.reward});

  final RewardSummary reward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final capReached = reward.myWins >= reward.maxWinsPerAccount;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RewardChip(reward: reward),
        Text(
          l10n.rewardRemaining(reward.payoutsRemaining),
          style: theme.textTheme.labelLarge?.copyWith(color: palette.ink),
        ),
        Text(
          capReached
              ? l10n.actionRewardCapReached
              : l10n.actionRewardPerPerson(reward.maxWinsPerAccount),
          style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
        ),
      ],
    );
  }
}

/// The creator's view of their own action: no Start, but Edit and the
/// venue code people scan.
class _CreatorPanel extends StatelessWidget {
  const _CreatorPanel({required this.action});

  final ActionOpportunity action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final venueCodes = [
      for (final requirement in action.requirements)
        if (requirement.kind == ActionRequirementKind.qrCode) requirement,
    ];
    return Container(
      key: VerilyTestKeys.actionCreatorPanel,
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: palette.highlight,
        outline: palette.ink,
        seed: 307,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.actionCreatorTitle,
            style: theme.textTheme.titleMedium?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 4),
          Text(
            switch (action.status) {
              ActionDefinitionStatus.draft => l10n.actionCreatorDraft,
              ActionDefinitionStatus.active => l10n.actionCreatorLive,
              ActionDefinitionStatus.paused => l10n.actionCreatorPaused,
              ActionDefinitionStatus.completed => l10n.actionCreatorCompleted,
            },
            style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 12),
          VerilyActionButton(
            key: VerilyTestKeys.actionEdit,
            label: l10n.actionCreatorEdit,
            tone: VerilyActionTone.secondary,
            leading: const SkribbleIcon(data: VerilyIcons.edit),
            onPressed: () => unawaited(
              context.push(VerilyLocations.actionEdit(action.id.toString())),
            ),
          ),
          for (final requirement in venueCodes) ...[
            const SizedBox(height: 12),
            VerilyActionButton(
              key: VerilyTestKeys.actionShowVenueCode(
                requirement.requirementKey,
              ),
              label: venueCodes.length == 1
                  ? l10n.actionCreatorShowVenueCode
                  : l10n.actionCreatorShowVenueCodeFor(requirement.title),
              tone: VerilyActionTone.secondary,
              leading: const SkribbleIcon(data: VerilyIcons.qrCode),
              onPressed: () => unawaited(
                showVenueCode(
                  context,
                  action: action,
                  requirement: requirement,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
