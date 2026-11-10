//! Privacy-preserving fingerprints both sides already compute.
//!
//! The server recomputes every digest from the evidence it accepted. A client
//! hash is not evidence. Changing a domain separator is a protocol bump, which
//! this port does not do.
//!
//! Capture of proof that demands a fresh recording starts with `beginCapture`,
//! before the camera, microphone, sensors, or scanner open. There is no gallery
//! and no file picker on that path.

use std::fmt::Write as _;

use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use chrono::{DateTime, Utc};
use sha2::{Digest, Sha256};
use thiserror::Error;

/// `SHA-256` domain for a Play Integrity request hash.
pub const CAPTURE_REQUEST_DOMAIN: &str = "verily-capture-request-v2";

/// `SHA-256` domain for the bytes a capture key signs.
pub const CAPTURE_MANIFEST_DOMAIN: &str = "verily-capture-manifest-v1";

/// `SHA-256` domain for an evidence binding.
pub const EVIDENCE_BINDING_DOMAIN: &str = "verily-evidence-binding-v1";

const APPLE_DEVICE_DOMAIN: &str = "verily-apple-device-v1";

/// The captured media families a private upload accepts.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MediaEvidenceKind {
	/// A recording with a positive duration.
	Video,
	/// A still. Duration is zero, so it cannot be replayed as a recording.
	Photo,
	/// A recording with a positive duration.
	Audio,
}

impl MediaEvidenceKind {
	fn name(self) -> &'static str {
		match self {
			Self::Video => "video",
			Self::Photo => "photo",
			Self::Audio => "audio",
		}
	}
}

/// A digest was refused before it could cross the trust boundary.
#[derive(Debug, Clone, PartialEq, Eq, Error)]
#[error("{parameter}: {message}")]
pub struct EvidenceError {
	/// The field that failed.
	pub parameter: &'static str,
	/// Why it failed.
	pub message: &'static str,
}

/// A server capture challenge: 32 random bytes, unpadded base64url.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CaptureChallenge(String);

impl CaptureChallenge {
	/// Checks the shape the server issues. The client does not choose the bytes.
	pub fn parse(value: &str) -> Result<Self, EvidenceError> {
		Ok(Self(normalize_capture_challenge(value)?.to_owned()))
	}

	/// The unpadded base64url text.
	#[must_use]
	pub fn as_str(&self) -> &str {
		&self.0
	}
}

/// Hex `SHA-256` of one evidence binding. It is not a claim the scene is real.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EvidenceBinding(String);

impl EvidenceBinding {
	/// Checks a 64-character hexadecimal `SHA-256` digest.
	pub fn parse(value: &str) -> Result<Self, EvidenceError> {
		Ok(Self(normalize_evidence_binding_hash(value)?))
	}

	/// The lowercase hex digest.
	#[must_use]
	pub fn as_str(&self) -> &str {
		&self.0
	}
}

/// Streams nothing: hashes the bytes already in hand.
#[must_use]
pub fn sha256_hex(bytes: &[u8]) -> String {
	hex_encode(&Sha256::digest(bytes))
}

/// Play Integrity request hash for one capture.
///
/// The token can vouch only for this attempt, requirement, binding, and
/// server-issued challenge.
pub fn capture_integrity_request_hash(
	attempt_id: &str,
	requirement_id: &str,
	capture_challenge: &str,
	evidence_binding_hash: &str,
) -> Result<String, EvidenceError> {
	let binding = normalize_evidence_binding_hash(evidence_binding_hash)?;
	let challenge = normalize_capture_challenge(capture_challenge)?;
	let attempt = canonical_identifier(attempt_id, "attemptId")?;
	let requirement = canonical_identifier(requirement_id, "requirementId")?;
	let joined = format!("{CAPTURE_REQUEST_DOMAIN}|{attempt}|{requirement}|{binding}|{challenge}");
	Ok(URL_SAFE_NO_PAD.encode(Sha256::digest(joined.as_bytes())))
}

/// The 32 raw bytes behind [`capture_integrity_request_hash`].
///
/// Play Integrity commits to this digest. The base64url text and these bytes
/// are the same hash; a token over anything else vouches for a different proof.
pub fn capture_integrity_request_nonce(
	attempt_id: &str,
	requirement_id: &str,
	capture_challenge: &str,
	evidence_binding_hash: &str,
) -> Result<[u8; 32], EvidenceError> {
	let encoded = capture_integrity_request_hash(
		attempt_id,
		requirement_id,
		capture_challenge,
		evidence_binding_hash,
	)?;
	let bytes = URL_SAFE_NO_PAD.decode(encoded).map_err(|_| {
		invalid(
			"requestHash",
			"Must be an unpadded base64url SHA-256 digest.",
		)
	})?;
	bytes.try_into().map_err(|_| {
		invalid(
			"requestHash",
			"Must be an unpadded base64url SHA-256 digest.",
		)
	})
}

/// Android Key Attestation challenge: `SHA-256(captureChallenge ‖ attemptId)`.
///
/// `captureChallenge` is the nonce's 32 raw bytes and `attemptId` its UTF-8 text.
pub fn capture_key_attestation_challenge(
	capture_challenge: &str,
	attempt_id: &str,
) -> Result<[u8; 32], EvidenceError> {
	let nonce = decode_challenge(capture_challenge)?;
	let attempt = canonical_identifier(attempt_id, "attemptId")?;
	let mut hasher = Sha256::new();
	hasher.update(nonce);
	hasher.update(attempt.as_bytes());
	Ok(hasher.finalize().into())
}

/// `clientDataHash` for App Attest `attestKey`: `SHA-256` of the registration
/// challenge's 32 raw bytes.
pub fn app_attest_registration_client_data_hash(
	registration_challenge: &str,
) -> Result<[u8; 32], EvidenceError> {
	let nonce = decode_challenge(registration_challenge)?;
	Ok(Sha256::digest(nonce).into())
}

/// `clientDataHash` for App Attest `generateAssertion`: `SHA-256` of the
/// canonical manifest bytes.
pub fn app_attest_assertion_client_data_hash(manifest: &[u8]) -> Result<[u8; 32], EvidenceError> {
	if manifest.is_empty() {
		return Err(invalid("manifest", "Must not be empty."));
	}
	Ok(Sha256::digest(manifest).into())
}

/// Binds the ephemeral DeviceCheck token to this manifest's App Attest assertion.
///
/// Length-prefixing avoids ambiguity. Only the token hash is included. Apple
/// exposes no cryptographic link that the token and the key came from the same
/// phone, and an App Attest proof never claims a verified boot.
pub fn app_attest_device_client_data(manifest: &[u8], device_check_token: &str) -> Vec<u8> {
	let prefix = format!("{APPLE_DEVICE_DOMAIN}|{}|", manifest.len());
	let mut out = prefix.into_bytes();
	out.extend_from_slice(manifest);
	out.extend_from_slice(&Sha256::digest(device_check_token.as_bytes()));
	out
}

/// Validates a server capture challenge: 32 random bytes, unpadded base64url.
pub fn normalize_capture_challenge(value: &str) -> Result<&str, EvidenceError> {
	let normalized = value.trim();
	if !is_unpadded_base64url_32(normalized) {
		return Err(invalid(
			"captureChallenge",
			"Must be 32 bytes as unpadded base64url.",
		));
	}
	Ok(normalized)
}

/// Canonical bytes signed by an app-controlled capture key.
///
/// The manifest binds one device signature to the server-issued challenge and
/// the exact evidence fingerprint. It contains no media, QR payload, or
/// location coordinates.
pub fn capture_provenance_manifest(
	attempt_id: &str,
	requirement_id: &str,
	request_hash: &str,
	evidence_binding_hash: &str,
) -> Result<Vec<u8>, EvidenceError> {
	let request_hash = request_hash.trim();
	if !is_unpadded_base64url_32(request_hash) {
		return Err(invalid(
			"requestHash",
			"Must be an unpadded base64url SHA-256 digest.",
		));
	}
	let attempt = canonical_identifier(attempt_id, "attemptId")?;
	let requirement = canonical_identifier(requirement_id, "requirementId")?;
	let binding = normalize_evidence_binding_hash(evidence_binding_hash)?;
	let text = format!(
		"{CAPTURE_MANIFEST_DOMAIN}\nattemptId={attempt}\nrequirementId={requirement}\nrequestHash={request_hash}\nevidenceBindingHash={binding}"
	);
	Ok(text.into_bytes())
}

/// `SHA-256` of an encoded capture public key, as lowercase hex.
pub fn capture_public_key_id(public_key_bytes: &[u8]) -> Result<String, EvidenceError> {
	if public_key_bytes.is_empty() {
		return Err(invalid("publicKeyBytes", "Must not be empty."));
	}
	Ok(sha256_hex(public_key_bytes))
}

/// Binds a capture to one normalized location observation.
pub fn location_evidence_binding_hash(
	captured_at: DateTime<Utc>,
	latitude: f64,
	longitude: f64,
	accuracy_meters: f64,
) -> Result<String, EvidenceError> {
	if !latitude.is_finite() || !(-90.0..=90.0).contains(&latitude) {
		return Err(invalid("latitude", "Must be between -90 and 90."));
	}
	if !longitude.is_finite() || !(-180.0..=180.0).contains(&longitude) {
		return Err(invalid("longitude", "Must be between -180 and 180."));
	}
	if !accuracy_meters.is_finite() || accuracy_meters < 0.0 {
		return Err(invalid(
			"accuracyMeters",
			"Must be a finite, non-negative number.",
		));
	}
	let accuracy_mm = (accuracy_meters * 1000.0).round() as i64;
	Ok(canonical_hash(&[
		EVIDENCE_BINDING_DOMAIN,
		"kind=location",
		&format!("capturedAtMs={}", captured_at.timestamp_millis()),
		&format!("latitude={latitude:.7}"),
		&format!("longitude={longitude:.7}"),
		&format!("accuracyMm={accuracy_mm}"),
	]))
}

/// Binds a capture to one QR payload without putting the payload in the digest text.
pub fn qr_evidence_binding_hash(
	captured_at: DateTime<Utc>,
	code: &str,
) -> Result<String, EvidenceError> {
	let normalized = code.trim();
	if normalized.is_empty() {
		return Err(invalid("code", "Must not be empty."));
	}
	let code_hash = sha256_hex(normalized.as_bytes());
	Ok(canonical_hash(&[
		EVIDENCE_BINDING_DOMAIN,
		"kind=qrCode",
		&format!("capturedAtMs={}", captured_at.timestamp_millis()),
		&format!("codeSha256={code_hash}"),
	]))
}

/// Binds a capture to the bytes and metadata of one uploaded photo, video, or audio recording.
///
/// `duration_seconds` is zero for a photo and positive for a recording, so one
/// fingerprint cannot be replayed as a different kind.
pub fn media_evidence_binding_hash(
	kind: MediaEvidenceKind,
	captured_at: DateTime<Utc>,
	sha256_digest: &str,
	byte_length: i64,
	duration_seconds: i64,
	content_type: &str,
) -> Result<String, EvidenceError> {
	let digest = normalize_sha256(sha256_digest, "sha256Digest")?;
	let content_type = content_type.trim().to_ascii_lowercase();
	if byte_length <= 0 {
		return Err(invalid("byteLength", "Must be positive."));
	}
	let duration_ok = match kind {
		MediaEvidenceKind::Photo => duration_seconds == 0,
		MediaEvidenceKind::Video | MediaEvidenceKind::Audio => duration_seconds > 0,
	};
	if !duration_ok {
		let message = match kind {
			MediaEvidenceKind::Photo => "A photo has no duration; pass zero.",
			MediaEvidenceKind::Video | MediaEvidenceKind::Audio => {
				"A recording needs a positive duration."
			}
		};
		return Err(invalid("durationSeconds", message));
	}
	if content_type.is_empty() {
		return Err(invalid("contentType", "Must not be empty."));
	}
	Ok(canonical_hash(&[
		EVIDENCE_BINDING_DOMAIN,
		&format!("kind={}", kind.name()),
		&format!("capturedAtMs={}", captured_at.timestamp_millis()),
		&format!("sha256={digest}"),
		&format!("byteLength={byte_length}"),
		&format!("durationSeconds={duration_seconds}"),
		&format!("contentType={content_type}"),
	]))
}

/// Binds a capture to one canonical device-motion trace.
pub fn motion_evidence_binding_hash(
	captured_at: DateTime<Utc>,
	trace_sha256: &str,
	sample_count: i64,
	duration_milliseconds: i64,
) -> Result<String, EvidenceError> {
	let digest = normalize_sha256(trace_sha256, "traceSha256")?;
	if !(1..=1000).contains(&sample_count) {
		return Err(invalid("sampleCount", "Must be between 1 and 1000."));
	}
	if !(1..=30_000).contains(&duration_milliseconds) {
		return Err(invalid(
			"durationMilliseconds",
			"Must be between 1 and 30000.",
		));
	}
	Ok(canonical_hash(&[
		EVIDENCE_BINDING_DOMAIN,
		"kind=motion",
		&format!("capturedAtMs={}", captured_at.timestamp_millis()),
		&format!("traceSha256={digest}"),
		&format!("sampleCount={sample_count}"),
		&format!("durationMilliseconds={duration_milliseconds}"),
	]))
}

/// Validates and normalizes a `SHA-256` binding supplied over the API.
pub fn normalize_evidence_binding_hash(value: &str) -> Result<String, EvidenceError> {
	normalize_sha256(value, "evidenceBindingHash")
}

fn canonical_hash(fields: &[&str]) -> String {
	let mut text = String::new();
	for (index, field) in fields.iter().enumerate() {
		if index > 0 {
			text.push('\n');
		}
		text.push_str(field);
	}
	sha256_hex(text.as_bytes())
}

fn normalize_sha256(value: &str, parameter: &'static str) -> Result<String, EvidenceError> {
	let normalized = value.trim().to_ascii_lowercase();
	if normalized.len() != 64 || !normalized.bytes().all(|byte| byte.is_ascii_hexdigit()) {
		return Err(invalid(
			parameter,
			"Must be a 64-character hexadecimal SHA-256 digest.",
		));
	}
	Ok(normalized)
}

fn canonical_identifier(value: &str, parameter: &'static str) -> Result<String, EvidenceError> {
	let normalized = value.trim();
	if normalized.is_empty()
		|| normalized.contains('\n')
		|| normalized.contains('\r')
		|| normalized.contains('=')
	{
		return Err(invalid(
			parameter,
			"Must be a non-empty single-line identifier without equals signs.",
		));
	}
	Ok(normalized.to_owned())
}

fn decode_challenge(value: &str) -> Result<[u8; 32], EvidenceError> {
	let normalized = normalize_capture_challenge(value)?;
	let bytes = URL_SAFE_NO_PAD.decode(normalized).map_err(|_| {
		invalid(
			"captureChallenge",
			"Must be 32 bytes as unpadded base64url.",
		)
	})?;
	// A valid 43-character unpadded base64url string is always 32 bytes.
	Ok(bytes
		.try_into()
		.expect("unpadded base64url of length 43 is 32 bytes"))
}

fn is_unpadded_base64url_32(value: &str) -> bool {
	value.len() == 43
		&& value
			.bytes()
			.all(|byte| byte.is_ascii_alphanumeric() || byte == b'-' || byte == b'_')
}

fn hex_encode(bytes: &[u8]) -> String {
	let mut out = String::with_capacity(bytes.len() * 2);
	for byte in bytes {
		let _ = write!(out, "{byte:02x}");
	}
	out
}

fn invalid(parameter: &'static str, message: &'static str) -> EvidenceError {
	EvidenceError { parameter, message }
}

/// App Attest client-data helpers failed closed.
pub type AppAttestError = EvidenceError;
