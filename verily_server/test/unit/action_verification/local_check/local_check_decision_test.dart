import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_models.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_replay.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/generated/protocol.dart';

final LocalCheckModel _model = LocalCheckModel.forTask(LocalCheckTask.gesture);

ActionLocalCheck _check({double minScore = 0.6, int minFrames = 3}) =>
    ActionLocalCheck(
      task: LocalCheckTask.gesture,
      label: 'Thumb_Up',
      minScore: minScore,
      minFrames: minFrames,
    );

LocalCheckReplayScores _scores(List<double> scores) =>
    LocalCheckReplayScores(scores, latency: const Duration(milliseconds: 42));

void main() {
  group('Given a replay that scored every frame', () {
    test('when enough frames reach the score then the proof is accepted', () {
      final decision = decideLocalCheck(
        model: _model,
        check: _check(),
        replay: _scores([0.2, 0.61, 0.6, 0.95, 0.1]),
        spokenChallengeRequired: false,
      )!;

      expect(decision.status, EvidenceDecisionStatus.accepted);
      expect(decision.verifierType, mpReplayVerifierType);
      expect(decision.reasonCode, LocalCheckReason.matched);
      expect(decision.modelName, _model.modelId);
      expect(decision.modelVersion, _model.sha256);
      expect(decision.confidence, 0.95);
      final vote = decision.votes.single;
      expect(vote.verdict, MediaEvidenceModelVerdict.fulfilled);
      expect(vote.providerName, mpReplayVerifierType);
      expect(vote.resolvedModelId, _model.sha256);
      expect(vote.latencyMilliseconds, 42);
      expect(vote.spokenChallengeVerdict, isNull);
    });

    test('when too few frames reach the score then the proof is rejected', () {
      final decision = decideLocalCheck(
        model: _model,
        check: _check(),
        replay: _scores([0.99, 0.98, 0.59, 0.0]),
        spokenChallengeRequired: false,
      )!;

      expect(decision.status, EvidenceDecisionStatus.rejected);
      expect(decision.reasonCode, LocalCheckReason.notMatched);
      expect(decision.confidence, 0.99);
      expect(
        decision.votes.single.verdict,
        MediaEvidenceModelVerdict.notFulfilled,
      );
    });

    test('when nothing was scored then the proof is rejected at zero', () {
      final decision = decideLocalCheck(
        model: _model,
        check: _check(minFrames: 1),
        replay: _scores(const []),
        spokenChallengeRequired: false,
      )!;

      expect(decision.status, EvidenceDecisionStatus.rejected);
      expect(decision.confidence, 0);
    });

    test('when a spoken word must also be heard then the replay defers', () {
      expect(
        decideLocalCheck(
          model: _model,
          check: _check(),
          replay: _scores([0.9, 0.9, 0.9]),
          spokenChallengeRequired: true,
        ),
        isNull,
      );
    });
  });

  group('Given a replay that could not run', () {
    const unavailable = LocalCheckReplayUnavailable(
      LocalCheckUnavailableCode.runtimeUnavailable,
    );

    test('when deciding then it never decides on its own', () {
      expect(
        decideLocalCheck(
          model: _model,
          check: _check(),
          replay: unavailable,
          spokenChallengeRequired: false,
        ),
        isNull,
      );
    });

    test('when the policy falls back to a person then the reason says so', () {
      final merged = withLocalCheckReplay(
        const MediaEvidenceVerification(
          status: EvidenceDecisionStatus.manualReview,
          verifierType: 'manual-review-fallback',
          reasonCode: MediaVerificationReason.unavailable,
          summary: needsReviewSummary,
        ),
        model: _model,
        check: _check(),
        replay: unavailable,
      );

      expect(merged.status, EvidenceDecisionStatus.manualReview);
      expect(merged.verifierType, 'manual-review-fallback');
      expect(merged.reasonCode, LocalCheckReason.replayUnavailable);
      final vote = merged.votes.single;
      expect(vote.verdict, MediaEvidenceModelVerdict.failed);
      expect(vote.errorCode, LocalCheckUnavailableCode.runtimeUnavailable);
    });

    test('when an AI model decides then its verdict and reason stand', () {
      final merged = withLocalCheckReplay(
        decideMediaVerification(
          policy: ActionVerificationPolicy.singleModel,
          votes: const [
            MediaEvidenceModelVote(
              modelId: openRouterGeminiFlashModel,
              verdict: MediaEvidenceModelVerdict.fulfilled,
              confidence: 0.93,
              latencyMilliseconds: 5,
            ),
          ],
          minimumConfidence: 0.8,
          spokenChallengeRequested: false,
        ),
        model: _model,
        check: _check(),
        replay: unavailable,
      );

      expect(merged.status, EvidenceDecisionStatus.accepted);
      expect(merged.reasonCode, MediaVerificationReason.verified);
      expect(merged.votes, hasLength(2));
      expect(merged.votes.first.errorCode, isNotNull);
      expect(merged.votes.last.modelId, openRouterGeminiFlashModel);
    });
  });

  group('Given a matched replay on a proof that needs a spoken word', () {
    test('when the AI policy rejects then the AI verdict decides', () {
      final merged = withLocalCheckReplay(
        decideMediaVerification(
          policy: ActionVerificationPolicy.singleModel,
          votes: const [
            MediaEvidenceModelVote(
              modelId: openRouterGeminiFlashModel,
              verdict: MediaEvidenceModelVerdict.fulfilled,
              confidence: 0.93,
              latencyMilliseconds: 5,
              spokenChallengeVerdict: SpokenChallengeVerdict.notHeard,
            ),
          ],
          minimumConfidence: 0.8,
          spokenChallengeRequested: true,
        ),
        model: _model,
        check: _check(),
        replay: _scores([0.9, 0.9, 0.9]),
      );

      expect(merged.status, EvidenceDecisionStatus.rejected);
      expect(merged.reasonCode, MediaVerificationReason.spokenNotHeard);
      expect(merged.votes.first.verdict, MediaEvidenceModelVerdict.fulfilled);
      expect(merged.votes.first.providerName, mpReplayVerifierType);
    });
  });
}
