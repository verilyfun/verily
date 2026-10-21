import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// The on-chain `RewardEscrow` account as read by a gateway.
///
/// A gateway reports only what it read from chain state; the server compares
/// every field with its own pool row ([rewardEscrowMismatches]) before an
/// action can publish. The gateway is responsible for the program-owner check
/// and for reading the vault balance from the escrow's own token account.
class RewardEscrowAccountState {
  const RewardEscrowAccountState({
    required this.escrowAddress,
    required this.ownedByEscrowProgram,
    required this.creator,
    required this.arbiter,
    required this.mint,
    required this.poolId,
    required this.amountPerPayout,
    required this.maxPayouts,
    required this.releasedCount,
    required this.expiresAt,
    required this.refundAfter,
    required this.refundDelaySeconds,
    required this.vaultBalance,
  });

  final String escrowAddress;
  final bool ownedByEscrowProgram;
  final String creator;
  final String arbiter;
  final String mint;
  final UuidValue poolId;
  final int amountPerPayout;
  final int maxPayouts;
  final int releasedCount;
  final DateTime expiresAt;
  final DateTime refundAfter;
  final int refundDelaySeconds;

  /// Atoms currently held by the escrow vault.
  final int vaultBalance;
}

/// The result of asking the escrow to pay one index.
sealed class RewardReleaseOutcome {
  const RewardReleaseOutcome();
}

/// The release transaction confirmed with [signature].
final class RewardReleased extends RewardReleaseOutcome {
  const RewardReleased(this.signature);

  final String signature;
}

/// The program refused with `PayoutAlreadyReleased` and the gateway confirmed
/// from the released bitmap that this index is paid. Only Verily's arbiter
/// releases, and each index belongs to one payout, so this is the earlier
/// attempt of the same payout landing.
final class RewardAlreadyReleased extends RewardReleaseOutcome {
  const RewardAlreadyReleased();
}

/// The release did not happen. [code] is stable and safe to persist; it
/// never contains provider or RPC text.
final class RewardReleaseFailed extends RewardReleaseOutcome {
  const RewardReleaseFailed(this.code, {required this.retryable});

  final String code;

  /// Whether retrying the same index later may succeed. An unknown outcome
  /// (a timeout after sending) is retryable: the bitmap makes it safe.
  final bool retryable;
}

/// Everything the server needs from the `verily_escrow` Pina program.
///
/// The real implementation will sit on the generated Dart client for the
/// program and a Cloud KMS arbiter signer. Tests use an in-memory fake, local
/// development uses `LocalDevelopmentRewardEscrowGateway`, and every other
/// deployment without a real gateway uses [DisabledRewardEscrowGateway], which
/// refuses every call so rewards fail closed.
abstract interface class RewardEscrowGateway {
  /// Whether funding and releases can work at all.
  bool get isAvailable;

  /// The arbiter public key that must be recorded in every escrow.
  String arbiterAddress(RewardCluster cluster);

  /// The escrow PDA for (`creatorWallet`, `poolId`), seeds
  /// `["reward-escrow", creator, pool_id]`.
  String deriveEscrowAddress({
    required RewardCluster cluster,
    required String creatorWallet,
    required UuidValue poolId,
  });

  /// A base64 unsigned `OpenEscrow` transaction for the creator's wallet.
  Future<String> buildOpenEscrowTransaction(RewardPool pool);

  /// A base64 unsigned `EndEarly` transaction for the creator's wallet.
  Future<String> buildEndEarlyTransaction(RewardPool pool);

  /// Reads the finalized escrow account at the pool's address, or null when
  /// none exists yet.
  Future<RewardEscrowAccountState?> readEscrow(RewardPool pool);

  /// Releases payout [payoutIndex] to [recipientWallet], signed by the
  /// arbiter. Creating the recipient's token account is the gateway's job.
  Future<RewardReleaseOutcome> releasePayout({
    required RewardPool pool,
    required int payoutIndex,
    required String recipientWallet,
  });

  /// Reads bit [payoutIndex] of the escrow's released bitmap.
  Future<bool> isPayoutReleased({
    required RewardPool pool,
    required int payoutIndex,
  });
}

/// Used wherever no escrow gateway is configured. Every call refuses with a
/// typed, product-safe error.
class DisabledRewardEscrowGateway implements RewardEscrowGateway {
  const DisabledRewardEscrowGateway();

  @override
  bool get isAvailable => false;

  Never _unavailable() => throw RewardException(
    problem: RewardProblem.rewardsUnavailable,
    message: 'Escrowed rewards are not configured on this server.',
  );

  @override
  String arbiterAddress(RewardCluster cluster) => _unavailable();

  @override
  String deriveEscrowAddress({
    required RewardCluster cluster,
    required String creatorWallet,
    required UuidValue poolId,
  }) => _unavailable();

  @override
  Future<String> buildOpenEscrowTransaction(RewardPool pool) async =>
      _unavailable();

  @override
  Future<String> buildEndEarlyTransaction(RewardPool pool) async =>
      _unavailable();

  @override
  Future<RewardEscrowAccountState?> readEscrow(RewardPool pool) async =>
      _unavailable();

  @override
  Future<RewardReleaseOutcome> releasePayout({
    required RewardPool pool,
    required int payoutIndex,
    required String recipientWallet,
  }) async => const RewardReleaseFailed(
    'escrow_gateway_unavailable',
    retryable: true,
  );

  @override
  Future<bool> isPayoutReleased({
    required RewardPool pool,
    required int payoutIndex,
  }) async => _unavailable();
}

/// Every field of [state] that disagrees with the server's own [pool] row.
///
/// Funding is verified from chain state, never from the client: the escrow
/// must be owned by the program, at the derived address, for this creator,
/// arbiter, mint, pool id, amount, payout count, expiry, and refund delay,
/// unspent, and holding the whole budget.
List<String> rewardEscrowMismatches(
  RewardPool pool,
  RewardEscrowAccountState state,
) {
  final expiresAt = _seconds(pool.expiresAt);
  final refundAfter = _seconds(pool.refundAfter);
  return [
    if (!state.ownedByEscrowProgram) 'owner',
    if (state.escrowAddress != pool.escrowAddress) 'address',
    if (state.creator != pool.creatorWallet) 'creator',
    if (state.arbiter != pool.arbiterAddress) 'arbiter',
    if (state.mint != pool.mint) 'mint',
    if (state.poolId != pool.id) 'poolId',
    if (state.amountPerPayout != pool.amountPerPayout) 'amountPerPayout',
    if (state.maxPayouts != pool.maxPayouts) 'maxPayouts',
    if (_seconds(state.expiresAt) != expiresAt) 'expiresAt',
    if (_seconds(state.refundAfter) != refundAfter) 'refundAfter',
    if (state.refundDelaySeconds != pool.refundDelaySeconds) 'refundDelay',
    if (state.releasedCount != 0) 'releasedCount',
    if (state.vaultBalance < pool.amountPerPayout * pool.maxPayouts)
      'vaultBalance',
  ];
}

int _seconds(DateTime value) =>
    value.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
