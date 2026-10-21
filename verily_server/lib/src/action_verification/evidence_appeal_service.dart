import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/evidence_review_service.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';

const Duration evidenceAppealSubmissionWindow = Duration(days: 7);

/// One appeal per rejected proof, decided by the action's creator.
///
/// Participants never send creator, action, or evidence identifiers: the
/// rejected evidence and its creator derive from the authenticated attempt.
/// Acceptance appends a new decision and completes the attempt in the same
/// transaction; the original verifier decision is retained.
class EvidenceAppealService {
  EvidenceAppealService({
    ActionVerificationService? actions,
    RewardPayoutService? payouts,
    DateTime Function()? clock,
  }) : actions = actions ?? ActionVerificationService(clock: clock),
       payouts = payouts ?? RewardPayoutService(clock: clock),
       clock = clock ?? (() => DateTime.now().toUtc());

  final ActionVerificationService actions;
  final RewardPayoutService payouts;
  final DateTime Function() clock;

  Future<EvidenceAppealView> submit(
    Session session, {
    required UuidValue participantAuthUserId,
    required UuidValue attemptId,
    required String reason,
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.length < 10 || normalizedReason.length > 1000) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Explain the issue in 10 to 1000 characters.',
      );
    }

    final appeal = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          participantAuthUserId,
          transaction: transaction,
        );
        final attempt = await ActionAttempt.db.findFirstRow(
          session,
          where: (table) =>
              table.id.equals(attemptId) &
              table.participantAuthUserId.equals(participantAuthUserId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (attempt == null) throw StateError('Action attempt was not found.');
        if (attempt.status != ActionAttemptStatus.rejected) {
          throw StateError('Only rejected proof can be appealed.');
        }
        final evidence = await _latestRejectedEvidence(
          session,
          attemptId: attemptId,
          transaction: transaction,
        );
        if (evidence == null) {
          throw StateError('No rejected proof is available to appeal.');
        }
        if (evidence.submittedAt.isBefore(
          clock().toUtc().subtract(evidenceAppealSubmissionWindow),
        )) {
          throw StateError('The appeal window for this proof has closed.');
        }
        final existing = await EvidenceAppeal.db.findFirstRow(
          session,
          where: (table) => table.evidenceId.equals(evidence.id),
          transaction: transaction,
        );
        if (existing != null) return existing;
        final action = await ActionDefinition.db.findById(
          session,
          attempt.actionDefinitionId,
          transaction: transaction,
        );
        if (action == null) throw StateError('Action was not found.');
        final now = clock().toUtc();
        return EvidenceAppeal.db.insertRow(
          session,
          EvidenceAppeal(
            evidenceId: evidence.id!,
            attemptId: attemptId,
            creatorAuthUserId: action.creatorAuthUserId,
            participantAuthUserId: participantAuthUserId,
            reason: normalizedReason,
            status: EvidenceAppealStatus.pending,
            createdAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    return _view(session, appeal, includeMedia: false);
  }

  Future<EvidenceAppealView?> getMine(
    Session session, {
    required UuidValue participantAuthUserId,
    required UuidValue attemptId,
  }) async {
    final appeal = await EvidenceAppeal.db.findFirstRow(
      session,
      where: (table) =>
          table.attemptId.equals(attemptId) &
          table.participantAuthUserId.equals(participantAuthUserId),
      orderBy: (table) => table.createdAt.desc(),
    );
    return appeal == null ? null : _view(session, appeal, includeMedia: false);
  }

  /// The creator's pending appeals, oldest first.
  Future<List<EvidenceAppealView>> listOwned(
    Session session, {
    required UuidValue creatorAuthUserId,
    int limit = 50,
  }) async {
    final appeals = await EvidenceAppeal.db.find(
      session,
      where: (table) =>
          table.creatorAuthUserId.equals(creatorAuthUserId) &
          table.status.equals(EvidenceAppealStatus.pending),
      orderBy: (table) => table.createdAt,
      limit: limit.clamp(1, 100),
    );
    return _views(session, appeals, includeMedia: true);
  }

  Future<EvidenceAppealView> resolve(
    Session session, {
    required UuidValue creatorAuthUserId,
    required UuidValue appealId,
    required EvidenceAppealStatus decision,
    required String note,
  }) async {
    if (decision == EvidenceAppealStatus.pending) {
      throw ArgumentError.value(
        decision,
        'decision',
        'An appeal must be accepted or rejected.',
      );
    }
    final normalizedNote = note.trim();
    if (normalizedNote.isEmpty || normalizedNote.length > 500) {
      throw ArgumentError.value(
        note,
        'note',
        'Add a resolution note of 500 characters or fewer.',
      );
    }

    final resolved = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final initial = await EvidenceAppeal.db.findFirstRow(
          session,
          where: (table) =>
              table.id.equals(appealId) &
              table.creatorAuthUserId.equals(creatorAuthUserId),
          transaction: transaction,
        );
        if (initial == null) {
          throw StateError('Only the creator can resolve this appeal.');
        }
        if (initial.participantAuthUserId == creatorAuthUserId) {
          throw StateError('Creators cannot resolve their own appeal.');
        }
        await AccountAccess.requireActive(
          session,
          initial.participantAuthUserId,
          transaction: transaction,
        );
        final appeal = await EvidenceAppeal.db.findFirstRow(
          session,
          where: (table) => table.id.equals(appealId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (appeal == null) throw StateError('Appeal was not found.');
        if (appeal.status != EvidenceAppealStatus.pending) {
          throw StateError('This appeal has already been resolved.');
        }
        final attempt = await ActionAttempt.db.findFirstRow(
          session,
          where: (table) => table.id.equals(appeal.attemptId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (attempt == null || attempt.status != ActionAttemptStatus.rejected) {
          throw StateError('This proof is no longer rejected.');
        }
        final latest = await latestDecision(
          session,
          evidenceId: appeal.evidenceId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (latest == null ||
            latest.status != EvidenceDecisionStatus.rejected) {
          throw StateError('This proof is no longer rejected.');
        }

        final now = clock().toUtc();
        if (decision == EvidenceAppealStatus.accepted) {
          await EvidenceDecision.db.insertRow(
            session,
            EvidenceDecision(
              evidenceId: appeal.evidenceId,
              status: EvidenceDecisionStatus.accepted,
              verifierType: 'appeal-review',
              confidence: 1,
              reasonCode: 'appeal_accepted',
              summary: normalizedNote,
              reviewedByAuthUserId: creatorAuthUserId,
              createdAt: now,
            ),
            transaction: transaction,
          );
          await actions.completeAttempt(
            session,
            authUserId: appeal.participantAuthUserId,
            attemptId: appeal.attemptId,
            enclosingTransaction: transaction,
          );
        }
        return EvidenceAppeal.db.updateRow(
          session,
          appeal.copyWith(
            status: decision,
            resolutionNote: normalizedNote,
            resolvedByAuthUserId: creatorAuthUserId,
            resolvedAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    if (resolved.status == EvidenceAppealStatus.accepted) {
      await payouts.scheduleForAttempt(session, attemptId: resolved.attemptId);
    }
    return _view(session, resolved, includeMedia: true);
  }

  Future<ActionEvidence?> _latestRejectedEvidence(
    Session session, {
    required UuidValue attemptId,
    required Transaction transaction,
  }) async {
    final evidenceRows = await ActionEvidence.db.find(
      session,
      where: (table) => table.attemptId.equals(attemptId),
      orderBy: (table) => table.submittedAt.desc(),
      transaction: transaction,
    );
    for (final evidence in evidenceRows) {
      final latest = await latestDecision(
        session,
        evidenceId: evidence.id!,
        transaction: transaction,
      );
      if (latest?.status == EvidenceDecisionStatus.rejected) return evidence;
    }
    return null;
  }

  Future<EvidenceAppealView> _view(
    Session session,
    EvidenceAppeal appeal, {
    required bool includeMedia,
  }) async {
    return (await _views(session, [appeal], includeMedia: includeMedia)).single;
  }

  Future<List<EvidenceAppealView>> _views(
    Session session,
    List<EvidenceAppeal> appeals, {
    required bool includeMedia,
  }) async {
    if (appeals.isEmpty) return const [];
    final evidenceRows = await ActionEvidence.db.find(
      session,
      where: (table) => table.id.inSet(<UuidValue>{
        for (final appeal in appeals) appeal.evidenceId,
      }),
    );
    final attempts = await ActionAttempt.db.find(
      session,
      where: (table) => table.id.inSet(<UuidValue>{
        for (final appeal in appeals) appeal.attemptId,
      }),
    );
    final actions = await ActionDefinition.db.find(
      session,
      where: (table) => table.id.inSet(<UuidValue>{
        for (final attempt in attempts) attempt.actionDefinitionId,
      }),
    );
    final requirements = await ActionRequirement.db.find(
      session,
      where: (table) => table.id.inSet(<UuidValue>{
        for (final evidence in evidenceRows) evidence.requirementId,
      }),
    );
    final evidenceById = {for (final row in evidenceRows) row.id!: row};
    final attemptById = {for (final row in attempts) row.id!: row};
    final actionById = {for (final row in actions) row.id!: row};
    final requirementById = {for (final row in requirements) row.id!: row};
    final views = <EvidenceAppealView>[];
    for (final appeal in appeals) {
      final evidence = evidenceById[appeal.evidenceId];
      final attempt = attemptById[appeal.attemptId];
      final action = attempt == null
          ? null
          : actionById[attempt.actionDefinitionId];
      final requirement = evidence == null
          ? null
          : requirementById[evidence.requirementId];
      if (evidence == null ||
          attempt == null ||
          action == null ||
          requirement == null) {
        throw StateError('Appeal context is incomplete.');
      }
      views.add(
        EvidenceAppealView(
          id: appeal.id!,
          evidenceId: appeal.evidenceId,
          attemptId: appeal.attemptId,
          actionTitle: action.title,
          requirementTitle: requirement.title,
          requirementKind: requirement.kind,
          reason: appeal.reason,
          status: appeal.status,
          createdAt: appeal.createdAt,
          resolutionNote: appeal.resolutionNote,
          resolvedAt: appeal.resolvedAt,
          mediaUrl: includeMedia
              ? await evidenceReviewUrl(session, evidence)
              : null,
          spokenChallengeWord: includeMedia
              ? evidence.spokenChallengeWord
              : null,
        ),
      );
    }
    return views;
  }
}
