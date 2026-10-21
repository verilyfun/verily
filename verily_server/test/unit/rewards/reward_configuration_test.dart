import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/local_development_reward_escrow_gateway.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';

void main() {
  RewardConfiguration configure(
    String runMode, [
    Map<String, String> environment = const {},
  ]) => RewardConfiguration.fromEnvironment(
    runMode: runMode,
    environment: environment,
  );

  Matcher refusedWith(String fragment) => throwsA(
    isA<StateError>().having(
      (error) => error.message,
      'message',
      contains(fragment),
    ),
  );

  group('Given no reward configuration', () {
    for (final runMode in [
      ServerpodRunMode.development,
      ServerpodRunMode.test,
      ServerpodRunMode.staging,
      ServerpodRunMode.production,
    ]) {
      test('when $runMode starts then rewards are disabled with the default '
          'review threshold', () {
        final configuration = configure(runMode);

        expect(configuration.gateway, isA<DisabledRewardEscrowGateway>());
        expect(configuration.gateway.isAvailable, isFalse);
        expect(
          configuration.reviewThresholdAtoms,
          defaultRewardReviewThresholdAtoms,
        );
      });
    }

    test('when development starts then pools default to devnet', () {
      expect(
        configure(ServerpodRunMode.development).cluster,
        RewardCluster.devnet,
      );
    });

    test('when production starts then pools default to mainnet USDC', () {
      final configuration = configure(ServerpodRunMode.production);

      expect(configuration.cluster, RewardCluster.mainnet);
      expect(configuration.token.symbol, 'USDC');
      expect(configuration.token.decimals, 6);
      expect(
        configuration.token.mint,
        'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
      );
    });
  });

  group('Given the local development escrow', () {
    const local = {'VERILY_REWARD_ESCROW_MODE': 'local-development'};

    for (final runMode in [
      ServerpodRunMode.development,
      ServerpodRunMode.test,
    ]) {
      test('when $runMode starts on devnet then the labelled simulation is '
          'used', () {
        final configuration = configure(runMode, local);

        expect(
          configuration.gateway,
          isA<LocalDevelopmentRewardEscrowGateway>(),
        );
        expect(configuration.gateway.isAvailable, isTrue);
        expect(configuration.cluster, RewardCluster.devnet);
      });
    }

    for (final runMode in [
      ServerpodRunMode.staging,
      ServerpodRunMode.production,
    ]) {
      test('when $runMode starts then startup is refused', () {
        expect(
          () => configure(runMode, local),
          refusedWith('refused outside development and test'),
        );
      });
    }

    test('when it is pointed at mainnet then startup is refused', () {
      expect(
        () => configure(ServerpodRunMode.development, {
          ...local,
          'VERILY_REWARD_CLUSTER': 'mainnet',
        }),
        refusedWith('only simulates devnet'),
      );
    });
  });

  group('Given the Solana escrow mode', () {
    for (final runMode in [
      ServerpodRunMode.development,
      ServerpodRunMode.production,
    ]) {
      test('when $runMode starts then it fails closed until the reviewed '
          'gateway ships', () {
        expect(
          () => configure(runMode, {'VERILY_REWARD_ESCROW_MODE': 'solana'}),
          refusedWith('not available in this build'),
        );
      });
    }
  });

  group('Given invalid reward settings', () {
    test('when the mode is unknown then startup is refused', () {
      expect(
        () => configure(ServerpodRunMode.development, {
          'VERILY_REWARD_ESCROW_MODE': 'fake',
        }),
        refusedWith('must be disabled, local-development, or solana'),
      );
    });

    test('when the cluster is unknown then startup is refused', () {
      expect(
        () => configure(ServerpodRunMode.development, {
          'VERILY_REWARD_CLUSTER': 'testnet',
        }),
        refusedWith('devnet or mainnet'),
      );
    });

    test('when the mode differs only in case and padding then it is '
        'accepted', () {
      expect(
        configure(ServerpodRunMode.test, {
          'VERILY_REWARD_ESCROW_MODE': ' Local-Development ',
          'VERILY_REWARD_CLUSTER': 'DEVNET',
        }).gateway,
        isA<LocalDevelopmentRewardEscrowGateway>(),
      );
    });
  });

  group('Given a payout review threshold', () {
    int? parse(String value) => parseRewardReviewThreshold({
      'VERILY_REWARD_REVIEW_THRESHOLD_ATOMS': value,
    });

    test('when unset or blank then the 25 USDC default applies', () {
      expect(parseRewardReviewThreshold(const {}), 25000000);
      expect(parse('  '), defaultRewardReviewThresholdAtoms);
    });

    test('when it is a whole number within bounds then it is used', () {
      expect(parse('0'), 0);
      expect(parse(' 1000000 '), 1000000);
      expect(parse('$maxRewardReviewThresholdAtoms'), 1000000000);
      expect(
        configure(ServerpodRunMode.production, {
          'VERILY_REWARD_REVIEW_THRESHOLD_ATOMS': '5000000',
        }).reviewThresholdAtoms,
        5000000,
      );
    });

    for (final value in [
      '-1',
      '1.5',
      '1e6',
      '25 USDC',
      '0x10',
      '1000000001',
      '99999999999999',
    ]) {
      test('when it is "$value" then it is invalid and startup is '
          'refused', () {
        expect(parse(value), isNull);
        expect(
          () => configure(ServerpodRunMode.development, {
            'VERILY_REWARD_REVIEW_THRESHOLD_ATOMS': value,
          }),
          refusedWith('VERILY_REWARD_REVIEW_THRESHOLD_ATOMS'),
        );
      });
    }
  });

  group('Given the disabled gateway', () {
    const gateway = DisabledRewardEscrowGateway();

    test('when a release is asked for then it fails retryably without '
        'moving value', () async {
      final outcome = await gateway.releasePayout(
        pool: _pool(),
        payoutIndex: 0,
        recipientWallet: _wallet,
      );

      expect(outcome, isA<RewardReleaseFailed>());
      expect((outcome as RewardReleaseFailed).retryable, isTrue);
      expect(outcome.code, 'escrow_gateway_unavailable');
    });

    test('when funding is prepared then a typed rewards-unavailable error '
        'is raised', () async {
      await expectLater(
        gateway.buildOpenEscrowTransaction(_pool()),
        throwsA(
          isA<RewardException>().having(
            (error) => error.problem,
            'problem',
            RewardProblem.rewardsUnavailable,
          ),
        ),
      );
      await expectLater(
        gateway.readEscrow(_pool()),
        throwsA(isA<RewardException>()),
      );
    });
  });

  group('Given the local development gateway', () {
    const gateway = LocalDevelopmentRewardEscrowGateway();

    test('when an escrow is derived then it is deterministic per pool', () {
      final first = gateway.deriveEscrowAddress(
        cluster: RewardCluster.devnet,
        creatorWallet: _wallet,
        poolId: _poolId,
      );

      expect(
        gateway.deriveEscrowAddress(
          cluster: RewardCluster.devnet,
          creatorWallet: _wallet,
          poolId: _poolId,
        ),
        first,
      );
      expect(
        gateway.deriveEscrowAddress(
          cluster: RewardCluster.devnet,
          creatorWallet: _wallet,
          poolId: UuidValue.withValidation(
            '0198bc26-4be5-7ca0-94d2-000000000099',
          ),
        ),
        isNot(first),
      );
    });

    test('when a funded escrow is read back then it matches its pool '
        'exactly', () async {
      final pool = _pool(
        escrowAddress: 'escrow',
        creatorWallet: _wallet,
        arbiterAddress: gateway.arbiterAddress(RewardCluster.devnet),
      );
      final state = await gateway.readEscrow(pool);

      expect(state, isNotNull);
      expect(rewardEscrowMismatches(pool, state!), isEmpty);
    });

    test('when a pool has no escrow yet then nothing is read', () async {
      expect(await gateway.readEscrow(_pool()), isNull);
    });

    test('when a payout is released then the signature is labelled as a '
        'local simulation', () async {
      final outcome = await gateway.releasePayout(
        pool: _pool(),
        payoutIndex: 3,
        recipientWallet: _wallet,
      );

      expect(
        (outcome as RewardReleased).signature,
        'local-dev-$_poolId-3',
      );
    });
  });
}

const _wallet = 'SysvarRent111111111111111111111111111111111';
final _poolId = UuidValue.withValidation(
  '0198bc26-4be5-7ca0-94d2-000000000042',
);

RewardPool _pool({
  String? escrowAddress,
  String? creatorWallet,
  String? arbiterAddress,
}) {
  final expiresAt = DateTime.utc(2026, 12);
  return RewardPool(
    id: _poolId,
    creatorAuthUserId: UuidValue.withValidation(
      '0198bc26-4be5-7ca0-94d2-000000000001',
    ),
    actionKey: 'water-a-plant',
    cluster: RewardCluster.devnet,
    mint: rewardTokens[RewardCluster.devnet]!.mint,
    tokenSymbol: 'USDC',
    decimals: 6,
    amountPerPayout: 1000000,
    maxPayouts: 10,
    creatorWallet: creatorWallet,
    escrowAddress: escrowAddress,
    arbiterAddress: arbiterAddress,
    expiresAt: expiresAt,
    refundDelaySeconds: 7 * 86400,
    refundAfter: expiresAt.add(const Duration(days: 7)),
    status: RewardPoolStatus.awaitingFunding,
  );
}
