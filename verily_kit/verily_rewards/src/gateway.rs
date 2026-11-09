//! Chain gateways the backend installs.
//!
//! The Solana gateway reads through `solana_kit_client` on
//! `solana_kit_native`. The planted gateway is a test double and
//! [`crate::Rewards::with_planted`] refuses it outside development and test.
//! Neither gateway reports a payout released because a signer was present.

use std::collections::BTreeMap;
use std::sync::Mutex;

use solana_kit_client::Client;
use solana_kit_client::methods::{AccountInfo, Commitment, ReadConfig};
use solana_kit_core::Address;
use solana_kit_native::{HttpConfig, NativeHttp};

use crate::chain::{self, ChainFailure};
use crate::decide::ExpectedEscrow;

/// One account body returned by a gateway.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RawAccount {
	/// Program that owns the account.
	pub owner: Address,
	/// Exact account data.
	pub data: Vec<u8>,
	/// Whether the account is executable.
	pub executable: bool,
}

/// Where escrow reads come from.
pub enum Gateway {
	/// Rewards are off. Reads fail closed.
	Disabled,
	/// Finalized reads through solana_kit.
	Solana(Box<SolanaGateway>),
	/// Accounts a test planted. Not a production payout.
	Planted(PlantedGateway),
}

impl Gateway {
	/// Whether this gateway is the test double.
	#[must_use]
	pub fn is_test_double(&self) -> bool {
		matches!(self, Self::Planted(_))
	}

	/// Whether rewards are configured off.
	#[must_use]
	pub fn is_disabled(&self) -> bool {
		matches!(self, Self::Disabled)
	}

	/// Reads one account at `commitment`.
	pub async fn account(
		&self,
		address: &Address,
		commitment: Commitment,
	) -> Result<Option<RawAccount>, ChainFailure> {
		match self {
			Self::Disabled => Err(ChainFailure::Unavailable),
			Self::Solana(gateway) => gateway.account(address, commitment).await,
			Self::Planted(planted) => Ok(planted.account(address)),
		}
	}
}

/// Solana RPC via `solana_kit_client::Client<NativeHttp>`.
pub struct SolanaGateway {
	client: Client<NativeHttp>,
	/// Program that must own the escrow.
	pub program: Address,
	/// Mint the cluster pays in.
	pub mint: Address,
	/// Arbiter the escrow must name.
	pub arbiter: Address,
	/// Genesis hash this cluster must report.
	pub genesis: solana_kit_core::Hash,
	verified: std::sync::atomic::AtomicBool,
}

impl SolanaGateway {
	/// Builds a client for `endpoint`. The endpoint is not logged.
	pub fn connect(
		endpoint: &str,
		program: Address,
		mint: Address,
		arbiter: Address,
		genesis: solana_kit_core::Hash,
	) -> Result<Self, crate::ConfigError> {
		let transport = NativeHttp::new(endpoint, HttpConfig::default()).map_err(|_| {
			crate::ConfigError::new("VERILY_REWARD_SOLANA_RPC_URL", "is not a usable endpoint")
		})?;
		Ok(Self {
			client: Client::new(
				transport,
				solana_kit_client::Limits {
					bytes: 1024 * 1024,
					depth: 32,
				},
			),
			program,
			mint,
			arbiter,
			genesis,
			verified: std::sync::atomic::AtomicBool::new(false),
		})
	}

	/// Checks genesis, the program account, and the USDC mint.
	pub async fn verify_identity(&self) -> Result<(), ChainFailure> {
		chain::verify_identity(&self.client, &self.genesis, &self.program, &self.mint).await?;
		self.verified
			.store(true, std::sync::atomic::Ordering::SeqCst);
		Ok(())
	}

	/// Whether [`Self::verify_identity`] has succeeded in this process.
	#[must_use]
	pub fn identity_verified(&self) -> bool {
		self.verified.load(std::sync::atomic::Ordering::SeqCst)
	}

	async fn account(
		&self,
		address: &Address,
		commitment: Commitment,
	) -> Result<Option<RawAccount>, ChainFailure> {
		let config = ReadConfig {
			commitment: Some(commitment),
			..ReadConfig::default()
		};
		chain::fetch_account(&self.client, AccountInfo(*address, config)).await
	}
}

/// In-memory accounts for tests. `release` still cannot succeed from here:
/// the release decision has no signer and does not invent a signature.
#[derive(Default)]
pub struct PlantedGateway {
	accounts: Mutex<BTreeMap<Address, RawAccount>>,
}

impl PlantedGateway {
	/// An empty chain.
	#[must_use]
	pub fn new() -> Self {
		Self::default()
	}

	/// Plants `account` at `address`.
	pub fn insert(&self, address: Address, account: RawAccount) {
		self.accounts
			.lock()
			.unwrap_or_else(std::sync::PoisonError::into_inner)
			.insert(address, account);
	}

	fn account(&self, address: &Address) -> Option<RawAccount> {
		self.accounts
			.lock()
			.unwrap_or_else(std::sync::PoisonError::into_inner)
			.get(address)
			.cloned()
	}
}

/// Reads the escrow and its vault for `expected` at `escrow_address`.
pub async fn read_escrow_parts(
	gateway: &Gateway,
	expected: &ExpectedEscrow,
	escrow_address: Address,
	commitment: Commitment,
) -> Result<(Option<RawAccount>, Option<RawAccount>), ChainFailure> {
	let account = gateway.account(&escrow_address, commitment).await?;
	let vault_address = account
		.as_ref()
		.and_then(|account| crate::decide::decode_escrow(&account.data))
		.map(|decoded| decoded.vault);
	let vault = match vault_address {
		Some(vault) => gateway.account(&vault, commitment).await?,
		None => None,
	};
	let _ = expected;
	Ok((account, vault))
}
