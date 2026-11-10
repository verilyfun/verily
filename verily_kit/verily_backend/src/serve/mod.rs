//! The operations `verily_app` declares with `service = "verily-backend"`.
//!
//! `verily_app::ops` keeps each operation's name and argument struct; with its
//! `service` feature on, the body of each one is a single call into this
//! module, which owns the rules. The host serves them under
//! [`leptoskit_rpc::service_prefix`]`(`[`SERVICE`]`)`, so the browser reaches
//! them on the app's own origin.
//!
//! Every operation needs a signed-in person. The caller is only ever the
//! signed-in identity: attempts, drafts, windows, and appeals are read
//! through it, so someone else's row is not found. Reviewers see proof a
//! person still has to decide, never their own. Domain rules come from
//! `verily_verification` and `verily_rewards`; this module stores what they
//! decide.

// Each operation fails with an `rpc::Error` whose message is a stable code
// the screens translate; the code is named where the failure is decided.
#![allow(
	clippy::missing_errors_doc,
	reason = "every operation fails with an rpc::Error carrying a stable code"
)]

mod account;
mod attempts;
pub(crate) mod catalogue;
mod review;

use std::sync::Arc;

use leptoskit_auth::Account as AuthAccount;
use leptoskit_auth::Auth;
use leptoskit_auth::SignedIn;
use leptoskit_db::Context;
use leptoskit_db::Db;
use leptoskit_db::DbError;
use leptoskit_db::Id;
use leptoskit_db::Read;
use leptoskit_rpc as rpc;
use uuid::Uuid;
use verily_api::ProofKind;
use verily_rewards::Rewards;
use verily_rewards::schema::ActionRow;
use verily_shared::ActionRequirementKind;
use verily_shared::ActionRequirementView;

pub use account::close_account;
pub use account::create_wallet_link_challenge;
pub use account::link_payout_wallet;
pub use account::list_my_payouts;
pub use account::sign_out;
pub use account::wallet_status;
pub use attempts::begin_attempt;
pub use attempts::begin_capture;
pub use attempts::complete_attempt;
pub use attempts::issue_spoken_challenge;
pub use attempts::list_my_attempts;
pub use attempts::submit_attestation;
pub use attempts::submit_live_proof;
pub use catalogue::get_action;
pub use catalogue::list_available_actions;
pub use catalogue::list_my_actions;
pub use catalogue::publish_action;
pub use catalogue::save_action;
pub use review::grant_reviewer;
pub use review::list_review_queue;
pub use review::review_attempt;
pub use review::submit_appeal;

use crate::MountedVerification;
use crate::schema::AccountClosureRow;

/// The service name the app's operations are declared with.
pub const SERVICE: &str = "verily-backend";

/// What `close_account` asks the person to type. The screen's copy names it.
pub const CLOSE_ACCOUNT_CONFIRMATION: &str = "DELETE";

/// What the operations reach besides the database. The host puts one on
/// every caller's context.
pub struct Backend {
	/// Funding checks from chain state, payout reservation.
	pub rewards: Arc<Rewards>,
	/// Capture windows, spoken words, media decisions.
	pub verification: Arc<MountedVerification>,
	/// Sessions, for signing out and closing an account. `None` refuses both.
	pub auth: Option<Auth>,
	/// The host's database, for the work `leptoskit_auth` owns once a
	/// closure has committed. `None` refuses closing an account.
	pub db: Option<Db>,
}

/// [`Backend`] on a caller's context.
#[derive(Clone)]
pub struct BackendHandle(pub Arc<Backend>);

impl BackendHandle {
	/// Shares `backend` with every request.
	#[must_use]
	pub fn new(backend: Backend) -> Self {
		Self(Arc::new(backend))
	}
}

fn backend(context: &Context) -> Result<&Backend, rpc::Error> {
	context
		.get::<BackendHandle>()
		.map(|handle| handle.0.as_ref())
		.ok_or_else(|| rpc::Error::retry("backendUnavailable"))
}

fn signed_in(context: &Context) -> Result<&SignedIn, rpc::Error> {
	context
		.get::<SignedIn>()
		.ok_or_else(|| rpc::Error::unauthorized("sign in"))
}

fn me(context: &Context) -> Result<Id<AuthAccount>, rpc::Error> {
	signed_in(context).map(|me| me.account)
}

/// A closed account starts nothing new.
async fn require_active(
	connection: &impl Read,
	account: Id<AuthAccount>,
) -> Result<(), rpc::Error> {
	let closed = AccountClosureRow::query()
		.filter(|row| row.account_id.eq(account))
		.exists(connection)
		.await
		.map_err(db)?;
	if closed {
		return Err(rpc::Error::forbidden("accountClosed"));
	}
	Ok(())
}

/// A database failure as the caller hears it. Contention stays contention,
/// so the mutation runs again.
fn db(error: DbError) -> rpc::Error {
	if error.is_contended() {
		return rpc::Error::from(error);
	}
	match error {
		DbError::NotFound { .. } => rpc::Error::not_found("notFound"),
		DbError::Forbidden { .. } => rpc::Error::forbidden("forbidden"),
		DbError::Conflict { .. } | DbError::Stale { .. } => rpc::Error::conflict("conflict"),
		DbError::Invalid(_) | DbError::Check { .. } | DbError::ForeignKey { .. } => {
			rpc::Error::invalid("invalidRequest")
		}
		other => rpc::Error::from(other),
	}
}

fn parse_id(value: &str) -> Result<Uuid, rpc::Error> {
	value
		.trim()
		.parse()
		.map_err(|_| rpc::Error::invalid("invalidRequest"))
}

/// The action's requirements, as `verily_rewards` stored them.
fn requirements(action: &ActionRow) -> Result<Vec<ActionRequirementView>, rpc::Error> {
	verily_rewards::store::requirements(action).map_err(verily_rewards::ops::into_rpc)
}

/// What the screens call a requirement kind.
pub(crate) fn proof_kind(kind: ActionRequirementKind) -> ProofKind {
	match kind {
		ActionRequirementKind::Video => ProofKind::Video,
		ActionRequirementKind::Photo => ProofKind::Photo,
		ActionRequirementKind::Audio => ProofKind::Audio,
		ActionRequirementKind::Location => ProofKind::Presence,
		ActionRequirementKind::QrCode => ProofKind::VenueCode,
		ActionRequirementKind::Motion => ProofKind::Movement,
		ActionRequirementKind::ExternalApp => ProofKind::App,
	}
}

/// The JSON name of a serde enum value, the way the tables store it.
fn name<T: serde::Serialize>(value: &T) -> String {
	serde_json::to_value(value)
		.ok()
		.and_then(|value| value.as_str().map(str::to_owned))
		.unwrap_or_default()
}

/// `atoms` of a token with `decimals` places, as people read it: `2.5 USDC`.
fn amount_label(atoms: i64, decimals: i64, symbol: &str) -> String {
	let decimals = u32::try_from(decimals.clamp(0, 18)).unwrap_or(0);
	let scale = 10_i128.pow(decimals);
	let atoms = i128::from(atoms);
	let whole = atoms / scale;
	let fraction = (atoms % scale).abs();
	if fraction == 0 {
		return format!("{whole} {symbol}");
	}
	let digits = format!("{fraction:0width$}", width = decimals as usize);
	format!("{whole}.{} {symbol}", digits.trim_end_matches('0'))
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn amounts_read_like_money_without_trailing_zeros() {
		assert_eq!(amount_label(2_000_000, 6, "USDC"), "2 USDC");
		assert_eq!(amount_label(2_500_000, 6, "USDC"), "2.5 USDC");
		assert_eq!(amount_label(1, 6, "USDC"), "0.000001 USDC");
	}

	#[test]
	fn every_requirement_kind_has_a_screen_kind() {
		assert_eq!(
			proof_kind(ActionRequirementKind::Location),
			ProofKind::Presence
		);
		assert_eq!(
			proof_kind(ActionRequirementKind::QrCode),
			ProofKind::VenueCode
		);
		assert_eq!(
			proof_kind(ActionRequirementKind::Motion),
			ProofKind::Movement
		);
		assert_eq!(
			proof_kind(ActionRequirementKind::ExternalApp),
			ProofKind::App
		);
	}
}
