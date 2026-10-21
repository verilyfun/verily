import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/core/token_amount.dart';
import 'package:verily_flutter/features/actions/action_labels.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// One payout: the action, the exact amount, and what is happening to it.
class PayoutTile extends StatelessWidget {
  const PayoutTile({required this.payout, required this.seed, super.key});

  final RewardPayoutView payout;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final amount = TokenAmount(
      atoms: payout.amount,
      decimals: payout.decimals,
      symbol: payout.tokenSymbol,
    ).format(l10n.localeName);
    final awaitingWallet = payout.status == RewardPayoutStatus.awaitingWallet;

    return Container(
      key: VerilyTestKeys.mePayout(payout.id.toString()),
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: awaitingWallet ? palette.rewardWash : palette.surface,
        outline: palette.quietPen,
        strokeWidth: 2,
        seed: seed,
      ),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SkribbleIcon(
                data: VerilyIcons.coins,
                size: 22,
                color: palette.reward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payout.actionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payoutStatusLabel(l10n, payout.status, amount),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                  if (awaitingWallet) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.mePayoutPayableUntil(
                        DateFormat.yMMMd(
                          l10n.localeName,
                        ).format(payout.payableUntil.toLocal()),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
