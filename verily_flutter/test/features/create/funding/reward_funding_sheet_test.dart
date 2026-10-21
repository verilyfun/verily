import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:hooks_riverpod/misc.dart';

import 'package:verily_flutter/features/create/funding/reward_funding_sheet.dart';
import 'package:verily_flutter/features/rewards/reward_funding_service.dart';
import 'package:verily_flutter/features/wallet/mobile_wallet.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../../support/test_app.dart';
import '../editor/support/fakes.dart';

final l10n = AppLocalizationsEn();
const _launch = ValueKey<String>('launch-funding');

/// The pool the last funding sheet returned.
class FundingResult {
  RewardPoolView? pool;
  bool returned = false;
}

Future<FundingResult> openFunding(
  WidgetTester tester,
  EditorFakes fakes, {
  List<Override> extraOverrides = const [],
}) async {
  final result = FundingResult();
  final action = actionFixture(reward: rewardSummaryFixture());
  await pumpVerilyPage(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            key: _launch,
            onPressed: () async {
              result
                ..pool = await showRewardFunding(context, action: action)
                ..returned = true;
            },
            child: const Text('Fund'),
          ),
        ),
      ),
    ),
    overrides: [...fakes.overrides, ...extraOverrides],
    physicalSize: const Size(1080, 2400),
    devicePixelRatio: 2.625,
  );
  await tester.tap(find.byKey(_launch));
  await tester.pumpAndSettle();
  return result;
}

Future<void> tapInSheet(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the escrow before anything is signed', (tester) async {
    await openFunding(
      tester,
      EditorFakes(
        wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
      ),
    );

    expect(find.text(l10n.fundingTitle), findsOneWidget);
    expect(find.text('2.5 USDC'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('50 USDC'), findsOneWidget);
    expect(find.text(l10n.fundingRefundFrom), findsOneWidget);
    expect(find.text(l10n.fundingWalletLinked('7xKX…gAsU')), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.fundingApprove), findsOneWidget);
  });

  testWidgets('links a payout wallet first when none is linked', (
    tester,
  ) async {
    final fakes = EditorFakes();
    await openFunding(tester, fakes);

    expect(find.text(l10n.fundingWalletNeeded), findsOneWidget);
    expect(fakes.rewards.preparedActions, isEmpty);
    await tapInSheet(tester, VerilyTestKeys.fundingLinkWallet);

    expect(fakes.wallet.signedMessages, hasLength(1));
    expect(fakes.wallets.linkedSignatures, ['signed-message']);
    expect(fakes.rewards.preparedActions, [editorActionId]);
    expect(find.byKey(VerilyTestKeys.fundingApprove), findsOneWidget);
  });

  testWidgets('says funding needs the Android app where no wallet can sign', (
    tester,
  ) async {
    await openFunding(
      tester,
      EditorFakes(wallet: FakeMobileWallet(isSupported: false)),
    );

    expect(find.text(l10n.fundingNeedsAndroid), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.fundingLinkWallet), findsNothing);
  });

  testWidgets('a linked wallet on an unsupported device cannot approve', (
    tester,
  ) async {
    await openFunding(
      tester,
      EditorFakes(
        wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
        wallet: FakeMobileWallet(isSupported: false),
      ),
    );

    expect(find.text(l10n.fundingNeedsAndroid), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.fundingApprove), findsNothing);
  });

  testWidgets('refuses a different wallet account in plain words', (
    tester,
  ) async {
    final fakes = EditorFakes(
      wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
      wallet: FakeMobileWallet(address: editorOtherWallet),
    );
    await openFunding(tester, fakes);
    await tapInSheet(tester, VerilyTestKeys.fundingApprove);

    expect(find.text(l10n.fundingWalletWrongAccount), findsOneWidget);
    expect(fakes.wallet.sentTransactions, isEmpty);
    expect(fakes.rewards.confirmedSignatures, isEmpty);
    expect(find.byKey(VerilyTestKeys.fundingFunded), findsNothing);
  });

  testWidgets('explains a declined wallet request', (tester) async {
    await openFunding(
      tester,
      EditorFakes(
        wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
        wallet: FakeMobileWallet(failure: WalletFailure.cancelled),
      ),
    );
    await tapInSheet(tester, VerilyTestKeys.fundingApprove);

    expect(find.text(l10n.fundingWalletCancelled), findsOneWidget);
  });

  testWidgets('says locked in escrow only once the server reports funded', (
    tester,
  ) async {
    final fakes = EditorFakes(
      wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
      rewards: FakeRewardRepository(
        confirmations: [
          poolFixture(status: RewardPoolStatus.awaitingFunding),
          poolFixture(),
        ],
      ),
    );
    final result = await openFunding(tester, fakes);

    await tapInSheet(tester, VerilyTestKeys.fundingApprove);
    expect(fakes.rewards.confirmedSignatures, ['funding-signature']);
    expect(find.text(l10n.fundingNotYet), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.fundingFunded), findsNothing);
    expect(find.text(l10n.fundingFunded), findsNothing);

    // Asking again re-checks the same transaction; it never signs twice.
    expect(find.text(l10n.fundingCheckAgain), findsOneWidget);
    await tapInSheet(tester, VerilyTestKeys.fundingApprove);
    expect(fakes.wallet.sentTransactions, hasLength(1));
    expect(fakes.rewards.confirmedSignatures, [
      'funding-signature',
      'funding-signature',
    ]);
    expect(find.byKey(VerilyTestKeys.fundingFunded), findsOneWidget);
    expect(find.text(l10n.fundingFundedBody('50 USDC')), findsOneWidget);

    await tapInSheet(tester, VerilyTestKeys.fundingDone);
    expect(result.returned, isTrue);
    expect(result.pool!.status, RewardPoolStatus.funded);
  });

  testWidgets('an escrow not yet visible is re-checked, never signed again', (
    tester,
  ) async {
    final fakes = EditorFakes(
      wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
      rewards: FakeRewardRepository(
        confirmErrors: [
          for (var i = 0; i < 2; i++)
            RewardException(
              problem: RewardProblem.escrowNotFound,
              message: 'Not found yet.',
            ),
        ],
      ),
    );
    await openFunding(
      tester,
      fakes,
      extraOverrides: [
        rewardFundingServiceProvider.overrideWith(
          (ref) => RewardFundingService(
            rewards: fakes.rewards,
            wallet: fakes.wallet,
            confirmationAttempts: 2,
            confirmationInterval: Duration.zero,
          ),
        ),
      ],
    );

    await tapInSheet(tester, VerilyTestKeys.fundingApprove);
    expect(find.text(l10n.fundingSentNotVisible), findsOneWidget);
    expect(find.text(l10n.fundingCheckAgain), findsOneWidget);

    await tapInSheet(tester, VerilyTestKeys.fundingApprove);
    expect(fakes.wallet.sentTransactions, hasLength(1));
    expect(fakes.rewards.confirmedSignatures, [
      'funding-signature',
      'funding-signature',
      'funding-signature',
    ]);
    expect(find.byKey(VerilyTestKeys.fundingFunded), findsOneWidget);
  });

  testWidgets('a sheet swiped away after funding still reports the pool', (
    tester,
  ) async {
    final fakes = EditorFakes(
      wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
    );
    final result = await openFunding(tester, fakes);
    await tapInSheet(tester, VerilyTestKeys.fundingApprove);

    Navigator.of(tester.element(find.byKey(VerilyTestKeys.fundingSheet))).pop();
    await tester.pumpAndSettle();
    expect(result.returned, isTrue);
    expect(result.pool!.status, RewardPoolStatus.funded);
  });

  testWidgets('the development escrow is a labelled debug-build tool', (
    tester,
  ) async {
    final fakes = EditorFakes(
      wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
      rewards: FakeRewardRepository(
        plan: fundingPlanFixture(localDevelopment: true),
      ),
    );
    await openFunding(tester, fakes);

    expect(find.text(l10n.fundingDevHeading), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.fundingApprove), findsNothing);
    await tapInSheet(tester, VerilyTestKeys.fundingDevConfirm);
    expect(fakes.rewards.confirmedSignatures, hasLength(1));
    expect(find.byKey(VerilyTestKeys.fundingFunded), findsOneWidget);
  });

  testWidgets('a release build never offers the development escrow', (
    tester,
  ) async {
    await openFunding(
      tester,
      EditorFakes(
        wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
        rewards: FakeRewardRepository(
          plan: fundingPlanFixture(localDevelopment: true),
        ),
        developmentEscrowAllowed: false,
      ),
    );

    expect(find.byKey(VerilyTestKeys.fundingDevelopment), findsNothing);
    expect(find.byKey(VerilyTestKeys.fundingDevConfirm), findsNothing);
    expect(find.text(l10n.fundingUnavailable), findsOneWidget);
  });

  testWidgets('a server without escrow says rewards are not available', (
    tester,
  ) async {
    await openFunding(
      tester,
      EditorFakes(
        wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
        rewards: FakeRewardRepository(
          prepareError: RewardException(
            problem: RewardProblem.rewardsUnavailable,
            message: 'Escrowed rewards are not available.',
          ),
        ),
      ),
    );

    expect(find.byKey(VerilyTestKeys.fundingUnavailable), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.fundingApprove), findsNothing);
  });

  testWidgets('other server refusals keep their words and can be retried', (
    tester,
  ) async {
    final fakes = EditorFakes(
      wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
      rewards: FakeRewardRepository(
        prepareError: RewardException(
          problem: RewardProblem.poolEnded,
          message: 'This reward has already ended.',
        ),
      ),
    );
    await openFunding(tester, fakes);
    expect(find.text('This reward has already ended.'), findsOneWidget);

    fakes.rewards.prepareError = null;
    await tester.tap(find.text(l10n.dialogRetry));
    await tester.pumpAndSettle();
    expect(find.byKey(VerilyTestKeys.fundingApprove), findsOneWidget);
  });
}
