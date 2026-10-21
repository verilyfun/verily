//! `EndEarly`: the creator can move the expiry earlier, never later.

use solana_program_error::ProgramError;
use solana_pubkey::Pubkey;
use verily_escrow::EscrowEnded;
use verily_escrow::EscrowError;

use crate::harness::DAY;
use crate::harness::Harness;
use crate::harness::START;

/// An opened escrow.
fn opened() -> Harness {
	let mut harness = Harness::new();
	harness.open();
	harness
}

#[test]
fn ending_early_moves_the_expiry_to_now_and_keeps_the_refund_delay() {
	let mut harness = opened();
	let now = START + 2 * DAY;
	harness.set_time(now);
	let outcome = harness.process(&harness.end_early().instruction());
	outcome.assert_ok();

	let state = harness.escrow_state();
	assert_eq!(state.expires_at, now);
	assert_eq!(state.refund_after, now + i64::from(state.refund_delay));
	assert!(state.refund_after < harness.terms.refund_after());

	let record = outcome.event();
	let event = EscrowEnded::try_from_bytes(&record).expect("an EscrowEnded record");
	assert_eq!(event.escrow, harness.escrow);
	assert_eq!(event.pool_id, harness.terms.pool_id);
	assert_eq!(event.expires_at(), now);
	assert_eq!(event.refund_after(), state.refund_after);
}

#[test]
fn ending_early_never_extends_an_escrow() {
	let mut harness = opened();
	let terms = harness.terms;
	for now in [
		terms.expires_at,
		terms.expires_at + DAY,
		terms.refund_after() + 30 * DAY,
	] {
		harness.set_time(now);
		harness
			.process(&harness.end_early().instruction())
			.assert_ok();
		let state = harness.escrow_state();
		assert_eq!(state.expires_at, terms.expires_at);
		assert_eq!(state.refund_after, terms.refund_after());
	}
}

#[test]
fn ending_twice_keeps_the_earlier_end() {
	let mut harness = opened();
	harness.set_time(START + DAY);
	harness
		.process(&harness.end_early().instruction())
		.assert_ok();
	harness.set_time(START + 3 * DAY);
	harness
		.process(&harness.end_early().instruction())
		.assert_ok();
	assert_eq!(harness.escrow_state().expires_at, START + DAY);
}

#[test]
fn payouts_and_refunds_follow_the_new_refund_time() {
	let mut harness = opened();
	let recipient = harness.participant();
	harness.set_time(START + DAY);
	harness
		.process(&harness.end_early().instruction())
		.assert_ok();
	let refund_after = harness.escrow_state().refund_after;

	// Proof submitted before the end is still paid during the delay.
	harness.set_time(refund_after - 1);
	harness.release(0, recipient);
	let close = harness.close_escrow().instruction();
	harness
		.process(&close)
		.assert_err(EscrowError::EscrowStillOpen);

	harness.set_time(refund_after);
	harness
		.process(&harness.release_payout(1, recipient).instruction())
		.assert_err(EscrowError::ReleaseWindowClosed);
	harness.process(&close).assert_ok();
}

#[test]
fn the_creator_must_sign() {
	let mut harness = opened();
	let mut end = harness.end_early();
	end.creator_signs = false;
	harness
		.process(&end.instruction())
		.assert_err(ProgramError::MissingRequiredSignature);
	assert_eq!(harness.escrow_state().expires_at, harness.terms.expires_at);
}

#[test]
fn only_the_creator_can_end_an_escrow() {
	let mut harness = opened();
	for signer in [harness.arbiter, Pubkey::new_unique()] {
		let mut end = harness.end_early();
		end.creator = signer;
		harness
			.process(&end.instruction())
			.assert_err(EscrowError::NotCreator);
	}
	assert_eq!(harness.escrow_state().expires_at, harness.terms.expires_at);
}

#[test]
fn an_account_that_is_not_an_escrow_is_rejected() {
	let mut harness = opened();
	let mut end = harness.end_early();
	end.escrow = harness.vault;
	harness
		.process(&end.instruction())
		.assert_err(ProgramError::InvalidAccountOwner);
}
