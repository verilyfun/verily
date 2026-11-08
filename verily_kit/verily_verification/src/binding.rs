//! Evidence fingerprints from `packages/verily_evidence`.
//!
//! Domain separators stay `verily-capture-request-v2`, `verily-capture-manifest-v1`,
//! and `verily-evidence-binding-v1`. The server recomputes them from the bytes
//! it stored. A digest supplied by the phone is not evidence.

use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use sha2::Digest;
use sha2::Sha256;

use crate::pending_shared::MediaKind;

pub const REQUEST_DOMAIN: &str = "verily-capture-request-v2";
pub const MANIFEST_DOMAIN: &str = "verily-capture-manifest-v1";
pub const BINDING_DOMAIN: &str = "verily-evidence-binding-v1";
pub const APPLE_DEVICE_DOMAIN: &str = "verily-apple-device-v1";

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum BindingError {
	#[error("the value is not a capture binding")]
	Invalid,
}

pub fn sha256_hex(bytes: &[u8]) -> String {
	hex_encode(&Sha256::digest(bytes))
}

pub fn normalize_sha256(value: &str) -> Result<String, BindingError> {
	let normalized = value.trim().to_ascii_lowercase();
	if normalized.len() == 64 && normalized.bytes().all(|byte| byte.is_ascii_hexdigit()) {
		Ok(normalized)
	} else {
		Err(BindingError::Invalid)
	}
}

pub fn normalize_capture_challenge(value: &str) -> Result<String, BindingError> {
	let normalized = value.trim();
	if normalized.len() != 43 || !normalized.bytes().all(is_base64url) {
		return Err(BindingError::Invalid);
	}
	let decoded = URL_SAFE_NO_PAD
		.decode(normalized)
		.map_err(|_| BindingError::Invalid)?;
	if decoded.len() == 32 {
		Ok(normalized.to_string())
	} else {
		Err(BindingError::Invalid)
	}
}

pub fn canonical_identifier(value: &str) -> Result<String, BindingError> {
	let normalized = value.trim();
	if normalized.is_empty() || normalized.contains(['\n', '\r', '=']) {
		Err(BindingError::Invalid)
	} else {
		Ok(normalized.to_string())
	}
}

/// `SHA-256(captureChallenge ‖ attemptId)`: nonce bytes, then the attempt id as UTF-8.
pub fn android_attestation_challenge(
	capture_challenge: &str,
	attempt_id: &str,
) -> Result<[u8; 32], BindingError> {
	let nonce = URL_SAFE_NO_PAD
		.decode(normalize_capture_challenge(capture_challenge)?)
		.map_err(|_| BindingError::Invalid)?;
	let attempt = canonical_identifier(attempt_id)?;
	let mut hasher = Sha256::new();
	hasher.update(nonce);
	hasher.update(attempt.as_bytes());
	Ok(hasher.finalize().into())
}

pub fn capture_request_hash(
	attempt_id: &str,
	requirement_id: &str,
	capture_challenge: &str,
	evidence_binding_hash: &str,
) -> Result<String, BindingError> {
	let material = [
		REQUEST_DOMAIN,
		canonical_identifier(attempt_id)?.as_str(),
		canonical_identifier(requirement_id)?.as_str(),
		normalize_sha256(evidence_binding_hash)?.as_str(),
		normalize_capture_challenge(capture_challenge)?.as_str(),
	]
	.join("|");
	Ok(URL_SAFE_NO_PAD.encode(Sha256::digest(material.as_bytes())))
}

pub fn capture_manifest(
	attempt_id: &str,
	requirement_id: &str,
	request_hash: &str,
	evidence_binding_hash: &str,
) -> Result<Vec<u8>, BindingError> {
	let request_hash = request_hash.trim();
	if request_hash.len() != 43 || !request_hash.bytes().all(is_base64url) {
		return Err(BindingError::Invalid);
	}
	let text = [
		MANIFEST_DOMAIN.to_string(),
		format!("attemptId={}", canonical_identifier(attempt_id)?),
		format!("requirementId={}", canonical_identifier(requirement_id)?),
		format!("requestHash={request_hash}"),
		format!(
			"evidenceBindingHash={}",
			normalize_sha256(evidence_binding_hash)?
		),
	]
	.join("\n");
	Ok(text.into_bytes())
}

pub fn media_binding_hash(
	kind: MediaKind,
	captured_at_ms: i64,
	sha256_digest: &str,
	byte_length: u64,
	duration_seconds: u64,
	content_type: &str,
) -> Result<String, BindingError> {
	if byte_length == 0 {
		return Err(BindingError::Invalid);
	}
	let duration_ok = match kind {
		MediaKind::Photo => duration_seconds == 0,
		MediaKind::Video | MediaKind::Audio => duration_seconds > 0,
	};
	let content_type = content_type.trim().to_ascii_lowercase();
	if !duration_ok || content_type.is_empty() {
		return Err(BindingError::Invalid);
	}
	Ok(canonical_hash(&[
		BINDING_DOMAIN,
		&format!("kind={}", kind_name(kind)),
		&format!("capturedAtMs={captured_at_ms}"),
		&format!("sha256={}", normalize_sha256(sha256_digest)?),
		&format!("byteLength={byte_length}"),
		&format!("durationSeconds={duration_seconds}"),
		&format!("contentType={content_type}"),
	]))
}

pub fn location_binding_hash(
	captured_at_ms: i64,
	latitude: f64,
	longitude: f64,
	accuracy_meters: f64,
) -> Result<String, BindingError> {
	if !latitude.is_finite() || !(-90.0..=90.0).contains(&latitude) {
		return Err(BindingError::Invalid);
	}
	if !longitude.is_finite() || !(-180.0..=180.0).contains(&longitude) {
		return Err(BindingError::Invalid);
	}
	if !accuracy_meters.is_finite() || accuracy_meters < 0.0 {
		return Err(BindingError::Invalid);
	}
	let accuracy_mm = (accuracy_meters * 1000.0).round() as i64;
	Ok(canonical_hash(&[
		BINDING_DOMAIN,
		"kind=location",
		&format!("capturedAtMs={captured_at_ms}"),
		&format!("latitude={latitude:.7}"),
		&format!("longitude={longitude:.7}"),
		&format!("accuracyMm={accuracy_mm}"),
	]))
}

pub fn qr_binding_hash(captured_at_ms: i64, code: &str) -> Result<String, BindingError> {
	let code = code.trim();
	if code.is_empty() {
		return Err(BindingError::Invalid);
	}
	Ok(canonical_hash(&[
		BINDING_DOMAIN,
		"kind=qrCode",
		&format!("capturedAtMs={captured_at_ms}"),
		&format!("codeSha256={}", sha256_hex(code.as_bytes())),
	]))
}

pub fn motion_binding_hash(
	captured_at_ms: i64,
	trace_sha256: &str,
	sample_count: u32,
	duration_milliseconds: u32,
) -> Result<String, BindingError> {
	if !(1..=1000).contains(&sample_count) || !(1..=30_000).contains(&duration_milliseconds) {
		return Err(BindingError::Invalid);
	}
	Ok(canonical_hash(&[
		BINDING_DOMAIN,
		"kind=motion",
		&format!("capturedAtMs={captured_at_ms}"),
		&format!("traceSha256={}", normalize_sha256(trace_sha256)?),
		&format!("sampleCount={sample_count}"),
		&format!("durationMilliseconds={duration_milliseconds}"),
	]))
}

/// Client data an iPhone passes to `generateAssertion`.
pub fn app_attest_device_client_data(manifest: &[u8], device_check_token: &str) -> Vec<u8> {
	let mut out = format!("{APPLE_DEVICE_DOMAIN}|{}|", manifest.len()).into_bytes();
	out.extend_from_slice(manifest);
	out.extend_from_slice(&Sha256::digest(device_check_token.as_bytes()));
	out
}

pub fn app_attest_registration_client_data_hash(
	registration_challenge: &str,
) -> Result<[u8; 32], BindingError> {
	let nonce = URL_SAFE_NO_PAD
		.decode(normalize_capture_challenge(registration_challenge)?)
		.map_err(|_| BindingError::Invalid)?;
	Ok(Sha256::digest(nonce).into())
}

fn canonical_hash(fields: &[&str]) -> String {
	sha256_hex(fields.join("\n").as_bytes())
}

fn kind_name(kind: MediaKind) -> &'static str {
	match kind {
		MediaKind::Video => "video",
		MediaKind::Photo => "photo",
		MediaKind::Audio => "audio",
	}
}

fn is_base64url(byte: u8) -> bool {
	byte.is_ascii_alphanumeric() || byte == b'-' || byte == b'_'
}

fn hex_encode(bytes: &[u8]) -> String {
	const HEX: &[u8; 16] = b"0123456789abcdef";
	let mut out = String::with_capacity(bytes.len() * 2);
	for byte in bytes {
		out.push(HEX[(byte >> 4) as usize] as char);
		out.push(HEX[(byte & 0x0f) as usize] as char);
	}
	out
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn media_binding_matches_the_evidence_contract() {
		let hash = media_binding_hash(
			MediaKind::Photo,
			1_700_000_000_000,
			&"ab".repeat(32),
			12,
			0,
			"image/jpeg",
		)
		.unwrap();
		assert_eq!(
			hash,
			"b20cee6f552f40b600db7e36b8e71a5dec4db19d5bfe497225a71bb3b59cc9f8"
		);
	}

	#[test]
	fn request_hash_and_attestation_challenge_bind_the_attempt() {
		let attempt = "11111111-1111-4111-8111-111111111111";
		let requirement = "22222222-2222-4222-8222-222222222222";
		let binding = "cd".repeat(32);
		let challenge = "ERERERERERERERERERERERERERERERERERERERERERE";
		assert_eq!(
			capture_request_hash(attempt, requirement, challenge, &binding).unwrap(),
			"cjKxZBPNTCDhfnQ13IApO_lHAKRhg__6l3c3EwhR9is"
		);
		assert_eq!(
			hex_encode(&android_attestation_challenge(challenge, attempt).unwrap()),
			"7fc6e3bcba8053f8f8bdc0fd3c0479374b8105a644c36907917ed62b2510fe2e"
		);
	}

	#[test]
	fn a_client_digest_is_only_accepted_when_it_matches_the_recompute() {
		let stored =
			media_binding_hash(MediaKind::Photo, 10, &"aa".repeat(32), 4, 0, "image/png").unwrap();
		assert_eq!(normalize_sha256(&stored.to_uppercase()).unwrap(), stored);
		assert!(normalize_sha256("not-a-digest").is_err());
		assert_ne!(stored, "aa".repeat(32));
	}
}
