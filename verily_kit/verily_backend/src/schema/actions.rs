//! Creator-owned action definitions (proof contracts).

use leptoskit_auth::Account as AuthAccount;
use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::policy;
use leptoskit_db::table;

use leptoskit_auth::AuthContext as _;

/// A versioned, creator-owned proof contract. Published revisions are
/// immutable; historical attempts stay tied to the revision they accepted.
#[table(
	name = "actions",
	public,
	live,
	index(creator_id),
	unique(creator_id, action_key, revision),
	on_account_merge = reassign_skip_conflicts
)]
#[policy(select, |action, cx| {
	action.status.eq("published")
		| cx.signed_in(|me| action.creator_id.eq(me.account))
})]
#[policy(insert, |action, cx| cx.signed_in(|me| action.creator_id.eq(me.account)))]
#[policy(update, |action, cx| {
	cx.signed_in(|me| action.creator_id.eq(me.account) & action.status.ne("published"))
})]
pub struct Action {
	pub id: Id<Action>,
	#[db(on_delete = restrict)]
	pub creator_id: Id<AuthAccount>,
	/// Stable key within a creator's catalogue (not globally unique alone).
	#[db(min_len = 1, max_len = 64, regex = "^[a-z0-9][a-z0-9_-]*$")]
	pub action_key: String,
	#[db(min = 1, default = 1)]
	pub revision: i32,
	#[db(min_len = 1, max_len = 200)]
	pub title: String,
	#[db(max_len = 4000, default = "")]
	pub description: String,
	/// `draft`, `published`, `paused`, or `closed`.
	#[db(one_of("draft", "published", "paused", "closed"), default = "draft")]
	pub status: String,
	/// IANA time zone for recurrence windows.
	#[db(min_len = 1, max_len = 64, default = "UTC")]
	pub time_zone: String,
	/// Public place name only — never precise coordinates on the public row.
	#[db(max_len = 200)]
	pub place_name: Option<String>,
	/// Public geofence radius in metres for the place pin, when set.
	#[db(min = 1)]
	pub place_radius_meters: Option<i32>,
	pub opens_at: Option<Timestamp>,
	pub closes_at: Option<Timestamp>,
	pub published_at: Option<Timestamp>,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}

