//! Motion is not accepted from a phone-reported score.
//!
//! The analyzer in `packages/verily_evidence` is the source of a later port.
//! Until that math is reproduced here, a trace is held for a person. A client
//! repetition count is not proof.

use crate::pending_shared::DecisionStatus;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MotionHold {
	pub status: DecisionStatus,
	pub reason_code: &'static str,
	pub summary: &'static str,
}

pub fn client_repetitions_are_proof(_count: u32) -> bool {
	false
}

pub fn hold_for_review(_client_repetitions: u32) -> MotionHold {
	MotionHold {
		status: DecisionStatus::ManualReview,
		reason_code: "motion_not_recomputed",
		summary: "A person will check this proof.",
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn a_client_score_does_not_accept() {
		assert!(!client_repetitions_are_proof(20));
		let held = hold_for_review(20);
		assert_eq!(held.status, DecisionStatus::ManualReview);
		assert_ne!(held.status, DecisionStatus::Accepted);
	}
}
