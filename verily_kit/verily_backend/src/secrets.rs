//! Host secrets for the Verily Axum backend.
//!
//! Resolve secrets only through Monosecret. Values reach this process after
//! `monosecret run` (or an injected production environment). This module
//! snapshots named entries with [`monosecret::client::Client`] — never call
//! `op` directly, and never retry secret access in a loop.
//!
//! Declarations live in the repository-root `monosecret.toml` (Development
//! vault item `"Verily"`; ignored `.env` mode `0600`, never committed). The
//! kit shell owns merging host names into that manifest; this crate owns
//! reading them at process start.
//!
//! Production profiles use injected environment values only — no 1Password
//! lookup at process restart.

use monosecret::client::Client;
use monosecret::client::ExposeSecret;
use monosecret::client::MissingSecret;

/// Environment names the Axum host reads at startup.
///
/// Keep these aligned with `leptoskit.toml`'s `_env` fields once the shell
/// writes that file. Domain crates (`verily_verification`, `verily_rewards`)
/// resolve their own secrets; this list is the host half only.
pub const HOST_SECRET_NAMES: &[&str] = &[
	"DATABASE_URL",
	"AUTH_ENCRYPTION_KEYS",
];

/// Errors while snapshotting host secrets.
#[derive(Debug, thiserror::Error)]
pub enum SecretsError {
	/// A required name was absent from the resolved environment.
	#[error(transparent)]
	Missing(#[from] MissingSecret),
}

/// Snapshot of host secrets resolved through Monosecret.
///
/// Values stay wrapped until explicitly exposed. Dropping the client zeroes
/// its owned storage.
#[derive(Debug)]
pub struct HostSecrets {
	client: Client,
}

impl HostSecrets {
	/// Snapshot [`HOST_SECRET_NAMES`] from the process environment once.
	///
	/// # Errors
	///
	/// When any required name is missing. Fail closed — do not retry.
	pub fn load() -> Result<Self, SecretsError> {
		Ok(Self {
			client: Client::from_env(HOST_SECRET_NAMES.iter().copied())?,
		})
	}

	/// Snapshot an explicit name list (tests, or a narrower host role).
	///
	/// # Errors
	///
	/// When any named entry is missing. Fail closed — do not retry.
	pub fn load_named(
		names: impl IntoIterator<Item = impl AsRef<str>>,
	) -> Result<Self, SecretsError> {
		Ok(Self {
			client: Client::from_env(names)?,
		})
	}

	/// Postgres / SQLite URL for [`leptoskit_db::Db::connect`].
	///
	/// # Errors
	///
	/// When `DATABASE_URL` was not part of the snapshot.
	pub fn database_url(&self) -> Result<&str, SecretsError> {
		Ok(self.client.get("DATABASE_URL")?.expose_secret())
	}

	/// Sign-in key ring for [`leptoskit_auth::Keys::parse`].
	///
	/// # Errors
	///
	/// When `AUTH_ENCRYPTION_KEYS` was not part of the snapshot.
	pub fn auth_encryption_keys(&self) -> Result<&str, SecretsError> {
		Ok(self.client.get("AUTH_ENCRYPTION_KEYS")?.expose_secret())
	}

	/// Borrow the underlying Monosecret client.
	#[must_use]
	pub fn client(&self) -> &Client {
		&self.client
	}
}

/// Load the host secret snapshot. Prefer this over reading `std::env` in
/// application code.
///
/// # Errors
///
/// When a required secret is missing. Callers must not retry in a loop.
pub fn load_host_secrets() -> Result<HostSecrets, SecretsError> {
	HostSecrets::load()
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn host_secret_names_are_stable() {
		assert_eq!(HOST_SECRET_NAMES, &["DATABASE_URL", "AUTH_ENCRYPTION_KEYS"]);
	}

	#[test]
	fn from_values_snapshot_exposes_names_only_in_debug() {
		let client = Client::from_values([
			("DATABASE_URL".into(), "sqlite://verily.sqlite3".into()),
			(
				"AUTH_ENCRYPTION_KEYS".into(),
				"dev:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA".into(),
			),
		]);
		let debug = format!("{client:?}");
		assert!(debug.contains("DATABASE_URL"));
		assert!(!debug.contains("sqlite://verily.sqlite3"));
	}
}
