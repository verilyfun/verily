import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:solana_kit/solana_kit.dart';
import 'package:solana_kit_token/solana_kit_token.dart' as spl;
import 'package:verily_escrow_client/verily_escrow.dart' as escrow;
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/solana_reward_escrow_configuration.dart';
import 'package:verily_server/src/rewards/solana_reward_escrow_gateway.dart';

// Test vectors. The escrow and vault addresses were computed by Agave's Rust
// derivation (`solana find-program-derived-address`, Agave 4.2.2):
//
//   solana find-program-derived-address \
//     ANL35GQjGtSuCAHTbXGBjnevFqbEtKNf6wDGPKwuPN1p string:reward-escrow \
//     pubkey:7v54NWdBtkjuAFJrLGsS2SXnuk8nKam81mZJeeYxVFi9 \
//     hex:0198bc264be57ca094d2000000000042
//   => 5Y4eUUnm8NEoLfRFQBfZJ7V2BqSSsuBBhusEgBQWYmHF, bump 254
//
//   solana find-program-derived-address \
//     ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL \
//     pubkey:5Y4eUUnm8NEoLfRFQBfZJ7V2BqSSsuBBhusEgBQWYmHF \
//     pubkey:TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA \
//     pubkey:4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU
//   => EHBWXFw4oeQmdNZj6kQN4bZEDCJEPpkv8Yoj5fEBGGKk, bump 255

/// Public, test-only seeds. These keys exist only in tests and hold nothing.
KeyPairSigner testSigner(int seed) => createKeyPairSignerFromPrivateKeyBytes(
  Uint8List.fromList(
    List<int>.filled(32, seed),
  ),
);

final KeyPairSigner creatorSigner = testSigner(11);
final KeyPairSigner arbiterSigner = testSigner(12);
final KeyPairSigner feePayerSigner = testSigner(14);
final KeyPairSigner recipientSigner = testSigner(21);

const creatorAddress = Address('7v54NWdBtkjuAFJrLGsS2SXnuk8nKam81mZJeeYxVFi9');
const arbiterAddressVector = Address(
  'mBKqcnGotbsSb5vNrdyhzZ5EhqZdids9QYiTRckvi7v',
);
const recipientAddress = Address(
  'FMUEmtxhU46GzhKF4FW9MLJdQWiLgjiXP9TYRWSrqTpV',
);
const escrowAddressVector = Address(
  '5Y4eUUnm8NEoLfRFQBfZJ7V2BqSSsuBBhusEgBQWYmHF',
);
const escrowBumpVector = 254;
const vaultAddressVector = Address(
  'EHBWXFw4oeQmdNZj6kQN4bZEDCJEPpkv8Yoj5fEBGGKk',
);
final Address devnetUsdc = Address(rewardTokens[RewardCluster.devnet]!.mint);
final UuidValue poolIdVector = UuidValue.withValidation(
  '0198bc26-4be5-7ca0-94d2-000000000042',
);
const testGenesisHash = 'EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG';
const testBlockhash = '4NCYB3kRT8sCNodPNuCZo8VUh4xqpBQxsxed2wd9xaD4';

const _secondsPerDay = 86400;
const int testExpiresAt = 1800000000;
const int testRefundDelay = 3 * _secondsPerDay;

/// The funded pool row the vectors above describe.
RewardPool fundedPool({
  int amountPerPayout = 1000000,
  int maxPayouts = 3,
  int payoutsReleased = 0,
  String? escrowAddress,
  String? arbiterAddress,
  RewardCluster cluster = RewardCluster.devnet,
  String? mint,
  DateTime? expiresAt,
  int refundDelaySeconds = testRefundDelay,
  bool funding = true,
}) {
  final expiry =
      expiresAt ??
      DateTime.fromMillisecondsSinceEpoch(testExpiresAt * 1000, isUtc: true);
  return RewardPool(
    id: poolIdVector,
    creatorAuthUserId: UuidValue.withValidation(
      '0198bc26-4be5-7ca0-94d2-000000000001',
    ),
    actionKey: 'water-a-plant',
    cluster: cluster,
    mint: mint ?? devnetUsdc.value,
    tokenSymbol: 'USDC',
    decimals: 6,
    amountPerPayout: amountPerPayout,
    maxPayouts: maxPayouts,
    payoutsReleased: payoutsReleased,
    creatorWallet: funding ? creatorAddress.value : null,
    escrowAddress: funding ? escrowAddress ?? escrowAddressVector.value : null,
    arbiterAddress: funding
        ? arbiterAddress ?? arbiterSigner.address.value
        : null,
    expiresAt: expiry,
    refundDelaySeconds: refundDelaySeconds,
    refundAfter: expiry.add(Duration(seconds: refundDelaySeconds)),
    status: funding ? RewardPoolStatus.funded : RewardPoolStatus.draft,
  );
}

/// `RewardEscrow` bytes written by the generated encoder.
Uint8List escrowBytes({
  Address? creator,
  Address? arbiter,
  Address? mint,
  Address? vault,
  Uint8List? poolId,
  int amountPerPayout = 1000000,
  int maxPayouts = 3,
  int releasedCount = 0,
  int expiresAt = testExpiresAt,
  int refundDelay = testRefundDelay,
  int? refundAfter,
  int bump = escrowBumpVector,
  Set<int> released = const {},
}) {
  final bitmap = Uint8List(256);
  for (final index in released) {
    bitmap[index ~/ 8] |= 1 << (index % 8);
  }
  return escrow.getRewardEscrowEncoder().encode(
    escrow.RewardEscrow(
      creator: creator ?? creatorAddress,
      arbiter: arbiter ?? arbiterSigner.address,
      mint: mint ?? devnetUsdc,
      vault: vault ?? vaultAddressVector,
      poolId: poolId ?? poolIdVector.toBytes(),
      amountPerPayout: BigInt.from(amountPerPayout),
      maxPayouts: maxPayouts,
      releasedCount: releasedCount,
      expiresAt: BigInt.from(expiresAt),
      refundAfter: BigInt.from(refundAfter ?? expiresAt + refundDelay),
      refundDelay: refundDelay,
      bump: bump,
      released: bitmap,
    ),
  );
}

/// SPL Token account bytes.
Uint8List tokenAccountBytes({
  required Address mint,
  required Address owner,
  required int amount,
  spl.AccountState state = spl.AccountState.initialized,
}) => spl.getTokenEncoder().encode(
  spl.Token(
    mint: mint,
    owner: owner,
    amount: BigInt.from(amount),
    delegate: null,
    state: state,
    isNative: null,
    delegatedAmount: BigInt.zero,
    closeAuthority: null,
  ),
);

/// SPL Token mint bytes.
Uint8List mintBytes({int decimals = 6, bool initialized = true}) =>
    spl.getMintEncoder().encode(
      spl.Mint(
        mintAuthority: null,
        supply: BigInt.from(1000000000000),
        decimals: decimals,
        isInitialized: initialized,
        freezeAuthority: null,
      ),
    );

/// One account as the RPC endpoint reports it.
final class FakeAccount {
  const FakeAccount({
    required this.owner,
    required this.data,
    this.executable = false,
  });

  final Address owner;
  final Uint8List data;
  final bool executable;

  Map<String, Object?> toJson() => {
    'owner': owner.value,
    'data': [base64Encode(data), 'base64'],
    'executable': executable,
    'lamports': 2039280,
    'rentEpoch': 0,
    'space': data.length,
  };
}

/// A JSON-RPC error the fake endpoint returns.
final class FakeRpcError implements Exception {
  const FakeRpcError(this.code, this.message, [this.data]);

  final int code;
  final String message;
  final Object? data;
}

/// A preflight failure carrying [err] and the simulation's [logs].
FakeRpcError preflightFailure(Object err, List<String> logs) => FakeRpcError(
  -32002,
  'Transaction simulation failed: provider detail that must never leak',
  {'err': err, 'logs': logs, 'accounts': null, 'unitsConsumed': 1000},
);

const _ataProgram = 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL';
const _tokenProgram = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';

String _failedLine(String program, int code) =>
    'Program $program failed: custom program error: 0x${code.toRadixString(16)}';

/// Logs of a release whose escrow program failed with [code].
List<String> escrowFailureLogs(int code) {
  final program = escrow.verilyEscrowProgramAddress.value;
  return [
    'Program $_ataProgram invoke [1]',
    'Program $_ataProgram success',
    'Program $program invoke [1]',
    'Program $program consumed 3000 of 197000 compute units',
    _failedLine(program, code),
  ];
}

/// Logs of a release whose SPL Token transfer failed with [code].
List<String> tokenFailureLogs(int code) {
  final program = escrow.verilyEscrowProgramAddress.value;
  return [
    'Program $_ataProgram invoke [1]',
    'Program $_ataProgram success',
    'Program $program invoke [1]',
    'Program $_tokenProgram invoke [2]',
    _failedLine(_tokenProgram, code),
    _failedLine(program, code),
  ];
}

/// An in-memory Solana JSON-RPC endpoint behind the real solana_kit RPC
/// client and its response transformers, so the gateway runs unchanged
/// without a network.
final class FakeSolanaRpc {
  FakeSolanaRpc() {
    rpc = createSolanaRpcFromTransport(_transport);
  }

  late final Rpc rpc;

  String genesisHash = testGenesisHash;
  int blockHeight = 100;
  int lastValidBlockHeight = 250;

  /// Accounts at `confirmed`; [finalized] overrides them at `finalized`.
  final Map<Address, FakeAccount?> confirmed = {};
  final Map<Address, FakeAccount?> finalized = {};

  /// Signature status values, keyed by signature, as `getSignatureStatuses`
  /// reports them. A missing key is an unknown signature.
  final Map<String, Map<String, Object?>> statuses = {};

  /// Called for each `sendTransaction` with the decoded transaction; throw a
  /// [FakeRpcError] to fail it. The default accepts and confirms it.
  void Function(Transaction transaction)? onSend;

  /// Whether an accepted transaction gets a `confirmed` status by default.
  bool confirmOnSend = true;

  /// Log messages `getTransaction` reports per signature.
  final Map<String, List<String>> transactionLogs = {};

  /// Methods that fail at the transport, like an unreachable endpoint.
  final Set<String> unavailable = {};

  final List<({String method, List<Object?> params})> calls = [];
  final List<Transaction> sent = [];

  /// Puts [account] at [address] for every commitment.
  void put(Address address, FakeAccount? account) {
    confirmed[address] = account;
    finalized[address] = account;
  }

  void putEscrow(Uint8List data, {bool finalizedToo = true}) {
    final account = FakeAccount(
      owner: escrow.verilyEscrowProgramAddress,
      data: data,
    );
    confirmed[escrowAddressVector] = account;
    if (finalizedToo) finalized[escrowAddressVector] = account;
  }

  void putVault({
    int amount = 3000000,
    spl.AccountState state = spl.AccountState.initialized,
    Address? owner,
    Address? programOwner,
  }) => put(
    vaultAddressVector,
    FakeAccount(
      owner: programOwner ?? tokenProgramAddress,
      data: tokenAccountBytes(
        mint: devnetUsdc,
        owner: owner ?? escrowAddressVector,
        amount: amount,
        state: state,
      ),
    ),
  );

  void putChainIdentity({int decimals = 6}) {
    put(
      escrow.verilyEscrowProgramAddress,
      FakeAccount(
        owner: const Address('BPFLoaderUpgradeab1e11111111111111111111111'),
        data: Uint8List(36),
        executable: true,
      ),
    );
    put(
      devnetUsdc,
      FakeAccount(
        owner: tokenProgramAddress,
        data: mintBytes(decimals: decimals),
      ),
    );
  }

  int count(String method) =>
      calls.where((call) => call.method == method).length;

  Future<Object?> _transport(RpcTransportConfig config) async {
    final payload = config.payload! as Map<String, Object?>;
    final method = payload['method']! as String;
    final params = (payload['params']! as List<Object?>).toList();
    calls.add((method: method, params: params));
    if (unavailable.contains(method)) {
      throw StateError('connection refused: https://rpc.example/secret-key');
    }
    try {
      return {
        'jsonrpc': '2.0',
        'id': payload['id'],
        'result': _respond(method, params),
      };
    } on FakeRpcError catch (error) {
      return {
        'jsonrpc': '2.0',
        'id': payload['id'],
        'error': {
          'code': error.code,
          'message': error.message,
          if (error.data != null) 'data': error.data,
        },
      };
    }
  }

  Object? _respond(String method, List<Object?> params) {
    switch (method) {
      case 'getGenesisHash':
        return genesisHash;
      case 'getLatestBlockhash':
        return {
          'context': {'slot': 1},
          'value': {
            'blockhash': testBlockhash,
            'lastValidBlockHeight': lastValidBlockHeight,
          },
        };
      case 'getBlockHeight':
        return blockHeight;
      case 'getMultipleAccounts':
        final addresses = (params[0]! as List<Object?>).cast<String>();
        final view = commitmentOf(params) == 'finalized'
            ? finalized
            : confirmed;
        return {
          'context': {'slot': 1},
          'value': [
            for (final address in addresses) view[Address(address)]?.toJson(),
          ],
        };
      case 'sendTransaction':
        final transaction = getTransactionDecoder().decode(
          base64Decode(params[0]! as String),
        );
        sent.add(transaction);
        onSend?.call(transaction);
        final signature = getSignatureFromTransaction(transaction).value;
        if (!confirmOnSend) return signature;
        statuses.putIfAbsent(
          signature,
          () => {
            'slot': 10,
            'confirmations': 0,
            'err': null,
            'confirmationStatus': 'confirmed',
          },
        );
        return signature;
      case 'getSignatureStatuses':
        final signatures = (params[0]! as List<Object?>).cast<String>();
        return {
          'context': {'slot': 1},
          'value': [for (final signature in signatures) statuses[signature]],
        };
      case 'getTransaction':
        final logs = transactionLogs[params[0]! as String];
        return logs == null
            ? null
            : {
                'meta': {'logMessages': logs, 'err': <String, Object?>{}},
              };
    }
    throw StateError('The fake RPC does not serve $method.');
  }
}

/// The commitment a request asked for. solana_kit drops an explicit
/// `finalized` because it is the server's default.
String commitmentOf(List<Object?> params) {
  final config = params.length > 1 ? params[1] : null;
  return (config is Map ? config['commitment'] as String? : null) ??
      'finalized';
}

/// A gateway over [rpc] with the test signers and fast polling.
SolanaRewardEscrowGateway testGateway(
  FakeSolanaRpc rpc, {
  Duration confirmationTimeout = const Duration(milliseconds: 200),
  TransactionPartialSigner? arbiter,
  DateTime Function()? clock,
}) => SolanaRewardEscrowGateway(
  rpc: rpc.rpc,
  cluster: RewardCluster.devnet,
  token: rewardTokens[RewardCluster.devnet]!,
  arbiter: arbiter ?? arbiterSigner,
  feePayer: feePayerSigner,
  confirmationTimeout: confirmationTimeout,
  confirmationPollInterval: const Duration(milliseconds: 5),
  clock: clock ?? () => DateTime.utc(2026, 10, 21),
);

/// The instructions and fee payer of a wire transaction.
TransactionMessage decodeMessage(Transaction transaction) =>
    decompileTransactionMessage(
      getCompiledTransactionMessageDecoder().decode(transaction.messageBytes),
    );

/// The pinned genesis hash the configuration expects for devnet.
String get devnetGenesisHash => solanaGenesisHashes[RewardCluster.devnet]!;
