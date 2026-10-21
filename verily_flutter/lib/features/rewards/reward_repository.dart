import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/api_client.dart';

/// Escrowed rewards and the caller's payouts.
abstract interface class RewardRepository {
  /// The creator's pool for [actionId], or null when it has no reward.
  Future<RewardPoolView?> getPool(UuidValue actionId);

  /// Freezes the reward terms and returns the escrow address and an unsigned
  /// `OpenEscrow` transaction for the creator's linked wallet.
  Future<RewardFundingPlan> prepareFunding(UuidValue actionId);

  /// Asks the server to verify the escrow from chain state. [signature] is the
  /// base58 signature of the funding transaction, kept for audit only.
  Future<RewardPoolView> confirmFunding({
    required UuidValue actionId,
    required String signature,
  });

  /// Stops new payouts and returns an unsigned `EndEarly` transaction.
  Future<RewardEndPlan> endEarly(UuidValue actionId);
  Future<List<RewardPayoutView>> listMyPayouts();
}

class ServerpodRewardRepository implements RewardRepository {
  const ServerpodRewardRepository(this._client);

  final Client _client;

  @override
  Future<RewardPoolView?> getPool(UuidValue actionId) =>
      _client.rewards.getRewardPool(actionId: actionId);

  @override
  Future<RewardFundingPlan> prepareFunding(UuidValue actionId) =>
      _client.rewards.prepareRewardFunding(actionId: actionId);

  @override
  Future<RewardPoolView> confirmFunding({
    required UuidValue actionId,
    required String signature,
  }) => _client.rewards.confirmRewardFunding(
    actionId: actionId,
    signature: signature,
  );

  @override
  Future<RewardEndPlan> endEarly(UuidValue actionId) =>
      _client.rewards.endRewardEarly(actionId: actionId);

  @override
  Future<List<RewardPayoutView>> listMyPayouts() =>
      _client.rewards.listMyPayouts(limit: 50);
}

final rewardRepositoryProvider = Provider<RewardRepository>(
  (ref) => ServerpodRewardRepository(ref.watch(verilyClientProvider)),
);

/// The wallet that receives the caller's payouts (and a creator's refunds).
abstract interface class PayoutWalletRepository {
  Future<PayoutWalletView?> getMine();

  /// Text for [walletAddress] to sign, valid for five minutes.
  Future<PayoutWalletLinkChallengeView> createLinkChallenge(
    String walletAddress,
  );

  /// Links the wallet with its base58 ed25519 [signature] over the challenge.
  Future<PayoutWalletView> link({
    required String walletAddress,
    required String nonce,
    required String signature,
  });
}

class ServerpodPayoutWalletRepository implements PayoutWalletRepository {
  const ServerpodPayoutWalletRepository(this._client);

  final Client _client;

  @override
  Future<PayoutWalletView?> getMine() => _client.payoutWallet.getMine();

  @override
  Future<PayoutWalletLinkChallengeView> createLinkChallenge(
    String walletAddress,
  ) => _client.payoutWallet.createWalletLinkChallenge(
    walletAddress: walletAddress,
  );

  @override
  Future<PayoutWalletView> link({
    required String walletAddress,
    required String nonce,
    required String signature,
  }) => _client.payoutWallet.linkPayoutWallet(
    walletAddress: walletAddress,
    nonce: nonce,
    signature: signature,
  );
}

final payoutWalletRepositoryProvider = Provider<PayoutWalletRepository>(
  (ref) => ServerpodPayoutWalletRepository(ref.watch(verilyClientProvider)),
);
