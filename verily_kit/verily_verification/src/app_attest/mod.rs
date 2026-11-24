//! Apple App Attest attestation, assertion, receipt, and DeviceCheck verifier.
//!
//! Pinned to Apple's App Attestation Root CA and Apple Root CA - G3. Validated
//! against the byte-identical vectors in `tests/app_attest/vectors/`.

use std::collections::BTreeMap;
use std::collections::HashMap;
use std::collections::HashSet;
use std::io::Cursor;
use std::time::Duration;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use chrono::DateTime;
use chrono::Utc;
use ciborium::Value as CborValue;
use p256::ecdsa::SigningKey;
use p256::ecdsa::signature::Signer;
use p256::pkcs8::DecodePrivateKey;
use sha2::Digest;
use sha2::Sha256;

use crate::asn1::DerError;
use crate::asn1::X509Certificate;
use crate::asn1::algorithm_oid;
use crate::asn1::constant_time_eq;
use crate::asn1::normalize_receipt_ber;
use crate::asn1::oid;
use crate::asn1::parse_der;
use crate::asn1::verify_ecdsa_der;

pub const VERILY_IOS_BUNDLE_ID: &str = "fun.verily.app";
pub const APP_ATTEST_NONCE_EXTENSION_OID: &str = "1.2.840.113635.100.8.2";

const MAX_CHAIN_LENGTH: usize = 8;
const MAX_DER_SIGNATURE: usize = 128;
const MAX_RECEIPT_BYTES: usize = 32 * 1024;
const MAX_APPLE_RESPONSE_BYTES: usize = 48 * 1024;

const OID_SIGNED_DATA: &str = "1.2.840.113549.1.7.2";
const OID_DATA: &str = "1.2.840.113549.1.7.1";
const OID_SHA256: &str = "2.16.840.1.101.3.4.2.1";
const OID_CONTENT_TYPE: &str = "1.2.840.113549.1.9.3";
const OID_MESSAGE_DIGEST: &str = "1.2.840.113549.1.9.4";
const OID_APPLE_APP_ATTEST_RECEIPT: &str = "1.2.840.113635.100.12.15";

const VALIDATION_CATEGORY_KEY: &str = "apple_validation_category_01";
const BUNDLE_VERSION_KEY: &str = "apple_bundle_version_01";

pub mod reason {
	pub const VALID: &str = "capture_app_attest_valid";
	pub const MALFORMED: &str = "capture_app_attest_malformed";
	pub const CHAIN_INVALID: &str = "capture_app_attest_chain_invalid";
	pub const UNTRUSTED_ROOT: &str = "capture_app_attest_untrusted_root";
	pub const EXPIRED: &str = "capture_app_attest_expired";
	pub const NONCE_MISMATCH: &str = "capture_app_attest_nonce_mismatch";
	pub const KEY_INVALID: &str = "capture_app_attest_key_invalid";
	pub const APP_MISMATCH: &str = "capture_app_attest_app_mismatch";
	pub const COUNTER_INVALID: &str = "capture_app_attest_counter_invalid";
	pub const ENVIRONMENT_MISMATCH: &str = "capture_app_attest_environment";
	pub const CATEGORY_REFUSED: &str = "capture_app_attest_category";
	pub const SIGNATURE_INVALID: &str = "capture_signature_invalid";
	pub const REPLAYED: &str = "capture_app_attest_replayed";
	pub const KEY_UNKNOWN: &str = "capture_app_attest_key_unknown";
	pub const UNCONFIGURED: &str = "capture_app_attest_unconfigured";
}

pub mod validation_category {
	pub const TEST_FLIGHT: u32 = 2;
	pub const DEVELOPMENT: u32 = 3;
	pub const APP_STORE: u32 = 4;
	pub const AD_HOC: u32 = 5;
}

/// Pinned Apple App Attestation Root CA.
const APPLE_APP_ATTESTATION_ROOT_PEM: &str = "\
-----BEGIN CERTIFICATE-----
MIICITCCAaegAwIBAgIQC/O+DvHN0uD7jG5yH2IXmDAKBggqhkjOPQQDAzBSMSYw
JAYDVQQDDB1BcHBsZSBBcHAgQXR0ZXN0YXRpb24gUm9vdCBDQTETMBEGA1UECgwK
QXBwbGUgSW5jLjETMBEGA1UECAwKQ2FsaWZvcm5pYTAeFw0yMDAzMTgxODMyNTNa
Fw00NTAzMTUwMDAwMDBaMFIxJjAkBgNVBAMMHUFwcGxlIEFwcCBBdHRlc3RhdGlv
biBSb290IENBMRMwEQYDVQQKDApBcHBsZSBJbmMuMRMwEQYDVQQIDApDYWxpZm9y
bmlhMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAERTHhmLW07ATaFQIEVwTtT4dyctdh
NbJhFs/Ii2FdCgAHGbpphY3+d8qjuDngIN3WVhQUBHAoMeQ/cLiP1sOUtgjqK9au
Yen1mMEvRq9Sk3Jm5X8U62H+xTD3FE9TgS41o0IwQDAPBgNVHRMBAf8EBTADAQH/
MB0GA1UdDgQWBBSskRBTM72+aEH/pwyp5frq5eWKoTAOBgNVHQ8BAf8EBAMCAQYw
CgYIKoZIzj0EAwMDaAAwZQIwQgFGnByvsiVbpTKwSga0kP0e8EeDS4+sQmTvb7vn
53O5+FRXgeLhpJ06ysC5PrOyAjEAp5U4xDgEgllF7En3VcE3iexZZtKeYnpqtijV
oyFraWVIyd/dganmrduC1bmTBGwD
-----END CERTIFICATE-----";

/// Pinned Apple Root CA - G3 for App Attest receipts.
const APPLE_RECEIPT_ROOT_PEM: &str = "\
-----BEGIN CERTIFICATE-----
MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwS
QXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9u
IEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcN
MTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBS
b290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9y
aXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49
AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtf
TjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517
IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySr
MA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gA
MGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4
at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM
6BgD56KyKA==
-----END CERTIFICATE-----";

pub fn apple_app_attestation_roots() -> Vec<X509Certificate> {
	vec![
		X509Certificate::from_pem(APPLE_APP_ATTESTATION_ROOT_PEM)
			.expect("pinned Apple App Attestation Root CA is valid DER"),
	]
}

pub fn apple_receipt_root() -> X509Certificate {
	X509Certificate::from_pem(APPLE_RECEIPT_ROOT_PEM)
		.expect("pinned Apple Root CA - G3 is valid DER")
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AppAttestEnvironment {
	Production,
	Development,
}

#[derive(Debug, Clone)]
pub struct AppAttestPolicy {
	pub team_id: String,
	pub bundle_id: String,
	pub environment: AppAttestEnvironment,
	pub validation_categories: HashSet<u32>,
}

impl AppAttestPolicy {
	pub fn new(team_id: impl Into<String>, bundle_id: impl Into<String>) -> Self {
		Self::with_environment(team_id, bundle_id, AppAttestEnvironment::Production)
	}

	pub fn with_environment(
		team_id: impl Into<String>,
		bundle_id: impl Into<String>,
		environment: AppAttestEnvironment,
	) -> Self {
		let categories = match environment {
			AppAttestEnvironment::Production => HashSet::from([
				validation_category::TEST_FLIGHT,
				validation_category::APP_STORE,
			]),
			AppAttestEnvironment::Development => HashSet::from([
				validation_category::DEVELOPMENT,
				validation_category::AD_HOC,
			]),
		};
		Self {
			team_id: team_id.into(),
			bundle_id: bundle_id.into(),
			environment,
			validation_categories: categories,
		}
	}

	pub fn with_validation_categories(mut self, categories: HashSet<u32>) -> Self {
		self.validation_categories = categories;
		self
	}

	pub fn from_env(env: &HashMap<String, String>) -> Result<Option<Self>, String> {
		let team_id = env
			.get("VERILY_APPLE_TEAM_ID")
			.map(|v| v.trim().to_string())
			.unwrap_or_default();
		let bundle_id = env
			.get("VERILY_IOS_BUNDLE_ID")
			.map(|v| v.trim().to_string())
			.unwrap_or_default();
		let environment = match env
			.get("VERILY_APP_ATTEST_ENVIRONMENT")
			.map(|v| v.trim())
			.unwrap_or("")
		{
			"" | "production" => AppAttestEnvironment::Production,
			"development" => AppAttestEnvironment::Development,
			other => {
				return Err(format!(
					"VERILY_APP_ATTEST_ENVIRONMENT must be production or development, not {other}."
				));
			}
		};
		if !bundle_id.is_empty() && !is_valid_bundle_id(&bundle_id) {
			return Err("VERILY_IOS_BUNDLE_ID must be a bundle identifier.".to_string());
		}
		if team_id.is_empty() {
			return Ok(None);
		}
		if !is_valid_team_id(&team_id) {
			return Err(
				"VERILY_APPLE_TEAM_ID must be the ten-character Apple team id.".to_string(),
			);
		}
		Ok(Some(Self::with_environment(
			team_id,
			if bundle_id.is_empty() {
				VERILY_IOS_BUNDLE_ID.to_string()
			} else {
				bundle_id
			},
			environment,
		)))
	}

	pub fn app_id(&self) -> String {
		format!("{}.{}", self.team_id, self.bundle_id)
	}

	pub fn rp_id_hash(&self) -> [u8; 32] {
		Sha256::digest(self.app_id().as_bytes()).into()
	}

	pub fn aaguid(&self) -> [u8; 16] {
		match self.environment {
			AppAttestEnvironment::Production => *b"appattest\0\0\0\0\0\0\0",
			AppAttestEnvironment::Development => *b"appattestdevelop",
		}
	}
}

fn is_valid_team_id(value: &str) -> bool {
	value.len() == 10
		&& value
			.bytes()
			.all(|b| b.is_ascii_uppercase() || b.is_ascii_digit())
}

fn is_valid_bundle_id(value: &str) -> bool {
	let parts: Vec<&str> = value.split('.').collect();
	parts.len() >= 2
		&& parts.iter().all(|part| {
			!part.is_empty() && part.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-')
		})
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppAttestedKey {
	pub public_key: Vec<u8>,
	pub certificate_chain: Vec<Vec<u8>>,
	pub receipt: Vec<u8>,
	pub validation_category: Option<u32>,
	pub bundle_version: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppAttestAttestationVerdict {
	pub reason_code: &'static str,
	pub key: Option<AppAttestedKey>,
}

impl AppAttestAttestationVerdict {
	pub fn trusted(key: AppAttestedKey) -> Self {
		Self {
			reason_code: reason::VALID,
			key: Some(key),
		}
	}

	pub fn untrusted(reason_code: &'static str) -> Self {
		Self {
			reason_code,
			key: None,
		}
	}

	pub fn is_trusted(&self) -> bool {
		self.key.is_some()
	}
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppAssertionVerdict {
	pub reason_code: &'static str,
	pub counter: Option<u32>,
}

impl AppAssertionVerdict {
	pub fn trusted(counter: u32) -> Self {
		Self {
			reason_code: reason::VALID,
			counter: Some(counter),
		}
	}

	pub fn untrusted(reason_code: &'static str) -> Self {
		Self {
			reason_code,
			counter: None,
		}
	}

	pub fn is_trusted(&self) -> bool {
		self.counter.is_some()
	}
}

#[derive(Debug, Clone)]
pub struct AttestedCredential {
	pub aaguid: [u8; 16],
	pub credential_id: Vec<u8>,
	pub public_key: Vec<u8>,
}

#[derive(Debug, Clone)]
pub struct AppAttestAuthenticatorData {
	pub rp_id_hash: [u8; 32],
	pub counter: u32,
	pub credential: Option<AttestedCredential>,
	pub validation_category: Option<u32>,
	pub bundle_version: Option<String>,
}

impl AppAttestAuthenticatorData {
	pub fn attested(bytes: &[u8]) -> Result<Self, String> {
		if bytes.len() < 37 + 16 + 2 {
			return Err("Truncated attested authenticator data.".to_string());
		}
		let rp_id_hash: [u8; 32] = bytes[0..32].try_into().unwrap();
		let counter = u32::from_be_bytes(bytes[33..37].try_into().unwrap());
		let aaguid: [u8; 16] = bytes[37..53].try_into().unwrap();
		let cred_len = usize::from(u16::from_be_bytes(bytes[53..55].try_into().unwrap()));
		let cred_end = 55usize
			.checked_add(cred_len)
			.ok_or_else(|| "Credential id overflow.".to_string())?;
		if cred_end > bytes.len() {
			return Err("Truncated credential id.".to_string());
		}
		let credential_id = bytes[55..cred_end].to_vec();
		let mut cursor = Cursor::new(&bytes[cred_end..]);
		let cose: CborValue =
			ciborium::from_reader(&mut cursor).map_err(|e| format!("Malformed COSE key: {e}"))?;
		let public_key = decode_cose_p256(&cose)?;
		let rest = &bytes[cred_end + cursor.position() as usize..];
		let (validation_category, bundle_version) = parse_apple_extensions(rest)?;
		Ok(Self {
			rp_id_hash,
			counter,
			credential: Some(AttestedCredential {
				aaguid,
				credential_id,
				public_key,
			}),
			validation_category,
			bundle_version,
		})
	}

	pub fn asserted(bytes: &[u8]) -> Result<Self, String> {
		if bytes.len() < 37 {
			return Err("Truncated assertion authenticator data.".to_string());
		}
		let rp_id_hash: [u8; 32] = bytes[0..32].try_into().unwrap();
		let counter = u32::from_be_bytes(bytes[33..37].try_into().unwrap());
		let (validation_category, bundle_version) = parse_apple_extensions(&bytes[37..])?;
		Ok(Self {
			rp_id_hash,
			counter,
			credential: None,
			validation_category,
			bundle_version,
		})
	}
}

fn parse_apple_extensions(rest: &[u8]) -> Result<(Option<u32>, Option<String>), String> {
	if rest.is_empty() {
		return Ok((None, None));
	}
	let mut cursor = Cursor::new(rest);
	let value: CborValue = ciborium::from_reader(&mut cursor)
		.map_err(|e| format!("Malformed authenticator extensions: {e}"))?;
	if cursor.position() as usize != rest.len() {
		return Err("Trailing bytes after authenticator extensions.".to_string());
	}
	let map = value
		.as_map()
		.ok_or_else(|| "Extensions must be a CBOR map.".to_string())?;
	let mut category: Option<u32> = None;
	let mut bundle_version: Option<String> = None;
	for (k, v) in map {
		let key = k
			.as_text()
			.ok_or_else(|| "Extension keys must be text.".to_string())?;
		match key {
			VALIDATION_CATEGORY_KEY => {
				let bytes = v
					.as_bytes()
					.ok_or_else(|| "Validation category must be bytes.".to_string())?;
				if bytes.len() != 4 {
					return Err("Validation category must be 4 little-endian bytes.".to_string());
				}
				category = Some(u32::from_le_bytes(bytes.as_slice().try_into().unwrap()));
			}
			BUNDLE_VERSION_KEY => {
				let text = v
					.as_text()
					.ok_or_else(|| "Bundle version must be text.".to_string())?;
				if text.is_empty() || text.len() > 64 {
					return Err("Bundle version must be 1..=64 chars.".to_string());
				}
				bundle_version = Some(text.to_string());
			}
			_ => {}
		}
	}
	Ok((category, bundle_version))
}

fn decode_cose_p256(value: &CborValue) -> Result<Vec<u8>, String> {
	let entries = value
		.as_map()
		.ok_or_else(|| "Expected COSE key map.".to_string())?;
	if entries.len() != 5 {
		return Err("Expected 5-entry COSE EC2 P-256 key.".to_string());
	}
	let mut kty = None;
	let mut alg = None;
	let mut crv = None;
	let mut x: Option<&[u8]> = None;
	let mut y: Option<&[u8]> = None;
	for (k, v) in entries {
		let key_int: i128 = k
			.as_integer()
			.map(Into::into)
			.ok_or_else(|| "COSE key label must be integer.".to_string())?;
		match key_int {
			1 => kty = v.as_integer().map(i128::from),
			3 => alg = v.as_integer().map(i128::from),
			-1 => crv = v.as_integer().map(i128::from),
			-2 => x = v.as_bytes().map(Vec::as_slice),
			-3 => y = v.as_bytes().map(Vec::as_slice),
			_ => return Err("Unexpected COSE key parameter.".to_string()),
		}
	}
	let (Some(x), Some(y)) = (x, y) else {
		return Err("Missing COSE coordinates.".to_string());
	};
	if kty != Some(2) || alg != Some(-7) || crv != Some(1) || x.len() != 32 || y.len() != 32 {
		return Err("Expected P-256 ES256 COSE key.".to_string());
	}
	let mut point = Vec::with_capacity(65);
	point.push(0x04);
	point.extend_from_slice(x);
	point.extend_from_slice(y);
	Ok(point)
}

fn cbor_decode_exact(bytes: &[u8]) -> Result<CborValue, String> {
	let mut cursor = Cursor::new(bytes);
	let value: CborValue =
		ciborium::from_reader(&mut cursor).map_err(|e| format!("Invalid CBOR: {e}"))?;
	if cursor.position() as usize != bytes.len() {
		return Err("Trailing CBOR bytes.".to_string());
	}
	Ok(value)
}

fn cbor_map_get<'a>(entries: &'a [(CborValue, CborValue)], key: &str) -> Option<&'a CborValue> {
	entries
		.iter()
		.find(|(k, _)| k.as_text() == Some(key))
		.map(|(_, v)| v)
}

#[derive(Clone)]
pub struct AppAttestVerifier {
	pub policy: AppAttestPolicy,
	pub trust_anchors: Vec<X509Certificate>,
}

impl AppAttestVerifier {
	pub fn new(policy: AppAttestPolicy) -> Self {
		Self {
			policy,
			trust_anchors: apple_app_attestation_roots(),
		}
	}

	pub fn with_trust_anchors(mut self, anchors: Vec<X509Certificate>) -> Self {
		self.trust_anchors = anchors;
		self
	}

	pub fn verify_attestation(
		&self,
		attestation_object: &[u8],
		key_id: &[u8],
		client_data_hash: &[u8],
		now: DateTime<Utc>,
	) -> AppAttestAttestationVerdict {
		let Ok(root_val) = cbor_decode_exact(attestation_object) else {
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		};
		let Some(root_map) = root_val.as_map() else {
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		};
		if root_map.len() != 3
			|| cbor_map_get(root_map, "fmt").and_then(CborValue::as_text) != Some("apple-appattest")
		{
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		}
		let Some(att_stmt) = cbor_map_get(root_map, "attStmt").and_then(CborValue::as_map) else {
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		};
		let Some(auth_data) = cbor_map_get(root_map, "authData").and_then(CborValue::as_bytes)
		else {
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		};
		if att_stmt.len() != 2 {
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		}
		let Some(x5c_arr) = cbor_map_get(att_stmt, "x5c").and_then(CborValue::as_array) else {
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		};
		let Some(receipt) = cbor_map_get(att_stmt, "receipt").and_then(CborValue::as_bytes) else {
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		};
		if x5c_arr.len() < 2 || x5c_arr.len() > MAX_CHAIN_LENGTH || receipt.is_empty() {
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		}
		let mut x5c = Vec::with_capacity(x5c_arr.len());
		for entry in x5c_arr {
			let Some(bytes) = entry.as_bytes() else {
				return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
			};
			x5c.push(bytes.clone());
		}

		let mut certs = Vec::with_capacity(x5c.len());
		for der in &x5c {
			match X509Certificate::parse(der) {
				Ok(cert) => certs.push(cert),
				Err(_) => return AppAttestAttestationVerdict::untrusted(reason::CHAIN_INVALID),
			}
		}

		if let Some(failure) = self.validate_path(&certs, now) {
			return AppAttestAttestationVerdict::untrusted(failure);
		}

		let Ok(data) = AppAttestAuthenticatorData::attested(auth_data) else {
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		};
		let Some(credential) = &data.credential else {
			return AppAttestAttestationVerdict::untrusted(reason::MALFORMED);
		};

		let cred_cert = &certs[0];
		let mut hasher = Sha256::new();
		hasher.update(auth_data);
		hasher.update(client_data_hash);
		let nonce = hasher.finalize();

		let Ok(Some(certified_nonce)) = certified_nonce(cred_cert) else {
			return AppAttestAttestationVerdict::untrusted(reason::NONCE_MISMATCH);
		};
		if !constant_time_eq(&certified_nonce, &nonce) {
			return AppAttestAttestationVerdict::untrusted(reason::NONCE_MISMATCH);
		}

		let Some(cert_point) = cred_cert.public_key.p256_point() else {
			return AppAttestAttestationVerdict::untrusted(reason::KEY_INVALID);
		};
		let cert_key_digest = Sha256::digest(cert_point);
		if !constant_time_eq(&cert_key_digest, key_id)
			|| !constant_time_eq(&credential.credential_id, key_id)
			|| !constant_time_eq(&credential.public_key, cert_point)
		{
			return AppAttestAttestationVerdict::untrusted(reason::KEY_INVALID);
		}
		if !constant_time_eq(&data.rp_id_hash, &self.policy.rp_id_hash()) {
			return AppAttestAttestationVerdict::untrusted(reason::APP_MISMATCH);
		}
		if data.counter != 0 {
			return AppAttestAttestationVerdict::untrusted(reason::COUNTER_INVALID);
		}
		if !constant_time_eq(&credential.aaguid, &self.policy.aaguid()) {
			return AppAttestAttestationVerdict::untrusted(reason::ENVIRONMENT_MISMATCH);
		}
		if !self.category_allowed(data.validation_category) {
			return AppAttestAttestationVerdict::untrusted(reason::CATEGORY_REFUSED);
		}

		AppAttestAttestationVerdict::trusted(AppAttestedKey {
			public_key: cert_point.to_vec(),
			certificate_chain: x5c,
			receipt: receipt.clone(),
			validation_category: data.validation_category,
			bundle_version: data.bundle_version,
		})
	}

	pub fn verify_assertion(
		&self,
		assertion: &[u8],
		client_data: &[u8],
		public_key: &[u8],
		previous_counter: u32,
	) -> AppAssertionVerdict {
		let Ok(root_val) = cbor_decode_exact(assertion) else {
			return AppAssertionVerdict::untrusted(reason::MALFORMED);
		};
		let Some(root_map) = root_val.as_map() else {
			return AppAssertionVerdict::untrusted(reason::MALFORMED);
		};
		if root_map.len() != 2 {
			return AppAssertionVerdict::untrusted(reason::MALFORMED);
		}
		let Some(signature) = cbor_map_get(root_map, "signature").and_then(CborValue::as_bytes)
		else {
			return AppAssertionVerdict::untrusted(reason::MALFORMED);
		};
		let Some(auth_data) =
			cbor_map_get(root_map, "authenticatorData").and_then(CborValue::as_bytes)
		else {
			return AppAssertionVerdict::untrusted(reason::MALFORMED);
		};
		let Ok(data) = AppAttestAuthenticatorData::asserted(auth_data) else {
			return AppAssertionVerdict::untrusted(reason::MALFORMED);
		};

		let mut nonce_hasher = Sha256::new();
		nonce_hasher.update(auth_data);
		nonce_hasher.update(Sha256::digest(client_data));
		let nonce = nonce_hasher.finalize();

		if signature.len() > MAX_DER_SIGNATURE
			|| !verify_ecdsa_der(
				oid::SECP256R1,
				public_key,
				&nonce,
				oid::ECDSA_WITH_SHA256,
				signature,
			) {
			return AppAssertionVerdict::untrusted(reason::SIGNATURE_INVALID);
		}
		if !constant_time_eq(&data.rp_id_hash, &self.policy.rp_id_hash()) {
			return AppAssertionVerdict::untrusted(reason::APP_MISMATCH);
		}
		if data.counter <= previous_counter {
			return AppAssertionVerdict::untrusted(reason::REPLAYED);
		}
		if !self.category_allowed(data.validation_category) {
			return AppAssertionVerdict::untrusted(reason::CATEGORY_REFUSED);
		}
		AppAssertionVerdict::trusted(data.counter)
	}

	fn category_allowed(&self, category: Option<u32>) -> bool {
		match category {
			None => true,
			Some(c) => self.policy.validation_categories.contains(&c),
		}
	}

	fn validate_path(&self, certs: &[X509Certificate], now: DateTime<Utc>) -> Option<&'static str> {
		let Some(top) = certs.last() else {
			return Some(reason::CHAIN_INVALID);
		};
		let Some(_anchor) = self.trust_anchors.iter().find(|anchor| {
			anchor.subject.matches(&top.issuer) && top.is_signed_by(&anchor.public_key)
		}) else {
			return Some(reason::UNTRUSTED_ROOT);
		};
		for idx in (0..certs.len()).rev() {
			let cert = &certs[idx];
			if idx != certs.len() - 1 {
				let issuer = &certs[idx + 1];
				if !cert.issuer.matches(&issuer.subject) || !cert.is_signed_by(&issuer.public_key) {
					return Some(reason::CHAIN_INVALID);
				}
			}
			if idx > 0 && cert.extensions.contains_key(APP_ATTEST_NONCE_EXTENSION_OID) {
				return Some(reason::CHAIN_INVALID);
			}
			if !cert.is_valid_at(now) {
				return Some(reason::EXPIRED);
			}
		}
		None
	}
}

fn certified_nonce(cert: &X509Certificate) -> Result<Option<Vec<u8>>, DerError> {
	let Some(ext) = cert.extensions.get(APP_ATTEST_NONCE_EXTENSION_OID) else {
		return Ok(None);
	};
	let fields = parse_der(ext)?.sequence()?;
	if fields.len() != 1 || !fields[0].is_context(1) {
		return Err(DerError::new("Malformed App Attest nonce extension."));
	}
	Ok(Some(fields[0].explicit()?.octets()?.to_vec()))
}

/// Verified Apple App Attest receipt metadata.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppAttestReceipt {
	pub created_at: DateTime<Utc>,
	pub not_before: DateTime<Utc>,
	pub expires_at: DateTime<Utc>,
	pub risk_metric: Option<u32>,
}

/// Verifies PKCS#7 Apple App Attest receipts up to pinned Apple Root CA - G3.
#[derive(Clone)]
pub struct AppAttestReceiptVerifier {
	pub root: X509Certificate,
}

impl Default for AppAttestReceiptVerifier {
	fn default() -> Self {
		Self {
			root: apple_receipt_root(),
		}
	}
}

impl AppAttestReceiptVerifier {
	pub fn verify(
		&self,
		receipt: &[u8],
		app_id: &str,
		public_key: &[u8],
		now: DateTime<Utc>,
		refreshed: bool,
	) -> Result<AppAttestReceipt, DerError> {
		if receipt.is_empty() || receipt.len() > MAX_RECEIPT_BYTES {
			return Err(DerError::new("Invalid App Attest receipt length."));
		}
		let normalized = normalize_receipt_ber(receipt)?;
		let content = parse_der(&normalized)?.sequence()?;
		if content.len() != 2 || content[0].object_identifier()? != OID_SIGNED_DATA {
			return Err(DerError::new("Invalid PKCS#7 ContentInfo."));
		}
		let signed = content[1].explicit()?.sequence()?;
		if signed.len() != 5 || signed[0].small_int()? != 1 {
			return Err(DerError::new("Invalid PKCS#7 SignedData."));
		}
		let digests = signed[1].set()?;
		if digests.len() != 1 || algorithm_oid(digests[0])? != OID_SHA256 {
			return Err(DerError::new("Receipt digest must be SHA-256."));
		}
		let encap = signed[2].sequence()?;
		if encap.len() != 2 || encap[0].object_identifier()? != OID_DATA || !encap[1].is_context(0)
		{
			return Err(DerError::new("Invalid PKCS#7 EncapsulatedContentInfo."));
		}
		let payload = encap[1].explicit()?.octets()?;
		if !signed[3].is_context(0) {
			return Err(DerError::new("Missing receipt certificates."));
		}
		let mut certs = Vec::new();
		for node in signed[3].children()? {
			certs.push(X509Certificate::parse(node.encoded())?);
		}
		if certs.is_empty() || certs.len() > 5 {
			return Err(DerError::new("Invalid receipt certificate count."));
		}
		let signers = signed[4].set()?;
		if signers.len() != 1 {
			return Err(DerError::new("Expected one receipt SignerInfo."));
		}
		let signer = signers[0].sequence()?;
		if signer.len() < 5 || signer[0].small_int()? != 1 {
			return Err(DerError::new("Invalid SignerInfo."));
		}
		let issuer_and_serial = signer[1].sequence()?;
		if issuer_and_serial.len() != 2 {
			return Err(DerError::new("Invalid issuerAndSerialNumber."));
		}
		let expected_issuer = issuer_and_serial[0].encoded();
		let expected_serial = issuer_and_serial[1].integer_bytes()?;
		let matching: Vec<&X509Certificate> = certs
			.iter()
			.filter(|c| c.issuer.encoded == expected_issuer && c.serial_bytes == expected_serial)
			.collect();
		if matching.len() != 1 || algorithm_oid(signer[2])? != OID_SHA256 {
			return Err(DerError::new(
				"Receipt signer certificate not uniquely matched.",
			));
		}
		let leaf = matching[0];
		if !leaf.extensions.contains_key(OID_APPLE_APP_ATTEST_RECEIPT) {
			return Err(DerError::new(
				"Receipt signer lacks Apple App Attest receipt OID.",
			));
		}
		if let Some(bc) = leaf.extensions.get("2.5.29.19") {
			let seq = parse_der(bc)?.sequence()?;
			if !seq.is_empty() && seq[0].boolean()? {
				return Err(DerError::new("Receipt leaf must not be a CA."));
			}
		}
		if let Some(ku) = leaf.extensions.get("2.5.29.15") {
			let bits = parse_der(ku)?.content();
			if bits.len() < 2 || (bits[1] & 0x80) == 0 {
				return Err(DerError::new(
					"Receipt leaf lacks digitalSignature keyUsage.",
				));
			}
		}
		self.verify_receipt_path(leaf, &certs, now)?;

		let mut idx = 3usize;
		let signed_message: Vec<u8> = if signer[idx].is_context(0) {
			let attrs = signer[idx];
			idx += 1;
			let mut values: BTreeMap<String, crate::asn1::DerElement<'_>> = BTreeMap::new();
			for attr in attrs.children()? {
				let parts = attr.sequence()?;
				if parts.len() != 2 {
					return Err(DerError::new("Malformed signed attribute."));
				}
				let attr_oid = parts[0].object_identifier()?;
				let set = parts[1].set()?;
				if set.len() != 1 || values.insert(attr_oid, set[0]).is_some() {
					return Err(DerError::new("Duplicate or multi-valued signed attribute."));
				}
			}
			let ct_ok = values
				.get(OID_CONTENT_TYPE)
				.and_then(|e| e.object_identifier().ok())
				.is_some_and(|v| v == OID_DATA);
			let md_ok = values
				.get(OID_MESSAGE_DIGEST)
				.and_then(|e| e.octets().ok())
				.is_some_and(|v| constant_time_eq(v, &Sha256::digest(payload)));
			if !ct_ok || !md_ok {
				return Err(DerError::new("Receipt signed attributes mismatch."));
			}
			let mut set_der = attrs.encoded().to_vec();
			set_der[0] = 0x31;
			set_der
		} else {
			payload.to_vec()
		};

		if signer.len() != idx + 2 {
			return Err(DerError::new("Unexpected trailing SignerInfo fields."));
		}
		let sig_alg = match algorithm_oid(signer[idx])?.as_str() {
			oid::RSA_ENCRYPTION | oid::SHA256_WITH_RSA => oid::SHA256_WITH_RSA,
			oid::ECDSA_WITH_SHA256 => oid::ECDSA_WITH_SHA256,
			_ => return Err(DerError::new("Unsupported receipt signature algorithm.")),
		};
		let sig_bytes = signer[idx + 1].octets()?;
		if !leaf
			.public_key
			.verifies(&signed_message, sig_alg, sig_bytes)
		{
			return Err(DerError::new("Receipt signature invalid."));
		}

		let mut fields: BTreeMap<i64, Vec<u8>> = BTreeMap::new();
		for entry in parse_der(payload)?.set()? {
			let parts = entry.sequence()?;
			if parts.len() != 3 || parts[1].small_int()? != 1 {
				return Err(DerError::new("Malformed receipt attribute."));
			}
			let id = parts[0].small_int()?;
			if fields.insert(id, parts[2].octets()?.to_vec()).is_some() {
				return Err(DerError::new("Duplicate receipt field."));
			}
		}
		let text = |id: i64| -> Result<String, DerError> {
			let bytes = fields
				.get(&id)
				.ok_or_else(|| DerError::new("Missing receipt field."))?;
			std::str::from_utf8(bytes)
				.map(str::to_string)
				.map_err(|_| DerError::new("Non-UTF-8 receipt field."))
		};

		if text(2)? != app_id || text(6)? != if refreshed { "RECEIPT" } else { "ATTEST" } {
			return Err(DerError::new("Receipt app id or type mismatch."));
		}
		let cert_field = fields
			.get(&3)
			.ok_or_else(|| DerError::new("Missing receipt credential cert."))?;
		let key_cert = X509Certificate::parse(cert_field)?;
		let Some(point) = key_cert.public_key.p256_point() else {
			return Err(DerError::new("Receipt key is not P-256."));
		};
		if !constant_time_eq(point, public_key) {
			return Err(DerError::new("Receipt public key mismatch."));
		}

		let created_at = parse_rfc3339_utc(&text(12)?)?;
		if created_at > now || now.signed_duration_since(created_at) > chrono::Duration::minutes(5)
		{
			return Err(DerError::new("Receipt creation time out of window."));
		}
		let not_before = if fields.contains_key(&19) {
			parse_rfc3339_utc(&text(19)?)?
		} else {
			created_at
		};
		let expires_at = parse_rfc3339_utc(&text(21)?)?;
		if expires_at <= now || expires_at <= not_before || not_before < created_at {
			return Err(DerError::new("Receipt validity window invalid."));
		}
		let risk_metric = if refreshed {
			let raw = text(17)?;
			if raw.is_empty() || raw.len() > 9 || !raw.bytes().all(|b| b.is_ascii_digit()) {
				return Err(DerError::new("Invalid receipt risk metric."));
			}
			Some(
				raw.parse::<u32>()
					.map_err(|_| DerError::new("Invalid receipt risk metric number."))?,
			)
		} else {
			None
		};

		Ok(AppAttestReceipt {
			created_at,
			not_before,
			expires_at,
			risk_metric,
		})
	}

	fn verify_receipt_path(
		&self,
		leaf: &X509Certificate,
		certs: &[X509Certificate],
		now: DateTime<Utc>,
	) -> Result<(), DerError> {
		let mut current = leaf;
		let mut seen: HashSet<Vec<u8>> = HashSet::new();
		for depth in 0..5usize {
			check_critical_extensions(current)?;
			if !current.is_valid_at(now) || !seen.insert(current.encoded.clone()) {
				return Err(DerError::new("Receipt cert expired or cyclic."));
			}
			if current.issuer.matches(&self.root.subject)
				&& current.is_signed_by(&self.root.public_key)
			{
				if !self.root.is_valid_at(now) {
					return Err(DerError::new("Apple receipt root expired."));
				}
				return Ok(());
			}
			let matching: Vec<&X509Certificate> = certs
				.iter()
				.filter(|c| {
					current.issuer.matches(&c.subject) && current.is_signed_by(&c.public_key)
				})
				.collect();
			if matching.len() != 1 {
				return Err(DerError::new("Receipt chain does not link to Apple G3."));
			}
			let issuer = matching[0];
			let Some(bc) = issuer.extensions.get("2.5.29.19") else {
				return Err(DerError::new(
					"Receipt intermediate missing basicConstraints.",
				));
			};
			let basic = parse_der(bc)?.sequence()?;
			if basic.is_empty() || !basic[0].boolean()? {
				return Err(DerError::new("Receipt intermediate is not a CA."));
			}
			if let Some(ku) = issuer.extensions.get("2.5.29.15") {
				let bits = parse_der(ku)?.content();
				if bits.len() < 2 || (bits[1] & 0x04) == 0 {
					return Err(DerError::new("Receipt intermediate lacks keyCertSign."));
				}
			}
			if basic.len() > 1 && depth as i64 > basic[1].small_int()? {
				return Err(DerError::new(
					"Receipt intermediate pathLenConstraint exceeded.",
				));
			}
			current = issuer;
		}
		Err(DerError::new("Receipt chain exceeded maximum depth."))
	}
}

fn parse_rfc3339_utc(value: &str) -> Result<DateTime<Utc>, DerError> {
	if !value.ends_with('Z') {
		return Err(DerError::new("Receipt time must end with Z."));
	}
	DateTime::parse_from_rfc3339(value)
		.map(|dt| dt.with_timezone(&Utc))
		.map_err(|_| DerError::new("Malformed receipt timestamp."))
}

fn check_critical_extensions(cert: &X509Certificate) -> Result<(), DerError> {
	for field in parse_der(&cert.tbs)?.sequence()? {
		if !field.is_context(3) {
			continue;
		}
		for ext in field.explicit()?.sequence()? {
			let parts = ext.sequence()?;
			if parts.len() == 3 && parts[1].boolean()? {
				let ext_oid = parts[0].object_identifier()?;
				if ext_oid != "2.5.29.19" && ext_oid != "2.5.29.15" {
					return Err(DerError::new(
						"Unsupported critical extension in receipt cert.",
					));
				}
			}
		}
	}
	Ok(())
}

/// Apple DeviceCheck durable two-bit state.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AppleDeviceBits {
	pub banned: bool,
	pub review_required: bool,
}

#[derive(Debug, Clone, thiserror::Error)]
#[error("Apple DeviceCheck or App Attest service unavailable")]
pub struct AppleDeviceUnavailable;

pub fn valid_device_check_token(token: &str) -> bool {
	if token.is_empty() || token.len() > 8192 {
		return false;
	}
	if !token
		.bytes()
		.all(|b| b.is_ascii_alphanumeric() || matches!(b, b'+' | b'/' | b'='))
	{
		return false;
	}
	STANDARD.decode(token).is_ok_and(|bytes| !bytes.is_empty())
}

/// Builds an APNs/DeviceCheck ES256 JWT using Apple's PKCS#8 P-256 `.p8` key.
pub fn device_check_jwt(
	pem: &str,
	key_id: &str,
	team_id: &str,
	now: DateTime<Utc>,
) -> Result<String, AppleDeviceUnavailable> {
	if !is_valid_team_id(key_id) || !is_valid_team_id(team_id) {
		return Err(AppleDeviceUnavailable);
	}
	let signing_key = SigningKey::from_pkcs8_pem(pem).map_err(|_| AppleDeviceUnavailable)?;
	let header = serde_json::json!({
		"alg": "ES256",
		"kid": key_id,
		"typ": "JWT",
	});
	let claims = serde_json::json!({
		"iss": team_id,
		"iat": now.timestamp(),
	});
	let encoded_header = URL_SAFE_NO_PAD.encode(header.to_string().as_bytes());
	let encoded_claims = URL_SAFE_NO_PAD.encode(claims.to_string().as_bytes());
	let signing_input = format!("{encoded_header}.{encoded_claims}");
	let sig: p256::ecdsa::Signature = signing_key.sign(signing_input.as_bytes());
	let encoded_sig = URL_SAFE_NO_PAD.encode(sig.to_bytes());
	Ok(format!("{signing_input}.{encoded_sig}"))
}

/// HTTP client for Apple App Attest receipt refresh and DeviceCheck two-bit APIs.
#[derive(Clone)]
pub struct HttpAppleDeviceClient {
	policy: AppAttestPolicy,
	key_id: String,
	private_key_pem: Option<String>,
	client: reqwest::Client,
}

impl HttpAppleDeviceClient {
	pub fn new(
		policy: AppAttestPolicy,
		key_id: impl Into<String>,
		private_key_pem: Option<String>,
	) -> Self {
		let client = reqwest::Client::builder()
			.timeout(Duration::from_secs(10))
			.redirect(reqwest::redirect::Policy::none())
			.user_agent("Verily")
			.build()
			.expect("reqwest client builds");
		Self {
			policy,
			key_id: key_id.into(),
			private_key_pem,
			client,
		}
	}

	fn is_development(&self) -> bool {
		self.policy.environment == AppAttestEnvironment::Development
	}

	pub async fn refresh_receipt(
		&self,
		receipt_b64: &str,
		now: DateTime<Utc>,
	) -> Result<String, AppleDeviceUnavailable> {
		let host = if self.is_development() {
			"data-development.appattest.apple.com"
		} else {
			"data.appattest.apple.com"
		};
		let body = self
			.post(host, "/v1/attestationData", receipt_b64, false, now)
			.await?;
		if body.is_empty() || body.len() > MAX_APPLE_RESPONSE_BYTES {
			return Err(AppleDeviceUnavailable);
		}
		Ok(body.trim().to_string())
	}

	pub async fn query_bits(
		&self,
		device_token: &str,
		transaction_id: &str,
		now: DateTime<Utc>,
	) -> Result<AppleDeviceBits, AppleDeviceUnavailable> {
		let body = self
			.device_check("query_two_bits", device_token, transaction_id, None, now)
			.await?;
		if body.trim() == "Bit State Not Found" {
			return Ok(AppleDeviceBits {
				banned: false,
				review_required: false,
			});
		}
		let parsed: serde_json::Value =
			serde_json::from_str(&body).map_err(|_| AppleDeviceUnavailable)?;
		let banned = parsed
			.get("bit0")
			.and_then(serde_json::Value::as_bool)
			.ok_or(AppleDeviceUnavailable)?;
		let review_required = parsed
			.get("bit1")
			.and_then(serde_json::Value::as_bool)
			.ok_or(AppleDeviceUnavailable)?;
		Ok(AppleDeviceBits {
			banned,
			review_required,
		})
	}

	pub async fn update_bits(
		&self,
		device_token: &str,
		transaction_id: &str,
		bits: AppleDeviceBits,
		now: DateTime<Utc>,
	) -> Result<(), AppleDeviceUnavailable> {
		self.device_check(
			"update_two_bits",
			device_token,
			transaction_id,
			Some(bits),
			now,
		)
		.await?;
		Ok(())
	}

	async fn device_check(
		&self,
		operation: &str,
		token: &str,
		transaction_id: &str,
		bits: Option<AppleDeviceBits>,
		now: DateTime<Utc>,
	) -> Result<String, AppleDeviceUnavailable> {
		if !valid_device_check_token(token) {
			return Err(AppleDeviceUnavailable);
		}
		let host = if self.is_development() {
			"api.development.devicecheck.apple.com"
		} else {
			"api.devicecheck.apple.com"
		};
		let mut payload = serde_json::json!({
			"device_token": token,
			"transaction_id": transaction_id,
			"timestamp": now.timestamp_millis(),
		});
		if let Some(bits) = bits {
			payload["bit0"] = serde_json::Value::Bool(bits.banned);
			payload["bit1"] = serde_json::Value::Bool(bits.review_required);
		}
		self.post(
			host,
			&format!("/v1/{operation}"),
			&payload.to_string(),
			true,
			now,
		)
		.await
	}

	async fn post(
		&self,
		host: &str,
		path: &str,
		body: &str,
		bearer: bool,
		now: DateTime<Utc>,
	) -> Result<String, AppleDeviceUnavailable> {
		let pem = self
			.private_key_pem
			.as_deref()
			.ok_or(AppleDeviceUnavailable)?;
		let jwt = device_check_jwt(pem, &self.key_id, &self.policy.team_id, now)?;
		let auth_header = if bearer { format!("Bearer {jwt}") } else { jwt };
		let content_type = if bearer {
			"application/json"
		} else {
			"application/octet-stream"
		};
		let url = format!("https://{host}{path}");
		let response = self
			.client
			.post(url)
			.header("authorization", auth_header)
			.header("content-type", content_type)
			.body(body.to_string())
			.send()
			.await
			.map_err(|_| AppleDeviceUnavailable)?;
		if !response.status().is_success() {
			return Err(AppleDeviceUnavailable);
		}
		let bytes = response.bytes().await.map_err(|_| AppleDeviceUnavailable)?;
		if bytes.len() > MAX_APPLE_RESPONSE_BYTES {
			return Err(AppleDeviceUnavailable);
		}
		String::from_utf8(bytes.to_vec()).map_err(|_| AppleDeviceUnavailable)
	}
}
