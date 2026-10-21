import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/payout_wallet_service.dart';

/// The one Solana wallet an account is paid to and funds rewards from.
class PayoutWalletEndpoint extends Endpoint {
  PayoutWalletEndpoint({PayoutWalletService? service})
    : service = service ?? PayoutWalletService();

  final PayoutWalletService service;

  @override
  bool get requireLogin => true;

  Future<PayoutWalletView?> getMine(Session session) {
    return service.getMine(
      session,
      authUserId: session.authenticated!.authUserId,
    );
  }

  /// Returns the exact text the wallet must sign to prove ownership.
  Future<PayoutWalletLinkChallengeView> createWalletLinkChallenge(
    Session session, {
    required String walletAddress,
  }) {
    return service.createChallenge(
      session,
      authUserId: session.authenticated!.authUserId,
      walletAddress: walletAddress,
    );
  }

  /// Links (or re-links) the wallet with its base58 ed25519 signature.
  Future<PayoutWalletView> linkPayoutWallet(
    Session session, {
    required String walletAddress,
    required String nonce,
    required String signature,
  }) {
    return service.link(
      session,
      authUserId: session.authenticated!.authUserId,
      walletAddress: walletAddress,
      nonce: nonce,
      signature: signature,
    );
  }
}
