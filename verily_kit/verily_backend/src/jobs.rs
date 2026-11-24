//! Durable background workers and recurring maintenance sweeps replacing all
//! 16 Serverpod `FutureCalls`.
//!
//! Runs via `leptoskit_rpc::server::Jobs` (`#[rpc::cron]` + background sweeps)
//! and exposes deterministic sweep entrypoints that integration tests can invoke
//! directly without waiting on wall-clock timers.

#![allow(
	clippy::missing_errors_doc,
	reason = "background sweeps propagate leptoskit_db::DbError directly"
)]

use std::path::PathBuf;
use std::time::Instant;

use chrono::Duration;
use chrono::Utc;
use leptoskit_db::Db;
use leptoskit_rpc as rpc;
use uuid::Uuid;
use verily_rewards::schema::ActionRow;
use verily_rewards::schema::RewardPayoutRow;
use verily_rewards::schema::WalletLinkChallengeRow;
use verily_shared::ActionRequirementKind;
use verily_shared::ActionVerificationPolicy;
use verily_shared::EvidenceDecisionStatus;
use verily_shared::RewardPayoutStatus;
use verily_verification::council::PROMPT_INJECTION;
use verily_verification::council::Verdict;
use verily_verification::local_check::LocalCheckReplayOutcome;
use verily_verification::openrouter::Budget;
use verily_verification::openrouter::IssuedMediaUrl;
use verily_verification::openrouter::MediaKind;
use verily_verification::openrouter::MediaProof;
use verily_verification::openrouter::Outcome;
use verily_verification::openrouter_http::ReqwestOpenRouterProvider;
use verily_verification::storage::StorageError;

use crate::partner_http::PullCheckVerdict;
use crate::partner_http::parse_pull_check_verdict;
use crate::partner_http::send_signed_pull_check;
use crate::partner_http::send_signed_webhook;
use crate::schema::ActionQrChallengeRow;
use crate::schema::AppAttestChallengeRow;
use crate::schema::AppAttestKeyRow;
use crate::schema::Appeal;
use crate::schema::Attempt;
use crate::schema::CaptureWindowRow;
use crate::schema::Evidence;
use crate::schema::EvidenceUploadReservationRow;
use crate::schema::EvidenceVerificationJobRow;
use crate::schema::NewEvidence;
use crate::schema::NewEvidenceDecision;
use crate::schema::NewEvidenceVerificationVoteRow;
use crate::schema::SpokenChallengeRow;
use crate::schema::VerificationRequestRow;
use crate::schema::VerilyAppLinkRow;
use crate::schema::VerilyAppPullCheckRow;
use crate::schema::VerilyAppRow;
use crate::schema::VerilyAppWebhookDeliveryRow;
use crate::serve::BackendHandle;

/// Estimated cost in micro-USD reserved per outbound AI verification model call (\$0.005).
const ESTIMATED_VERIFICATION_CALL_MICRO_USD: i64 = 5_000;
/// Evidence originals are deleted 7 days after submission once settled.
const STANDARD_EVIDENCE_RETENTION_DAYS: i64 = 7;
/// Open appeals extend raw evidence retention to 30 days so human reviewers can inspect proof.
const APPEAL_EVIDENCE_RETENTION_DAYS: i64 = 30;

/// Summary returned by a maintenance sweep pass (useful for tests & metrics).
#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct MaintenanceSummary {
	pub expired_capture_windows: usize,
	pub expired_spoken_challenges: usize,
	pub expired_qr_challenges: usize,
	pub expired_wallet_challenges: usize,
	pub expired_upload_reservations: usize,
	pub expired_app_attest_challenges: usize,
	pub expired_verification_requests: usize,
}

/// RAII temporary media file written for `MediaPipe` replay and always removed on drop.
struct TempMediaFile {
	path: PathBuf,
}

impl TempMediaFile {
	fn write(bytes: &[u8], mime_type: &str) -> std::io::Result<Self> {
		let ext = match mime_type.split(';').next().map(str::trim) {
			Some("video/mp4") => "mp4",
			Some("video/quicktime") => "mov",
			Some("video/webm") => "webm",
			Some("image/jpeg") => "jpg",
			Some("image/png") => "png",
			Some("image/webp") => "webp",
			Some("audio/wav" | "audio/x-wav") => "wav",
			Some("audio/mp4" | "audio/m4a") => "m4a",
			Some("audio/mpeg") => "mp3",
			_ => "bin",
		};
		let path = std::env::temp_dir().join(format!("verily-replay-{}.{ext}", Uuid::new_v4()));
		std::fs::write(&path, bytes)?;
		Ok(Self { path })
	}

	fn path(&self) -> &std::path::Path {
		&self.path
	}
}

impl Drop for TempMediaFile {
	fn drop(&mut self) {
		let _ = std::fs::remove_file(&self.path);
	}
}

/// Database-backed inference budget enforcing daily micro-USD caps before every model call.
struct DbInferenceBudget {
	db: Db,
	handle: tokio::runtime::Handle,
	daily_budget_micro_usd: Option<i64>,
}

impl Budget for DbInferenceBudget {
	fn reserve(&mut self, model_id: &str) -> bool {
		let db = self.db.clone();
		let model_id = model_id.to_owned();
		let cap = self.daily_budget_micro_usd;
		self.handle.block_on(async move {
			let sys = db.system("verily inference budget");
			crate::serve::reserve_inference_call(
				&sys,
				&model_id,
				ESTIMATED_VERIFICATION_CALL_MICRO_USD,
				cap,
			)
			.await
			.unwrap_or(false)
		})
	}
}

/// Runs all 7 expiry cleanup sweeps in one bounded pass.
pub async fn run_cleanup_sweeps(db: &Db) -> Result<MaintenanceSummary, leptoskit_db::DbError> {
	let db = &db.system("verily cleanup sweeps");
	let now = Utc::now();
	let mut summary = MaintenanceSummary::default();

	for mut row in CaptureWindowRow::query()
		.filter(|r| r.expires_at.lt(now))
		.limit(200)
		.all(db)
		.await?
	{
		if row.consumed_at.is_none() {
			row.delete(db).await?;
			summary.expired_capture_windows += 1;
		}
	}

	for mut row in SpokenChallengeRow::query()
		.filter(|r| r.expires_at.lt(now))
		.limit(200)
		.all(db)
		.await?
	{
		if row.bound_at.is_none() {
			row.delete(db).await?;
			summary.expired_spoken_challenges += 1;
		}
	}

	for mut row in ActionQrChallengeRow::query()
		.filter(|r| r.expires_at.lt(now))
		.limit(200)
		.all(db)
		.await?
	{
		if row.consumed_at.is_none() {
			row.delete(db).await?;
			summary.expired_qr_challenges += 1;
		}
	}

	for mut row in WalletLinkChallengeRow::query()
		.filter(|r| r.expires_at.lt(now))
		.limit(200)
		.all(db)
		.await?
	{
		row.delete(db).await?;
		summary.expired_wallet_challenges += 1;
	}

	for mut row in EvidenceUploadReservationRow::query()
		.filter(|r| r.expires_at.lt(now))
		.limit(200)
		.all(db)
		.await?
	{
		if row.confirmed_at.is_none() {
			row.delete(db).await?;
			summary.expired_upload_reservations += 1;
		}
	}

	for mut row in AppAttestChallengeRow::query()
		.filter(|r| r.expires_at.lt(now))
		.limit(200)
		.all(db)
		.await?
	{
		if row.consumed_at.is_none() {
			row.delete(db).await?;
			summary.expired_app_attest_challenges += 1;
		}
	}

	for mut row in VerificationRequestRow::query()
		.filter(|r| r.expires_at.lt(now))
		.limit(200)
		.all(db)
		.await?
	{
		if matches!(row.status.as_str(), "open" | "in_progress") {
			"expired".clone_into(&mut row.status);
			row.save(db).await?;
			summary.expired_verification_requests += 1;
		}
	}

	Ok(summary)
}

/// Processes queued evidence verification jobs:
/// 1. Runs server-side `MediaPipe` local-check replay when configured on the requirement.
/// 2. Falls through to `OpenRouter` media verification (over a version-pinned short-lived URL
///    with daily inference budget metering and zero-prose vote auditing) or manual review.
/// 3. Settles the parent attempt (reserving rewards, stamping verification request receipts,
///    and queuing signed partner webhooks).
#[allow(
	clippy::too_many_lines,
	reason = "end-to-end verification job pipeline (local-check replay, AI council/fallback, settlement)"
)]
pub async fn run_evidence_verification_sweep(
	db: &Db,
	backend: &BackendHandle,
) -> Result<usize, leptoskit_db::DbError> {
	let sys_db = &db.system("verily evidence verification sweep");
	let jobs = EvidenceVerificationJobRow::query()
		.order_by(|r| r.created_at.asc())
		.limit(25)
		.all(sys_db)
		.await?;
	let stale_cutoff = Utc::now() - Duration::minutes(5);
	let mut processed = 0usize;

	for mut job in jobs {
		let runnable = job.status == "queued"
			|| (job.status == "running" && job.updated_at < stale_cutoff && job.attempt_count < 3);
		if !runnable {
			continue;
		}
		"running".clone_into(&mut job.status);
		job.attempt_count += 1;
		job.save(sys_db).await?;

		let Some(evidence) = Evidence::query()
			.filter(|e| e.id.eq(job.evidence_id))
			.first(sys_db)
			.await?
		else {
			"failed".clone_into(&mut job.status);
			job.last_error_code = Some("evidence_missing".to_owned());
			job.save(sys_db).await?;
			continue;
		};

		let Some(mut attempt) = Attempt::query()
			.filter(|a| a.id.eq(evidence.attempt_id))
			.first(sys_db)
			.await?
		else {
			"failed".clone_into(&mut job.status);
			job.last_error_code = Some("attempt_missing".to_owned());
			job.save(sys_db).await?;
			continue;
		};

		let Some(action) = ActionRow::query()
			.filter(|a| a.id.eq(attempt.action_id))
			.first(sys_db)
			.await?
		else {
			"failed".clone_into(&mut job.status);
			job.last_error_code = Some("action_missing".to_owned());
			job.save(sys_db).await?;
			continue;
		};

		let Ok(requirements) = verily_rewards::store::requirements(&action) else {
			"failed".clone_into(&mut job.status);
			job.last_error_code = Some("requirements_invalid".to_owned());
			job.save(sys_db).await?;
			continue;
		};

		let Some(requirement) = requirements
			.into_iter()
			.find(|req| req.id.to_string() == evidence.requirement_key)
		else {
			"failed".clone_into(&mut job.status);
			job.last_error_code = Some("requirement_missing".to_owned());
			job.save(sys_db).await?;
			continue;
		};

		let bound_spoken = SpokenChallengeRow::query()
			.filter(|s| {
				s.attempt_id.eq(attempt.id) & s.requirement_id.eq(evidence.requirement_key.clone())
			})
			.order_by(|s| s.issued_at.desc())
			.all(sys_db)
			.await?
			.into_iter()
			.find(|s| s.bound_at.is_some());

		let mut decided = false;

		// Step 1: Server-side MediaPipe local-check replay over immutable pinned evidence bytes.
		if let Some(local_check) = requirement.local_check.clone()
			&& let (Some(storage_path), Some(version_id)) = (
				evidence.storage_path.as_deref(),
				evidence.storage_version_id.as_deref(),
			)
			&& let Ok((bytes, mime_type)) = backend
				.0
				.evidence_store
				.read_version_bytes(storage_path, version_id)
				.await
		{
			let replayer = backend.0.local_check_replayer.clone();
			let replay = tokio::task::spawn_blocking(move || {
				let temp = TempMediaFile::write(&bytes, &mime_type).ok()?;
				Some(replayer.replay_file(&local_check, temp.path()))
			})
			.await
			.ok()
			.flatten();

			if let Some(outcome) = replay {
				let has_extra_checks = requirement.spoken_challenge_required
					|| requirement
						.verification_prompt
						.as_deref()
						.is_some_and(|p| !p.trim().is_empty());
				match outcome {
					LocalCheckReplayOutcome::NotMatched { reason_code, .. } => {
						NewEvidenceDecision {
							evidence_id: evidence.id,
							status: "rejected".to_owned(),
							verifier_type: "mediapipe-local-check".to_owned(),
							reason_code: reason_code.to_owned(),
							summary: "Proof did not match the required visual or audio check."
								.to_owned(),
							reviewed_by: None,
						}
						.insert(sys_db)
						.await?;
						decided = true;
					}
					LocalCheckReplayOutcome::Matched { reason_code, .. } if !has_extra_checks => {
						NewEvidenceDecision {
							evidence_id: evidence.id,
							status: "accepted".to_owned(),
							verifier_type: "mediapipe-local-check".to_owned(),
							reason_code: reason_code.to_owned(),
							summary: "Proof matched the required check.".to_owned(),
							reviewed_by: None,
						}
						.insert(sys_db)
						.await?;
						decided = true;
					}
					LocalCheckReplayOutcome::Matched { .. }
					| LocalCheckReplayOutcome::Unavailable { .. } => {}
				}
			}
		}

		// Step 2: OpenRouter media assessment (version-pinned URL + budget metering + zero-prose votes)
		// or manual-review fallback.
		if !decided {
			let issued_url = match (
				evidence.storage_path.as_deref(),
				evidence.storage_version_id.as_deref(),
			) {
				(Some(path), Some(version)) => backend
					.0
					.evidence_store
					.presign_get_version(path, version, Utc::now(), 180)
					.ok()
					.and_then(|presigned| IssuedMediaUrl::issue(&presigned.url, version)),
				_ => None,
			};

			let verification = backend.0.verification.clone();
			let timeout = verification.config().timeout;
			let verification_prompt = requirement.verification_prompt.clone();
			let policy = requirement
				.verification_policy
				.unwrap_or(ActionVerificationPolicy::SingleModel);
			let kind = match requirement.kind {
				ActionRequirementKind::Photo => MediaKind::Photo,
				ActionRequirementKind::Audio => MediaKind::Audio,
				_ => MediaKind::Video,
			};
			let mime_type = evidence
				.mime_type
				.clone()
				.unwrap_or_else(|| "application/octet-stream".to_owned());
			let min_duration_seconds = positive_seconds(requirement.min_duration_seconds);
			let max_duration_seconds = positive_seconds(requirement.max_duration_seconds);
			let minimum_confidence = requirement.min_confidence.unwrap_or(0.7);
			let spoken_word = bound_spoken.map(|s| s.word);

			let budget_db = db.clone();
			let rt_handle = tokio::runtime::Handle::current();
			let started = Instant::now();
			let outcome = tokio::task::spawn_blocking(move || {
				let proof = MediaProof {
					verification_prompt: verification_prompt.as_deref(),
					policy,
					kind,
					mime_type: &mime_type,
					duration_seconds: None,
					min_duration_seconds,
					max_duration_seconds,
					minimum_confidence,
					spoken_word: spoken_word.as_deref(),
					media: issued_url.as_ref(),
				};
				let mut provider = ReqwestOpenRouterProvider::new(timeout);
				let mut budget = DbInferenceBudget {
					db: budget_db,
					handle: rt_handle,
					daily_budget_micro_usd: None,
				};
				verification.assess_media_with(&proof, &mut provider, &mut budget)
			})
			.await
			.unwrap_or_else(|_| Outcome::Unreadable {
				code: "worker_join_failed".to_owned(),
			});
			let elapsed_ms = i64::try_from(started.elapsed().as_millis()).unwrap_or(i64::MAX);

			match outcome {
				Outcome::Decided(assessment) => {
					for checked_vote in assessment.votes {
						let verdict_str = match checked_vote.vote.verdict {
							Verdict::Fulfilled => "fulfilled",
							Verdict::NotFulfilled => "not_fulfilled",
							Verdict::Uncertain => "uncertain",
							Verdict::Failed => "failed",
						};
						let prompt_injection_detected =
							checked_vote.vote.error_code.as_deref() == Some(PROMPT_INJECTION);
						NewEvidenceVerificationVoteRow {
							evidence_id: evidence.id,
							model_id: checked_vote.vote.model_id,
							verdict: verdict_str.to_owned(),
							confidence: checked_vote.vote.confidence,
							prompt_injection_detected,
							latency_ms: elapsed_ms,
							error_code: checked_vote.vote.error_code,
						}
						.insert(sys_db)
						.await?;
					}
					let status_str = match assessment.decision.status {
						EvidenceDecisionStatus::Accepted => "accepted",
						EvidenceDecisionStatus::Rejected => "rejected",
						EvidenceDecisionStatus::ManualReview => "manual_review",
					};
					NewEvidenceDecision {
						evidence_id: evidence.id,
						status: status_str.to_owned(),
						verifier_type: assessment.decision.verifier_type.to_owned(),
						reason_code: assessment.decision.reason_code.to_owned(),
						summary: assessment.decision.summary.to_owned(),
						reviewed_by: None,
					}
					.insert(sys_db)
					.await?;
				}
				Outcome::Unreadable { code } => {
					NewEvidenceDecision {
						evidence_id: evidence.id,
						status: "manual_review".to_owned(),
						verifier_type: "manual-review-fallback".to_owned(),
						reason_code: code,
						summary: "A person will check this proof.".to_owned(),
						reviewed_by: None,
					}
					.insert(sys_db)
					.await?;
				}
			}
		}

		// Step 3: Settle the parent attempt (rewards + receipts + partner webhooks).
		if matches!(
			attempt.status.as_str(),
			"collecting_evidence" | "verifying" | "pending_review"
		) {
			let _ = crate::serve::settle(sys_db, &backend.0, &mut attempt).await;
		}

		"completed".clone_into(&mut job.status);
		job.save(sys_db).await?;
		processed += 1;
	}
	Ok(processed)
}

fn positive_seconds(value: Option<i64>) -> Option<u32> {
	u32::try_from(value.unwrap_or(0))
		.ok()
		.filter(|seconds| *seconds > 0)
}

/// Retries reserved/releasing reward payouts via `verily_rewards::store::release_payout`.
pub async fn run_payout_recovery_sweep(
	db: &Db,
	backend: &BackendHandle,
) -> Result<usize, leptoskit_db::DbError> {
	let db = &db.system("verily payout recovery sweep");
	let payouts = RewardPayoutRow::query()
		.order_by(|r| r.created_at.asc())
		.limit(25)
		.all(db)
		.await?;
	let mut touched = 0usize;
	let releasing = serde_json::to_value(RewardPayoutStatus::Releasing)
		.ok()
		.and_then(|v| v.as_str().map(str::to_owned))
		.unwrap_or_else(|| "releasing".to_owned());
	let reserved = serde_json::to_value(RewardPayoutStatus::Reserved)
		.ok()
		.and_then(|v| v.as_str().map(str::to_owned))
		.unwrap_or_else(|| "reserved".to_owned());

	for payout in payouts {
		if payout.status != releasing && payout.status != reserved {
			continue;
		}
		let _ =
			verily_rewards::store::release_payout(db, &backend.0.rewards, payout.id.uuid()).await;
		touched += 1;
	}
	Ok(touched)
}

/// Refreshes expiring Apple App Attest receipts when `apple_device_client` is configured.
pub async fn run_app_attest_receipt_refresh_sweep(
	db: &Db,
	backend: &BackendHandle,
) -> Result<usize, leptoskit_db::DbError> {
	let db = &db.system("verily app attest receipt refresh");
	let Some(client) = &backend.0.apple_device_client else {
		return Ok(0);
	};
	let threshold = Utc::now() + Duration::days(3);
	let keys = AppAttestKeyRow::query().limit(50).all(db).await?;
	let mut refreshed = 0usize;
	for mut key in keys {
		if key.revoked_at.is_some() {
			continue;
		}
		if key.receipt_expires_at.is_some_and(|exp| exp > threshold) {
			continue;
		}
		let Some(receipt_b64) = key.receipt_b64.clone() else {
			continue;
		};
		if let Ok(next_receipt) = client.refresh_receipt(&receipt_b64, Utc::now()).await {
			key.receipt_b64 = Some(next_receipt);
			key.receipt_expires_at = Some(Utc::now() + Duration::days(30));
			key.save(db).await?;
			refreshed += 1;
		}
	}
	Ok(refreshed)
}

/// Delivers pending partner webhooks with exponential backoff and SSRF checks.
pub async fn run_webhook_delivery_sweep(db: &Db) -> Result<usize, leptoskit_db::DbError> {
	let db = &db.system("verily webhook delivery sweep");
	let now = Utc::now();
	let pending = VerilyAppWebhookDeliveryRow::query()
		.filter(|r| r.status.eq("pending") & r.next_attempt_at.lte(now))
		.order_by(|r| r.created_at.asc())
		.limit(25)
		.all(db)
		.await?;
	let mut delivered = 0usize;
	for mut row in pending {
		let Some(app) = VerilyAppRow::query()
			.filter(|a| a.id.eq(row.app_id))
			.first(db)
			.await?
		else {
			"failed".clone_into(&mut row.status);
			row.save(db).await?;
			continue;
		};
		let Some(url) = app.webhook_url.as_deref() else {
			"failed".clone_into(&mut row.status);
			row.save(db).await?;
			continue;
		};
		row.attempts += 1;
		match send_signed_webhook(
			url,
			&app.webhook_secret,
			&row.event_type,
			row.payload_json.as_bytes(),
		)
		.await
		{
			Ok(code) if (200..300).contains(&code) => {
				"delivered".clone_into(&mut row.status);
				row.last_status_code = Some(i64::from(code));
				delivered += 1;
			}
			Ok(code) => {
				row.last_status_code = Some(i64::from(code));
				if row.attempts >= 5 {
					"failed".clone_into(&mut row.status);
				} else {
					let backoff_secs = 30_i64 * (1_i64 << row.attempts.min(5));
					row.next_attempt_at = now + Duration::seconds(backoff_secs);
				}
			}
			Err(_) => {
				if row.attempts >= 5 {
					"failed".clone_into(&mut row.status);
				} else {
					let backoff_secs = 30_i64 * (1_i64 << row.attempts.min(5));
					row.next_attempt_at = now + Duration::seconds(backoff_secs);
				}
			}
		}
		row.save(db).await?;
	}
	Ok(delivered)
}

/// Processes pending external partner pull checks by sending a signed HTTPS POST
/// (`attempt.verify`) to the partner's endpoint, strictly parsing
/// `{"verdict": "accepted" | "rejected" | "pending"}`, recording an evidence
/// decision, and settling the parent attempt.
pub async fn run_pull_check_sweep(
	db: &Db,
	backend: &BackendHandle,
) -> Result<usize, leptoskit_db::DbError> {
	let sys_db = &db.system("verily pull check sweep");
	let pending = VerilyAppPullCheckRow::query()
		.filter(|r| r.status.eq("pending"))
		.limit(25)
		.all(sys_db)
		.await?;
	let mut checked = 0usize;

	for mut row in pending {
		row.attempts += 1;
		let Some(app) = VerilyAppRow::query()
			.filter(|a| a.id.eq(row.app_id))
			.first(sys_db)
			.await?
		else {
			"failed".clone_into(&mut row.status);
			row.save(sys_db).await?;
			checked += 1;
			continue;
		};
		let Some(url) = app.webhook_url.as_deref().filter(|_| app.active) else {
			"failed".clone_into(&mut row.status);
			row.save(sys_db).await?;
			checked += 1;
			continue;
		};
		let Some(mut attempt) = Attempt::query()
			.filter(|a| a.id.eq(row.attempt_id))
			.first(sys_db)
			.await?
		else {
			"failed".clone_into(&mut row.status);
			row.save(sys_db).await?;
			checked += 1;
			continue;
		};
		let link = VerilyAppLinkRow::query()
			.filter(|l| l.app_id.eq(app.id) & l.account_id.eq(attempt.participant_id))
			.first(sys_db)
			.await?;
		let payload = serde_json::json!({
			"attemptId": attempt.id.to_string(),
			"actionId": attempt.action_id.to_string(),
			"requirementId": row.requirement_id,
			"externalUserId": link.map(|l| l.external_user_id),
		});

		match send_signed_pull_check(url, &app.webhook_secret, payload.to_string().as_bytes()).await
		{
			Ok((code, body)) if (200..300).contains(&code) => {
				match parse_pull_check_verdict(&body) {
					Some(PullCheckVerdict::Accepted) => {
						"verified".clone_into(&mut row.status);
						record_pull_check_decision(
							sys_db,
							backend,
							&mut attempt,
							&row.requirement_id,
							EvidenceDecisionStatus::Accepted,
							"partner_verified",
							"Confirmed by partner app.",
						)
						.await?;
					}
					Some(PullCheckVerdict::Rejected) => {
						"rejected".clone_into(&mut row.status);
						record_pull_check_decision(
							sys_db,
							backend,
							&mut attempt,
							&row.requirement_id,
							EvidenceDecisionStatus::Rejected,
							"partner_rejected",
							"Rejected by partner app.",
						)
						.await?;
					}
					Some(PullCheckVerdict::Pending) | None => {
						if row.attempts >= 5 {
							"failed".clone_into(&mut row.status);
						}
					}
				}
			}
			Ok(_) | Err(_) => {
				if row.attempts >= 5 {
					"failed".clone_into(&mut row.status);
				}
			}
		}

		row.save(sys_db).await?;
		checked += 1;
	}
	Ok(checked)
}

async fn record_pull_check_decision(
	sys_db: &impl leptoskit_db::Connection,
	backend: &BackendHandle,
	attempt: &mut Attempt,
	requirement_key: &str,
	decision_status: EvidenceDecisionStatus,
	reason_code: &str,
	summary: &str,
) -> Result<(), leptoskit_db::DbError> {
	let evidence = match Evidence::query()
		.filter(|e| e.attempt_id.eq(attempt.id) & e.requirement_key.eq(requirement_key.to_owned()))
		.first(sys_db)
		.await?
	{
		Some(existing) => existing,
		None => {
			NewEvidence {
				attempt_id: attempt.id,
				requirement_key: requirement_key.to_owned(),
				kind: "external_app".to_owned(),
				storage_path: None,
				storage_version_id: None,
				mime_type: None,
				sha256_digest: None,
				byte_length: None,
				provenance_level: "basic".to_owned(),
				capture_manifest: None,
				capture_signature: None,
				capture_public_key: None,
				capture_key_id: None,
				capture_key_storage: None,
				captured_at: Utc::now(),
			}
			.insert(sys_db)
			.await?
		}
	};
	let _ = crate::serve::record_decision(
		sys_db,
		evidence.id,
		decision_status,
		"partner-pull-check",
		reason_code,
		None,
		summary,
	)
	.await;
	let _ = crate::serve::settle(sys_db, &backend.0, attempt).await;
	Ok(())
}

/// Deletes expired private evidence objects from storage past 7 days (or 30 days
/// when an open appeal holds the attempt), clearing `storage_path` and
/// `storage_version_id` while retaining `sha256_digest`, `EvidenceDecision`, and
/// audit records.
pub async fn run_evidence_retention_sweep(
	db: &Db,
	backend: &BackendHandle,
) -> Result<usize, leptoskit_db::DbError> {
	run_evidence_retention_sweep_at(db, backend, Utc::now()).await
}

/// Deterministic clock variant of [`run_evidence_retention_sweep`].
pub async fn run_evidence_retention_sweep_at(
	db: &Db,
	backend: &BackendHandle,
	now: chrono::DateTime<Utc>,
) -> Result<usize, leptoskit_db::DbError> {
	let sys_db = &db.system("verily evidence retention sweep");
	let standard_cutoff = now - Duration::days(STANDARD_EVIDENCE_RETENTION_DAYS);
	let appeal_cutoff = now - Duration::days(APPEAL_EVIDENCE_RETENTION_DAYS);

	let candidates = Evidence::query()
		.filter(|e| e.submitted_at.lt(standard_cutoff))
		.order_by(|e| e.submitted_at.asc())
		.limit(100)
		.all(sys_db)
		.await?;

	let mut purged = 0usize;
	for mut evidence in candidates {
		let (Some(storage_path), Some(version_id)) = (
			evidence.storage_path.clone(),
			evidence.storage_version_id.clone(),
		) else {
			continue;
		};

		// Never purge raw evidence while its attempt is still collecting or awaiting review.
		let active_attempt = Attempt::query()
			.filter(|a| a.id.eq(evidence.attempt_id))
			.first(sys_db)
			.await?
			.is_some_and(|a| {
				matches!(
					a.status.as_str(),
					"collecting_evidence" | "verifying" | "pending_review"
				)
			});
		if active_attempt {
			continue;
		}

		// Hold evidence for 30 days when an open appeal exists on this attempt.
		let has_open_appeal = Appeal::query()
			.filter(|ap| ap.attempt_id.eq(evidence.attempt_id) & ap.status.eq("open"))
			.exists(sys_db)
			.await?;
		if has_open_appeal && evidence.submitted_at >= appeal_cutoff {
			continue;
		}

		match backend
			.0
			.evidence_store
			.delete_version(&storage_path, &version_id)
			.await
		{
			Ok(()) | Err(StorageError::NotFound) => {
				evidence.storage_path = None;
				evidence.storage_version_id = None;
				evidence.save(sys_db).await?;
				purged += 1;
			}
			Err(_) => {
				// Leave intact to retry on next sweep.
			}
		}
	}

	Ok(purged)
}

/// Recurring maintenance cron registered with `leptoskit_rpc::server::Jobs`.
#[rpc::cron("*/5 * * * *")]
#[rpc::job]
pub async fn verily_maintenance_cron(cx: &rpc::JobCx) -> rpc::Result<()> {
	let db = cx.db().clone();
	let _ = run_cleanup_sweeps(&db).await;
	let _ = run_webhook_delivery_sweep(&db).await;
	if let Some(backend) = cx.state::<BackendHandle>() {
		let _ = run_evidence_verification_sweep(&db, backend).await;
		let _ = run_pull_check_sweep(&db, backend).await;
		let _ = run_payout_recovery_sweep(&db, backend).await;
		let _ = run_app_attest_receipt_refresh_sweep(&db, backend).await;
		let _ = run_evidence_retention_sweep(&db, backend).await;
	}
	Ok(())
}

/// Links `#[rpc::cron]` inventory registrations onto the host process.
pub fn link_jobs() {
	let _ = verily_maintenance_cron;
}

/// Starts the `leptoskit_rpc::server::Jobs` worker with `BackendHandle` state
/// attached so every background cron and job can access verification & rewards.
#[must_use]
pub fn start_worker(db: Db, backend: BackendHandle) -> rpc::server::JobsHandle {
	link_jobs();
	rpc::server::Jobs::new(db).state(backend).start()
}
