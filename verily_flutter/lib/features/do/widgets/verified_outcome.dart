import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_brand/verily_brand.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/features/actions/action_labels.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// A verified attempt: the stamp, pressed once onto proof that passed, and
/// what happens to the reward.
///
/// The stamp slams only when the verification arrived while this page was
/// open; a restored result shows it settled. Reduced motion always shows it
/// settled (the stamp reads the Skribble motion setting).
class VerifiedOutcome extends HookWidget {
  const VerifiedOutcome({
    required this.attempt,
    required this.reward,
    required this.celebrate,
    super.key,
  });

  final ActionAttemptView attempt;
  final RewardSummary? reward;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final slam = useAnimationController(
      duration: const Duration(milliseconds: 900),
      initialValue: celebrate ? 0 : 1,
    );
    useEffect(() {
      if (celebrate) slam.forward();
      return null;
    }, [celebrate]);
    final pressed = useAnimation(slam);

    final payoutStatus = attempt.payoutStatus;
    final amount = reward == null
        ? null
        : payoutAmountOf(reward!).format(l10n.localeName);
    final note = rewardOutcomeNote(l10n, attempt.rewardOutcome);

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: VerilyTestKeys.actionVerifiedOutcome,
        padding: const EdgeInsets.all(16),
        decoration: VerilyRoughDecoration(
          color: palette.surface,
          outline: palette.ink,
          seed: 263,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: VerifiedStamp(
                size: 128,
                color: palette.accent,
                pressed: pressed,
                semanticLabel: l10n.attemptStatusVerified,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.actionVerifiedTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.actionVerifiedBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.mutedInk,
              ),
            ),
            if (payoutStatus != null && amount != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: VerilyRoughDecoration(
                  color: palette.rewardWash,
                  outline: palette.reward,
                  radius: VerilyRadius.chip,
                  strokeWidth: 2,
                  seed: 269,
                ),
                child: Row(
                  children: [
                    SkribbleIcon(
                      data: VerilyIcons.coins,
                      size: 20,
                      color: palette.reward,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payoutStatusLabel(l10n, payoutStatus, amount),
                        key: VerilyTestKeys.actionPayoutStatus,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: palette.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (payoutStatus == RewardPayoutStatus.awaitingWallet) ...[
                const SizedBox(height: 12),
                VerilyActionButton(
                  key: VerilyTestKeys.actionAddWallet,
                  label: l10n.actionAddWallet,
                  leading: const SkribbleIcon(data: VerilyIcons.wallet),
                  onPressed: () => context.go(VerilyRoutePaths.me),
                ),
              ],
              if (payoutStatus == RewardPayoutStatus.heldForReview) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.actionPayoutHeldBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
              ],
            ],
            if (note != null) ...[
              const SizedBox(height: 12),
              Text(
                note,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedInk,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
