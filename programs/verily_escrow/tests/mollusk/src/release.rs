//! `ReleasePayout`: one payout per index, only by the arbiter, only before
//! the refund window.

use pina::PinaProgramError;
use solana_instruction::AccountMeta;
use solana_instruction::Instruction;
use solana_program_error::ProgramError;
use solana_pubkey::Pubkey;
use verily_escrow::EscrowError;
use verily_escrow::MAX_PAYOUTS;
use verily_escrow::PayoutReleased;
use verily_escrow::RewardEscrow;

use crate::harness::ATA_PROGRAM;
use crate::harness::DAY;
use crate::harness::DECIMALS;
use crate::harness::Harness;
use crate::harness::ReleasePayout;
use crate::harness::SOL;
use crate::harness::SYSTEM_PROGRAM;
use crate::harness::TOKEN_2022_PROGRAM;
use crate::harness::TOKEN_PROGRAM;
use crate::harness::ata;
use crate::harness::mint_account;
use crate::harness::token_account;
use crate::harness::wallet_account;

/// An opened escrow and one participant ready to be paid.
fn opened() -> (Harness, Pubkey) {
	let mut harness = Harness::new();
	harness.open();
	let participant = harness.participant();
	(harness, participant)
}

/// Run `release` and require it to fail with `error` without moving tokens
/// or touching the escrow.
#[track_caller]
fn assert_rejected(harness: &mut Harness, release: &ReleasePayout, error: impl Into<ProgramError>) {
	let vault = harness.token_amount(&harness.vault);
	let state = harness.escrow_state();
	let outcome = harness.process(&release.instruction());
	outcome.assert_err(error);
	assert_eq!(harness.token_amount(&harness.vault), vault);
	assert_eq!(harness.escrow_state(), state);
}

#[test]
fn a_release_pays_one_payout_and_marks_its_index() {
	let (mut harness, recipient) = opened();
	let budget = harness.terms.budget();
	let amount = harness.terms.amount_per_payout;
	let outcome = harness.release(3, recipient);
	eprintln!(
		"ReleasePayout: {} CU",
		outcome.result.compute_units_consumed
	);

	assert_eq!(harness.token_amount(&recipient), amount);
	assert_eq!(harness.token_amount(&harness.vault), budget - amount);
	let state = harness.escrow_state();
	assert_eq!(state.released_count, 1);
	assert!(state.is_released(3));
	assert_eq!(
		state
			.released
			.iter()
			.map(|byte| byte.count_ones())
			.sum::<u32>(),
		1
	);

	let record = outcome.event();
	let event = PayoutReleased::try_from_bytes(&record).expect("a PayoutReleased record");
	assert_eq!(event.escrow, harness.escrow);
	assert_eq!(event.pool_id, harness.terms.pool_id);
	assert_eq!(event.index(), 3);
	assert_eq!(event.recipient, recipient);
	assert_eq!(event.amount(), amount);
}

#[test]
fn the_server_flow_creates_the_recipient_account_in_the_same_transaction() {
	// The server prepends an idempotent associated token account creation,
	// paid by its own fee payer, so a participant never needs SOL.
	let (mut harness, _) = opened();
	let fee_payer = Pubkey::new_unique();
	harness.set_account(fee_payer, wallet_account(SOL));
	let participant = Pubkey::new_unique();
	let recipient = ata(&participant, &harness.mint);
	let create_recipient = Instruction::new_with_bytes(
		ATA_PROGRAM,
		&[1],
		vec![
			AccountMeta::new(fee_payer, true),
			AccountMeta::new(recipient, false),
			AccountMeta::new_readonly(participant, false),
			AccountMeta::new_readonly(harness.mint, false),
			AccountMeta::new_readonly(SYSTEM_PROGRAM, false),
			AccountMeta::new_readonly(TOKEN_PROGRAM, false),
		],
	);
	let release = harness.release_payout(0, recipient).instruction();
	let (result, logs) = harness.process_transaction(&[create_recipient, release]);
	assert!(
		result.program_result.is_ok(),
		"transaction failed; logs:\n{}",
		logs.join("\n")
	);
	assert_eq!(
		harness.token_amount(&recipient),
		harness.terms.amount_per_payout
	);
	assert_eq!(
		harness.lamports(&participant),
		0,
		"the participant paid nothing"
	);
}

#[test]
fn every_payout_can_be_released_once_and_the_vault_empties() {
	let (mut harness, recipient) = opened();
	for index in 0..harness.terms.max_payouts {
		harness.release(index, recipient);
	}
	let state = harness.escrow_state();
	assert_eq!(state.released_count, state.max_payouts);
	assert_eq!(harness.token_amount(&harness.vault), 0);
	assert_eq!(harness.token_amount(&recipient), harness.terms.budget());
}

#[test]
fn a_released_index_can_never_be_paid_again() {
	let (mut harness, recipient) = opened();
	harness.release(5, recipient);
	let other = harness.participant();
	for target in [recipient, other] {
		let release = harness.release_payout(5, target);
		assert_rejected(&mut harness, &release, EscrowError::PayoutAlreadyReleased);
	}
	assert_eq!(harness.escrow_state().released_count, 1);
	assert_eq!(harness.token_amount(&other), 0);
}

#[test]
fn a_retry_of_a_paid_index_reports_it_after_the_window_closes() {
	// The payout job settles a retry by reading the bitmap; it must learn the
	// index was paid rather than only that the window closed.
	let (mut harness, recipient) = opened();
	harness.release(1, recipient);
	harness.set_time(harness.terms.refund_after());
	let release = harness.release_payout(1, recipient);
	assert_rejected(&mut harness, &release, EscrowError::PayoutAlreadyReleased);
	let release = harness.release_payout(2, recipient);
	assert_rejected(&mut harness, &release, EscrowError::ReleaseWindowClosed);
}

#[test]
fn an_index_at_or_past_the_payout_count_is_rejected() {
	let (mut harness, recipient) = opened();
	let max_payouts = harness.terms.max_payouts;
	for index in [max_payouts, max_payouts + 1, MAX_PAYOUTS, u16::MAX] {
		let release = harness.release_payout(index, recipient);
		assert_rejected(&mut harness, &release, EscrowError::PayoutIndexOutOfRange);
	}
}

#[test]
fn payouts_stop_at_the_refund_time() {
	let (mut harness, recipient) = opened();
	let refund_after = harness.terms.refund_after();

	// After the expiry but before the refund time, proof in review is paid.
	harness.set_time(harness.terms.expires_at + DAY);
	harness.release(0, recipient);
	harness.set_time(refund_after - 1);
	harness.release(1, recipient);

	for now in [refund_after, refund_after + 1, refund_after + 365 * DAY] {
		harness.set_time(now);
		let release = harness.release_payout(2, recipient);
		assert_rejected(&mut harness, &release, EscrowError::ReleaseWindowClosed);
	}
}

#[test]
fn the_arbiter_must_sign() {
	let (mut harness, recipient) = opened();
	let mut release = harness.release_payout(0, recipient);
	release.arbiter_signs = false;
	assert_rejected(
		&mut harness,
		&release,
		ProgramError::MissingRequiredSignature,
	);
}

#[test]
fn only_the_escrows_arbiter_can_release() {
	let (mut harness, recipient) = opened();
	let stranger = Pubkey::new_unique();
	for arbiter in [harness.creator, stranger, recipient] {
		let mut release = harness.release_payout(0, recipient);
		release.arbiter = arbiter;
		assert_rejected(&mut harness, &release, EscrowError::NotArbiter);
	}
}

#[test]
fn the_mint_must_be_the_escrows() {
	let (mut harness, recipient) = opened();
	let other_mint = Pubkey::new_unique();
	harness.set_account(other_mint, mint_account(DECIMALS, 1_000));
	let mut release = harness.release_payout(0, recipient);
	release.mint = other_mint;
	assert_rejected(&mut harness, &release, EscrowError::MintMismatch);
}

#[test]
fn the_recipient_account_must_hold_the_escrows_mint() {
	let (mut harness, _) = opened();
	let other_mint = Pubkey::new_unique();
	harness.set_account(other_mint, mint_account(DECIMALS, 1_000));
	let wallet = Pubkey::new_unique();
	let wrong_token = ata(&wallet, &other_mint);
	harness.set_account(wrong_token, token_account(&other_mint, &wallet, 0));
	let release = harness.release_payout(0, wrong_token);
	assert_rejected(&mut harness, &release, EscrowError::MintMismatch);
}

#[test]
fn the_recipient_must_be_an_spl_token_account() {
	let (mut harness, _) = opened();
	let not_a_token_account = Pubkey::new_unique();
	harness.set_account(not_a_token_account, wallet_account(SOL));
	let release = harness.release_payout(0, not_a_token_account);
	assert_rejected(&mut harness, &release, ProgramError::InvalidAccountData);
}

#[test]
fn a_payout_cannot_go_to_an_account_the_escrow_owns() {
	let (mut harness, _) = opened();
	// The vault itself is rejected as an aliased writable account, and any
	// other token account the escrow owns could never be emptied.
	let release = harness.release_payout(0, harness.vault);
	assert_rejected(
		&mut harness,
		&release,
		PinaProgramError::DuplicateMutableAccount,
	);
	let escrow_owned = Pubkey::new_unique();
	harness.set_account(
		escrow_owned,
		token_account(&harness.mint, &harness.escrow, 0),
	);
	let release = harness.release_payout(0, escrow_owned);
	assert_rejected(&mut harness, &release, EscrowError::InvalidRecipient);
}

#[test]
fn the_vault_must_be_the_escrows() {
	let (mut harness, recipient) = opened();
	let decoy = Pubkey::new_unique();
	harness.set_account(decoy, token_account(&harness.mint, &harness.escrow, 1_000));
	let mut release = harness.release_payout(0, recipient);
	release.vault = decoy;
	assert_rejected(&mut harness, &release, EscrowError::VaultMismatch);
}

#[test]
fn only_the_spl_token_program_is_accepted() {
	let (mut harness, recipient) = opened();
	for token_program in [TOKEN_2022_PROGRAM, SYSTEM_PROGRAM, Pubkey::new_unique()] {
		let mut release = harness.release_payout(0, recipient);
		release.token_program = token_program;
		assert_rejected(&mut harness, &release, ProgramError::InvalidAccountData);
	}
}

#[test]
fn an_escrow_copied_to_another_address_is_rejected() {
	// Valid escrow bytes owned by the program at an address that is not their
	// PDA: the stored seeds and bump do not derive it.
	let (mut harness, recipient) = opened();
	let forged = Pubkey::new_unique();
	let escrow = harness.account(&harness.escrow).expect("escrow exists");
	harness.set_account(forged, escrow);
	let mut release = harness.release_payout(0, recipient);
	release.escrow = forged;
	let outcome = harness.process(&release.instruction());
	outcome.assert_err(ProgramError::InvalidSeeds);
}

#[test]
fn an_account_the_program_does_not_own_is_rejected() {
	let (mut harness, recipient) = opened();
	let impostor = Pubkey::new_unique();
	let mut escrow = harness.account(&harness.escrow).expect("escrow exists");
	escrow.owner = Pubkey::new_unique();
	harness.set_account(impostor, escrow);
	let mut release = harness.release_payout(0, recipient);
	release.escrow = impostor;
	let outcome = harness.process(&release.instruction());
	outcome.assert_err(ProgramError::InvalidAccountOwner);
}

#[test]
fn a_stored_bump_that_does_not_derive_the_escrow_is_rejected() {
	let (mut harness, recipient) = opened();
	let mut escrow = harness.account(&harness.escrow).expect("escrow exists");
	// `bump` sits after the discriminator, version, and 176 payload bytes.
	let bump_offset = 2 + 176;
	assert_eq!(RewardEscrow::SIZE, 2 + 433);
	escrow.data[bump_offset] = escrow.data[bump_offset].wrapping_sub(1);
	harness.set_account(harness.escrow, escrow);
	let release = harness.release_payout(0, recipient);
	let outcome = harness.process(&release.instruction());
	outcome.assert_err(ProgramError::InvalidSeeds);
	// The program never signed for an address it does not own.
	assert_eq!(harness.token_amount(&recipient), 0);
}
