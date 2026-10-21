import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/token_amount.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// Plain words for an attempt's [status].
String attemptStatusLabel(AppLocalizations l10n, ActionAttemptStatus status) =>
    switch (status) {
      ActionAttemptStatus.collectingEvidence =>
        l10n.attemptStatusCollectingEvidence,
      ActionAttemptStatus.verifying => l10n.attemptStatusVerifying,
      ActionAttemptStatus.pendingReview => l10n.attemptStatusPendingReview,
      ActionAttemptStatus.verified => l10n.attemptStatusVerified,
      ActionAttemptStatus.rejected => l10n.attemptStatusRejected,
      ActionAttemptStatus.capacityReached => l10n.attemptStatusCapacityReached,
    };

/// What happens to a payout of [amount], in plain words.
String payoutStatusLabel(
  AppLocalizations l10n,
  RewardPayoutStatus status,
  String amount,
) => switch (status) {
  RewardPayoutStatus.reserved ||
  RewardPayoutStatus.releasing => l10n.payoutOnItsWay(amount),
  RewardPayoutStatus.awaitingWallet => l10n.payoutAwaitingWallet(amount),
  RewardPayoutStatus.heldForReview => l10n.payoutHeldForReview(amount),
  RewardPayoutStatus.released => l10n.payoutReleased(amount),
  RewardPayoutStatus.failed => l10n.payoutFailed(amount),
  RewardPayoutStatus.expired => l10n.payoutExpired(amount),
};

/// Why a verified attempt earned nothing, or null when it won (or the action
/// has no reward).
String? rewardOutcomeNote(AppLocalizations l10n, RewardOutcome? outcome) =>
    switch (outcome) {
      null || RewardOutcome.won => null,
      RewardOutcome.poolEmpty => l10n.rewardOutcomePoolEmpty,
      RewardOutcome.accountLimitReached => l10n.rewardOutcomeAccountLimit,
      RewardOutcome.poolEnded => l10n.rewardOutcomePoolEnded,
    };

/// One payout of [reward], such as `5 USDC`.
TokenAmount payoutAmountOf(RewardSummary reward) => TokenAmount(
  atoms: reward.amountPerPayout,
  decimals: reward.decimals,
  symbol: reward.tokenSymbol,
);

/// The App that confirms [action], or null when its proof is captured on the
/// phone. A v1 action is one or the other, never both.
String? confirmingAppName(ActionOpportunity action) {
  for (final requirement in action.requirements) {
    if (requirement.kind == ActionRequirementKind.externalApp) {
      return requirement.appName ?? '';
    }
  }
  return null;
}
