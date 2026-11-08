//! Capture windows and device signatures.
//!
//! `begin_capture` is the server opening a window. This crate does not open a
//! camera, microphone, sensor, or scanner, and it has no gallery or file picker.
//! A signature is accepted only when it verifies over the manifest the server
//! rebuilt from the evidence it stored. Android attestation that this process
//! cannot check fails closed: there is no substitute success.

use std::time::Duration;

use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use chrono::DateTime;
use chrono::Utc;
use p256::ecdsa::Signature;
use p256::ecdsa::VerifyingKey;
use p256::ecdsa::signature::Verifier;

use crate::binding;
use crate::pending_shared::KeyStorage;
use crate::pending_shared::Provenance;

pub const WINDOW: Duration = Duration::from_secs(30 * 60);
pub const CLOCK_TOLERANCE: Duration = Duration::from_secs(2 * 60);

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum CaptureError {
	#[error("the capture was refused")]
	Refused,
	#[error("attestation is not available")]
	Unavailable,
	#[error("the assertion was replayed")]
	Replayed,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CaptureWindow {
	pub attempt_id: String,
	pub requirement_id: String,
	/// 32 random bytes, unpadded base64url.
	pub capture_challenge: String,
	pub opened_at: DateTime<Utc>,
	pub expires_at: DateTime<Utc>,
}

pub fn begin_capture(
	attempt_id: &str,
	requirement_id: &str,
	now: DateTime<Utc>,
) -> Result<CaptureWindow, CaptureError> {
	let attempt_id =
		binding::canonical_identifier(attempt_id).map_err(|_| CaptureError::Refused)?;
	let requirement_id =
		binding::canonical_identifier(requirement_id).map_err(|_| CaptureError::Refused)?;
	let mut nonce = [0_u8; 32];
	getrandom::getrandom(&mut nonce).map_err(|_| CaptureError::Unavailable)?;
	Ok(CaptureWindow {
		attempt_id,
		requirement_id,
		capture_challenge: URL_SAFE_NO_PAD.encode(nonce),
		opened_at: now,
		expires_at: now + WINDOW,
	})
}

pub fn captured_before_window(captured_at: DateTime<Utc>, opened_at: DateTime<Utc>) -> bool {
	captured_at + CLOCK_TOLERANCE < opened_at
}

/// A parsed Android leaf. `trusted` is true only after a chain verifier says so.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParsedAndroidKey {
	pub public_sec1: Vec<u8>,
	pub trusted: bool,
	pub storage: Option<KeyStorage>,
	pub reason: &'static str,
}

pub trait AndroidAttestation {
	fn parse(
		&self,
		chain_der: &[&[u8]],
		expected_challenge: &[u8; 32],
	) -> Result<ParsedAndroidKey, CaptureError>;
}

/// Production default until a chain verifier pinned to Google's roots is installed.
#[derive(Debug, Default, Clone, Copy)]
pub struct AttestationUnavailable;

impl AndroidAttestation for AttestationUnavailable {
	fn parse(
		&self,
		_chain_der: &[&[u8]],
		_expected_challenge: &[u8; 32],
	) -> Result<ParsedAndroidKey, CaptureError> {
		Err(CaptureError::Unavailable)
	}
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SignatureMode {
	Optional,
	Required,
}

pub fn signature_mode(value: Option<&str>) -> Result<SignatureMode, CaptureError> {
	match value.map(str::trim).filter(|value| !value.is_empty()) {
		None | Some("optional") => Ok(SignatureMode::Optional),
		Some("required") => Ok(SignatureMode::Required),
		Some(_) => Err(CaptureError::Refused),
	}
}

/// Verifies the signature with the leaf the attestation parser returned.
///
/// Hardware provenance requires `trusted`. Optional mode may record
/// `DeviceSigned` when the signature verifies and the chain does not.
/// Missing attestation never becomes a success.
pub fn verify_android_capture(
	attestation: &impl AndroidAttestation,
	chain_der: &[&[u8]],
	capture_challenge: &str,
	attempt_id: &str,
	manifest: &[u8],
	signature_p1363: &[u8],
	mode: SignatureMode,
) -> Result<Provenance, CaptureError> {
	let challenge = binding::android_attestation_challenge(capture_challenge, attempt_id)
		.map_err(|_| CaptureError::Refused)?;
	let parsed = attestation.parse(chain_der, &challenge)?;
	verify_p256(manifest, signature_p1363, &parsed.public_sec1)?;
	if parsed.trusted {
		return match parsed.storage {
			Some(KeyStorage::StrongBox | KeyStorage::TrustedEnvironment) => {
				Ok(Provenance::HardwareAttested)
			}
			None => Err(CaptureError::Refused),
		};
	}
	match mode {
		SignatureMode::Required => Err(CaptureError::Refused),
		SignatureMode::Optional => Ok(Provenance::DeviceSigned),
	}
}

pub fn verify_p256(
	message: &[u8],
	signature_p1363: &[u8],
	public_sec1: &[u8],
) -> Result<(), CaptureError> {
	let key = VerifyingKey::from_sec1_bytes(public_sec1).map_err(|_| CaptureError::Refused)?;
	let signature = Signature::from_slice(signature_p1363).map_err(|_| CaptureError::Refused)?;
	key.verify(message, &signature)
		.map_err(|_| CaptureError::Refused)
}

/// App Attest judgement. A passing assertion is `SecureEnclaveAttested` and
/// never a verified-boot claim.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AppAttestAssertion {
	pub signature_verifies: bool,
	pub rp_id_matches: bool,
	pub counter: u32,
	pub last_accepted_counter: u32,
}

pub fn judge_app_attest(assertion: AppAttestAssertion) -> Result<Provenance, CaptureError> {
	if !assertion.signature_verifies || !assertion.rp_id_matches {
		return Err(CaptureError::Refused);
	}
	if assertion.counter <= assertion.last_accepted_counter {
		return Err(CaptureError::Replayed);
	}
	Ok(Provenance::SecureEnclaveAttested)
}

#[cfg(test)]
mod tests {
	use super::*;
	use p256::ecdsa::SigningKey;
	use p256::ecdsa::signature::Signer;

	struct Scripted {
		key: ParsedAndroidKey,
	}

	impl AndroidAttestation for Scripted {
		fn parse(
			&self,
			_chain_der: &[&[u8]],
			expected: &[u8; 32],
		) -> Result<ParsedAndroidKey, CaptureError> {
			let challenge = binding::android_attestation_challenge(
				"ERERERERERERERERERERERERERERERERERERERERERE",
				"attempt-1",
			)
			.unwrap();
			if expected == &challenge {
				Ok(self.key.clone())
			} else {
				Err(CaptureError::Refused)
			}
		}
	}

	fn keypair() -> (SigningKey, Vec<u8>) {
		let mut scalar = [0_u8; 32];
		scalar[31] = 1;
		let signing = SigningKey::from_slice(&scalar).unwrap();
		let public = signing
			.verifying_key()
			.to_encoded_point(true)
			.as_bytes()
			.to_vec();
		(signing, public)
	}

	#[test]
	fn a_trusted_chain_and_a_real_signature_are_hardware_attested() {
		let (signing, public) = keypair();
		let manifest = b"verily-capture-manifest-v1\nattempt";
		let signature: Signature = signing.sign(manifest);
		let attestation = Scripted {
			key: ParsedAndroidKey {
				public_sec1: public,
				trusted: true,
				storage: Some(KeyStorage::StrongBox),
				reason: "ok",
			},
		};
		let provenance = verify_android_capture(
			&attestation,
			&[&[1, 2, 3]],
			"ERERERERERERERERERERERERERERERERERERERERERE",
			"attempt-1",
			manifest,
			&signature.to_bytes(),
			SignatureMode::Required,
		)
		.unwrap();
		assert_eq!(provenance, Provenance::HardwareAttested);
	}

	#[test]
	fn unavailable_attestation_does_not_become_device_signed() {
		let error = verify_android_capture(
			&AttestationUnavailable,
			&[&[1]],
			"ERERERERERERERERERERERERERERERERERERERERERE",
			"attempt-1",
			b"manifest",
			&[0; 64],
			SignatureMode::Optional,
		);
		assert_eq!(error, Err(CaptureError::Unavailable));
	}

	#[test]
	fn an_untrusted_signature_is_device_signed_only_when_optional() {
		let (signing, public) = keypair();
		let manifest = b"manifest";
		let signature: Signature = signing.sign(manifest);
		let attestation = Scripted {
			key: ParsedAndroidKey {
				public_sec1: public,
				trusted: false,
				storage: None,
				reason: "debug",
			},
		};
		assert_eq!(
			verify_android_capture(
				&attestation,
				&[&[1]],
				"ERERERERERERERERERERERERERERERERERERERERERE",
				"attempt-1",
				manifest,
				&signature.to_bytes(),
				SignatureMode::Optional,
			)
			.unwrap(),
			Provenance::DeviceSigned
		);
		assert_eq!(
			verify_android_capture(
				&attestation,
				&[&[1]],
				"ERERERERERERERERERERERERERERERERERERERERERE",
				"attempt-1",
				manifest,
				&signature.to_bytes(),
				SignatureMode::Required,
			),
			Err(CaptureError::Refused)
		);
	}

	#[test]
	fn app_attest_never_claims_a_verified_boot() {
		let provenance = judge_app_attest(AppAttestAssertion {
			signature_verifies: true,
			rp_id_matches: true,
			counter: 4,
			last_accepted_counter: 3,
		})
		.unwrap();
		assert_eq!(provenance, Provenance::SecureEnclaveAttested);
		assert_ne!(provenance, Provenance::HardwareAttested);
		assert_eq!(
			judge_app_attest(AppAttestAssertion {
				signature_verifies: true,
				rp_id_matches: true,
				counter: 3,
				last_accepted_counter: 3,
			}),
			Err(CaptureError::Replayed)
		);
	}

	#[test]
	fn capture_before_the_window_is_refused() {
		let opened = DateTime::from_timestamp(1_700_000_000, 0).unwrap();
		let early = opened - Duration::from_secs(121);
		assert!(captured_before_window(early, opened));
		assert!(!captured_before_window(opened - CLOCK_TOLERANCE, opened));
	}
}
