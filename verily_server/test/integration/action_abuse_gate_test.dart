import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/abuse/abuse_privacy.dart';
import 'package:verily_server/src/abuse/abuse_risk_policy.dart';
import 'package:verily_server/src/abuse/action_abuse_gate.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

void main() {
  withServerpod('Given an enforced abuse gate and one video action', (
    sessionBuilder,
    _,
  ) {
    final creatorId = testId(0x401);
    final firstId = testId(0x402);
    final secondId = testId(0x403);
    final now = DateTime.utc(2026, 9, 4, 12);
    late ActionDefinition action;
    late ActionRequirement requirement;
    late ServerpodActionAbuseGate gate;

    setUp(() async {
      final session = sessionBuilder.build();
      await insertAccounts(session, {
        creatorId: 'Ada',
        firstId: 'Grace',
        secondId: 'Hedy',
      });
      action = await ActionDefinition.db.insertRow(
        session,
        ActionDefinition(
          creatorAuthUserId: creatorId,
          actionKey: 'one-video-one-person',
          title: 'Record one original action',
          description: 'Each participant records their own proof.',
          status: ActionDefinitionStatus.active,
          recurrence: ActionRecurrence.once,
          timeZone: 'UTC',
          publishedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      requirement = await ActionRequirement.db.insertRow(
        session,
        ActionRequirement(
          actionDefinitionId: action.id!,
          requirementKey: 'video',
          kind: ActionRequirementKind.video,
          title: 'Record it',
          instructions: 'Use one continuous recording.',
          position: 0,
          createdAt: now,
        ),
      );
      gate = ServerpodActionAbuseGate(
        pseudonymizer: AbusePseudonymizer(
          secret: 'test-only-abuse-pseudonym-secret-32-bytes',
          keyEpoch: 'pilot-2026-09',
        ),
        clock: () => now.add(const Duration(minutes: 1)),
      );
    });

    Future<AbuseRiskDecision> assess(
      Session session,
      ActionAttempt attempt,
      ActionEvidence evidence,
    ) => DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) => gate.assess(
        session,
        action: action,
        attempt: attempt,
        evidence: evidence,
        phase: AbuseAssessmentPhase.evidenceSubmission,
        transaction: transaction,
      ),
    );

    test(
      'when a second account submits the same recording then it is '
      'rejected as a replay',
      () async {
        final session = sessionBuilder.build();
        final digest = 'a' * 64;
        final firstAttempt = await _attempt(session, action, firstId, now);
        final secondAttempt = await _attempt(session, action, secondId, now);
        final firstEvidence = await _evidence(
          session,
          firstAttempt,
          requirement,
          digest: digest,
          capturedAt: now,
        );
        final firstDecision = await assess(
          session,
          firstAttempt,
          firstEvidence,
        );
        final secondEvidence = await _evidence(
          session,
          secondAttempt,
          requirement,
          digest: digest,
          capturedAt: now.add(const Duration(seconds: 1)),
        );

        final secondDecision = await assess(
          session,
          secondAttempt,
          secondEvidence,
        );

        expect(firstDecision.disposition, AbuseRiskDisposition.allow);
        expect(secondDecision.disposition, AbuseRiskDisposition.reject);
        expect(
          secondDecision.signals,
          contains(AbuseSignalCode.evidenceReplay),
        );
      },
    );

    test(
      'when the same proof is assessed again then the stored decision is '
      'reused',
      () async {
        final session = sessionBuilder.build();
        final attempt = await _attempt(session, action, firstId, now);
        final evidence = await _evidence(
          session,
          attempt,
          requirement,
          digest: 'b' * 64,
          capturedAt: now,
        );

        final first = await assess(session, attempt, evidence);
        final again = await assess(session, attempt, evidence);

        expect(again.disposition, first.disposition);
        expect(again.score, first.score);
        expect(await AbuseRiskAssessment.db.count(session), 1);
      },
    );

    test(
      'when decisions are recorded then the audit rows hold no account and '
      'cannot be changed',
      () async {
        final session = sessionBuilder.build();
        for (final (accountId, digest) in [
          (firstId, 'c' * 64),
          (secondId, 'd' * 64),
        ]) {
          final attempt = await _attempt(session, action, accountId, now);
          await assess(
            session,
            attempt,
            await _evidence(
              session,
              attempt,
              requirement,
              digest: digest,
              capturedAt: now,
            ),
          );
        }

        final assessments = await AbuseRiskAssessment.db.find(session);
        expect(assessments, hasLength(2));
        final stored = assessments.expand((row) => row.toJson().values);
        for (final id in [firstId, secondId, creatorId]) {
          expect(stored, isNot(contains(id.toString())));
        }
        for (final assessment in assessments) {
          expect(assessment.policyVersion, AbuseRiskDecision.policyVersion);
          expect(
            assessment.phase,
            AbuseAssessmentPhase.evidenceSubmission.name,
          );
        }

        // The trigger rejects edits, so this must stay the last statement in
        // the test transaction.
        await expectLater(
          session.db.unsafeQuery(
            'UPDATE verily_abuse_risk_assessment SET score = 0 '
            'WHERE id = CAST(@id AS uuid)',
            parameters: QueryParameters.named({
              'id': assessments.last.id.toString(),
            }),
          ),
          throwsA(isA<DatabaseQueryException>()),
        );
      },
    );
  });

  withServerpod('Given a gate that holds every value authorization', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x411);
    final participantId = testId(0x412);

    setUp(() async {
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        participantId: 'Grace',
      });
    });

    test(
      'when accepted proof completes then the attempt waits for a person '
      'instead of verifying',
      () async {
        final action = await endpoints.actionVerification.createAction(
          signedIn(sessionBuilder, creatorId),
          actionRequest(
            actionKey: 'abuse-gated-completion',
            requirements: [locationRequirement()],
          ),
        );
        final participant = signedIn(sessionBuilder, participantId);
        final attempt = await endpoints.actionVerification.beginAttempt(
          participant,
          actionId: action.id,
          idempotencyKey: 'abuse-gated',
        );
        final service = ActionVerificationService(
          abuseGate: _ReviewValueAuthorizationGate(),
        );
        final session = participant.build();
        final submitted = await service.submitEvidence(
          session,
          authUserId: participantId,
          input: ActionEvidenceInput(
            attemptId: attempt.id,
            requirementId: action.requirements.single.id,
            capturedAt: DateTime.now().toUtc(),
            latitude: 51.5007,
            longitude: -0.1246,
            accuracyMeters: 10,
          ),
        );

        final completed = await service.completeAttempt(
          session,
          authUserId: participantId,
          attemptId: attempt.id,
        );

        expect(submitted.status, EvidenceDecisionStatus.accepted);
        expect(completed.status, ActionAttemptStatus.pendingReview);
        final hold = await EvidenceDecision.db.findFirstRow(
          session,
          where: (table) => table.verifierType.equals('abuse-risk'),
        );
        expect(hold!.status, EvidenceDecisionStatus.manualReview);
        expect(hold.reasonCode, 'abuse_review_required');
        final stored = await ActionDefinition.db.findById(session, action.id);
        expect(stored!.verifiedCompletions, 0);
      },
    );
  });
}

Future<ActionAttempt> _attempt(
  Session session,
  ActionDefinition action,
  UuidValue accountId,
  DateTime now,
) => ActionAttempt.db.insertRow(
  session,
  ActionAttempt(
    actionDefinitionId: action.id!,
    participantAuthUserId: accountId,
    periodKey: 'once',
    idempotencyKey: 'abuse-$accountId',
    status: ActionAttemptStatus.collectingEvidence,
    startedAt: now,
    updatedAt: now,
  ),
);

Future<ActionEvidence> _evidence(
  Session session,
  ActionAttempt attempt,
  ActionRequirement requirement, {
  required String digest,
  required DateTime capturedAt,
}) => ActionEvidence.db.insertRow(
  session,
  ActionEvidence(
    attemptId: attempt.id!,
    requirementId: requirement.id!,
    kind: ActionRequirementKind.video,
    storagePath: 'action-evidence/${attempt.id}.mp4',
    storageVersionId: 'version-${attempt.id}',
    mimeType: 'video/mp4',
    sha256Digest: digest,
    byteLength: 1024,
    durationSeconds: 10,
    provenanceLevel: EvidenceProvenanceLevel.deviceSigned,
    captureKeyId: 'capture-${attempt.id}',
    capturedAt: capturedAt,
    submittedAt: capturedAt,
  ),
);

/// Allows proof at submission but routes every value authorization to a
/// person, as a high-risk correlation would.
final class _ReviewValueAuthorizationGate implements ActionAbuseGate {
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
  }) async => phase == AbuseAssessmentPhase.evidenceSubmission
      ? const AbuseRiskDecision(
          disposition: AbuseRiskDisposition.allow,
          tier: AbuseRiskTier.low,
          score: 0,
          signals: [],
        )
      : const AbuseRiskDecision(
          disposition: AbuseRiskDisposition.manualReview,
          tier: AbuseRiskTier.high,
          score: 50,
          signals: [AbuseSignalCode.accountVelocity],
        );
}
