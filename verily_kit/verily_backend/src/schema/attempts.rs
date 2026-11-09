//! Participant attempts against a published action revision.

use leptoskit_auth::Account as AuthAccount;
use leptoskit_auth::AuthContext as _;
use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::policy;
use leptoskit_db::table;
use verily_rewards::schema::ActionRow;

/// One account attempt per action period; retries reuse the same attempt.
#[table(
	name = "attempts",
	public,
	live,
	index(action_id),
	index(participant_id),
	unique(action_id, participant_id, period_key),
	unique(participant_id, idempotency_key),
	on_account_merge = reassign_skip_conflicts
)]
#[policy(select, |attempt, cx| {
	cx.signed_in(|me| attempt.participant_id.eq(me.account))
})]
#[policy(insert, |attempt, cx| {
	cx.signed_in(|me| attempt.participant_id.eq(me.account))
})]
#[policy(update, |attempt, cx| {
	cx.signed_in(|me| attempt.participant_id.eq(me.account))
})]
pub struct Attempt {
	pub id: Id<Attempt>,
	#[db(on_delete = restrict)]
	pub action_id: Id<ActionRow>,
	#[db(on_delete = cascade)]
	pub participant_id: Id<AuthAccount>,
	/// Recurrence bucket key (for example a calendar day in the action TZ).
	#[db(min_len = 1, max_len = 64)]
	pub period_key: String,
	#[db(min_len = 1, max_len = 128)]
	pub idempotency_key: String,
	/// `collecting_evidence`, `verifying`, `pending_review`, `verified`,
	/// `rejected`, or `capacity_reached`.
	#[db(
		one_of(
			"collecting_evidence",
			"verifying",
			"pending_review",
			"verified",
			"rejected",
			"capacity_reached"
		),
		default = "collecting_evidence"
	)]
	pub status: String,
	pub verification_score: Option<f64>,
	pub rejection_code: Option<String>,
	/// Set when a verified attempt met a reward pool: won or why not.
	#[db(max_len = 64)]
	pub reward_outcome: Option<String>,
	#[db(created_at)]
	pub started_at: Timestamp,
	pub submitted_at: Option<Timestamp>,
	pub verified_at: Option<Timestamp>,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}
