//! Integration tests against the byte-identical Apple App Attest vectors
//! (Apple's 2024 sample, Apple's current sample, and recorded iPhone iOS 27).

use std::collections::HashSet;
use std::path::PathBuf;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use chrono::DateTime;
use chrono::TimeZone;
use chrono::Utc;
use serde_json::Value;
use sha2::Digest;
use sha2::Sha256;
use verily_verification::app_attest::AppAttestEnvironment;
use verily_verification::app_attest::AppAttestPolicy;
use verily_verification::app_attest::AppAttestVerifier;
use verily_verification::app_attest::reason;
use verily_verification::app_attest::validation_category;

fn load_vector(name: &str) -> Value {
	let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
		.join("tests")
		.join("app_attest")
		.join("vectors")
		.join(format!("{name}.json"));
	let raw = std::fs::read_to_string(path).expect("read app attest vector");
	serde_json::from_str(&raw).expect("parse app attest vector")
}

fn b64(json: &Value, key: &str) -> Vec<u8> {
	STANDARD
		.decode(json[key].as_str().expect("string field"))
		.expect("base64 field")
}

fn check_time(json: &Value) -> DateTime<Utc> {
	let raw = json
		.get("checkTime")
		.or_else(|| json.get("captured"))
		.and_then(Value::as_str)
		.expect("vector timestamp");
	DateTime::parse_from_rfc3339(raw)
		.expect("parse rfc3339")
		.with_timezone(&Utc)
}

#[test]
fn apple_documented_sample_attestation_verifies_and_enforces_policy() {
	let vector = load_vector("apple-sample-attestation");
	let team = vector["appIdPrefix"].as_str().unwrap();
	let bundle = vector["bundleId"].as_str().unwrap();
	let policy = AppAttestPolicy::new(team, bundle).with_validation_categories(HashSet::from([1]));
	let verifier = AppAttestVerifier::new(policy.clone());

	let attestation = b64(&vector, "attestation");
	let key_id = b64(&vector, "keyId");
	let client_data_hash = vector["clientDataHash"].as_str().unwrap().as_bytes();
	let now = check_time(&vector);

	let verdict = verifier.verify_attestation(&attestation, &key_id, client_data_hash, now);
	assert!(verdict.is_trusted(), "got {}", verdict.reason_code);
	assert_eq!(verdict.reason_code, reason::VALID);
	let key = verdict.key.unwrap();
	assert_eq!(
		Sha256::digest(&key.public_key).as_slice(),
		key_id.as_slice()
	);
	assert_eq!(key.validation_category, Some(1));
	assert_eq!(key.bundle_version.as_deref(), Some("1"));
	assert_eq!(key.certificate_chain.len(), 2);
	assert_eq!(
		STANDARD.encode(&key.certificate_chain[0]),
		vector["expected"]["leafCertificate"].as_str().unwrap()
	);
	assert!(!key.receipt.is_empty());

	// Production policy refuses OS-executable category 1.
	let prod = AppAttestVerifier::new(AppAttestPolicy::new(team, bundle));
	assert_eq!(
		prod.verify_attestation(&attestation, &key_id, client_data_hash, now)
			.reason_code,
		reason::CATEGORY_REFUSED
	);

	// Wrong clientDataHash -> nonce mismatch.
	let hashed = Sha256::digest(client_data_hash);
	assert_eq!(
		verifier
			.verify_attestation(&attestation, &key_id, &hashed, now)
			.reason_code,
		reason::NONCE_MISMATCH
	);

	// Wrong key id -> key invalid.
	assert_eq!(
		verifier
			.verify_attestation(&attestation, &[7u8; 32], client_data_hash, now)
			.reason_code,
		reason::KEY_INVALID
	);

	// Wrong team -> app mismatch.
	let other_team = AppAttestVerifier::new(
		AppAttestPolicy::new("ABCDEFGHIJ", bundle).with_validation_categories(HashSet::from([1])),
	);
	assert_eq!(
		other_team
			.verify_attestation(&attestation, &key_id, client_data_hash, now)
			.reason_code,
		reason::APP_MISMATCH
	);

	// Sandbox environment mismatch.
	let sandbox = AppAttestVerifier::new(
		AppAttestPolicy::with_environment(team, bundle, AppAttestEnvironment::Development)
			.with_validation_categories(HashSet::from([1])),
	);
	assert_eq!(
		sandbox
			.verify_attestation(&attestation, &key_id, client_data_hash, now)
			.reason_code,
		reason::ENVIRONMENT_MISMATCH
	);

	// Expired three-day credential cert.
	let expired_at = Utc.with_ymd_and_hms(2026, 4, 24, 0, 0, 0).unwrap();
	assert_eq!(
		verifier
			.verify_attestation(&attestation, &key_id, client_data_hash, expired_at)
			.reason_code,
		reason::EXPIRED
	);

	// Truncated CBOR object -> malformed.
	assert_eq!(
		verifier
			.verify_attestation(
				&attestation[..attestation.len() - 1],
				&key_id,
				client_data_hash,
				now,
			)
			.reason_code,
		reason::MALFORMED
	);
}

#[test]
fn apple_2024_ios18_sample_without_category_is_trusted_under_production_policy() {
	let vector = load_vector("apple-sample-attestation-2024");
	let verifier = AppAttestVerifier::new(AppAttestPolicy::new(
		vector["appIdPrefix"].as_str().unwrap(),
		vector["bundleId"].as_str().unwrap(),
	));
	let verdict = verifier.verify_attestation(
		&b64(&vector, "attestation"),
		&b64(&vector, "keyId"),
		vector["clientDataHash"].as_str().unwrap().as_bytes(),
		check_time(&vector),
	);
	assert_eq!(verdict.reason_code, reason::VALID);
	let key = verdict.key.unwrap();
	assert_eq!(key.validation_category, None);
	assert_eq!(key.bundle_version, None);
}

#[test]
fn recorded_iphone_attestation_and_sequential_assertions_verify_and_stop_replays() {
	let vector = load_vector("termakan-ios27-attestation");
	let app_id = vector["appId"].as_str().unwrap();
	let (team, bundle) = app_id.split_once('.').unwrap();
	let policy = AppAttestPolicy::new(team, bundle)
		.with_validation_categories(HashSet::from([validation_category::DEVELOPMENT]));
	let verifier = AppAttestVerifier::new(policy);

	let challenge = vector["challenge"].as_str().unwrap().as_bytes();
	let client_data_hash = b64(&vector, "clientDataHashBase64");
	assert_eq!(
		client_data_hash.as_slice(),
		Sha256::digest(challenge).as_slice()
	);

	let attested = verifier.verify_attestation(
		&b64(&vector, "attestation"),
		&b64(&vector, "keyId"),
		&client_data_hash,
		check_time(&vector),
	);
	assert_eq!(attested.reason_code, reason::VALID);
	let key = attested.key.unwrap();
	assert_eq!(key.validation_category, Some(3));
	assert_eq!(key.bundle_version.as_deref(), Some("1"));

	let assertions = vector["assertions"].as_array().unwrap();
	let a0 = STANDARD
		.decode(assertions[0]["assertion"].as_str().unwrap())
		.unwrap();
	let c0 = assertions[0]["clientData"].as_str().unwrap().as_bytes();
	let a1 = STANDARD
		.decode(assertions[1]["assertion"].as_str().unwrap())
		.unwrap();
	let c1 = assertions[1]["clientData"].as_str().unwrap().as_bytes();

	let v0 = verifier.verify_assertion(&a0, c0, &key.public_key, 0);
	assert_eq!(v0.reason_code, reason::VALID);
	assert_eq!(v0.counter, Some(1));

	let v1 = verifier.verify_assertion(&a1, c1, &key.public_key, 1);
	assert_eq!(v1.reason_code, reason::VALID);
	assert_eq!(v1.counter, Some(2));

	// Replayed counters refused.
	assert_eq!(
		verifier
			.verify_assertion(&a0, c0, &key.public_key, 1)
			.reason_code,
		reason::REPLAYED
	);
	assert_eq!(
		verifier
			.verify_assertion(&a1, c1, &key.public_key, 2)
			.reason_code,
		reason::REPLAYED
	);

	// Wrong clientData refused.
	assert_eq!(
		verifier
			.verify_assertion(&a0, c1, &key.public_key, 0)
			.reason_code,
		reason::SIGNATURE_INVALID
	);

	// Production policy refuses development binary for both attestation & assertion.
	let prod = AppAttestVerifier::new(AppAttestPolicy::new(team, bundle));
	assert_eq!(
		prod.verify_attestation(
			&b64(&vector, "attestation"),
			&b64(&vector, "keyId"),
			&client_data_hash,
			check_time(&vector),
		)
		.reason_code,
		reason::CATEGORY_REFUSED
	);
	assert_eq!(
		prod.verify_assertion(&a0, c0, &key.public_key, 0)
			.reason_code,
		reason::CATEGORY_REFUSED
	);
}
