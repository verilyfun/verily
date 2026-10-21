//! `CloseEscrow`: the creator gets back what is left, and both rents, once
//! nothing can still be paid.

use solana_program_error::ProgramError;
use solana_pubkey::Pubkey;
use verily_escrow::EscrowClosed;
use verily_escrow::EscrowError;
use verily_escrow::RELEASED_BITMAP_BYTES;

use crate::harness::CREATOR_FUNDS;
use crate::harness::CloseEscrow;
use crate::harness::DAY;
use crate::harness::DECIMALS;
use crate::harness::Harness;
use crate::harness::START;
use crate::harness::TOKEN_2022_PROGRAM;
use crate::harness::ata;
use crate::harness::mint_account;
use crate::harness::token_account;

/// An opened escrow.
fn opened() -> Harness {
	let mut harness = Harness::new();
	harness.open();
	harness
}

/// Run `close` and require it to fail with `error`, leaving the escrow and
/// its vault in place.
#[track_caller]
fn assert_rejected(harness: &mut Harness, close: &CloseEscrow, error: impl Into<ProgramError>) {
	let vault = harness.token_amount(&harness.vault);
	let outcome = harness.process(&close.instruction());
	outcome.assert_err(error);
	assert_eq!(harness.token_amount(&harness.vault), vault);
	assert!(!harness.is_closed(&harness.escrow));
}

#[test]
fn closing_before_the_refund_time_with_payouts_owed_is_rejected() {
	let mut harness = opened();
	let recipient = harness.participant();
	harness.release(0, recipient);
	let refund_after = harness.terms.refund_after();
	for now in [START, harness.terms.expires_at, refund_after - 1] {
		harness.set_time(now);
		let close = harness.close_escrow();
		assert_rejected(&mut harness, &close, EscrowError::EscrowStillOpen);
	}
}

#[test]
fn closing_from_the_refund_time_returns_the_tokens_and_both_rents() {
	let mut harness = opened();
	let recipient = harness.participant();
	harness.release(0, recipient);
	harness.release(9, recipient);
	let terms = harness.terms;
	let remaining = terms.budget() - 2 * terms.amount_per_payout;
	let rent = harness.lamports(&harness.escrow) + harness.lamports(&harness.vault);
	let creator_lamports = harness.lamports(&harness.creator);

	harness.set_time(terms.refund_after());
	let outcome = harness.process(&harness.close_escrow().instruction());
	outcome.assert_ok();
	eprintln!("CloseEscrow: {} CU", outcome.result.compute_units_consumed);

	assert_eq!(
		harness.token_amount(&harness.creator_token),
		CREATOR_FUNDS - 2 * terms.amount_per_payout
	);
	assert_eq!(harness.lamports(&harness.creator), creator_lamports + rent);
	assert!(
		harness.is_closed(&harness.escrow),
		"the escrow is closed and zeroed"
	);
	assert!(harness.is_closed(&harness.vault), "the vault is closed");

	let record = outcome.event();
	let event = EscrowClosed::try_from_bytes(&record).expect("an EscrowClosed record");
	assert_eq!(event.escrow, harness.escrow);
	assert_eq!(event.pool_id, terms.pool_id);
	assert_eq!(event.refunded(), remaining);
	assert_eq!(event.released_count(), 2);
	let mut released = [0u8; RELEASED_BITMAP_BYTES];
	released[0] = 0b0000_0001;
	released[1] = 0b0000_0010;
	assert_eq!(event.released, released);
}

#[test]
fn closing_after_every_payout_is_released_needs_no_wait() {
	let mut harness = opened();
	let recipient = harness.participant();
	for index in 0..harness.terms.max_payouts {
		harness.release(index, recipient);
	}
	let rent = harness.lamports(&harness.escrow) + harness.lamports(&harness.vault);
	let creator_lamports = harness.lamports(&harness.creator);
	let outcome = harness.process(&harness.close_escrow().instruction());
	outcome.assert_ok();
	assert_eq!(harness.lamports(&harness.creator), creator_lamports + rent);
	assert!(harness.is_closed(&harness.escrow));
	assert!(harness.is_closed(&harness.vault));
	let record = outcome.event();
	let event = EscrowClosed::try_from_bytes(&record).expect("an EscrowClosed record");
	assert_eq!(event.refunded(), 0);
	assert_eq!(event.released_count(), harness.terms.max_payouts);
}

#[test]
fn an_unpaid_escrow_refunds_its_whole_budget_and_extra_deposits() {
	let mut harness = opened();
	// Tokens anyone sent to the vault go back to the creator too.
	let mut vault = harness.account(&harness.vault).expect("vault exists");
	let donated = 5;
	let budget = harness.terms.budget();
	vault.data[64..72].copy_from_slice(&(budget + donated).to_le_bytes());
	harness.set_account(harness.vault, vault);
	harness.set_time(harness.terms.refund_after() + 30 * DAY);
	let outcome = harness.process(&harness.close_escrow().instruction());
	outcome.assert_ok();
	assert_eq!(
		harness.token_amount(&harness.creator_token),
		CREATOR_FUNDS + donated
	);
	let record = outcome.event();
	let event = EscrowClosed::try_from_bytes(&record).expect("an EscrowClosed record");
	assert_eq!(event.refunded(), budget + donated);
	assert_eq!(event.released_count(), 0);
}

#[test]
fn a_closed_escrow_pays_nothing_more_and_can_be_opened_again() {
	let mut harness = opened();
	let recipient = harness.participant();
	harness.set_time(harness.terms.refund_after());
	harness
		.process(&harness.close_escrow().instruction())
		.assert_ok();
	harness
		.process(&harness.release_payout(0, recipient).instruction())
		.assert_err(ProgramError::InvalidAccountOwner);
	// The same creator and pool can fund a fresh escrow later; its bitmap
	// starts empty, so the server never reuses a pool id across escrows.
	let mut open = harness.open_escrow();
	open.terms.expires_at = harness.terms.refund_after() + 7 * DAY;
	harness.process(&open.instruction()).assert_ok();
	assert_eq!(harness.escrow_state().released_count, 0);
}

#[test]
fn the_creator_must_sign() {
	let mut harness = opened();
	harness.set_time(harness.terms.refund_after());
	let mut close = harness.close_escrow();
	close.creator_signs = false;
	assert_rejected(&mut harness, &close, ProgramError::MissingRequiredSignature);
}

#[test]
fn only_the_creator_can_close() {
	let mut harness = opened();
	harness.set_time(harness.terms.refund_after());
	let stranger = Pubkey::new_unique();
	for signer in [harness.arbiter, stranger] {
		let mut close = harness.close_escrow();
		close.creator = signer;
		close.creator_token = ata(&signer, &harness.mint);
		harness.set_account(
			close.creator_token,
			token_account(&harness.mint, &signer, 0),
		);
		assert_rejected(&mut harness, &close, EscrowError::NotCreator);
	}
}

#[test]
fn the_refund_account_must_hold_the_escrows_mint() {
	let mut harness = opened();
	harness.set_time(harness.terms.refund_after());
	let other_mint = Pubkey::new_unique();
	harness.set_account(other_mint, mint_account(DECIMALS, 1_000));
	let mut close = harness.close_escrow();
	close.creator_token = ata(&harness.creator, &other_mint);
	harness.set_account(
		close.creator_token,
		token_account(&other_mint, &harness.creator, 0),
	);
	assert_rejected(&mut harness, &close, EscrowError::MintMismatch);
}

#[test]
fn the_mint_must_be_the_escrows() {
	let mut harness = opened();
	harness.set_time(harness.terms.refund_after());
	let other_mint = Pubkey::new_unique();
	harness.set_account(other_mint, mint_account(DECIMALS, 1_000));
	let mut close = harness.close_escrow();
	close.mint = other_mint;
	assert_rejected(&mut harness, &close, EscrowError::MintMismatch);
}

#[test]
fn the_vault_must_be_the_escrows() {
	let mut harness = opened();
	harness.set_time(harness.terms.refund_after());
	let decoy = Pubkey::new_unique();
	harness.set_account(decoy, token_account(&harness.mint, &harness.escrow, 0));
	let mut close = harness.close_escrow();
	close.vault = decoy;
	assert_rejected(&mut harness, &close, EscrowError::VaultMismatch);
}

#[test]
fn only_the_spl_token_program_is_accepted() {
	let mut harness = opened();
	harness.set_time(harness.terms.refund_after());
	for token_program in [TOKEN_2022_PROGRAM, Pubkey::new_unique()] {
		let mut close = harness.close_escrow();
		close.token_program = token_program;
		assert_rejected(&mut harness, &close, ProgramError::InvalidAccountData);
	}
}
