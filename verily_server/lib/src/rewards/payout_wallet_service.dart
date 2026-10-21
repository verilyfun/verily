import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/auth/solana_auth_verify.dart';
import 'package:verily_server/src/auth/solana_wallet_address.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';

/// Links one Solana payout wallet to an account by a signed, single-use,
/// Sign-In-With-Solana-style message.
///
/// The wallet signs the exact server-built text, so a signature can only
/// prove ownership for this account, this nonce, and this window. Re-linking
/// with a new signature replaces the wallet; payouts already releasing keep
/// the wallet they froze.
class PayoutWalletService {
  PayoutWalletService({
    RewardPayoutService? payoutService,
    DateTime Function()? clock,
    Random? random,
  }) : payoutService = payoutService ?? RewardPayoutService(),
       clock = clock ?? (() => DateTime.now().toUtc()),
       _random = random ?? Random.secure();

  final RewardPayoutService payoutService;
  final DateTime Function() clock;
  final Random _random;

  static const challengeLifetime = Duration(minutes: 5);
  static const challengeRateWindow = Duration(minutes: 10);
  static const maxChallengesPerWindow = 10;
  static const _statement =
      'Verily pays your rewards to this wallet. Signing does not move any '
      'funds.';

  Future<PayoutWalletView?> getMine(
    Session session, {
    required UuidValue authUserId,
  }) async {
    final wallet = await PayoutWallet.db.findFirstRow(
      session,
      where: (table) => table.authUserId.equals(authUserId),
    );
    return wallet == null ? null : _view(wallet);
  }

  Future<PayoutWalletLinkChallengeView> createChallenge(
    Session session, {
    required UuidValue authUserId,
    required String walletAddress,
  }) async {
    final normalizedWallet = validatedSolanaWalletAddress(walletAddress);
    final now = clock().toUtc();
    final expiresAt = now.add(challengeLifetime);
    final nonce = base58.encode(
      Uint8List.fromList([for (var i = 0; i < 24; i++) _random.nextInt(256)]),
    );
    final message = _message(
      session,
      walletAddress: normalizedWallet,
      nonce: nonce,
      issuedAt: now,
      expiresAt: expiresAt,
    );
    await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final recent = await PayoutWalletLinkChallenge.db.count(
          session,
          where: (table) =>
              table.authUserId.equals(authUserId) &
              (table.createdAt >= now.subtract(challengeRateWindow)),
          transaction: transaction,
        );
        if (recent >= maxChallengesPerWindow) {
          throw StateError(
            'Too many wallet link requests. Wait a few minutes and try again.',
          );
        }
        await PayoutWalletLinkChallenge.db.insertRow(
          session,
          PayoutWalletLinkChallenge(
            authUserId: authUserId,
            walletAddress: normalizedWallet,
            nonce: nonce,
            message: message,
            createdAt: now,
            expiresAt: expiresAt,
          ),
          transaction: transaction,
        );
      },
    );
    return PayoutWalletLinkChallengeView(
      walletAddress: normalizedWallet,
      message: message,
      nonce: nonce,
      expiresAt: expiresAt,
    );
  }

  /// Verifies the wallet's ed25519 signature over the challenge text and
  /// links the wallet. Then wakes every payout that was waiting for it.
  Future<PayoutWalletView> link(
    Session session, {
    required UuidValue authUserId,
    required String walletAddress,
    required String nonce,
    required String signature,
  }) async {
    final normalizedWallet = validatedSolanaWalletAddress(walletAddress);
    final publicKey = decodeBase58PublicKey(normalizedWallet);
    final signatureBytes = decodeBase58Signature(signature);
    final wallet = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final challenge = await PayoutWalletLinkChallenge.db.findFirstRow(
          session,
          where: (table) =>
              table.nonce.equals(nonce.trim()) &
              table.authUserId.equals(authUserId) &
              table.walletAddress.equals(normalizedWallet),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        final now = clock().toUtc();
        if (challenge == null ||
            challenge.usedAt != null ||
            !challenge.expiresAt.isAfter(now)) {
          throw StateError('This wallet link request is no longer valid.');
        }
        final verified = verifySolanaSignature(
          publicKeyBytes: publicKey,
          messageBytes: Uint8List.fromList(utf8.encode(challenge.message)),
          signatureBytes: signatureBytes,
        );
        if (!verified) {
          throw StateError('The wallet signature could not be verified.');
        }
        final otherOwner = await PayoutWallet.db.findFirstRow(
          session,
          where: (table) =>
              table.walletAddress.equals(normalizedWallet) &
              table.authUserId.notEquals(authUserId),
          transaction: transaction,
        );
        if (otherOwner != null) {
          throw StateError('This wallet is linked to another account.');
        }
        await PayoutWalletLinkChallenge.db.updateRow(
          session,
          challenge.copyWith(usedAt: now),
          transaction: transaction,
        );
        final existing = await PayoutWallet.db.findFirstRow(
          session,
          where: (table) => table.authUserId.equals(authUserId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (existing == null) {
          return PayoutWallet.db.insertRow(
            session,
            PayoutWallet(
              authUserId: authUserId,
              walletAddress: normalizedWallet,
              linkedAt: now,
              updatedAt: now,
            ),
            transaction: transaction,
          );
        }
        return PayoutWallet.db.updateRow(
          session,
          existing.copyWith(
            walletAddress: normalizedWallet,
            linkedAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    await payoutService.releaseAwaitingWallet(session, authUserId: authUserId);
    return _view(wallet);
  }

  String _message(
    Session session, {
    required String walletAddress,
    required String nonce,
    required DateTime issuedAt,
    required DateTime expiresAt,
  }) {
    final config =
        session.serverpod.config.webServer ??
        session.serverpod.config.apiServer;
    final defaultPort = switch (config.publicScheme) {
      'http' => 80,
      'https' => 443,
      _ => null,
    };
    final uri = Uri(
      scheme: config.publicScheme,
      host: config.publicHost,
      port: config.publicPort == defaultPort ? null : config.publicPort,
    );
    return [
      '${uri.authority} wants you to link a Solana payout wallet to your Verily account:',
      walletAddress,
      '',
      _statement,
      '',
      'URI: $uri',
      'Version: 1',
      'Nonce: $nonce',
      'Issued At: ${issuedAt.toIso8601String()}',
      'Expiration Time: ${expiresAt.toIso8601String()}',
    ].join('\n');
  }
}

PayoutWalletView _view(PayoutWallet wallet) => PayoutWalletView(
  walletAddress: wallet.walletAddress,
  label: solanaWalletLabel(wallet.walletAddress),
  linkedAt: wallet.linkedAt,
);
