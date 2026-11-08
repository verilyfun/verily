//! Model council. A vote is a signal. It never releases a reward.
//!
//! Any injection report forces manual review, including when other votes would
//! accept. Missing quorum routes to a person. The council does not guess.

use crate::pending_shared::DecisionStatus;
use crate::pending_shared::VerificationPolicy;

pub const PROMPT_INJECTION: &str = "media_prompt_injection_detected";
pub const VERIFIED_SUMMARY: &str = "Proof verified.";
pub const REVIEW_SUMMARY: &str = "A person will check this proof.";
pub const NOT_MET_SUMMARY: &str = "This proof did not show what the action asks for.";
pub const SPOKEN_SUMMARY: &str = "We could not hear the challenge word in this recording.";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Verdict {
	Fulfilled,
	NotFulfilled,
	Failed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SpokenVerdict {
	Heard,
	NotHeard,
	Abstained,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ModelVote {
	pub model_id: String,
	pub resolved_model_id: Option<String>,
	pub verdict: Verdict,
	pub confidence: Option<f64>,
	pub spoken: Option<SpokenVerdict>,
	pub error_code: Option<String>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct MediaDecision {
	pub status: DecisionStatus,
	pub verifier_type: &'static str,
	pub reason_code: &'static str,
	pub summary: &'static str,
	pub confidence: Option<f64>,
	pub model_name: Option<String>,
	pub model_version: Option<String>,
}

/// Combines votes. `minimum_confidence` is the rule's threshold, not a caller's.
pub fn decide(
	policy: VerificationPolicy,
	votes: &[ModelVote],
	minimum_confidence: f64,
	spoken_challenge_requested: bool,
) -> MediaDecision {
	let council = policy == VerificationPolicy::ModelCouncil;
	let verifier_type = if council {
		"openrouter-model-council"
	} else {
		"openrouter-single-model"
	};
	let model_name = if council {
		Some("openrouter-council".to_string())
	} else {
		votes.first().map(|vote| vote.model_id.clone())
	};
	let model_version = if council {
		Some("2-of-3-v1".to_string())
	} else {
		votes
			.first()
			.and_then(|vote| vote.resolved_model_id.clone())
	};
	let decision = |status, reason_code, summary, confidence| MediaDecision {
		status,
		verifier_type,
		reason_code,
		summary,
		confidence,
		model_name: model_name.clone(),
		model_version: model_version.clone(),
	};

	if votes
		.iter()
		.any(|vote| vote.error_code.as_deref() == Some(PROMPT_INJECTION))
	{
		return decision(
			DecisionStatus::ManualReview,
			"media_security_review_required",
			REVIEW_SUMMARY,
			None,
		);
	}

	let quorum = if council { 2 } else { 1 };
	let fulfilled = decisive(votes, Verdict::Fulfilled, minimum_confidence);
	let not_fulfilled = decisive(votes, Verdict::NotFulfilled, minimum_confidence);
	if not_fulfilled.len() >= quorum && fulfilled.len() < quorum {
		return decision(
			DecisionStatus::Rejected,
			if council {
				"media_council_requirements_not_met"
			} else {
				"media_requirements_not_met"
			},
			NOT_MET_SUMMARY,
			lowest(&not_fulfilled),
		);
	}
	if fulfilled.len() < quorum {
		let any_failed = votes.iter().any(|vote| vote.verdict == Verdict::Failed);
		let single = (votes.len() == 1).then(|| &votes[0]);
		let reason = if council {
			if any_failed {
				"media_council_quorum_unavailable"
			} else {
				"media_council_no_consensus"
			}
		} else if single.is_some_and(|vote| vote.verdict == Verdict::Failed) {
			if single.is_some_and(|vote| {
				vote.error_code.as_deref() == Some("verification_budget_unavailable")
			}) {
				"verification_budget_unavailable"
			} else {
				"media_verifier_unavailable"
			}
		} else if single.is_some_and(|vote| {
			vote.confidence
				.is_some_and(|confidence| confidence < minimum_confidence)
		}) {
			"media_confidence_below_threshold"
		} else {
			"media_verifier_uncertain"
		};
		return decision(
			DecisionStatus::ManualReview,
			reason,
			REVIEW_SUMMARY,
			single.and_then(|vote| vote.confidence),
		);
	}

	let confidence = lowest(&fulfilled);
	if !spoken_challenge_requested {
		return decision(
			DecisionStatus::Accepted,
			if council {
				"media_council_verified"
			} else {
				"media_requirements_verified"
			},
			VERIFIED_SUMMARY,
			confidence,
		);
	}

	let hearing: Vec<_> = votes
		.iter()
		.filter(|vote| {
			vote.verdict != Verdict::Failed
				&& vote
					.confidence
					.is_some_and(|confidence| confidence >= minimum_confidence)
		})
		.collect();
	let heard = hearing
		.iter()
		.filter(|vote| vote.spoken == Some(SpokenVerdict::Heard))
		.count();
	let not_heard = hearing
		.iter()
		.filter(|vote| vote.spoken == Some(SpokenVerdict::NotHeard))
		.count();
	if heard >= quorum && not_heard == 0 {
		return decision(
			DecisionStatus::Accepted,
			if council {
				"media_council_verified"
			} else {
				"media_requirements_verified"
			},
			VERIFIED_SUMMARY,
			confidence,
		);
	}
	if not_heard >= quorum && heard == 0 {
		return decision(
			DecisionStatus::Rejected,
			"spoken_challenge_not_heard",
			SPOKEN_SUMMARY,
			confidence,
		);
	}
	decision(
		DecisionStatus::ManualReview,
		"spoken_challenge_unverified",
		REVIEW_SUMMARY,
		confidence,
	)
}

/// Manual review when no verifier is configured. It does not accept the proof.
pub fn manual_review() -> MediaDecision {
	MediaDecision {
		status: DecisionStatus::ManualReview,
		verifier_type: "manual-review-fallback",
		reason_code: "media_verifier_unavailable",
		summary: REVIEW_SUMMARY,
		confidence: None,
		model_name: None,
		model_version: None,
	}
}

fn decisive<'a>(
	votes: &'a [ModelVote],
	verdict: Verdict,
	minimum_confidence: f64,
) -> Vec<&'a ModelVote> {
	votes
		.iter()
		.filter(|vote| {
			vote.verdict == verdict
				&& vote
					.confidence
					.is_some_and(|confidence| confidence >= minimum_confidence)
		})
		.collect()
}

fn lowest(votes: &[&ModelVote]) -> Option<f64> {
	votes
		.iter()
		.filter_map(|vote| vote.confidence)
		.reduce(f64::min)
}

#[cfg(test)]
mod tests {
	use super::*;

	fn vote(verdict: Verdict, confidence: f64, spoken: Option<SpokenVerdict>) -> ModelVote {
		ModelVote {
			model_id: "google/gemini-2.5-flash-lite".to_string(),
			resolved_model_id: Some("google/gemini-2.5-flash-lite".to_string()),
			verdict,
			confidence: Some(confidence),
			spoken,
			error_code: None,
		}
	}

	#[test]
	fn injection_forces_review_even_when_the_council_would_accept() {
		let mut votes = vec![
			vote(Verdict::Fulfilled, 0.9, Some(SpokenVerdict::Heard)),
			vote(Verdict::Fulfilled, 0.9, Some(SpokenVerdict::Heard)),
		];
		votes[0].error_code = Some(PROMPT_INJECTION.to_string());
		let decision = decide(VerificationPolicy::ModelCouncil, &votes, 0.6, true);
		assert_eq!(decision.status, DecisionStatus::ManualReview);
		assert_eq!(decision.reason_code, "media_security_review_required");
	}

	#[test]
	fn two_matching_votes_accept_and_one_does_not() {
		let votes = vec![
			vote(Verdict::Fulfilled, 0.8, None),
			vote(Verdict::Fulfilled, 0.7, None),
			vote(Verdict::NotFulfilled, 0.4, None),
		];
		let accepted = decide(VerificationPolicy::ModelCouncil, &votes, 0.6, false);
		assert_eq!(accepted.status, DecisionStatus::Accepted);
		assert_eq!(accepted.reason_code, "media_council_verified");
		let thin = vec![vote(Verdict::Fulfilled, 0.9, None)];
		let review = decide(VerificationPolicy::ModelCouncil, &thin, 0.6, false);
		assert_eq!(review.status, DecisionStatus::ManualReview);
		assert_eq!(review.reason_code, "media_council_no_consensus");
	}

	#[test]
	fn a_clear_miss_rejects_and_a_missing_word_does_not_guess() {
		let missed = vec![
			vote(Verdict::NotFulfilled, 0.8, None),
			vote(Verdict::NotFulfilled, 0.9, None),
		];
		assert_eq!(
			decide(VerificationPolicy::ModelCouncil, &missed, 0.6, true).status,
			DecisionStatus::Rejected
		);
		let quiet = vec![
			vote(Verdict::Fulfilled, 0.9, Some(SpokenVerdict::Abstained)),
			vote(Verdict::Fulfilled, 0.9, Some(SpokenVerdict::Heard)),
		];
		assert_eq!(
			decide(VerificationPolicy::ModelCouncil, &quiet, 0.6, true).reason_code,
			"spoken_challenge_unverified"
		);
	}

	#[test]
	fn manual_review_does_not_accept() {
		assert_eq!(manual_review().status, DecisionStatus::ManualReview);
	}
}
