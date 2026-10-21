//! Verily reward escrow: an action's reward is locked before anyone works for
//! it, and it can leave escrow in only two ways.
//!
//! - `OpenEscrow` creates the escrow PDA and its vault and moves the whole
//!   budget, `amount_per_payout × max_payouts`, from the creator in one
//!   instruction, so a published reward provably exists.
//! - `ReleasePayout` pays one fixed payout for one payout index, signed by the
//!   escrow's arbiter (Verily's server key). A bitmap makes each index payable
//!   once, and nothing is released from `refund_after` on.
//! - `EndEarly` lets the creator move the expiry to now. It can never extend
//!   an escrow, and the refund time stays the full refund delay after it.
//! - `CloseEscrow` returns the vault's balance and both accounts' rent to the
//!   creator, from `refund_after` on or once every payout is released.
//!
//! The arbiter never holds funds and cannot change the amount, the token, or
//! the number of payouts. Rewards are classic SPL Token mints only; Token-2022
//! extensions are out of scope until reviewed.
//!
//! ## Module map
//!
//! | Module | Contents |
//! | --- | --- |
//! | [`state`] | The `RewardEscrow` layout, seeds, and limits |
//! | [`instructions`] | Instruction data layouts and discriminators |
//! | [`processors`] | Account lists and handlers for every instruction |
//! | [`math`] | Budget, time, and bitmap arithmetic |
//! | [`events`] | Events emitted to the transaction log |
//! | [`errors`] | Program error codes |

#![no_std]
// Pina's macros generate explicit `Clone` impls for `Copy` types, inline
// accessors, and glob imports. Processors return the program's documented
// error codes, so per-function error docs are relaxed.
#![allow(
	clippy::expl_impl_clone_on_copy,
	clippy::inline_always,
	clippy::missing_errors_doc,
	clippy::wildcard_imports
)]
// `AccountView` is a copyable handle, but borrowing it keeps account access and
// mutability explicit at helper boundaries.
#![allow(clippy::trivially_copy_pass_by_ref)]

#[cfg(all(not(target_arch = "bpf"), not(feature = "bpf-entrypoint"), not(test)))]
extern crate std;

// Host tests build account and instruction bytes with `std` types.
#[cfg(test)]
extern crate std;

/// On-chain entrypoint that routes every instruction to its processor.
#[cfg(feature = "bpf-entrypoint")]
pub mod entrypoint;

pub mod errors;
pub mod events;
pub mod instructions;
pub mod math;
pub mod processors;
pub mod state;

pub use errors::*;
pub use events::*;
pub use instructions::*;
use pina::*;
pub use processors::*;
pub use state::*;

declare_id!("ANL35GQjGtSuCAHTbXGBjnevFqbEtKNf6wDGPKwuPN1p");
