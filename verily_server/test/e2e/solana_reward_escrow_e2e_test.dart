// Validator startup, funding finality, and two releases take minutes.
@Timeout(Duration(minutes: 5))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart' hide Transaction;
import 'package:solana_kit/solana_kit.dart';
import 'package:solana_kit_rpc_api/solana_kit_rpc_api.dart' as rpc_api;
import 'package:solana_kit_rpc_types/solana_kit_rpc_types.dart' as rpc_types;
import 'package:solana_kit_token/solana_kit_token.dart' as spl;
import 'package:test/test.dart';
import 'package:verily_escrow_client/verily_escrow.dart' as escrow;
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';
import 'package:verily_server/src/rewards/solana_reward_escrow_configuration.dart';
import 'package:verily_server/src/rewards/solana_reward_escrow_gateway.dart';

import '../integration/test_tools/fake_reward_escrow_gateway.dart'
    show RecordingRewardPayoutScheduler, completedLocationAttempt, rewardTerms;
import '../integration/test_tools/serverpod_test_tools.dart';
import '../integration/test_tools/verily_fixtures.dart';

/// Opt-in: the path of the compiled program (`target/deploy/verily_escrow.so`
/// from `devenv shell build:escrow`). `devenv shell test:escrow:e2e` sets it.
final String? _programPath = Platform.environment['VERILY_ESCROW_E2E_PROGRAM'];

/// Public, test-only keys for a throwaway local ledger. They hold nothing.
KeyPairSigner _signer(int seed) => createKeyPairSignerFromPrivateKeyBytes(
  Uint8List.fromList(List<int>.filled(32, seed)),
);

const _usdc = 1000000;

void main() {
  final programPath = _programPath;
  if (programPath == null) {
    test(
      'the Solana reward escrow runs end to end on a local validator',
      () {},
      skip:
          'Opt-in: run `devenv shell test:escrow:e2e`, which builds the '
          'program and sets VERILY_ESCROW_E2E_PROGRAM.',
    );
    return;
  }

  late _LocalValidator validator;
  late SolanaRewardEscrowGateway gateway;
  final mintAuthority = _signer(31);
  final arbiter = _signer(41);
  final feePayer = _signer(42);
  // Seeds 11, 21, and 22 are the payout wallets of the fixtures' TestWallet.
  final creator = _signer(11);
  final firstWallet = TestWallet.fromSeed(21);
  final secondWallet = TestWallet.fromSeed(22);
  final usdc = Address(rewardTokens[RewardCluster.devnet]!.mint);

  setUpAll(() async {
    validator = await _LocalValidator.start(
      programPath: programPath,
      // The devnet USDC address with a mint this test controls, so the
      // gateway's allow-list and startup decimals check run unchanged.
      accounts: {usdc: _mintAccount(mintAuthority.address)},
    );
    for (final signer in [mintAuthority, feePayer, creator]) {
      await validator.airdrop(signer.address);
    }
    final creatorToken = spl.getAssociatedTokenAddressSync(
      owner: creator.address,
      tokenProgram: tokenProgramAddress,
      mint: usdc,
    );
    await validator.send(
      [
        spl.getCreateAssociatedTokenIdempotentInstruction(
          programAddress: associatedTokenProgramAddress,
          payer: mintAuthority.address,
          ata: creatorToken,
          owner: creator.address,
          mint: usdc,
          systemProgram: systemProgramAddress,
          tokenProgram: tokenProgramAddress,
        ),
        spl.getMintToCheckedInstruction(
          programAddress: tokenProgramAddress,
          mint: usdc,
          token: creatorToken,
          mintAuthority: mintAuthority.address,
          amount: BigInt.from(10 * _usdc),
          decimals: 6,
        ),
      ],
      feePayer: mintAuthority,
    );

    // Startup exactly as the server runs it: configuration from settings,
    // keypair consistency and pinning, genesis, program, and mint decimals.
    gateway = await connectSolanaRewardEscrow(
      SolanaRewardEscrowConfiguration.fromEnvironment(
        runMode: ServerpodRunMode.test,
        cluster: RewardCluster.devnet,
        environment: {
          'VERILY_REWARD_SIGNER': 'local-keypair',
          'VERILY_REWARD_ARBITER_ADDRESS': arbiter.address.value,
          'VERILY_REWARD_FEE_PAYER_ADDRESS': feePayer.address.value,
          'VERILY_REWARD_SOLANA_GENESIS_HASH': await validator.genesisHash(),
        },
        readPassword: (alias) => switch (alias) {
          'rewardSolanaRpcUrl' => validator.url,
          'rewardArbiterKeypair' => _keypairJson(arbiter),
          'rewardFeePayerKeypair' => _keypairJson(feePayer),
          _ => null,
        },
      ),
    );
  });

  tearDownAll(() async => validator.stop());

  withServerpod('Given the escrow program on a local validator', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x901);
    final firstId = testId(0x902);
    final secondId = testId(0x903);
    late TestSessionBuilder creatorSession;
    late TestSessionBuilder first;
    late TestSessionBuilder second;
    late RewardPayoutService payouts;

    setUp(() async {
      RewardRuntime.current = RewardConfiguration(
        gateway: gateway,
        cluster: RewardCluster.devnet,
        reviewThresholdAtoms: defaultRewardReviewThresholdAtoms,
      );
      payouts = RewardPayoutService(
        configuration: RewardRuntime.current,
        scheduler: RecordingRewardPayoutScheduler(),
      );
      creatorSession = signedIn(sessionBuilder, creatorId);
      first = signedIn(sessionBuilder, firstId);
      second = signedIn(sessionBuilder, secondId);
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {
        creatorId: 'Ada',
        firstId: 'Grace',
        secondId: 'Katherine',
      });
      await linkWallet(endpoints, creatorSession, TestWallet.fromSeed(11));
      await linkWallet(endpoints, first, firstWallet);
      await linkWallet(endpoints, second, secondWallet);
    });

    tearDown(() {
      RewardRuntime.current = const RewardConfiguration.disabled();
    });

    test('when a creator funds an escrow and two participants complete the '
        'action then each is paid exactly once, including a retried '
        'release', () async {
      final session = sessionBuilder.build();
      Future<RewardPool> pool() async => (await RewardPool.db.findFirstRow(
        session,
        where: (table) => table.creatorAuthUserId.equals(creatorId),
      ))!;

      // Funding: the creator signs the server's unsigned transaction, and
      // the server confirms it only from finalized chain state.
      final draft = await endpoints.actionVerification.saveActionDraft(
        creatorSession,
        actionRequest(
          actionKey: 'e2e-plant-a-tree',
          requirements: [locationRequirement()],
          reward: rewardTerms(),
        ),
      );
      final plan = await endpoints.rewards.prepareRewardFunding(
        creatorSession,
        actionId: draft.id,
      );
      expect(plan.creatorWallet, creator.address.value);
      expect(plan.arbiterAddress, arbiter.address.value);
      expect(plan.totalAtoms, 3 * _usdc);
      final fundingSignature = await validator.sendWire(
        plan.unsignedTransaction,
        signer: creator,
      );

      var notFinalYet = 0;
      final funded = await _eventually(() async {
        try {
          return await endpoints.rewards.confirmRewardFunding(
            creatorSession,
            actionId: draft.id,
            signature: fundingSignature,
          );
        } on RewardException catch (error) {
          if (error.problem != RewardProblem.escrowNotFound) rethrow;
          notFinalYet += 1;
          return null;
        }
      });
      expect(funded.status, RewardPoolStatus.funded);
      expect(funded.escrowAddress, plan.escrowAddress);
      // Confirmed is not enough: the read waits for finalized state.
      expect(notFinalYet, greaterThan(0));

      final action = await endpoints.actionVerification.publishAction(
        creatorSession,
        actionId: draft.id,
        expectedRevision: draft.revision,
      );

      // The first payout releases normally.
      final firstAttempt = await completedLocationAttempt(
        endpoints,
        first,
        action: action,
        idempotencyKey: 'e2e-first',
      );
      final firstPayout = (await _payoutFor(session, firstAttempt.id))!;
      expect(firstPayout.payoutIndex, 0);
      await payouts.release(session, firstPayout.id!);
      final firstReleased = (await RewardPayout.db.findById(
        session,
        firstPayout.id!,
      ))!;
      expect(firstReleased.status, RewardPayoutStatus.released);
      expect(
        await validator.tokenBalance(firstWallet.address, usdc),
        _usdc,
      );

      // Its event is attributed from the real program's complete logs.
      final events = escrow.parseVerilyEscrowEventsFromLogs(
        await validator.logs(firstReleased.releaseSignature!),
      );
      final released = events.single as escrow.PayoutReleasedEvent;
      expect(released.escrow.value, plan.escrowAddress);
      expect(released.index, 0);
      expect(
        released.recipient,
        spl.getAssociatedTokenAddressSync(
          owner: Address(firstWallet.address),
          tokenProgram: tokenProgramAddress,
          mint: usdc,
        ),
      );

      // The second payout's first release lands but its job never records
      // it, like a crash after sending. The retried job must settle it from
      // the bitmap and never pay again.
      final secondAttempt = await completedLocationAttempt(
        endpoints,
        second,
        action: action,
        idempotencyKey: 'e2e-second',
      );
      final secondPayout = (await _payoutFor(session, secondAttempt.id))!;
      expect(secondPayout.payoutIndex, 1);
      expect(
        await gateway.releasePayout(
          pool: await pool(),
          payoutIndex: 1,
          recipientWallet: secondWallet.address,
        ),
        isA<RewardReleased>(),
      );
      await payouts.release(session, secondPayout.id!);
      await _eventually(
        () async =>
            await gateway.isPayoutReleased(pool: await pool(), payoutIndex: 1)
            ? true
            : null,
      );
      if ((await RewardPayout.db.findById(session, secondPayout.id!))!.status !=
          RewardPayoutStatus.released) {
        // The first retry saw the bit before it was final and backed off.
        await payouts.release(session, secondPayout.id!);
      }
      final secondReleased = (await RewardPayout.db.findById(
        session,
        secondPayout.id!,
      ))!;
      expect(secondReleased.status, RewardPayoutStatus.released);
      expect(secondReleased.payoutIndex, 1);
      // Settled from the finalized bitmap: the job sent nothing that paid.
      expect(secondReleased.releaseSignature, isNull);
      expect(
        await gateway.releasePayout(
          pool: await pool(),
          payoutIndex: 1,
          recipientWallet: secondWallet.address,
        ),
        isA<RewardAlreadyReleased>(),
      );
      expect(
        await validator.tokenBalance(secondWallet.address, usdc),
        _usdc,
        reason: 'A retried index must never pay twice.',
      );
      expect(
        await gateway.isPayoutReleased(pool: await pool(), payoutIndex: 2),
        isFalse,
      );
      final state = (await gateway.readEscrow(await pool()))!;
      expect(state.releasedCount, 2);
      expect(state.vaultBalance, _usdc);
      expect((await pool()).payoutsReleased, 2);

      // Ending early moves the on-chain expiry to the chain's now; reserved
      // payouts stay releasable until the refund window.
      final end = await endpoints.rewards.endRewardEarly(
        creatorSession,
        actionId: action.id,
      );
      await validator.sendWire(end.unsignedTransaction, signer: creator);
      final ended = await _eventually(() async {
        final read = await gateway.readEscrow(await pool());
        return read != null && read.expiresAt.isBefore(funded.expiresAt)
            ? read
            : null;
      });
      expect(
        ended.refundAfter.difference(ended.expiresAt).inSeconds,
        3 * 86400,
      );
      expect(
        ended.expiresAt.difference(end.expiresAt).inSeconds.abs(),
        lessThan(120),
      );
    });
  });
}

Future<RewardPayout?> _payoutFor(Session session, UuidValue attemptId) =>
    RewardPayout.db.findFirstRow(
      session,
      where: (table) => table.attemptId.equals(attemptId),
    );

/// Polls [probe] until it returns a value, for at most a minute and a half.
Future<T> _eventually<T extends Object>(Future<T?> Function() probe) async {
  final elapsed = Stopwatch()..start();
  while (true) {
    final value = await probe();
    if (value != null) return value;
    if (elapsed.elapsed > const Duration(seconds: 90)) {
      throw TimeoutException('The local validator did not get there in time.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}

String _keypairJson(KeyPairSigner signer) => jsonEncode([
  ...signer.keyPair.privateKey,
  ...signer.keyPair.publicKey,
]);

/// A classic SPL Token mint with six decimals that [authority] can mint.
Uint8List _mintAccount(Address authority) => spl.getMintEncoder().encode(
  spl.Mint(
    mintAuthority: authority,
    supply: BigInt.zero,
    decimals: 6,
    isInitialized: true,
    freezeAuthority: null,
  ),
);

/// A throwaway `solana-test-validator` with the escrow program loaded at
/// its reviewed address.
final class _LocalValidator {
  _LocalValidator._(this._process, this._directory, this.url)
    : rpc = createSolanaRpc(url: url, allowInsecureHttp: true);

  static Future<_LocalValidator> start({
    required String programPath,
    required Map<Address, Uint8List> accounts,
  }) async {
    if (!File(programPath).existsSync()) {
      throw StateError('Build the program first: devenv shell build:escrow');
    }
    final directory = await Directory.systemTemp.createTemp('verily-escrow-');
    final rpcPort = await _freePort();
    final accountArguments = <String>[];
    for (final MapEntry(key: address, value: data) in accounts.entries) {
      final file = File('${directory.path}/${address.value}.json')
        ..writeAsStringSync(
          jsonEncode({
            'pubkey': address.value,
            'account': {
              'lamports': 1461600,
              'data': [base64Encode(data), 'base64'],
              'owner': tokenProgramAddress.value,
              'executable': false,
              'rentEpoch': 0,
              'space': data.length,
            },
          }),
        );
      accountArguments.addAll(['--account', address.value, file.path]);
    }
    final process = await Process.start(
      Platform.environment['VERILY_ESCROW_E2E_VALIDATOR'] ??
          'solana-test-validator',
      [
        '--reset',
        '--quiet',
        '--ledger',
        '${directory.path}/ledger',
        '--rpc-port',
        '$rpcPort',
        '--faucet-port',
        '${await _freePort()}',
        '--gossip-port',
        '${await _freePort()}',
        '--bpf-program',
        escrow.verilyEscrowProgramAddress.value,
        programPath,
        ...accountArguments,
      ],
    );
    final log = File('${directory.path}/validator.out').openWrite();
    unawaited(process.stdout.pipe(log));
    unawaited(process.stderr.drain<void>());
    final validator = _LocalValidator._(
      process,
      directory,
      'http://127.0.0.1:$rpcPort',
    );
    try {
      await _eventually(() async {
        try {
          final slot = await validator.rpc
              .getSlot(
                const rpc_api.GetSlotConfig(
                  commitment: rpc_types.Commitment.processed,
                ),
              )
              .send();
          return slot > BigInt.one ? slot : null;
        } on Object {
          return null;
        }
      });
    } on Object {
      await validator.stop();
      rethrow;
    }
    return validator;
  }

  final Process _process;
  final Directory _directory;
  final String url;
  final Rpc rpc;

  Future<String> genesisHash() async =>
      (await rpc.request<Object?>('getGenesisHash').send())! as String;

  Future<void> airdrop(Address address) async {
    final signature = await rpc
        .requestAirdrop(address, lamports(BigInt.from(10000000000)))
        .send();
    await _confirmed(signature);
  }

  /// Signs [instructions] with [feePayer] and waits until they confirm.
  Future<String> send(
    List<Instruction> instructions, {
    required KeyPairSigner feePayer,
  }) async {
    final latest = await rpc.getLatestBlockhashValue().send();
    final transaction = compileTransaction(
      createTransactionMessage(version: TransactionVersion.v0)
          .withFeePayer(feePayer.address)
          .withBlockhashLifetime(
            BlockhashLifetimeConstraint(
              blockhash: latest.value.blockhash.value,
              lastValidBlockHeight: latest.value.lastValidBlockHeight,
            ),
          )
          .appendInstructions(instructions),
    );
    return _sendSigned(await signTransaction([feePayer.keyPair], transaction));
  }

  /// Signs a server-built base64 transaction as a wallet would, then sends
  /// it and waits until it confirms.
  Future<String> sendWire(String wire, {required KeyPairSigner signer}) async {
    final transaction = getTransactionDecoder().decode(base64Decode(wire));
    return _sendSigned(await signTransaction([signer.keyPair], transaction));
  }

  Future<String> _sendSigned(Transaction transaction) async {
    final signature = await rpc
        .sendTransaction(
          getBase64EncodedWireTransaction(transaction),
          const rpc_api.SendTransactionConfig(
            encoding: rpc_types.WireTransactionEncoding.base64,
          ),
        )
        .send();
    await _confirmed(signature);
    return signature;
  }

  Future<void> _confirmed(String signature) => _eventually(() async {
    final response = await rpc.getSignatureStatuses([
      Signature(signature),
    ]).send();
    final status = (response['value']! as List<Object?>).single;
    if (status is! Map) return null;
    if (status['err'] != null) {
      throw StateError('Transaction $signature failed: ${status['err']}');
    }
    final level = status['confirmationStatus'];
    return level == 'confirmed' || level == 'finalized' ? true : null;
  });

  /// The complete log messages of [signature].
  Future<List<String>> logs(String signature) async {
    final transaction = await rpc
        .getTransaction(
          Signature(signature),
          const rpc_api.GetTransactionConfig(
            commitment: rpc_types.Commitment.confirmed,
            encoding: rpc_types.TransactionEncoding.json,
            maxSupportedTransactionVersion: 0,
          ),
        )
        .send();
    final meta = transaction!['meta']! as Map;
    return (meta['logMessages']! as List<Object?>).cast<String>();
  }

  /// The atoms [owner]'s associated token account holds for [mint].
  Future<int> tokenBalance(String owner, Address mint) async {
    final account = await rpc
        .getAccountInfoValue(
          spl.getAssociatedTokenAddressSync(
            owner: Address(owner),
            tokenProgram: tokenProgramAddress,
            mint: mint,
          ),
          const rpc_api.GetAccountInfoConfig(
            commitment: rpc_types.Commitment.confirmed,
            encoding: rpc_types.AccountEncoding.base64,
          ),
        )
        .send();
    final data = (account.value!['data']! as List<Object?>).first! as String;
    return spl.getTokenDecoder().decode(base64Decode(data)).amount.toInt();
  }

  Future<void> stop() async {
    _process.kill();
    await _process.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    if (_directory.existsSync()) _directory.deleteSync(recursive: true);
  }
}

Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}
