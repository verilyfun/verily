//! Reward release stays a server decision. A model verdict is not one.

use crate::council::MediaDecision;

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum PayoutError {
	#[error("payout configuration is missing")]
	FailClosed,
	#[error("a model verdict does not release a reward")]
	ModelVerdict,
	#[error("a person has to accept this payout")]
	NeedsPerson,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PayoutAuthorization {
	/// Deterministic server checks passed and the amount is within the threshold.
	Automatic,
	/// A person accepted, which is what an above-threshold payout requires.
	PersonAccepted,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AcceptanceBasis {
	Deterministic,
	Person,
	Model,
}

pub struct PayoutRequest {
	pub amount_atoms: u64,
	/// `None` is missing configuration and fails closed.
	pub review_threshold_atoms: Option<u64>,
	pub basis: AcceptanceBasis,
}

pub fn authorize(request: PayoutRequest) -> Result<PayoutAuthorization, PayoutError> {
	if request.basis == AcceptanceBasis::Model {
		return Err(PayoutError::ModelVerdict);
	}
	let Some(threshold) = request.review_threshold_atoms else {
		return Err(PayoutError::FailClosed);
	};
	if request.amount_atoms > threshold {
		return if request.basis == AcceptanceBasis::Person {
			Ok(PayoutAuthorization::PersonAccepted)
		} else {
			Err(PayoutError::NeedsPerson)
		};
	}
	Ok(if request.basis == AcceptanceBasis::Person {
		PayoutAuthorization::PersonAccepted
	} else {
		PayoutAuthorization::Automatic
	})
}

pub fn model_decision_releases_reward(_decision: &MediaDecision) -> bool {
	false
}

#[cfg(test)]
mod tests {
	use super::*;
	use crate::council;

	#[test]
	fn a_model_acceptance_does_not_release_and_a_missing_threshold_fails_closed() {
		let decision = council::decide(
			verily_shared::ActionVerificationPolicy::SingleModel,
			&[council::ModelVote {
				model_id: "google/gemini-2.5-flash-lite".to_string(),
				resolved_model_id: None,
				verdict: council::Verdict::Fulfilled,
				confidence: Some(0.99),
				spoken: None,
				error_code: None,
			}],
			0.5,
			false,
		);
		assert_eq!(
			decision.status,
			verily_shared::EvidenceDecisionStatus::Accepted
		);
		assert!(!model_decision_releases_reward(&decision));
		assert_eq!(
			authorize(PayoutRequest {
				amount_atoms: 1,
				review_threshold_atoms: Some(10),
				basis: AcceptanceBasis::Model,
			}),
			Err(PayoutError::ModelVerdict)
		);
		assert_eq!(
			authorize(PayoutRequest {
				amount_atoms: 1,
				review_threshold_atoms: None,
				basis: AcceptanceBasis::Deterministic,
			}),
			Err(PayoutError::FailClosed)
		);
	}

	#[test]
	fn an_amount_above_the_threshold_needs_a_person() {
		assert_eq!(
			authorize(PayoutRequest {
				amount_atoms: 11,
				review_threshold_atoms: Some(10),
				basis: AcceptanceBasis::Deterministic,
			}),
			Err(PayoutError::NeedsPerson)
		);
		assert_eq!(
			authorize(PayoutRequest {
				amount_atoms: 11,
				review_threshold_atoms: Some(10),
				basis: AcceptanceBasis::Person,
			}),
			Ok(PayoutAuthorization::PersonAccepted)
		);
	}
}
