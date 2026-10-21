// Generated copyWith methods use null to clear nullable persisted fields.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:convert';
import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/action_key_lock.dart';
import 'package:verily_server/src/action_verification/action_period.dart';
import 'package:verily_server/src/action_verification/action_requirement_rules.dart';
import 'package:verily_server/src/action_verification/action_views.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/moderation/moderation_gate.dart';
import 'package:verily_server/src/rewards/reward_pool_service.dart';
import 'package:verily_server/src/security/secret_digest.dart';

/// Prefix of rotating venue codes. Pinned by the venue-code check below.
const venueCodePrefix = 'verily:v1:';

/// A creator's lifecycle for their own actions: drafts, immutable published
/// revisions, preview, publication, pausing, and rotating venue codes.
///
/// Ownership is `id == actionId & creatorAuthUserId == authUserId` on every
/// call; hiding a screen is not access control. Every write to one action key
/// runs under that key's [ActionKeyLock].
class ActionAuthoringService {
  ActionAuthoringService({
    ModerationGate? moderationGate,
    RewardPoolService? rewardPools,
    ActionViews? views,
    DateTime Function()? clock,
    math.Random? random,
  }) : clock = clock ?? (() => DateTime.now().toUtc()),
       moderationGate = moderationGate ?? const ModerationGate(),
       rewardPools = rewardPools ?? RewardPoolService(clock: clock),
       views = views ?? ActionViews(clock: clock),
       _random = random ?? math.Random.secure();

  final DateTime Function() clock;
  final ModerationGate moderationGate;
  final RewardPoolService rewardPools;
  final ActionViews views;
  final math.Random _random;

  /// Creates and immediately publishes an action without a reward. A
  /// rewarded action is saved as a draft, funded, then published.
  Future<ActionOpportunity> createAction(
    Session session, {
    required UuidValue authUserId,
    required CreateActionDefinitionRequest request,
  }) {
    if (request.reward != null) {
      throw ActionAuthoringException(
        reason: ActionAuthoringProblem.rewardNeedsDraft,
        message: 'Save a rewarded action as a draft and fund it first.',
      );
    }
    return _store(
      session,
      authUserId: authUserId,
      request: request,
      asDraft: false,
    );
  }

  /// Persists a private draft: updates the latest draft revision when there
  /// is one, and creates the next immutable revision after publication.
  Future<ActionOpportunity> saveActionDraft(
    Session session, {
    required UuidValue authUserId,
    required CreateActionDefinitionRequest request,
  }) {
    return _store(
      session,
      authUserId: authUserId,
      request: request,
      asDraft: true,
    );
  }

  /// Like [saveActionDraft], inside the caller's [transaction], for server
  /// callers (the App API) that lock and check more in the same
  /// transaction. Returns the stored revision; build any view after commit.
  Future<ActionDefinition> saveActionDraftIn(
    Session session, {
    required UuidValue authUserId,
    required CreateActionDefinitionRequest request,
    required Transaction transaction,
  }) {
    return _storeDefinition(
      session,
      authUserId: authUserId,
      request: request,
      asDraft: true,
      transaction: transaction,
    );
  }

  Future<ActionOpportunity> _store(
    Session session, {
    required UuidValue authUserId,
    required CreateActionDefinitionRequest request,
    required bool asDraft,
  }) async {
    final action = await _storeDefinition(
      session,
      authUserId: authUserId,
      request: request,
      asDraft: asDraft,
    );
    return views.opportunity(
      session,
      action: action,
      viewerAuthUserId: authUserId,
    );
  }

  Future<ActionDefinition> _storeDefinition(
    Session session, {
    required UuidValue authUserId,
    required CreateActionDefinitionRequest request,
    required bool asDraft,
    Transaction? transaction,
  }) async {
    final now = clock().toUtc();
    final input = _validatedRequest(request, now);
    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      transaction,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        await ActionKeyLock.acquire(
          session,
          creatorAuthUserId: authUserId,
          actionKey: input.actionKey,
          transaction: transaction,
        );
        await _assertAppsUsable(
          session,
          creatorAuthUserId: authUserId,
          appIds: [
            for (final requirement in input.requirements)
              ?requirement.draft.appId,
          ],
          transaction: transaction,
        );
        final latest = await ActionDefinition.db.findFirstRow(
          session,
          where: (table) =>
              table.creatorAuthUserId.equals(authUserId) &
              table.actionKey.equals(input.actionKey),
          orderBy: (table) => table.revision.desc(),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (!asDraft && latest != null) {
          throw ActionAuthoringException(
            reason: ActionAuthoringProblem.actionKeyTaken,
            message: 'You already use that action key.',
          );
        }

        final reusableDraft =
            asDraft && latest?.status == ActionDefinitionStatus.draft
            ? latest
            : null;
        final action = reusableDraft == null
            ? await ActionDefinition.db.insertRow(
                session,
                ActionDefinition(
                  creatorAuthUserId: authUserId,
                  actionKey: input.actionKey,
                  revision: (latest?.revision ?? 0) + 1,
                  title: input.title,
                  description: input.description,
                  status: asDraft
                      ? ActionDefinitionStatus.draft
                      : ActionDefinitionStatus.active,
                  recurrence: request.recurrence,
                  timeZone: input.timeZone,
                  maxVerifiedCompletions: request.maxVerifiedCompletions,
                  opensAt: request.opensAt?.toUtc(),
                  closesAt: request.closesAt?.toUtc(),
                  publishedAt: asDraft ? null : now,
                  createdAt: now,
                  updatedAt: now,
                ),
                transaction: transaction,
              )
            : await ActionDefinition.db.updateRow(
                session,
                reusableDraft.copyWith(
                  title: input.title,
                  description: input.description,
                  recurrence: request.recurrence,
                  timeZone: input.timeZone,
                  maxVerifiedCompletions: request.maxVerifiedCompletions,
                  opensAt: request.opensAt?.toUtc(),
                  closesAt: request.closesAt?.toUtc(),
                  pausedAt: null,
                  updatedAt: now,
                ),
                transaction: transaction,
              );
        final actionId = action.id!;
        if (!asDraft) {
          await moderationGate.assertActionAllowed(
            session,
            actionId: actionId,
            transaction: transaction,
          );
        }
        if (reusableDraft != null) {
          await ActionRequirement.db.deleteWhere(
            session,
            where: (table) => table.actionDefinitionId.equals(actionId),
            transaction: transaction,
          );
        }
        for (final item in input.requirements) {
          final requirement = await ActionRequirement.db.insertRow(
            session,
            ActionRequirement(
              actionDefinitionId: actionId,
              requirementKey: item.key,
              kind: item.draft.kind,
              title: item.title,
              instructions: item.instructions,
              position: item.position,
              isRequired: item.draft.isRequired,
            ),
            transaction: transaction,
          );
          await insertRequirementRule(
            session,
            requirement.id!,
            item,
            transaction,
          );
        }
        await rewardPools.applyDraftTerms(
          session,
          creatorAuthUserId: authUserId,
          actionKey: input.actionKey,
          terms: input.reward,
          now: now,
          transaction: transaction,
        );
        return action;
      },
    );
  }

  Future<ActionOpportunity> previewAction(
    Session session, {
    required UuidValue authUserId,
    required UuidValue actionId,
  }) async {
    final action = await _ownedAction(
      session,
      authUserId: authUserId,
      actionId: actionId,
    );
    return views.opportunity(
      session,
      action: action,
      viewerAuthUserId: authUserId,
    );
  }

  /// The latest revision of each of the creator's action keys.
  Future<List<ActionOpportunity>> listOwnedActions(
    Session session, {
    required UuidValue authUserId,
    int limit = 50,
  }) async {
    final definitions = await ActionDefinition.db.find(
      session,
      // Verification-request actions belong to their request, not the list.
      where: (table) =>
          table.creatorAuthUserId.equals(authUserId) &
          table.visibility.equals(ActionVisibility.public),
      orderBy: (table) => table.updatedAt.desc(),
      limit: 500,
    );
    final latestByKey = <String, ActionDefinition>{};
    for (final definition in definitions) {
      final current = latestByKey[definition.actionKey];
      if (current == null || definition.revision > current.revision) {
        latestByKey[definition.actionKey] = definition;
      }
    }
    final latest = latestByKey.values.toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return views.opportunities(
      session,
      actions: latest.take(limit.clamp(1, 100)).toList(),
      viewerAuthUserId: authUserId,
    );
  }

  Future<ActionOpportunity> publishAction(
    Session session, {
    required UuidValue authUserId,
    required UuidValue actionId,
    required int expectedRevision,
  }) {
    return _setPublication(
      session,
      authUserId: authUserId,
      actionId: actionId,
      expectedRevision: expectedRevision,
      publish: true,
    );
  }

  Future<ActionOpportunity> pauseAction(
    Session session, {
    required UuidValue authUserId,
    required UuidValue actionId,
    required int expectedRevision,
  }) {
    return _setPublication(
      session,
      authUserId: authUserId,
      actionId: actionId,
      expectedRevision: expectedRevision,
      publish: false,
    );
  }

  /// Publishes ([publish]) or pauses inside the caller's [transaction], for
  /// server callers such as the App API. Returns the updated revision; build
  /// any view after commit.
  Future<ActionDefinition> setPublicationIn(
    Session session, {
    required UuidValue authUserId,
    required UuidValue actionId,
    required int expectedRevision,
    required bool publish,
    required Transaction transaction,
  }) {
    return _setPublicationDefinition(
      session,
      authUserId: authUserId,
      actionId: actionId,
      expectedRevision: expectedRevision,
      publish: publish,
      transaction: transaction,
    );
  }

  Future<ActionOpportunity> _setPublication(
    Session session, {
    required UuidValue authUserId,
    required UuidValue actionId,
    required int expectedRevision,
    required bool publish,
  }) async {
    final result = await _setPublicationDefinition(
      session,
      authUserId: authUserId,
      actionId: actionId,
      expectedRevision: expectedRevision,
      publish: publish,
    );
    return views.opportunity(
      session,
      action: result,
      viewerAuthUserId: authUserId,
    );
  }

  Future<ActionDefinition> _setPublicationDefinition(
    Session session, {
    required UuidValue authUserId,
    required UuidValue actionId,
    required int expectedRevision,
    required bool publish,
    Transaction? transaction,
  }) async {
    final now = clock().toUtc();
    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      transaction,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final owned = await _ownedAction(
          session,
          authUserId: authUserId,
          actionId: actionId,
          transaction: transaction,
        );
        await ActionKeyLock.acquire(
          session,
          creatorAuthUserId: authUserId,
          actionKey: owned.actionKey,
          transaction: transaction,
        );
        final action = await ActionDefinition.db.findFirstRow(
          session,
          where: (table) => table.id.equals(actionId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (action == null || action.revision != expectedRevision) {
          throw StateError('This action changed. Refresh before continuing.');
        }

        if (!publish) {
          if (action.status != ActionDefinitionStatus.active) {
            throw StateError('Only a live action can be paused.');
          }
          return ActionDefinition.db.updateRow(
            session,
            action.copyWith(
              status: ActionDefinitionStatus.paused,
              pausedAt: now,
              updatedAt: now,
            ),
            transaction: transaction,
          );
        }

        await moderationGate.assertActionAllowed(
          session,
          actionId: actionId,
          transaction: transaction,
        );
        if (action.status == ActionDefinitionStatus.completed) {
          throw StateError('A completed revision cannot be published again.');
        }
        await _assertBoundAppsActive(
          session,
          action: action,
          transaction: transaction,
        );
        await rewardPools.assertPublishable(
          session,
          creatorAuthUserId: authUserId,
          actionKey: action.actionKey,
          transaction: transaction,
        );
        final activeRevisions = await ActionDefinition.db.find(
          session,
          where: (table) =>
              table.creatorAuthUserId.equals(authUserId) &
              table.actionKey.equals(action.actionKey) &
              table.status.equals(ActionDefinitionStatus.active),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        for (final active in activeRevisions) {
          if (active.id == action.id) continue;
          await ActionDefinition.db.updateRow(
            session,
            active.copyWith(
              status: ActionDefinitionStatus.completed,
              updatedAt: now,
            ),
            transaction: transaction,
          );
        }
        if (action.status == ActionDefinitionStatus.active) return action;
        return ActionDefinition.db.updateRow(
          session,
          action.copyWith(
            status: ActionDefinitionStatus.active,
            publishedAt: action.publishedAt ?? now,
            pausedAt: null,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
  }

  /// Creates a short-lived, single-use venue code for a live QR action.
  Future<ActionQrChallengeView> createQrChallenge(
    Session session, {
    required UuidValue authUserId,
    required UuidValue requirementId,
    int validitySeconds = 300,
  }) async {
    if (validitySeconds < 30 || validitySeconds > 900) {
      throw ArgumentError.value(
        validitySeconds,
        'validitySeconds',
        'Venue codes must last between 30 seconds and 15 minutes.',
      );
    }
    final requirement = await ActionRequirement.db.findById(
      session,
      requirementId,
    );
    if (requirement == null ||
        requirement.kind != ActionRequirementKind.qrCode) {
      throw StateError('The venue code requirement was not found.');
    }
    final action = await _ownedAction(
      session,
      authUserId: authUserId,
      actionId: requirement.actionDefinitionId,
    );
    final now = clock().toUtc();
    if (action.status != ActionDefinitionStatus.active ||
        (action.opensAt?.isAfter(now) ?? false) ||
        !(action.closesAt?.isAfter(now) ?? true)) {
      throw StateError('Publish this action before showing its venue code.');
    }

    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    final code =
        '$venueCodePrefix${base64Url.encode(bytes).replaceAll('=', '')}';
    final expiresAt = now.add(Duration(seconds: validitySeconds));
    await ActionQrChallenge.db.insertRow(
      session,
      ActionQrChallenge(
        requirementId: requirementId,
        createdByAuthUserId: authUserId,
        secretHash: secretSha256Hex(code),
        expiresAt: expiresAt,
        createdAt: now,
      ),
    );
    return ActionQrChallengeView(code: code, expiresAt: expiresAt);
  }

  Future<ActionDefinition> _ownedAction(
    Session session, {
    required UuidValue authUserId,
    required UuidValue actionId,
    Transaction? transaction,
  }) async {
    final action = await ActionDefinition.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(actionId) &
          table.creatorAuthUserId.equals(authUserId),
      transaction: transaction,
    );
    if (action == null) {
      throw StateError('Only the creator can manage this action.');
    }
    return action;
  }

  /// External requirements may only name this creator's active Apps, each
  /// at most once per action, so a confirmation maps to one requirement.
  Future<void> _assertAppsUsable(
    Session session, {
    required UuidValue creatorAuthUserId,
    required List<UuidValue> appIds,
    required Transaction transaction,
  }) async {
    if (appIds.isEmpty) return;
    final unique = appIds.toSet();
    if (unique.length != appIds.length) {
      throw ArgumentError('Each app can confirm only one proof in an action.');
    }
    final apps = await VerilyApp.db.find(
      session,
      where: (table) =>
          table.id.inSet(unique) &
          table.creatorAuthUserId.equals(creatorAuthUserId) &
          table.status.equals(VerilyAppStatus.active),
      transaction: transaction,
    );
    if (apps.length != unique.length) {
      throw ActionAuthoringException(
        reason: ActionAuthoringProblem.appUnavailable,
        message: 'Choose one of your active apps.',
      );
    }
  }

  /// Publication re-checks bindings saved with a draft: an App revoked after
  /// the save must not go live, and App confirmations still may not be mixed
  /// with phone proof.
  Future<void> _assertBoundAppsActive(
    Session session, {
    required ActionDefinition action,
    required Transaction transaction,
  }) async {
    final requirements = await ActionRequirement.db.find(
      session,
      where: (table) => table.actionDefinitionId.equals(action.id),
      transaction: transaction,
    );
    assertExternalProofNotMixed([
      for (final requirement in requirements) requirement.kind,
    ]);
    final external = [
      for (final requirement in requirements)
        if (requirement.kind == ActionRequirementKind.externalApp) requirement,
    ];
    if (external.isEmpty) return;
    final rules = await ActionExternalRule.db.find(
      session,
      where: (table) => table.requirementId.inSet({
        for (final requirement in external) requirement.id!,
      }),
      transaction: transaction,
    );
    if (rules.length != external.length) {
      throw ActionAuthoringException(
        reason: ActionAuthoringProblem.appUnavailable,
        message: 'An app-confirmed proof is missing its app.',
      );
    }
    await _assertAppsUsable(
      session,
      creatorAuthUserId: action.creatorAuthUserId,
      appIds: [for (final rule in rules) rule.appId],
      transaction: transaction,
    );
  }

  _ValidatedRequest _validatedRequest(
    CreateActionDefinitionRequest request,
    DateTime now,
  ) {
    final requirements = request.requirements;
    if (requirements.isEmpty || requirements.length > maxActionRequirements) {
      throw ArgumentError.value(
        requirements.length,
        'requirements',
        'An action needs between 1 and $maxActionRequirements requirements.',
      );
    }
    if (request.maxVerifiedCompletions case final maximum? when maximum <= 0) {
      throw ArgumentError.value(
        maximum,
        'maxVerifiedCompletions',
        'Must be greater than zero.',
      );
    }
    if (request.opensAt case final opensAt?) {
      if (request.closesAt case final closesAt?
          when !closesAt.isAfter(opensAt)) {
        throw ArgumentError('closesAt must be after opensAt.');
      }
    }
    final validated = <ValidatedRequirement>[];
    final keys = <String>{};
    for (var index = 0; index < requirements.length; index += 1) {
      final requirement = validateRequirementDraft(requirements[index], index);
      if (!keys.add(requirement.key)) {
        throw ArgumentError('Requirement keys must be unique.');
      }
      validated.add(requirement);
    }
    // Completion checks only required proof, so an action whose proof is all
    // optional would verify with none and pay its reward to anyone.
    if (!requirements.any((requirement) => requirement.isRequired)) {
      throw ArgumentError(
        'An action needs at least one required proof.',
        'requirements',
      );
    }
    assertExternalProofNotMixed([
      for (final requirement in requirements) requirement.kind,
    ]);
    final timeZone = requiredText(request.timeZone, 'timeZone', maxLength: 64);
    actionTimeZone(timeZone);
    return _ValidatedRequest(
      actionKey: requiredSlug(request.actionKey, 'actionKey'),
      title: requiredText(request.title, 'title', maxLength: 120),
      description: requiredText(
        request.description,
        'description',
        maxLength: 1000,
      ),
      timeZone: timeZone,
      requirements: validated,
      reward: request.reward == null
          ? null
          : rewardPools.validateTerms(request.reward!, now),
    );
  }
}

class _ValidatedRequest {
  const _ValidatedRequest({
    required this.actionKey,
    required this.title,
    required this.description,
    required this.timeZone,
    required this.requirements,
    required this.reward,
  });

  final String actionKey;
  final String title;
  final String description;
  final String timeZone;
  final List<ValidatedRequirement> requirements;
  final ValidatedRewardTerms? reward;
}
