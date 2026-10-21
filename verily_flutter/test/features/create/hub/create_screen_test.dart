import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/widgets/reward_chip.dart';
import 'package:verily_flutter/app/widgets/trust_label.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/features/create/hub/create_hub_providers.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../apps/support/fakes.dart';
import 'support/fakes.dart';
import 'support/router_harness.dart';

RewardPoolView _pool(RewardPoolStatus status) => RewardPoolView(
  poolId: fixtureId(77),
  status: status,
  cluster: RewardCluster.devnet,
  mint: 'mint',
  tokenSymbol: 'USDC',
  decimals: 6,
  amountPerPayout: 5000000,
  maxPayouts: 20,
  maxWinsPerAccount: 1,
  payoutsReserved: 0,
  payoutsReleased: 0,
  expiresAt: fixtureNow.add(const Duration(days: 30)),
  refundAfter: fixtureNow.add(const Duration(days: 37)),
);

void main() {
  late FakeHubActionRepository actions;
  late FakeAppsRepository apps;
  late List<ActionOpportunity> fundingRequests;
  late RewardPoolView? fundingResult;
  late List<ActionRequirementView> venueRequests;

  setUp(() {
    actions = FakeHubActionRepository();
    apps = FakeAppsRepository();
    fundingRequests = [];
    fundingResult = null;
    venueRequests = [];
  });

  Future<GoRouter> pumpHub(WidgetTester tester) => pumpCreateRoutes(
    tester,
    initialLocation: '/create',
    overrides: [
      actionRepositoryProvider.overrideWithValue(actions),
      appsRepositoryProvider.overrideWithValue(apps),
      rewardFundingLauncherProvider.overrideWithValue((
        context, {
        required action,
      }) async {
        fundingRequests.add(action);
        return fundingResult;
      }),
      venueCodeLauncherProvider.overrideWithValue((
        context, {
        required action,
        required requirement,
      }) async {
        venueRequests.add(requirement);
      }),
    ],
  );

  VerilyActionButton button(WidgetTester tester, Key key) =>
      tester.widget<VerilyActionButton>(find.byKey(key));

  testWidgets('lists the creator actions with status and trust label', (
    tester,
  ) async {
    actions.owned = [
      fixtureOwnedAction(),
      fixtureOwnedAction(
        index: 2,
        title: 'Morning check-in',
        status: ActionDefinitionStatus.draft,
      ),
    ];
    await pumpHub(tester);
    await tester.pumpAndSettle();

    expect(find.text('Ten squats at the park'), findsOneWidget);
    expect(find.text('Morning check-in'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.byType(TrustLabel), findsNWidgets(2));
    expect(find.text('4 verified completions'), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.hubPostAction), findsOneWidget);
  });

  testWidgets('shows an inviting empty state with no actions', (tester) async {
    actions.owned = [];
    await pumpHub(tester);
    await tester.pumpAndSettle();

    expect(find.text('Post your first action'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry and calls again once asked', (
    tester,
  ) async {
    actions.listError = StateError('offline');
    await pumpHub(tester);
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load your actions"), findsOneWidget);
    final calls = actions.listCalls;
    actions.listError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(actions.listCalls, calls + 1);
    expect(find.text('Ten squats at the park'), findsOneWidget);
  });

  testWidgets('publishes a draft at its revision and pauses a live action', (
    tester,
  ) async {
    final draft = fixtureOwnedAction(
      index: 2,
      status: ActionDefinitionStatus.draft,
      revision: 7,
    );
    final live = fixtureOwnedAction();
    actions.owned = [live, draft];
    await pumpHub(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(VerilyTestKeys.hubPublish('${draft.id}')));
    await tester.pumpAndSettle();
    expect(actions.published, [(id: draft.id, revision: 7)]);
    expect(find.text('Ten squats at the park is live.'), findsOneWidget);

    await tester.tap(find.byKey(VerilyTestKeys.hubPause('${live.id}')));
    await tester.pumpAndSettle();
    expect(actions.paused, [(id: live.id, revision: 3)]);
  });

  testWidgets('an unfunded reward opens funding, then publishes once funded', (
    tester,
  ) async {
    final draft = fixtureOwnedAction(
      status: ActionDefinitionStatus.draft,
      reward: fixtureReward(status: RewardPoolStatus.draft),
    );
    actions
      ..owned = [draft]
      ..publishErrors = [
        ActionAuthoringException(
          reason: ActionAuthoringProblem.rewardNotFunded,
          message: 'Fund the reward first.',
        ),
      ];
    fundingResult = _pool(RewardPoolStatus.funded);
    await pumpHub(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(VerilyTestKeys.hubPublish('${draft.id}')));
    await tester.pumpAndSettle();

    expect(fundingRequests.single.id, draft.id);
    expect(actions.published, hasLength(2));
    expect(find.text('Ten squats at the park is live.'), findsOneWidget);
  });

  testWidgets('does not publish when funding comes back unfunded', (
    tester,
  ) async {
    final draft = fixtureOwnedAction(
      status: ActionDefinitionStatus.draft,
      reward: fixtureReward(status: RewardPoolStatus.awaitingFunding),
    );
    actions
      ..owned = [draft]
      ..publishErrors = [
        ActionAuthoringException(
          reason: ActionAuthoringProblem.rewardNotFunded,
          message: 'Fund the reward first.',
        ),
      ];
    fundingResult = _pool(RewardPoolStatus.awaitingFunding);
    await pumpHub(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(VerilyTestKeys.hubPublish('${draft.id}')));
    await tester.pumpAndSettle();

    expect(actions.published, hasLength(1));
    expect(find.text('Your reward is in escrow.'), findsNothing);
  });

  testWidgets('an unfunded reward makes funding the one primary step', (
    tester,
  ) async {
    final draft = fixtureOwnedAction(
      status: ActionDefinitionStatus.draft,
      reward: fixtureReward(status: RewardPoolStatus.draft),
    );
    actions.owned = [draft];
    await pumpHub(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('The reward needs funding before this action can go live.'),
      findsOneWidget,
    );
    expect(find.byType(RewardChip), findsNothing);
    final id = '${draft.id}';
    expect(
      button(tester, VerilyTestKeys.hubFund(id)).tone,
      VerilyActionTone.primary,
    );
    expect(
      button(tester, VerilyTestKeys.hubPublish(id)).tone,
      VerilyActionTone.secondary,
    );

    fundingResult = _pool(RewardPoolStatus.funded);
    await tester.tap(find.byKey(VerilyTestKeys.hubFund(id)));
    await tester.pumpAndSettle();
    expect(fundingRequests, hasLength(1));
    expect(find.text('Your reward is in escrow.'), findsOneWidget);
  });

  testWidgets('a funded reward shows its escrow chip and what remains', (
    tester,
  ) async {
    actions.owned = [fixtureOwnedAction(reward: fixtureReward())];
    await pumpHub(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RewardChip), findsOneWidget);
    expect(find.text('5 USDC · in escrow'), findsOneWidget);
    expect(find.text('12 rewards left'), findsOneWidget);
  });

  testWidgets('offers the venue code only on a live venue-code action', (
    tester,
  ) async {
    final qr = fixtureRequirement(kind: ActionRequirementKind.qrCode);
    final live = fixtureOwnedAction(requirements: [qr]);
    final draft = fixtureOwnedAction(
      index: 2,
      status: ActionDefinitionStatus.draft,
      requirements: [fixtureRequirement(kind: ActionRequirementKind.qrCode)],
    );
    actions.owned = [live, draft];
    await pumpHub(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(VerilyTestKeys.hubVenueCode('${draft.id}')),
      findsNothing,
    );
    await tester.tap(find.byKey(VerilyTestKeys.hubVenueCode('${live.id}')));
    await tester.pump();
    expect(venueRequests.single.id, qr.id);
  });

  testWidgets('opens the editor, the participant view, Apps, and appeals', (
    tester,
  ) async {
    final action = fixtureOwnedAction();
    actions.owned = [action];
    final router = await pumpHub(tester);
    await tester.pumpAndSettle();
    Future<void> back() async {
      router.pop();
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(VerilyTestKeys.hubPostAction));
    await tester.pumpAndSettle();
    expect(find.text('editor: new'), findsOneWidget);
    await back();

    await tester.tap(find.byKey(VerilyTestKeys.hubEdit('${action.id}')));
    await tester.pumpAndSettle();
    expect(find.text('editor: ${action.id}'), findsOneWidget);
    await back();

    await tester.tap(find.byKey(VerilyTestKeys.hubView('${action.id}')));
    await tester.pumpAndSettle();
    expect(find.text('action: ${action.id}'), findsOneWidget);
    await back();

    expect(find.text('1 App confirms actions for you.'), findsOneWidget);
    await tester.tap(find.text('Manage Apps'));
    await tester.pumpAndSettle();
    expect(find.text('Registered Apps'), findsOneWidget);
    await back();

    await tester.scrollUntilVisible(find.text('Open appeals'), 200);
    await tester.tap(find.text('Open appeals'));
    await tester.pumpAndSettle();
    expect(find.text('appeals'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a Seeker phone with large text ($brightness)', (
      tester,
    ) async {
      actions.owned = [
        fixtureOwnedAction(
          title: 'Ten squats at the park every single morning this month',
          reward: fixtureReward(),
          requirements: [
            fixtureRequirement(kind: ActionRequirementKind.qrCode),
          ],
        ),
        fixtureOwnedAction(
          index: 2,
          status: ActionDefinitionStatus.draft,
          reward: fixtureReward(status: RewardPoolStatus.draft),
        ),
      ];
      await pumpCreateRoutes(
        tester,
        initialLocation: '/create',
        physicalSize: seekerPhysicalSize,
        devicePixelRatio: seekerPixelRatio,
        textScale: 1.3,
        brightness: brightness,
        overrides: [
          actionRepositoryProvider.overrideWithValue(actions),
          appsRepositoryProvider.overrideWithValue(apps),
        ],
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
