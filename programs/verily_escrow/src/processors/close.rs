//! `CloseEscrow`: return what is left to the creator.

use pina::*;

use crate::ID;
use crate::errors::EscrowError;
use crate::events::EscrowClosed;
use crate::instructions::CloseEscrowInstruction;
use crate::processors::EscrowView;
use crate::processors::mint_decimals;
use crate::processors::now;
use crate::processors::token_account_for_mint;
use crate::state::RewardEscrow;

/// Accounts for `CloseEscrow`.
#[derive(Accounts, Debug)]
pub struct CloseEscrowAccounts<'a> {
	/// The escrow's creator: receives the vault's and the escrow's rent.
	#[pina(validate(signer))]
	pub creator: &'a mut AccountView,
	/// The escrow to close.
	pub escrow: &'a mut AccountView,
	/// The escrow's vault, closed here.
	pub vault: &'a mut AccountView,
	/// The creator's token account for the escrow's mint; receives the
	/// vault's whole balance.
	pub creator_token: &'a mut AccountView,
	/// The escrow's reward token.
	#[pina(validate(owner = token::ID))]
	pub mint: &'a AccountView,
	/// The SPL Token program.
	#[pina(validate(program = token::ID))]
	pub token_program: &'a AccountView,
}

impl<'a> ProcessAccountInfos<'a> for CloseEscrowAccounts<'a> {
	fn process(self, data: &[u8]) -> ProgramResult {
		CloseEscrowInstruction::try_from_bytes(data)?;
		let escrow = EscrowView::load(self.escrow)?;
		escrow.assert_creator(self.creator)?;
		escrow.assert_mint(self.mint)?;
		escrow.assert_vault(self.vault)?;
		token_account_for_mint(self.creator_token, &escrow.mint)?;
		// No payout is released from `refund_after` on, so a close from then
		// can never race a release. Before it, the creator may close only
		// once nothing is owed.
		let fully_released = escrow.released_count == escrow.max_payouts;
		if !fully_released && now()? < escrow.refund_after {
			return Err(EscrowError::EscrowStillOpen.into());
		}
		let decimals = mint_decimals(self.mint)?;
		let (_, refunded) = token_account_for_mint(self.vault, &escrow.mint)?;
		let released = self.escrow.as_account::<RewardEscrow>(&ID)?.released;

		escrow.with_signer(|signer| {
			let signers = [signer];
			if refunded > 0 {
				token::instructions::TransferChecked::new(
					self.vault,
					self.mint,
					self.creator_token,
					self.escrow,
					refunded,
					decimals,
				)
				.invoke_signed(&signers)?;
			}
			token::instructions::CloseAccount::new(self.vault, self.creator, self.escrow)
				.invoke_signed(&signers)
		})?;
		// Closing the escrow moves lamports directly, so it runs after the
		// last cross-program call. Zeroing the data keeps the closed account
		// from being read as an escrow again within this transaction.
		CloseAccountZeroed {
			account: self.escrow,
			recipient: self.creator,
			program_id: &ID,
		}
		.invoke()?;

		EscrowClosed::emit(|event| {
			event.escrow = escrow.address;
			event.pool_id = escrow.pool_id;
			event.refunded.set(refunded);
			event.released_count.set(escrow.released_count);
			event.released = released;
			Ok(())
		})
	}
}
