// Renders the app's main screens through the real router and tab shell at
// the Solana Seeker's portrait size, with the real Skribble faces, in light
// and dark. Every repository is a fake, so nothing reaches a server, a
// wallet, a plugin, or a native map.
//
// Every run asserts the screens lay out without errors. To also write PNGs
// for review into `.screenshots/phase-b/` (ignored by git):
//
//   flutter test --dart-define=VERILY_SCREENSHOTS=true \
//     test/screenshots/phase_b_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/app_router.dart';
import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/core/provider_retry.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/features/rewards/reward_repository.dart';
import 'package:verily_flutter/features/wallet/mobile_wallet.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../features/apps/support/fakes.dart' as apps;
import '../features/create/editor/support/fakes.dart' as editor;
import '../features/create/hub/support/fakes.dart' as hub;
import '../features/do/support/fakes.dart' as doing;
import '../features/me/support/fakes.dart' as me;
import '../support/skribble_faces.dart';
import '../support/test_app.dart';

const _writeScreenshots = bool.fromEnvironment('VERILY_SCREENSHOTS');
const _outputDirectory = '.screenshots/phase-b';
const _seekerPhysicalSize = Size(1080, 2400);
const _seekerPixelRatio = 2.625;

void main() {
  setUpAll(loadSkribbleFaces);

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    group('signed out ($theme)', () {
      testWidgets('welcome', (tester) async {
        await _pumpApp(
          tester,
          location: VerilyRoutePaths.welcome,
          session: const AccountSession.signedOut(),
          brightness: brightness,
        );
        await _capture(tester, 'welcome-$theme');
      });

      testWidgets('sign in', (tester) async {
        await _pumpApp(
          tester,
          location: VerilyRoutePaths.signIn,
          session: const AccountSession.signedOut(),
          brightness: brightness,
        );
        await _capture(tester, 'sign-in-$theme');
      });
    });

    group('Do ($theme)', () {
      testWidgets('feed and map', (tester) async {
        final feed = _feed();
        // Each card shows its own words, so a review can tell them apart.
        expect(
          feed.map((action) => action.description).toSet(),
          hasLength(feed.length),
        );
        final fakes = doing.DoFakes(
          actions: doing.FakeActionRepository(available: feed),
        );
        await _pumpApp(
          tester,
          location: VerilyRoutePaths.doTab,
          overrides: fakes.overrides,
          brightness: brightness,
        );
        await _capture(tester, 'do-feed-$theme');

        await tester.tap(find.byKey(VerilyTestKeys.doViewToggle));
        await _settle(tester);
        await _capture(tester, 'do-map-$theme');
      });

      testWidgets('an action before starting', (tester) async {
        final action = doing.actionFixture(
          id: 1,
          requirements: [
            doing.placeRequirement(),
            doing.venueCodeRequirement(),
            doing.videoRequirement(),
          ],
          reward: doing.rewardFixture(),
        );
        final fakes = doing.DoFakes(
          actions: doing.FakeActionRepository(available: [action]),
        );
        await _pumpApp(
          tester,
          location: '/actions/${action.id}',
          overrides: fakes.overrides,
          brightness: brightness,
        );
        await _capture(tester, 'action-$theme');
      });

      testWidgets('a verified action that paid', (tester) async {
        final action = doing.actionFixture(
          id: 1,
          reward: doing.rewardFixture(),
          myAttempt: doing.attemptFixture(
            actionId: 1,
            status: ActionAttemptStatus.verified,
            accepted: [doing.placeRequirement().id],
            payoutStatus: RewardPayoutStatus.released,
            rewardOutcome: RewardOutcome.won,
          ),
        );
        final fakes = doing.DoFakes(
          actions: doing.FakeActionRepository(available: [action]),
        );
        await _pumpApp(
          tester,
          location: '/actions/${action.id}',
          overrides: fakes.overrides,
          brightness: brightness,
        );
        await _capture(tester, 'action-verified-$theme');
      });
    });

    group('Create ($theme)', () {
      testWidgets('hub and reward funding', (tester) async {
        final draft = hub.fixtureOwnedAction(
          index: 2,
          title: 'Sunrise at the bridge',
          status: ActionDefinitionStatus.draft,
          reward: hub.fixtureReward(status: RewardPoolStatus.awaitingFunding),
        );
        final live = hub.fixtureOwnedAction(reward: hub.fixtureReward());
        await _pumpApp(
          tester,
          location: VerilyRoutePaths.create,
          overrides: [
            actionRepositoryProvider.overrideWithValue(
              hub.FakeHubActionRepository(owned: [draft, live]),
            ),
            appsRepositoryProvider.overrideWithValue(
              apps.FakeAppsRepository(),
            ),
            rewardRepositoryProvider.overrideWithValue(
              editor.FakeRewardRepository(),
            ),
            payoutWalletRepositoryProvider.overrideWithValue(
              editor.FakePayoutWalletRepository(
                wallet: editor.linkedWalletFixture(),
              ),
            ),
            mobileWalletProvider.overrideWithValue(editor.FakeMobileWallet()),
          ],
          brightness: brightness,
        );
        await _capture(tester, 'create-hub-$theme');

        final fund = find.byKey(VerilyTestKeys.hubFund(draft.id.toString()));
        await tester.ensureVisible(fund);
        await _settle(tester);
        await tester.tap(fund);
        await _settle(tester);
        await _capture(tester, 'reward-funding-$theme');
      });

      testWidgets('the editor from a template', (tester) async {
        final fakes = editor.EditorFakes(
          actions: editor.FakeActionRepository(
            templates: [editor.walkTemplate(), editor.venueTemplate()],
          ),
        );
        await _pumpApp(
          tester,
          location: VerilyRoutePaths.actionNew,
          overrides: fakes.overrides,
          brightness: brightness,
        );
        await _capture(tester, 'editor-start-$theme');

        await tester.tap(
          find.byKey(VerilyTestKeys.editorTemplate('morning-walk')),
        );
        await _settle(tester);
        await _capture(tester, 'editor-form-$theme');

        await tester.ensureVisible(
          find.byKey(VerilyTestKeys.editorRewardToggle),
        );
        await _settle(tester);
        await tester.tap(find.byKey(VerilyTestKeys.editorRewardToggle));
        await _settle(tester);
        await tester.ensureVisible(
          find.byKey(VerilyTestKeys.editorRewardBudget),
        );
        await _settle(tester);
        await _capture(tester, 'editor-reward-$theme');
      });

      testWidgets('apps and one App', (tester) async {
        final app = apps.fixtureApp(boundActionCount: 2);
        final repository = apps.FakeAppsRepository(
          apps: [
            app,
            apps.fixtureApp(index: 2, name: 'Slopper'),
          ],
          confirmationPages: [
            [
              apps.fixtureConfirmation(1),
              apps.fixtureConfirmation(
                2,
                outcome: AppConfirmationOutcome.rejected,
                reasonCode: 'attempt_not_found',
                attemptStatus: null,
              ),
            ],
          ],
        );
        final overrides = <Override>[
          appsRepositoryProvider.overrideWithValue(repository),
          actionRepositoryProvider.overrideWithValue(
            hub.FakeHubActionRepository(),
          ),
        ];
        await _pumpApp(
          tester,
          location: VerilyRoutePaths.apps,
          overrides: overrides,
          brightness: brightness,
        );
        await _capture(tester, 'apps-$theme');

        await _pumpApp(
          tester,
          location: '/apps/${app.id}',
          overrides: overrides,
          brightness: brightness,
        );
        await _capture(tester, 'app-$theme');
      });
    });

    group('Me ($theme)', () {
      testWidgets('history, payouts, and wallet', (tester) async {
        await _pumpApp(
          tester,
          location: VerilyRoutePaths.me,
          session: me.testReviewerSession,
          overrides: me.meSliceOverrides(
            actions: me.FakeActionRepository(
              attempts: [
                me.fakeAttempt(
                  id: 1,
                  actionId: 10,
                  actionTitle: 'Ten squats at the park',
                  status: ActionAttemptStatus.verified,
                  payoutStatus: RewardPayoutStatus.released,
                  rewardOutcome: RewardOutcome.won,
                ),
                me.fakeAttempt(
                  id: 2,
                  actionId: 11,
                  actionTitle: 'Sunrise at the bridge',
                  status: ActionAttemptStatus.verifying,
                ),
                me.fakeAttempt(
                  id: 3,
                  actionId: 12,
                  actionTitle: 'Scan the code at the bar',
                  status: ActionAttemptStatus.rejected,
                ),
              ],
            ),
            rewards: me.FakeRewardRepository(
              payouts: [
                me
                    .fakePayout(
                      id: 40,
                      actionTitle: 'Ten squats at the park',
                      status: RewardPayoutStatus.released,
                    )
                    .copyWith(attemptId: me.testUuid(1)),
                me.fakePayout(
                  id: 41,
                  actionTitle: 'Sunrise at the bridge',
                  status: RewardPayoutStatus.awaitingWallet,
                ),
              ],
            ),
          ),
          brightness: brightness,
        );
        await _capture(tester, 'me-$theme');
      });

      testWidgets('review queue and appeals', (tester) async {
        final overrides = me.meSliceOverrides(
          reviews: me.FakeEvidenceReviewRepository(
            queue: [me.fakeReviewItem(evidenceId: 1)],
          ),
          appeals: me.FakeEvidenceAppealRepository(
            owned: [me.fakeAppeal(id: 1, attemptId: 2)],
          ),
        );
        await _pumpApp(
          tester,
          location: VerilyRoutePaths.reviews,
          session: me.testReviewerSession,
          overrides: overrides,
          brightness: brightness,
        );
        await _capture(tester, 'reviews-$theme');

        await _pumpApp(
          tester,
          location: VerilyRoutePaths.appeals,
          session: me.testReviewerSession,
          overrides: overrides,
          brightness: brightness,
        );
        await _capture(tester, 'appeals-$theme');
      });

      testWidgets('settings', (tester) async {
        await _pumpApp(
          tester,
          location: VerilyRoutePaths.settings,
          overrides: me.meSliceOverrides(),
          brightness: brightness,
        );
        await _capture(tester, 'settings-$theme');
      });
    });
  }
}

/// A feed with one action of each proof kind, one of them already checking.
List<ActionOpportunity> _feed() => [
  doing.actionFixture(
    id: 1,
    description: 'Check in on the bridge before the sun comes up.',
    reward: doing.rewardFixture(),
  ),
  doing.actionFixture(
    id: 2,
    title: 'Twenty squats',
    description: 'Twenty full squats on camera, counted as you go.',
    creator: 'Park Run Club',
    requirements: [
      doing.videoRequirement(
        movementKind: ActionMovementKind.squats,
        targetRepetitions: 20,
      ),
    ],
    reward: doing.rewardFixture(amountPerPayout: 2000000, payoutsRemaining: 3),
  ),
  doing.actionFixture(
    id: 3,
    title: 'Visit the bar',
    description: 'Scan the code behind the bar on your next visit.',
    requirements: [doing.venueCodeRequirement()],
  ),
  doing.actionFixture(
    id: 4,
    title: 'Bake a loaf',
    description: 'Bake a sourdough loaf and log it in Slopper.',
    creator: 'Slopper',
    requirements: [doing.appRequirement()],
  ),
  doing.actionFixture(
    id: 5,
    title: 'Spin around',
    description: 'Hold your phone out and turn a full circle.',
    requirements: [doing.motionRequirement()],
    myAttempt: doing.attemptFixture(
      actionId: 5,
      status: ActionAttemptStatus.verifying,
    ),
  ),
];

/// Pumps the whole app at [location] through the real router and tab shell.
Future<void> _pumpApp(
  WidgetTester tester, {
  required String location,
  required Brightness brightness,
  List<Override> overrides = const [],
  AccountSession? session,
}) async {
  tester.view.physicalSize = _seekerPhysicalSize;
  tester.view.devicePixelRatio = _seekerPixelRatio;
  addTearDown(tester.view.reset);

  final account = session ?? testSignedInSession;
  final refresh = ValueNotifier<int>(0);
  addTearDown(refresh.dispose);
  final router = buildAppRouter(
    isSignedIn: () => account.isSignedIn,
    refresh: refresh,
    initialLocation: location,
  );
  addTearDown(router.dispose);

  // A fresh scope per pump, so one screen's state never leaks into the next.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticProviderRetry,
      overrides: [
        ...baseTestOverrides(session: account),
        ...overrides,
      ],
      child: MaterialApp.router(
        // As in the app.
        debugShowCheckedModeBanner: false,
        theme: buildVerilyTheme(brightness: brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, page) => VerilyWiredScope(child: page!),
        routerConfig: router,
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  if (!_writeScreenshots) return;

  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    // The root layer already scales by the device pixel ratio.
    final image = await layer.toImage(Offset.zero & tester.view.physicalSize);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_outputDirectory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}

/// Lets ink motion, async work, and route transitions finish. Loading
/// indicators spin forever, so this pumps fixed steps instead of settling.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var step = 0; step < 4; step++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}
