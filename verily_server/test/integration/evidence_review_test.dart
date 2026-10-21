import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/action_views.dart';
import 'package:verily_server/src/action_verification/evidence_verification_worker.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _reviewScope = 'evidence.review';

void main() {
  withServerpod('Given proof a verifier sent to a person', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(401);
    final participantId = testId(402);
    final reviewerId = testId(403);
    final unnamedCreatorId = testId(404);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late TestSessionBuilder reviewer;
    late ActionOpportunity action;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      reviewer = signedIn(sessionBuilder, reviewerId, scopes: {_reviewScope});
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {
        creatorId: 'Ada',
        participantId: 'Grace',
        reviewerId: 'Rita',
      });
      action = await publishedAction(
        endpoints,
        creator,
        actionRequest(
          actionKey: 'reviewed-video',
          title: 'Ten squats',
          requirements: [
            mediaRequirement(
              kind: ActionRequirementKind.video,
              spokenChallengeRequired: false,
            ),
          ],
        ),
      );
    });

    /// Uploads a video for [as] and lets a manual-review verifier route it to
    /// a person. Returns the evidence id.
    Future<UuidValue> pendingReview({
      required TestSessionBuilder as,
      required UuidValue asId,
      ActionOpportunity? onAction,
      bool issueWord = false,
    }) async {
      final target = onAction ?? action;
      final attempt = await endpoints.actionVerification.beginAttempt(
        as,
        actionId: target.id,
        idempotencyKey: 'review-$asId-${target.actionKey}',
      );
      final requirementId = target.requirements.single.id;
      if (issueWord) {
        await endpoints.actionVerification.issueSpokenChallenge(
          as,
          attemptId: attempt.id,
          requirementId: requirementId,
        );
      }
      await uploadMediaProof(
        endpoints,
        as,
        participantId: asId,
        attemptId: attempt.id,
        requirementId: requirementId,
        contentType: 'video/mp4',
        bytes: MediaFixtures.mp4Video(),
        durationSeconds: 8,
      );
      final evidence = await ActionEvidence.db.findFirstRow(
        sessionBuilder.build(),
        where: (table) => table.attemptId.equals(attempt.id),
      );
      await EvidenceVerificationWorker(
        verifierFactory: (_, _, _) => const ManualReviewMediaEvidenceVerifier(),
      ).verify(sessionBuilder.build(), evidence!.id!);
      final stored = await ActionAttempt.db.findById(
        sessionBuilder.build(),
        attempt.id,
      );
      expect(stored!.status, ActionAttemptStatus.pendingReview);
      return evidence.id!;
    }

    group('when the caller lacks review authority', () {
      test('then an anonymous caller is refused', () async {
        await expectLater(
          endpoints.evidenceReview.listQueue(sessionBuilder, limit: 10),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
      });

      test('then a signed-in account without the scope is refused', () async {
        await expectLater(
          endpoints.evidenceReview.listQueue(creator, limit: 10),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
        final evidenceId = await pendingReview(
          as: participant,
          asId: participantId,
        );
        await expectLater(
          endpoints.evidenceReview.review(
            creator,
            evidenceId: evidenceId,
            decision: EvidenceDecisionStatus.accepted,
            note: 'Creators are not reviewers.',
          ),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
      });
    });

    test(
      'when a scoped reviewer lists the queue then each item names the '
      'creator and links the pinned media',
      () async {
        final evidenceId = await pendingReview(
          as: participant,
          asId: participantId,
        );

        final queue = await endpoints.evidenceReview.listQueue(
          reviewer,
          limit: 30,
        );

        final item = queue.single;
        expect(item.evidenceId, evidenceId);
        expect(item.actionDefinitionId, action.id);
        expect(item.creatorDisplayName, 'Ada');
        expect(item.actionTitle, 'Ten squats');
        expect(item.requirementKind, ActionRequirementKind.video);
        expect(item.mimeType, 'video/mp4');
        expect(item.durationSeconds, 8);
        expect(item.reviewSummary, needsReviewSummary);
        expect(item.mediaUrl, isNotNull);
        expect(item.spokenChallengeWord, isNull);
        expect(item.payoutReview, isNull);
      },
    );

    test(
      'when the reviewer accepts the proof once then the attempt verifies and '
      'a second decision is refused',
      () async {
        final evidenceId = await pendingReview(
          as: participant,
          asId: participantId,
        );

        final result = await endpoints.evidenceReview.review(
          reviewer,
          evidenceId: evidenceId,
          decision: EvidenceDecisionStatus.accepted,
          note: 'The full movement is visible.',
        );

        expect(result.status, ActionAttemptStatus.verified);
        expect(result.verifiedRank, 1);
        final decisions = await EvidenceDecision.db.find(
          sessionBuilder.build(),
          where: (table) => table.evidenceId.equals(evidenceId),
          orderBy: (table) => table.createdAt,
        );
        expect(decisions, hasLength(2));
        expect(decisions.first.status, EvidenceDecisionStatus.manualReview);
        expect(decisions.last.verifierType, 'human-review');
        expect(decisions.last.reviewedByAuthUserId, reviewerId);
        expect(decisions.last.summary, 'The full movement is visible.');
        final stored = await ActionDefinition.db.findById(
          sessionBuilder.build(),
          action.id,
        );
        expect(stored!.verifiedCompletions, 1);
        expect(
          await endpoints.evidenceReview.listQueue(reviewer, limit: 30),
          isEmpty,
        );

        await expectLater(
          endpoints.evidenceReview.review(
            reviewer,
            evidenceId: evidenceId,
            decision: EvidenceDecisionStatus.accepted,
            note: 'Deciding the same proof twice.',
          ),
          throwsStateError,
        );
      },
    );

    test(
      'when the reviewer rejects the proof then the attempt is rejected',
      () async {
        final evidenceId = await pendingReview(
          as: participant,
          asId: participantId,
        );

        final result = await endpoints.evidenceReview.review(
          reviewer,
          evidenceId: evidenceId,
          decision: EvidenceDecisionStatus.rejected,
          note: 'The recording does not show the movement.',
        );

        expect(result.status, ActionAttemptStatus.rejected);
        expect(result.rejectionCode, 'proof_not_accepted');
      },
    );

    test(
      'when a decision is not accept or reject then it is refused',
      () async {
        final evidenceId = await pendingReview(
          as: participant,
          asId: participantId,
        );

        await expectLater(
          endpoints.evidenceReview.review(
            reviewer,
            evidenceId: evidenceId,
            decision: EvidenceDecisionStatus.manualReview,
            note: 'Sending it back to the queue.',
          ),
          throwsArgumentError,
        );
        await expectLater(
          endpoints.evidenceReview.review(
            reviewer,
            evidenceId: evidenceId,
            decision: EvidenceDecisionStatus.accepted,
            note: '   ',
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      'when the reviewer submitted the proof then it is hidden from their '
      'queue and they cannot decide it',
      () async {
        final evidenceId = await pendingReview(
          as: reviewer,
          asId: reviewerId,
        );

        expect(
          await endpoints.evidenceReview.listQueue(reviewer, limit: 30),
          isEmpty,
        );
        await expectLater(
          endpoints.evidenceReview.review(
            reviewer,
            evidenceId: evidenceId,
            decision: EvidenceDecisionStatus.accepted,
            note: 'Approving my own proof.',
          ),
          throwsStateError,
        );
      },
    );

    test(
      'when the participant closed their account then no decision is recorded',
      () async {
        final evidenceId = await pendingReview(
          as: participant,
          asId: participantId,
        );
        final session = sessionBuilder.build();
        final account = await AuthUser.db.findById(session, participantId);
        await AuthUser.db.updateRow(session, account!.copyWith(blocked: true));

        await expectLater(
          endpoints.evidenceReview.review(
            reviewer,
            evidenceId: evidenceId,
            decision: EvidenceDecisionStatus.accepted,
            note: 'This must stop before any lock is taken.',
          ),
          throwsStateError,
        );

        final decisions = await EvidenceDecision.db.find(
          sessionBuilder.build(),
          where: (table) => table.evidenceId.equals(evidenceId),
        );
        expect(decisions.single.status, EvidenceDecisionStatus.manualReview);
      },
    );

    test(
      'when the proof carried a challenge word then the reviewer sees the word',
      () async {
        final worded = await publishedAction(
          endpoints,
          creator,
          actionRequest(
            actionKey: 'worded-video',
            requirements: [mediaRequirement(kind: ActionRequirementKind.video)],
          ),
        );
        await pendingReview(
          as: participant,
          asId: participantId,
          onAction: worded,
          issueWord: true,
        );
        final challenge = await ActionSpokenChallenge.db.findFirstRow(
          sessionBuilder.build(),
        );

        final queue = await endpoints.evidenceReview.listQueue(
          reviewer,
          limit: 30,
        );

        expect(queue.single.spokenChallengeWord, challenge!.word);
      },
    );

    test(
      'when the creator has no public name then the queue uses the neutral '
      'creator name',
      () async {
        final session = sessionBuilder.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: unnamedCreatorId, scopeNames: const {}),
        );
        final unnamed = await publishedAction(
          endpoints,
          signedIn(sessionBuilder, unnamedCreatorId),
          actionRequest(
            actionKey: 'unnamed-creator',
            requirements: [
              mediaRequirement(
                kind: ActionRequirementKind.video,
                spokenChallengeRequired: false,
              ),
            ],
          ),
        );
        await pendingReview(
          as: participant,
          asId: participantId,
          onAction: unnamed,
        );

        final queue = await endpoints.evidenceReview.listQueue(
          reviewer,
          limit: 30,
        );

        expect(queue.single.creatorDisplayName, anonymousCreatorName);
      },
    );
  });
}
