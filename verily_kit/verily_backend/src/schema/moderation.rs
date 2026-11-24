//! Content moderation cases, audit history, abuse risk signals, AI drafting
//! usage rate limits, and inference budget reservations.

use leptoskit_auth::Account as AuthAccount;
use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::table;

use crate::schema::Appeal;

/// Appeal resolution note recorded when a reviewer decides an appeal.
#[table(name = "appeal_resolutions", unique(appeal_id))]
pub struct AppealResolutionRow {
	pub id: Id<AppealResolutionRow>,
	#[db(on_delete = cascade)]
	pub appeal_id: Id<Appeal>,
	pub resolved_by: Id<AuthAccount>,
	#[db(one_of("upheld", "overturned"))]
	pub decision: String,
	#[db(private, max_len = 500)]
	pub note: String,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Moderation report / safety hold case for an action, attempt, or account.
#[table(name = "moderation_cases", index(target_id), index(status))]
pub struct ModerationCaseRow {
	pub id: Id<ModerationCaseRow>,
	pub reporter_id: Id<AuthAccount>,
	#[db(one_of("action", "attempt", "account", "app"))]
	pub target_kind: String,
	#[db(min_len = 1, max_len = 64)]
	pub target_id: String,
	#[db(min_len = 1, max_len = 128)]
	pub reason: String,
	#[db(
		one_of("open", "under_review", "held", "cleared", "removed", "appealed"),
		default = "open"
	)]
	pub status: String,
	#[db(private, max_len = 1000)]
	pub notes: Option<String>,
	pub assigned_moderator_id: Option<Id<AuthAccount>>,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}

/// Append-only audit trail for moderation case transitions.
#[table(name = "moderation_audit_entries", index(case_id))]
pub struct ModerationAuditRow {
	pub id: Id<ModerationAuditRow>,
	#[db(on_delete = cascade)]
	pub case_id: Id<ModerationCaseRow>,
	pub actor_id: Id<AuthAccount>,
	#[db(min_len = 1, max_len = 64)]
	pub action: String,
	#[db(private, max_len = 500)]
	pub note: String,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Pseudonymized abuse risk assessment per account / device key.
#[table(name = "abuse_risk_assessments", index(subject_hash))]
pub struct AbuseRiskRow {
	pub id: Id<AbuseRiskRow>,
	#[db(private, min_len = 1, max_len = 64)]
	pub subject_hash: String,
	#[db(one_of("low", "elevated", "high", "blocked"))]
	pub tier: String,
	#[db(min_len = 1, max_len = 128)]
	pub reason_code: String,
	pub expires_at: Option<Timestamp>,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Hourly/daily AI drafting usage ledger per account.
#[table(name = "ai_usage_requests", index(account_id))]
pub struct AiUsageRow {
	pub id: Id<AiUsageRow>,
	#[db(on_delete = cascade)]
	pub account_id: Id<AuthAccount>,
	#[db(min_len = 1, max_len = 64)]
	pub feature: String,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Per-call inference cost reservation ledger for `OpenRouter` budget caps.
#[table(name = "inference_cost_reservations", index(created_at))]
pub struct InferenceReservationRow {
	pub id: Id<InferenceReservationRow>,
	#[db(min_len = 1, max_len = 128)]
	pub model_id: String,
	/// Estimated micro-USD reserved before sending the model call.
	pub estimated_micro_usd: i64,
	pub settled_micro_usd: Option<i64>,
	#[db(created_at)]
	pub created_at: Timestamp,
}
