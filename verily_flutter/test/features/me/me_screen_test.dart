import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/me/me_screen.dart';
import 'package:verily_flutter/features/wallet/mobile_wallet.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../support/test_app.dart';
import 'support/fakes.dart';
import 'support/router_harness.dart';

const _walletAddress = '7t4rL4Ph7v8iKxBHZQH7BdsM5zFi3pCYpu2eMXWJxqP1';

/// Pumps Me on a view tall enough that every section is built.
Future<void> _pumpMe(
  WidgetTester tester, {
  required List<Override> overrides,
  AccountSession? session,
}) async {
  await pumpVerilyPage(
    tester,
    const MeScreen(),
    overrides: overrides,
    session: session,
    physicalSize: const Size(800, 3200),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('attempts', () {
    testWidgets('show the action each attempt belongs to, or say so', (
      tester,
    ) async {
      final squats = fakeAttempt(
        id: 1,
        actionId: 10,
        actionTitle: 'Ten squats at the park',
        status: ActionAttemptStatus.verified,
        payoutStatus: RewardPayoutStatus.released,
        rewardOutcome: RewardOutcome.won,
      );
      final cafe = fakeAttempt(
        id: 2,
        actionId: 11,
        actionTitle: 'Check in at Café Lumen',
      );
      // An attempt from before titles were recorded.
      final ended = fakeAttempt(
        id: 3,
        actionId: 12,
        status: ActionAttemptStatus.capacityReached,
      );
      await _pumpMe(
        tester,
        overrides: meSliceOverrides(
          actions: FakeActionRepository(attempts: [squats, cafe, ended]),
          rewards: FakeRewardRepository(
            payouts: [
              fakePayout(
                id: 40,
                actionTitle: 'Ten squats at the park',
                status: RewardPayoutStatus.released,
              ).copyWith(attemptId: squats.id),
            ],
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(VerilyTestKeys.meAttempt(squats.id.toString())),
          matching: find.text('Ten squats at the park'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(VerilyTestKeys.meAttempt(cafe.id.toString())),
          matching: find.text('Check in at Café Lumen'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(VerilyTestKeys.meAttempt(ended.id.toString())),
          matching: find.text('An action you tried'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(VerilyTestKeys.meAttempt(squats.id.toString())),
          matching: find.text('5 USDC paid'),
        ),
        findsOneWidget,
      );
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('This action is full'), findsOneWidget);
      expect(find.text('Started Oct 21, 2026'), findsNWidgets(3));
    });

    testWidgets('say so when there are none yet', (tester) async {
      await _pumpMe(tester, overrides: meSliceOverrides());

      expect(
        find.text("You haven't tried an action yet. Find one in Do."),
        findsOneWidget,
      );
      expect(
        find.text('Nothing paid yet. Rewards you earn show up here.'),
        findsOneWidget,
      );
    });

    testWidgets('a tap opens the action it belongs to', (tester) async {
      final attempt = fakeAttempt(
        id: 1,
        actionId: 10,
        actionTitle: 'Ten squats at the park',
      );
      await pumpVerilyRoutes(
        tester,
        initialLocation: VerilyRoutePaths.me,
        physicalSize: const Size(800, 3200),
        screens: {VerilyRouteNames.me: const MeScreen()},
        overrides: meSliceOverrides(
          actions: FakeActionRepository(attempts: [attempt]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ten squats at the park'));
      await tester.pumpAndSettle();

      expect(find.byKey(routeStandIn(VerilyRouteNames.action)), findsOneWidget);
      expect(
        find.text(VerilyLocations.action('${testUuid(10)}')),
        findsOneWidget,
      );
    });
  });

  group('appeals', () {
    testWidgets('a rejected attempt can be appealed once', (tester) async {
      final rejected = fakeAttempt(
        id: 4,
        actionId: 10,
        status: ActionAttemptStatus.rejected,
      );
      final appeals = FakeEvidenceAppealRepository();
      await _pumpMe(
        tester,
        overrides: meSliceOverrides(
          actions: FakeActionRepository(attempts: [rejected]),
          appeals: appeals,
        ),
      );
      final appealButton = find.byKey(
        VerilyTestKeys.meAppeal(rejected.id.toString()),
      );
      expect(find.text('Not accepted'), findsOneWidget);
      expect(appealButton, findsOneWidget);

      await tester.tap(appealButton);
      await tester.pumpAndSettle();
      expect(find.text('Appeal this decision'), findsOneWidget);

      bool canSend() => tester
          .widget<FilledButton>(find.byKey(VerilyTestKeys.meAppealSubmit))
          .enabled;
      await tester.enterText(
        find.byKey(VerilyTestKeys.meAppealReason),
        'Too short',
      );
      await tester.pump();
      expect(canSend(), isFalse);

      const reason = 'All ten squats are in the second half.';
      await tester.enterText(find.byKey(VerilyTestKeys.meAppealReason), reason);
      await tester.pump();
      expect(canSend(), isTrue);
      await tester.tap(find.byKey(VerilyTestKeys.meAppealSubmit));
      await tester.pumpAndSettle();

      expect(appeals.submitted, [(attemptId: rejected.id, reason: reason)]);
      expect(find.text('Appeal sent.'), findsOneWidget);
      expect(
        find.text('Appeal sent · waiting for the creator'),
        findsOneWidget,
      );
      expect(appealButton, findsNothing);
    });

    testWidgets("show an existing appeal's outcome instead of the button", (
      tester,
    ) async {
      final rejected = fakeAttempt(
        id: 5,
        actionId: 10,
        status: ActionAttemptStatus.rejected,
      );
      await _pumpMe(
        tester,
        overrides: meSliceOverrides(
          actions: FakeActionRepository(attempts: [rejected]),
          appeals: FakeEvidenceAppealRepository(
            mine: {
              rejected.id: fakeAppeal(
                id: 7,
                attemptId: 5,
                status: EvidenceAppealStatus.rejected,
                resolutionNote: 'Only six squats are in frame.',
              ),
            },
          ),
        ),
      );

      expect(find.text('Appeal not accepted'), findsOneWidget);
      expect(find.text('Only six squats are in frame.'), findsOneWidget);
      expect(
        find.byKey(VerilyTestKeys.meAppeal(rejected.id.toString())),
        findsNothing,
      );
    });
  });

  group('payouts', () {
    testWidgets('state what happens to each one, to the exact amount', (
      tester,
    ) async {
      await _pumpMe(
        tester,
        overrides: meSliceOverrides(
          rewards: FakeRewardRepository(
            payouts: [
              fakePayout(
                id: 1,
                actionTitle: 'Ten squats at the park',
                status: RewardPayoutStatus.awaitingWallet,
              ),
              fakePayout(
                id: 2,
                actionTitle: 'Check in at Café Lumen',
                status: RewardPayoutStatus.heldForReview,
                amount: 2500000,
              ),
              fakePayout(
                id: 3,
                actionTitle: 'Clap for the band',
                status: RewardPayoutStatus.released,
                amount: 1234567,
              ),
            ],
          ),
        ),
      );

      Finder inPayout(int id, String text) => find.descendant(
        of: find.byKey(VerilyTestKeys.mePayout('${testUuid(id)}')),
        matching: find.text(text),
      );
      expect(inPayout(1, 'Ten squats at the park'), findsOneWidget);
      expect(inPayout(1, 'Add a wallet to receive 5 USDC'), findsOneWidget);
      expect(
        inPayout(1, 'Link a wallet by Nov 20, 2026 to receive it.'),
        findsOneWidget,
      );
      expect(inPayout(2, '2.5 USDC held for a quick check'), findsOneWidget);
      expect(inPayout(3, '1.234567 USDC paid'), findsOneWidget);
      expect(find.textContaining('Link a wallet by'), findsOneWidget);
    });
  });

  group('payout wallet', () {
    testWidgets('links a wallet with one signed challenge', (tester) async {
      final wallets = FakePayoutWalletRepository();
      final wallet = FakeMobileWallet();
      await _pumpMe(
        tester,
        overrides: meSliceOverrides(wallets: wallets, wallet: wallet),
      );
      expect(find.text('Link a wallet to get paid'), findsOneWidget);

      await tester.tap(find.byKey(VerilyTestKeys.meWalletLink));
      await tester.pumpAndSettle();

      expect(wallets.challenges, [_walletAddress]);
      expect(wallet.signedMessages, ['Link $_walletAddress to Verily']);
      expect(wallets.links, [
        (
          walletAddress: _walletAddress,
          nonce: 'nonce-1',
          signature: 'signature-base58',
        ),
      ]);
      expect(find.text('Wallet linked. Payouts go there now.'), findsOneWidget);
      expect(find.text('Payout wallet'), findsOneWidget);
      expect(find.text('7t4r…xqP1'), findsOneWidget);
      expect(find.text('Use a different wallet'), findsOneWidget);
    });

    testWidgets('explains why linking needs Android and a wallet app', (
      tester,
    ) async {
      await _pumpMe(
        tester,
        overrides: meSliceOverrides(
          wallet: FakeMobileWallet(isSupported: false),
        ),
      );

      expect(
        find.text(
          'Linking a wallet needs Verily on Android with a Solana wallet app '
          'installed.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(VerilyTestKeys.meWalletLink), findsNothing);
    });

    for (final (failure, message) in [
      (WalletFailure.cancelled, 'Linking was cancelled in your wallet.'),
      (
        WalletFailure.unavailable,
        'No Solana wallet app answered. Install one, then try again.',
      ),
      (
        WalletFailure.wrongAccount,
        'Your wallet offered a different account. Choose the one you want '
            'paid, then try again.',
      ),
    ]) {
      testWidgets('says what happened when the wallet is ${failure.name}', (
        tester,
      ) async {
        final wallets = FakePayoutWalletRepository();
        await _pumpMe(
          tester,
          overrides: meSliceOverrides(
            wallets: wallets,
            wallet: FakeMobileWallet(failure: failure),
          ),
        );

        await tester.tap(find.byKey(VerilyTestKeys.meWalletLink));
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
        expect(wallets.links, isEmpty);
        expect(find.text('Link a wallet to get paid'), findsOneWidget);
      });
    }

    testWidgets(
      'shows a linked wallet short, reads it in full, and copies it',
      (
        tester,
      ) async {
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied =
                  (call.arguments as Map<Object?, Object?>)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await _pumpMe(
          tester,
          overrides: meSliceOverrides(
            wallets: FakePayoutWalletRepository(
              wallet: PayoutWalletView(
                walletAddress: _walletAddress,
                label: 'Mobile wallet',
                linkedAt: fixtureNow,
              ),
            ),
          ),
        );

        final semantics = tester.ensureSemantics();
        expect(find.text('7t4r…xqP1'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Wallet address $_walletAddress'),
          findsOneWidget,
        );
        semantics.dispose();

        await tester.tap(find.byKey(VerilyTestKeys.meWalletCopy));
        await tester.pumpAndSettle();

        expect(copied, _walletAddress);
        expect(find.text('Wallet address copied'), findsOneWidget);
      },
    );
  });

  group('links', () {
    testWidgets('offer review only to reviewers', (tester) async {
      await _pumpMe(tester, overrides: meSliceOverrides());

      expect(find.byKey(VerilyTestKeys.meLinkSettings), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.meLinkAppeals), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.meLinkReview), findsNothing);
    });

    for (final (key, routeName) in [
      (VerilyTestKeys.meLinkSettings, VerilyRouteNames.settings),
      (VerilyTestKeys.meSettingsButton, VerilyRouteNames.settings),
      (VerilyTestKeys.meLinkAppeals, VerilyRouteNames.appeals),
      (VerilyTestKeys.meLinkReview, VerilyRouteNames.reviews),
    ]) {
      testWidgets('${key.value} opens $routeName', (tester) async {
        await pumpVerilyRoutes(
          tester,
          initialLocation: VerilyRoutePaths.me,
          session: testReviewerSession,
          physicalSize: const Size(800, 3200),
          screens: {VerilyRouteNames.me: const MeScreen()},
          overrides: meSliceOverrides(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();

        expect(find.byKey(routeStandIn(routeName)), findsOneWidget);
      });
    }
  });

  testWidgets('fits a Seeker at 1.3x text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final rejected = fakeAttempt(
      id: 4,
      actionId: 10,
      status: ActionAttemptStatus.rejected,
    );
    await pumpVerilyPage(
      tester,
      const MeScreen(),
      session: testReviewerSession,
      physicalSize: const Size(1080, 2400),
      devicePixelRatio: 2.625,
      overrides: meSliceOverrides(
        actions: FakeActionRepository(attempts: [rejected]),
        rewards: FakeRewardRepository(
          payouts: [
            fakePayout(
              id: 1,
              actionTitle: 'Ten squats at the park',
              status: RewardPayoutStatus.awaitingWallet,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    const width = 1080 / 2.625;
    for (final key in [
      VerilyTestKeys.meWalletLink,
      VerilyTestKeys.mePayout('${testUuid(1)}'),
      VerilyTestKeys.meAttempt('${rejected.id}'),
      VerilyTestKeys.meAppeal('${rejected.id}'),
      VerilyTestKeys.meLinkReview,
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(key),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byKey(key));
      expect(rect.left, greaterThanOrEqualTo(0), reason: '$key');
      expect(rect.right, lessThanOrEqualTo(width), reason: '$key');
    }
    expect(tester.takeException(), isNull);
  });
}
