import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/reward_chip.dart';
import 'package:verily_flutter/app/widgets/trust_label.dart';
import 'package:verily_flutter/features/actions/action_labels.dart';
import 'package:verily_flutter/features/do/distance_text.dart';
import 'package:verily_flutter/features/do/proof_kind.dart';
import 'package:verily_flutter/features/do/widgets/action_tag.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// One action in the Do feed: what it asks, who posted it, who vouches for
/// it, the reward, and how far away its place is.
class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.action,
    required this.onTap,
    this.distanceMeters,
    super.key,
  });

  final ActionOpportunity action;
  final VoidCallback onTap;

  /// From the device's approximate position, when the person shared it.
  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final reward = action.reward;
    final attempt = action.myAttempt;
    // Each card keeps its own wobble, fixed by its key, so a filter change
    // never re-rolls the outline of a card that stays visible.
    final seed = action.actionKey.hashCode & 0x7fffffff;

    return Semantics(
      container: true,
      button: true,
      label: action.title,
      child: DecoratedBox(
        key: VerilyTestKeys.doActionCard(action.id.toString()),
        decoration: VerilyRoughDecoration(
          color: palette.surface,
          outline: palette.ink,
          seed: seed,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(VerilyRadius.card),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.doCreatorBy(action.creatorDisplayName),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: palette.mutedInk,
                          ),
                        ),
                      ),
                      if (distanceMeters case final meters?) ...[
                        const SizedBox(width: 8),
                        SkribbleIcon(
                          data: VerilyIcons.nearby,
                          size: 15,
                          color: palette.place,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceText(l10n, meters),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                  if (action.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      action.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.mutedInk,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final kind in proofKindsOf(action))
                        ActionTag(
                          label: kind.label(l10n),
                          icon: kind.icon,
                          tone: kind == ProofKind.place
                              ? VerilyTone.place
                              : VerilyTone.neutral,
                          seed: 47 + kind.index,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TrustLabel(action: action),
                  if (reward != null &&
                      reward.status == RewardPoolStatus.funded) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: RewardChip(reward: reward),
                    ),
                  ],
                  if (attempt != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SkribbleIcon(
                          data: attempt.status == ActionAttemptStatus.verified
                              ? VerilyIcons.verified
                              : VerilyIcons.hourglass,
                          size: 16,
                          color: attempt.status == ActionAttemptStatus.verified
                              ? palette.accent
                              : palette.mutedInk,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.doYourAttempt(
                              attemptStatusLabel(l10n, attempt.status),
                            ),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: palette.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
