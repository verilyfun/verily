//! Google Play Integrity verification and unified capture integrity evaluation.
//!
//! Signs RS256 OAuth2 JWT assertions with the configured Google service account
//! JSON, exchanges for an access token, calls Google's `decodeIntegrityToken`
//! endpoint, and evaluates the decrypted payload against Verily's policy.

use std::collections::HashSet;
use std::time::Duration;

use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use chrono::DateTime;
use chrono::Utc;
use rsa::RsaPrivateKey;
use rsa::pkcs1v15::SigningKey;
use rsa::pkcs8::DecodePrivateKey;
use rsa::signature::SignatureEncoding;
use rsa::signature::Signer;
use serde::Deserialize;
use serde_json::Value;
use sha2::Sha256;

use crate::asn1::hex_lower;
use crate::key_attestation::VERILY_ANDROID_PACKAGE_NAME;

const PLAY_INTEGRITY_SCOPE: &str = "https://www.googleapis.com/auth/playintegrity";
const GOOGLE_TOKEN_URI: &str = "https://oauth2.googleapis.com/token";
const MAX_VERDICT_AGE_SECONDS: i64 = 120;

pub const DEVICE_CAPTURE_RISK_REVIEW_CODE: &str = "device_capture_risk";
pub const DEVICE_ACTIVITY_RISK_REVIEW_CODE: &str = "device_activity_risk";
pub const APPLE_DEVICE_RISK_UNAVAILABLE_REVIEW_CODE: &str = "apple_device_risk_unavailable";
pub const APPLE_DEVICE_REVIEW_CODE: &str = "apple_device_review";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DeviceIntegrityVerdict {
	pub trusted: bool,
	pub reason_code: &'static str,
	pub provider: &'static str,
	pub review_reason_code: Option<&'static str>,
}

impl DeviceIntegrityVerdict {
	pub const fn unavailable() -> Self {
		Self {
			trusted: false,
			reason_code: "device_integrity_unavailable",
			provider: "google-play-integrity",
			review_reason_code: None,
		}
	}

	pub const fn invalid() -> Self {
		Self {
			trusted: false,
			reason_code: "device_integrity_invalid",
			provider: "google-play-integrity",
			review_reason_code: None,
		}
	}
}

/// Evaluates an already decrypted Google Play Integrity `tokenPayloadExternal`.
pub fn evaluate_google_play_integrity_payload(
	payload: &Value,
	request_hash: &str,
	now: DateTime<Utc>,
	require_strong_integrity: bool,
	signing_certificate_digests: &HashSet<String>,
) -> DeviceIntegrityVerdict {
	let Some(request) = payload.get("requestDetails").and_then(Value::as_object) else {
		return DeviceIntegrityVerdict::invalid();
	};
	let package_name = request.get("requestPackageName").and_then(Value::as_str);
	let returned_hash = request.get("requestHash").and_then(Value::as_str);
	let timestamp_millis = request
		.get("timestampMillis")
		.and_then(Value::as_str)
		.and_then(|s| s.parse::<i64>().ok());
	let Some(ts) = timestamp_millis else {
		return DeviceIntegrityVerdict::invalid();
	};
	if package_name != Some(VERILY_ANDROID_PACKAGE_NAME) || returned_hash != Some(request_hash) {
		return DeviceIntegrityVerdict::invalid();
	}
	let Some(requested_at) = DateTime::from_timestamp_millis(ts) else {
		return DeviceIntegrityVerdict::invalid();
	};
	let age = now.signed_duration_since(requested_at);
	if age.num_milliseconds() < 0 || age.num_seconds() > MAX_VERDICT_AGE_SECONDS {
		return DeviceIntegrityVerdict::invalid();
	}

	let app_integrity = payload.get("appIntegrity").and_then(Value::as_object);
	let app_recognized = app_integrity
		.and_then(|a| a.get("appRecognitionVerdict"))
		.and_then(Value::as_str)
		== Some("PLAY_RECOGNIZED");
	let cert_ok = signing_certificate_digests.is_empty()
		|| signed_with_release_certificate(
			app_integrity.and_then(|a| a.get("certificateSha256Digest")),
			signing_certificate_digests,
		);
	if !app_recognized || !cert_ok {
		return DeviceIntegrityVerdict {
			trusted: false,
			reason_code: "app_integrity_not_recognised",
			provider: "google-play-integrity",
			review_reason_code: None,
		};
	}

	let device_integrity = payload.get("deviceIntegrity").and_then(Value::as_object);
	let labels: HashSet<&str> = device_integrity
		.and_then(|d| d.get("deviceRecognitionVerdict"))
		.and_then(Value::as_array)
		.map(|arr| arr.iter().filter_map(Value::as_str).collect())
		.unwrap_or_default();
	if !labels.contains("MEETS_DEVICE_INTEGRITY") {
		return DeviceIntegrityVerdict {
			trusted: false,
			reason_code: "device_integrity_not_met",
			provider: "google-play-integrity",
			review_reason_code: None,
		};
	}
	let strong = labels.contains("MEETS_STRONG_INTEGRITY");
	if require_strong_integrity && !strong {
		return DeviceIntegrityVerdict {
			trusted: false,
			reason_code: "device_integrity_not_strong",
			provider: "google-play-integrity",
			review_reason_code: None,
		};
	}

	let risky_app = payload
		.get("environmentDetails")
		.and_then(|e| e.get("appAccessRiskVerdict"))
		.and_then(|a| a.get("appsDetected"))
		.and_then(Value::as_array)
		.is_some_and(|arr| {
			arr.iter().filter_map(Value::as_str).any(|label| {
				matches!(
					label,
					"UNKNOWN_CAPTURING" | "UNKNOWN_CONTROLLING" | "UNKNOWN_OVERLAYS"
				)
			})
		});
	let farming = device_integrity
		.and_then(|d| d.get("recentDeviceActivity"))
		.and_then(|a| a.get("deviceActivityLevel"))
		.and_then(Value::as_str)
		.is_some_and(|level| matches!(level, "LEVEL_3" | "LEVEL_4"));

	let review_reason_code = if risky_app {
		Some(DEVICE_CAPTURE_RISK_REVIEW_CODE)
	} else if farming {
		Some(DEVICE_ACTIVITY_RISK_REVIEW_CODE)
	} else {
		None
	};

	DeviceIntegrityVerdict {
		trusted: true,
		reason_code: if strong {
			"device_integrity_strong"
		} else {
			"device_integrity_met"
		},
		provider: "google-play-integrity",
		review_reason_code,
	}
}

fn signed_with_release_certificate(
	reported: Option<&Value>,
	signing_certificate_digests: &HashSet<String>,
) -> bool {
	let Some(arr) = reported.and_then(Value::as_array) else {
		return false;
	};
	for entry in arr.iter().filter_map(Value::as_str) {
		let trimmed = entry.trim().trim_end_matches('=');
		let Ok(bytes) = URL_SAFE_NO_PAD.decode(trimmed.as_bytes()) else {
			return false;
		};
		if signing_certificate_digests.contains(&hex_lower(&bytes)) {
			return true;
		}
	}
	false
}

#[derive(Debug, Deserialize)]
pub struct GoogleServiceAccount {
	pub client_email: String,
	pub private_key: String,
	#[serde(default)]
	pub token_uri: Option<String>,
}

/// Signs a Google OAuth2 RS256 service-account JWT assertion.
pub fn google_service_account_jwt(
	account: &GoogleServiceAccount,
	scope: &str,
	now: DateTime<Utc>,
) -> Result<String, String> {
	let private_key = RsaPrivateKey::from_pkcs8_pem(&account.private_key)
		.map_err(|e| format!("Invalid Google service account private key: {e}"))?;
	let signing_key = SigningKey::<Sha256>::new(private_key);
	let aud = account
		.token_uri
		.as_deref()
		.filter(|s| !s.trim().is_empty())
		.unwrap_or(GOOGLE_TOKEN_URI);
	let iat = now.timestamp();
	let exp = iat + 3600;
	let header = serde_json::json!({ "alg": "RS256", "typ": "JWT" });
	let claims = serde_json::json!({
		"iss": account.client_email,
		"scope": scope,
		"aud": aud,
		"iat": iat,
		"exp": exp,
	});
	let input = format!(
		"{}.{}",
		URL_SAFE_NO_PAD.encode(header.to_string().as_bytes()),
		URL_SAFE_NO_PAD.encode(claims.to_string().as_bytes())
	);
	let sig = signing_key.sign(input.as_bytes());
	Ok(format!(
		"{input}.{}",
		URL_SAFE_NO_PAD.encode(sig.to_bytes())
	))
}

/// Live Google Play Integrity client calling `decodeIntegrityToken`.
#[derive(Clone)]
pub struct GooglePlayIntegrityVerifier {
	service_account_json: Option<String>,
	signing_certificate_digests: HashSet<String>,
	client: reqwest::Client,
}

impl GooglePlayIntegrityVerifier {
	pub fn new(
		service_account_json: Option<String>,
		signing_certificate_digests: HashSet<String>,
	) -> Self {
		let client = reqwest::Client::builder()
			.timeout(Duration::from_secs(10))
			.redirect(reqwest::redirect::Policy::none())
			.build()
			.expect("reqwest client builds");
		Self {
			service_account_json,
			signing_certificate_digests,
			client,
		}
	}

	pub fn is_configured(&self) -> bool {
		self.service_account_json
			.as_deref()
			.is_some_and(|s| !s.trim().is_empty())
	}

	pub async fn verify(
		&self,
		token: &str,
		request_hash: &str,
		now: DateTime<Utc>,
		require_strong_integrity: bool,
	) -> DeviceIntegrityVerdict {
		let Some(raw) = self
			.service_account_json
			.as_deref()
			.map(str::trim)
			.filter(|s| !s.is_empty())
		else {
			return DeviceIntegrityVerdict::unavailable();
		};
		let Ok(account) = serde_json::from_str::<GoogleServiceAccount>(raw) else {
			return DeviceIntegrityVerdict::unavailable();
		};
		let Ok(assertion) = google_service_account_jwt(&account, PLAY_INTEGRITY_SCOPE, now) else {
			return DeviceIntegrityVerdict::unavailable();
		};
		let token_uri = account
			.token_uri
			.as_deref()
			.filter(|s| !s.trim().is_empty())
			.unwrap_or(GOOGLE_TOKEN_URI);
		let token_res = self
			.client
			.post(token_uri)
			.form(&[
				("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
				("assertion", assertion.as_str()),
			])
			.send()
			.await;
		let Ok(token_res) = token_res else {
			return DeviceIntegrityVerdict::unavailable();
		};
		if !token_res.status().is_success() {
			return DeviceIntegrityVerdict::unavailable();
		}
		let Ok(token_json) = token_res.json::<Value>().await else {
			return DeviceIntegrityVerdict::unavailable();
		};
		let Some(access_token) = token_json.get("access_token").and_then(Value::as_str) else {
			return DeviceIntegrityVerdict::unavailable();
		};

		let url = format!(
			"https://playintegrity.googleapis.com/v1/{VERILY_ANDROID_PACKAGE_NAME}:decodeIntegrityToken"
		);
		let Ok(res) = self
			.client
			.post(url)
			.bearer_auth(access_token)
			.json(&serde_json::json!({ "integrity_token": token }))
			.send()
			.await
		else {
			return DeviceIntegrityVerdict::unavailable();
		};
		if !res.status().is_success() {
			return DeviceIntegrityVerdict::unavailable();
		}
		let Ok(body) = res.json::<Value>().await else {
			return DeviceIntegrityVerdict::invalid();
		};
		let Some(payload) = body.get("tokenPayloadExternal") else {
			return DeviceIntegrityVerdict::invalid();
		};
		evaluate_google_play_integrity_payload(
			payload,
			request_hash,
			now,
			require_strong_integrity,
			&self.signing_certificate_digests,
		)
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn evaluates_strong_play_integrity_and_flags_capture_risk() {
		let now = Utc::now();
		let digest_bytes = [0xab_u8; 32];
		let digest_hex = hex_lower(&digest_bytes);
		let digest_b64 = URL_SAFE_NO_PAD.encode(digest_bytes);
		let payload = serde_json::json!({
			"requestDetails": {
				"requestPackageName": VERILY_ANDROID_PACKAGE_NAME,
				"requestHash": "req-hash-1",
				"timestampMillis": (now - chrono::Duration::seconds(10)).timestamp_millis().to_string(),
			},
			"appIntegrity": {
				"appRecognitionVerdict": "PLAY_RECOGNIZED",
				"certificateSha256Digest": [digest_b64],
			},
			"deviceIntegrity": {
				"deviceRecognitionVerdict": ["MEETS_DEVICE_INTEGRITY", "MEETS_STRONG_INTEGRITY"],
			},
			"environmentDetails": {
				"appAccessRiskVerdict": {
					"appsDetected": ["UNKNOWN_CAPTURING"],
				}
			}
		});
		let verdict = evaluate_google_play_integrity_payload(
			&payload,
			"req-hash-1",
			now,
			true,
			&HashSet::from([digest_hex]),
		);
		assert!(verdict.trusted);
		assert_eq!(verdict.reason_code, "device_integrity_strong");
		assert_eq!(
			verdict.review_reason_code,
			Some(DEVICE_CAPTURE_RISK_REVIEW_CODE)
		);
	}

	#[test]
	fn refuses_mismatched_hash_or_missing_strong_integrity() {
		let now = Utc::now();
		let payload = serde_json::json!({
			"requestDetails": {
				"requestPackageName": VERILY_ANDROID_PACKAGE_NAME,
				"requestHash": "other",
				"timestampMillis": now.timestamp_millis().to_string(),
			},
			"appIntegrity": { "appRecognitionVerdict": "PLAY_RECOGNIZED" },
			"deviceIntegrity": { "deviceRecognitionVerdict": ["MEETS_DEVICE_INTEGRITY"] },
		});
		let bad_hash = evaluate_google_play_integrity_payload(
			&payload,
			"expected",
			now,
			false,
			&HashSet::new(),
		);
		assert!(!bad_hash.trusted);
		assert_eq!(bad_hash.reason_code, "device_integrity_invalid");

		let not_strong =
			evaluate_google_play_integrity_payload(&payload, "other", now, true, &HashSet::new());
		assert!(!not_strong.trusted);
		assert_eq!(not_strong.reason_code, "device_integrity_not_strong");
	}
}
