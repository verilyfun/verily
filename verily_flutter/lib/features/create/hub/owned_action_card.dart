import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/reward_chip.dart';
import 'package:verily_flutter/app/widgets/trust_label.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/widgets/apps_common.dart';
import 'package:verily_flutter/features/create/hub/create_hub_providers.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// One of the creator's actions: its state, its reward, and what to do next.
///
/// Each card offers one primary step: fund the reward when it needs funding,
/// otherwise publish a draft or paused action.
class OwnedActionCard extends HookConsumerWidget {
  const OwnedActionCard({required this.action, super.key});

  final ActionOpportunity action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final busy = useState(false);
    final id = action.id.toString();
    final reward = action.reward;
    final needsFunding = rewardNeedsFunding(reward);
    final canPublish =
        action.status == ActionDefinitionStatus.draft ||
        action.status == ActionDefinitionStatus.paused;
    final venueRequirement = venueCodeRequirementOf(action);

    void say(String message) {
      if (!context.mounted) return;
      // The latest outcome replaces any earlier note, so a publish that
      // needed funding first ends on "is live", not "in escrow".
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    void refresh() => ref.invalidate(createHubActionsProvider);

    /// Opens funding and reports what the server says afterwards. Returns
    /// whether the server reports the pool funded.
    Future<bool> fund() async {
      final pool = await ref.read(rewardFundingLauncherProvider)(
        context,
        action: action,
      );
      refresh();
      final funded = pool?.status == RewardPoolStatus.funded;
      if (funded) say(l10n.hubRewardFunded);
      return funded;
    }

    Future<void> run(Future<void> Function() step) async {
      if (busy.value) return;
      busy.value = true;
      try {
        await step();
      } on Object catch (error) {
        debugPrint('Updating an action failed: $error');
        say(userMessageFor(l10n, error));
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    Future<void> publish() => run(() async {
      final repository = ref.read(actionRepositoryProvider);
      try {
        await repository.publish(action);
      } on ActionAuthoringException catch (error) {
        if (error.reason != ActionAuthoringProblem.rewardNotFunded) rethrow;
        // A rewarded action goes live only once its escrow is verified.
        if (!await fund()) return;
        await repository.publish(action);
      }
      refresh();
      say(l10n.hubPublished(action.title));
    });

    Future<void> pause() => run(() async {
      await ref.read(actionRepositoryProvider).pause(action);
      refresh();
      say(l10n.hubPaused(action.title));
    });

    final status = switch (action.status) {
      ActionDefinitionStatus.draft => l10n.hubStatusDraft,
      ActionDefinitionStatus.active => l10n.hubStatusLive,
      ActionDefinitionStatus.paused => l10n.hubStatusPaused,
      ActionDefinitionStatus.completed => l10n.hubStatusCompleted,
    };

    return Container(
      key: VerilyTestKeys.hubActionCard(id),
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.ink,
        seed: action.id.hashCode & 0x7fffffff,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                headingLevel: 3,
                child: Text(
                  action.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
              AppsStatusPill(
                label: status,
                muted: action.status == ActionDefinitionStatus.completed,
              ),
            ],
          ),
          const SizedBox(height: 6),
          TrustLabel(action: action),
          if (action.status != ActionDefinitionStatus.draft) ...[
            const SizedBox(height: 4),
            Text(
              l10n.hubVerifiedCount(action.verifiedCompletions),
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          ],
          if (reward != null) ...[
            const SizedBox(height: 12),
            _RewardState(reward: reward),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (needsFunding)
                VerilyActionButton(
                  key: VerilyTestKeys.hubFund(id),
                  label: l10n.hubFund,
                  expand: false,
                  isLoading: busy.value,
                  leading: const SkribbleIcon(data: VerilyIcons.escrow),
                  onPressed: () => unawaited(run(() async => fund())),
                ),
              if (canPublish)
                VerilyActionButton(
                  key: VerilyTestKeys.hubPublish(id),
                  label: l10n.hubPublish,
                  tone: needsFunding
                      ? VerilyActionTone.secondary
                      : VerilyActionTone.primary,
                  expand: false,
                  isLoading: busy.value && !needsFunding,
                  leading: const SkribbleIcon(data: VerilyIcons.rocket),
                  onPressed: () => unawaited(publish()),
                ),
              if (action.status == ActionDefinitionStatus.active)
                VerilyActionButton(
                  key: VerilyTestKeys.hubPause(id),
                  label: l10n.hubPause,
                  tone: VerilyActionTone.secondary,
                  expand: false,
                  isLoading: busy.value,
                  leading: const SkribbleIcon(data: VerilyIcons.pause),
                  onPressed: () => unawaited(pause()),
                ),
              if (venueRequirement case final requirement?)
                VerilyActionButton(
                  key: VerilyTestKeys.hubVenueCode(id),
                  label: l10n.hubVenueCode,
                  tone: VerilyActionTone.secondary,
                  expand: false,
                  leading: const SkribbleIcon(data: VerilyIcons.qrCode),
                  onPressed: () => unawaited(
                    ref.read(venueCodeLauncherProvider)(
                      context,
                      action: action,
                      requirement: requirement,
                    ),
                  ),
                ),
            ],
          ),
          // Editing and previewing are always there, so they stay quiet
          // links instead of competing with the step the action needs next.
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                key: VerilyTestKeys.hubEdit(id),
                icon: const SkribbleIcon(data: VerilyIcons.edit, size: 20),
                label: Text(l10n.hubEdit),
                onPressed: () async {
                  await context.push(VerilyLocations.actionEdit(id));
                  if (context.mounted) refresh();
                },
              ),
              TextButton.icon(
                key: VerilyTestKeys.hubView(id),
                icon: const SkribbleIcon(data: VerilyIcons.eye, size: 20),
                label: Text(l10n.hubView),
                onPressed: () =>
                    unawaited(context.push(VerilyLocations.action(id))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Where the reward stands, in the server's words: a reward is shown as in
/// escrow only once the server reports the pool funded.
class _RewardState extends StatelessWidget {
  const _RewardState({required this.reward});

  final RewardSummary reward;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final note = theme.textTheme.bodySmall?.copyWith(color: palette.ink);

    return switch (reward.status) {
      RewardPoolStatus.draft || RewardPoolStatus.awaitingFunding => Row(
        children: [
          SkribbleIcon(data: VerilyIcons.escrow, size: 20, color: palette.ink),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.hubRewardNeedsFunding, style: note)),
        ],
      ),
      RewardPoolStatus.funded => Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          RewardChip(reward: reward),
          Text(l10n.rewardRemaining(reward.payoutsRemaining), style: note),
        ],
      ),
      RewardPoolStatus.ended => Text(l10n.hubRewardEnded, style: note),
      RewardPoolStatus.closed => Text(l10n.hubRewardClosed, style: note),
    };
  }
}
