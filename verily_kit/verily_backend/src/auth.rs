//! Sign-in and identity-provider builders for the Axum host.
//!
//! Encryption keys come from Monosecret-resolved environment values (see
//! [`crate::secrets`]). Call [`crate::load_host_secrets`] first so missing
//! names fail closed once — never retry. A debug build without
//! `AUTH_ENCRYPTION_KEYS` uses a fixed development key; release builds refuse
//! to start without keys.

use std::time::Duration;

use leptoskit_auth::Auth;
use leptoskit_auth::AuthBuilder;
use leptoskit_auth::AuthError;
use leptoskit_auth::Keys;
use leptoskit_auth::SessionLifetimes;
use leptoskit_config::LeptoskitConfig;
use leptoskit_db::Db;
use leptoskit_idp::Idp;
use leptoskit_idp::IdpBuilder;
use leptoskit_idp::IdpError;

use crate::secrets::HostSecrets;
use crate::secrets::SecretsError;

/// Default environment name for auth encryption keys (leptoskit default).
pub const AUTH_KEYS_ENV: &str = "AUTH_ENCRYPTION_KEYS";

const DAY: u64 = 24 * 60 * 60;

/// Errors while building auth or the identity provider from secrets / config.
#[derive(Debug, thiserror::Error)]
pub enum AuthSetup {
	/// Monosecret snapshot failed.
	#[error(transparent)]
	Secrets(#[from] SecretsError),
	/// `leptoskit_auth` refused the configuration or keys.
	#[error(transparent)]
	Auth(#[from] AuthError),
	/// `leptoskit_idp` refused the configuration.
	#[error(transparent)]
	Idp(#[from] IdpError),
}

/// Build sign-in from a Monosecret host snapshot and optional `leptoskit.toml`.
///
/// When `config` has an `[auth]` table, session lifetimes and origin come from
/// it. Keys always come from the Monosecret snapshot (or the debug development
/// key), never from the toml file. Full `Auth::from_config` (mailers, OAuth
/// providers) is used when that path succeeds; otherwise the snapshot builder
/// still starts the host.
///
/// # Errors
///
/// When keys are missing in release, invalid, or `[auth]` cannot be applied.
pub fn build_auth(
	db: &Db,
	secrets: &HostSecrets,
	config: Option<&LeptoskitConfig>,
) -> Result<AuthBuilder, AuthSetup> {
	let keys = match secrets.auth_encryption_keys() {
		Ok(value) => Keys::parse(value)?,
		#[cfg(debug_assertions)]
		Err(_) => Keys::single("development", [7; 32]),
		#[cfg(not(debug_assertions))]
		Err(error) => return Err(error.into()),
	};

	if let Some(config) = config.filter(|config| config.auth.is_some()) {
		if let Ok(builder) = Auth::from_config(db, config) {
			return Ok(builder);
		}

		let auth = config
			.auth
			.as_ref()
			.ok_or_else(|| AuthError::Config("add an [auth] table to leptoskit.toml".into()))?;
		let mut builder = Auth::builder(db, keys).app_name(
			auth.app_name
				.clone()
				.unwrap_or_else(|| config.app.name.clone()),
		);
		builder = builder.sessions(SessionLifetimes {
			idle: Duration::from_secs(u64::from(auth.idle_days) * DAY),
			absolute: Duration::from_secs(u64::from(auth.absolute_days) * DAY),
			access: Duration::from_secs(u64::from(auth.access_minutes) * 60),
		});
		if let Some(origin) = &auth.origin {
			builder = builder.origin(origin.clone());
		}
		if let Some(header) = &auth.client_ip_header {
			builder = builder.client_ip_header(header.clone());
		}
		return Ok(builder);
	}

	Ok(Auth::builder(db, keys).app_name("Verily"))
}

/// Build the identity provider beside `auth` when `[auth.idp]` is present.
///
/// Returns `Ok(None)` when the config has no idp table, so the host can run
/// first-party sign-in alone until OAuth clients are needed.
///
/// # Errors
///
/// When `[auth.idp]` is present but invalid.
pub fn build_idp(
	db: &Db,
	auth: &Auth,
	config: Option<&LeptoskitConfig>,
) -> Result<Option<IdpBuilder>, AuthSetup> {
	let Some(config) = config else {
		return Ok(None);
	};
	let Some(auth_config) = &config.auth else {
		return Ok(None);
	};
	if auth_config.idp.is_none() {
		return Ok(None);
	}
	Ok(Some(Idp::from_config(db, auth, config)?))
}
