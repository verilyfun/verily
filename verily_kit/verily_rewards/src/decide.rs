//! Pure funding, publish, review, and release decisions.
//!
//! Chain bytes are decoded here. Nothing in this module opens a socket or
//! treats a signature as proof that an escrow is funded.

use solana_kit_associated_token_account::{AssociatedTokenSeeds, TOKEN_PROGRAM};
use solana_kit_core::Address;
use solana_kit_core::crypto::find_program_address;
use verily_shared::{ActionAuthoringProblem, RewardPoolStatus};

use crate::gateway::RawAccount;

/// Account discriminator for `RewardEscrow`.
pub const ESCROW_DISCRIMINATOR: u8 = 1;
/// Schema version of the 435-byte layout.
pub const ESCROW_SCHEMA_VERSION: u8 = 1;
/// Packed size of a reward escrow account.
pub const ESCROW_ACCOUNT_LEN: usize = 435;
/// SPL token account size.
pub const TOKEN_ACCOUNT_LEN: usize = 165;
/// SPL mint account size.
pub const MINT_ACCOUNT_LEN: usize = 82;
/// The most payouts one escrow can hold.
pub const MAX_PAYOUTS: u16 = 2_048;
/// One payout is at most 1,000,000 USDC atoms.
pub const MAX_AMOUNT_PER_PAYOUT_ATOMS: i64 = 1_000_000_000_000;
/// Wins one account can take from one pool.
pub const MAX_WINS_PER_ACCOUNT: i64 = 365;
/// Shortest refund delay, in days.
pub const MIN_REFUND_DELAY_DAYS: i64 = 3;
/// Longest refund delay, in days.
pub const MAX_REFUND_DELAY_DAYS: i64 = 30;
pub(crate) const MIN_REFUND_DELAY_SECONDS: u32 = 3 * 24 * 60 * 60;
const MAX_REFUND_DELAY_SECONDS: u32 = 30 * 24 * 60 * 60;
const RELEASED_BITMAP_LEN: usize = 256;

const CREATOR: usize = 2;
const ARBITER: usize = 34;
const MINT: usize = 66;
const VAULT: usize = 98;
const POOL: usize = 130;
const AMOUNT: usize = 146;
const MAX_PAYOUTS_AT: usize = 154;
const RELEASED_COUNT_AT: usize = 156;
const EXPIRES: usize = 158;
const REFUND_AFTER: usize = 166;
const REFUND_DELAY: usize = 174;
const BUMP: usize = 178;
const BITMAP: usize = 179;

/// What the server expects the finalized escrow to say.
#[derive(Clone, Copy, Debug)]
pub struct ExpectedEscrow {
	/// Escrow program.
	pub program: Address,
	/// Creator wallet that funded the escrow.
	pub creator: Address,
	/// Verily's arbiter.
	pub arbiter: Address,
	/// Reward mint.
	pub mint: Address,
	/// Pool id bytes, the same UUID the row stores.
	pub pool_id: [u8; 16],
	/// Atoms paid for one index.
	pub amount_per_payout: u64,
	/// How many indexes the escrow funds.
	pub max_payouts: u16,
	/// Unix seconds after which new completions stop.
	pub expires_at: i64,
	/// Unix seconds when the refund window opens.
	pub refund_after: i64,
	/// Seconds between expiry and the refund window.
	pub refund_delay: u32,
}

/// A decoded escrow account.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct DecodedEscrow {
	/// Creator wallet.
	pub creator: Address,
	/// Arbiter.
	pub arbiter: Address,
	/// Mint.
	pub mint: Address,
	/// Vault token account.
	pub vault: Address,
	/// Pool id.
	pub pool_id: [u8; 16],
	/// Atoms per index.
	pub amount_per_payout: u64,
	/// Funded indexes.
	pub max_payouts: u16,
	/// Indexes already released.
	pub released_count: u16,
	/// Expiry, unix seconds.
	pub expires_at: i64,
	/// Refund window, unix seconds.
	pub refund_after: i64,
	/// Refund delay, seconds.
	pub refund_delay: u32,
	/// Canonical bump stored on the account.
	pub bump: u8,
	/// Released bitmap.
	pub released: [u8; 256],
}

/// Why a chain read is not this pool's funded escrow.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FundingMismatch {
	/// Stable field names. Empty means the read matched.
	pub fields: Vec<&'static str>,
}

impl FundingMismatch {
	/// Whether the read failed.
	#[must_use]
	pub fn failed(&self) -> bool {
		!self.fields.is_empty()
	}
}

/// Why a release did not pay.
#[derive(Clone, Copy, Debug, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ReleaseCode {
	/// The bit is set at confirmed and not yet at finalized.
	ReleasePendingFinality,
	/// Sent, and not confirmed within the wait.
	ReleaseUnconfirmed,
	/// The blockhash can no longer land.
	BlockhashExpired,
	/// The fee payer cannot pay fees or rent.
	FeePayerUnderfunded,
	/// The recipient token account could not be created.
	RecipientAccountFailed,
	/// The RPC endpoint did not answer.
	RpcUnavailable,
	/// The RPC answer was not a usable account.
	RpcInvalidResponse,
	/// No signer is configured, or it could not sign.
	SignerUnavailable,
	/// Fewer releases on chain than the server recorded.
	EscrowReplaced,
	/// The refund window has opened.
	RefundWindowReached,
	/// The escrow account is gone.
	EscrowClosed,
	/// The account is not this pool.
	EscrowMismatch,
	/// The arbiter is not Verily's.
	ArbiterMismatch,
	/// The recipient wallet is not a usable address.
	InvalidRecipient,
	/// The index is outside the escrow.
	PayoutIndexOutOfRange,
	/// The vault or recipient token account is frozen.
	TokenAccountFrozen,
	/// The vault cannot cover the payout.
	VaultUnderfunded,
	/// The token program refused the transfer.
	TokenTransferFailed,
	/// Any other rejection.
	ReleaseRejected,
}

/// The only release result this crate produces.
///
/// [`ReleaseOutcome::AlreadyReleased`] is the finalized bitmap. A signature
/// becomes a release only through [`confirmed_release_signature`], which
/// refuses a `local-dev-` prefix and an unconfirmed signature.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ReleaseOutcome {
	/// Finalized chain state already has this index set.
	AlreadyReleased,
	/// The payout was not released.
	Failed {
		/// Stable code. No RPC text.
		code: ReleaseCode,
		/// Whether the same index may be tried again.
		retryable: bool,
	},
}

/// Inputs for one release decision.
#[derive(Clone, Debug)]
pub struct ReleaseInput {
	/// Terms stored for the pool.
	pub expected: ExpectedEscrow,
	/// Finalized escrow account, when the RPC returned one.
	pub finalized: Option<RawAccount>,
	/// Confirmed escrow account, when a finality check needs it.
	pub confirmed: Option<RawAccount>,
	/// Finalized vault account.
	pub vault: Option<RawAccount>,
	/// Address the server derived and read.
	pub escrow_address: Address,
	/// Index already stored for this attempt.
	pub index: u16,
	/// Releases the server has already settled for the pool.
	pub recorded_released: u16,
	/// Unix seconds used for the refund window.
	pub now_unix: i64,
	/// Whether a signer is configured. A signer alone is not a release.
	pub signer_available: bool,
}

/// A signature is a release only when chain confirmation says so.
///
/// A `local-dev-` prefix is never accepted.
#[must_use]
pub fn confirmed_release_signature(signature: &str, confirmed_by_chain: bool) -> Option<&str> {
	if !confirmed_by_chain || signature.is_empty() || signature.starts_with("local-dev-") {
		return None;
	}
	Some(signature)
}

/// Whether a payout must wait for a person.
///
/// A missing or negative threshold blocks release. Zero means every positive
/// payout waits. Acceptance is ignored when the amount is within the threshold.
#[must_use]
pub fn review_blocks_release(
	amount_atoms: i64,
	threshold_atoms: Option<i64>,
	accepted: bool,
) -> bool {
	match verily_shared::payout_needs_person(amount_atoms, threshold_atoms) {
		Some(true) => !accepted,
		Some(false) => false,
		None => true,
	}
}

/// Publish is refused while the pool is still a draft or waiting for funding.
///
/// Ended and closed pools do not block publish. An action with no pool is
/// not a rewarded action.
#[must_use]
pub fn publish_block(status: Option<RewardPoolStatus>) -> Option<ActionAuthoringProblem> {
	match status {
		Some(RewardPoolStatus::Draft | RewardPoolStatus::AwaitingFunding) => {
			Some(ActionAuthoringProblem::RewardNotFunded)
		}
		_ => None,
	}
}

/// Derives the escrow address the server will read.
pub fn escrow_address(
	program: &Address,
	creator: &Address,
	pool_id: &[u8; 16],
) -> Option<(Address, u8)> {
	let derived =
		find_program_address(&[b"reward-escrow", creator.as_bytes(), pool_id], program).ok()?;
	Some((derived.address(), derived.bump()))
}

/// Decodes a 435-byte escrow account.
pub fn decode_escrow(data: &[u8]) -> Option<DecodedEscrow> {
	if data.len() != ESCROW_ACCOUNT_LEN
		|| data[0] != ESCROW_DISCRIMINATOR
		|| data[1] != ESCROW_SCHEMA_VERSION
	{
		return None;
	}
	let decoded = DecodedEscrow {
		creator: address_at(data, CREATOR)?,
		arbiter: address_at(data, ARBITER)?,
		mint: address_at(data, MINT)?,
		vault: address_at(data, VAULT)?,
		pool_id: data[POOL..POOL + 16].try_into().ok()?,
		amount_per_payout: u64_at(data, AMOUNT)?,
		max_payouts: u16_at(data, MAX_PAYOUTS_AT)?,
		released_count: u16_at(data, RELEASED_COUNT_AT)?,
		expires_at: i64_at(data, EXPIRES)?,
		refund_after: i64_at(data, REFUND_AFTER)?,
		refund_delay: u32_at(data, REFUND_DELAY)?,
		bump: data[BUMP],
		released: data[BITMAP..BITMAP + RELEASED_BITMAP_LEN].try_into().ok()?,
	};
	if decoded.amount_per_payout < 1
		|| decoded.max_payouts < 1
		|| decoded.max_payouts > MAX_PAYOUTS
		|| decoded.released_count > decoded.max_payouts
		|| decoded.refund_delay < MIN_REFUND_DELAY_SECONDS
		|| decoded.refund_delay > MAX_REFUND_DELAY_SECONDS
	{
		return None;
	}
	let refund_after = decoded
		.expires_at
		.checked_add(i64::from(decoded.refund_delay))?;
	if refund_after != decoded.refund_after {
		return None;
	}
	Some(decoded)
}

/// Encodes an escrow account. Tests and the funding reader share this layout.
#[must_use]
pub fn encode_escrow(escrow: &DecodedEscrow) -> [u8; ESCROW_ACCOUNT_LEN] {
	let mut data = [0u8; ESCROW_ACCOUNT_LEN];
	data[0] = ESCROW_DISCRIMINATOR;
	data[1] = ESCROW_SCHEMA_VERSION;
	data[CREATOR..CREATOR + 32].copy_from_slice(escrow.creator.as_bytes());
	data[ARBITER..ARBITER + 32].copy_from_slice(escrow.arbiter.as_bytes());
	data[MINT..MINT + 32].copy_from_slice(escrow.mint.as_bytes());
	data[VAULT..VAULT + 32].copy_from_slice(escrow.vault.as_bytes());
	data[POOL..POOL + 16].copy_from_slice(&escrow.pool_id);
	data[AMOUNT..AMOUNT + 8].copy_from_slice(&escrow.amount_per_payout.to_le_bytes());
	data[MAX_PAYOUTS_AT..MAX_PAYOUTS_AT + 2].copy_from_slice(&escrow.max_payouts.to_le_bytes());
	data[RELEASED_COUNT_AT..RELEASED_COUNT_AT + 2]
		.copy_from_slice(&escrow.released_count.to_le_bytes());
	data[EXPIRES..EXPIRES + 8].copy_from_slice(&escrow.expires_at.to_le_bytes());
	data[REFUND_AFTER..REFUND_AFTER + 8].copy_from_slice(&escrow.refund_after.to_le_bytes());
	data[REFUND_DELAY..REFUND_DELAY + 4].copy_from_slice(&escrow.refund_delay.to_le_bytes());
	data[BUMP] = escrow.bump;
	data[BITMAP..BITMAP + RELEASED_BITMAP_LEN].copy_from_slice(&escrow.released);
	data
}

/// Whether bit `index` is set.
#[must_use]
pub fn payout_bit_set(bitmap: &[u8; 256], index: u16) -> bool {
	let index = usize::from(index);
	if index >= MAX_PAYOUTS as usize {
		return false;
	}
	bitmap[index / 8] & (1 << (index % 8)) != 0
}

/// Sets bit `index` and returns the bitmap.
#[must_use]
pub fn with_payout_bit(mut bitmap: [u8; 256], index: u16) -> [u8; 256] {
	let index = usize::from(index);
	if index < MAX_PAYOUTS as usize {
		bitmap[index / 8] |= 1 << (index % 8);
	}
	bitmap
}

/// What the vault can pay.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum VaultState {
	/// Initialized, owned by the escrow, and the canonical token account.
	Payable(u64),
	/// The token account is frozen.
	Frozen,
	/// Missing, or not this escrow's token account for the mint.
	Unusable,
}

/// Classifies the vault account the escrow names.
#[must_use]
pub fn vault_state(
	escrow: Address,
	mint: Address,
	vault: Address,
	account: Option<&RawAccount>,
) -> VaultState {
	let Some(account) = account else {
		return VaultState::Unusable;
	};
	if account.owner != TOKEN_PROGRAM || account.data.len() != TOKEN_ACCOUNT_LEN {
		return VaultState::Unusable;
	}
	let Some(account_mint) = address_at(&account.data, 0) else {
		return VaultState::Unusable;
	};
	let Some(account_owner) = address_at(&account.data, 32) else {
		return VaultState::Unusable;
	};
	let Some(expected) = associated_token_address(escrow, mint) else {
		return VaultState::Unusable;
	};
	if account_mint != mint || account_owner != escrow || expected != vault {
		return VaultState::Unusable;
	}
	match account.data[108] {
		1 => VaultState::Payable(u64_at(&account.data, 64).unwrap_or(0)),
		2 => VaultState::Frozen,
		_ => VaultState::Unusable,
	}
}

/// Compares a finalized account with the pool row.
pub fn inspect_funding(
	expected: &ExpectedEscrow,
	read_address: Address,
	account: Option<&RawAccount>,
	vault: Option<&RawAccount>,
) -> Result<DecodedEscrow, FundingMismatch> {
	let Some(account) = account else {
		return Err(mismatch(&["account"]));
	};
	let mut fields = Vec::new();
	if account.owner != expected.program {
		fields.push("owner");
	}
	let Some(decoded) = decode_escrow(&account.data) else {
		fields.push("layout");
		return Err(FundingMismatch { fields });
	};
	let Some((derived, bump)) =
		escrow_address(&expected.program, &decoded.creator, &decoded.pool_id)
	else {
		fields.push("address");
		return Err(FundingMismatch { fields });
	};
	if derived != read_address {
		fields.push("address");
	}
	if decoded.bump != bump {
		fields.push("bump");
	}
	if decoded.creator != expected.creator {
		fields.push("creator");
	}
	if decoded.arbiter != expected.arbiter {
		fields.push("arbiter");
	}
	if decoded.mint != expected.mint {
		fields.push("mint");
	}
	if decoded.pool_id != expected.pool_id {
		fields.push("poolId");
	}
	if decoded.amount_per_payout != expected.amount_per_payout {
		fields.push("amountPerPayout");
	}
	if decoded.max_payouts != expected.max_payouts {
		fields.push("maxPayouts");
	}
	if decoded.expires_at != expected.expires_at {
		fields.push("expiresAt");
	}
	if decoded.refund_after != expected.refund_after {
		fields.push("refundAfter");
	}
	if decoded.refund_delay != expected.refund_delay {
		fields.push("refundDelay");
	}
	if decoded.released_count != 0 {
		fields.push("releasedCount");
	}
	let budget = expected
		.amount_per_payout
		.checked_mul(u64::from(expected.max_payouts));
	match vault_state(read_address, expected.mint, decoded.vault, vault) {
		VaultState::Payable(balance) if budget.is_some_and(|budget| balance >= budget) => {}
		_ => fields.push("vaultBalance"),
	}
	if fields.is_empty() {
		Ok(decoded)
	} else {
		Err(FundingMismatch { fields })
	}
}

/// Decides a release from chain bytes. This does not send a transaction.
#[must_use]
pub fn decide_release(input: &ReleaseInput) -> ReleaseOutcome {
	let Some(account) = input.finalized.as_ref() else {
		return failed(ReleaseCode::EscrowClosed, false);
	};
	if account.owner != input.expected.program {
		return failed(ReleaseCode::EscrowMismatch, false);
	}
	let Some(decoded) = decode_escrow(&account.data) else {
		return failed(ReleaseCode::EscrowMismatch, false);
	};
	if decoded.arbiter != input.expected.arbiter {
		return failed(ReleaseCode::ArbiterMismatch, false);
	}
	if decoded.creator != input.expected.creator
		|| decoded.mint != input.expected.mint
		|| decoded.pool_id != input.expected.pool_id
		|| decoded.amount_per_payout != input.expected.amount_per_payout
		|| decoded.max_payouts != input.expected.max_payouts
		|| decoded.expires_at != input.expected.expires_at
		|| decoded.refund_delay != input.expected.refund_delay
	{
		return failed(ReleaseCode::EscrowMismatch, false);
	}
	let Some((derived, bump)) =
		escrow_address(&input.expected.program, &decoded.creator, &decoded.pool_id)
	else {
		return failed(ReleaseCode::EscrowMismatch, false);
	};
	if derived != input.escrow_address || decoded.bump != bump {
		return failed(ReleaseCode::EscrowMismatch, false);
	}
	if decoded.released_count < input.recorded_released {
		return failed(ReleaseCode::EscrowReplaced, true);
	}
	if input.index >= decoded.max_payouts {
		return failed(ReleaseCode::PayoutIndexOutOfRange, false);
	}
	if input.now_unix >= decoded.refund_after {
		return failed(ReleaseCode::RefundWindowReached, false);
	}
	if payout_bit_set(&decoded.released, input.index) {
		return ReleaseOutcome::AlreadyReleased;
	}
	if input.confirmed.as_ref().is_some_and(|confirmed| {
		confirmed.owner == input.expected.program
			&& decode_escrow(&confirmed.data)
				.is_some_and(|confirmed| payout_bit_set(&confirmed.released, input.index))
	}) {
		return failed(ReleaseCode::ReleasePendingFinality, true);
	}
	match vault_state(
		input.escrow_address,
		input.expected.mint,
		decoded.vault,
		input.vault.as_ref(),
	) {
		VaultState::Frozen => return failed(ReleaseCode::TokenAccountFrozen, false),
		VaultState::Payable(balance) if balance < decoded.amount_per_payout => {
			return failed(ReleaseCode::VaultUnderfunded, false);
		}
		VaultState::Unusable => return failed(ReleaseCode::VaultUnderfunded, false),
		VaultState::Payable(_) => {}
	}
	// A configured signer is not a release. The transaction is not sent here,
	// and a missing signer stays retryable on the same index.
	let _ = input.signer_available;
	failed(ReleaseCode::SignerUnavailable, true)
}

/// Whether a mint account is the classic SPL mint this cluster pays in.
#[must_use]
pub fn mint_is_classic_usdc(mint: &Address, account: &RawAccount, expected: &Address) -> bool {
	account.owner == TOKEN_PROGRAM
		&& account.data.len() == MINT_ACCOUNT_LEN
		&& account.data.get(44) == Some(&6)
		&& account.data.get(45) == Some(&1)
		&& mint == expected
}

fn associated_token_address(owner: Address, mint: Address) -> Option<Address> {
	AssociatedTokenSeeds {
		owner,
		token_program: TOKEN_PROGRAM,
		mint,
	}
	.find()
	.ok()
	.map(|derived| derived.address())
}

fn failed(code: ReleaseCode, retryable: bool) -> ReleaseOutcome {
	ReleaseOutcome::Failed { code, retryable }
}

fn mismatch(fields: &[&'static str]) -> FundingMismatch {
	FundingMismatch {
		fields: fields.to_vec(),
	}
}

fn address_at(data: &[u8], at: usize) -> Option<Address> {
	let bytes: [u8; 32] = data.get(at..at + 32)?.try_into().ok()?;
	Some(Address::from_bytes(bytes))
}

fn u64_at(data: &[u8], at: usize) -> Option<u64> {
	Some(u64::from_le_bytes(data.get(at..at + 8)?.try_into().ok()?))
}

fn u32_at(data: &[u8], at: usize) -> Option<u32> {
	Some(u32::from_le_bytes(data.get(at..at + 4)?.try_into().ok()?))
}

fn u16_at(data: &[u8], at: usize) -> Option<u16> {
	Some(u16::from_le_bytes(data.get(at..at + 2)?.try_into().ok()?))
}

fn i64_at(data: &[u8], at: usize) -> Option<i64> {
	Some(i64::from_le_bytes(data.get(at..at + 8)?.try_into().ok()?))
}

#[cfg(test)]
mod tests {
	use super::*;

	fn address(byte: u8) -> Address {
		Address::from_bytes([byte; 32])
	}

	fn sample() -> (ExpectedEscrow, DecodedEscrow, Address) {
		let program = address(9);
		let creator = address(3);
		let pool_id = [7u8; 16];
		let (escrow, bump) = escrow_address(&program, &creator, &pool_id).unwrap();
		let mint = address(5);
		let vault = associated_token_address(escrow, mint).unwrap();
		let decoded = DecodedEscrow {
			creator,
			arbiter: address(4),
			mint,
			vault,
			pool_id,
			amount_per_payout: 1_000,
			max_payouts: 2,
			released_count: 0,
			expires_at: 1_700_000_000,
			refund_delay: MIN_REFUND_DELAY_SECONDS,
			refund_after: 1_700_000_000 + i64::from(MIN_REFUND_DELAY_SECONDS),
			bump,
			released: [0; 256],
		};
		let expected = ExpectedEscrow {
			program,
			creator,
			arbiter: decoded.arbiter,
			mint,
			pool_id,
			amount_per_payout: decoded.amount_per_payout,
			max_payouts: decoded.max_payouts,
			expires_at: decoded.expires_at,
			refund_after: decoded.refund_after,
			refund_delay: decoded.refund_delay,
		};
		(expected, decoded, escrow)
	}

	fn vault_account(decoded: &DecodedEscrow, balance: u64) -> RawAccount {
		let mut data = vec![0u8; TOKEN_ACCOUNT_LEN];
		data[0..32].copy_from_slice(decoded.mint.as_bytes());
		data[32..64].copy_from_slice(
			escrow_address(&address(9), &decoded.creator, &decoded.pool_id)
				.unwrap()
				.0
				.as_bytes(),
		);
		data[64..72].copy_from_slice(&balance.to_le_bytes());
		data[108] = 1;
		RawAccount {
			owner: TOKEN_PROGRAM,
			data,
			executable: false,
		}
	}

	#[test]
	fn the_layout_is_435_bytes_and_round_trips() {
		let (_expected, decoded, _escrow) = sample();
		let bytes = encode_escrow(&decoded);
		assert_eq!(bytes.len(), 435);
		assert_eq!(decode_escrow(&bytes), Some(decoded));
	}

	#[test]
	fn a_matching_vault_funds_and_a_creator_mismatch_does_not() {
		let (expected, decoded, escrow) = sample();
		let account = RawAccount {
			owner: expected.program,
			data: encode_escrow(&decoded).to_vec(),
			executable: false,
		};
		let vault = vault_account(&decoded, 2_000);
		assert!(inspect_funding(&expected, escrow, Some(&account), Some(&vault)).is_ok());

		let mut wrong = expected;
		wrong.creator = address(8);
		let mismatch = inspect_funding(&wrong, escrow, Some(&account), Some(&vault)).unwrap_err();
		assert!(mismatch.fields.contains(&"creator"));
	}

	#[test]
	fn publish_waits_for_funding_and_review_fails_closed() {
		assert_eq!(
			publish_block(Some(RewardPoolStatus::Draft)),
			Some(ActionAuthoringProblem::RewardNotFunded)
		);
		assert_eq!(
			publish_block(Some(RewardPoolStatus::AwaitingFunding)),
			Some(ActionAuthoringProblem::RewardNotFunded)
		);
		assert_eq!(publish_block(Some(RewardPoolStatus::Funded)), None);
		assert_eq!(publish_block(Some(RewardPoolStatus::Ended)), None);
		assert_eq!(publish_block(Some(RewardPoolStatus::Closed)), None);
		assert_eq!(publish_block(None), None);

		assert!(review_blocks_release(25_000_001, Some(25_000_000), false));
		assert!(!review_blocks_release(25_000_001, Some(25_000_000), true));
		assert!(!review_blocks_release(25_000_000, Some(25_000_000), false));
		assert!(review_blocks_release(1, Some(0), false));
		assert!(review_blocks_release(1, None, true));
		assert!(review_blocks_release(-1, Some(1), true));
	}

	#[test]
	fn a_local_development_signature_is_not_a_release() {
		assert_eq!(confirmed_release_signature("local-dev-1", true), None);
		assert_eq!(
			confirmed_release_signature("5".repeat(64).as_str(), false),
			None
		);
		assert!(confirmed_release_signature("5".repeat(64).as_str(), true).is_some());
	}

	#[test]
	fn the_bitmap_settles_a_release_and_a_missing_signer_does_not() {
		let (expected, mut decoded, escrow) = sample();
		decoded.released = with_payout_bit(decoded.released, 0);
		decoded.released_count = 1;
		let account = RawAccount {
			owner: expected.program,
			data: encode_escrow(&decoded).to_vec(),
			executable: false,
		};
		let vault = vault_account(&decoded, 2_000);
		let input = ReleaseInput {
			expected,
			finalized: Some(account.clone()),
			confirmed: Some(account),
			vault: Some(vault.clone()),
			escrow_address: escrow,
			index: 0,
			recorded_released: 0,
			now_unix: decoded.expires_at,
			signer_available: false,
		};
		assert_eq!(decide_release(&input), ReleaseOutcome::AlreadyReleased);

		let (expected, decoded, escrow) = sample();
		let account = RawAccount {
			owner: expected.program,
			data: encode_escrow(&decoded).to_vec(),
			executable: false,
		};
		let outcome = decide_release(&ReleaseInput {
			expected,
			finalized: Some(account),
			confirmed: None,
			vault: Some(vault),
			escrow_address: escrow,
			index: 0,
			recorded_released: 0,
			now_unix: decoded.expires_at,
			signer_available: true,
		});
		assert_eq!(
			outcome,
			ReleaseOutcome::Failed {
				code: ReleaseCode::SignerUnavailable,
				retryable: true,
			}
		);
	}

	#[test]
	fn a_confirmed_bit_waits_for_finality() {
		let (expected, decoded, escrow) = sample();
		let mut confirmed = decoded;
		confirmed.released = with_payout_bit(confirmed.released, 1);
		let outcome = decide_release(&ReleaseInput {
			expected,
			finalized: Some(RawAccount {
				owner: expected.program,
				data: encode_escrow(&decoded).to_vec(),
				executable: false,
			}),
			confirmed: Some(RawAccount {
				owner: expected.program,
				data: encode_escrow(&confirmed).to_vec(),
				executable: false,
			}),
			vault: Some(vault_account(&decoded, 2_000)),
			escrow_address: escrow,
			index: 1,
			recorded_released: 0,
			now_unix: decoded.expires_at,
			signer_available: true,
		});
		assert_eq!(
			outcome,
			ReleaseOutcome::Failed {
				code: ReleaseCode::ReleasePendingFinality,
				retryable: true,
			}
		);
	}
}
