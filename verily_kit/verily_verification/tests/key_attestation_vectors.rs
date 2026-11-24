//! Integration tests against the byte-identical Android Key Attestation real
//! device vectors from Google's `android/keyattestation`.

use std::collections::HashSet;
use std::path::PathBuf;
use std::sync::Arc;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use chrono::DateTime;
use chrono::Utc;
use serde_json::Value;
use sha2::Digest;
use sha2::Sha256;
use verily_verification::asn1::X509Certificate;
use verily_verification::asn1::decode_pem_blocks;
use verily_verification::asn1::hex_lower;
use verily_verification::key_attestation::AndroidKeyAttestationVerifier;
use verily_verification::key_attestation::AttestationStatusList;
use verily_verification::key_attestation::AttestationStatusSource;
use verily_verification::key_attestation::FixedStatusSource;
use verily_verification::key_attestation::KEY_ATTESTATION_EXTENSION_OID;
use verily_verification::key_attestation::KeyAttestationPolicy;
use verily_verification::key_attestation::KeyDescription;
use verily_verification::key_attestation::KeySecurityLevel;
use verily_verification::key_attestation::UnavailableStatusSource;
use verily_verification::key_attestation::reason;

struct Vector {
	chain: Vec<Vec<u8>>,
	certs: Vec<X509Certificate>,
	description: KeyDescription,
	json: Value,
	created_at: DateTime<Utc>,
	challenge: Vec<u8>,
	package_name: String,
	signing_digests: HashSet<String>,
}

impl Vector {
	fn vectors_dir() -> PathBuf {
		PathBuf::from(env!("CARGO_MANIFEST_DIR"))
			.join("tests")
			.join("key_attestation")
			.join("vectors")
	}

	fn load(name: &str) -> Self {
		let dir = Self::vectors_dir();
		let pem =
			std::fs::read_to_string(dir.join(format!("{name}.pem"))).expect("read vector pem");
		let json_raw =
			std::fs::read_to_string(dir.join(format!("{name}.json"))).expect("read vector json");
		let json: Value = serde_json::from_str(&json_raw).expect("parse vector json");
		let chain = decode_pem_blocks(&pem).expect("decode vector pem chain");
		let certs: Vec<X509Certificate> = chain
			.iter()
			.map(|der| X509Certificate::parse(der).expect("parse vector cert"))
			.collect();
		let ext = certs[0]
			.extensions
			.get(KEY_ATTESTATION_EXTENSION_OID)
			.expect("leaf carries KeyDescription");
		let description = KeyDescription::parse(ext).expect("parse KeyDescription");
		let challenge = STANDARD
			.decode(json["attestationChallenge"].as_str().unwrap())
			.unwrap();
		let app = description
			.attestation_application_id()
			.unwrap()
			.expect("vector has AttestationApplicationId");
		let package_name = app.package_names.iter().next().unwrap().clone();
		let signing_digests = app.signature_digests.clone();

		let created_ms: i64 = json["softwareEnforced"]["creationDateTime"]
			.as_str()
			.expect("creationDateTime")
			.parse()
			.expect("parse creationDateTime ms");
		let created_at =
			DateTime::from_timestamp_millis(created_ms).expect("valid creationDateTime");

		Self {
			chain,
			certs,
			description,
			json,
			created_at,
			challenge,
			package_name,
			signing_digests,
		}
	}

	fn leaf_point(&self) -> Option<Vec<u8>> {
		self.certs[0].public_key.p256_point().map(ToOwned::to_owned)
	}

	#[allow(
		clippy::too_many_arguments,
		reason = "test fixture helper overriding individual policy inputs"
	)]
	fn verify_with(
		&self,
		chain_override: Option<&[Vec<u8>]>,
		challenge_override: Option<&[u8]>,
		package_override: Option<&str>,
		digests_override: Option<HashSet<String>>,
		max_patch_age_months: i32,
		now_override: Option<DateTime<Utc>>,
		status: Arc<dyn AttestationStatusSource>,
	) -> verily_verification::key_attestation::KeyAttestationVerdict {
		let mut policy = KeyAttestationPolicy::new(
			digests_override.unwrap_or_else(|| self.signing_digests.clone()),
		);
		policy.package_name = package_override
			.map(str::to_string)
			.unwrap_or_else(|| self.package_name.clone());
		policy.max_patch_age_months = max_patch_age_months;
		let verifier = AndroidKeyAttestationVerifier::new(policy, status);
		let raw = chain_override.unwrap_or(&self.chain);
		let refs: Vec<&[u8]> = raw.iter().map(Vec::as_slice).collect();
		verifier.verify(
			&refs,
			challenge_override.unwrap_or(&self.challenge),
			now_override.unwrap_or(self.created_at),
		)
	}

	fn verify(&self) -> verily_verification::key_attestation::KeyAttestationVerdict {
		self.verify_with(
			None,
			None,
			None,
			None,
			12,
			None,
			Arc::new(FixedStatusSource(AttestationStatusList::default())),
		)
	}
}

#[test]
fn trusted_real_device_chains_verify_at_exact_security_level() {
	let cases = [
		("caiman-sdk36_SB_EC_RKP", KeySecurityLevel::StrongBox),
		(
			"caiman-sdk36_TEE_EC_RKP",
			KeySecurityLevel::TrustedEnvironment,
		),
		("tegu-sdk36_SB_EC_2026_ROOT", KeySecurityLevel::StrongBox),
		(
			"frankel-sdk37_TEE_EC_2026",
			KeySecurityLevel::TrustedEnvironment,
		),
	];
	for (name, expected_level) in cases {
		let vector = Vector::load(name);
		let verdict = vector.verify();
		assert!(verdict.trusted, "{name}: got {}", verdict.reason_code);
		assert_eq!(verdict.reason_code, reason::VALID, "{name}");
		assert_eq!(verdict.security_level, Some(expected_level), "{name}");
		assert_eq!(verdict.public_key, vector.leaf_point(), "{name}");
		let expected_device_id =
			hex_lower(&Sha256::digest(&vector.certs[1].subject_public_key_info));
		assert_eq!(verdict.device_key_id, Some(expected_device_id), "{name}");
	}
}

#[test]
fn factory_chain_tolerates_expired_intermediate_and_enforces_patch_age() {
	let vector = Vector::load("sony-xperia10-iii-sdk33_TEE_EC");
	assert!(vector.certs[1].not_after < vector.created_at);

	let stale = vector.verify();
	assert!(!stale.trusted);
	assert_eq!(stale.reason_code, reason::PATCH_OUTDATED);
	assert_eq!(stale.public_key, vector.leaf_point());

	let relaxed = vector.verify_with(
		None,
		None,
		None,
		None,
		48,
		None,
		Arc::new(FixedStatusSource(AttestationStatusList::default())),
	);
	assert!(relaxed.trusted, "got {}", relaxed.reason_code);
	assert_eq!(
		relaxed.security_level,
		Some(KeySecurityLevel::TrustedEnvironment)
	);
	assert_eq!(relaxed.device_key_id, None);
}

#[test]
fn unlocked_bootloader_rsa_mldsa_and_software_root_are_refused() {
	let unlocked = Vector::load("akita-sdk34_TEE_EC_NONE").verify();
	assert!(!unlocked.trusted);
	assert_eq!(unlocked.reason_code, reason::BOOT_UNTRUSTED);

	let rsa = Vector::load("akita-sdk34_TEE_RSA_NONE").verify();
	assert!(!rsa.trusted);
	assert_eq!(rsa.public_key, None);

	let mldsa = Vector::load("tokay-sdk37_TEE_MLDSA_RKP").verify();
	assert!(!mldsa.trusted);
	assert_eq!(mldsa.public_key, None);

	let software_root = Vector::load("marlin-sdk29_TEE_EC_NONE").verify();
	assert!(!software_root.trusted);
	assert_eq!(software_root.reason_code, reason::UNTRUSTED_ROOT);
}

#[test]
fn malformed_root_of_trust_vector_is_rejected() {
	let pem = std::fs::read_to_string(
		Vector::vectors_dir().join("invalid_malformed_rot_device_locked.pem"),
	)
	.expect("read malformed vector");
	let chain = decode_pem_blocks(&pem).expect("decode pem");
	let refs: Vec<&[u8]> = chain.iter().map(Vec::as_slice).collect();
	let verifier = AndroidKeyAttestationVerifier::new(
		KeyAttestationPolicy::new(HashSet::from(["aa".repeat(32)])),
		Arc::new(FixedStatusSource(AttestationStatusList::default())),
	);
	let verdict = verifier.verify(&refs, b"challenge", Utc::now());
	assert!(!verdict.trusted);
}

#[test]
fn challenge_app_revocation_status_expiry_and_tamper_checks_fail_closed() {
	let vector = Vector::load("caiman-sdk36_SB_EC_RKP");
	let empty_status = Arc::new(FixedStatusSource(AttestationStatusList::default()));

	assert_eq!(
		vector
			.verify_with(
				None,
				Some(b"wrong challenge"),
				None,
				None,
				12,
				None,
				empty_status.clone(),
			)
			.reason_code,
		reason::CHALLENGE_MISMATCH
	);

	assert_eq!(
		vector
			.verify_with(
				None,
				None,
				Some("fun.verily.fake"),
				None,
				12,
				None,
				empty_status.clone(),
			)
			.reason_code,
		reason::APP_MISMATCH
	);

	assert_eq!(
		vector
			.verify_with(
				None,
				None,
				None,
				Some(HashSet::new()),
				12,
				None,
				empty_status.clone(),
			)
			.reason_code,
		reason::UNCONFIGURED
	);

	let revoked = vector.verify_with(
		None,
		None,
		None,
		None,
		12,
		None,
		Arc::new(FixedStatusSource(AttestationStatusList::new([vector
			.certs[1]
			.serial_hex()]))),
	);
	assert_eq!(revoked.reason_code, reason::REVOKED);

	let unavailable = vector.verify_with(
		None,
		None,
		None,
		None,
		12,
		None,
		Arc::new(UnavailableStatusSource),
	);
	assert_eq!(unavailable.reason_code, reason::STATUS_UNAVAILABLE);

	let expired = vector.verify_with(
		None,
		None,
		None,
		None,
		12,
		Some(vector.certs[1].not_after + chrono::Duration::days(1)),
		empty_status.clone(),
	);
	assert_eq!(expired.reason_code, reason::EXPIRED);

	let mut tampered = vector.chain.clone();
	let len = tampered[1].len();
	tampered[1][len - 4] ^= 0x01;
	assert_eq!(
		vector
			.verify_with(
				Some(&tampered),
				None,
				None,
				None,
				12,
				None,
				empty_status.clone(),
			)
			.reason_code,
		reason::CHAIN_INVALID
	);

	let mut top_tampered = vector.chain.clone();
	let top_idx = top_tampered.len() - 2;
	let top_len = top_tampered[top_idx].len();
	top_tampered[top_idx][top_len - 4] ^= 0x01;
	assert_eq!(
		vector
			.verify_with(
				Some(&top_tampered),
				None,
				None,
				None,
				12,
				None,
				empty_status,
			)
			.reason_code,
		reason::UNTRUSTED_ROOT
	);
}

#[test]
fn parsed_key_descriptions_match_recorded_json_for_all_nine_vectors() {
	let names = [
		"caiman-sdk36_SB_EC_RKP",
		"caiman-sdk36_TEE_EC_RKP",
		"tegu-sdk36_SB_EC_2026_ROOT",
		"frankel-sdk37_TEE_EC_2026",
		"sony-xperia10-iii-sdk33_TEE_EC",
		"akita-sdk34_TEE_EC_NONE",
		"akita-sdk34_TEE_RSA_NONE",
		"tokay-sdk37_TEE_MLDSA_RKP",
		"marlin-sdk29_TEE_EC_NONE",
	];
	for name in names {
		let vector = Vector::load(name);
		let expected_challenge = STANDARD
			.decode(vector.json["attestationChallenge"].as_str().unwrap())
			.unwrap();
		assert_eq!(
			vector.description.attestation_challenge, expected_challenge,
			"{name}"
		);
		let hw = &vector.json["hardwareEnforced"];
		let expected_alg: i64 = hw["algorithms"].as_str().unwrap().parse().unwrap();
		assert_eq!(
			vector.description.hardware_enforced.algorithm,
			Some(expected_alg),
			"{name}"
		);
	}
}
