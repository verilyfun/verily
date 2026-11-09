//! Verily account profiles, keyed by `leptoskit_auth::Account`.

use leptoskit_auth::Account as AuthAccount;
use leptoskit_auth::AuthContext as _;
use leptoskit_auth::OnSignUp;
use leptoskit_auth::Profile;
use leptoskit_auth::Result as AuthResult;
use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::Tx;
use leptoskit_db::policy;
use leptoskit_db::table;

/// Someone on Verily. Shares its primary key with `auth.accounts`, so deleting
/// the signed-in account removes this profile.
#[table(name = "accounts", public, live, on_account_merge = keep_survivor)]
#[policy(select, |account, cx| cx.signed_in(|me| account.id.eq(me.account)))]
#[policy(update, |account, cx| cx.signed_in(|me| account.id.eq(me.account)))]
pub struct Account {
	#[db(on_delete = cascade)]
	pub id: Id<AuthAccount>,
	/// Display name shown on public action and attempt surfaces.
	#[db(min_len = 1, max_len = 100)]
	pub display_name: String,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}

impl OnSignUp for Account {
	async fn on_sign_up(tx: &Tx, account: Id<AuthAccount>, profile: &Profile) -> AuthResult<()> {
		let display_name = profile
			.name
			.clone()
			.filter(|name| !name.trim().is_empty())
			.unwrap_or_else(|| "Verily member".into());
		NewAccount {
			id: account,
			display_name,
		}
		.insert(tx)
		.await?;
		Ok(())
	}
}

// Keep AuthContext linked so policy expansions resolve in this module.
