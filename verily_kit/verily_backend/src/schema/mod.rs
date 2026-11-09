//! Verily's `leptoskit_db` schema: accounts, attempts, and evidence, plus the
//! action and reward tables linked from `verily_rewards`.
//!
//! Tables are declared with `leptoskit_db` macros from leptoskit `main`. Auth
//! and IdP packs sit beside them. After changing a table, use
//! the LeptosKit CLI (never ad-hoc SQL scripts) from this package directory:
//!
//! ```sh
//! cd verily_kit/verily_backend
//! monosecret run --profile development -- leptoskit doctor
//! monosecret run --profile development -- leptoskit db migration create <name>
//! monosecret run --profile development -- leptoskit db check
//! monosecret run --profile development -- leptoskit db migrate
//! monosecret run --profile development -- leptoskit db status
//! monosecret run --profile development -- leptoskit dev
//! # `lk` is the same binary as `leptoskit`.
//! ```
//!
//! Domain crates own business logic against these rows. Action and reward
//! pool tables come from `verily_rewards` (path-dep); this host does not
//! redeclare them. `leptoskit_rpc` is packed there too, so this module only
//! packs auth and idp.

use leptoskit_db as _;
use leptoskit_db_macros as _;
use leptoskit_db_schema as _;

mod accounts;
mod attempts;
mod evidence;

pub use accounts::Account;
pub use attempts::Attempt;
pub use evidence::Evidence;
pub use verily_rewards::schema::ActionRow;
pub use verily_rewards::schema::PayoutWalletRow;
pub use verily_rewards::schema::RewardPayoutRow;
pub use verily_rewards::schema::RewardPoolRow;
pub use verily_rewards::schema::WalletLinkChallengeRow;

// Sign-in tables under `auth`, and the OAuth / OIDC provider under `idp`.
// `leptoskit_rpc` is packed by `verily_rewards` once that crate is linked.
leptoskit_db::packs!(leptoskit_auth, leptoskit_idp);

leptoskit_db::export_schema!();

/// Every migration, embedded for the host to apply at startup.
pub static MIGRATIONS: &[leptoskit_db::Migration] = leptoskit_db::migrations!("migrations");

/// Postgres-shaped migrations for multi-server deploys (PostGIS host).
pub static POSTGRES_MIGRATIONS: &[leptoskit_db::Migration] =
	leptoskit_db::migrations!("migrations-postgres");
