//! Solana reads through `solana_kit_client`.
//!
//! There is no second RPC stack. Account, genesis, and token reads use the
//! kit's typed methods. Failures become stable codes and drop provider text.

use solana_kit_client::methods::node::GenesisHash;
use solana_kit_client::methods::{AccountInfo, Commitment};
use solana_kit_client::{Client, Transport};
use solana_kit_core::accounts::MaybeAccount;
use solana_kit_core::{Address, Hash};

use crate::decide::{self, mint_is_classic_usdc};
use crate::gateway::RawAccount;

/// A chain read failed closed.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ChainFailure {
	/// Rewards are not configured.
	Unavailable,
	/// The endpoint did not answer.
	RpcUnavailable,
	/// The answer was not a usable account or hash.
	RpcInvalid,
	/// Genesis, the program, or the mint did not match.
	Identity,
}

impl ChainFailure {
	/// Stable release code for this failure.
	#[must_use]
	pub fn release_code(self) -> crate::ReleaseCode {
		match self {
			Self::Unavailable => crate::ReleaseCode::SignerUnavailable,
			Self::RpcUnavailable => crate::ReleaseCode::RpcUnavailable,
			Self::RpcInvalid | Self::Identity => crate::ReleaseCode::RpcInvalidResponse,
		}
	}
}

/// Reads one account. `None` means the account is absent.
pub async fn fetch_account<T: Transport>(
	client: &Client<T>,
	request: AccountInfo,
) -> Result<Option<RawAccount>, ChainFailure> {
	let response = client.call(request).await.map_err(classify)?;
	match response.value {
		MaybeAccount::Missing(_) => Ok(None),
		MaybeAccount::Present(account) => Ok(Some(RawAccount {
			owner: account.owner,
			data: account.data,
			executable: account.executable,
		})),
	}
}

/// Checks the cluster genesis hash, that the program account is executable,
/// and that the mint is the classic SPL USDC mint.
pub async fn verify_identity<T: Transport>(
	client: &Client<T>,
	expected_genesis: &Hash,
	program: &Address,
	mint: &Address,
) -> Result<(), ChainFailure> {
	let genesis = client.call(GenesisHash).await.map_err(classify)?;
	if &genesis != expected_genesis {
		return Err(ChainFailure::Identity);
	}
	let config = solana_kit_client::methods::ReadConfig {
		commitment: Some(Commitment::Finalized),
		..solana_kit_client::methods::ReadConfig::default()
	};
	let program_account = fetch_account(client, AccountInfo(*program, config))
		.await?
		.ok_or(ChainFailure::Identity)?;
	if !program_account.executable {
		return Err(ChainFailure::Identity);
	}
	let mint_account = fetch_account(client, AccountInfo(*mint, config))
		.await?
		.ok_or(ChainFailure::Identity)?;
	if !mint_is_classic_usdc(mint, &mint_account, mint) {
		return Err(ChainFailure::Identity);
	}
	let _ = decide::ESCROW_ACCOUNT_LEN;
	Ok(())
}

fn classify(error: solana_kit_client::Error) -> ChainFailure {
	use solana_kit_client::Error::{AccountData, Envelope, Json, Schema, Status, Transport};
	match error {
		Transport(_) | Status(_) => ChainFailure::RpcUnavailable,
		Json(_) | Schema(_) | AccountData | Envelope => ChainFailure::RpcInvalid,
		_ => ChainFailure::RpcUnavailable,
	}
}

#[cfg(test)]
mod tests {
	use std::collections::BTreeMap;
	use std::future::Ready;

	use base64::Engine;
	use solana_kit_client::{Reply, Request, Transport, TransportError};
	use solana_kit_core::Address;

	use super::*;
	use crate::decide::{
		DecodedEscrow, ExpectedEscrow, MIN_REFUND_DELAY_SECONDS, encode_escrow, inspect_funding,
	};
	use crate::gateway::RawAccount;

	struct Scripted {
		accounts: BTreeMap<String, RawAccount>,
		genesis: String,
	}

	impl Transport for Scripted {
		type Exchange<'a>
			= Ready<Result<Reply, TransportError>>
		where
			Self: 'a;

		fn exchange(&self, request: Request) -> Self::Exchange<'_> {
			let body = String::from_utf8_lossy(&request.body);
			let parsed: serde_json::Value =
				serde_json::from_str(&body).unwrap_or(serde_json::Value::Null);
			let id = parsed
				.get("id")
				.and_then(|value| value.as_u64())
				.unwrap_or(1);
			let method = parsed
				.get("method")
				.and_then(|value| value.as_str())
				.unwrap_or("");
			let result = match method {
				"getGenesisHash" => {
					serde_json::to_string(&self.genesis).unwrap_or_else(|_| "null".to_owned())
				}
				"getAccountInfo" => account_json(&self.accounts, &parsed),
				_ => "null".to_owned(),
			};
			let envelope = format!(r#"{{"jsonrpc":"2.0","id":{id},"result":{result}}}"#);
			std::future::ready(Ok(Reply {
				status: 200,
				body: envelope.into_bytes(),
			}))
		}
	}

	fn account_json(
		accounts: &BTreeMap<String, RawAccount>,
		request: &serde_json::Value,
	) -> String {
		let address = request
			.pointer("/params/0")
			.and_then(|value| value.as_str())
			.unwrap_or("");
		let Some(account) = accounts.get(address) else {
			return r#"{"context":{"slot":1},"value":null}"#.to_owned();
		};
		let data = base64::engine::general_purpose::STANDARD.encode(&account.data);
		format!(
			r#"{{"context":{{"slot":1}},"value":{{"executable":{},"lamports":1,"owner":"{}","rentEpoch":0,"space":{},"data":["{data}","base64"]}}}}"#,
			if account.executable { "true" } else { "false" },
			account.owner,
			account.data.len(),
		)
	}

	fn client(scripted: Scripted) -> Client<Scripted> {
		Client::new(scripted, solana_kit_client::Limits::default())
	}

	#[tokio::test]
	async fn a_scripted_solana_kit_client_funds_only_a_matching_account() {
		let program = Address::from_bytes([9; 32]);
		let creator = Address::from_bytes([3; 32]);
		let mint = Address::from_bytes([5; 32]);
		let pool_id = [7u8; 16];
		let (escrow, bump) = crate::decide::escrow_address(&program, &creator, &pool_id).unwrap();
		let vault = solana_kit_associated_token_account::AssociatedTokenSeeds {
			owner: escrow,
			token_program: solana_kit_associated_token_account::TOKEN_PROGRAM,
			mint,
		}
		.find()
		.unwrap()
		.address();
		let decoded = DecodedEscrow {
			creator,
			arbiter: Address::from_bytes([4; 32]),
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
		let mut vault_data = vec![0u8; 165];
		vault_data[0..32].copy_from_slice(mint.as_bytes());
		vault_data[32..64].copy_from_slice(escrow.as_bytes());
		vault_data[64..72].copy_from_slice(&2_000u64.to_le_bytes());
		vault_data[108] = 1;
		let mut accounts = BTreeMap::new();
		accounts.insert(
			escrow.to_string(),
			RawAccount {
				owner: program,
				data: encode_escrow(&decoded).to_vec(),
				executable: false,
			},
		);
		accounts.insert(
			vault.to_string(),
			RawAccount {
				owner: solana_kit_associated_token_account::TOKEN_PROGRAM,
				data: vault_data,
				executable: false,
			},
		);
		let rpc = client(Scripted {
			accounts,
			genesis: "EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG".to_owned(),
		});
		let config = solana_kit_client::methods::ReadConfig {
			commitment: Some(Commitment::Finalized),
			..solana_kit_client::methods::ReadConfig::default()
		};
		let account = fetch_account(&rpc, AccountInfo(escrow, config))
			.await
			.unwrap()
			.unwrap();
		let vault_account = fetch_account(&rpc, AccountInfo(vault, config))
			.await
			.unwrap();
		let expected = ExpectedEscrow {
			program,
			creator,
			arbiter: decoded.arbiter,
			mint,
			pool_id,
			amount_per_payout: 1_000,
			max_payouts: 2,
			expires_at: decoded.expires_at,
			refund_after: decoded.refund_after,
			refund_delay: decoded.refund_delay,
		};
		assert!(inspect_funding(&expected, escrow, Some(&account), vault_account.as_ref()).is_ok());

		let missing = fetch_account(&rpc, AccountInfo(Address::from_bytes([8; 32]), config))
			.await
			.unwrap();
		assert!(missing.is_none());
		assert!(inspect_funding(&expected, escrow, None, None).is_err());
	}

	#[tokio::test]
	async fn genesis_identity_uses_solana_kit() {
		let program = Address::from_bytes([9; 32]);
		let mint = "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU"
			.parse::<Address>()
			.unwrap();
		let mut mint_data = vec![0u8; 82];
		mint_data[44] = 6;
		mint_data[45] = 1;
		let mut accounts = BTreeMap::new();
		accounts.insert(
			program.to_string(),
			RawAccount {
				owner: Address::from_bytes([1; 32]),
				data: vec![0],
				executable: true,
			},
		);
		accounts.insert(
			mint.to_string(),
			RawAccount {
				owner: solana_kit_associated_token_account::TOKEN_PROGRAM,
				data: mint_data,
				executable: false,
			},
		);
		let genesis = "EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG";
		let rpc = client(Scripted {
			accounts,
			genesis: genesis.to_owned(),
		});
		let expected: Hash = genesis.parse().unwrap();
		verify_identity(&rpc, &expected, &program, &mint)
			.await
			.unwrap();
		let wrong: Hash = "5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d"
			.parse()
			.unwrap();
		assert_eq!(
			verify_identity(&rpc, &wrong, &program, &mint).await,
			Err(ChainFailure::Identity)
		);
	}
}
