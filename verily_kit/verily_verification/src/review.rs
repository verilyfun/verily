//! Person decisions. A queued review is not a resolution.

use verily_shared::EvidenceDecisionStatus;

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum ReviewError {
	#[error("the note must be between 1 and 500 characters")]
	Note,
	#[error("pending is not a resolution")]
	Pending,
}

pub fn review_note(note: &str) -> Result<&str, ReviewError> {
	let note = note.trim();
	let length = note.chars().count();
	if (1..=500).contains(&length) {
		Ok(note)
	} else {
		Err(ReviewError::Note)
	}
}

pub fn resolve(decision: EvidenceDecisionStatus) -> Result<EvidenceDecisionStatus, ReviewError> {
	match decision {
		EvidenceDecisionStatus::Accepted | EvidenceDecisionStatus::Rejected => Ok(decision),
		EvidenceDecisionStatus::ManualReview => Err(ReviewError::Pending),
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn a_review_needs_a_bounded_note_and_a_real_decision() {
		assert_eq!(review_note("  looks right  ").unwrap(), "looks right");
		assert_eq!(review_note("   "), Err(ReviewError::Note));
		assert_eq!(review_note(&"a".repeat(501)), Err(ReviewError::Note));
		assert_eq!(
			resolve(EvidenceDecisionStatus::ManualReview),
			Err(ReviewError::Pending)
		);
		assert_eq!(
			resolve(EvidenceDecisionStatus::Accepted).unwrap(),
			EvidenceDecisionStatus::Accepted
		);
	}
}
