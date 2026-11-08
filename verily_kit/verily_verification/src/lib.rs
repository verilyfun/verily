//! Server-side verification for Verily.
//!
//! `verily_backend` mounts [`ops::Verification`]. The checks here are the ones
//! in `docs/verification.md`: evidence stays hash-pinned, device signatures
//! commit to the digest the server stored, live words come from the server
//! list, and a model verdict does not release a reward. Missing attestation
//! or configuration fails closed.
//!
//! Domain records that `verily_shared` does not own yet live in [`pending_shared`].

pub mod binding;
pub mod capture;
pub mod config;
pub mod council;
pub mod evidence;
pub mod location;
pub mod model_input;
pub mod motion;
pub mod movement;
pub mod ops;
pub mod payout;
pub mod pending_shared;
pub mod reasons;
pub mod review;
pub mod spoken;

pub use ops::Verification;
