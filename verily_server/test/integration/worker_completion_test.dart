import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/evidence_verification_worker.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
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
  });
}
