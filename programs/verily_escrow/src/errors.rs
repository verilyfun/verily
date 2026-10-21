//! Program error codes.
//!
//! Every variant is returned as `ProgramError::Custom(code)`. Codes are part of
//! the public interface, so a variant's value never changes once released.
//! Each variant's doc comment is one sentence on one line because generated
//! clients use that line as the error message.

use pina::*;

/// Errors returned by the reward escrow program.
#[error]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EscrowError {
	/// The signer is not the escrow's creator.
	NotCreator = 0,
	/// The signer is not the escrow's arbiter.
	NotArbiter = 1,
	/// The mint or a token account does not hold the escrow's reward token.
	MintMismatch = 2,
	/// The vault is not the escrow's associated token account for its mint.
	VaultMismatch = 3,
	/// Each payout must be at least one token atom.
	InvalidPayoutAmount = 4,
	/// The number of payouts must be from 1 to 2048.
	InvalidMaxPayouts = 5,
	/// The refund delay must be from 3 to 30 days.
	InvalidRefundDelay = 6,
	/// The expiry must be in the future and its refund time must fit in an i64.
	InvalidExpiry = 7,
	/// The payout amount times the number of payouts does not fit in a u64.
	BudgetOverflow = 8,
	/// The arbiter must be a real key that is not the creator.
	InvalidArbiter = 9,
	/// The payout index is not below the escrow's number of payouts.
	PayoutIndexOutOfRange = 10,
	/// This payout index was already released.
	PayoutAlreadyReleased = 11,
	/// The refund window has opened, so no more payouts can be released.
	ReleaseWindowClosed = 12,
	/// The escrow can close only from its refund time or once every payout is released.
	EscrowStillOpen = 13,
	/// A payout cannot go to a token account the escrow itself owns.
	InvalidRecipient = 14,
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn codes_are_stable() {
		let codes = [
			(EscrowError::NotCreator, 0),
			(EscrowError::NotArbiter, 1),
			(EscrowError::MintMismatch, 2),
			(EscrowError::VaultMismatch, 3),
			(EscrowError::InvalidPayoutAmount, 4),
			(EscrowError::InvalidMaxPayouts, 5),
			(EscrowError::InvalidRefundDelay, 6),
			(EscrowError::InvalidExpiry, 7),
			(EscrowError::BudgetOverflow, 8),
			(EscrowError::InvalidArbiter, 9),
			(EscrowError::PayoutIndexOutOfRange, 10),
			(EscrowError::PayoutAlreadyReleased, 11),
			(EscrowError::ReleaseWindowClosed, 12),
			(EscrowError::EscrowStillOpen, 13),
			(EscrowError::InvalidRecipient, 14),
		];
		for (error, code) in codes {
			assert_eq!(ProgramError::from(error), ProgramError::Custom(code));
		}
	}
}
