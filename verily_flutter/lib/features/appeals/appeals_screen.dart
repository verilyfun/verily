import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/appeals/evidence_appeal_repository.dart';
import 'package:verily_flutter/features/me/widgets/pushed_page.dart';
import 'package:verily_flutter/features/review/review_queue_screen.dart'
    show proofKindLabel;
import 'package:verily_flutter/features/review/widgets/decision_note_dialog.dart';
import 'package:verily_flutter/features/review/widgets/evidence_media_view.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

final FutureProvider<List<EvidenceAppealView>> ownedAppealsProvider =
    FutureProvider.autoDispose(
      (ref) => ref.watch(evidenceAppealRepositoryProvider).listOwned(),
    );

/// Appeals on the creator's own actions: a participant contests a
/// rejection, and the creator decides with a note the participant sees.
class AppealsScreen extends ConsumerWidget {
  const AppealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appeals = ref.watch(ownedAppealsProvider);

    return PushedPage(
      title: l10n.appealsTitle,
      fallbackRouteName: VerilyRouteNames.me,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ownedAppealsProvider);
          try {
            await ref.read(ownedAppealsProvider.future);
          } on Object catch (error) {
            // The problem panel below says what happened.
            debugPrint('Refreshing appeals failed: $error');
          }
        },
        child: appeals.when(
          loading: () => ListView(
            children: [VerilyLoadingPanel(label: l10n.appealsLoading)],
          ),
          error: (error, _) {
            debugPrint('Appeals failed to load: $error');
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VerilyStatePanel.problem(
                  title: l10n.appealsLoadFailedTitle,
                  message: userMessageFor(l10n, error),
                  action: VerilyStateAction(
                    label: l10n.dialogRetry,
                    onPressed: () => ref.invalidate(ownedAppealsProvider),
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
                      title: l10n.appealsEmptyTitle,
                      message: l10n.appealsEmptyBody,
                      tone: VerilyTone.review,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => Semantics(
                    container: true,
                    child: _AppealCard(appeal: items[index], seed: 431 + index),
                  ),
                ),
        ),
      ),
    );
  }
}

class _AppealCard extends ConsumerWidget {
  const _AppealCard({required this.appeal, required this.seed});

  final EvidenceAppealView appeal;
  final int seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final id = appeal.id.toString();
    final status = switch (appeal.status) {
      EvidenceAppealStatus.pending => l10n.appealsStatusPending,
      EvidenceAppealStatus.accepted => l10n.appealsStatusAccepted,
      EvidenceAppealStatus.rejected => l10n.appealsStatusRejected,
    };

    Future<void> resolve(EvidenceAppealStatus decision) async {
      final accepting = decision == EvidenceAppealStatus.accepted;
      final note = await showDecisionNoteDialog(
        context,
        title: accepting ? l10n.appealsAcceptTitle : l10n.appealsRejectTitle,
        body: accepting ? l10n.appealsAcceptBody : l10n.appealsRejectBody,
        label: l10n.appealsNoteLabel,
        hint: l10n.appealsNoteHint,
        confirmLabel: accepting ? l10n.appealsAccept : l10n.appealsReject,
      );
      if (note == null || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref
            .read(evidenceAppealRepositoryProvider)
            .resolve(appealId: appeal.id, decision: decision, note: note);
        ref.invalidate(ownedAppealsProvider);
        messenger.showSnackBar(SnackBar(content: Text(l10n.appealsSaved)));
      } on Object catch (error) {
        debugPrint('Resolving an appeal failed: $error');
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.appealsSaveFailed)),
        );
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
          if (appeal.mediaUrl != null) ...[
            EvidenceMediaView(
              kind: appeal.requirementKind,
              url: appeal.mediaUrl,
              photoLabel: l10n.reviewPhotoLabel(appeal.actionTitle),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            appeal.actionTitle,
            style: theme.textTheme.titleLarge?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appealsRequirement(
              appeal.requirementTitle,
              proofKindLabel(l10n, appeal.requirementKind),
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
          if (appeal.spokenChallengeWord case final word?
              when word.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.reviewListenFor(word),
              style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.appealsReasonHeading,
            style: theme.textTheme.labelMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
          const SizedBox(height: 4),
          // The participant's own words, quoted on the review wash.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: VerilyRoughDecoration(
              color: palette.reviewWash,
              outline: palette.review,
              radius: VerilyRadius.chip,
              strokeWidth: 2,
              seed: seed + 1000,
            ),
            child: Text(
              appeal.reason,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: theme.textTheme.labelLarge?.copyWith(color: palette.ink),
          ),
          if (appeal.resolutionNote case final note?
              when note.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          ],
          if (appeal.status == EvidenceAppealStatus.pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: VerilyActionButton(
                    key: VerilyTestKeys.appealReject(id),
                    label: l10n.appealsReject,
                    tone: VerilyActionTone.secondary,
                    onPressed: () =>
                        unawaited(resolve(EvidenceAppealStatus.rejected)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VerilyActionButton(
                    key: VerilyTestKeys.appealAccept(id),
                    label: l10n.appealsAccept,
                    onPressed: () =>
                        unawaited(resolve(EvidenceAppealStatus.accepted)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
