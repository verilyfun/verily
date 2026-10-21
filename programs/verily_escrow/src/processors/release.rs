//! `ReleasePayout`: pay one verified completion.

use pina::*;

use crate::ID;
use crate::errors::EscrowError;
use crate::events::PayoutReleased;
use crate::instructions::ReleasePayoutInstruction;
use crate::math::is_released;
use crate::math::mark_released;
use crate::processors::EscrowView;
use crate::processors::mint_decimals;
use crate::processors::now;
use crate::processors::token_account_for_mint;
use crate::state::RewardEscrow;

/// Accounts for `ReleasePayout`.
///
/// The server prepends an idempotent creation of the recipient's associated
/// token account, paid by its own fee payer, so a participant never needs SOL
/// to be paid.
#[derive(Accounts, Debug)]
pub struct ReleasePayoutAccounts<'a> {
	/// The escrow's arbiter.
	#[pina(validate(signer))]
	pub arbiter: &'a AccountView,
	/// The escrow paying the completion.
	pub escrow: &'a mut AccountView,
	/// The escrow's vault.
	pub vault: &'a mut AccountView,
	/// The participant's token account for the escrow's mint.
	pub recipient_token: &'a mut AccountView,
	/// The escrow's reward token.
	#[pina(validate(owner = token::ID))]
	pub mint: &'a AccountView,
	/// The SPL Token program.
	#[pina(validate(program = token::ID))]
	pub token_program: &'a AccountView,
}

impl<'a> ProcessAccountInfos<'a> for ReleasePayoutAccounts<'a> {
	fn process(self, data: &[u8]) -> ProgramResult {
		let args = ReleasePayoutInstruction::try_from_bytes(data)?;
		let index = args.index.get();
		let escrow = EscrowView::load(self.escrow)?;
		if self.arbiter.address() != &escrow.arbiter {
			return Err(EscrowError::NotArbiter.into());
		}
		escrow.assert_mint(self.mint)?;
		escrow.assert_vault(self.vault)?;
		let (recipient_owner, _) = token_account_for_mint(self.recipient_token, &escrow.mint)?;
		// Tokens sent to an account the escrow owns could never leave it, and
		// the payout index would be spent without paying anyone.
		if recipient_owner == escrow.address {
			return Err(EscrowError::InvalidRecipient.into());
		}
		if index >= escrow.max_payouts {
			return Err(EscrowError::PayoutIndexOutOfRange.into());
		}
		let decimals = mint_decimals(self.mint)?;
		let now = now()?;
		{
			let mut state = self.escrow.as_account_mut::<RewardEscrow>(&ID)?;
			// A retried release of a paid index reports that first, even
			// once the window has closed, so the payout job can settle it.
			if is_released(&state.released, index) {
				return Err(EscrowError::PayoutAlreadyReleased.into());
			}
			if now >= escrow.refund_after {
				return Err(EscrowError::ReleaseWindowClosed.into());
			}
			mark_released(&mut state.released, index)?;
			let released_count = escrow
				.released_count
				.checked_add(1)
				.filter(|count| *count <= escrow.max_payouts)
				.ok_or(ProgramError::InvalidAccountData)?;
			state.released_count.set(released_count);
		}

		let recipient = *self.recipient_token.address();
		escrow.with_signer(|signer| {
			token::instructions::TransferChecked::new(
				self.vault,
				self.mint,
				self.recipient_token,
				self.escrow,
				escrow.amount_per_payout,
				decimals,
			)
			.invoke_signed(&[signer])
		})?;

		PayoutReleased::emit(|event| {
			event.escrow = escrow.address;
			event.pool_id = escrow.pool_id;
			event.index = args.index;
			event.recipient = recipient;
			event.amount.set(escrow.amount_per_payout);
			Ok(())
		})
	}
}
