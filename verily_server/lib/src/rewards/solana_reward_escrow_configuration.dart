import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart' show ServerpodRunMode;
import 'package:solana_kit/solana_kit.dart';
import 'package:verily_escrow_client/verily_escrow.dart' as escrow;
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/custody/kms_api_client.dart';
import 'package:verily_server/src/rewards/custody/kms_transaction_signer.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/solana_reward_escrow_gateway.dart';

/// Genesis hashes that pin each cluster itself, not a hostname that could
/// route to another network. Sources: Agave `genesis_config.rs`
/// (`ClusterType::Devnet`, `ClusterType::MainnetBeta`).
const solanaGenesisHashes = <RewardCluster, String>{
  RewardCluster.devnet: 'EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG',
  RewardCluster.mainnet: '5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d',
};

/// Secret values the Solana gateway reads through Serverpod passwords, so
/// `passwords.yaml` and the Monosecret-injected environment both work. Pass
/// these to `Serverpod.loadCustomPasswords`.
const solanaRewardSecretPasswords = <({String envName, String alias})>[
  (envName: 'VERILY_REWARD_SOLANA_RPC_URL', alias: 'rewardSolanaRpcUrl'),
  (envName: 'VERILY_REWARD_ARBITER_KEYPAIR', alias: 'rewardArbiterKeypair'),
  (envName: 'VERILY_REWARD_FEE_PAYER_KEYPAIR', alias: 'rewardFeePayerKeypair'),
  (
    envName: 'VERILY_REWARD_KMS_CREDENTIALS_JSON',
    alias: 'rewardKmsCredentialsJson',
  ),
];

/// Reads one Serverpod password by alias.
typedef RewardPasswordReader = String? Function(String alias);

/// Where Verily's arbiter and fee-payer keys live.
sealed class SolanaRewardSignerSource {
  const SolanaRewardSignerSource();
}

/// Cloud KMS Ed25519 key versions: the only custody accepted for staging,
/// production, and mainnet. Key bytes never reach this process.
final class KmsRewardSigners extends SolanaRewardSignerSource {
  const KmsRewardSigners({
    required this.credentials,
    required this.arbiterKeyVersion,
    required this.feePayerKeyVersion,
  });

  final KmsCredentialsSource credentials;
  final String arbiterKeyVersion;
  final String feePayerKeyVersion;
}

/// Solana CLI keypairs from Monosecret secrets. Development and test run
/// modes on devnet only.
final class LocalKeypairRewardSigners extends SolanaRewardSignerSource {
  LocalKeypairRewardSigners({
    required Uint8List arbiterKeypair,
    required Uint8List feePayerKeypair,
  }) : arbiterKeypair = Uint8List.fromList(arbiterKeypair),
       feePayerKeypair = Uint8List.fromList(feePayerKeypair);

  final Uint8List arbiterKeypair;
  final Uint8List feePayerKeypair;

  @override
  String toString() => 'LocalKeypairRewardSigners(<redacted>)';
}

/// Fail-closed deployment settings for the Solana escrow gateway.
///
/// Holds addresses, the RPC endpoint, and a signer source; never prints a
/// secret. Every invalid or missing value throws a [StateError] naming the
/// variable, never its value.
final class SolanaRewardEscrowConfiguration {
  const SolanaRewardEscrowConfiguration({
    required this.cluster,
    required this.rpcUri,
    required this.genesisHash,
    required this.programAddress,
    required this.token,
    required this.arbiterAddress,
    required this.feePayerAddress,
    required this.signers,
  });

  /// Parses the `VERILY_REWARD_*` Solana settings for [cluster].
  ///
  /// - `VERILY_REWARD_SOLANA_RPC_URL` (secret: providers embed keys in it):
  ///   HTTPS, or loopback HTTP in development and test only.
  /// - `VERILY_REWARD_SOLANA_GENESIS_HASH`: development and test only, for a
  ///   local validator; otherwise the cluster's pinned hash.
  /// - `VERILY_REWARD_ESCROW_PROGRAM_ID`: optional; another program than the
  ///   generated client's id only in development and test.
  /// - `VERILY_REWARD_ARBITER_ADDRESS`, `VERILY_REWARD_FEE_PAYER_ADDRESS`:
  ///   pinned public keys the signers must prove they hold.
  /// - `VERILY_REWARD_SIGNER`: `kms` or `local-keypair`.
  /// - `VERILY_REWARD_MAINNET_ENABLED`: exactly `true` to allow mainnet.
  factory SolanaRewardEscrowConfiguration.fromEnvironment({
    required String runMode,
    required RewardCluster cluster,
    required Map<String, String> environment,
    required RewardPasswordReader readPassword,
  }) {
    final developmentLike =
        runMode == ServerpodRunMode.development ||
        runMode == ServerpodRunMode.test;
    if (cluster == RewardCluster.mainnet) {
      // The escrow program, this gateway, and its key custody have not been
      // audited for real money. Enabling mainnet is a reviewed, deliberate
      // deployment decision, never a default.
      if (runMode != ServerpodRunMode.production) {
        throw StateError(
          'Mainnet reward escrow runs only in the production run mode.',
        );
      }
      if (!_flag(environment, 'VERILY_REWARD_MAINNET_ENABLED')) {
        throw StateError(
          'Mainnet reward escrow is refused until VERILY_REWARD_MAINNET_ENABLED '
          'is set to true after the escrow and its custody pass review.',
        );
      }
    }

    final rpcUri = _rpcUri(
      readPassword('rewardSolanaRpcUrl'),
      allowLoopback: developmentLike,
    );
    final genesisHash = _genesisHash(
      environment,
      cluster: cluster,
      developmentLike: developmentLike,
    );
    final programAddress = _programAddress(
      environment,
      developmentLike: developmentLike,
    );
    final arbiterAddress = _address(
      environment,
      'VERILY_REWARD_ARBITER_ADDRESS',
    );
    final feePayerAddress = _address(
      environment,
      'VERILY_REWARD_FEE_PAYER_ADDRESS',
    );
    if (arbiterAddress == feePayerAddress) {
      throw StateError(
        'The reward arbiter and fee payer must be different keys.',
      );
    }

    final signers = switch (environment['VERILY_REWARD_SIGNER']?.trim()) {
      'kms' => _kmsSigners(environment, readPassword),
      // Mainnet already requires the production run mode above, so this
      // also keeps local keys off mainnet.
      'local-keypair' when !developmentLike => throw StateError(
        'Local reward keypairs are refused outside development and test; use '
        'VERILY_REWARD_SIGNER=kms.',
      ),
      'local-keypair' => LocalKeypairRewardSigners(
        arbiterKeypair: _keypair(
          readPassword('rewardArbiterKeypair'),
          'VERILY_REWARD_ARBITER_KEYPAIR',
        ),
        feePayerKeypair: _keypair(
          readPassword('rewardFeePayerKeypair'),
          'VERILY_REWARD_FEE_PAYER_KEYPAIR',
        ),
      ),
      _ => throw StateError(
        'VERILY_REWARD_SIGNER must be kms or local-keypair.',
      ),
    };

    return SolanaRewardEscrowConfiguration(
      cluster: cluster,
      rpcUri: rpcUri,
      genesisHash: genesisHash,
      programAddress: programAddress,
      token: rewardTokens[cluster]!,
      arbiterAddress: arbiterAddress,
      feePayerAddress: feePayerAddress,
      signers: signers,
    );
  }

  final RewardCluster cluster;

  /// Never logged: an RPC URL may embed a provider key.
  final Uri rpcUri;
  final String genesisHash;
  final Address programAddress;
  final RewardToken token;
  final Address arbiterAddress;
  final Address feePayerAddress;
  final SolanaRewardSignerSource signers;

  /// Plain HTTP is accepted only for a loopback validator, which only the
  /// development and test run modes may use.
  bool get usesLoopbackRpc => _isLoopback(rpcUri.host);

  @override
  String toString() =>
      'SolanaRewardEscrowConfiguration(cluster: ${cluster.name}, '
      'program: ${programAddress.value}, arbiter: ${arbiterAddress.value}, '
      'feePayer: ${feePayerAddress.value})';
}

/// True when `VERILY_REWARD_ESCROW_MODE` selects the Solana gateway.
bool solanaRewardEscrowRequested(Map<String, String> environment) =>
    environment['VERILY_REWARD_ESCROW_MODE']?.trim().toLowerCase() == 'solana';

/// Connects the Solana gateway when `VERILY_REWARD_ESCROW_MODE=solana`, and
/// returns null for every other mode.
///
/// Startup awaits this before the server accepts traffic. Every failure
/// throws, so a misconfigured, unreachable, or mispointed deployment never
/// starts with rewards half-working.
Future<SolanaRewardEscrowGateway?> connectSolanaRewardEscrowFromEnvironment({
  required String runMode,
  required Map<String, String> environment,
  required RewardPasswordReader readPassword,
}) async {
  if (!solanaRewardEscrowRequested(environment)) return null;
  final configuration = SolanaRewardEscrowConfiguration.fromEnvironment(
    runMode: runMode,
    cluster: rewardClusterFromEnvironment(
      runMode: runMode,
      environment: environment,
    ),
    environment: environment,
    readPassword: readPassword,
  );
  return connectSolanaRewardEscrow(configuration);
}

/// Opens the configured signers, proves each controls its pinned address,
/// and verifies the RPC endpoint serves the expected cluster, program, and
/// mint before returning a gateway.
///
/// [rpcFactory] and [kmsClientFactory] replace the network in tests.
Future<SolanaRewardEscrowGateway> connectSolanaRewardEscrow(
  SolanaRewardEscrowConfiguration configuration, {
  Rpc Function(SolanaRewardEscrowConfiguration configuration)? rpcFactory,
  Future<KmsApiClient> Function(KmsCredentialsSource source)? kmsClientFactory,
  Random? random,
}) async {
  final signers = await _openSigners(
    configuration,
    kmsClientFactory: kmsClientFactory ?? GoogleCloudKmsClient.fromCredentials,
    random: random ?? Random.secure(),
  );
  try {
    final rpc =
        rpcFactory?.call(configuration) ??
        createSolanaRpc(
          url: configuration.rpcUri.toString(),
          allowInsecureHttp: configuration.usesLoopbackRpc,
        );
    final gateway = SolanaRewardEscrowGateway(
      rpc: rpc,
      cluster: configuration.cluster,
      token: configuration.token,
      arbiter: signers.arbiter,
      feePayer: signers.feePayer,
      programAddress: configuration.programAddress,
    );
    await gateway.verifyChainIdentity(genesisHash: configuration.genesisHash);
    return gateway;
  } on Object {
    signers.close();
    rethrow;
  }
}

final class _OpenedSigners {
  const _OpenedSigners({
    required this.arbiter,
    required this.feePayer,
    required this.close,
  });

  final TransactionPartialSigner arbiter;
  final TransactionPartialSigner feePayer;
  final void Function() close;
}

Future<_OpenedSigners> _openSigners(
  SolanaRewardEscrowConfiguration configuration, {
  required Future<KmsApiClient> Function(KmsCredentialsSource source)
  kmsClientFactory,
  required Random random,
}) async {
  switch (configuration.signers) {
    case LocalKeypairRewardSigners(
      :final arbiterKeypair,
      :final feePayerKeypair,
    ):
      final arbiter = _localSigner(
        arbiterKeypair,
        expected: configuration.arbiterAddress,
        name: 'VERILY_REWARD_ARBITER_KEYPAIR',
      );
      final KeyPairSigner feePayer;
      try {
        feePayer = _localSigner(
          feePayerKeypair,
          expected: configuration.feePayerAddress,
          name: 'VERILY_REWARD_FEE_PAYER_KEYPAIR',
        );
      } on Object {
        arbiter.keyPair.dispose();
        rethrow;
      }
      return _OpenedSigners(
        arbiter: arbiter,
        feePayer: feePayer,
        close: () {
          arbiter.keyPair.dispose();
          feePayer.keyPair.dispose();
        },
      );
    case KmsRewardSigners(
      :final credentials,
      :final arbiterKeyVersion,
      :final feePayerKeyVersion,
    ):
      final client = await kmsClientFactory(credentials);
      try {
        final arbiter = await KmsTransactionSigner.create(
          client: client,
          keyVersionName: arbiterKeyVersion,
          expectedAddress: configuration.arbiterAddress,
        );
        final feePayer = await KmsTransactionSigner.create(
          client: client,
          keyVersionName: feePayerKeyVersion,
          expectedAddress: configuration.feePayerAddress,
        );
        for (final signer in [arbiter, feePayer]) {
          await signer.proveSigningPower(
            Uint8List.fromList(List.generate(32, (_) => random.nextInt(256))),
          );
        }
        return _OpenedSigners(
          arbiter: arbiter,
          feePayer: feePayer,
          close: client.close,
        );
      } on Object {
        client.close();
        rethrow;
      }
  }
}

KeyPairSigner _localSigner(
  Uint8List keypair, {
  required Address expected,
  required String name,
}) {
  final KeyPairSigner signer;
  try {
    // Checks that the public half belongs to the private half.
    signer = createKeyPairSignerFromBytes(keypair);
  } on SolanaError {
    throw StateError('$name is not a consistent Solana keypair.');
  }
  if (signer.address != expected) {
    signer.keyPair.dispose();
    throw StateError('$name does not match its pinned address.');
  }
  return signer;
}

KmsRewardSigners _kmsSigners(
  Map<String, String> environment,
  RewardPasswordReader readPassword,
) {
  const fileKey = 'VERILY_REWARD_KMS_CREDENTIALS_FILE';
  const jsonKey = 'VERILY_REWARD_KMS_CREDENTIALS_JSON';
  final file = environment[fileKey];
  final json = readPassword('rewardKmsCredentialsJson');
  // A present but blank value still counts as configured, so a stray empty
  // variable can never silently select the other source.
  if ((file == null) == (json == null)) {
    throw StateError(
      'Cloud KMS reward custody requires exactly one of $fileKey or $jsonKey.',
    );
  }
  final KmsCredentialsSource credentials;
  if (file != null) {
    if (file.trim().isEmpty || file != file.trim()) {
      throw StateError(
        'Cloud KMS reward custody requires a value for $fileKey.',
      );
    }
    credentials = KmsCredentialsFile(file);
  } else {
    if (json!.trim().isEmpty) {
      throw StateError(
        'Cloud KMS reward custody requires a value for $jsonKey.',
      );
    }
    credentials = KmsCredentialsJson(json);
  }
  final arbiterKeyVersion = _keyVersion(
    environment,
    'VERILY_REWARD_KMS_ARBITER_KEY',
  );
  final feePayerKeyVersion = _keyVersion(
    environment,
    'VERILY_REWARD_KMS_FEE_PAYER_KEY',
  );
  if (arbiterKeyVersion == feePayerKeyVersion) {
    throw StateError(
      'The reward arbiter and fee payer must use different KMS keys.',
    );
  }
  return KmsRewardSigners(
    credentials: credentials,
    arbiterKeyVersion: arbiterKeyVersion,
    feePayerKeyVersion: feePayerKeyVersion,
  );
}

final RegExp _keyVersionPattern = RegExp(
  '^projects/[a-z][a-z0-9-]{4,28}'
  '/locations/[a-z0-9-]{2,}'
  '/keyRings/[A-Za-z0-9_-]{1,63}'
  '/cryptoKeys/[A-Za-z0-9_-]{1,63}'
  r'/cryptoKeyVersions/[0-9]+$',
);

String _keyVersion(Map<String, String> environment, String key) {
  final value = environment[key];
  if (value == null || !_keyVersionPattern.hasMatch(value)) {
    throw StateError(
      '$key must be a Cloud KMS crypto key version resource name '
      '(projects/.../locations/.../keyRings/.../cryptoKeys/.../'
      'cryptoKeyVersions/N).',
    );
  }
  return value;
}

/// `localhost` or any loopback address (`127.0.0.0/8`, `::1`).
bool _isLoopback(String host) =>
    host == 'localhost' ||
    (InternetAddress.tryParse(host)?.isLoopback ?? false);

Uri _rpcUri(String? raw, {required bool allowLoopback}) {
  // Never include the value in an error: providers embed API keys in it.
  const error =
      'VERILY_REWARD_SOLANA_RPC_URL must be an HTTPS URL without '
      'credentials; plain HTTP is accepted only for a loopback validator in '
      'development and test.';
  final uri = Uri.tryParse(raw?.trim() ?? '');
  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    throw StateError(error);
  }
  final loopback = _isLoopback(uri.host);
  if (loopback && !allowLoopback) throw StateError(error);
  final secure = uri.scheme == 'https';
  if (!secure && !(uri.scheme == 'http' && loopback)) throw StateError(error);
  return uri;
}

String _genesisHash(
  Map<String, String> environment, {
  required RewardCluster cluster,
  required bool developmentLike,
}) {
  const key = 'VERILY_REWARD_SOLANA_GENESIS_HASH';
  final override = environment[key]?.trim();
  if (override == null || override.isEmpty) {
    return solanaGenesisHashes[cluster]!;
  }
  if (!developmentLike || cluster != RewardCluster.devnet) {
    throw StateError(
      '$key may only point devnet rewards at a local validator in '
      'development and test.',
    );
  }
  try {
    if (getBase58Encoder().encode(override).length != 32) {
      throw const FormatException('Not 32 bytes.');
    }
  } on Object {
    throw StateError('$key must be a base58 32-byte genesis hash.');
  }
  return override;
}

Address _programAddress(
  Map<String, String> environment, {
  required bool developmentLike,
}) {
  const key = 'VERILY_REWARD_ESCROW_PROGRAM_ID';
  if (environment[key]?.trim().isEmpty ?? true) {
    return escrow.verilyEscrowProgramAddress;
  }
  final address = _address(environment, key);
  if (address != escrow.verilyEscrowProgramAddress && !developmentLike) {
    throw StateError(
      '$key may differ from the reviewed program only in development and '
      'test.',
    );
  }
  return address;
}

Address _address(Map<String, String> environment, String key) {
  final value = environment[key];
  if (value == null || value != value.trim() || !isAddress(value)) {
    throw StateError('$key must be a canonical base58 Solana address.');
  }
  final address = Address(value);
  if (getAddressEncoder().encode(address).every((byte) => byte == 0)) {
    throw StateError('$key must not be the zero address.');
  }
  return address;
}

/// A Solana CLI keypair: a JSON array of 64 bytes, private then public half.
Uint8List _keypair(String? raw, String name) {
  // Never include the value in an error: it is a private key.
  final error = StateError(
    '$name must be a Solana CLI keypair: a JSON array of 64 bytes.',
  );
  if (raw == null || raw.trim().isEmpty) throw error;
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    throw error;
  }
  if (decoded is! List<Object?> || decoded.length != 64) throw error;
  final bytes = Uint8List(64);
  for (final (index, value) in decoded.indexed) {
    if (value is! int || value < 0 || value > 255) throw error;
    bytes[index] = value;
  }
  return bytes;
}

bool _flag(Map<String, String> environment, String key) {
  return switch (environment[key]?.trim()) {
    null || '' || 'false' => false,
    'true' => true,
    _ => throw StateError('$key must be true or false.'),
  };
}
