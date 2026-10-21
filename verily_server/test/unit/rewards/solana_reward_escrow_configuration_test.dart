import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart' show ServerpodRunMode;
import 'package:solana_kit/solana_kit.dart';
import 'package:test/test.dart';
import 'package:verily_escrow_client/verily_escrow.dart' as escrow;
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/custody/kms_api_client.dart';
import 'package:verily_server/src/rewards/custody/kms_transaction_signer.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/solana_reward_escrow_configuration.dart';
import 'package:verily_server/src/rewards/solana_reward_escrow_gateway.dart';

import 'custody/fake_kms_api_client.dart';
import 'solana_test_support.dart';

const _rpcUrl = 'https://devnet.rpc.example/v1/provider-key-do-not-echo';
const _arbiterKey =
    'projects/verily-dev/locations/europe-west2/keyRings/escrow/'
    'cryptoKeys/reward-arbiter/cryptoKeyVersions/1';
const _feePayerKey =
    'projects/verily-dev/locations/europe-west2/keyRings/escrow/'
    'cryptoKeys/reward-fee-payer/cryptoKeyVersions/1';
const _secretMarker = 'do-not-echo-this-secret';

/// The Solana CLI keypair file format: private half, then public half.
String _keypairJson(KeyPairSigner signer) => jsonEncode([
  ...signer.keyPair.privateKey,
  ...signer.keyPair.publicKey,
]);

Map<String, String> _localEnvironment([Map<String, String> extra = const {}]) =>
    {
      'VERILY_REWARD_ESCROW_MODE': 'solana',
      'VERILY_REWARD_SIGNER': 'local-keypair',
      'VERILY_REWARD_ARBITER_ADDRESS': arbiterSigner.address.value,
      'VERILY_REWARD_FEE_PAYER_ADDRESS': feePayerSigner.address.value,
      ...extra,
    };

Map<String, String> _kmsEnvironment([Map<String, String> extra = const {}]) => {
  'VERILY_REWARD_ESCROW_MODE': 'solana',
  'VERILY_REWARD_SIGNER': 'kms',
  'VERILY_REWARD_ARBITER_ADDRESS': arbiterSigner.address.value,
  'VERILY_REWARD_FEE_PAYER_ADDRESS': feePayerSigner.address.value,
  'VERILY_REWARD_KMS_ARBITER_KEY': _arbiterKey,
  'VERILY_REWARD_KMS_FEE_PAYER_KEY': _feePayerKey,
  'VERILY_REWARD_KMS_CREDENTIALS_FILE': '/run/secrets/verily-kms.json',
  ...extra,
};

RewardPasswordReader _passwords([Map<String, String?> overrides = const {}]) {
  final values = <String, String?>{
    'rewardSolanaRpcUrl': _rpcUrl,
    'rewardArbiterKeypair': _keypairJson(arbiterSigner),
    'rewardFeePayerKeypair': _keypairJson(feePayerSigner),
    ...overrides,
  };
  return (alias) => values[alias];
}

SolanaRewardEscrowConfiguration _configure(
  String runMode,
  Map<String, String> environment, {
  RewardCluster cluster = RewardCluster.devnet,
  RewardPasswordReader? passwords,
}) => SolanaRewardEscrowConfiguration.fromEnvironment(
  runMode: runMode,
  cluster: cluster,
  environment: environment,
  readPassword: passwords ?? _passwords(),
);

Matcher _refusedWith(String fragment) => throwsA(
  isA<StateError>()
      .having((error) => error.message, 'message', contains(fragment))
      .having(
        (error) => error.message,
        'message',
        allOf(isNot(contains('provider-key')), isNot(contains(_secretMarker))),
      ),
);

void main() {
  group('Given Solana escrow settings', () {
    test('when local keypairs are configured in development then devnet, the '
        'reviewed program, and the pinned genesis are used', () {
      final configuration = _configure(
        ServerpodRunMode.development,
        _localEnvironment(),
      );

      expect(configuration.cluster, RewardCluster.devnet);
      expect(
        configuration.programAddress,
        escrow.verilyEscrowProgramAddress,
      );
      expect(configuration.genesisHash, devnetGenesisHash);
      expect(configuration.token.mint, devnetUsdc.value);
      expect(configuration.signers, isA<LocalKeypairRewardSigners>());
      expect(configuration.toString(), isNot(contains('provider-key')));
      expect(
        configuration.signers.toString(),
        isNot(contains(arbiterSigner.keyPair.privateKey.first.toString())),
      );
    });

    for (final runMode in [
      ServerpodRunMode.staging,
      ServerpodRunMode.production,
    ]) {
      test('when local keypairs are configured in $runMode then startup is '
          'refused', () {
        expect(
          () => _configure(runMode, _localEnvironment()),
          _refusedWith('refused outside development and test'),
        );
      });
    }

    test('when Cloud KMS is configured for staging then it is accepted', () {
      final configuration = _configure(
        ServerpodRunMode.staging,
        _kmsEnvironment(),
      );

      final signers = configuration.signers as KmsRewardSigners;
      expect(signers.arbiterKeyVersion, _arbiterKey);
      expect(signers.feePayerKeyVersion, _feePayerKey);
      expect(signers.credentials, isA<KmsCredentialsFile>());
    });

    test('when Cloud KMS credentials come inline then they are redacted', () {
      final environment = _kmsEnvironment()
        ..remove('VERILY_REWARD_KMS_CREDENTIALS_FILE');
      final configuration = _configure(
        ServerpodRunMode.production,
        environment,
        passwords: _passwords({
          'rewardKmsCredentialsJson': '{"x":"$_secretMarker"}',
        }),
      );

      final credentials =
          (configuration.signers as KmsRewardSigners).credentials;
      expect(credentials, isA<KmsCredentialsJson>());
      expect(credentials.toString(), isNot(contains(_secretMarker)));
    });

    for (final (description, environment, passwords, fragment) in [
      (
        'both credential sources',
        _kmsEnvironment(),
        _passwords({'rewardKmsCredentialsJson': '{}'}),
        'exactly one of',
      ),
      (
        'no credential source',
        _kmsEnvironment()..remove('VERILY_REWARD_KMS_CREDENTIALS_FILE'),
        _passwords(),
        'exactly one of',
      ),
      (
        'a blank credentials file',
        _kmsEnvironment({'VERILY_REWARD_KMS_CREDENTIALS_FILE': ' '}),
        _passwords(),
        'VERILY_REWARD_KMS_CREDENTIALS_FILE',
      ),
      (
        'a key name that is not a key version',
        _kmsEnvironment({
          'VERILY_REWARD_KMS_ARBITER_KEY':
              'projects/verily-dev/locations/x/keyRings/a/cryptoKeys/b',
        }),
        _passwords(),
        'VERILY_REWARD_KMS_ARBITER_KEY',
      ),
      (
        'one key for both roles',
        _kmsEnvironment({'VERILY_REWARD_KMS_FEE_PAYER_KEY': _arbiterKey}),
        _passwords(),
        'different KMS keys',
      ),
    ]) {
      test('when Cloud KMS has $description then startup is refused', () {
        expect(
          () => _configure(
            ServerpodRunMode.production,
            environment,
            passwords: passwords,
          ),
          _refusedWith(fragment),
        );
      });
    }

    for (final (description, environment, fragment) in [
      (
        'one address for both roles',
        _localEnvironment({
          'VERILY_REWARD_FEE_PAYER_ADDRESS': arbiterSigner.address.value,
        }),
        'must be different keys',
      ),
      (
        'a malformed arbiter address',
        _localEnvironment({'VERILY_REWARD_ARBITER_ADDRESS': 'not-an-address'}),
        'VERILY_REWARD_ARBITER_ADDRESS',
      ),
      (
        'a padded fee payer address',
        _localEnvironment({
          'VERILY_REWARD_FEE_PAYER_ADDRESS': ' ${feePayerSigner.address.value}',
        }),
        'VERILY_REWARD_FEE_PAYER_ADDRESS',
      ),
      (
        'the zero address',
        _localEnvironment({
          'VERILY_REWARD_ARBITER_ADDRESS': '11111111111111111111111111111111',
        }),
        'zero address',
      ),
      (
        'no signer mode',
        _localEnvironment()..remove('VERILY_REWARD_SIGNER'),
        'VERILY_REWARD_SIGNER',
      ),
      (
        'an unknown signer mode',
        _localEnvironment({'VERILY_REWARD_SIGNER': 'hot-wallet'}),
        'VERILY_REWARD_SIGNER',
      ),
      (
        'an invalid genesis override',
        _localEnvironment({'VERILY_REWARD_SOLANA_GENESIS_HASH': 'nope'}),
        'VERILY_REWARD_SOLANA_GENESIS_HASH',
      ),
    ]) {
      test('when there is $description then startup is refused', () {
        expect(
          () => _configure(ServerpodRunMode.development, environment),
          _refusedWith(fragment),
        );
      });
    }

    for (final (description, keypair) in [
      ('missing', null),
      ('not JSON', 'not json $_secretMarker'),
      ('too short', jsonEncode(List<int>.filled(32, 1))),
      ('out of byte range', jsonEncode(List<int>.filled(64, 256))),
      ('a JSON object', jsonEncode({'secret': _secretMarker})),
    ]) {
      test('when the arbiter keypair is $description then startup is '
          'refused without echoing it', () {
        expect(
          () => _configure(
            ServerpodRunMode.development,
            _localEnvironment(),
            passwords: _passwords({'rewardArbiterKeypair': keypair}),
          ),
          _refusedWith('VERILY_REWARD_ARBITER_KEYPAIR'),
        );
      });
    }
  });

  group('Given the RPC endpoint', () {
    for (final (description, url, runMode) in [
      ('missing', null, ServerpodRunMode.development),
      (
        'plain HTTP to a remote host',
        'http://rpc.example/provider-key',
        ServerpodRunMode.development,
      ),
      (
        'a loopback validator in production',
        'https://127.0.0.1:8899',
        ServerpodRunMode.production,
      ),
      (
        'another loopback address in production',
        'https://127.0.0.2:8899',
        ServerpodRunMode.production,
      ),
      (
        'IPv6 loopback in staging',
        'https://[::1]:8899',
        ServerpodRunMode.staging,
      ),
      (
        'carrying credentials',
        'https://user:provider-key@rpc.example',
        ServerpodRunMode.development,
      ),
      (
        'with a fragment',
        'https://rpc.example/#provider-key',
        ServerpodRunMode.development,
      ),
      ('not a URL', 'provider-key', ServerpodRunMode.development),
    ]) {
      test('when it is $description then startup is refused without echoing '
          'it', () {
        expect(
          () => _configure(
            runMode,
            runMode == ServerpodRunMode.production
                ? _kmsEnvironment()
                : _localEnvironment(),
            passwords: _passwords({'rewardSolanaRpcUrl': url}),
          ),
          _refusedWith('VERILY_REWARD_SOLANA_RPC_URL'),
        );
      });
    }

    test('when it is a loopback validator in test then plain HTTP is '
        'accepted', () {
      final configuration = _configure(
        ServerpodRunMode.test,
        _localEnvironment(),
        passwords: _passwords({'rewardSolanaRpcUrl': 'http://127.0.0.1:8899'}),
      );

      expect(configuration.usesLoopbackRpc, isTrue);
    });
  });

  group('Given a local validator override', () {
    test('when development points devnet at a local genesis then it is '
        'accepted', () {
      final configuration = _configure(
        ServerpodRunMode.development,
        _localEnvironment({
          'VERILY_REWARD_SOLANA_GENESIS_HASH': testBlockhash,
          'VERILY_REWARD_ESCROW_PROGRAM_ID': recipientAddress.value,
        }),
      );

      expect(configuration.genesisHash, testBlockhash);
      expect(configuration.programAddress, recipientAddress);
    });

    test('when production overrides the genesis then startup is refused', () {
      expect(
        () => _configure(
          ServerpodRunMode.production,
          _kmsEnvironment({'VERILY_REWARD_SOLANA_GENESIS_HASH': testBlockhash}),
        ),
        _refusedWith('VERILY_REWARD_SOLANA_GENESIS_HASH'),
      );
    });

    test('when production names another program then startup is refused', () {
      expect(
        () => _configure(
          ServerpodRunMode.production,
          _kmsEnvironment({
            'VERILY_REWARD_ESCROW_PROGRAM_ID': recipientAddress.value,
          }),
        ),
        _refusedWith('VERILY_REWARD_ESCROW_PROGRAM_ID'),
      );
      expect(
        _configure(
          ServerpodRunMode.production,
          _kmsEnvironment({
            'VERILY_REWARD_ESCROW_PROGRAM_ID':
                escrow.verilyEscrowProgramAddress.value,
          }),
        ).programAddress,
        escrow.verilyEscrowProgramAddress,
      );
    });
  });

  group('Given mainnet', () {
    test('when development asks for mainnet then startup is refused', () {
      expect(
        () => _configure(
          ServerpodRunMode.development,
          _localEnvironment(),
          cluster: RewardCluster.mainnet,
        ),
        _refusedWith('production run mode'),
      );
    });

    for (final flag in [null, 'false', 'yes', '1', 'TRUE']) {
      test('when production has VERILY_REWARD_MAINNET_ENABLED=$flag then '
          'startup is refused', () {
        expect(
          () => _configure(
            ServerpodRunMode.production,
            _kmsEnvironment({'VERILY_REWARD_MAINNET_ENABLED': ?flag}),
            cluster: RewardCluster.mainnet,
          ),
          _refusedWith('VERILY_REWARD_MAINNET_ENABLED'),
        );
      });
    }

    test('when production explicitly enables mainnet with KMS then mainnet '
        'USDC and the mainnet genesis are pinned', () {
      final configuration = _configure(
        ServerpodRunMode.production,
        _kmsEnvironment({'VERILY_REWARD_MAINNET_ENABLED': 'true'}),
        cluster: RewardCluster.mainnet,
      );

      expect(configuration.cluster, RewardCluster.mainnet);
      expect(
        configuration.genesisHash,
        solanaGenesisHashes[RewardCluster.mainnet],
      );
      expect(
        configuration.token.mint,
        'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
      );
    });

    test('when production enables mainnet with local keypairs then startup '
        'is refused', () {
      expect(
        () => _configure(
          ServerpodRunMode.production,
          _localEnvironment({'VERILY_REWARD_MAINNET_ENABLED': 'true'}),
          cluster: RewardCluster.mainnet,
        ),
        _refusedWith('refused outside development and test'),
      );
    });
  });

  group('Given gateway startup', () {
    late FakeSolanaRpc chain;
    late FakeKmsApiClient kms;
    late FakeKmsKey arbiterKey;
    late FakeKmsKey feePayerKey;

    setUp(() {
      chain = FakeSolanaRpc()
        ..genesisHash = devnetGenesisHash
        ..putChainIdentity();
      kms = FakeKmsApiClient();
      arbiterKey = FakeKmsKey();
      feePayerKey = FakeKmsKey();
      kms
        ..register(_arbiterKey, arbiterKey)
        ..register(_feePayerKey, feePayerKey);
    });

    Address addressOf(FakeKmsKey key) =>
        getAddressDecoder().decode(Uint8List.fromList(key.keyPair.publicKey));

    Future<SolanaRewardEscrowGateway> connectKms({
      Address? arbiter,
      Address? feePayer,
    }) => connectSolanaRewardEscrow(
      _configure(
        ServerpodRunMode.production,
        _kmsEnvironment({
          'VERILY_REWARD_ARBITER_ADDRESS':
              (arbiter ?? addressOf(arbiterKey)).value,
          'VERILY_REWARD_FEE_PAYER_ADDRESS':
              (feePayer ?? addressOf(feePayerKey)).value,
        }),
      ),
      rpcFactory: (_) => chain.rpc,
      kmsClientFactory: (_) async => kms,
    );

    test('when Cloud KMS proves both keys and the chain matches then the '
        'gateway signs with KMS', () async {
      final gateway = await connectKms();

      expect(gateway.arbiter, isA<KmsTransactionSigner>());
      expect(gateway.arbiter.address, addressOf(arbiterKey));
      expect(gateway.feePayer.address, addressOf(feePayerKey));
      expect(
        gateway.arbiterAddress(RewardCluster.devnet),
        addressOf(arbiterKey).value,
      );
      // One proof-of-possession signature per key at startup.
      expect(kms.signedKeyVersions, [_arbiterKey, _feePayerKey]);
      expect(kms.closed, isFalse);
      expect(chain.count('getGenesisHash'), 1);
    });

    test('when a KMS key differs from its pinned address then startup is '
        'refused and the client is closed', () async {
      await expectLater(
        connectKms(arbiter: recipientAddress),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('pinned address'),
          ),
        ),
      );
      expect(kms.signedKeyVersions, isEmpty);
      expect(kms.closed, isTrue);
    });

    test(
      'when a KMS key cannot prove possession then startup is refused',
      () async {
        feePayerKey.corruptSignatures = true;

        await expectLater(connectKms(), throwsStateError);
        expect(kms.closed, isTrue);
      },
    );

    test('when the RPC serves another cluster then startup is refused and '
        'the client is closed', () async {
      chain.genesisHash = solanaGenesisHashes[RewardCluster.mainnet]!;

      await expectLater(connectKms(), throwsStateError);
      expect(kms.closed, isTrue);
    });

    test('when local keypairs match their pinned addresses then the gateway '
        'is ready', () async {
      final gateway = await connectSolanaRewardEscrow(
        _configure(ServerpodRunMode.development, _localEnvironment()),
        rpcFactory: (_) => chain.rpc,
      );

      expect(gateway.arbiter.address, arbiterSigner.address);
      expect(gateway.feePayer.address, feePayerSigner.address);
    });

    test('when a local keypair belongs to another address then startup is '
        'refused', () async {
      await expectLater(
        connectSolanaRewardEscrow(
          _configure(
            ServerpodRunMode.development,
            _localEnvironment(),
            passwords: _passwords({
              'rewardArbiterKeypair': _keypairJson(recipientSigner),
            }),
          ),
          rpcFactory: (_) => chain.rpc,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('VERILY_REWARD_ARBITER_KEYPAIR does not match'),
          ),
        ),
      );
    });

    test(
      'when a local keypair halves disagree then startup is refused',
      () async {
        await expectLater(
          connectSolanaRewardEscrow(
            _configure(
              ServerpodRunMode.development,
              _localEnvironment(),
              passwords: _passwords({
                'rewardFeePayerKeypair': jsonEncode([
                  ...feePayerSigner.keyPair.privateKey,
                  ...arbiterSigner.keyPair.publicKey,
                ]),
              }),
            ),
            rpcFactory: (_) => chain.rpc,
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('not a consistent Solana keypair'),
            ),
          ),
        );
      },
    );

    test('when the escrow mode is not solana then nothing connects', () async {
      expect(
        await connectSolanaRewardEscrowFromEnvironment(
          runMode: ServerpodRunMode.production,
          environment: const {'VERILY_REWARD_ESCROW_MODE': 'disabled'},
          readPassword: (_) => throw StateError('No secret may be read.'),
        ),
        isNull,
      );
    });
  });

  group('Given the reward configuration in solana mode', () {
    const solana = {'VERILY_REWARD_ESCROW_MODE': 'solana'};

    test('when a connected devnet gateway is given then it is used', () {
      final gateway = testGateway(FakeSolanaRpc());

      final configuration = RewardConfiguration.fromEnvironment(
        runMode: ServerpodRunMode.development,
        environment: solana,
        solanaGateway: gateway,
      );

      expect(configuration.gateway, same(gateway));
      expect(configuration.cluster, RewardCluster.devnet);
    });

    test('when the gateway serves another cluster then startup is refused', () {
      expect(
        () => RewardConfiguration.fromEnvironment(
          runMode: ServerpodRunMode.production,
          environment: solana,
          solanaGateway: testGateway(FakeSolanaRpc()),
        ),
        _refusedWith('serves another cluster'),
      );
    });
  });
}
