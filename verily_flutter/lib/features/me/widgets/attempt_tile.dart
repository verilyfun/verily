import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/core/token_amount.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/actions/action_labels.dart';
import 'package:verily_flutter/features/appeals/evidence_appeal_repository.dart';
import 'package:verily_flutter/features/me/me_providers.dart';
import 'package:verily_flutter/features/me/widgets/appeal_dialog.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// One attempt: the action, where it stands, what it earned, and, for a
/// rejection, the one appeal it allows.
class AttemptTile extends ConsumerWidget {
  const AttemptTile({required this.item, required this.seed, super.key});

  final MyAttempt item;
  final int seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final attempt = item.attempt;
    final payout = item.payout;
    final started = DateFormat.yMMMd(
      l10n.localeName,
    ).format(attempt.startedAt.toLocal());
    final payoutStatus = attempt.payoutStatus;
    final outcomeNote = rewardOutcomeNote(l10n, attempt.rewardOutcome);
    final verified = attempt.status == ActionAttemptStatus.verified;

    final card = Container(
      key: VerilyTestKeys.meAttempt(attempt.id.toString()),
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.quietPen,
        strokeWidth: 2,
        seed: seed,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            attempt.actionTitle ?? l10n.meAttemptUnknownAction,
            style: theme.textTheme.titleMedium?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SkribbleIcon(
                data: _statusIcon(attempt.status),
                size: 18,
                color: verified ? palette.accent : palette.mutedInk,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  attemptStatusLabel(l10n, attempt.status),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l10n.meAttemptStarted(started),
            style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
          if (payoutStatus != null && payout != null) ...[
            const SizedBox(height: 8),
            Text(
              payoutStatusLabel(
                l10n,
                payoutStatus,
                TokenAmount(
                  atoms: payout.amount,
                  decimals: payout.decimals,
                  symbol: payout.tokenSymbol,
                ).format(l10n.localeName),
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
            ),
          ],
          if (verified && outcomeNote != null) ...[
            const SizedBox(height: 8),
            Text(
              outcomeNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          ],
          if (attempt.status == ActionAttemptStatus.rejected) ...[
            const SizedBox(height: 12),
            _AppealState(attemptId: attempt.id),
          ],
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(VerilyRadius.card),
        onTap: () => context.push(
          VerilyLocations.action(attempt.actionDefinitionId.toString()),
        ),
        child: card,
      ),
    );
  }

  static WiredSvgIconData _statusIcon(ActionAttemptStatus status) =>
      switch (status) {
        ActionAttemptStatus.verified => VerilyIcons.verified,
        ActionAttemptStatus.verifying ||
        ActionAttemptStatus.pendingReview => VerilyIcons.hourglass,
        ActionAttemptStatus.rejected => VerilyIcons.close,
        ActionAttemptStatus.capacityReached => VerilyIcons.lock,
        ActionAttemptStatus.collectingEvidence => VerilyIcons.bolt,
      };
}

/// The appeal on a rejected attempt: its state when one was sent, or the
/// button that sends the one appeal allowed.
class _AppealState extends ConsumerWidget {
  const _AppealState({required this.attemptId});

  final UuidValue attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final appeal = ref.watch(myAppealProvider(attemptId));

    Future<void> appealNow() async {
      final reason = await showAppealDialog(context);
      if (reason == null || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref
            .read(evidenceAppealRepositoryProvider)
            .submit(attemptId: attemptId, reason: reason);
        ref.invalidate(myAppealProvider(attemptId));
        messenger.showSnackBar(SnackBar(content: Text(l10n.meAppealSent)));
      } on Object catch (error) {
        debugPrint('Appeal failed: $error');
        messenger.showSnackBar(
          SnackBar(content: Text(userMessageFor(l10n, error))),
        );
      }
    }

    return appeal.when(
      // Until the appeal state is known, nothing is offered: an appeal may
      // already be on its way.
      loading: () => const SizedBox.shrink(),
      error: (error, _) {
        debugPrint('Appeal state failed to load: $error');
        return const SizedBox.shrink();
      },
      data: (existing) {
        if (existing == null) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: VerilyActionButton(
              key: VerilyTestKeys.meAppeal(attemptId.toString()),
              label: l10n.meAppeal,
              tone: VerilyActionTone.secondary,
              expand: false,
              onPressed: () => unawaited(appealNow()),
            ),
          );
        }
        final status = switch (existing.status) {
          EvidenceAppealStatus.pending => l10n.meAppealPending,
          EvidenceAppealStatus.accepted => l10n.meAppealAccepted,
          EvidenceAppealStatus.rejected => l10n.meAppealRejected,
        };
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: VerilyRoughDecoration(
            color: palette.reviewWash,
            outline: palette.review,
            radius: VerilyRadius.chip,
            strokeWidth: 2,
            seed: 281,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                status,
                style: theme.textTheme.labelLarge?.copyWith(color: palette.ink),
              ),
              if (existing.resolutionNote case final note?
                  when note.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
