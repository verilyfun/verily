//! Solana reads through `solana_kit_client`.
//!
//! There is no second RPC stack. Account, genesis, and token reads use the
//! kit's typed methods. Failures become stable codes and drop provider text.

use std::time::{Duration, Instant};

use solana_kit_associated_token_account::{
	AssociatedTokenInstruction, AssociatedTokenSeeds, CreateAccounts, SYSTEM_PROGRAM, TOKEN_PROGRAM,
};
use solana_kit_client::methods::history::ConfirmationStatus;
use solana_kit_client::methods::node::{BlockHeight, GenesisHash};
use solana_kit_client::methods::submission::{
	SendConfig, SendTransaction, SignatureStatuses, SignedWire, StatusesConfig, WireEncoding,
};
use solana_kit_client::methods::{AccountInfo, Commitment, LatestBlockhash, ReadConfig};
use solana_kit_client::{Client, Transport};
use solana_kit_core::accounts::MaybeAccount;
use solana_kit_core::codecs::Limits;
use solana_kit_core::transaction::{Lifetime, Message, Transaction, Version};
use solana_kit_core::{AccountMeta, AccountRole, Address, Hash, Instruction};

use crate::custody::PayoutSigners;
use crate::decide::{
	self, ReleaseCode, ReleaseOutcome, confirmed_release_signature, mint_is_classic_usdc,
};
use crate::gateway::RawAccount;

/// Instruction discriminator for `EscrowInstruction::ReleasePayout` in `programs/verily_escrow`.
pub const RELEASE_PAYOUT_DISCRIMINATOR: u8 = 1;

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

/// Builds the exact `ReleasePayout` instruction for `programs/verily_escrow`.
#[must_use]
pub fn build_release_payout_instruction(
	program: Address,
	arbiter: Address,
	escrow: Address,
	vault: Address,
	recipient_token: Address,
	mint: Address,
	payout_index: u16,
) -> Instruction {
	let idx = payout_index.to_le_bytes();
	Instruction {
		program_address: program,
		accounts: vec![
			AccountMeta {
				address: arbiter,
				role: AccountRole::ReadonlySigner,
			},
			AccountMeta {
				address: escrow,
				role: AccountRole::Writable,
			},
			AccountMeta {
				address: vault,
				role: AccountRole::Writable,
			},
			AccountMeta {
				address: recipient_token,
				role: AccountRole::Writable,
			},
			AccountMeta {
				address: mint,
				role: AccountRole::Readonly,
			},
			AccountMeta {
				address: TOKEN_PROGRAM,
				role: AccountRole::Readonly,
			},
		],
		data: vec![RELEASE_PAYOUT_DISCRIMINATOR, idx[0], idx[1]],
	}
}

/// Compiles, dual-signs (`fee_payer` + `arbiter`), cryptographically verifies,
/// and encodes a `CreateAssociatedTokenIdempotent + ReleasePayout` v0 transaction.
#[allow(
	clippy::too_many_arguments,
	reason = "explicit Solana release accounts, payout index, blockhash lifetime, and dual signers"
)]
pub async fn build_and_sign_release_transaction(
	program: Address,
	mint: Address,
	escrow: Address,
	vault: Address,
	recipient_wallet: Address,
	payout_index: u16,
	blockhash: Hash,
	last_valid_block_height: u64,
	signers: &PayoutSigners,
) -> Result<(Vec<u8>, solana_kit_core::Signature), ReleaseOutcome> {
	if recipient_wallet == escrow {
		return Err(ReleaseOutcome::Failed {
			code: ReleaseCode::InvalidRecipient,
			retryable: false,
		});
	}
	let recipient_token = AssociatedTokenSeeds {
		owner: recipient_wallet,
		token_program: TOKEN_PROGRAM,
		mint,
	}
	.find()
	.map_err(|_| ReleaseOutcome::Failed {
		code: ReleaseCode::InvalidRecipient,
		retryable: false,
	})?
	.address();

	let fee_payer = signers.fee_payer.address();
	let arbiter = signers.arbiter.address();

	let create_ata = AssociatedTokenInstruction::CreateIdempotent(CreateAccounts {
		payer: fee_payer,
		associated_token: recipient_token,
		owner: recipient_wallet,
		mint,
		system_program: SYSTEM_PROGRAM,
		token_program: TOKEN_PROGRAM,
	})
	.instruction(Limits::new(128, 16))
	.map_err(|_| ReleaseOutcome::Failed {
		code: ReleaseCode::ReleaseRejected,
		retryable: false,
	})?;

	let release = build_release_payout_instruction(
		program,
		arbiter,
		escrow,
		vault,
		recipient_token,
		mint,
		payout_index,
	);

	let message = Message::compile(
		Version::V0,
		fee_payer,
		Lifetime::Blockhash {
			blockhash,
			last_valid_block_height,
		},
		&[create_ata, release],
		&[],
	)
	.map_err(|_| ReleaseOutcome::Failed {
		code: ReleaseCode::ReleaseRejected,
		retryable: false,
	})?;

	// Refuse any message whose signer set diverges from {fee_payer, arbiter}.
	if message
		.signers()
		.iter()
		.any(|s| *s != fee_payer && *s != arbiter)
	{
		return Err(ReleaseOutcome::Failed {
			code: ReleaseCode::ReleaseRejected,
			retryable: false,
		});
	}

	let msg_bytes = message.bytes().to_vec();
	let fee_sig = signers
		.fee_payer
		.sign_message(&msg_bytes)
		.await
		.map_err(|_| ReleaseOutcome::Failed {
			code: ReleaseCode::SignerUnavailable,
			retryable: true,
		})?;
	let arbiter_sig = if arbiter == fee_payer {
		fee_sig
	} else {
		signers
			.arbiter
			.sign_message(&msg_bytes)
			.await
			.map_err(|_| ReleaseOutcome::Failed {
				code: ReleaseCode::SignerUnavailable,
				retryable: true,
			})?
	};

	let mut tx = Transaction::new(message)
		.with_signature(fee_payer, &msg_bytes, fee_sig)
		.map_err(|_| ReleaseOutcome::Failed {
			code: ReleaseCode::SignerUnavailable,
			retryable: true,
		})?;
	if arbiter != fee_payer {
		tx = tx
			.with_signature(arbiter, &msg_bytes, arbiter_sig)
			.map_err(|_| ReleaseOutcome::Failed {
				code: ReleaseCode::SignerUnavailable,
				retryable: true,
			})?;
	}
	tx.verify().map_err(|_| ReleaseOutcome::Failed {
		code: ReleaseCode::SignerUnavailable,
		retryable: true,
	})?;
	let wire = tx.encode(true).map_err(|_| ReleaseOutcome::Failed {
		code: ReleaseCode::ReleaseRejected,
		retryable: false,
	})?;
	Ok((wire, fee_sig))
}

/// Fetches a fresh blockhash, signs, submits, and polls `ReleasePayout` until
/// confirmed or finalized on chain. Never fakes a signature.
#[allow(clippy::too_many_arguments)]
pub async fn submit_and_confirm_release<T: Transport>(
	client: &Client<T>,
	program: Address,
	mint: Address,
	escrow: Address,
	vault: Address,
	recipient_wallet: Address,
	payout_index: u16,
	signers: &PayoutSigners,
	confirmation_timeout: Duration,
	poll_interval: Duration,
) -> ReleaseOutcome {
	let latest = match client
		.call(LatestBlockhash(Some(ReadConfig {
			commitment: Some(Commitment::Confirmed),
			..ReadConfig::default()
		})))
		.await
	{
		Ok(res) => res.value,
		Err(err) => {
			return ReleaseOutcome::Failed {
				code: classify(err).release_code(),
				retryable: true,
			};
		}
	};

	let (wire_bytes, signature) = match build_and_sign_release_transaction(
		program,
		mint,
		escrow,
		vault,
		recipient_wallet,
		payout_index,
		latest.blockhash,
		latest.last_valid_block_height,
		signers,
	)
	.await
	{
		Ok(pair) => pair,
		Err(outcome) => return outcome,
	};

	let Ok(signed_wire) = SignedWire::new(&wire_bytes) else {
		return ReleaseOutcome::Failed {
			code: ReleaseCode::ReleaseRejected,
			retryable: false,
		};
	};

	let _send_result = client
		.call(SendTransaction {
			wire: signed_wire,
			encoding: WireEncoding::Base64,
			config: SendConfig {
				preflight_commitment: Some(Commitment::Confirmed),
				..SendConfig::default()
			},
		})
		.await;

	let start = Instant::now();
	loop {
		if let Ok(statuses) = client
			.call(SignatureStatuses(
				&[signature],
				Some(StatusesConfig {
					search_transaction_history: Some(false),
				}),
			))
			.await
		{
			if let Some(Some(status)) = statuses.value.first() {
				if status.err.is_some() {
					return ReleaseOutcome::Failed {
						code: ReleaseCode::ReleaseRejected,
						retryable: true,
					};
				}
				if matches!(
					status.confirmation_status,
					Some(ConfirmationStatus::Confirmed | ConfirmationStatus::Finalized)
				) {
					let sig_str = signature.to_string();
					if let Some(confirmed) = confirmed_release_signature(&sig_str, true) {
						return ReleaseOutcome::Released {
							signature: confirmed.to_owned(),
						};
					}
					return ReleaseOutcome::Failed {
						code: ReleaseCode::ReleaseUnconfirmed,
						retryable: true,
					};
				}
			} else if let Ok(height) = client
				.call(BlockHeight(Some(ReadConfig {
					commitment: Some(Commitment::Confirmed),
					..ReadConfig::default()
				})))
				.await
				&& height > latest.last_valid_block_height
			{
				if let Ok(hist) = client
					.call(SignatureStatuses(
						&[signature],
						Some(StatusesConfig {
							search_transaction_history: Some(true),
						}),
					))
					.await
					&& let Some(Some(status)) = hist.value.first()
					&& status.err.is_none()
					&& matches!(
						status.confirmation_status,
						Some(ConfirmationStatus::Confirmed | ConfirmationStatus::Finalized)
					) {
					let sig_str = signature.to_string();
					if let Some(confirmed) = confirmed_release_signature(&sig_str, true) {
						return ReleaseOutcome::Released {
							signature: confirmed.to_owned(),
						};
					}
				}
				return ReleaseOutcome::Failed {
					code: ReleaseCode::BlockhashExpired,
					retryable: true,
				};
			}
		}

		if start.elapsed() >= confirmation_timeout {
			return ReleaseOutcome::Failed {
				code: ReleaseCode::ReleaseUnconfirmed,
				retryable: true,
			};
		}
		tokio::time::sleep(poll_interval).await;
	}
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

	#[tokio::test]
	async fn release_payout_compiles_dual_signs_submits_and_confirms() {
		use std::sync::Mutex;

		use crate::custody::{CustodySigner, LocalKeypairSigner, PayoutSigners};
		use solana_kit_core::crypto::Keypair;

		struct ReleaseRpc {
			blockhash: String,
			submitted: Mutex<Option<String>>,
		}

		impl Transport for ReleaseRpc {
			type Exchange<'a>
				= Ready<Result<Reply, TransportError>>
			where
				Self: 'a;

			fn exchange(&self, request: Request) -> Self::Exchange<'_> {
				let body = String::from_utf8_lossy(&request.body);
				let parsed: serde_json::Value =
					serde_json::from_str(&body).unwrap_or(serde_json::Value::Null);
				let id = parsed.get("id").and_then(|v| v.as_u64()).unwrap_or(1);
				let method = parsed.get("method").and_then(|v| v.as_str()).unwrap_or("");
				let result = match method {
					"getLatestBlockhash" => format!(
						r#"{{"context":{{"slot":10}},"value":{{"blockhash":"{}","lastValidBlockHeight":500}}}}"#,
						self.blockhash
					),
					"sendTransaction" => {
						let b64 = parsed.pointer("/params/0").and_then(|v| v.as_str()).unwrap();
						let wire = base64::engine::general_purpose::STANDARD
							.decode(b64)
							.unwrap();
						let tx = Transaction::decode(&wire).unwrap();
						tx.verify().expect("both Ed25519 signatures verify");
						let sig = tx.signatures()[0].unwrap().to_string();
						*self.submitted.lock().unwrap() = Some(sig.clone());
						serde_json::to_string(&sig).unwrap()
					}
					"getSignatureStatuses" => r#"{"context":{"slot":11},"value":[{"slot":11,"confirmations":5,"err":null,"status":{"Ok":null},"confirmationStatus":"confirmed"}]}"#.to_owned(),
					_ => "null".to_owned(),
				};
				let envelope = format!(r#"{{"jsonrpc":"2.0","id":{id},"result":{result}}}"#);
				std::future::ready(Ok(Reply {
					status: 200,
					body: envelope.into_bytes(),
				}))
			}
		}

		let arbiter_kp = Keypair::from_seed(&[11_u8; 32]);
		let fee_payer_kp = Keypair::from_seed(&[22_u8; 32]);
		let recipient_kp = Keypair::from_seed(&[33_u8; 32]);
		let program = Address::from_bytes([9; 32]);
		let mint: Address = "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU"
			.parse()
			.unwrap();
		let creator = Address::from_bytes([3; 32]);
		let (escrow, _) = crate::decide::escrow_address(&program, &creator, &[7u8; 16]).unwrap();
		let vault = AssociatedTokenSeeds {
			owner: escrow,
			token_program: TOKEN_PROGRAM,
			mint,
		}
		.find()
		.unwrap()
		.address();

		let signers = PayoutSigners::new(
			CustodySigner::Local(LocalKeypairSigner::from_keypair(arbiter_kp)),
			CustodySigner::Local(LocalKeypairSigner::from_keypair(fee_payer_kp)),
		);
		let rpc = Client::new(
			ReleaseRpc {
				blockhash: "EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG".to_owned(),
				submitted: Mutex::new(None),
			},
			solana_kit_client::Limits::default(),
		);
		let outcome = submit_and_confirm_release(
			&rpc,
			program,
			mint,
			escrow,
			vault,
			recipient_kp.address(),
			0,
			&signers,
			Duration::from_secs(5),
			Duration::from_millis(10),
		)
		.await;
		match outcome {
			ReleaseOutcome::Released { signature } => {
				assert!(!signature.is_empty());
				assert!(!signature.starts_with("local-dev-"));
			}
			other => panic!("expected Released, got {other:?}"),
		}
	}
}
