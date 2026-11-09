//! Public reason codes. Internal verifier codes stay on the server.

use verily_shared::EvidenceDecisionStatus;

pub const PROOF_ACCEPTED: &str = "proof_accepted";
pub const CHECKING: &str = "checking";
pub const NEEDS_REVIEW: &str = "needs_review";
pub const PROOF_NOT_ACCEPTED: &str = "proof_not_accepted";
pub const PROOF_MISSING: &str = "proof_missing";
pub const ACTION_FULL: &str = "action_full";
pub const OUTSIDE_AREA: &str = "outside_area";
pub const LOCATION_NOT_PRECISE: &str = "location_not_precise";
pub const LOCATION_TOO_OLD: &str = "location_too_old";
pub const PHONE_CLOCK: &str = "phone_clock";
pub const RECORDING_LENGTH: &str = "recording_length";
pub const CHALLENGE_WORD_MISSING: &str = "challenge_word_missing";
pub const CHALLENGE_WORD_TOO_EARLY: &str = "challenge_word_too_early";
pub const CHALLENGE_WORD_NOT_HEARD: &str = "challenge_word_not_heard";
pub const CODE_NOT_MATCHED: &str = "code_not_matched";
pub const MOTION_NOT_MATCHED: &str = "motion_not_matched";
pub const CAPTURE_NOT_VERIFIED: &str = "capture_not_verified";
pub const PAYOUT_REVIEW: &str = "payout_review";

pub fn public_decision_reason(
	code: Option<&str>,
	status: Option<EvidenceDecisionStatus>,
) -> &'static str {
	if let Some(exact) = code.and_then(exact) {
		return exact;
	}
	match status {
		None => CHECKING,
		Some(EvidenceDecisionStatus::Accepted) => PROOF_ACCEPTED,
		Some(EvidenceDecisionStatus::ManualReview) => NEEDS_REVIEW,
		Some(EvidenceDecisionStatus::Rejected) => {
			code.and_then(rejected_family).unwrap_or(PROOF_NOT_ACCEPTED)
		}
	}
}

pub fn public_review_reason(code: &str) -> &'static str {
	match code {
		"high_value_payout_review" => "payout_review",
		"media_security_review_required"
		| "media_prompt_injection_detected"
		| "device_capture_risk"
		| "device_activity_risk"
		| "apple_device_risk_unavailable"
		| "apple_device_review" => "security_review",
		"spoken_challenge_unverified" => "challenge_word_unclear",
		"location_travel_needs_review" => "location_review",
		"abuse_review_required" => "abuse_review",
		"mp_replay_unavailable" => "local_check_unavailable",
		"media_verifier_unavailable"
		| "media_council_quorum_unavailable"
		| "verification_budget_unavailable"
		| "media_verifier_retry_exhausted" => "verifier_unavailable",
		"media_confidence_below_threshold"
		| "media_verifier_uncertain"
		| "media_council_no_consensus" => "low_confidence",
		_ => "needs_review",
	}
}

fn exact(code: &str) -> Option<&'static str> {
	Some(match code {
		"inside_geofence" | "qr_code_matched" | "motion_verified" => PROOF_ACCEPTED,
		"outside_geofence" => OUTSIDE_AREA,
		"location_accuracy_too_low" => LOCATION_NOT_PRECISE,
		"location_capture_stale" => LOCATION_TOO_OLD,
		"location_capture_time_invalid" | "media_capture_time_invalid" => PHONE_CLOCK,
		"location_travel_needs_review" => NEEDS_REVIEW,
		"media_duration_out_of_range" => RECORDING_LENGTH,
		"media_verification_queued" => CHECKING,
		"spoken_challenge_missing" => CHALLENGE_WORD_MISSING,
		"spoken_challenge_predates_capture" => CHALLENGE_WORD_TOO_EARLY,
		"spoken_challenge_not_heard" => CHALLENGE_WORD_NOT_HEARD,
		"qr_code_mismatch" => CODE_NOT_MATCHED,
		"missing_required_evidence" => PROOF_MISSING,
		"action_capacity_reached" => ACTION_FULL,
		"high_value_payout_review" => PAYOUT_REVIEW,
		_ => return None,
	})
}

fn rejected_family(code: &str) -> Option<&'static str> {
	if code.starts_with("motion_") {
		Some(MOTION_NOT_MATCHED)
	} else if code.starts_with("capture_")
		|| code.starts_with("device_integrity_")
		|| code == "app_integrity_not_recognised"
	{
		Some(CAPTURE_NOT_VERIFIED)
	} else {
		None
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn internal_codes_become_the_public_set() {
		assert_eq!(
			public_decision_reason(
				Some("outside_geofence"),
				Some(EvidenceDecisionStatus::Rejected)
			),
			OUTSIDE_AREA
		);
		assert_eq!(
			public_decision_reason(
				Some("capture_attestation_untrusted"),
				Some(EvidenceDecisionStatus::Rejected)
			),
			CAPTURE_NOT_VERIFIED
		);
		assert_eq!(
			public_review_reason("media_prompt_injection_detected"),
			"security_review"
		);
		assert!(
			!public_decision_reason(Some("openrouter-model-council"), None).contains("openrouter")
		);
	}
}
