//! Escrowed reward pools. Funding is verified from chain state by
//! `verily_rewards`; this host only stores the rows that gateway mounts.

use leptoskit_auth::Account as AuthAccount;
use leptoskit_auth::AuthContext as _;
use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::policy;
use leptoskit_db::table;

/// One escrowed reward pool per creator and action key.
///
/// The row id is the on-chain pool id. Terms freeze once funding starts.
/// Payout indexes are assigned in the DB transaction that verifies an
/// attempt — never re-indexed on a failed release.
#[table(
	name = "rewards",
	public,
	live,
	unique(creator_id, action_key),
	unique(escrow_address),
	index(status),
	on_account_merge = reassign_skip_conflicts
)]
#[policy(select, |reward, cx| {
	reward.status.eq("funded")
		| reward.status.eq("ended")
		| cx.signed_in(|me| reward.creator_id.eq(me.account))
})]
#[policy(insert, |reward, cx| cx.signed_in(|me| reward.creator_id.eq(me.account)))]
#[policy(update, |reward, cx| cx.signed_in(|me| reward.creator_id.eq(me.account)))]
pub struct Reward {
	pub id: Id<Reward>,
	#[db(on_delete = restrict)]
	pub creator_id: Id<AuthAccount>,
	#[db(min_len = 1, max_len = 64, regex = "^[a-z0-9][a-z0-9_-]*$")]
	pub action_key: String,
	/// SPL mint address (base58).
	#[db(min_len = 32, max_len = 64)]
	pub mint: String,
	#[db(min_len = 1, max_len = 16)]
	pub token_symbol: String,
	#[db(min = 0, max = 18)]
	pub decimals: i32,
	/// Token atoms per verified completion.
	#[db(min = 1)]
	pub amount_per_payout: i64,
	#[db(min = 1)]
	pub max_payouts: i32,
	#[db(min = 1, default = 1)]
	pub max_wins_per_account: i32,
	#[db(min = 0, default = 0)]
	pub payouts_reserved: i32,
	#[db(min = 0, default = 0)]
	pub payouts_released: i32,
	/// Creator wallet frozen when funding starts.
	#[db(private, max_len = 64)]
	pub creator_wallet: Option<String>,
	#[db(max_len = 64)]
	pub escrow_address: Option<String>,
	#[db(private, max_len = 64)]
	pub arbiter_address: Option<String>,
	pub expires_at: Timestamp,
	#[db(min = 0)]
	pub refund_delay_seconds: i64,
	pub refund_after: Timestamp,
	/// `draft`, `awaiting_funding`, `funded`, `ended`, or `closed`.
	#[db(
		one_of("draft", "awaiting_funding", "funded", "ended", "closed"),
		default = "draft"
	)]
	pub status: String,
	#[db(private, max_len = 128)]
	pub funding_signature: Option<String>,
	pub funded_at: Option<Timestamp>,
	pub ended_at: Option<Timestamp>,
	pub closed_at: Option<Timestamp>,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}


