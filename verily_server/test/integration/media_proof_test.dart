import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/evidence_verification_recovery_future_call.dart';
import 'package:verily_server/src/action_verification/evidence_verification_worker.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/evidence_storage/local_evidence_storage.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

void main() {
  withServerpod('Given published video, photo, and audio actions', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(101);
    final participantId = testId(102);
    final otherId = testId(103);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late TestSessionBuilder other;
    late ActionOpportunity videoAction;
    late ActionOpportunity photoAction;
    late ActionOpportunity audioAction;
    late ActionOpportunity councilAudioAction;

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
      videoAction = await publishedAction(
        endpoints,
        creator,
        actionRequest(
          actionKey: 'video-proof',
          requirements: [
            mediaRequirement(
              kind: ActionRequirementKind.video,
              spokenChallengeRequired: false,
            ),
          ],
        ),
      );
      photoAction = await publishedAction(
        endpoints,
        creator,
        actionRequest(
          actionKey: 'photo-proof',
          requirements: [mediaRequirement(kind: ActionRequirementKind.photo)],
        ),
      );
      audioAction = await publishedAction(
        endpoints,
        creator,
        actionRequest(
          actionKey: 'audio-proof',
          requirements: [
            mediaRequirement(
              kind: ActionRequirementKind.audio,
              spokenChallengeRequired: false,
            ),
          ],
        ),
      );
      councilAudioAction = await publishedAction(
        endpoints,
        creator,
        actionRequest(
          actionKey: 'council-audio-proof',
          requirements: [
            mediaRequirement(
              kind: ActionRequirementKind.audio,
              policy: ActionVerificationPolicy.modelCouncil,
            ),
          ],
        ),
      );
    });

    Future<ActionAttemptView> begin(
      ActionOpportunity action, {
      TestSessionBuilder? as,
    }) => endpoints.actionVerification.beginAttempt(
      as ?? participant,
      actionId: action.id,
      idempotencyKey: 'attempt-${action.actionKey}',
    );

    Future<ActionEvidence> evidenceFor(UuidValue attemptId) async {
      final evidence = await ActionEvidence.db.findFirstRow(
        sessionBuilder.build(),
        where: (table) => table.attemptId.equals(attemptId),
      );
      return evidence!;
    }

    Future<void> storeRaw({
      required UuidValue attemptId,
      required UuidValue requirementId,
      required String contentType,
      required Uint8List bytes,
    }) async {
      final session = sessionBuilder.build();
      final storage =
          session.serverpod.storage[evidenceStorageId]! as LocalEvidenceStorage;
      await storage.storeUnverifiedFile(
        session: session,
        path: evidenceStoragePath(
          authUserId: participantId.toString(),
          attemptId: attemptId.toString(),
          requirementId: requirementId.toString(),
          type: evidenceMediaTypes[contentType]!,
        ),
        byteData: ByteData.sublistView(bytes),
        options: StoreFileOptions(
          metadata: FileMetadata(contentType: contentType),
        ),
      );
    }

    MediaUploadConfirmation confirmation({
      required ActionAttemptView attempt,
      required ActionOpportunity action,
      required String contentType,
      required int byteLength,
      int? durationSeconds,
    }) => MediaUploadConfirmation(
      attemptId: attempt.id,
      requirementId: action.requirements.single.id,
      contentType: contentType,
      byteLength: byteLength,
      durationSeconds: durationSeconds,
      capturedAt: DateTime.now().toUtc(),
    );

    group('when a JPEG photo is uploaded', () {
      test(
        'then the evidence pins the server-measured digest and version',
        () async {
          final attempt = await begin(photoAction);
          final bytes = MediaFixtures.jpeg();

          final result = await uploadMediaProof(
            endpoints,
            participant,
            participantId: participantId,
            attemptId: attempt.id,
            requirementId: photoAction.requirements.single.id,
            contentType: 'image/jpeg',
            bytes: bytes,
          );

          expect(result.status, isNull);
          expect(result.attempt.status, ActionAttemptStatus.verifying);
          final digest = sha256.convert(bytes).toString();
          final evidence = await evidenceFor(attempt.id);
          expect(evidence.kind, ActionRequirementKind.photo);
          expect(evidence.sha256Digest, digest);
          expect(evidence.storageVersionId, localEvidenceVersionId(digest));
          expect(evidence.byteLength, bytes.length);
          expect(evidence.mimeType, 'image/jpeg');
          expect(evidence.durationSeconds, isNull);
          expect(evidence.spokenChallengeWord, isNull);
          final reservation = await EvidenceUploadReservation.db.findFirstRow(
            sessionBuilder.build(),
            where: (table) => table.attemptId.equals(attempt.id),
          );
          expect(reservation!.status, EvidenceUploadStatus.confirmed);
          expect(reservation.storageVersionId, evidence.storageVersionId);
          final job = await EvidenceVerificationJob.db.findFirstRow(
            sessionBuilder.build(),
            where: (table) => table.evidenceId.equals(evidence.id),
          );
          expect(job!.status, EvidenceVerificationJobStatus.queued);
        },
      );

      test('then a reported duration is refused', () async {
        final attempt = await begin(photoAction);
        final bytes = MediaFixtures.jpeg();

        await expectLater(
          uploadMediaProof(
            endpoints,
            participant,
            participantId: participantId,
            attemptId: attempt.id,
            requirementId: photoAction.requirements.single.id,
            contentType: 'image/jpeg',
            bytes: bytes,
            durationSeconds: 4,
          ),
          throwsArgumentError,
        );
        expect(
          await ActionEvidence.db.count(
            sessionBuilder.build(),
            where: (table) => table.attemptId.equals(attempt.id),
          ),
          0,
        );
      });
    });

    test(
      'when the worker accepts a PNG photo then the attempt is verified '
      'without another client call',
      () async {
        final attempt = await begin(photoAction);
        await uploadMediaProof(
          endpoints,
          participant,
          participantId: participantId,
          attemptId: attempt.id,
          requirementId: photoAction.requirements.single.id,
          contentType: 'image/png',
          bytes: MediaFixtures.png(),
        );
        final verifier = ScriptedMediaVerifier();
        final evidence = await evidenceFor(attempt.id);

        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => verifier,
        ).verify(sessionBuilder.build(), evidence.id!);

        expect(verifier.requests.single.mimeType, 'image/png');
        expect(verifier.requests.single.durationSeconds, isNull);
        final stored = await ActionAttempt.db.findById(
          sessionBuilder.build(),
          attempt.id,
        );
        expect(stored!.status, ActionAttemptStatus.verified);
        expect(stored.verifiedRank, 1);
      },
    );

    test(
      'when the worker accepts an m4a recording then the attempt is verified '
      'without another client call',
      () async {
        final attempt = await begin(audioAction);
        final result = await uploadMediaProof(
          endpoints,
          participant,
          participantId: participantId,
          attemptId: attempt.id,
          requirementId: audioAction.requirements.single.id,
          contentType: 'audio/mp4',
          bytes: MediaFixtures.m4aAudio(),
          durationSeconds: 12,
        );
        expect(result.attempt.status, ActionAttemptStatus.verifying);
        final verifier = ScriptedMediaVerifier();
        final evidence = await evidenceFor(attempt.id);

        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => verifier,
        ).verify(sessionBuilder.build(), evidence.id!);

        final request = verifier.requests.single;
        expect(request.mimeType, 'audio/mp4');
        expect(request.durationSeconds, 12);
        expect(request.spokenChallengeWord, isNull);
        expect(request.sha256Digest, evidence.sha256Digest);
        final listed = await endpoints.actionVerification.listMyAttempts(
          participant,
          limit: 10,
        );
        expect(listed.single.status, ActionAttemptStatus.verified);
        final decisions = await EvidenceDecision.db.find(
          sessionBuilder.build(),
          where: (table) => table.evidenceId.equals(evidence.id),
        );
        expect(decisions.single.status, EvidenceDecisionStatus.accepted);
        expect(
          decisions.single.reasonCode,
          MediaVerificationReason.verified,
        );
      },
    );

    test(
      'when a council has fewer than two models that can hear the audio then '
      'the proof goes to a person',
      () async {
        final attempt = await begin(councilAudioAction);
        final requirementId = councilAudioAction.requirements.single.id;
        final challenge = await endpoints.actionVerification
            .issueSpokenChallenge(
              participant,
              attemptId: attempt.id,
              requirementId: requirementId,
            );
        await uploadMediaProof(
          endpoints,
          participant,
          participantId: participantId,
          attemptId: attempt.id,
          requirementId: requirementId,
          contentType: 'audio/mp4',
          bytes: MediaFixtures.m4aAudio(),
          durationSeconds: 9,
        );
        final verifier = _CouncilVerifier(
          hearing: SpokenChallengeVerdict.heard,
          hearingMembers: 1,
        );
        final evidence = await evidenceFor(attempt.id);

        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => verifier,
        ).verify(sessionBuilder.build(), evidence.id!);

        expect(verifier.requests.single.spokenChallengeWord, challenge.word);
        final stored = await ActionAttempt.db.findById(
          sessionBuilder.build(),
          attempt.id,
        );
        expect(stored!.status, ActionAttemptStatus.pendingReview);
        final session = sessionBuilder.build();
        final decision = await EvidenceDecision.db.findFirstRow(
          session,
          where: (table) => table.evidenceId.equals(evidence.id),
        );
        expect(decision!.status, EvidenceDecisionStatus.manualReview);
        expect(decision.reasonCode, MediaVerificationReason.spokenUnverified);
        final votes = await EvidenceVerificationVote.db.find(
          session,
          where: (table) => table.decisionId.equals(decision.id),
        );
        expect(votes, hasLength(3));
        expect(
          votes.where((vote) => vote.spokenChallengeVerdict == 'abstained'),
          hasLength(2),
        );
      },
    );

    test(
      'when two council members hear the word then the audio proof verifies',
      () async {
        final attempt = await begin(councilAudioAction);
        final requirementId = councilAudioAction.requirements.single.id;
        await endpoints.actionVerification.issueSpokenChallenge(
          participant,
          attemptId: attempt.id,
          requirementId: requirementId,
        );
        await uploadMediaProof(
          endpoints,
          participant,
          participantId: participantId,
          attemptId: attempt.id,
          requirementId: requirementId,
          contentType: 'audio/mp4',
          bytes: MediaFixtures.m4aAudio(),
          durationSeconds: 9,
        );
        final evidence = await evidenceFor(attempt.id);

        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => _CouncilVerifier(
            hearing: SpokenChallengeVerdict.heard,
            hearingMembers: 2,
          ),
        ).verify(sessionBuilder.build(), evidence.id!);

        final stored = await ActionAttempt.db.findById(
          sessionBuilder.build(),
          attempt.id,
        );
        expect(stored!.status, ActionAttemptStatus.verified);
      },
    );

    group('when the upload request does not fit the requirement', () {
      test('then a type of another media kind is refused', () async {
        final photoAttempt = await begin(photoAction);
        final audioAttempt = await begin(audioAction);

        await expectLater(
          endpoints.actionVerification.requestMediaUpload(
            participant,
            attemptId: photoAttempt.id,
            requirementId: photoAction.requirements.single.id,
            contentType: 'video/mp4',
            byteLength: 1024,
          ),
          throwsArgumentError,
        );
        await expectLater(
          endpoints.actionVerification.requestMediaUpload(
            participant,
            attemptId: audioAttempt.id,
            requirementId: audioAction.requirements.single.id,
            contentType: 'image/jpeg',
            byteLength: 1024,
          ),
          throwsArgumentError,
        );
        await expectLater(
          endpoints.actionVerification.requestMediaUpload(
            participant,
            attemptId: photoAttempt.id,
            requirementId: photoAction.requirements.single.id,
            contentType: 'text/plain',
            byteLength: 1024,
          ),
          throwsArgumentError,
        );
        expect(
          await EvidenceUploadReservation.db.count(sessionBuilder.build()),
          0,
        );
      });

      test('then a size outside the kind limit is refused', () async {
        final photoAttempt = await begin(photoAction);
        final audioAttempt = await begin(audioAction);
        final videoAttempt = await begin(videoAction);

        for (final (attempt, action, type, size) in [
          (photoAttempt, photoAction, 'image/jpeg', 20 * 1024 * 1024 + 1),
          (audioAttempt, audioAction, 'audio/mp4', 50 * 1024 * 1024 + 1),
          (videoAttempt, videoAction, 'video/mp4', 150 * 1024 * 1024 + 1),
          (photoAttempt, photoAction, 'image/jpeg', 0),
        ]) {
          await expectLater(
            endpoints.actionVerification.requestMediaUpload(
              participant,
              attemptId: attempt.id,
              requirementId: action.requirements.single.id,
              contentType: type,
              byteLength: size,
            ),
            throwsArgumentError,
            reason: '$type of $size bytes',
          );
        }
      });

      test('then another account cannot upload to the attempt', () async {
        final attempt = await begin(videoAction);

        await expectLater(
          endpoints.actionVerification.requestMediaUpload(
            other,
            attemptId: attempt.id,
            requirementId: videoAction.requirements.single.id,
            contentType: 'video/mp4',
            byteLength: 1024,
          ),
          throwsStateError,
        );
      });

      test('then a requirement of another action is refused', () async {
        final attempt = await begin(videoAction);

        await expectLater(
          endpoints.actionVerification.requestMediaUpload(
            participant,
            attemptId: attempt.id,
            requirementId: photoAction.requirements.single.id,
            contentType: 'image/jpeg',
            byteLength: 1024,
          ),
          throwsStateError,
        );
      });
    });

    test(
      'when the stored bytes are a different container then confirmation '
      'deletes them and refuses the proof',
      () async {
        final attempt = await begin(photoAction);
        final requirementId = photoAction.requirements.single.id;
        final disguised = MediaFixtures.png();
        await endpoints.actionVerification.requestMediaUpload(
          participant,
          attemptId: attempt.id,
          requirementId: requirementId,
          contentType: 'image/jpeg',
          byteLength: disguised.length,
        );
        await storeRaw(
          attemptId: attempt.id,
          requirementId: requirementId,
          contentType: 'image/jpeg',
          bytes: disguised,
        );

        await expectLater(
          endpoints.actionVerification.confirmMediaUpload(
            participant,
            confirmation(
              attempt: attempt,
              action: photoAction,
              contentType: 'image/jpeg',
              byteLength: disguised.length,
            ),
          ),
          throwsStateError,
        );

        final session = sessionBuilder.build();
        final path = evidenceStoragePath(
          authUserId: participantId.toString(),
          attemptId: attempt.id.toString(),
          requirementId: requirementId.toString(),
          type: evidenceMediaTypes['image/jpeg']!,
        );
        expect(
          await session.storage.fileExists(
            storageId: evidenceStorageId,
            path: path,
          ),
          isFalse,
        );
        expect(
          await ActionEvidence.db.count(
            session,
            where: (table) => table.attemptId.equals(attempt.id),
          ),
          0,
        );
        final reservation = await EvidenceUploadReservation.db.findFirstRow(
          session,
          where: (table) => table.attemptId.equals(attempt.id),
        );
        expect(reservation!.status, EvidenceUploadStatus.reserved);
        expect(reservation.confirmationStartedAt, isNull);
      },
    );

    test(
      'when nothing was uploaded then confirmation is refused and can retry',
      () async {
        final attempt = await begin(videoAction);
        final bytes = MediaFixtures.mp4Video();
        await endpoints.actionVerification.requestMediaUpload(
          participant,
          attemptId: attempt.id,
          requirementId: videoAction.requirements.single.id,
          contentType: 'video/mp4',
          byteLength: bytes.length,
        );

        await expectLater(
          endpoints.actionVerification.confirmMediaUpload(
            participant,
            confirmation(
              attempt: attempt,
              action: videoAction,
              contentType: 'video/mp4',
              byteLength: bytes.length,
              durationSeconds: 8,
            ),
          ),
          throwsStateError,
        );
        final reservation = await EvidenceUploadReservation.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) => table.attemptId.equals(attempt.id),
        );
        expect(reservation!.status, EvidenceUploadStatus.reserved);
        expect(reservation.confirmationAttemptCount, 1);
      },
    );

    test(
      'when a confirmation reports a different size than reserved then it is '
      'refused',
      () async {
        final attempt = await begin(videoAction);
        final bytes = MediaFixtures.mp4Video();
        await endpoints.actionVerification.requestMediaUpload(
          participant,
          attemptId: attempt.id,
          requirementId: videoAction.requirements.single.id,
          contentType: 'video/mp4',
          byteLength: bytes.length,
        );

        await expectLater(
          endpoints.actionVerification.confirmMediaUpload(
            participant,
            confirmation(
              attempt: attempt,
              action: videoAction,
              contentType: 'video/mp4',
              byteLength: bytes.length + 1,
              durationSeconds: 8,
            ),
          ),
          throwsStateError,
        );
      },
    );

    test(
      'when a confirmed proof is uploaded again then the new upload and '
      'confirmation are refused',
      () async {
        final attempt = await begin(videoAction);
        final bytes = MediaFixtures.mp4Video();
        await uploadMediaProof(
          endpoints,
          participant,
          participantId: participantId,
          attemptId: attempt.id,
          requirementId: videoAction.requirements.single.id,
          contentType: 'video/mp4',
          bytes: bytes,
          durationSeconds: 8,
        );
        final original = await evidenceFor(attempt.id);

        await expectLater(
          endpoints.actionVerification.requestMediaUpload(
            participant,
            attemptId: attempt.id,
            requirementId: videoAction.requirements.single.id,
            contentType: 'video/mp4',
            byteLength: bytes.length,
          ),
          throwsStateError,
        );
        await expectLater(
          endpoints.actionVerification.confirmMediaUpload(
            participant,
            confirmation(
              attempt: attempt,
              action: videoAction,
              contentType: 'video/mp4',
              byteLength: bytes.length,
              durationSeconds: 8,
            ),
          ),
          throwsStateError,
        );
        final after = await evidenceFor(attempt.id);
        expect(after.storageVersionId, original.storageVersionId);
      },
    );

    group('when a recording reports its duration', () {
      test('then a missing duration is refused', () async {
        final attempt = await begin(audioAction);

        await expectLater(
          uploadMediaProof(
            endpoints,
            participant,
            participantId: participantId,
            attemptId: attempt.id,
            requirementId: audioAction.requirements.single.id,
            contentType: 'audio/mp4',
            bytes: MediaFixtures.m4aAudio(),
          ),
          throwsArgumentError,
        );
      });

      test(
        'then a duration outside the rule is rejected before any model runs',
        () async {
          final attempt = await begin(videoAction);

          final result = await uploadMediaProof(
            endpoints,
            participant,
            participantId: participantId,
            attemptId: attempt.id,
            requirementId: videoAction.requirements.single.id,
            contentType: 'video/mp4',
            bytes: MediaFixtures.mp4Video(),
            durationSeconds: 61,
          );

          expect(result.status, EvidenceDecisionStatus.rejected);
          expect(result.reasonCode, 'recording_length');
          final evidence = await evidenceFor(attempt.id);
          expect(
            await EvidenceVerificationJob.db.count(
              sessionBuilder.build(),
              where: (table) => table.evidenceId.equals(evidence.id),
            ),
            0,
          );
          final completed = await endpoints.actionVerification.completeAttempt(
            participant,
            attempt.id,
          );
          expect(completed.status, ActionAttemptStatus.rejected);
          expect(completed.rejectionCode, 'recording_length');
        },
      );

      test('then a capture time in the future is rejected', () async {
        final attempt = await begin(videoAction);

        final result = await uploadMediaProof(
          endpoints,
          participant,
          participantId: participantId,
          attemptId: attempt.id,
          requirementId: videoAction.requirements.single.id,
          contentType: 'video/mp4',
          bytes: MediaFixtures.mp4Video(),
          durationSeconds: 8,
          capturedAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
        );

        expect(result.status, EvidenceDecisionStatus.rejected);
        expect(result.reasonCode, 'phone_clock');
      });
    });

    group('when verification stalls', () {
      Future<(ActionAttemptView, ActionEvidence)> uploadedVideo() async {
        final attempt = await begin(videoAction);
        await uploadMediaProof(
          endpoints,
          participant,
          participantId: participantId,
          attemptId: attempt.id,
          requirementId: videoAction.requirements.single.id,
          contentType: 'video/mp4',
          bytes: MediaFixtures.mp4Video(),
          durationSeconds: 8,
        );
        return (attempt, await evidenceFor(attempt.id));
      }

      final stale = DateTime.now().toUtc().subtract(
        const Duration(minutes: 10),
      );

      test(
        'then recovery completes an attempt stranded in verifying after its '
        'decision landed',
        () async {
          final (attempt, evidence) = await uploadedVideo();
          final session = sessionBuilder.build();
          // A crash between the decision commit and completion.
          await EvidenceDecision.db.insertRow(
            session,
            EvidenceDecision(
              evidenceId: evidence.id!,
              status: EvidenceDecisionStatus.accepted,
              verifierType: 'openrouter-single-model',
              confidence: 0.95,
              reasonCode: MediaVerificationReason.verified,
              summary: verifiedSummary,
            ),
          );
          final job = await EvidenceVerificationJob.db.findFirstRow(
            session,
            where: (table) => table.evidenceId.equals(evidence.id),
          );
          await EvidenceVerificationJob.db.updateRow(
            session,
            job!.copyWith(
              status: EvidenceVerificationJobStatus.completed,
              attemptCount: 1,
              completedAt: stale,
            ),
          );
          final stored = await ActionAttempt.db.findById(session, attempt.id);
          expect(stored!.status, ActionAttemptStatus.verifying);
          await ActionAttempt.db.updateRow(
            session,
            stored.copyWith(updatedAt: stale),
          );

          await endpoints.futureCalls.evidenceVerificationRecovery.recover(
            sessionBuilder,
            EvidenceVerificationRecoveryTask(batchSize: 50),
          );

          final recovered = await ActionAttempt.db.findById(
            sessionBuilder.build(),
            attempt.id,
          );
          expect(recovered!.status, ActionAttemptStatus.verified);
          expect(recovered.verifiedRank, 1);
        },
      );

      test(
        'then a job that exhausted its retries goes to a person',
        () async {
          final (attempt, evidence) = await uploadedVideo();
          final session = sessionBuilder.build();
          final job = await EvidenceVerificationJob.db.findFirstRow(
            session,
            where: (table) => table.evidenceId.equals(evidence.id),
          );
          await EvidenceVerificationJob.db.updateRow(
            session,
            job!.copyWith(
              status: EvidenceVerificationJobStatus.failed,
              attemptCount: evidenceVerificationMaximumAttempts,
              updatedAt: stale,
              lastErrorCode: 'verification_worker_failed',
            ),
          );

          await endpoints.futureCalls.evidenceVerificationRecovery.recover(
            sessionBuilder,
            EvidenceVerificationRecoveryTask(batchSize: 50),
          );

          final routed = await EvidenceVerificationJob.db.findById(
            sessionBuilder.build(),
            job.id!,
          );
          expect(routed!.status, EvidenceVerificationJobStatus.completed);
          expect(routed.lastErrorCode, MediaVerificationReason.retryExhausted);
          final decision = await EvidenceDecision.db.findFirstRow(
            sessionBuilder.build(),
            where: (table) => table.evidenceId.equals(evidence.id),
          );
          expect(decision!.status, EvidenceDecisionStatus.manualReview);
          expect(decision.reasonCode, MediaVerificationReason.retryExhausted);
          final stored = await ActionAttempt.db.findById(
            sessionBuilder.build(),
            attempt.id,
          );
          expect(stored!.status, ActionAttemptStatus.pendingReview);
        },
      );

      test('then a stale queued job is queued again', () async {
        final (_, evidence) = await uploadedVideo();
        final session = sessionBuilder.build();
        final job = await EvidenceVerificationJob.db.findFirstRow(
          session,
          where: (table) => table.evidenceId.equals(evidence.id),
        );
        await EvidenceVerificationJob.db.updateRow(
          session,
          job!.copyWith(attemptCount: 1, updatedAt: stale),
        );

        await endpoints.futureCalls.evidenceVerificationRecovery.recover(
          sessionBuilder,
          EvidenceVerificationRecoveryTask(batchSize: 50),
        );

        final requeued = await EvidenceVerificationJob.db.findById(
          sessionBuilder.build(),
          job.id!,
        );
        expect(requeued!.status, EvidenceVerificationJobStatus.queued);
        expect(requeued.updatedAt.isAfter(stale), isTrue);
        expect(
          await EvidenceDecision.db.count(
            sessionBuilder.build(),
            where: (table) => table.evidenceId.equals(evidence.id),
          ),
          0,
        );
      });

      test('then a verifier failure leaves the job for recovery', () async {
        final (attempt, evidence) = await uploadedVideo();

        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => _ThrowingVerifier(),
        ).verify(sessionBuilder.build(), evidence.id!);

        final job = await EvidenceVerificationJob.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) => table.evidenceId.equals(evidence.id),
        );
        expect(job!.status, EvidenceVerificationJobStatus.failed);
        expect(job.attemptCount, 1);
        expect(job.lastErrorCode, 'verification_worker_failed');
        final stored = await ActionAttempt.db.findById(
          sessionBuilder.build(),
          attempt.id,
        );
        expect(stored!.status, ActionAttemptStatus.verifying);
      });

      test('then running the worker twice records one decision', () async {
        final (_, evidence) = await uploadedVideo();
        final worker = EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => ScriptedMediaVerifier(),
        );

        await worker.verify(sessionBuilder.build(), evidence.id!);
        await worker.verify(sessionBuilder.build(), evidence.id!);

        expect(
          await EvidenceDecision.db.count(
            sessionBuilder.build(),
            where: (table) => table.evidenceId.equals(evidence.id),
          ),
          1,
        );
      });
    });
  });
}

/// Three council votes that all see the action done; [hearingMembers] of
/// them can hear the audio and report [hearing], the rest abstain.
class _CouncilVerifier implements MediaEvidenceVerifier {
  _CouncilVerifier({required this.hearing, required this.hearingMembers});

  final SpokenChallengeVerdict hearing;
  final int hearingMembers;
  final requests = <MediaVerificationRequest>[];

  @override
  Future<MediaEvidenceVerification> verify(
    Session session,
    MediaVerificationRequest request,
  ) async {
    requests.add(request);
    const models = [
      openRouterGeminiFlashModel,
      openRouterGemmaModel,
      openRouterGlmFlashModel,
    ];
    return decideMediaVerification(
      policy: request.rule.verificationPolicy,
      votes: [
        for (var index = 0; index < models.length; index += 1)
          MediaEvidenceModelVote(
            modelId: models[index],
            verdict: MediaEvidenceModelVerdict.fulfilled,
            confidence: 0.95,
            latencyMilliseconds: 5,
            spokenChallengeVerdict: index < hearingMembers
                ? hearing
                : SpokenChallengeVerdict.abstained,
          ),
      ],
      minimumConfidence: request.rule.minConfidence,
      spokenChallengeRequested: request.spokenChallengeWord != null,
    );
  }
}

class _ThrowingVerifier implements MediaEvidenceVerifier {
  @override
  Future<MediaEvidenceVerification> verify(
    Session session,
    MediaVerificationRequest request,
  ) => throw const MediaEvidenceVerifierException('provider timed out');
}
