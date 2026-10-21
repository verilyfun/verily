import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';

/// A fixed id for fixtures, distinct per [index].
UuidValue fixtureId(int index) => UuidValue.fromString(
  '00000000-0000-4000-8000-${index.toRadixString(16).padLeft(12, '0')}',
);

final fixtureNow = DateTime.utc(2026, 10, 21, 14);

ActionRequirementView fixtureRequirement({
  int index = 1,
  ActionRequirementKind kind = ActionRequirementKind.location,
  UuidValue? appId,
  String? appName,
}) => ActionRequirementView(
  id: fixtureId(1000 + index),
  requirementKey: 'requirement-$index',
  kind: kind,
  title: switch (kind) {
    ActionRequirementKind.location => 'Be at the park',
    ActionRequirementKind.qrCode => 'Scan the code at the counter',
    ActionRequirementKind.externalApp => 'Check in with the club app',
    _ => 'Record the moment',
  },
  instructions: 'Follow the steps on the action.',
  position: index,
  isRequired: true,
  latitude: kind == ActionRequirementKind.location ? 51.5072 : null,
  longitude: kind == ActionRequirementKind.location ? -0.1276 : null,
  radiusMeters: kind == ActionRequirementKind.location ? 150 : null,
  appId: appId,
  appName: appName,
);

RewardSummary fixtureReward({
  RewardPoolStatus status = RewardPoolStatus.funded,
  int amountPerPayout = 5000000,
  int maxPayouts = 20,
  int payoutsRemaining = 12,
}) => RewardSummary(
  cluster: RewardCluster.devnet,
  mint: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
  tokenSymbol: 'USDC',
  decimals: 6,
  amountPerPayout: amountPerPayout,
  maxPayouts: maxPayouts,
  payoutsRemaining: payoutsRemaining,
  maxWinsPerAccount: 1,
  myWins: 0,
  status: status,
  expiresAt: fixtureNow.add(const Duration(days: 30)),
);

ActionOpportunity fixtureOwnedAction({
  int index = 1,
  String title = 'Ten squats at the park',
  ActionDefinitionStatus status = ActionDefinitionStatus.active,
  int revision = 3,
  RewardSummary? reward,
  List<ActionRequirementView>? requirements,
  int verifiedCompletions = 4,
}) => ActionOpportunity(
  id: fixtureId(index),
  creatorDisplayName: 'Ada',
  viewerIsCreator: true,
  actionKey: 'action-$index',
  revision: revision,
  status: status,
  title: title,
  description: 'Do ten squats where the pin is.',
  recurrence: ActionRecurrence.daily,
  timeZone: 'Europe/London',
  verifiedCompletions: verifiedCompletions,
  updatedAt: fixtureNow,
  requirements: requirements ?? [fixtureRequirement()],
  reward: reward,
);

/// An [ActionRepository] for the Create hub: owned actions, publish, pause.
class FakeHubActionRepository implements ActionRepository {
  FakeHubActionRepository({
    List<ActionOpportunity>? owned,
    this.publishErrors = const [],
  }) : owned = owned ?? [fixtureOwnedAction()];

  List<ActionOpportunity> owned;

  /// Errors thrown by successive publish calls; after they run out, publish
  /// succeeds.
  List<Object> publishErrors;

  /// When set, `listOwned` throws it.
  Object? listError;

  int listCalls = 0;
  final published = <({UuidValue id, int revision})>[];
  final paused = <({UuidValue id, int revision})>[];

  @override
  Future<List<ActionOpportunity>> listOwned() async {
    listCalls++;
    if (listError case final error?) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
    return owned;
  }

  @override
  Future<ActionOpportunity> publish(ActionOpportunity action) async {
    published.add((id: action.id, revision: action.revision));
    if (published.length <= publishErrors.length) {
      Error.throwWithStackTrace(
        publishErrors[published.length - 1],
        StackTrace.current,
      );
    }
    return action.copyWith(status: ActionDefinitionStatus.active);
  }

  @override
  Future<ActionOpportunity> pause(ActionOpportunity action) async {
    paused.add((id: action.id, revision: action.revision));
    return action.copyWith(status: ActionDefinitionStatus.paused);
  }

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked here.');
}
