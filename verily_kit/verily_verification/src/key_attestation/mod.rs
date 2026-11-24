//! Android Key Attestation chain verifier pinned to Google's Hardware
//! Attestation roots.
//!
//! Ported from `verily_server/lib/src/action_verification/key_attestation/` and
//! validated against the byte-identical vectors from `android/keyattestation`.

use std::collections::BTreeMap;
use std::collections::HashMap;
use std::collections::HashSet;
use std::sync::Arc;
use std::sync::Mutex;
use std::time::Duration;

use chrono::DateTime;
use chrono::Datelike;
use chrono::Utc;
use sha2::Digest;
use sha2::Sha256;

use crate::asn1::DerElement;
use crate::asn1::DerError;
use crate::asn1::TagClass;
use crate::asn1::X509Certificate;
use crate::asn1::constant_time_eq;
use crate::asn1::hex_lower;
use crate::asn1::oid;
use crate::asn1::parse_der;
use crate::capture::AndroidAttestation;
use crate::capture::CaptureError;
use crate::capture::KeyStorage;
use crate::capture::ParsedAndroidKey;

/// The Android application id Play and the keystore attest.
pub const VERILY_ANDROID_PACKAGE_NAME: &str = "fun.verily.app";

/// The Android Key Attestation extension, `KeyDescription`.
pub const KEY_ATTESTATION_EXTENSION_OID: &str = "1.3.6.1.4.1.11129.2.1.17";

const MAX_CHAIN_LENGTH: usize = 10;
const MAX_CERTIFICATE_BYTES: usize = 16 * 1024;
const MAX_PACKAGES: usize = 32;
const MAX_SIGNATURES: usize = 10;
const MAX_STATUS_BODY_BYTES: usize = 8 * 1024 * 1024;
const MAX_FRESHNESS_SECONDS: u64 = 24 * 60 * 60;

pub mod reason {
	pub const VALID: &str = "capture_attestation_valid";
	pub const CHAIN_INVALID: &str = "capture_attestation_chain_invalid";
	pub const UNTRUSTED_ROOT: &str = "capture_attestation_untrusted_root";
	pub const EXPIRED: &str = "capture_attestation_expired";
	pub const REVOKED: &str = "capture_attestation_revoked";
	pub const STATUS_UNAVAILABLE: &str = "capture_attestation_status_unavailable";
	pub const EXTENSION_INVALID: &str = "capture_attestation_extension_invalid";
	pub const CHALLENGE_MISMATCH: &str = "capture_attestation_challenge_mismatch";
	pub const SECURITY_LEVEL: &str = "capture_attestation_security_level";
	pub const BOOT_UNTRUSTED: &str = "capture_attestation_boot_untrusted";
	pub const KEY_INVALID: &str = "capture_attestation_key_invalid";
	pub const APP_MISMATCH: &str = "capture_attestation_app_mismatch";
	pub const PATCH_OUTDATED: &str = "capture_attestation_patch_outdated";
	pub const UNCONFIGURED: &str = "capture_attestation_unconfigured";
}

/// Pinned Google Android Key Attestation roots (`https://android.googleapis.com/attestation/root`).
const LEGACY_RSA_ROOT_PEM: &str = "\
-----BEGIN CERTIFICATE-----
MIIFHDCCAwSgAwIBAgIJAPHBcqaZ6vUdMA0GCSqGSIb3DQEBCwUAMBsxGTAXBgNV
BAUTEGY5MjAwOWU4NTNiNmIwNDUwHhcNMjIwMzIwMTgwNzQ4WhcNNDIwMzE1MTgw
NzQ4WjAbMRkwFwYDVQQFExBmOTIwMDllODUzYjZiMDQ1MIICIjANBgkqhkiG9w0B
AQEFAAOCAg8AMIICCgKCAgEAr7bHgiuxpwHsK7Qui8xUFmOr75gvMsd/dTEDDJdS
Sxtf6An7xyqpRR90PL2abxM1dEqlXnf2tqw1Ne4Xwl5jlRfdnJLmN0pTy/4lj4/7
tv0Sk3iiKkypnEUtR6WfMgH0QZfKHM1+di+y9TFRtv6y//0rb+T+W8a9nsNL/ggj
nar86461qO0rOs2cXjp3kOG1FEJ5MVmFmBGtnrKpa73XpXyTqRxB/M0n1n/W9nGq
C4FSYa04T6N5RIZGBN2z2MT5IKGbFlbC8UrW0DxW7AYImQQcHtGl/m00QLVWutHQ
oVJYnFPlXTcHYvASLu+RhhsbDmxMgJJ0mcDpvsC4PjvB+TxywElgS70vE0XmLD+O
JtvsBslHZvPBKCOdT0MS+tgSOIfga+z1Z1g7+DVagf7quvmag8jfPioyKvxnK/Eg
sTUVi2ghzq8wm27ud/mIM7AY2qEORR8Go3TVB4HzWQgpZrt3i5MIlCaY504LzSRi
igHCzAPlHws+W0rB5N+er5/2pJKnfBSDiCiFAVtCLOZ7gLiMm0jhO2B6tUXHI/+M
RPjy02i59lINMRRev56GKtcd9qO/0kUJWdZTdA2XoS82ixPvZtXQpUpuL12ab+9E
aDK8Z4RHJYYfCT3Q5vNAXaiWQ+8PTWm2QgBR/bkwSWc+NpUFgNPN9PvQi8WEg5Um
AGMCAwEAAaNjMGEwHQYDVR0OBBYEFDZh4QB8iAUJUYtEbEf/GkzJ6k8SMB8GA1Ud
IwQYMBaAFDZh4QB8iAUJUYtEbEf/GkzJ6k8SMA8GA1UdEwEB/wQFMAMBAf8wDgYD
VR0PAQH/BAQDAgIEMA0GCSqGSIb3DQEBCwUAA4ICAQB8cMqTllHc8U+qCrOlg3H7
174lmaCsbo/bJ0C17JEgMLb4kvrqsXZs01U3mB/qABg/1t5Pd5AORHARs1hhqGIC
W/nKMav574f9rZN4PC2ZlufGXb7sIdJpGiO9ctRhiLuYuly10JccUZGEHpHSYM2G
tkgYbZba6lsCPYAAP83cyDV+1aOkTf1RCp/lM0PKvmxYN10RYsK631jrleGdcdkx
oSK//mSQbgcWnmAEZrzHoF1/0gso1HZgIn0YLzVhLSA/iXCX4QT2h3J5z3znluKG
1nv8NQdxei2DIIhASWfu804CA96cQKTTlaae2fweqXjdN1/v2nqOhngNyz1361mF
mr4XmaKH/ItTwOe72NI9ZcwS1lVaCvsIkTDCEXdm9rCNPAY10iTunIHFXRh+7KPz
lHGewCq/8TOohBRn0/NNfh7uRslOSZ/xKbN9tMBtw37Z8d2vvnXq/YWdsm1+JLVw
n6yYD/yacNJBlwpddla8eaVMjsF6nBnIgQOf9zKSe06nSTqvgwUHosgOECZJZ1Eu
zbH4yswbt02tKtKEFhx+v+OTge/06V+jGsqTWLsfrOCNLuA8H++z+pUENmpqnnHo
vaI47gC+TNpkgYGkkBT6B/m/U01BuOBBTzhIlMEZq9qkDWuM2cA5kW5V3FJUcfHn
w1IdYIg2Wxg7yHcQZemFQg==
-----END CERTIFICATE-----";

const KEY_ATTESTATION_CA1_PEM: &str = "\
-----BEGIN CERTIFICATE-----
MIICIjCCAaigAwIBAgIRAISp0Cl7DrWK5/8OgN52BgUwCgYIKoZIzj0EAwMwUjEc
MBoGA1UEAwwTS2V5IEF0dGVzdGF0aW9uIENBMTEQMA4GA1UECwwHQW5kcm9pZDET
MBEGA1UECgwKR29vZ2xlIExMQzELMAkGA1UEBhMCVVMwHhcNMjUwNzE3MjIzMjE4
WhcNMzUwNzE1MjIzMjE4WjBSMRwwGgYDVQQDDBNLZXkgQXR0ZXN0YXRpb24gQ0Ex
MRAwDgYDVQQLDAdBbmRyb2lkMRMwEQYDVQQKDApHb29nbGUgTExDMQswCQYDVQQG
EwJVUzB2MBAGByqGSM49AgEGBSuBBAAiA2IABCPaI3FO3z5bBQo8cuiEas4HjqCt
G/mLFfRT0MsIssPBEEU5Cfbt6sH5yOAxqEi5QagpU1yX4HwnGb7OtBYpDTB57uH5
Eczm34A5FNijV3s0/f0UPl7zbJcTx6xwqMIRq6NCMEAwDwYDVR0TAQH/BAUwAwEB
/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFFIyuyz7RkOb3NaBqQ5lZuA0QepA
MAoGCCqGSM49BAMDA2gAMGUCMETfjPO/HwqReR2CS7p0ZWoD/LHs6hDi422opifH
EUaYLxwGlT9SLdjkVpz0UUOR5wIxAIoGyxGKRHVTpqpGRFiJtQEOOTp/+s1GcxeY
uR2zh/80lQyu9vAFCj6E4AXc+osmRg==
-----END CERTIFICATE-----";

pub fn google_attestation_roots() -> Vec<X509Certificate> {
	vec![
		X509Certificate::from_pem(LEGACY_RSA_ROOT_PEM)
			.expect("pinned Google legacy RSA root is valid DER"),
		X509Certificate::from_pem(KEY_ATTESTATION_CA1_PEM)
			.expect("pinned Google Key Attestation CA1 root is valid DER"),
	]
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KeySecurityLevel {
	Software = 0,
	TrustedEnvironment = 1,
	StrongBox = 2,
}

impl KeySecurityLevel {
	pub fn from_i64(value: i64) -> Result<Self, DerError> {
		match value {
			0 => Ok(Self::Software),
			1 => Ok(Self::TrustedEnvironment),
			2 => Ok(Self::StrongBox),
			other => Err(DerError::new(format!("Unknown security level {other}."))),
		}
	}

	pub const fn as_key_storage(self) -> Option<KeyStorage> {
		match self {
			Self::StrongBox => Some(KeyStorage::StrongBox),
			Self::TrustedEnvironment => Some(KeyStorage::TrustedEnvironment),
			Self::Software => None,
		}
	}
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VerifiedBootState {
	Verified = 0,
	SelfSigned = 1,
	Unverified = 2,
	Failed = 3,
}

impl VerifiedBootState {
	pub fn from_i64(value: i64) -> Result<Self, DerError> {
		match value {
			0 => Ok(Self::Verified),
			1 => Ok(Self::SelfSigned),
			2 => Ok(Self::Unverified),
			3 => Ok(Self::Failed),
			other => Err(DerError::new(format!("Unknown boot state {other}."))),
		}
	}
}

pub mod keymint_tag {
	pub const PURPOSE: u32 = 1;
	pub const ALGORITHM: u32 = 2;
	pub const KEY_SIZE: u32 = 3;
	pub const EC_CURVE: u32 = 10;
	pub const ORIGIN: u32 = 702;
	pub const ROOT_OF_TRUST: u32 = 704;
	pub const OS_VERSION: u32 = 705;
	pub const OS_PATCH_LEVEL: u32 = 706;
	pub const ATTESTATION_APPLICATION_ID: u32 = 709;

	pub const PURPOSE_SIGN: i64 = 2;
	pub const ALGORITHM_EC: i64 = 3;
	pub const EC_CURVE_P256: i64 = 1;
	pub const ORIGIN_GENERATED: i64 = 0;
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RootOfTrust {
	pub verified_boot_key: Vec<u8>,
	pub device_locked: bool,
	pub verified_boot_state: VerifiedBootState,
}

impl RootOfTrust {
	pub fn parse(element: DerElement<'_>) -> Result<Self, DerError> {
		let fields = element.sequence()?;
		if fields.len() != 3 && fields.len() != 4 {
			return Err(DerError::new("Malformed RootOfTrust."));
		}
		Ok(Self {
			verified_boot_key: fields[0].octets()?.to_vec(),
			device_locked: fields[1].boolean()?,
			verified_boot_state: VerifiedBootState::from_i64(fields[2].small_int()?)?,
		})
	}
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AttestationApplicationId {
	pub package_names: HashSet<String>,
	pub signature_digests: HashSet<String>,
}

impl AttestationApplicationId {
	pub fn parse(bytes: &[u8]) -> Result<Self, DerError> {
		let fields = parse_der(bytes)?.sequence()?;
		if fields.len() != 2 {
			return Err(DerError::new("Malformed AttestationApplicationId."));
		}
		let packages = fields[0].set()?;
		let signatures = fields[1].set()?;
		if packages.len() > MAX_PACKAGES || signatures.len() > MAX_SIGNATURES {
			return Err(DerError::new("AttestationApplicationId is too large."));
		}
		let mut package_names = HashSet::new();
		for pkg in packages {
			let parts = pkg.sequence()?;
			if parts.len() != 2 {
				return Err(DerError::new("Malformed package info."));
			}
			let version = parts[1].small_int()?;
			if version < 0 {
				return Err(DerError::new("Negative package version."));
			}
			let name = std::str::from_utf8(parts[0].octets()?)
				.map_err(|_| DerError::new("Non-UTF-8 package name."))?;
			package_names.insert(name.to_string());
		}
		let mut signature_digests = HashSet::new();
		for sig in signatures {
			signature_digests.insert(hex_lower(sig.octets()?));
		}
		Ok(Self {
			package_names,
			signature_digests,
		})
	}

	pub fn same_identity_as(&self, other: &Self) -> bool {
		self.package_names == other.package_names
			&& self.signature_digests == other.signature_digests
	}
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct AuthorizationList {
	pub purposes: Option<HashSet<i64>>,
	pub algorithm: Option<i64>,
	pub key_size: Option<i64>,
	pub ec_curve: Option<i64>,
	pub origin: Option<i64>,
	pub root_of_trust: Option<RootOfTrust>,
	pub os_version: Option<i64>,
	pub os_patch_level: Option<i64>,
	pub attestation_application_id: Option<AttestationApplicationId>,
}

impl AuthorizationList {
	pub fn parse(element: DerElement<'_>) -> Result<Self, DerError> {
		let mut seen = HashSet::new();
		let mut list = Self::default();
		for entry in element.sequence()? {
			if entry.tag_class != TagClass::ContextSpecific {
				return Err(DerError::new(
					"Authorization tags must be context-specific.",
				));
			}
			if !seen.insert(entry.tag_number) {
				return Err(DerError::new(format!(
					"Tag {} is repeated.",
					entry.tag_number
				)));
			}
			let value = entry.explicit()?;
			match entry.tag_number {
				keymint_tag::PURPOSE => {
					let mut set = HashSet::new();
					for item in value.set()? {
						set.insert(item.small_int()?);
					}
					list.purposes = Some(set);
				}
				keymint_tag::ALGORITHM => list.algorithm = Some(value.small_int()?),
				keymint_tag::KEY_SIZE => list.key_size = Some(value.small_int()?),
				keymint_tag::EC_CURVE => list.ec_curve = Some(value.small_int()?),
				keymint_tag::ORIGIN => list.origin = Some(value.small_int()?),
				keymint_tag::ROOT_OF_TRUST => list.root_of_trust = Some(RootOfTrust::parse(value)?),
				keymint_tag::OS_VERSION => list.os_version = Some(value.small_int()?),
				keymint_tag::OS_PATCH_LEVEL => list.os_patch_level = Some(value.small_int()?),
				keymint_tag::ATTESTATION_APPLICATION_ID => {
					list.attestation_application_id =
						Some(AttestationApplicationId::parse(value.octets()?)?);
				}
				_ => {}
			}
		}
		Ok(list)
	}
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyDescription {
	pub attestation_version: i64,
	pub attestation_security_level: KeySecurityLevel,
	pub key_mint_version: i64,
	pub key_mint_security_level: KeySecurityLevel,
	pub attestation_challenge: Vec<u8>,
	pub software_enforced: AuthorizationList,
	pub hardware_enforced: AuthorizationList,
}

impl KeyDescription {
	pub fn parse(extension_value: &[u8]) -> Result<Self, DerError> {
		let fields = parse_der(extension_value)?.sequence()?;
		if fields.len() != 8 {
			return Err(DerError::new("A KeyDescription has eight fields."));
		}
		Ok(Self {
			attestation_version: fields[0].small_int()?,
			attestation_security_level: KeySecurityLevel::from_i64(fields[1].small_int()?)?,
			key_mint_version: fields[2].small_int()?,
			key_mint_security_level: KeySecurityLevel::from_i64(fields[3].small_int()?)?,
			attestation_challenge: fields[4].octets()?.to_vec(),
			software_enforced: AuthorizationList::parse(fields[6])?,
			hardware_enforced: AuthorizationList::parse(fields[7])?,
		})
	}

	pub fn attestation_application_id(
		&self,
	) -> Result<Option<&AttestationApplicationId>, DerError> {
		let software = self.software_enforced.attestation_application_id.as_ref();
		let hardware = self.hardware_enforced.attestation_application_id.as_ref();
		if let (Some(sw), Some(hw)) = (software, hardware)
			&& !sw.same_identity_as(hw)
		{
			return Err(DerError::new("Attestation application ids disagree."));
		}
		Ok(hardware.or(software))
	}
}

/// Google's attestation certificate status list (by lowercase serial hex).
#[derive(Debug, Clone, Default)]
pub struct AttestationStatusList {
	listed: HashSet<String>,
}

impl AttestationStatusList {
	pub fn new(serials: impl IntoIterator<Item = impl Into<String>>) -> Self {
		Self {
			listed: serials
				.into_iter()
				.map(|s| s.into().trim().to_ascii_lowercase())
				.collect(),
		}
	}

	pub fn parse(body: &str) -> Result<Self, String> {
		let value: serde_json::Value =
			serde_json::from_str(body).map_err(|e| format!("Invalid status list JSON: {e}"))?;
		let entries = value
			.get("entries")
			.and_then(|v| v.as_object())
			.ok_or_else(|| "The status list has no entries object.".to_string())?;
		let mut listed = HashSet::with_capacity(entries.len());
		for (key, entry) in entries {
			if key.is_empty()
				|| key.len() > 64
				|| !key.bytes().all(|b| matches!(b, b'0'..=b'9' | b'a'..=b'f'))
			{
				return Err("Malformed serial in status list.".to_string());
			}
			let has_status = entry
				.as_object()
				.and_then(|obj| obj.get("status"))
				.and_then(|v| v.as_str())
				.is_some();
			if !has_status {
				return Err("Malformed status list entry.".to_string());
			}
			listed.insert(key.clone());
		}
		Ok(Self { listed })
	}

	pub fn len(&self) -> usize {
		self.listed.len()
	}

	pub fn is_empty(&self) -> bool {
		self.listed.is_empty()
	}

	pub fn lists(&self, serial_hex: &str) -> bool {
		self.listed.contains(serial_hex)
	}
}

#[derive(Debug, Clone, thiserror::Error)]
#[error("AttestationStatusUnavailable({0})")]
pub struct AttestationStatusUnavailable(pub String);

pub trait AttestationStatusSource: Send + Sync {
	fn status_at(
		&self,
		now: DateTime<Utc>,
	) -> Result<AttestationStatusList, AttestationStatusUnavailable>;
}

/// Fixed in-memory status source for tests or offline pinned snapshots.
#[derive(Debug, Clone)]
pub struct FixedStatusSource(pub AttestationStatusList);

impl AttestationStatusSource for FixedStatusSource {
	fn status_at(
		&self,
		_now: DateTime<Utc>,
	) -> Result<AttestationStatusList, AttestationStatusUnavailable> {
		Ok(self.0.clone())
	}
}

/// Status source that always fails closed.
#[derive(Debug, Clone, Copy, Default)]
pub struct UnavailableStatusSource;

impl AttestationStatusSource for UnavailableStatusSource {
	fn status_at(
		&self,
		_now: DateTime<Utc>,
	) -> Result<AttestationStatusList, AttestationStatusUnavailable> {
		Err(AttestationStatusUnavailable(
			"status list unavailable".to_string(),
		))
	}
}

struct CachedStatus {
	list: AttestationStatusList,
	fresh_until: DateTime<Utc>,
}

/// Fetches and caches `https://android.googleapis.com/attestation/status`.
/// Fails closed if unavailable beyond `stale_grace`.
pub struct GoogleAttestationStatusSource {
	url: String,
	stale_grace: Duration,
	timeout: Duration,
	cache: Mutex<Option<CachedStatus>>,
}

impl Default for GoogleAttestationStatusSource {
	fn default() -> Self {
		Self::new()
	}
}

impl GoogleAttestationStatusSource {
	pub fn new() -> Self {
		Self {
			url: "https://android.googleapis.com/attestation/status".to_string(),
			stale_grace: Duration::from_secs(24 * 60 * 60),
			timeout: Duration::from_secs(10),
			cache: Mutex::new(None),
		}
	}

	pub fn with_url(mut self, url: impl Into<String>) -> Self {
		self.url = url.into();
		self
	}

	pub async fn refresh_async(
		&self,
		now: DateTime<Utc>,
	) -> Result<AttestationStatusList, AttestationStatusUnavailable> {
		if let Some(cached) = self.cache.lock().unwrap().as_ref()
			&& now < cached.fresh_until
		{
			return Ok(cached.list.clone());
		}

		let fetch_result = async {
			let client = reqwest::Client::builder()
				.timeout(self.timeout)
				.redirect(reqwest::redirect::Policy::none())
				.build()
				.map_err(|e| AttestationStatusUnavailable(e.to_string()))?;
			let response = client
				.get(&self.url)
				.send()
				.await
				.map_err(|e| AttestationStatusUnavailable(e.to_string()))?;
			if !response.status().is_success() {
				return Err(AttestationStatusUnavailable(format!(
					"Status list answered {}",
					response.status().as_u16()
				)));
			}
			let mut headers = BTreeMap::new();
			for (k, v) in response.headers() {
				if let Ok(val) = v.to_str() {
					headers.insert(k.as_str().to_ascii_lowercase(), val.to_string());
				}
			}
			let bytes = response
				.bytes()
				.await
				.map_err(|e| AttestationStatusUnavailable(e.to_string()))?;
			if bytes.len() > MAX_STATUS_BODY_BYTES {
				return Err(AttestationStatusUnavailable(
					"Status list exceeds size limit.".to_string(),
				));
			}
			let body = std::str::from_utf8(&bytes).map_err(|_| {
				AttestationStatusUnavailable("Status list is not UTF-8.".to_string())
			})?;
			let list = AttestationStatusList::parse(body).map_err(AttestationStatusUnavailable)?;
			let lifetime = freshness_lifetime(&headers);
			Ok((list, lifetime))
		}
		.await;

		let mut guard = self.cache.lock().unwrap();
		match fetch_result {
			Ok((list, lifetime)) => {
				let fresh_until = now
					+ chrono::Duration::from_std(lifetime)
						.unwrap_or_else(|_| chrono::Duration::hours(1));
				*guard = Some(CachedStatus {
					list: list.clone(),
					fresh_until,
				});
				Ok(list)
			}
			Err(err) => {
				if let Some(cached) = guard.as_ref() {
					let grace = chrono::Duration::from_std(self.stale_grace)
						.unwrap_or_else(|_| chrono::Duration::hours(24));
					if now < cached.fresh_until + grace {
						return Ok(cached.list.clone());
					}
				}
				Err(err)
			}
		}
	}

	/// Seed the cache directly (for startup prefetch or tests).
	pub fn seed(&self, list: AttestationStatusList, fresh_until: DateTime<Utc>) {
		*self.cache.lock().unwrap() = Some(CachedStatus { list, fresh_until });
	}
}

impl AttestationStatusSource for GoogleAttestationStatusSource {
	fn status_at(
		&self,
		now: DateTime<Utc>,
	) -> Result<AttestationStatusList, AttestationStatusUnavailable> {
		let guard = self.cache.lock().unwrap();
		if let Some(cached) = guard.as_ref() {
			let grace = chrono::Duration::from_std(self.stale_grace)
				.unwrap_or_else(|_| chrono::Duration::hours(24));
			if now < cached.fresh_until + grace {
				return Ok(cached.list.clone());
			}
		}
		Err(AttestationStatusUnavailable(
			"Status list cache is empty or expired; call refresh_async first.".to_string(),
		))
	}
}

pub fn freshness_lifetime(headers: &BTreeMap<String, String>) -> Duration {
	let cc = headers
		.get("cache-control")
		.map(String::as_str)
		.unwrap_or("");
	let directives: Vec<String> = cc
		.split(',')
		.map(|p| p.trim().to_ascii_lowercase())
		.collect();
	if directives
		.iter()
		.any(|d| d == "no-store" || d == "no-cache")
	{
		return Duration::ZERO;
	}
	let max_age = directives.iter().find_map(|d| {
		d.strip_prefix("max-age=")
			.and_then(|v| v.parse::<u64>().ok())
	});
	let lifetime_secs = match max_age {
		Some(v) => v.min(MAX_FRESHNESS_SECONDS),
		None => 3600,
	};
	let age_secs = headers
		.get("age")
		.and_then(|v| v.trim().parse::<u64>().ok())
		.unwrap_or(0);
	Duration::from_secs(lifetime_secs.saturating_sub(age_secs))
}

#[derive(Debug, Clone)]
pub struct KeyAttestationPolicy {
	pub package_name: String,
	pub signing_certificate_digests: HashSet<String>,
	pub max_patch_age_months: i32,
}

impl KeyAttestationPolicy {
	pub fn new(signing_certificate_digests: HashSet<String>) -> Self {
		Self {
			package_name: VERILY_ANDROID_PACKAGE_NAME.to_string(),
			signing_certificate_digests,
			max_patch_age_months: 12,
		}
	}

	pub fn from_env(env: &HashMap<String, String>) -> Result<Self, String> {
		let raw = env
			.get("VERILY_ANDROID_SIGNING_CERT_SHA256")
			.map(String::as_str)
			.unwrap_or("");
		let digests = parse_signing_certificate_digests(raw)?;
		Ok(Self::new(digests))
	}
}

pub fn parse_signing_certificate_digests(raw: &str) -> Result<HashSet<String>, String> {
	let mut digests = HashSet::new();
	for entry in raw.split(',') {
		let normalized = entry.trim().replace(':', "").to_ascii_lowercase();
		if normalized.is_empty() {
			continue;
		}
		if normalized.len() != 64
			|| !normalized
				.bytes()
				.all(|b| matches!(b, b'0'..=b'9' | b'a'..=b'f'))
		{
			return Err(
				"VERILY_ANDROID_SIGNING_CERT_SHA256 must list SHA-256 digests of the release signing certificate as hex, separated by commas."
					.to_string(),
			);
		}
		digests.insert(normalized);
	}
	Ok(digests)
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyAttestationVerdict {
	pub trusted: bool,
	pub reason_code: &'static str,
	pub public_key: Option<Vec<u8>>,
	pub security_level: Option<KeySecurityLevel>,
	pub device_key_id: Option<String>,
}

impl KeyAttestationVerdict {
	pub fn trusted(
		public_key: Vec<u8>,
		security_level: KeySecurityLevel,
		device_key_id: Option<String>,
	) -> Self {
		Self {
			trusted: true,
			reason_code: reason::VALID,
			public_key: Some(public_key),
			security_level: Some(security_level),
			device_key_id,
		}
	}

	pub fn untrusted(reason_code: &'static str, public_key: Option<Vec<u8>>) -> Self {
		Self {
			trusted: false,
			reason_code,
			public_key,
			security_level: None,
			device_key_id: None,
		}
	}
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Provisioning {
	Factory,
	Remote,
	Unknown,
}

#[derive(Clone)]
pub struct AndroidKeyAttestationVerifier {
	pub policy: KeyAttestationPolicy,
	pub trust_anchors: Vec<X509Certificate>,
	pub status_source: Arc<dyn AttestationStatusSource>,
}

impl AndroidKeyAttestationVerifier {
	pub fn new(
		policy: KeyAttestationPolicy,
		status_source: Arc<dyn AttestationStatusSource>,
	) -> Self {
		Self {
			policy,
			trust_anchors: google_attestation_roots(),
			status_source,
		}
	}

	pub fn with_trust_anchors(mut self, anchors: Vec<X509Certificate>) -> Self {
		self.trust_anchors = anchors;
		self
	}

	pub fn verify(
		&self,
		chain: &[&[u8]],
		challenge: &[u8],
		now: DateTime<Utc>,
	) -> KeyAttestationVerdict {
		if chain.len() < 3 || chain.len() > MAX_CHAIN_LENGTH {
			return KeyAttestationVerdict::untrusted(reason::CHAIN_INVALID, None);
		}
		let mut certs = Vec::with_capacity(chain.len());
		for &der in chain {
			if der.len() > MAX_CERTIFICATE_BYTES {
				return KeyAttestationVerdict::untrusted(reason::CHAIN_INVALID, None);
			}
			match X509Certificate::parse(der) {
				Ok(cert) => certs.push(cert),
				Err(_) => return KeyAttestationVerdict::untrusted(reason::CHAIN_INVALID, None),
			}
		}

		let public_key = certs[0].public_key.p256_point().map(ToOwned::to_owned);

		if let Some(failure) = self.validate_path(&certs, now) {
			return KeyAttestationVerdict::untrusted(failure, public_key);
		}

		let path = &certs[..certs.len() - 1];
		let Some(ext_bytes) = path[0].extensions.get(KEY_ATTESTATION_EXTENSION_OID) else {
			return KeyAttestationVerdict::untrusted(reason::EXTENSION_INVALID, public_key);
		};
		let Ok(description) = KeyDescription::parse(ext_bytes) else {
			return KeyAttestationVerdict::untrusted(reason::EXTENSION_INVALID, public_key);
		};
		let Ok(application) = description.attestation_application_id() else {
			return KeyAttestationVerdict::untrusted(reason::EXTENSION_INVALID, public_key);
		};

		if !constant_time_eq(&description.attestation_challenge, challenge) {
			return KeyAttestationVerdict::untrusted(reason::CHALLENGE_MISMATCH, public_key);
		}

		let security_level = description.key_mint_security_level;
		if description.attestation_security_level != security_level
			|| security_level == KeySecurityLevel::Software
			|| !chain_supports_security_level(path, security_level)
		{
			return KeyAttestationVerdict::untrusted(reason::SECURITY_LEVEL, public_key);
		}

		let hardware = &description.hardware_enforced;
		let Some(root_of_trust) = &hardware.root_of_trust else {
			return KeyAttestationVerdict::untrusted(reason::BOOT_UNTRUSTED, public_key);
		};
		if root_of_trust.verified_boot_state != VerifiedBootState::Verified
			|| !root_of_trust.device_locked
		{
			return KeyAttestationVerdict::untrusted(reason::BOOT_UNTRUSTED, public_key);
		}

		let p256 = hardware.ec_curve == Some(keymint_tag::EC_CURVE_P256)
			|| (hardware.ec_curve.is_none() && hardware.key_size == Some(256));
		let can_sign = hardware
			.purposes
			.as_ref()
			.is_some_and(|p| p.contains(&keymint_tag::PURPOSE_SIGN));
		let Some(leaf_pub) = public_key.clone() else {
			return KeyAttestationVerdict::untrusted(reason::KEY_INVALID, None);
		};
		if hardware.origin != Some(keymint_tag::ORIGIN_GENERATED)
			|| hardware.algorithm != Some(keymint_tag::ALGORITHM_EC)
			|| !p256
			|| !can_sign
		{
			return KeyAttestationVerdict::untrusted(reason::KEY_INVALID, Some(leaf_pub));
		}

		if self.policy.signing_certificate_digests.is_empty() {
			return KeyAttestationVerdict::untrusted(reason::UNCONFIGURED, Some(leaf_pub));
		}
		let app_matches = application.is_some_and(|app| {
			app.package_names.contains(&self.policy.package_name)
				&& app
					.signature_digests
					.iter()
					.any(|d| self.policy.signing_certificate_digests.contains(d))
		});
		if !app_matches {
			return KeyAttestationVerdict::untrusted(reason::APP_MISMATCH, Some(leaf_pub));
		}

		if !self.patch_within_policy(hardware.os_patch_level, now) {
			return KeyAttestationVerdict::untrusted(reason::PATCH_OUTDATED, Some(leaf_pub));
		}

		let device_key_id = if provisioning(path) == Provisioning::Remote {
			Some(hex_lower(&Sha256::digest(&path[1].subject_public_key_info)))
		} else {
			None
		};

		KeyAttestationVerdict::trusted(leaf_pub, security_level, device_key_id)
	}

	fn validate_path(&self, certs: &[X509Certificate], now: DateTime<Utc>) -> Option<&'static str> {
		let Some(root) = certs.last() else {
			return Some(reason::CHAIN_INVALID);
		};
		let path = &certs[..certs.len() - 1];
		if !root.is_self_issued() {
			return Some(reason::UNTRUSTED_ROOT);
		}
		let Some(top) = path.last() else {
			return Some(reason::CHAIN_INVALID);
		};
		let Some(_anchor) = self.trust_anchors.iter().find(|anchor| {
			anchor.subject.matches(&top.issuer) && top.is_signed_by(&anchor.public_key)
		}) else {
			return Some(reason::UNTRUSTED_ROOT);
		};

		let is_factory = provisioning(path) == Provisioning::Factory;
		for idx in (0..path.len()).rev() {
			let cert = &path[idx];
			if idx != path.len() - 1 {
				let issuer = &path[idx + 1];
				if !cert.issuer.matches(&issuer.subject) || !cert.is_signed_by(&issuer.public_key) {
					return Some(reason::CHAIN_INVALID);
				}
			}
			if idx > 0 && cert.extensions.contains_key(KEY_ATTESTATION_EXTENSION_OID) {
				return Some(reason::CHAIN_INVALID);
			}
			if idx == 0 {
				continue;
			}
			if now < cert.not_before {
				return Some(reason::EXPIRED);
			}
			if now > cert.not_after && !is_factory {
				return Some(reason::EXPIRED);
			}
		}

		let status = match self.status_source.status_at(now) {
			Ok(status) => status,
			Err(_) => return Some(reason::STATUS_UNAVAILABLE),
		};
		if path.iter().any(|cert| status.lists(&cert.serial_hex())) {
			return Some(reason::REVOKED);
		}
		None
	}

	fn patch_within_policy(&self, patch_level: Option<i64>, now: DateTime<Utc>) -> bool {
		let Some(level) = patch_level else {
			return false;
		};
		let year = level / 100;
		let month = level % 100;
		if year < 2000 || !(1..=12).contains(&month) {
			return false;
		}
		let age = (i64::from(now.year()) * 12 + i64::from(now.month())) - (year * 12 + month);
		age <= i64::from(self.policy.max_patch_age_months)
	}
}

impl AndroidAttestation for AndroidKeyAttestationVerifier {
	fn parse(
		&self,
		chain_der: &[&[u8]],
		expected_challenge: &[u8; 32],
	) -> Result<ParsedAndroidKey, CaptureError> {
		let verdict = self.verify(chain_der, expected_challenge, Utc::now());
		let Some(public_sec1) = verdict.public_key else {
			return Err(CaptureError::Refused);
		};
		Ok(ParsedAndroidKey {
			public_sec1,
			trusted: verdict.trusted,
			storage: verdict
				.security_level
				.and_then(KeySecurityLevel::as_key_storage),
			reason: verdict.reason_code,
		})
	}
}

fn provisioning(path: &[X509Certificate]) -> Provisioning {
	let Some(top) = path.last() else {
		return Provisioning::Unknown;
	};
	let intermediate = &top.subject;
	if intermediate.attribute(oid::SERIAL_NUMBER).is_some() {
		return Provisioning::Factory;
	}
	if intermediate.attribute(oid::COMMON_NAME) == Some("Droid CA2")
		&& intermediate.attribute(oid::ORGANIZATION) == Some("Google LLC")
	{
		return Provisioning::Remote;
	}
	Provisioning::Unknown
}

fn chain_supports_security_level(path: &[X509Certificate], level: KeySecurityLevel) -> bool {
	if path.len() < 2 {
		return false;
	}
	let attestation = &path[1].subject;
	let claim = match provisioning(path) {
		Provisioning::Remote => match attestation.attribute(oid::ORGANIZATION) {
			Some("StrongBox") => Some(KeySecurityLevel::StrongBox),
			Some("TEE") => Some(KeySecurityLevel::TrustedEnvironment),
			_ => Some(KeySecurityLevel::Software),
		},
		Provisioning::Factory => {
			if attestation.mentions("strongbox")
				|| path.last().is_some_and(|c| c.subject.mentions("strongbox"))
			{
				Some(KeySecurityLevel::StrongBox)
			} else {
				None
			}
		}
		Provisioning::Unknown => None,
	};
	match level {
		KeySecurityLevel::StrongBox => claim == Some(KeySecurityLevel::StrongBox),
		KeySecurityLevel::TrustedEnvironment => {
			claim.is_none() || claim == Some(KeySecurityLevel::TrustedEnvironment)
		}
		KeySecurityLevel::Software => false,
	}
}
