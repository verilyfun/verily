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
mod apps;
mod attempts;
mod attest;
pub(crate) mod catalogue;
mod moderation;
mod review;
mod rewards_ops;
mod templates;

use std::collections::HashMap;
use std::path::PathBuf;
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
use verily_verification::app_attest::AppAttestEnvironment;
use verily_verification::app_attest::AppAttestPolicy;
use verily_verification::app_attest::AppAttestVerifier;
use verily_verification::app_attest::HttpAppleDeviceClient;
use verily_verification::app_attest::VERILY_IOS_BUNDLE_ID;
use verily_verification::key_attestation::AndroidKeyAttestationVerifier;
use verily_verification::key_attestation::GoogleAttestationStatusSource;
use verily_verification::key_attestation::KeyAttestationPolicy;
use verily_verification::local_check::MediaPipeLocalCheckReplayer;
use verily_verification::openrouter_http::ActionDraftGenerator;
use verily_verification::play_integrity::GooglePlayIntegrityVerifier;
use verily_verification::storage::EvidenceStore;
use verily_verification::storage::StorageConfig;
use verily_verification::storage::StorageError;

pub use account::close_account;
pub use account::create_wallet_link_challenge;
pub use account::link_payout_wallet;
pub use account::list_my_payouts;
pub use account::sign_out;
pub use account::wallet_status;
pub use apps::add_app_redirect_uri;
pub use apps::approve_app_link;
pub use apps::cancel_verification_request;
pub use apps::create_app;
pub use apps::get_verification_request;
pub use apps::list_app_deliveries;
pub use apps::list_my_apps;
pub use apps::revoke_app_key;
pub use apps::revoke_app_link;
pub use apps::rotate_app_key;
pub use apps::start_verification_request;
pub use apps::update_app;
pub use attempts::begin_attempt;
pub use attempts::begin_capture;
pub use attempts::complete_attempt;
pub use attempts::issue_spoken_challenge;
pub use attempts::list_my_attempts;
pub(crate) use attempts::notify_attempt_outcome;
pub(crate) use attempts::record_decision;
pub(crate) use attempts::settle;
pub use attempts::submit_attestation;
pub use attempts::submit_device_attestation;
pub use attempts::submit_live_proof;
pub use attempts::submit_location_proof;
pub use attempts::submit_media_proof;
pub use attempts::submit_motion_proof;
pub use attempts::submit_qr_proof;
pub use attest::begin_app_attest_registration;
pub use attest::confirm_media_upload;
pub use attest::create_qr_challenge;
pub use attest::query_device_check;
pub use attest::register_app_attest_key;
pub use attest::request_media_upload;
pub use attest::update_device_check;
pub use catalogue::get_action;
pub use catalogue::get_draft;
pub use catalogue::list_available_actions;
pub use catalogue::list_my_actions;
pub use catalogue::pause_action;
pub use catalogue::publish_action;
pub use catalogue::save_action;
pub use moderation::appeal_moderation;
pub use moderation::is_action_safety_held;
pub use moderation::is_subject_blocked;
pub use moderation::list_moderation_queue;
pub use moderation::list_my_appeals;
pub use moderation::list_my_moderation_cases;
pub use moderation::list_review_appeals;
pub use moderation::pseudonymize_subject;
pub use moderation::record_abuse_risk;
pub use moderation::report_content;
pub use moderation::reserve_inference_call;
pub use moderation::resolve_appeal;
pub use moderation::review_moderation_case;
pub use review::grant_reviewer;
pub use review::list_review_queue;
pub use review::review_attempt;
pub use review::submit_appeal;
pub use rewards_ops::confirm_reward_funding;
pub use rewards_ops::end_reward_early;
pub use rewards_ops::get_reward_pool;
pub use rewards_ops::prepare_reward_funding;
pub use templates::draft_action_from_prompt;
pub use templates::list_templates;

use crate::MountedVerification;
use crate::partner_http::ReceiptSigner;
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
	/// Immutable private evidence storage (local dev store or Backblaze B2).
	pub evidence_store: Arc<EvidenceStore>,
	/// Server-side `MediaPipe` replayer for gesture/object/sound local checks.
	pub local_check_replayer: Arc<MediaPipeLocalCheckReplayer>,
	/// Apple App Attest verifier (pinned to Apple App Attestation Root CA).
	pub app_attest: Option<Arc<AppAttestVerifier>>,
	/// Apple `DeviceCheck` & App Attest receipt refresh HTTP client.
	pub apple_device_client: Option<Arc<HttpAppleDeviceClient>>,
	/// Google Play Integrity HTTP verifier.
	pub play_integrity: Option<Arc<GooglePlayIntegrityVerifier>>,
	/// Android Hardware Key Attestation verifier (pinned to Google roots).
	pub android_attestation: Option<Arc<AndroidKeyAttestationVerifier>>,
	/// `OpenRouter` plain-language action draft generator (optional, zero tools).
	pub draft_generator: Arc<ActionDraftGenerator>,
	/// Ed25519 JWS signer for partner verification receipts (`/.well-known/jwks.json`).
	/// `None` in production when `VERILY_RECEIPT_SIGNING_PRIVATE_KEY` is unset (never signs with dev keys).
	pub receipt_signer: Option<Arc<ReceiptSigner>>,
	/// HMAC salt for pseudonymizing accounts/devices in abuse-risk rows.
	pub abuse_salt: Vec<u8>,
}

impl Backend {
	/// Builds a [`Backend`] from the current process environment in development
	/// mode (falls back to local storage and dev receipt signer when unset).
	#[must_use]
	pub fn from_env(
		rewards: Arc<Rewards>,
		verification: Arc<MountedVerification>,
		auth: Option<Auth>,
		db: Option<Db>,
	) -> Self {
		let env_map: HashMap<String, String> = std::env::vars().collect();
		Self::from_env_map(
			rewards.clone(),
			verification.clone(),
			auth.clone(),
			db.clone(),
			&env_map,
			false,
		)
		.unwrap_or_else(|_| Self::for_test(rewards, verification, auth, db))
	}

	/// Builds a [`Backend`] from the current process environment, failing closed
	/// in production (`is_production = true`) if Backblaze B2 storage is missing
	/// or misconfigured, and never falling back to a hardcoded dev receipt key.
	pub fn from_env_checked(
		rewards: Arc<Rewards>,
		verification: Arc<MountedVerification>,
		auth: Option<Auth>,
		db: Option<Db>,
		is_production: bool,
	) -> Result<Self, StorageError> {
		let env_map: HashMap<String, String> = std::env::vars().collect();
		Self::from_env_map(rewards, verification, auth, db, &env_map, is_production)
	}

	/// Deterministic environment builder used by startup and tests.
	#[allow(
		clippy::too_many_lines,
		reason = "initializes every optional platform verifier and storage client from env"
	)]
	pub fn from_env_map(
		rewards: Arc<Rewards>,
		verification: Arc<MountedVerification>,
		auth: Option<Auth>,
		db: Option<Db>,
		env_map: &HashMap<String, String>,
		is_production: bool,
	) -> Result<Self, StorageError> {
		let pairs: Vec<(&str, &str)> = env_map
			.iter()
			.map(|(k, v)| (k.as_str(), v.as_str()))
			.collect();
		let default_dir = std::env::temp_dir().join("verily-evidence");
		let storage_cfg = StorageConfig::from_env(pairs, default_dir)?;
		if is_production && matches!(storage_cfg, StorageConfig::Local { .. }) {
			return Err(StorageError::Config(
				"local evidence storage cannot be used in production",
			));
		}
		let evidence_store = Arc::new(EvidenceStore::from_config(storage_cfg));

		let model_cache_dir = env_map
			.get("VERILY_LOCAL_CHECK_MODEL_CACHE")
			.map(|s| s.trim())
			.filter(|s| !s.is_empty())
			.map_or_else(|| PathBuf::from("/app/local-check-models"), PathBuf::from);
		let local_check_replayer = Arc::new(MediaPipeLocalCheckReplayer::new(model_cache_dir));

		let app_attest_policy = env_map
			.get("VERILY_APPLE_TEAM_ID")
			.map(|s| s.trim())
			.filter(|s| !s.is_empty())
			.map(|team_id| {
				let bundle = env_map
					.get("VERILY_IOS_BUNDLE_ID")
					.map(|s| s.trim())
					.filter(|s| !s.is_empty())
					.unwrap_or(VERILY_IOS_BUNDLE_ID);
				let env_mode = match env_map
					.get("VERILY_APPLE_APP_ATTEST_ENV")
					.map(|s| s.trim().to_ascii_lowercase())
					.as_deref()
				{
					Some("development" | "dev" | "sandbox") => AppAttestEnvironment::Development,
					_ => AppAttestEnvironment::Production,
				};
				AppAttestPolicy::with_environment(team_id, bundle, env_mode)
			});

		let app_attest = app_attest_policy
			.clone()
			.map(|policy| Arc::new(AppAttestVerifier::new(policy)));

		let apple_device_client = app_attest_policy.and_then(|policy| {
			let key_id = env_map
				.get("VERILY_APPLE_DEVICECHECK_KEY_ID")
				.map(|s| s.trim())
				.filter(|s| !s.is_empty())?;
			let pem = env_map
				.get("VERILY_APPLE_DEVICECHECK_PRIVATE_KEY")
				.map(|s| s.trim().to_owned())
				.filter(|s| !s.is_empty());
			Some(Arc::new(HttpAppleDeviceClient::new(policy, key_id, pem)))
		});

		let android_policy = KeyAttestationPolicy::from_env(env_map).ok();
		let android_attestation = android_policy
			.as_ref()
			.filter(|p| !p.signing_certificate_digests.is_empty())
			.map(|policy| {
				Arc::new(AndroidKeyAttestationVerifier::new(
					policy.clone(),
					Arc::new(GoogleAttestationStatusSource::new()),
				))
			});

		let play_integrity = env_map
			.get("VERILY_GOOGLE_PLAY_INTEGRITY_SERVICE_ACCOUNT_JSON")
			.map(|s| s.trim().to_owned())
			.filter(|s| !s.is_empty())
			.map(|sa_json| {
				let digests = android_policy
					.as_ref()
					.map(|p| p.signing_certificate_digests.clone())
					.unwrap_or_default();
				Arc::new(GooglePlayIntegrityVerifier::new(Some(sa_json), digests))
			});

		let openrouter_key = env_map
			.get("VERILY_OPENROUTER_API_KEY")
			.map(|s| s.trim().to_owned())
			.filter(|s| !s.is_empty());
		let draft_generator = Arc::new(ActionDraftGenerator::new(openrouter_key));

		let receipt_signer = ReceiptSigner::from_env_map(env_map)
			.or_else(|| (!is_production).then(ReceiptSigner::development))
			.map(Arc::new);

		let abuse_salt = env_map
			.get("VERILY_ABUSE_RISK_SALT")
			.filter(|s| !s.trim().is_empty())
			.map_or_else(
				|| b"verily-dev-abuse-salt".to_vec(),
				|s| s.as_bytes().to_vec(),
			);

		Ok(Self {
			rewards,
			verification,
			auth,
			db,
			evidence_store,
			local_check_replayer,
			app_attest,
			apple_device_client,
			play_integrity,
			android_attestation,
			draft_generator,
			receipt_signer,
			abuse_salt,
		})
	}

	/// Builds an isolated [`Backend`] for in-memory tests using a unique temporary
	/// local evidence directory and deterministic test keys.
	#[must_use]
	pub fn for_test(
		rewards: Arc<Rewards>,
		verification: Arc<MountedVerification>,
		auth: Option<Auth>,
		db: Option<Db>,
	) -> Self {
		let dir: PathBuf = std::env::temp_dir().join(format!("verily-test-{}", Uuid::new_v4()));
		let model_dir: PathBuf =
			std::env::temp_dir().join(format!("verily-models-{}", Uuid::new_v4()));
		let evidence_store = Arc::new(EvidenceStore::from_config(StorageConfig::Local {
			root: dir,
			public_origin: "http://127.0.0.1:8184".to_owned(),
		}));
		Self {
			rewards,
			verification,
			auth,
			db,
			evidence_store,
			local_check_replayer: Arc::new(MediaPipeLocalCheckReplayer::new(model_dir)),
			app_attest: None,
			apple_device_client: None,
			play_integrity: None,
			android_attestation: None,
			draft_generator: Arc::new(ActionDraftGenerator::new(None)),
			receipt_signer: Some(Arc::new(ReceiptSigner::development())),
			abuse_salt: b"verily-test-abuse-salt".to_vec(),
		}
	}
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
