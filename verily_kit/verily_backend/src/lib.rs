//! Verily's LeptosKit Axum host.
//!
//! This crate wires the database, sign-in, identity provider, and RPC server,
//! then mounts [`verily_verification::Verification`] and
//! [`verily_rewards::Rewards`]. Domain logic stays in those crates — this
//! host only mounts them (fail closed via `::closed()`).
//!
//! Secrets are resolved only through Monosecret (see [`secrets`]): the root
//! `monosecret.toml`, Development vault item `"Verily"`, and an ignored `.env`
//! with mode `0600`. This crate never calls `op` and never retries secret
//! access in a loop. Production uses injected environment values only.
//!
//! Solana / chain access is not owned here: `verily_rewards` owns the gateway
//! (via `pina-rs/solana_kit`). This host only mounts what rewards exports and
//! installs [`verily_rewards::RewardsHandle`] on each RPC identity.

mod auth;
mod mounts;
pub mod schema;
mod secrets;

use std::path::PathBuf;

use leptoskit_auth::Auth;
use leptoskit_auth::AuthBuilder;
use leptoskit_auth::AuthError;
use leptoskit_auth::Mailbox;
use leptoskit_axum::axum::Router;
use leptoskit_axum::axum::routing::get;
use leptoskit_config::LeptoskitConfig;
use leptoskit_db::Db;
use leptoskit_idp::Idp;
use leptoskit_idp::IdpError;
use leptoskit_rpc::server::Live;
use leptoskit_rpc::server::Roles;
use leptoskit_rpc::server::Server;

pub use auth::AUTH_KEYS_ENV;
pub use auth::AuthSetup;
pub use auth::build_auth;
pub use auth::build_idp;
pub use mounts::DomainMount;
pub use mounts::rewards;
pub use mounts::rewards::Mounted as MountedRewards;
pub use mounts::verification;
pub use mounts::verification::Mounted as MountedVerification;
pub use schema::Account;
pub use schema::ActionRow;
pub use schema::Attempt;
pub use schema::Evidence;
pub use schema::MIGRATIONS;
pub use schema::POSTGRES_MIGRATIONS;
pub use schema::RewardPoolRow;
pub use secrets::HOST_SECRET_NAMES;
pub use secrets::HostSecrets;
pub use secrets::SecretsError;
pub use secrets::load_host_secrets;

/// How to start the Verily Axum host.
#[derive(Debug, Clone)]
pub struct Options {
	/// Site origin for cookies and the live socket origin check.
	pub origin: Option<String>,
	/// Built web client root (`dist/`). `None` serves no static files.
	pub site_root: Option<PathBuf>,
	/// Which process roles to run. Defaults to every role.
	pub roles: Roles,
	/// Keep development mail in an in-app mailbox (debug / local only).
	pub demo_mail: bool,
}

impl Options {
	/// Defaults for a migrated `db`: every role, no origin, no static files.
	#[must_use]
	pub fn new(_db: &Db) -> Self {
		Self {
			origin: None,
			site_root: None,
			roles: Roles::ALL,
			demo_mail: cfg!(debug_assertions),
		}
	}
}

/// A running Verily host: its router and the pieces the binary shuts down.
pub struct Host {
	/// Everything this process serves.
	pub router: Router,
	/// The live socket server; start it before serving when `roles.live()`.
	pub live: Live,
	/// Sign-in service.
	pub auth: Auth,
	/// Optional OAuth / OIDC provider built beside auth.
	pub idp: Option<Idp>,
	/// Fail-closed verification ops from `verily_verification`.
	pub verification: MountedVerification,
	/// Fail-closed rewards handle from `verily_rewards` (also on RPC context).
	pub rewards: verily_rewards::RewardsHandle,
	/// Roles this process runs.
	pub roles: Roles,
	/// Development mailbox when [`Options::demo_mail`] is on.
	pub mailbox: Option<Mailbox>,
}

impl std::fmt::Debug for Host {
	fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
		f.debug_struct("Host")
			.field("roles", &self.roles)
			.field("has_idp", &self.idp.is_some())
			.field("verification_mounted", &true)
			.field("rewards_mounted", &true)
			.finish_non_exhaustive()
	}
}

/// Errors while assembling the host.
#[derive(Debug, thiserror::Error)]
pub enum StartError {
	/// Sign-in could not be built.
	#[error(transparent)]
	Auth(#[from] AuthError),
	/// The identity provider could not be built.
	#[error(transparent)]
	Idp(#[from] IdpError),
	/// Auth / IdP setup from secrets or config failed.
	#[error(transparent)]
	Setup(#[from] AuthSetup),
	/// Verification mount refused to start (fail closed).
	#[error(transparent)]
	Verification(#[from] verily_verification::config::ConfigError),
	/// Rewards mount refused to start (fail closed).
	#[error(transparent)]
	Rewards(#[from] verily_rewards::ConfigError),
}

/// The app's queries and mutations on `db`, with domain ops mounted.
///
/// Call [`Server::identify`] with the built [`Auth`] so operations run as the
/// signed-in person.
#[must_use]
pub fn operations(db: Db) -> Server {
	let server = Server::new(db);
	let server = verification::mount_ops(server);
	rewards::mount_ops(server)
}

/// Installs `POST /api/<name>` for every registered operation, plus the host's
/// own health route and domain mounts.
pub fn router<S>(operations: &Server) -> Router<S>
where
	S: Clone + Send + Sync + 'static,
{
	let mut app = operations
		.router()
		.route("/api/health", get(|| async { "ok" }));
	app = verification::mount_router(app);
	app = rewards::mount_router(app);
	app
}

/// Builds Verily on a migrated `db`, with sign-in from `auth`.
///
/// When `config` includes `[auth.idp]`, the identity provider is built and
/// mounted. Verification and rewards are mounted fail-closed from their
/// crates (`Verification::closed`, `Rewards::closed`).
///
/// # Errors
///
/// When sign-in, the identity provider, verification, or rewards cannot be
/// built.
pub fn start(
	db: &Db,
	mut auth: AuthBuilder,
	config: Option<&LeptoskitConfig>,
	options: Options,
) -> Result<Host, StartError> {
	let mailbox = options.demo_mail.then(Mailbox::new);
	if let Some(mailbox) = &mailbox {
		auth = auth.mailer(mailbox.clone());
		#[cfg(debug_assertions)]
		{
			auth = auth.dev_sign_in();
		}
	}
	if let Some(origin) = &options.origin {
		auth = auth.origin(origin.clone());
	}
	// Each new auth account gets a Verily `accounts` profile row.
	let auth = auth.on_sign_up::<Account>().build()?;

	let idp = match build_idp(db, &auth, config)? {
		Some(builder) => Some(builder.build()?),
		None => None,
	};

	let verification = verification::mount()?;
	let rewards = rewards::handle(rewards::mount()?);

	let roles = options.roles;
	let identify = rewards::identify(auth.clone(), rewards.clone());
	let rpc = operations(db.clone()).identify(identify);
	let mut live = match auth.origin() {
		Some(origin) => rpc.live().origin(origin),
		None => rpc.live(),
	};
	if let Some(origin) = &options.origin {
		live = live.origin(origin);
	}

	let mut app = Router::new();
	if roles.web() {
		app = app.merge(router(&rpc)).merge(auth.router());
		if let Some(idp) = &idp {
			app = app.merge(idp.router());
		}
		if let Some(root) = &options.site_root {
			app = app.fallback_service(leptoskit_axum::static_files(root));
		}
	}
	if roles.live() {
		app = app.merge(live.router());
	}

	// Session layer wraps application routes; IdP layer wraps outside it.
	let app = app.layer(auth.layer());
	let app = match &idp {
		Some(idp) => app.layer(idp.layer()),
		None => app,
	};

	Ok(Host {
		router: app,
		live,
		auth,
		idp,
		verification,
		rewards,
		roles,
		mailbox,
	})
}
