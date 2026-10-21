import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/rewards/reward_funding_service.dart';
import 'package:verily_flutter/features/rewards/reward_repository.dart';
import 'package:verily_flutter/features/wallet/mobile_wallet.dart';

final _actionId = UuidValue.fromString('00000000-0000-4000-8000-0000000000a1');
const _creatorWallet = '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU';

RewardFundingPlan _plan({required String unsignedTransaction}) =>
    RewardFundingPlan(
      poolId: UuidValue.fromString('00000000-0000-4000-8000-0000000000b1'),
      cluster: RewardCluster.devnet,
      escrowAddress: 'Escrow1111111111111111111111111111111111111',
      creatorWallet: _creatorWallet,
      arbiterAddress: 'Arbiter111111111111111111111111111111111111',
      mint: 'Mint11111111111111111111111111111111111111',
      tokenSymbol: 'USDC',
      decimals: 6,
      totalAtoms: 50000000,
      expiresAt: DateTime.utc(2026, 12),
      refundAfter: DateTime.utc(2026, 12, 8),
      unsignedTransaction: unsignedTransaction,
    );

RewardPoolView _pool(RewardPoolStatus status) => RewardPoolView(
  poolId: UuidValue.fromString('00000000-0000-4000-8000-0000000000b1'),
  status: status,
  cluster: RewardCluster.devnet,
  mint: 'Mint11111111111111111111111111111111111111',
  tokenSymbol: 'USDC',
  decimals: 6,
  amountPerPayout: 2500000,
  maxPayouts: 20,
  maxWinsPerAccount: 1,
  payoutsReserved: 0,
  payoutsReleased: 0,
  expiresAt: DateTime.utc(2026, 12),
  refundAfter: DateTime.utc(2026, 12, 8),
);

class _Rewards implements RewardRepository {
  _Rewards({required this.plan, List<Exception>? confirmErrors})
    : confirmErrors = confirmErrors ?? [];

  RewardFundingPlan plan;
  final List<Exception> confirmErrors;
  final confirmed = <String>[];

  @override
  Future<RewardFundingPlan> prepareFunding(UuidValue actionId) async => plan;

  @override
  Future<RewardPoolView> confirmFunding({
    required UuidValue actionId,
    required String signature,
  }) async {
    confirmed.add(signature);
    if (confirmErrors.isNotEmpty) throw confirmErrors.removeAt(0);
    return _pool(RewardPoolStatus.funded);
  }

  @override
  Future<RewardPoolView?> getPool(UuidValue actionId) =>
      throw UnimplementedError();

  @override
  Future<RewardEndPlan> endEarly(UuidValue actionId) =>
      throw UnimplementedError();

  @override
  Future<List<RewardPayoutView>> listMyPayouts() => throw UnimplementedError();
}

class _Wallet implements MobileWallet {
  _Wallet({this.address = _creatorWallet});

  final String address;
  final sent = <Uint8List>[];
  final chains = <WalletChain>[];

  @override
  bool get isSupported => true;

  @override
  Future<T> connect<T>({
    required WalletChain chain,
    required Future<T> Function(WalletConnection wallet) body,
  }) {
    chains.add(chain);
    return body(_Connection(this));
  }
}

class _Connection implements WalletConnection {
  _Connection(this._wallet);

  final _Wallet _wallet;

  @override
  String get address => _wallet.address;

  @override
  Future<String> signMessage(String message) async => 'message-signature';

  @override
  Future<String> signAndSendTransaction(Uint8List wireTransaction) async {
    _wallet.sent.add(wireTransaction);
    return 'tx-signature';
  }
}

RewardException _notFound() => RewardException(
  problem: RewardProblem.escrowNotFound,
  message: 'The escrow is not visible yet.',
);

void main() {
  final realTransaction = base64Encode([1, 0, 1, 2, 3]);
  final localDescriptor = base64Encode(
    utf8.encode(
      jsonEncode({'localDevelopmentOnly': true, 'instruction': 'OpenEscrow'}),
    ),
  );

  test('a real transaction is for the wallet to sign', () async {
    final service = RewardFundingService(
      rewards: _Rewards(plan: _plan(unsignedTransaction: realTransaction)),
      wallet: _Wallet(),
    );

    final step = await service.prepare(_actionId);

    expect(step, isA<WalletFundingStep>());
    expect((step as WalletFundingStep).transaction, [1, 0, 1, 2, 3]);
  });

  test('the local development escrow is recognised, never signed', () async {
    final service = RewardFundingService(
      rewards: _Rewards(plan: _plan(unsignedTransaction: localDescriptor)),
      wallet: _Wallet(),
    );

    expect(
      await service.prepare(_actionId),
      isA<LocalDevelopmentFundingStep>(),
    );
  });

  test('sends once from the linked wallet on the plan cluster', () async {
    final wallet = _Wallet();
    final service = RewardFundingService(
      rewards: _Rewards(plan: _plan(unsignedTransaction: realTransaction)),
      wallet: wallet,
    );
    final step = await service.prepare(_actionId) as WalletFundingStep;

    expect(await service.sendFundingTransaction(step), 'tx-signature');
    expect(wallet.sent, hasLength(1));
    expect(wallet.chains, [WalletChain.devnet]);
  });

  test('refuses a wallet account other than the linked one', () async {
    final wallet = _Wallet(
      address: 'SomeoneElse11111111111111111111111111111111',
    );
    final service = RewardFundingService(
      rewards: _Rewards(plan: _plan(unsignedTransaction: realTransaction)),
      wallet: wallet,
    );
    final step = await service.prepare(_actionId) as WalletFundingStep;

    await expectLater(
      service.sendFundingTransaction(step),
      throwsA(
        isA<WalletException>().having(
          (error) => error.failure,
          'failure',
          WalletFailure.wrongAccount,
        ),
      ),
    );
    expect(wallet.sent, isEmpty);
  });

  test('re-checks a settling escrow with the same signature', () async {
    final rewards = _Rewards(
      plan: _plan(unsignedTransaction: realTransaction),
      confirmErrors: [_notFound(), _notFound()],
    );
    final service = RewardFundingService(
      rewards: rewards,
      wallet: _Wallet(),
      confirmationInterval: Duration.zero,
    );

    final pool = await service.confirmSentFunding(_actionId, 'tx-signature');

    expect(pool.status, RewardPoolStatus.funded);
    expect(rewards.confirmed, ['tx-signature', 'tx-signature', 'tx-signature']);
  });

  test('hands the signature back when the escrow stays invisible', () async {
    final rewards = _Rewards(
      plan: _plan(unsignedTransaction: realTransaction),
      confirmErrors: [_notFound(), _notFound(), _notFound()],
    );
    final service = RewardFundingService(
      rewards: rewards,
      wallet: _Wallet(),
      confirmationAttempts: 3,
      confirmationInterval: Duration.zero,
    );

    await expectLater(
      service.confirmSentFunding(_actionId, 'tx-signature'),
      throwsA(
        isA<EscrowNotYetVisibleException>().having(
          (error) => error.signature,
          'signature',
          'tx-signature',
        ),
      ),
    );
    expect(rewards.confirmed, hasLength(3));
  });

  test('other refusals are not retried', () async {
    final rewards = _Rewards(
      plan: _plan(unsignedTransaction: realTransaction),
      confirmErrors: [
        RewardException(
          problem: RewardProblem.escrowMismatch,
          message: 'The escrow does not match this reward.',
        ),
      ],
    );
    final service = RewardFundingService(
      rewards: rewards,
      wallet: _Wallet(),
      confirmationInterval: Duration.zero,
    );

    await expectLater(
      service.confirmSentFunding(_actionId, 'tx-signature'),
      throwsA(isA<RewardException>()),
    );
    expect(rewards.confirmed, hasLength(1));
  });

  group('PayoutWalletLinkService', () {
    test('links in one wallet session with the signed challenge', () async {
      final wallets = _Wallets();
      final wallet = _Wallet();
      final service = PayoutWalletLinkService(wallets: wallets, wallet: wallet);

      final linked = await service.linkWithMobileWallet();

      expect(linked.walletAddress, _creatorWallet);
      expect(wallets.challengedAddresses, [_creatorWallet]);
      expect(wallets.links, [
        (_creatorWallet, 'nonce-1', 'message-signature'),
      ]);
      expect(wallet.chains, hasLength(1));
    });
  });
}

class _Wallets implements PayoutWalletRepository {
  final challengedAddresses = <String>[];
  final links = <(String, String, String)>[];

  @override
  Future<PayoutWalletView?> getMine() async => null;

  @override
  Future<PayoutWalletLinkChallengeView> createLinkChallenge(
    String walletAddress,
  ) async {
    challengedAddresses.add(walletAddress);
    return PayoutWalletLinkChallengeView(
      walletAddress: walletAddress,
      message: 'Link this wallet to Verily. Nonce: nonce-1',
      nonce: 'nonce-1',
      expiresAt: DateTime.utc(2026, 10, 21, 12, 5),
    );
  }

  @override
  Future<PayoutWalletView> link({
    required String walletAddress,
    required String nonce,
    required String signature,
  }) async {
    links.add((walletAddress, nonce, signature));
    return PayoutWalletView(
      walletAddress: walletAddress,
      label: 'Payout wallet',
      linkedAt: DateTime.utc(2026, 10, 21, 12),
    );
  }
}
