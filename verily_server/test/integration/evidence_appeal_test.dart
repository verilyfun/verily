import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/evidence_verification_worker.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/evidence_storage/evidence_upload_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _reason = 'The whole movement is visible from start to finish.';

void main() {
  withServerpod('Given proof a verifier rejected', (sessionBuilder, endpoints) {
    final creatorId = testId(501);
    final participantId = testId(502);
    final otherId = testId(503);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late TestSessionBuilder other;
    late ActionOpportunity action;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      other = signedIn(sessionBuilder, otherId);
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {
        creatorId: 'Ada',
        participantId: 'Grace',
        otherId: 'Linus',
      });
      action = await publishedAction(
        endpoints,
        creator,
        actionRequest(
          actionKey: 'appealable-video',
          title: 'Ten squats',
          requirements: [
            mediaRequirement(
              kind: ActionRequirementKind.video,
              spokenChallengeRequired: false,
            ),
          ],
        ),
      );
    });

    /// Uploads a video as [as] and has the verifier decide it with
    /// [verdict]. Returns the attempt id.
    Future<UuidValue> decidedProof({
      TestSessionBuilder? as,
      UuidValue? asId,
      MediaEvidenceModelVerdict verdict =
          MediaEvidenceModelVerdict.notFulfilled,
    }) async {
      final session = as ?? participant;
      final accountId = asId ?? participantId;
      final attempt = await endpoints.actionVerification.beginAttempt(
        session,
        actionId: action.id,
        idempotencyKey: 'appeal-$accountId',
      );
      await uploadMediaProof(
        endpoints,
        session,
        participantId: accountId,
        attemptId: attempt.id,
        requirementId: action.requirements.single.id,
        contentType: 'video/mp4',
        bytes: MediaFixtures.mp4Video(),
        durationSeconds: 8,
      );
      final evidence = await ActionEvidence.db.findFirstRow(
        sessionBuilder.build(),
        where: (table) => table.attemptId.equals(attempt.id),
      );
      await EvidenceVerificationWorker(
        verifierFactory: (_, _, _) => ScriptedMediaVerifier(verdict: verdict),
      ).verify(sessionBuilder.build(), evidence!.id!);
      return attempt.id;
    }

    Future<ActionAttempt> storedAttempt(UuidValue attemptId) async =>
        (await ActionAttempt.db.findById(sessionBuilder.build(), attemptId))!;

    group('when the participant appeals', () {
      test(
        'then one idempotent appeal is filed with the action creator',
        () async {
          final attemptId = await decidedProof();
          expect(
            (await storedAttempt(attemptId)).status,
            ActionAttemptStatus.rejected,
          );

          final first = await endpoints.evidenceAppeal.submit(
            participant,
            attemptId: attemptId,
            reason: '  $_reason  ',
          );
          final again = await endpoints.evidenceAppeal.submit(
            participant,
            attemptId: attemptId,
            reason: _reason,
          );

          expect(again.id, first.id);
          expect(first.status, EvidenceAppealStatus.pending);
          expect(first.reason, _reason);
          expect(first.actionTitle, 'Ten squats');
          expect(first.requirementKind, ActionRequirementKind.video);
          // Playback links are for the creator resolving the appeal only.
          expect(first.mediaUrl, isNull);
          final row = await EvidenceAppeal.db.findById(
            sessionBuilder.build(),
            first.id,
          );
          expect(row!.creatorAuthUserId, creatorId);
          expect(row.participantAuthUserId, participantId);
          final mine = await endpoints.evidenceAppeal.getMine(
            participant,
            attemptId: attemptId,
          );
          expect(mine!.id, first.id);
          expect(
            await endpoints.evidenceAppeal.getMine(other, attemptId: attemptId),
            isNull,
          );
        },
      );

      test('then a reason that is too short is refused', () async {
        final attemptId = await decidedProof();

        await expectLater(
          endpoints.evidenceAppeal.submit(
            participant,
            attemptId: attemptId,
            reason: 'unfair',
          ),
          throwsArgumentError,
        );
      });

      test('then verified proof cannot be appealed', () async {
        final attemptId = await decidedProof(
          verdict: MediaEvidenceModelVerdict.fulfilled,
        );

        await expectLater(
          endpoints.evidenceAppeal.submit(
            participant,
            attemptId: attemptId,
            reason: _reason,
          ),
          throwsStateError,
        );
      });

      test('then another account cannot appeal the attempt', () async {
        final attemptId = await decidedProof();

        await expectLater(
          endpoints.evidenceAppeal.submit(
            other,
            attemptId: attemptId,
            reason: _reason,
          ),
          throwsStateError,
        );
      });

      test('then the appeal cannot start after the seven-day window', () async {
        final attemptId = await decidedProof();
        final session = sessionBuilder.build();
        final evidence = await ActionEvidence.db.findFirstRow(
          session,
          where: (table) => table.attemptId.equals(attemptId),
        );
        final old = DateTime.now().toUtc().subtract(const Duration(days: 8));
        await ActionEvidence.db.updateRow(
          session,
          evidence!.copyWith(capturedAt: old, submittedAt: old),
        );

        await expectLater(
          endpoints.evidenceAppeal.submit(
            participant,
            attemptId: attemptId,
            reason: _reason,
          ),
          throwsStateError,
        );
      });

      test('then a closed account cannot appeal', () async {
        final attemptId = await decidedProof();
        final session = sessionBuilder.build();
        final account = await AuthUser.db.findById(session, participantId);
        await AuthUser.db.updateRow(session, account!.copyWith(blocked: true));

        await expectLater(
          endpoints.evidenceAppeal.submit(
            participant,
            attemptId: attemptId,
            reason: _reason,
          ),
          throwsStateError,
        );
      });
    });

    group('when the creator handles the appeal', () {
      Future<EvidenceAppealView> filed() async {
        final attemptId = await decidedProof();
        return endpoints.evidenceAppeal.submit(
          participant,
          attemptId: attemptId,
          reason: _reason,
        );
      }

      test('then only the creator lists it, with the private media', () async {
        final appeal = await filed();

        final owned = await endpoints.evidenceAppeal.listOwned(
          creator,
          limit: 50,
        );

        expect(owned.single.id, appeal.id);
        expect(owned.single.mediaUrl, isNotNull);
        expect(
          await endpoints.evidenceAppeal.listOwned(other, limit: 50),
          isEmpty,
        );
        expect(
          await endpoints.evidenceAppeal.listOwned(participant, limit: 50),
          isEmpty,
        );
      });

      test(
        'then accepting appends a decision and verifies the attempt',
        () async {
          final appeal = await filed();

          final resolved = await endpoints.evidenceAppeal.resolve(
            creator,
            appealId: appeal.id,
            decision: EvidenceAppealStatus.accepted,
            note: 'The squats are clear on a second look.',
          );

          expect(resolved.status, EvidenceAppealStatus.accepted);
          expect(resolved.resolvedAt, isNotNull);
          final attempt = await storedAttempt(appeal.attemptId);
          expect(attempt.status, ActionAttemptStatus.verified);
          expect(attempt.verifiedRank, 1);
          final decisions = await EvidenceDecision.db.find(
            sessionBuilder.build(),
            where: (table) => table.evidenceId.equals(appeal.evidenceId),
            orderBy: (table) => table.createdAt,
          );
          expect(decisions.map((row) => row.status), [
            EvidenceDecisionStatus.rejected,
            EvidenceDecisionStatus.accepted,
          ]);
          expect(decisions.last.verifierType, 'appeal-review');
          expect(decisions.last.reviewedByAuthUserId, creatorId);
          expect(
            await endpoints.evidenceAppeal.listOwned(creator, limit: 50),
            isEmpty,
          );

          await expectLater(
            endpoints.evidenceAppeal.resolve(
              creator,
              appealId: appeal.id,
              decision: EvidenceAppealStatus.rejected,
              note: 'Changing my mind.',
            ),
            throwsStateError,
          );
        },
      );

      test('then rejecting keeps the attempt rejected', () async {
        final appeal = await filed();

        final resolved = await endpoints.evidenceAppeal.resolve(
          creator,
          appealId: appeal.id,
          decision: EvidenceAppealStatus.rejected,
          note: 'The movement is incomplete.',
        );

        expect(resolved.status, EvidenceAppealStatus.rejected);
        expect(resolved.resolutionNote, 'The movement is incomplete.');
        expect(
          (await storedAttempt(appeal.attemptId)).status,
          ActionAttemptStatus.rejected,
        );
        expect(
          await EvidenceDecision.db.count(
            sessionBuilder.build(),
            where: (table) => table.evidenceId.equals(appeal.evidenceId),
          ),
          1,
        );
      });

      test('then a pending decision or empty note is refused', () async {
        final appeal = await filed();

        await expectLater(
          endpoints.evidenceAppeal.resolve(
            creator,
            appealId: appeal.id,
            decision: EvidenceAppealStatus.pending,
            note: 'Still thinking.',
          ),
          throwsArgumentError,
        );
        await expectLater(
          endpoints.evidenceAppeal.resolve(
            creator,
            appealId: appeal.id,
            decision: EvidenceAppealStatus.accepted,
            note: ' ',
          ),
          throwsArgumentError,
        );
      });

      test('then another account cannot resolve it', () async {
        final appeal = await filed();

        await expectLater(
          endpoints.evidenceAppeal.resolve(
            other,
            appealId: appeal.id,
            decision: EvidenceAppealStatus.accepted,
            note: 'I am not the creator.',
          ),
          throwsStateError,
        );
        await expectLater(
          endpoints.evidenceAppeal.resolve(
            participant,
            appealId: appeal.id,
            decision: EvidenceAppealStatus.accepted,
            note: 'Approving my own appeal.',
          ),
          throwsStateError,
        );
      });

      test(
        'then the participant closing their account blocks an accepted appeal',
        () async {
          final appeal = await filed();
          final session = sessionBuilder.build();
          final account = await AuthUser.db.findById(session, participantId);
          await AuthUser.db.updateRow(
            session,
            account!.copyWith(blocked: true),
          );

          await expectLater(
            endpoints.evidenceAppeal.resolve(
              creator,
              appealId: appeal.id,
              decision: EvidenceAppealStatus.accepted,
              note: 'The proof is fine.',
            ),
            throwsStateError,
          );
          final row = await EvidenceAppeal.db.findById(
            sessionBuilder.build(),
            appeal.id,
          );
          expect(row!.status, EvidenceAppealStatus.pending);
        },
      );

      test(
        'then a pending appeal keeps the recording past its normal retention',
        () async {
          final appeal = await filed();
          final session = sessionBuilder.build();
          final reservation = await EvidenceUploadReservation.db.findFirstRow(
            session,
            where: (table) => table.attemptId.equals(appeal.attemptId),
          );
          final past = DateTime.now().toUtc().subtract(
            const Duration(days: 1),
          );
          await EvidenceUploadReservation.db.updateRow(
            session,
            reservation!.copyWith(
              reservedAt: past.subtract(const Duration(days: 1)),
              lastSignedAt: past.subtract(const Duration(days: 1)),
              uploadExpiresAt: past.subtract(const Duration(hours: 1)),
              retainUntil: past,
            ),
          );

          expect(await EvidenceUploadService().cleanupExpired(session), 0);
          expect(
            await EvidenceUploadReservation.db.count(session),
            1,
          );

          await endpoints.evidenceAppeal.resolve(
            creator,
            appealId: appeal.id,
            decision: EvidenceAppealStatus.rejected,
            note: 'The movement is incomplete.',
          );
          expect(
            await EvidenceUploadService().cleanupExpired(
              sessionBuilder.build(),
            ),
            1,
          );
        },
      );
    });

    test(
      'when the creator appealed their own proof then they cannot resolve it',
      () async {
        final attemptId = await decidedProof(as: creator, asId: creatorId);
        final appeal = await endpoints.evidenceAppeal.submit(
          creator,
          attemptId: attemptId,
          reason: _reason,
        );

        await expectLater(
          endpoints.evidenceAppeal.resolve(
            creator,
            appealId: appeal.id,
            decision: EvidenceAppealStatus.accepted,
            note: 'Approving my own proof.',
          ),
          throwsStateError,
        );
      },
    );
  });
}
