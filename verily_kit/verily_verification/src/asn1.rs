//! Strict DER/BER ASN.1 reader and X.509 certificate verifier for Android Key
//! Attestation and Apple App Attest chains and receipts.
//!
//! Keeps exact TBS bytes for signature verification and tolerates real-world
//! hardware keystore quirks (non-minimal lengths, boolean `0x01`, high-tag
//! KeyMint fields, and leaf keys using unsupported algorithms such as ML-DSA)
//! while refusing indefinite DER lengths, truncation, duplicate extensions, and
//! algorithm confusion.

use std::collections::BTreeMap;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use chrono::DateTime;
use chrono::NaiveDate;
use chrono::Utc;
use p256::ecdsa::VerifyingKey as P256VerifyingKey;
use p384::ecdsa::VerifyingKey as P384VerifyingKey;
use rsa::BigUint;
use rsa::RsaPublicKey;
use rsa::pkcs1v15::VerifyingKey as RsaVerifyingKey;
use rsa::signature::Verifier;
use sha2::Digest;
use sha2::Sha256;
use sha2::Sha384;
use sha2::Sha512;

#[derive(Debug, Clone, thiserror::Error, PartialEq, Eq)]
#[error("{0}")]
pub struct DerError(pub String);

impl DerError {
	pub fn new(message: impl Into<String>) -> Self {
		Self(message.into())
	}
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TagClass {
	Universal = 0,
	Application = 1,
	ContextSpecific = 2,
	Private = 3,
}

pub mod tag {
	pub const BOOLEAN: u32 = 1;
	pub const INTEGER: u32 = 2;
	pub const BIT_STRING: u32 = 3;
	pub const OCTET_STRING: u32 = 4;
	pub const NULL: u32 = 5;
	pub const OBJECT_IDENTIFIER: u32 = 6;
	pub const ENUMERATED: u32 = 10;
	pub const UTF8_STRING: u32 = 12;
	pub const SEQUENCE: u32 = 16;
	pub const SET: u32 = 17;
	pub const PRINTABLE_STRING: u32 = 19;
	pub const TELETEX_STRING: u32 = 20;
	pub const IA5_STRING: u32 = 22;
	pub const UTC_TIME: u32 = 23;
	pub const GENERALIZED_TIME: u32 = 24;
	pub const BMP_STRING: u32 = 30;
}

pub mod oid {
	pub const COMMON_NAME: &str = "2.5.4.3";
	pub const SERIAL_NUMBER: &str = "2.5.4.5";
	pub const ORGANIZATION: &str = "2.5.4.10";
	pub const EC_PUBLIC_KEY: &str = "1.2.840.10045.2.1";
	pub const RSA_ENCRYPTION: &str = "1.2.840.113549.1.1.1";
	pub const SECP256R1: &str = "1.2.840.10045.3.1.7";
	pub const SECP384R1: &str = "1.3.132.0.34";
	pub const ECDSA_WITH_SHA256: &str = "1.2.840.10045.4.3.2";
	pub const ECDSA_WITH_SHA384: &str = "1.2.840.10045.4.3.3";
	pub const ECDSA_WITH_SHA512: &str = "1.2.840.10045.4.3.4";
	pub const SHA256_WITH_RSA: &str = "1.2.840.113549.1.1.11";
	pub const SHA384_WITH_RSA: &str = "1.2.840.113549.1.1.12";
	pub const SHA512_WITH_RSA: &str = "1.2.840.113549.1.1.13";
}

#[derive(Debug, Clone, Copy)]
pub struct DerElement<'a> {
	source: &'a [u8],
	pub tag_class: TagClass,
	pub tag_number: u32,
	pub constructed: bool,
	pub start: usize,
	pub value_start: usize,
	pub end: usize,
}

pub fn parse_der(bytes: &[u8]) -> Result<DerElement<'_>, DerError> {
	let element = read_element(bytes, 0, bytes.len())?;
	if element.end != bytes.len() {
		return Err(DerError::new("Trailing bytes after DER element."));
	}
	Ok(element)
}

fn read_element(source: &[u8], offset: usize, limit: usize) -> Result<DerElement<'_>, DerError> {
	let mut index = offset;
	let next = |idx: &mut usize| -> Result<u8, DerError> {
		if *idx >= limit {
			return Err(DerError::new("Truncated DER element."));
		}
		let byte = source[*idx];
		*idx += 1;
		Ok(byte)
	};

	let identifier = next(&mut index)?;
	let tag_class = match identifier >> 6 {
		0 => TagClass::Universal,
		1 => TagClass::Application,
		2 => TagClass::ContextSpecific,
		_ => TagClass::Private,
	};
	let constructed = (identifier & 0x20) != 0;
	let mut tag_number = u32::from(identifier & 0x1f);
	if tag_number == 0x1f {
		tag_number = 0;
		for octets in 0.. {
			if octets == 4 {
				return Err(DerError::new("DER tag number is too large."));
			}
			let byte = next(&mut index)?;
			tag_number = (tag_number << 7) | u32::from(byte & 0x7f);
			if (byte & 0x80) == 0 {
				break;
			}
		}
	}

	let first = next(&mut index)?;
	let length: usize = if first < 0x80 {
		usize::from(first)
	} else if first == 0x80 {
		return Err(DerError::new("Indefinite lengths are not DER."));
	} else {
		let octets = usize::from(first & 0x7f);
		if octets > 4 {
			return Err(DerError::new("DER length is too large."));
		}
		let mut len: usize = 0;
		for _ in 0..octets {
			len = (len << 8) | usize::from(next(&mut index)?);
		}
		len
	};

	let value_start = index;
	let end = value_start
		.checked_add(length)
		.ok_or_else(|| DerError::new("DER length overflow."))?;
	if end > limit {
		return Err(DerError::new("Truncated DER value."));
	}

	Ok(DerElement {
		source,
		tag_class,
		tag_number,
		constructed,
		start: offset,
		value_start,
		end,
	})
}

impl<'a> DerElement<'a> {
	pub fn encoded(&self) -> &'a [u8] {
		&self.source[self.start..self.end]
	}

	pub fn content(&self) -> &'a [u8] {
		&self.source[self.value_start..self.end]
	}

	pub fn is_universal(&self, number: u32) -> bool {
		self.tag_class == TagClass::Universal && self.tag_number == number
	}

	pub fn is_context(&self, number: u32) -> bool {
		self.tag_class == TagClass::ContextSpecific && self.tag_number == number
	}

	pub fn children(&self) -> Result<Vec<DerElement<'a>>, DerError> {
		if !self.constructed {
			return Err(DerError::new("Expected a constructed DER element."));
		}
		let mut out = Vec::new();
		let mut offset = self.value_start;
		while offset < self.end {
			let child = read_element(self.source, offset, self.end)?;
			offset = child.end;
			out.push(child);
		}
		Ok(out)
	}

	pub fn sequence(&self) -> Result<Vec<DerElement<'a>>, DerError> {
		if !self.is_universal(tag::SEQUENCE) {
			return Err(DerError::new("Expected SEQUENCE."));
		}
		self.children()
	}

	pub fn set(&self) -> Result<Vec<DerElement<'a>>, DerError> {
		if !self.is_universal(tag::SET) {
			return Err(DerError::new("Expected SET."));
		}
		self.children()
	}

	pub fn explicit(&self) -> Result<DerElement<'a>, DerError> {
		if self.tag_class != TagClass::ContextSpecific {
			return Err(DerError::new("Expected context-specific EXPLICIT tag."));
		}
		let inner = self.children()?;
		if inner.len() != 1 {
			return Err(DerError::new("EXPLICIT tag must wrap exactly one element."));
		}
		Ok(inner[0])
	}

	pub fn integer_bytes(&self) -> Result<&'a [u8], DerError> {
		self.require_primitive(tag::INTEGER)?;
		let content = self.content();
		if content.is_empty() {
			return Err(DerError::new("Empty INTEGER."));
		}
		Ok(content)
	}

	pub fn unsigned_integer_bytes(&self) -> Result<&'a [u8], DerError> {
		let bytes = self.integer_bytes()?;
		if (bytes[0] & 0x80) != 0 {
			return Err(DerError::new("Expected non-negative INTEGER."));
		}
		Ok(strip_leading_zeros(bytes))
	}

	pub fn small_int(&self) -> Result<i64, DerError> {
		let bytes = if self.is_universal(tag::ENUMERATED) && !self.constructed {
			self.content()
		} else {
			self.integer_bytes()?
		};
		if bytes.is_empty() || bytes.len() > 8 {
			return Err(DerError::new("Integer out of i64 range."));
		}
		let negative = (bytes[0] & 0x80) != 0;
		let mut value: i64 = if negative { -1 } else { 0 };
		for &byte in bytes {
			value = (value << 8) | i64::from(byte);
		}
		Ok(value)
	}

	pub fn boolean(&self) -> Result<bool, DerError> {
		self.require_primitive(tag::BOOLEAN)?;
		let content = self.content();
		if content.len() != 1 {
			return Err(DerError::new("BOOLEAN must have one octet."));
		}
		Ok(content[0] != 0)
	}

	pub fn octets(&self) -> Result<&'a [u8], DerError> {
		self.require_primitive(tag::OCTET_STRING)?;
		Ok(self.content())
	}

	pub fn bit_string_bytes(&self) -> Result<&'a [u8], DerError> {
		self.require_primitive(tag::BIT_STRING)?;
		let content = self.content();
		if content.is_empty() || content[0] != 0 {
			return Err(DerError::new("Expected whole-octet BIT STRING."));
		}
		Ok(&content[1..])
	}

	pub fn object_identifier(&self) -> Result<String, DerError> {
		self.require_primitive(tag::OBJECT_IDENTIFIER)?;
		let content = self.content();
		if content.is_empty() || (content[content.len() - 1] & 0x80) != 0 {
			return Err(DerError::new("Malformed OID."));
		}
		let mut arcs: Vec<u128> = Vec::new();
		let mut current: u128 = 0;
		for &byte in content {
			current = current
				.checked_shl(7)
				.ok_or_else(|| DerError::new("OID arc overflow."))?
				| u128::from(byte & 0x7f);
			if (byte & 0x80) == 0 {
				arcs.push(current);
				current = 0;
			}
		}
		if arcs.is_empty() {
			return Err(DerError::new("Empty OID."));
		}
		let first = arcs[0];
		let (a, b) = if first < 80 {
			(first / 40, first % 40)
		} else {
			(2, first - 80)
		};
		let mut out = format!("{a}.{b}");
		for arc in &arcs[1..] {
			out.push('.');
			out.push_str(&arc.to_string());
		}
		Ok(out)
	}

	pub fn text(&self) -> Result<String, DerError> {
		if self.tag_class != TagClass::Universal || self.constructed {
			return Err(DerError::new("Expected primitive string."));
		}
		let value = self.content();
		match self.tag_number {
			tag::UTF8_STRING => std::str::from_utf8(value)
				.map(str::to_string)
				.map_err(|_| DerError::new("Invalid UTF-8 string.")),
			tag::PRINTABLE_STRING | tag::IA5_STRING | tag::TELETEX_STRING => {
				Ok(value.iter().map(|&b| char::from(b)).collect())
			}
			tag::BMP_STRING => {
				if !value.len().is_multiple_of(2) {
					return Err(DerError::new("Invalid BMPString length."));
				}
				let units: Vec<u16> = value
					.as_chunks::<2>()
					.0
					.iter()
					.map(|pair| u16::from_be_bytes(*pair))
					.collect();
				String::from_utf16(&units).map_err(|_| DerError::new("Invalid BMPString."))
			}
			_ => Err(DerError::new("Unsupported string tag.")),
		}
	}

	pub fn time(&self) -> Result<DateTime<Utc>, DerError> {
		if self.tag_class != TagClass::Universal || self.constructed {
			return Err(DerError::new("Expected primitive time."));
		}
		let text = std::str::from_utf8(self.content())
			.map_err(|_| DerError::new("Non-ASCII certificate time."))?;
		let (year, month, day, hour, min, sec) = match self.tag_number {
			tag::UTC_TIME => {
				if text.len() != 13 || !text.ends_with('Z') {
					return Err(DerError::new("Malformed UTCTime."));
				}
				let yy: i32 = parse_2(&text[0..2])? as i32;
				let year = if yy < 50 { 2000 + yy } else { 1900 + yy };
				(
					year,
					parse_2(&text[2..4])?,
					parse_2(&text[4..6])?,
					parse_2(&text[6..8])?,
					parse_2(&text[8..10])?,
					parse_2(&text[10..12])?,
				)
			}
			tag::GENERALIZED_TIME => {
				if text.len() != 15 || !text.ends_with('Z') {
					return Err(DerError::new("Malformed GeneralizedTime."));
				}
				let year: i32 = text[0..4]
					.parse()
					.map_err(|_| DerError::new("Malformed GeneralizedTime year."))?;
				(
					year,
					parse_2(&text[4..6])?,
					parse_2(&text[6..8])?,
					parse_2(&text[8..10])?,
					parse_2(&text[10..12])?,
					parse_2(&text[12..14])?,
				)
			}
			_ => return Err(DerError::new("Expected time tag.")),
		};
		let date = NaiveDate::from_ymd_opt(year, month, day)
			.ok_or_else(|| DerError::new("Out-of-range certificate date."))?;
		let naive = date
			.and_hms_opt(hour, min, sec)
			.ok_or_else(|| DerError::new("Out-of-range certificate time."))?;
		Ok(DateTime::from_naive_utc_and_offset(naive, Utc))
	}

	fn require_primitive(&self, number: u32) -> Result<(), DerError> {
		if !self.is_universal(number) || self.constructed {
			return Err(DerError::new(format!("Expected primitive tag {number}.")));
		}
		Ok(())
	}
}

fn parse_2(s: &str) -> Result<u32, DerError> {
	if s.len() != 2 || !s.bytes().all(|b| b.is_ascii_digit()) {
		return Err(DerError::new("Malformed time component."));
	}
	s.parse()
		.map_err(|_| DerError::new("Malformed time number."))
}

pub fn strip_leading_zeros(bytes: &[u8]) -> &[u8] {
	let first_non_zero = bytes.iter().position(|&b| b != 0);
	match first_non_zero {
		Some(idx) => &bytes[idx..],
		None => &bytes[bytes.len().saturating_sub(1)..],
	}
}

/// Normalizes Apple PKCS#7 BER indefinite containers and fragmented OCTET
/// STRINGs into DER while leaving primitive payload bytes untouched.
pub fn normalize_receipt_ber(input: &[u8]) -> Result<Vec<u8>, DerError> {
	struct Reader<'a> {
		input: &'a [u8],
		offset: usize,
		nodes: usize,
	}

	impl<'a> Reader<'a> {
		fn next(&mut self) -> Result<u8, DerError> {
			if self.offset >= self.input.len() {
				return Err(DerError::new("Truncated BER."));
			}
			let byte = self.input[self.offset];
			self.offset += 1;
			Ok(byte)
		}

		fn read(&mut self, depth: usize) -> Result<Vec<u8>, DerError> {
			self.nodes += 1;
			if depth > 24 || self.nodes > 4096 {
				return Err(DerError::new("BER depth or node limit exceeded."));
			}
			let tag = self.next()?;
			if tag == 0 || (tag & 31) == 31 {
				return Err(DerError::new("Unsupported BER tag."));
			}
			let first = self.next()?;
			let indefinite = first == 0x80;
			let length: usize = if first < 0x80 {
				usize::from(first)
			} else if indefinite {
				0
			} else {
				let count = usize::from(first & 0x7f);
				if count > 4 {
					return Err(DerError::new("BER length too large."));
				}
				let mut len: usize = 0;
				for _ in 0..count {
					len = (len << 8) | usize::from(self.next()?);
				}
				len
			};
			if indefinite && (tag & 0x20) == 0 {
				return Err(DerError::new("Primitive indefinite BER length."));
			}
			let end = self
				.offset
				.checked_add(length)
				.ok_or_else(|| DerError::new("BER length overflow."))?;
			if !indefinite && end > self.input.len() {
				return Err(DerError::new("BER length exceeds input."));
			}

			let mut value = Vec::new();
			if (tag & 0x20) == 0 {
				value.extend_from_slice(&self.input[self.offset..end]);
				self.offset = end;
			} else {
				loop {
					if indefinite {
						if self.offset + 1 < self.input.len()
							&& self.input[self.offset] == 0
							&& self.input[self.offset + 1] == 0
						{
							self.offset += 2;
							break;
						}
					} else if self.offset >= end {
						break;
					}
					let child = self.read(depth + 1)?;
					if tag == 0x24 {
						if child.first() != Some(&4) {
							return Err(DerError::new("Expected OCTET STRING fragment."));
						}
						let mut start = 2;
						if child.len() < 2 {
							return Err(DerError::new("Truncated OCTET STRING fragment."));
						}
						if child[1] >= 128 {
							start += usize::from(child[1] & 0x7f);
						}
						if start > child.len() {
							return Err(DerError::new("Malformed OCTET STRING fragment."));
						}
						value.extend_from_slice(&child[start..]);
					} else {
						value.extend_from_slice(&child);
					}
				}
				if !indefinite && self.offset != end {
					return Err(DerError::new("BER container overrun."));
				}
			}

			let mut out = Vec::with_capacity(value.len() + 6);
			out.push(if tag == 0x24 { 4 } else { tag });
			if value.len() < 128 {
				out.push(value.len() as u8);
			} else {
				let mut size_bytes = Vec::new();
				let mut rem = value.len();
				while rem > 0 {
					size_bytes.push((rem & 0xff) as u8);
					rem >>= 8;
				}
				size_bytes.reverse();
				out.push(0x80 | (size_bytes.len() as u8));
				out.extend_from_slice(&size_bytes);
			}
			out.extend_from_slice(&value);
			Ok(out)
		}
	}

	let mut reader = Reader {
		input,
		offset: 0,
		nodes: 0,
	};
	let result = reader.read(0)?;
	if reader.offset != input.len() {
		return Err(DerError::new("Trailing BER bytes."));
	}
	Ok(result)
}

#[derive(Debug, Clone)]
pub struct X509Name {
	pub encoded: Vec<u8>,
	attributes: Vec<Vec<NameAttribute>>,
	canonical: String,
}

#[derive(Debug, Clone)]
struct NameAttribute {
	oid: String,
	text: Option<String>,
	canonical: String,
}

impl X509Name {
	fn parse(element: DerElement<'_>) -> Result<Self, DerError> {
		let mut attributes = Vec::new();
		for rdn in element.sequence()? {
			let mut rdn_attrs = Vec::new();
			for attr in rdn.set()? {
				let parts = attr.sequence()?;
				if parts.len() != 2 {
					return Err(DerError::new("Malformed X509 name attribute."));
				}
				let oid = parts[0].object_identifier()?;
				let text = parts[1].text().ok();
				let canonical = match &text {
					Some(s) => {
						let collapsed = s
							.split_whitespace()
							.collect::<Vec<_>>()
							.join(" ")
							.to_ascii_lowercase();
						format!("{oid}={collapsed}")
					}
					None => format!("{oid}=#{}", hex_lower(parts[1].encoded())),
				};
				rdn_attrs.push(NameAttribute {
					oid,
					text,
					canonical,
				});
			}
			if rdn_attrs.is_empty() {
				return Err(DerError::new("Empty relative distinguished name."));
			}
			attributes.push(rdn_attrs);
		}
		let canonical = attributes
			.iter()
			.map(|rdn| {
				let mut items: Vec<&str> = rdn.iter().map(|a| a.canonical.as_str()).collect();
				items.sort_unstable();
				items.join("+")
			})
			.collect::<Vec<_>>()
			.join(",");
		Ok(Self {
			encoded: element.encoded().to_vec(),
			attributes,
			canonical,
		})
	}

	pub fn attribute(&self, target_oid: &str) -> Option<&str> {
		for rdn in &self.attributes {
			for attr in rdn {
				if attr.oid == target_oid {
					return attr.text.as_deref();
				}
			}
		}
		None
	}

	pub fn mentions(&self, word: &str) -> bool {
		let needle = word.to_ascii_lowercase();
		self.attributes.iter().any(|rdn| {
			rdn.iter().any(|attr| {
				attr.text
					.as_deref()
					.is_some_and(|t| t.to_ascii_lowercase().contains(&needle))
			})
		})
	}

	pub fn matches(&self, other: &Self) -> bool {
		self.encoded == other.encoded || self.canonical == other.canonical
	}
}

#[derive(Debug, Clone)]
pub enum CertificatePublicKey {
	Ec { curve_oid: String, point: Vec<u8> },
	Rsa { modulus: Vec<u8>, exponent: Vec<u8> },
	Unsupported(String),
}

impl CertificatePublicKey {
	fn parse(spki: DerElement<'_>) -> Result<Self, DerError> {
		let parts = spki.sequence()?;
		if parts.len() != 2 {
			return Err(DerError::new("Malformed SubjectPublicKeyInfo."));
		}
		let algorithm = parts[0].sequence()?;
		if algorithm.is_empty() {
			return Err(DerError::new("Empty key algorithm."));
		}
		let alg_oid = algorithm[0].object_identifier()?;
		let key_bytes = parts[1].bit_string_bytes()?;
		match alg_oid.as_str() {
			oid::EC_PUBLIC_KEY => {
				if algorithm.len() != 2 {
					return Err(DerError::new("EC key missing curve OID."));
				}
				let curve_oid = algorithm[1].object_identifier()?;
				let coord_bytes = match curve_oid.as_str() {
					oid::SECP256R1 => 32,
					oid::SECP384R1 => 48,
					_ => {
						return Ok(Self::Unsupported(format!("{alg_oid}/{curve_oid}")));
					}
				};
				if key_bytes.len() != 1 + 2 * coord_bytes || key_bytes[0] != 0x04 {
					return Err(DerError::new("Expected uncompressed EC point."));
				}
				Ok(Self::Ec {
					curve_oid,
					point: key_bytes.to_vec(),
				})
			}
			oid::RSA_ENCRYPTION => {
				let rsa_parts = parse_der(key_bytes)?.sequence()?;
				if rsa_parts.len() != 2 {
					return Err(DerError::new("Malformed RSA public key."));
				}
				let modulus = rsa_parts[0].unsigned_integer_bytes()?.to_vec();
				let exponent = rsa_parts[1].unsigned_integer_bytes()?.to_vec();
				if modulus.is_empty()
					|| exponent.is_empty()
					|| (exponent.len() == 1 && exponent[0] <= 1)
				{
					return Err(DerError::new("Invalid RSA modulus or exponent."));
				}
				Ok(Self::Rsa { modulus, exponent })
			}
			_ => Ok(Self::Unsupported(alg_oid)),
		}
	}

	pub fn p256_point(&self) -> Option<&[u8]> {
		match self {
			Self::Ec { curve_oid, point } if curve_oid == oid::SECP256R1 => Some(point),
			_ => None,
		}
	}

	pub fn verifies(&self, message: &[u8], signature_algorithm: &str, signature: &[u8]) -> bool {
		match self {
			Self::Ec { curve_oid, point } => {
				verify_ecdsa_der(curve_oid, point, message, signature_algorithm, signature)
			}
			Self::Rsa { modulus, exponent } => {
				verify_rsa_pkcs1v15(modulus, exponent, message, signature_algorithm, signature)
			}
			Self::Unsupported(_) => false,
		}
	}
}

pub fn verify_ecdsa_der(
	curve_oid: &str,
	point: &[u8],
	message: &[u8],
	signature_algorithm: &str,
	signature_der: &[u8],
) -> bool {
	let digest: Vec<u8> = match signature_algorithm {
		oid::ECDSA_WITH_SHA256 => Sha256::digest(message).to_vec(),
		oid::ECDSA_WITH_SHA384 => Sha384::digest(message).to_vec(),
		oid::ECDSA_WITH_SHA512 => Sha512::digest(message).to_vec(),
		_ => return false,
	};
	match curve_oid {
		oid::SECP256R1 => {
			let Ok(vk) = P256VerifyingKey::from_sec1_bytes(point) else {
				return false;
			};
			let Ok(sig) = p256::ecdsa::DerSignature::from_bytes(signature_der)
				.and_then(p256::ecdsa::Signature::try_from)
			else {
				return false;
			};
			use p256::ecdsa::signature::hazmat::PrehashVerifier;
			vk.verify_prehash(&digest, &sig).is_ok()
		}
		oid::SECP384R1 => {
			let Ok(vk) = P384VerifyingKey::from_sec1_bytes(point) else {
				return false;
			};
			let Ok(sig) = p384::ecdsa::DerSignature::from_bytes(signature_der)
				.and_then(p384::ecdsa::Signature::try_from)
			else {
				return false;
			};
			use p384::ecdsa::signature::hazmat::PrehashVerifier;
			vk.verify_prehash(&digest, &sig).is_ok()
		}
		_ => false,
	}
}

fn verify_rsa_pkcs1v15(
	modulus: &[u8],
	exponent: &[u8],
	message: &[u8],
	signature_algorithm: &str,
	signature: &[u8],
) -> bool {
	let n = BigUint::from_bytes_be(modulus);
	let e = BigUint::from_bytes_be(exponent);
	let Ok(public_key) = RsaPublicKey::new(n, e) else {
		return false;
	};
	let Ok(sig) = rsa::pkcs1v15::Signature::try_from(signature) else {
		return false;
	};
	match signature_algorithm {
		oid::SHA256_WITH_RSA => {
			let vk = RsaVerifyingKey::<Sha256>::new(public_key);
			vk.verify(message, &sig).is_ok()
		}
		oid::SHA384_WITH_RSA => {
			let vk = RsaVerifyingKey::<Sha384>::new(public_key);
			vk.verify(message, &sig).is_ok()
		}
		oid::SHA512_WITH_RSA => {
			let vk = RsaVerifyingKey::<Sha512>::new(public_key);
			vk.verify(message, &sig).is_ok()
		}
		_ => false,
	}
}

#[derive(Debug, Clone)]
pub struct X509Certificate {
	pub encoded: Vec<u8>,
	pub tbs: Vec<u8>,
	pub signature_algorithm: String,
	pub signature: Vec<u8>,
	pub serial_bytes: Vec<u8>,
	pub issuer: X509Name,
	pub subject: X509Name,
	pub not_before: DateTime<Utc>,
	pub not_after: DateTime<Utc>,
	pub subject_public_key_info: Vec<u8>,
	pub public_key: CertificatePublicKey,
	pub extensions: BTreeMap<String, Vec<u8>>,
}

impl X509Certificate {
	pub fn parse(der: &[u8]) -> Result<Self, DerError> {
		let cert = parse_der(der)?.sequence()?;
		if cert.len() != 3 {
			return Err(DerError::new("X509 certificate must have three elements."));
		}
		let tbs = cert[0];
		let fields = tbs.sequence()?;
		let mut idx = 0usize;
		let next = |i: &mut usize| -> Result<DerElement<'_>, DerError> {
			let item = *fields
				.get(*i)
				.ok_or_else(|| DerError::new("Truncated TBSCertificate."))?;
			*i += 1;
			Ok(item)
		};

		if fields.first().is_some_and(|f| f.is_context(0)) {
			let version = next(&mut idx)?.explicit()?.small_int()?;
			if !(0..=2).contains(&version) {
				return Err(DerError::new("Unknown X509 version."));
			}
		}

		let serial_bytes = next(&mut idx)?.integer_bytes()?.to_vec();
		let inner_alg = algorithm_oid(next(&mut idx)?)?;
		let issuer = X509Name::parse(next(&mut idx)?)?;
		let validity = next(&mut idx)?.sequence()?;
		if validity.len() != 2 {
			return Err(DerError::new("X509 validity must have two timestamps."));
		}
		let not_before = validity[0].time()?;
		let not_after = validity[1].time()?;
		let subject = X509Name::parse(next(&mut idx)?)?;
		let spki = next(&mut idx)?;
		let subject_public_key_info = spki.encoded().to_vec();
		let public_key = CertificatePublicKey::parse(spki)?;

		let mut extensions = BTreeMap::new();
		let mut last_tag: u32 = 0;
		while idx < fields.len() {
			let opt = next(&mut idx)?;
			if opt.tag_class != TagClass::ContextSpecific
				|| opt.tag_number <= last_tag
				|| opt.tag_number > 3
			{
				return Err(DerError::new("Unexpected optional certificate field."));
			}
			last_tag = opt.tag_number;
			if opt.tag_number != 3 {
				continue;
			}
			for ext in opt.explicit()?.sequence()? {
				let parts = ext.sequence()?;
				if parts.len() < 2 || parts.len() > 3 {
					return Err(DerError::new("Malformed X509 extension."));
				}
				let ext_oid = parts[0].object_identifier()?;
				if parts.len() == 3 && !parts[1].is_universal(tag::BOOLEAN) {
					return Err(DerError::new("Malformed extension criticality flag."));
				}
				let value = parts[parts.len() - 1].octets()?.to_vec();
				if extensions.insert(ext_oid, value).is_some() {
					return Err(DerError::new("Duplicate X509 extension."));
				}
			}
		}

		let outer_alg = algorithm_oid(cert[1])?;
		if outer_alg != inner_alg {
			return Err(DerError::new("Certificate signature algorithms disagree."));
		}
		let signature = cert[2].bit_string_bytes()?.to_vec();

		Ok(Self {
			encoded: der.to_vec(),
			tbs: tbs.encoded().to_vec(),
			signature_algorithm: outer_alg,
			signature,
			serial_bytes,
			issuer,
			subject,
			not_before,
			not_after,
			subject_public_key_info,
			public_key,
			extensions,
		})
	}

	pub fn from_pem(pem: &str) -> Result<Self, DerError> {
		let der = decode_pem_blocks(pem)?;
		if der.len() != 1 {
			return Err(DerError::new("Expected exactly one PEM CERTIFICATE block."));
		}
		Self::parse(&der[0])
	}

	/// Lowercase hex serial without leading zeros (matching Google's status list).
	pub fn serial_hex(&self) -> String {
		let stripped = strip_leading_zeros(&self.serial_bytes);
		let full = hex_lower(stripped);
		let trimmed = full.trim_start_matches('0');
		if trimmed.is_empty() {
			"0".to_string()
		} else {
			trimmed.to_string()
		}
	}

	pub fn is_self_issued(&self) -> bool {
		self.issuer.matches(&self.subject)
	}

	pub fn is_signed_by(&self, issuer_key: &CertificatePublicKey) -> bool {
		issuer_key.verifies(&self.tbs, &self.signature_algorithm, &self.signature)
	}

	pub fn is_valid_at(&self, instant: DateTime<Utc>) -> bool {
		instant >= self.not_before && instant <= self.not_after
	}
}

pub fn decode_pem_blocks(pem: &str) -> Result<Vec<Vec<u8>>, DerError> {
	let mut certs = Vec::new();
	let mut in_block = false;
	let mut body = String::new();
	for line in pem.lines() {
		let trimmed = line.trim();
		if trimmed == "-----BEGIN CERTIFICATE-----" {
			in_block = true;
			body.clear();
		} else if trimmed == "-----END CERTIFICATE-----" {
			if !in_block {
				return Err(DerError::new("Unexpected END CERTIFICATE."));
			}
			let der = STANDARD
				.decode(body.as_bytes())
				.map_err(|_| DerError::new("Invalid PEM base64."))?;
			certs.push(der);
			in_block = false;
			body.clear();
		} else if in_block {
			body.push_str(trimmed);
		}
	}
	if in_block {
		return Err(DerError::new("Unterminated PEM block."));
	}
	Ok(certs)
}

pub fn algorithm_oid(element: DerElement<'_>) -> Result<String, DerError> {
	let parts = element.sequence()?;
	if parts.is_empty() || parts.len() > 2 {
		return Err(DerError::new("Malformed AlgorithmIdentifier."));
	}
	parts[0].object_identifier()
}

pub fn hex_lower(bytes: &[u8]) -> String {
	const HEX: &[u8; 16] = b"0123456789abcdef";
	let mut out = String::with_capacity(bytes.len() * 2);
	for &byte in bytes {
		out.push(char::from(HEX[usize::from(byte >> 4)]));
		out.push(char::from(HEX[usize::from(byte & 0x0f)]));
	}
	out
}

pub fn constant_time_eq(left: &[u8], right: &[u8]) -> bool {
	if left.len() != right.len() {
		return false;
	}
	let mut diff = 0u8;
	for (&a, &b) in left.iter().zip(right.iter()) {
		diff |= a ^ b;
	}
	diff == 0
}
