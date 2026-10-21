//! The schema version envelope and the reserved `Migrate` route.

use pina::PinaProgramError;
use solana_instruction::AccountMeta;
use solana_instruction::Instruction;

use crate::harness::Harness;
use crate::harness::PROGRAM;
use crate::harness::SYSTEM_PROGRAM;

/// Pina's reserved discriminator for the framework `Migrate` instruction.
const MIGRATE: u8 = 0xff;

#[test]
fn the_migrate_route_leaves_a_current_escrow_unchanged() {
	let mut harness = Harness::new();
	harness.open();
	let before = harness.account(&harness.escrow).expect("escrow exists");
	let migrate = Instruction::new_with_bytes(
		PROGRAM,
		&[MIGRATE],
		vec![
			AccountMeta::new(harness.creator, true),
			AccountMeta::new_readonly(SYSTEM_PROGRAM, false),
			AccountMeta::new(harness.escrow, false),
		],
	);
	harness.process(&migrate).assert_ok();
	assert_eq!(harness.account(&harness.escrow), Some(before));
}

#[test]
fn an_escrow_written_by_a_newer_schema_is_rejected() {
	let mut harness = Harness::new();
	harness.open();
	let recipient = harness.participant();
	let mut escrow = harness.account(&harness.escrow).expect("escrow exists");
	// The version byte follows the one-byte discriminator.
	assert_eq!(escrow.data[..2], [1, 0]);
	escrow.data[1] = 1;
	harness.set_account(harness.escrow, escrow);
	harness
		.process(&harness.release_payout(0, recipient).instruction())
		.assert_err(PinaProgramError::InvalidMigrationVersion);
	assert_eq!(harness.token_amount(&recipient), 0);
}
