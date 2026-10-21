import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:solana_kit/solana_kit.dart';
import 'package:solana_kit_token/solana_kit_token.dart' as spl;
import 'package:test/test.dart';
import 'package:verily_escrow_client/verily_escrow.dart' as escrow;
import 'package:verily_server/src/auth/solana_auth_verify.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';
import 'package:verily_server/src/rewards/solana_reward_escrow_gateway.dart';

import 'solana_test_support.dart';

// Bytes written by the Rust program crate itself (`RewardEscrow::initialize`
// and the events' `initialize`, verily_escrow 0.1.0 with Pina 0.23.0) for:
// creator 7v54…, arbiter mBKq…, devnet USDC, vault EHBW…, pool id
// 0198bc26-4be5-7ca0-94d2-000000000042, 1 USDC × 2048 payouts, 2 released
// (indexes 1 and 2047), expiry 1,800,000,000, the 3-day minimum delay, bump
// 254. The events name escrow 5Y4e… and recipient FMUE….
const _rustEscrow =
    'AQBmvn4zLHpFMzK9nQp/fbBV9cXvGgatpm2Ys5+2gQxHOgtROtm0kkAVygkC7QeQRNOsXb7C'
    'MG8GlIwQ2o62458tO0Qss5EhV/E6kz0BNCgtAytf/s0Botvxt3kGCN8ALqfFTRsFC37xGNPe'
    'pBeOYWWAvQb0Krd1w/n8ofWyzg1+8wGYvCZL5XyglNIAAAAAAEJAQg8AAAAAAAAIAgAA0klr'
    'AAAAAIDGTWsAAAAAgPQDAP4CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AACA';
const _rustPayoutReleased =
    'AkNj4B0lJSbC5rLESYlJej1D5eilatLSgaDqXPIJ7OXmAZi8JkvlfKCU0gAAAAAAQgEA1UIH'
    '2hlJd9z0atv+wrwudbUtWopCGE/t/cAAJPDj6NpAQg8AAAAAAA==';
const _rustEscrowClosed =
    'BENj4B0lJSbC5rLESYlJej1D5eilatLSgaDqXPIJ7OXmAZi8JkvlfKCU0gAAAAAAQoB783kA'
    'AAAAAgACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACA';

/// Every code the gateway may persist. None carries provider text.
const _stableCodes = {
  'arbiter_mismatch',
  'blockhash_expired',
  'escrow_closed',
  'escrow_closed_bitmap_unknown',
  'escrow_invalid',
  'escrow_mismatch',
  'escrow_not_configured',
  'escrow_replaced',
  'fee_payer_underfunded',
  'invalid_recipient',
  'payout_index_out_of_range',
  'pool_not_supported',
  'recipient_account_failed',
  'refund_window_reached',
  'release_pending_finality',
  'release_rejected',
  'release_unconfirmed',
  'rpc_invalid_response',
  'rpc_unavailable',
  'signer_unavailable',
  'token_account_frozen',
  'token_transfer_failed',
  'vault_underfunded',
};

Matcher _failed(String code, {required bool retryable}) =>
    isA<RewardReleaseFailed>()
        .having((outcome) => outcome.code, 'code', code)
        .having((outcome) => outcome.retryable, 'retryable', retryable)
        .having((outcome) => _stableCodes, 'stable codes', contains(code));

Matcher _escrowError(String code) => throwsA(
  isA<SolanaRewardEscrowException>()
      .having((error) => error.code, 'code', code)
      .having((error) => error.message, 'message', isNot(contains('http'))),
);

void main() {
  late FakeSolanaRpc chain;

  setUp(() {
    chain = FakeSolanaRpc();
  });

  group('Given the escrow PDA', () {
    test('when derived then it matches the Rust program derivation', () {
      final (address, bump) = findRewardEscrowAddress(
        programAddress: escrow.verilyEscrowProgramAddress,
        creator: creatorAddress,
        poolId: poolIdVector.toBytes(),
      );

      expect(creatorSigner.address, creatorAddress);
      expect(address, escrowAddressVector);
      expect(bump, escrowBumpVector);
      expect(
        testGateway(chain).deriveEscrowAddress(
          cluster: RewardCluster.devnet,
          creatorWallet: creatorAddress.value,
          poolId: poolIdVector,
        ),
        escrowAddressVector.value,
      );
    });

    test('when derived then the generated client agrees', () async {
      final (address, bump) = await escrow.findRewardEscrowPda(
        seeds: escrow.RewardEscrowSeeds(
          creator: creatorAddress,
          poolId: poolIdVector.toBytes(),
        ),
        programAddress: escrow.verilyEscrowProgramAddress,
      );

      expect(address, escrowAddressVector);
      expect(bump, escrowBumpVector);
    });

    test('when the vault is derived then it is the escrow token account', () {
      expect(
        spl.getAssociatedTokenAddressSync(
          owner: escrowAddressVector,
          tokenProgram: tokenProgramAddress,
          mint: devnetUsdc,
        ),
        vaultAddressVector,
      );
    });

    test('when another creator or pool is used then the address changes', () {
      final gateway = testGateway(chain);
      String derive(String creator, String poolId) =>
          gateway.deriveEscrowAddress(
            cluster: RewardCluster.devnet,
            creatorWallet: creator,
            poolId: UuidValue.withValidation(poolId),
          );

      expect(
        derive(recipientAddress.value, poolIdVector.toString()),
        isNot(escrowAddressVector.value),
      );
      expect(
        derive(creatorAddress.value, '0198bc26-4be5-7ca0-94d2-000000000043'),
        isNot(escrowAddressVector.value),
      );
    });

    test('when the cluster is not the gateway cluster then it refuses', () {
      expect(
        () => testGateway(chain).deriveEscrowAddress(
          cluster: RewardCluster.mainnet,
          creatorWallet: creatorAddress.value,
          poolId: poolIdVector,
        ),
        throwsStateError,
      );
      expect(
        () => testGateway(chain).arbiterAddress(RewardCluster.mainnet),
        throwsStateError,
      );
    });
  });

  group('Given bytes written by the Rust program', () {
    test('when the account is decoded then every field and bit matches', () {
      final bytes = base64Decode(_rustEscrow);
      final decoded = escrow.getRewardEscrowDecoder().decode(bytes);

      expect(bytes, hasLength(rewardEscrowAccountSize));
      expect(
        (escrow.getRewardEscrowDecoder()
                as FixedSizeDecoder<escrow.RewardEscrow>)
            .fixedSize,
        rewardEscrowAccountSize,
      );
      expect(decoded.creator, creatorAddress);
      expect(decoded.arbiter, arbiterAddressVector);
      expect(decoded.mint, devnetUsdc);
      expect(decoded.vault, vaultAddressVector);
      expect(decoded.poolId, poolIdVector.toBytes());
      expect(decoded.amountPerPayout, BigInt.from(1000000));
      expect(decoded.maxPayouts, 2048);
      expect(decoded.releasedCount, 2);
      expect(decoded.expiresAt, BigInt.from(1800000000));
      expect(decoded.refundAfter, BigInt.from(1800000000 + 259200));
      expect(decoded.refundDelay, 259200);
      expect(decoded.bump, 254);
      expect(decoded.released[0], 0x02);
      expect(decoded.released[255], 0x80);
      expect(escrow.getRewardEscrowEncoder().encode(decoded), bytes);
    });

    test('when events are read from complete logs then only frames of the '
        'escrow program are attributed', () {
      final program = escrow.verilyEscrowProgramAddress.value;
      final events = escrow.parseVerilyEscrowEventsFromLogs([
        // Outside any frame: never trusted.
        'Program data: $_rustEscrowClosed',
        'Program $program invoke [1]',
        'Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [2]',
        // Emitted inside another program's frame: never trusted.
        'Program data: $_rustEscrowClosed',
        'Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA success',
        'Program data: $_rustPayoutReleased',
        'Program $program success',
        'Program $program invoke [1]',
        'Program data: $_rustEscrowClosed',
        'Program $program success',
      ]);

      expect(events, hasLength(2));
      final released = events.first as escrow.PayoutReleasedEvent;
      expect(released.escrow, escrowAddressVector);
      expect(released.poolId, poolIdVector.toBytes());
      expect(released.index, 1);
      expect(released.recipient, recipientAddress);
      expect(released.amount, BigInt.from(1000000));
      final closed = events.last as escrow.EscrowClosedEvent;
      expect(closed.escrow, escrowAddressVector);
      expect(closed.refunded, BigInt.from(2046000000));
      expect(closed.releasedCount, 2);
      expect(closed.released[0], 0x02);
      expect(closed.released[255], 0x80);
    });

    test('when the gateway reads it then the bitmap order matches the '
        'program', () async {
      chain.putEscrow(base64Decode(_rustEscrow));
      final pool = fundedPool(
        maxPayouts: 2048,
        arbiterAddress: arbiterAddressVector.value,
      );
      final gateway = testGateway(chain);

      for (final (index, released) in [
        (0, false),
        (1, true),
        (2, false),
        (8, false),
        (2046, false),
        (2047, true),
      ]) {
        expect(
          await gateway.isPayoutReleased(pool: pool, payoutIndex: index),
          released,
          reason: 'index $index',
        );
      }
    });
  });

  group('Given chain identity verification', () {
    test('when the cluster, program, and mint match then it passes', () async {
      chain
        ..genesisHash = devnetGenesisHash
        ..putChainIdentity();

      await testGateway(chain).verifyChainIdentity(
        genesisHash: devnetGenesisHash,
      );
      final reads = chain.calls.where(
        (call) => call.method == 'getMultipleAccounts',
      );
      expect(commitmentOf(reads.single.params), 'finalized');
    });

    test('when the RPC serves another cluster then it refuses', () async {
      chain.putChainIdentity();

      await expectLater(
        testGateway(chain).verifyChainIdentity(
          genesisHash: '5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('another cluster'),
          ),
        ),
      );
    });

    test(
      'when the program is missing or not executable then it refuses',
      () async {
        chain
          ..putChainIdentity()
          ..put(escrow.verilyEscrowProgramAddress, null);
        await expectLater(
          testGateway(chain).verifyChainIdentity(genesisHash: testGenesisHash),
          throwsStateError,
        );

        chain.put(
          escrow.verilyEscrowProgramAddress,
          FakeAccount(owner: systemProgramAddress, data: Uint8List(0)),
        );
        await expectLater(
          testGateway(chain).verifyChainIdentity(genesisHash: testGenesisHash),
          throwsStateError,
        );
      },
    );

    test('when the mint has other decimals or another owner then it '
        'refuses', () async {
      chain.putChainIdentity(decimals: 9);
      await expectLater(
        testGateway(chain).verifyChainIdentity(genesisHash: testGenesisHash),
        throwsStateError,
      );

      chain.put(
        devnetUsdc,
        FakeAccount(
          owner: const Address('TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb'),
          data: mintBytes(),
        ),
      );
      await expectLater(
        testGateway(chain).verifyChainIdentity(genesisHash: testGenesisHash),
        throwsStateError,
      );
    });

    test(
      'when the endpoint is unreachable then the error hides the URL',
      () async {
        chain.unavailable.add('getGenesisHash');

        await expectLater(
          testGateway(chain).verifyChainIdentity(genesisHash: testGenesisHash),
          _escrowError('rpc_unavailable'),
        );
      },
    );

    test('when the arbiter is the fee payer then the gateway refuses', () {
      expect(
        () => testGateway(chain, arbiter: feePayerSigner),
        throwsArgumentError,
      );
    });
  });

  group('Given funding transactions for the creator wallet', () {
    final now = DateTime.utc(2026, 10, 21);

    test('when OpenEscrow is built then it carries the exact terms, the '
        'derived accounts, and only the creator as signer', () async {
      final pool = fundedPool();
      final wire = await testGateway(chain).buildOpenEscrowTransaction(pool);
      final transaction = getTransactionDecoder().decode(base64Decode(wire));
      final message = decodeMessage(transaction);

      expect(message.version, TransactionVersion.v0);
      expect(message.feePayer, creatorAddress);
      expect(transaction.signatures.keys, [creatorAddress]);
      expect(transaction.signatures[creatorAddress], isNull);
      final instruction = message.instructions.single;
      expect(instruction.programAddress, escrow.verilyEscrowProgramAddress);
      expect(
        [for (final meta in instruction.accounts!) meta.address],
        [
          creatorAddress,
          escrowAddressVector,
          vaultAddressVector,
          spl.getAssociatedTokenAddressSync(
            owner: creatorAddress,
            tokenProgram: tokenProgramAddress,
            mint: devnetUsdc,
          ),
          devnetUsdc,
          tokenProgramAddress,
          associatedTokenProgramAddress,
          systemProgramAddress,
        ],
      );
      final data = escrow.parseOpenEscrowInstruction(instruction);
      expect(data.poolId, poolIdVector.toBytes());
      expect(data.arbiter, arbiterSigner.address);
      expect(data.amountPerPayout, BigInt.from(pool.amountPerPayout));
      expect(data.maxPayouts, pool.maxPayouts);
      expect(data.expiresAt, BigInt.from(testExpiresAt));
      expect(data.refundDelay, testRefundDelay);
      expect(
        (message.lifetimeConstraint! as BlockhashLifetimeConstraint).blockhash,
        testBlockhash,
      );
    });

    test('when EndEarly is built then only the creator signs it', () async {
      final wire = await testGateway(chain).buildEndEarlyTransaction(
        fundedPool(),
      );
      final transaction = getTransactionDecoder().decode(base64Decode(wire));
      final instruction = decodeMessage(transaction).instructions.single;

      expect(transaction.signatures.keys, [creatorAddress]);
      expect(
        [for (final meta in instruction.accounts!) meta.address],
        [creatorAddress, escrowAddressVector],
      );
      expect(
        escrow.identifyVerilyEscrowInstruction(instruction.data!),
        escrow.VerilyEscrowInstruction.endEarly,
      );
    });

    for (final (description, pool) in [
      (
        'another arbiter',
        fundedPool(arbiterAddress: recipientAddress.value),
      ),
      (
        'another escrow address',
        fundedPool(escrowAddress: vaultAddressVector.value),
      ),
      (
        'an expired reward',
        fundedPool(expiresAt: now.subtract(const Duration(seconds: 1))),
      ),
      (
        'a refund delay the program refuses',
        fundedPool(refundDelaySeconds: 3600),
      ),
      (
        'a mint outside the allow-list',
        fundedPool(mint: recipientAddress.value),
      ),
      ('another cluster', fundedPool(cluster: RewardCluster.mainnet)),
    ]) {
      test('when the pool has $description then nothing is built', () async {
        await expectLater(
          testGateway(chain, clock: () => now).buildOpenEscrowTransaction(pool),
          throwsA(anything),
        );
        expect(chain.count('getLatestBlockhash'), 0);
      });
    }
  });

  group('Given an escrow read for funding confirmation', () {
    test('when it matches its pool then nothing mismatches and it was read '
        'at finalized', () async {
      chain
        ..putEscrow(escrowBytes())
        ..putVault();
      final pool = fundedPool();

      final state = await testGateway(chain).readEscrow(pool);

      expect(state, isNotNull);
      expect(rewardEscrowMismatches(pool, state!), isEmpty);
      expect(state.vaultBalance, 3000000);
      final read = chain.calls.singleWhere(
        (call) => call.method == 'getMultipleAccounts',
      );
      expect(read.params[0], [
        escrowAddressVector.value,
        vaultAddressVector.value,
      ]);
      expect(commitmentOf(read.params), 'finalized');
    });

    test(
      'when it exists only at confirmed then it is not funded yet',
      () async {
        chain
          ..putEscrow(escrowBytes(), finalizedToo: false)
          ..putVault();

        expect(await testGateway(chain).readEscrow(fundedPool()), isNull);
      },
    );

    test('when only lamports were sent to the address then it is not an '
        'escrow', () async {
      chain.put(
        escrowAddressVector,
        FakeAccount(owner: systemProgramAddress, data: Uint8List(0)),
      );

      expect(await testGateway(chain).readEscrow(fundedPool()), isNull);
    });

    test(
      'when the pool has not started funding then nothing is read',
      () async {
        final pool = fundedPool(funding: false);

        expect(await testGateway(chain).readEscrow(pool), isNull);
        expect(chain.calls, isEmpty);
      },
    );

    for (final (description, account) in [
      (
        'another program owns the account',
        FakeAccount(owner: tokenProgramAddress, data: escrowBytes()),
      ),
      (
        'the data is longer than an escrow',
        FakeAccount(
          owner: escrow.verilyEscrowProgramAddress,
          data: Uint8List.fromList([...escrowBytes(), 0]),
        ),
      ),
      (
        'the discriminator is wrong',
        FakeAccount(
          owner: escrow.verilyEscrowProgramAddress,
          data: Uint8List.fromList([2, ...escrowBytes().skip(1)]),
        ),
      ),
      (
        'the schema version is newer',
        FakeAccount(
          owner: escrow.verilyEscrowProgramAddress,
          data: Uint8List.fromList([1, 1, ...escrowBytes().skip(2)]),
        ),
      ),
      (
        'the stored creator does not derive this address',
        FakeAccount(
          owner: escrow.verilyEscrowProgramAddress,
          data: escrowBytes(creator: recipientAddress),
        ),
      ),
      (
        'the bump is not canonical',
        FakeAccount(
          owner: escrow.verilyEscrowProgramAddress,
          data: escrowBytes(bump: 253),
        ),
      ),
      (
        'the refund time is off its delay',
        FakeAccount(
          owner: escrow.verilyEscrowProgramAddress,
          data: escrowBytes(refundAfter: testExpiresAt),
        ),
      ),
      (
        'more payouts are released than funded',
        FakeAccount(
          owner: escrow.verilyEscrowProgramAddress,
          data: escrowBytes(releasedCount: 4),
        ),
      ),
    ]) {
      test('when $description then it is refused', () async {
        chain
          ..put(escrowAddressVector, account)
          ..putVault();

        await expectLater(
          testGateway(chain).readEscrow(fundedPool()),
          _escrowError('escrow_invalid'),
        );
      });
    }

    for (final (description, arrange) in <(String, void Function())>[
      ('the vault is missing', () => chain.put(vaultAddressVector, null)),
      (
        'the vault is frozen',
        () => chain.putVault(state: spl.AccountState.frozen),
      ),
      (
        'the vault is held by another owner',
        () => chain.putVault(owner: recipientAddress),
      ),
      (
        'the vault is not an SPL Token account',
        () => chain.putVault(programOwner: systemProgramAddress),
      ),
      (
        'the escrow records another vault',
        () {
          chain
            ..putVault()
            ..putEscrow(escrowBytes(vault: recipientAddress));
        },
      ),
    ]) {
      test('when $description then it cannot pay and funding fails on the '
          'vault balance', () async {
        chain.putEscrow(escrowBytes());
        arrange();
        final pool = fundedPool();

        final state = await testGateway(chain).readEscrow(pool);

        expect(state!.vaultBalance, 0);
        expect(rewardEscrowMismatches(pool, state), contains('vaultBalance'));
      });
    }

    test(
      'when the terms differ then the pool service sees each field',
      () async {
        chain
          ..putEscrow(
            escrowBytes(
              arbiter: recipientAddress,
              amountPerPayout: 999,
              maxPayouts: 4,
              expiresAt: testExpiresAt + 1,
              releasedCount: 1,
            ),
          )
          ..putVault();
        final pool = fundedPool();

        final state = await testGateway(chain).readEscrow(pool);

        expect(
          rewardEscrowMismatches(pool, state!),
          containsAll([
            'arbiter',
            'amountPerPayout',
            'maxPayouts',
            'expiresAt',
            'refundAfter',
            'releasedCount',
          ]),
        );
      },
    );

    test('when the RPC endpoint fails then the error hides the URL', () async {
      chain.unavailable.add('getMultipleAccounts');

      await expectLater(
        testGateway(chain).readEscrow(fundedPool()),
        _escrowError('rpc_unavailable'),
      );
    });
  });

  group('Given a payout release', () {
    setUp(() {
      chain
        ..putEscrow(escrowBytes())
        ..putVault();
    });

    Future<RewardReleaseOutcome> release({
      RewardPool? pool,
      int index = 0,
      String? recipient,
      Duration timeout = const Duration(milliseconds: 200),
      TransactionPartialSigner? arbiter,
    }) =>
        testGateway(
          chain,
          confirmationTimeout: timeout,
          arbiter: arbiter,
        ).releasePayout(
          pool: pool ?? fundedPool(),
          payoutIndex: index,
          recipientWallet: recipient ?? recipientAddress.value,
        );

    test('when it confirms then the fee payer and arbiter signed exactly the '
        'recipient account creation and the release', () async {
      final outcome = await release(index: 2);

      final transaction = chain.sent.single;
      expect(
        outcome,
        isA<RewardReleased>().having(
          (released) => released.signature,
          'signature',
          getSignatureFromTransaction(transaction).value,
        ),
      );
      final message = decodeMessage(transaction);
      expect(message.feePayer, feePayerSigner.address);
      expect(transaction.signatures.keys.toSet(), {
        feePayerSigner.address,
        arbiterSigner.address,
      });
      for (final signer in [feePayerSigner, arbiterSigner]) {
        expect(
          verifySolanaSignature(
            publicKeyBytes: getAddressEncoder().encode(signer.address),
            messageBytes: transaction.messageBytes,
            signatureBytes: transaction.signatures[signer.address]!.value,
          ),
          isTrue,
        );
      }
      final [createAccount, releasePayout] = message.instructions;
      final recipientToken = spl.getAssociatedTokenAddressSync(
        owner: recipientAddress,
        tokenProgram: tokenProgramAddress,
        mint: devnetUsdc,
      );
      expect(createAccount.programAddress, associatedTokenProgramAddress);
      expect(
        [for (final meta in createAccount.accounts!) meta.address],
        [
          feePayerSigner.address,
          recipientToken,
          recipientAddress,
          devnetUsdc,
          systemProgramAddress,
          tokenProgramAddress,
        ],
      );
      expect(releasePayout.programAddress, escrow.verilyEscrowProgramAddress);
      expect(
        [for (final meta in releasePayout.accounts!) meta.address],
        [
          arbiterSigner.address,
          escrowAddressVector,
          vaultAddressVector,
          recipientToken,
          devnetUsdc,
          tokenProgramAddress,
        ],
      );
      expect(escrow.parseReleasePayoutInstruction(releasePayout).index, 2);
      final send = chain.calls.singleWhere(
        (call) => call.method == 'sendTransaction',
      );
      expect(
        (send.params[1]! as Map<String, Object?>)['preflightCommitment'],
        'confirmed',
      );
      expect(
        (send.params[1]! as Map<String, Object?>)['skipPreflight'],
        isNull,
      );
    });

    test(
      'when the index is already set and final then nothing is sent',
      () async {
        chain.putEscrow(escrowBytes(released: {0}, releasedCount: 1));

        expect(await release(), isA<RewardAlreadyReleased>());
        expect(chain.sent, isEmpty);
      },
    );

    test(
      'when the index is set but not final yet then it retries later',
      () async {
        chain
          ..putEscrow(escrowBytes())
          ..confirmed[escrowAddressVector] = FakeAccount(
            owner: escrow.verilyEscrowProgramAddress,
            data: escrowBytes(released: {0}, releasedCount: 1),
          );

        expect(
          await release(),
          _failed('release_pending_finality', retryable: true),
        );
        expect(chain.sent, isEmpty);
      },
    );

    test('when the program reports PayoutAlreadyReleased and the final '
        'bitmap agrees then the earlier release is accepted', () async {
      chain.onSend = (_) {
        // A lost earlier attempt landed between the read and the send.
        chain.finalized[escrowAddressVector] = FakeAccount(
          owner: escrow.verilyEscrowProgramAddress,
          data: escrowBytes(released: {0}, releasedCount: 1),
        );
        throw preflightFailure(
          {
            'InstructionError': [
              1,
              {'Custom': escrow.verilyEscrowErrorPayoutAlreadyReleased},
            ],
          },
          escrowFailureLogs(escrow.verilyEscrowErrorPayoutAlreadyReleased),
        );
      };

      expect(await release(), isA<RewardAlreadyReleased>());
    });

    test(
      'when the program reports PayoutAlreadyReleased but the final '
      'bitmap does not show it then it is retried, never marked paid',
      () async {
        chain.onSend = (_) => throw preflightFailure(
          {
            'InstructionError': [
              1,
              {'Custom': escrow.verilyEscrowErrorPayoutAlreadyReleased},
            ],
          },
          escrowFailureLogs(escrow.verilyEscrowErrorPayoutAlreadyReleased),
        );

        expect(
          await release(),
          _failed('release_pending_finality', retryable: true),
        );
      },
    );

    test('when SPL Token raises the same custom code then it is not '
        'mistaken for PayoutAlreadyReleased', () async {
      // SPL Token's 11 is NonNativeHasBalance; only the logs attribute it.
      chain.onSend = (_) => throw preflightFailure(
        {
          'InstructionError': [
            1,
            {'Custom': 11},
          ],
        },
        tokenFailureLogs(11),
      );

      expect(
        await release(),
        _failed('token_transfer_failed', retryable: false),
      );
      expect(chain.count('getMultipleAccounts'), 1);
    });

    test('when a custom code arrives without logs then it is not '
        'attributed', () async {
      chain.onSend = (_) => throw preflightFailure({
        'InstructionError': [
          1,
          {'Custom': escrow.verilyEscrowErrorPayoutAlreadyReleased},
        ],
      }, const []);

      expect(await release(), _failed('release_rejected', retryable: false));
    });

    for (final (code, expected, retryable) in [
      (
        escrow.verilyEscrowErrorReleaseWindowClosed,
        'refund_window_reached',
        false,
      ),
      (escrow.verilyEscrowErrorNotArbiter, 'arbiter_mismatch', false),
      (escrow.verilyEscrowErrorVaultMismatch, 'escrow_mismatch', false),
      (escrow.verilyEscrowErrorMintMismatch, 'escrow_mismatch', false),
      (escrow.verilyEscrowErrorInvalidRecipient, 'invalid_recipient', false),
      (
        escrow.verilyEscrowErrorPayoutIndexOutOfRange,
        'payout_index_out_of_range',
        false,
      ),
      (escrow.verilyEscrowErrorEscrowStillOpen, 'release_rejected', false),
    ]) {
      test('when the program fails with $code then the outcome is '
          '$expected', () async {
        chain.onSend = (_) => throw preflightFailure(
          {
            'InstructionError': [
              1,
              {'Custom': code},
            ],
          },
          escrowFailureLogs(code),
        );

        expect(await release(), _failed(expected, retryable: retryable));
      });
    }

    for (final (tokenCode, expected) in [
      (spl.tokenErrorAccountFrozen, 'token_account_frozen'),
      (spl.tokenErrorInsufficientFunds, 'vault_underfunded'),
    ]) {
      test('when SPL Token fails with $tokenCode then the outcome is '
          '$expected', () async {
        chain.onSend = (_) => throw preflightFailure(
          {
            'InstructionError': [
              1,
              {'Custom': tokenCode},
            ],
          },
          tokenFailureLogs(tokenCode),
        );

        expect(await release(), _failed(expected, retryable: false));
      });
    }

    for (final (err, expected) in <(Object, String)>[
      ('BlockhashNotFound', 'blockhash_expired'),
      ('InsufficientFundsForFee', 'fee_payer_underfunded'),
      (
        {
          'InsufficientFundsForRent': {'account_index': 0},
        },
        'fee_payer_underfunded',
      ),
      ('AccountInUse', 'release_rejected'),
    ]) {
      test('when preflight fails with $err then the outcome is a retryable '
          '$expected', () async {
        chain.onSend = (_) => throw preflightFailure(err, const []);

        expect(await release(), _failed(expected, retryable: true));
      });
    }

    test(
      'when creating the recipient account fails then it is retried',
      () async {
        chain.onSend = (_) => throw preflightFailure(
          {
            'InstructionError': [
              0,
              {'Custom': 1},
            ],
          },
          [
            'Program ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL invoke [1]',
            'Program 11111111111111111111111111111111 invoke [2]',
            'Program 11111111111111111111111111111111 failed: custom program error: 0x1',
            'Program ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL failed: custom program error: 0x1',
          ],
        );

        expect(
          await release(),
          _failed('recipient_account_failed', retryable: true),
        );
      },
    );

    test('when the send response is lost but the transaction confirms then '
        'it is released', () async {
      chain.onSend = (transaction) {
        chain.statuses[getSignatureFromTransaction(transaction).value] = {
          'slot': 12,
          'confirmations': 1,
          'err': null,
          'confirmationStatus': 'finalized',
        };
        throw const FakeRpcError(-32603, 'gateway timeout');
      };

      expect(await release(), isA<RewardReleased>());
    });

    test('when the transaction lands with a program error then its logs '
        'decide the outcome', () async {
      chain.onSend = (transaction) {
        final signature = getSignatureFromTransaction(transaction).value;
        chain
          ..statuses[signature] = {
            'slot': 12,
            'confirmations': 1,
            'err': {
              'InstructionError': [
                1,
                {'Custom': escrow.verilyEscrowErrorReleaseWindowClosed},
              ],
            },
            'confirmationStatus': 'confirmed',
          }
          ..transactionLogs[signature] = escrowFailureLogs(
            escrow.verilyEscrowErrorReleaseWindowClosed,
          );
      };

      expect(
        await release(),
        _failed('refund_window_reached', retryable: false),
      );
    });

    test('when the blockhash expires before the transaction lands then it '
        'is retried with the same index', () async {
      chain
        ..confirmOnSend = false
        ..onSend = (_) => chain.blockHeight = chain.lastValidBlockHeight + 1;

      expect(await release(), _failed('blockhash_expired', retryable: true));
      expect(
        chain.calls.where(
          (call) =>
              call.method == 'getSignatureStatuses' &&
              (call.params[1]!
                      as Map<String, Object?>)['searchTransactionHistory'] ==
                  true,
        ),
        isNotEmpty,
      );
    });

    test('when the transaction stays unconfirmed past the bound then the '
        'outcome is unknown and retryable', () async {
      chain.onSend = (transaction) {
        chain.statuses[getSignatureFromTransaction(transaction).value] = {
          'slot': 12,
          'confirmations': null,
          'err': null,
          'confirmationStatus': 'processed',
        };
      };

      expect(
        await release(timeout: const Duration(milliseconds: 30)),
        _failed('release_unconfirmed', retryable: true),
      );
    });

    test('when the escrow is closed then it fails without sending', () async {
      chain.put(escrowAddressVector, null);

      expect(await release(), _failed('escrow_closed', retryable: false));
      expect(chain.sent, isEmpty);
    });

    test('when the chain shows fewer releases than the server recorded then '
        'a replaced escrow is never paid from', () async {
      expect(
        await release(pool: fundedPool(payoutsReleased: 1)),
        _failed('escrow_replaced', retryable: true),
      );
      expect(chain.sent, isEmpty);
    });

    test('when the escrow has another arbiter then it fails without '
        'sending', () async {
      chain.putEscrow(escrowBytes(arbiter: recipientAddress));

      expect(await release(), _failed('escrow_mismatch', retryable: false));
      expect(chain.sent, isEmpty);
    });

    test('when the pool records another escrow then it fails', () async {
      expect(
        await release(
          pool: fundedPool(escrowAddress: vaultAddressVector.value),
        ),
        _failed('escrow_mismatch', retryable: false),
      );
    });

    for (final (description, recipient) in [
      ('not an address', 'not-a-wallet'),
      ('the escrow itself', escrowAddressVector.value),
    ]) {
      test('when the recipient is $description then it fails', () async {
        expect(
          await release(recipient: recipient),
          _failed('invalid_recipient', retryable: false),
        );
        expect(chain.sent, isEmpty);
      });
    }

    for (final index in [-1, 3, 2048]) {
      test('when the index is $index then it fails', () async {
        expect(
          await release(index: index),
          _failed('payout_index_out_of_range', retryable: false),
        );
      });
    }

    test('when the RPC endpoint is unreachable then it is retried', () async {
      chain.unavailable.add('getMultipleAccounts');

      expect(await release(), _failed('rpc_unavailable', retryable: true));
    });

    test('when the signer is unavailable then nothing is sent', () async {
      expect(
        await release(arbiter: _FailingSigner(arbiterSigner.address)),
        _failed('signer_unavailable', retryable: true),
      );
      expect(chain.sent, isEmpty);
    });
  });

  group('Given the released bitmap', () {
    test('when the escrow is open then it reads the finalized bit', () async {
      chain.putEscrow(escrowBytes(released: {2}, releasedCount: 1));
      final gateway = testGateway(chain);

      expect(
        await gateway.isPayoutReleased(pool: fundedPool(), payoutIndex: 2),
        isTrue,
      );
      expect(
        await gateway.isPayoutReleased(pool: fundedPool(), payoutIndex: 1),
        isFalse,
      );
      expect(
        chain.calls.every((call) => commitmentOf(call.params) == 'finalized'),
        isTrue,
      );
    });

    test('when finalized state lags releases the server recorded at '
        'confirmed then it still answers', () async {
      chain.putEscrow(escrowBytes(released: {0}, releasedCount: 1));

      expect(
        await testGateway(chain).isPayoutReleased(
          pool: fundedPool(payoutsReleased: 2),
          payoutIndex: 0,
        ),
        isTrue,
      );
    });

    test('when the escrow is closed then the answer is unknown, never '
        'false', () async {
      await expectLater(
        testGateway(chain).isPayoutReleased(pool: fundedPool(), payoutIndex: 0),
        _escrowError('escrow_closed_bitmap_unknown'),
      );
    });

    test('when the escrow is not the pool escrow then the answer is '
        'unknown', () async {
      chain.putEscrow(escrowBytes(amountPerPayout: 5));

      await expectLater(
        testGateway(chain).isPayoutReleased(pool: fundedPool(), payoutIndex: 0),
        _escrowError('escrow_mismatch'),
      );
    });

    test('when the index is outside the escrow then it refuses', () async {
      chain.putEscrow(escrowBytes());

      await expectLater(
        testGateway(chain).isPayoutReleased(pool: fundedPool(), payoutIndex: 3),
        _escrowError('payout_index_out_of_range'),
      );
    });
  });
}

/// A custody signer that cannot sign, like a disabled KMS key.
final class _FailingSigner implements TransactionPartialSigner {
  const _FailingSigner(this.address);

  @override
  final Address address;

  @override
  Future<List<Map<Address, SignatureBytes>>> signTransactions(
    List<Transaction> transactions, [
    TransactionSignerConfig? config,
  ]) async => throw StateError('Cloud KMS rejected the signing request.');
}
