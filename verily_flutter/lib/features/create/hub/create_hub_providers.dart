import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/create/funding/reward_funding_sheet.dart';
import 'package:verily_flutter/features/create/venue_code/venue_code_sheet.dart';

/// The creator's own actions, latest revision of each.
final FutureProvider<List<ActionOpportunity>> createHubActionsProvider =
    FutureProvider.autoDispose(
      (ref) => ref.watch(actionRepositoryProvider).listOwned(),
    );

/// Opens the reward funding flow for an action. A provider so tests can
/// replace the real sheet, which talks to a wallet.
typedef RewardFundingLauncher = Future<RewardPoolView?> Function(
  BuildContext context, {
  required ActionOpportunity action,
});

final rewardFundingLauncherProvider = Provider<RewardFundingLauncher>(
  (ref) => showRewardFunding,
);

/// Opens the rotating venue code for a QR requirement.
typedef VenueCodeLauncher = Future<void> Function(
  BuildContext context, {
  required ActionOpportunity action,
  required ActionRequirementView requirement,
});

final venueCodeLauncherProvider = Provider<VenueCodeLauncher>(
  (ref) => showVenueCode,
);

/// Whether [reward] still has to be locked in escrow before the action can
/// go live.
bool rewardNeedsFunding(RewardSummary? reward) => switch (reward?.status) {
  RewardPoolStatus.draft || RewardPoolStatus.awaitingFunding => true,
  null ||
  RewardPoolStatus.funded ||
  RewardPoolStatus.ended ||
  RewardPoolStatus.closed => false,
};

/// The venue-code requirement of a live [action], if it has one.
ActionRequirementView? venueCodeRequirementOf(ActionOpportunity action) {
  if (action.status != ActionDefinitionStatus.active) return null;
  for (final requirement in action.requirements) {
    if (requirement.kind == ActionRequirementKind.qrCode) return requirement;
  }
  return null;
}
