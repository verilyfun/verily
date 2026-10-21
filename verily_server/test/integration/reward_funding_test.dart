import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';

import 'test_tools/fake_reward_escrow_gateway.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

Matcher _authoringProblem(ActionAuthoringProblem reason) => throwsA(
  isA<ActionAuthoringException>().having(
    (error) => error.reason,
    'reason',
    reason,
  ),
);

Matcher _rewardProblem(RewardProblem problem) => throwsA(
  isA<RewardException>().having(
    (error) => error.problem,
    'problem',
    problem,
  ),
);

Matcher _guardFailure(String message) => throwsA(
  isA<DatabaseQueryException>().having(
    (error) => error.message,
    'message',
    contains(message),
  ),
);

/// Runs [sql] in its own savepoint, so an expected failure does not abort the
/// test's enclosing transaction.
Future<void> _execute(Session session, String sql) =>
    session.db.transaction((transaction) async {
      await session.db.unsafeExecute(sql, transaction: transaction);
    });

void main() {
  withServerpod('Given a creator with a linked payout wallet', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x101);
    final otherCreatorId = testId(0x102);
    final participantId = testId(0x103);
    final creatorWallet = TestWallet.fromSeed(11);
    late TestSessionBuilder creator;
    late TestSessionBuilder otherCreator;
    late TestSessionBuilder participant;
    late FakeRewardEscrowGateway gateway;

    setUp(() async {
      gateway = FakeRewardEscrowGateway();
      RewardRuntime.current = fakeRewardConfiguration(gateway);
      creator = signedIn(sessionBuilder, creatorId);
      otherCreator = signedIn(sessionBuilder, otherCreatorId);
      participant = signedIn(sessionBuilder, participantId);
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        otherCreatorId: 'Linus',
        participantId: 'Grace',
      });
      await linkWallet(endpoints, creator, creatorWallet);
    });

    tearDown(() {
      RewardRuntime.current = const RewardConfiguration.disabled();
    });

    Future<ActionOpportunity> saveDraft(RewardTermsDraft reward) =>
        endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(
            actionKey: 'plant-a-tree',
            requirements: [locationRequirement()],
            reward: reward,
          ),
        );

    group('when a rewarded action is authored', () {
      test('then direct creation is refused until it is funded', () async {
        await expectLater(
          endpoints.actionVerification.createAction(
            creator,
            actionRequest(
              actionKey: 'plant-a-tree',
              requirements: [locationRequirement()],
              reward: rewardTerms(),
            ),
          ),
          _authoringProblem(ActionAuthoringProblem.rewardNeedsDraft),
        );
      });

      test('then terms outside the escrow bounds are refused', () async {
        final invalid = <String, RewardTermsDraft>{
          'zero amount': rewardTerms(amountPerPayout: 0),
          'amount above the cap': rewardTerms(
            amountPerPayout: RewardBounds.maxAmountPerPayoutAtoms + 1,
          ),
          'no payouts': rewardTerms(maxPayouts: 0),
          'too many payouts': rewardTerms(
            maxPayouts: RewardBounds.maxPayouts + 1,
          ),
          'no wins per account': rewardTerms(maxWinsPerAccount: 0),
          'too many wins per account': rewardTerms(
            maxWinsPerAccount: RewardBounds.maxWinsPerAccount + 1,
          ),
          'short refund delay': rewardTerms(
            refundDelayDays: RewardBounds.minRefundDelayDays - 1,
          ),
          'long refund delay': rewardTerms(
            refundDelayDays: RewardBounds.maxRefundDelayDays + 1,
          ),
          'short lifetime': rewardTerms(
            expiresIn: const Duration(minutes: 30),
          ),
          'long lifetime': rewardTerms(expiresIn: const Duration(days: 366)),
        };
        for (final entry in invalid.entries) {
          await expectLater(
            saveDraft(entry.value),
            throwsA(isA<ArgumentError>()),
            reason: entry.key,
          );
        }
        final pool = await RewardPool.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) => table.creatorAuthUserId.equals(creatorId),
        );
        expect(pool, isNull);
      });

      test('then draft terms stay editable and can be removed', () async {
        final draft = await saveDraft(rewardTerms(amountPerPayout: 500000));
        await saveDraft(rewardTerms(amountPerPayout: 750000, maxPayouts: 5));

        final pool = await endpoints.rewards.getRewardPool(
          creator,
          actionId: draft.id,
        );
        expect(pool!.status, RewardPoolStatus.draft);
        expect(pool.amountPerPayout, 750000);
        expect(pool.maxPayouts, 5);
        expect(pool.payoutsReserved, 0);
        expect(pool.escrowAddress, isNull);
        expect(pool.tokenSymbol, 'USDC');
        expect(pool.decimals, 6);

        await endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(
            actionKey: 'plant-a-tree',
            requirements: [locationRequirement()],
          ),
        );
        expect(
          await endpoints.rewards.getRewardPool(creator, actionId: draft.id),
          isNull,
        );
      });

      test('then the action cannot publish before it is funded', () async {
        final draft = await saveDraft(rewardTerms());

        await expectLater(
          endpoints.actionVerification.publishAction(
            creator,
            actionId: draft.id,
            expectedRevision: draft.revision,
          ),
          _authoringProblem(ActionAuthoringProblem.rewardNotFunded),
        );
        await endpoints.rewards.prepareRewardFunding(
          creator,
          actionId: draft.id,
        );
        await expectLater(
          endpoints.actionVerification.publishAction(
            creator,
            actionId: draft.id,
            expectedRevision: draft.revision,
          ),
          _authoringProblem(ActionAuthoringProblem.rewardNotFunded),
        );
      });
    });

    group('when funding is prepared', () {
      test(
        'then the plan names the derived escrow and the terms freeze',
        () async {
          final terms = rewardTerms(amountPerPayout: 2000000, maxPayouts: 4);
          final draft = await saveDraft(terms);

          final plan = await endpoints.rewards.prepareRewardFunding(
            creator,
            actionId: draft.id,
          );

          expect(plan.creatorWallet, creatorWallet.address);
          expect(plan.arbiterAddress, gateway.arbiterAddress(plan.cluster));
          expect(
            plan.escrowAddress,
            gateway.deriveEscrowAddress(
              cluster: RewardCluster.devnet,
              creatorWallet: creatorWallet.address,
              poolId: plan.poolId,
            ),
          );
          expect(plan.cluster, RewardCluster.devnet);
          expect(plan.mint, rewardTokens[RewardCluster.devnet]!.mint);
          expect(plan.totalAtoms, 8000000);
          expect(
            plan.refundAfter.difference(plan.expiresAt),
            const Duration(days: 3),
          );
          expect(
            utf8.decode(base64Decode(plan.unsignedTransaction)),
            'OpenEscrow:${plan.poolId}',
          );
          final pool = await endpoints.rewards.getRewardPool(
            creator,
            actionId: draft.id,
          );
          expect(pool!.status, RewardPoolStatus.awaitingFunding);

          await expectLater(
            saveDraft(rewardTerms(amountPerPayout: 1, maxPayouts: 4)),
            _authoringProblem(ActionAuthoringProblem.rewardTermsLocked),
          );
          // Repeating the frozen terms is allowed.
          await saveDraft(terms);

          final again = await endpoints.rewards.prepareRewardFunding(
            creator,
            actionId: draft.id,
          );
          expect(again.escrowAddress, plan.escrowAddress);
          expect(again.poolId, plan.poolId);
        },
      );

      test('then a creator without a payout wallet is asked for one', () async {
        final draft = await endpoints.actionVerification.saveActionDraft(
          otherCreator,
          actionRequest(
            actionKey: 'plant-a-tree',
            requirements: [locationRequirement()],
            reward: rewardTerms(),
          ),
        );

        await expectLater(
          endpoints.rewards.prepareRewardFunding(
            otherCreator,
            actionId: draft.id,
          ),
          _rewardProblem(RewardProblem.payoutWalletRequired),
        );
      });

      test('then an action without a reward reports none', () async {
        final draft = await endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(
            actionKey: 'no-reward',
            requirements: [locationRequirement()],
          ),
        );

        await expectLater(
          endpoints.rewards.prepareRewardFunding(creator, actionId: draft.id),
          _rewardProblem(RewardProblem.poolNotFound),
        );
      });
    });

    group('when funding is confirmed', () {
      late ActionOpportunity draft;

      setUp(() async {
        draft = await saveDraft(rewardTerms());
        await endpoints.rewards.prepareRewardFunding(
          creator,
          actionId: draft.id,
        );
      });

      test('then a missing escrow is refused', () async {
        gateway.readMode = FakeEscrowReadMode.missing;

        await expectLater(
          endpoints.rewards.confirmRewardFunding(
            creator,
            actionId: draft.id,
            signature: fakeSignature('fund'),
          ),
          _rewardProblem(RewardProblem.escrowNotFound),
        );
        final pool = await endpoints.rewards.getRewardPool(
          creator,
          actionId: draft.id,
        );
        expect(pool!.status, RewardPoolStatus.awaitingFunding);
      });

      test('then every mismatched escrow field is refused', () async {
        final tampering =
            <
              String,
              RewardEscrowAccountState Function(RewardEscrowAccountState)
            >{
              'owner': (state) =>
                  escrowStateWith(state, ownedByEscrowProgram: false),
              'address': (state) =>
                  escrowStateWith(state, escrowAddress: fakeAddress(['x'])),
              'creator': (state) =>
                  escrowStateWith(state, creator: fakeAddress(['creator'])),
              'arbiter': (state) =>
                  escrowStateWith(state, arbiter: fakeAddress(['arbiter'])),
              'mint': (state) =>
                  escrowStateWith(state, mint: fakeAddress(['mint'])),
              'poolId': (state) => escrowStateWith(state, poolId: testId(999)),
              'amountPerPayout': (state) => escrowStateWith(
                state,
                amountPerPayout: state.amountPerPayout + 1,
              ),
              'maxPayouts': (state) =>
                  escrowStateWith(state, maxPayouts: state.maxPayouts + 1),
              'expiresAt': (state) => escrowStateWith(
                state,
                expiresAt: state.expiresAt.add(const Duration(hours: 1)),
              ),
              'refundAfter': (state) => escrowStateWith(
                state,
                refundAfter: state.refundAfter.add(const Duration(hours: 1)),
              ),
              'refundDelay': (state) => escrowStateWith(
                state,
                refundDelaySeconds: state.refundDelaySeconds + 60,
              ),
              'releasedCount': (state) =>
                  escrowStateWith(state, releasedCount: 1),
              'vaultBalance': (state) =>
                  escrowStateWith(state, vaultBalance: state.vaultBalance - 1),
            };

        for (final entry in tampering.entries) {
          gateway.tamper = entry.value;
          final pool = await RewardPool.db.findFirstRow(
            sessionBuilder.build(),
            where: (table) => table.creatorAuthUserId.equals(creatorId),
          );
          expect(
            rewardEscrowMismatches(
              pool!,
              entry.value(matchingEscrowState(pool)),
            ),
            [entry.key],
          );
          await expectLater(
            endpoints.rewards.confirmRewardFunding(
              creator,
              actionId: draft.id,
              signature: fakeSignature('fund'),
            ),
            _rewardProblem(RewardProblem.escrowMismatch),
            reason: entry.key,
          );
        }
        final pool = await endpoints.rewards.getRewardPool(
          creator,
          actionId: draft.id,
        );
        expect(pool!.status, RewardPoolStatus.awaitingFunding);
        expect(pool.fundingSignature, isNull);
      });

      test('then a malformed signature is refused before any read', () async {
        await expectLater(
          endpoints.rewards.confirmRewardFunding(
            creator,
            actionId: draft.id,
            signature: 'not-a-signature',
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(gateway.readCount, 0);
      });

      test(
        'then a matching escrow funds the reward and the action can publish',
        () async {
          final signature = fakeSignature('fund');

          final funded = await endpoints.rewards.confirmRewardFunding(
            creator,
            actionId: draft.id,
            signature: signature,
          );
          final repeated = await endpoints.rewards.confirmRewardFunding(
            creator,
            actionId: draft.id,
            signature: signature,
          );

          expect(funded.status, RewardPoolStatus.funded);
          expect(funded.fundingSignature, signature);
          expect(funded.fundedAt, isNotNull);
          expect(repeated.status, RewardPoolStatus.funded);
          expect(gateway.readCount, 1);

          final published = await endpoints.actionVerification.publishAction(
            creator,
            actionId: draft.id,
            expectedRevision: draft.revision,
          );
          expect(published.status, ActionDefinitionStatus.active);
          final listed = await endpoints.actionVerification
              .listAvailableActions(participant, limit: 10);
          final reward = listed.single.reward!;
          expect(reward.status, RewardPoolStatus.funded);
          expect(reward.payoutsRemaining, 3);
          expect(reward.myWins, 0);
          expect(reward.escrowAddress, funded.escrowAddress);
        },
      );

      test('then confirming before preparing is refused', () async {
        final unprepared = await endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(
            actionKey: 'another-reward',
            requirements: [locationRequirement()],
            reward: rewardTerms(),
          ),
        );

        await expectLater(
          endpoints.rewards.confirmRewardFunding(
            creator,
            actionId: unprepared.id,
            signature: fakeSignature('fund'),
          ),
          _rewardProblem(RewardProblem.poolNotAwaitingFunding),
        );
      });
    });

    group('when someone other than the creator manages the reward', () {
      test('then every creator operation is refused', () async {
        final draft = await saveDraft(rewardTerms());

        await expectLater(
          endpoints.rewards.getRewardPool(otherCreator, actionId: draft.id),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          endpoints.rewards.prepareRewardFunding(
            otherCreator,
            actionId: draft.id,
          ),
          throwsA(isA<StateError>()),
        );
        await endpoints.rewards.prepareRewardFunding(
          creator,
          actionId: draft.id,
        );
        await expectLater(
          endpoints.rewards.confirmRewardFunding(
            participant,
            actionId: draft.id,
            signature: fakeSignature('fund'),
          ),
          throwsA(isA<StateError>()),
        );
        await endpoints.rewards.confirmRewardFunding(
          creator,
          actionId: draft.id,
          signature: fakeSignature('fund'),
        );
        await expectLater(
          endpoints.rewards.endRewardEarly(participant, actionId: draft.id),
          throwsA(isA<StateError>()),
        );
        final pool = await endpoints.rewards.getRewardPool(
          creator,
          actionId: draft.id,
        );
        expect(pool!.status, RewardPoolStatus.funded);
      });
    });

    group('when the creator ends a funded reward early', () {
      test(
        'then expiry moves to now and the end transaction is returned',
        () async {
          final action = await fundedRewardAction(
            endpoints,
            creator,
            actionKey: 'plant-a-tree',
            reward: rewardTerms(),
          );
          final before = DateTime.now().toUtc();

          final plan = await endpoints.rewards.endRewardEarly(
            creator,
            actionId: action.id,
          );

          expect(
            plan.expiresAt.isAfter(before.add(const Duration(seconds: 2))),
            isFalse,
          );
          expect(
            plan.refundAfter.difference(plan.expiresAt),
            const Duration(days: 3),
          );
          expect(
            utf8.decode(base64Decode(plan.unsignedTransaction)),
            'EndEarly:${plan.poolId}',
          );
          final pool = await endpoints.rewards.getRewardPool(
            creator,
            actionId: action.id,
          );
          expect(pool!.status, RewardPoolStatus.ended);
          await expectLater(
            endpoints.rewards.endRewardEarly(creator, actionId: action.id),
            _rewardProblem(RewardProblem.poolEnded),
          );
        },
      );

      test('then an unfunded reward cannot end early', () async {
        final draft = await saveDraft(rewardTerms());

        await expectLater(
          endpoints.rewards.endRewardEarly(creator, actionId: draft.id),
          _rewardProblem(RewardProblem.poolEnded),
        );
      });
    });

    group('when funded terms are changed directly in the database', () {
      late UuidValue poolId;

      setUp(() async {
        final action = await fundedRewardAction(
          endpoints,
          creator,
          actionKey: 'plant-a-tree',
          reward: rewardTerms(),
        );
        final pool = await endpoints.rewards.getRewardPool(
          creator,
          actionId: action.id,
        );
        poolId = pool!.poolId;
      });

      test('then the terms guard rejects a new amount', () async {
        await expectLater(
          _execute(
            sessionBuilder.build(),
            'UPDATE verily_reward_pool SET "amountPerPayout" = 1 '
            "WHERE id = '$poolId'",
          ),
          _guardFailure('reward terms are immutable'),
        );
      });

      test('then the terms guard rejects an extended expiry', () async {
        await expectLater(
          _execute(
            sessionBuilder.build(),
            'UPDATE verily_reward_pool '
            "SET \"expiresAt\" = \"expiresAt\" + interval '1 day', "
            "\"refundAfter\" = \"refundAfter\" + interval '1 day' "
            "WHERE id = '$poolId'",
          ),
          _guardFailure('never be extended'),
        );
      });

      test('then the terms guard allows ending earlier', () async {
        await _execute(
          sessionBuilder.build(),
          'UPDATE verily_reward_pool '
          "SET \"expiresAt\" = \"expiresAt\" - interval '1 day', "
          "\"refundAfter\" = \"refundAfter\" - interval '1 day' "
          "WHERE id = '$poolId'",
        );
        final pool = await RewardPool.db.findById(
          sessionBuilder.build(),
          poolId,
        );
        expect(
          pool!.expiresAt.isBefore(
            DateTime.now().toUtc().add(const Duration(days: 6, hours: 1)),
          ),
          isTrue,
        );
      });
    });
  });

  withServerpod('Given rewards are not configured', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x111);
    late TestSessionBuilder creator;

    setUp(() async {
      RewardRuntime.current = const RewardConfiguration.disabled();
      creator = signedIn(sessionBuilder, creatorId);
      await insertAccounts(sessionBuilder.build(), {creatorId: 'Ada'});
    });

    test(
      'when the creator funds or ends a reward then a typed unavailable '
      'error is returned',
      () async {
        final draft = await endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(
            actionKey: 'plant-a-tree',
            requirements: [locationRequirement()],
            reward: rewardTerms(),
          ),
        );

        await expectLater(
          endpoints.rewards.prepareRewardFunding(creator, actionId: draft.id),
          _rewardProblem(RewardProblem.rewardsUnavailable),
        );
        await expectLater(
          endpoints.rewards.confirmRewardFunding(
            creator,
            actionId: draft.id,
            signature: fakeSignature('fund'),
          ),
          _rewardProblem(RewardProblem.rewardsUnavailable),
        );
        await expectLater(
          endpoints.rewards.endRewardEarly(creator, actionId: draft.id),
          _rewardProblem(RewardProblem.rewardsUnavailable),
        );
        await expectLater(
          endpoints.actionVerification.publishAction(
            creator,
            actionId: draft.id,
            expectedRevision: draft.revision,
          ),
          _authoringProblem(ActionAuthoringProblem.rewardNotFunded),
        );
      },
    );
  });
}
