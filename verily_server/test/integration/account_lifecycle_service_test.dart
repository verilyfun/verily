import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_auth_idp_server/providers/google.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/account/account_lifecycle_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

void main() {
  withServerpod('Given a signed-in account that creates and takes part', (
    sessionBuilder,
    endpoints,
  ) {
    final accountId = testId(0x601);
    final otherCreatorId = testId(0x602);
    final closedAt = DateTime.utc(2026, 8, 23, 18);
    late List<UuidValue> revoked;
    late AccountLifecycleService service;

    setUp(() async {
      revoked = [];
      service = AccountLifecycleService(
        clock: () => closedAt,
        revokeTokens: (session, userId) async => revoked.add(userId),
      );
      final session = sessionBuilder.build();
      await AuthUser.db.insert(session, [
        AuthUser(id: accountId, scopeNames: const {'evidence.review'}),
        AuthUser(id: otherCreatorId, scopeNames: const {}),
      ]);
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: accountId,
          email: 'creator@example.com',
          passwordHash: 'not-a-real-password-hash',
        ),
      );
      await GoogleAccount.db.insertRow(
        session,
        GoogleAccount(
          authUserId: accountId,
          userIdentifier: 'google-subject',
          email: 'creator@example.com',
        ),
      );
      await UserProfile.db.insert(session, [
        UserProfile(
          authUserId: accountId,
          userName: 'creator',
          fullName: 'Verily Creator',
          email: 'creator@example.com',
        ),
        UserProfile(authUserId: otherCreatorId, userName: 'Bea'),
      ]);
    });

    test(
      'when the account closes then identity is purged, sign-in is blocked, '
      'closure is recorded, and tokens are revoked',
      () async {
        final session = sessionBuilder.build();

        final result = await service.closeAccount(
          session,
          authUserId: accountId,
          confirmation: accountClosureConfirmation,
        );

        expect(result, closedAt);
        expect(revoked, [accountId]);
        final account = await AuthUser.db.findById(session, accountId);
        expect(account!.blocked, isTrue);
        expect(account.scopeNames, isEmpty);
        expect(await EmailAccount.db.count(session), 0);
        expect(await GoogleAccount.db.count(session), 0);
        expect(
          await UserProfile.db.count(
            session,
            where: (table) => table.authUserId.equals(accountId),
          ),
          0,
        );
        final closure = await AccountClosure.db.findFirstRow(
          session,
          where: (table) => table.authUserId.equals(accountId),
        );
        expect(closure!.status, AccountClosureStatus.closed);
        expect(closure.identityPurgedAt, closedAt);
        // Another account's profile is untouched.
        expect(await UserProfile.db.count(session), 1);
      },
    );

    test(
      'when the account closes then its payout wallet and link challenges '
      'are removed',
      () async {
        final session = sessionBuilder.build();
        final wallet = TestWallet.fromSeed(7);
        final now = DateTime.utc(2026, 8, 23, 17);
        await PayoutWallet.db.insertRow(
          session,
          PayoutWallet(
            authUserId: accountId,
            walletAddress: wallet.address,
            linkedAt: now,
            updatedAt: now,
          ),
        );
        await PayoutWalletLinkChallenge.db.insertRow(
          session,
          PayoutWalletLinkChallenge(
            authUserId: accountId,
            walletAddress: wallet.address,
            nonce: 'closure-test-nonce-0001',
            message: 'Link this wallet to Verily.',
            createdAt: now,
            expiresAt: now.add(const Duration(minutes: 10)),
          ),
        );

        await service.closeAccount(
          session,
          authUserId: accountId,
          confirmation: accountClosureConfirmation,
        );

        expect(await PayoutWallet.db.count(session), 0);
        expect(await PayoutWalletLinkChallenge.db.count(session), 0);
      },
    );

    test(
      'when a creator closes then their live actions pause and their '
      'history stays',
      () async {
        final creator = signedIn(sessionBuilder, accountId);
        final participantId = testId(0x603);
        await insertAccounts(sessionBuilder.build(), {participantId: 'Grace'});
        final participant = signedIn(sessionBuilder, participantId);
        final live = await endpoints.actionVerification.createAction(
          creator,
          actionRequest(
            actionKey: 'closing-creator-live',
            requirements: [locationRequirement()],
          ),
        );
        final draft = await endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(
            actionKey: 'closing-creator-draft',
            requirements: [locationRequirement()],
          ),
        );
        final others = await endpoints.actionVerification.createAction(
          signedIn(sessionBuilder, otherCreatorId),
          actionRequest(
            actionKey: 'someone-elses-action',
            requirements: [locationRequirement()],
          ),
        );
        final attempt = await endpoints.actionVerification.beginAttempt(
          participant,
          actionId: live.id,
          idempotencyKey: 'before-closure',
        );
        final session = sessionBuilder.build();

        await service.closeAccount(
          session,
          authUserId: accountId,
          confirmation: accountClosureConfirmation,
        );

        final stored = {
          for (final action in await ActionDefinition.db.find(session))
            action.id!: action,
        };
        expect(stored[live.id]!.status, ActionDefinitionStatus.paused);
        expect(stored[live.id]!.pausedAt, closedAt);
        expect(stored[draft.id]!.status, ActionDefinitionStatus.draft);
        expect(stored[others.id]!.status, ActionDefinitionStatus.active);
        expect(
          (await endpoints.actionVerification.listAvailableActions(
            participant,
            limit: 10,
          )).map((action) => action.id),
          [others.id],
        );
        await expectLater(
          endpoints.actionVerification.beginAttempt(
            participant,
            actionId: live.id,
            idempotencyKey: 'after-closure',
          ),
          throwsStateError,
        );
        // The participant's history with the closed creator's action stays.
        expect(await ActionAttempt.db.findById(session, attempt.id), isNotNull);
      },
    );

    test(
      'when a participant closes then they can no longer submit or finish '
      'proof',
      () async {
        final creator = signedIn(sessionBuilder, otherCreatorId);
        final participant = signedIn(sessionBuilder, accountId);
        final action = await endpoints.actionVerification.createAction(
          creator,
          actionRequest(
            actionKey: 'closing-participant',
            requirements: [locationRequirement()],
          ),
        );
        final attempt = await endpoints.actionVerification.beginAttempt(
          participant,
          actionId: action.id,
          idempotencyKey: 'closing-participant',
        );
        final checkIn = ActionEvidenceInput(
          attemptId: attempt.id,
          requirementId: action.requirements.single.id,
          capturedAt: DateTime.now().toUtc(),
          latitude: 51.5007,
          longitude: -0.1246,
          accuracyMeters: 10,
        );
        await endpoints.actionVerification.submitEvidence(participant, checkIn);

        await service.closeAccount(
          sessionBuilder.build(),
          authUserId: accountId,
          confirmation: accountClosureConfirmation,
        );

        await expectLater(
          endpoints.actionVerification.submitEvidence(participant, checkIn),
          throwsStateError,
        );
        await expectLater(
          endpoints.actionVerification.completeAttempt(participant, attempt.id),
          throwsStateError,
        );
        await expectLater(
          endpoints.actionVerification.beginAttempt(
            participant,
            actionId: action.id,
            idempotencyKey: 'after-closure',
          ),
          throwsStateError,
        );
        final stored = await ActionAttempt.db.findById(
          sessionBuilder.build(),
          attempt.id,
        );
        expect(stored!.status, ActionAttemptStatus.collectingEvidence);
        expect(stored.verifiedAt, isNull);
      },
    );

    test('when closure is repeated then the first receipt stands', () async {
      final session = sessionBuilder.build();
      await service.closeAccount(
        session,
        authUserId: accountId,
        confirmation: accountClosureConfirmation,
      );
      final later = AccountLifecycleService(
        clock: () => closedAt.add(const Duration(days: 1)),
        revokeTokens: (session, userId) async => revoked.add(userId),
      );

      final result = await later.closeAccount(
        session,
        authUserId: accountId,
        confirmation: ' $accountClosureConfirmation ',
      );

      expect(result, closedAt);
      expect(await AccountClosure.db.count(session), 1);
      // Revocation is retried so a token minted mid-closure still dies.
      expect(revoked, [accountId, accountId]);
    });

    test(
      'when the confirmation phrase is wrong then nothing changes',
      () async {
        final session = sessionBuilder.build();

        for (final confirmation in ['delete', 'DELETE ME', '']) {
          await expectLater(
            service.closeAccount(
              session,
              authUserId: accountId,
              confirmation: confirmation,
            ),
            throwsArgumentError,
          );
        }
        await expectLater(
          endpoints.accountLifecycle.closeAccount(
            signedIn(sessionBuilder, accountId),
            confirmation: 'delete',
          ),
          throwsArgumentError,
        );

        final account = await AuthUser.db.findById(session, accountId);
        expect(account!.blocked, isFalse);
        expect(await EmailAccount.db.count(session), 1);
        expect(await AccountClosure.db.count(session), 0);
        expect(revoked, isEmpty);
      },
    );

    test('when the account does not exist then closure is refused', () async {
      await expectLater(
        service.closeAccount(
          sessionBuilder.build(),
          authUserId: testId(0x6ff),
          confirmation: accountClosureConfirmation,
        ),
        throwsStateError,
      );
      expect(revoked, isEmpty);
    });

    test('when signed out then the endpoint requires sign-in', () async {
      await expectLater(
        endpoints.accountLifecycle.closeAccount(
          sessionBuilder,
          confirmation: accountClosureConfirmation,
        ),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });
  });
}
