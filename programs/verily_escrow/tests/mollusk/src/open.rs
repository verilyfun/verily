//! `OpenEscrow`: funding, the vault, and every rejected term or account.

use pina::PinaProgramError;
use solana_program_error::ProgramError;
use solana_pubkey::Pubkey;
use verily_escrow::EscrowError;
use verily_escrow::EscrowOpened;
use verily_escrow::MAX_PAYOUTS;
use verily_escrow::MAX_REFUND_DELAY;
use verily_escrow::MIN_REFUND_DELAY;
use verily_escrow::RELEASED_BITMAP_BYTES;
use verily_escrow::RewardEscrow;

use crate::harness::ATA_PROGRAM;
use crate::harness::CREATOR_FUNDS;
use crate::harness::DAY;
use crate::harness::DECIMALS;
use crate::harness::Harness;
use crate::harness::OpenEscrow;
use crate::harness::PROGRAM;
use crate::harness::START;
use crate::harness::TOKEN;
use crate::harness::TOKEN_2022_PROGRAM;
use crate::harness::TOKEN_PROGRAM;
use crate::harness::ata;
use crate::harness::escrow_address;
use crate::harness::mint_account;
use crate::harness::token_account;

/// Run `open` and require it to fail with `error`, leaving no escrow and the
/// creator's balance untouched.
#[track_caller]
fn assert_rejected(harness: &mut Harness, open: &OpenEscrow, error: impl Into<ProgramError>) {
	let outcome = harness.process(&open.instruction());
	outcome.assert_err(error);
	assert!(harness.is_closed(&open.escrow), "no escrow was created");
	assert_eq!(harness.token_amount(&harness.creator_token), CREATOR_FUNDS);
}

#[test]
fn opening_locks_the_whole_budget_in_the_vault() {
	let mut harness = Harness::new();
	let creator_lamports = harness.lamports(&harness.creator);
	let outcome = harness.open();
	eprintln!("OpenEscrow: {} CU", outcome.result.compute_units_consumed);

	let terms = harness.terms;
	let budget = terms.budget();
	assert_eq!(budget, 250 * TOKEN);
	assert_eq!(harness.token_amount(&harness.vault), budget);
	assert_eq!(
		harness.token_amount(&harness.creator_token),
		CREATOR_FUNDS - budget
	);

	let (_, bump) = escrow_address(&harness.creator, &terms.pool_id);
	let state = harness.escrow_state();
	assert_eq!(state.creator, harness.creator);
	assert_eq!(state.arbiter, harness.arbiter);
	assert_eq!(state.mint, harness.mint);
	assert_eq!(state.vault, harness.vault);
	assert_eq!(state.pool_id, terms.pool_id);
	assert_eq!(state.amount_per_payout, terms.amount_per_payout);
	assert_eq!(state.max_payouts, terms.max_payouts);
	assert_eq!(state.released_count, 0);
	assert_eq!(state.expires_at, terms.expires_at);
	assert_eq!(state.refund_after, terms.refund_after());
	assert_eq!(
		state.refund_after - state.expires_at,
		i64::from(MIN_REFUND_DELAY)
	);
	assert_eq!(state.refund_delay, terms.refund_delay);
	assert_eq!(state.bump, bump, "the escrow stores its canonical bump");
	assert_eq!(state.released, [0; RELEASED_BITMAP_BYTES]);

	// The vault is the escrow PDA's own token account.
	let vault = harness.account(&harness.vault).expect("vault exists");
	assert_eq!(vault.owner, TOKEN_PROGRAM);
	let escrow = harness.account(&harness.escrow).expect("escrow exists");
	assert_eq!(escrow.data.len(), RewardEscrow::SIZE);
	// The creator paid both rents.
	assert_eq!(
		harness.lamports(&harness.creator),
		creator_lamports - escrow.lamports - vault.lamports
	);

	let record = outcome.event();
	let event = EscrowOpened::try_from_bytes(&record).expect("an EscrowOpened record");
	assert_eq!(event.escrow, harness.escrow);
	assert_eq!(event.creator, harness.creator);
	assert_eq!(event.arbiter, harness.arbiter);
	assert_eq!(event.mint, harness.mint);
	assert_eq!(event.vault, harness.vault);
	assert_eq!(event.pool_id, terms.pool_id);
	assert_eq!(event.amount_per_payout(), terms.amount_per_payout);
	assert_eq!(event.max_payouts(), terms.max_payouts);
	assert_eq!(event.expires_at(), terms.expires_at);
	assert_eq!(event.refund_after(), terms.refund_after());
}

#[test]
fn the_largest_budget_and_longest_delay_are_accepted() {
	let mut harness = Harness::new();
	let mut open = harness.open_escrow();
	open.terms.max_payouts = MAX_PAYOUTS;
	open.terms.amount_per_payout = 1;
	open.terms.refund_delay = MAX_REFUND_DELAY;
	harness.process(&open.instruction()).assert_ok();
	let state = harness.escrow_state();
	assert_eq!(state.max_payouts, MAX_PAYOUTS);
	assert_eq!(
		state.refund_after,
		open.terms.expires_at + i64::from(MAX_REFUND_DELAY)
	);
	assert_eq!(harness.token_amount(&harness.vault), u64::from(MAX_PAYOUTS));
}

#[test]
fn a_vault_someone_created_first_is_reused() {
	// Anyone can derive and create the escrow's vault before it opens. That
	// front-run must not block the escrow, and tokens already in it stay.
	let mut harness = Harness::new();
	harness.set_account(
		harness.vault,
		token_account(&harness.mint, &harness.escrow, 7),
	);
	harness.open();
	assert_eq!(
		harness.token_amount(&harness.vault),
		harness.terms.budget() + 7
	);
}

#[test]
fn the_creator_must_sign() {
	let mut harness = Harness::new();
	let mut open = harness.open_escrow();
	open.creator_signs = false;
	assert_rejected(&mut harness, &open, ProgramError::MissingRequiredSignature);
}

#[test]
fn an_escrow_cannot_be_opened_twice() {
	let mut harness = Harness::new();
	harness.open();
	let outcome = harness.process(&harness.open_escrow().instruction());
	outcome.assert_err(ProgramError::AccountAlreadyInitialized);
	assert_eq!(harness.token_amount(&harness.vault), harness.terms.budget());
}

#[test]
fn the_escrow_must_be_the_creators_pda_for_the_pool() {
	let mut harness = Harness::new();
	// Another pool's PDA, a random address, and the PDA of another creator.
	let other_pool = escrow_address(&harness.creator, &[9; 16]).0;
	let other_creator = escrow_address(&Pubkey::new_unique(), &harness.terms.pool_id).0;
	for escrow in [other_pool, Pubkey::new_unique(), other_creator] {
		let mut open = harness.open_escrow();
		open.escrow = escrow;
		open.vault = ata(&escrow, &harness.mint);
		assert_rejected(&mut harness, &open, ProgramError::InvalidSeeds);
	}
}

#[test]
fn the_vault_must_be_the_escrows_associated_token_account() {
	let mut harness = Harness::new();
	let creator_ata = ata(&harness.creator, &harness.mint);
	let other_mint_ata = ata(&harness.escrow, &Pubkey::new_unique());
	for vault in [Pubkey::new_unique(), creator_ata, other_mint_ata] {
		let mut open = harness.open_escrow();
		open.vault = vault;
		if vault == creator_ata {
			// Distinct from the funding account, so only the address is wrong.
			open.creator_token = Pubkey::new_unique();
			harness.set_account(
				open.creator_token,
				token_account(&harness.mint, &harness.creator, CREATOR_FUNDS),
			);
		}
		let outcome = harness.process(&open.instruction());
		outcome.assert_err(EscrowError::VaultMismatch);
	}
}

#[test]
fn the_funding_account_must_hold_the_mint() {
	let mut harness = Harness::new();
	let other_mint = Pubkey::new_unique();
	harness.set_account(other_mint, mint_account(DECIMALS, CREATOR_FUNDS));
	let other_token = ata(&harness.creator, &other_mint);
	harness.set_account(
		other_token,
		token_account(&other_mint, &harness.creator, CREATOR_FUNDS),
	);
	let mut open = harness.open_escrow();
	open.creator_token = other_token;
	assert_rejected(&mut harness, &open, EscrowError::MintMismatch);
}

#[test]
fn a_token_2022_mint_is_rejected() {
	let mut harness = Harness::new();
	let mint = Pubkey::new_unique();
	let mut account = mint_account(DECIMALS, CREATOR_FUNDS);
	account.owner = TOKEN_2022_PROGRAM;
	harness.set_account(mint, account);
	let mut open = harness.open_escrow();
	open.mint = mint;
	open.vault = ata(&harness.escrow, &mint);
	assert_rejected(&mut harness, &open, ProgramError::InvalidAccountOwner);
}

#[test]
fn only_the_spl_token_program_is_accepted() {
	let mut harness = Harness::new();
	for token_program in [TOKEN_2022_PROGRAM, Pubkey::new_unique(), ATA_PROGRAM] {
		let mut open = harness.open_escrow();
		open.token_program = token_program;
		assert_rejected(&mut harness, &open, ProgramError::InvalidAccountData);
	}
}

#[test]
fn the_associated_token_and_system_programs_are_checked() {
	let mut harness = Harness::new();
	let mut open = harness.open_escrow();
	open.associated_token_program = TOKEN_PROGRAM;
	assert_rejected(&mut harness, &open, ProgramError::InvalidAccountData);
	let mut open = harness.open_escrow();
	open.system_program = PROGRAM;
	assert_rejected(&mut harness, &open, ProgramError::InvalidAccountData);
}

#[test]
fn a_payout_must_be_at_least_one_atom() {
	let mut harness = Harness::new();
	let mut open = harness.open_escrow();
	open.terms.amount_per_payout = 0;
	assert_rejected(&mut harness, &open, EscrowError::InvalidPayoutAmount);
}

#[test]
fn the_payout_count_must_be_from_one_to_max() {
	let mut harness = Harness::new();
	for max_payouts in [0, MAX_PAYOUTS + 1, u16::MAX] {
		let mut open = harness.open_escrow();
		open.terms.max_payouts = max_payouts;
		assert_rejected(&mut harness, &open, EscrowError::InvalidMaxPayouts);
	}
}

#[test]
fn the_refund_delay_must_be_from_three_to_thirty_days() {
	let mut harness = Harness::new();
	for refund_delay in [0, MIN_REFUND_DELAY - 1, MAX_REFUND_DELAY + 1, u32::MAX] {
		let mut open = harness.open_escrow();
		open.terms.refund_delay = refund_delay;
		assert_rejected(&mut harness, &open, EscrowError::InvalidRefundDelay);
	}
}

#[test]
fn a_budget_that_overflows_u64_is_rejected() {
	let mut harness = Harness::new();
	let mut open = harness.open_escrow();
	open.terms.max_payouts = 2;
	open.terms.amount_per_payout = u64::MAX / 2 + 1;
	assert_rejected(&mut harness, &open, EscrowError::BudgetOverflow);
}

#[test]
fn a_budget_beyond_the_creators_balance_fails_in_the_token_program() {
	let mut harness = Harness::new();
	let mut open = harness.open_escrow();
	open.terms.amount_per_payout = CREATOR_FUNDS / u64::from(open.terms.max_payouts) + 1;
	// SPL Token's `InsufficientFunds`.
	assert_rejected(&mut harness, &open, ProgramError::Custom(1));
}

#[test]
fn the_expiry_must_be_in_the_future() {
	let mut harness = Harness::new();
	for expires_at in [START, START - DAY, i64::MIN] {
		let mut open = harness.open_escrow();
		open.terms.expires_at = expires_at;
		assert_rejected(&mut harness, &open, EscrowError::InvalidExpiry);
	}
}

#[test]
fn a_refund_time_that_overflows_i64_is_rejected() {
	let mut harness = Harness::new();
	let mut open = harness.open_escrow();
	open.terms.expires_at = i64::MAX - i64::from(open.terms.refund_delay) + 1;
	assert_rejected(&mut harness, &open, EscrowError::InvalidExpiry);
}

#[test]
fn the_arbiter_must_be_a_real_key_other_than_the_creator() {
	let mut harness = Harness::new();
	for arbiter in [Pubkey::default(), harness.creator] {
		let mut open = harness.open_escrow();
		open.terms.arbiter = arbiter;
		assert_rejected(&mut harness, &open, EscrowError::InvalidArbiter);
	}
}

#[test]
fn the_vault_cannot_double_as_the_funding_account() {
	let mut harness = Harness::new();
	let mut open = harness.open_escrow();
	open.creator_token = open.vault;
	let outcome = harness.process(&open.instruction());
	outcome.assert_err(PinaProgramError::DuplicateMutableAccount);
}
