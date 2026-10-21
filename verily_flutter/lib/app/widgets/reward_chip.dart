import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/actions/action_labels.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// "5 USDC · in escrow": the payout per completion of an escrowed reward.
///
/// Butter wash with ink text and a gold coin, per DESIGN.md. Shown only for a
/// pool the server reports funded; anything else is not a reward anyone can
/// rely on yet.
class RewardChip extends StatelessWidget {
  const RewardChip({required this.reward, super.key});

  final RewardSummary reward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final amount = payoutAmountOf(reward).format(l10n.localeName);

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: VerilyRoughDecoration(
        color: palette.rewardWash,
        outline: palette.reward,
        radius: VerilyRadius.chip,
        strokeWidth: 2,
        seed: 233,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkribbleIcon(
            data: VerilyIcons.coins,
            size: 20,
            color: palette.reward,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.rewardInEscrow(amount),
              style: theme.textTheme.labelLarge?.copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}
