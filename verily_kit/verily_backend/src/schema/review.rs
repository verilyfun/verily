//! People deciding proof: Verily's reviewers, every decision on a piece of
//! evidence, and a participant's one appeal.
//!
//! A decision row is appended, never edited, so the latest one is the
//! evidence's state and the earlier ones are its history. A model verdict is
//! one such row and never releases a reward by itself.

use leptoskit_auth::Account as AuthAccount;
use leptoskit_auth::AuthContext as _;
use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::policy;
use leptoskit_db::table;

use crate::schema::Attempt;
use crate::schema::Evidence;

/// An account Verily lets decide proof that was sent to a person. Server
/// code grants it; no operation does, and a merge never carries it over.
#[table(name = "reviewers", unique(account_id), on_account_merge = keep_survivor)]
pub struct Reviewer {
	pub id: Id<Reviewer>,
	#[db(on_delete = cascade)]
	pub account_id: Id<AuthAccount>,
	#[db(created_at)]
	pub granted_at: Timestamp,
}

/// One decision on one piece of evidence: a verifier's, or a person's.
#[table(name = "evidence_decisions", index(evidence_id))]
pub struct EvidenceDecision {
	pub id: Id<EvidenceDecision>,
	#[db(on_delete = cascade)]
	pub evidence_id: Id<Evidence>,
	/// `accepted`, `rejected`, or `manual_review`.
	#[db(one_of("accepted", "rejected", "manual_review"))]
	pub status: String,
	/// What decided: `manual-review-fallback`, `human-review`, a model council.
	#[db(min_len = 1, max_len = 64)]
	pub verifier_type: String,
	/// Server-owned reason key. Never model prose.
	#[db(min_len = 1, max_len = 64)]
	pub reason_code: String,
	/// The reviewer's note, or the server's fixed summary.
	#[db(private, max_len = 500)]
	pub summary: String,
	/// The person who decided, for a person's decision.
	pub reviewed_by: Option<Id<AuthAccount>>,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// A participant's request for another look at a rejected attempt. One per
/// attempt.
#[table(name = "appeals", unique(attempt_id), index(participant_id))]
#[policy(select, insert, |appeal, cx| {
	cx.signed_in(|me| appeal.participant_id.eq(me.account))
})]
pub struct Appeal {
	pub id: Id<Appeal>,
	#[db(on_delete = cascade)]
	pub attempt_id: Id<Attempt>,
	#[db(on_delete = cascade)]
	pub participant_id: Id<AuthAccount>,
	#[db(private, min_len = 1, max_len = 1000)]
	pub reason: String,
	/// `open` until a person answers it.
	#[db(one_of("open", "upheld", "overturned"), default = "open")]
	pub status: String,
	#[db(created_at)]
	pub created_at: Timestamp,
}
