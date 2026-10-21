#![cfg(test)]

//! Mollusk tests for the reward escrow program.
//!
//! Every test loads the compiled program beside the real SPL Token and
//! associated token account programs, so each budget deposit, payout, refund,
//! and account close runs the token program's own rules. Instructions are
//! encoded by hand from the documented layouts, which also pins the wire
//! format the generated clients use.
//!
//! Build the program first, then run the suite (Mollusk logs every
//! instruction at debug level; `RUST_LOG=error` quiets it):
//!
//! ```sh
//! devenv shell build:escrow
//! cargo test --manifest-path programs/verily_escrow/tests/mollusk/Cargo.toml --locked
//! ```
//!
//! `VERILY_ESCROW_ARTIFACT` points the suite at another build of the program.

mod close;
mod end_early;
mod harness;
mod migrate;
mod open;
mod release;
