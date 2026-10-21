// Generated copyWith methods use null to clear nullable persisted fields.
// ignore_for_file: avoid_redundant_argument_values

import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/generated/protocol.dart';

const Duration evidenceUploadUrlLifetime = Duration(minutes: 5);
const Duration evidenceRetention = Duration(days: 7);
const Duration appealedEvidenceMaximumRetention = Duration(days: 30);

const int _maxReservationsPerRollingDay = 12;
const int _maxReservedBytesPerRollingDay = 500 * 1024 * 1024;
const int _maxUploadUrlRequestsPerRequirement = 3;
const int _maxConfirmationAttemptsPerRequirement = 5;
const Duration _confirmationLease = Duration(minutes: 10);

/// Durable, quota-bounded authorizations for private evidence uploads.
///
/// One reservation exists per attempt and requirement. A row-locked
/// `reserved` to `confirming` lease lets only one inspection run at a time,
/// and a confirmed reservation never issues another upload URL, so the bytes
/// a verifier reads are the bytes that were hashed.
class EvidenceUploadService {
  EvidenceUploadService({DateTime Function()? clock})
    : clock = clock ?? (() => DateTime.now().toUtc());

  final DateTime Function() clock;

  Future<EvidenceUploadReservation> reserve(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required UuidValue requirementId,
    required ActionRequirementKind kind,
    required String storagePath,
    required String contentType,
    required int byteLength,
    required bool requireSpokenChallenge,
  }) {
    final now = clock().toUtc();
    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final existing = await EvidenceUploadReservation.db.findFirstRow(
          session,
          where: (table) =>
              table.attemptId.equals(attemptId) &
              table.requirementId.equals(requirementId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (existing != null) {
          _validateExistingReservation(
            existing,
            authUserId: authUserId,
            storagePath: storagePath,
            contentType: contentType,
            byteLength: byteLength,
          );
          if (_hasActiveConfirmation(existing, now)) {
            throw StateError('This recording is already being checked.');
          }
          if (existing.requestCount >= _maxUploadUrlRequestsPerRequirement) {
            throw StateError(
              'This recording has already used its upload attempts.',
            );
          }
          return EvidenceUploadReservation.db.updateRow(
            session,
            existing.copyWith(
              status: EvidenceUploadStatus.reserved,
              requestCount: existing.requestCount + 1,
              lastSignedAt: now,
              uploadExpiresAt: now.add(evidenceUploadUrlLifetime),
              confirmationStartedAt: null,
            ),
            transaction: transaction,
          );
        }

        final recent = await EvidenceUploadReservation.db.find(
          session,
          where: (table) =>
              table.authUserId.equals(authUserId) &
              (table.reservedAt >= now.subtract(const Duration(days: 1))),
          limit: _maxReservationsPerRollingDay,
          transaction: transaction,
        );
        final reservedBytes = recent.fold<int>(
          0,
          (total, reservation) => total + reservation.byteLength,
        );
        if (recent.length >= _maxReservationsPerRollingDay ||
            reservedBytes + byteLength > _maxReservedBytesPerRollingDay) {
          throw StateError(
            'Your recording upload limit has been reached. Try again later.',
          );
        }

        // The live word must have been issued before recording. Binding it
        // here, once, ties this recording to that word for good.
        final spokenChallenge = requireSpokenChallenge
            ? await _bindSpokenChallenge(
                session,
                attemptId: attemptId,
                requirementId: requirementId,
                authUserId: authUserId,
                now: now,
                transaction: transaction,
              )
            : null;

        return EvidenceUploadReservation.db.insertRow(
          session,
          EvidenceUploadReservation(
            authUserId: authUserId,
            attemptId: attemptId,
            requirementId: requirementId,
            kind: kind,
            storagePath: storagePath,
            contentType: contentType,
            byteLength: byteLength,
            status: EvidenceUploadStatus.reserved,
            spokenChallengeId: spokenChallenge?.id,
            requestCount: 1,
            reservedAt: now,
            lastSignedAt: now,
            uploadExpiresAt: now.add(evidenceUploadUrlLifetime),
            retainUntil: now.add(evidenceRetention),
          ),
          transaction: transaction,
        );
      },
    );
  }

  Future<EvidenceUploadReservation> reservationForConfirmation(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String contentType,
    required int byteLength,
  }) {
    final now = clock().toUtc();
    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final reservation = await EvidenceUploadReservation.db.findFirstRow(
          session,
          where: (table) =>
              table.attemptId.equals(attemptId) &
              table.requirementId.equals(requirementId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (reservation == null || reservation.authUserId != authUserId) {
          throw StateError('The recording upload was not found.');
        }
        if (reservation.status == EvidenceUploadStatus.confirmed) {
          throw StateError('This recording upload is already confirmed.');
        }
        if (_hasActiveConfirmation(reservation, now)) {
          throw StateError('This recording is already being checked.');
        }
        if (reservation.contentType != contentType ||
            reservation.byteLength != byteLength) {
          throw StateError(
            'The recording does not match its upload reservation.',
          );
        }
        if (reservation.retainUntil.isBefore(now)) {
          throw StateError('The recording upload is no longer available.');
        }
        if (reservation.confirmationAttemptCount >=
            _maxConfirmationAttemptsPerRequirement) {
          throw StateError(
            'This recording has already used its verification attempts.',
          );
        }
        return EvidenceUploadReservation.db.updateRow(
          session,
          reservation.copyWith(
            status: EvidenceUploadStatus.confirming,
            confirmationAttemptCount: reservation.confirmationAttemptCount + 1,
            confirmationStartedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
  }

  Future<void> releaseConfirmation(
    Session session, {
    required UuidValue reservationId,
    required int confirmationAttemptCount,
  }) {
    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final reservation = await EvidenceUploadReservation.db.findById(
          session,
          reservationId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (reservation?.status != EvidenceUploadStatus.confirming ||
            reservation?.confirmationAttemptCount != confirmationAttemptCount) {
          return;
        }
        await EvidenceUploadReservation.db.updateRow(
          session,
          reservation!.copyWith(
            status: EvidenceUploadStatus.reserved,
            confirmationStartedAt: null,
          ),
          transaction: transaction,
        );
      },
    );
  }

  Future<void> markConfirmed(
    Session session, {
    required UuidValue reservationId,
    required int confirmationAttemptCount,
    required String storageVersionId,
  }) {
    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final reservation = await EvidenceUploadReservation.db.findById(
          session,
          reservationId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (reservation == null) return;
        if (reservation.status == EvidenceUploadStatus.confirmed) {
          if (reservation.storageVersionId != storageVersionId) {
            throw StateError('The recording upload version changed.');
          }
          return;
        }
        if (reservation.status != EvidenceUploadStatus.confirming) {
          throw StateError('The recording upload was not claimed.');
        }
        if (reservation.confirmationAttemptCount != confirmationAttemptCount) {
          throw StateError('The recording confirmation lease changed.');
        }
        await EvidenceUploadReservation.db.updateRow(
          session,
          reservation.copyWith(
            status: EvidenceUploadStatus.confirmed,
            confirmationStartedAt: null,
            confirmedAt: clock().toUtc(),
            storageVersionId: storageVersionId,
          ),
          transaction: transaction,
        );
      },
    );
  }

  Future<int> cleanupExpired(
    Session session, {
    int batchSize = 100,
  }) async {
    final now = clock().toUtc();
    final expired = await EvidenceUploadReservation.db.find(
      session,
      where: (table) => table.retainUntil <= now,
      orderBy: (table) => table.retainUntil,
      limit: batchSize.clamp(1, 500),
    );
    final protectedPairs = await _pendingAppealEvidencePairs(
      session,
      expired,
      now: now,
    );
    var deleted = 0;
    for (final reservation in expired) {
      if (protectedPairs.contains((
        reservation.attemptId,
        reservation.requirementId,
      ))) {
        continue;
      }
      try {
        await session.storage.deleteFile(
          storageId: evidenceStorageId,
          path: reservation.storagePath,
        );
        await EvidenceUploadReservation.db.deleteRow(session, reservation);
        deleted += 1;
      } on Object catch (error, stackTrace) {
        session.log(
          'Evidence cleanup failed for reservation ${reservation.id}.',
          level: LogLevel.warning,
          exception: error,
          stackTrace: stackTrace,
        );
      }
    }
    return deleted;
  }

  Future<Set<(UuidValue, UuidValue)>> _pendingAppealEvidencePairs(
    Session session,
    List<EvidenceUploadReservation> reservations, {
    required DateTime now,
  }) async {
    if (reservations.isEmpty) return const {};
    final reservationPairs = {
      for (final reservation in reservations)
        (reservation.attemptId, reservation.requirementId),
    };
    final evidence = await ActionEvidence.db.find(
      session,
      where: (table) => table.attemptId.inSet(
        reservations.map((reservation) => reservation.attemptId).toSet(),
      ),
    );
    final relevantEvidence = [
      for (final row in evidence)
        if (reservationPairs.contains((row.attemptId, row.requirementId)) &&
            row.submittedAt.isAfter(
              now.subtract(appealedEvidenceMaximumRetention),
            ))
          row,
    ];
    if (relevantEvidence.isEmpty) return const {};
    final pendingAppeals = await EvidenceAppeal.db.find(
      session,
      where: (table) =>
          table.evidenceId.inSet(
            relevantEvidence.map((row) => row.id!).toSet(),
          ) &
          table.status.equals(EvidenceAppealStatus.pending),
    );
    final protectedEvidenceIds = pendingAppeals
        .map((appeal) => appeal.evidenceId)
        .toSet();
    return {
      for (final row in relevantEvidence)
        if (protectedEvidenceIds.contains(row.id))
          (row.attemptId, row.requirementId),
    };
  }
}

Future<ActionSpokenChallenge> _bindSpokenChallenge(
  Session session, {
  required UuidValue attemptId,
  required UuidValue requirementId,
  required UuidValue authUserId,
  required DateTime now,
  required Transaction transaction,
}) async {
  final challenge = await ActionSpokenChallenge.db.findFirstRow(
    session,
    where: (table) =>
        table.attemptId.equals(attemptId) &
        table.requirementId.equals(requirementId) &
        table.participantAuthUserId.equals(authUserId) &
        table.boundAt.equals(null) &
        (table.expiresAt > now),
    orderBy: (table) => table.issuedAt.desc(),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );
  if (challenge == null) {
    throw StateError(
      'Get a fresh challenge word, then record again while saying it.',
    );
  }
  return ActionSpokenChallenge.db.updateRow(
    session,
    challenge.copyWith(boundAt: now),
    transaction: transaction,
  );
}

bool _hasActiveConfirmation(
  EvidenceUploadReservation reservation,
  DateTime now,
) {
  if (reservation.status != EvidenceUploadStatus.confirming) return false;
  final startedAt = reservation.confirmationStartedAt;
  return startedAt == null ||
      startedAt.isAfter(now.subtract(_confirmationLease));
}

void _validateExistingReservation(
  EvidenceUploadReservation reservation, {
  required UuidValue authUserId,
  required String storagePath,
  required String contentType,
  required int byteLength,
}) {
  if (reservation.authUserId != authUserId ||
      reservation.storagePath != storagePath ||
      reservation.contentType != contentType ||
      reservation.byteLength != byteLength) {
    throw StateError('The recording does not match its upload reservation.');
  }
  if (reservation.status == EvidenceUploadStatus.confirmed) {
    throw StateError('This recording upload is already confirmed.');
  }
}
