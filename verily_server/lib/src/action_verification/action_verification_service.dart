// Generated copyWith methods use null to clear nullable persisted fields.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/abuse/abuse_risk_policy.dart';
import 'package:verily_server/src/abuse/action_abuse_gate.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/action_period.dart';
import 'package:verily_server/src/action_verification/action_requirement_rules.dart';
import 'package:verily_server/src/action_verification/action_templates.dart';
import 'package:verily_server/src/action_verification/action_views.dart';
import 'package:verily_server/src/action_verification/capture_integrity.dart';
import 'package:verily_server/src/action_verification/evidence_verification_queue.dart';
import 'package:verily_server/src/action_verification/location_evidence_policy.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/action_verification/spoken_challenge_words.dart';
import 'package:verily_server/src/apps/app_confirmation_payload.dart';
import 'package:verily_server/src/apps/external_confirmation.dart';
import 'package:verily_server/src/evidence_storage/evidence_integrity_policy.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/moderation/moderation_gate.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';
import 'package:verily_server/src/security/secret_digest.dart';

/// Verifier type recorded on decisions created from App confirmations.
const appConfirmationVerifierType = 'verily-app';
const _externalProofMessage =
    'An app confirms this proof; it cannot be submitted here.';
const _mediaProofMessage = 'Media proof must use the private upload flow.';

/// How long a spoken challenge word stays usable before recording starts.
const spokenChallengeLifetime = Duration(minutes: 15);

/// Words one proof may draw. A small cap stops word-fishing for a recording
/// made in advance.
const maxSpokenChallengesPerProof = 5;

/// Clock skew tolerated between the device and the server.
const _captureClockTolerance = Duration(minutes: 2);

/// Participation, proof, and completion for creator-owned actions.
///
/// Completion is the single place a proof becomes a verified completion, and
/// it runs from every path that can finish one: the participant, the media
/// verification worker, a reviewer, an accepted appeal, and an App
/// confirmation.
class ActionVerificationService {
  ActionVerificationService({
    CaptureIntegrityEvaluator? captureIntegrity,
    LocationEvidencePolicy? locationEvidencePolicy,
    ModerationGate? moderationGate,
    ActionAbuseGate? abuseGate,
    RewardPayoutService? payouts,
    ActionViews? views,
    EvidenceVerificationQueue? verificationQueue,
    DateTime Function()? clock,
    bool? allowStaticQrCodes,
    math.Random? random,
  }) : clock = clock ?? (() => DateTime.now().toUtc()),
       captureIntegrity =
           captureIntegrity ?? CaptureIntegrityEvaluator(clock: clock),
       locationEvidencePolicy =
           locationEvidencePolicy ?? const LocationEvidencePolicy(),
       moderationGate = moderationGate ?? const ModerationGate(),
       abuseGate = abuseGate ?? ActionAbuseGateRegistry.current,
       payouts = payouts ?? RewardPayoutService(clock: clock),
       views = views ?? ActionViews(clock: clock),
       verificationQueue =
           verificationQueue ?? const EvidenceVerificationQueue(),
       allowStaticQrCodes = allowStaticQrCodes ?? staticQrCodesAllowed(),
       _random = random ?? math.Random.secure();

  final DateTime Function() clock;
  final CaptureIntegrityEvaluator captureIntegrity;
  final LocationEvidencePolicy locationEvidencePolicy;
  final ModerationGate moderationGate;
  final ActionAbuseGate abuseGate;
  final RewardPayoutService payouts;
  final ActionViews views;
  final EvidenceVerificationQueue verificationQueue;
  final bool allowStaticQrCodes;
  final math.Random _random;

  List<ActionTemplate> listTemplates() => actionTemplates();

  Future<List<ActionOpportunity>> listAvailableActions(
    Session session, {
    required UuidValue authUserId,
    int limit = 50,
  }) async {
    final now = clock().toUtc();
    final actions = await ActionDefinition.db.find(
      session,
      where: (table) =>
          table.status.equals(ActionDefinitionStatus.active) &
          (table.opensAt.equals(null) | (table.opensAt <= now)) &
          (table.closesAt.equals(null) | (table.closesAt > now)) &
          (table.maxVerifiedCompletions.equals(null) |
              (table.verifiedCompletions < table.maxVerifiedCompletions)),
      orderBy: (table) => table.createdAt.desc(),
      limit: limit.clamp(1, 100),
    );
    return views.opportunities(
      session,
      actions: await _withoutSafetyHolds(session, actions),
      viewerAuthUserId: authUserId,
    );
  }

  /// Drops actions whose creator and key are under an active safety hold, so
  /// discovery never advertises an action that participation would refuse.
  /// A hold covers every revision of the key, as in [ModerationGate].
  Future<List<ActionDefinition>> _withoutSafetyHolds(
    Session session,
    List<ActionDefinition> actions,
  ) async {
    if (actions.isEmpty) return actions;
    final holds = await ModerationCase.db.find(
      session,
      where: (table) =>
          table.pauseActive.equals(true) &
          table.creatorAuthUserId.inSet(<UuidValue>{
            for (final action in actions) action.creatorAuthUserId,
          }),
    );
    if (holds.isEmpty) return actions;
    final heldActions = await ActionDefinition.db.find(
      session,
      where: (table) => table.id.inSet(<UuidValue>{
        for (final hold in holds) hold.actionDefinitionId,
      }),
    );
    final heldKeys = {
      for (final held in heldActions) (held.creatorAuthUserId, held.actionKey),
    };
    return [
      for (final action in actions)
        if (!heldKeys.contains((action.creatorAuthUserId, action.actionKey)))
          action,
    ];
  }

  /// Live actions whose public place lies within [radiusKm] of the given
  /// point, nearest first.
  ///
  /// The point is coarsened to about 100 metres before it is used and is
  /// never stored or logged. Distance is measured by PostGIS on the WGS 84
  /// spheroid; only the actions' own public places are returned.
  Future<List<ActionOpportunity>> listNearbyActions(
    Session session, {
    required UuidValue authUserId,
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 30,
  }) async {
    if (!validCoordinates(latitude, longitude)) {
      throw ArgumentError('Coordinates are out of range.');
    }
    if (!radiusKm.isFinite || radiusKm <= 0) {
      throw ArgumentError('Choose a positive search radius.');
    }
    final point = GeographyPoint(
      latitude: _coarse(latitude),
      longitude: _coarse(longitude),
    );
    final radiusMeters = radiusKm.clamp(0.1, 50) * 1000;
    final boundedLimit = limit.clamp(1, 50);
    final now = clock().toUtc();
    final rules = await ActionLocationRule.db.find(
      session,
      where: (table) =>
          table.location.distanceWithin(point, radiusMeters.toDouble()) &
          table.requirement.actionDefinition.status.equals(
            ActionDefinitionStatus.active,
          ) &
          (table.requirement.actionDefinition.opensAt.equals(null) |
              (table.requirement.actionDefinition.opensAt <= now)) &
          (table.requirement.actionDefinition.closesAt.equals(null) |
              (table.requirement.actionDefinition.closesAt > now)),
      orderBy: (table) => table.location.distance(point),
      limit: boundedLimit * 4,
      include: ActionLocationRule.include(
        requirement: ActionRequirement.include(),
      ),
    );
    final orderedIds = <UuidValue>[];
    for (final rule in rules) {
      final actionId = rule.requirement?.actionDefinitionId;
      if (actionId != null && !orderedIds.contains(actionId)) {
        orderedIds.add(actionId);
      }
    }
    if (orderedIds.isEmpty) return const [];
    final actions = await ActionDefinition.db.find(
      session,
      where: (table) => table.id.inSet(orderedIds.toSet()),
    );
    final byId = {
      for (final action in actions)
        if (_isOpen(action, now)) action.id!: action,
    };
    final nearest = await _withoutSafetyHolds(session, [
      for (final id in orderedIds) ?byId[id],
    ]);
    return views.opportunities(
      session,
      actions: nearest.take(boundedLimit).toList(),
      viewerAuthUserId: authUserId,
    );
  }

  Future<ActionAttemptView> beginAttempt(
    Session session, {
    required UuidValue authUserId,
    required UuidValue actionId,
    required String idempotencyKey,
  }) async {
    final key = requiredText(idempotencyKey, 'idempotencyKey', maxLength: 128);
    final attempt = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        await moderationGate.assertActionAllowed(
          session,
          actionId: actionId,
          transaction: transaction,
        );
        final action = await ActionDefinition.db.findFirstRow(
          session,
          where: (table) => table.id.equals(actionId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (action == null || !_isOpen(action, clock())) {
          throw StateError('This action is not currently available.');
        }
        final revokedApp = await _revokedAppName(
          session,
          actionId: actionId,
          transaction: transaction,
        );
        if (revokedApp != null) {
          throw AppUnavailableException(
            appName: revokedApp,
            message: 'This action relies on an app that was revoked.',
          );
        }
        return _reserveAttempt(
          session,
          transaction: transaction,
          action: action,
          authUserId: authUserId,
          periodKey: _periodKey(action, clock()),
          idempotencyKey: key,
        );
      },
    );
    return attemptView(attempt);
  }

  /// Returns the account's attempt for [periodKey], creating it only when no
  /// attempt exists yet. Callers hold the action row lock; concurrent inserts
  /// for the same period or idempotency key converge on the persisted row.
  Future<ActionAttempt> _reserveAttempt(
    Session session, {
    required Transaction transaction,
    required ActionDefinition action,
    required UuidValue authUserId,
    required String periodKey,
    required String idempotencyKey,
  }) async {
    final actionId = action.id!;
    Future<ActionAttempt?> forPeriod() => ActionAttempt.db.findFirstRow(
      session,
      where: (table) =>
          table.actionDefinitionId.equals(actionId) &
          table.participantAuthUserId.equals(authUserId) &
          table.periodKey.equals(periodKey),
      transaction: transaction,
    );
    Future<ActionAttempt?> forKey() => ActionAttempt.db.findFirstRow(
      session,
      where: (table) =>
          table.participantAuthUserId.equals(authUserId) &
          table.idempotencyKey.equals(idempotencyKey),
      transaction: transaction,
    );

    final existingForPeriod = await forPeriod();
    if (existingForPeriod != null) return existingForPeriod;
    final existingForKey = await forKey();
    if (existingForKey != null) {
      if (existingForKey.actionDefinitionId != actionId) {
        throw StateError(
          'Attempt idempotency key was reused with different data.',
        );
      }
      return existingForKey;
    }

    final inserted = await ActionAttempt.db.insert(
      session,
      [
        ActionAttempt(
          actionDefinitionId: actionId,
          participantAuthUserId: authUserId,
          periodKey: periodKey,
          idempotencyKey: idempotencyKey,
          status: ActionAttemptStatus.collectingEvidence,
        ),
      ],
      transaction: transaction,
      ignoreConflicts: true,
    );
    if (inserted case [final attempt]) return attempt;

    final concurrentForPeriod = await forPeriod();
    if (concurrentForPeriod != null) return concurrentForPeriod;
    final concurrentForKey = await forKey();
    if (concurrentForKey != null &&
        concurrentForKey.actionDefinitionId == actionId) {
      return concurrentForKey;
    }
    throw StateError(
      'Attempt idempotency key conflicted with another request.',
    );
  }

  /// Issues, or returns the still-valid, live challenge word for one video
  /// or audio proof. Show it before recording: "Say 'pelican' while you
  /// record". Once a recording is bound to a word, that word is returned.
  Future<ActionSpokenChallengeView> issueSpokenChallenge(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) async {
    final challenge = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final attempt = await _ownedAttempt(
          session,
          attemptId,
          authUserId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (attempt.status != ActionAttemptStatus.collectingEvidence) {
          throw StateError('This attempt no longer accepts proof.');
        }
        await _requireLiveAction(
          session,
          actionId: attempt.actionDefinitionId,
          transaction: transaction,
        );
        final requirement = await _attemptRequirement(
          session,
          attempt: attempt,
          requirementId: requirementId,
          transaction: transaction,
        );
        final rule = await ActionMediaRule.db.findFirstRow(
          session,
          where: (table) => table.requirementId.equals(requirement.id),
          transaction: transaction,
        );
        if (rule == null || !rule.spokenChallengeRequired) {
          throw StateError('This proof does not use a challenge word.');
        }
        final reservation = await EvidenceUploadReservation.db.findFirstRow(
          session,
          where: (table) =>
              table.attemptId.equals(attemptId) &
              table.requirementId.equals(requirementId),
          transaction: transaction,
        );
        if (reservation?.spokenChallengeId case final boundId?) {
          final bound = await ActionSpokenChallenge.db.findById(
            session,
            boundId,
            transaction: transaction,
          );
          if (bound != null) return bound;
        }
        final now = clock().toUtc();
        final issued = await ActionSpokenChallenge.db.find(
          session,
          where: (table) =>
              table.attemptId.equals(attemptId) &
              table.requirementId.equals(requirementId),
          orderBy: (table) => table.issuedAt.desc(),
          transaction: transaction,
        );
        final active = issued.where(
          (item) => item.boundAt == null && item.expiresAt.isAfter(now),
        );
        if (active.isNotEmpty) return active.first;
        if (issued.length >= maxSpokenChallengesPerProof) {
          throw StateError(
            'This proof has used all of its challenge words. Try again in '
            'the next period.',
          );
        }
        return ActionSpokenChallenge.db.insertRow(
          session,
          ActionSpokenChallenge(
            attemptId: attemptId,
            requirementId: requirementId,
            participantAuthUserId: authUserId,
            word: pickSpokenChallengeWord(_random),
            issuedAt: now,
            expiresAt: now.add(spokenChallengeLifetime),
          ),
          transaction: transaction,
        );
      },
    );
    return ActionSpokenChallengeView(
      id: challenge.id!,
      word: challenge.word,
      expiresAt: challenge.expiresAt,
    );
  }

  /// Binds the next proof submission to a fresh device-integrity request
  /// that commits to [evidenceBindingHash].
  Future<ActionCaptureChallengeView> createCaptureChallenge(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String evidenceBindingHash,
  }) async {
    final normalizedBindingHash = normalizeEvidenceBindingHash(
      evidenceBindingHash,
    );
    final now = clock().toUtc();
    final nonce = base64Url
        .encode(List<int>.generate(32, (_) => _random.nextInt(256)))
        .replaceAll('=', '');
    final requestHash = captureIntegrityRequestHash(
      authUserId: authUserId.toString(),
      attemptId: attemptId.toString(),
      requirementId: requirementId.toString(),
      evidenceBindingHash: normalizedBindingHash,
      nonce: nonce,
    );
    final expiresAt = now.add(const Duration(minutes: 15));
    final challenge = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final attempt = await _ownedAttempt(
          session,
          attemptId,
          authUserId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (attempt.status != ActionAttemptStatus.collectingEvidence) {
          throw StateError('This action attempt no longer accepts proof.');
        }
        await moderationGate.assertActionAllowed(
          session,
          actionId: attempt.actionDefinitionId,
          transaction: transaction,
        );
        final requirement = await _attemptRequirement(
          session,
          attempt: attempt,
          requirementId: requirementId,
          transaction: transaction,
        );
        if (requirement.kind == ActionRequirementKind.externalApp) {
          throw StateError(_externalProofMessage);
        }
        final recent = await ActionCaptureChallenge.db.count(
          session,
          where: (table) =>
              table.attemptId.equals(attemptId) &
              (table.createdAt > now.subtract(const Duration(hours: 1))),
          transaction: transaction,
        );
        if (recent >= 10) {
          throw StateError(
            'Please wait before requesting another capture check.',
          );
        }
        return ActionCaptureChallenge.db.insertRow(
          session,
          ActionCaptureChallenge(
            attemptId: attemptId,
            requirementId: requirementId,
            participantAuthUserId: authUserId,
            requestHash: requestHash,
            evidenceBindingHash: normalizedBindingHash,
            expiresAt: expiresAt,
            createdAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    return ActionCaptureChallengeView(
      id: challenge.id!,
      requestHash: requestHash,
      expiresAt: expiresAt,
      integrityRequired: captureIntegrity.deviceIntegrityRequired,
      signatureRequired: captureIntegrity.captureSignatureRequired,
    );
  }

  /// Accepts deterministic proof: a location check, a venue code, or a
  /// device-motion trace. Media proof uses [submitMediaEvidence] through the
  /// private upload flow.
  Future<EvidenceSubmissionResult> submitEvidence(
    Session session, {
    required UuidValue authUserId,
    required ActionEvidenceInput input,
  }) async {
    final attempt = await _ownedAttempt(session, input.attemptId, authUserId);
    await AccountAccess.requireActive(session, authUserId);
    await moderationGate.preflightAction(session, attempt.actionDefinitionId);
    _requireOpenAttempt(attempt);
    final requirement = await ActionRequirement.db.findById(
      session,
      input.requirementId,
    );
    if (requirement == null ||
        requirement.actionDefinitionId != attempt.actionDefinitionId) {
      throw StateError('The requirement does not belong to this attempt.');
    }
    switch (requirement.kind) {
      case ActionRequirementKind.externalApp:
        throw StateError(_externalProofMessage);
      case ActionRequirementKind.video ||
          ActionRequirementKind.photo ||
          ActionRequirementKind.audio:
        throw StateError(_mediaProofMessage);
      case ActionRequirementKind.location ||
          ActionRequirementKind.qrCode ||
          ActionRequirementKind.motion:
        break;
    }

    final integrity = await captureIntegrity.evaluate(
      session,
      authUserId: authUserId,
      attemptId: input.attemptId,
      requirementId: input.requirementId,
      material: CaptureIntegrityMaterial(
        captureChallengeId: input.captureChallengeId,
        deviceIntegrityToken: input.deviceIntegrityToken,
        captureManifest: input.captureManifest,
        captureSignature: input.captureSignature,
        capturePublicKey: input.capturePublicKey,
        captureKeyId: input.captureKeyId,
        captureKeyStorage: input.captureKeyStorage,
      ),
      evidenceBindingHash: () => _deterministicBindingHash(requirement, input),
    );
    // Location is evaluated under the participant lock below so concurrent
    // check-ins cannot each miss the other's travel.
    final immediate = requirement.kind == ActionRequirementKind.location
        ? null
        : await _evaluateDeterministic(
            session,
            requirement,
            input,
            authUserId: authUserId,
          );
    final result = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final lockedAttempt = await _ownedAttempt(
          session,
          input.attemptId,
          authUserId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        _requireOpenAttempt(lockedAttempt);
        final action = await _requireLiveAction(
          session,
          actionId: lockedAttempt.actionDefinitionId,
          transaction: transaction,
        );

        final now = clock().toUtc();
        if (requirement.kind == ActionRequirementKind.location) {
          await session.db.unsafeQuery(
            'SELECT pg_advisory_xact_lock(hashtextextended(@lockKey, 0));',
            transaction: transaction,
            parameters: QueryParameters.named({
              'lockKey': 'verily:location:$authUserId',
            }),
          );
        }
        final proof =
            immediate ??
            await _evaluateDeterministic(
              session,
              requirement,
              input,
              authUserId: authUserId,
              transaction: transaction,
            );
        var evaluation = _withCaptureIntegrity(proof, integrity);
        await _consumeCaptureChallenge(
          session,
          evaluation: evaluation,
          attempt: lockedAttempt,
          requirement: requirement,
          authUserId: authUserId,
          now: now,
          transaction: transaction,
        );
        if (evaluation.qrChallengeId case final challengeId?) {
          final challenge = await ActionQrChallenge.db.findFirstRow(
            session,
            where: (table) => table.id.equals(challengeId),
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          );
          if (challenge == null ||
              challenge.requirementId != requirement.id ||
              !challenge.expiresAt.isAfter(now) ||
              (challenge.usedByAttemptId != null &&
                  challenge.usedByAttemptId != lockedAttempt.id)) {
            throw StateError(
              'That venue code has expired or was already used.',
            );
          }
          if (challenge.usedAt == null) {
            await ActionQrChallenge.db.updateRow(
              session,
              challenge.copyWith(
                usedAt: now,
                usedByAttemptId: lockedAttempt.id,
              ),
              transaction: transaction,
            );
          }
        }
        final candidate = _deterministicEvidence(
          lockedAttempt.id!,
          requirement,
          input,
          evaluation,
          now,
        );
        if (evaluation.status == EvidenceDecisionStatus.accepted) {
          final abuseDecision = await abuseGate.assess(
            session,
            action: action,
            attempt: lockedAttempt,
            evidence: candidate,
            phase: AbuseAssessmentPhase.evidenceSubmission,
            transaction: transaction,
            singleUseQr: evaluation.qrChallengeId != null,
          );
          evaluation = _withAbuseDecision(evaluation, abuseDecision);
        }
        final existing = await ActionEvidence.db.findFirstRow(
          session,
          where: (table) =>
              table.attemptId.equals(lockedAttempt.id) &
              table.requirementId.equals(requirement.id),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        final evidence = existing == null
            ? await ActionEvidence.db.insertRow(
                session,
                candidate.copyWith(
                  motionAnalysisJson: evaluation.motionAnalysisJson,
                ),
                transaction: transaction,
              )
            : await ActionEvidence.db.updateRow(
                session,
                candidate.copyWith(
                  id: existing.id,
                  motionAnalysisJson: evaluation.motionAnalysisJson,
                ),
                transaction: transaction,
              );
        await _insertDecision(session, evidence, evaluation, now, transaction);
        final refreshed = await ActionAttempt.db.updateRow(
          session,
          lockedAttempt.copyWith(
            status: ActionAttemptStatus.collectingEvidence,
            rejectionCode: null,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        return (attempt: refreshed, evaluation: evaluation);
      },
    );
    return EvidenceSubmissionResult(
      attempt: attemptView(result.attempt),
      requirementId: requirement.id!,
      status: result.evaluation.status,
      confidence: result.evaluation.confidence,
      reasonCode: result.evaluation.reasonCode,
      summary: result.evaluation.summary,
      provenanceLevel: result.evaluation.provenanceLevel,
    );
  }

  /// Records one inspected, version-pinned media upload as evidence.
  ///
  /// Server-side preflight (duration, capture time, the live challenge word,
  /// capture integrity, and abuse correlation) may decide the proof at once.
  /// Otherwise the evidence gets a durable verification job and the attempt
  /// waits in `verifying`; the worker completes it.
  Future<EvidenceSubmissionResult> submitMediaEvidence(
    Session session, {
    required UuidValue authUserId,
    required EvidenceUploadReservation reservation,
    required EvidenceIntegritySeal seal,
    required MediaUploadConfirmation confirmation,
  }) async {
    final requirement = await ActionRequirement.db.findById(
      session,
      reservation.requirementId,
    );
    final mediaKind = requirement == null
        ? null
        : mediaKindOf(requirement.kind);
    if (requirement == null || mediaKind == null) {
      throw StateError('The media requirement was not found.');
    }
    final rule = await ActionMediaRule.db.findFirstRow(
      session,
      where: (table) => table.requirementId.equals(requirement.id),
    );
    if (rule == null) throw StateError('Media rule is missing.');
    _validateDeviceRepetitionCount(rule, confirmation);
    final duration = confirmation.durationSeconds;
    if (mediaKind == MediaEvidenceKind.photo && duration != null) {
      throw ArgumentError('A photo has no duration.');
    }
    if (mediaKind != MediaEvidenceKind.photo &&
        (duration == null || duration <= 0)) {
      throw ArgumentError('A recording needs its duration.');
    }
    final capturedAt = confirmation.capturedAt.toUtc();
    final integrity = await captureIntegrity.evaluate(
      session,
      authUserId: authUserId,
      attemptId: reservation.attemptId,
      requirementId: reservation.requirementId,
      material: CaptureIntegrityMaterial(
        captureChallengeId: confirmation.captureChallengeId,
        deviceIntegrityToken: confirmation.deviceIntegrityToken,
        captureManifest: confirmation.captureManifest,
        captureSignature: confirmation.captureSignature,
        capturePublicKey: confirmation.capturePublicKey,
        captureKeyId: confirmation.captureKeyId,
        captureKeyStorage: confirmation.captureKeyStorage,
      ),
      evidenceBindingHash: () => mediaEvidenceBindingHash(
        kind: mediaKind,
        capturedAt: capturedAt,
        sha256Digest: seal.sha256Digest,
        byteLength: seal.byteLength,
        durationSeconds: duration ?? 0,
        contentType: seal.contentType,
      ),
    );
    final spokenChallenge = switch (reservation.spokenChallengeId) {
      final id? => await ActionSpokenChallenge.db.findById(session, id),
      null => null,
    };

    final result = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final attempt = await _ownedAttempt(
          session,
          reservation.attemptId,
          authUserId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        _requireOpenAttempt(attempt);
        final action = await _requireLiveAction(
          session,
          actionId: attempt.actionDefinitionId,
          transaction: transaction,
        );
        final now = clock().toUtc();
        final preflight = _mediaPreflight(
          rule: rule,
          durationSeconds: duration,
          capturedAt: capturedAt,
          now: now,
          spokenChallenge: spokenChallenge,
        );
        var evaluation = _withCaptureIntegrity(
          preflight ?? _queuedEvaluation,
          integrity,
        );
        await _consumeCaptureChallenge(
          session,
          evaluation: evaluation,
          attempt: attempt,
          requirement: requirement,
          authUserId: authUserId,
          now: now,
          transaction: transaction,
        );
        final candidate = ActionEvidence(
          attemptId: attempt.id!,
          requirementId: requirement.id!,
          kind: requirement.kind,
          storagePath: seal.storagePath,
          storageVersionId: seal.storageVersionId,
          mimeType: seal.contentType,
          sha256Digest: seal.sha256Digest,
          byteLength: seal.byteLength,
          durationSeconds: duration,
          deviceRepetitionCount: confirmation.deviceRepetitionCount,
          deviceTrackerVersion: confirmation.deviceTrackerVersion,
          spokenChallengeId: spokenChallenge?.id,
          spokenChallengeWord: spokenChallenge?.word,
          provenanceLevel: evaluation.provenanceLevel,
          captureManifest: evaluation.captureManifest,
          captureSignature: evaluation.captureSignature,
          capturePublicKey: evaluation.capturePublicKey,
          captureKeyId: evaluation.captureKeyId,
          captureKeyStorage: evaluation.captureKeyStorage,
          capturedAt: capturedAt,
          submittedAt: now,
        );
        if (evaluation.status == null) {
          // Replayed or correlated media is stopped before any model spend.
          final abuseDecision = await abuseGate.assess(
            session,
            action: action,
            attempt: attempt,
            evidence: candidate,
            phase: AbuseAssessmentPhase.evidenceSubmission,
            transaction: transaction,
          );
          evaluation = _withAbuseDecision(evaluation, abuseDecision);
        }
        final existing = await ActionEvidence.db.findFirstRow(
          session,
          where: (table) =>
              table.attemptId.equals(attempt.id) &
              table.requirementId.equals(requirement.id),
          transaction: transaction,
        );
        if (existing != null) {
          throw StateError('This proof has already been submitted.');
        }
        final evidence = await ActionEvidence.db.insertRow(
          session,
          candidate,
          transaction: transaction,
        );
        if (evaluation.status == null) {
          await verificationQueue.insertJob(
            session,
            evidenceId: evidence.id!,
            now: now,
            transaction: transaction,
          );
        } else {
          await _insertDecision(
            session,
            evidence,
            evaluation,
            now,
            transaction,
          );
        }
        final status = await _statusWhileCollecting(
          session,
          attempt: attempt,
          transaction: transaction,
        );
        final refreshed = await ActionAttempt.db.updateRow(
          session,
          attempt.copyWith(
            status: status,
            rejectionCode: null,
            submittedAt: status == ActionAttemptStatus.verifying
                ? now
                : attempt.submittedAt,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        return (
          attempt: refreshed,
          evaluation: evaluation,
          queuedEvidenceId: evaluation.status == null ? evidence.id : null,
        );
      },
    );
    if (result.queuedEvidenceId case final evidenceId?) {
      await verificationQueue.schedule(session, evidenceId: evidenceId);
    }
    return EvidenceSubmissionResult(
      attempt: attemptView(result.attempt),
      requirementId: requirement.id!,
      status: result.evaluation.status,
      confidence: result.evaluation.confidence,
      reasonCode: result.evaluation.reasonCode,
      summary: result.evaluation.summary,
      provenanceLevel: result.evaluation.provenanceLevel,
    );
  }

  /// Decides what an uploaded recording's server-measurable facts allow.
  /// Returns null when the proof should go on to its verifier.
  _Evaluation? _mediaPreflight({
    required ActionMediaRule rule,
    required int? durationSeconds,
    required DateTime capturedAt,
    required DateTime now,
    required ActionSpokenChallenge? spokenChallenge,
  }) {
    if (capturedAt.isAfter(now.add(_captureClockTolerance))) {
      return const _Evaluation(
        status: EvidenceDecisionStatus.rejected,
        verifierType: 'media-preflight',
        confidence: 0,
        reasonCode: 'media_capture_time_invalid',
        summary: 'Check the phone clock, then record again.',
      );
    }
    final minimum = rule.minDurationSeconds;
    final maximum = rule.maxDurationSeconds;
    if (minimum != null &&
        maximum != null &&
        (durationSeconds == null ||
            durationSeconds < minimum ||
            durationSeconds > maximum)) {
      return const _Evaluation(
        status: EvidenceDecisionStatus.rejected,
        verifierType: 'media-preflight',
        confidence: 0,
        reasonCode: 'media_duration_out_of_range',
        summary: 'The recording was too short or too long for this action.',
      );
    }
    if (rule.spokenChallengeRequired) {
      if (spokenChallenge == null) {
        return const _Evaluation(
          status: EvidenceDecisionStatus.rejected,
          verifierType: 'spoken-challenge',
          confidence: 0,
          reasonCode: 'spoken_challenge_missing',
          summary: 'Get a challenge word before recording, then try again.',
        );
      }
      if (capturedAt.isBefore(
        spokenChallenge.issuedAt.subtract(_captureClockTolerance),
      )) {
        return const _Evaluation(
          status: EvidenceDecisionStatus.rejected,
          verifierType: 'spoken-challenge',
          confidence: 0,
          reasonCode: 'spoken_challenge_predates_capture',
          summary: 'This recording started before its challenge word.',
        );
      }
    }
    return null;
  }

  /// The attempt status after a proof arrives: `verifying` once every
  /// required proof is in and some still wait for automated verification.
  Future<ActionAttemptStatus> _statusWhileCollecting(
    Session session, {
    required ActionAttempt attempt,
    required Transaction transaction,
  }) async {
    final readiness = await _requiredProofReadiness(
      session,
      attempt: attempt,
      transaction: transaction,
    );
    return readiness.allSubmitted && readiness.awaitingVerification
        ? ActionAttemptStatus.verifying
        : ActionAttemptStatus.collectingEvidence;
  }

  Future<({bool allSubmitted, bool awaitingVerification})>
  _requiredProofReadiness(
    Session session, {
    required ActionAttempt attempt,
    Transaction? transaction,
  }) async {
    final required = await ActionRequirement.db.find(
      session,
      where: (table) =>
          table.actionDefinitionId.equals(attempt.actionDefinitionId) &
          table.isRequired.equals(true),
      transaction: transaction,
    );
    final evidence = await ActionEvidence.db.find(
      session,
      where: (table) => table.attemptId.equals(attempt.id),
      transaction: transaction,
    );
    final submitted = {for (final row in evidence) row.requirementId};
    final requiredEvidenceIds = {
      for (final row in evidence)
        if (required.any((requirement) => requirement.id == row.requirementId))
          row.id!,
    };
    final decided = requiredEvidenceIds.isEmpty
        ? const <UuidValue>{}
        : {
            for (final decision in await EvidenceDecision.db.find(
              session,
              where: (table) => table.evidenceId.inSet(requiredEvidenceIds),
              transaction: transaction,
            ))
              decision.evidenceId,
          };
    return (
      allSubmitted:
          required.isNotEmpty &&
          required.every((requirement) => submitted.contains(requirement.id)),
      awaitingVerification: requiredEvidenceIds.any(
        (id) => !decided.contains(id),
      ),
    );
  }

  /// Completes an attempt when every required proof is accepted.
  ///
  /// Inside the same transaction it re-checks every proof, the abuse gate,
  /// the action's capacity, and the reward pool under its row lock, then
  /// reserves the next payout index. Pass [enclosingTransaction] from a
  /// caller that commits later; that caller then schedules the payout with
  /// [RewardPayoutService.scheduleForAttempt] after its commit.
  Future<ActionAttemptView> completeAttempt(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    Transaction? enclosingTransaction,
  }) async {
    final completed = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      enclosingTransaction,
      (transaction) => _complete(
        session,
        authUserId: authUserId,
        attemptId: attemptId,
        transaction: transaction,
      ),
    );
    if (enclosingTransaction == null &&
        completed.payout?.status == RewardPayoutStatus.reserved) {
      await payouts.scheduler.schedule(session, completed.payout!.id!);
    }
    return attemptView(completed.attempt, payout: completed.payout);
  }

  /// Completes [attemptId] on the participant's behalf once every required
  /// proof has been submitted. Used by the verification worker and recovery,
  /// so a participant never has to come back to finish a verified attempt.
  Future<ActionAttemptView?> completeIfReady(
    Session session, {
    required UuidValue attemptId,
  }) async {
    final attempt = await ActionAttempt.db.findById(session, attemptId);
    if (attempt == null ||
        !{
          ActionAttemptStatus.collectingEvidence,
          ActionAttemptStatus.verifying,
          ActionAttemptStatus.pendingReview,
        }.contains(attempt.status)) {
      return null;
    }
    final readiness = await _requiredProofReadiness(session, attempt: attempt);
    if (!readiness.allSubmitted) return null;
    try {
      return await completeAttempt(
        session,
        authUserId: attempt.participantAuthUserId,
        attemptId: attemptId,
      );
      // Business-rule refusals are StateErrors in this codebase; any other
      // failure propagates.
      // ignore: avoid_catching_errors
    } on StateError catch (error) {
      // A paused or blocked state is retried by recovery; the decision
      // itself is already durable.
      session.log(
        'Attempt $attemptId could not complete yet: ${error.message}',
        level: LogLevel.info,
      );
      return null;
    }
  }

  Future<({ActionAttempt attempt, RewardPayout? payout})> _complete(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required Transaction transaction,
  }) async {
    await AccountAccess.requireActive(
      session,
      authUserId,
      transaction: transaction,
    );
    final attempt = await ActionAttempt.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(attemptId) &
          table.participantAuthUserId.equals(authUserId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (attempt == null) throw StateError('Action attempt was not found.');
    if (attempt.status == ActionAttemptStatus.verified ||
        attempt.status == ActionAttemptStatus.capacityReached) {
      final payout = await RewardPayout.db.findFirstRow(
        session,
        where: (table) => table.attemptId.equals(attempt.id),
        transaction: transaction,
      );
      return (attempt: attempt, payout: payout);
    }

    await moderationGate.assertActionAllowed(
      session,
      actionId: attempt.actionDefinitionId,
      transaction: transaction,
    );
    final action = await ActionDefinition.db.findFirstRow(
      session,
      where: (table) => table.id.equals(attempt.actionDefinitionId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    // Proof arrives only while an action is live. Once it has arrived, a
    // later close, pause, or new revision does not void it.
    if (action == null || action.status == ActionDefinitionStatus.draft) {
      throw StateError('This action is not currently available.');
    }
    final requirements = await ActionRequirement.db.find(
      session,
      where: (table) =>
          table.actionDefinitionId.equals(action.id) &
          table.isRequired.equals(true),
      transaction: transaction,
    );
    // Authoring refuses actions without required proof; one that has none
    // anyway must never verify, and pay out, on no evidence.
    if (requirements.isEmpty) {
      throw StateError('This action has no required proof.');
    }
    final decisions = <EvidenceDecision>[];
    final acceptedEvidence = <ActionEvidence>[];
    var hasMissingEvidence = false;
    var awaitingVerification = false;
    for (final requirement in requirements) {
      final evidence = await ActionEvidence.db.findFirstRow(
        session,
        where: (table) =>
            table.attemptId.equals(attempt.id) &
            table.requirementId.equals(requirement.id),
        transaction: transaction,
      );
      if (evidence == null) {
        hasMissingEvidence = true;
        continue;
      }
      final decision = await latestDecision(
        session,
        evidenceId: evidence.id!,
        transaction: transaction,
      );
      if (decision == null) {
        awaitingVerification = true;
        continue;
      }
      decisions.add(decision);
      acceptedEvidence.add(evidence);
    }

    final now = clock().toUtc();
    Future<({ActionAttempt attempt, RewardPayout? payout})> settle(
      ActionAttemptStatus status, {
      String? rejectionCode,
    }) async => (
      attempt: await ActionAttempt.db.updateRow(
        session,
        attempt.copyWith(
          status: status,
          rejectionCode: rejectionCode,
          submittedAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      ),
      payout: null,
    );

    final rejected = decisions.where(
      (decision) => decision.status == EvidenceDecisionStatus.rejected,
    );
    if (rejected.isNotEmpty) {
      return settle(
        ActionAttemptStatus.rejected,
        rejectionCode: rejected.first.reasonCode,
      );
    }
    if (hasMissingEvidence) {
      return settle(
        ActionAttemptStatus.collectingEvidence,
        rejectionCode: 'missing_required_evidence',
      );
    }
    if (awaitingVerification) return settle(ActionAttemptStatus.verifying);
    final awaitingReview = decisions.where(
      (decision) => decision.status == EvidenceDecisionStatus.manualReview,
    );
    if (awaitingReview.isNotEmpty) {
      // Proof held for its payout's value keeps saying so while a reviewer
      // works through the rest.
      return settle(
        ActionAttemptStatus.pendingReview,
        rejectionCode:
            awaitingReview.any(
              (decision) => decision.reasonCode == highValuePayoutReviewCode,
            )
            ? highValuePayoutReviewCode
            : null,
      );
    }

    for (var index = 0; index < acceptedEvidence.length; index += 1) {
      if (decisions[index].reviewedByAuthUserId != null) continue;
      final evidence = acceptedEvidence[index];
      final abuseDecision = await abuseGate.assess(
        session,
        action: action,
        attempt: attempt,
        evidence: evidence,
        phase: AbuseAssessmentPhase.valueAuthorization,
        transaction: transaction,
      );
      if (abuseDecision.disposition == AbuseRiskDisposition.allow) continue;
      final blocked = abuseDecision.disposition == AbuseRiskDisposition.reject
          ? EvidenceDecisionStatus.rejected
          : EvidenceDecisionStatus.manualReview;
      await EvidenceDecision.db.insertRow(
        session,
        EvidenceDecision(
          evidenceId: evidence.id!,
          status: blocked,
          verifierType: 'abuse-risk',
          confidence: 0,
          reasonCode: _abuseReasonCode(abuseDecision),
          summary: blocked == EvidenceDecisionStatus.rejected
              ? 'This proof could not be accepted.'
              : needsReviewSummary,
          createdAt: now,
        ),
        transaction: transaction,
      );
      return blocked == EvidenceDecisionStatus.rejected
          ? settle(
              ActionAttemptStatus.rejected,
              rejectionCode: _abuseReasonCode(abuseDecision),
            )
          : settle(ActionAttemptStatus.pendingReview);
    }

    final maximum = action.maxVerifiedCompletions;
    if (maximum != null && action.verifiedCompletions >= maximum) {
      return settle(
        ActionAttemptStatus.capacityReached,
        rejectionCode: 'action_capacity_reached',
      );
    }

    final reward = await payouts.evaluate(
      session,
      action: action,
      participantAuthUserId: authUserId,
      now: now,
      transaction: transaction,
    );
    final pool = reward.pool;
    // A payout above the review threshold is reserved only on proof a
    // person accepted. Proof a person already accepted is never held again.
    final unreviewed = [
      for (var index = 0; index < decisions.length; index += 1)
        if (decisions[index].reviewedByAuthUserId == null)
          acceptedEvidence[index],
    ];
    if (pool != null &&
        reward.outcome == RewardOutcome.won &&
        payouts.requiresPersonReview(pool) &&
        unreviewed.isNotEmpty) {
      await EvidenceDecision.db.insert(
        session,
        [
          for (final evidence in unreviewed)
            EvidenceDecision(
              evidenceId: evidence.id!,
              status: EvidenceDecisionStatus.manualReview,
              verifierType: 'payout-value-review',
              reasonCode: highValuePayoutReviewCode,
              summary:
                  'A person checks this proof because its reward is large.',
              createdAt: now,
            ),
        ],
        transaction: transaction,
      );
      return settle(
        ActionAttemptStatus.pendingReview,
        rejectionCode: highValuePayoutReviewCode,
      );
    }

    final rank = action.verifiedCompletions + 1;
    final payout = pool != null && reward.outcome == RewardOutcome.won
        ? await payouts.reserve(
            session,
            pool: pool,
            attempt: attempt,
            now: now,
            transaction: transaction,
          )
        : null;
    await ActionDefinition.db.updateRow(
      session,
      action.copyWith(verifiedCompletions: rank, updatedAt: now),
      transaction: transaction,
    );
    final verified = await ActionAttempt.db.updateRow(
      session,
      attempt.copyWith(
        status: ActionAttemptStatus.verified,
        verificationScore: _meanConfidence(decisions),
        verifiedRank: rank,
        rejectionCode: null,
        rewardOutcome: reward.outcome,
        submittedAt: now,
        verifiedAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    return (attempt: verified, payout: payout);
  }

  /// Applies an App's confirmation of one `external` requirement.
  ///
  /// Runs inside the delivery transaction, which already holds the App row
  /// lock. Rule failures return an [ExternalConfirmationRejected] so the
  /// caller can persist a receipt; any other failure throws and rolls the
  /// whole delivery back so the App can retry it.
  ///
  /// The period comes from [occurredAt] in the action's time zone, so a late
  /// delivery still counts for the day the participant acted. A new attempt
  /// uses the idempotency key `app:<appId>:<eventId>`; an existing attempt
  /// for that period is reused.
  Future<ExternalConfirmation> confirmExternalRequirement(
    Session session, {
    required Transaction transaction,
    required VerilyApp app,
    required String actionKey,
    required UuidValue authUserId,
    required String eventId,
    required String eventDigest,
    required DateTime occurredAt,
  }) async {
    final candidate = await ActionDefinition.db.findFirstRow(
      session,
      where: (table) =>
          table.creatorAuthUserId.equals(app.creatorAuthUserId) &
          table.actionKey.equals(actionKey) &
          table.status.equals(ActionDefinitionStatus.active),
      transaction: transaction,
    );
    if (candidate == null) {
      return const ExternalConfirmationRejected(
        ExternalConfirmationRejection.unknownAction,
      );
    }
    final actionId = candidate.id!;
    ExternalConfirmationRejected reject(ExternalConfirmationRejection reason) =>
        ExternalConfirmationRejected(reason, actionDefinitionId: actionId);

    final requirement = await _externalRequirement(
      session,
      actionId: actionId,
      appId: app.id!,
      transaction: transaction,
    );
    if (requirement == null) {
      return reject(ExternalConfirmationRejection.unknownAction);
    }
    if (!await AccountAccess.isActive(
      session,
      authUserId,
      transaction: transaction,
    )) {
      return reject(ExternalConfirmationRejection.unknownSubject);
    }
    if (await moderationGate.isActionPaused(
      session,
      actionId: actionId,
      transaction: transaction,
    )) {
      return reject(ExternalConfirmationRejection.actionUnavailable);
    }
    final action = await ActionDefinition.db.findFirstRow(
      session,
      where: (table) => table.id.equals(actionId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (action == null) {
      return reject(ExternalConfirmationRejection.unknownAction);
    }
    final now = clock().toUtc();
    // An App clock running slightly ahead never earns a future period.
    final countedAt = occurredAt.isAfter(now) ? now : occurredAt;
    if (!_isWithinWindow(action, countedAt)) {
      return reject(ExternalConfirmationRejection.occurredOutsideWindow);
    }
    if (!_isWithinWindow(action, now)) {
      return reject(ExternalConfirmationRejection.actionUnavailable);
    }
    // Late delivery may still count for the period the action happened in,
    // but only shortly after that period ended, so one burst cannot credit
    // several consecutive periods.
    final periodEnd = actionPeriodEnd(
      action.recurrence,
      action.timeZone,
      countedAt,
    );
    if (periodEnd != null &&
        now.isAfter(periodEnd.add(appConfirmationLatePeriodGrace))) {
      return reject(ExternalConfirmationRejection.occurredOutsidePeriod);
    }
    if (await _revokedAppName(
          session,
          actionId: actionId,
          transaction: transaction,
        ) !=
        null) {
      return reject(ExternalConfirmationRejection.actionUnavailable);
    }

    final periodKey = _periodKey(action, countedAt);
    var attempt = await ActionAttempt.db.findFirstRow(
      session,
      where: (table) =>
          table.actionDefinitionId.equals(actionId) &
          table.participantAuthUserId.equals(authUserId) &
          table.periodKey.equals(periodKey),
      transaction: transaction,
    );
    if (attempt == null) {
      if (!_isOpen(action, now)) {
        return reject(ExternalConfirmationRejection.actionUnavailable);
      }
      attempt = await _reserveAttempt(
        session,
        transaction: transaction,
        action: action,
        authUserId: authUserId,
        periodKey: periodKey,
        idempotencyKey: 'app:${app.id}:$eventId',
      );
    }

    final lockedAttempt = await _ownedAttempt(
      session,
      attempt.id!,
      authUserId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lockedAttempt.status == ActionAttemptStatus.verified ||
        lockedAttempt.status == ActionAttemptStatus.capacityReached) {
      return ExternalConfirmationAccepted(
        actionDefinitionId: actionId,
        attempt: attemptView(lockedAttempt),
        alreadyComplete: true,
      );
    }

    final candidateEvidence = ActionEvidence(
      attemptId: lockedAttempt.id!,
      requirementId: requirement.id!,
      kind: ActionRequirementKind.externalApp,
      sha256Digest: eventDigest,
      capturedAt: occurredAt.toUtc(),
      submittedAt: now,
    );
    final abuseDecision = await abuseGate.assess(
      session,
      action: action,
      attempt: lockedAttempt,
      evidence: candidateEvidence,
      phase: AbuseAssessmentPhase.evidenceSubmission,
      transaction: transaction,
    );
    final evaluation = _withAbuseDecision(
      _Evaluation(
        status: EvidenceDecisionStatus.accepted,
        verifierType: appConfirmationVerifierType,
        confidence: 1,
        reasonCode: 'app_confirmed',
        summary: 'Confirmed by ${app.name}.',
      ),
      abuseDecision,
    );
    final existing = await ActionEvidence.db.findFirstRow(
      session,
      where: (table) =>
          table.attemptId.equals(lockedAttempt.id) &
          table.requirementId.equals(requirement.id),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final evidence = existing == null
        ? await ActionEvidence.db.insertRow(
            session,
            candidateEvidence,
            transaction: transaction,
          )
        : await ActionEvidence.db.updateRow(
            session,
            existing.copyWith(
              sha256Digest: eventDigest,
              capturedAt: occurredAt.toUtc(),
              submittedAt: now,
            ),
            transaction: transaction,
          );
    await _insertDecision(session, evidence, evaluation, now, transaction);
    await ActionAttempt.db.updateRow(
      session,
      lockedAttempt.copyWith(
        status: ActionAttemptStatus.collectingEvidence,
        rejectionCode: null,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    // The delivery commits after this returns; the confirmation route
    // schedules any payout once the attempt is visible.
    final completed = await completeAttempt(
      session,
      authUserId: authUserId,
      attemptId: lockedAttempt.id!,
      enclosingTransaction: transaction,
    );
    return ExternalConfirmationAccepted(
      actionDefinitionId: actionId,
      attempt: completed,
      alreadyComplete: false,
    );
  }

  /// Name of a revoked App that [actionId] relies on, if any. A revoked App
  /// can no longer confirm, so new attempts would strand.
  Future<String?> _revokedAppName(
    Session session, {
    required UuidValue actionId,
    required Transaction transaction,
  }) async {
    final rows = await session.db.unsafeQuery(
      '''
SELECT p."name"
FROM "verily_action_external_rule" AS r
JOIN "verily_action_requirement" AS q ON q."id" = r."requirementId"
JOIN "verily_app" AS p ON p."id" = r."appId"
WHERE q."actionDefinitionId" = CAST(@actionId AS uuid)
  AND p."status" <> @active
ORDER BY p."name"
LIMIT 1;
''',
      parameters: QueryParameters.named({
        'actionId': actionId.toString(),
        'active': VerilyAppStatus.active.name,
      }),
      transaction: transaction,
    );
    return rows.isEmpty ? null : rows.first.first! as String;
  }

  /// The requirement of [actionId] that [appId] may confirm.
  Future<ActionRequirement?> _externalRequirement(
    Session session, {
    required UuidValue actionId,
    required UuidValue appId,
    required Transaction transaction,
  }) async {
    final requirements = await ActionRequirement.db.find(
      session,
      where: (table) =>
          table.actionDefinitionId.equals(actionId) &
          table.kind.equals(ActionRequirementKind.externalApp),
      transaction: transaction,
    );
    if (requirements.isEmpty) return null;
    final rule = await ActionExternalRule.db.findFirstRow(
      session,
      where: (table) =>
          table.appId.equals(appId) &
          table.requirementId.inSet({
            for (final requirement in requirements) requirement.id!,
          }),
      transaction: transaction,
    );
    if (rule == null) return null;
    return requirements.firstWhere(
      (requirement) => requirement.id == rule.requirementId,
    );
  }

  Future<List<ActionAttemptView>> listMyAttempts(
    Session session, {
    required UuidValue authUserId,
    int limit = 50,
  }) async {
    final attempts = await ActionAttempt.db.find(
      session,
      where: (table) => table.participantAuthUserId.equals(authUserId),
      orderBy: (table) => table.updatedAt.desc(),
      limit: limit.clamp(1, 100),
    );
    final payouts = await views.payoutsByAttempt(
      session,
      attemptIds: {for (final attempt in attempts) attempt.id!},
    );
    return [
      for (final attempt in attempts)
        attemptView(attempt, payout: payouts[attempt.id]),
    ];
  }

  Future<_Evaluation> _evaluateDeterministic(
    Session session,
    ActionRequirement requirement,
    ActionEvidenceInput input, {
    required UuidValue authUserId,
    Transaction? transaction,
  }) async {
    switch (requirement.kind) {
      case ActionRequirementKind.location:
        return _evaluateLocation(
          session,
          requirement,
          input,
          authUserId: authUserId,
          transaction: transaction,
        );
      case ActionRequirementKind.qrCode:
        final rule = await ActionQrRule.db.findFirstRow(
          session,
          where: (table) => table.requirementId.equals(requirement.id),
          transaction: transaction,
        );
        if (rule == null) throw StateError('QR rule is missing.');
        final code = requiredText(input.qrCode ?? '', 'qrCode', maxLength: 512);
        final digest = secretSha256Hex(code);
        final now = clock().toUtc();
        final challenge = await ActionQrChallenge.db.findFirstRow(
          session,
          where: (table) =>
              table.requirementId.equals(requirement.id) &
              table.secretHash.equals(digest) &
              (table.expiresAt > now) &
              (table.usedAt.equals(null) |
                  table.usedByAttemptId.equals(input.attemptId)),
          transaction: transaction,
        );
        final staticAccepted = allowStaticQrCodes && digest == rule.secretHash;
        final accepted = challenge != null || staticAccepted;
        return _Evaluation(
          status: accepted
              ? EvidenceDecisionStatus.accepted
              : EvidenceDecisionStatus.rejected,
          verifierType: 'qr-digest',
          confidence: accepted ? 1 : 0,
          reasonCode: accepted ? 'qr_code_matched' : 'qr_code_mismatch',
          summary: accepted
              ? 'Venue code accepted.'
              : 'That venue code was not recognised.',
          qrChallengeId: challenge?.id,
        );
      case ActionRequirementKind.motion:
        final persistedRule = await ActionMotionRule.db.findFirstRow(
          session,
          where: (table) => table.requirementId.equals(requirement.id),
          transaction: transaction,
        );
        if (persistedRule == null) throw StateError('Motion rule is missing.');
        final analysis = const MotionEvidenceAnalyzer().analyze(
          samples: _motionSamples(input),
          rule: motionEvidenceRule(persistedRule),
        );
        return _Evaluation(
          status: analysis.accepted
              ? EvidenceDecisionStatus.accepted
              : EvidenceDecisionStatus.rejected,
          verifierType: 'device-motion-v1',
          confidence: analysis.score,
          reasonCode: analysis.reasonCode,
          summary: analysis.accepted
              ? 'Phone motion accepted.'
              : 'The phone motion did not match this action.',
          motionAnalysisJson: jsonEncode(analysis.toJson()),
        );
      case ActionRequirementKind.video ||
          ActionRequirementKind.photo ||
          ActionRequirementKind.audio:
        throw StateError(_mediaProofMessage);
      case ActionRequirementKind.externalApp:
        throw StateError(_externalProofMessage);
    }
  }

  Future<_Evaluation> _evaluateLocation(
    Session session,
    ActionRequirement requirement,
    ActionEvidenceInput input, {
    required UuidValue authUserId,
    required Transaction? transaction,
  }) async {
    final rule = await ActionLocationRule.db.findFirstRow(
      session,
      where: (table) => table.requirementId.equals(requirement.id),
      transaction: transaction,
    );
    if (rule == null) throw StateError('Location rule is missing.');
    final latitude = input.latitude;
    final longitude = input.longitude;
    final accuracy = input.accuracyMeters;
    if (latitude == null || longitude == null || accuracy == null) {
      throw ArgumentError('Location evidence is incomplete.');
    }
    if (!validCoordinates(latitude, longitude) ||
        !accuracy.isFinite ||
        accuracy < 0) {
      throw ArgumentError('Location evidence is invalid.');
    }
    final point = GeographyPoint(latitude: latitude, longitude: longitude);
    final current = LocationObservation(
      accuracyMeters: accuracy,
      capturedAt: input.capturedAt,
    );
    final freshness = locationEvidencePolicy.evaluate(
      now: clock(),
      current: current,
    );
    if (freshness == LocationEvidenceRisk.stale) {
      return const _Evaluation(
        status: EvidenceDecisionStatus.rejected,
        verifierType: 'location-risk',
        confidence: 0,
        reasonCode: 'location_capture_stale',
        summary: 'Take a new location check and try again.',
      );
    }
    if (freshness == LocationEvidenceRisk.fromFuture) {
      return const _Evaluation(
        status: EvidenceDecisionStatus.rejected,
        verifierType: 'location-risk',
        confidence: 0,
        reasonCode: 'location_capture_time_invalid',
        summary: 'Check the phone clock, then take a new location check.',
      );
    }
    if (accuracy > rule.maxAccuracyMeters) {
      return const _Evaluation(
        status: EvidenceDecisionStatus.rejected,
        verifierType: 'geofence',
        confidence: 0,
        reasonCode: 'location_accuracy_too_low',
        summary: 'The location was not precise enough.',
      );
    }
    // ST_DWithin on the geography column measures on the WGS 84 spheroid,
    // inclusive of the radius boundary.
    final accepted =
        await ActionLocationRule.db.count(
          session,
          where: (table) =>
              table.id.equals(rule.id) &
              table.location.distanceWithin(point, rule.radiusMeters),
          transaction: transaction,
        ) ==
        1;
    if (accepted) {
      final previous = await _latestAcceptedLocation(
        session,
        authUserId: authUserId,
        before: input.capturedAt,
        from: point,
        transaction: transaction,
      );
      final travel = locationEvidencePolicy.evaluate(
        now: clock(),
        current: current,
        previous: previous,
      );
      if (travel == LocationEvidenceRisk.implausibleTravel) {
        return const _Evaluation(
          status: EvidenceDecisionStatus.manualReview,
          verifierType: 'location-risk',
          reasonCode: 'location_travel_needs_review',
          summary: needsReviewSummary,
        );
      }
    }
    return _Evaluation(
      status: accepted
          ? EvidenceDecisionStatus.accepted
          : EvidenceDecisionStatus.rejected,
      verifierType: 'geofence',
      confidence: accepted ? 1 : 0,
      reasonCode: accepted ? 'inside_geofence' : 'outside_geofence',
      summary: accepted
          ? 'Location check accepted.'
          : 'The check-in was outside the place.',
    );
  }

  /// The participant's newest earlier accepted check-in and its PostGIS
  /// distance from [from]. The latest-decision lateral join has no ORM
  /// equivalent, so this stays one parameterized query.
  Future<PreviousLocationObservation?> _latestAcceptedLocation(
    Session session, {
    required UuidValue authUserId,
    required DateTime before,
    required GeographyPoint from,
    required Transaction? transaction,
  }) async {
    final rows = await session.db.unsafeQuery(
      '''
SELECT
  ST_Distance(e."location", ST_GeogFromText(@from)),
  e."accuracyMeters",
  e."capturedAt"
FROM "verily_action_evidence" AS e
JOIN "verily_action_attempt" AS a ON a."id" = e."attemptId"
JOIN LATERAL (
  SELECT d."status"
  FROM "verily_evidence_decision" AS d
  WHERE d."evidenceId" = e."id"
  ORDER BY d."createdAt" DESC, d."id" DESC
  LIMIT 1
) AS latest ON latest."status" = @acceptedStatus
WHERE a."participantAuthUserId" = CAST(@participantAuthUserId AS uuid)
  AND e."kind" = @locationKind
  AND e."location" IS NOT NULL
  AND e."capturedAt" <= @before
ORDER BY e."capturedAt" DESC
LIMIT 1;
''',
      transaction: transaction,
      parameters: QueryParameters.named({
        'from': from.toEwkt(),
        'acceptedStatus': EvidenceDecisionStatus.accepted.name,
        'participantAuthUserId': authUserId.toString(),
        'locationKind': ActionRequirementKind.location.name,
        'before': before.toUtc(),
      }),
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return PreviousLocationObservation(
      distanceMeters: row[0]! as double,
      accuracyMeters: row[1]! as double,
      capturedAt: (row[2]! as DateTime).toUtc(),
    );
  }

  Future<void> _consumeCaptureChallenge(
    Session session, {
    required _Evaluation evaluation,
    required ActionAttempt attempt,
    required ActionRequirement requirement,
    required UuidValue authUserId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final challengeId = evaluation.captureChallengeId;
    if (challengeId == null) return;
    final challenge = await ActionCaptureChallenge.db.findFirstRow(
      session,
      where: (table) => table.id.equals(challengeId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (challenge == null ||
        challenge.attemptId != attempt.id ||
        challenge.requirementId != requirement.id ||
        challenge.participantAuthUserId != authUserId ||
        challenge.usedAt != null ||
        !challenge.expiresAt.isAfter(now)) {
      throw StateError('That capture check has expired or was already used.');
    }
    await ActionCaptureChallenge.db.updateRow(
      session,
      challenge.copyWith(
        usedAt: now,
        provider: evaluation.integrityProvider,
        verdict: evaluation.integrityVerdict,
        tokenHash: evaluation.integrityTokenHash,
      ),
      transaction: transaction,
    );
  }

  Future<void> _insertDecision(
    Session session,
    ActionEvidence evidence,
    _Evaluation evaluation,
    DateTime now,
    Transaction transaction,
  ) async {
    await EvidenceDecision.db.insertRow(
      session,
      EvidenceDecision(
        evidenceId: evidence.id!,
        status: evaluation.status!,
        verifierType: evaluation.verifierType,
        modelName: evaluation.modelName,
        modelVersion: evaluation.modelVersion,
        confidence: evaluation.confidence,
        reasonCode: evaluation.reasonCode,
        summary: evaluation.summary,
        createdAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<ActionDefinition> _requireLiveAction(
    Session session, {
    required UuidValue actionId,
    required Transaction transaction,
  }) async {
    await moderationGate.assertActionAllowed(
      session,
      actionId: actionId,
      transaction: transaction,
    );
    final action = await ActionDefinition.db.findById(
      session,
      actionId,
      transaction: transaction,
    );
    if (action == null || !_isWithinWindow(action, clock())) {
      throw StateError('This action is not accepting proof right now.');
    }
    return action;
  }

  Future<ActionRequirement> _attemptRequirement(
    Session session, {
    required ActionAttempt attempt,
    required UuidValue requirementId,
    required Transaction transaction,
  }) async {
    final requirement = await ActionRequirement.db.findById(
      session,
      requirementId,
      transaction: transaction,
    );
    if (requirement == null ||
        requirement.actionDefinitionId != attempt.actionDefinitionId) {
      throw StateError('The requirement does not belong to this attempt.');
    }
    return requirement;
  }

  Future<ActionAttempt> _ownedAttempt(
    Session session,
    UuidValue attemptId,
    UuidValue authUserId, {
    Transaction? transaction,
    LockMode? lockMode,
  }) async {
    final attempt = await ActionAttempt.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(attemptId) &
          table.participantAuthUserId.equals(authUserId),
      transaction: transaction,
      lockMode: lockMode,
    );
    if (attempt == null) throw StateError('Action attempt was not found.');
    return attempt;
  }

  bool _isOpen(ActionDefinition action, DateTime now) {
    final hasCapacity =
        action.maxVerifiedCompletions == null ||
        action.verifiedCompletions < action.maxVerifiedCompletions!;
    return _isWithinWindow(action, now) && hasCapacity;
  }

  String _periodKey(ActionDefinition action, DateTime instant) {
    return actionPeriodKey(action.recurrence, action.timeZone, instant);
  }
}

/// The newest append-only decision for one evidence row.
Future<EvidenceDecision?> latestDecision(
  Session session, {
  required UuidValue evidenceId,
  Transaction? transaction,
  LockMode? lockMode,
}) {
  return EvidenceDecision.db.findFirstRow(
    session,
    where: (table) => table.evidenceId.equals(evidenceId),
    orderByList: (table) => [table.createdAt.desc(), table.id.desc()],
    transaction: transaction,
    lockMode: lockMode,
  );
}

/// Whether permanent, creator-entered static QR codes may satisfy a proof.
///
/// Static codes are a local fixture only: they are reusable by design, so a
/// code shared beyond the venue verifies forever. The default is fail-closed
/// and `VERILY_STATIC_QR_ENABLED=true` is an explicit opt-in.
bool staticQrCodesAllowed([Map<String, String>? environment]) {
  return switch ((environment ??
      Platform.environment)['VERILY_STATIC_QR_ENABLED']) {
    null || '' || 'false' => false,
    'true' => true,
    final value => throw StateError(
      'VERILY_STATIC_QR_ENABLED must be true or false, not $value.',
    ),
  };
}

bool _isWithinWindow(ActionDefinition action, DateTime now) {
  final current = now.toUtc();
  return action.status == ActionDefinitionStatus.active &&
      (action.opensAt == null || !action.opensAt!.isAfter(current)) &&
      (action.closesAt == null || action.closesAt!.isAfter(current));
}

void _requireOpenAttempt(ActionAttempt attempt) {
  if (attempt.status == ActionAttemptStatus.verified ||
      attempt.status == ActionAttemptStatus.capacityReached) {
    throw StateError('This attempt is already complete.');
  }
}

/// Rounds a coordinate to three decimal places, about 110 metres.
double _coarse(double value) => (value * 1000).roundToDouble() / 1000;

String _deterministicBindingHash(
  ActionRequirement requirement,
  ActionEvidenceInput input,
) {
  return switch (requirement.kind) {
    ActionRequirementKind.location => locationEvidenceBindingHash(
      capturedAt: input.capturedAt,
      latitude:
          input.latitude ??
          (throw ArgumentError('Location evidence needs latitude.')),
      longitude:
          input.longitude ??
          (throw ArgumentError('Location evidence needs longitude.')),
      accuracyMeters:
          input.accuracyMeters ??
          (throw ArgumentError('Location evidence needs accuracy.')),
    ),
    ActionRequirementKind.qrCode => qrEvidenceBindingHash(
      capturedAt: input.capturedAt,
      code: input.qrCode ?? '',
    ),
    ActionRequirementKind.motion => _motionBindingHash(input),
    ActionRequirementKind.video ||
    ActionRequirementKind.photo ||
    ActionRequirementKind.audio => throw StateError(_mediaProofMessage),
    ActionRequirementKind.externalApp => throw StateError(
      _externalProofMessage,
    ),
  };
}

ActionEvidence _deterministicEvidence(
  UuidValue attemptId,
  ActionRequirement requirement,
  ActionEvidenceInput input,
  _Evaluation evaluation,
  DateTime submittedAt,
) {
  final motionFields = requirement.kind == ActionRequirementKind.motion
      ? _motionEvidenceFields(input)
      : null;
  return ActionEvidence(
    attemptId: attemptId,
    requirementId: requirement.id!,
    kind: requirement.kind,
    sha256Digest: switch (requirement.kind) {
      ActionRequirementKind.qrCode => secretSha256Hex(input.qrCode ?? ''),
      ActionRequirementKind.motion => motionFields!.traceSha256,
      _ => null,
    },
    location: _evidenceLocation(input),
    accuracyMeters: input.accuracyMeters,
    motionTraceJson: motionFields?.traceJson,
    motionTraceSha256: motionFields?.traceSha256,
    motionSampleCount: motionFields?.sampleCount,
    motionDurationMilliseconds: motionFields?.durationMilliseconds,
    motionAnalysisJson: evaluation.motionAnalysisJson,
    provenanceLevel: evaluation.provenanceLevel,
    captureManifest: evaluation.captureManifest,
    captureSignature: evaluation.captureSignature,
    capturePublicKey: evaluation.capturePublicKey,
    captureKeyId: evaluation.captureKeyId,
    captureKeyStorage: evaluation.captureKeyStorage,
    capturedAt: input.capturedAt.toUtc(),
    submittedAt: submittedAt,
  );
}

/// PostGIS silently wraps out-of-range geography coordinates, so every
/// evidence kind validates ranges before a point reaches the database.
GeographyPoint? _evidenceLocation(ActionEvidenceInput input) {
  final latitude = input.latitude;
  final longitude = input.longitude;
  if (latitude == null && longitude == null) return null;
  if (latitude == null ||
      longitude == null ||
      !validCoordinates(latitude, longitude)) {
    throw ArgumentError('Evidence coordinates are invalid.');
  }
  return GeographyPoint(latitude: latitude, longitude: longitude);
}

/// The on-device count is advisory metadata kept for review and calibration.
/// It is bounded so stored rows stay well-formed, but it is never forwarded
/// to a verifier and never changes a decision.
void _validateDeviceRepetitionCount(
  ActionMediaRule rule,
  MediaUploadConfirmation confirmation,
) {
  final count = confirmation.deviceRepetitionCount;
  final version = confirmation.deviceTrackerVersion;
  if (count == null && version == null) return;
  if (rule.movementKind == null) {
    throw ArgumentError('Device repetition counts need a movement video.');
  }
  if (count == null ||
      version == null ||
      count < 0 ||
      count > _maximumDeviceRepetitionCount ||
      !_deviceTrackerVersionPattern.hasMatch(version)) {
    throw ArgumentError('The device repetition count is invalid.');
  }
}

// A 300-second recording at the fastest tracked pace stays well below this.
const _maximumDeviceRepetitionCount = 5000;
final _deviceTrackerVersionPattern = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');

String _motionBindingHash(ActionEvidenceInput input) {
  final fields = _motionEvidenceFields(input);
  return motionEvidenceBindingHash(
    capturedAt: input.capturedAt,
    traceSha256: fields.traceSha256,
    sampleCount: fields.sampleCount,
    durationMilliseconds: fields.durationMilliseconds,
  );
}

({
  String traceJson,
  String traceSha256,
  int sampleCount,
  int durationMilliseconds,
})
_motionEvidenceFields(ActionEvidenceInput input) {
  final samples = _motionSamples(input);
  return (
    traceJson: canonicalMotionTraceJson(samples),
    traceSha256: motionTraceSha256(samples),
    sampleCount: samples.length,
    durationMilliseconds: (samples.last.elapsedMicroseconds / 1000).round(),
  );
}

List<MotionEvidenceSample> _motionSamples(ActionEvidenceInput input) {
  final samples = input.motionSamples;
  if (samples == null || samples.isEmpty) {
    throw ArgumentError('Motion evidence needs sensor samples.');
  }
  return [
    for (final sample in samples)
      MotionEvidenceSample(
        elapsedMicroseconds: sample.elapsedMicroseconds,
        gyroscopeX: sample.gyroscopeX,
        gyroscopeY: sample.gyroscopeY,
        gyroscopeZ: sample.gyroscopeZ,
        accelerationX: sample.accelerationX,
        accelerationY: sample.accelerationY,
        accelerationZ: sample.accelerationZ,
      ),
  ];
}

double _meanConfidence(List<EvidenceDecision> decisions) {
  final values = decisions
      .map((decision) => decision.confidence)
      .whereType<double>()
      .toList(growable: false);
  if (values.isEmpty) return 1;
  return values.reduce((left, right) => left + right) / values.length;
}

/// A media proof with no immediate decision: it waits for its verifier.
const _queuedEvaluation = _Evaluation(
  status: null,
  verifierType: 'media-verification-queued',
  reasonCode: 'media_verification_queued',
  summary: 'Your proof is being checked.',
);

_Evaluation _withAbuseDecision(_Evaluation proof, AbuseRiskDecision decision) {
  if (decision.disposition == AbuseRiskDisposition.allow) return proof;
  final rejected = decision.disposition == AbuseRiskDisposition.reject;
  return proof.copyWith(
    status: rejected
        ? EvidenceDecisionStatus.rejected
        : EvidenceDecisionStatus.manualReview,
    verifierType: 'abuse-risk',
    reasonCode: _abuseReasonCode(decision),
    summary: rejected
        ? 'This proof could not be accepted.'
        : needsReviewSummary,
    confidence: 0,
  );
}

String _abuseReasonCode(AbuseRiskDecision decision) {
  if (decision.disposition == AbuseRiskDisposition.manualReview) {
    return 'abuse_review_required';
  }
  final signal = decision.signals.firstOrNull;
  return signal == null ? 'abuse_proof_rejected' : 'abuse_${signal.name}';
}

_Evaluation _withCaptureIntegrity(
  _Evaluation proof,
  CaptureIntegrityResult? integrity,
) {
  if (integrity == null) return proof;
  if (!integrity.trusted) {
    // An untrusted capture consumes its capture challenge but never a venue
    // code, and carries no model provenance.
    return _Evaluation(
      status: EvidenceDecisionStatus.rejected,
      verifierType: integrity.provider,
      reasonCode: integrity.reasonCode,
      summary: 'This phone could not verify the capture.',
      confidence: 0,
      captureChallengeId: integrity.challengeId,
      integrityProvider: integrity.provider,
      integrityVerdict: integrity.reasonCode,
      integrityTokenHash: integrity.tokenHash,
      provenanceLevel: integrity.provenanceLevel,
      motionAnalysisJson: proof.motionAnalysisJson,
    );
  }
  return proof.copyWith(
    captureChallengeId: integrity.challengeId,
    integrityProvider: integrity.provider,
    integrityVerdict: integrity.reasonCode,
    integrityTokenHash: integrity.tokenHash,
    provenanceLevel: integrity.provenanceLevel,
    captureManifest: integrity.captureManifest,
    captureSignature: integrity.captureSignature,
    capturePublicKey: integrity.capturePublicKey,
    captureKeyId: integrity.captureKeyId,
    captureKeyStorage: integrity.captureKeyStorage,
  );
}

class _Evaluation {
  const _Evaluation({
    required this.status,
    required this.verifierType,
    required this.reasonCode,
    required this.summary,
    this.modelName,
    this.modelVersion,
    this.confidence,
    this.qrChallengeId,
    this.captureChallengeId,
    this.integrityProvider,
    this.integrityVerdict,
    this.integrityTokenHash,
    this.provenanceLevel = EvidenceProvenanceLevel.basic,
    this.captureManifest,
    this.captureSignature,
    this.capturePublicKey,
    this.captureKeyId,
    this.captureKeyStorage,
    this.motionAnalysisJson,
  });

  /// Null while a media proof waits for its verifier.
  final EvidenceDecisionStatus? status;
  final String verifierType;
  final String reasonCode;
  final String summary;
  final String? modelName;
  final String? modelVersion;
  final double? confidence;
  final UuidValue? qrChallengeId;
  final UuidValue? captureChallengeId;
  final String? integrityProvider;
  final String? integrityVerdict;
  final String? integrityTokenHash;
  final EvidenceProvenanceLevel provenanceLevel;
  final String? captureManifest;
  final String? captureSignature;
  final String? capturePublicKey;
  final String? captureKeyId;
  final String? captureKeyStorage;
  final String? motionAnalysisJson;

  _Evaluation copyWith({
    EvidenceDecisionStatus? status,
    String? verifierType,
    String? reasonCode,
    String? summary,
    double? confidence,
    UuidValue? captureChallengeId,
    String? integrityProvider,
    String? integrityVerdict,
    String? integrityTokenHash,
    EvidenceProvenanceLevel? provenanceLevel,
    String? captureManifest,
    String? captureSignature,
    String? capturePublicKey,
    String? captureKeyId,
    String? captureKeyStorage,
  }) => _Evaluation(
    status: status ?? this.status,
    verifierType: verifierType ?? this.verifierType,
    reasonCode: reasonCode ?? this.reasonCode,
    summary: summary ?? this.summary,
    modelName: modelName,
    modelVersion: modelVersion,
    confidence: confidence ?? this.confidence,
    qrChallengeId: qrChallengeId,
    captureChallengeId: captureChallengeId ?? this.captureChallengeId,
    integrityProvider: integrityProvider ?? this.integrityProvider,
    integrityVerdict: integrityVerdict ?? this.integrityVerdict,
    integrityTokenHash: integrityTokenHash ?? this.integrityTokenHash,
    provenanceLevel: provenanceLevel ?? this.provenanceLevel,
    captureManifest: captureManifest ?? this.captureManifest,
    captureSignature: captureSignature ?? this.captureSignature,
    capturePublicKey: capturePublicKey ?? this.capturePublicKey,
    captureKeyId: captureKeyId ?? this.captureKeyId,
    captureKeyStorage: captureKeyStorage ?? this.captureKeyStorage,
    motionAnalysisJson: motionAnalysisJson,
  );
}
