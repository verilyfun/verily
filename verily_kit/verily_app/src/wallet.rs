//! Links the participant's payout wallet through Mobile Wallet Adapter.
//!
//! Android hands the association to a wallet app on the phone. The wallet
//! signs the server's challenge. That signature does not fund an escrow and
//! does not release a payout. Other platforms have no adapter to call.

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use serde_json::Map;
use serde_json::Value;
use solana_kit_core::Address;
use solana_kit_core::Signature;

/// Why linking did not finish. The screen maps this to product copy.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LinkFault {
	/// This build cannot open a mobile wallet.
	#[cfg_attr(all(feature = "android", target_arch = "wasm32"), allow(dead_code))]
	Unsupported,
	/// No wallet app answered.
	#[cfg_attr(
		not(all(feature = "android", target_arch = "wasm32")),
		allow(dead_code)
	)]
	Unavailable,
	/// The person declined in the wallet.
	#[cfg_attr(
		not(all(feature = "android", target_arch = "wasm32")),
		allow(dead_code)
	)]
	Cancelled,
	/// The wallet did not answer in time. The session does not invent this
	/// from a native failure; the screen still has copy for it.
	#[allow(dead_code)]
	TimedOut,
	/// The wallet's bytes were not a signature of the challenge.
	#[cfg_attr(
		not(all(feature = "android", target_arch = "wasm32")),
		allow(dead_code)
	)]
	Invalid,
	/// The signature was not from the authorized account.
	#[cfg_attr(
		not(all(feature = "android", target_arch = "wasm32")),
		allow(dead_code)
	)]
	WrongAccount,
	/// Linking did not finish.
	#[cfg_attr(
		not(all(feature = "android", target_arch = "wasm32")),
		allow(dead_code)
	)]
	Failed,
}

/// Address and signature the server can check. No secret.
#[cfg_attr(
	not(all(feature = "android", target_arch = "wasm32")),
	allow(dead_code)
)]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PayoutLinkProof {
	/// Base58 account the wallet authorized.
	pub address: String,
	/// Base58 signature of the server's challenge.
	pub signature: String,
}

#[cfg_attr(
	not(all(feature = "android", target_arch = "wasm32")),
	allow(dead_code)
)]
const SIGNATURE_LEN: usize = 64;

/// Android can hand off to a Mobile Wallet Adapter app.
#[must_use]
pub const fn mobile_link_supported() -> bool {
	cfg!(all(feature = "android", target_arch = "wasm32"))
}

/// The account an authorize result names, in the wallet's encoding and as base58.
#[cfg_attr(
	not(all(feature = "android", target_arch = "wasm32")),
	allow(dead_code)
)]
fn authorized_account(authorize: &Map<String, Value>) -> Result<(String, Address), LinkFault> {
	let encoded = authorize
		.get("accounts")
		.and_then(Value::as_array)
		.and_then(|accounts| accounts.first())
		.and_then(|account| account.get("address"))
		.and_then(Value::as_str)
		.ok_or(LinkFault::Invalid)?;
	let bytes = STANDARD.decode(encoded).map_err(|_| LinkFault::Invalid)?;
	let address = Address::try_from(bytes.as_slice()).map_err(|_| LinkFault::Invalid)?;
	Ok((encoded.to_owned(), address))
}

/// Reads the authorized account and the signature over `message`.
///
/// `authorize` is the Mobile Wallet Adapter authorize result. `signed` is the
/// sign-messages result. The signed payload is the message bytes followed by
/// one 64-byte signature.
#[cfg_attr(
	not(all(feature = "android", target_arch = "wasm32")),
	allow(dead_code)
)]
pub fn proof_from_wallet(
	authorize: &Map<String, Value>,
	signed: &Map<String, Value>,
	message: &str,
) -> Result<PayoutLinkProof, LinkFault> {
	let (_, address) = authorized_account(authorize)?;
	let payload = one_payload(signed)?;
	let text = message.as_bytes();
	if payload.len() != text.len() + SIGNATURE_LEN || !payload.starts_with(text) {
		return Err(LinkFault::Invalid);
	}
	let signature = Signature::try_from(&payload[text.len()..]).map_err(|_| LinkFault::Invalid)?;
	solana_kit_core::crypto::verify(&address, text, &signature)
		.map_err(|_| LinkFault::WrongAccount)?;
	Ok(PayoutLinkProof {
		address: address.to_string(),
		signature: signature.to_string(),
	})
}

#[cfg_attr(
	not(all(feature = "android", target_arch = "wasm32")),
	allow(dead_code)
)]
fn one_payload(signed: &Map<String, Value>) -> Result<Vec<u8>, LinkFault> {
	let payloads = signed
		.get("signed_payloads")
		.and_then(Value::as_array)
		.ok_or(LinkFault::Invalid)?;
	if payloads.len() != 1 {
		return Err(LinkFault::Invalid);
	}
	let encoded = payloads[0].as_str().ok_or(LinkFault::Invalid)?;
	STANDARD.decode(encoded).map_err(|_| LinkFault::Invalid)
}

/// Asks the phone's wallet to authorize and sign, then stores the link.
///
/// On builds without the Android adapter the callback hears [`LinkFault::Unsupported`].
pub fn begin_link(done: impl FnOnce(Result<(), LinkFault>) + 'static) {
	#[cfg(all(feature = "android", target_arch = "wasm32"))]
	{
		session::start(done);
	}
	#[cfg(not(all(feature = "android", target_arch = "wasm32")))]
	{
		done(Err(LinkFault::Unsupported));
	}
}

#[cfg(all(feature = "android", target_arch = "wasm32"))]
mod session {
	use std::cell::Cell;
	use std::cell::RefCell;
	use std::collections::VecDeque;

	use base64::Engine;
	use base64::engine::general_purpose::STANDARD;
	use leptoskit_bridge::Event;
	use leptoskit_bridge::guest::Events;
	use solana_kit_leptoskit::GuestMobileWallet;
	use solana_kit_leptoskit::WalletPlatformError;
	use solana_kit_leptoskit::WalletSessionError;
	use solana_kit_wallet::mwa::Method;
	use solana_kit_wallet::mwa::ProtocolError;

	use super::LinkFault;
	use super::authorized_account;
	use super::proof_from_wallet;
	use crate::ops::CreateWalletLinkChallenge;
	use crate::ops::LinkPayoutWallet;

	/// Devnet is the cluster a reward is funded on until mainnet is reviewed.
	/// The payout address is the same on every cluster. This call submits nothing.
	const PAYOUT_CHAIN: &str = "solana:devnet";
	const WALLET_NAME: &str = "Verily";
	const UNRELATED_LIMIT: usize = 64;

	thread_local! {
		static EVENTS: RefCell<Option<Events>> = const { RefCell::new(None) };
		static BUSY: Cell<bool> = const { Cell::new(false) };
	}

	pub(super) fn start(done: impl FnOnce(Result<(), LinkFault>) + 'static) {
		if BUSY.replace(true) {
			done(Err(LinkFault::Failed));
			return;
		}
		leptoskit::guest::spawn(async move {
			let result = link().await;
			BUSY.set(false);
			done(result);
		});
	}

	async fn link() -> Result<(), LinkFault> {
		let mut events = take_events()?;
		let result = connect_and_sign(&mut events).await;
		EVENTS.with(|slot| *slot.borrow_mut() = Some(events));
		result
	}

	fn take_events() -> Result<Events, LinkFault> {
		EVENTS.with(|slot| {
			if let Some(events) = slot.borrow_mut().take() {
				return Ok(events);
			}
			Events::take().map_err(map_bridge)
		})
	}

	async fn connect_and_sign(events: &mut Events) -> Result<(), LinkFault> {
		let mut unrelated = VecDeque::new();
		let mut wallet = GuestMobileWallet::connect_android(events, |event: Event| {
			if unrelated.len() == UNRELATED_LIMIT {
				return Err(leptoskit_bridge::Error::Busy);
			}
			unrelated.push_back(event);
			Ok(())
		})
		.await
		.map_err(map_session)?;
		let outcome = sign_challenge(&mut wallet).await;
		let _closed = wallet.close().await;
		outcome
	}

	async fn sign_challenge(wallet: &mut GuestMobileWallet) -> Result<(), LinkFault> {
		let authorize = wallet
			.call(Method::Authorize, authorize_params()?)
			.await
			.map_err(map_session)?;
		let (encoded, address) = authorized_account(&authorize)?;
		let challenge = leptoskit::rpc::client::call(CreateWalletLinkChallenge {
			wallet_address: address.to_string(),
		})
		.await
		.map_err(|_| LinkFault::Failed)?;
		let signed = wallet
			.call(
				Method::SignMessages,
				sign_params(&encoded, &challenge.message)?,
			)
			.await
			.map_err(map_session)?;
		let proof = proof_from_wallet(&authorize, &signed, &challenge.message)?;
		leptoskit::rpc::client::call(LinkPayoutWallet {
			wallet_address: proof.address,
			signature: proof.signature,
		})
		.await
		.map_err(|_| LinkFault::Failed)?;
		Ok(())
	}

	fn authorize_params() -> Result<serde_json::Map<String, serde_json::Value>, LinkFault> {
		object(serde_json::json!({
			"chain": PAYOUT_CHAIN,
			"identity": {"name": WALLET_NAME}
		}))
	}

	fn sign_params(
		encoded: &str,
		message: &str,
	) -> Result<serde_json::Map<String, serde_json::Value>, LinkFault> {
		object(serde_json::json!({
			"addresses": [encoded],
			"payloads": [STANDARD.encode(message.as_bytes())]
		}))
	}

	fn object(
		value: serde_json::Value,
	) -> Result<serde_json::Map<String, serde_json::Value>, LinkFault> {
		value.as_object().cloned().ok_or(LinkFault::Invalid)
	}

	fn map_session(error: WalletSessionError) -> LinkFault {
		match error {
			WalletSessionError::Bridge(error) => map_bridge(error),
			WalletSessionError::Platform(WalletPlatformError::Bridge(error)) => map_bridge(error),
			WalletSessionError::Platform(_) => LinkFault::Unavailable,
			WalletSessionError::Rejected(error)
				if error.code == ProtocolError::AUTHORIZATION_FAILED
					|| error.code == ProtocolError::NOT_SIGNED =>
			{
				LinkFault::Cancelled
			}
			WalletSessionError::Rejected(_) => LinkFault::Failed,
			WalletSessionError::Malformed => LinkFault::Invalid,
			WalletSessionError::Method => LinkFault::Failed,
		}
	}

	fn map_bridge(error: leptoskit_bridge::Error) -> LinkFault {
		match error {
			leptoskit_bridge::Error::Unavailable => LinkFault::Unavailable,
			leptoskit_bridge::Error::Cancelled => LinkFault::Cancelled,
			leptoskit_bridge::Error::InvalidArgument => LinkFault::Invalid,
			leptoskit_bridge::Error::PermissionDenied
			| leptoskit_bridge::Error::Busy
			| leptoskit_bridge::Error::TooLarge
			| leptoskit_bridge::Error::Native
			| leptoskit_bridge::Error::InvalidCall
			| leptoskit_bridge::Error::Exhausted => LinkFault::Failed,
		}
	}
}

#[cfg(test)]
mod tests {
	use base64::Engine;
	use base64::engine::general_purpose::STANDARD;
	use solana_kit_core::crypto::Keypair;

	use super::LinkFault;
	use super::mobile_link_supported;
	use super::proof_from_wallet;

	fn authorize(key: &Keypair) -> serde_json::Map<String, serde_json::Value> {
		let encoded = STANDARD.encode(key.address().as_bytes());
		serde_json::json!({"accounts": [{"address": encoded}]})
			.as_object()
			.cloned()
			.expect("object")
	}

	fn signed(message: &str, key: &Keypair) -> serde_json::Map<String, serde_json::Value> {
		let mut payload = message.as_bytes().to_vec();
		payload.extend_from_slice(key.sign(message.as_bytes()).as_bytes());
		serde_json::json!({"signed_payloads": [STANDARD.encode(payload)]})
			.as_object()
			.cloned()
			.expect("object")
	}

	#[test]
	fn this_host_has_no_mobile_wallet_adapter() {
		assert!(!mobile_link_supported());
	}

	#[test]
	fn a_wallet_proof_is_the_authorized_signature() {
		let key = Keypair::from_seed(&[9; 32]);
		let message = format!(
			"Verily payout wallet\nAddress: {}\nNonce: abc\n",
			key.address()
		);
		let proof =
			proof_from_wallet(&authorize(&key), &signed(&message, &key), &message).expect("proof");
		assert_eq!(proof.address, key.address().to_string());
		assert_eq!(proof.signature, key.sign(message.as_bytes()).to_string());
	}

	#[test]
	fn a_different_message_is_not_a_proof() {
		let key = Keypair::from_seed(&[9; 32]);
		let message = "Verily payout wallet\nAddress: x\nNonce: abc\n";
		let error = proof_from_wallet(&authorize(&key), &signed(message, &key), "other")
			.expect_err("message");
		assert_eq!(error, LinkFault::Invalid);
	}

	#[test]
	fn a_different_key_is_the_wrong_account() {
		let key = Keypair::from_seed(&[9; 32]);
		let other = Keypair::from_seed(&[4; 32]);
		let message = "Verily payout wallet\nAddress: x\nNonce: abc\n";
		let error = proof_from_wallet(&authorize(&key), &signed(message, &other), message)
			.expect_err("key");
		assert_eq!(error, LinkFault::WrongAccount);
	}

	#[test]
	fn a_missing_account_is_invalid() {
		let key = Keypair::from_seed(&[9; 32]);
		let message = "Verily payout wallet\n";
		let empty = serde_json::Map::new();
		assert_eq!(
			proof_from_wallet(&empty, &signed(message, &key), message),
			Err(LinkFault::Invalid)
		);
	}
}
