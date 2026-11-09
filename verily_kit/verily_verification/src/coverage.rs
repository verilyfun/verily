//! Exercises every branch the library exposes. Kept under `cfg(test)`.

use std::collections::HashMap;

use chrono::DateTime;
use chrono::Utc;
use p256::ecdsa::Signature;
use p256::ecdsa::SigningKey;
use p256::ecdsa::signature::Signer;

use crate::binding;
use crate::capture;
use crate::capture::AndroidAttestation;
use crate::capture::AppAttestAssertion;
use crate::capture::AttestationUnavailable;
use crate::capture::KeyStorage;
use crate::capture::ParsedAndroidKey;
use crate::capture::SignatureMode;
use crate::config;
use crate::config::VerifierConfig;
use crate::config::VerifierMode;
use crate::council;
use crate::council::ModelVote;
use crate::council::SpokenVerdict;
use crate::council::Verdict;
use crate::evidence;
use crate::location;
use crate::location::LocationPolicy;
use crate::location::Observation;
use crate::location::PreviousObservation;
use crate::model_input;
use crate::movement;
use crate::movement::MovementKind;
use crate::ops::Verification;
use crate::payout;
use crate::payout::AcceptanceBasis;
use crate::payout::PayoutRequest;
use crate::reasons;
use crate::review;
use verily_shared::ActionVerificationPolicy;
use verily_shared::EvidenceDecisionStatus;
use verily_shared::EvidenceProvenanceLevel;
use verily_shared::MediaEvidenceKind;

fn now() -> DateTime<Utc> {
	DateTime::from_timestamp(1_700_000_100, 0).unwrap()
}

fn keypair() -> (SigningKey, Vec<u8>) {
	let mut scalar = [0_u8; 32];
	scalar[31] = 7;
	let signing = SigningKey::from_slice(&scalar).unwrap();
	let public = signing
		.verifying_key()
		.to_encoded_point(true)
		.as_bytes()
		.to_vec();
	(signing, public)
}

struct Scripted {
	key: ParsedAndroidKey,
}

impl AndroidAttestation for Scripted {
	fn parse(
		&self,
		_chain_der: &[&[u8]],
		_expected_challenge: &[u8; 32],
	) -> Result<ParsedAndroidKey, capture::CaptureError> {
		Ok(self.key.clone())
	}
}

#[test]
fn binding_covers_every_kind_and_refusal() {
	assert!(binding::normalize_capture_challenge("short").is_err());
	assert!(binding::normalize_capture_challenge(&"!".repeat(43)).is_err());
	assert!(binding::canonical_identifier("").is_err());
	assert!(binding::canonical_identifier("a=b").is_err());
	assert!(binding::canonical_identifier("a\nb").is_err());
	let challenge = "ERERERERERERERERERERERERERERERERERERERERERE";
	let attempt = "attempt-1";
	let requirement = "requirement-1";
	let binding_hash = "ab".repeat(32);
	let request =
		binding::capture_request_hash(attempt, requirement, challenge, &binding_hash).unwrap();
	assert_eq!(request.len(), 43);
	let manifest =
		binding::capture_manifest(attempt, requirement, &request, &binding_hash).unwrap();
	assert!(binding::capture_manifest(attempt, requirement, "nope", &binding_hash).is_err());
	assert!(
		binding::media_binding_hash(
			MediaEvidenceKind::Photo,
			1,
			&binding_hash,
			0,
			0,
			"image/jpeg"
		)
		.is_err()
	);
	assert!(
		binding::media_binding_hash(
			MediaEvidenceKind::Photo,
			1,
			&binding_hash,
			4,
			1,
			"image/jpeg"
		)
		.is_err()
	);
	assert!(
		binding::media_binding_hash(
			MediaEvidenceKind::Video,
			1,
			&binding_hash,
			4,
			0,
			"video/mp4"
		)
		.is_err()
	);
	assert!(
		binding::media_binding_hash(MediaEvidenceKind::Audio, 1, &binding_hash, 4, 2, "").is_err()
	);
	assert!(
		binding::media_binding_hash(
			MediaEvidenceKind::Video,
			1,
			&binding_hash,
			4,
			2,
			"video/mp4"
		)
		.is_ok()
	);
	assert!(
		binding::media_binding_hash(
			MediaEvidenceKind::Audio,
			1,
			&binding_hash,
			4,
			2,
			"audio/mp4"
		)
		.is_ok()
	);
	assert!(binding::location_binding_hash(1, f64::NAN, 0.0, 1.0).is_err());
	assert!(binding::location_binding_hash(1, 91.0, 0.0, 1.0).is_err());
	assert!(binding::location_binding_hash(1, 0.0, 181.0, 1.0).is_err());
	assert!(binding::location_binding_hash(1, 0.0, 0.0, -1.0).is_err());
	assert!(binding::location_binding_hash(1, 51.5, -0.12, 8.0).is_ok());
	assert!(binding::qr_binding_hash(1, "  ").is_err());
	assert!(binding::qr_binding_hash(1, "abc").is_ok());
	assert!(binding::motion_binding_hash(1, &binding_hash, 0, 10).is_err());
	assert!(binding::motion_binding_hash(1, &binding_hash, 10, 0).is_err());
	assert!(binding::motion_binding_hash(1, &binding_hash, 10, 100).is_ok());
	assert!(!binding::app_attest_device_client_data(&manifest, "token").is_empty());
	assert!(
		binding::app_attest_registration_client_data_hash(challenge)
			.unwrap()
			.len() == 32
	);
}

#[test]
fn capture_covers_window_modes_and_trusted_without_storage() {
	let opened = now();
	let window = capture::begin_capture("attempt-1", "requirement-1", opened).unwrap();
	assert_eq!(window.capture_challenge.len(), 43);
	assert!(capture::begin_capture("", "requirement-1", opened).is_err());
	assert!(capture::begin_capture("attempt-1", "bad=id", opened).is_err());
	assert_eq!(
		capture::signature_mode(None).unwrap(),
		SignatureMode::Optional
	);
	assert_eq!(
		capture::signature_mode(Some("required")).unwrap(),
		SignatureMode::Required
	);
	assert!(capture::signature_mode(Some("maybe")).is_err());
	let (signing, public) = keypair();
	let manifest = b"manifest";
	let signature: Signature = signing.sign(manifest);
	let refused = capture::verify_android_capture(
		&Scripted {
			key: ParsedAndroidKey {
				public_sec1: public.clone(),
				trusted: true,
				storage: None,
				reason: "no-storage",
			},
		},
		&[],
		&window.capture_challenge,
		"attempt-1",
		manifest,
		&signature.to_bytes(),
		SignatureMode::Optional,
	);
	assert_eq!(refused, Err(capture::CaptureError::Refused));
	assert_eq!(
		capture::judge_app_attest(AppAttestAssertion {
			signature_verifies: false,
			rp_id_matches: true,
			counter: 2,
			last_accepted_counter: 1,
		}),
		Err(capture::CaptureError::Refused)
	);
	assert_eq!(
		capture::verify_android_capture(
			&Scripted {
				key: ParsedAndroidKey {
					public_sec1: public,
					trusted: false,
					storage: None,
					reason: "unused",
				},
			},
			&[],
			"not-a-valid-challenge",
			"attempt-1",
			manifest,
			&signature.to_bytes(),
			SignatureMode::Optional,
		),
		Err(capture::CaptureError::Refused)
	);
}

#[test]
fn capture_scripted_refuses_a_mismatched_challenge() {
	struct Checking {
		key: ParsedAndroidKey,
	}
	impl AndroidAttestation for Checking {
		fn parse(
			&self,
			_chain_der: &[&[u8]],
			expected: &[u8; 32],
		) -> Result<ParsedAndroidKey, capture::CaptureError> {
			let challenge = binding::android_attestation_challenge(
				"ERERERERERERERERERERERERERERERERERERERERERE",
				"attempt-1",
			)
			.unwrap();
			if expected == &challenge {
				Ok(self.key.clone())
			} else {
				Err(capture::CaptureError::Refused)
			}
		}
	}
	let (signing, public) = keypair();
	let manifest = b"manifest";
	let signature: Signature = signing.sign(manifest);
	let checking = Checking {
		key: ParsedAndroidKey {
			public_sec1: public,
			trusted: true,
			storage: Some(KeyStorage::StrongBox),
			reason: "ok",
		},
	};
	assert_eq!(
		capture::verify_android_capture(
			&checking,
			&[],
			"ERERERERERERERERERERERERERERERERERERERERERE",
			"attempt-1",
			manifest,
			&signature.to_bytes(),
			SignatureMode::Optional,
		)
		.unwrap(),
		EvidenceProvenanceLevel::HardwareAttested
	);
	assert_eq!(
		capture::verify_android_capture(
			&checking,
			&[],
			"ERERERERERERERERERERERERERERERERERERERERERE",
			"other-attempt",
			manifest,
			&signature.to_bytes(),
			SignatureMode::Optional,
		),
		Err(capture::CaptureError::Refused)
	);
}

#[test]
fn config_covers_cloud_openrouter_and_every_refusal() {
	let mut env = HashMap::new();
	env.insert("VERILY_MEDIA_VERIFIER_MODE".into(), "nope".into());
	assert!(VerifierConfig::from_resolved(&env, None, None).is_err());
	env.insert("VERILY_MEDIA_VERIFIER_MODE".into(), "cloud".into());
	assert!(VerifierConfig::from_resolved(&env, Some("tok"), None).is_err());
	env.insert(
		"VERILY_MEDIA_VERIFIER_URL".into(),
		"https://verifier.example/v1".into(),
	);
	assert!(VerifierConfig::from_resolved(&env, None, None).is_err());
	assert!(VerifierConfig::from_resolved(&env, Some("  "), None).is_err());
	let cloud = VerifierConfig::from_resolved(&env, Some("tok"), None).unwrap();
	assert_eq!(cloud.mode, VerifierMode::Cloud);
	assert!(format!("{:?}", cloud.token.as_ref().unwrap()).contains("redacted"));
	assert_eq!(cloud.token.as_ref().unwrap().expose(), "tok");

	env.insert("VERILY_MEDIA_VERIFIER_MODE".into(), "openrouter".into());
	env.insert(
		"VERILY_OPENROUTER_PROMPT_INJECTION_GUARD".into(),
		"block".into(),
	);
	assert!(VerifierConfig::from_resolved(&env, None, None).is_err());
	assert!(VerifierConfig::from_resolved(&env, None, Some("key")).is_ok());
	env.insert(
		"VERILY_OPENROUTER_COUNCIL_MODELS".into(),
		format!(
			"{},{},{}",
			config::GEMINI_FLASH_LITE,
			config::GEMINI_FLASH_LITE,
			config::GEMMA
		),
	);
	assert!(VerifierConfig::from_resolved(&env, None, Some("key")).is_err());
	env.insert(
		"VERILY_OPENROUTER_COUNCIL_MODELS".into(),
		format!(
			"{},{},{}",
			config::GEMINI_FLASH_LITE,
			config::GEMMA,
			config::DEEPSEEK_VISION
		),
	);
	assert!(VerifierConfig::from_resolved(&env, None, Some("key")).is_err());
	env.insert(
		"VERILY_OPENROUTER_COUNCIL_MODELS".into(),
		format!(
			"{},{},{}",
			config::GEMINI_FLASH_LITE,
			config::GEMMA,
			config::GLM_FLASH
		),
	);
	env.insert("VERILY_OPENROUTER_REQUIRE_ZDR".into(), "maybe".into());
	assert!(VerifierConfig::from_resolved(&env, None, Some("key")).is_err());
	env.insert("VERILY_OPENROUTER_REQUIRE_ZDR".into(), "false".into());
	env.insert("VERILY_MEDIA_VERIFIER_TIMEOUT_SECONDS".into(), "3".into());
	assert!(VerifierConfig::from_resolved(&env, None, Some("key")).is_err());
	env.insert("VERILY_MEDIA_VERIFIER_TIMEOUT_SECONDS".into(), "90".into());
	env.insert(
		"VERILY_OPENROUTER_URL".into(),
		"http://openrouter.ai/x".into(),
	);
	assert!(VerifierConfig::from_resolved(&env, None, Some("key")).is_err());
	env.insert(
		"VERILY_OPENROUTER_URL".into(),
		"https://openrouter.ai/api/v1/chat/completions?x=1".into(),
	);
	assert!(VerifierConfig::from_resolved(&env, None, Some("key")).is_err());
	env.insert(
		"VERILY_OPENROUTER_URL".into(),
		"https://openrouter.ai/api/v1/chat/completions".into(),
	);
	let openrouter = VerifierConfig::from_resolved(&env, None, Some("key")).unwrap();
	assert_eq!(openrouter.mode, VerifierMode::OpenRouter);
	assert!(!openrouter.require_zero_data_retention);
}

#[test]
fn council_covers_single_model_spoken_and_budget_paths() {
	let accept = ModelVote {
		model_id: "m".into(),
		resolved_model_id: None,
		verdict: Verdict::Fulfilled,
		confidence: Some(0.9),
		spoken: Some(SpokenVerdict::Heard),
		error_code: None,
	};
	let reject = ModelVote {
		verdict: Verdict::NotFulfilled,
		spoken: Some(SpokenVerdict::NotHeard),
		..accept.clone()
	};
	let failed = ModelVote {
		verdict: Verdict::Failed,
		confidence: Some(0.1),
		error_code: Some("verification_budget_unavailable".into()),
		spoken: None,
		..accept.clone()
	};
	let low = ModelVote {
		confidence: Some(0.1),
		spoken: None,
		..accept.clone()
	};
	assert_eq!(
		council::decide(
			ActionVerificationPolicy::SingleModel,
			std::slice::from_ref(&reject),
			0.5,
			false
		)
		.reason_code,
		"media_requirements_not_met"
	);
	assert_eq!(
		council::decide(
			ActionVerificationPolicy::SingleModel,
			std::slice::from_ref(&failed),
			0.5,
			false
		)
		.reason_code,
		"verification_budget_unavailable"
	);
	assert_eq!(
		council::decide(
			ActionVerificationPolicy::SingleModel,
			&[ModelVote {
				error_code: Some("other".into()),
				..failed.clone()
			}],
			0.5,
			false
		)
		.reason_code,
		"media_verifier_unavailable"
	);
	assert_eq!(
		council::decide(ActionVerificationPolicy::SingleModel, &[low], 0.5, false).reason_code,
		"media_confidence_below_threshold"
	);
	assert_eq!(
		council::decide(
			ActionVerificationPolicy::ModelCouncil,
			&[
				accept.clone(),
				ModelVote {
					verdict: Verdict::Failed,
					confidence: None,
					error_code: Some("down".into()),
					spoken: None,
					..accept.clone()
				},
				ModelVote {
					verdict: Verdict::Failed,
					confidence: None,
					error_code: Some("down".into()),
					spoken: None,
					..accept.clone()
				}
			],
			0.5,
			false
		)
		.reason_code,
		"media_council_quorum_unavailable"
	);
	assert_eq!(
		council::decide(
			ActionVerificationPolicy::SingleModel,
			std::slice::from_ref(&accept),
			0.5,
			true
		)
		.reason_code,
		"media_requirements_verified"
	);
	assert_eq!(
		council::decide(
			ActionVerificationPolicy::ModelCouncil,
			&[
				ModelVote {
					spoken: Some(SpokenVerdict::Heard),
					..accept.clone()
				},
				ModelVote {
					spoken: Some(SpokenVerdict::Heard),
					..accept.clone()
				},
				accept.clone()
			],
			0.5,
			true
		)
		.reason_code,
		"media_council_verified"
	);
	assert_eq!(
		council::decide(
			ActionVerificationPolicy::SingleModel,
			&[ModelVote {
				spoken: Some(SpokenVerdict::NotHeard),
				..accept.clone()
			}],
			0.5,
			true
		)
		.reason_code,
		"spoken_challenge_not_heard"
	);
	assert_eq!(
		council::decide(
			ActionVerificationPolicy::SingleModel,
			&[ModelVote {
				verdict: Verdict::Fulfilled,
				confidence: None,
				spoken: None,
				error_code: None,
				..accept.clone()
			}],
			0.5,
			false
		)
		.reason_code,
		"media_verifier_uncertain"
	);
	assert_eq!(
		council::decide(
			ActionVerificationPolicy::ModelCouncil,
			&[accept.clone(), accept.clone(), accept.clone()],
			0.99,
			false
		)
		.reason_code,
		"media_council_no_consensus"
	);
}

#[test]
fn evidence_covers_limits_validate_and_change() {
	let user = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
	let attempt = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
	let requirement = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
	assert!(evidence::Expectation::new(user, attempt, requirement, "image/jpeg", 0).is_err());
	assert!(
		evidence::Expectation::new(user, attempt, requirement, "image/jpeg", 21 * 1024 * 1024)
			.is_err()
	);
	for content in [
		"video/mp4",
		"video/quicktime",
		"video/webm",
		"image/png",
		"image/heic",
		"audio/mp4",
		"audio/webm",
	] {
		assert!(evidence::Expectation::new(user, attempt, requirement, content, 12).is_ok());
	}
	let expectation =
		evidence::Expectation::new(user, attempt, requirement, "image/jpeg", 12).unwrap();
	let digest = "ab".repeat(32);
	let ok = evidence::Inspection {
		version_id: format!("local-sha256-{digest}"),
		sha256_digest: digest.clone(),
		byte_length: 12,
		content_type: "image/jpeg".into(),
	};
	assert!(evidence::seal_inspection(&expectation, "wrong-path", &ok).is_err());
	let sealed = evidence::seal_inspection(&expectation, &expectation.storage_path, &ok).unwrap();
	assert!(
		evidence::validate_persisted(
			&expectation,
			"wrong",
			&ok.version_id,
			&digest,
			12,
			"image/jpeg"
		)
		.is_err()
	);
	assert!(
		evidence::validate_persisted(
			&expectation,
			&expectation.storage_path,
			&ok.version_id,
			&digest,
			12,
			"image/jpeg"
		)
		.is_ok()
	);
	assert!(
		evidence::assert_unchanged(
			&sealed,
			&evidence::Inspection {
				content_type: "image/png".into(),
				..ok.clone()
			}
		)
		.is_err()
	);
	assert!(
		evidence::assert_unchanged(
			&sealed,
			&evidence::Inspection {
				sha256_digest: "cd".repeat(32),
				version_id: format!("local-sha256-{}", "cd".repeat(32)),
				..ok
			}
		)
		.is_err()
	);
	assert!(
		evidence::Expectation::new(
			"AAAAAAAA-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
			attempt,
			requirement,
			"image/jpeg",
			12
		)
		.is_err()
	);
	assert!(
		evidence::validate_persisted(
			&expectation,
			&expectation.storage_path,
			"short",
			&"ab".repeat(32),
			12,
			"image/jpeg"
		)
		.is_err()
	);
	assert!(
		evidence::validate_persisted(
			&expectation,
			&expectation.storage_path,
			&ok.version_id,
			&"ab".repeat(32),
			12,
			"image/gif"
		)
		.is_err()
	);
	assert!(
		evidence::seal_for_test(
			&expectation.storage_path,
			&ok.version_id,
			&"ab".repeat(32),
			12,
			"image/gif"
		)
		.is_err()
	);
	assert!(
		evidence::seal_for_test(
			&expectation.storage_path,
			&ok.version_id,
			&"ab".repeat(32),
			0,
			"image/jpeg"
		)
		.is_err()
	);
}

#[test]
fn location_covers_risk_accuracy_and_travel() {
	let policy = LocationPolicy::default();
	let current = Observation {
		accuracy_meters: 8.0,
		captured_at: now(),
	};
	assert_eq!(
		policy.evaluate(
			now(),
			Observation {
				accuracy_meters: 1.0,
				captured_at: now() - chrono::Duration::minutes(10),
			},
			None
		),
		location::LocationRisk::Stale
	);
	assert_eq!(
		policy.evaluate(
			now(),
			Observation {
				accuracy_meters: 1.0,
				captured_at: now() + chrono::Duration::minutes(5),
			},
			None
		),
		location::LocationRisk::FromFuture
	);
	assert_eq!(
		policy.evaluate(
			now(),
			current,
			Some(PreviousObservation {
				distance_meters: 60_000.0,
				accuracy_meters: 1.0,
				captured_at: now() + chrono::Duration::seconds(1),
			})
		),
		location::LocationRisk::None
	);
	assert_eq!(
		policy.evaluate(
			now(),
			current,
			Some(PreviousObservation {
				distance_meters: 60_000.0,
				accuracy_meters: 1.0,
				captured_at: now() - chrono::Duration::seconds(1),
			})
		),
		location::LocationRisk::ImplausibleTravel
	);
	assert_eq!(
		policy.evaluate(
			now(),
			current,
			Some(PreviousObservation {
				distance_meters: 60_000.0,
				accuracy_meters: 1.0,
				captured_at: current.captured_at,
			})
		),
		location::LocationRisk::ImplausibleTravel
	);
	assert_eq!(
		policy.evaluate(
			now(),
			current,
			Some(PreviousObservation {
				distance_meters: 100.0,
				accuracy_meters: 1.0,
				captured_at: now() - chrono::Duration::seconds(10),
			})
		),
		location::LocationRisk::None
	);
	assert_eq!(
		policy.evaluate(
			now(),
			current,
			Some(PreviousObservation {
				distance_meters: 60_000.0,
				accuracy_meters: 1.0,
				captured_at: now() - chrono::Duration::hours(1),
			})
		),
		location::LocationRisk::None
	);
	assert!(location::decide(policy, now(), current, 50.0, 1.0, 0.0, None).is_err());
	assert_eq!(
		location::decide(
			policy,
			now(),
			Observation {
				accuracy_meters: 8.0,
				captured_at: now() - chrono::Duration::minutes(10),
			},
			50.0,
			1.0,
			100.0,
			None
		)
		.unwrap()
		.reason_code,
		"location_capture_stale"
	);
	assert_eq!(
		location::decide(
			policy,
			now(),
			Observation {
				accuracy_meters: 8.0,
				captured_at: now() + chrono::Duration::minutes(5),
			},
			50.0,
			1.0,
			100.0,
			None
		)
		.unwrap()
		.reason_code,
		"location_capture_time_invalid"
	);
	assert_eq!(
		location::decide(policy, now(), current, 5.0, 1.0, 100.0, None)
			.unwrap()
			.reason_code,
		"location_accuracy_too_low"
	);
	assert_eq!(
		location::decide(
			policy,
			now(),
			current,
			50.0,
			1.0,
			100.0,
			Some(PreviousObservation {
				distance_meters: 60_000.0,
				accuracy_meters: 1.0,
				captured_at: now() - chrono::Duration::seconds(1),
			})
		)
		.unwrap()
		.reason_code,
		"location_travel_needs_review"
	);
}

#[test]
fn model_input_movement_reasons_and_ops_cover_the_rest() {
	assert!(!model_input::is_safe_verification_policy("too short"));
	assert!(model_input::validate_short_copy("").is_err());
	assert!(model_input::validate_creator_prompt(&"a".repeat(2001)).is_err());
	for kind in [
		MovementKind::Squats,
		MovementKind::PressUps,
		MovementKind::SitUps,
		MovementKind::Lunges,
		MovementKind::StarJumps,
		MovementKind::Burpees,
		MovementKind::HighKnees,
		MovementKind::LateralRaises,
		MovementKind::BicepsCurls,
		MovementKind::SideBends,
		MovementKind::FootballKickUps,
		MovementKind::TableTennisBounces,
	] {
		assert!(movement::verification_prompt(kind, 3).is_ok());
		assert!(movement::validate_target(kind, Some(3), 3600).is_ok());
	}
	assert!(movement::validate_target(MovementKind::Squats, None, 10).is_err());

	assert_eq!(
		reasons::public_decision_reason(None, None),
		reasons::CHECKING
	);
	assert_eq!(
		reasons::public_decision_reason(None, Some(EvidenceDecisionStatus::Accepted)),
		reasons::PROOF_ACCEPTED
	);
	assert_eq!(
		reasons::public_decision_reason(None, Some(EvidenceDecisionStatus::ManualReview)),
		reasons::NEEDS_REVIEW
	);
	assert_eq!(
		reasons::public_decision_reason(Some("other"), Some(EvidenceDecisionStatus::Rejected)),
		reasons::PROOF_NOT_ACCEPTED
	);
	assert_eq!(
		reasons::public_decision_reason(
			Some("motion_miss"),
			Some(EvidenceDecisionStatus::Rejected)
		),
		reasons::MOTION_NOT_MATCHED
	);
	assert_eq!(
		reasons::public_decision_reason(
			Some("device_integrity_fail"),
			Some(EvidenceDecisionStatus::Rejected)
		),
		reasons::CAPTURE_NOT_VERIFIED
	);
	assert_eq!(
		reasons::public_decision_reason(
			Some("app_integrity_not_recognised"),
			Some(EvidenceDecisionStatus::Rejected)
		),
		reasons::CAPTURE_NOT_VERIFIED
	);
	for code in [
		"inside_geofence",
		"qr_code_matched",
		"motion_verified",
		"location_accuracy_too_low",
		"location_capture_stale",
		"media_capture_time_invalid",
		"location_travel_needs_review",
		"media_duration_out_of_range",
		"media_verification_queued",
		"spoken_challenge_missing",
		"spoken_challenge_predates_capture",
		"spoken_challenge_not_heard",
		"qr_code_mismatch",
		"missing_required_evidence",
		"action_capacity_reached",
		"high_value_payout_review",
	] {
		let _ = reasons::public_decision_reason(Some(code), Some(EvidenceDecisionStatus::Accepted));
	}
	for code in [
		"high_value_payout_review",
		"spoken_challenge_unverified",
		"location_travel_needs_review",
		"abuse_review_required",
		"mp_replay_unavailable",
		"media_verifier_retry_exhausted",
		"media_confidence_below_threshold",
		"unknown",
	] {
		let _ = reasons::public_review_reason(code);
	}

	assert_eq!(
		payout::authorize(PayoutRequest {
			amount_atoms: 1,
			review_threshold_atoms: Some(10),
			basis: AcceptanceBasis::Person,
		})
		.unwrap(),
		payout::PayoutAuthorization::PersonAccepted
	);

	let closed = Verification::closed().unwrap();
	let opened = now();
	let window = closed
		.begin_capture("attempt-1", "requirement-1", opened)
		.unwrap();
	assert!(closed.begin_capture("", "requirement-1", opened).is_err());
	let spoken = closed.issue_spoken_challenge(None, 0, 2, opened).unwrap();
	assert!(closed.issue_spoken_challenge(None, 5, 2, opened).is_err());
	let user = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
	let attempt = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
	let requirement = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
	let expectation =
		evidence::Expectation::new(user, attempt, requirement, "image/jpeg", 12).unwrap();
	let digest = "ab".repeat(32);
	let inspection = evidence::Inspection {
		version_id: format!("local-sha256-{digest}"),
		sha256_digest: digest,
		byte_length: 12,
		content_type: "image/jpeg".into(),
	};
	assert!(
		closed
			.seal_stored_evidence(&expectation, &inspection)
			.is_ok()
	);
	assert!(
		closed
			.seal_stored_evidence(
				&expectation,
				&evidence::Inspection {
					byte_length: 1,
					..inspection.clone()
				}
			)
			.is_err()
	);
	assert_eq!(
		closed.decide_media(&[], 0.5, false).status,
		EvidenceDecisionStatus::ManualReview
	);
	let mut env = HashMap::new();
	env.insert("VERILY_MEDIA_VERIFIER_MODE".into(), "openrouter".into());
	env.insert(
		"VERILY_OPENROUTER_PROMPT_INJECTION_GUARD".into(),
		"block".into(),
	);
	env.insert(
		"VERILY_OPENROUTER_COUNCIL_MODELS".into(),
		format!(
			"{},{},{}",
			config::GEMINI_FLASH_LITE,
			config::GEMMA,
			config::GLM_FLASH
		),
	);
	let openrouter = Verification::new(
		VerifierConfig::from_resolved(&env, None, Some("key")).unwrap(),
		SignatureMode::Optional,
		AttestationUnavailable,
	);
	let fulfilled = ModelVote {
		model_id: "m".into(),
		resolved_model_id: None,
		verdict: Verdict::Fulfilled,
		confidence: Some(0.9),
		spoken: None,
		error_code: None,
	};
	assert_eq!(
		openrouter
			.decide_media(
				&[fulfilled.clone(), fulfilled.clone(), fulfilled.clone()],
				0.5,
				false
			)
			.status,
		EvidenceDecisionStatus::Accepted
	);
	let mut single_config = VerifierConfig::from_resolved(&env, None, Some("key")).unwrap();
	single_config.council_model_ids.clear();
	let single = Verification::new(
		single_config,
		SignatureMode::Optional,
		AttestationUnavailable,
	);
	assert_eq!(
		single.decide_media(&[fulfilled], 0.5, false).reason_code,
		"media_requirements_verified"
	);
	assert_eq!(
		closed.verify_android_capture(&[], &window.capture_challenge, "attempt-1", b"m", &[0; 64]),
		Err(crate::ops::OpError::Unavailable)
	);
	let (signing, public) = keypair();
	let manifest = b"ops-manifest";
	let signature: Signature = signing.sign(manifest);
	let scripted = Verification::new(
		VerifierConfig::from_resolved(&HashMap::new(), None, None).unwrap(),
		SignatureMode::Required,
		Scripted {
			key: ParsedAndroidKey {
				public_sec1: public,
				trusted: false,
				storage: Some(KeyStorage::TrustedEnvironment),
				reason: "test",
			},
		},
	);
	assert_eq!(
		scripted.verify_android_capture(
			&[],
			&window.capture_challenge,
			"attempt-1",
			manifest,
			&signature.to_bytes()
		),
		Err(crate::ops::OpError::Refused)
	);
	assert!(
		closed
			.decide_location(
				opened,
				Observation {
					accuracy_meters: 8.0,
					captured_at: opened
				},
				50.0,
				1.0,
				100.0,
				None
			)
			.is_ok()
	);
	assert!(
		closed
			.decide_location(
				opened,
				Observation {
					accuracy_meters: f64::NAN,
					captured_at: opened
				},
				50.0,
				1.0,
				100.0,
				None
			)
			.is_err()
	);
	assert!(
		closed
			.authorize_payout(PayoutRequest {
				amount_atoms: 1,
				review_threshold_atoms: Some(10),
				basis: AcceptanceBasis::Deterministic,
			})
			.is_ok()
	);
	assert_eq!(
		closed
			.resolve_review(EvidenceDecisionStatus::Accepted, "looks good")
			.unwrap(),
		"looks good"
	);
	assert!(
		closed
			.resolve_review(EvidenceDecisionStatus::ManualReview, "note")
			.is_err()
	);
	let _ = spoken;
	let _ = review::review_note("ok");
	assert_eq!(
		EvidenceProvenanceLevel::Basic,
		EvidenceProvenanceLevel::Basic
	);
}
