import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:solana_kit/solana_kit.dart';
import 'package:solana_kit_rpc_api/solana_kit_rpc_api.dart' as rpc_api;
import 'package:solana_kit_rpc_types/solana_kit_rpc_types.dart' as rpc_types;
import 'package:solana_kit_token/solana_kit_token.dart' as spl;
import 'package:verily_escrow_client/verily_escrow.dart' as escrow;
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';

/// Exact byte length of a `RewardEscrow` account: discriminator, schema
/// version, and the packed fields. The program decodes at exactly this size.
const rewardEscrowAccountSize = 435;

/// `ReleasePayout` follows the recipient's idempotent token-account creation.
const _releaseInstructionIndex = 1;

const _rewardEscrowSeed = 'reward-escrow';
const _maxPayouts = 2048;
const int _minRefundDelaySeconds = 3 * Duration.secondsPerDay;
const int _maxRefundDelaySeconds = 30 * Duration.secondsPerDay;

final Uint8List _pdaMarker = Uint8List.fromList(
  utf8.encode('ProgramDerivedAddress'),
);
final RegExp _failedProgramLog = RegExp(r'^Program (\S+) failed: ');

/// A chain read or write the gateway could not complete.
///
/// [code] is stable and safe to persist or show to operators. Messages never
/// carry RPC URLs, provider text, or key material.
final class SolanaRewardEscrowException implements Exception {
  const SolanaRewardEscrowException(
    this.code,
    this.message, {
    this.retryable = false,
  });

  final String code;
  final String message;
  final bool retryable;

  @override
  String toString() => 'SolanaRewardEscrowException($code): $message';
}

/// The `verily_escrow` program on a real Solana cluster.
///
/// Every value the server acts on is read from chain state and checked
/// before use: account owners, exact sizes, the discriminator and schema
/// version, the PDA derivation and canonical bump, the stored invariants, the
/// vault's token account, and the terms against the server's own pool row.
///
/// Commitments:
///
/// - Funding is verified at `finalized`, because a published reward cannot
///   be taken back from participants if its funding block were dropped.
/// - The released bitmap behind [isPayoutReleased] is read at `finalized`,
///   because the payout job marks a payout paid on it without a signature of
///   its own.
/// - A release is simulated against `confirmed` state and reported as
///   [RewardReleased] once its own signature is `confirmed` without error: a
///   supermajority voted on it, and the watcher reconciles every
///   `PayoutReleased` event against the database.
///
/// The arbiter and the fee payer are separate keys. The arbiter only signs
/// `ReleasePayout`; the fee payer pays transaction fees and the recipient's
/// token-account rent, so a participant never needs SOL to be paid.
final class SolanaRewardEscrowGateway implements RewardEscrowGateway {
  SolanaRewardEscrowGateway({
    required this.rpc,
    required this.cluster,
    required this.token,
    required this.arbiter,
    required this.feePayer,
    this.programAddress = escrow.verilyEscrowProgramAddress,
    this.confirmationTimeout = const Duration(seconds: 60),
    this.confirmationPollInterval = const Duration(seconds: 1),
    DateTime Function()? clock,
  }) : clock = clock ?? (() => DateTime.now().toUtc()),
       mint = Address(token.mint) {
    if (arbiter.address == feePayer.address) {
      throw ArgumentError(
        'The reward arbiter and fee payer must be different keys.',
      );
    }
  }

  final Rpc rpc;
  final RewardCluster cluster;
  final RewardToken token;

  /// Signs `ReleasePayout` and nothing else.
  final TransactionPartialSigner arbiter;

  /// Pays fees and recipients' token-account rent.
  final TransactionPartialSigner feePayer;
  final Address programAddress;

  /// The only mint this gateway escrows or pays.
  final Address mint;

  /// Upper bound on waiting for a sent release to confirm.
  final Duration confirmationTimeout;
  final Duration confirmationPollInterval;
  final DateTime Function() clock;

  @override
  bool get isAvailable => true;

  /// Refuses an RPC endpoint on another cluster, a missing or
  /// non-executable escrow program, or a reward mint that is not the
  /// expected classic SPL Token mint with the expected decimals.
  Future<void> verifyChainIdentity({required String genesisHash}) async {
    final observed = await _send(rpc.request<Object?>('getGenesisHash'));
    if (observed != genesisHash) {
      throw StateError('The Solana RPC endpoint serves another cluster.');
    }
    final [program, mintAccount] = await _readAccounts([
      programAddress,
      mint,
    ], rpc_types.Commitment.finalized);
    if (program == null || !program.executable) {
      throw StateError('The reward escrow program is not deployed.');
    }
    if (mintAccount == null || mintAccount.owner != tokenProgramAddress) {
      throw StateError('The reward mint is not a classic SPL Token mint.');
    }
    final spl.Mint decoded;
    try {
      if (mintAccount.data.length != spl.mintSize) {
        throw const FormatException('Unexpected mint size.');
      }
      decoded = spl.getMintDecoder().decode(mintAccount.data);
    } on Object {
      throw StateError('The reward mint account is not a valid mint.');
    }
    if (!decoded.isInitialized || decoded.decimals != token.decimals) {
      throw StateError('The reward mint does not have the expected decimals.');
    }
  }

  @override
  String arbiterAddress(RewardCluster cluster) {
    _requireCluster(cluster);
    return arbiter.address.value;
  }

  @override
  String deriveEscrowAddress({
    required RewardCluster cluster,
    required String creatorWallet,
    required UuidValue poolId,
  }) {
    _requireCluster(cluster);
    return findRewardEscrowAddress(
      programAddress: programAddress,
      creator: _parseAddress(creatorWallet, 'creatorWallet'),
      poolId: poolId.toBytes(),
    ).$1.value;
  }

  @override
  Future<String> buildOpenEscrowTransaction(RewardPool pool) async {
    final target = await _verifiedTarget(pool);
    _requireFundableTerms(pool);
    final creatorToken = _associatedTokenAddress(target.creator);
    final instruction = escrow.getOpenEscrowInstruction(
      programAddress: programAddress,
      creator: target.creator,
      escrow: target.escrow,
      vault: target.vault,
      creatorToken: creatorToken,
      mint: mint,
      tokenProgram: tokenProgramAddress,
      associatedTokenProgram: associatedTokenProgramAddress,
      systemProgram: systemProgramAddress,
      poolId: target.poolId,
      arbiter: arbiter.address,
      amountPerPayout: BigInt.from(pool.amountPerPayout),
      maxPayouts: pool.maxPayouts,
      expiresAt: BigInt.from(_unixSeconds(pool.expiresAt)),
      refundDelay: pool.refundDelaySeconds,
    );
    return _unsignedCreatorTransaction(target.creator, instruction);
  }

  @override
  Future<String> buildEndEarlyTransaction(RewardPool pool) async {
    final target = await _verifiedTarget(pool);
    return _unsignedCreatorTransaction(
      target.creator,
      escrow.getEndEarlyInstruction(
        programAddress: programAddress,
        creator: target.creator,
        escrow: target.escrow,
      ),
    );
  }

  /// Reads the escrow at the address this gateway derives from the pool's
  /// creator and id, at `finalized`.
  ///
  /// The reported vault balance is what the escrow can actually pay from its
  /// recorded vault: zero when the vault is missing, is not the escrow's
  /// associated token account for its mint, is not an SPL Token account of
  /// that mint owned by the escrow, or is frozen. Funding then fails on the
  /// vault balance instead of trusting a vault that cannot pay.
  @override
  Future<RewardEscrowAccountState?> readEscrow(RewardPool pool) async {
    final creatorWallet = pool.creatorWallet;
    final poolId = pool.id;
    if (creatorWallet == null || poolId == null || pool.escrowAddress == null) {
      return null;
    }
    final target = _target(pool, creatorWallet, poolId);
    final [escrowAccount, vaultAccount] = await _readAccounts([
      target.escrow,
      target.vault,
    ], rpc_types.Commitment.finalized);
    final state = _escrowState(target.escrow, escrowAccount);
    if (state == null) return null;
    return RewardEscrowAccountState(
      escrowAddress: target.escrow.value,
      ownedByEscrowProgram: true,
      creator: state.creator.value,
      arbiter: state.arbiter.value,
      mint: state.mint.value,
      poolId: UuidValue.fromByteList(state.poolId),
      amountPerPayout: state.amountPerPayout,
      maxPayouts: state.maxPayouts,
      releasedCount: state.releasedCount,
      expiresAt: _dateTime(state.expiresAt),
      refundAfter: _dateTime(state.refundAfter),
      refundDelaySeconds: state.refundDelay,
      vaultBalance: state.vault == target.vault
          ? _usableVaultBalance(target.escrow, state.mint, vaultAccount)
          : 0,
    );
  }

  @override
  Future<RewardReleaseOutcome> releasePayout({
    required RewardPool pool,
    required int payoutIndex,
    required String recipientWallet,
  }) async {
    try {
      return await _release(pool, payoutIndex, recipientWallet);
    } on SolanaRewardEscrowException catch (error) {
      return RewardReleaseFailed(error.code, retryable: error.retryable);
    }
  }

  /// Bit [payoutIndex] of the escrow's released bitmap at `finalized`.
  ///
  /// Throws [SolanaRewardEscrowException] when the answer is unknown: the
  /// escrow account is gone (closed, so only its `EscrowClosed` event holds
  /// the final bitmap, which the server does not record yet), it is not the
  /// escrow this pool funded, or the RPC endpoint cannot be read. The payout
  /// job never marks a payout paid on an unknown.
  @override
  Future<bool> isPayoutReleased({
    required RewardPool pool,
    required int payoutIndex,
  }) async {
    final target = _fundedTarget(pool);
    final state = _escrowState(
      target.escrow,
      (await _readAccounts([
        target.escrow,
      ], rpc_types.Commitment.finalized)).single,
    );
    if (state == null) {
      throw const SolanaRewardEscrowException(
        'escrow_closed_bitmap_unknown',
        'The escrow account is closed and its final released bitmap is not '
            'recorded, so this payout cannot be settled from chain state.',
      );
    }
    _requireSameEscrow(pool, target, state);
    if (payoutIndex < 0 || payoutIndex >= state.maxPayouts) {
      throw const SolanaRewardEscrowException(
        'payout_index_out_of_range',
        'The payout index is outside the escrow.',
      );
    }
    return state.isReleased(payoutIndex);
  }

  Future<RewardReleaseOutcome> _release(
    RewardPool pool,
    int payoutIndex,
    String recipientWallet,
  ) async {
    final target = _fundedTarget(pool);
    if (payoutIndex < 0 || payoutIndex >= pool.maxPayouts) {
      return const RewardReleaseFailed(
        'payout_index_out_of_range',
        retryable: false,
      );
    }
    if (!isAddress(recipientWallet) ||
        Address(recipientWallet) == target.escrow) {
      return const RewardReleaseFailed('invalid_recipient', retryable: false);
    }
    final recipient = Address(recipientWallet);

    // The latest view: an index already set or an escrow already closed is
    // answered without sending anything.
    final state = _escrowState(
      target.escrow,
      (await _readAccounts([
        target.escrow,
      ], rpc_types.Commitment.confirmed)).single,
    );
    if (state == null) {
      return const RewardReleaseFailed('escrow_closed', retryable: false);
    }
    _requireSameEscrow(pool, target, state);
    _requireNotReplaced(pool, state);
    if (payoutIndex >= state.maxPayouts) {
      return const RewardReleaseFailed(
        'payout_index_out_of_range',
        retryable: false,
      );
    }
    if (state.isReleased(payoutIndex)) {
      return _alreadyReleased(pool, payoutIndex);
    }

    final recipientToken = _associatedTokenAddress(recipient);
    final latest = await _latestBlockhash();
    final message = createTransactionMessage(version: TransactionVersion.v0)
        .withFeePayer(feePayer.address)
        .withBlockhashLifetime(
          BlockhashLifetimeConstraint(
            blockhash: latest.blockhash.value,
            lastValidBlockHeight: latest.lastValidBlockHeight,
          ),
        )
        .appendInstructions([
          spl.getCreateAssociatedTokenIdempotentInstruction(
            programAddress: associatedTokenProgramAddress,
            payer: feePayer.address,
            ata: recipientToken,
            owner: recipient,
            mint: mint,
            systemProgram: systemProgramAddress,
            tokenProgram: tokenProgramAddress,
          ),
          escrow.getReleasePayoutInstruction(
            programAddress: programAddress,
            arbiter: arbiter.address,
            escrow: target.escrow,
            vault: target.vault,
            recipientToken: recipientToken,
            mint: mint,
            tokenProgram: tokenProgramAddress,
            index: payoutIndex,
          ),
        ]);
    final unsigned = compileTransaction(message);
    if (!_sameSigners(unsigned, {feePayer.address, arbiter.address})) {
      throw StateError('The release transaction names an unexpected signer.');
    }
    final Transaction signed;
    try {
      signed = await signTransactionWithSigners([feePayer, arbiter], unsigned);
    } on Object {
      return const RewardReleaseFailed('signer_unavailable', retryable: true);
    }
    final signature = getSignatureFromTransaction(signed);

    try {
      await rpc
          .sendTransaction(
            getBase64EncodedWireTransaction(signed),
            const rpc_api.SendTransactionConfig(
              encoding: rpc_types.WireTransactionEncoding.base64,
              preflightCommitment: rpc_types.Commitment.confirmed,
            ),
          )
          .send();
    } on Object catch (error) {
      // A failed preflight proves nothing was sent. Any other failure may
      // have reached the node before the response was lost, so the
      // signature decides below.
      if (error is SolanaError &&
          error.code ==
              SolanaErrorCode
                  .jsonRpcServerErrorSendTransactionPreflightFailure) {
        final outcome = await _failure(
          error.context['cause'],
          _logs(error.context['logs']),
          pool,
          payoutIndex,
        );
        if (outcome != null) return outcome;
      }
    }
    return _awaitRelease(
      signature,
      lastValidBlockHeight: latest.lastValidBlockHeight,
      pool: pool,
      payoutIndex: payoutIndex,
    );
  }

  /// Polls [signature] until it confirms, fails, can no longer land, or the
  /// bounded wait ends. An unknown outcome is retryable: the bitmap makes a
  /// retry of the same index safe.
  Future<RewardReleaseOutcome> _awaitRelease(
    Signature signature, {
    required BigInt lastValidBlockHeight,
    required RewardPool pool,
    required int payoutIndex,
  }) async {
    final elapsed = Stopwatch()..start();
    while (true) {
      try {
        var status = await _signatureStatus(signature, history: false);
        if (status == null && await _blockHeight() > lastValidBlockHeight) {
          // The blockhash expired, so the transaction can no longer land; a
          // last look with history catches one that landed just before.
          status = await _signatureStatus(signature, history: true);
          if (status == null) {
            return const RewardReleaseFailed(
              'blockhash_expired',
              retryable: true,
            );
          }
        }
        if (status != null) {
          final error = status['err'];
          if (error != null) {
            return await _failure(
                  getSolanaErrorFromTransactionError(error),
                  await _transactionLogs(signature),
                  pool,
                  payoutIndex,
                ) ??
                const RewardReleaseFailed(
                  'release_unconfirmed',
                  retryable: true,
                );
          }
          final level = status['confirmationStatus'];
          if (level == 'confirmed' || level == 'finalized') {
            return RewardReleased(signature.value);
          }
        }
      } on SolanaRewardEscrowException {
        // A transient read failure; keep waiting within the bound.
      }
      if (elapsed.elapsed >= confirmationTimeout) {
        return const RewardReleaseFailed(
          'release_unconfirmed',
          retryable: true,
        );
      }
      await Future<void>.delayed(confirmationPollInterval);
    }
  }

  /// Maps a failed release to an outcome, or null when the transaction was
  /// already processed and its own status decides.
  Future<RewardReleaseOutcome?> _failure(
    Object? cause,
    List<String>? logs,
    RewardPool pool,
    int payoutIndex,
  ) async {
    if (cause is! SolanaError) {
      return const RewardReleaseFailed('release_rejected', retryable: true);
    }
    switch (cause.code) {
      case SolanaErrorCode.transactionErrorAlreadyProcessed:
        return null;
      case SolanaErrorCode.transactionErrorBlockhashNotFound:
        return const RewardReleaseFailed('blockhash_expired', retryable: true);
      case SolanaErrorCode.transactionErrorInsufficientFundsForFee ||
          SolanaErrorCode.transactionErrorInsufficientFundsForRent:
        return const RewardReleaseFailed(
          'fee_payer_underfunded',
          retryable: true,
        );
      case SolanaErrorCode.instructionErrorCustom:
        final instructionIndex = _integer(cause.context['index']);
        final code = _integer(cause.context['code']);
        // A custom code is meaningful only next to the program that raised
        // it: the escrow's codes overlap SPL Token's. The runtime logs the
        // innermost failing program first.
        final failing = failingProgram(logs);
        if (failing == programAddress &&
            instructionIndex == _releaseInstructionIndex &&
            code != null) {
          return _programFailure(code, pool, payoutIndex);
        }
        if (failing == tokenProgramAddress) {
          return switch (code) {
            spl.tokenErrorAccountFrozen => const RewardReleaseFailed(
              'token_account_frozen',
              retryable: false,
            ),
            spl.tokenErrorInsufficientFunds => const RewardReleaseFailed(
              'vault_underfunded',
              retryable: false,
            ),
            _ => const RewardReleaseFailed(
              'token_transfer_failed',
              retryable: false,
            ),
          };
        }
        return _instructionFailure(instructionIndex);
      case _ when cause.context.containsKey('index'):
        return _instructionFailure(_integer(cause.context['index']));
      case _:
        return const RewardReleaseFailed('release_rejected', retryable: true);
    }
  }

  RewardReleaseOutcome _instructionFailure(int? instructionIndex) =>
      instructionIndex == _releaseInstructionIndex
      ? const RewardReleaseFailed('release_rejected', retryable: false)
      // The recipient's token account could not be created, most often
      // because the fee payer is short of rent.
      : const RewardReleaseFailed('recipient_account_failed', retryable: true);

  Future<RewardReleaseOutcome> _programFailure(
    int code,
    RewardPool pool,
    int payoutIndex,
  ) async {
    return switch (code) {
      escrow.verilyEscrowErrorPayoutAlreadyReleased => await _alreadyReleased(
        pool,
        payoutIndex,
      ),
      escrow.verilyEscrowErrorReleaseWindowClosed => const RewardReleaseFailed(
        'refund_window_reached',
        retryable: false,
      ),
      escrow.verilyEscrowErrorPayoutIndexOutOfRange =>
        const RewardReleaseFailed(
          'payout_index_out_of_range',
          retryable: false,
        ),
      escrow.verilyEscrowErrorNotArbiter => const RewardReleaseFailed(
        'arbiter_mismatch',
        retryable: false,
      ),
      escrow.verilyEscrowErrorMintMismatch ||
      escrow.verilyEscrowErrorVaultMismatch => const RewardReleaseFailed(
        'escrow_mismatch',
        retryable: false,
      ),
      escrow.verilyEscrowErrorInvalidRecipient => const RewardReleaseFailed(
        'invalid_recipient',
        retryable: false,
      ),
      _ => const RewardReleaseFailed('release_rejected', retryable: false),
    };
  }

  /// The index is set on chain at some commitment. Only the finalized
  /// bitmap settles it, so a set bit that is not final yet is retried.
  Future<RewardReleaseOutcome> _alreadyReleased(
    RewardPool pool,
    int payoutIndex,
  ) async {
    try {
      if (await isPayoutReleased(pool: pool, payoutIndex: payoutIndex)) {
        return const RewardAlreadyReleased();
      }
    } on SolanaRewardEscrowException catch (error) {
      if (!error.retryable) {
        return RewardReleaseFailed(error.code, retryable: false);
      }
    }
    return const RewardReleaseFailed(
      'release_pending_finality',
      retryable: true,
    );
  }

  /// The pool's escrow as this gateway derives it, after checking the pool
  /// belongs to this gateway's cluster and pays its mint.
  _EscrowTarget _target(
    RewardPool pool,
    String creatorWallet,
    UuidValue poolId,
  ) {
    if (pool.cluster != cluster || pool.mint != mint.value) {
      throw const SolanaRewardEscrowException(
        'pool_not_supported',
        'The pool belongs to another cluster or pays another mint.',
      );
    }
    final creator = _parseAddress(creatorWallet, 'creatorWallet');
    final poolIdBytes = poolId.toBytes();
    final (escrowAddress, _) = findRewardEscrowAddress(
      programAddress: programAddress,
      creator: creator,
      poolId: poolIdBytes,
    );
    return _EscrowTarget(
      creator: creator,
      escrow: escrowAddress,
      vault: _associatedTokenAddress(escrowAddress),
      poolId: poolIdBytes,
    );
  }

  /// The target of a pool whose funding started: its recorded escrow and
  /// arbiter must be exactly this gateway's.
  _EscrowTarget _fundedTarget(RewardPool pool) {
    final creatorWallet = pool.creatorWallet;
    final poolId = pool.id;
    if (creatorWallet == null || poolId == null) {
      throw const SolanaRewardEscrowException(
        'escrow_not_configured',
        'The pool has no escrow yet.',
      );
    }
    final target = _target(pool, creatorWallet, poolId);
    if (pool.escrowAddress != target.escrow.value ||
        pool.arbiterAddress != arbiter.address.value) {
      throw const SolanaRewardEscrowException(
        'escrow_mismatch',
        "The pool's recorded escrow is not this gateway's.",
      );
    }
    return target;
  }

  /// [_fundedTarget], cross-checked against the generated client's own PDA
  /// derivation before a transaction is built for a wallet to sign.
  Future<_EscrowTarget> _verifiedTarget(RewardPool pool) async {
    final target = _fundedTarget(pool);
    final (generated, _) = await escrow.findRewardEscrowPda(
      seeds: escrow.RewardEscrowSeeds(
        creator: target.creator,
        poolId: target.poolId,
      ),
      programAddress: programAddress,
    );
    if (generated != target.escrow) {
      throw StateError('The escrow address derivations disagree.');
    }
    return target;
  }

  /// Refuses terms the program would reject, so a creator is never asked to
  /// sign a transaction that cannot succeed.
  void _requireFundableTerms(RewardPool pool) {
    final expiresAt = _unixSeconds(pool.expiresAt);
    if (pool.amountPerPayout < 1 ||
        pool.amountPerPayout > RewardBounds.maxAmountPerPayoutAtoms ||
        pool.maxPayouts < 1 ||
        pool.maxPayouts > _maxPayouts ||
        pool.refundDelaySeconds < _minRefundDelaySeconds ||
        pool.refundDelaySeconds > _maxRefundDelaySeconds ||
        expiresAt <= _unixSeconds(clock()) ||
        _unixSeconds(pool.refundAfter) != expiresAt + pool.refundDelaySeconds) {
      throw StateError('The pool terms cannot open an escrow.');
    }
  }

  /// Requires [state] to be the escrow [pool] funded: same creator, arbiter,
  /// mint, vault, pool id, and immutable terms. Ending early may move the
  /// expiry, so it is not compared here.
  void _requireSameEscrow(
    RewardPool pool,
    _EscrowTarget target,
    _EscrowState state,
  ) {
    if (state.creator != target.creator ||
        state.arbiter != arbiter.address ||
        state.mint != mint ||
        state.vault != target.vault ||
        !_bytesEqual(state.poolId, target.poolId) ||
        state.amountPerPayout != pool.amountPerPayout ||
        state.maxPayouts != pool.maxPayouts ||
        state.refundDelay != pool.refundDelaySeconds) {
      throw const SolanaRewardEscrowException(
        'escrow_mismatch',
        'The escrow on chain does not match its pool.',
      );
    }
  }

  /// Refuses to release from an escrow that shows fewer releases than the
  /// server recorded. Releases only ever increase, so that is a fresh escrow
  /// opened at the same address after this pool's escrow closed, which this
  /// pool never funded and must never pay from.
  ///
  /// Only meaningful on a `confirmed` read: the server records a release
  /// once it is confirmed, so a finalized read may lag behind it. The
  /// refusal is retryable because a lagging RPC node looks the same, and a
  /// retry only checks again.
  void _requireNotReplaced(RewardPool pool, _EscrowState state) {
    if (state.releasedCount < pool.payoutsReleased) {
      throw const SolanaRewardEscrowException(
        'escrow_replaced',
        'The escrow at this address shows fewer releases than this pool '
            'recorded.',
        retryable: true,
      );
    }
  }

  /// Decodes a fetched escrow account, or null when none exists. An account
  /// the system program owns holds only lamports someone sent to the
  /// address, which is not an escrow.
  _EscrowState? _escrowState(Address address, _Account? account) {
    if (account == null) return null;
    if (account.owner == systemProgramAddress && account.data.isEmpty) {
      return null;
    }
    if (account.owner != programAddress) {
      throw const SolanaRewardEscrowException(
        'escrow_invalid',
        'The escrow address holds an account the program does not own.',
      );
    }
    final state = _decodeRewardEscrowAccount(account.data);
    if (findRewardEscrowAddress(
          programAddress: programAddress,
          creator: state.creator,
          poolId: state.poolId,
        ) !=
        (address, state.bump)) {
      throw const SolanaRewardEscrowException(
        'escrow_invalid',
        'The escrow is not at its canonical address.',
      );
    }
    return state;
  }

  int _usableVaultBalance(
    Address escrowAddress,
    Address mint,
    _Account? vault,
  ) {
    if (vault == null ||
        vault.owner != tokenProgramAddress ||
        vault.data.length != spl.tokenSize) {
      return 0;
    }
    final spl.Token account;
    try {
      account = spl.getTokenDecoder().decode(vault.data);
    } on Object {
      return 0;
    }
    if (account.mint != mint ||
        account.owner != escrowAddress ||
        account.state != spl.AccountState.initialized ||
        !account.amount.isValidInt) {
      return 0;
    }
    return account.amount.toInt();
  }

  Future<String> _unsignedCreatorTransaction(
    Address creator,
    Instruction instruction,
  ) async {
    final latest = await _latestBlockhash();
    final transaction = compileTransaction(
      createTransactionMessage(version: TransactionVersion.v0)
          .withFeePayer(creator)
          .withBlockhashLifetime(
            BlockhashLifetimeConstraint(
              blockhash: latest.blockhash.value,
              lastValidBlockHeight: latest.lastValidBlockHeight,
            ),
          )
          .appendInstructions([instruction]),
    );
    // Only the creator's wallet signs; Verily's keys never appear here.
    if (!_sameSigners(transaction, {creator})) {
      throw StateError('The creator transaction names an unexpected signer.');
    }
    return getBase64EncodedWireTransaction(transaction);
  }

  Future<LatestBlockhashValue> _latestBlockhash() async => (await _send(
    rpc.getLatestBlockhashValue(
      const rpc_api.GetLatestBlockhashConfig(
        commitment: rpc_types.Commitment.confirmed,
      ),
    ),
  )).value;

  Future<BigInt> _blockHeight() async => _send(
    rpc.getBlockHeight(
      const rpc_api.GetBlockHeightConfig(
        commitment: rpc_types.Commitment.confirmed,
      ),
    ),
  );

  Future<Map<String, Object?>?> _signatureStatus(
    Signature signature, {
    required bool history,
  }) async {
    final response = await _send(
      rpc.getSignatureStatuses(
        [signature],
        rpc_api.GetSignatureStatusesConfig(searchTransactionHistory: history),
      ),
    );
    final values = response['value'];
    if (values is! List<Object?> || values.length != 1) {
      throw const SolanaRewardEscrowException(
        'rpc_invalid_response',
        'The RPC endpoint returned an invalid signature status.',
        retryable: true,
      );
    }
    final status = values.single;
    if (status == null) return null;
    if (status is! Map) {
      throw const SolanaRewardEscrowException(
        'rpc_invalid_response',
        'The RPC endpoint returned an invalid signature status.',
        retryable: true,
      );
    }
    return status.cast<String, Object?>();
  }

  /// The complete logs of a landed transaction, or null when they cannot be
  /// read. Without logs a custom error cannot be attributed to a program.
  Future<List<String>?> _transactionLogs(Signature signature) async {
    try {
      final transaction = await _send(
        rpc.getTransaction(
          signature,
          const rpc_api.GetTransactionConfig(
            commitment: rpc_types.Commitment.confirmed,
            encoding: rpc_types.TransactionEncoding.json,
            maxSupportedTransactionVersion: 0,
          ),
        ),
      );
      final meta = transaction?['meta'];
      return meta is Map ? _logs(meta['logMessages']) : null;
    } on SolanaRewardEscrowException {
      return null;
    }
  }

  Future<List<_Account?>> _readAccounts(
    List<Address> addresses,
    rpc_types.Commitment commitment,
  ) async {
    final response = await _send(
      rpc.getMultipleAccountsValue(
        addresses,
        rpc_api.GetMultipleAccountsConfig(
          commitment: commitment,
          encoding: rpc_types.AccountEncoding.base64,
        ),
      ),
    );
    final accounts = response.value;
    if (accounts.length != addresses.length) {
      throw const SolanaRewardEscrowException(
        'rpc_invalid_response',
        'The RPC endpoint returned the wrong number of accounts.',
        retryable: true,
      );
    }
    return [for (final account in accounts) _Account.parse(account)];
  }

  /// Sends one RPC request. Transport failures can echo the endpoint URL,
  /// which may embed a provider key, so only a fixed message leaves here.
  Future<T> _send<T>(PendingRpcRequest<T> request) async {
    try {
      return await request.send();
    } on Object {
      throw const SolanaRewardEscrowException(
        'rpc_unavailable',
        'The Solana RPC endpoint could not be read.',
        retryable: true,
      );
    }
  }

  Address _associatedTokenAddress(Address owner) =>
      spl.getAssociatedTokenAddressSync(
        owner: owner,
        tokenProgram: tokenProgramAddress,
        mint: mint,
      );

  void _requireCluster(RewardCluster requested) {
    if (requested != cluster) {
      throw StateError('This reward escrow gateway serves another cluster.');
    }
  }
}

/// The escrow PDA for (`creator`, `poolId`) and its canonical bump, using
/// the program's seeds `["reward-escrow", creator, pool_id]`.
///
/// Synchronous because [RewardEscrowGateway.deriveEscrowAddress] is; the
/// gateway cross-checks it against the generated client's asynchronous
/// derivation before building any transaction, and tests pin it to vectors
/// computed by the Rust program's own derivation.
(Address, int) findRewardEscrowAddress({
  required Address programAddress,
  required Address creator,
  required Uint8List poolId,
}) {
  if (poolId.length != 16) {
    throw ArgumentError.value(poolId.length, 'poolId', 'Must be 16 bytes.');
  }
  final seeds = [
    utf8.encode(_rewardEscrowSeed),
    getAddressEncoder().encode(creator),
    poolId,
  ];
  final program = getAddressEncoder().encode(programAddress);
  for (var bump = 255; bump >= 0; bump -= 1) {
    final hash = Uint8List.fromList(
      sha256.convert([
        for (final seed in seeds) ...seed,
        bump,
        ...program,
        ..._pdaMarker,
      ]).bytes,
    );
    if (!compressedPointBytesAreOnCurve(hash)) {
      return (getAddressDecoder().decode(hash), bump);
    }
  }
  throw StateError('No viable bump exists for this escrow.');
}

/// Decodes and validates `RewardEscrow` account bytes with the generated
/// codec, then checks every stored invariant the server relies on. The
/// caller must already have checked that the escrow program owns the
/// account.
_EscrowState _decodeRewardEscrowAccount(Uint8List data) {
  const invalid = SolanaRewardEscrowException(
    'escrow_invalid',
    'The escrow account data is not a valid RewardEscrow.',
  );
  if (data.length != rewardEscrowAccountSize) throw invalid;
  final escrow.RewardEscrow decoded;
  try {
    // Checks the discriminator and the schema version.
    decoded = escrow.getRewardEscrowDecoder().decode(data);
  } on Object {
    throw invalid;
  }
  if (!decoded.amountPerPayout.isValidInt ||
      !decoded.expiresAt.isValidInt ||
      !decoded.refundAfter.isValidInt) {
    throw invalid;
  }
  final state = _EscrowState(
    creator: decoded.creator,
    arbiter: decoded.arbiter,
    mint: decoded.mint,
    vault: decoded.vault,
    poolId: Uint8List.fromList(decoded.poolId),
    amountPerPayout: decoded.amountPerPayout.toInt(),
    maxPayouts: decoded.maxPayouts,
    releasedCount: decoded.releasedCount,
    expiresAt: decoded.expiresAt.toInt(),
    refundAfter: decoded.refundAfter.toInt(),
    refundDelay: decoded.refundDelay,
    bump: decoded.bump,
    released: Uint8List.fromList(decoded.released),
  );
  // The program's own stored-state validation, repeated where it is used.
  if (state.amountPerPayout < 1 ||
      state.maxPayouts < 1 ||
      state.maxPayouts > _maxPayouts ||
      state.releasedCount > state.maxPayouts ||
      state.refundDelay < _minRefundDelaySeconds ||
      state.refundDelay > _maxRefundDelaySeconds ||
      state.refundAfter != state.expiresAt + state.refundDelay ||
      _dateTimeOrNull(state.refundAfter) == null ||
      _dateTimeOrNull(state.expiresAt) == null) {
    throw invalid;
  }
  return state;
}

/// The innermost program that failed in [logs]: the runtime prints the
/// failing CPI callee before each caller that propagates its error.
Address? failingProgram(List<String>? logs) {
  if (logs == null) return null;
  for (final line in logs) {
    final match = _failedProgramLog.firstMatch(line);
    if (match != null && isAddress(match.group(1)!)) {
      return Address(match.group(1)!);
    }
  }
  return null;
}

final class _EscrowTarget {
  const _EscrowTarget({
    required this.creator,
    required this.escrow,
    required this.vault,
    required this.poolId,
  });

  final Address creator;
  final Address escrow;
  final Address vault;
  final Uint8List poolId;
}

/// A decoded, validated `RewardEscrow`.
final class _EscrowState {
  const _EscrowState({
    required this.creator,
    required this.arbiter,
    required this.mint,
    required this.vault,
    required this.poolId,
    required this.amountPerPayout,
    required this.maxPayouts,
    required this.releasedCount,
    required this.expiresAt,
    required this.refundAfter,
    required this.refundDelay,
    required this.bump,
    required this.released,
  });

  final Address creator;
  final Address arbiter;
  final Address mint;
  final Address vault;
  final Uint8List poolId;
  final int amountPerPayout;
  final int maxPayouts;
  final int releasedCount;
  final int expiresAt;
  final int refundAfter;
  final int refundDelay;
  final int bump;
  final Uint8List released;

  /// Bit `index % 8` of byte `index ~/ 8`, as the program sets it.
  bool isReleased(int index) =>
      (released[index ~/ 8] & (1 << (index % 8))) != 0;
}

/// One account from a `base64` RPC read.
final class _Account {
  const _Account({
    required this.owner,
    required this.data,
    required this.executable,
  });

  static _Account? parse(Map<String, Object?>? account) {
    if (account == null) return null;
    final owner = account['owner'];
    final data = account['data'];
    final executable = account['executable'];
    if (owner is! String ||
        !isAddress(owner) ||
        executable is! bool ||
        data is! List<Object?> ||
        data.length != 2 ||
        data.first is! String ||
        data.last != 'base64') {
      throw const SolanaRewardEscrowException(
        'rpc_invalid_response',
        'The RPC endpoint returned an invalid account.',
        retryable: true,
      );
    }
    final Uint8List bytes;
    try {
      bytes = base64Decode(data.first! as String);
    } on FormatException {
      throw const SolanaRewardEscrowException(
        'rpc_invalid_response',
        'The RPC endpoint returned an invalid account.',
        retryable: true,
      );
    }
    return _Account(owner: Address(owner), data: bytes, executable: executable);
  }

  final Address owner;
  final Uint8List data;
  final bool executable;
}

/// RPC numbers arrive as [int] or, after solana_kit's upcasting, [BigInt].
int? _integer(Object? value) => switch (value) {
  final int number => number,
  final BigInt number when number.isValidInt => number.toInt(),
  _ => null,
};

bool _sameSigners(Transaction transaction, Set<Address> expected) {
  final signers = transaction.signatures.keys.toSet();
  return signers.length == expected.length && signers.containsAll(expected);
}

List<String>? _logs(Object? logs) {
  if (logs is! List<Object?>) return null;
  final lines = <String>[];
  for (final line in logs) {
    if (line is! String) return null;
    lines.add(line);
  }
  return lines;
}

Address _parseAddress(String value, String name) {
  if (!isAddress(value)) {
    throw ArgumentError.value('<redacted>', name, 'Not a Solana address.');
  }
  return Address(value);
}

bool _bytesEqual(Uint8List left, Uint8List right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

int _unixSeconds(DateTime value) =>
    value.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

DateTime _dateTime(int seconds) => _dateTimeOrNull(seconds)!;

DateTime? _dateTimeOrNull(int seconds) {
  // DateTime spans ±8.64e15 milliseconds.
  const limit = 8640000000000;
  if (seconds.abs() > limit) return null;
  return DateTime.fromMillisecondsSinceEpoch(
    seconds * Duration.millisecondsPerSecond,
    isUtc: true,
  );
}
