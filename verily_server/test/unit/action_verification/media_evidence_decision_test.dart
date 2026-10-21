import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/generated/protocol.dart';

const _threshold = 0.85;

void main() {
  group('Given a single-model policy', () {
    MediaEvidenceVerification decide(
      List<MediaEvidenceModelVote> votes, {
      bool spokenChallengeRequested = false,
    }) => decideMediaVerification(
      policy: ActionVerificationPolicy.singleModel,
      votes: votes,
      minimumConfidence: _threshold,
      spokenChallengeRequested: spokenChallengeRequested,
    );

    test('when the model confidently sees the action then it accepts', () {
      final decision = decide([_vote(MediaEvidenceModelVerdict.fulfilled)]);

      expect(decision.status, EvidenceDecisionStatus.accepted);
      expect(decision.reasonCode, MediaVerificationReason.verified);
      expect(decision.summary, verifiedSummary);
      expect(decision.confidence, 0.95);
      expect(decision.verifierType, 'openrouter-single-model');
      expect(decision.modelName, openRouterGeminiFlashLiteModel);
    });

    test('when the model confidently sees no action then it rejects', () {
      final decision = decide([_vote(MediaEvidenceModelVerdict.notFulfilled)]);

      expect(decision.status, EvidenceDecisionStatus.rejected);
      expect(decision.reasonCode, MediaVerificationReason.notMet);
      expect(decision.summary, notMetSummary);
    });

    test('when confidence is below the rule threshold then a person '
        'reviews', () {
      final decision = decide([
        _vote(MediaEvidenceModelVerdict.fulfilled, confidence: 0.84),
      ]);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.belowThreshold);
      expect(decision.confidence, 0.84);
      expect(decision.summary, needsReviewSummary);
    });

    test('when a low-confidence rejection arrives then it is never an '
        'automatic rejection', () {
      final decision = decide([
        _vote(MediaEvidenceModelVerdict.notFulfilled, confidence: 0.5),
      ]);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.belowThreshold);
    });

    test('when the model is uncertain then a person reviews', () {
      final decision = decide([_vote(MediaEvidenceModelVerdict.uncertain)]);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.uncertain);
    });

    test('when the call failed then the verifier is reported unavailable', () {
      final decision = decide([
        _failedVote(errorCode: 'openrouter_http_503'),
      ]);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.unavailable);
    });

    test('when the budget refused the call then the reason says so', () {
      final decision = decide([
        _failedVote(errorCode: MediaVerificationReason.budgetUnavailable),
      ]);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.budgetUnavailable);
    });

    test('when there is no vote at all then a person reviews', () {
      final decision = decide(const []);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.uncertain);
    });

    test('when the media tried to instruct the model then a person reviews '
        'even though the vote accepts', () {
      final decision = decide([
        _vote(
          MediaEvidenceModelVerdict.fulfilled,
          confidence: 0.99,
          errorCode: promptInjectionErrorCode,
        ),
      ]);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.securityReview);
    });
  });

  group('Given a model-council policy', () {
    MediaEvidenceVerification decide(
      List<MediaEvidenceModelVote> votes, {
      bool spokenChallengeRequested = false,
    }) => decideMediaVerification(
      policy: ActionVerificationPolicy.modelCouncil,
      votes: votes,
      minimumConfidence: _threshold,
      spokenChallengeRequested: spokenChallengeRequested,
    );

    test('when two of three members confidently agree then it accepts with '
        'the lowest agreeing confidence', () {
      final decision = decide([
        _vote(MediaEvidenceModelVerdict.fulfilled, confidence: 0.96),
        _vote(
          MediaEvidenceModelVerdict.fulfilled,
          confidence: 0.91,
          modelId: openRouterGemmaModel,
        ),
        _vote(
          MediaEvidenceModelVerdict.notFulfilled,
          confidence: 0.93,
          modelId: openRouterGlmFlashModel,
        ),
      ]);

      expect(decision.status, EvidenceDecisionStatus.accepted);
      expect(decision.reasonCode, MediaVerificationReason.councilVerified);
      expect(decision.confidence, 0.91);
      expect(decision.verifierType, 'openrouter-model-council');
      expect(decision.votes, hasLength(3));
    });

    test('when two members confidently reject then it rejects', () {
      final decision = decide([
        _vote(MediaEvidenceModelVerdict.notFulfilled),
        _vote(MediaEvidenceModelVerdict.notFulfilled),
        _vote(MediaEvidenceModelVerdict.fulfilled),
      ]);

      expect(decision.status, EvidenceDecisionStatus.rejected);
      expect(decision.reasonCode, MediaVerificationReason.councilNotMet);
    });

    test('when only one member accepts then there is no consensus', () {
      final decision = decide([
        _vote(MediaEvidenceModelVerdict.fulfilled),
        _vote(MediaEvidenceModelVerdict.notFulfilled),
        _vote(MediaEvidenceModelVerdict.uncertain),
      ]);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.councilNoConsensus);
    });

    test('when a member failed and no quorum remains then the quorum is '
        'unavailable', () {
      final decision = decide([
        _vote(MediaEvidenceModelVerdict.fulfilled),
        _failedVote(),
        _failedVote(),
      ]);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(
        decision.reasonCode,
        MediaVerificationReason.councilQuorumUnavailable,
      );
    });

    test('when two accepting votes are below the threshold then they do '
        'not form a quorum', () {
      final decision = decide([
        _vote(MediaEvidenceModelVerdict.fulfilled, confidence: 0.8),
        _vote(MediaEvidenceModelVerdict.fulfilled, confidence: 0.84),
        _vote(MediaEvidenceModelVerdict.uncertain),
      ]);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.councilNoConsensus);
    });

    test('when one member reports injection then it vetoes an accepting '
        'quorum', () {
      final decision = decide([
        _vote(MediaEvidenceModelVerdict.fulfilled, confidence: 0.99),
        _vote(MediaEvidenceModelVerdict.fulfilled, confidence: 0.99),
        _vote(
          MediaEvidenceModelVerdict.uncertain,
          errorCode: promptInjectionErrorCode,
        ),
      ]);

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.securityReview);
    });
  });

  group('Given a proof that asks for the live spoken word', () {
    test('when a single hearing model accepts and heard the word then it '
        'accepts', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.singleModel,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            spoken: SpokenChallengeVerdict.heard,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: true,
      );

      expect(decision.status, EvidenceDecisionStatus.accepted);
      expect(decision.reasonCode, MediaVerificationReason.verified);
    });

    test('when the model clearly did not hear the word then it rejects', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.singleModel,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            spoken: SpokenChallengeVerdict.notHeard,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: true,
      );

      expect(decision.status, EvidenceDecisionStatus.rejected);
      expect(decision.reasonCode, MediaVerificationReason.spokenNotHeard);
      expect(decision.summary, spokenNotHeardSummary);
    });

    test('when the word was unclear then a person reviews', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.singleModel,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            spoken: SpokenChallengeVerdict.unclear,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: true,
      );

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.spokenUnverified);
    });

    test('when the only model cannot hear audio then it abstains and a '
        'person reviews', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.singleModel,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            modelId: openRouterGemmaModel,
            spoken: SpokenChallengeVerdict.abstained,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: true,
      );

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.spokenUnverified);
    });

    test('when the action is clearly not done then the word cannot rescue '
        'it', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.singleModel,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.notFulfilled,
            spoken: SpokenChallengeVerdict.heard,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: true,
      );

      expect(decision.status, EvidenceDecisionStatus.rejected);
      expect(decision.reasonCode, MediaVerificationReason.notMet);
    });

    test('when a council has only one hearing member then the word is '
        'unverified and a person reviews', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.modelCouncil,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            spoken: SpokenChallengeVerdict.heard,
          ),
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            modelId: openRouterGemmaModel,
            spoken: SpokenChallengeVerdict.abstained,
          ),
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            modelId: openRouterGlmFlashModel,
            spoken: SpokenChallengeVerdict.abstained,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: true,
      );

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.spokenUnverified);
    });

    test('when two hearing council members heard the word then it accepts', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.modelCouncil,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            spoken: SpokenChallengeVerdict.heard,
          ),
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            modelId: openRouterGeminiFlashModel,
            spoken: SpokenChallengeVerdict.heard,
          ),
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            modelId: openRouterGemmaModel,
            spoken: SpokenChallengeVerdict.abstained,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: true,
      );

      expect(decision.status, EvidenceDecisionStatus.accepted);
      expect(decision.reasonCode, MediaVerificationReason.councilVerified);
    });

    test('when hearing members disagree about the word then a person '
        'reviews', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.modelCouncil,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            spoken: SpokenChallengeVerdict.heard,
          ),
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            modelId: openRouterGeminiFlashModel,
            spoken: SpokenChallengeVerdict.heard,
          ),
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            modelId: openRouterGeminiFlashModel,
            spoken: SpokenChallengeVerdict.notHeard,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: true,
      );

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.spokenUnverified);
    });

    test('when two hearing council members did not hear the word then it '
        'rejects', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.modelCouncil,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            spoken: SpokenChallengeVerdict.notHeard,
          ),
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            modelId: openRouterGeminiFlashModel,
            spoken: SpokenChallengeVerdict.notHeard,
          ),
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            modelId: openRouterGemmaModel,
            spoken: SpokenChallengeVerdict.abstained,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: true,
      );

      expect(decision.status, EvidenceDecisionStatus.rejected);
      expect(decision.reasonCode, MediaVerificationReason.spokenNotHeard);
    });

    test('when a hearing vote is below the threshold then its word verdict '
        'does not count', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.modelCouncil,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            spoken: SpokenChallengeVerdict.heard,
          ),
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            modelId: openRouterGeminiFlashModel,
            spoken: SpokenChallengeVerdict.heard,
          ),
          _vote(
            MediaEvidenceModelVerdict.uncertain,
            confidence: 0.4,
            modelId: openRouterGeminiFlashModel,
            spoken: SpokenChallengeVerdict.notHeard,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: true,
      );

      expect(decision.status, EvidenceDecisionStatus.accepted);
    });
  });

  group('Given a proof that asks for no spoken word', () {
    test('when votes carry word verdicts then they are ignored', () {
      final decision = decideMediaVerification(
        policy: ActionVerificationPolicy.singleModel,
        votes: [
          _vote(
            MediaEvidenceModelVerdict.fulfilled,
            spoken: SpokenChallengeVerdict.notHeard,
          ),
        ],
        minimumConfidence: _threshold,
        spokenChallengeRequested: false,
      );

      expect(decision.status, EvidenceDecisionStatus.accepted);
      expect(decision.reasonCode, MediaVerificationReason.verified);
    });
  });

  group('Given the manual-review fallback verifier', () {
    test('when asked to verify then it never accepts', () async {
      final decision = await const ManualReviewMediaEvidenceVerifier().verify(
        _UnusedSession(),
        MediaVerificationRequest(
          rule: ActionMediaRule(
            requirementId: UuidValue.withValidation(
              '0198bc26-4be5-7ca0-94d2-16385b5add41',
            ),
            kind: ActionRequirementKind.video,
            verificationPrompt: 'Verify ten continuous squats.',
            minDurationSeconds: 5,
            maxDurationSeconds: 120,
            minConfidence: _threshold,
          ),
          storagePath: 'action-evidence/user/attempt/requirement.mp4',
          storageVersionId: 'pinned-version',
          mimeType: 'video/mp4',
          sha256Digest: 'a' * 64,
          byteLength: 1024,
          capturedAt: DateTime.utc(2026, 10, 21, 12),
          durationSeconds: 30,
        ),
      );

      expect(decision.status, EvidenceDecisionStatus.manualReview);
      expect(decision.reasonCode, MediaVerificationReason.unavailable);
      expect(decision.summary, needsReviewSummary);
    });
  });
}

MediaEvidenceModelVote _vote(
  MediaEvidenceModelVerdict verdict, {
  double confidence = 0.95,
  String modelId = openRouterGeminiFlashLiteModel,
  SpokenChallengeVerdict? spoken,
  String? errorCode,
}) => MediaEvidenceModelVote(
  modelId: modelId,
  verdict: verdict,
  confidence: confidence,
  latencyMilliseconds: 10,
  spokenChallengeVerdict: spoken,
  errorCode: errorCode,
);

MediaEvidenceModelVote _failedVote({String errorCode = 'openrouter_timeout'}) =>
    MediaEvidenceModelVote(
      modelId: openRouterGemmaModel,
      verdict: MediaEvidenceModelVerdict.failed,
      latencyMilliseconds: 10,
      errorCode: errorCode,
    );

/// The manual verifier never touches its session.
class _UnusedSession implements Session {
  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('The session is not used by this verifier.');
}
