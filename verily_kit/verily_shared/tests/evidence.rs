//! Every digest helper, including the refuse paths.

use chrono::TimeZone;
use chrono::Utc;
use verily_shared::CaptureChallenge;
use verily_shared::EvidenceBinding;
use verily_shared::MediaEvidenceKind;
use verily_shared::app_attest_assertion_client_data_hash;
use verily_shared::app_attest_device_client_data;
use verily_shared::app_attest_registration_client_data_hash;
use verily_shared::capture_integrity_request_hash;
use verily_shared::capture_key_attestation_challenge;
use verily_shared::capture_provenance_manifest;
use verily_shared::capture_public_key_id;
use verily_shared::location_evidence_binding_hash;
use verily_shared::media_evidence_binding_hash;
use verily_shared::motion_evidence_binding_hash;
use verily_shared::normalize_capture_challenge;
use verily_shared::normalize_evidence_binding_hash;
use verily_shared::qr_evidence_binding_hash;
use verily_shared::sha256_hex;

const CHALLENGE: &str = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8";
const BINDING: &str = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const DIGEST: &str = "1a656a301805a7df373828a001d069b7da8442a1428e756de4f8226a821f81ae";

fn captured_at() -> chrono::DateTime<Utc> {
	Utc.with_ymd_and_hms(2026, 8, 27, 12, 34, 56).unwrap() + chrono::Duration::milliseconds(789)
}

fn bytes_hex(bytes: &[u8]) -> String {
	bytes.iter().map(|byte| format!("{byte:02x}")).collect()
}

#[test]
fn capture_challenge_and_binding_wrappers_round_trip() {
	let challenge =
		CaptureChallenge::parse(format!("  {CHALLENGE}  ").as_str()).expect("challenge");
	assert_eq!(challenge.as_str(), CHALLENGE);
	assert!(CaptureChallenge::parse("too-short").is_err());
	assert!(CaptureChallenge::parse("AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh=").is_err());

	let binding = EvidenceBinding::parse(format!("  {BINDING}  ").as_str()).expect("binding");
	assert_eq!(binding.as_str(), BINDING);
	assert!(EvidenceBinding::parse("not-a-digest").is_err());
	assert!(normalize_evidence_binding_hash("ZZ").is_err());
}

#[test]
fn integrity_request_key_attestation_and_manifest_match_goldens() {
	assert_eq!(
		capture_integrity_request_hash("attempt", "requirement", CHALLENGE, BINDING).expect("hash"),
		"8lR_I1KQkSn4128SNfCNkdjvbTPLfm35Rh1ZDqGdguE"
	);
	assert_eq!(
		bytes_hex(&capture_key_attestation_challenge(CHALLENGE, "attempt").expect("attest")),
		"35daff575b9ca0b1be213cecb524dbb945126335ce86668d80d0a8c01f565b2c"
	);
	assert_eq!(
		bytes_hex(&app_attest_registration_client_data_hash(CHALLENGE).expect("register")),
		"630dcd2966c4336691125448bbb25b4ff412a49c732db2c8abc1b8581bd710dd"
	);

	let request =
		capture_integrity_request_hash("attempt", "requirement", CHALLENGE, BINDING).expect("hash");
	let manifest =
		capture_provenance_manifest("attempt", "requirement", &request, BINDING).expect("manifest");
	assert!(
		std::str::from_utf8(&manifest)
			.expect("utf8")
			.starts_with("verily-capture-manifest-v1\n")
	);
	assert_eq!(
		bytes_hex(&app_attest_assertion_client_data_hash(&manifest).expect("assert")),
		sha256_hex(&manifest)
	);

	let device = app_attest_device_client_data(&manifest, "device-token");
	assert!(device.starts_with(b"verily-apple-device-v1|"));
	assert!(
		device
			.windows(manifest.len())
			.any(|window| window == manifest)
	);

	assert_eq!(
		capture_public_key_id(&[1, 2, 3]).expect("key"),
		"039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81"
	);
}

#[test]
fn media_and_motion_bindings_accept_each_kind() {
	let at = captured_at();
	let photo =
		media_evidence_binding_hash(MediaEvidenceKind::Photo, at, DIGEST, 12, 0, " image/jpeg ")
			.expect("photo");
	let video =
		media_evidence_binding_hash(MediaEvidenceKind::Video, at, DIGEST, 12, 3, "video/mp4")
			.expect("video");
	let audio =
		media_evidence_binding_hash(MediaEvidenceKind::Audio, at, DIGEST, 12, 3, "audio/mp4")
			.expect("audio");
	assert_ne!(photo, video);
	assert_ne!(video, audio);

	let motion = motion_evidence_binding_hash(at, DIGEST, 1, 1).expect("motion");
	assert_eq!(motion.len(), 64);
}

#[test]
fn refuse_paths_fail_closed() {
	let at = captured_at();
	assert!(location_evidence_binding_hash(at, f64::NAN, 0.0, 1.0).is_err());
	assert!(location_evidence_binding_hash(at, 91.0, 0.0, 1.0).is_err());
	assert!(location_evidence_binding_hash(at, 0.0, 181.0, 1.0).is_err());
	assert!(location_evidence_binding_hash(at, 0.0, f64::INFINITY, 1.0).is_err());
	assert!(location_evidence_binding_hash(at, 0.0, 0.0, -0.1).is_err());
	assert!(qr_evidence_binding_hash(at, "   ").is_err());

	assert!(
		media_evidence_binding_hash(MediaEvidenceKind::Photo, at, "zz", 1, 0, "image/jpeg")
			.is_err()
	);
	assert!(
		media_evidence_binding_hash(MediaEvidenceKind::Photo, at, DIGEST, 0, 0, "image/jpeg")
			.is_err()
	);
	assert!(
		media_evidence_binding_hash(MediaEvidenceKind::Photo, at, DIGEST, 1, 1, "image/jpeg")
			.is_err()
	);
	assert!(
		media_evidence_binding_hash(MediaEvidenceKind::Video, at, DIGEST, 1, 0, "video/mp4")
			.is_err()
	);
	assert!(
		media_evidence_binding_hash(MediaEvidenceKind::Audio, at, DIGEST, 1, 0, "audio/mp4")
			.is_err()
	);
	assert!(media_evidence_binding_hash(MediaEvidenceKind::Video, at, DIGEST, 1, 1, "  ").is_err());

	assert!(motion_evidence_binding_hash(at, DIGEST, 0, 1).is_err());
	assert!(motion_evidence_binding_hash(at, DIGEST, 1001, 1).is_err());
	assert!(motion_evidence_binding_hash(at, DIGEST, 1, 0).is_err());
	assert!(motion_evidence_binding_hash(at, DIGEST, 1, 30_001).is_err());

	assert!(capture_integrity_request_hash("", "requirement", CHALLENGE, BINDING).is_err());
	assert!(capture_integrity_request_hash("attempt", "req=bad", CHALLENGE, BINDING).is_err());
	assert!(
		capture_integrity_request_hash("attempt\nid", "requirement", CHALLENGE, BINDING).is_err()
	);
	assert!(
		capture_integrity_request_hash("attempt\rid", "requirement", CHALLENGE, BINDING).is_err()
	);
	assert!(
		capture_integrity_request_hash("attempt", "requirement", CHALLENGE, "not-hex").is_err()
	);
	assert!(capture_integrity_request_hash("attempt", "requirement", "short", BINDING).is_err());
	assert!(
		capture_key_attestation_challenge("AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHhB", "attempt")
			.is_err()
	);
	assert!(capture_key_attestation_challenge(CHALLENGE, "").is_err());
	assert!(capture_key_attestation_challenge("short", "attempt").is_err());
	assert!(app_attest_registration_client_data_hash("short").is_err());
	assert!(
		app_attest_registration_client_data_hash("AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHhB")
			.is_err()
	);
	assert!(app_attest_assertion_client_data_hash(b"").is_err());
	assert!(capture_public_key_id(b"").is_err());
	assert!(capture_provenance_manifest("attempt", "requirement", "short", BINDING).is_err());
	assert!(capture_provenance_manifest("", "requirement", CHALLENGE, BINDING).is_err());
	assert!(capture_provenance_manifest("attempt", "req=bad", CHALLENGE, BINDING).is_err());
	assert!(capture_provenance_manifest("attempt", "requirement", CHALLENGE, "not-hex").is_err());
	assert!(motion_evidence_binding_hash(at, "not-hex", 1, 1).is_err());
	let bad = normalize_capture_challenge("!!!").expect_err("shape");
	assert_eq!(
		bad.to_string(),
		"captureChallenge: Must be 32 bytes as unpadded base64url."
	);
}
