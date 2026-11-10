//! Doing an action: the attempt, its capture windows, spoken words, proof,
//! and the server's decision.
//!
//! The order is the one in `docs/verification.md`. `begin_capture` opens a
//! window before any sensor does. Proof is accepted only inside an open
//! window, once, and pinned to the SHA-256 the phone reports: a different
//! digest for the same proof is refused, never swapped in. Every decision
//! here comes from `verily_verification`; with the manual-review verifier
//! (the default without secrets) proof goes to a person, never to a pass.

use chrono::DateTime;
use chrono::Utc;
use leptoskit_auth::Account as AuthAccount;
use leptoskit_db::Connection;
use leptoskit_db::Id;
use leptoskit_db::Read;
use leptoskit_rpc as rpc;
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
use verily_shared::EvidenceDecisionStatus;
use verily_shared::RewardPoolStatus;
use verily_verification::capture::SignatureMode;
use verily_verification::ops::OpError;
use verily_verification::spoken::SpokenChallenge;

use super::Backend;
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
use crate::schema::NewAttempt;
use crate::schema::NewCaptureWindowRow;
use crate::schema::NewEvidence;
use crate::schema::NewEvidenceDecision;
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

	// The phone sent a digest, not the bytes or an observation, so nothing
	// here can pass the proof by itself: media goes to the configured
	// verifier (a person without secrets), everything else to a person.
	let decision = if is_media(requirement.kind) {
		let decided = backend
			.verification
			.decide_media(&[], MIN_CONFIDENCE, spoken);
		(decided.status, decided.verifier_type, decided.reason_code)
	} else {
		(
			EvidenceDecisionStatus::ManualReview,
			"manual-review-fallback",
			"observation_unavailable",
		)
	};
	record_decision(
		cx.tx(),
		evidence.id,
		decision.0,
		decision.1,
		decision.2,
		None,
		"",
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
/// its proof puts it, and reserves the payout a verified attempt earned.
pub(super) async fn settle(
	connection: &impl Connection,
	backend: &Backend,
	attempt: &mut Attempt,
) -> Result<AttemptStatus, rpc::Error> {
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
			return Ok(status_of(&attempt.status));
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
	} else if action
		.max_verified_completions
		.is_some_and(|limit| action.verified_completions >= limit)
	{
		AttemptStatus::CapacityReached
	} else {
		action.verified_completions += 1;
		action.updated_at = now;
		action.save(connection).await.map_err(db)?;
		attempt.verified_at = Some(now);
		attempt.reward_outcome = reserve_reward(connection, backend, &action, attempt).await?;
		AttemptStatus::Verified
	};
	status_name(status).clone_into(&mut attempt.status);
	attempt.submitted_at.get_or_insert(now);
	attempt.save(connection).await.map_err(db)?;
	Ok(status)
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

pub(super) async fn record_decision(
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

const fn is_media(kind: ActionRequirementKind) -> bool {
	matches!(
		kind,
		ActionRequirementKind::Photo | ActionRequirementKind::Video | ActionRequirementKind::Audio
	)
}

/// `once`, or the UTC day for a daily action.
fn period_key(action: &ActionRow, now: DateTime<Utc>) -> String {
	match serde_json::from_value(serde_json::Value::String(action.recurrence.clone())) {
		Ok(ActionRecurrence::Daily) => now.format("%Y-%m-%d").to_string(),
		_ => "once".to_owned(),
	}
}

fn op_error(error: &OpError) -> rpc::Error {
	match error {
		OpError::Unavailable => rpc::Error::retry("verificationUnavailable"),
		OpError::Refused => rpc::Error::invalid("invalidRequest"),
	}
}
