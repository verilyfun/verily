import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/abuse/abuse_privacy.dart';
import 'package:verily_server/src/abuse/abuse_risk_policy.dart';
import 'package:verily_server/src/abuse/abuse_risk_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

enum AbuseAssessmentPhase { evidenceSubmission, valueAuthorization }

/// Runtime boundary called before an accepted proof and again before value.
abstract interface class ActionAbuseGate {
  bool get isEnforced;

  Future<AbuseRiskDecision> assess(
    Session session, {
    required ActionDefinition action,
    required ActionAttempt attempt,
    required ActionEvidence evidence,
    required AbuseAssessmentPhase phase,
    required Transaction transaction,
    bool? singleUseQr,
  });
}

/// Development-only default. Production readiness rejects this configuration.
final class DisabledActionAbuseGate implements ActionAbuseGate {
  const DisabledActionAbuseGate();

  @override
  bool get isEnforced => false;

  @override
  Future<AbuseRiskDecision> assess(
    Session session, {
    required ActionDefinition action,
    required ActionAttempt attempt,
    required ActionEvidence evidence,
    required AbuseAssessmentPhase phase,
    required Transaction transaction,
    bool? singleUseQr,
  }) async => _allowDecision;
}

/// PostgreSQL-backed, deterministic correlation gate.
///
/// Raw account, attempt, device, and location values exist only while building
/// one in-memory observation. The durable row stores bounded decision codes.
final class ServerpodActionAbuseGate implements ActionAbuseGate {
  ServerpodActionAbuseGate({
    required this._pseudonymizer,
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  final AbusePseudonymizer _pseudonymizer;
  final DateTime Function() _clock;

  @override
  bool get isEnforced => true;

  @override
  Future<AbuseRiskDecision> assess(
    Session session, {
    required ActionDefinition action,
    required ActionAttempt attempt,
    required ActionEvidence evidence,
    required AbuseAssessmentPhase phase,
    required Transaction transaction,
    bool? singleUseQr,
  }) async {
    final now = _clock().toUtc();
    final resolvedSingleUseQr =
        singleUseQr ??
        await _isSingleUseQr(session, evidence, transaction: transaction);
    final candidate = _observation(
      action: action,
      attempt: attempt,
      evidence: evidence,
      receivedAt: now,
      singleUseQr: resolvedSingleUseQr,
    );
    final assessmentKey = _assessmentKey(
      phase: phase,
      action: action,
      evidence: evidence,
      candidate: candidate,
    );

    // The per-action lock serializes the final read/decision/write boundary.
    await session.db.unsafeQuery(
      'SELECT pg_advisory_xact_lock(hashtextextended(@lockKey, 0));',
      parameters: QueryParameters.named({
        'lockKey': 'verily:abuse:${action.id}',
      }),
      transaction: transaction,
    );

    final existing = await AbuseRiskAssessment.db.findFirstRow(
      session,
      where: (table) => table.assessmentKey.equals(assessmentKey),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (existing != null) return _decisionFrom(existing);

    final service = AbuseRiskService(
      loadHistory: (query) => _loadHistory(
        session,
        query,
        action: action,
        attempt: attempt,
        evidence: evidence,
        transaction: transaction,
      ),
    );
    final decision = await service.evaluate(candidate);
    final row = AbuseRiskAssessment(
      actionDefinitionId: action.id!,
      assessmentKey: assessmentKey,
      phase: phase.name,
      policyVersion: AbuseRiskDecision.policyVersion,
      disposition: decision.disposition.name,
      tier: decision.tier.name,
      score: decision.score,
      signalCodes: [for (final signal in decision.signals) signal.name],
      correlationWindowStartsAt: now.subtract(AbuseRiskPolicy.historyWindow),
      createdAt: now,
    );

    await AbuseRiskAssessment.db.insertRow(
      session,
      row,
      transaction: transaction,
    );
    return decision;
  }

  Future<List<AbuseObservation>> _loadHistory(
    Session session,
    AbuseHistoryQuery query, {
    required ActionDefinition action,
    required ActionAttempt attempt,
    required ActionEvidence evidence,
    required Transaction transaction,
  }) async {
    final rows = await session.db.unsafeQuery(
      _historySql,
      parameters: QueryParameters.named({
        'startsAt': query.startsAt.toUtc(),
        'receivedAt': query.candidate.receivedAt.toUtc(),
        'accountId': attempt.participantAuthUserId.toString(),
        'creatorId': action.creatorAuthUserId.toString(),
        'actionId': action.id.toString(),
        'digest': evidence.sha256Digest,
        'deviceKeyId': evidence.captureDeviceKeyId,
        'capturedFrom': evidence.capturedAt.toUtc().subtract(
          AbuseRiskPolicy.locationTimeWindow,
        ),
        'capturedUntil': evidence.capturedAt.toUtc().add(
          AbuseRiskPolicy.locationTimeWindow,
        ),
        'limit': query.limit,
      }),
      transaction: transaction,
    );

    return [for (final row in rows) _historyObservation(row)];
  }

  AbuseObservation _historyObservation(List<Object?> row) {
    final kind = ActionRequirementKind.fromJson(row[4]! as String);
    final latitude = row[8] as double?;
    final longitude = row[9] as double?;

    return AbuseObservation(
      accountPseudonym: _pseudonymizer.account(row[0]! as String),
      creatorPseudonym: _pseudonymizer.creator(row[1]! as String),
      actionPseudonym: _pseudonymizer.action(row[2]! as String),
      attemptPseudonym: _pseudonymizer.attempt(row[3]! as String),
      evidenceKind: _kind(kind, singleUseQr: row[5]! as bool),
      evidenceDigest: row[6] as String?,
      devicePseudonym: switch (row[7] as String?) {
        final value? => _pseudonymizer.device(value),
        null => null,
      },
      coarseLocationPseudonym: latitude == null || longitude == null
          ? null
          : _pseudonymizer.coarseLocation(
              latitude: latitude,
              longitude: longitude,
            ),
      capturedAt: (row[10]! as DateTime).toUtc(),
      receivedAt: (row[11]! as DateTime).toUtc(),
      captureIntegrityTrusted: _captureIntegrityTrusted(
        kind,
        EvidenceProvenanceLevel.fromJson(row[12]! as String),
      ),
      immutableEvidenceBound: _immutableEvidenceBound(
        kind,
        storagePath: row[13] as String?,
        storageVersionId: row[14] as String?,
        digest: row[6] as String?,
        motionTraceSha256: row[15] as String?,
        motionTraceJson: row[16] as String?,
      ),
    );
  }

  AbuseObservation _observation({
    required ActionDefinition action,
    required ActionAttempt attempt,
    required ActionEvidence evidence,
    required DateTime receivedAt,
    required bool singleUseQr,
  }) => AbuseObservation(
    accountPseudonym: _pseudonymizer.account(
      attempt.participantAuthUserId.toString(),
    ),
    creatorPseudonym: _pseudonymizer.creator(
      action.creatorAuthUserId.toString(),
    ),
    actionPseudonym: _pseudonymizer.action(action.id.toString()),
    attemptPseudonym: _pseudonymizer.attempt(attempt.id.toString()),
    evidenceKind: _kind(evidence.kind, singleUseQr: singleUseQr),
    evidenceDigest: evidence.sha256Digest,
    devicePseudonym: switch (evidence.captureDeviceKeyId) {
      final value? => _pseudonymizer.device(value),
      null => null,
    },
    coarseLocationPseudonym: switch (evidence.location) {
      final location? => _pseudonymizer.coarseLocation(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      null => null,
    },
    capturedAt: evidence.capturedAt.toUtc(),
    receivedAt: receivedAt,
    captureIntegrityTrusted: _captureIntegrityTrusted(
      evidence.kind,
      evidence.provenanceLevel,
    ),
    immutableEvidenceBound: _immutableEvidenceBound(
      evidence.kind,
      storagePath: evidence.storagePath,
      storageVersionId: evidence.storageVersionId,
      digest: evidence.sha256Digest,
      motionTraceSha256: evidence.motionTraceSha256,
      motionTraceJson: evidence.motionTraceJson,
    ),
  );

  Future<bool> _isSingleUseQr(
    Session session,
    ActionEvidence evidence, {
    required Transaction transaction,
  }) async {
    if (evidence.kind != ActionRequirementKind.qrCode) return false;
    final challenge = await ActionQrChallenge.db.findFirstRow(
      session,
      where: (table) =>
          table.requirementId.equals(evidence.requirementId) &
          table.usedByAttemptId.equals(evidence.attemptId),
      transaction: transaction,
    );
    return challenge != null;
  }

  String _assessmentKey({
    required AbuseAssessmentPhase phase,
    required ActionDefinition action,
    required ActionEvidence evidence,
    required AbuseObservation candidate,
  }) {
    final source = [
      AbuseRiskDecision.policyVersion,
      phase.name,
      action.id,
      candidate.attemptPseudonym,
      evidence.requirementId,
      evidence.sha256Digest ?? '',
      evidence.capturedAt.toUtc().toIso8601String(),
    ].join('\n');
    return sha256.convert(utf8.encode(source)).toString();
  }
}

/// Process-wide configuration is set before Serverpod constructs endpoints.
abstract final class ActionAbuseGateRegistry {
  static ActionAbuseGate _current = const DisabledActionAbuseGate();

  static ActionAbuseGate get current => _current;

  static void configureFromEnvironment(Map<String, String> environment) {
    _current = const DisabledActionAbuseGate();
    final mode = environment['VERILY_ABUSE_RUNTIME_MODE']?.trim() ?? 'disabled';
    if (mode == 'disabled') return;
    if (mode != 'enforced') {
      throw StateError(
        'VERILY_ABUSE_RUNTIME_MODE must be disabled or enforced.',
      );
    }
    if (environment['VERILY_CAPTURE_SIGNATURE_MODE']?.trim() != 'required') {
      throw StateError('Abuse enforcement requires signed device captures.');
    }

    _current = ServerpodActionAbuseGate(
      pseudonymizer: AbusePseudonymizer(
        secret: environment['VERILY_ABUSE_PSEUDONYM_SECRET'] ?? '',
        keyEpoch: environment['VERILY_ABUSE_PSEUDONYM_KEY_EPOCH']?.trim() ?? '',
      ),
    );
  }
}

AbuseEvidenceKind _kind(
  ActionRequirementKind kind, {
  required bool singleUseQr,
}) => switch (kind) {
  ActionRequirementKind.video => AbuseEvidenceKind.video,
  ActionRequirementKind.photo => AbuseEvidenceKind.photo,
  ActionRequirementKind.audio => AbuseEvidenceKind.audio,
  ActionRequirementKind.motion => AbuseEvidenceKind.motion,
  ActionRequirementKind.location => AbuseEvidenceKind.location,
  ActionRequirementKind.qrCode =>
    singleUseQr ? AbuseEvidenceKind.singleUseQr : AbuseEvidenceKind.reusableQr,
  ActionRequirementKind.externalApp => AbuseEvidenceKind.externalAttestation,
};

/// An App confirmation is authenticated server-to-server by the creator's App
/// key, so device-capture provenance does not apply to it. Every other kind is
/// trusted only with app attestation or a device signature.
bool _captureIntegrityTrusted(
  ActionRequirementKind kind,
  EvidenceProvenanceLevel provenance,
) =>
    kind == ActionRequirementKind.externalApp ||
    provenance != EvidenceProvenanceLevel.basic;

/// Media must be pinned to an immutable stored version and digest; a motion
/// trace must be stored with its own digest. Location and venue codes carry no
/// stored bytes.
bool _immutableEvidenceBound(
  ActionRequirementKind kind, {
  required String? storagePath,
  required String? storageVersionId,
  required String? digest,
  required String? motionTraceSha256,
  required String? motionTraceJson,
}) => switch (kind) {
  ActionRequirementKind.video ||
  ActionRequirementKind.photo ||
  ActionRequirementKind.audio =>
    (storagePath?.isNotEmpty ?? false) &&
        (storageVersionId?.isNotEmpty ?? false) &&
        (digest?.isNotEmpty ?? false),
  ActionRequirementKind.motion =>
    (motionTraceJson?.isNotEmpty ?? false) &&
        (motionTraceSha256?.isNotEmpty ?? false) &&
        motionTraceSha256 == digest,
  ActionRequirementKind.externalApp => digest?.isNotEmpty ?? false,
  ActionRequirementKind.location || ActionRequirementKind.qrCode => true,
};

AbuseRiskDecision _decisionFrom(AbuseRiskAssessment row) => AbuseRiskDecision(
  disposition: AbuseRiskDisposition.values.byName(row.disposition),
  tier: AbuseRiskTier.values.byName(row.tier),
  score: row.score,
  signals: List.unmodifiable([
    for (final value in row.signalCodes) AbuseSignalCode.values.byName(value),
  ]),
);

const _allowDecision = AbuseRiskDecision(
  disposition: AbuseRiskDisposition.allow,
  tier: AbuseRiskTier.low,
  score: 0,
  signals: [],
);

const _historySql = '''
SELECT
  a."participantAuthUserId"::text,
  d."creatorAuthUserId"::text,
  d."id"::text,
  a."id"::text,
  e."kind"::text,
  EXISTS (
    SELECT 1 FROM "verily_action_qr_challenge" AS q
    WHERE q."requirementId" = e."requirementId"
      AND q."usedByAttemptId" = e."attemptId"
  ),
  e."sha256Digest",
  e."captureDeviceKeyId",
  ST_Y(e."location"::geometry),
  ST_X(e."location"::geometry),
  e."capturedAt",
  e."submittedAt",
  e."provenanceLevel"::text,
  e."storagePath",
  e."storageVersionId",
  e."motionTraceSha256",
  e."motionTraceJson"
FROM "verily_action_evidence" AS e
JOIN "verily_action_attempt" AS a ON a."id" = e."attemptId"
JOIN "verily_action_definition" AS d ON d."id" = a."actionDefinitionId"
WHERE e."submittedAt" >= @startsAt
  AND e."submittedAt" <= @receivedAt
  AND (
    a."participantAuthUserId" = CAST(@accountId AS uuid)
    OR (CAST(@digest AS text) IS NOT NULL AND e."sha256Digest" = @digest)
    OR (CAST(@deviceKeyId AS text) IS NOT NULL
      AND e."captureDeviceKeyId" = @deviceKeyId)
    OR (
      d."creatorAuthUserId" = CAST(@creatorId AS uuid)
      AND d."id" = CAST(@actionId AS uuid)
      AND e."capturedAt" BETWEEN @capturedFrom AND @capturedUntil
    )
  )
ORDER BY e."submittedAt" DESC, e."id" DESC
LIMIT @limit;
''';
