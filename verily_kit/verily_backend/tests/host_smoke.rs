//! Compile-time and unit smoke for the Axum host mounts and secret names.

use verily_backend::HOST_SECRET_NAMES;
use verily_backend::MIGRATIONS;
use verily_backend::POSTGRES_MIGRATIONS;
use verily_backend::rewards;
use verily_backend::verification;

#[test]
fn host_secret_contract_names_database_and_auth_keys() {
	assert!(HOST_SECRET_NAMES.contains(&"DATABASE_URL"));
	assert!(HOST_SECRET_NAMES.contains(&"AUTH_ENCRYPTION_KEYS"));
}

#[test]
fn domain_prefixes_are_reserved() {
	assert_eq!(verification::PREFIX, "/verification");
	assert_eq!(rewards::PREFIX, "/rewards");
	assert_eq!(rewards::PREFIX, verily_rewards::PREFIX);
}

#[test]
fn verification_mounts_fail_closed_service() {
	let _mounted = verification::mount().expect("closed verification mounts");
}

#[test]
fn rewards_mounts_fail_closed_service() {
	let mounted = rewards::mount().expect("closed rewards mounts");
	let _handle = rewards::handle(mounted);
}

#[test]
fn init_migrations_are_embedded() {
	assert!(
		!MIGRATIONS.is_empty(),
		"sqlite migrations/ must contain the CLI-written init migration"
	);
	assert!(
		!POSTGRES_MIGRATIONS.is_empty(),
		"migrations-postgres/ must contain the CLI-written init migration"
	);
}
