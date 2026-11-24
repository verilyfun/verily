//! Reward payout signing custody: Google Cloud KMS Ed25519 (production/staging)
//! and devnet-only local keypairs (strictly refused in staging and production).
//!
//! Private key material never leaves Cloud KMS in production; every KMS
//! signature is locally verified against the expected Solana address before
//! leaving this module.

use std::fs;
use std::path::Path;
use std::time::Duration;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use chrono::Utc;
use rsa::RsaPrivateKey;
use rsa::pkcs1v15::SigningKey;
use rsa::pkcs8::DecodePrivateKey;
use rsa::signature::SignatureEncoding;
use rsa::signature::Signer;
use serde::Deserialize;
use serde_json::Value;
use solana_kit_core::Address;
use solana_kit_core::Signature;
use solana_kit_core::crypto::Keypair;
use solana_kit_core::crypto::verify;

use crate::config::ConfigError;
use crate::config::RunMode;

const CLOUD_KMS_SCOPE: &str = "https://www.googleapis.com/auth/cloudkms";
const CLOUD_KMS_API_ROOT: &str = "https://cloudkms.googleapis.com/v1/";
const GOOGLE_TOKEN_URI: &str = "https://oauth2.googleapis.com/token";
const KMS_ED25519_ALGORITHM: &str = "EC_SIGN_ED25519";

/// DER `SubjectPublicKeyInfo` prefix for an Ed25519 public key: 12 bytes
/// followed by the 32-byte raw public key.
pub const ED25519_SPKI_PREFIX: [u8; 12] = [
	0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00,
];

#[derive(Debug, thiserror::Error)]
pub enum CustodyError {
	#[error("signer configuration invalid: {0}")]
	InvalidConfig(&'static str),
	#[error("signer unavailable")]
	Unavailable,
	#[error("signature verification failed")]
	InvalidSignature,
}

/// Strictly parses a single `PUBLIC KEY` PEM block containing an Ed25519 SPKI
/// into its 32-byte public key.
pub fn parse_ed25519_public_key_pem(pem: &str) -> Result<[u8; 32], CustodyError> {
	let lines: Vec<&str> = pem.trim().lines().collect();
	if lines.len() < 3
		|| lines.first().map(|l| l.trim()) != Some("-----BEGIN PUBLIC KEY-----")
		|| lines.last().map(|l| l.trim()) != Some("-----END PUBLIC KEY-----")
	{
		return Err(CustodyError::InvalidConfig(
			"a single PUBLIC KEY PEM block is required",
		));
	}
	let body_lines = &lines[1..lines.len() - 1];
	for line in body_lines {
		if line.is_empty()
			|| *line != line.trim()
			|| line.contains("-----")
			|| !line
				.bytes()
				.all(|b| b.is_ascii_alphanumeric() || matches!(b, b'+' | b'/' | b'='))
		{
			return Err(CustodyError::InvalidConfig("malformed public key PEM body"));
		}
	}
	let joined: String = body_lines.iter().copied().collect();
	let der = STANDARD
		.decode(joined.as_bytes())
		.map_err(|_| CustodyError::InvalidConfig("invalid base64 in public key PEM"))?;
	if der.len() != ED25519_SPKI_PREFIX.len() + 32
		|| der[..ED25519_SPKI_PREFIX.len()] != ED25519_SPKI_PREFIX
	{
		return Err(CustodyError::InvalidConfig(
			"public key is not an Ed25519 SPKI",
		));
	}
	let mut key = [0u8; 32];
	key.copy_from_slice(&der[ED25519_SPKI_PREFIX.len()..]);
	Ok(key)
}

#[derive(Debug, Deserialize)]
struct GoogleServiceAccount {
	client_email: String,
	private_key: String,
	#[serde(default)]
	token_uri: Option<String>,
}

/// Google Cloud KMS Ed25519 transaction signer.
pub struct KmsTransactionSigner {
	address: Address,
	key_version_name: String,
	credentials_json: String,
	api_root: String,
	http: reqwest::Client,
}

impl KmsTransactionSigner {
	pub fn new(
		address: Address,
		key_version_name: String,
		credentials_json: String,
	) -> Result<Self, CustodyError> {
		let parsed: GoogleServiceAccount =
			serde_json::from_str(&credentials_json).map_err(|_| {
				CustodyError::InvalidConfig("KMS credentials are not valid service account JSON")
			})?;
		RsaPrivateKey::from_pkcs8_pem(&parsed.private_key).map_err(|_| {
			CustodyError::InvalidConfig("KMS service account private key is invalid")
		})?;
		if !key_version_name.starts_with("projects/")
			|| !key_version_name.contains("/cryptoKeyVersions/")
		{
			return Err(CustodyError::InvalidConfig(
				"KMS key version name must be a full Cloud KMS resource path",
			));
		}
		let http = reqwest::Client::builder()
			.timeout(Duration::from_secs(15))
			.redirect(reqwest::redirect::Policy::none())
			.build()
			.map_err(|_| CustodyError::Unavailable)?;
		Ok(Self {
			address,
			key_version_name,
			credentials_json,
			api_root: CLOUD_KMS_API_ROOT.to_owned(),
			http,
		})
	}

	pub fn from_credentials_file(
		address: Address,
		key_version_name: String,
		path: &Path,
	) -> Result<Self, CustodyError> {
		#[cfg(unix)]
		{
			use std::os::unix::fs::MetadataExt;
			let meta = fs::metadata(path)
				.map_err(|_| CustodyError::InvalidConfig("KMS credentials file cannot be read"))?;
			if !meta.is_file() {
				return Err(CustodyError::InvalidConfig(
					"KMS credentials path is not a file",
				));
			}
			if (meta.mode() & 0o077) != 0 {
				return Err(CustodyError::InvalidConfig(
					"KMS credentials file must be mode 0600 (owner-only)",
				));
			}
		}
		let contents = fs::read_to_string(path)
			.map_err(|_| CustodyError::InvalidConfig("KMS credentials file cannot be read"))?;
		Self::new(address, key_version_name, contents)
	}

	pub fn address(&self) -> Address {
		self.address
	}

	async fn access_token(&self) -> Result<String, CustodyError> {
		let account: GoogleServiceAccount =
			serde_json::from_str(&self.credentials_json).map_err(|_| CustodyError::Unavailable)?;
		let private_key = RsaPrivateKey::from_pkcs8_pem(&account.private_key)
			.map_err(|_| CustodyError::Unavailable)?;
		let signing_key = SigningKey::<sha2::Sha256>::new(private_key);
		let token_uri = account
			.token_uri
			.as_deref()
			.filter(|s| !s.trim().is_empty())
			.unwrap_or(GOOGLE_TOKEN_URI);
		let iat = Utc::now().timestamp();
		let exp = iat + 3600;
		let header = serde_json::json!({ "alg": "RS256", "typ": "JWT" });
		let claims = serde_json::json!({
			"iss": account.client_email,
			"scope": CLOUD_KMS_SCOPE,
			"aud": token_uri,
			"iat": iat,
			"exp": exp,
		});
		let input = format!(
			"{}.{}",
			URL_SAFE_NO_PAD.encode(header.to_string().as_bytes()),
			URL_SAFE_NO_PAD.encode(claims.to_string().as_bytes())
		);
		let sig = signing_key.sign(input.as_bytes());
		let assertion = format!("{input}.{}", URL_SAFE_NO_PAD.encode(sig.to_bytes()));

		let resp = self
			.http
			.post(token_uri)
			.form(&[
				("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
				("assertion", assertion.as_str()),
			])
			.send()
			.await
			.map_err(|_| CustodyError::Unavailable)?;
		if !resp.status().is_success() {
			return Err(CustodyError::Unavailable);
		}
		let body: Value = resp.json().await.map_err(|_| CustodyError::Unavailable)?;
		body.get("access_token")
			.and_then(Value::as_str)
			.map(str::to_owned)
			.ok_or(CustodyError::Unavailable)
	}

	/// Verifies the KMS key matches the expected Solana address and is Ed25519.
	pub async fn prove_signing_power(&self) -> Result<(), CustodyError> {
		let token = self.access_token().await?;
		let url = format!("{}{}:getPublicKey", self.api_root, self.key_version_name);
		let resp = self
			.http
			.get(url)
			.bearer_auth(&token)
			.send()
			.await
			.map_err(|_| CustodyError::Unavailable)?;
		if !resp.status().is_success() {
			return Err(CustodyError::Unavailable);
		}
		let body: Value = resp.json().await.map_err(|_| CustodyError::Unavailable)?;
		let algorithm = body
			.get("algorithm")
			.and_then(Value::as_str)
			.ok_or(CustodyError::Unavailable)?;
		if algorithm != KMS_ED25519_ALGORITHM {
			return Err(CustodyError::InvalidConfig(
				"KMS key is not EC_SIGN_ED25519",
			));
		}
		let pem = body
			.get("pem")
			.and_then(Value::as_str)
			.ok_or(CustodyError::Unavailable)?;
		let pub_bytes = parse_ed25519_public_key_pem(pem)?;
		if Address::from_bytes(pub_bytes) != self.address {
			return Err(CustodyError::InvalidConfig(
				"KMS public key does not match configured address",
			));
		}
		Ok(())
	}

	pub async fn sign_message(&self, message: &[u8]) -> Result<Signature, CustodyError> {
		let token = self.access_token().await?;
		let url = format!("{}{}:asymmetricSign", self.api_root, self.key_version_name);
		let resp = self
			.http
			.post(url)
			.bearer_auth(&token)
			.json(&serde_json::json!({ "data": STANDARD.encode(message) }))
			.send()
			.await
			.map_err(|_| CustodyError::Unavailable)?;
		if !resp.status().is_success() {
			return Err(CustodyError::Unavailable);
		}
		let body: Value = resp.json().await.map_err(|_| CustodyError::Unavailable)?;
		let raw_sig = body
			.get("signature")
			.and_then(Value::as_str)
			.ok_or(CustodyError::Unavailable)?;
		let sig_bytes = STANDARD
			.decode(raw_sig.as_bytes())
			.map_err(|_| CustodyError::InvalidSignature)?;
		let sig_arr: [u8; 64] = sig_bytes
			.try_into()
			.map_err(|_| CustodyError::InvalidSignature)?;
		let signature = Signature::from_bytes(sig_arr);
		verify(&self.address, message, &signature).map_err(|_| CustodyError::InvalidSignature)?;
		Ok(signature)
	}
}

/// Devnet-only local keypair signer. Refused in staging and production.
pub struct LocalKeypairSigner {
	keypair: Keypair,
}

impl LocalKeypairSigner {
	pub fn from_json_bytes(raw: &str, run_mode: RunMode) -> Result<Self, ConfigError> {
		if !run_mode.allows_test_double() {
			return Err(ConfigError::new(
				"VERILY_REWARD_ARBITER_KEYPAIR",
				"local keypair signers are refused outside development and test",
			));
		}
		let bytes: Vec<u8> = serde_json::from_str(raw.trim()).map_err(|_| {
			ConfigError::new(
				"VERILY_REWARD_ARBITER_KEYPAIR",
				"must be a 64-byte JSON integer array",
			)
		})?;
		let keypair = Keypair::from_bytes(&bytes).map_err(|_| {
			ConfigError::new(
				"VERILY_REWARD_ARBITER_KEYPAIR",
				"must be a valid 64-byte Ed25519 keypair",
			)
		})?;
		Ok(Self { keypair })
	}

	pub fn from_keypair(keypair: Keypair) -> Self {
		Self { keypair }
	}

	pub fn address(&self) -> Address {
		self.keypair.address()
	}

	pub fn sign_message(&self, message: &[u8]) -> Result<Signature, CustodyError> {
		let sig = self.keypair.sign(message);
		verify(&self.address(), message, &sig).map_err(|_| CustodyError::InvalidSignature)?;
		Ok(sig)
	}
}

/// A custody-backed Solana transaction signer.
pub enum CustodySigner {
	Kms(KmsTransactionSigner),
	Local(LocalKeypairSigner),
}

impl CustodySigner {
	pub fn address(&self) -> Address {
		match self {
			Self::Kms(kms) => kms.address(),
			Self::Local(local) => local.address(),
		}
	}

	pub async fn prove_signing_power(&self) -> Result<(), CustodyError> {
		match self {
			Self::Kms(kms) => kms.prove_signing_power().await,
			Self::Local(local) => {
				let _ = local.sign_message(b"verily-startup-probe")?;
				Ok(())
			}
		}
	}

	pub async fn sign_message(&self, message: &[u8]) -> Result<Signature, CustodyError> {
		match self {
			Self::Kms(kms) => kms.sign_message(message).await,
			Self::Local(local) => local.sign_message(message),
		}
	}
}

/// Separate arbiter and fee-payer signers for `ReleasePayout`.
pub struct PayoutSigners {
	pub arbiter: CustodySigner,
	pub fee_payer: CustodySigner,
}

impl PayoutSigners {
	pub fn new(arbiter: CustodySigner, fee_payer: CustodySigner) -> Self {
		Self { arbiter, fee_payer }
	}

	pub async fn prove_signing_power(&self) -> Result<(), CustodyError> {
		self.arbiter.prove_signing_power().await?;
		self.fee_payer.prove_signing_power().await?;
		Ok(())
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn parses_strict_ed25519_spki_pem_and_rejects_malformed() {
		let raw_pub = [0x42_u8; 32];
		let mut der = Vec::from(ED25519_SPKI_PREFIX);
		der.extend_from_slice(&raw_pub);
		let pem = format!(
			"-----BEGIN PUBLIC KEY-----\n{}\n-----END PUBLIC KEY-----",
			STANDARD.encode(&der)
		);
		assert_eq!(parse_ed25519_public_key_pem(&pem).unwrap(), raw_pub);
		assert!(parse_ed25519_public_key_pem("not a pem").is_err());

		let mut bad = der.clone();
		bad[0] = 0x31;
		let bad_pem = format!(
			"-----BEGIN PUBLIC KEY-----\n{}\n-----END PUBLIC KEY-----",
			STANDARD.encode(&bad)
		);
		assert!(parse_ed25519_public_key_pem(&bad_pem).is_err());
	}

	#[test]
	fn local_keypair_signer_is_refused_in_production_and_works_in_dev() {
		let kp = Keypair::from_seed(&[7_u8; 32]);
		let mut raw_bytes = Vec::with_capacity(64);
		raw_bytes.extend_from_slice(&[7_u8; 32]);
		raw_bytes.extend_from_slice(kp.address().as_bytes());
		let json = serde_json::to_string(&raw_bytes).unwrap();

		assert!(LocalKeypairSigner::from_json_bytes(&json, RunMode::Production).is_err());
		assert!(LocalKeypairSigner::from_json_bytes(&json, RunMode::Staging).is_err());
		let signer = LocalKeypairSigner::from_json_bytes(&json, RunMode::Development).unwrap();
		assert_eq!(signer.address(), kp.address());
		let sig = signer.sign_message(b"hello release").unwrap();
		assert!(verify(&kp.address(), b"hello release", &sig).is_ok());
	}
}
