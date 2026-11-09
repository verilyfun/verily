//! Reward and action tables.
//!
//! Server code writes these rows. They are not a public client schema.
//! Audited pool and payout updates take the row lock, which is where a
//! payout index is assigned.

use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::table;
use uuid::Uuid;

/// One action revision owned by an account.
#[table(
	name = "actions",
	audit,
	unique(creator_id, action_key),
	index(creator_id)
)]
pub struct ActionRow {
	/// Row id.
	pub id: Id<ActionRow>,
	/// Account that created the action.
	pub creator_id: Uuid,
	/// Creator-chosen key, unique per account.
	#[db(max_len = 80)]
	pub action_key: String,
	/// Revision the client must send back.
	pub revision: i64,
	/// `draft`, `active`, `paused`, or `completed`.
	#[db(max_len = 32)]
	pub status: String,
	/// Title.
	#[db(max_len = 160)]
	pub title: String,
	/// Description.
	#[db(max_len = 4000)]
	pub description: String,
	/// `once` or `daily`.
	#[db(max_len = 16)]
	pub recurrence: String,
	/// IANA time zone.
	#[db(max_len = 80)]
	pub time_zone: String,
	/// Optional cap on verified completions.
	pub max_verified_completions: Option<i64>,
	/// Verified completions so far.
	pub verified_completions: i64,
	/// When the action opens.
	pub opens_at: Option<Timestamp>,
	/// When the action closes.
	pub closes_at: Option<Timestamp>,
	/// When it was published.
	pub published_at: Option<Timestamp>,
	/// Name shown on the action.
	#[db(max_len = 80)]
	pub creator_display_name: String,
	/// Requirement drafts as JSON.
	#[db(max_len = 32000)]
	pub requirements_json: String,
	/// When the row was created.
	pub created_at: Timestamp,
	/// When the row was last saved.
	pub updated_at: Timestamp,
}

/// One action's reward pool.
#[table(name = "reward_pools", audit, unique(action_id), index(creator_id))]
pub struct RewardPoolRow {
	/// Row id.
	pub id: Id<RewardPoolRow>,
	/// The action this pool pays for.
	#[db(on_delete = cascade)]
	pub action_id: Id<ActionRow>,
	/// Account that created the pool.
	pub creator_id: Uuid,
	/// UUID whose 16 bytes are the on-chain pool id.
	pub chain_pool_id: Uuid,
	/// Pool status name.
	#[db(max_len = 32)]
	pub status: String,
	/// `devnet` or `mainnet`.
	#[db(max_len = 16)]
	pub cluster: String,
	/// Mint address.
	#[db(max_len = 64)]
	pub mint: String,
	/// Token symbol.
	#[db(max_len = 16)]
	pub token_symbol: String,
	/// Token decimals.
	pub decimals: i64,
	/// Atoms per payout.
	pub amount_per_payout: i64,
	/// Funded payout count.
	pub max_payouts: i64,
	/// Wins one account may take.
	pub max_wins_per_account: i64,
	/// Indexes assigned so far.
	pub payouts_reserved: i64,
	/// Indexes settled from the bitmap.
	pub payouts_released: i64,
	/// When new completions stop.
	pub expires_at: Timestamp,
	/// When the refund window opens.
	pub refund_after: Timestamp,
	/// Refund delay in days.
	pub refund_delay_days: i64,
	/// Creator wallet, once funding is prepared.
	#[db(max_len = 64)]
	pub creator_wallet: Option<String>,
	/// Derived escrow address.
	#[db(max_len = 64)]
	pub escrow_address: Option<String>,
	/// Audit signature stored after the chain read matches.
	#[db(max_len = 128)]
	pub funding_signature: Option<String>,
	/// When the chain read matched.
	pub funded_at: Option<Timestamp>,
	/// Arbiter address.
	#[db(max_len = 64)]
	pub arbiter_address: String,
	/// When the row was created.
	pub created_at: Timestamp,
	/// When the row was last saved.
	pub updated_at: Timestamp,
}

/// One payout reserved for one attempt.
#[table(
	name = "reward_payouts",
	audit,
	unique(pool_id, payout_index),
	unique(attempt_id),
	index(account_id)
)]
pub struct RewardPayoutRow {
	/// Row id.
	pub id: Id<RewardPayoutRow>,
	/// Pool the index belongs to.
	#[db(on_delete = cascade)]
	pub pool_id: Id<RewardPoolRow>,
	/// Attempt this payout was reserved for. Unique.
	pub attempt_id: Uuid,
	/// Account that completed the attempt.
	pub account_id: Uuid,
	/// Index assigned under the pool row lock.
	pub payout_index: i64,
	/// Atoms.
	pub amount: i64,
	/// Payout status name.
	#[db(max_len = 32)]
	pub status: String,
	/// Action title copied at reserve time.
	#[db(max_len = 160)]
	pub action_title: String,
	/// Wallet the payout would be sent to.
	#[db(max_len = 64)]
	pub recipient_wallet: Option<String>,
	/// Signature of a confirmed release. Never a `local-dev-` prefix.
	#[db(max_len = 128)]
	pub release_signature: Option<String>,
	/// When a different person accepted the review.
	pub person_accepted_at: Option<Timestamp>,
	/// Account that accepted the review.
	pub person_accepted_by: Option<Uuid>,
	/// Last time a release may be sent.
	pub payable_until: Timestamp,
	/// When the row was created.
	pub created_at: Timestamp,
	/// When the row was last saved.
	pub updated_at: Timestamp,
}

/// The wallet an account is paid to.
#[table(name = "payout_wallets", audit, unique(account_id))]
pub struct PayoutWalletRow {
	/// Row id.
	pub id: Id<PayoutWalletRow>,
	/// Account.
	pub account_id: Uuid,
	/// Wallet address.
	#[db(max_len = 64)]
	pub wallet_address: String,
	/// Label.
	#[db(max_len = 80)]
	pub label: String,
	/// When the signature was verified.
	pub linked_at: Timestamp,
}

/// A wallet-link challenge. Signing it does not move funds.
#[table(name = "wallet_link_challenges", index(account_id))]
pub struct WalletLinkChallengeRow {
	/// Row id.
	pub id: Id<WalletLinkChallengeRow>,
	/// Account the challenge was issued to.
	pub account_id: Uuid,
	/// Address the signature must come from.
	#[db(max_len = 64)]
	pub wallet_address: String,
	/// Single-use nonce.
	#[db(max_len = 80)]
	pub nonce: String,
	/// Exact bytes the wallet signs.
	#[db(max_len = 400)]
	pub message: String,
	/// When the challenge stops being acceptable.
	pub expires_at: Timestamp,
	/// When the challenge was issued.
	pub created_at: Timestamp,
}
