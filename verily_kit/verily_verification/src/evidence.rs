//! Hash-pinned evidence. Originals are identified and never rewritten.
//!
//! Paths come from authenticated ids. A review link is not part of the seal
//! and is not proof.

use crate::pending_shared::MediaKind;
use sha2::Digest;
use sha2::Sha256;

pub const CONTRACT: &str = "verily.evidence-integrity.v1";
pub const OBJECT_PREFIX: &str = "action-evidence/";
pub const MAX_BYTES: u64 = 150 * 1024 * 1024;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MediaType {
	pub content_type: &'static str,
	pub extension: &'static str,
	pub kind: MediaKind,
}

const MEDIA_TYPES: &[MediaType] = &[
	MediaType {
		content_type: "video/mp4",
		extension: "mp4",
		kind: MediaKind::Video,
	},
	MediaType {
		content_type: "video/quicktime",
		extension: "mov",
		kind: MediaKind::Video,
	},
	MediaType {
		content_type: "video/webm",
		extension: "webm",
		kind: MediaKind::Video,
	},
	MediaType {
		content_type: "image/jpeg",
		extension: "jpg",
		kind: MediaKind::Photo,
	},
	MediaType {
		content_type: "image/png",
		extension: "png",
		kind: MediaKind::Photo,
	},
	MediaType {
		content_type: "image/heic",
		extension: "heic",
		kind: MediaKind::Photo,
	},
	MediaType {
		content_type: "audio/mp4",
		extension: "m4a",
		kind: MediaKind::Audio,
	},
	MediaType {
		content_type: "audio/webm",
		extension: "webm",
		kind: MediaKind::Audio,
	},
];

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum EvidenceError {
	#[error("evidence identity was refused")]
	Refused,
	#[error("the sealed evidence no longer matches the stored object")]
	Changed,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Expectation {
	pub auth_user_id: String,
	pub attempt_id: String,
	pub requirement_id: String,
	pub media: MediaType,
	pub byte_length: u64,
	pub storage_path: String,
}

impl Expectation {
	pub fn new(
		auth_user_id: &str,
		attempt_id: &str,
		requirement_id: &str,
		content_type: &str,
		byte_length: u64,
	) -> Result<Self, EvidenceError> {
		let media = media_type(content_type).ok_or(EvidenceError::Refused)?;
		if byte_length == 0 || byte_length > max_bytes(media.kind) {
			return Err(EvidenceError::Refused);
		}
		let auth_user_id = uuid(auth_user_id)?;
		let attempt_id = uuid(attempt_id)?;
		let requirement_id = uuid(requirement_id)?;
		let storage_path = format!(
			"{OBJECT_PREFIX}{auth_user_id}/{attempt_id}/{requirement_id}.{}",
			media.extension
		);
		Ok(Self {
			auth_user_id,
			attempt_id,
			requirement_id,
			media,
			byte_length,
			storage_path,
		})
	}
}

/// What storage reported after reading the object the server reserved.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Inspection {
	pub version_id: String,
	pub sha256_digest: String,
	pub byte_length: u64,
	pub content_type: String,
}

/// A version-pinned identity. It holds no media bytes and no review URL.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Seal {
	pub storage_path: String,
	pub storage_version_id: String,
	pub sha256_digest: String,
	pub byte_length: u64,
	pub content_type: String,
	/// Digest of the canonical identity. It does not replace the media hash.
	pub binding_digest: String,
}

pub fn seal_inspection(
	expectation: &Expectation,
	storage_path: &str,
	inspection: &Inspection,
) -> Result<Seal, EvidenceError> {
	if storage_path != expectation.storage_path
		|| inspection.byte_length != expectation.byte_length
		|| !content_type_matches(&inspection.content_type, expectation.media.content_type)
	{
		return Err(EvidenceError::Refused);
	}
	seal(
		storage_path,
		&inspection.version_id,
		&inspection.sha256_digest,
		inspection.byte_length,
		expectation.media.content_type,
	)
}

pub fn validate_persisted(
	expectation: &Expectation,
	storage_path: &str,
	storage_version_id: &str,
	sha256_digest: &str,
	byte_length: u64,
	content_type: &str,
) -> Result<Seal, EvidenceError> {
	if storage_path != expectation.storage_path
		|| byte_length != expectation.byte_length
		|| content_type != expectation.media.content_type
	{
		return Err(EvidenceError::Refused);
	}
	seal(
		storage_path,
		storage_version_id,
		sha256_digest,
		byte_length,
		content_type,
	)
}

pub fn assert_unchanged(sealed: &Seal, inspection: &Inspection) -> Result<(), EvidenceError> {
	if !content_type_matches(&inspection.content_type, &sealed.content_type) {
		return Err(EvidenceError::Changed);
	}
	let again = seal(
		&sealed.storage_path,
		&inspection.version_id,
		&inspection.sha256_digest,
		inspection.byte_length,
		&sealed.content_type,
	)?;
	if again.binding_digest == sealed.binding_digest {
		Ok(())
	} else {
		Err(EvidenceError::Changed)
	}
}

/// Digest of bytes the server read. Callers pass those bytes, not a phone digest.
pub fn digest_stored_bytes(bytes: &[u8]) -> String {
	crate::binding::sha256_hex(bytes)
}

#[cfg(test)]
pub(crate) fn seal_for_test(
	storage_path: &str,
	storage_version_id: &str,
	sha256_digest: &str,
	byte_length: u64,
	content_type: &str,
) -> Result<Seal, EvidenceError> {
	seal(
		storage_path,
		storage_version_id,
		sha256_digest,
		byte_length,
		content_type,
	)
}

fn seal(
	storage_path: &str,
	storage_version_id: &str,
	sha256_digest: &str,
	byte_length: u64,
	content_type: &str,
) -> Result<Seal, EvidenceError> {
	let version = validate_version(storage_version_id)?;
	let digest =
		crate::binding::normalize_sha256(sha256_digest).map_err(|_| EvidenceError::Refused)?;
	let content_type = content_type.trim().to_ascii_lowercase();
	if media_type(&content_type).is_none() || byte_length == 0 || byte_length > MAX_BYTES {
		return Err(EvidenceError::Refused);
	}
	let canonical = [
		CONTRACT,
		storage_path,
		version.as_str(),
		digest.as_str(),
		&byte_length.to_string(),
		content_type.as_str(),
	]
	.join("\n");
	let binding_digest = encode_hex(&Sha256::digest(canonical.as_bytes()));
	Ok(Seal {
		storage_path: storage_path.to_string(),
		storage_version_id: version,
		sha256_digest: digest,
		byte_length,
		content_type,
		binding_digest,
	})
}

fn media_type(content_type: &str) -> Option<MediaType> {
	let normalized = content_type.trim().to_ascii_lowercase();
	MEDIA_TYPES
		.iter()
		.copied()
		.find(|media| media.content_type == normalized)
}

fn max_bytes(kind: MediaKind) -> u64 {
	match kind {
		MediaKind::Video => 150 * 1024 * 1024,
		MediaKind::Photo => 20 * 1024 * 1024,
		MediaKind::Audio => 50 * 1024 * 1024,
	}
}

fn content_type_matches(reported: &str, expected: &str) -> bool {
	reported.trim().eq_ignore_ascii_case(expected)
}

fn uuid(value: &str) -> Result<String, EvidenceError> {
	let bytes = value.as_bytes();
	if bytes.len() != 36 {
		return Err(EvidenceError::Refused);
	}
	for (index, byte) in bytes.iter().enumerate() {
		let ok = if matches!(index, 8 | 13 | 18 | 23) {
			*byte == b'-'
		} else {
			byte.is_ascii_hexdigit() && !byte.is_ascii_uppercase()
		};
		if !ok {
			return Err(EvidenceError::Refused);
		}
	}
	Ok(value.to_string())
}

fn validate_version(value: &str) -> Result<String, EvidenceError> {
	let bytes = value.as_bytes();
	let length_ok = (8..=256).contains(&bytes.len());
	let alphabet = bytes
		.iter()
		.all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'.' | b'_' | b':' | b'-'));
	if length_ok && alphabet && bytes.first().is_some_and(u8::is_ascii_alphanumeric) {
		Ok(value.to_string())
	} else {
		Err(EvidenceError::Refused)
	}
}

fn encode_hex(bytes: &[u8]) -> String {
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

	fn expectation() -> Expectation {
		Expectation::new(
			"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
			"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
			"cccccccc-cccc-4ccc-8ccc-cccccccccccc",
			"image/jpeg",
			12,
		)
		.unwrap()
	}

	#[test]
	fn seal_pins_the_stored_object_and_a_later_read_must_match() {
		let expectation = expectation();
		let inspection = Inspection {
			version_id: format!("local-sha256-{}", "ab".repeat(32)),
			sha256_digest: "ab".repeat(32),
			byte_length: 12,
			content_type: "image/jpeg".to_string(),
		};
		let sealed = seal_inspection(&expectation, &expectation.storage_path, &inspection).unwrap();
		assert_eq!(
			sealed.binding_digest,
			"c845ce219e4fe41bbd6b2989fbf02e34caddc9adfb577f5719ac81d44e4ef592"
		);
		assert!(assert_unchanged(&sealed, &inspection).is_ok());
		let mut moved = inspection.clone();
		moved.sha256_digest = "cd".repeat(32);
		assert_eq!(
			assert_unchanged(&sealed, &moved),
			Err(EvidenceError::Changed)
		);
	}

	#[test]
	fn a_client_chosen_path_or_url_is_not_an_expectation() {
		assert!(
			Expectation::new(
				"not-a-uuid",
				"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
				"cccccccc-cccc-4ccc-8ccc-cccccccccccc",
				"image/jpeg",
				12
			)
			.is_err()
		);
		assert!(
			Expectation::new(
				"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
				"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
				"cccccccc-cccc-4ccc-8ccc-cccccccccccc",
				"text/html",
				12
			)
			.is_err()
		);
	}

	#[test]
	fn stored_bytes_are_hashed_by_the_server() {
		assert_eq!(
			digest_stored_bytes(b"jpeg-bytes!!"),
			crate::binding::sha256_hex(b"jpeg-bytes!!")
		);
	}
}
