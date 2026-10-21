import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSlider;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/core/token_amount.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/features/create/editor/editor_labels.dart';
import 'package:verily_flutter/features/create/editor/widgets/editor_common.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The escrowed reward: what one completion pays, how many payouts there
/// are, and when unused funds come back, with the whole budget the creator
/// locks written out as they type.
class RewardSection extends HookWidget {
  const RewardSection({required this.form, super.key});

  final EditorForm form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reward = form.reward;
    useListenable(form);

    return EditorSection(
      title: l10n.editorRewardHeading,
      help: l10n.editorRewardHelp,
      children: [
        EditorSwitchRow(
          key: VerilyTestKeys.editorRewardToggle,
          label: l10n.editorRewardToggle,
          value: reward.enabled,
          onChanged: reward.isLocked
              ? null
              : (value) {
                  reward.enabled = value;
                  form.touch();
                },
        ),
        if (reward.enabled) ...[
          const SizedBox(height: editorStackGap),
          if (reward.isLocked)
            _LockedReward(reward: reward)
          else
            _RewardTerms(form: form),
        ],
      ],
    );
  }
}

class _RewardTerms extends HookWidget {
  const _RewardTerms({required this.form});

  final EditorForm form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final reward = form.reward;
    useListenable(
      Listenable.merge([
        reward.amount,
        reward.maxPayouts,
        reward.maxWinsPerAccount,
      ]),
    );
    Set<RewardInputProblem> problems() => reward.problems(clock.now());
    final budget = reward.budget;
    final winCap = switch (reward.maxPayoutsValue) {
      final payouts?
          when payouts >= 1 && payouts < EditorLimits.maxWinsPerAccount =>
        payouts,
      _ => EditorLimits.maxWinsPerAccount,
    };

    Future<void> pickEnd() async {
      final now = clock.now();
      final last = now.add(EditorLimits.maxRewardLifetime);
      final picked = await showDatePicker(
        context: context,
        initialDate: reward.expiresAt.isBefore(now)
            ? now
            : reward.expiresAt.isAfter(last)
            ? last
            : reward.expiresAt,
        firstDate: now,
        lastDate: last,
      );
      if (picked == null) return;
      reward.expiresAt = picked.copyWith(hour: 23, minute: 59);
      form.touch();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: VerilyTestKeys.editorRewardAmount,
          controller: reward.amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.editorRewardAmountLabel,
            suffixText: DefaultRewardToken.symbol,
          ),
          validator: (_) {
            final found = problems();
            if (found.contains(RewardInputProblem.amountInvalid)) {
              return l10n.editorRewardAmountInvalid;
            }
            if (found.contains(RewardInputProblem.amountTooLarge)) {
              return l10n.editorRewardAmountTooLarge;
            }
            return null;
          },
        ),
        const SizedBox(height: editorStackGap),
        TextFormField(
          key: VerilyTestKeys.editorRewardMaxPayouts,
          controller: reward.maxPayouts,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.editorRewardMaxPayoutsLabel,
          ),
          validator: (_) =>
              problems().contains(RewardInputProblem.maxPayoutsInvalid)
              ? l10n.editorRewardMaxPayoutsInvalid
              : null,
        ),
        const SizedBox(height: editorStackGap),
        TextFormField(
          key: VerilyTestKeys.editorRewardMaxWins,
          controller: reward.maxWinsPerAccount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: l10n.editorRewardMaxWinsLabel),
          validator: (_) =>
              problems().contains(RewardInputProblem.maxWinsInvalid)
              ? l10n.editorRewardMaxWinsInvalid(winCap)
              : null,
        ),
        const SizedBox(height: editorStackGap),
        FormField<void>(
          builder: (field) => EditorDateRow(
            key: VerilyTestKeys.editorRewardEnds,
            label: l10n.editorRewardEndsLabel,
            value: reward.expiresAt,
            onPick: pickEnd,
            errorText: field.errorText,
          ),
          validator: (_) {
            final found = problems();
            if (found.contains(RewardInputProblem.endTooSoon)) {
              return l10n.editorRewardEndTooSoon;
            }
            if (found.contains(RewardInputProblem.endTooLate)) {
              return l10n.editorRewardEndTooLate;
            }
            return null;
          },
        ),
        const SizedBox(height: editorStackGap),
        Text(
          l10n.editorRewardRefundDelay(reward.refundDelayDays),
          style: theme.textTheme.labelLarge?.copyWith(color: palette.ink),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.editorRewardRefundDelayHelp,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
        ),
        // The slider paints its thumb past its own height, so it gets a
        // full touch-sized row instead of overlapping the help above.
        SizedBox(
          height: 48,
          child: WiredSlider(
            key: VerilyTestKeys.editorRewardRefundDelay,
            value: reward.refundDelayDays.toDouble(),
            min: EditorLimits.minRefundDelayDays.toDouble(),
            max: EditorLimits.maxRefundDelayDays.toDouble(),
            divisions:
                EditorLimits.maxRefundDelayDays -
                EditorLimits.minRefundDelayDays,
            semanticLabel: l10n.editorRewardRefundSemantic,
            onChanged: (value) {
              reward.refundDelayDays = value.round();
              form.touch();
              return true;
            },
          ),
        ),
        const SizedBox(height: editorStackGap),
        EditorPanel(
          key: VerilyTestKeys.editorRewardBudget,
          seed: 419,
          fill: palette.rewardWash,
          outline: palette.reward,
          child: Row(
            children: [
              SkribbleIcon(
                data: VerilyIcons.coins,
                size: 24,
                color: palette.reward,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  budget == null
                      ? l10n.editorRewardBudgetIncomplete
                      : l10n.editorRewardBudget(budget.format(l10n.localeName)),
                  style: budget == null
                      ? theme.textTheme.bodyMedium?.copyWith(color: palette.ink)
                      : theme.textTheme.titleMedium?.copyWith(
                          color: palette.ink,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Terms the escrow already holds: shown, never edited.
class _LockedReward extends StatelessWidget {
  const _LockedReward({required this.reward});

  final RewardForm reward;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final material = MaterialLocalizations.of(context);
    final status = reward.lockedStatus!;
    final perPayout = reward.amountPerPayout;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );

    return EditorPanel(
      seed: 421,
      fill: palette.rewardWash,
      outline: palette.reward,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SkribbleIcon(
                data: status == RewardPoolStatus.funded
                    ? VerilyIcons.lock
                    : VerilyIcons.hourglass,
                size: 22,
                color: palette.reward,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lockedRewardStatusName(l10n, status) ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.editorRewardLocked,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
          ),
          if (perPayout != null)
            row(l10n.fundingPerCompletion, perPayout.format(l10n.localeName)),
          if (reward.maxPayoutsValue case final payouts?)
            row(l10n.fundingPayouts, '$payouts'),
          if (reward.budget case final total?)
            row(l10n.fundingTotal, total.format(l10n.localeName)),
          row(l10n.fundingEnds, material.formatMediumDate(reward.expiresAt)),
        ],
      ),
    );
  }
}
