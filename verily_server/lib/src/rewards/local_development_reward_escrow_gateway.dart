import 'dart:convert';
import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';

/// LOCAL DEVELOPMENT ONLY. Simulates the escrow so the funding and payout
/// flows run end to end without a Solana cluster.
///
/// Nothing here touches a chain or moves value. Addresses are deterministic
/// hashes, "transactions" are labelled JSON descriptors that no wallet can
/// send, every escrow reads back as exactly matching its pool, and releases
/// return a deterministic `local-dev-…` signature. Startup refuses this
/// gateway outside the development and test run modes.
class LocalDevelopmentRewardEscrowGateway implements RewardEscrowGateway {
  const LocalDevelopmentRewardEscrowGateway();

  @override
  bool get isAvailable => true;

  @override
  String arbiterAddress(RewardCluster cluster) =>
      _address(['verily-local-development-arbiter', cluster.name]);

  @override
  String deriveEscrowAddress({
    required RewardCluster cluster,
    required String creatorWallet,
    required UuidValue poolId,
  }) => _address([
    'verily-local-development-escrow',
    cluster.name,
    creatorWallet,
    poolId.toString(),
  ]);

  @override
  Future<String> buildOpenEscrowTransaction(RewardPool pool) async =>
      _descriptor('OpenEscrow', pool);

  @override
  Future<String> buildEndEarlyTransaction(RewardPool pool) async =>
      _descriptor('EndEarly', pool);

  @override
  Future<RewardEscrowAccountState?> readEscrow(RewardPool pool) async {
    final escrowAddress = pool.escrowAddress;
    final creatorWallet = pool.creatorWallet;
    final arbiter = pool.arbiterAddress;
    if (escrowAddress == null || creatorWallet == null || arbiter == null) {
      return null;
    }
    return RewardEscrowAccountState(
      escrowAddress: escrowAddress,
      ownedByEscrowProgram: true,
      creator: creatorWallet,
      arbiter: arbiter,
      mint: pool.mint,
      poolId: pool.id!,
      amountPerPayout: pool.amountPerPayout,
      maxPayouts: pool.maxPayouts,
      releasedCount: 0,
      expiresAt: pool.expiresAt,
      refundAfter: pool.refundAfter,
      refundDelaySeconds: pool.refundDelaySeconds,
      vaultBalance: pool.amountPerPayout * pool.maxPayouts,
    );
  }

  @override
  Future<RewardReleaseOutcome> releasePayout({
    required RewardPool pool,
    required int payoutIndex,
    required String recipientWallet,
  }) async => RewardReleased('local-dev-${pool.id}-$payoutIndex');

  @override
  Future<bool> isPayoutReleased({
    required RewardPool pool,
    required int payoutIndex,
  }) async => false;

  static String _address(List<String> parts) => base58.encode(
    Uint8List.fromList(sha256.convert(utf8.encode(parts.join('|'))).bytes),
  );

  static String _descriptor(String instruction, RewardPool pool) =>
      base64Encode(
        utf8.encode(
          jsonEncode({
            'localDevelopmentOnly': true,
            'instruction': instruction,
            'poolId': pool.id.toString(),
            'escrow': pool.escrowAddress,
          }),
        ),
      );
}
