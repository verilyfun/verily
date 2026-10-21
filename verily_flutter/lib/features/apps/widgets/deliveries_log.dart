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
import 'package:verily_flutter/features/apps/apps_providers.dart';
import 'package:verily_flutter/features/apps/widgets/apps_common.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Every call Verily made to the App's webhook, newest first: events it
/// delivered and pull checks it asked, each with how the App's server
/// answered.
///
/// Each row leads with plain words; the event type and the error code the
/// App's own logs will show sit underneath in the code face, labelled.
class AppDeliveriesLog extends ConsumerWidget {
  const AppDeliveriesLog({required this.appId, super.key});

  final UuidValue appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final deliveries = ref.watch(appDeliveriesProvider(appId));

    Future<void> loadMore() async {
      try {
        await ref.read(appDeliveriesProvider(appId).notifier).loadMore();
      } on Object catch (error) {
        debugPrint('Loading older webhook calls failed: $error');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appsDeliveriesFailed)),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppsSectionHeading(l10n.appsDeliveriesHeading),
        const SizedBox(height: 6),
        Text(
          l10n.appsDeliveriesBody,
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: 12),
        ...deliveries.when(
          loading: () => [
            VerilyLoadingPanel(label: l10n.appsDeliveriesLoading),
          ],
          error: (error, _) => [
            VerilyStatePanel.problem(
              title: l10n.appsDeliveriesFailed,
              action: VerilyStateAction(
                label: l10n.dialogRetry,
                onPressed: () => ref.invalidate(appDeliveriesProvider(appId)),
              ),
            ),
          ],
          data: (page) => [
            if (page.items.isEmpty)
              Text(
                l10n.appsDeliveriesEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.mutedInk,
                ),
              ),
            for (final delivery in page.items) ...[
              _DeliveryRow(delivery: delivery),
              const SizedBox(height: 8),
            ],
            if (page.hasMore)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: VerilyActionButton(
                  key: VerilyTestKeys.appsDeliveriesMore,
                  label: l10n.appsDeliveriesMore,
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

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({required this.delivery});

  final AppWebhookDeliveryView delivery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final statusCode = delivery.statusCode;
    final errorCode = delivery.errorCode;
    final eventStatus = delivery.eventStatus;
    final answer = statusCode == null
        ? l10n.appsDeliveryNoAnswer
        : l10n.appsDeliveryHttp(statusCode);
    final muted = theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk);

    return Container(
      key: VerilyTestKeys.appsDelivery(delivery.id.uuid),
      padding: const EdgeInsets.all(12),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.quietPen,
        strokeWidth: 2,
        seed: delivery.id.hashCode & 0x7fffffff,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkribbleIcon(
            data: delivery.succeeded
                ? VerilyIcons.circleCheck
                : VerilyIcons.close,
            color: palette.ink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appsDeliveryEventName(l10n, delivery.eventType),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  delivery.succeeded
                      ? l10n.appsDeliverySucceeded
                      : appsDeliveryProblem(l10n, errorCode, statusCode),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.appsDeliveryDetails(
                    delivery.attemptNumber,
                    answer,
                    delivery.durationMilliseconds,
                  ),
                  style: muted,
                ),
                Text(
                  appsDateTime(l10n, delivery.requestedAt),
                  style: muted,
                ),
                if (eventStatus != null)
                  Text(
                    appsEventStatusLabel(l10n, eventStatus),
                    style: muted,
                  ),
                const SizedBox(height: 4),
                Text(
                  errorCode == null
                      ? l10n.appsDeliveryEvent(delivery.eventType)
                      : l10n.appsDeliveryEventError(
                          delivery.eventType,
                          errorCode,
                        ),
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

/// Plain words for a webhook call's event type.
String appsDeliveryEventName(AppLocalizations l10n, String eventType) =>
    switch (eventType) {
      'attempt.verify' => l10n.appsEventAttemptVerify,
      'attempt.verified' => l10n.appsEventAttemptVerified,
      'attempt.rejected' => l10n.appsEventAttemptRejected,
      'payout.released' => l10n.appsEventPayoutReleased,
      'verification_request.completed' => l10n.appsEventRequestCompleted,
      _ => l10n.appsEventOther,
    };

/// What went wrong with a failed call, in plain words.
String appsDeliveryProblem(
  AppLocalizations l10n,
  String? errorCode,
  int? statusCode,
) => switch (errorCode) {
  'timeout' => l10n.appsDeliveryTimeout,
  'connection_failed' => l10n.appsDeliveryConnectionFailed,
  'tls_failure' => l10n.appsDeliveryTlsFailure,
  'host_not_public' => l10n.appsDeliveryHostNotPublic,
  'invalid_url' => l10n.appsDeliveryInvalidUrl,
  'response_too_large' => l10n.appsDeliveryTooLarge,
  'invalid_response' => l10n.appsDeliveryInvalidResponse,
  'webhook_not_configured' => l10n.appsDeliveryNoWebhook,
  'signing_unavailable' => l10n.appsDeliveryNoSecret,
  _ when statusCode != null => l10n.appsDeliveryRefused(statusCode),
  _ => l10n.appsDeliveryFailedOther,
};

/// Where the event behind a call stands now.
String appsEventStatusLabel(AppLocalizations l10n, AppEventStatus status) =>
    switch (status) {
      AppEventStatus.pending => l10n.appsEventStatusPending,
      AppEventStatus.delivering => l10n.appsEventStatusDelivering,
      AppEventStatus.delivered => l10n.appsEventStatusDelivered,
      AppEventStatus.failed => l10n.appsEventStatusFailed,
    };
