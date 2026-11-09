//! Server-side actions and rewards.
//!
//! `verily_backend` mounts [`Rewards::closed`] the same way it mounts
//! `verily_verification::Verification::closed`: no chain client, and every
//! release fails closed until `from_secrets` installs a Solana gateway.
//! Domain records come from
//! [`verily_shared`]. Solana reads and the escrow PDA go through
//! `pina-rs/solana_kit`. Reward, escrow, and chain secrets are read from a
//! Monosecret client that the process already populated. This crate does not
//! call `op`, does not wrap Serverpod, and does not ship the escrow program.
//!
//! A rewarded action publishes only after the escrow account has been read
//! from finalized chain state. A payout index is stored once for an attempt.
//! A payout above the review threshold stays held until a different person
//! accepts it. Missing or invalid configuration does not release a payout,
//! and a `local-dev-` signature is never a production release.

#![forbid(unsafe_code)]

/// HTTP prefix the backend reserves for rewards routes.
pub const PREFIX: &str = "/rewards";

pub mod chain;
pub mod config;
pub mod decide;
pub mod gateway;
pub mod ops;
pub mod schema;
pub mod store;

leptoskit_db::packs!(leptoskit_rpc);

pub use config::{ConfigError, Rewards, RunMode};
pub use decide::{
	FundingMismatch, ReleaseCode, ReleaseOutcome, confirmed_release_signature, inspect_funding,
	publish_block, review_blocks_release,
};
pub use gateway::{Gateway, PlantedGateway, RawAccount};
pub use ops::{CallerName, RewardsHandle};
pub use store::{
	ReservedPayout, RewardsError, accept_review, confirm_funding, create_action,
	link_payout_wallet, prepare_funding, publish_action, release_payout, reserve_payout,
	save_action,
};
