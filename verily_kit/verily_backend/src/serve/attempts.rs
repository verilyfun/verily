//! Doing an action: the attempt, its capture windows, spoken words, proof,
//! and the server's decision.
//!
//! The order is the one in `docs/verification.md`. `begin_capture` opens a
//! window before any sensor does. Proof is accepted only inside an open
//! window, once, and pinned to the SHA-256 the phone reports: a different
//! digest for the same proof is refused, never swapped in. Every decision
//! here comes from `verily_verification`; with the manual-review verifier
//! (the default without secrets) proof goes to a person, never to a pass.

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use chrono::DateTime;
use chrono::Utc;
use leptoskit_auth::Account as AuthAccount;
use leptoskit_db::Connection;
use leptoskit_db::Id;
use leptoskit_db::Read;
use leptoskit_rpc as rpc;
use sha2::Digest;
use sha2::Sha256;
use uuid::Uuid;
use verily_api::AppealStatus;
use verily_api::AttemptOpened;
use verily_api::AttemptOutcome;
use verily_api::AttemptRow;
use verily_api::AttemptStatus;
use verily_api::AttestationReceipt;
use verily_api::CaptureWindow;
use verily_api::ProofReceipt;
use verily_api::SpokenWord;
use verily_rewards::RewardsError;
use verily_rewards::ops::into_rpc;
use verily_rewards::schema::ActionRow;
use verily_rewards::schema::RewardPoolRow;
use verily_shared::ActionRecurrence;
use verily_shared::ActionRequirementKind;
use verily_shared::ActionRequirementView;
use verily_shared::ActionVerificationPolicy;
use verily_shared::EvidenceDecisionStatus;
use verily_shared::RewardPoolStatus;
use verily_verification::asn1::hex_lower;
use verily_verification::capture::SignatureMode;
use verily_verification::motion;
use verily_verification::ops::OpError;
use verily_verification::spoken::SpokenChallenge;

use super::Backend;
use super::attest::redeem_qr_challenge;
use super::attest::verify_registered_app_attest_assertion;
use super::backend;
use super::catalogue::is_open;
use super::db;
use super::me;
use super::name;
use super::parse_id;
use super::require_active;
use super::requirements;
use crate::schema::Appeal;
use crate::schema::Attempt;
use crate::schema::CaptureWindowRow;
use crate::schema::Evidence;
use crate::schema::EvidenceDecision;
use crate::schema::EvidenceUploadReservationRow;
use crate::schema::NewAttempt;
use crate::schema::NewCaptureWindowRow;
use crate::schema::NewEvidence;
use crate::schema::NewEvidenceDecision;
use crate::schema::NewEvidenceVerificationJobRow;
use crate::schema::NewSpokenChallengeRow;
use crate::schema::SpokenChallengeRow;

/// An attempt may open this many capture windows an hour.
const WINDOWS_PER_HOUR: u64 = 10;
/// Confidence a model must reach when one is configured. The default
/// verifier is a person, so this only matters in a model mode.
const MIN_CONFIDENCE: f64 = 0.7;

/// The signed-in person's attempts, newest first.
pub async fn list_my_attempts(cx: &rpc::QueryCx) -> rpc::Result<Vec<AttemptRow>> {
	let participant = me(cx.context())?;
	let attempts = Attempt::query()
		.filter(|row| row.participant_id.eq(participant))
		.order_by(|row| row.started_at.desc())
		.limit(100)
		.all(cx.db())
		.await
		.map_err(db)?;
	let mut rows = Vec::with_capacity(attempts.len());
	for attempt in attempts {
		let appeal = Appeal::query()
			.filter(|row| row.attempt_id.eq(attempt.id))
			.first(cx.db())
			.await
			.map_err(db)?;
		let appeal = match appeal.as_ref().map(|row| row.status.as_str()) {
			Some("open") => AppealStatus::Pending,
			Some("overturned") => AppealStatus::Accepted,
			Some("upheld") => AppealStatus::Rejected,
			None if status_of(&attempt.status) == AttemptStatus::Rejected => {
				AppealStatus::Available
			}
			_ => AppealStatus::Unavailable,
		};
		let title = ActionRow::query()
			.filter(|row| row.id.eq(attempt.action_id))
			.first(cx.db())
			.await
			.map_err(db)?
			.map(|action| action.title)
			.unwrap_or_default();
		rows.push(AttemptRow {
			id: attempt.id.to_string(),
			action_title: title,
			status: status_of(&attempt.status),
			appeal,
		});
	}
	Ok(rows)
}

/// Opens, or returns, the signed-in person's attempt at a live action for
/// this period, and the first proof it still needs.
pub async fn begin_attempt(cx: &rpc::MutationCx, action_id: String) -> rpc::Result<AttemptOpened> {
	let participant = me(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let action_uuid = parse_id(&action_id)?;
	let action = ActionRow::query()
		.filter(|row| row.id.eq(Id::<ActionRow>::from_uuid(action_uuid)))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	let now = Utc::now();
	if !is_open(&action, now) {
		return Err(rpc::Error::invalid("actionUnavailable"));
	}
	let period_key = period_key(&action, now);
	let attempt = match Attempt::query()
		.filter(|row| {
			row.action_id.eq(action.id)
				& row.participant_id.eq(participant)
				& row.period_key.eq(period_key.clone())
		})
		.first(cx.tx())
		.await
		.map_err(db)?
	{
		Some(attempt) => attempt,
		None => NewAttempt {
			action_id: action.id,
			participant_id: participant,
			idempotency_key: format!("{}:{period_key}", action.id),
			period_key,
			status: status_name(AttemptStatus::CollectingEvidence).to_owned(),
			verification_score: None,
			rejection_code: None,
			reward_outcome: None,
			submitted_at: None,
			verified_at: None,
		}
		.insert(cx.tx())
		.await
		.map_err(db)?,
	};
	let requirements = requirements(&action)?;
	let next = next_requirement(cx.tx(), &attempt, &requirements).await?;
	Ok(AttemptOpened {
		attempt_id: attempt.id.to_string(),
		requirement_id: next
			.map(|requirement| requirement.id.to_string())
			.unwrap_or_default(),
	})
}

/// Opens a capture window for one proof. The camera, microphone, sensors,
/// and scanner start only after this answers. The challenge it returns is
/// what the device's fresh key attests to.
pub async fn begin_capture(
	cx: &rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
) -> rpc::Result<CaptureWindow> {
	let participant = me(cx.context())?;
	let backend = backend(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let (attempt, _action, requirement) =
		open_attempt(cx.tx(), participant, &attempt_id, &requirement_id).await?;
	if requirement.kind == ActionRequirementKind::ExternalApp {
		return Err(rpc::Error::invalid("externalProof"));
	}
	let now = Utc::now();
	let recent = CaptureWindowRow::query()
		.filter(|row| {
			row.attempt_id.eq(attempt.id) & row.opened_at.gt(now - chrono::Duration::hours(1))
		})
		.count(cx.tx())
		.await
		.map_err(db)?;
	if recent >= WINDOWS_PER_HOUR {
		return Err(rpc::Error::conflict("tooManyCaptures"));
	}
	let window = backend
		.verification
		.begin_capture(&attempt.id.to_string(), &requirement.id.to_string(), now)
		.map_err(|error| op_error(&error))?;
	NewCaptureWindowRow {
		attempt_id: attempt.id,
		participant_id: participant,
		requirement_id: window.requirement_id.clone(),
		challenge: window.capture_challenge.clone(),
		opened_at: window.opened_at,
		expires_at: window.expires_at,
		consumed_at: None,
		sha256_digest: None,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;
	let spoken_word = if requirement.spoken_challenge_required {
		Some(issue_word(cx.tx(), backend, &attempt, &requirement, now).await?)
	} else {
		None
	};
	Ok(CaptureWindow {
		attempt_id: window.attempt_id,
		requirement_id: window.requirement_id,
		challenge: window.capture_challenge,
		spoken_word,
		kind: super::proof_kind(requirement.kind),
	})
}

/// The word to say while recording this proof, from the server's list.
///
/// It is a query the capture screen reads as it opens, so it issues in its
/// own transaction as the caller. Issuing is idempotent: a word that is
/// still live, or one proof is already bound to, comes back unchanged, so a
/// refetch never spends another word.
pub async fn issue_spoken_challenge(
	cx: &rpc::QueryCx,
	attempt_id: String,
	requirement_id: String,
) -> rpc::Result<SpokenWord> {
	let participant = me(cx.context())?;
	let backend = backend(cx.context())?;
	let tx = cx
		.db()
		.connection()
		.begin_serializable()
		.await
		.map_err(db)?;
	let word = async {
		require_active(&tx, participant).await?;
		let (attempt, _action, requirement) =
			open_attempt(&tx, participant, &attempt_id, &requirement_id).await?;
		if !requirement.spoken_challenge_required {
			return Err(rpc::Error::invalid("noSpokenChallenge"));
		}
		issue_word(&tx, backend, &attempt, &requirement, Utc::now()).await
	}
	.await;
	match word {
		Ok(word) => {
			tx.commit().await.map_err(db)?;
			Ok(SpokenWord { word })
		}
		Err(error) => {
			let _ = tx.rollback().await;
			Err(error)
		}
	}
}

/// Pins the digest of a live capture to this attempt's proof.
///
/// The capture must come from a window the server opened for this proof and
/// that is still open; the window is then used up. The same digest again is
/// the same proof; a different digest for proof already pinned is refused.
pub async fn submit_live_proof(
	cx: &rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	digest_hex: String,
) -> rpc::Result<ProofReceipt> {
	let participant = me(cx.context())?;
	let backend = backend(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let (attempt, _action, requirement) =
		open_attempt(cx.tx(), participant, &attempt_id, &requirement_id).await?;
	let digest = verily_verification::binding::normalize_sha256(&digest_hex)
		.map_err(|_| rpc::Error::invalid("invalidDigest"))?;

	if let Some(existing) = evidence_for(cx.tx(), &attempt, &requirement).await? {
		return if existing.sha256_digest.as_deref() == Some(digest.as_str()) {
			Ok(ProofReceipt {
				digest_hex: digest,
				stored: true,
			})
		} else {
			Err(rpc::Error::conflict("proofAlreadySubmitted"))
		};
	}

	let now = Utc::now();
	let requirement_key = requirement.id.to_string();
	let mut window = CaptureWindowRow::query()
		.filter(|row| {
			row.attempt_id.eq(attempt.id)
				& row.requirement_id.eq(requirement_key.clone())
				& row.consumed_at.is_null()
				& row.expires_at.gt(now)
		})
		.order_by(|row| row.opened_at.desc())
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::invalid("captureWindowClosed"))?;
	if verily_verification::capture::captured_before_window(now, window.opened_at) {
		return Err(rpc::Error::invalid("captureWindowClosed"));
	}

	let spoken = requirement.spoken_challenge_required;
	if spoken {
		let mut word = live_word(cx.tx(), &attempt, &requirement_key, now)
			.await?
			.ok_or_else(|| rpc::Error::invalid("spokenChallengeMissing"))?;
		if verily_verification::spoken::capture_predates_challenge(now, word.issued_at) {
			return Err(rpc::Error::invalid("spokenChallengeMissing"));
		}
		word.bound_at = Some(now);
		word.save(cx.tx()).await.map_err(db)?;
	}

	window.consumed_at = Some(now);
	window.sha256_digest = Some(digest.clone());
	window.save(cx.tx()).await.map_err(db)?;

	let evidence = NewEvidence {
		attempt_id: attempt.id,
		requirement_key,
		kind: name(&requirement.kind),
		storage_path: None,
		storage_version_id: None,
		mime_type: None,
		sha256_digest: Some(digest.clone()),
		byte_length: None,
		provenance_level: "basic".to_owned(),
		capture_manifest: None,
		capture_signature: None,
		capture_public_key: None,
		capture_key_id: None,
		capture_key_storage: None,
		captured_at: now,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	let decision = proof_decision(backend, &requirement);
	record_decision(
		cx.tx(),
		evidence.id,
		decision.0,
		decision.1,
		decision.2,
		None,
		decision.3,
	)
	.await?;

	Ok(ProofReceipt {
		digest_hex: digest,
		stored: true,
	})
}

/// Whether the digest the phone attested is proof this attempt pinned.
///
/// The call carries no signature, token, or certificate, so it never raises
/// the proof's provenance: `bound` only says the attested digest is exactly
/// the evidence the server accepted. When a device signature is required,
/// this call cannot satisfy it and answers `false`.
pub async fn submit_attestation(
	cx: &rpc::MutationCx,
	attempt_id: String,
	digest_hex: String,
) -> rpc::Result<AttestationReceipt> {
	let participant = me(cx.context())?;
	let backend = backend(cx.context())?;
	let attempt = owned_attempt(cx.tx(), participant, &attempt_id).await?;
	let Ok(digest) = verily_verification::binding::normalize_sha256(&digest_hex) else {
		return Ok(AttestationReceipt { bound: false });
	};
	if backend.verification.signature_mode() == SignatureMode::Required {
		return Ok(AttestationReceipt { bound: false });
	}
	let pinned = Evidence::query()
		.filter(|row| row.attempt_id.eq(attempt.id) & row.sha256_digest.eq(Some(digest)))
		.exists(cx.tx())
		.await
		.map_err(db)?;
	Ok(AttestationReceipt { bound: pinned })
}

/// Binds a confirmed immutable storage upload (`reservation_id`) to an open
/// capture window and queues background verification (`EvidenceVerificationJobRow`).
#[allow(
	clippy::too_many_lines,
	reason = "linear transactional verification of upload reservation, capture window, spoken challenge, evidence, and job"
)]
pub async fn submit_media_proof(
	cx: &rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	reservation_id: String,
) -> rpc::Result<ProofReceipt> {
	let participant = me(cx.context())?;
	let backend = backend(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let (attempt, _action, requirement) =
		open_attempt(cx.tx(), participant, &attempt_id, &requirement_id).await?;

	let res_id = Id::<EvidenceUploadReservationRow>::from_uuid(parse_id(&reservation_id)?);
	let reservation = EvidenceUploadReservationRow::query()
		.filter(|r| {
			r.id.eq(res_id) & r.attempt_id.eq(attempt.id) & r.participant_id.eq(participant)
		})
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	if reservation.requirement_id != requirement.id.to_string() {
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	let (Some(version_id), Some(digest)) = (reservation.version_id, reservation.sha256_digest)
	else {
		return Err(rpc::Error::invalid("uploadNotConfirmed"));
	};

	if let Some(existing) = evidence_for(cx.tx(), &attempt, &requirement).await? {
		return if existing.sha256_digest.as_deref() == Some(digest.as_str()) {
			Ok(ProofReceipt {
				digest_hex: digest,
				stored: true,
			})
		} else {
			Err(rpc::Error::conflict("proofAlreadySubmitted"))
		};
	}

	let now = Utc::now();
	let requirement_key = requirement.id.to_string();
	let mut window = CaptureWindowRow::query()
		.filter(|row| {
			row.attempt_id.eq(attempt.id)
				& row.requirement_id.eq(requirement_key.clone())
				& row.consumed_at.is_null()
				& row.expires_at.gt(now)
		})
		.order_by(|row| row.opened_at.desc())
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::invalid("captureWindowClosed"))?;

	if requirement.spoken_challenge_required {
		let mut word = live_word(cx.tx(), &attempt, &requirement_key, now)
			.await?
			.ok_or_else(|| rpc::Error::invalid("spokenChallengeMissing"))?;
		word.bound_at = Some(now);
		word.save(cx.tx()).await.map_err(db)?;
	}

	window.consumed_at = Some(now);
	window.sha256_digest = Some(digest.clone());
	window.save(cx.tx()).await.map_err(db)?;

	let evidence = NewEvidence {
		attempt_id: attempt.id,
		requirement_key,
		kind: name(&requirement.kind),
		storage_path: Some(reservation.object_key),
		storage_version_id: Some(version_id),
		mime_type: Some(reservation.mime_type),
		sha256_digest: Some(digest.clone()),
		byte_length: reservation.byte_length,
		provenance_level: "basic".to_owned(),
		capture_manifest: None,
		capture_signature: None,
		capture_public_key: None,
		capture_key_id: None,
		capture_key_storage: None,
		captured_at: now,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	NewEvidenceVerificationJobRow {
		evidence_id: evidence.id,
		attempt_id: attempt.id,
		status: "queued".to_owned(),
		attempt_count: 0,
		last_error_code: None,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	let decision = proof_decision(backend, &requirement);
	record_decision(
		cx.tx(),
		evidence.id,
		decision.0,
		decision.1,
		decision.2,
		None,
		decision.3,
	)
	.await?;

	Ok(ProofReceipt {
		digest_hex: digest,
		stored: true,
	})
}

/// Evaluates a canonical device gyroscope + accelerometer motion trace
/// deterministically on the server (never trusting client repetition counts).
#[allow(
	clippy::too_many_lines,
	reason = "linear transactional verification of motion trace, capture window, evidence, and deterministic scoring"
)]
pub async fn submit_motion_proof(
	cx: &rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	trace_json: String,
) -> rpc::Result<ProofReceipt> {
	let participant = me(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let (attempt, _action, requirement) =
		open_attempt(cx.tx(), participant, &attempt_id, &requirement_id).await?;
	if requirement.kind != ActionRequirementKind::Motion {
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	let samples = motion::parse_canonical_trace_json(&trace_json)
		.map_err(|_| rpc::Error::invalid("invalidMotionTrace"))?;
	let digest = motion::motion_trace_sha256(&samples)
		.map_err(|_| rpc::Error::invalid("invalidMotionTrace"))?;

	if let Some(existing) = evidence_for(cx.tx(), &attempt, &requirement).await? {
		return if existing.sha256_digest.as_deref() == Some(digest.as_str()) {
			Ok(ProofReceipt {
				digest_hex: digest,
				stored: true,
			})
		} else {
			Err(rpc::Error::conflict("proofAlreadySubmitted"))
		};
	}

	let now = Utc::now();
	let requirement_key = requirement.id.to_string();
	let mut window = CaptureWindowRow::query()
		.filter(|row| {
			row.attempt_id.eq(attempt.id)
				& row.requirement_id.eq(requirement_key.clone())
				& row.consumed_at.is_null()
				& row.expires_at.gt(now)
		})
		.order_by(|row| row.opened_at.desc())
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::invalid("captureWindowClosed"))?;

	window.consumed_at = Some(now);
	window.sha256_digest = Some(digest.clone());
	window.save(cx.tx()).await.map_err(db)?;

	let evidence = NewEvidence {
		attempt_id: attempt.id,
		requirement_key,
		kind: name(&requirement.kind),
		storage_path: None,
		storage_version_id: None,
		mime_type: Some("application/json".to_owned()),
		sha256_digest: Some(digest.clone()),
		byte_length: i64::try_from(trace_json.len()).ok(),
		provenance_level: "basic".to_owned(),
		capture_manifest: None,
		capture_signature: None,
		capture_public_key: None,
		capture_key_id: None,
		capture_key_storage: None,
		captured_at: now,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	if let Some(rule) = motion_rule_from_requirement(&requirement) {
		match motion::analyze(&samples, &rule) {
			Ok(analysis) => {
				let status = if analysis.accepted {
					EvidenceDecisionStatus::Accepted
				} else {
					EvidenceDecisionStatus::Rejected
				};
				record_decision(
					cx.tx(),
					evidence.id,
					status,
					"motion-deterministic",
					analysis.reason_code,
					None,
					if analysis.accepted {
						"Motion trace satisfied the action rule."
					} else {
						"Motion trace did not meet the action rule."
					},
				)
				.await?;
			}
			Err(_) => {
				record_decision(
					cx.tx(),
					evidence.id,
					EvidenceDecisionStatus::Rejected,
					"motion-deterministic",
					"motion_trace_invalid",
					None,
					"Motion trace failed validation.",
				)
				.await?;
			}
		}
	} else {
		let hold = motion::hold_for_review(0);
		record_decision(
			cx.tx(),
			evidence.id,
			hold.status,
			"motion-deterministic",
			hold.reason_code,
			None,
			hold.summary,
		)
		.await?;
	}

	Ok(ProofReceipt {
		digest_hex: digest,
		stored: true,
	})
}

/// Redeems a rotating creator-issued venue QR code once for a `QrCode` requirement.
pub async fn submit_qr_proof(
	cx: &rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	code: String,
) -> rpc::Result<ProofReceipt> {
	let participant = me(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let (attempt, action, requirement) =
		open_attempt(cx.tx(), participant, &attempt_id, &requirement_id).await?;
	if requirement.kind != ActionRequirementKind::QrCode {
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	redeem_qr_challenge(cx.tx(), action.id, attempt.id, &code).await?;

	let digest = hex_lower(&Sha256::digest(code.trim().as_bytes()));
	let now = Utc::now();
	let requirement_key = requirement.id.to_string();
	if let Some(mut window) = CaptureWindowRow::query()
		.filter(|row| {
			row.attempt_id.eq(attempt.id)
				& row.requirement_id.eq(requirement_key.clone())
				& row.consumed_at.is_null()
				& row.expires_at.gt(now)
		})
		.order_by(|row| row.opened_at.desc())
		.first(cx.tx())
		.await
		.map_err(db)?
	{
		window.consumed_at = Some(now);
		window.sha256_digest = Some(digest.clone());
		window.save(cx.tx()).await.map_err(db)?;
	}

	let evidence = NewEvidence {
		attempt_id: attempt.id,
		requirement_key,
		kind: name(&requirement.kind),
		storage_path: None,
		storage_version_id: None,
		mime_type: None,
		sha256_digest: Some(digest.clone()),
		byte_length: None,
		provenance_level: "basic".to_owned(),
		capture_manifest: None,
		capture_signature: None,
		capture_public_key: None,
		capture_key_id: None,
		capture_key_storage: None,
		captured_at: now,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	record_decision(
		cx.tx(),
		evidence.id,
		EvidenceDecisionStatus::Accepted,
		"venue-qr-verifier",
		"venue_code_verified",
		None,
		"Venue code redeemed once.",
	)
	.await?;

	Ok(ProofReceipt {
		digest_hex: digest,
		stored: true,
	})
}

#[derive(serde::Serialize, serde::Deserialize)]
struct StoredLocationObservation {
	latitude: f64,
	longitude: f64,
	accuracy_meters: f64,
	captured_at_ms: i64,
}

/// Evaluates a live device GPS fix against the action's geofence, accuracy,
/// freshness, and implausible-travel rules via [`verily_verification::location::decide`].
///
/// Coordinates stay private on the server (`capture_manifest` is `#[db(private)]`)
/// and mock/simulated fixes are rejected unconditionally.
#[allow(
	clippy::too_many_arguments,
	clippy::too_many_lines,
	reason = "linear transactional verification of location fix, capture window, geofence, and travel plausibility"
)]
pub async fn submit_location_proof(
	cx: &rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	latitude: f64,
	longitude: f64,
	accuracy_meters: f64,
	captured_at_ms: i64,
	is_mock: bool,
) -> rpc::Result<ProofReceipt> {
	let participant = me(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let (attempt, action, requirement) =
		open_attempt(cx.tx(), participant, &attempt_id, &requirement_id).await?;
	if requirement.kind != ActionRequirementKind::Location {
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	if is_mock {
		return Err(rpc::Error::invalid("mockLocationRejected"));
	}
	if !latitude.is_finite()
		|| !longitude.is_finite()
		|| !(-90.0..=90.0).contains(&latitude)
		|| !(-180.0..=180.0).contains(&longitude)
		|| !accuracy_meters.is_finite()
		|| accuracy_meters < 0.0
	{
		return Err(rpc::Error::invalid("invalidLocation"));
	}
	let captured_at = DateTime::from_timestamp_millis(captured_at_ms)
		.ok_or_else(|| rpc::Error::invalid("invalidLocation"))?;

	let canonical = format!("{latitude:.6},{longitude:.6},{accuracy_meters:.2},{captured_at_ms}");
	let digest = hex_lower(&Sha256::digest(canonical.as_bytes()));

	if let Some(existing) = evidence_for(cx.tx(), &attempt, &requirement).await? {
		return if existing.sha256_digest.as_deref() == Some(digest.as_str()) {
			Ok(ProofReceipt {
				digest_hex: digest,
				stored: true,
			})
		} else {
			Err(rpc::Error::conflict("proofAlreadySubmitted"))
		};
	}

	let now = Utc::now();
	let requirement_key = requirement.id.to_string();
	let mut window = CaptureWindowRow::query()
		.filter(|row| {
			row.attempt_id.eq(attempt.id)
				& row.requirement_id.eq(requirement_key.clone())
				& row.consumed_at.is_null()
				& row.expires_at.gt(now)
		})
		.order_by(|row| row.opened_at.desc())
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::invalid("captureWindowClosed"))?;

	window.consumed_at = Some(now);
	window.sha256_digest = Some(digest.clone());
	window.save(cx.tx()).await.map_err(db)?;

	let place = super::catalogue::place_for(cx.tx(), action.id).await?;
	let target_coords = requirement
		.latitude
		.zip(requirement.longitude)
		.or_else(|| place.as_ref().and_then(|p| p.latitude.zip(p.longitude)));
	let radius_meters = requirement.radius_meters.or_else(|| {
		place.as_ref().and_then(|p| {
			(p.radius_meters > 0)
				.then(|| u32::try_from(p.radius_meters).ok().map(f64::from))
				.flatten()
		})
	});
	let max_accuracy_meters = requirement.max_accuracy_meters.unwrap_or(100.0);

	let previous =
		previous_location_observation(cx.tx(), participant, (latitude, longitude)).await?;

	let manifest_json = serde_json::to_string(&StoredLocationObservation {
		latitude,
		longitude,
		accuracy_meters,
		captured_at_ms,
	})
	.ok();

	let evidence = NewEvidence {
		attempt_id: attempt.id,
		requirement_key,
		kind: name(&requirement.kind),
		storage_path: None,
		storage_version_id: None,
		mime_type: Some("application/json".to_owned()),
		sha256_digest: Some(digest.clone()),
		byte_length: manifest_json
			.as_ref()
			.and_then(|s| i64::try_from(s.len()).ok()),
		provenance_level: "basic".to_owned(),
		capture_manifest: manifest_json,
		capture_signature: None,
		capture_public_key: None,
		capture_key_id: None,
		capture_key_storage: None,
		captured_at,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	match (target_coords, radius_meters) {
		(Some(target), Some(radius)) if radius > 0.0 => {
			let distance_meters = super::catalogue::haversine_meters((latitude, longitude), target);
			let obs = verily_verification::location::Observation {
				accuracy_meters,
				captured_at,
			};
			let decision = verily_verification::location::decide(
				verily_verification::location::LocationPolicy::default(),
				now,
				obs,
				max_accuracy_meters,
				distance_meters,
				radius,
				previous,
			)
			.map_err(|_| rpc::Error::invalid("invalidLocation"))?;
			record_decision(
				cx.tx(),
				evidence.id,
				decision.status,
				decision.verifier_type,
				decision.reason_code,
				None,
				decision.summary,
			)
			.await?;
		}
		_ => {
			record_decision(
				cx.tx(),
				evidence.id,
				EvidenceDecisionStatus::ManualReview,
				"geofence",
				"location_target_missing",
				None,
				"A person will check this location proof.",
			)
			.await?;
		}
	}

	Ok(ProofReceipt {
		digest_hex: digest,
		stored: true,
	})
}

async fn previous_location_observation(
	connection: &impl Read,
	participant: Id<AuthAccount>,
	current_coords: (f64, f64),
) -> Result<Option<verily_verification::location::PreviousObservation>, rpc::Error> {
	let attempts = Attempt::query()
		.filter(|row| row.participant_id.eq(participant))
		.order_by(|row| row.started_at.desc())
		.limit(25)
		.all(connection)
		.await
		.map_err(db)?;
	let location_kind = name(&ActionRequirementKind::Location);
	let mut latest: Option<(DateTime<Utc>, StoredLocationObservation)> = None;
	for attempt in attempts {
		let rows = Evidence::query()
			.filter(|row| row.attempt_id.eq(attempt.id) & row.kind.eq(location_kind.clone()))
			.order_by(|row| row.captured_at.desc())
			.limit(5)
			.all(connection)
			.await
			.map_err(db)?;
		for row in rows {
			let Some(raw) = row.capture_manifest.as_deref() else {
				continue;
			};
			let Ok(parsed) = serde_json::from_str::<StoredLocationObservation>(raw) else {
				continue;
			};
			let Some(ts) = DateTime::from_timestamp_millis(parsed.captured_at_ms) else {
				continue;
			};
			if latest.as_ref().is_none_or(|(prev_ts, _)| ts > *prev_ts) {
				latest = Some((ts, parsed));
			}
		}
	}
	Ok(latest.map(|(captured_at, prev)| {
		let distance_meters =
			super::catalogue::haversine_meters((prev.latitude, prev.longitude), current_coords);
		verily_verification::location::PreviousObservation {
			distance_meters,
			accuracy_meters: prev.accuracy_meters,
			captured_at,
		}
	}))
}

/// Cryptographically verifies Android Key Attestation + Play Integrity OR
/// registered Apple App Attest assertions bound to an already-pinned evidence digest.
///
/// Key storage level and hardware provenance are derived solely from verified
/// certificate chains or registered App Attest keys — never from client claims.
pub async fn submit_device_attestation(
	cx: &rpc::MutationCx,
	attempt_id: String,
	digest_hex: String,
	platform: String,
	payload_b64: String,
	key_id_b64: Option<String>,
	integrity_token: Option<String>,
) -> rpc::Result<AttestationReceipt> {
	let participant = me(cx.context())?;
	let backend = backend(cx.context())?;
	let attempt = owned_attempt(cx.tx(), participant, &attempt_id).await?;
	let Ok(digest) = verily_verification::binding::normalize_sha256(&digest_hex) else {
		return Ok(AttestationReceipt { bound: false });
	};
	let Some(mut evidence) = Evidence::query()
		.filter(|row| row.attempt_id.eq(attempt.id) & row.sha256_digest.eq(Some(digest.clone())))
		.first(cx.tx())
		.await
		.map_err(db)?
	else {
		return Ok(AttestationReceipt { bound: false });
	};

	let now = Utc::now();
	match platform.trim().to_ascii_lowercase().as_str() {
		"android" => {
			let Some(verifier) = &backend.android_attestation else {
				return Ok(AttestationReceipt { bound: false });
			};
			let Some(window) = CaptureWindowRow::query()
				.filter(|r| r.attempt_id.eq(attempt.id) & r.sha256_digest.eq(Some(digest.clone())))
				.order_by(|r| r.opened_at.desc())
				.first(cx.tx())
				.await
				.map_err(db)?
			else {
				return Ok(AttestationReceipt { bound: false });
			};
			// Payload is JSON array of base64 DER certificates.
			let Ok(raw_json) = STANDARD.decode(payload_b64.trim().as_bytes()) else {
				return Ok(AttestationReceipt { bound: false });
			};
			let Ok(cert_b64s) = serde_json::from_slice::<Vec<String>>(&raw_json) else {
				return Ok(AttestationReceipt { bound: false });
			};
			let mut certs = Vec::with_capacity(cert_b64s.len());
			for b64 in &cert_b64s {
				let Ok(der) = STANDARD.decode(b64.trim().as_bytes()) else {
					return Ok(AttestationReceipt { bound: false });
				};
				certs.push(der);
			}
			let refs: Vec<&[u8]> = certs.iter().map(Vec::as_slice).collect();
			let mut challenge_hasher = Sha256::new();
			challenge_hasher.update(window.challenge.as_bytes());
			challenge_hasher.update(attempt.id.to_string().as_bytes());
			let expected_challenge = challenge_hasher.finalize();

			let verdict = verifier.verify(&refs, &expected_challenge, now);
			if !verdict.trusted {
				return Ok(AttestationReceipt { bound: false });
			}
			let mut provenance = "hardware_attested".to_owned();
			if let (Some(pi), Some(token)) = (&backend.play_integrity, integrity_token.as_deref()) {
				let pi_verdict = pi.verify(token, &digest, now, false).await;
				if pi_verdict.trusted {
					"play_integrity_verified".clone_into(&mut provenance);
				}
			}
			evidence.provenance_level = provenance;
			evidence.capture_key_id = verdict.device_key_id;
			evidence.capture_key_storage = verdict.security_level.map(|lvl| format!("{lvl:?}"));
			evidence.save(cx.tx()).await.map_err(db)?;
			Ok(AttestationReceipt { bound: true })
		}
		"ios" => {
			let Some(key_id) = key_id_b64.as_deref() else {
				return Ok(AttestationReceipt { bound: false });
			};
			let ok = verify_registered_app_attest_assertion(
				cx.tx(),
				backend,
				participant,
				key_id,
				&payload_b64,
				digest.as_bytes(),
			)
			.await?;
			if !ok {
				return Ok(AttestationReceipt { bound: false });
			}
			"secure_enclave_attested".clone_into(&mut evidence.provenance_level);
			evidence.capture_key_storage = Some("secureEnclaveAttested".to_owned());
			evidence.save(cx.tx()).await.map_err(db)?;
			Ok(AttestationReceipt { bound: true })
		}
		_ => Ok(AttestationReceipt { bound: false }),
	}
}

fn motion_rule_from_requirement(req: &ActionRequirementView) -> Option<motion::MotionRule> {
	let kind = match req.motion_type? {
		verily_shared::ActionMotionType::PhoneToss => motion::MotionActionType::PhoneToss,
		verily_shared::ActionMotionType::Rotation => motion::MotionActionType::Rotation,
		verily_shared::ActionMotionType::Shake => motion::MotionActionType::Shake,
		verily_shared::ActionMotionType::Stillness => motion::MotionActionType::Stillness,
	};
	let axis = match req.motion_axis {
		Some(verily_shared::ActionMotionAxis::Yaw) => motion::MotionAxis::Yaw,
		Some(verily_shared::ActionMotionAxis::Pitch) => motion::MotionAxis::Pitch,
		Some(verily_shared::ActionMotionAxis::Roll) => motion::MotionAxis::Roll,
		_ => motion::MotionAxis::Any,
	};
	let rule = motion::MotionRule {
		kind,
		axis,
		target_repetitions: u32::try_from(req.target_repetitions.unwrap_or(1)).unwrap_or(1),
		minimum_duration_seconds: u32::try_from(req.min_duration_seconds.unwrap_or(1)).unwrap_or(1),
		maximum_duration_seconds: u32::try_from(req.max_duration_seconds.unwrap_or(30))
			.unwrap_or(30),
		minimum_angular_speed_radians_per_second: req
			.min_angular_speed_radians_per_second
			.unwrap_or(1.5),
		maximum_angular_speed_radians_per_second: req
			.max_angular_speed_radians_per_second
			.unwrap_or(20.0),
		minimum_axis_dominance: req.min_axis_dominance.unwrap_or(0.65),
		minimum_free_fall_milliseconds: u32::try_from(
			req.min_free_fall_milliseconds.unwrap_or(150),
		)
		.unwrap_or(150),
		maximum_free_fall_milliseconds: u32::try_from(
			req.max_free_fall_milliseconds.unwrap_or(600),
		)
		.unwrap_or(600),
		minimum_peak_acceleration_meters_per_second_squared: req
			.min_peak_acceleration_meters_per_second_squared
			.unwrap_or(10.0),
		maximum_peak_acceleration_meters_per_second_squared: req
			.max_peak_acceleration_meters_per_second_squared
			.unwrap_or(50.0),
	};
	motion::validate_rule(&rule).ok()?;
	Some(rule)
}

/// Asks the server to decide the attempt from the proof it holds.
///
/// Until every required proof is in, the attempt keeps collecting. A proof a
/// person still has to look at sends it to review; a rejected one rejects
/// it; only when every proof is accepted is it verified, and only then is a
/// payout reserved.
pub async fn complete_attempt(
	cx: &rpc::MutationCx,
	attempt_id: String,
) -> rpc::Result<AttemptOutcome> {
	let participant = me(cx.context())?;
	let backend = backend(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let mut attempt = owned_attempt(cx.tx(), participant, &attempt_id).await?;
	if status_of(&attempt.status) != AttemptStatus::CollectingEvidence {
		return Ok(AttemptOutcome {
			status: status_of(&attempt.status),
		});
	}
	let status = settle(cx.tx(), backend, &mut attempt).await?;
	Ok(AttemptOutcome { status })
}

/// Moves an attempt that is collecting evidence or pending review to where
/// its proof puts it, reserves any payout earned, and notifies partner apps
/// (stamping verification request receipts and queuing signed webhooks).
pub(crate) async fn settle(
	connection: &impl Connection,
	backend: &Backend,
	attempt: &mut Attempt,
) -> Result<AttemptStatus, rpc::Error> {
	let prev_status = status_of(&attempt.status);
	let mut action = ActionRow::query()
		.filter(|row| row.id.eq(attempt.action_id))
		.first(connection)
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	let requirements = requirements(&action)?;
	let mut decisions = Vec::new();
	for requirement in requirements
		.iter()
		.filter(|requirement| requirement.is_required)
	{
		let Some(evidence) = evidence_for(connection, attempt, requirement).await? else {
			return Ok(prev_status);
		};
		decisions.push(latest_decision(connection, evidence.id).await?);
	}

	let now = Utc::now();
	let status = if decisions
		.iter()
		.any(|decision| decision == &Some(EvidenceDecisionStatus::Rejected))
	{
		attempt.rejection_code = Some("proof_rejected".to_owned());
		AttemptStatus::Rejected
	} else if decisions
		.iter()
		.any(|decision| decision != &Some(EvidenceDecisionStatus::Accepted))
	{
		AttemptStatus::PendingReview
	} else if prev_status != AttemptStatus::Verified
		&& action
			.max_verified_completions
			.is_some_and(|limit| action.verified_completions >= limit)
	{
		AttemptStatus::CapacityReached
	} else {
		if prev_status != AttemptStatus::Verified {
			action.verified_completions += 1;
			action.updated_at = now;
			action.save(connection).await.map_err(db)?;
		}
		attempt.verified_at.get_or_insert(now);
		if attempt.reward_outcome.is_none() {
			attempt.reward_outcome = reserve_reward(connection, backend, &action, attempt).await?;
		}
		AttemptStatus::Verified
	};
	status_name(status).clone_into(&mut attempt.status);
	attempt.submitted_at.get_or_insert(now);
	attempt.save(connection).await.map_err(db)?;

	if prev_status != status && matches!(status, AttemptStatus::Verified | AttemptStatus::Rejected)
	{
		notify_attempt_outcome(connection, backend, &action, attempt, status).await?;
	}
	Ok(status)
}

/// Stamps matching partner [`crate::schema::VerificationRequestRow`] entries with
/// a signed Ed25519 JWS receipt and enqueues signed webhook deliveries
/// (`attempt.verified` / `attempt.rejected`).
#[allow(
	clippy::too_many_lines,
	reason = "stamps partner verification requests with JWS receipts and enqueues deduplicated webhooks"
)]
pub(crate) async fn notify_attempt_outcome(
	connection: &impl Connection,
	backend: &Backend,
	action: &ActionRow,
	attempt: &Attempt,
	status: AttemptStatus,
) -> Result<(), rpc::Error> {
	let (status_str, event_type) = match status {
		AttemptStatus::Verified => ("verified", "attempt.verified"),
		AttemptStatus::Rejected => ("rejected", "attempt.rejected"),
		_ => return Ok(()),
	};
	let now = Utc::now();
	let mut notified_apps = std::collections::HashSet::new();

	// 1. Stamp any matching partner-initiated verification requests.
	let requests = crate::schema::VerificationRequestRow::query()
		.filter(|r| r.action_id.eq(attempt.action_id))
		.all(connection)
		.await
		.map_err(db)?;
	for mut req in requests {
		let bound_to_attempt = req.attempt_id == Some(attempt.id);
		let open_for_participant = req.participant_id == Some(attempt.participant_id)
			&& matches!(req.status.as_str(), "open" | "in_progress");
		if !bound_to_attempt && !open_for_participant {
			continue;
		}
		let app = crate::schema::VerilyAppRow::query()
			.filter(|a| a.id.eq(req.app_id))
			.first(connection)
			.await
			.map_err(db)?;
		req.attempt_id = Some(attempt.id);
		req.status = status_str.to_owned();
		let mut signed_receipt = req.receipt_jws.clone();
		if status == AttemptStatus::Verified
			&& signed_receipt.is_none()
			&& let (Some(signer), Some(app_row)) = (&backend.receipt_signer, &app)
		{
			let claims = serde_json::json!({
				"iss": "https://verily.fun",
				"aud": app_row.slug,
				"sub": req.external_subject.clone().unwrap_or_else(|| attempt.participant_id.to_string()),
				"jti": req.id.to_string(),
				"actionId": req.action_id.to_string(),
				"attemptId": attempt.id.to_string(),
				"status": "verified",
				"iat": now.timestamp(),
			});
			let jws = signer.sign_jws(&claims);
			req.receipt_jws = Some(jws.clone());
			signed_receipt = Some(jws);
		}
		req.save(connection).await.map_err(db)?;

		if let Some(app_row) = app
			&& app_row.active
			&& app_row.webhook_url.is_some()
			&& notified_apps.insert(app_row.id)
		{
			let payload = serde_json::json!({
				"event": event_type,
				"requestId": req.id.to_string(),
				"attemptId": attempt.id.to_string(),
				"actionId": attempt.action_id.to_string(),
				"externalSubject": req.external_subject,
				"status": status_str,
				"receipt": signed_receipt,
				"occurredAt": now.to_rfc3339(),
			});
			crate::schema::NewVerilyAppWebhookDeliveryRow {
				app_id: app_row.id,
				event_type: event_type.to_owned(),
				payload_json: payload.to_string(),
				status: "pending".to_owned(),
				attempts: 0,
				last_status_code: None,
				next_attempt_at: now,
			}
			.insert(connection)
			.await
			.map_err(db)?;
		}
	}

	// 2. Notify active partner apps owned by the action's creator that have a webhook URL.
	let creator_id = Id::<AuthAccount>::from_uuid(action.creator_id);
	let creator_apps = crate::schema::VerilyAppRow::query()
		.filter(|a| a.owner_id.eq(creator_id))
		.all(connection)
		.await
		.map_err(db)?;
	for app_row in creator_apps {
		if !app_row.active || app_row.webhook_url.is_none() || !notified_apps.insert(app_row.id) {
			continue;
		}
		let link = crate::schema::VerilyAppLinkRow::query()
			.filter(|l| l.app_id.eq(app_row.id) & l.account_id.eq(attempt.participant_id))
			.first(connection)
			.await
			.map_err(db)?;
		let payload = serde_json::json!({
			"event": event_type,
			"attemptId": attempt.id.to_string(),
			"actionId": attempt.action_id.to_string(),
			"externalUserId": link.map(|l| l.external_user_id),
			"status": status_str,
			"occurredAt": now.to_rfc3339(),
		});
		crate::schema::NewVerilyAppWebhookDeliveryRow {
			app_id: app_row.id,
			event_type: event_type.to_owned(),
			payload_json: payload.to_string(),
			status: "pending".to_owned(),
			attempts: 0,
			last_status_code: None,
			next_attempt_at: now,
		}
		.insert(connection)
		.await
		.map_err(db)?;
	}

	Ok(())
}

/// Reserves the payout index a verified attempt earned, in this transaction,
/// under the pool row `verily_rewards` updates. A retry gets the same index.
async fn reserve_reward(
	connection: &impl Connection,
	backend: &Backend,
	action: &ActionRow,
	attempt: &Attempt,
) -> Result<Option<String>, rpc::Error> {
	let Some(pool) = RewardPoolRow::query()
		.filter(|row| row.action_id.eq(action.id))
		.first(connection)
		.await
		.map_err(db)?
	else {
		return Ok(None);
	};
	if pool.status != name(&RewardPoolStatus::Funded) {
		return Ok(Some("pool_closed".to_owned()));
	}
	match verily_rewards::store::reserve_payout(
		connection,
		&backend.rewards,
		pool.chain_pool_id,
		attempt.id.uuid(),
		attempt.participant_id.uuid(),
	)
	.await
	{
		Ok(_) => Ok(Some("won".to_owned())),
		Err(RewardsError::Conflict("accountLimitReached")) => Ok(Some("account_limit".to_owned())),
		Err(RewardsError::Conflict("poolEmpty")) => Ok(Some("pool_empty".to_owned())),
		Err(error) => Err(into_rpc(error)),
	}
}

pub(super) async fn latest_decision(
	connection: &impl Read,
	evidence: Id<Evidence>,
) -> Result<Option<EvidenceDecisionStatus>, rpc::Error> {
	Ok(EvidenceDecision::query()
		.filter(|row| row.evidence_id.eq(evidence))
		.order_by(|row| row.created_at.desc())
		.first(connection)
		.await
		.map_err(db)?
		.and_then(|decision| decision_status(&decision.status)))
}

pub(crate) async fn record_decision(
	connection: &impl Connection,
	evidence: Id<Evidence>,
	status: EvidenceDecisionStatus,
	verifier_type: &str,
	reason_code: &str,
	reviewed_by: Option<Id<AuthAccount>>,
	summary: &str,
) -> Result<(), rpc::Error> {
	NewEvidenceDecision {
		evidence_id: evidence,
		status: decision_name(status).to_owned(),
		verifier_type: verifier_type.to_owned(),
		reason_code: reason_code.to_owned(),
		summary: summary.to_owned(),
		reviewed_by,
	}
	.insert(connection)
	.await
	.map_err(db)?;
	Ok(())
}

pub(super) const fn decision_name(status: EvidenceDecisionStatus) -> &'static str {
	match status {
		EvidenceDecisionStatus::Accepted => "accepted",
		EvidenceDecisionStatus::Rejected => "rejected",
		EvidenceDecisionStatus::ManualReview => "manual_review",
	}
}

fn decision_status(value: &str) -> Option<EvidenceDecisionStatus> {
	match value {
		"accepted" => Some(EvidenceDecisionStatus::Accepted),
		"rejected" => Some(EvidenceDecisionStatus::Rejected),
		"manual_review" => Some(EvidenceDecisionStatus::ManualReview),
		_ => None,
	}
}

pub(super) const fn status_name(status: AttemptStatus) -> &'static str {
	match status {
		AttemptStatus::CollectingEvidence => "collecting_evidence",
		AttemptStatus::Verifying => "verifying",
		AttemptStatus::PendingReview => "pending_review",
		AttemptStatus::Verified => "verified",
		AttemptStatus::Rejected => "rejected",
		AttemptStatus::CapacityReached => "capacity_reached",
	}
}

/// An unknown stored status is never shown as progress.
pub(super) fn status_of(value: &str) -> AttemptStatus {
	match value {
		"collecting_evidence" => AttemptStatus::CollectingEvidence,
		"verifying" => AttemptStatus::Verifying,
		"pending_review" => AttemptStatus::PendingReview,
		"verified" => AttemptStatus::Verified,
		"capacity_reached" => AttemptStatus::CapacityReached,
		_ => AttemptStatus::Rejected,
	}
}

/// The signed-in person's own attempt. Anyone else's is not found.
pub(super) async fn owned_attempt(
	connection: &impl Read,
	participant: Id<AuthAccount>,
	attempt_id: &str,
) -> Result<Attempt, rpc::Error> {
	let id = Id::<Attempt>::from_uuid(parse_id(attempt_id)?);
	Attempt::query()
		.filter(|row| row.id.eq(id) & row.participant_id.eq(participant))
		.first(connection)
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))
}

/// The caller's attempt, still collecting proof for a live action, and the
/// requirement of that action's revision it names.
async fn open_attempt(
	connection: &impl Read,
	participant: Id<AuthAccount>,
	attempt_id: &str,
	requirement_id: &str,
) -> Result<(Attempt, ActionRow, ActionRequirementView), rpc::Error> {
	let attempt = owned_attempt(connection, participant, attempt_id).await?;
	if status_of(&attempt.status) != AttemptStatus::CollectingEvidence {
		return Err(rpc::Error::invalid("attemptClosed"));
	}
	let action = ActionRow::query()
		.filter(|row| row.id.eq(attempt.action_id))
		.first(connection)
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	if !is_open(&action, Utc::now()) {
		return Err(rpc::Error::invalid("actionUnavailable"));
	}
	let requirement_id = parse_id(requirement_id)?;
	let requirement = requirements(&action)?
		.into_iter()
		.find(|requirement| requirement.id == requirement_id)
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	Ok((attempt, action, requirement))
}

async fn evidence_for(
	connection: &impl Read,
	attempt: &Attempt,
	requirement: &ActionRequirementView,
) -> Result<Option<Evidence>, rpc::Error> {
	let key = requirement.id.to_string();
	Evidence::query()
		.filter(|row| row.attempt_id.eq(attempt.id) & row.requirement_key.eq(key))
		.first(connection)
		.await
		.map_err(db)
}

/// The first required proof without evidence, else the first proof.
async fn next_requirement<'a>(
	connection: &impl Read,
	attempt: &Attempt,
	requirements: &'a [ActionRequirementView],
) -> Result<Option<&'a ActionRequirementView>, rpc::Error> {
	for requirement in requirements
		.iter()
		.filter(|requirement| requirement.is_required)
	{
		if evidence_for(connection, attempt, requirement)
			.await?
			.is_none()
		{
			return Ok(Some(requirement));
		}
	}
	Ok(requirements.first())
}

/// A word that is live, or the one proof is bound to; otherwise a new word
/// from `verily_verification`'s list.
async fn issue_word(
	connection: &impl Connection,
	backend: &Backend,
	attempt: &Attempt,
	requirement: &ActionRequirementView,
	now: DateTime<Utc>,
) -> Result<String, rpc::Error> {
	let requirement_key = requirement.id.to_string();
	let issued = SpokenChallengeRow::query()
		.filter(|row| {
			row.attempt_id.eq(attempt.id) & row.requirement_id.eq(requirement_key.clone())
		})
		.order_by(|row| row.issued_at.desc())
		.all(connection)
		.await
		.map_err(db)?;
	if let Some(bound) = issued.iter().find(|row| row.bound_at.is_some()) {
		return Ok(bound.word.clone());
	}
	let live = issued
		.iter()
		.find(|row| row.expires_at > now)
		.map(|row| SpokenChallenge {
			word: row.word.clone(),
			issued_at: row.issued_at,
			expires_at: row.expires_at,
		});
	let count = u32::try_from(issued.len()).unwrap_or(u32::MAX);
	let entropy = u64::from_le_bytes(Uuid::new_v4().as_bytes()[..8].try_into().unwrap_or([0; 8]));
	let challenge = backend
		.verification
		.issue_spoken_challenge(live.as_ref(), count, entropy, now)
		.map_err(|_| rpc::Error::conflict("challengesUsed"))?;
	if live.as_ref() != Some(&challenge) {
		NewSpokenChallengeRow {
			attempt_id: attempt.id,
			participant_id: attempt.participant_id,
			requirement_id: requirement_key,
			word: challenge.word.clone(),
			issued_at: challenge.issued_at,
			expires_at: challenge.expires_at,
			bound_at: None,
		}
		.insert(connection)
		.await
		.map_err(db)?;
	}
	Ok(challenge.word)
}

/// The live, unbound word for this proof.
async fn live_word(
	connection: &impl Read,
	attempt: &Attempt,
	requirement_key: &str,
	now: DateTime<Utc>,
) -> Result<Option<SpokenChallengeRow>, rpc::Error> {
	SpokenChallengeRow::query()
		.filter(|row| {
			row.attempt_id.eq(attempt.id)
				& row.requirement_id.eq(requirement_key.to_owned())
				& row.bound_at.is_null()
				& row.expires_at.gt(now)
		})
		.order_by(|row| row.issued_at.desc())
		.first(connection)
		.await
		.map_err(db)
}

/// Media goes through the verification checks. A model runs only when the
/// guard is confirmed, a budget is approved, and this server has issued a URL
/// for the immutable version. A digest alone has none of those, so a person
/// reviews. Other proof has no observation here.
fn proof_decision(
	backend: &Backend,
	requirement: &ActionRequirementView,
) -> (
	EvidenceDecisionStatus,
	&'static str,
	&'static str,
	&'static str,
) {
	if !is_media(requirement.kind) {
		return (
			EvidenceDecisionStatus::ManualReview,
			"manual-review-fallback",
			"observation_unavailable",
			"",
		);
	}
	let proof = media_proof(requirement);
	let decided = match backend.verification.assess_media(&proof) {
		verily_verification::openrouter::Outcome::Decided(assessment) => assessment.decision,
		verily_verification::openrouter::Outcome::Unreadable { .. } => {
			verily_verification::council::manual_review()
		}
	};
	(
		decided.status,
		decided.verifier_type,
		decided.reason_code,
		decided.summary,
	)
}

fn media_proof(
	requirement: &ActionRequirementView,
) -> verily_verification::openrouter::MediaProof<'_> {
	verily_verification::openrouter::MediaProof {
		verification_prompt: requirement.verification_prompt.as_deref(),
		policy: requirement
			.verification_policy
			.unwrap_or(ActionVerificationPolicy::SingleModel),
		kind: match requirement.kind {
			ActionRequirementKind::Photo => verily_verification::openrouter::MediaKind::Photo,
			ActionRequirementKind::Audio => verily_verification::openrouter::MediaKind::Audio,
			_ => verily_verification::openrouter::MediaKind::Video,
		},
		mime_type: "",
		duration_seconds: None,
		min_duration_seconds: seconds(requirement.min_duration_seconds),
		max_duration_seconds: seconds(requirement.max_duration_seconds),
		minimum_confidence: requirement.min_confidence.unwrap_or(MIN_CONFIDENCE),
		spoken_word: None,
		media: None,
	}
}

fn seconds(value: Option<i64>) -> Option<u32> {
	u32::try_from(value.unwrap_or(0))
		.ok()
		.filter(|seconds| *seconds > 0)
}

const fn is_media(kind: ActionRequirementKind) -> bool {
	matches!(
		kind,
		ActionRequirementKind::Photo | ActionRequirementKind::Video | ActionRequirementKind::Audio
	)
}

/// `once`, or the action's IANA time-zone day for a daily action (falling back to UTC).
fn period_key(action: &ActionRow, now: DateTime<Utc>) -> String {
	match serde_json::from_value(serde_json::Value::String(action.recurrence.clone())) {
		Ok(ActionRecurrence::Daily) => {
			if let Ok(tz) = action.time_zone.parse::<chrono_tz::Tz>() {
				now.with_timezone(&tz).format("%Y-%m-%d").to_string()
			} else {
				now.format("%Y-%m-%d").to_string()
			}
		}
		_ => "once".to_owned(),
	}
}

fn op_error(error: &OpError) -> rpc::Error {
	match error {
		OpError::Unavailable => rpc::Error::retry("verificationUnavailable"),
		OpError::Refused => rpc::Error::invalid("invalidRequest"),
	}
}
