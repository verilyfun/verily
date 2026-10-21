//! Events written to the transaction log.
//!
//! Each event is one `Program data:` record: its one-byte `EscrowEvent`
//! discriminator, then its packed fields. Generated clients decode them;
//! attribute records to this program by following the runtime's invoke frames,
//! because the SPL Token and associated token account programs also log
//! during the same instructions.
//!
//! Every event names its `escrow` address. A `pool_id` alone is not unique on
//! chain: any creator can open an escrow under its own key with any pool id,
//! so a watcher must match the escrow address it derived itself.
// Pina's schema macros generate zero-copy companion types and accessors without
// doc comments. Every hand-written item and field in this module is documented;
// the allowance only covers the generated companions.
#![allow(missing_docs)]

use pina::*;

/// Event discriminators.
#[discriminator]
pub enum EscrowEvent {
	/// See `EscrowOpened`.
	EscrowOpened = 1,
	/// See `PayoutReleased`.
	PayoutReleased = 2,
	/// See `EscrowEnded`.
	EscrowEnded = 3,
	/// See `EscrowClosed`.
	EscrowClosed = 4,
}

/// Emitted by `OpenEscrow` once the vault holds the whole budget.
#[event(discriminator = EscrowEvent)]
pub struct EscrowOpened {
	/// The escrow PDA.
	pub escrow: Address,
	/// The creator who funded it.
	pub creator: Address,
	/// The key that can release payouts.
	pub arbiter: Address,
	/// The reward token.
	pub mint: Address,
	/// The escrow's vault.
	pub vault: Address,
	/// The server's reward pool id.
	pub pool_id: [u8; 16],
	/// Token atoms per payout.
	pub amount_per_payout: u64,
	/// Payout indexes funded.
	pub max_payouts: u16,
	/// Unix seconds after which no new completions are paid.
	pub expires_at: i64,
	/// Unix seconds from which no payout is released and the creator may
	/// close.
	pub refund_after: i64,
}

/// Emitted by `ReleasePayout`.
#[event(discriminator = EscrowEvent)]
pub struct PayoutReleased {
	/// The escrow that paid.
	pub escrow: Address,
	/// The server's reward pool id.
	pub pool_id: [u8; 16],
	/// The payout index released.
	pub index: u16,
	/// The token account that received the payout.
	pub recipient: Address,
	/// Token atoms paid.
	pub amount: u64,
}

/// Emitted by `EndEarly`.
#[event(discriminator = EscrowEvent)]
pub struct EscrowEnded {
	/// The escrow that ended.
	pub escrow: Address,
	/// The server's reward pool id.
	pub pool_id: [u8; 16],
	/// The escrow's expiry after ending; never later than before.
	pub expires_at: i64,
	/// The escrow's refund time after ending; never later than before.
	pub refund_after: i64,
}

/// Emitted by `CloseEscrow`.
#[event(discriminator = EscrowEvent)]
pub struct EscrowClosed {
	/// The escrow that closed. Its account no longer exists after this
	/// instruction.
	pub escrow: Address,
	/// The server's reward pool id.
	pub pool_id: [u8; 16],
	/// Token atoms returned to the creator.
	pub refunded: u64,
	/// Payouts released over the escrow's life.
	pub released_count: u16,
	/// The final released bitmap, so a payout job can still tell which
	/// indexes were paid after the account is gone.
	pub released: [u8; 256],
}
