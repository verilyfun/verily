import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:solana_kit/solana_kit.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/rewards/reward_repository.dart';
import 'package:verily_flutter/features/wallet/mobile_wallet.dart';

/// What the creator must do to put a reward into escrow.
sealed class RewardFundingStep {
  const RewardFundingStep(this.plan);

  final RewardFundingPlan plan;
}

/// A real `OpenEscrow` transaction for the creator's wallet to sign and send.
final class WalletFundingStep extends RewardFundingStep {
  const WalletFundingStep(super.plan, this.transaction);

  final Uint8List transaction;
}

/// The server runs the labelled local-development escrow: there is no chain,
/// so nothing can be signed. Only debug builds may confirm it.
final class LocalDevelopmentFundingStep extends RewardFundingStep {
  const LocalDevelopmentFundingStep(super.plan);
}

/// Locks an action's reward in escrow.
///
/// 1. [prepare] freezes the terms on the server and returns the unsigned
///    transaction for the creator's linked payout wallet.
/// 2. [sendFundingTransaction] has that wallet sign and send it, once. Keep
///    the returned signature: sending again would open a second escrow.
/// 3. [confirmSentFunding] asks the server to verify the escrow from chain
///    state; repeat it with the same signature until the server reports the
///    pool funded. The app never decides that funding happened.
class RewardFundingService {
  const RewardFundingService({
    required this._rewards,
    required this._wallet,
    this._confirmationAttempts = 6,
    this._confirmationInterval = const Duration(seconds: 2),
  });

  final RewardRepository _rewards;
  final MobileWallet _wallet;

  /// How often to ask the server again while a freshly sent escrow is not yet
  /// visible on chain, and how long to wait between asks.
  final int _confirmationAttempts;
  final Duration _confirmationInterval;

  /// Whether this device can sign the funding transaction.
  bool get canSignOnThisDevice => _wallet.isSupported;

  Future<RewardFundingStep> prepare(UuidValue actionId) async {
    final plan = await _rewards.prepareFunding(actionId);
    final bytes = base64Decode(plan.unsignedTransaction);
    if (_isLocalDevelopmentDescriptor(bytes)) {
      return LocalDevelopmentFundingStep(plan);
    }
    return WalletFundingStep(plan, bytes);
  }

  /// Signs and sends [step]'s transaction with the creator's wallet and
  /// returns its base58 signature. Throws [WalletException] with
  /// [WalletFailure.wrongAccount] when the wallet offers an account other than
  /// the linked one the escrow was built for.
  Future<String> sendFundingTransaction(WalletFundingStep step) =>
      _wallet.connect(
        chain: chainFor(step.plan.cluster),
        body: (wallet) async {
          if (wallet.address != step.plan.creatorWallet) {
            throw const WalletException(WalletFailure.wrongAccount);
          }
          return wallet.signAndSendTransaction(step.transaction);
        },
      );

  /// Asks the server to verify an escrow whose transaction [signature] was
  /// already sent.
  ///
  /// A transaction that was just sent may not be final when the server first
  /// reads the chain, so `escrowNotFound` is asked again a few times with the
  /// same signature. Approving again in the wallet would send a second escrow,
  /// so the signature is never thrown away: if the escrow still isn't visible,
  /// the [RewardException] carries on to the caller, which can call this
  /// again later with the same [signature] (as [EscrowNotYetVisibleException]
  /// carries it).
  Future<RewardPoolView> confirmSentFunding(
    UuidValue actionId,
    String signature,
  ) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await _rewards.confirmFunding(
          actionId: actionId,
          signature: signature,
        );
      } on RewardException catch (error) {
        if (error.problem != RewardProblem.escrowNotFound) rethrow;
        if (attempt >= _confirmationAttempts) {
          throw EscrowNotYetVisibleException(signature);
        }
        await Future<void>.delayed(_confirmationInterval);
      }
    }
  }

  /// Confirms a local-development escrow. The server's development gateway
  /// accepts any well-formed signature and still reports the pool's real
  /// state; release builds can never reach this.
  Future<RewardPoolView> confirmLocalDevelopment(
    UuidValue actionId,
    LocalDevelopmentFundingStep step,
  ) {
    if (!kDebugMode) {
      throw StateError('Local development funding is for debug builds only.');
    }
    final random = Random.secure();
    final signature = getBase58Decoder().decode(
      Uint8List.fromList(List.generate(64, (_) => random.nextInt(256))),
    );
    return _rewards.confirmFunding(actionId: actionId, signature: signature);
  }

  static bool _isLocalDevelopmentDescriptor(Uint8List bytes) {
    // A Solana transaction starts with a compact signature count, never `{`.
    if (bytes.isEmpty || bytes.first != 0x7B) return false;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, Object?> &&
          decoded['localDevelopmentOnly'] == true;
    } on FormatException {
      return false;
    }
  }
}

/// The wallet sent the escrow transaction, but the server can't see the
/// escrow on chain yet. Confirm again later with [signature]; never sign a
/// second escrow.
class EscrowNotYetVisibleException implements Exception {
  const EscrowNotYetVisibleException(this.signature);

  /// The base58 signature of the transaction the wallet already sent.
  final String signature;

  @override
  String toString() => 'EscrowNotYetVisibleException($signature)';
}

/// The wallet chain for a reward's cluster.
WalletChain chainFor(RewardCluster cluster) => switch (cluster) {
  RewardCluster.devnet => WalletChain.devnet,
  RewardCluster.mainnet => WalletChain.mainnet,
};

final rewardFundingServiceProvider = Provider<RewardFundingService>(
  (ref) => RewardFundingService(
    rewards: ref.watch(rewardRepositoryProvider),
    wallet: ref.watch(mobileWalletProvider),
  ),
);

/// Links the wallet that receives payouts, proven by a signature.
class PayoutWalletLinkService {
  const PayoutWalletLinkService({
    required this._wallets,
    required this._wallet,
    this._chain = WalletChain.devnet,
  });

  final PayoutWalletRepository _wallets;
  final MobileWallet _wallet;
  final WalletChain _chain;

  bool get canLinkOnThisDevice => _wallet.isSupported;

  /// Opens the wallet, asks the server for a challenge for the account it
  /// authorizes, has the wallet sign it, and links the wallet. One wallet
  /// session, so the person approves once.
  Future<PayoutWalletView> linkWithMobileWallet() => _wallet.connect(
    chain: _chain,
    body: (wallet) async {
      final challenge = await _wallets.createLinkChallenge(wallet.address);
      final signature = await wallet.signMessage(challenge.message);
      return _wallets.link(
        walletAddress: challenge.walletAddress,
        nonce: challenge.nonce,
        signature: signature,
      );
    },
  );
}

const _walletChainDefine = String.fromEnvironment(
  'VERILY_WALLET_CHAIN',
  defaultValue: 'solana:devnet',
);

final payoutWalletLinkServiceProvider = Provider<PayoutWalletLinkService>(
  (ref) => PayoutWalletLinkService(
    wallets: ref.watch(payoutWalletRepositoryProvider),
    wallet: ref.watch(mobileWalletProvider),
    chain: WalletChain.values.firstWhere(
      (chain) => chain.id == _walletChainDefine,
      orElse: () => throw StateError(
        'VERILY_WALLET_CHAIN must be solana:devnet or solana:mainnet.',
      ),
    ),
  ),
);
