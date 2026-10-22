import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/evidence_verification_worker.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/apps/webhooks/app_attempt_events.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

void main() {
  withServerpod('Given a published video action', (sessionBuilder, endpoints) {
    final creatorId = testId(1);
    final participantId = testId(2);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late ActionOpportunity action;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {
        creatorId: 'Ada',
        participantId: 'Grace',
      });
      action = await publishedAction(
        endpoints,
        creator,
        actionRequest(
          actionKey: 'water-a-plant',
          requirements: [
            mediaRequirement(
              kind: ActionRequirementKind.video,
              spokenChallengeRequired: false,
            ),
          ],
        ),
      );
    });

    Future<(ActionAttemptView, EvidenceSubmissionResult)> submitVideo() async {
      final attempt = await endpoints.actionVerification.beginAttempt(
        participant,
        actionId: action.id,
        idempotencyKey: 'attempt-1',
      );
      final submitted = await uploadMediaProof(
        endpoints,
        participant,
        participantId: participantId,
        attemptId: attempt.id,
        requirementId: action.requirements.single.id,
        contentType: 'video/mp4',
        bytes: MediaFixtures.mp4Video(),
        durationSeconds: 8,
      );
      return (attempt, submitted);
    }

    test('when uploaded then the proof waits for verification', () async {
      final (_, submitted) = await submitVideo();

      expect(submitted.status, isNull);
      expect(submitted.attempt.status, ActionAttemptStatus.verifying);
    });

    test(
      'when the worker accepts the proof then the attempt is verified '
      'without another client call',
      () async {
        final (attempt, _) = await submitVideo();
        final session = sessionBuilder.build();
        final evidence = await ActionEvidence.db.findFirstRow(
          session,
          where: (table) => table.attemptId.equals(attempt.id),
        );

        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => ScriptedMediaVerifier(),
        ).verify(session, evidence!.id!);

        final stored = await ActionAttempt.db.findById(session, attempt.id);
        expect(stored!.status, ActionAttemptStatus.verified);
        expect(stored.verifiedRank, 1);
        final listed = await endpoints.actionVerification.listMyAttempts(
          participant,
          limit: 10,
        );
        expect(listed.single.status, ActionAttemptStatus.verified);
      },
    );

    test(
      'when the worker routes the proof to a person then the attempt waits '
      'for review',
      () async {
        final (attempt, _) = await submitVideo();
        final session = sessionBuilder.build();
        final evidence = await ActionEvidence.db.findFirstRow(
          session,
          where: (table) => table.attemptId.equals(attempt.id),
        );

        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) =>
              const ManualReviewMediaEvidenceVerifier(),
        ).verify(session, evidence!.id!);

        final stored = await ActionAttempt.db.findById(session, attempt.id);
        expect(stored!.status, ActionAttemptStatus.pendingReview);
      },
    );

    test(
      'when the participant is blocked then the accepted proof waits for the '
      'hold to lift',
      () async {
        final (attempt, _) = await submitVideo();
        final session = sessionBuilder.build();
        final evidence = await ActionEvidence.db.findFirstRow(
          session,
          where: (table) => table.attemptId.equals(attempt.id),
        );
        Future<void> setBlocked({required bool blocked}) async {
          final account = await AuthUser.db.findById(session, participantId);
          await AuthUser.db.updateRow(
            session,
            account!.copyWith(blocked: blocked),
          );
        }

        await setBlocked(blocked: true);
        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => ScriptedMediaVerifier(),
        ).verify(session, evidence!.id!);

        final held = await ActionAttempt.db.findById(session, attempt.id);
        expect(held!.status, ActionAttemptStatus.verifying);

        await setBlocked(blocked: false);
        final completed = await ActionVerificationService().completeIfReady(
          session,
          attemptId: attempt.id,
        );
        expect(completed!.status, ActionAttemptStatus.verified);
      },
    );

    test(
      'when completion hits a bug then the worker surfaces it instead of '
      'waiting',
      () async {
        final (attempt, _) = await submitVideo();
        final session = sessionBuilder.build();
        final evidence = await ActionEvidence.db.findFirstRow(
          session,
          where: (table) => table.attemptId.equals(attempt.id),
        );
        final bug = StateError('A programming error inside completion.');

        await expectLater(
          EvidenceVerificationWorker(
            verifierFactory: (_, _, _) => ScriptedMediaVerifier(),
            actions: ActionVerificationService(
              settlementHooks: _FailingSettlement(bug),
            ),
          ).verify(session, evidence!.id!),
          throwsA(same(bug)),
        );

        // The decision is durable; only the completion rolled back.
        final decision = await EvidenceDecision.db.findFirstRow(
          session,
          where: (table) => table.evidenceId.equals(evidence.id),
        );
        expect(decision!.status, EvidenceDecisionStatus.accepted);
        final stored = await ActionAttempt.db.findById(session, attempt.id);
        expect(stored!.status, ActionAttemptStatus.verifying);
      },
    );
  });
}

/// Settlement that fails the way a bug would, inside the completion
/// transaction.
final class _FailingSettlement extends AttemptSettlementHooks {
  const _FailingSettlement(this.error);

  final Error error;

  @override
  Future<List<UuidValue>> onAttemptSettled(
    Session session, {
    required ActionAttempt attempt,
    required DateTime now,
    required Transaction transaction,
  }) async {
    throw error;
  }
}
