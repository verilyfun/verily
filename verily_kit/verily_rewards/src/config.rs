//! Reward configuration from Monosecret.
//!
//! Values are whatever the process environment already holds. This module
//! does not spawn `op` and does not retry a secret read. Invalid
//! configuration fails closed. `local-development` is not a mode: it would
//! be a simulated payout.

use std::str::FromStr;

use monosecret::client::{Client, ExposeSecret};
use solana_kit_core::{Address, Hash};
use verily_shared::RewardCluster;

use crate::gateway::{Gateway, PlantedGateway, SolanaGateway};

/// The escrow program id. Anything else is refused outside development and test.
pub const ESCROW_PROGRAM_ID: &str = "ANL35GQjGtSuCAHTbXGBjnevFqbEtKNf6wDGPKwuPN1p";
/// Devnet USDC mint.
pub const DEVNET_USDC_MINT: &str = "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU";
/// Mainnet USDC mint.
pub const MAINNET_USDC_MINT: &str = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
/// Devnet genesis hash.
pub const DEVNET_GENESIS: &str = "EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG";
/// Mainnet genesis hash.
pub const MAINNET_GENESIS: &str = "5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d";
/// Default review threshold: 25 USDC.
pub const DEFAULT_REVIEW_THRESHOLD_ATOMS: i64 = 25_000_000;
/// Highest review threshold: 1,000 USDC.
pub const MAX_REVIEW_THRESHOLD_ATOMS: i64 = 1_000_000_000;

/// How the process is running. Production refuses the test double.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RunMode {
	/// A developer machine.
	Development,
	/// Automated tests.
	Test,
	/// A shared deployed environment.
	Staging,
	/// Production.
	Production,
}

impl RunMode {
	/// Development and test may install the planted gateway.
	#[must_use]
	pub fn allows_test_double(self) -> bool {
		matches!(self, Self::Development | Self::Test)
	}
}

/// A named configuration failure. The message names the variable, never a secret.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct ConfigError {
	/// Environment variable.
	pub variable: &'static str,
	/// What is wrong, without the value.
	pub reason: &'static str,
}

impl ConfigError {
	/// A failure for `variable`.
	#[must_use]
	pub const fn new(variable: &'static str, reason: &'static str) -> Self {
		Self { variable, reason }
	}
}

impl std::fmt::Display for ConfigError {
	fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
		write!(formatter, "{} {}", self.variable, self.reason)
	}
}

impl std::error::Error for ConfigError {}

/// Installed rewards service.
pub struct Rewards {
	/// Chain reads.
	pub gateway: Gateway,
	/// Cluster the mint belongs to.
	pub cluster: RewardCluster,
	/// Atoms above which a person must accept a payout. Zero means every payout.
	pub review_threshold_atoms: i64,
	/// Process run mode.
	pub run_mode: RunMode,
	/// Token symbol. v1 is USDC.
	pub token_symbol: &'static str,
	/// USDC decimals.
	pub decimals: i64,
	/// Mint address, base58.
	pub mint: String,
	/// Arbiter address, base58. Empty when rewards are disabled.
	pub arbiter: String,
	program: Address,
	mint_address: Address,
	arbiter_address: Option<Address>,
	signers: Option<crate::custody::PayoutSigners>,
}

impl Rewards {
	/// Fail-closed rewards: the gateway is disabled, no chain client is opened,
	/// and a payout cannot be released.
	///
	/// `verily_backend` mounts this the same way it mounts
	/// `Verification::closed()`. Solana mode is `from_secrets` after Monosecret
	/// has injected the reward variables.
	pub fn closed() -> Result<Self, ConfigError> {
		Ok(disabled(
			RunMode::Production,
			DEFAULT_REVIEW_THRESHOLD_ATOMS,
		))
	}

	/// Reads reward settings from a Monosecret client.
	///
	/// `disabled` is the default when `VERILY_REWARD_ESCROW_MODE` is absent.
	/// `solana` requires an RPC URL, cluster, and arbiter. `local-development`
	/// is rejected in every run mode.
	pub fn from_secrets(secrets: &Client, run_mode: RunMode) -> Result<Self, ConfigError> {
		let mode =
			optional(secrets, "VERILY_REWARD_ESCROW_MODE").unwrap_or_else(|| "disabled".to_owned());
		let threshold = threshold(optional(secrets, "VERILY_REWARD_REVIEW_THRESHOLD_ATOMS"))?;
		match mode.as_str() {
			"disabled" => Ok(disabled(run_mode, threshold)),
			"solana" => solana(secrets, run_mode, threshold),
			"local-development" => Err(ConfigError::new(
				"VERILY_REWARD_ESCROW_MODE",
				"must be disabled or solana",
			)),
			_ => Err(ConfigError::new(
				"VERILY_REWARD_ESCROW_MODE",
				"must be disabled or solana",
			)),
		}
	}

	/// Sets the arbiter a test or a solana configuration releases with.
	#[must_use]
	pub fn with_arbiter(mut self, arbiter: Address) -> Self {
		self.arbiter = arbiter.to_string();
		self.arbiter_address = Some(arbiter);
		self
	}

	/// Installs payout signers (Cloud KMS or devnet-only local keypair).
	#[must_use]
	pub fn with_signers(mut self, signers: crate::custody::PayoutSigners) -> Self {
		self.signers = Some(signers);
		self
	}

	/// Configured payout signers, when present.
	#[must_use]
	pub fn signers(&self) -> Option<&crate::custody::PayoutSigners> {
		self.signers.as_ref()
	}

	/// Whether custody signers are installed for submitting releases.
	#[must_use]
	pub fn has_signers(&self) -> bool {
		self.signers.is_some()
	}

	/// Installs a planted chain. Refused for staging and production.
	pub fn with_planted(mut self, planted: PlantedGateway) -> Result<Self, ConfigError> {
		if !self.run_mode.allows_test_double() {
			return Err(ConfigError::new(
				"VERILY_REWARD_ESCROW_MODE",
				"a test double is refused in this run mode",
			));
		}
		self.gateway = Gateway::Planted(planted);
		Ok(self)
	}

	/// Program id the escrow account must be owned by.
	#[must_use]
	pub fn program_id(&self) -> Address {
		self.program
	}

	/// Parsed mint.
	#[must_use]
	pub fn mint_address(&self) -> Address {
		self.mint_address
	}

	/// Parsed arbiter, when solana mode configured one.
	#[must_use]
	pub fn arbiter_address(&self) -> Option<Address> {
		self.arbiter_address
	}

	/// Whether Solana identity has been verified, or the gateway does not need it.
	#[must_use]
	pub fn chain_ready(&self) -> bool {
		match &self.gateway {
			Gateway::Disabled => false,
			Gateway::Planted(_) => true,
			Gateway::Solana(gateway) => gateway.identity_verified(),
		}
	}
}

fn disabled(run_mode: RunMode, threshold: i64) -> Rewards {
	let mint = DEVNET_USDC_MINT
		.parse()
		.expect("devnet USDC mint is a valid address");
	let program = ESCROW_PROGRAM_ID
		.parse()
		.expect("escrow program id is a valid address");
	Rewards {
		gateway: Gateway::Disabled,
		cluster: RewardCluster::Devnet,
		review_threshold_atoms: threshold,
		run_mode,
		token_symbol: "USDC",
		decimals: 6,
		mint: DEVNET_USDC_MINT.to_owned(),
		arbiter: String::new(),
		program,
		mint_address: mint,
		arbiter_address: None,
		signers: None,
	}
}

fn solana(secrets: &Client, run_mode: RunMode, threshold: i64) -> Result<Rewards, ConfigError> {
	let cluster = match optional(secrets, "VERILY_REWARD_CLUSTER").as_deref() {
		Some("devnet") => RewardCluster::Devnet,
		Some("mainnet") => RewardCluster::Mainnet,
		_ => {
			return Err(ConfigError::new(
				"VERILY_REWARD_CLUSTER",
				"must be devnet or mainnet",
			));
		}
	};
	if cluster == RewardCluster::Mainnet {
		if run_mode != RunMode::Production {
			return Err(ConfigError::new(
				"VERILY_REWARD_CLUSTER",
				"mainnet is only available in production",
			));
		}
		if optional(secrets, "VERILY_REWARD_MAINNET_ENABLED").as_deref() != Some("true") {
			return Err(ConfigError::new(
				"VERILY_REWARD_MAINNET_ENABLED",
				"must be true for mainnet",
			));
		}
	}
	let rpc_url = required(secrets, "VERILY_REWARD_SOLANA_RPC_URL")?;
	if !rpc_url_allowed(&rpc_url, run_mode) {
		return Err(ConfigError::new(
			"VERILY_REWARD_SOLANA_RPC_URL",
			"must be https, or loopback http in development and test",
		));
	}
	let arbiter = required(secrets, "VERILY_REWARD_ARBITER_ADDRESS")?;
	let arbiter_address = Address::from_str(&arbiter)
		.map_err(|_| ConfigError::new("VERILY_REWARD_ARBITER_ADDRESS", "must be an address"))?;
	let mint = match cluster {
		RewardCluster::Devnet => DEVNET_USDC_MINT,
		RewardCluster::Mainnet => MAINNET_USDC_MINT,
	};
	let mint_address = mint.parse().expect("USDC mint is a valid address");
	let program = program_id(secrets, run_mode)?;
	let genesis = genesis(secrets, cluster, run_mode)?;
	let signers = load_signers(secrets, run_mode, arbiter_address)?;
	let gateway =
		SolanaGateway::connect(&rpc_url, program, mint_address, arbiter_address, genesis)?;
	drop(rpc_url);
	Ok(Rewards {
		gateway: Gateway::Solana(Box::new(gateway)),
		cluster,
		review_threshold_atoms: threshold,
		run_mode,
		token_symbol: "USDC",
		decimals: 6,
		mint: mint.to_owned(),
		arbiter,
		program,
		mint_address,
		arbiter_address: Some(arbiter_address),
		signers,
	})
}

fn load_signers(
	secrets: &Client,
	run_mode: RunMode,
	expected_arbiter: Address,
) -> Result<Option<crate::custody::PayoutSigners>, ConfigError> {
	use crate::custody::{CustodySigner, KmsTransactionSigner, LocalKeypairSigner, PayoutSigners};

	let arbiter_kms = optional(secrets, "VERILY_REWARD_ARBITER_KMS_KEY");
	let fee_payer_kms = optional(secrets, "VERILY_REWARD_FEE_PAYER_KMS_KEY");
	if let (Some(arb_key), Some(fee_key)) = (arbiter_kms, fee_payer_kms) {
		let fee_addr_raw = required(secrets, "VERILY_REWARD_FEE_PAYER_ADDRESS")?;
		let fee_addr = Address::from_str(&fee_addr_raw).map_err(|_| {
			ConfigError::new("VERILY_REWARD_FEE_PAYER_ADDRESS", "must be an address")
		})?;
		let kms_json = optional(secrets, "VERILY_REWARD_KMS_CREDENTIALS_JSON");
		let kms_file = optional(secrets, "VERILY_REWARD_KMS_CREDENTIALS_FILE");
		let (arb_signer, fee_signer) = match (kms_json, kms_file) {
			(Some(json), None) => (
				KmsTransactionSigner::new(expected_arbiter, arb_key, json.clone()).map_err(
					|_| ConfigError::new("VERILY_REWARD_KMS_CREDENTIALS_JSON", "is invalid"),
				)?,
				KmsTransactionSigner::new(fee_addr, fee_key, json).map_err(|_| {
					ConfigError::new("VERILY_REWARD_KMS_CREDENTIALS_JSON", "is invalid")
				})?,
			),
			(None, Some(path)) => (
				KmsTransactionSigner::from_credentials_file(
					expected_arbiter,
					arb_key,
					std::path::Path::new(&path),
				)
				.map_err(|_| {
					ConfigError::new("VERILY_REWARD_KMS_CREDENTIALS_FILE", "is invalid")
				})?,
				KmsTransactionSigner::from_credentials_file(
					fee_addr,
					fee_key,
					std::path::Path::new(&path),
				)
				.map_err(|_| {
					ConfigError::new("VERILY_REWARD_KMS_CREDENTIALS_FILE", "is invalid")
				})?,
			),
			_ => {
				return Err(ConfigError::new(
					"VERILY_REWARD_KMS_CREDENTIALS_JSON",
					"requires exactly one KMS credential source",
				));
			}
		};
		return Ok(Some(PayoutSigners::new(
			CustodySigner::Kms(arb_signer),
			CustodySigner::Kms(fee_signer),
		)));
	}

	if let Some(arb_raw) = optional(secrets, "VERILY_REWARD_ARBITER_KEYPAIR") {
		let arb = LocalKeypairSigner::from_json_bytes(&arb_raw, run_mode)?;
		if arb.address() != expected_arbiter {
			return Err(ConfigError::new(
				"VERILY_REWARD_ARBITER_KEYPAIR",
				"does not match VERILY_REWARD_ARBITER_ADDRESS",
			));
		}
		let fee_raw =
			optional(secrets, "VERILY_REWARD_FEE_PAYER_KEYPAIR").unwrap_or_else(|| arb_raw.clone());
		let fee = LocalKeypairSigner::from_json_bytes(&fee_raw, run_mode)?;
		return Ok(Some(PayoutSigners::new(
			CustodySigner::Local(arb),
			CustodySigner::Local(fee),
		)));
	}

	Ok(None)
}

fn program_id(secrets: &Client, run_mode: RunMode) -> Result<Address, ConfigError> {
	let Some(value) = optional(secrets, "VERILY_REWARD_ESCROW_PROGRAM_ID") else {
		return ESCROW_PROGRAM_ID.parse().map_err(|_| {
			ConfigError::new("VERILY_REWARD_ESCROW_PROGRAM_ID", "must be an address")
		});
	};
	if value != ESCROW_PROGRAM_ID && !run_mode.allows_test_double() {
		return Err(ConfigError::new(
			"VERILY_REWARD_ESCROW_PROGRAM_ID",
			"must be the escrow program",
		));
	}
	value
		.parse()
		.map_err(|_| ConfigError::new("VERILY_REWARD_ESCROW_PROGRAM_ID", "must be an address"))
}

fn genesis(
	secrets: &Client,
	cluster: RewardCluster,
	run_mode: RunMode,
) -> Result<Hash, ConfigError> {
	let pinned = match cluster {
		RewardCluster::Devnet => DEVNET_GENESIS,
		RewardCluster::Mainnet => MAINNET_GENESIS,
	};
	let value =
		optional(secrets, "VERILY_REWARD_SOLANA_GENESIS_HASH").unwrap_or_else(|| pinned.to_owned());
	if value != pinned && !run_mode.allows_test_double() {
		return Err(ConfigError::new(
			"VERILY_REWARD_SOLANA_GENESIS_HASH",
			"must be the cluster genesis hash",
		));
	}
	value.parse().map_err(|_| {
		ConfigError::new(
			"VERILY_REWARD_SOLANA_GENESIS_HASH",
			"must be a genesis hash",
		)
	})
}

fn threshold(raw: Option<String>) -> Result<i64, ConfigError> {
	let Some(raw) = raw else {
		return Ok(DEFAULT_REVIEW_THRESHOLD_ATOMS);
	};
	let value: i64 = raw.parse().map_err(|_| {
		ConfigError::new(
			"VERILY_REWARD_REVIEW_THRESHOLD_ATOMS",
			"must be a whole number of atoms",
		)
	})?;
	if !(0..=MAX_REVIEW_THRESHOLD_ATOMS).contains(&value) {
		return Err(ConfigError::new(
			"VERILY_REWARD_REVIEW_THRESHOLD_ATOMS",
			"is outside the allowed range",
		));
	}
	Ok(value)
}

/// Builds a client from values the host already resolved.
///
/// This does not read the environment and does not spawn a secret provider.
pub fn secrets_from_pairs<I, K, V>(pairs: I) -> Client
where
	I: IntoIterator<Item = (K, V)>,
	K: Into<String>,
	V: Into<String>,
{
	Client::from_values(pairs.into_iter().map(|(key, value)| {
		let value: String = value.into();
		(key.into(), value.into())
	}))
}

fn optional(secrets: &Client, name: &str) -> Option<String> {
	secrets
		.get(name)
		.ok()
		.map(|secret| secret.expose_secret().to_owned())
}

fn required(secrets: &Client, name: &'static str) -> Result<String, ConfigError> {
	optional(secrets, name).ok_or(ConfigError::new(name, "is required"))
}

fn rpc_url_allowed(url: &str, run_mode: RunMode) -> bool {
	let Some((scheme, rest)) = url.split_once("://") else {
		return false;
	};
	if rest.contains('@') || url.contains('#') || rest.is_empty() {
		return false;
	}
	match scheme {
		"https" => true,
		"http" if run_mode.allows_test_double() && is_loopback(rest) => true,
		_ => false,
	}
}

fn is_loopback(rest: &str) -> bool {
	let host = rest.split('/').next().unwrap_or("");
	let host = host.rsplit_once(':').map(|(host, _)| host).unwrap_or(host);
	let host = host.trim_matches(['[', ']']);
	host == "localhost" || host == "127.0.0.1" || host == "::1"
}

#[cfg(test)]
mod tests {
	use super::*;
	use solana_kit_native::{HttpConfig, NativeHttp};

	fn values(pairs: &[(&str, &str)]) -> Client {
		super::secrets_from_pairs(pairs.iter().copied())
	}

	#[test]
	fn closed_rewards_do_not_open_a_chain_client() {
		let rewards = Rewards::closed().unwrap();
		assert!(rewards.gateway.is_disabled());
		assert!(!rewards.gateway.is_test_double());
		assert!(!rewards.chain_ready());
		assert!(rewards.with_planted(PlantedGateway::new()).is_err());
		assert_eq!(crate::PREFIX, "/rewards");
	}

	#[test]
	fn local_development_and_a_planted_gateway_are_refused_in_production() {
		let secrets = values(&[("VERILY_REWARD_ESCROW_MODE", "local-development")]);
		assert!(Rewards::from_secrets(&secrets, RunMode::Production).is_err());
		assert!(Rewards::from_secrets(&secrets, RunMode::Test).is_err());

		let disabled = Rewards::from_secrets(&values(&[]), RunMode::Production).unwrap();
		assert!(disabled.gateway.is_disabled());
		assert!(disabled.with_planted(PlantedGateway::new()).is_err());

		let test = Rewards::from_secrets(&values(&[]), RunMode::Test).unwrap();
		assert!(test.with_planted(PlantedGateway::new()).is_ok());
	}

	#[test]
	fn an_invalid_threshold_fails_closed_and_zero_is_kept() {
		let secrets = values(&[("VERILY_REWARD_REVIEW_THRESHOLD_ATOMS", "nope")]);
		assert!(Rewards::from_secrets(&secrets, RunMode::Test).is_err());
		let secrets = values(&[("VERILY_REWARD_REVIEW_THRESHOLD_ATOMS", "0")]);
		let rewards = Rewards::from_secrets(&secrets, RunMode::Test).unwrap();
		assert_eq!(rewards.review_threshold_atoms, 0);
	}

	#[test]
	fn the_rpc_url_rejects_userinfo() {
		assert!(NativeHttp::new("https://user:secret@example.com", HttpConfig::default()).is_err());
		assert!(!rpc_url_allowed(
			"https://user:secret@example.com",
			RunMode::Production
		));
		assert!(rpc_url_allowed("https://example.com", RunMode::Production));
		assert!(!rpc_url_allowed(
			"http://127.0.0.1:8899",
			RunMode::Production
		));
		assert!(rpc_url_allowed("http://127.0.0.1:8899", RunMode::Test));
	}
}
