import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/action_verification/action_period.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';
import 'package:verily_server/src/action_verification/public_reasons.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_pool_service.dart';

/// Reason code on an attempt held because its payout needs a person.
const highValuePayoutReviewCode = 'high_value_payout_review';

/// Shown when a creator has no profile name. Never an email or account id.
const anonymousCreatorName = 'A Verily creator';

/// Builds participant- and creator-facing action views in bounded queries.
class ActionViews {
  ActionViews({RewardPoolService? rewardPools, DateTime Function()? clock})
    : rewardPools = rewardPools ?? RewardPoolService(),
      clock = clock ?? (() => DateTime.now().toUtc());

  final RewardPoolService rewardPools;
  final DateTime Function() clock;

  Future<ActionOpportunity> opportunity(
    Session session, {
    required ActionDefinition action,
    required UuidValue viewerAuthUserId,
  }) async {
    return (await opportunities(
      session,
      actions: [action],
      viewerAuthUserId: viewerAuthUserId,
    )).single;
  }

  Future<List<ActionOpportunity>> opportunities(
    Session session, {
    required List<ActionDefinition> actions,
    required UuidValue viewerAuthUserId,
  }) async {
    if (actions.isEmpty) return const [];
    final actionIds = {for (final action in actions) action.id!};
    final requirements = await ActionRequirement.db.find(
      session,
      where: (table) => table.actionDefinitionId.inSet(actionIds),
    );
    final requirementIds = {
      for (final requirement in requirements) requirement.id!,
    };
    final locationRules = requirementIds.isEmpty
        ? const <ActionLocationRule>[]
        : await ActionLocationRule.db.find(
            session,
            where: (table) => table.requirementId.inSet(requirementIds),
          );
    final mediaRules = requirementIds.isEmpty
        ? const <ActionMediaRule>[]
        : await ActionMediaRule.db.find(
            session,
            where: (table) => table.requirementId.inSet(requirementIds),
          );
    final motionRules = requirementIds.isEmpty
        ? const <ActionMotionRule>[]
        : await ActionMotionRule.db.find(
            session,
            where: (table) => table.requirementId.inSet(requirementIds),
          );
    final externalRules = requirementIds.isEmpty
        ? const <ActionExternalRule>[]
        : await ActionExternalRule.db.find(
            session,
            where: (table) => table.requirementId.inSet(requirementIds),
          );
    // Venue secrets are never shown; creators only learn one is stored.
    final creatorRequirementIds = <UuidValue>{
      for (final requirement in requirements)
        if (actions.any(
          (action) =>
              action.id == requirement.actionDefinitionId &&
              action.creatorAuthUserId == viewerAuthUserId,
        ))
          requirement.id!,
    };
    final qrRules = creatorRequirementIds.isEmpty
        ? const <ActionQrRule>[]
        : await ActionQrRule.db.find(
            session,
            where: (table) => table.requirementId.inSet(creatorRequirementIds),
          );
    final venueCodeRequirementIds = {
      for (final rule in qrRules) rule.requirementId,
    };
    final appIds = {for (final rule in externalRules) rule.appId};
    final apps = appIds.isEmpty
        ? const <VerilyApp>[]
        : await VerilyApp.db.find(
            session,
            where: (table) => table.id.inSet(appIds),
          );

    final now = clock();
    final periodKeyByAction = {
      for (final action in actions)
        action.id!: actionPeriodKey(action.recurrence, action.timeZone, now),
    };
    final attempts = await ActionAttempt.db.find(
      session,
      where: (table) =>
          table.actionDefinitionId.inSet(actionIds) &
          table.participantAuthUserId.equals(viewerAuthUserId) &
          table.periodKey.inSet(periodKeyByAction.values.toSet()),
    );
    final attemptIds = {for (final attempt in attempts) attempt.id!};
    final payouts = await payoutsByAttempt(session, attemptIds: attemptIds);
    final accepted = await acceptedRequirementIds(
      session,
      attemptIds: attemptIds,
    );
    final rewards = await rewardPools.summaries(
      session,
      actions: actions,
      viewerAuthUserId: viewerAuthUserId,
    );
    final names = await creatorDisplayNames(
      session,
      creatorIds: {for (final action in actions) action.creatorAuthUserId},
    );

    final requirementsByAction = <UuidValue, List<ActionRequirement>>{};
    for (final requirement in requirements) {
      requirementsByAction
          .putIfAbsent(requirement.actionDefinitionId, () => [])
          .add(requirement);
    }
    for (final items in requirementsByAction.values) {
      items.sort((left, right) => left.position.compareTo(right.position));
    }
    final locationByRequirement = {
      for (final rule in locationRules) rule.requirementId: rule,
    };
    final mediaByRequirement = {
      for (final rule in mediaRules) rule.requirementId: rule,
    };
    final motionByRequirement = {
      for (final rule in motionRules) rule.requirementId: rule,
    };
    final appById = {for (final app in apps) app.id!: app};
    final appByRequirement = {
      for (final rule in externalRules)
        rule.requirementId: ?appById[rule.appId],
    };
    final externalByRequirement = {
      for (final rule in externalRules) rule.requirementId: rule,
    };
    final attemptByAction = {
      for (final attempt in attempts)
        if (attempt.periodKey == periodKeyByAction[attempt.actionDefinitionId])
          attempt.actionDefinitionId: attempt,
    };

    return [
      for (final action in actions)
        ActionOpportunity(
          id: action.id!,
          creatorDisplayName:
              names[action.creatorAuthUserId] ?? anonymousCreatorName,
          viewerIsCreator: action.creatorAuthUserId == viewerAuthUserId,
          actionKey: action.actionKey,
          revision: action.revision,
          status: action.status,
          title: action.title,
          description: action.description,
          recurrence: action.recurrence,
          timeZone: action.timeZone,
          maxVerifiedCompletions: action.maxVerifiedCompletions,
          verifiedCompletions: action.verifiedCompletions,
          opensAt: action.opensAt,
          closesAt: action.closesAt,
          publishedAt: action.publishedAt,
          updatedAt: action.updatedAt,
          requirements: [
            for (final requirement
                in requirementsByAction[action.id] ??
                    const <ActionRequirement>[])
              requirementView(
                requirement,
                location: locationByRequirement[requirement.id],
                media: mediaByRequirement[requirement.id],
                motion: motionByRequirement[requirement.id],
                app: appByRequirement[requirement.id],
                external: externalByRequirement[requirement.id],
                creatorView: action.creatorAuthUserId == viewerAuthUserId,
                venueCodeConfigured: venueCodeRequirementIds.contains(
                  requirement.id,
                ),
              ),
          ],
          myAttempt: switch (attemptByAction[action.id]) {
            final attempt? => attemptView(
              attempt,
              action: action,
              payout: payouts[attempt.id],
              acceptedRequirementIds: accepted[attempt.id] ?? const [],
            ),
            null => null,
          },
          reward: rewards[action.id],
        ),
    ];
  }

  /// The won payout of each attempt in [attemptIds].
  Future<Map<UuidValue, RewardPayout>> payoutsByAttempt(
    Session session, {
    required Set<UuidValue> attemptIds,
  }) async {
    if (attemptIds.isEmpty) return const {};
    final payouts = await RewardPayout.db.find(
      session,
      where: (table) => table.attemptId.inSet(attemptIds),
    );
    return {for (final payout in payouts) payout.attemptId: payout};
  }

  /// Requirement ids whose latest append-only decision is `accepted`, per
  /// attempt, in one bounded query.
  Future<Map<UuidValue, List<UuidValue>>> acceptedRequirementIds(
    Session session, {
    required Set<UuidValue> attemptIds,
  }) async {
    if (attemptIds.isEmpty) return const {};
    final rows = await session.db.unsafeQuery(
      '''
SELECT e."attemptId"::text, e."requirementId"::text
FROM "verily_action_evidence" AS e
JOIN LATERAL (
  SELECT d."status"
  FROM "verily_evidence_decision" AS d
  WHERE d."evidenceId" = e."id"
  ORDER BY d."createdAt" DESC, d."id" DESC
  LIMIT 1
) AS latest ON latest."status" = @acceptedStatus
WHERE e."attemptId" = ANY(CAST(@attemptIds AS uuid[]));
''',
      parameters: QueryParameters.named({
        'acceptedStatus': EvidenceDecisionStatus.accepted.name,
        'attemptIds': [for (final id in attemptIds) id.toString()],
      }),
    );
    final accepted = <UuidValue, List<UuidValue>>{};
    for (final row in rows) {
      accepted
          .putIfAbsent(UuidValue.withValidation(row[0]! as String), () => [])
          .add(UuidValue.withValidation(row[1]! as String));
    }
    return accepted;
  }
}

/// Public creator names: the profile's user name or full name, never an
/// email address or account id.
Future<Map<UuidValue, String>> creatorDisplayNames(
  Session session, {
  required Set<UuidValue> creatorIds,
}) async {
  if (creatorIds.isEmpty) return const {};
  final profiles = await UserProfile.db.find(
    session,
    where: (table) => table.authUserId.inSet(creatorIds),
  );
  return {
    for (final profile in profiles) profile.authUserId: ?_displayName(profile),
  };
}

String? _displayName(UserProfile profile) {
  for (final candidate in [profile.userName, profile.fullName]) {
    final trimmed = candidate?.trim();
    if (trimmed != null && trimmed.isNotEmpty && !trimmed.contains('@')) {
      return trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed;
    }
  }
  return null;
}

ActionRequirementView requirementView(
  ActionRequirement requirement, {
  ActionLocationRule? location,
  ActionMediaRule? media,
  ActionMotionRule? motion,
  VerilyApp? app,
  ActionExternalRule? external,
  bool creatorView = false,
  bool venueCodeConfigured = false,
}) {
  final mediaKind = mediaKindOf(requirement.kind);
  return ActionRequirementView(
    id: requirement.id!,
    requirementKey: requirement.requirementKey,
    kind: requirement.kind,
    title: requirement.title,
    instructions: requirement.instructions,
    position: requirement.position,
    isRequired: requirement.isRequired,
    latitude: location?.location.latitude,
    longitude: location?.location.longitude,
    radiusMeters: location?.radiusMeters,
    maxAccuracyMeters: location?.maxAccuracyMeters,
    minDurationSeconds: media?.minDurationSeconds ?? motion?.minDurationSeconds,
    maxDurationSeconds: media?.maxDurationSeconds ?? motion?.maxDurationSeconds,
    verificationPolicy: media?.verificationPolicy,
    verificationPrompt: creatorView ? creatorWrittenPrompt(media) : null,
    minConfidence: creatorView ? media?.minConfidence : null,
    venueCodeConfigured:
        creatorView && requirement.kind == ActionRequirementKind.qrCode
        ? venueCodeConfigured
        : null,
    spokenChallengeRequired: media?.spokenChallengeRequired ?? false,
    acceptedContentTypes: mediaKind == null
        ? null
        : acceptedContentTypesFor(mediaKind),
    maxByteLength: mediaKind == null ? null : maxEvidenceBytesFor(mediaKind),
    movementKind: media?.movementKind,
    motionType: motion?.motionType,
    motionAxis: motion?.axis,
    targetRepetitions: motion?.targetRepetitions ?? media?.targetRepetitions,
    minAngularSpeedRadiansPerSecond: motion?.minAngularSpeedRadiansPerSecond,
    maxAngularSpeedRadiansPerSecond: motion?.maxAngularSpeedRadiansPerSecond,
    minAxisDominance: motion?.minAxisDominance,
    minFreeFallMilliseconds: motion?.minFreeFallMilliseconds,
    maxFreeFallMilliseconds: motion?.maxFreeFallMilliseconds,
    minPeakAccelerationMetersPerSecondSquared:
        motion?.minPeakAccelerationMetersPerSecondSquared,
    maxPeakAccelerationMetersPerSecondSquared:
        motion?.maxPeakAccelerationMetersPerSecondSquared,
    appId: app?.id,
    appName: app?.name,
    appAvailable: app == null ? null : app.status == VerilyAppStatus.active,
    appVerificationMode: external?.verificationMode,
    localCheck: switch (media) {
      ActionMediaRule(
        localCheckTask: final task?,
        localCheckLabel: final label?,
        localCheckMinScore: final minScore?,
        localCheckMinFrames: final minFrames?,
      ) =>
        ActionLocalCheck(
          task: task,
          label: label,
          minScore: minScore,
          minFrames: minFrames,
        ),
      _ => null,
    },
    localCheckModel: switch (media?.localCheckTask) {
      final task? => LocalCheckModel.forTask(task).view,
      null => null,
    },
  );
}

/// [attemptView] with its action loaded, for single attempts returned to the
/// app.
Future<ActionAttemptView> attemptViewWithAction(
  Session session,
  ActionAttempt attempt, {
  RewardPayout? payout,
  Transaction? transaction,
}) async {
  final action = await ActionDefinition.db.findById(
    session,
    attempt.actionDefinitionId,
    transaction: transaction,
  );
  return attemptView(attempt, payout: payout, action: action);
}

/// The app-facing attempt. [action] fills its title and key; the reason is
/// always a public code (see `public_reasons.dart`).
ActionAttemptView attemptView(
  ActionAttempt attempt, {
  RewardPayout? payout,
  ActionDefinition? action,
  List<UuidValue>? acceptedRequirementIds,
}) {
  return ActionAttemptView(
    id: attempt.id!,
    actionDefinitionId: attempt.actionDefinitionId,
    actionTitle: action?.title,
    actionKey: action?.actionKey,
    periodKey: attempt.periodKey,
    status: attempt.status,
    verificationScore: attempt.verificationScore,
    verifiedRank: attempt.verifiedRank,
    rejectionCode: publicAttemptReason(attempt),
    startedAt: attempt.startedAt,
    submittedAt: attempt.submittedAt,
    verifiedAt: attempt.verifiedAt,
    updatedAt: attempt.updatedAt,
    rewardOutcome: attempt.rewardOutcome,
    payoutStatus: payout?.status,
    acceptedRequirementIds: acceptedRequirementIds,
    rewardValueReview:
        attempt.status == ActionAttemptStatus.pendingReview &&
        attempt.rejectionCode == highValuePayoutReviewCode,
  );
}

/// The verifier text a creator wrote, or null when the server wrote it (a
/// tracked movement, or a local check without creator text), so saving the
/// view back as a draft reproduces the stored rule exactly.
String? creatorWrittenPrompt(ActionMediaRule? media) {
  if (media == null || media.movementKind != null) return null;
  final check = switch (media) {
    ActionMediaRule(
      localCheckTask: final task?,
      localCheckLabel: final label?,
      localCheckMinScore: final minScore?,
      localCheckMinFrames: final minFrames?,
    ) =>
      ActionLocalCheck(
        task: task,
        label: label,
        minScore: minScore,
        minFrames: minFrames,
      ),
    _ => null,
  };
  if (check != null &&
      media.verificationPrompt == localCheckVerificationPrompt(check)) {
    return null;
  }
  return media.verificationPrompt;
}
