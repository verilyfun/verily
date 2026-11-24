//! Verily device attestation bridge plugin (`"verily-attest"`).
//!
//! - Android generates a fresh P-256 key in `AndroidKeyStore` (StrongBox
//!   preferred, TEE fallback) per capture window with `setAttestationChallenge`,
//!   signs the capture manifest (DER -> IEEE P1363 64-byte `r || s`) alongside
//!   the full X.509 attestation certificate chain, and requests Google Play
//!   Integrity Standard API tokens bound to `request_hash`.
//! - iOS wraps `DCAppAttestService` (one Secure Enclave key per account stored
//!   in `ThisDeviceOnly` Keychain) and `DCDevice.current.generateToken`.

use leptoskit_bridge::codec::{Decoder, Encoder};
use leptoskit_bridge::{Bytes, Error, MethodId};

/// Runtime plugin name in `leptoskit.toml`.
pub const NAME: &str = "verily-attest";

// Android methods
pub const PREPARE_CAPTURE_KEY: MethodId = MethodId(0);
pub const SIGN_CAPTURE_MANIFEST: MethodId = MethodId(1);
pub const REQUEST_PLAY_INTEGRITY: MethodId = MethodId(2);

// iOS methods
pub const APP_ATTEST_SUPPORTED: MethodId = MethodId(10);
pub const READ_APP_ATTEST_KEY: MethodId = MethodId(11);
pub const GENERATE_APP_ATTEST_KEY: MethodId = MethodId(12);
pub const ATTEST_APP_ATTEST_KEY: MethodId = MethodId(13);
pub const MARK_APP_ATTEST_REGISTERED: MethodId = MethodId(14);
pub const GENERATE_APP_ATTEST_ASSERTION: MethodId = MethodId(15);
pub const DISCARD_APP_ATTEST_KEY: MethodId = MethodId(16);
pub const GENERATE_DEVICE_CHECK_TOKEN: MethodId = MethodId(17);

pub const METHODS: &[MethodId] = &[
	PREPARE_CAPTURE_KEY,
	SIGN_CAPTURE_MANIFEST,
	REQUEST_PLAY_INTEGRITY,
	APP_ATTEST_SUPPORTED,
	READ_APP_ATTEST_KEY,
	GENERATE_APP_ATTEST_KEY,
	ATTEST_APP_ATTEST_KEY,
	MARK_APP_ATTEST_REGISTERED,
	GENERATE_APP_ATTEST_ASSERTION,
	DISCARD_APP_ATTEST_KEY,
	GENERATE_DEVICE_CHECK_TOKEN,
];

pub const MAX_ATTESTATION_CHALLENGE_BYTES: usize = 128;
pub const MAX_MANIFEST_BYTES: usize = 4096;
pub const MAX_CHAIN_CERTS: usize = 16;

/// Android request to generate a per-window attested capture key.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PrepareCaptureKey {
	pub capture_id: String,
	pub attestation_challenge: Vec<u8>,
}

impl PrepareCaptureKey {
	pub fn encode(&self) -> Result<Bytes, Error> {
		if self.capture_id.is_empty()
			|| self.attestation_challenge.is_empty()
			|| self.attestation_challenge.len() > MAX_ATTESTATION_CHALLENGE_BYTES
		{
			return Err(Error::InvalidArgument);
		}
		let mut enc = Encoder::with_capacity(64 + self.attestation_challenge.len());
		enc.bytes(self.capture_id.as_bytes())?;
		enc.bytes(&self.attestation_challenge)?;
		Ok(enc.finish())
	}

	pub fn decode(bytes: &[u8]) -> Result<Self, Error> {
		let mut dec = Decoder::new(bytes);
		let capture_id = dec.string()?.to_owned();
		let attestation_challenge = dec.bytes()?.to_vec();
		dec.finish()?;
		if capture_id.is_empty()
			|| attestation_challenge.is_empty()
			|| attestation_challenge.len() > MAX_ATTESTATION_CHALLENGE_BYTES
		{
			return Err(Error::InvalidArgument);
		}
		Ok(Self {
			capture_id,
			attestation_challenge,
		})
	}
}

/// Android request to sign a capture manifest with the capture window's key.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SignCaptureManifest {
	pub capture_id: String,
	pub manifest: Vec<u8>,
}

impl SignCaptureManifest {
	pub fn encode(&self) -> Result<Bytes, Error> {
		if self.capture_id.is_empty()
			|| self.manifest.is_empty()
			|| self.manifest.len() > MAX_MANIFEST_BYTES
		{
			return Err(Error::InvalidArgument);
		}
		let mut enc = Encoder::with_capacity(64 + self.manifest.len());
		enc.bytes(self.capture_id.as_bytes())?;
		enc.bytes(&self.manifest)?;
		Ok(enc.finish())
	}

	pub fn decode(bytes: &[u8]) -> Result<Self, Error> {
		let mut dec = Decoder::new(bytes);
		let capture_id = dec.string()?.to_owned();
		let manifest = dec.bytes()?.to_vec();
		dec.finish()?;
		if capture_id.is_empty() || manifest.is_empty() || manifest.len() > MAX_MANIFEST_BYTES {
			return Err(Error::InvalidArgument);
		}
		Ok(Self {
			capture_id,
			manifest,
		})
	}
}

/// Android signed manifest proof: IEEE P1363 64-byte signature + DER X.509 certificate chain.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SignedManifestProof {
	pub signature_p1363: Vec<u8>,
	pub certificate_chain_der: Vec<Vec<u8>>,
}

impl SignedManifestProof {
	pub fn encode(&self) -> Result<Bytes, Error> {
		if self.signature_p1363.len() != 64
			|| self.certificate_chain_der.is_empty()
			|| self.certificate_chain_der.len() > MAX_CHAIN_CERTS
		{
			return Err(Error::InvalidArgument);
		}
		let mut enc = Encoder::with_capacity(128);
		enc.bytes(&self.signature_p1363)?;
		enc.u32(self.certificate_chain_der.len() as u32);
		for cert in &self.certificate_chain_der {
			enc.bytes(cert)?;
		}
		Ok(enc.finish())
	}

	pub fn decode(bytes: &[u8]) -> Result<Self, Error> {
		let mut dec = Decoder::new(bytes);
		let signature_p1363 = dec.bytes()?.to_vec();
		if signature_p1363.len() != 64 {
			return Err(Error::InvalidArgument);
		}
		let count = dec.u32()? as usize;
		if count == 0 || count > MAX_CHAIN_CERTS {
			return Err(Error::InvalidArgument);
		}
		let mut certificate_chain_der = Vec::with_capacity(count);
		for _ in 0..count {
			let cert = dec.bytes()?.to_vec();
			if cert.is_empty() {
				return Err(Error::InvalidArgument);
			}
			certificate_chain_der.push(cert);
		}
		dec.finish()?;
		Ok(Self {
			signature_p1363,
			certificate_chain_der,
		})
	}
}

/// Android Play Integrity Standard API request.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlayIntegrityRequest {
	pub request_hash: String,
	pub cloud_project_number: u64,
}

impl PlayIntegrityRequest {
	pub fn encode(&self) -> Result<Bytes, Error> {
		if self.request_hash.is_empty() || self.cloud_project_number == 0 {
			return Err(Error::InvalidArgument);
		}
		let mut enc = Encoder::with_capacity(16 + self.request_hash.len());
		enc.bytes(self.request_hash.as_bytes())?;
		let n = self.cloud_project_number.to_le_bytes();
		enc.u32(u32::from_le_bytes([n[0], n[1], n[2], n[3]]));
		enc.u32(u32::from_le_bytes([n[4], n[5], n[6], n[7]]));
		Ok(enc.finish())
	}

	pub fn decode(bytes: &[u8]) -> Result<Self, Error> {
		let mut dec = Decoder::new(bytes);
		let request_hash = dec.string()?.to_owned();
		let lo = dec.u32()?.to_le_bytes();
		let hi = dec.u32()?.to_le_bytes();
		dec.finish()?;
		let cloud_project_number =
			u64::from_le_bytes([lo[0], lo[1], lo[2], lo[3], hi[0], hi[1], hi[2], hi[3]]);
		if request_hash.is_empty() || cloud_project_number == 0 {
			return Err(Error::InvalidArgument);
		}
		Ok(Self {
			request_hash,
			cloud_project_number,
		})
	}
}

/// Stored iOS App Attest key state for one account.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StoredAppAttestKey {
	pub key_id: String,
	pub registered: bool,
}

impl StoredAppAttestKey {
	pub fn encode(value: Option<&Self>) -> Result<Bytes, Error> {
		let mut enc = Encoder::with_capacity(64);
		match value {
			None => enc.u32(0),
			Some(item) => {
				enc.u32(1);
				enc.bytes(item.key_id.as_bytes())?;
				enc.u32(u32::from(item.registered));
			}
		}
		Ok(enc.finish())
	}

	pub fn decode(bytes: &[u8]) -> Result<Option<Self>, Error> {
		let mut dec = Decoder::new(bytes);
		let present = dec.u32()?;
		if present == 0 {
			dec.finish()?;
			return Ok(None);
		}
		if present != 1 {
			return Err(Error::InvalidArgument);
		}
		let key_id = dec.string()?.to_owned();
		let registered = match dec.u32()? {
			0 => false,
			1 => true,
			_ => return Err(Error::InvalidArgument),
		};
		dec.finish()?;
		Ok(Some(Self { key_id, registered }))
	}
}

/// iOS request carrying a key id and 32-byte `client_data_hash`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyHashRequest {
	pub key_id: String,
	pub client_data_hash: [u8; 32],
}

impl KeyHashRequest {
	pub fn encode(&self) -> Result<Bytes, Error> {
		if self.key_id.is_empty() {
			return Err(Error::InvalidArgument);
		}
		let mut enc = Encoder::with_capacity(48 + self.key_id.len());
		enc.bytes(self.key_id.as_bytes())?;
		enc.bytes(&self.client_data_hash)?;
		Ok(enc.finish())
	}

	pub fn decode(bytes: &[u8]) -> Result<Self, Error> {
		let mut dec = Decoder::new(bytes);
		let key_id = dec.string()?.to_owned();
		let hash = dec.bytes()?;
		dec.finish()?;
		let client_data_hash: [u8; 32] = hash.try_into().map_err(|_| Error::InvalidArgument)?;
		if key_id.is_empty() {
			return Err(Error::InvalidArgument);
		}
		Ok(Self {
			key_id,
			client_data_hash,
		})
	}
}

/// Wasm guest client for calling `"verily-attest"`.
#[cfg(all(feature = "guest", target_arch = "wasm32"))]
pub mod guest {
	use leptoskit_bridge::Error;
	use leptoskit_bridge::codec::{Decoder, Encoder};
	use leptoskit_bridge::guest::Plugin;

	use super::{
		APP_ATTEST_SUPPORTED, ATTEST_APP_ATTEST_KEY, DISCARD_APP_ATTEST_KEY,
		GENERATE_APP_ATTEST_ASSERTION, GENERATE_APP_ATTEST_KEY, GENERATE_DEVICE_CHECK_TOKEN,
		KeyHashRequest, MARK_APP_ATTEST_REGISTERED, PREPARE_CAPTURE_KEY, PlayIntegrityRequest,
		PrepareCaptureKey, READ_APP_ATTEST_KEY, REQUEST_PLAY_INTEGRITY, SIGN_CAPTURE_MANIFEST,
		SignCaptureManifest, SignedManifestProof, StoredAppAttestKey,
	};

	#[derive(Clone, Copy)]
	pub struct VerilyAttest(Plugin);

	impl VerilyAttest {
		pub fn new() -> Result<Self, Error> {
			Plugin::resolve(super::NAME).map(Self)
		}

		pub async fn prepare_capture_key(self, req: &PrepareCaptureKey) -> Result<(), Error> {
			let reply = self.0.call(PREPARE_CAPTURE_KEY, &req.encode()?)?.await?;
			Decoder::new(&reply).finish()
		}

		pub async fn sign_capture_manifest(
			self,
			req: &SignCaptureManifest,
		) -> Result<SignedManifestProof, Error> {
			let reply = self.0.call(SIGN_CAPTURE_MANIFEST, &req.encode()?)?.await?;
			SignedManifestProof::decode(&reply)
		}

		pub async fn request_play_integrity(
			self,
			req: &PlayIntegrityRequest,
		) -> Result<String, Error> {
			let reply = self.0.call(REQUEST_PLAY_INTEGRITY, &req.encode()?)?.await?;
			let mut dec = Decoder::new(&reply);
			let token = dec.string()?.to_owned();
			dec.finish()?;
			Ok(token)
		}

		pub async fn app_attest_supported(self) -> Result<bool, Error> {
			let reply = self.0.call(APP_ATTEST_SUPPORTED, &[])?.await?;
			let mut dec = Decoder::new(&reply);
			let supported = match dec.u32()? {
				0 => false,
				1 => true,
				_ => return Err(Error::InvalidArgument),
			};
			dec.finish()?;
			Ok(supported)
		}

		pub async fn read_app_attest_key(
			self,
			account_id: &str,
		) -> Result<Option<StoredAppAttestKey>, Error> {
			let mut enc = Encoder::with_capacity(40);
			enc.bytes(account_id.as_bytes())?;
			let reply = self.0.call(READ_APP_ATTEST_KEY, &enc.finish())?.await?;
			StoredAppAttestKey::decode(&reply)
		}

		pub async fn generate_app_attest_key(self, account_id: &str) -> Result<String, Error> {
			let mut enc = Encoder::with_capacity(40);
			enc.bytes(account_id.as_bytes())?;
			let reply = self.0.call(GENERATE_APP_ATTEST_KEY, &enc.finish())?.await?;
			let mut dec = Decoder::new(&reply);
			let key_id = dec.string()?.to_owned();
			dec.finish()?;
			Ok(key_id)
		}

		pub async fn attest_app_attest_key(self, req: &KeyHashRequest) -> Result<Vec<u8>, Error> {
			let reply = self.0.call(ATTEST_APP_ATTEST_KEY, &req.encode()?)?.await?;
			let mut dec = Decoder::new(&reply);
			let bytes = dec.bytes()?.to_vec();
			dec.finish()?;
			Ok(bytes)
		}

		pub async fn mark_app_attest_registered(
			self,
			account_id: &str,
			key_id: &str,
		) -> Result<(), Error> {
			let mut enc = Encoder::with_capacity(96);
			enc.bytes(account_id.as_bytes())?;
			enc.bytes(key_id.as_bytes())?;
			let reply = self
				.0
				.call(MARK_APP_ATTEST_REGISTERED, &enc.finish())?
				.await?;
			Decoder::new(&reply).finish()
		}

		pub async fn generate_app_attest_assertion(
			self,
			req: &KeyHashRequest,
		) -> Result<Vec<u8>, Error> {
			let reply = self
				.0
				.call(GENERATE_APP_ATTEST_ASSERTION, &req.encode()?)?
				.await?;
			let mut dec = Decoder::new(&reply);
			let bytes = dec.bytes()?.to_vec();
			dec.finish()?;
			Ok(bytes)
		}

		pub async fn discard_app_attest_key(self, account_id: &str) -> Result<(), Error> {
			let mut enc = Encoder::with_capacity(40);
			enc.bytes(account_id.as_bytes())?;
			let reply = self.0.call(DISCARD_APP_ATTEST_KEY, &enc.finish())?.await?;
			Decoder::new(&reply).finish()
		}

		pub async fn generate_device_check_token(self) -> Result<Vec<u8>, Error> {
			let reply = self.0.call(GENERATE_DEVICE_CHECK_TOKEN, &[])?.await?;
			let mut dec = Decoder::new(&reply);
			let token = dec.bytes()?.to_vec();
			dec.finish()?;
			Ok(token)
		}
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn android_wire_codecs_round_trip() {
		let prep = PrepareCaptureKey {
			capture_id: "01234567-89ab-4def-8123-456789abcdef".to_owned(),
			attestation_challenge: vec![0xab; 32],
		};
		assert_eq!(
			PrepareCaptureKey::decode(&prep.encode().unwrap()).unwrap(),
			prep
		);

		let sign = SignCaptureManifest {
			capture_id: prep.capture_id.clone(),
			manifest: b"verily-capture-manifest-v1\n...".to_vec(),
		};
		assert_eq!(
			SignCaptureManifest::decode(&sign.encode().unwrap()).unwrap(),
			sign
		);

		let proof = SignedManifestProof {
			signature_p1363: vec![7u8; 64],
			certificate_chain_der: vec![vec![0x30, 0x82, 0x01, 0x00], vec![0x30, 0x82, 0x02, 0x00]],
		};
		assert_eq!(
			SignedManifestProof::decode(&proof.encode().unwrap()).unwrap(),
			proof
		);

		let pi = PlayIntegrityRequest {
			request_hash: "a".repeat(64),
			cloud_project_number: 123_456_789_012,
		};
		assert_eq!(
			PlayIntegrityRequest::decode(&pi.encode().unwrap()).unwrap(),
			pi
		);
	}

	#[test]
	fn ios_wire_codecs_round_trip() {
		let none = StoredAppAttestKey::encode(None).unwrap();
		assert_eq!(StoredAppAttestKey::decode(&none).unwrap(), None);

		let stored = StoredAppAttestKey {
			key_id: "key123".to_owned(),
			registered: true,
		};
		assert_eq!(
			StoredAppAttestKey::decode(&StoredAppAttestKey::encode(Some(&stored)).unwrap())
				.unwrap(),
			Some(stored)
		);

		let req = KeyHashRequest {
			key_id: "key123".to_owned(),
			client_data_hash: [0x55; 32],
		};
		assert_eq!(KeyHashRequest::decode(&req.encode().unwrap()).unwrap(), req);
	}
}
