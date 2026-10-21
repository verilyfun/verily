//! `OpenEscrow`: lock a reward budget before anyone works for it.

use pina::*;

use crate::ID;
use crate::errors::EscrowError;
use crate::events::EscrowOpened;
use crate::instructions::OpenEscrowInstruction;
use crate::math::escrow_budget;
use crate::math::refund_after;
use crate::processors::mint_decimals;
use crate::processors::now;
use crate::processors::token_account_for_mint;
use crate::state::RewardEscrow;

/// Accounts for `OpenEscrow`.
#[derive(Accounts, Debug)]
pub struct OpenEscrowAccounts<'a> {
	/// The creator: pays the escrow's and the vault's rent and funds the
	/// budget from `creator_token`.
	#[pina(validate(signer))]
	pub creator: &'a mut AccountView,
	/// The escrow PDA to create: `[b"reward-escrow", creator, pool_id]`.
	pub escrow: &'a mut AccountView,
	/// The vault: the escrow PDA's associated token account for `mint`,
	/// created here if it does not exist yet.
	pub vault: &'a mut AccountView,
	/// The creator's token account the budget is drawn from.
	pub creator_token: &'a mut AccountView,
	/// The reward token: a classic SPL Token mint.
	#[pina(validate(owner = token::ID))]
	pub mint: &'a AccountView,
	/// The SPL Token program.
	#[pina(validate(program = token::ID))]
	pub token_program: &'a AccountView,
	/// The associated token account program.
	#[pina(validate(program = associated_token_account::ID))]
	pub associated_token_program: &'a AccountView,
	/// The system program.
	#[pina(validate(program = system::ID))]
	pub system_program: &'a AccountView,
}

impl<'a> ProcessAccountInfos<'a> for OpenEscrowAccounts<'a> {
	fn process(self, data: &[u8]) -> ProgramResult {
		// Decoding already bounded the payout amount, the payout count, and
		// the refund delay, and checked that the budget and the refund time
		// fit their types and that the arbiter is set.
		let args = OpenEscrowInstruction::try_from_bytes(data)?;
		let creator = *self.creator.address();
		if args.arbiter == creator {
			return Err(EscrowError::InvalidArbiter.into());
		}
		let expires_at = args.expires_at.get();
		if expires_at <= now()? {
			return Err(EscrowError::InvalidExpiry.into());
		}
		let amount_per_payout = args.amount_per_payout.get();
		let max_payouts = args.max_payouts.get();
		let refund_delay = args.refund_delay.get();
		let refund_after = refund_after(expires_at, refund_delay)?;
		let budget = escrow_budget(amount_per_payout, max_payouts)?;

		let mint = *self.mint.address();
		let decimals = mint_decimals(self.mint)?;
		token_account_for_mint(self.creator_token, &mint)?;
		// The escrow's own address is proven when it is created below; the
		// vault must be that address's associated token account before any
		// account is created or funded.
		let escrow = *self.escrow.address();
		let vault = *self.vault.address();
		self.vault
			.assert_associated_token_address(&escrow, &mint, &token::ID)
			.map_err(|_| EscrowError::VaultMismatch)?;

		CreateProgramAccount {
			account: self.escrow,
			payer: self.creator,
			owner: &ID,
			seeds: &RewardEscrow::seeds(&creator, args.pool_id).as_slices(),
		}
		.invoke_with_bump::<RewardEscrow>(|state, bump| {
			state.creator = creator;
			state.arbiter = args.arbiter;
			state.mint = mint;
			state.vault = vault;
			state.pool_id = args.pool_id;
			state.amount_per_payout = args.amount_per_payout;
			state.max_payouts = args.max_payouts;
			state.expires_at = args.expires_at;
			state.refund_after.set(refund_after);
			state.refund_delay = args.refund_delay;
			state.bump = bump;
			Ok(())
		})?;
		// Anyone can derive the vault and create it first, so creation must be
		// idempotent or a front-run would block this escrow forever. The
		// associated token account program accepts an existing account only
		// when it is this address's SPL Token account for `mint`, owned by the
		// escrow PDA, which only this program can sign for.
		associated_token_account::instructions::CreateIdempotent {
			funding_account: self.creator,
			account: self.vault,
			wallet: self.escrow,
			mint: self.mint,
			system_program: self.system_program,
			token_program: self.token_program,
		}
		.invoke()?;
		token::instructions::TransferChecked::new(
			self.creator_token,
			self.mint,
			self.vault,
			self.creator,
			budget,
			decimals,
		)
		.invoke()?;

		EscrowOpened::emit(|event| {
			event.escrow = escrow;
			event.creator = creator;
			event.arbiter = args.arbiter;
			event.mint = mint;
			event.vault = vault;
			event.pool_id = args.pool_id;
			event.amount_per_payout = args.amount_per_payout;
			event.max_payouts = args.max_payouts;
			event.expires_at = args.expires_at;
			event.refund_after.set(refund_after);
			Ok(())
		})
	}
}
