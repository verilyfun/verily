//! The `RewardEscrow` account, its PDA seeds, and its limits.
//!
//! Pina accounts are packed, fixed width, and decoded at their exact size, so
//! the field order of `RewardEscrow` is part of the on-chain ABI. The first
//! byte of the account is its `EscrowAccount` discriminator and the second is
//! the schema version recorded by `pina migrations`.
// Pina's schema macros generate zero-copy companion types and accessors without
// doc comments. Every hand-written item and field in this module is documented;
// the allowance only covers the generated companions.
#![allow(missing_docs)]

use pina::*;

use crate::math::refund_after;

/// Seed prefix for `RewardEscrow` PDAs: `[b"reward-escrow", creator, pool_id]`.
pub const REWARD_ESCROW_SEED: &[u8] = b"reward-escrow";

/// Bytes of a reward pool id: the server's 16-byte pool UUID.
pub const POOL_ID_BYTES: usize = 16;

/// The most payouts one escrow can hold.
pub const MAX_PAYOUTS: u16 = 2_048;

/// Bytes of the `released` bitmap: one bit per payout index.
pub const RELEASED_BITMAP_BYTES: usize = 256;

/// The shortest refund delay an escrow may set: 3 days.
pub const MIN_REFUND_DELAY: u32 = 3 * 24 * 60 * 60;

/// The longest refund delay an escrow may set: 30 days.
pub const MAX_REFUND_DELAY: u32 = 30 * 24 * 60 * 60;

// Pina's schema macros need literal array lengths; keep them in step with the
// named limits the code uses, and keep the bitmap exactly one bit per payout.
const _: () = assert!(
	POOL_ID_BYTES == 16
		&& RELEASED_BITMAP_BYTES == 256
		&& RELEASED_BITMAP_BYTES * 8 == MAX_PAYOUTS as usize
);

/// Account-type discriminators for every account this program owns.
#[discriminator]
pub enum EscrowAccount {
	/// One action's locked reward budget. See `RewardEscrow`.
	RewardEscrow = 1,
}

/// One action's reward budget, locked until it is paid out or refunded.
///
/// `OpenEscrow` creates it and funds its vault with
/// `amount_per_payout × max_payouts` in one instruction. Afterwards the vault
/// moves only through `ReleasePayout`, one fixed payout per payout index and
/// only before `refund_after`, and through `CloseEscrow`, which returns the
/// remainder to the creator from `refund_after` on, or as soon as every payout
/// is released.
#[account(discriminator = EscrowAccount, migrations, validate(with = validate_reward_escrow))]
#[pda(seeds = [REWARD_ESCROW_SEED, creator: Address, pool_id: [u8; 16]], bump = bump)]
pub struct RewardEscrow {
	/// Funded the escrow; the only key that can end or close it, and the
	/// owner of everything it refunds.
	pub creator: Address,
	/// The only key that can release payouts.
	pub arbiter: Address,
	/// The reward token: a classic SPL Token mint.
	pub mint: Address,
	/// The escrow PDA's associated token account for `mint`.
	pub vault: Address,
	/// The server's reward pool id (a 16-byte UUID).
	pub pool_id: [u8; 16],
	/// Token atoms paid per released payout index.
	#[pina(validate(value >= 1))]
	pub amount_per_payout: u64,
	/// Payout indexes the escrow funds: `0..max_payouts`.
	#[pina(validate(value >= 1 && value <= MAX_PAYOUTS))]
	pub max_payouts: u16,
	/// Payouts released so far.
	pub released_count: u16,
	/// Unix seconds after which the server pays no new completions. The
	/// creator can only move it earlier.
	pub expires_at: i64,
	/// `expires_at + refund_delay`. No payout is released from this time on,
	/// and the creator may close the escrow.
	pub refund_after: i64,
	/// Seconds between `expires_at` and `refund_after`, kept so proof
	/// submitted just before the end can still be reviewed and appealed.
	#[pina(validate(value >= MIN_REFUND_DELAY && value <= MAX_REFUND_DELAY))]
	pub refund_delay: u32,
	/// Canonical bump of this PDA.
	pub bump: u8,
	/// Bit `i` (byte `i / 8`, bit `i % 8`) is set once payout index `i` is
	/// released.
	pub released: [u8; 256],
}

/// The stored-state invariants `RewardEscrow` keeps across every
/// instruction: no more payouts released than funded, and a refund time that
/// is always exactly the refund delay after the expiry.
fn validate_reward_escrow(value: &RewardEscrowZc) -> ProgramResult {
	if value.released_count() > value.max_payouts() {
		return Err(ProgramError::InvalidAccountData);
	}
	match refund_after(value.expires_at(), value.refund_delay()) {
		Ok(expected) if expected == value.refund_after() => Ok(()),
		_ => Err(ProgramError::InvalidAccountData),
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	const CREATOR: Address = Address::new_from_array([1; 32]);
	const ARBITER: Address = Address::new_from_array([2; 32]);
	const POOL_ID: [u8; 16] = [7; 16];

	fn escrow_bytes(configure: impl FnOnce(&mut RewardEscrowZc)) -> std::vec::Vec<u8> {
		let mut data = std::vec![0u8; RewardEscrow::SIZE];
		// Write a valid escrow, then let the test corrupt it in place.
		RewardEscrow::initialize(&mut data, |escrow| {
			escrow.creator = CREATOR;
			escrow.arbiter = ARBITER;
			escrow.pool_id = POOL_ID;
			escrow.amount_per_payout.set(1_000);
			escrow.max_payouts.set(10);
			escrow.expires_at.set(1_000);
			escrow.refund_delay.set(MIN_REFUND_DELAY);
			escrow.refund_after.set(1_000 + i64::from(MIN_REFUND_DELAY));
			Ok(())
		})
		.expect("a consistent escrow initializes");
		let escrow = RewardEscrow::try_from_bytes_mut(&mut data).expect("decodes");
		configure(escrow);
		data
	}

	#[test]
	fn discriminators_and_seed_are_stable() {
		assert_eq!(EscrowAccount::RewardEscrow as u8, 1);
		assert_eq!(REWARD_ESCROW_SEED, b"reward-escrow");
		assert_eq!(MIN_REFUND_DELAY, 259_200);
		assert_eq!(MAX_REFUND_DELAY, 2_592_000);
	}

	#[test]
	fn seeds_are_prefix_creator_then_pool_id() {
		let seeds = RewardEscrow::seeds(&CREATOR, POOL_ID);
		let slices = seeds.as_slices();
		assert_eq!(slices.len(), 3);
		assert_eq!(slices[0], REWARD_ESCROW_SEED);
		assert_eq!(slices[1], CREATOR.as_ref());
		assert_eq!(slices[2], POOL_ID);
	}

	#[test]
	fn the_layout_holds_one_bit_per_payout() {
		// Discriminator, version, then the packed fields.
		assert_eq!(
			RewardEscrow::SIZE,
			2 + 4 * 32 + 16 + 8 + 2 + 2 + 8 + 8 + 4 + 1 + 256
		);
	}

	#[test]
	fn a_consistent_escrow_decodes() {
		let data = escrow_bytes(|_| {});
		let escrow = RewardEscrow::try_from_bytes(&data).expect("decodes");
		assert_eq!(escrow.max_payouts(), 10);
	}

	#[test]
	fn more_releases_than_payouts_is_rejected() {
		let data = escrow_bytes(|escrow| escrow.released_count.set(11));
		assert_eq!(
			RewardEscrow::try_from_bytes(&data).err(),
			Some(ProgramError::InvalidAccountData)
		);
	}

	#[test]
	fn a_refund_time_off_the_delay_is_rejected() {
		let data = escrow_bytes(|escrow| escrow.refund_after.set(1_000));
		assert_eq!(
			RewardEscrow::try_from_bytes(&data).err(),
			Some(ProgramError::InvalidAccountData)
		);
	}

	#[test]
	fn out_of_range_terms_are_rejected() {
		for corrupt in [
			(|escrow: &mut RewardEscrowZc| escrow.amount_per_payout.set(0)) as fn(&mut _),
			|escrow| escrow.max_payouts.set(0),
			|escrow| escrow.max_payouts.set(MAX_PAYOUTS + 1),
			|escrow| {
				escrow.refund_delay.set(MIN_REFUND_DELAY - 1);
				escrow
					.refund_after
					.set(1_000 + i64::from(MIN_REFUND_DELAY) - 1);
			},
		] {
			let data = escrow_bytes(corrupt);
			assert_eq!(
				RewardEscrow::try_from_bytes(&data).err(),
				Some(ProgramError::InvalidAccountData)
			);
		}
	}
}
