import 'package:serverpod/protocol.dart' show FutureCallEntry;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/capture_integrity.dart';
import 'package:verily_server/src/action_verification/device_integrity_verifier.dart';
import 'package:verily_server/src/action_verification/evidence_verification_worker.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';

import 'test_tools/fake_reward_escrow_gateway.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _reviewScope = 'evidence.review';

Future<RewardPayout?> _payoutFor(Session session, UuidValue attemptId) =>
    RewardPayout.db.findFirstRow(
      session,
      where: (table) => table.attemptId.equals(attemptId),
    );

Future<RewardPool> _poolOf(
  Session session,
  UuidValue creatorId,
  String actionKey,
) async => (await RewardPool.db.findFirstRow(
  session,
  where: (table) =>
      table.creatorAuthUserId.equals(creatorId) &
      table.actionKey.equals(actionKey),
))!;

/// Future calls the production scheduler created for [payoutId].
Future<int> _scheduledReleaseCalls(Session session, UuidValue payoutId) =>
    FutureCallEntry.db.count(
      session,
      where: (table) => table.serializedObject.like('%$payoutId%'),
    );

/// Runs [body] in its own savepoint, so an expected failure does not abort
/// the test's enclosing transaction.
Future<void> _inSavepoint(
  Session session,
  Future<void> Function(Transaction transaction) body,
) => session.db.transaction(body);

Matcher _guardFailure(String message) => throwsA(
  isA<DatabaseQueryException>().having(
    (error) => error.message,
    'message',
    contains(message),
  ),
);

void main() {
  withServerpod('Given a funded reward pool', (sessionBuilder, endpoints) {
    final creatorId = testId(0x201);
    final firstId = testId(0x202);
    final secondId = testId(0x203);
    final walletlessId = testId(0x204);
    final firstWallet = TestWallet.fromSeed(21);
    final secondWallet = TestWallet.fromSeed(22);
    late TestSessionBuilder creator;
    late TestSessionBuilder first;
    late TestSessionBuilder second;
    late TestSessionBuilder walletless;
    late FakeRewardEscrowGateway gateway;
    late RewardConfiguration configuration;
    late RecordingRewardPayoutScheduler scheduler;

    RewardPayoutService payouts({DateTime Function()? clock}) =>
        RewardPayoutService(
          configuration: configuration,
          scheduler: scheduler,
          clock: clock,
        );

    setUp(() async {
      gateway = FakeRewardEscrowGateway();
      configuration = fakeRewardConfiguration(gateway);
      RewardRuntime.current = configuration;
      scheduler = RecordingRewardPayoutScheduler();
      creator = signedIn(sessionBuilder, creatorId);
      first = signedIn(sessionBuilder, firstId);
      second = signedIn(sessionBuilder, secondId);
      walletless = signedIn(sessionBuilder, walletlessId);
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {
        creatorId: 'Ada',
        firstId: 'Grace',
        secondId: 'Katherine',
        walletlessId: 'Dorothy',
      });
      await linkWallet(endpoints, creator, TestWallet.fromSeed(20));
      await linkWallet(endpoints, first, firstWallet);
      await linkWallet(endpoints, second, secondWallet);
    });

    tearDown(() {
      RewardRuntime.current = const RewardConfiguration.disabled();
    });

    Future<ActionOpportunity> fundedAction({
      String actionKey = 'plant-a-tree',
      int maxPayouts = 3,
      int maxWinsPerAccount = 1,
      int? maxVerifiedCompletions,
    }) => fundedRewardAction(
      endpoints,
      creator,
      actionKey: actionKey,
      reward: rewardTerms(
        maxPayouts: maxPayouts,
        maxWinsPerAccount: maxWinsPerAccount,
      ),
      maxVerifiedCompletions: maxVerifiedCompletions,
    );

    group('when proof toward the reward is captured', () {
      late _StrongIntegrityProbe integrity;
      late ActionVerificationService service;

      setUp(() {
        integrity = _StrongIntegrityProbe();
        service = ActionVerificationService(
          captureIntegrity: CaptureIntegrityEvaluator(
            deviceIntegrityRequired: true,
            deviceIntegrityVerifier: integrity,
          ),
        );
      });

      Future<EvidenceSubmissionResult> checkIn(
        ActionOpportunity action,
        String key,
      ) async {
        final session = first.build();
        final attempt = await endpoints.actionVerification.beginAttempt(
          first,
          actionId: action.id,
          idempotencyKey: key,
        );
        final requirement = action.requirements.single;
        final window = await service.beginCapture(
          session,
          authUserId: firstId,
          attemptId: attempt.id,
          requirementId: requirement.id,
        );
        return service.submitEvidence(
          session,
          authUserId: firstId,
          input: ActionEvidenceInput(
            attemptId: attempt.id,
            requirementId: requirement.id,
            capturedAt: DateTime.now().toUtc(),
            latitude: requirement.latitude,
            longitude: requirement.longitude,
            accuracyMeters: 10,
            captureChallengeId: window.id,
            deviceIntegrityToken: 'device-token',
          ),
        );
      }

      test(
        'then a payout above the review threshold needs strong integrity',
        () async {
          RewardRuntime.current = fakeRewardConfiguration(
            gateway,
            reviewThresholdAtoms: 500000,
          );
          final action = await fundedAction(actionKey: 'large-reward');

          final result = await checkIn(action, 'large');

          expect(integrity.strongRequired, [true]);
          expect(result.status, EvidenceDecisionStatus.rejected);
          expect(result.reasonCode, 'capture_not_verified');
        },
      );

      test(
        'then a payout within the threshold needs only device integrity',
        () async {
          final action = await fundedAction(actionKey: 'small-reward');

          final result = await checkIn(action, 'small');

          expect(integrity.strongRequired, [false]);
          expect(result.status, EvidenceDecisionStatus.accepted);
        },
      );
    });

    group('when a participant completes the action', () {
      test(
        'then the next payout index is reserved and its release is scheduled',
        () async {
          final action = await fundedAction();

          final completed = await completedLocationAttempt(
            endpoints,
            first,
            action: action,
            idempotencyKey: 'first-attempt',
          );

          expect(completed.status, ActionAttemptStatus.verified);
          expect(completed.rewardOutcome, RewardOutcome.won);
          expect(completed.payoutStatus, RewardPayoutStatus.reserved);
          final session = sessionBuilder.build();
          final payout = (await _payoutFor(session, completed.id))!;
          expect(payout.payoutIndex, 0);
          expect(payout.amount, 1000000);
          expect(payout.recipientAuthUserId, firstId);
          expect(payout.status, RewardPayoutStatus.reserved);
          final pool = await _poolOf(session, creatorId, 'plant-a-tree');
          expect(pool.payoutsReserved, 1);
          expect(await _scheduledReleaseCalls(session, payout.id!), 1);

          final mine = await endpoints.rewards.listMyPayouts(first, limit: 10);
          expect(mine.single.id, payout.id);
          expect(mine.single.actionTitle, 'Water a plant');
          expect(mine.single.status, RewardPayoutStatus.reserved);
          expect(
            mine.single.payableUntil,
            pool.refundAfter.subtract(RewardBounds.releaseSafetyMargin),
          );
          expect(
            await endpoints.rewards.listMyPayouts(second, limit: 10),
            isEmpty,
          );

          final listed = await endpoints.actionVerification
              .listAvailableActions(first, limit: 10);
          expect(listed.single.reward!.myWins, 1);
          expect(listed.single.reward!.payoutsRemaining, 2);
        },
      );

      test('then completing again returns the same payout', () async {
        final action = await fundedAction();
        final completed = await completedLocationAttempt(
          endpoints,
          first,
          action: action,
          idempotencyKey: 'first-attempt',
        );

        final again = await endpoints.actionVerification.completeAttempt(
          first,
          completed.id,
        );

        expect(again.payoutStatus, RewardPayoutStatus.reserved);
        final session = sessionBuilder.build();
        expect(
          await RewardPayout.db.count(
            session,
            where: (table) => table.recipientAuthUserId.equals(firstId),
          ),
          1,
        );
        expect(
          (await _poolOf(session, creatorId, 'plant-a-tree')).payoutsReserved,
          1,
        );
      });

      test('then every payout in the pool is taken in order', () async {
        final action = await fundedAction(maxPayouts: 1);

        final winner = await completedLocationAttempt(
          endpoints,
          first,
          action: action,
          idempotencyKey: 'first-attempt',
        );
        final late = await completedLocationAttempt(
          endpoints,
          second,
          action: action,
          idempotencyKey: 'second-attempt',
        );

        expect(winner.rewardOutcome, RewardOutcome.won);
        expect(late.status, ActionAttemptStatus.verified);
        expect(late.rewardOutcome, RewardOutcome.poolEmpty);
        expect(late.payoutStatus, isNull);
        final session = sessionBuilder.build();
        expect(await _payoutFor(session, late.id), isNull);
        final listed = await endpoints.actionVerification.listAvailableActions(
          second,
          limit: 10,
        );
        expect(listed.single.reward!.payoutsRemaining, 0);
      });

      test(
        'then an account at its win cap verifies on a new revision without '
        'another payout',
        () async {
          final action = await fundedAction();
          final firstWin = await completedLocationAttempt(
            endpoints,
            first,
            action: action,
            idempotencyKey: 'revision-one',
          );
          final revision = await endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: 'plant-a-tree',
              title: 'Water a plant again',
              requirements: [locationRequirement()],
            ),
          );
          expect(revision.revision, 2);
          final live = await endpoints.actionVerification.publishAction(
            creator,
            actionId: revision.id,
            expectedRevision: revision.revision,
          );

          final capped = await completedLocationAttempt(
            endpoints,
            first,
            action: live,
            idempotencyKey: 'revision-two',
          );
          final newcomer = await completedLocationAttempt(
            endpoints,
            second,
            action: live,
            idempotencyKey: 'revision-two-second',
          );

          expect(firstWin.rewardOutcome, RewardOutcome.won);
          expect(capped.status, ActionAttemptStatus.verified);
          expect(capped.rewardOutcome, RewardOutcome.accountLimitReached);
          expect(capped.payoutStatus, isNull);
          expect(newcomer.rewardOutcome, RewardOutcome.won);
          final session = sessionBuilder.build();
          expect((await _payoutFor(session, newcomer.id))!.payoutIndex, 1);
        },
      );

      test(
        'then the action capacity stops completion before any payout',
        () async {
          final action = await fundedAction(maxVerifiedCompletions: 1);
          // Both start while the action still has room.
          final winner = await readyLocationAttempt(
            endpoints,
            first,
            action: action,
            idempotencyKey: 'first-attempt',
          );
          final ready = await readyLocationAttempt(
            endpoints,
            second,
            action: action,
            idempotencyKey: 'second-attempt',
          );
          final won = await endpoints.actionVerification.completeAttempt(
            first,
            winner.id,
          );
          expect(won.rewardOutcome, RewardOutcome.won);

          final full = await endpoints.actionVerification.completeAttempt(
            second,
            ready.id,
          );

          expect(full.status, ActionAttemptStatus.capacityReached);
          expect(full.rewardOutcome, isNull);
          final session = sessionBuilder.build();
          expect(await _payoutFor(session, full.id), isNull);
          expect(
            (await _poolOf(session, creatorId, 'plant-a-tree')).payoutsReserved,
            1,
          );
        },
      );

      test('then a reward ended early pays nothing new', () async {
        final action = await fundedAction();
        final early = await completedLocationAttempt(
          endpoints,
          first,
          action: action,
          idempotencyKey: 'first-attempt',
        );
        await endpoints.rewards.endRewardEarly(creator, actionId: action.id);

        final after = await completedLocationAttempt(
          endpoints,
          second,
          action: action,
          idempotencyKey: 'second-attempt',
        );

        expect(after.status, ActionAttemptStatus.verified);
        expect(after.rewardOutcome, RewardOutcome.poolEnded);
        final session = sessionBuilder.build();
        expect(await _payoutFor(session, after.id), isNull);
        // A payout reserved before the end still releases.
        final reserved = (await _payoutFor(session, early.id))!;
        await payouts().release(session, reserved.id!);
        expect(
          (await RewardPayout.db.findById(session, reserved.id!))!.status,
          RewardPayoutStatus.released,
        );
      });

      test('then a pool past its expiry records that it ended', () async {
        final action = await fundedAction();
        final ready = await readyLocationAttempt(
          endpoints,
          first,
          action: action,
          idempotencyKey: 'first-attempt',
        );
        final session = sessionBuilder.build();
        final pool = await _poolOf(session, creatorId, 'plant-a-tree');
        DateTime afterExpiry() =>
            pool.expiresAt.add(const Duration(minutes: 1));

        final completed = await ActionVerificationService(
          clock: afterExpiry,
          payouts: payouts(clock: afterExpiry),
        ).completeAttempt(session, authUserId: firstId, attemptId: ready.id);

        expect(completed.status, ActionAttemptStatus.verified);
        expect(completed.rewardOutcome, RewardOutcome.poolEnded);
        expect(await _payoutFor(session, completed.id), isNull);
        expect(scheduler.scheduled, isEmpty);
      });
    });

    group('when the release job runs', () {
      late RewardPayout payout;
      late RewardPool pool;

      setUp(() async {
        final action = await fundedAction();
        final completed = await completedLocationAttempt(
          endpoints,
          first,
          action: action,
          idempotencyKey: 'first-attempt',
        );
        final session = sessionBuilder.build();
        payout = (await _payoutFor(session, completed.id))!;
        pool = await _poolOf(session, creatorId, 'plant-a-tree');
      });

      Future<RewardPayout> reload() async =>
          (await RewardPayout.db.findById(sessionBuilder.build(), payout.id!))!;

      test(
        'then the payout is paid to the frozen wallet exactly once',
        () async {
          await endpoints.futureCalls.rewardPayout.release(
            sessionBuilder,
            RewardPayoutTask(payoutId: payout.id!),
          );
          await payouts().release(sessionBuilder.build(), payout.id!);

          final released = await reload();
          expect(released.status, RewardPayoutStatus.released);
          expect(released.recipientWallet, firstWallet.address);
          expect(
            released.releaseSignature,
            fakeSignature('release-${pool.id}-0'),
          );
          expect(released.releasedAt, isNotNull);
          expect(released.attemptCount, 1);
          expect(gateway.releaseCalls, hasLength(1));
          expect(gateway.releaseCalls.single.payoutIndex, 0);
          expect(
            gateway.releaseCalls.single.recipientWallet,
            firstWallet.address,
          );
          final session = sessionBuilder.build();
          expect(
            (await _poolOf(session, creatorId, 'plant-a-tree')).payoutsReleased,
            1,
          );
          final mine = await endpoints.rewards.listMyPayouts(first, limit: 10);
          expect(mine.single.status, RewardPayoutStatus.released);
          expect(mine.single.releaseSignature, released.releaseSignature);
        },
      );

      test(
        'then a relinked wallet does not change a frozen recipient',
        () async {
          await RewardPayout.db.updateRow(
            sessionBuilder.build(),
            payout.copyWith(recipientWallet: firstWallet.address),
          );
          await linkWallet(endpoints, first, TestWallet.fromSeed(29));

          await payouts().release(sessionBuilder.build(), payout.id!);

          expect(
            gateway.releaseCalls.single.recipientWallet,
            firstWallet.address,
          );
        },
      );

      test(
        'then an index already paid on chain is recorded as released',
        () async {
          gateway.markReleased(pool.id!, payout.payoutIndex);

          await payouts().release(sessionBuilder.build(), payout.id!);

          final released = await reload();
          expect(released.status, RewardPayoutStatus.released);
          expect(released.releaseSignature, isNull);
          expect(
            (await _poolOf(
              sessionBuilder.build(),
              creatorId,
              'plant-a-tree',
            )).payoutsReleased,
            1,
          );
        },
      );

      test(
        'then a retryable failure reschedules with backoff until the attempts '
        'run out',
        () async {
          for (var attempt = 1; attempt <= rewardPayoutMaxAttempts; attempt++) {
            gateway.releaseScript.add(
              () => const RewardReleaseFailed('rpc_timeout', retryable: true),
            );
            await payouts().release(sessionBuilder.build(), payout.id!);

            final current = await reload();
            expect(current.attemptCount, attempt);
            expect(current.lastErrorCode, 'rpc_timeout');
            if (attempt < rewardPayoutMaxAttempts) {
              expect(current.status, RewardPayoutStatus.reserved);
              expect(scheduler.scheduled, hasLength(attempt));
              expect(
                scheduler.scheduled.last.delay,
                Duration(seconds: 15 * (1 << (attempt - 1))),
              );
            } else {
              expect(current.status, RewardPayoutStatus.failed);
              expect(scheduler.scheduled, hasLength(attempt - 1));
            }
          }

          await payouts().release(sessionBuilder.build(), payout.id!);
          expect(gateway.releaseCalls, hasLength(rewardPayoutMaxAttempts));
        },
      );

      test('then a permanent failure stops without a retry', () async {
        gateway.releaseScript.add(
          () =>
              const RewardReleaseFailed('recipient_invalid', retryable: false),
        );

        await payouts().release(sessionBuilder.build(), payout.id!);
        await payouts().release(sessionBuilder.build(), payout.id!);

        final failed = await reload();
        expect(failed.status, RewardPayoutStatus.failed);
        expect(failed.lastErrorCode, 'recipient_invalid');
        expect(failed.attemptCount, 1);
        expect(scheduler.scheduled, isEmpty);
        expect(gateway.releaseCalls, hasLength(1));
      });

      test('then a gateway error is retried with a stable code', () async {
        gateway.releaseScript.add(() => throw StateError('rpc unreachable'));

        await payouts().release(sessionBuilder.build(), payout.id!);

        final retried = await reload();
        expect(retried.status, RewardPayoutStatus.reserved);
        expect(retried.lastErrorCode, 'escrow_gateway_error');
        expect(scheduler.scheduled.single.payoutId, payout.id);
        expect(scheduler.scheduled.single.delay, const Duration(seconds: 15));
      });

      test('then a release in flight is not claimed twice', () async {
        final now = DateTime.now().toUtc();
        await RewardPayout.db.updateRow(
          sessionBuilder.build(),
          payout.copyWith(
            status: RewardPayoutStatus.releasing,
            recipientWallet: firstWallet.address,
            attemptCount: 1,
            releaseStartedAt: now.subtract(const Duration(minutes: 1)),
          ),
        );

        await payouts().release(sessionBuilder.build(), payout.id!);

        expect(gateway.releaseCalls, isEmpty);
        expect((await reload()).status, RewardPayoutStatus.releasing);
      });

      test('then a release whose lease expired is retried', () async {
        final now = DateTime.now().toUtc();
        await RewardPayout.db.updateRow(
          sessionBuilder.build(),
          payout.copyWith(
            status: RewardPayoutStatus.releasing,
            recipientWallet: firstWallet.address,
            attemptCount: 1,
            releaseStartedAt: now.subtract(
              rewardPayoutReleaseLease + const Duration(minutes: 1),
            ),
          ),
        );

        await payouts().release(sessionBuilder.build(), payout.id!);

        final released = await reload();
        expect(released.status, RewardPayoutStatus.released);
        expect(released.attemptCount, 2);
        expect(gateway.releaseCalls, hasLength(1));
      });

      group('and the refund window is about to open', () {
        DateTime insideMargin() => pool.refundAfter.subtract(
          RewardBounds.releaseSafetyMargin - const Duration(minutes: 1),
        );

        test('then a reserved payout expires without a release', () async {
          await payouts(
            clock: insideMargin,
          ).release(sessionBuilder.build(), payout.id!);

          final expired = await reload();
          expect(expired.status, RewardPayoutStatus.expired);
          expect(expired.lastErrorCode, 'refund_window_reached');
          expect(gateway.releaseCalls, isEmpty);
        });

        test('then a payout just outside the margin still releases', () async {
          await payouts(
            clock: () => pool.refundAfter.subtract(
              RewardBounds.releaseSafetyMargin + const Duration(minutes: 1),
            ),
          ).release(sessionBuilder.build(), payout.id!);

          expect((await reload()).status, RewardPayoutStatus.released);
        });

        Future<void> loseRelease() => RewardPayout.db.updateRow(
          sessionBuilder.build(),
          payout.copyWith(
            status: RewardPayoutStatus.releasing,
            recipientWallet: firstWallet.address,
            attemptCount: 1,
            releaseStartedAt: insideMargin().subtract(
              rewardPayoutReleaseLease + const Duration(minutes: 1),
            ),
          ),
        );

        test('then a lost release that landed is recorded as paid', () async {
          await loseRelease();
          gateway.markReleased(pool.id!, payout.payoutIndex);

          await payouts(
            clock: insideMargin,
          ).release(sessionBuilder.build(), payout.id!);

          expect((await reload()).status, RewardPayoutStatus.released);
          expect(gateway.releaseCalls, isEmpty);
          expect(gateway.bitmapReadCount, 1);
        });

        test('then a lost release that never landed expires', () async {
          await loseRelease();

          await payouts(
            clock: insideMargin,
          ).release(sessionBuilder.build(), payout.id!);

          final expired = await reload();
          expect(expired.status, RewardPayoutStatus.expired);
          expect(expired.lastErrorCode, 'refund_window_reached');
          expect(gateway.releaseCalls, isEmpty);
          expect(scheduler.scheduled, isEmpty);
        });

        test(
          'then an unreadable bitmap keeps the lease for recovery',
          () async {
            await loseRelease();
            gateway.bitmapError = Exception('rpc unreachable');

            await payouts(
              clock: insideMargin,
            ).release(sessionBuilder.build(), payout.id!);

            expect((await reload()).status, RewardPayoutStatus.releasing);
          },
        );
      });

      test('then a blocked recipient is held for review', () async {
        final session = sessionBuilder.build();
        final account = (await AuthUser.db.findById(session, firstId))!;
        await AuthUser.db.updateRow(session, account.copyWith(blocked: true));

        await payouts().release(session, payout.id!);

        final held = await reload();
        expect(held.status, RewardPayoutStatus.heldForReview);
        expect(held.lastErrorCode, 'recipient_inactive');
        expect(gateway.releaseCalls, isEmpty);
      });
    });

    group('when the winner has no payout wallet', () {
      test(
        'then the payout waits and releases after the wallet is linked',
        () async {
          final action = await fundedAction();
          final completed = await completedLocationAttempt(
            endpoints,
            walletless,
            action: action,
            idempotencyKey: 'walletless-attempt',
          );
          expect(completed.rewardOutcome, RewardOutcome.won);
          expect(completed.payoutStatus, RewardPayoutStatus.awaitingWallet);
          final session = sessionBuilder.build();
          final payout = (await _payoutFor(session, completed.id))!;
          expect(await _scheduledReleaseCalls(session, payout.id!), 0);

          await payouts().release(session, payout.id!);
          expect(
            (await RewardPayout.db.findById(session, payout.id!))!.status,
            RewardPayoutStatus.awaitingWallet,
          );
          expect(gateway.releaseCalls, isEmpty);

          final wallet = TestWallet.fromSeed(24);
          await linkWallet(endpoints, walletless, wallet);
          expect(
            (await RewardPayout.db.findById(session, payout.id!))!.status,
            RewardPayoutStatus.reserved,
          );
          expect(await _scheduledReleaseCalls(session, payout.id!), 1);

          await endpoints.futureCalls.rewardPayout.release(
            sessionBuilder,
            RewardPayoutTask(payoutId: payout.id!),
          );
          final released = (await RewardPayout.db.findById(
            session,
            payout.id!,
          ))!;
          expect(released.status, RewardPayoutStatus.released);
          expect(released.recipientWallet, wallet.address);
        },
      );
    });

    group('when recovery runs', () {
      late RewardPayout payout;
      late RewardPool pool;

      setUp(() async {
        final action = await fundedAction();
        final completed = await completedLocationAttempt(
          endpoints,
          first,
          action: action,
          idempotencyKey: 'first-attempt',
        );
        final session = sessionBuilder.build();
        payout = (await _payoutFor(session, completed.id))!;
        pool = await _poolOf(session, creatorId, 'plant-a-tree');
      });

      test(
        'then a reserved payout that missed its call is scheduled',
        () async {
          await payouts().recover(sessionBuilder.build(), batchSize: 10);
          expect(scheduler.scheduled, isEmpty);

          await payouts(
            clock: () => DateTime.now().toUtc().add(const Duration(minutes: 3)),
          ).recover(sessionBuilder.build(), batchSize: 10);

          expect(scheduler.scheduled.single.payoutId, payout.id);
        },
      );

      test('then the recurring future call schedules it too', () async {
        final session = sessionBuilder.build();
        await RewardPayout.db.updateRow(
          session,
          payout.copyWith(
            updatedAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 5),
            ),
          ),
        );
        final before = await _scheduledReleaseCalls(session, payout.id!);

        await endpoints.futureCalls.rewardPayoutRecovery.recover(
          sessionBuilder,
          RewardPayoutRecoveryTask(batchSize: 10),
        );

        expect(await _scheduledReleaseCalls(session, payout.id!), before + 1);
      });

      test('then a lost release past its lease is scheduled', () async {
        final now = DateTime.now().toUtc();
        await RewardPayout.db.updateRow(
          sessionBuilder.build(),
          payout.copyWith(
            status: RewardPayoutStatus.releasing,
            recipientWallet: firstWallet.address,
            attemptCount: 1,
            releaseStartedAt: now.subtract(
              rewardPayoutReleaseLease + const Duration(minutes: 1),
            ),
          ),
        );

        await payouts().recover(sessionBuilder.build(), batchSize: 10);

        expect(scheduler.scheduled.single.payoutId, payout.id);
      });

      test('then a wallet linked elsewhere wakes a waiting payout', () async {
        final session = sessionBuilder.build();
        final waiting = await completedLocationAttempt(
          endpoints,
          walletless,
          action: (await endpoints.actionVerification.listAvailableActions(
            walletless,
            limit: 10,
          )).single,
          idempotencyKey: 'walletless-attempt',
        );
        final waitingPayout = (await _payoutFor(session, waiting.id))!;
        expect(waitingPayout.status, RewardPayoutStatus.awaitingWallet);
        final now = DateTime.now().toUtc();
        await PayoutWallet.db.insertRow(
          session,
          PayoutWallet(
            authUserId: walletlessId,
            walletAddress: TestWallet.fromSeed(25).address,
            linkedAt: now,
            updatedAt: now,
          ),
        );

        await payouts().recover(session, batchSize: 10);

        expect(
          (await RewardPayout.db.findById(session, waitingPayout.id!))!.status,
          RewardPayoutStatus.reserved,
        );
        expect(
          scheduler.scheduled.map((entry) => entry.payoutId),
          contains(waitingPayout.id),
        );
      });

      test(
        'then pools past their refund window close and expire payouts',
        () async {
          final afterRefund = pool.refundAfter.add(const Duration(minutes: 1));

          await payouts(
            clock: () => afterRefund,
          ).recover(sessionBuilder.build(), batchSize: 10);

          final session = sessionBuilder.build();
          final closed = await _poolOf(session, creatorId, 'plant-a-tree');
          expect(closed.status, RewardPoolStatus.closed);
          expect(closed.closedAt, isNotNull);
          final expired = (await RewardPayout.db.findById(
            session,
            payout.id!,
          ))!;
          expect(expired.status, RewardPayoutStatus.expired);
          expect(expired.lastErrorCode, 'refund_window_reached');
        },
      );

      test('then a pool past its expiry is marked ended', () async {
        await payouts(
          clock: () => pool.expiresAt.add(const Duration(minutes: 1)),
        ).recover(sessionBuilder.build(), batchSize: 10);

        final ended = await _poolOf(
          sessionBuilder.build(),
          creatorId,
          'plant-a-tree',
        );
        expect(ended.status, RewardPoolStatus.ended);
        expect(ended.endedAt, isNotNull);
      });

      test('then an out-of-range batch size is refused', () async {
        await expectLater(
          payouts().recover(sessionBuilder.build(), batchSize: 0),
          throwsA(isA<ArgumentError>()),
        );
        await expectLater(
          payouts().recover(sessionBuilder.build(), batchSize: 501),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('when a payout row breaks the pool contract', () {
      late RewardPool pool;
      late UuidValue unpaidAttemptId;
      late RewardPayout payout;

      setUp(() async {
        final action = await fundedAction(maxPayouts: 2);
        final completed = await completedLocationAttempt(
          endpoints,
          first,
          action: action,
          idempotencyKey: 'first-attempt',
        );
        final ready = await readyLocationAttempt(
          endpoints,
          second,
          action: action,
          idempotencyKey: 'second-attempt',
        );
        unpaidAttemptId = ready.id;
        final session = sessionBuilder.build();
        pool = await _poolOf(session, creatorId, 'plant-a-tree');
        payout = (await _payoutFor(session, completed.id))!;
      });

      RewardPayout candidate({required int index, required int amount}) =>
          RewardPayout(
            poolId: pool.id!,
            attemptId: unpaidAttemptId,
            recipientAuthUserId: secondId,
            payoutIndex: index,
            amount: amount,
            status: RewardPayoutStatus.reserved,
          );

      test('then an index past the escrow is rejected', () async {
        final session = sessionBuilder.build();
        await expectLater(
          _inSavepoint(session, (transaction) async {
            await RewardPayout.db.insertRow(
              session,
              candidate(index: pool.maxPayouts, amount: pool.amountPerPayout),
              transaction: transaction,
            );
          }),
          _guardFailure('payout does not fit its reward pool'),
        );
      });

      test('then a different amount is rejected', () async {
        final session = sessionBuilder.build();
        await expectLater(
          _inSavepoint(session, (transaction) async {
            await RewardPayout.db.insertRow(
              session,
              candidate(index: 1, amount: pool.amountPerPayout + 1),
              transaction: transaction,
            );
          }),
          _guardFailure('payout does not fit its reward pool'),
        );
      });

      test('then a released payout cannot be reopened', () async {
        await payouts().release(sessionBuilder.build(), payout.id!);
        final session = sessionBuilder.build();
        final released = (await RewardPayout.db.findById(session, payout.id!))!;

        await expectLater(
          _inSavepoint(session, (transaction) async {
            await RewardPayout.db.updateRow(
              session,
              released.copyWith(status: RewardPayoutStatus.reserved),
              transaction: transaction,
            );
          }),
          _guardFailure('a released payout stays released'),
        );
      });

      test('then a payout identity cannot be moved', () async {
        final session = sessionBuilder.build();
        await expectLater(
          _inSavepoint(session, (transaction) async {
            await RewardPayout.db.updateRow(
              session,
              payout.copyWith(payoutIndex: 1),
              transaction: transaction,
            );
          }),
          _guardFailure('payout identity is immutable'),
        );
      });
    });

    group('when a verification worker accepts rewarded media proof', () {
      test(
        'then the worker completes the attempt and reserves the payout',
        () async {
          final draft = await endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: 'water-on-video',
              requirements: [
                mediaRequirement(
                  kind: ActionRequirementKind.video,
                  spokenChallengeRequired: false,
                ),
              ],
              reward: rewardTerms(),
            ),
          );
          await endpoints.rewards.prepareRewardFunding(
            creator,
            actionId: draft.id,
          );
          await endpoints.rewards.confirmRewardFunding(
            creator,
            actionId: draft.id,
            signature: fakeSignature('fund-video'),
          );
          final action = await endpoints.actionVerification.publishAction(
            creator,
            actionId: draft.id,
            expectedRevision: draft.revision,
          );
          final attempt = await endpoints.actionVerification.beginAttempt(
            first,
            actionId: action.id,
            idempotencyKey: 'video-attempt',
          );
          await uploadMediaProof(
            endpoints,
            first,
            participantId: firstId,
            attemptId: attempt.id,
            requirementId: action.requirements.single.id,
            contentType: 'video/mp4',
            bytes: MediaFixtures.mp4Video(),
            durationSeconds: 8,
          );
          final session = sessionBuilder.build();
          final evidence = (await ActionEvidence.db.findFirstRow(
            session,
            where: (table) => table.attemptId.equals(attempt.id),
          ))!;

          await EvidenceVerificationWorker(
            verifierFactory: (_, _, _) => ScriptedMediaVerifier(),
            actions: ActionVerificationService(payouts: payouts()),
          ).verify(session, evidence.id!);

          final verified = (await ActionAttempt.db.findById(
            session,
            attempt.id,
          ))!;
          expect(verified.status, ActionAttemptStatus.verified);
          expect(verified.rewardOutcome, RewardOutcome.won);
          final payout = (await _payoutFor(session, attempt.id))!;
          expect(payout.status, RewardPayoutStatus.reserved);
          expect(scheduler.scheduled.single.payoutId, payout.id);
        },
      );
    });
  });

  withServerpod('Given a reward above the automatic-release threshold', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x301);
    final participantId = testId(0x302);
    final reviewerId = testId(0x303);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late TestSessionBuilder reviewer;
    late FakeRewardEscrowGateway gateway;

    setUp(() async {
      gateway = FakeRewardEscrowGateway();
      // The default threshold: 25 USDC.
      RewardRuntime.current = fakeRewardConfiguration(gateway);
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      reviewer = signedIn(sessionBuilder, reviewerId, scopes: {_reviewScope});
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        participantId: 'Grace',
        reviewerId: 'Reviewer',
      });
      await linkWallet(endpoints, creator, TestWallet.fromSeed(30));
      await linkWallet(endpoints, participant, TestWallet.fromSeed(31));
    });

    tearDown(() {
      RewardRuntime.current = const RewardConfiguration.disabled();
    });

    Future<ActionOpportunity> rewardedAction(int amountPerPayout) =>
        fundedRewardAction(
          endpoints,
          creator,
          actionKey: 'plant-a-tree',
          reward: rewardTerms(amountPerPayout: amountPerPayout),
        );

    test(
      'when the proof passes automatically then a person must accept it '
      'before the payout is reserved',
      () async {
        final action = await rewardedAction(30000000);

        final held = await completedLocationAttempt(
          endpoints,
          participant,
          action: action,
          idempotencyKey: 'valuable-attempt',
        );

        expect(held.status, ActionAttemptStatus.pendingReview);
        expect(held.rewardValueReview, isTrue);
        expect(held.rejectionCode, 'payout_review');
        expect(held.payoutStatus, isNull);
        final session = sessionBuilder.build();
        expect(await _payoutFor(session, held.id), isNull);
        expect(
          (await _poolOf(session, creatorId, 'plant-a-tree')).payoutsReserved,
          0,
        );

        final queue = await endpoints.evidenceReview.listQueue(
          reviewer,
          limit: 10,
        );
        final item = queue.single;
        expect(item.reviewReasonCode, 'payout_review');
        expect(item.payoutReview!.amountPerPayout, 30000000);
        expect(
          item.payoutReview!.thresholdAtoms,
          defaultRewardReviewThresholdAtoms,
        );
        expect(item.payoutReview!.tokenSymbol, 'USDC');

        final accepted = await endpoints.evidenceReview.review(
          reviewer,
          evidenceId: item.evidenceId,
          decision: EvidenceDecisionStatus.accepted,
          note: 'The check-in is genuine.',
        );

        expect(accepted.status, ActionAttemptStatus.verified);
        expect(accepted.rewardOutcome, RewardOutcome.won);
        expect(accepted.payoutStatus, RewardPayoutStatus.reserved);
        expect(accepted.rewardValueReview, isFalse);
        final payout = (await _payoutFor(session, held.id))!;
        expect(payout.amount, 30000000);
        expect(await _scheduledReleaseCalls(session, payout.id!), 1);
      },
    );

    test(
      'when the reviewer rejects the proof then nothing is reserved',
      () async {
        final action = await rewardedAction(30000000);
        final held = await completedLocationAttempt(
          endpoints,
          participant,
          action: action,
          idempotencyKey: 'valuable-attempt',
        );
        final item = (await endpoints.evidenceReview.listQueue(
          reviewer,
          limit: 10,
        )).single;

        final rejected = await endpoints.evidenceReview.review(
          reviewer,
          evidenceId: item.evidenceId,
          decision: EvidenceDecisionStatus.rejected,
          note: 'The location looks spoofed.',
        );

        expect(rejected.status, ActionAttemptStatus.rejected);
        expect(rejected.rewardOutcome, isNull);
        expect(await _payoutFor(sessionBuilder.build(), held.id), isNull);
        expect(gateway.releaseCalls, isEmpty);
      },
    );

    test(
      'when the payout equals the threshold then it is reserved without a '
      'person',
      () async {
        final action = await rewardedAction(25000000);

        final completed = await completedLocationAttempt(
          endpoints,
          participant,
          action: action,
          idempotencyKey: 'threshold-attempt',
        );

        expect(completed.status, ActionAttemptStatus.verified);
        expect(completed.payoutStatus, RewardPayoutStatus.reserved);
      },
    );

    test(
      'when the threshold is zero then every payout needs a person',
      () async {
        RewardRuntime.current = fakeRewardConfiguration(
          gateway,
          reviewThresholdAtoms: 0,
        );
        final action = await rewardedAction(1);

        final held = await completedLocationAttempt(
          endpoints,
          participant,
          action: action,
          idempotencyKey: 'tiny-attempt',
        );

        expect(held.status, ActionAttemptStatus.pendingReview);
        expect(held.rewardValueReview, isTrue);
      },
    );
  });

  withServerpod(
    'Given more participants than payouts racing to complete',
    (sessionBuilder, endpoints) {
      final creatorId = testId(0x401);
      final participantIds = [for (var i = 0; i < 5; i++) testId(0x410 + i)];
      late FakeRewardEscrowGateway gateway;
      late RewardConfiguration configuration;

      setUpAll(() async {
        gateway = FakeRewardEscrowGateway();
        configuration = fakeRewardConfiguration(gateway);
        RewardRuntime.current = configuration;
        await insertAccounts(sessionBuilder.build(), {
          creatorId: 'Ada',
          for (final (index, id) in participantIds.indexed) id: 'Runner $index',
        });
        await linkWallet(
          endpoints,
          signedIn(sessionBuilder, creatorId),
          TestWallet.fromSeed(40),
        );
      });

      tearDownAll(() {
        RewardRuntime.current = const RewardConfiguration.disabled();
      });

      test(
        'when every completion runs at once then no payout index is '
        'reserved twice and the pool is never over-reserved',
        () async {
          final creator = signedIn(sessionBuilder, creatorId);
          final action = await fundedRewardAction(
            endpoints,
            creator,
            actionKey: 'race-to-plant',
            reward: rewardTerms(maxPayouts: 2),
          );
          final ready = <(TestSessionBuilder, ActionAttemptView)>[];
          for (final (index, id) in participantIds.indexed) {
            final participant = signedIn(sessionBuilder, id);
            ready.add((
              participant,
              await readyLocationAttempt(
                endpoints,
                participant,
                action: action,
                idempotencyKey: 'race-$index',
              ),
            ));
          }

          final completed = await Future.wait([
            for (final (participant, attempt) in ready)
              endpoints.actionVerification.completeAttempt(
                participant,
                attempt.id,
              ),
          ]);

          expect(
            completed.every(
              (attempt) => attempt.status == ActionAttemptStatus.verified,
            ),
            isTrue,
          );
          expect(
            completed.where((a) => a.rewardOutcome == RewardOutcome.won),
            hasLength(2),
          );
          expect(
            completed.where((a) => a.rewardOutcome == RewardOutcome.poolEmpty),
            hasLength(3),
          );
          final session = sessionBuilder.build();
          final pool = await _poolOf(session, creatorId, 'race-to-plant');
          expect(pool.payoutsReserved, 2);
          final payouts = await RewardPayout.db.find(
            session,
            where: (table) => table.poolId.equals(pool.id),
          );
          expect(payouts.map((payout) => payout.payoutIndex).toSet(), {0, 1});
          expect(
            completed.map((attempt) => attempt.verifiedRank).toSet(),
            {1, 2, 3, 4, 5},
          );
        },
      );

      test(
        'when one attempt is completed twice at once then it holds one payout',
        () async {
          final creator = signedIn(sessionBuilder, creatorId);
          final action = await fundedRewardAction(
            endpoints,
            creator,
            actionKey: 'double-tap',
            reward: rewardTerms(),
          );
          final participant = signedIn(sessionBuilder, participantIds.first);
          final attempt = await readyLocationAttempt(
            endpoints,
            participant,
            action: action,
            idempotencyKey: 'double-tap',
          );

          final results = await Future.wait([
            endpoints.actionVerification.completeAttempt(
              participant,
              attempt.id,
            ),
            endpoints.actionVerification.completeAttempt(
              participant,
              attempt.id,
            ),
          ]);

          expect(
            results.map((result) => result.status).toSet(),
            {ActionAttemptStatus.verified},
          );
          final session = sessionBuilder.build();
          final pool = await _poolOf(session, creatorId, 'double-tap');
          expect(pool.payoutsReserved, 1);
          final payouts = await RewardPayout.db.find(
            session,
            where: (table) => table.poolId.equals(pool.id),
          );
          expect(payouts, hasLength(1));
          expect(payouts.single.status, RewardPayoutStatus.awaitingWallet);
          await linkWallet(endpoints, participant, TestWallet.fromSeed(41));

          // Two release jobs racing for the same payout pay it once.
          final service = RewardPayoutService(
            configuration: configuration,
            scheduler: RecordingRewardPayoutScheduler(),
          );
          final before = gateway.releaseCalls.length;
          await Future.wait([
            service.release(sessionBuilder.build(), payouts.single.id!),
            service.release(sessionBuilder.build(), payouts.single.id!),
          ]);
          expect(gateway.releaseCalls.length - before, 1);
          expect(
            (await RewardPayout.db.findById(
              session,
              payouts.single.id!,
            ))!.status,
            RewardPayoutStatus.released,
          );
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}

/// A device that meets basic but not strong integrity, recording which bar
/// each proof was held to.
final class _StrongIntegrityProbe implements DeviceIntegrityVerifier {
  final List<bool> strongRequired = [];

  @override
  String get providerName => 'test-device-integrity';

  @override
  Future<DeviceIntegrityVerdict> verify(
    Session session, {
    required String token,
    required String requestHash,
    required DateTime now,
    required bool requireStrongIntegrity,
  }) async {
    strongRequired.add(requireStrongIntegrity);
    return DeviceIntegrityVerdict(
      trusted: !requireStrongIntegrity,
      reasonCode: requireStrongIntegrity
          ? 'device_integrity_not_strong'
          : 'device_integrity_met',
      provider: providerName,
    );
  }
}
