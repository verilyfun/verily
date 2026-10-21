import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/token_amount.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/me/widgets/pushed_page.dart';
import 'package:verily_flutter/features/review/evidence_review_repository.dart';
import 'package:verily_flutter/features/review/widgets/decision_note_dialog.dart';
import 'package:verily_flutter/features/review/widgets/evidence_media_view.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

final FutureProvider<List<EvidenceReviewQueueItem>> reviewQueueProvider =
    FutureProvider.autoDispose(
      (ref) => ref.watch(evidenceReviewRepositoryProvider).listQueue(),
    );

/// Proof that needs a person.
///
/// Only accounts with the `evidence.review` scope see the queue; the server
/// refuses everyone else regardless. Reviewers see what was captured, what
/// was asked, and why it is waiting, never a model's name or score.
class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canReview = ref.watch(
      accountSessionProvider.select((session) => session.canReviewEvidence),
    );

    return PushedPage(
      title: l10n.reviewTitle,
      fallbackRouteName: VerilyRouteNames.me,
      body: canReview
          ? const _Queue()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VerilyStatePanel.empty(
                  title: l10n.reviewNotReviewerTitle,
                  message: l10n.reviewNotReviewerBody,
                  tone: VerilyTone.review,
                ),
              ],
            ),
    );
  }
}

class _Queue extends ConsumerWidget {
  const _Queue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final queue = ref.watch(reviewQueueProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(reviewQueueProvider);
        try {
          await ref.read(reviewQueueProvider.future);
        } on Object catch (error) {
          // The problem panel below says what happened.
          debugPrint('Refreshing the review queue failed: $error');
        }
      },
      child: queue.when(
        loading: () => ListView(
          children: [VerilyLoadingPanel(label: l10n.reviewLoading)],
        ),
        error: (error, _) {
          debugPrint('The review queue failed to load: $error');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              VerilyStatePanel.problem(
                title: l10n.reviewLoadFailedTitle,
                message: userMessageFor(l10n, error),
                action: VerilyStateAction(
                  label: l10n.dialogRetry,
                  onPressed: () => ref.invalidate(reviewQueueProvider),
                ),
              ),
            ],
          );
        },
        data: (items) => items.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  VerilyStatePanel.empty(
                    title: l10n.reviewEmptyTitle,
                    message: l10n.reviewEmptyBody,
                    tone: VerilyTone.review,
                  ),
                ],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1180
                      ? 3
                      : constraints.maxWidth >= 720
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - 32 - 16 * (columns - 1)) /
                      columns;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final (index, item) in items.indexed)
                          Semantics(
                            container: true,
                            child: SizedBox(
                              width: width,
                              child: _ReviewCard(item: item, seed: 401 + index),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.item, required this.seed});

  final EvidenceReviewQueueItem item;
  final int seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final time = DateFormat.MMMd(l10n.localeName).add_jm();
    final kind = proofKindLabel(l10n, item.requirementKind);
    final duration = item.durationSeconds;
    final payout = item.payoutReview;
    final id = item.evidenceId.toString();

    Future<void> decide(EvidenceDecisionStatus decision) async {
      final accepting = decision == EvidenceDecisionStatus.accepted;
      final note = await showDecisionNoteDialog(
        context,
        title: accepting ? l10n.reviewAcceptTitle : l10n.reviewRejectTitle,
        label: l10n.reviewNoteLabel,
        hint: l10n.reviewNoteHint,
        confirmLabel: accepting ? l10n.reviewAccept : l10n.reviewReject,
      );
      if (note == null || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref
            .read(evidenceReviewRepositoryProvider)
            .review(
              evidenceId: item.evidenceId,
              decision: decision,
              note: note,
            );
        ref.invalidate(reviewQueueProvider);
        messenger.showSnackBar(SnackBar(content: Text(l10n.reviewSaved)));
      } on Object catch (error) {
        debugPrint('Saving a review failed: $error');
        messenger.showSnackBar(SnackBar(content: Text(l10n.reviewSaveFailed)));
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.ink,
        seed: seed,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EvidenceMediaView(
            kind: item.requirementKind,
            url: item.mediaUrl,
            photoLabel: l10n.reviewPhotoLabel(item.actionTitle),
          ),
          if (item.mediaUrl != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.reviewMediaExpires,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.mutedInk,
                    ),
                  ),
                ),
                TextButton(
                  key: VerilyTestKeys.reviewMediaReload,
                  onPressed: () => ref.invalidate(reviewQueueProvider),
                  child: Text(l10n.reviewMediaReload),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            item.actionTitle,
            style: theme.textTheme.titleLarge?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reviewContext(item.creatorDisplayName, item.requirementTitle),
            style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: 4),
          Text(
            duration == null || duration <= 0
                ? kind
                : l10n.reviewKindWithDuration(kind, duration),
            style: theme.textTheme.labelMedium?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reviewTimes(
              time.format(item.capturedAt.toLocal()),
              time.format(item.submittedAt.toLocal()),
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
          if (item.reviewSummary.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              item.reviewSummary,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
            ),
          ],
          if (item.spokenChallengeWord case final word?
              when word.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _Note(
              icon: VerilyIcons.microphone,
              tone: VerilyTone.review,
              text: l10n.reviewListenFor(word),
              seed: seed + 1000,
            ),
          ],
          if (payout != null) ...[
            const SizedBox(height: 12),
            _Note(
              icon: VerilyIcons.coins,
              tone: VerilyTone.reward,
              text: l10n.reviewPayout(
                TokenAmount(
                  atoms: payout.amountPerPayout,
                  decimals: payout.decimals,
                  symbol: payout.tokenSymbol,
                ).format(l10n.localeName),
                TokenAmount(
                  atoms: payout.thresholdAtoms,
                  decimals: payout.decimals,
                  symbol: payout.tokenSymbol,
                ).format(l10n.localeName),
              ),
              seed: seed + 2000,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: VerilyActionButton(
                  key: VerilyTestKeys.reviewReject(id),
                  label: l10n.reviewReject,
                  tone: VerilyActionTone.secondary,
                  onPressed: () =>
                      unawaited(decide(EvidenceDecisionStatus.rejected)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VerilyActionButton(
                  key: VerilyTestKeys.reviewAccept(id),
                  label: l10n.reviewAccept,
                  onPressed: () =>
                      unawaited(decide(EvidenceDecisionStatus.accepted)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What a reviewer should listen or look for, on its tone's wash.
class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.tone,
    required this.text,
    required this.seed,
  });

  final WiredSvgIconData icon;
  final VerilyTone tone;
  final String text;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: VerilyRoughDecoration(
        color: palette.wash(tone),
        outline: palette.hue(tone),
        radius: VerilyRadius.chip,
        strokeWidth: 2,
        seed: seed,
      ),
      child: Row(
        children: [
          SkribbleIcon(data: icon, size: 20, color: palette.hue(tone)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The kind of proof, in plain words.
String proofKindLabel(AppLocalizations l10n, ActionRequirementKind kind) =>
    switch (kind) {
      ActionRequirementKind.video => l10n.reviewKindVideo,
      ActionRequirementKind.photo => l10n.reviewKindPhoto,
      ActionRequirementKind.audio => l10n.reviewKindAudio,
      ActionRequirementKind.location => l10n.reviewKindLocation,
      ActionRequirementKind.qrCode => l10n.reviewKindQrCode,
      ActionRequirementKind.motion => l10n.reviewKindMotion,
      ActionRequirementKind.externalApp => l10n.reviewKindExternalApp,
    };
