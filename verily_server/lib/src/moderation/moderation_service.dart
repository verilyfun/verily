import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/action_key_lock.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/moderation/moderation_access.dart';
import 'package:verily_server/src/moderation/moderation_policy.dart';

/// Durable human review of reported actions with independent safety holds
/// and append-only audit events. Anyone can post an action, so anyone signed
/// in can report one; only scoped staff can hold, dismiss, or lift.
class ModerationService {
  ModerationService({DateTime Function()? clock})
    : clock = clock ?? (() => DateTime.now().toUtc());

  final DateTime Function() clock;

  /// Reports never delete content. High-risk allegations pause it for humans.
  Future<ModerationCaseStatusView> report(
    Session session, {
    required UuidValue actionDefinitionId,
    required String category,
    required String details,
    required String idempotencyKey,
  }) async {
    final account = requireGovernanceAccount(session);
    final normalizedDetails = ModerationPolicy.text(details);
    final key = ModerationPolicy.text(idempotencyKey, minimum: 1, maximum: 128);
    final precautionaryPause = ModerationPolicy.requiresPrecautionaryPause(
      category,
    );

    return DatabaseUtil.runInTransactionOrSavepoint(session.db, null, (
      transaction,
    ) async {
      await AccountAccess.requireActive(
        session,
        account,
        transaction: transaction,
      );
      final action = await _lockAction(
        session,
        actionDefinitionId,
        transaction,
      );
      final isCreator = action.creatorAuthUserId == account;
      if (!isCreator && action.status == ActionDefinitionStatus.draft) {
        throw StateError('This action is not available to report.');
      }

      final existing = await ModerationCase.db.findFirstRow(
        session,
        where: (table) =>
            table.reporterAuthUserId.equals(account) &
            table.idempotencyKey.equals(key),
        transaction: transaction,
      );

      if (existing != null) {
        if (existing.actionDefinitionId != actionDefinitionId ||
            existing.category != category ||
            existing.details != normalizedDetails) {
          throw StateError(
            'That report key was already used for another report.',
          );
        }

        return _status(existing, isCreator: isCreator);
      }

      final now = clock().toUtc();
      final recentCount = await ModerationCase.db.count(
        session,
        where: (table) =>
            table.creatorAuthUserId.equals(action.creatorAuthUserId) &
            table.reporterAuthUserId.equals(account) &
            (table.createdAt > now.subtract(const Duration(days: 1))),
        transaction: transaction,
      );

      if (recentCount >= 20) {
        throw StateError('Please wait before reporting this creator again.');
      }

      final report = await ModerationCase.db.insertRow(
        session,
        ModerationCase(
          creatorAuthUserId: action.creatorAuthUserId,
          actionDefinitionId: actionDefinitionId,
          reporterAuthUserId: account,
          idempotencyKey: key,
          category: category,
          details: normalizedDetails,
          status: 'pendingReview',
          pauseActive: precautionaryPause,
          createdAt: now,
        ),
        transaction: transaction,
      );
      await _audit(
        session,
        report,
        account,
        'reportSubmitted',
        precautionaryPause
            ? 'Precautionary hold pending human review.'
            : 'Human review requested.',
        transaction,
      );

      return _status(report, isCreator: isCreator);
    });
  }

  /// A reporter or creator sees status, never staff notes or identities.
  Future<ModerationCaseStatusView> getStatus(
    Session session, {
    required UuidValue caseId,
  }) async {
    final account = requireGovernanceAccount(session);
    await AccountAccess.requireActive(session, account);
    final report = await ModerationCase.db.findById(session, caseId);

    if (report == null) throw StateError('Report was not found.');

    final isCreator = report.creatorAuthUserId == account;

    if (!isCreator && report.reporterAuthUserId != account) {
      throw StateError('Report was not found.');
    }

    return _status(report, isCreator: isCreator);
  }

  /// A bounded status list lets creators discover an appealable decision.
  Future<List<ModerationCaseStatusView>> listMine(
    Session session, {
    int limit = 30,
  }) async {
    final account = requireGovernanceAccount(session);
    await AccountAccess.requireActive(session, account);
    final reports = await ModerationCase.db.find(
      session,
      where: (table) =>
          table.reporterAuthUserId.equals(account) |
          table.creatorAuthUserId.equals(account),
      orderByList: (table) => [table.createdAt.desc(), table.id.desc()],
      limit: limit.clamp(1, 100),
    );

    return [
      for (final report in reports)
        _status(report, isCreator: report.creatorAuthUserId == account),
    ];
  }

  /// One timely creator appeal preserves the hold until independent staff act.
  Future<ModerationCaseStatusView> appeal(
    Session session, {
    required UuidValue caseId,
    required String reason,
  }) async {
    final account = requireGovernanceAccount(session);
    final normalizedReason = ModerationPolicy.text(reason);

    return DatabaseUtil.runInTransactionOrSavepoint(session.db, null, (
      transaction,
    ) async {
      await AccountAccess.requireActive(
        session,
        account,
        transaction: transaction,
      );
      final report = await _lockCase(session, caseId, transaction);

      if (!ModerationPolicy.canAppeal(
        isCreator: report.creatorAuthUserId == account,
        pauseActive: report.pauseActive,
        reviewedAt: report.reviewedAt,
        appealedAt: report.appealedAt,
        now: clock().toUtc(),
      )) {
        throw StateError('This decision is not available to appeal.');
      }

      final updated = await ModerationCase.db.updateRow(
        session,
        report.copyWith(
          status: 'appealPending',
          appealReason: normalizedReason,
          appealedAt: clock().toUtc(),
        ),
        transaction: transaction,
      );
      await _audit(
        session,
        updated,
        account,
        'appealSubmitted',
        'Creator requested independent staff review.',
        transaction,
      );

      return _status(updated, isCreator: true);
    });
  }

  /// Scope is checked here as well as on the endpoint; creators are not staff.
  Future<List<ModerationCaseStatusView>> listQueue(
    Session session, {
    int limit = 30,
  }) async {
    final reviewer = requireModerationStaff(session);
    await AccountAccess.requireActive(session, reviewer);
    final reports = await ModerationCase.db.find(
      session,
      where: (table) => table.status.inSet({'pendingReview', 'appealPending'}),
      orderBy: (table) => table.createdAt,
      limit: limit.clamp(1, 100),
    );

    return [for (final report in reports) _status(report)];
  }

  /// Raw report text and the audit trail stay on this staff-only surface.
  Future<ModerationCaseReviewView> getCase(
    Session session, {
    required UuidValue caseId,
  }) async {
    final reviewer = requireModerationStaff(session);
    await AccountAccess.requireActive(session, reviewer);
    final report = await ModerationCase.db.findById(session, caseId);

    if (report == null) throw StateError('Report was not found.');

    final entries = await ModerationAuditEntry.db.find(
      session,
      where: (table) => table.caseId.equals(caseId),
      orderBy: (table) => table.createdAt,
      limit: 100,
    );

    return ModerationCaseReviewView(
      status: _status(report),
      details: report.details,
      appealReason: report.appealReason,
      audit: [
        for (final entry in entries)
          ModerationAuditView(
            actorAuthUserId: entry.actorAuthUserId,
            event: entry.event,
            note: entry.note,
            pauseActive: entry.pauseActive,
            createdAt: entry.createdAt,
          ),
      ],
    );
  }

  /// Every decision updates only this case's hold in the audit transaction.
  Future<ModerationCaseStatusView> review(
    Session session, {
    required UuidValue caseId,
    required String decision,
    required String note,
  }) async {
    final reviewer = requireModerationStaff(session);
    final normalizedNote = ModerationPolicy.text(note, maximum: 500);

    if (decision != 'pause' && decision != 'dismiss') {
      throw ArgumentError('Choose pause or dismiss.');
    }

    return DatabaseUtil.runInTransactionOrSavepoint(session.db, null, (
      transaction,
    ) async {
      await AccountAccess.requireActive(
        session,
        reviewer,
        transaction: transaction,
      );
      final report = await _lockCase(session, caseId, transaction);
      ModerationPolicy.requireIndependentReviewer(
        reviewerId: reviewer.toString(),
        creatorId: report.creatorAuthUserId.toString(),
        reporterId: report.reporterAuthUserId?.toString(),
      );

      if (report.status != 'pendingReview') {
        throw StateError('This case has already been reviewed.');
      }

      final pause = decision == 'pause';
      final updated = await ModerationCase.db.updateRow(
        session,
        report.copyWith(
          status: pause ? 'paused' : 'dismissed',
          pauseActive: pause,
          reviewedAt: clock().toUtc(),
          reviewedByAuthUserId: reviewer,
        ),
        transaction: transaction,
      );
      await _audit(
        session,
        updated,
        reviewer,
        pause ? 'staffPaused' : 'staffDismissed',
        normalizedNote,
        transaction,
      );

      return _status(updated);
    });
  }

  /// Neither a creator nor the original reviewer can overturn a safety hold.
  Future<ModerationCaseStatusView> resolveAppeal(
    Session session, {
    required UuidValue caseId,
    required String decision,
    required String note,
  }) async {
    final reviewer = requireModerationStaff(session);
    final normalizedNote = ModerationPolicy.text(note, maximum: 500);

    if (decision != 'uphold' && decision != 'lift') {
      throw ArgumentError('Choose uphold or lift.');
    }

    return DatabaseUtil.runInTransactionOrSavepoint(session.db, null, (
      transaction,
    ) async {
      await AccountAccess.requireActive(
        session,
        reviewer,
        transaction: transaction,
      );
      final report = await _lockCase(session, caseId, transaction);
      ModerationPolicy.requireIndependentReviewer(
        reviewerId: reviewer.toString(),
        creatorId: report.creatorAuthUserId.toString(),
        reporterId: report.reporterAuthUserId?.toString(),
        originalReviewerId: report.reviewedByAuthUserId?.toString(),
      );

      if (report.status != 'appealPending' || report.appealResolvedAt != null) {
        throw StateError('This appeal is not awaiting review.');
      }

      final uphold = decision == 'uphold';
      final updated = await ModerationCase.db.updateRow(
        session,
        report.copyWith(
          status: uphold ? 'paused' : 'lifted',
          pauseActive: uphold,
          appealResolvedAt: clock().toUtc(),
        ),
        transaction: transaction,
      );
      await _audit(
        session,
        updated,
        reviewer,
        uphold ? 'appealUpheld' : 'appealLifted',
        normalizedNote,
        transaction,
      );

      return _status(updated);
    });
  }

  /// Takes the action-key lock every protected mutation takes, then the case.
  Future<ActionDefinition> _lockAction(
    Session session,
    UuidValue actionId,
    Transaction transaction,
  ) async {
    final action = await ActionDefinition.db.findById(
      session,
      actionId,
      transaction: transaction,
    );
    if (action == null) {
      throw StateError('This action is not available to report.');
    }
    await ActionKeyLock.acquire(
      session,
      creatorAuthUserId: action.creatorAuthUserId,
      actionKey: action.actionKey,
      transaction: transaction,
    );
    return action;
  }

  Future<ModerationCase> _lockCase(
    Session session,
    UuidValue caseId,
    Transaction transaction,
  ) async {
    final initial = await ModerationCase.db.findById(
      session,
      caseId,
      transaction: transaction,
    );

    if (initial == null) throw StateError('Report was not found.');

    await _lockAction(session, initial.actionDefinitionId, transaction);
    final report = await ModerationCase.db.findFirstRow(
      session,
      where: (table) => table.id.equals(caseId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );

    if (report == null) throw StateError('Report was not found.');

    return report;
  }

  Future<void> _audit(
    Session session,
    ModerationCase report,
    UuidValue actor,
    String event,
    String note,
    Transaction transaction,
  ) async {
    await ModerationAuditEntry.db.insertRow(
      session,
      ModerationAuditEntry(
        caseId: report.id!,
        actorAuthUserId: actor,
        event: event,
        note: note,
        pauseActive: report.pauseActive,
        createdAt: clock().toUtc(),
      ),
      transaction: transaction,
    );
  }

  ModerationCaseStatusView _status(
    ModerationCase report, {
    bool isCreator = false,
  }) => ModerationCaseStatusView(
    caseId: report.id!,
    actionDefinitionId: report.actionDefinitionId,
    category: report.category,
    status: report.status,
    pauseActive: report.pauseActive,
    createdAt: report.createdAt,
    canAppeal: ModerationPolicy.canAppeal(
      isCreator: isCreator,
      pauseActive: report.pauseActive,
      reviewedAt: report.reviewedAt,
      appealedAt: report.appealedAt,
      now: clock().toUtc(),
    ),
  );
}
