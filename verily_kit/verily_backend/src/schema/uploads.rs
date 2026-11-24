//! Media upload reservations, verification jobs/votes, venue QR challenges,
//! Apple App Attest keys/challenges, and `DeviceCheck` audit rows.

use leptoskit_auth::Account as AuthAccount;
use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::table;
use verily_rewards::schema::ActionRow;

use crate::schema::Attempt;
use crate::schema::Evidence;

/// A server-issued presigned upload reservation pinned to an authenticated user
/// and attempt requirement.
#[table(
	name = "evidence_upload_reservations",
	index(attempt_id),
	index(participant_id)
)]
pub struct EvidenceUploadReservationRow {
	pub id: Id<EvidenceUploadReservationRow>,
	#[db(on_delete = cascade)]
	pub attempt_id: Id<Attempt>,
	#[db(on_delete = cascade)]
	pub participant_id: Id<AuthAccount>,
	#[db(min_len = 1, max_len = 64)]
	pub requirement_id: String,
	#[db(private, min_len = 1, max_len = 256)]
	pub object_key: String,
	#[db(min_len = 1, max_len = 64)]
	pub mime_type: String,
	pub max_byte_length: i64,
	pub expires_at: Timestamp,
	pub confirmed_at: Option<Timestamp>,
	#[db(private, max_len = 128)]
	pub version_id: Option<String>,
	#[db(private, max_len = 64)]
	pub sha256_digest: Option<String>,
	pub byte_length: Option<i64>,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Durable background verification job state for one sealed media evidence row.
#[table(
	name = "evidence_verification_jobs",
	unique(evidence_id),
	index(status)
)]
pub struct EvidenceVerificationJobRow {
	pub id: Id<EvidenceVerificationJobRow>,
	#[db(on_delete = cascade)]
	pub evidence_id: Id<Evidence>,
	#[db(on_delete = cascade)]
	pub attempt_id: Id<Attempt>,
	#[db(one_of("queued", "running", "completed", "failed"), default = "queued")]
	pub status: String,
	pub attempt_count: i64,
	pub last_error_code: Option<String>,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}

/// One model vote recorded during media verification (zero prose persisted).
#[table(name = "evidence_verification_votes", index(evidence_id))]
pub struct EvidenceVerificationVoteRow {
	pub id: Id<EvidenceVerificationVoteRow>,
	#[db(on_delete = cascade)]
	pub evidence_id: Id<Evidence>,
	#[db(min_len = 1, max_len = 128)]
	pub model_id: String,
	#[db(one_of("fulfilled", "not_fulfilled", "uncertain", "failed"))]
	pub verdict: String,
	pub confidence: Option<f64>,
	pub prompt_injection_detected: bool,
	pub latency_ms: i64,
	pub error_code: Option<String>,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Short-lived venue QR challenge created by an action's creator and redeemed once.
#[table(name = "action_qr_challenges", unique(code_hash), index(action_id))]
pub struct ActionQrChallengeRow {
	pub id: Id<ActionQrChallengeRow>,
	#[db(on_delete = cascade)]
	pub action_id: Id<ActionRow>,
	#[db(on_delete = cascade)]
	pub creator_id: Id<AuthAccount>,
	#[db(private, min_len = 1, max_len = 64)]
	pub code_hash: String,
	pub expires_at: Timestamp,
	pub consumed_at: Option<Timestamp>,
	pub consumed_by_attempt_id: Option<Id<Attempt>>,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// One-time registration challenge for an iPhone's Apple App Attest key.
#[table(name = "app_attest_challenges", index(account_id))]
pub struct AppAttestChallengeRow {
	pub id: Id<AppAttestChallengeRow>,
	#[db(on_delete = cascade)]
	pub account_id: Id<AuthAccount>,
	#[db(private, min_len = 1, max_len = 128)]
	pub nonce: String,
	pub expires_at: Timestamp,
	pub consumed_at: Option<Timestamp>,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Verified Apple App Attest hardware key owned by one account.
#[table(name = "app_attest_keys", unique(key_id_hash), index(account_id))]
pub struct AppAttestKeyRow {
	pub id: Id<AppAttestKeyRow>,
	#[db(on_delete = cascade)]
	pub account_id: Id<AuthAccount>,
	#[db(private, min_len = 1, max_len = 64)]
	pub key_id_hash: String,
	/// Uncompressed P-256 public key `0x04 || X || Y` in base64.
	#[db(private, min_len = 1, max_len = 128)]
	pub public_key_b64: String,
	/// Monotonic `WebAuthn` assertion counter to prevent assertion replay.
	pub sign_count: i64,
	/// Latest Apple receipt in base64 for background refresh.
	#[db(private)]
	pub receipt_b64: Option<String>,
	pub receipt_expires_at: Option<Timestamp>,
	pub risk_metric: Option<i64>,
	pub revoked_at: Option<Timestamp>,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}

/// Audit log of operator `DeviceCheck` queries and bit mutations.
#[table(name = "device_check_audits", index(operator_id))]
pub struct DeviceCheckAuditRow {
	pub id: Id<DeviceCheckAuditRow>,
	#[db(on_delete = cascade)]
	pub operator_id: Id<AuthAccount>,
	#[db(one_of("query", "update"))]
	pub operation: String,
	pub banned: bool,
	pub review_required: bool,
	#[db(max_len = 500)]
	pub note: String,
	#[db(created_at)]
	pub created_at: Timestamp,
}
