import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/evidence_verification_worker.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/action_verification/spoken_challenge_words.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

void main() {
  withServerpod('Given a video action that asks for a live challenge word', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(201);
    final participantId = testId(202);
    final otherId = testId(203);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late ActionOpportunity action;
    late UuidValue requirementId;
    late ActionAttemptView attempt;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {
        creatorId: 'Ada',
        participantId: 'Grace',
        otherId: 'Linus',
      });
      // A null opt-out keeps the default: video asks for a word.
      action = await publishedAction(
        endpoints,
        creator,
        actionRequest(
          actionKey: 'say-the-word',
          requirements: [mediaRequirement(kind: ActionRequirementKind.video)],
        ),
      );
      requirementId = action.requirements.single.id;
      attempt = await endpoints.actionVerification.beginAttempt(
        participant,
        actionId: action.id,
        idempotencyKey: 'spoken-attempt',
      );
    });

    Future<ActionSpokenChallengeView> issue({TestSessionBuilder? as}) =>
        endpoints.actionVerification.issueSpokenChallenge(
          as ?? participant,
          attemptId: attempt.id,
          requirementId: requirementId,
        );

    Future<EvidenceSubmissionResult> upload({DateTime? capturedAt}) =>
        uploadMediaProof(
          endpoints,
          participant,
          participantId: participantId,
          attemptId: attempt.id,
          requirementId: requirementId,
          contentType: 'video/mp4',
          bytes: MediaFixtures.mp4Video(),
          durationSeconds: 8,
          capturedAt: capturedAt,
        );

    Future<ActionEvidence> evidence() async =>
        (await ActionEvidence.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) => table.attemptId.equals(attempt.id),
        ))!;

    Future<ActionAttempt> storedAttempt() async =>
        (await ActionAttempt.db.findById(sessionBuilder.build(), attempt.id))!;

    test('then the requirement tells the app to fetch a word', () async {
      expect(action.requirements.single.spokenChallengeRequired, isTrue);
    });

    group('when the participant asks for a word before recording', () {
      test(
        'then a server-listed word valid for fifteen minutes is issued',
        () async {
          final challenge = await issue();

          expect(spokenChallengeWords, contains(challenge.word));
          final row = await ActionSpokenChallenge.db.findById(
            sessionBuilder.build(),
            challenge.id,
          );
          expect(row!.participantAuthUserId, participantId);
          expect(row.boundAt, isNull);
          expect(
            row.expiresAt.difference(row.issuedAt),
            spokenChallengeLifetime,
          );
          expect(challenge.expiresAt, row.expiresAt);
        },
      );

      test('then asking again returns the same unbound word', () async {
        final first = await issue();
        final second = await issue();

        expect(second.id, first.id);
        expect(second.word, first.word);
        expect(
          await ActionSpokenChallenge.db.count(sessionBuilder.build()),
          1,
        );
      });

      test('then another account cannot get a word for the attempt', () async {
        await expectLater(
          issue(as: signedIn(sessionBuilder, otherId)),
          throwsStateError,
        );
      });
    });

    test(
      'when an upload is requested without a word then it is refused',
      () async {
        await expectLater(
          endpoints.actionVerification.requestMediaUpload(
            participant,
            attemptId: attempt.id,
            requirementId: requirementId,
            contentType: 'video/mp4',
            byteLength: MediaFixtures.mp4Video().length,
          ),
          throwsStateError,
        );
        expect(
          await EvidenceUploadReservation.db.count(sessionBuilder.build()),
          0,
        );
      },
    );

    test(
      'when the upload is reserved then the word is bound once and returned '
      'afterwards',
      () async {
        final challenge = await issue();
        final byteLength = MediaFixtures.mp4Video().length;

        await endpoints.actionVerification.requestMediaUpload(
          participant,
          attemptId: attempt.id,
          requirementId: requirementId,
          contentType: 'video/mp4',
          byteLength: byteLength,
        );

        final session = sessionBuilder.build();
        final bound = await ActionSpokenChallenge.db.findById(
          session,
          challenge.id,
        );
        expect(bound!.boundAt, isNotNull);
        final reservation = await EvidenceUploadReservation.db.findFirstRow(
          session,
          where: (table) => table.attemptId.equals(attempt.id),
        );
        expect(reservation!.spokenChallengeId, challenge.id);

        final again = await issue();
        expect(again.id, challenge.id);
        expect(again.word, challenge.word);

        // A renewed upload URL keeps the original binding.
        await endpoints.actionVerification.requestMediaUpload(
          participant,
          attemptId: attempt.id,
          requirementId: requirementId,
          contentType: 'video/mp4',
          byteLength: byteLength,
        );
        final renewed = await ActionSpokenChallenge.db.findById(
          session,
          challenge.id,
        );
        expect(renewed!.boundAt, bound.boundAt);
        expect(await ActionSpokenChallenge.db.count(session), 1);
      },
    );

    test(
      'when the word expired before the upload then the upload is refused '
      'and a fresh word is issued',
      () async {
        final challenge = await issue();
        final session = sessionBuilder.build();
        final row = await ActionSpokenChallenge.db.findById(
          session,
          challenge.id,
        );
        final past = DateTime.now().toUtc().subtract(
          const Duration(minutes: 30),
        );
        await ActionSpokenChallenge.db.updateRow(
          session,
          row!.copyWith(
            issuedAt: past,
            expiresAt: past.add(spokenChallengeLifetime),
          ),
        );

        await expectLater(
          endpoints.actionVerification.requestMediaUpload(
            participant,
            attemptId: attempt.id,
            requirementId: requirementId,
            contentType: 'video/mp4',
            byteLength: MediaFixtures.mp4Video().length,
          ),
          throwsStateError,
        );
        final fresh = await issue();
        expect(fresh.id, isNot(challenge.id));
      },
    );

    test(
      'when every word for the proof was used then no more are issued',
      () async {
        final session = sessionBuilder.build();
        final past = DateTime.now().toUtc().subtract(const Duration(hours: 2));
        await ActionSpokenChallenge.db.insert(session, [
          for (var index = 0; index < maxSpokenChallengesPerProof; index += 1)
            ActionSpokenChallenge(
              attemptId: attempt.id,
              requirementId: requirementId,
              participantAuthUserId: participantId,
              word: spokenChallengeWords[index],
              issuedAt: past.add(Duration(minutes: index)),
              expiresAt: past.add(Duration(minutes: index + 15)),
            ),
        ]);

        await expectLater(issue(), throwsStateError);
      },
    );

    group('when the recording is uploaded with its word', () {
      test(
        'then the evidence keeps the word and the verifier is asked for it',
        () async {
          final challenge = await issue();
          final result = await upload();
          expect(result.status, isNull);
          final stored = await evidence();
          expect(stored.spokenChallengeId, challenge.id);
          expect(stored.spokenChallengeWord, challenge.word);
          final verifier = ScriptedMediaVerifier();

          await EvidenceVerificationWorker(
            verifierFactory: (_, _, _) => verifier,
          ).verify(sessionBuilder.build(), stored.id!);

          expect(verifier.requests.single.spokenChallengeWord, challenge.word);
          expect((await storedAttempt()).status, ActionAttemptStatus.verified);
          final vote = await EvidenceVerificationVote.db.findFirstRow(
            sessionBuilder.build(),
            where: (table) => table.evidenceId.equals(stored.id),
          );
          expect(vote!.spokenChallengeVerdict, 'heard');
        },
      );

      test('then a word the verifier did not hear rejects the proof', () async {
        await issue();
        await upload();
        final stored = await evidence();

        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => ScriptedMediaVerifier(
            spokenChallengeVerdict: SpokenChallengeVerdict.notHeard,
          ),
        ).verify(sessionBuilder.build(), stored.id!);

        final rejected = await storedAttempt();
        expect(rejected.status, ActionAttemptStatus.rejected);
        expect(rejected.rejectionCode, MediaVerificationReason.spokenNotHeard);
      });

      test(
        'then a model that cannot hear sends the proof to a person',
        () async {
          await issue();
          await upload();
          final stored = await evidence();

          await EvidenceVerificationWorker(
            verifierFactory: (_, _, _) => ScriptedMediaVerifier(
              spokenChallengeVerdict: SpokenChallengeVerdict.abstained,
            ),
          ).verify(sessionBuilder.build(), stored.id!);

          expect(
            (await storedAttempt()).status,
            ActionAttemptStatus.pendingReview,
          );
          final decision = await EvidenceDecision.db.findFirstRow(
            sessionBuilder.build(),
            where: (table) => table.evidenceId.equals(stored.id),
          );
          expect(
            decision!.reasonCode,
            MediaVerificationReason.spokenUnverified,
          );
        },
      );

      test(
        'then a recording that started before the word was issued is '
        'rejected without a model',
        () async {
          await issue();

          final result = await upload(
            capturedAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 10),
            ),
          );

          expect(result.status, EvidenceDecisionStatus.rejected);
          expect(result.reasonCode, 'spoken_challenge_predates_capture');
          final stored = await evidence();
          expect(
            await EvidenceVerificationJob.db.count(
              sessionBuilder.build(),
              where: (table) => table.evidenceId.equals(stored.id),
            ),
            0,
          );
        },
      );
    });

    test(
      'when expired words are cleaned up then bound words stay with their '
      'evidence',
      () async {
        final challenge = await issue();
        await upload();
        final session = sessionBuilder.build();
        final old = DateTime.now().toUtc().subtract(const Duration(days: 9));
        final unbound = await ActionSpokenChallenge.db.insertRow(
          session,
          ActionSpokenChallenge(
            attemptId: attempt.id,
            requirementId: requirementId,
            participantAuthUserId: participantId,
            word: 'pelican',
            issuedAt: old,
            expiresAt: old.add(spokenChallengeLifetime),
          ),
        );
        final bound = await ActionSpokenChallenge.db.findById(
          session,
          challenge.id,
        );
        await ActionSpokenChallenge.db.updateRow(
          session,
          bound!.copyWith(
            issuedAt: old,
            expiresAt: old.add(spokenChallengeLifetime),
            boundAt: old,
          ),
        );

        await endpoints.futureCalls.actionSpokenChallengeCleanup.cleanup(
          sessionBuilder,
          ActionSpokenChallengeCleanupTask(batchSize: 100),
        );

        final remaining = await ActionSpokenChallenge.db.find(
          sessionBuilder.build(),
        );
        expect(remaining.map((row) => row.id), [challenge.id]);
        expect(remaining.single.id, isNot(unbound.id));
        expect((await evidence()).spokenChallengeWord, challenge.word);
      },
    );
  });

  withServerpod('Given proof that does not use a challenge word', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(211);
    final participantId = testId(212);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {creatorId: 'Ada', participantId: 'Grace'});
    });

    test(
      'when a video requirement opts out then it records without a word',
      () async {
        final action = await publishedAction(
          endpoints,
          creator,
          actionRequest(
            actionKey: 'no-word-video',
            requirements: [
              mediaRequirement(
                kind: ActionRequirementKind.video,
                spokenChallengeRequired: false,
              ),
            ],
          ),
        );
        final requirementId = action.requirements.single.id;
        expect(action.requirements.single.spokenChallengeRequired, isFalse);
        final attempt = await endpoints.actionVerification.beginAttempt(
          participant,
          actionId: action.id,
          idempotencyKey: 'no-word',
        );

        await expectLater(
          endpoints.actionVerification.issueSpokenChallenge(
            participant,
            attemptId: attempt.id,
            requirementId: requirementId,
          ),
          throwsStateError,
        );
        await uploadMediaProof(
          endpoints,
          participant,
          participantId: participantId,
          attemptId: attempt.id,
          requirementId: requirementId,
          contentType: 'video/mp4',
          bytes: MediaFixtures.mp4Video(),
          durationSeconds: 8,
        );
        final evidence = await ActionEvidence.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) => table.attemptId.equals(attempt.id),
        );
        expect(evidence!.spokenChallengeWord, isNull);
        final verifier = ScriptedMediaVerifier();
        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => verifier,
        ).verify(sessionBuilder.build(), evidence.id!);
        expect(verifier.requests.single.spokenChallengeWord, isNull);
        final stored = await ActionAttempt.db.findById(
          sessionBuilder.build(),
          attempt.id,
        );
        expect(stored!.status, ActionAttemptStatus.verified);
      },
    );

    test('when a photo asks for a word then authoring refuses it', () async {
      await expectLater(
        endpoints.actionVerification.createAction(
          creator,
          actionRequest(
            actionKey: 'photo-with-word',
            requirements: [
              mediaRequirement(
                kind: ActionRequirementKind.photo,
                spokenChallengeRequired: true,
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });

    test(
      'when a photo proof is asked for a word then none is issued',
      () async {
        final action = await publishedAction(
          endpoints,
          creator,
          actionRequest(
            actionKey: 'plain-photo',
            requirements: [mediaRequirement(kind: ActionRequirementKind.photo)],
          ),
        );
        expect(action.requirements.single.spokenChallengeRequired, isFalse);
        final attempt = await endpoints.actionVerification.beginAttempt(
          participant,
          actionId: action.id,
          idempotencyKey: 'photo-word',
        );

        await expectLater(
          endpoints.actionVerification.issueSpokenChallenge(
            participant,
            attemptId: attempt.id,
            requirementId: action.requirements.single.id,
          ),
          throwsStateError,
        );
      },
    );

    test(
      'when an audio requirement keeps the default then it asks for a word',
      () async {
        final action = await publishedAction(
          endpoints,
          creator,
          actionRequest(
            actionKey: 'default-audio',
            requirements: [mediaRequirement(kind: ActionRequirementKind.audio)],
          ),
        );

        expect(action.requirements.single.spokenChallengeRequired, isTrue);
      },
    );
  });
}
