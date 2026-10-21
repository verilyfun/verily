import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/me/me_providers.dart';
import 'package:verily_flutter/features/me/widgets/attempt_tile.dart';
import 'package:verily_flutter/features/me/widgets/payout_tile.dart';
import 'package:verily_flutter/features/me/widgets/payout_wallet_card.dart';
import 'package:verily_flutter/features/me/widgets/pushed_page.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The Me tab: where rewards go, what was paid, every attempt, and the way
/// to settings, review, and appeals.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).verily;
    final l10n = context.l10n;
    final canReview = ref.watch(
      accountSessionProvider.select((session) => session.canReviewEvidence),
    );
    final wallet = ref.watch(myPayoutWalletProvider);
    final payouts = ref.watch(myPayoutsProvider);
    final attempts = ref.watch(myAttemptsProvider);

    Future<void> refresh() async {
      ref
        ..invalidate(myPayoutWalletProvider)
        ..invalidate(myPayoutsProvider)
        ..invalidate(myAttemptsProvider);
      try {
        await Future.wait([
          ref.read(myPayoutWalletProvider.future),
          ref.read(myPayoutsProvider.future),
          ref.read(myAttemptsProvider.future),
        ]);
      } on Object catch (error) {
        // Each section shows its own problem with a retry; the pull only
        // needs to end.
        debugPrint('Refreshing Me failed: $error');
      }
    }

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerilyAppHeader(
            title: l10n.meTitle,
            subtitle: l10n.meSubtitle,
            trailing: IconButton(
              key: VerilyTestKeys.meSettingsButton,
              tooltip: l10n.settingsOpenTooltip,
              onPressed: () => context.pushNamed(VerilyRouteNames.settings),
              icon: const SkribbleIcon(data: VerilyIcons.settings),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  ...wallet.when(
                    loading: () => [const SizedBox.shrink()],
                    error: (error, _) => [
                      _SectionProblem(
                        error: error,
                        onRetry: () => ref.invalidate(myPayoutWalletProvider),
                      ),
                    ],
                    data: (linked) => [PayoutWalletCard(wallet: linked)],
                  ),
                  const SizedBox(height: 24),
                  SectionHeading(l10n.mePayoutsTitle),
                  const SizedBox(height: 12),
                  ...payouts.when(
                    loading: () => [
                      VerilyLoadingPanel(label: l10n.meLoadingPayouts),
                    ],
                    error: (error, _) => [
                      _SectionProblem(
                        error: error,
                        onRetry: () => ref.invalidate(myPayoutsProvider),
                      ),
                    ],
                    data: (items) => items.isEmpty
                        ? [_Quiet(l10n.mePayoutsEmpty)]
                        : [
                            for (final (index, payout) in items.indexed) ...[
                              if (index > 0) const SizedBox(height: 12),
                              PayoutTile(payout: payout, seed: 291 + index),
                            ],
                          ],
                  ),
                  const SizedBox(height: 24),
                  SectionHeading(l10n.meAttemptsTitle),
                  const SizedBox(height: 12),
                  ...attempts.when(
                    loading: () => [
                      VerilyLoadingPanel(label: l10n.meLoadingAttempts),
                    ],
                    error: (error, _) => [
                      _SectionProblem(
                        error: error,
                        onRetry: () => ref.invalidate(myAttemptsProvider),
                      ),
                    ],
                    data: (items) => items.isEmpty
                        ? [_Quiet(l10n.meAttemptsEmpty)]
                        : [
                            for (final (index, item) in items.indexed) ...[
                              if (index > 0) const SizedBox(height: 12),
                              AttemptTile(item: item, seed: 311 + index),
                            ],
                          ],
                  ),
                  const SizedBox(height: 24),
                  _LinkRow(
                    key: VerilyTestKeys.meLinkSettings,
                    icon: VerilyIcons.settings,
                    label: l10n.settingsTitle,
                    seed: 331,
                    onTap: () => context.pushNamed(VerilyRouteNames.settings),
                  ),
                  const SizedBox(height: 12),
                  _LinkRow(
                    key: VerilyTestKeys.meLinkAppeals,
                    icon: VerilyIcons.review,
                    label: l10n.meLinkAppeals,
                    seed: 333,
                    onTap: () => context.pushNamed(VerilyRouteNames.appeals),
                  ),
                  if (canReview) ...[
                    const SizedBox(height: 12),
                    _LinkRow(
                      key: VerilyTestKeys.meLinkReview,
                      icon: VerilyIcons.checklist,
                      label: l10n.meLinkReview,
                      seed: 335,
                      onTap: () => context.pushNamed(VerilyRouteNames.reviews),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.verily.mutedInk,
      ),
    );
  }
}

class _SectionProblem extends StatelessWidget {
  const _SectionProblem({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    debugPrint('A Me section failed to load: $error');
    return VerilyStatePanel.problem(
      title: l10n.meLoadFailedTitle,
      message: userMessageFor(l10n, error),
      action: VerilyStateAction(label: l10n.dialogRetry, onPressed: onRetry),
    );
  }
}

/// A row that opens another page.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.seed,
    required this.onTap,
    super.key,
  });

  final WiredSvgIconData icon;
  final String label;
  final int seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(VerilyRadius.card),
          onTap: onTap,
          child: Ink(
            decoration: VerilyRoughDecoration(
              color: palette.surface,
              outline: palette.quietPen,
              strokeWidth: 2,
              seed: seed,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SkribbleIcon(data: icon, size: 22, color: palette.ink),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: palette.ink,
                        ),
                      ),
                    ),
                    SkribbleIcon(
                      data: VerilyIcons.chevronRight,
                      size: 20,
                      color: palette.mutedInk,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
