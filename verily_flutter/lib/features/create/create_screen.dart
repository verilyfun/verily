import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/features/apps/apps_providers.dart';
import 'package:verily_flutter/features/apps/widgets/apps_common.dart';
import 'package:verily_flutter/features/create/hub/create_hub_providers.dart';
import 'package:verily_flutter/features/create/hub/owned_action_card.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The Create tab: your actions, their rewards, and your Verily Apps.
///
/// The page leads with its one primary step, posting an action, then lists
/// the creator's actions with what each needs next.
class CreateScreen extends ConsumerWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = Theme.of(context).verily;
    final actions = ref.watch(createHubActionsProvider);

    // The editor may have saved or published; show what it left behind.
    Future<void> postAction() async {
      await context.push(VerilyRoutePaths.actionNew);
      if (context.mounted) ref.invalidate(createHubActionsProvider);
    }

    Future<void> refresh() async {
      ref
        ..invalidate(createHubActionsProvider)
        ..invalidate(verilyAppsProvider);
      await ref
          .read(createHubActionsProvider.future)
          .catchError(
            // The list shows its own problem state; the pull just ends.
            (Object _) => const <ActionOpportunity>[],
          );
    }

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerilyAppHeader(title: l10n.hubTitle, subtitle: l10n.hubSubtitle),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gutter = math.max(
                    appsPageGutter,
                    (constraints.maxWidth - appsMaxContentWidth) / 2,
                  );
                  return RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
                      children: [
                        VerilyActionButton(
                          key: VerilyTestKeys.hubPostAction,
                          label: l10n.hubPostAction,
                          leading: const SkribbleIcon(data: VerilyIcons.plus),
                          onPressed: postAction,
                        ),
                        const SizedBox(height: 24),
                        AppsSectionHeading(l10n.hubActionsHeading),
                        const SizedBox(height: 12),
                        ...actions.when(
                          loading: () => [
                            VerilyLoadingPanel(label: l10n.hubLoading),
                          ],
                          error: (error, _) => [
                            VerilyStatePanel.problem(
                              title: l10n.hubLoadFailedTitle,
                              message: l10n.errorGeneric,
                              action: VerilyStateAction(
                                label: l10n.dialogRetry,
                                onPressed: () =>
                                    ref.invalidate(createHubActionsProvider),
                              ),
                            ),
                          ],
                          data: (items) => [
                            if (items.isEmpty)
                              VerilyStatePanel.empty(
                                title: l10n.hubEmptyTitle,
                                message: l10n.hubEmptyBody,
                              ),
                            for (final action in items) ...[
                              OwnedActionCard(action: action),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        const _AppsSummary(),
                        const SizedBox(height: 12),
                        _LinkPanel(
                          key: VerilyTestKeys.hubAppeals,
                          heading: l10n.hubAppealsHeading,
                          body: l10n.hubAppealsBody,
                          label: l10n.hubAppealsOpen,
                          onPressed: () => unawaited(
                            context.push(VerilyRoutePaths.appeals),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// How many Apps confirm actions for the creator, and the way to them.
class _AppsSummary extends ConsumerWidget {
  const _AppsSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final apps = ref.watch(verilyAppsProvider);
    final activeCount = apps.value
        ?.where((app) => app.status == VerilyAppStatus.active)
        .length;

    return _LinkPanel(
      key: VerilyTestKeys.hubApps,
      heading: l10n.hubAppsHeading,
      body: activeCount == null
          ? l10n.hubAppsIntro
          : l10n.hubAppsBody(activeCount),
      label: l10n.hubAppsOpen,
      onPressed: () => unawaited(context.push(VerilyRoutePaths.apps)),
    );
  }
}

class _LinkPanel extends StatelessWidget {
  const _LinkPanel({
    required this.heading,
    required this.body,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String heading;
  final String body;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return AppsPanel(
      seed: heading.hashCode & 0x7fffffff,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppsSectionHeading(heading),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
          const SizedBox(height: 12),
          VerilyActionButton(
            label: label,
            tone: VerilyActionTone.secondary,
            expand: false,
            leading: const SkribbleIcon(data: VerilyIcons.chevronRight),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
