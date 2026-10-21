import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/evidence_storage/evidence_upload_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

void main() {
  withServerpod('Given private evidence upload reservations', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(301);
    final participantId = testId(302);
    final now = DateTime.utc(2026, 8, 21, 12);
    late DateTime clockNow;
    late EvidenceUploadService service;
    late UuidValue attemptId;
    late List<UuidValue> requirementIds;

    setUp(() async {
      clockNow = now;
      service = EvidenceUploadService(clock: () => clockNow);
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {creatorId: 'Ada', participantId: 'Grace'});
      final action = await ActionDefinition.db.insertRow(
        session,
        ActionDefinition(
          creatorAuthUserId: creatorId,
          actionKey: 'evidence-upload-action',
          title: 'Record proof',
          description: 'Record proof for upload tests.',
          status: ActionDefinitionStatus.active,
          recurrence: ActionRecurrence.daily,
          timeZone: 'UTC',
          publishedAt: now,
          updatedAt: now,
        ),
      );
      final requirements = await ActionRequirement.db.insert(session, [
        for (var index = 0; index < 4; index += 1)
          ActionRequirement(
            actionDefinitionId: action.id!,
            requirementKey: 'video-$index',
            kind: ActionRequirementKind.video,
            title: 'Recording ${index + 1}',
            instructions: 'Record the action.',
            position: index,
          ),
      ]);
      requirementIds = [for (final row in requirements) row.id!];
      final attempt = await ActionAttempt.db.insertRow(
        session,
        ActionAttempt(
          actionDefinitionId: action.id!,
          participantAuthUserId: participantId,
          periodKey: '2026-08-21',
          idempotencyKey: 'evidence-upload-attempt',
          status: ActionAttemptStatus.collectingEvidence,
          updatedAt: now,
        ),
      );
      attemptId = attempt.id!;
    });

    String pathFor(UuidValue requirementId) =>
        '$evidenceObjectPrefix$participantId/$attemptId/$requirementId.mp4';

    Future<EvidenceUploadReservation> reserve(
      UuidValue requirementId, {
      int byteLength = 1024,
      bool requireSpokenChallenge = false,
    }) => service.reserve(
      sessionBuilder.build(),
      authUserId: participantId,
      attemptId: attemptId,
      requirementId: requirementId,
      kind: ActionRequirementKind.video,
      storagePath: pathFor(requirementId),
      contentType: 'video/mp4',
      byteLength: byteLength,
      requireSpokenChallenge: requireSpokenChallenge,
    );

    Future<EvidenceUploadReservation> claim(UuidValue requirementId) =>
        service.reservationForConfirmation(
          sessionBuilder.build(),
          authUserId: participantId,
          attemptId: attemptId,
          requirementId: requirementId,
          contentType: 'video/mp4',
          byteLength: 1024,
        );

    test(
      'when one requirement asks for signed URLs then at most three are issued',
      () async {
        final requirementId = requirementIds.first;

        for (var request = 1; request <= 3; request += 1) {
          final reservation = await reserve(requirementId);
          expect(reservation.requestCount, request);
          expect(reservation.retainUntil, now.add(evidenceRetention));
        }

        await expectLater(reserve(requirementId), throwsStateError);
        expect(
          await EvidenceUploadReservation.db.count(sessionBuilder.build()),
          1,
        );
      },
    );

    test(
      'when a reservation changes its size then the request is refused',
      () async {
        await reserve(requirementIds.first);

        await expectLater(
          reserve(requirementIds.first, byteLength: 2048),
          throwsStateError,
        );
      },
    );

    test('when a day of reservations exceeds the byte cap then the next is '
        'refused', () async {
      const largeRecording = 150 * 1024 * 1024;
      for (final requirementId in requirementIds.take(3)) {
        await reserve(requirementId, byteLength: largeRecording);
      }

      await expectLater(
        reserve(requirementIds.last, byteLength: 60 * 1024 * 1024),
        throwsStateError,
      );
      expect(
        await EvidenceUploadReservation.db.count(sessionBuilder.build()),
        3,
      );
    });

    test(
      'when a word is required but none was issued then nothing is reserved',
      () async {
        await expectLater(
          reserve(requirementIds.first, requireSpokenChallenge: true),
          throwsStateError,
        );
        expect(
          await EvidenceUploadReservation.db.count(sessionBuilder.build()),
          0,
        );
      },
    );

    test(
      'when a word was issued then the reservation binds that word',
      () async {
        final challenge = await ActionSpokenChallenge.db.insertRow(
          sessionBuilder.build(),
          ActionSpokenChallenge(
            attemptId: attemptId,
            requirementId: requirementIds.first,
            participantAuthUserId: participantId,
            word: 'pelican',
            issuedAt: now.subtract(const Duration(minutes: 1)),
            expiresAt: now.add(const Duration(minutes: 14)),
          ),
        );

        final reservation = await reserve(
          requirementIds.first,
          requireSpokenChallenge: true,
        );

        expect(reservation.spokenChallengeId, challenge.id);
        final bound = await ActionSpokenChallenge.db.findById(
          sessionBuilder.build(),
          challenge.id!,
        );
        expect(bound!.boundAt, now);
      },
    );

    test(
      'when the signed URL expired then the upload can still be confirmed',
      () async {
        final requirementId = requirementIds.first;
        await reserve(requirementId);
        clockNow = now.add(const Duration(minutes: 10));

        final reservation = await claim(requirementId);

        expect(reservation.status, EvidenceUploadStatus.confirming);
        expect(reservation.confirmationAttemptCount, 1);
        expect(reservation.confirmationStartedAt, clockNow);
      },
    );

    test(
      'when a confirmation is running then a second one waits for its release',
      () async {
        final requirementId = requirementIds.first;
        await reserve(requirementId);
        final claimed = await claim(requirementId);

        await expectLater(claim(requirementId), throwsStateError);
        await expectLater(reserve(requirementId), throwsStateError);
        await service.releaseConfirmation(
          sessionBuilder.build(),
          reservationId: claimed.id!,
          confirmationAttemptCount: claimed.confirmationAttemptCount,
        );

        final retried = await claim(requirementId);
        expect(retried.status, EvidenceUploadStatus.confirming);
        expect(retried.confirmationAttemptCount, 2);
      },
    );

    test(
      'when a confirmation is abandoned then its lease expires and a stale '
      'holder cannot finish it',
      () async {
        final requirementId = requirementIds.first;
        await reserve(requirementId);
        await claim(requirementId);
        clockNow = now.add(const Duration(minutes: 11));

        final recovered = await claim(requirementId);

        expect(recovered.confirmationAttemptCount, 2);
        expect(recovered.confirmationStartedAt, clockNow);
        final session = sessionBuilder.build();
        await service.releaseConfirmation(
          session,
          reservationId: recovered.id!,
          confirmationAttemptCount: 1,
        );
        await expectLater(
          service.markConfirmed(
            session,
            reservationId: recovered.id!,
            confirmationAttemptCount: 1,
            storageVersionId: 'stale-version',
          ),
          throwsStateError,
        );
        final persisted = await EvidenceUploadReservation.db.findById(
          session,
          recovered.id!,
        );
        expect(persisted!.status, EvidenceUploadStatus.confirming);
        expect(persisted.confirmationAttemptCount, 2);
      },
    );

    test(
      'when a confirmation is marked then the version is pinned and no new '
      'upload or confirmation is allowed',
      () async {
        final requirementId = requirementIds.first;
        await reserve(requirementId);
        final claimed = await claim(requirementId);
        final session = sessionBuilder.build();

        await service.markConfirmed(
          session,
          reservationId: claimed.id!,
          confirmationAttemptCount: claimed.confirmationAttemptCount,
          storageVersionId: 'version-1',
        );
        // Repeating the same mark is idempotent; another version is not.
        await service.markConfirmed(
          session,
          reservationId: claimed.id!,
          confirmationAttemptCount: claimed.confirmationAttemptCount,
          storageVersionId: 'version-1',
        );
        await expectLater(
          service.markConfirmed(
            session,
            reservationId: claimed.id!,
            confirmationAttemptCount: claimed.confirmationAttemptCount,
            storageVersionId: 'version-2',
          ),
          throwsStateError,
        );

        final confirmed = await EvidenceUploadReservation.db.findById(
          session,
          claimed.id!,
        );
        expect(confirmed!.status, EvidenceUploadStatus.confirmed);
        expect(confirmed.storageVersionId, 'version-1');
        expect(confirmed.confirmedAt, now);
        await expectLater(reserve(requirementId), throwsStateError);
        await expectLater(claim(requirementId), throwsStateError);
      },
    );

    test('when confirmations keep failing then they are capped', () async {
      final requirementId = requirementIds.first;
      await reserve(requirementId);

      for (var attempt = 1; attempt <= 5; attempt += 1) {
        final claimed = await claim(requirementId);
        await service.releaseConfirmation(
          sessionBuilder.build(),
          reservationId: claimed.id!,
          confirmationAttemptCount: claimed.confirmationAttemptCount,
        );
      }

      await expectLater(claim(requirementId), throwsStateError);
    });

    test(
      'when another account confirms the upload then it is refused',
      () async {
        await reserve(requirementIds.first);

        await expectLater(
          service.reservationForConfirmation(
            sessionBuilder.build(),
            authUserId: creatorId,
            attemptId: attemptId,
            requirementId: requirementIds.first,
            contentType: 'video/mp4',
            byteLength: 1024,
          ),
          throwsStateError,
        );
      },
    );

    group('when the retention window has passed', () {
      Future<EvidenceUploadReservation> expiredReservation() async {
        final requirementId = requirementIds.first;
        final reservation = await reserve(requirementId);
        final session = sessionBuilder.build();
        await session.storage.storeFile(
          storageId: evidenceStorageId,
          path: reservation.storagePath,
          byteData: ByteData.sublistView(MediaFixtures.mp4Video()),
        );
        return EvidenceUploadReservation.db.updateRow(
          session,
          reservation.copyWith(
            reservedAt: now.subtract(const Duration(days: 9)),
            uploadExpiresAt: now.subtract(
              const Duration(days: 8, hours: 23, minutes: 55),
            ),
            retainUntil: now.subtract(const Duration(days: 2)),
          ),
        );
      }

      test('then cleanup removes the bytes and the reservation', () async {
        final reservation = await expiredReservation();
        final session = sessionBuilder.build();

        expect(await service.cleanupExpired(session), 1);

        expect(await EvidenceUploadReservation.db.count(session), 0);
        expect(
          await session.storage.fileExists(
            storageId: evidenceStorageId,
            path: reservation.storagePath,
          ),
          isFalse,
        );
      });

      test('then the cleanup future call removes it on schedule', () async {
        await expiredReservation();

        await endpoints.futureCalls.evidenceUploadCleanup.cleanup(
          sessionBuilder,
          EvidenceUploadCleanupTask(batchSize: 100),
        );

        expect(
          await EvidenceUploadReservation.db.count(sessionBuilder.build()),
          0,
        );
      });

      test(
        'then a recording with a pending appeal is kept until the appeal is '
        'resolved',
        () async {
          final reservation = await expiredReservation();
          final session = sessionBuilder.build();
          final evidence = await ActionEvidence.db.insertRow(
            session,
            ActionEvidence(
              attemptId: attemptId,
              requirementId: reservation.requirementId,
              kind: ActionRequirementKind.video,
              storagePath: reservation.storagePath,
              storageVersionId: 'version-1',
              mimeType: 'video/mp4',
              sha256Digest: 'a' * 64,
              byteLength: 1024,
              durationSeconds: 10,
              capturedAt: now.subtract(const Duration(days: 9, minutes: 1)),
              submittedAt: now.subtract(const Duration(days: 9)),
            ),
          );
          final appeal = await EvidenceAppeal.db.insertRow(
            session,
            EvidenceAppeal(
              evidenceId: evidence.id!,
              attemptId: attemptId,
              creatorAuthUserId: creatorId,
              participantAuthUserId: participantId,
              reason: 'The complete movement is visible in the recording.',
              status: EvidenceAppealStatus.pending,
              createdAt: now,
              updatedAt: now,
            ),
          );

          expect(await service.cleanupExpired(session), 0);
          expect(await EvidenceUploadReservation.db.count(session), 1);
          expect(
            await session.storage.fileExists(
              storageId: evidenceStorageId,
              path: reservation.storagePath,
            ),
            isTrue,
          );

          await EvidenceAppeal.db.updateRow(
            session,
            appeal.copyWith(
              status: EvidenceAppealStatus.rejected,
              resolutionNote: 'The proof does not meet the requirement.',
              resolvedAt: now,
              updatedAt: now,
            ),
          );
          expect(await service.cleanupExpired(session), 1);
          expect(await EvidenceUploadReservation.db.count(session), 0);
        },
      );

      test(
        'then a pending appeal no longer protects proof older than the '
        'longest appeal retention',
        () async {
          final reservation = await expiredReservation();
          final session = sessionBuilder.build();
          final submittedAt = now.subtract(
            appealedEvidenceMaximumRetention + const Duration(days: 1),
          );
          final evidence = await ActionEvidence.db.insertRow(
            session,
            ActionEvidence(
              attemptId: attemptId,
              requirementId: reservation.requirementId,
              kind: ActionRequirementKind.video,
              storagePath: reservation.storagePath,
              storageVersionId: 'version-1',
              mimeType: 'video/mp4',
              sha256Digest: 'b' * 64,
              byteLength: 1024,
              durationSeconds: 10,
              capturedAt: submittedAt,
              submittedAt: submittedAt,
            ),
          );
          await EvidenceAppeal.db.insertRow(
            session,
            EvidenceAppeal(
              evidenceId: evidence.id!,
              attemptId: attemptId,
              creatorAuthUserId: creatorId,
              participantAuthUserId: participantId,
              reason: 'Please look at this proof again carefully.',
              status: EvidenceAppealStatus.pending,
              createdAt: submittedAt,
              updatedAt: submittedAt,
            ),
          );

          expect(await service.cleanupExpired(session), 1);
        },
      );
    });
  });
}
