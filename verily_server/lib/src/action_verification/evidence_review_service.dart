import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/action_views.dart';
import 'package:verily_server/src/action_verification/public_reasons.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';

/// Verily's scoped human review of proof that a rule or model sent to a
/// person. Reviewers never decide their own proof, and every decision is an
/// appended record with the reviewer's account.
class EvidenceReviewService {
  EvidenceReviewService({
    ActionVerificationService? actions,
    RewardPayoutService? payouts,
    this._rewardConfiguration,
    DateTime Function()? clock,
  }) : actions = actions ?? ActionVerificationService(clock: clock),
       payouts = payouts ?? RewardPayoutService(clock: clock),
       clock = clock ?? (() => DateTime.now().toUtc());

  final ActionVerificationService actions;
  final RewardPayoutService payouts;
  final RewardConfiguration? _rewardConfiguration;
  final DateTime Function() clock;

  RewardConfiguration get rewardConfiguration =>
      _rewardConfiguration ?? RewardRuntime.current;

  Future<List<EvidenceReviewQueueItem>> listQueue(
    Session session, {
    required UuidValue reviewerAuthUserId,
    int limit = 30,
  }) async {
    final pendingEvidenceIds = await _pendingManualReviewEvidenceIds(
      session,
      reviewerAuthUserId: reviewerAuthUserId,
      limit: limit.clamp(1, 100),
    );
    if (pendingEvidenceIds.isEmpty) return const [];

    final evidenceRows = await ActionEvidence.db.find(
      session,
      where: (table) => table.id.inSet(pendingEvidenceIds),
      orderBy: (table) => table.submittedAt,
    );
    final decisions = await EvidenceDecision.db.find(
      session,
      where: (table) => table.evidenceId.inSet(pendingEvidenceIds),
      orderByList: (table) => [table.createdAt.desc(), table.id.desc()],
    );
    final latestByEvidence = <UuidValue, EvidenceDecision>{};
    for (final decision in decisions) {
      latestByEvidence.putIfAbsent(decision.evidenceId, () => decision);
    }
    final attempts = await ActionAttempt.db.find(
      session,
      where: (table) =>
          table.id.inSet(<UuidValue>{
            for (final row in evidenceRows) row.attemptId,
          }) &
          table.status.equals(ActionAttemptStatus.pendingReview),
    );
    final attemptsById = {for (final row in attempts) row.id!: row};
    final visible = [
      for (final row in evidenceRows)
        if (attemptsById.containsKey(row.attemptId)) row,
    ];
    if (visible.isEmpty) return const [];

    final actions = await ActionDefinition.db.find(
      session,
      where: (table) => table.id.inSet(<UuidValue>{
        for (final row in visible)
          attemptsById[row.attemptId]!.actionDefinitionId,
      }),
    );
    final actionsById = {for (final row in actions) row.id!: row};
    final requirements = await ActionRequirement.db.find(
      session,
      where: (table) => table.id.inSet(<UuidValue>{
        for (final row in visible) row.requirementId,
      }),
    );
    final requirementsById = {for (final row in requirements) row.id!: row};
    final names = await creatorDisplayNames(
      session,
      creatorIds: {for (final action in actions) action.creatorAuthUserId},
    );
    final pools = await _poolsFor(session, actions);
    final reviewerStorage =
        switch (session.serverpod.storage[evidenceStorageId]) {
          final EvidenceObjectAccess value => value,
          _ => null,
        };

    final queue = <EvidenceReviewQueueItem>[];
    for (final evidence in visible) {
      final attempt = attemptsById[evidence.attemptId]!;
      final action = actionsById[attempt.actionDefinitionId];
      final requirement = requirementsById[evidence.requirementId];
      final latest = latestByEvidence[evidence.id];
      if (action == null || requirement == null || latest == null) continue;
      final pool = latest.reasonCode == highValuePayoutReviewCode
          ? pools[(action.creatorAuthUserId, action.actionKey)]
          : null;
      queue.add(
        EvidenceReviewQueueItem(
          evidenceId: evidence.id!,
          attemptId: attempt.id!,
          actionDefinitionId: action.id!,
          creatorDisplayName:
              names[action.creatorAuthUserId] ?? anonymousCreatorName,
          actionTitle: action.title,
          requirementTitle: requirement.title,
          requirementKind: requirement.kind,
          mimeType: evidence.mimeType,
          byteLength: evidence.byteLength,
          durationSeconds: evidence.durationSeconds,
          capturedAt: evidence.capturedAt,
          submittedAt: evidence.submittedAt,
          reviewReasonCode: publicReviewReason(latest.reasonCode),
          reviewSummary: latest.summary,
          mediaUrl: await _mediaUrl(session, reviewerStorage, evidence),
          spokenChallengeWord: evidence.spokenChallengeWord,
          payoutReview: pool == null
              ? null
              : PayoutReviewView(
                  amountPerPayout: pool.amountPerPayout,
                  tokenSymbol: pool.tokenSymbol,
                  decimals: pool.decimals,
                  thresholdAtoms: rewardConfiguration.reviewThresholdAtoms,
                ),
        ),
      );
    }
    return queue;
  }

  Future<ActionAttemptView> review(
    Session session, {
    required UuidValue reviewerAuthUserId,
    required UuidValue evidenceId,
    required EvidenceDecisionStatus decision,
    required String note,
  }) async {
    if (decision != EvidenceDecisionStatus.accepted &&
        decision != EvidenceDecisionStatus.rejected) {
      throw ArgumentError.value(
        decision,
        'decision',
        'A review must accept or reject the evidence.',
      );
    }
    final normalizedNote = note.trim();
    if (normalizedNote.isEmpty || normalizedNote.length > 500) {
      throw ArgumentError.value(
        note,
        'note',
        'Add a review note of 500 characters or fewer.',
      );
    }

    final result = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final evidence = await ActionEvidence.db.findById(
          session,
          evidenceId,
          transaction: transaction,
        );
        if (evidence == null) throw StateError('Evidence was not found.');
        final initialAttempt = await ActionAttempt.db.findById(
          session,
          evidence.attemptId,
          transaction: transaction,
        );
        if (initialAttempt == null) {
          throw StateError('This evidence is no longer awaiting review.');
        }
        if (initialAttempt.participantAuthUserId == reviewerAuthUserId) {
          throw StateError('Reviewers cannot decide their own evidence.');
        }
        await AccountAccess.requireActive(
          session,
          initialAttempt.participantAuthUserId,
          transaction: transaction,
        );
        final lockedAttempt = await ActionAttempt.db.findFirstRow(
          session,
          where: (table) => table.id.equals(evidence.attemptId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (lockedAttempt == null ||
            lockedAttempt.status != ActionAttemptStatus.pendingReview) {
          throw StateError('This evidence is no longer awaiting review.');
        }
        final latest = await latestDecision(
          session,
          evidenceId: evidenceId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (latest == null ||
            latest.status != EvidenceDecisionStatus.manualReview) {
          throw StateError('This evidence is no longer awaiting review.');
        }
        await EvidenceDecision.db.insertRow(
          session,
          EvidenceDecision(
            evidenceId: evidenceId,
            status: decision,
            verifierType: 'human-review',
            confidence: decision == EvidenceDecisionStatus.accepted ? 1 : 0,
            reasonCode: decision == EvidenceDecisionStatus.accepted
                ? 'manual_review_accepted'
                : 'manual_review_rejected',
            summary: normalizedNote,
            reviewedByAuthUserId: reviewerAuthUserId,
            createdAt: clock().toUtc(),
          ),
          transaction: transaction,
        );
        return actions.completeAttempt(
          session,
          authUserId: lockedAttempt.participantAuthUserId,
          attemptId: lockedAttempt.id!,
          enclosingTransaction: transaction,
        );
      },
    );
    await payouts.scheduleForAttempt(session, attemptId: result.id);
    return result;
  }

  /// Selects from the latest decision for every evidence row in PostgreSQL,
  /// so an old pending review never disappears behind newer decisions.
  Future<Set<UuidValue>> _pendingManualReviewEvidenceIds(
    Session session, {
    required UuidValue reviewerAuthUserId,
    required int limit,
  }) async {
    final rows = await session.db.unsafeQuery(
      '''
SELECT e."id"::text
FROM "verily_action_evidence" AS e
JOIN "verily_action_attempt" AS a ON a."id" = e."attemptId"
JOIN LATERAL (
  SELECT d."status"
  FROM "verily_evidence_decision" AS d
  WHERE d."evidenceId" = e."id"
  ORDER BY d."createdAt" DESC, d."id" DESC
  LIMIT 1
) AS latest ON latest."status" = @manualReviewStatus
WHERE a."status" = @pendingReviewStatus
  AND a."participantAuthUserId" <> CAST(@reviewerAuthUserId AS uuid)
ORDER BY e."submittedAt"
LIMIT @limit;
''',
      parameters: QueryParameters.named({
        'manualReviewStatus': EvidenceDecisionStatus.manualReview.name,
        'pendingReviewStatus': ActionAttemptStatus.pendingReview.name,
        'reviewerAuthUserId': reviewerAuthUserId.toString(),
        'limit': limit,
      }),
    );
    return {for (final row in rows) UuidValue.fromString(row[0]! as String)};
  }

  Future<Map<(UuidValue, String), RewardPool>> _poolsFor(
    Session session,
    List<ActionDefinition> actions,
  ) async {
    final pools = await RewardPool.db.find(
      session,
      where: (table) =>
          table.creatorAuthUserId.inSet({
            for (final action in actions) action.creatorAuthUserId,
          }) &
          table.actionKey.inSet({
            for (final action in actions) action.actionKey,
          }),
    );
    return {
      for (final pool in pools) (pool.creatorAuthUserId, pool.actionKey): pool,
    };
  }
}

/// A short-lived private link to the pinned version of [evidence], or null
/// for proof without stored media.
Future<String?> _mediaUrl(
  Session session,
  EvidenceObjectAccess? storage,
  ActionEvidence evidence,
) async {
  final path = evidence.storagePath;
  final versionId = evidence.storageVersionId;
  if (storage == null || path == null || versionId == null) return null;
  return (await storage.createReviewUrl(
    session,
    path,
    versionId: versionId,
  )).toString();
}

/// Shared with the appeal flow, which shows creators the same private link.
Future<String?> evidenceReviewUrl(Session session, ActionEvidence evidence) {
  final storage = switch (session.serverpod.storage[evidenceStorageId]) {
    final EvidenceObjectAccess value => value,
    _ => null,
  };
  return _mediaUrl(session, storage, evidence);
}
