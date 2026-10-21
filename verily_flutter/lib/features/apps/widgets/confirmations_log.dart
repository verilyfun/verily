import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/features/actions/action_labels.dart';
import 'package:verily_flutter/features/apps/apps_providers.dart';
import 'package:verily_flutter/features/apps/widgets/apps_common.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Every confirmation an App sent, newest first, with what Verily made of it.
///
/// Each row leads with the outcome and a plain reason. App owners are
/// developers wiring up an API, so the response code their server receives
/// is shown underneath in the code face, labelled as such, for matching
/// logs; it never replaces the plain reason.
class AppConfirmationsLog extends ConsumerWidget {
  const AppConfirmationsLog({required this.appId, super.key});

  final UuidValue appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final confirmations = ref.watch(appConfirmationsProvider(appId));

    Future<void> loadMore() async {
      try {
        await ref.read(appConfirmationsProvider(appId).notifier).loadMore();
      } on Object catch (error) {
        debugPrint('Loading older confirmations failed: $error');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appsConfirmationsFailed)),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppsSectionHeading(l10n.appsConfirmationsHeading),
        const SizedBox(height: 12),
        ...confirmations.when(
          loading: () => [
            VerilyLoadingPanel(label: l10n.appsConfirmationsLoading),
          ],
          error: (error, _) => [
            VerilyStatePanel.problem(
              title: l10n.appsConfirmationsFailed,
              action: VerilyStateAction(
                label: l10n.dialogRetry,
                onPressed: () =>
                    ref.invalidate(appConfirmationsProvider(appId)),
              ),
            ),
          ],
          data: (page) => [
            if (page.items.isEmpty)
              Text(
                l10n.appsConfirmationsEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.mutedInk,
                ),
              ),
            for (final confirmation in page.items) ...[
              _ConfirmationRow(confirmation: confirmation),
              const SizedBox(height: 8),
            ],
            if (page.hasMore)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: VerilyActionButton(
                  key: VerilyTestKeys.appsConfirmationsMore,
                  label: l10n.appsConfirmationsMore,
                  tone: VerilyActionTone.secondary,
                  expand: false,
                  isLoading: page.loadingMore,
                  leading: const SkribbleIcon(data: VerilyIcons.chevronDown),
                  onPressed: () => unawaited(loadMore()),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.confirmation});

  final AppConfirmationView confirmation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final accepted = confirmation.outcome == AppConfirmationOutcome.accepted;
    final attemptStatus = confirmation.attemptStatus;

    return Container(
      key: VerilyTestKeys.appsConfirmation(confirmation.eventId),
      padding: const EdgeInsets.all(12),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.quietPen,
        strokeWidth: 2,
        seed: confirmation.eventId.hashCode & 0x7fffffff,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkribbleIcon(
            data: accepted ? VerilyIcons.circleCheck : VerilyIcons.close,
            color: palette.ink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accepted
                      ? l10n.appsConfirmationAccepted
                      : l10n.appsConfirmationRejected,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appsConfirmationReason(l10n, confirmation.reasonCode),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.appsConfirmationEvent(
                    confirmation.eventId,
                    confirmation.actionKey,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
                Text(
                  l10n.appsConfirmationReceived(
                    appsDateTime(l10n, confirmation.receivedAt),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
                if (attemptStatus != null)
                  Text(
                    l10n.appsConfirmationAttempt(
                      attemptStatusLabel(l10n, attemptStatus),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.mutedInk,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  l10n.appsConfirmationCode(confirmation.reasonCode),
                  style: appsCodeStyle(
                    context,
                    base: theme.textTheme.labelSmall,
                  )?.copyWith(color: palette.mutedInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
