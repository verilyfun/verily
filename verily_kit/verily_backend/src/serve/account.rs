//! Payouts, the payout wallet, signing out, and closing the account.

use chrono::Utc;
use leptoskit_auth::Account as AuthAccount;
use leptoskit_auth::Auth;
use leptoskit_auth::EmailAddress;
use leptoskit_auth::Identity as SignInIdentity;
use leptoskit_auth::Passkey;
use leptoskit_auth::Password;
use leptoskit_auth::ProviderToken;
use leptoskit_auth::RecoveryCode;
use leptoskit_auth::RequestInfo;
use leptoskit_auth::TotpSecret;
use leptoskit_auth::Wallet;
use leptoskit_db::Db;
use leptoskit_db::Id;
use leptoskit_rpc as rpc;
use verily_api::PayoutRow;
use verily_api::PayoutStatus;
use verily_api::WalletLink;
use verily_rewards::ops::into_rpc;
use verily_rewards::schema::ActionRow;
use verily_rewards::schema::PayoutWalletRow;
use verily_rewards::schema::WalletLinkChallengeRow;
use verily_shared::ActionDefinitionStatus;
use verily_shared::RewardPayoutStatus;

use super::CLOSE_ACCOUNT_CONFIRMATION;
use super::amount_label;
use super::backend;
use super::db;
use super::me;
use super::name;
use super::signed_in;
use crate::schema::Account;
use crate::schema::AccountClosureRow;
use crate::schema::NewAccountClosureRow;

/// The signed-in person's payouts, newest first. A payout is only ever
/// shown released when `verily_rewards` read the release from chain state.
pub async fn list_my_payouts(cx: &rpc::QueryCx) -> rpc::Result<Vec<PayoutRow>> {
	let account = me(cx.context())?;
	let payouts = verily_rewards::store::list_payouts(cx.db(), account.uuid())
		.await
		.map_err(into_rpc)?;
	Ok(payouts
		.into_iter()
		.map(|payout| PayoutRow {
			id: payout.id.to_string(),
			action_title: payout.action_title,
			amount_label: amount_label(payout.amount, payout.decimals, &payout.token_symbol),
			status: payout_status(payout.status),
		})
		.collect())
}

/// Whether the signed-in person linked a payout wallet. No address.
pub async fn wallet_status(cx: &rpc::QueryCx) -> rpc::Result<WalletLink> {
	let account = me(cx.context())?;
	let linked = PayoutWalletRow::query()
		.filter(|row| row.account_id.eq(account.uuid()))
		.exists(cx.db())
		.await
		.map_err(db)?;
	Ok(WalletLink { linked })
}

/// Ends the session this request came with.
pub async fn sign_out(cx: &rpc::MutationCx) -> rpc::Result<()> {
	let me = signed_in(cx.context())?.clone();
	let auth = auth(cx)?;
	// Sessions live in their own tables, written by `leptoskit_auth`; it ends
	// this one once nothing else in the call can roll back.
	cx.after_commit(async move {
		if let Err(error) = auth.revoke(&me, me.session, &RequestInfo::default()).await {
			tracing::warn!(%error, "a session did not end at sign-out");
		}
	});
	Ok(())
}

/// Closes the signed-in account once the person typed the phrase the screen
/// asked for.
///
/// The payout wallet goes, live actions pause so nobody starts work nobody
/// will answer, and the profile name is cleared. Attempts, proof, and payouts
/// stay for audit. Then sign-in methods are removed and every session ends.
/// Asking again finishes any of that a failure left undone.
pub async fn close_account(cx: &rpc::MutationCx, confirmation: String) -> rpc::Result<()> {
	if confirmation.trim() != CLOSE_ACCOUNT_CONFIRMATION {
		return Err(rpc::Error::invalid("confirmationMismatch"));
	}
	let account = me(cx.context())?;
	let auth = auth(cx)?;
	let system = backend(cx.context())?
		.db
		.clone()
		.ok_or_else(|| rpc::Error::retry("backendUnavailable"))?;

	let closed = AccountClosureRow::query()
		.filter(|row| row.account_id.eq(account))
		.exists(cx.tx())
		.await
		.map_err(db)?;
	if !closed {
		PayoutWalletRow::query()
			.filter(|row| row.account_id.eq(account.uuid()))
			.delete(cx.tx())
			.await
			.map_err(db)?;
		WalletLinkChallengeRow::query()
			.filter(|row| row.account_id.eq(account.uuid()))
			.delete(cx.tx())
			.await
			.map_err(db)?;
		let now = Utc::now();
		let active = name(&ActionDefinitionStatus::Active);
		let live = ActionRow::query()
			.filter(|row| row.creator_id.eq(account.uuid()) & row.status.eq(active))
			.all(cx.tx())
			.await
			.map_err(db)?;
		for mut action in live {
			action.status = name(&ActionDefinitionStatus::Paused);
			action.updated_at = now;
			action.save(cx.tx()).await.map_err(db)?;
		}
		if let Some(mut profile) = Account::query()
			.filter(|row| row.id.eq(account))
			.first(cx.tx())
			.await
			.map_err(db)?
		{
			"Closed account".clone_into(&mut profile.display_name);
			profile.save(cx.tx()).await.map_err(db)?;
		}
		NewAccountClosureRow {
			account_id: account,
		}
		.insert(cx.tx())
		.await
		.map_err(db)?;
	}

	cx.after_commit(async move {
		if let Err(error) = purge_sign_in(&system, account).await {
			tracing::warn!(%error, "sign-in methods were not removed at account closure");
		}
		if let Err(error) = auth.disable(account, &RequestInfo::default()).await {
			tracing::warn!(%error, "an account was not disabled at closure");
		}
	});
	Ok(())
}

/// Removes every way `account` signs in. The account row stays, disabled,
/// so the history that names it stays too.
async fn purge_sign_in(db: &Db, account: Id<AuthAccount>) -> Result<(), leptoskit_db::DbError> {
	let system = db.system("close an account: remove its sign-in methods");
	let tx = system.begin().await?;
	EmailAddress::query()
		.filter(|row| row.account_id.eq(account))
		.delete(&tx)
		.await?;
	SignInIdentity::query()
		.filter(|row| row.account_id.eq(account))
		.delete(&tx)
		.await?;
	Passkey::query()
		.filter(|row| row.account_id.eq(account))
		.delete(&tx)
		.await?;
	Password::query()
		.filter(|row| row.account_id.eq(account))
		.delete(&tx)
		.await?;
	TotpSecret::query()
		.filter(|row| row.account_id.eq(account))
		.delete(&tx)
		.await?;
	RecoveryCode::query()
		.filter(|row| row.account_id.eq(account))
		.delete(&tx)
		.await?;
	ProviderToken::query()
		.filter(|row| row.account_id.eq(account))
		.delete(&tx)
		.await?;
	Wallet::query()
		.filter(|row| row.account_id.eq(account))
		.delete(&tx)
		.await?;
	tx.commit().await
}

fn auth(cx: &rpc::MutationCx) -> Result<Auth, rpc::Error> {
	backend(cx.context())?
		.auth
		.clone()
		.ok_or_else(|| rpc::Error::retry("backendUnavailable"))
}

/// What the Me screen says about a payout. Reserved and releasing are both
/// "on its way": neither is a release.
const fn payout_status(status: RewardPayoutStatus) -> PayoutStatus {
	match status {
		RewardPayoutStatus::Reserved | RewardPayoutStatus::Releasing => PayoutStatus::OnItsWay,
		RewardPayoutStatus::AwaitingWallet => PayoutStatus::AwaitingWallet,
		RewardPayoutStatus::HeldForReview => PayoutStatus::HeldForReview,
		RewardPayoutStatus::Released => PayoutStatus::Released,
		RewardPayoutStatus::Failed => PayoutStatus::Failed,
		RewardPayoutStatus::Expired => PayoutStatus::Expired,
	}
}
