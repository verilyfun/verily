//! Media upload reservations, venue QR challenges, Apple App Attest key
//! registration & assertion verification, and Apple `DeviceCheck` operator tools.

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use chrono::Duration;
use chrono::Utc;
use leptoskit_auth::Account as AuthAccount;
use leptoskit_db::Connection;
use leptoskit_db::Id;
use leptoskit_rpc as rpc;
use rand::RngCore;
use sha2::Digest;
use sha2::Sha256;
use verily_api::AppAttestChallengeView;
use verily_api::AppAttestKeyRegistered;
use verily_api::DeviceCheckBitsView;
use verily_api::MediaUploadConfirmed;
use verily_api::MediaUploadPlan;
use verily_api::QrChallengeView;
use verily_rewards::schema::ActionRow;
use verily_verification::app_attest::AppleDeviceBits;
use verily_verification::asn1::hex_lower;
use verily_verification::binding::normalize_sha256;

use super::Backend;
use super::attempts::owned_attempt;
use super::backend;
use super::catalogue::owned_action;
use super::db;
use super::me;
use super::parse_id;
use super::require_active;
use super::review::is_reviewer;
use crate::schema::ActionQrChallengeRow;
use crate::schema::AppAttestChallengeRow;
use crate::schema::AppAttestKeyRow;
use crate::schema::Attempt;
use crate::schema::EvidenceUploadReservationRow;
use crate::schema::NewActionQrChallengeRow;
use crate::schema::NewAppAttestChallengeRow;
use crate::schema::NewAppAttestKeyRow;
use crate::schema::NewDeviceCheckAuditRow;
use crate::schema::NewEvidenceUploadReservationRow;

const MAX_UPLOAD_BYTES: i64 = 100 * 1024 * 1024;
const UPLOAD_PRESIGN_TTL_SECONDS: u32 = 15 * 60;
const QR_DEFAULT_TTL_SECONDS: i64 = 15 * 60;
const APP_ATTEST_CHALLENGE_TTL_SECONDS: i64 = 10 * 60;

/// Reserves a private, version-pinned object key and returns a short-lived
/// presigned PUT upload plan.
pub async fn request_media_upload(
	cx: &rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	mime_type: String,
	byte_length: i64,
) -> rpc::Result<MediaUploadPlan> {
	let participant = me(cx.context())?;
	let backend = backend(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let attempt = owned_attempt(cx.tx(), participant, &attempt_id).await?;

	let mime_type = mime_type.trim().to_ascii_lowercase();
	if !is_allowed_media_mime(&mime_type) {
		return Err(rpc::Error::invalid("unsupportedMimeType"));
	}
	if !(1..=MAX_UPLOAD_BYTES).contains(&byte_length) {
		return Err(rpc::Error::invalid("invalidByteLength"));
	}
	let req_uuid = parse_id(&requirement_id)?;
	let ext = mime_extension(&mime_type);
	let object_key = format!(
		"evidence/{}/{}/{}-{}.{}",
		attempt.id,
		req_uuid,
		Utc::now().timestamp(),
		random_hex(6),
		ext
	);
	let now = Utc::now();
	let presigned = backend
		.evidence_store
		.presign_put(&object_key, &mime_type, now, UPLOAD_PRESIGN_TTL_SECONDS)
		.map_err(|_| rpc::Error::retry("storageUnavailable"))?;

	let reservation = NewEvidenceUploadReservationRow {
		attempt_id: attempt.id,
		participant_id: participant,
		requirement_id: req_uuid.to_string(),
		object_key: presigned.object_key.clone(),
		mime_type,
		max_byte_length: byte_length,
		expires_at: presigned.expires_at,
		confirmed_at: None,
		version_id: None,
		sha256_digest: None,
		byte_length: None,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	Ok(MediaUploadPlan {
		reservation_id: reservation.id.to_string(),
		object_key: presigned.object_key,
		upload_url: presigned.upload_url,
		headers: presigned.headers.into_iter().collect(),
		expires_at_unix: presigned.expires_at.timestamp(),
	})
}

/// Inspects the immutable storage version uploaded for `reservation_id`,
/// checks its SHA-256 digest and byte size against the reservation, and seals it.
pub async fn confirm_media_upload(
	cx: &rpc::MutationCx,
	reservation_id: String,
	version_id: String,
	expected_sha256_hex: String,
) -> rpc::Result<MediaUploadConfirmed> {
	let participant = me(cx.context())?;
	let backend = backend(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let res_id = Id::<EvidenceUploadReservationRow>::from_uuid(parse_id(&reservation_id)?);
	let mut row = EvidenceUploadReservationRow::query()
		.filter(|r| r.id.eq(res_id) & r.participant_id.eq(participant))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;

	let expected_digest =
		normalize_sha256(&expected_sha256_hex).map_err(|_| rpc::Error::invalid("invalidDigest"))?;
	if row.confirmed_at.is_some() {
		if row.sha256_digest.as_deref() == Some(expected_digest.as_str())
			&& row.version_id.as_deref() == Some(version_id.trim())
		{
			return Ok(MediaUploadConfirmed {
				reservation_id: row.id.to_string(),
				version_id: row.version_id.unwrap_or_default(),
				sha256_hex: expected_digest,
				byte_length: u64::try_from(row.byte_length.unwrap_or(0)).unwrap_or(0),
			});
		}
		return Err(rpc::Error::conflict("uploadAlreadyConfirmed"));
	}
	if row.expires_at < Utc::now() {
		return Err(rpc::Error::invalid("uploadExpired"));
	}

	let inspection = backend
		.evidence_store
		.inspect_version(&row.object_key, version_id.trim())
		.await
		.map_err(|_| rpc::Error::invalid("uploadNotFound"))?;

	if inspection.sha256_digest.to_ascii_lowercase() != expected_digest {
		return Err(rpc::Error::invalid("digestMismatch"));
	}
	let inspected_len = i64::try_from(inspection.byte_length)
		.map_err(|_| rpc::Error::invalid("invalidByteLength"))?;
	if inspected_len <= 0 || inspected_len > MAX_UPLOAD_BYTES {
		return Err(rpc::Error::invalid("invalidByteLength"));
	}

	row.confirmed_at = Some(Utc::now());
	row.version_id = Some(inspection.version_id.clone());
	row.sha256_digest = Some(expected_digest.clone());
	row.byte_length = Some(inspected_len);
	row.save(cx.tx()).await.map_err(db)?;

	Ok(MediaUploadConfirmed {
		reservation_id: row.id.to_string(),
		version_id: inspection.version_id,
		sha256_hex: expected_digest,
		byte_length: inspection.byte_length,
	})
}

/// Issues a short-lived rotating venue QR code for an action's creator.
pub async fn create_qr_challenge(
	cx: &rpc::MutationCx,
	action_id: String,
	ttl_seconds: Option<i64>,
) -> rpc::Result<QrChallengeView> {
	let creator = me(cx.context())?;
	require_active(cx.tx(), creator).await?;
	let action = owned_action(cx.tx(), creator, parse_id(&action_id)?).await?;
	let ttl = ttl_seconds
		.unwrap_or(QR_DEFAULT_TTL_SECONDS)
		.clamp(60, 24 * 3600);
	let expires_at = Utc::now() + Duration::seconds(ttl);
	let code = format!("vqr_{}", random_token(18));
	let code_hash = hex_lower(&Sha256::digest(code.as_bytes()));

	NewActionQrChallengeRow {
		action_id: action.id,
		creator_id: creator,
		code_hash,
		expires_at,
		consumed_at: None,
		consumed_by_attempt_id: None,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	Ok(QrChallengeView {
		code,
		expires_at_unix: expires_at.timestamp(),
	})
}

/// Atomically redeems a single-use venue QR challenge inside a participant's attempt.
pub(crate) async fn redeem_qr_challenge(
	connection: &impl Connection,
	action_id: Id<ActionRow>,
	attempt_id: Id<Attempt>,
	raw_code: &str,
) -> Result<(), rpc::Error> {
	let trimmed = raw_code.trim();
	if trimmed.is_empty() || trimmed.len() > 256 {
		return Err(rpc::Error::invalid("invalidVenueCode"));
	}
	let code_hash = hex_lower(&Sha256::digest(trimmed.as_bytes()));
	let mut row = ActionQrChallengeRow::query()
		.filter(|r| r.action_id.eq(action_id) & r.code_hash.eq(code_hash))
		.first(connection)
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::invalid("invalidVenueCode"))?;
	let now = Utc::now();
	if row.consumed_at.is_some() {
		return Err(rpc::Error::conflict("venueCodeUsed"));
	}
	if row.expires_at < now {
		return Err(rpc::Error::invalid("venueCodeExpired"));
	}
	row.consumed_at = Some(now);
	row.consumed_by_attempt_id = Some(attempt_id);
	row.save(connection).await.map_err(db)?;
	Ok(())
}

/// Mints a one-time registration nonce for an iPhone's Apple App Attest key.
pub async fn begin_app_attest_registration(
	cx: &rpc::MutationCx,
) -> rpc::Result<AppAttestChallengeView> {
	let account = me(cx.context())?;
	require_active(cx.tx(), account).await?;
	let nonce = random_token(32);
	let expires_at = Utc::now() + Duration::seconds(APP_ATTEST_CHALLENGE_TTL_SECONDS);
	let row = NewAppAttestChallengeRow {
		account_id: account,
		nonce: nonce.clone(),
		expires_at,
		consumed_at: None,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	Ok(AppAttestChallengeView {
		challenge_id: row.id.to_string(),
		nonce,
	})
}

/// Verifies an Apple App Attest CBOR attestation object against Apple's pinned
/// App Attestation Root CA and registers the hardware P-256 key on the account.
pub async fn register_app_attest_key(
	cx: &rpc::MutationCx,
	challenge_id: String,
	key_id_b64: String,
	attestation_object_b64: String,
) -> rpc::Result<AppAttestKeyRegistered> {
	let account = me(cx.context())?;
	let backend = backend(cx.context())?;
	require_active(cx.tx(), account).await?;

	let Some(verifier) = &backend.app_attest else {
		return Err(rpc::Error::retry("appAttestUnavailable"));
	};
	let cid = Id::<AppAttestChallengeRow>::from_uuid(parse_id(&challenge_id)?);
	let mut challenge = AppAttestChallengeRow::query()
		.filter(|r| r.id.eq(cid) & r.account_id.eq(account))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	let now = Utc::now();
	if challenge.consumed_at.is_some() || challenge.expires_at < now {
		return Err(rpc::Error::invalid("challengeExpired"));
	}

	let key_id = STANDARD
		.decode(key_id_b64.trim().as_bytes())
		.map_err(|_| rpc::Error::invalid("invalidKeyId"))?;
	let attestation_object = STANDARD
		.decode(attestation_object_b64.trim().as_bytes())
		.map_err(|_| rpc::Error::invalid("invalidAttestation"))?;
	let client_data_hash = Sha256::digest(challenge.nonce.as_bytes());

	let verdict = verifier.verify_attestation(&attestation_object, &key_id, &client_data_hash, now);
	let Some(attested) = verdict.key else {
		return Err(rpc::Error::invalid(verdict.reason_code));
	};

	challenge.consumed_at = Some(now);
	challenge.save(cx.tx()).await.map_err(db)?;

	let key_id_hash = hex_lower(&Sha256::digest(&key_id));
	let receipt_b64 = STANDARD.encode(&attested.receipt);
	let public_key_b64 = STANDARD.encode(&attested.public_key);

	NewAppAttestKeyRow {
		account_id: account,
		key_id_hash,
		public_key_b64,
		sign_count: 0,
		receipt_b64: Some(receipt_b64),
		receipt_expires_at: Some(now + Duration::days(30)),
		risk_metric: None,
		revoked_at: None,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	Ok(AppAttestKeyRegistered {
		key_id: key_id_b64.trim().to_owned(),
		registered: true,
	})
}

/// Verifies a signed Apple App Attest assertion against a registered key and
/// atomically advances its monotonic `WebAuthn` signature counter.
pub(crate) async fn verify_registered_app_attest_assertion(
	connection: &impl Connection,
	backend: &Backend,
	account: Id<AuthAccount>,
	key_id_b64: &str,
	assertion_b64: &str,
	client_data: &[u8],
) -> Result<bool, rpc::Error> {
	let Some(verifier) = &backend.app_attest else {
		return Ok(false);
	};
	let Ok(key_id) = STANDARD.decode(key_id_b64.trim().as_bytes()) else {
		return Ok(false);
	};
	let Ok(assertion) = STANDARD.decode(assertion_b64.trim().as_bytes()) else {
		return Ok(false);
	};
	let key_id_hash = hex_lower(&Sha256::digest(&key_id));
	let Some(mut key_row) = AppAttestKeyRow::query()
		.filter(|r| r.key_id_hash.eq(key_id_hash) & r.account_id.eq(account))
		.first(connection)
		.await
		.map_err(db)?
	else {
		return Ok(false);
	};
	if key_row.revoked_at.is_some() {
		return Ok(false);
	}
	let Ok(public_key) = STANDARD.decode(key_row.public_key_b64.as_bytes()) else {
		return Ok(false);
	};
	let prev = u32::try_from(key_row.sign_count.max(0)).unwrap_or(u32::MAX);
	let verdict = verifier.verify_assertion(&assertion, client_data, &public_key, prev);
	let Some(next_counter) = verdict.counter else {
		return Ok(false);
	};
	key_row.sign_count = i64::from(next_counter);
	key_row.save(connection).await.map_err(db)?;
	Ok(true)
}

/// Operator query of an iPhone's Apple `DeviceCheck` two-bit state.
pub async fn query_device_check(
	cx: &rpc::MutationCx,
	device_token: String,
) -> rpc::Result<DeviceCheckBitsView> {
	let operator = me(cx.context())?;
	let backend = backend(cx.context())?;
	if !is_reviewer(cx.tx(), operator).await? {
		return Err(rpc::Error::forbidden("notReviewer"));
	}
	let Some(client) = &backend.apple_device_client else {
		return Err(rpc::Error::retry("deviceCheckUnavailable"));
	};
	let tx_id = uuid::Uuid::new_v4().to_string();
	let bits = client
		.query_bits(device_token.trim(), &tx_id, Utc::now())
		.await
		.map_err(|_| rpc::Error::retry("deviceCheckUnavailable"))?;
	NewDeviceCheckAuditRow {
		operator_id: operator,
		operation: "query".to_owned(),
		banned: bits.banned,
		review_required: bits.review_required,
		note: "operator query".to_owned(),
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;
	Ok(DeviceCheckBitsView {
		banned: bits.banned,
		review_required: bits.review_required,
	})
}

/// Operator update of an iPhone's Apple `DeviceCheck` two-bit state.
pub async fn update_device_check(
	cx: &rpc::MutationCx,
	device_token: String,
	banned: bool,
	review_required: bool,
	note: String,
) -> rpc::Result<DeviceCheckBitsView> {
	let operator = me(cx.context())?;
	let backend = backend(cx.context())?;
	if !is_reviewer(cx.tx(), operator).await? {
		return Err(rpc::Error::forbidden("notReviewer"));
	}
	let note = note.trim();
	if note.is_empty() || note.chars().count() > 500 {
		return Err(rpc::Error::invalid("reviewNote"));
	}
	let Some(client) = &backend.apple_device_client else {
		return Err(rpc::Error::retry("deviceCheckUnavailable"));
	};
	let tx_id = uuid::Uuid::new_v4().to_string();
	let bits = AppleDeviceBits {
		banned,
		review_required,
	};
	client
		.update_bits(device_token.trim(), &tx_id, bits, Utc::now())
		.await
		.map_err(|_| rpc::Error::retry("deviceCheckUnavailable"))?;
	NewDeviceCheckAuditRow {
		operator_id: operator,
		operation: "update".to_owned(),
		banned,
		review_required,
		note: note.to_owned(),
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;
	Ok(DeviceCheckBitsView {
		banned,
		review_required,
	})
}

fn is_allowed_media_mime(mime: &str) -> bool {
	matches!(
		mime,
		"image/jpeg"
			| "image/png"
			| "image/webp"
			| "video/mp4"
			| "video/quicktime"
			| "video/webm"
			| "audio/mp4"
			| "audio/m4a"
			| "audio/aac"
			| "audio/wav"
			| "audio/ogg"
			| "audio/webm"
			| "application/json"
	)
}

fn mime_extension(mime: &str) -> &'static str {
	match mime {
		"image/jpeg" => "jpg",
		"image/png" => "png",
		"image/webp" => "webp",
		"video/mp4" => "mp4",
		"video/quicktime" => "mov",
		"video/webm" => "webm",
		"audio/mp4" | "audio/m4a" => "m4a",
		"audio/aac" => "aac",
		"audio/wav" => "wav",
		"audio/ogg" => "ogg",
		"audio/webm" => "weba",
		"application/json" => "json",
		_ => "bin",
	}
}

fn random_token(bytes_len: usize) -> String {
	let mut buf = vec![0u8; bytes_len];
	rand::thread_rng().fill_bytes(&mut buf);
	URL_SAFE_NO_PAD.encode(buf)
}

fn random_hex(bytes_len: usize) -> String {
	let mut buf = vec![0u8; bytes_len];
	rand::thread_rng().fill_bytes(&mut buf);
	hex_lower(&buf)
}
