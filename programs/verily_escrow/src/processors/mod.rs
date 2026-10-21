//! Account lists and handlers for every instruction.
//!
//! Each `*Accounts` struct is the ordered account list its instruction expects;
//! the generated clients build the same list. Handlers validate every account's
//! owner, address, signer and writable flags, and mint before any transfer or
//! state change, and emit an event when they succeed.

mod close;
mod end;
mod open;
mod release;

pub use close::*;
pub use end::*;
pub use open::*;
use pina::sysvars::Sysvar;
use pina::sysvars::clock::Clock;
use pina::*;
pub use release::*;

use crate::ID;
use crate::errors::EscrowError;
use crate::state::RewardEscrow;

/// A copy of an escrow's terms, taken so the account borrow ends before any
/// cross-program call.
#[derive(Clone, Copy, Debug)]
pub(crate) struct EscrowView {
	/// The escrow PDA.
	pub(crate) address: Address,
	/// The creator, the escrow's first variable seed.
	pub(crate) creator: Address,
	/// The only key that can release payouts.
	pub(crate) arbiter: Address,
	/// The reward token.
	pub(crate) mint: Address,
	/// The escrow's vault.
	pub(crate) vault: Address,
	/// The server's reward pool id, the escrow's second variable seed.
	pub(crate) pool_id: [u8; 16],
	/// Token atoms per payout.
	pub(crate) amount_per_payout: u64,
	/// Payout indexes funded.
	pub(crate) max_payouts: u16,
	/// Payouts released so far.
	pub(crate) released_count: u16,
	/// Unix seconds after which no new completions are paid.
	pub(crate) expires_at: i64,
	/// Unix seconds from which no payout is released.
	pub(crate) refund_after: i64,
	/// Seconds between the expiry and the refund time.
	pub(crate) refund_delay: u32,
	/// Canonical bump of the escrow PDA.
	pub(crate) bump: u8,
}

impl EscrowView {
	/// Load an escrow and prove it sits at its own PDA.
	///
	/// The typed load checks ownership, discriminator, schema version, size,
	/// and the stored-state invariants; the derivation check re-derives the
	/// address from the stored creator, pool id, and bump, so the signer seeds
	/// this view produces always belong to `escrow`.
	pub(crate) fn load(escrow: &AccountView) -> Result<Self, ProgramError> {
		let view = {
			let state = escrow.as_account::<RewardEscrow>(&ID)?;
			Self {
				address: *escrow.address(),
				creator: state.creator,
				arbiter: state.arbiter,
				mint: state.mint,
				vault: state.vault,
				pool_id: state.pool_id,
				amount_per_payout: state.amount_per_payout(),
				max_payouts: state.max_payouts(),
				released_count: state.released_count(),
				expires_at: state.expires_at(),
				refund_after: state.refund_after(),
				refund_delay: state.refund_delay(),
				bump: state.bump,
			}
		};
		if !is_derived_address(
			&view.address,
			&RewardEscrow::seeds(&view.creator, view.pool_id).as_slices(),
			view.bump,
			&ID,
		) {
			return Err(ProgramError::InvalidSeeds);
		}
		Ok(view)
	}

	/// Require `creator` to be this escrow's creator.
	pub(crate) fn assert_creator(&self, creator: &AccountView) -> ProgramResult {
		if creator.address() != &self.creator {
			return Err(EscrowError::NotCreator.into());
		}
		Ok(())
	}

	/// Require `mint` to be this escrow's reward token.
	pub(crate) fn assert_mint(&self, mint: &AccountView) -> ProgramResult {
		if mint.address() != &self.mint {
			return Err(EscrowError::MintMismatch.into());
		}
		Ok(())
	}

	/// Require `vault` to be this escrow's vault.
	pub(crate) fn assert_vault(&self, vault: &AccountView) -> ProgramResult {
		if vault.address() != &self.vault {
			return Err(EscrowError::VaultMismatch.into());
		}
		Ok(())
	}

	/// Run `sign` with the escrow PDA's signer seeds.
	pub(crate) fn with_signer<T>(&self, sign: impl FnOnce(Signer<'_, '_>) -> T) -> T {
		let seeds = RewardEscrow::seeds(&self.creator, self.pool_id).with_bump(self.bump);
		let signer = seeds.to_signer();
		sign(signer.as_signer())
	}
}

/// The decimals of a classic SPL Token mint.
///
/// The account list already requires the SPL Token program to own `mint`;
/// this load also checks its size and that it is initialized.
pub(crate) fn mint_decimals(mint: &AccountView) -> Result<u8, ProgramError> {
	let mint = mint.as_token_mint_for_program(&token::ID)?;
	if !mint.is_initialized() {
		return Err(ProgramError::UninitializedAccount);
	}
	Ok(mint.decimals())
}

/// Require `token_account` to be an SPL Token account that holds `mint`, and
/// return its owner and balance.
pub(crate) fn token_account_for_mint(
	token_account: &AccountView,
	mint: &Address,
) -> Result<(Address, u64), ProgramError> {
	let account = token_account.as_token_account_for_program(&token::ID)?;
	if account.mint() != mint {
		return Err(EscrowError::MintMismatch.into());
	}
	Ok((*account.owner(), account.amount()))
}

/// The cluster's Unix time.
pub(crate) fn now() -> Result<i64, ProgramError> {
	Ok(Clock::get()?.unix_timestamp)
}
