//! `EndEarly`: stop new completions before the planned expiry.

use pina::*;

use crate::ID;
use crate::events::EscrowEnded;
use crate::instructions::EndEarlyInstruction;
use crate::math::ended_expiry;
use crate::math::refund_after;
use crate::processors::EscrowView;
use crate::processors::now;
use crate::state::RewardEscrow;

/// Accounts for `EndEarly`.
#[derive(Accounts, Debug)]
pub struct EndEarlyAccounts<'a> {
	/// The escrow's creator.
	#[pina(validate(signer))]
	pub creator: &'a AccountView,
	/// The escrow to end.
	pub escrow: &'a mut AccountView,
}

impl<'a> ProcessAccountInfos<'a> for EndEarlyAccounts<'a> {
	fn process(self, data: &[u8]) -> ProgramResult {
		EndEarlyInstruction::try_from_bytes(data)?;
		let escrow = EscrowView::load(self.escrow)?;
		escrow.assert_creator(self.creator)?;
		// The expiry only ever moves earlier, and the refund time keeps the
		// full refund delay after it, so completions made before the end can
		// still be reviewed and paid. An escrow past its expiry is unchanged.
		let expires_at = ended_expiry(escrow.expires_at, now()?);
		let refund_after = refund_after(expires_at, escrow.refund_delay)?;
		{
			let mut state = self.escrow.as_account_mut::<RewardEscrow>(&ID)?;
			state.expires_at.set(expires_at);
			state.refund_after.set(refund_after);
		}

		EscrowEnded::emit(|event| {
			event.escrow = escrow.address;
			event.pool_id = escrow.pool_id;
			event.expires_at.set(expires_at);
			event.refund_after.set(refund_after);
			Ok(())
		})
	}
}
