//! Operations `verily_backend` mounts.
//!
//! Routes belong to the backend. These functions do not take a model id, a
//! system prompt, or an evidence URL. Spoken words come from the server list.
//! Attestation that cannot be checked fails closed.

use chrono::DateTime;
use chrono::Utc;

use crate::capture::AndroidAttestation;
use crate::capture::AttestationUnavailable;
use crate::capture::CaptureWindow;
use crate::capture::SignatureMode;
use crate::config::VerifierConfig;
use crate::config::VerifierMode;
use crate::council::MediaDecision;
use crate::council::ModelVote;
use crate::evidence::Expectation;
use crate::evidence::Inspection;
use crate::evidence::Seal;
use crate::location::LocationDecision;
use crate::location::LocationPolicy;
use crate::location::Observation;
use crate::location::PreviousObservation;
use crate::payout::PayoutAuthorization;
use crate::payout::PayoutRequest;
use crate::spoken::SpokenChallenge;
use verily_shared::ActionVerificationPolicy;
use verily_shared::EvidenceProvenanceLevel;

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum OpError {
	#[error("the operation was refused")]
	Refused,
	#[error("verification is not available")]
	Unavailable,
}

pub struct Verification<A> {
	config: VerifierConfig,
	signature_mode: SignatureMode,
	android: A,
}

impl Verification<AttestationUnavailable> {
	/// Manual review, and attestation that fails closed until a chain verifier is set.
	pub fn closed() -> Result<Self, crate::config::ConfigError> {
		Ok(Self {
			config: VerifierConfig::from_resolved(&std::collections::HashMap::new(), None, None)?,
			signature_mode: SignatureMode::Optional,
			android: AttestationUnavailable,
		})
	}
}

impl<A: AndroidAttestation> Verification<A> {
	pub fn new(config: VerifierConfig, signature_mode: SignatureMode, android: A) -> Self {
		Self {
			config,
			signature_mode,
			android,
		}
	}

	/// Whether a capture must carry a device signature.
	pub fn signature_mode(&self) -> SignatureMode {
		self.signature_mode
	}

	pub fn begin_capture(
		&self,
		attempt_id: &str,
		requirement_id: &str,
		now: DateTime<Utc>,
	) -> Result<CaptureWindow, OpError> {
		crate::capture::begin_capture(attempt_id, requirement_id, now).map_err(map_capture)
	}

	pub fn issue_spoken_challenge(
		&self,
		existing: Option<&SpokenChallenge>,
		issued_count: u32,
		entropy: u64,
		now: DateTime<Utc>,
	) -> Result<SpokenChallenge, OpError> {
		crate::spoken::issue(existing, issued_count, entropy, now).map_err(|_| OpError::Refused)
	}

	pub fn seal_stored_evidence(
		&self,
		expectation: &Expectation,
		inspection: &Inspection,
	) -> Result<Seal, OpError> {
		crate::evidence::seal_inspection(expectation, &expectation.storage_path, inspection)
			.map_err(|_| OpError::Refused)
	}

	pub fn decide_media(
		&self,
		votes: &[ModelVote],
		minimum_confidence: f64,
		spoken: bool,
	) -> MediaDecision {
		match self.config.mode {
			VerifierMode::ManualReview => crate::council::manual_review(),
			VerifierMode::Cloud | VerifierMode::OpenRouter => {
				let policy = if self.config.council_model_ids.len() == 3 {
					ActionVerificationPolicy::ModelCouncil
				} else {
					ActionVerificationPolicy::SingleModel
				};
				crate::council::decide(policy, votes, minimum_confidence, spoken)
			}
		}
	}

	pub fn verify_android_capture(
		&self,
		chain_der: &[&[u8]],
		capture_challenge: &str,
		attempt_id: &str,
		manifest: &[u8],
		signature_p1363: &[u8],
	) -> Result<EvidenceProvenanceLevel, OpError> {
		crate::capture::verify_android_capture(
			&self.android,
			chain_der,
			capture_challenge,
			attempt_id,
			manifest,
			signature_p1363,
			self.signature_mode,
		)
		.map_err(map_capture)
	}

	pub fn decide_location(
		&self,
		now: DateTime<Utc>,
		current: Observation,
		max_accuracy_meters: f64,
		distance_meters: f64,
		radius_meters: f64,
		previous: Option<PreviousObservation>,
	) -> Result<LocationDecision, OpError> {
		crate::location::decide(
			LocationPolicy::default(),
			now,
			current,
			max_accuracy_meters,
			distance_meters,
			radius_meters,
			previous,
		)
		.map_err(|_| OpError::Refused)
	}

	pub fn authorize_payout(
		&self,
		request: PayoutRequest,
	) -> Result<PayoutAuthorization, crate::payout::PayoutError> {
		crate::payout::authorize(request)
	}

	pub fn resolve_review<'a>(
		&self,
		decision: verily_shared::EvidenceDecisionStatus,
		note: &'a str,
	) -> Result<&'a str, crate::review::ReviewError> {
		crate::review::resolve(decision)?;
		crate::review::review_note(note)
	}
}

fn map_capture(error: crate::capture::CaptureError) -> OpError {
	match error {
		crate::capture::CaptureError::Unavailable => OpError::Unavailable,
		crate::capture::CaptureError::Refused | crate::capture::CaptureError::Replayed => {
			OpError::Refused
		}
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn the_closed_service_reviews_by_hand_and_does_not_demand_a_signature() {
		let closed = Verification::closed().unwrap();
		assert_eq!(closed.signature_mode(), SignatureMode::Optional);
		let decision = closed.decide_media(&[], 0.7, true);
		assert_eq!(
			decision.status,
			verily_shared::EvidenceDecisionStatus::ManualReview
		);
	}
}
