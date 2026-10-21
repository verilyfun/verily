//! Instruction discriminators and data layouts.
//!
//! Every instruction's data is its one-byte discriminator followed by the
//! packed little-endian fields of its data struct. The account list for each
//! instruction lives next to its handler in `crate::processors`.
// Pina's schema macros generate zero-copy companion types and accessors without
// doc comments. Every hand-written item and field in this module is documented;
// the allowance only covers the generated companions.
#![allow(missing_docs)]

use pina::*;

use crate::ID;
use crate::errors::EscrowError;
use crate::math::escrow_budget;
use crate::math::refund_after;
use crate::processors::*;
use crate::state::MAX_PAYOUTS;
use crate::state::MAX_REFUND_DELAY;
use crate::state::MIN_REFUND_DELAY;
use crate::state::RewardEscrow;

/// Upper bound on the reserved `Migrate` instruction's rent top-up: roughly
/// 6,960 lamports per byte an account grows when its layout changes.
pub const MAX_MIGRATION_LAMPORTS: u64 = 100_000;

/// Instruction discriminators. Values are part of the wire format.
#[discriminator(
	entrypoint,
	migrations(RewardEscrow),
	migrations_max_lamports = MAX_MIGRATION_LAMPORTS
)]
pub enum EscrowInstruction {
	/// Create an escrow and its vault, and lock the whole reward budget.
	OpenEscrow = 0,
	/// Release one fixed payout for a payout index. Arbiter only.
	ReleasePayout = 1,
	/// Move the expiry to now if it is later. Creator only.
	EndEarly = 2,
	/// Refund the vault and close the escrow. Creator only.
	CloseEscrow = 3,
}

/// Data for `EscrowInstruction::OpenEscrow`.
#[instruction(
	discriminator = EscrowInstruction::OpenEscrow,
	validate(with = validate_open_escrow)
)]
pub struct OpenEscrowInstruction {
	/// The server's reward pool id (a 16-byte UUID); the escrow's second seed.
	pub pool_id: [u8; 16],
	/// The only key that can release payouts.
	pub arbiter: Address,
	/// Token atoms per verified completion.
	#[pina(validate(value >= 1, error = EscrowError::InvalidPayoutAmount))]
	pub amount_per_payout: u64,
	/// Payout indexes to fund, from 1 to `MAX_PAYOUTS`.
	#[pina(validate(value >= 1 && value <= MAX_PAYOUTS, error = EscrowError::InvalidMaxPayouts))]
	pub max_payouts: u16,
	/// Unix seconds after which no new completions are paid; must be in the
	/// future.
	pub expires_at: i64,
	/// Seconds from the expiry until the refund window opens, from
	/// `MIN_REFUND_DELAY` to `MAX_REFUND_DELAY`.
	#[pina(validate(
		value >= MIN_REFUND_DELAY && value <= MAX_REFUND_DELAY,
		error = EscrowError::InvalidRefundDelay
	))]
	pub refund_delay: u32,
}

/// The cross-field rules decoding enforces: a real arbiter, a budget that
/// fits in a `u64`, and a refund time that fits in an `i64`. Rules that need
/// the clock or the creator's key run in the handler.
fn validate_open_escrow(value: &OpenEscrowInstructionZc) -> ProgramResult {
	if value.arbiter == Address::default() {
		return Err(EscrowError::InvalidArbiter.into());
	}
	escrow_budget(value.amount_per_payout(), value.max_payouts())?;
	refund_after(value.expires_at(), value.refund_delay())?;
	Ok(())
}

/// Data for `EscrowInstruction::ReleasePayout`.
#[instruction(discriminator = EscrowInstruction::ReleasePayout)]
pub struct ReleasePayoutInstruction {
	/// The payout index to release; must be below the escrow's
	/// `max_payouts`. The server assigns indexes, one per verified
	/// completion.
	pub index: u16,
}

/// Data for `EscrowInstruction::EndEarly`.
#[instruction(discriminator = EscrowInstruction::EndEarly)]
pub struct EndEarlyInstruction {}

/// Data for `EscrowInstruction::CloseEscrow`.
#[instruction(discriminator = EscrowInstruction::CloseEscrow)]
pub struct CloseEscrowInstruction {}

#[cfg(test)]
mod tests {
	use super::*;

	const ARBITER: Address = Address::new_from_array([2; 32]);

	/// The client-supplied terms, encoded by hand so a test can send values
	/// the decoder must reject.
	struct OpenTerms {
		arbiter: Address,
		amount_per_payout: u64,
		max_payouts: u16,
		expires_at: i64,
		refund_delay: u32,
	}

	/// The wire layout: discriminator, pool id, arbiter, then the packed
	/// little-endian terms.
	fn open_bytes(configure: impl FnOnce(&mut OpenTerms)) -> std::vec::Vec<u8> {
		let mut terms = OpenTerms {
			arbiter: ARBITER,
			amount_per_payout: 1_000_000,
			max_payouts: 100,
			expires_at: 1_700_000_000,
			refund_delay: MIN_REFUND_DELAY,
		};
		configure(&mut terms);
		let mut data = std::vec![EscrowInstruction::OpenEscrow as u8];
		data.extend_from_slice(&[7; 16]);
		data.extend_from_slice(terms.arbiter.as_ref());
		data.extend_from_slice(&terms.amount_per_payout.to_le_bytes());
		data.extend_from_slice(&terms.max_payouts.to_le_bytes());
		data.extend_from_slice(&terms.expires_at.to_le_bytes());
		data.extend_from_slice(&terms.refund_delay.to_le_bytes());
		assert_eq!(data.len(), OpenEscrowInstruction::SIZE);
		data
	}

	fn decode(data: &[u8]) -> Result<(), ProgramError> {
		OpenEscrowInstruction::try_from_bytes(data).map(|_| ())
	}

	#[test]
	fn discriminators_are_stable() {
		assert_eq!(EscrowInstruction::OpenEscrow as u8, 0);
		assert_eq!(EscrowInstruction::ReleasePayout as u8, 1);
		assert_eq!(EscrowInstruction::EndEarly as u8, 2);
		assert_eq!(EscrowInstruction::CloseEscrow as u8, 3);
	}

	#[test]
	fn valid_terms_decode() {
		assert_eq!(decode(&open_bytes(|_| {})), Ok(()));
		assert_eq!(
			decode(&open_bytes(|terms| {
				terms.max_payouts = MAX_PAYOUTS;
				terms.refund_delay = MAX_REFUND_DELAY;
				terms.amount_per_payout = u64::MAX / u64::from(MAX_PAYOUTS);
			})),
			Ok(())
		);
	}

	#[test]
	fn a_zero_payout_is_rejected() {
		assert_eq!(
			decode(&open_bytes(|terms| terms.amount_per_payout = 0)),
			Err(EscrowError::InvalidPayoutAmount.into())
		);
	}

	#[test]
	fn payout_counts_outside_one_to_max_are_rejected() {
		for max_payouts in [0, MAX_PAYOUTS + 1, u16::MAX] {
			assert_eq!(
				decode(&open_bytes(|terms| terms.max_payouts = max_payouts)),
				Err(EscrowError::InvalidMaxPayouts.into())
			);
		}
	}

	#[test]
	fn refund_delays_outside_three_to_thirty_days_are_rejected() {
		for refund_delay in [0, MIN_REFUND_DELAY - 1, MAX_REFUND_DELAY + 1, u32::MAX] {
			assert_eq!(
				decode(&open_bytes(|terms| terms.refund_delay = refund_delay)),
				Err(EscrowError::InvalidRefundDelay.into())
			);
		}
	}

	#[test]
	fn a_budget_past_u64_is_rejected() {
		assert_eq!(
			decode(&open_bytes(|terms| {
				terms.max_payouts = MAX_PAYOUTS;
				terms.amount_per_payout = u64::MAX / u64::from(MAX_PAYOUTS) + 1;
			})),
			Err(EscrowError::BudgetOverflow.into())
		);
	}

	#[test]
	fn a_refund_time_past_i64_is_rejected() {
		assert_eq!(
			decode(&open_bytes(|terms| terms.expires_at = i64::MAX)),
			Err(EscrowError::InvalidExpiry.into())
		);
	}

	#[test]
	fn an_unset_arbiter_is_rejected() {
		assert_eq!(
			decode(&open_bytes(|terms| terms.arbiter = Address::default())),
			Err(EscrowError::InvalidArbiter.into())
		);
	}

	#[test]
	fn truncated_data_is_rejected() {
		let data = open_bytes(|_| {});
		assert!(decode(&data[..data.len() - 1]).is_err());
	}
}
