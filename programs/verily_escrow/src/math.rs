//! Budget, time, and bitmap arithmetic.
//!
//! Every operation is checked: a value that does not fit is an error, never a
//! wrap or a saturation, so the stored terms always describe exactly what the
//! vault holds.

use crate::errors::EscrowError;
use crate::state::MAX_PAYOUTS;
use crate::state::RELEASED_BITMAP_BYTES;

/// The whole budget an escrow locks: `amount_per_payout × max_payouts`.
///
/// # Errors
///
/// [`EscrowError::BudgetOverflow`] when the product does not fit in a `u64`.
pub fn escrow_budget(amount_per_payout: u64, max_payouts: u16) -> Result<u64, EscrowError> {
	amount_per_payout
		.checked_mul(u64::from(max_payouts))
		.ok_or(EscrowError::BudgetOverflow)
}

/// The first Unix second at which no payout can be released and the creator
/// may close: `expires_at + refund_delay`.
///
/// # Errors
///
/// [`EscrowError::InvalidExpiry`] when the sum does not fit in an `i64`.
pub fn refund_after(expires_at: i64, refund_delay: u32) -> Result<i64, EscrowError> {
	expires_at
		.checked_add(i64::from(refund_delay))
		.ok_or(EscrowError::InvalidExpiry)
}

/// The expiry after the creator ends an escrow at `now`. It never moves
/// later, so ending an escrow can never extend it.
#[must_use]
pub const fn ended_expiry(expires_at: i64, now: i64) -> i64 {
	if now < expires_at { now } else { expires_at }
}

/// The byte and mask that hold payout `index` in the released bitmap, or
/// `None` when `index` is outside the bitmap.
#[must_use]
pub const fn released_bit(index: u16) -> Option<(usize, u8)> {
	if index >= MAX_PAYOUTS {
		return None;
	}
	let byte = (index / 8) as usize;
	if byte >= RELEASED_BITMAP_BYTES {
		return None;
	}
	Some((byte, 1 << (index % 8)))
}

/// Whether payout `index` is marked released in `bitmap`. An index outside
/// the bitmap is never released.
#[must_use]
pub fn is_released(bitmap: &[u8; RELEASED_BITMAP_BYTES], index: u16) -> bool {
	released_bit(index).is_some_and(|(byte, mask)| bitmap[byte] & mask != 0)
}

/// Mark payout `index` released in `bitmap`.
///
/// # Errors
///
/// [`EscrowError::PayoutIndexOutOfRange`] when `index` is outside the bitmap,
/// and [`EscrowError::PayoutAlreadyReleased`] when its bit is already set, so a
/// payout index can be released at most once.
pub fn mark_released(
	bitmap: &mut [u8; RELEASED_BITMAP_BYTES],
	index: u16,
) -> Result<(), EscrowError> {
	let (byte, mask) = released_bit(index).ok_or(EscrowError::PayoutIndexOutOfRange)?;
	if bitmap[byte] & mask != 0 {
		return Err(EscrowError::PayoutAlreadyReleased);
	}
	bitmap[byte] |= mask;
	Ok(())
}

#[cfg(test)]
mod tests {
	use super::*;
	use crate::state::MAX_REFUND_DELAY;

	#[test]
	fn the_budget_is_the_product_of_the_terms() {
		assert_eq!(escrow_budget(1_000_000, 2_048), Ok(2_048_000_000));
		assert_eq!(escrow_budget(1, 1), Ok(1));
		assert_eq!(escrow_budget(u64::MAX, 1), Ok(u64::MAX));
	}

	#[test]
	fn a_budget_past_u64_overflows() {
		assert_eq!(escrow_budget(u64::MAX, 2), Err(EscrowError::BudgetOverflow));
		assert_eq!(
			escrow_budget(u64::MAX / 2_048 + 1, 2_048),
			Err(EscrowError::BudgetOverflow)
		);
		assert_eq!(
			escrow_budget(u64::MAX / 2_048, 2_048),
			Ok(u64::MAX / 2_048 * 2_048)
		);
	}

	#[test]
	fn the_refund_time_is_the_delay_after_the_expiry() {
		assert_eq!(refund_after(1_000, 259_200), Ok(260_200));
		assert_eq!(
			refund_after(i64::MAX - i64::from(MAX_REFUND_DELAY), MAX_REFUND_DELAY),
			Ok(i64::MAX)
		);
	}

	#[test]
	fn a_refund_time_past_i64_is_rejected() {
		assert_eq!(
			refund_after(i64::MAX - i64::from(MAX_REFUND_DELAY) + 1, MAX_REFUND_DELAY),
			Err(EscrowError::InvalidExpiry)
		);
	}

	#[test]
	fn ending_never_extends_the_expiry() {
		assert_eq!(ended_expiry(1_000, 400), 400);
		assert_eq!(ended_expiry(1_000, 1_000), 1_000);
		assert_eq!(ended_expiry(1_000, 5_000), 1_000);
	}

	#[test]
	fn every_index_maps_to_its_own_bit() {
		assert_eq!(released_bit(0), Some((0, 0b0000_0001)));
		assert_eq!(released_bit(7), Some((0, 0b1000_0000)));
		assert_eq!(released_bit(8), Some((1, 0b0000_0001)));
		assert_eq!(released_bit(MAX_PAYOUTS - 1), Some((255, 0b1000_0000)));
		assert_eq!(released_bit(MAX_PAYOUTS), None);
		assert_eq!(released_bit(u16::MAX), None);
	}

	#[test]
	fn an_index_is_released_once() {
		let mut bitmap = [0u8; RELEASED_BITMAP_BYTES];
		for index in [0, 7, 8, 1_000, MAX_PAYOUTS - 1] {
			assert!(!is_released(&bitmap, index));
			assert_eq!(mark_released(&mut bitmap, index), Ok(()));
			assert!(is_released(&bitmap, index));
			assert_eq!(
				mark_released(&mut bitmap, index),
				Err(EscrowError::PayoutAlreadyReleased)
			);
		}
		assert_eq!(bitmap.iter().map(|byte| byte.count_ones()).sum::<u32>(), 5);
		assert!(!is_released(&bitmap, 1));
	}

	#[test]
	fn an_index_outside_the_bitmap_is_rejected() {
		let mut bitmap = [0u8; RELEASED_BITMAP_BYTES];
		assert_eq!(
			mark_released(&mut bitmap, MAX_PAYOUTS),
			Err(EscrowError::PayoutIndexOutOfRange)
		);
		assert!(!is_released(&bitmap, MAX_PAYOUTS));
		assert_eq!(bitmap, [0u8; RELEASED_BITMAP_BYTES]);
	}
}
