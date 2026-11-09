//! The evidence bytes both sides already hash. Vectors are independent of the
//! implementation: same domain strings, same field order, SHA-256.

use chrono::TimeZone;
use chrono::Utc;
use verily_shared::CAPTURE_MANIFEST_DOMAIN;
use verily_shared::CAPTURE_REQUEST_DOMAIN;
use verily_shared::EVIDENCE_BINDING_DOMAIN;
use verily_shared::location_evidence_binding_hash;
use verily_shared::qr_evidence_binding_hash;
use verily_shared::sha256_hex;

fn captured_at() -> chrono::DateTime<Utc> {
	Utc.with_ymd_and_hms(2026, 8, 27, 12, 34, 56).unwrap() + chrono::Duration::milliseconds(789)
}

#[test]
fn domain_separators_stay_on_the_existing_protocol() {
	assert_eq!(CAPTURE_REQUEST_DOMAIN, "verily-capture-request-v2");
	assert_eq!(CAPTURE_MANIFEST_DOMAIN, "verily-capture-manifest-v1");
	assert_eq!(EVIDENCE_BINDING_DOMAIN, "verily-evidence-binding-v1");
}

#[test]
fn location_and_qr_bindings_match_the_shared_bytes() {
	let at = captured_at();
	assert_eq!(
		location_evidence_binding_hash(at, 51.5074, -0.1278, 8.25).expect("location"),
		"377e7ef23fbd05fc0625b2a0594d689c4dcbbd9dbbac1c918be49d793b69f716"
	);
	let qr = qr_evidence_binding_hash(at, "  venue-secret-2026  ").expect("qr");
	assert_eq!(
		qr,
		qr_evidence_binding_hash(at, "venue-secret-2026").expect("trimmed")
	);
	assert_eq!(
		qr,
		"b5b901390d98a6c0872bd3f4227151608efaa016591a88032605217cf7b7fb47"
	);
	assert!(!qr.contains("venue-secret"));
}

#[test]
fn a_chunked_recording_hashes_as_one_buffer() {
	assert_eq!(
		sha256_hex(b"recording-bytes"),
		"1a656a301805a7df373828a001d069b7da8442a1428e756de4f8226a821f81ae"
	);
}
