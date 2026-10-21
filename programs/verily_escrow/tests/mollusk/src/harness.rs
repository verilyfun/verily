//! A small, explicit harness around Mollusk.
//!
//! The harness loads the compiled program beside the real SPL Token and
//! associated token account programs, keeps every account in one store
//! between instructions, sets the cluster clock, and encodes each
//! instruction by hand from its documented layout. Every helper panics with
//! the failing step and the program logs, so a broken journey says where it
//! broke.

use std::collections::HashMap;
use std::path::PathBuf;

use base64::Engine as _;
use base64::engine::general_purpose::STANDARD as BASE64;
use mollusk_svm::Mollusk;
use mollusk_svm::MolluskContext;
use mollusk_svm::program::loader_keys::LOADER_V3;
use mollusk_svm::result::InstructionResult;
use mollusk_svm::result::ProgramResult;
use mollusk_svm::result::types::TransactionResult;
use mollusk_svm_programs_token::associated_token;
use mollusk_svm_programs_token::token;
use solana_account::Account;
use solana_instruction::AccountMeta;
use solana_instruction::Instruction;
use solana_program_error::ProgramError;
use solana_program_option::COption;
use solana_program_pack::Pack;
use solana_pubkey::Pubkey;
use solana_svm_log_collector::LogCollector;
use spl_token_interface::state::Account as TokenAccount;
use spl_token_interface::state::AccountState;
use spl_token_interface::state::Mint;
use verily_escrow::MIN_REFUND_DELAY;
use verily_escrow::RELEASED_BITMAP_BYTES;
use verily_escrow::REWARD_ESCROW_SEED;
use verily_escrow::RewardEscrow;

/// The reward escrow program under test.
pub const PROGRAM: Pubkey = verily_escrow::ID;
/// The original SPL Token program.
pub const TOKEN_PROGRAM: Pubkey = token::ID;
/// The Token-2022 program, which the escrow does not accept.
pub const TOKEN_2022_PROGRAM: Pubkey =
	Pubkey::from_str_const("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb");
/// The associated token account program.
pub const ATA_PROGRAM: Pubkey = associated_token::ID;
/// The system program.
pub const SYSTEM_PROGRAM: Pubkey = Pubkey::from_str_const("11111111111111111111111111111111");

/// Decimals of the test reward token, as USDC.
pub const DECIMALS: u8 = 6;
/// One whole reward token in atoms.
pub const TOKEN: u64 = 1_000_000;
/// One SOL in lamports.
pub const SOL: u64 = 1_000_000_000;
/// The creator's starting reward-token balance.
pub const CREATOR_FUNDS: u64 = 1_000_000 * TOKEN;
/// The cluster time every test starts at.
pub const START: i64 = 1_800_000_000;
/// One day in seconds.
pub const DAY: i64 = 86_400;

/// Instruction discriminators, encoded by hand.
const OPEN_ESCROW: u8 = 0;
const RELEASE_PAYOUT: u8 = 1;
const END_EARLY: u8 = 2;
const CLOSE_ESCROW: u8 = 3;

/// The escrow PDA for `creator` and `pool_id`, with its canonical bump.
pub fn escrow_address(creator: &Pubkey, pool_id: &[u8; 16]) -> (Pubkey, u8) {
	Pubkey::find_program_address(&[REWARD_ESCROW_SEED, creator.as_ref(), pool_id], &PROGRAM)
}

/// The classic SPL Token associated token account of `wallet` for `mint`.
pub fn ata(wallet: &Pubkey, mint: &Pubkey) -> Pubkey {
	Pubkey::find_program_address(
		&[wallet.as_ref(), TOKEN_PROGRAM.as_ref(), mint.as_ref()],
		&ATA_PROGRAM,
	)
	.0
}

/// An initialized classic SPL Token mint with no authorities.
pub fn mint_account(decimals: u8, supply: u64) -> Account {
	token::create_account_for_mint(Mint {
		mint_authority: COption::None,
		supply,
		decimals,
		is_initialized: true,
		freeze_authority: COption::None,
	})
}

/// An initialized classic SPL Token account.
pub fn token_account(mint: &Pubkey, owner: &Pubkey, amount: u64) -> Account {
	token::create_account_for_token_account(TokenAccount {
		mint: *mint,
		owner: *owner,
		amount,
		delegate: COption::None,
		state: AccountState::Initialized,
		is_native: COption::None,
		delegated_amount: 0,
		close_authority: COption::None,
	})
}

/// A wallet the system program owns, holding `lamports`.
pub fn wallet_account(lamports: u64) -> Account {
	Account::new(lamports, 0, &SYSTEM_PROGRAM)
}

/// The terms `OpenEscrow` carries in its instruction data.
#[derive(Clone, Copy, Debug)]
pub struct Terms {
	pub pool_id: [u8; 16],
	pub arbiter: Pubkey,
	pub amount_per_payout: u64,
	pub max_payouts: u16,
	pub expires_at: i64,
	pub refund_delay: u32,
}

impl Terms {
	/// The payout amount times the number of payouts.
	pub fn budget(&self) -> u64 {
		self.amount_per_payout * u64::from(self.max_payouts)
	}

	/// The expiry plus the refund delay.
	pub fn refund_after(&self) -> i64 {
		self.expires_at + i64::from(self.refund_delay)
	}

	/// `[0][pool_id; 16][arbiter; 32][amount u64][max u16][expires i64][delay u32]`.
	fn data(&self) -> Vec<u8> {
		let mut data = vec![OPEN_ESCROW];
		data.extend_from_slice(&self.pool_id);
		data.extend_from_slice(self.arbiter.as_ref());
		data.extend_from_slice(&self.amount_per_payout.to_le_bytes());
		data.extend_from_slice(&self.max_payouts.to_le_bytes());
		data.extend_from_slice(&self.expires_at.to_le_bytes());
		data.extend_from_slice(&self.refund_delay.to_le_bytes());
		data
	}
}

/// The account list and data of an `OpenEscrow`, editable before encoding.
#[derive(Clone, Debug)]
pub struct OpenEscrow {
	pub creator: Pubkey,
	pub creator_signs: bool,
	pub escrow: Pubkey,
	pub vault: Pubkey,
	pub creator_token: Pubkey,
	pub mint: Pubkey,
	pub token_program: Pubkey,
	pub associated_token_program: Pubkey,
	pub system_program: Pubkey,
	pub terms: Terms,
}

impl OpenEscrow {
	pub fn instruction(&self) -> Instruction {
		Instruction::new_with_bytes(
			PROGRAM,
			&self.terms.data(),
			vec![
				AccountMeta::new(self.creator, self.creator_signs),
				AccountMeta::new(self.escrow, false),
				AccountMeta::new(self.vault, false),
				AccountMeta::new(self.creator_token, false),
				AccountMeta::new_readonly(self.mint, false),
				AccountMeta::new_readonly(self.token_program, false),
				AccountMeta::new_readonly(self.associated_token_program, false),
				AccountMeta::new_readonly(self.system_program, false),
			],
		)
	}
}

/// The account list and data of a `ReleasePayout`.
#[derive(Clone, Debug)]
pub struct ReleasePayout {
	pub arbiter: Pubkey,
	pub arbiter_signs: bool,
	pub escrow: Pubkey,
	pub vault: Pubkey,
	pub recipient_token: Pubkey,
	pub mint: Pubkey,
	pub token_program: Pubkey,
	pub index: u16,
}

impl ReleasePayout {
	pub fn instruction(&self) -> Instruction {
		let mut data = vec![RELEASE_PAYOUT];
		data.extend_from_slice(&self.index.to_le_bytes());
		Instruction::new_with_bytes(
			PROGRAM,
			&data,
			vec![
				AccountMeta::new_readonly(self.arbiter, self.arbiter_signs),
				AccountMeta::new(self.escrow, false),
				AccountMeta::new(self.vault, false),
				AccountMeta::new(self.recipient_token, false),
				AccountMeta::new_readonly(self.mint, false),
				AccountMeta::new_readonly(self.token_program, false),
			],
		)
	}
}

/// The account list of an `EndEarly`.
#[derive(Clone, Debug)]
pub struct EndEarly {
	pub creator: Pubkey,
	pub creator_signs: bool,
	pub escrow: Pubkey,
}

impl EndEarly {
	pub fn instruction(&self) -> Instruction {
		Instruction::new_with_bytes(
			PROGRAM,
			&[END_EARLY],
			vec![
				AccountMeta::new_readonly(self.creator, self.creator_signs),
				AccountMeta::new(self.escrow, false),
			],
		)
	}
}

/// The account list of a `CloseEscrow`.
#[derive(Clone, Debug)]
pub struct CloseEscrow {
	pub creator: Pubkey,
	pub creator_signs: bool,
	pub escrow: Pubkey,
	pub vault: Pubkey,
	pub creator_token: Pubkey,
	pub mint: Pubkey,
	pub token_program: Pubkey,
}

impl CloseEscrow {
	pub fn instruction(&self) -> Instruction {
		Instruction::new_with_bytes(
			PROGRAM,
			&[CLOSE_ESCROW],
			vec![
				AccountMeta::new(self.creator, self.creator_signs),
				AccountMeta::new(self.escrow, false),
				AccountMeta::new(self.vault, false),
				AccountMeta::new(self.creator_token, false),
				AccountMeta::new_readonly(self.mint, false),
				AccountMeta::new_readonly(self.token_program, false),
			],
		)
	}
}

/// What one instruction produced.
pub struct Outcome {
	pub result: InstructionResult,
	pub logs: Vec<String>,
}

impl Outcome {
	/// Panic with the program logs unless the instruction succeeded.
	#[track_caller]
	pub fn assert_ok(&self) -> &Self {
		assert_eq!(
			self.result.program_result,
			ProgramResult::Success,
			"instruction failed; logs:\n{}",
			self.logs.join("\n")
		);
		self
	}

	/// Panic with the program logs unless the instruction failed with
	/// `error`.
	#[track_caller]
	pub fn assert_err(&self, error: impl Into<ProgramError>) {
		assert_eq!(
			self.result.program_result,
			ProgramResult::Failure(error.into()),
			"unexpected result; logs:\n{}",
			self.logs.join("\n")
		);
	}

	/// The `Program data:` records this program wrote in its own frames.
	pub fn events(&self) -> Vec<Vec<u8>> {
		program_data(&self.logs)
	}

	/// The one event this instruction emitted.
	#[track_caller]
	pub fn event(&self) -> Vec<u8> {
		let mut events = self.events();
		assert_eq!(
			events.len(),
			1,
			"expected one event; logs:\n{}",
			self.logs.join("\n")
		);
		events.remove(0)
	}
}

/// Decode the `Program data:` lines written while this program was the
/// innermost invoked program, following the runtime's invoke frames, so a
/// record another program wrote is never attributed to the escrow.
fn program_data(logs: &[String]) -> Vec<Vec<u8>> {
	let program = PROGRAM.to_string();
	let mut frames: Vec<String> = Vec::new();
	let mut records = Vec::new();
	for line in logs {
		let Some(rest) = line.strip_prefix("Program ") else {
			continue;
		};
		if let Some(data) = rest.strip_prefix("data: ") {
			if frames.last() == Some(&program) {
				let mut record = Vec::new();
				for segment in data.split(' ') {
					record.extend(BASE64.decode(segment).expect("event segments are base64"));
				}
				records.push(record);
			}
		} else if let Some((id, tail)) = rest.split_once(' ') {
			if tail.starts_with("invoke [") {
				frames.push(id.to_owned());
			} else if tail == "success" || tail.starts_with("failed") {
				frames.pop();
			}
		}
	}
	records
}

/// A copy of the decoded escrow account.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct EscrowState {
	pub creator: Pubkey,
	pub arbiter: Pubkey,
	pub mint: Pubkey,
	pub vault: Pubkey,
	pub pool_id: [u8; 16],
	pub amount_per_payout: u64,
	pub max_payouts: u16,
	pub released_count: u16,
	pub expires_at: i64,
	pub refund_after: i64,
	pub refund_delay: u32,
	pub bump: u8,
	pub released: [u8; RELEASED_BITMAP_BYTES],
}

impl EscrowState {
	/// Whether payout `index` is marked released.
	pub fn is_released(&self, index: u16) -> bool {
		self.released[usize::from(index / 8)] & (1 << (index % 8)) != 0
	}
}

/// The Mollusk context plus the accounts every journey uses.
pub struct Harness {
	context: MolluskContext<HashMap<Pubkey, Account>>,
	pub creator: Pubkey,
	pub arbiter: Pubkey,
	pub mint: Pubkey,
	pub creator_token: Pubkey,
	pub terms: Terms,
	pub escrow: Pubkey,
	pub vault: Pubkey,
}

/// The compiled program, built by `devenv shell build:escrow`.
fn program_elf() -> Vec<u8> {
	let path = std::env::var_os("VERILY_ESCROW_ARTIFACT").map_or_else(
		|| {
			PathBuf::from(env!("CARGO_MANIFEST_DIR"))
				.join("../../../../target/deploy/verily_escrow.so")
		},
		PathBuf::from,
	);
	std::fs::read(&path).unwrap_or_else(|error| {
		panic!(
			"read the compiled program at {}: {error}; build it first with `devenv shell \
			 build:escrow`, or point VERILY_ESCROW_ARTIFACT at it",
			path.display()
		)
	})
}

impl Harness {
	/// A funded creator with a reward-token balance, an arbiter, and the
	/// default terms; no escrow exists yet.
	pub fn new() -> Self {
		let mut mollusk = Mollusk::default();
		mollusk.add_program_with_loader_and_elf(&PROGRAM, &LOADER_V3, &program_elf());
		token::add_program(&mut mollusk);
		associated_token::add_program(&mut mollusk);
		mollusk.sysvars.clock.unix_timestamp = START;
		let context = mollusk.with_context(HashMap::new());

		let creator = Pubkey::new_unique();
		let arbiter = Pubkey::new_unique();
		let mint = Pubkey::new_unique();
		let creator_token = ata(&creator, &mint);
		let pool_id: [u8; 16] = Pubkey::new_unique().to_bytes()[..16]
			.try_into()
			.expect("16 bytes");
		let terms = Terms {
			pool_id,
			arbiter,
			amount_per_payout: 25 * TOKEN,
			max_payouts: 10,
			expires_at: START + 7 * DAY,
			refund_delay: MIN_REFUND_DELAY,
		};
		let (escrow, _) = escrow_address(&creator, &terms.pool_id);
		let vault = ata(&escrow, &mint);

		let mut harness = Self {
			context,
			creator,
			arbiter,
			mint,
			creator_token,
			terms,
			escrow,
			vault,
		};
		harness.set_account(creator, wallet_account(10 * SOL));
		harness.set_account(arbiter, wallet_account(SOL));
		harness.set_account(mint, mint_account(DECIMALS, CREATOR_FUNDS));
		harness.set_account(creator_token, token_account(&mint, &creator, CREATOR_FUNDS));
		harness
	}

	/// Set the cluster's Unix time.
	pub fn set_time(&mut self, unix_timestamp: i64) {
		self.context.mollusk.sysvars.clock.unix_timestamp = unix_timestamp;
	}

	/// The stored account at `address`, if any.
	pub fn account(&self, address: &Pubkey) -> Option<Account> {
		self.context.account_store.borrow().get(address).cloned()
	}

	/// Store `account` at `address`.
	pub fn set_account(&mut self, address: Pubkey, account: Account) {
		self.context
			.account_store
			.borrow_mut()
			.insert(address, account);
	}

	/// The lamports at `address`; zero when it does not exist.
	pub fn lamports(&self, address: &Pubkey) -> u64 {
		self.account(address).map_or(0, |account| account.lamports)
	}

	/// The balance of the SPL token account at `address`.
	#[track_caller]
	pub fn token_amount(&self, address: &Pubkey) -> u64 {
		let account = self.account(address).expect("token account exists");
		TokenAccount::unpack(&account.data)
			.expect("an initialized token account")
			.amount
	}

	/// Whether no account exists at `address`: closed or never created.
	pub fn is_closed(&self, address: &Pubkey) -> bool {
		self.account(address).is_none()
	}

	/// Decode the escrow account at `address`.
	#[track_caller]
	pub fn escrow_state_at(&self, address: &Pubkey) -> EscrowState {
		let account = self.account(address).expect("escrow exists");
		assert_eq!(account.owner, PROGRAM, "the escrow program owns the escrow");
		let state = RewardEscrow::try_from_bytes(&account.data).expect("a valid escrow");
		EscrowState {
			creator: state.creator,
			arbiter: state.arbiter,
			mint: state.mint,
			vault: state.vault,
			pool_id: state.pool_id,
			amount_per_payout: state.amount_per_payout(),
			max_payouts: state.max_payouts(),
			released_count: state.released_count(),
			expires_at: state.expires_at(),
			refund_after: state.refund_after(),
			refund_delay: state.refund_delay(),
			bump: state.bump,
			released: state.released,
		}
	}

	/// Decode this harness's escrow.
	#[track_caller]
	pub fn escrow_state(&self) -> EscrowState {
		self.escrow_state_at(&self.escrow)
	}

	/// A new participant's token account for the reward mint: their
	/// associated token account, existing and empty.
	pub fn participant(&mut self) -> Pubkey {
		let wallet = Pubkey::new_unique();
		let token = ata(&wallet, &self.mint);
		self.set_account(token, token_account(&self.mint, &wallet, 0));
		token
	}

	/// Run one instruction, persisting its accounts only on success.
	pub fn process(&mut self, instruction: &Instruction) -> Outcome {
		let logger = LogCollector::new_ref();
		self.context.mollusk.logger = Some(logger.clone());
		let result = self.context.process_instruction(instruction);
		self.context.mollusk.logger = None;
		self.collect_garbage();
		let logs = logger.borrow().get_recorded_content().to_vec();
		Outcome { result, logs }
	}

	/// Run `instructions` as one transaction, persisting its accounts only on
	/// success.
	pub fn process_transaction(
		&mut self,
		instructions: &[Instruction],
	) -> (TransactionResult, Vec<String>) {
		let logger = LogCollector::new_ref();
		self.context.mollusk.logger = Some(logger.clone());
		let result = self
			.context
			.process_transaction_instructions(instructions, None);
		self.context.mollusk.logger = None;
		self.collect_garbage();
		let logs = logger.borrow().get_recorded_content().to_vec();
		(result, logs)
	}

	/// Drop accounts left with no lamports, as the runtime does once a
	/// transaction ends, so a closed account reads as absent.
	fn collect_garbage(&mut self) {
		self.context
			.account_store
			.borrow_mut()
			.retain(|_, account| account.lamports > 0);
	}

	/// The default `OpenEscrow` for this harness's creator and terms.
	pub fn open_escrow(&self) -> OpenEscrow {
		OpenEscrow {
			creator: self.creator,
			creator_signs: true,
			escrow: self.escrow,
			vault: self.vault,
			creator_token: self.creator_token,
			mint: self.mint,
			token_program: TOKEN_PROGRAM,
			associated_token_program: ATA_PROGRAM,
			system_program: SYSTEM_PROGRAM,
			terms: self.terms,
		}
	}

	/// Open the default escrow and require success.
	#[track_caller]
	pub fn open(&mut self) -> Outcome {
		let instruction = self.open_escrow().instruction();
		let outcome = self.process(&instruction);
		outcome.assert_ok();
		outcome
	}

	/// A `ReleasePayout` of `index` to `recipient_token`, signed by the
	/// arbiter.
	pub fn release_payout(&self, index: u16, recipient_token: Pubkey) -> ReleasePayout {
		ReleasePayout {
			arbiter: self.arbiter,
			arbiter_signs: true,
			escrow: self.escrow,
			vault: self.vault,
			recipient_token,
			mint: self.mint,
			token_program: TOKEN_PROGRAM,
			index,
		}
	}

	/// Release `index` to `recipient_token` and require success.
	#[track_caller]
	pub fn release(&mut self, index: u16, recipient_token: Pubkey) -> Outcome {
		let instruction = self.release_payout(index, recipient_token).instruction();
		let outcome = self.process(&instruction);
		outcome.assert_ok();
		outcome
	}

	/// An `EndEarly` signed by the creator.
	pub fn end_early(&self) -> EndEarly {
		EndEarly {
			creator: self.creator,
			creator_signs: true,
			escrow: self.escrow,
		}
	}

	/// A `CloseEscrow` signed by the creator, refunding to the creator's
	/// token account.
	pub fn close_escrow(&self) -> CloseEscrow {
		CloseEscrow {
			creator: self.creator,
			creator_signs: true,
			escrow: self.escrow,
			vault: self.vault,
			creator_token: self.creator_token,
			mint: self.mint,
			token_program: TOKEN_PROGRAM,
		}
	}
}
