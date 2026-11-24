//! Partner HTTP API (`/api/v1/*`), Ed25519 receipt JWKS (`/.well-known/jwks.json`),
//! database health probe (`/healthz`), local development evidence upload route
//! (`/_verily/local-evidence/*`), and SSRF-safe HMAC-SHA256 webhook delivery.

use std::net::IpAddr;
use std::sync::Arc;
use std::time::Duration;

use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use chrono::Utc;
use ed25519_dalek::Signer;
use ed25519_dalek::SigningKey;
use ed25519_dalek::VerifyingKey;
use hmac::Hmac;
use hmac::Mac;
use leptoskit_axum::axum::Json;
use leptoskit_axum::axum::Router;
use leptoskit_axum::axum::body::Bytes;
use leptoskit_axum::axum::extract::Path;
use leptoskit_axum::axum::extract::Query;
use leptoskit_axum::axum::extract::State;
use leptoskit_axum::axum::http::HeaderMap;
use leptoskit_axum::axum::http::StatusCode;
use leptoskit_axum::axum::response::IntoResponse;
use leptoskit_axum::axum::routing::get;
use leptoskit_axum::axum::routing::post;
use leptoskit_axum::axum::routing::put;
use leptoskit_db::Db;
use leptoskit_db::Id;
use serde::Deserialize;
use serde::Serialize;
use sha2::Digest;
use sha2::Sha256;
use verily_rewards::schema::ActionRow;
use verily_shared::ActionDefinitionStatus;
use verily_verification::asn1::hex_lower;
use verily_verification::storage::EvidenceStore;

use crate::schema::NewVerificationRequestRow;
use crate::schema::NewVerilyAppConfirmationRow;
use crate::schema::NewVerilyAppLinkRow;
use crate::schema::VerificationRequestRow;
use crate::schema::VerilyAppKeyRow;
use crate::schema::VerilyAppLinkCodeRow;
use crate::schema::VerilyAppRow;
use crate::serve::BackendHandle;

type HmacSha256 = Hmac<Sha256>;

/// Ed25519 JWS receipt signer supporting active key + retired verification keys
/// published at `/.well-known/jwks.json`.
#[derive(Clone)]
pub struct ReceiptSigner {
	kid: String,
	signing_key: SigningKey,
	retired_public_keys: Vec<(String, VerifyingKey)>,
}

impl ReceiptSigner {
	/// Deterministic development signer for debug/test hosts without secrets.
	#[must_use]
	pub fn development() -> Self {
		let seed = [0x56_u8; 32];
		Self::from_seed("verily-dev-ed25519-1".to_owned(), seed, Vec::new())
	}

	/// Builds a signer from a 32-byte Ed25519 seed (e.g. decoded from
	/// `VERILY_RECEIPT_SIGNING_PRIVATE_KEY`).
	#[must_use]
	pub fn from_seed(
		kid: String,
		seed: [u8; 32],
		retired_public_keys: Vec<(String, VerifyingKey)>,
	) -> Self {
		Self {
			kid,
			signing_key: SigningKey::from_bytes(&seed),
			retired_public_keys,
		}
	}

	/// Resolves from `VERILY_RECEIPT_SIGNING_PRIVATE_KEY` (base64url 32-byte seed).
	/// Returns `None` when unset so release builds can fail closed if needed.
	#[must_use]
	pub fn from_env() -> Option<Self> {
		let env_map: std::collections::HashMap<String, String> = std::env::vars().collect();
		Self::from_env_map(&env_map)
	}

	/// Resolves from an explicit environment map (for deterministic startup & tests).
	#[must_use]
	pub fn from_env_map(env_map: &std::collections::HashMap<String, String>) -> Option<Self> {
		let raw = env_map.get("VERILY_RECEIPT_SIGNING_PRIVATE_KEY")?;
		let bytes = URL_SAFE_NO_PAD.decode(raw.trim().as_bytes()).ok()?;
		let seed: [u8; 32] = bytes.try_into().ok()?;
		let kid = env_map
			.get("VERILY_RECEIPT_SIGNING_KEY_ID")
			.map(|s| s.trim().to_owned())
			.filter(|s| !s.is_empty())
			.unwrap_or_else(|| "verily-ed25519-1".to_owned());
		Some(Self::from_seed(kid, seed, Vec::new()))
	}

	/// Signs a compact `EdDSA` (Ed25519) JWS over `claims`.
	#[must_use]
	pub fn sign_jws(&self, claims: &serde_json::Value) -> String {
		let header = serde_json::json!({
			"alg": "EdDSA",
			"typ": "JWT",
			"kid": self.kid,
		});
		let h = URL_SAFE_NO_PAD.encode(header.to_string().as_bytes());
		let p = URL_SAFE_NO_PAD.encode(claims.to_string().as_bytes());
		let signing_input = format!("{h}.{p}");
		let sig = self.signing_key.sign(signing_input.as_bytes());
		let s = URL_SAFE_NO_PAD.encode(sig.to_bytes());
		format!("{signing_input}.{s}")
	}

	/// Public JWKS document advertising the active key plus any retired keys.
	#[must_use]
	pub fn jwks(&self) -> serde_json::Value {
		let mut keys = Vec::with_capacity(1 + self.retired_public_keys.len());
		keys.push(jwk_entry(&self.kid, &self.signing_key.verifying_key()));
		for (kid, vk) in &self.retired_public_keys {
			keys.push(jwk_entry(kid, vk));
		}
		serde_json::json!({ "keys": keys })
	}
}

fn jwk_entry(kid: &str, vk: &VerifyingKey) -> serde_json::Value {
	serde_json::json!({
		"kty": "OKP",
		"crv": "Ed25519",
		"alg": "EdDSA",
		"use": "sig",
		"kid": kid,
		"x": URL_SAFE_NO_PAD.encode(vk.to_bytes()),
	})
}

/// Validates an outbound partner webhook / pull-check URL against SSRF:
/// must be `https://`, no userinfo, and cannot literal-target loopback/private/link-local IPs.
///
/// # Errors
///
/// Returns a static error code when the URL is malformed, non-HTTPS, contains
/// userinfo, or targets a private/loopback host or IP literal.
pub fn validate_outbound_url(raw: &str) -> Result<url::Url, &'static str> {
	let parsed = url::Url::parse(raw.trim()).map_err(|_| "invalid_url")?;
	if parsed.scheme() != "https" {
		return Err("https_required");
	}
	if !parsed.username().is_empty() || parsed.password().is_some() {
		return Err("userinfo_forbidden");
	}
	let host = parsed.host_str().ok_or("missing_host")?;
	let host_lower = host.to_ascii_lowercase();
	let private_tld = host_lower
		.rsplit('.')
		.next()
		.is_some_and(|tld| matches!(tld, "local" | "internal"));
	if host_lower == "localhost" || private_tld {
		return Err("private_host_forbidden");
	}
	if let Ok(ip) = host.trim_matches(['[', ']']).parse::<IpAddr>()
		&& is_forbidden_ip(ip)
	{
		return Err("private_ip_forbidden");
	}
	Ok(parsed)
}

/// Checks whether a resolved IP address is private, loopback, link-local, or unspecified.
#[must_use]
pub const fn is_forbidden_ip(ip: IpAddr) -> bool {
	match ip {
		IpAddr::V4(v4) => {
			v4.is_loopback()
				|| v4.is_private()
				|| v4.is_link_local()
				|| v4.is_unspecified()
				|| v4.is_broadcast()
				|| v4.is_multicast()
				|| (v4.octets()[0] == 100 && (v4.octets()[1] & 0xc0) == 64) // CGNAT 100.64.0.0/10
		}
		IpAddr::V6(v6) => {
			v6.is_loopback()
				|| v6.is_unspecified()
				|| v6.is_multicast()
				|| (v6.segments()[0] & 0xfe00) == 0xfc00 // ULA fc00::/7
				|| (v6.segments()[0] & 0xffc0) == 0xfe80 // link-local fe80::/10
		}
	}
}

/// Computes `sha256=<hex>` HMAC-SHA256 webhook signature over `timestamp.payload`.
///
/// # Panics
///
/// Never panics because HMAC-SHA256 accepts keys of any length.
#[must_use]
pub fn sign_webhook_payload(secret: &str, timestamp: i64, payload: &[u8]) -> String {
	let mut mac =
		HmacSha256::new_from_slice(secret.as_bytes()).expect("HMAC accepts any secret size");
	mac.update(timestamp.to_string().as_bytes());
	mac.update(b".");
	mac.update(payload);
	format!("sha256={}", hex_lower(&mac.finalize().into_bytes()))
}

/// Delivers one signed partner webhook with DNS resolution SSRF verification
/// and zero redirect following.
///
/// # Errors
///
/// Returns a static error code when URL validation, DNS resolution, SSRF IP
/// checks, or HTTP delivery fail.
pub async fn send_signed_webhook(
	url_str: &str,
	secret: &str,
	event_type: &str,
	payload: &[u8],
) -> Result<u16, &'static str> {
	let parsed = validate_outbound_url(url_str)?;
	let host = parsed.host_str().ok_or("missing_host")?;
	let port = parsed.port_or_known_default().unwrap_or(443);

	let addrs: Vec<std::net::SocketAddr> = tokio::net::lookup_host((host, port))
		.await
		.map_err(|_| "dns_failed")?
		.collect();
	if addrs.is_empty() || addrs.iter().any(|addr| is_forbidden_ip(addr.ip())) {
		return Err("private_ip_forbidden");
	}
	let pinned_addr = addrs[0];

	let client = reqwest::Client::builder()
		.timeout(Duration::from_secs(10))
		.redirect(reqwest::redirect::Policy::none())
		.resolve(host, pinned_addr)
		.build()
		.map_err(|_| "http_client_failed")?;

	let ts = Utc::now().timestamp();
	let sig = sign_webhook_payload(secret, ts, payload);
	let response = client
		.post(parsed)
		.header("content-type", "application/json")
		.header("x-verily-event", event_type)
		.header("x-verily-timestamp", ts.to_string())
		.header("x-verily-signature-256", sig)
		.body(payload.to_vec())
		.send()
		.await
		.map_err(|_| "delivery_failed")?;
	Ok(response.status().as_u16())
}

/// Strict verdict returned by a partner pull-check endpoint.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PullCheckVerdict {
	Accepted,
	Rejected,
	Pending,
}

const MAX_PULL_CHECK_RESPONSE_BYTES: usize = 32 * 1024;

/// Parses a partner pull-check response under a strict schema (`{"verdict": ...}`).
/// Rejects oversized bodies, non-JSON prose, or unknown verdicts.
#[must_use]
pub fn parse_pull_check_verdict(body: &[u8]) -> Option<PullCheckVerdict> {
	if body.is_empty() || body.len() > MAX_PULL_CHECK_RESPONSE_BYTES {
		return None;
	}
	let value: serde_json::Value = serde_json::from_slice(body).ok()?;
	let obj = value.as_object()?;
	let verdict = obj.get("verdict")?.as_str()?.trim();
	match verdict {
		"accepted" => Some(PullCheckVerdict::Accepted),
		"rejected" => Some(PullCheckVerdict::Rejected),
		"pending" => Some(PullCheckVerdict::Pending),
		_ => None,
	}
}

/// Sends one signed partner pull-check request (`x-verily-event: attempt.verify`)
/// with DNS-pinned SSRF protection, zero redirects, and a 32 KiB response cap.
///
/// # Errors
///
/// Returns a static error code when URL validation, DNS resolution, SSRF IP
/// checks, HTTP delivery, or response size checks fail.
pub async fn send_signed_pull_check(
	url_str: &str,
	secret: &str,
	payload: &[u8],
) -> Result<(u16, Vec<u8>), &'static str> {
	let parsed = validate_outbound_url(url_str)?;
	let host = parsed.host_str().ok_or("missing_host")?;
	let port = parsed.port_or_known_default().unwrap_or(443);

	let addrs: Vec<std::net::SocketAddr> = tokio::net::lookup_host((host, port))
		.await
		.map_err(|_| "dns_failed")?
		.collect();
	if addrs.is_empty() || addrs.iter().any(|addr| is_forbidden_ip(addr.ip())) {
		return Err("private_ip_forbidden");
	}
	let pinned_addr = addrs[0];

	let client = reqwest::Client::builder()
		.timeout(Duration::from_secs(10))
		.redirect(reqwest::redirect::Policy::none())
		.resolve(host, pinned_addr)
		.build()
		.map_err(|_| "http_client_failed")?;

	let ts = Utc::now().timestamp();
	let sig = sign_webhook_payload(secret, ts, payload);
	let response = client
		.post(parsed)
		.header("content-type", "application/json")
		.header("x-verily-event", "attempt.verify")
		.header("x-verily-timestamp", ts.to_string())
		.header("x-verily-signature-256", sig)
		.body(payload.to_vec())
		.send()
		.await
		.map_err(|_| "delivery_failed")?;
	let status = response.status().as_u16();
	if response
		.content_length()
		.is_some_and(|len| len > MAX_PULL_CHECK_RESPONSE_BYTES as u64)
	{
		return Err("response_too_large");
	}
	let bytes = response.bytes().await.map_err(|_| "delivery_failed")?;
	if bytes.len() > MAX_PULL_CHECK_RESPONSE_BYTES {
		return Err("response_too_large");
	}
	Ok((status, bytes.to_vec()))
}

#[derive(Clone)]
struct HttpState {
	db: Db,
	backend: BackendHandle,
}

/// Mounts `/api/v1/health`, `/.well-known/jwks.json`, `/api/v1/*`, and dev local evidence routes.
///
/// Liveness (`/healthz`) and readiness (`/readyz`) are owned by `leptoskit::server::Readiness`
/// on the binary host so graceful shutdown can drain probes cleanly.
pub fn router(db: Db, backend: BackendHandle) -> Router {
	let state = Arc::new(HttpState { db, backend });
	Router::new()
		.route("/api/v1/health", get(healthz))
		.route("/.well-known/jwks.json", get(jwks))
		.route("/api/v1/confirmations", post(post_confirmation))
		.route("/api/v1/actions", post(post_partner_action))
		.route(
			"/api/v1/actions/{action_id}/publish",
			post(post_partner_publish),
		)
		.route(
			"/api/v1/actions/{action_id}/pause",
			post(post_partner_pause),
		)
		.route("/api/v1/links/exchange", post(post_link_exchange))
		.route(
			"/api/v1/verification-requests",
			post(post_verification_request),
		)
		.route(
			"/api/v1/verification-requests/{request_id}/receipt",
			get(get_verification_receipt),
		)
		.route("/_verily/local-evidence/{*path}", put(put_local_evidence))
		.route("/_verily/local-evidence/{*path}", get(get_local_evidence))
		.with_state(state)
}

async fn healthz(State(state): State<Arc<HttpState>>) -> impl IntoResponse {
	match ActionRow::query().limit(1).all(&state.db).await {
		Ok(_) => (StatusCode::OK, "ok"),
		Err(_) => (StatusCode::SERVICE_UNAVAILABLE, "database unavailable"),
	}
}

async fn jwks(State(state): State<Arc<HttpState>>) -> impl IntoResponse {
	let doc = state
		.backend
		.0
		.receipt_signer
		.as_ref()
		.map_or_else(|| serde_json::json!({ "keys": [] }), |s| s.jwks());
	Json(doc)
}

async fn authenticate_app(db: &Db, headers: &HeaderMap) -> Result<VerilyAppRow, StatusCode> {
	let auth = headers
		.get("authorization")
		.and_then(|v| v.to_str().ok())
		.and_then(|v| v.strip_prefix("Bearer "))
		.map(str::trim)
		.filter(|s| !s.is_empty())
		.ok_or(StatusCode::UNAUTHORIZED)?;
	let key_hash = hex_lower(&Sha256::digest(auth.as_bytes()));
	let key = VerilyAppKeyRow::query()
		.filter(|k| k.key_hash.eq(key_hash))
		.first(db)
		.await
		.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
		.ok_or(StatusCode::UNAUTHORIZED)?;
	if key.revoked_at.is_some() {
		return Err(StatusCode::UNAUTHORIZED);
	}
	let app = VerilyAppRow::query()
		.filter(|a| a.id.eq(key.app_id))
		.first(db)
		.await
		.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
		.ok_or(StatusCode::UNAUTHORIZED)?;
	if !app.active {
		return Err(StatusCode::FORBIDDEN);
	}
	Ok(app)
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct ConfirmationBody {
	action_id: String,
	external_user_id: String,
	idempotency_key: String,
	verified: bool,
}

async fn post_confirmation(
	State(state): State<Arc<HttpState>>,
	headers: HeaderMap,
	Json(body): Json<ConfirmationBody>,
) -> Result<Json<serde_json::Value>, StatusCode> {
	let app = authenticate_app(&state.db, &headers).await?;
	let action_uuid: uuid::Uuid = body
		.action_id
		.parse()
		.map_err(|_| StatusCode::BAD_REQUEST)?;
	let row = NewVerilyAppConfirmationRow {
		app_id: app.id,
		action_id: Id::<ActionRow>::from_uuid(action_uuid),
		external_user_id: body.external_user_id,
		idempotency_key: body.idempotency_key,
		verified: body.verified,
	}
	.insert(&state.db)
	.await
	.map_err(|_| StatusCode::BAD_REQUEST)?;
	Ok(Json(serde_json::json!({
		"id": row.id.to_string(),
		"recorded": true,
	})))
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct PartnerActionBody {
	action_key: String,
	title: String,
	description: String,
}

async fn post_partner_action(
	State(state): State<Arc<HttpState>>,
	headers: HeaderMap,
	Json(body): Json<PartnerActionBody>,
) -> Result<Json<serde_json::Value>, StatusCode> {
	let app = authenticate_app(&state.db, &headers).await?;
	if body.title.trim().is_empty() || body.action_key.trim().is_empty() {
		return Err(StatusCode::BAD_REQUEST);
	}
	let req = verily_shared::CreateActionDefinitionRequest {
		action_key: body.action_key.trim().to_owned(),
		title: body.title.trim().to_owned(),
		description: body.description.trim().to_owned(),
		recurrence: verily_shared::ActionRecurrence::Once,
		time_zone: "UTC".to_owned(),
		max_verified_completions: None,
		opens_at: None,
		closes_at: None,
		requirements: vec![verily_shared::ActionRequirementDraft::new(
			"app-proof",
			verily_shared::ActionRequirementKind::ExternalApp,
			"Partner verification",
			"Complete in partner app",
			true,
		)],
		reward: None,
	};
	let created = verily_rewards::store::create_action(
		&state.db,
		&state.backend.0.rewards,
		app.owner_id.uuid(),
		&app.name,
		&req,
	)
	.await
	.map_err(|_| StatusCode::BAD_REQUEST)?;
	Ok(Json(serde_json::json!({
		"id": created.id.to_string(),
		"status": "draft",
	})))
}

async fn post_partner_publish(
	State(state): State<Arc<HttpState>>,
	headers: HeaderMap,
	Path(action_id): Path<String>,
) -> Result<Json<serde_json::Value>, StatusCode> {
	let app = authenticate_app(&state.db, &headers).await?;
	let action_uuid: uuid::Uuid = action_id.parse().map_err(|_| StatusCode::BAD_REQUEST)?;
	let action = ActionRow::query()
		.filter(|r| {
			r.id.eq(Id::<ActionRow>::from_uuid(action_uuid)) & r.creator_id.eq(app.owner_id.uuid())
		})
		.first(&state.db)
		.await
		.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
		.ok_or(StatusCode::NOT_FOUND)?;
	let published = verily_rewards::store::publish_action(
		&state.db,
		&state.backend.0.rewards,
		app.owner_id.uuid(),
		action.id.uuid(),
		action.revision,
	)
	.await
	.map_err(|_| StatusCode::CONFLICT)?;
	Ok(Json(serde_json::json!({
		"id": published.id.to_string(),
		"status": "active",
	})))
}

async fn post_partner_pause(
	State(state): State<Arc<HttpState>>,
	headers: HeaderMap,
	Path(action_id): Path<String>,
) -> Result<Json<serde_json::Value>, StatusCode> {
	let app = authenticate_app(&state.db, &headers).await?;
	let action_uuid: uuid::Uuid = action_id.parse().map_err(|_| StatusCode::BAD_REQUEST)?;
	let mut action = ActionRow::query()
		.filter(|r| {
			r.id.eq(Id::<ActionRow>::from_uuid(action_uuid)) & r.creator_id.eq(app.owner_id.uuid())
		})
		.first(&state.db)
		.await
		.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
		.ok_or(StatusCode::NOT_FOUND)?;
	action.status = serde_json::to_value(ActionDefinitionStatus::Paused)
		.ok()
		.and_then(|v| v.as_str().map(str::to_owned))
		.unwrap_or_else(|| "paused".to_owned());
	action.updated_at = Utc::now();
	action
		.save(&state.db)
		.await
		.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
	Ok(Json(serde_json::json!({
		"id": action.id.to_string(),
		"status": "paused",
	})))
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct LinkExchangeBody {
	code: String,
	redirect_uri: String,
	external_user_id: String,
}

async fn post_link_exchange(
	State(state): State<Arc<HttpState>>,
	headers: HeaderMap,
	Json(body): Json<LinkExchangeBody>,
) -> Result<Json<serde_json::Value>, StatusCode> {
	let app = authenticate_app(&state.db, &headers).await?;
	let code_hash = hex_lower(&Sha256::digest(body.code.trim().as_bytes()));
	let mut code_row = VerilyAppLinkCodeRow::query()
		.filter(|r| r.code_hash.eq(code_hash) & r.app_id.eq(app.id))
		.first(&state.db)
		.await
		.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
		.ok_or(StatusCode::BAD_REQUEST)?;
	let now = Utc::now();
	if code_row.exchanged_at.is_some()
		|| code_row.expires_at < now
		|| code_row.redirect_uri != body.redirect_uri.trim()
	{
		return Err(StatusCode::BAD_REQUEST);
	}
	code_row.exchanged_at = Some(now);
	code_row
		.save(&state.db)
		.await
		.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

	let link = NewVerilyAppLinkRow {
		app_id: app.id,
		account_id: code_row.account_id,
		external_user_id: body.external_user_id.trim().to_owned(),
	}
	.insert(&state.db)
	.await
	.map_err(|_| StatusCode::BAD_REQUEST)?;

	Ok(Json(serde_json::json!({
		"linkId": link.id.to_string(),
		"accountId": link.account_id.to_string(),
		"externalUserId": link.external_user_id,
	})))
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct CreateVerificationRequestBody {
	action_id: String,
	external_subject: Option<String>,
	callback_url: Option<String>,
	ttl_seconds: Option<i64>,
}

async fn post_verification_request(
	State(state): State<Arc<HttpState>>,
	headers: HeaderMap,
	Json(body): Json<CreateVerificationRequestBody>,
) -> Result<Json<serde_json::Value>, StatusCode> {
	let app = authenticate_app(&state.db, &headers).await?;
	let action_uuid: uuid::Uuid = body
		.action_id
		.parse()
		.map_err(|_| StatusCode::BAD_REQUEST)?;
	if let Some(cb) = &body.callback_url {
		validate_outbound_url(cb).map_err(|_| StatusCode::BAD_REQUEST)?;
	}
	let ttl = body.ttl_seconds.unwrap_or(3600).clamp(60, 86_400);
	let expires_at = Utc::now() + chrono::Duration::seconds(ttl);
	let row = NewVerificationRequestRow {
		app_id: app.id,
		action_id: Id::<ActionRow>::from_uuid(action_uuid),
		participant_id: None,
		attempt_id: None,
		external_subject: body.external_subject,
		callback_url: body.callback_url,
		status: "open".to_owned(),
		receipt_jws: None,
		expires_at,
	}
	.insert(&state.db)
	.await
	.map_err(|_| StatusCode::BAD_REQUEST)?;

	Ok(Json(serde_json::json!({
		"id": row.id.to_string(),
		"url": format!("/r/{}", row.id),
		"expiresAt": expires_at.to_rfc3339(),
	})))
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct ReceiptResponse {
	request_id: String,
	status: String,
	receipt: String,
}

async fn get_verification_receipt(
	State(state): State<Arc<HttpState>>,
	headers: HeaderMap,
	Path(request_id): Path<String>,
) -> Result<Json<ReceiptResponse>, StatusCode> {
	let app = authenticate_app(&state.db, &headers).await?;
	let req_uuid: uuid::Uuid = request_id.parse().map_err(|_| StatusCode::BAD_REQUEST)?;
	let mut row = VerificationRequestRow::query()
		.filter(|r| {
			r.id.eq(Id::<VerificationRequestRow>::from_uuid(req_uuid)) & r.app_id.eq(app.id)
		})
		.first(&state.db)
		.await
		.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
		.ok_or(StatusCode::NOT_FOUND)?;
	if row.status != "verified" {
		return Err(StatusCode::CONFLICT);
	}
	let receipt = if let Some(existing) = &row.receipt_jws {
		existing.clone()
	} else {
		let Some(signer) = &state.backend.0.receipt_signer else {
			return Err(StatusCode::SERVICE_UNAVAILABLE);
		};
		let claims = serde_json::json!({
			"iss": "https://verily.fun",
			"aud": app.slug,
			"sub": row.external_subject.clone().unwrap_or_else(|| row.participant_id.map(|p| p.to_string()).unwrap_or_default()),
			"jti": row.id.to_string(),
			"actionId": row.action_id.to_string(),
			"status": "verified",
			"iat": Utc::now().timestamp(),
		});
		let jws = signer.sign_jws(&claims);
		row.receipt_jws = Some(jws.clone());
		let _ = row.save(&state.db).await;
		jws
	};
	Ok(Json(ReceiptResponse {
		request_id: row.id.to_string(),
		status: row.status,
		receipt,
	}))
}

#[derive(Deserialize)]
struct VersionQuery {
	#[serde(rename = "versionId")]
	version_id: Option<String>,
}

async fn put_local_evidence(
	State(state): State<Arc<HttpState>>,
	Path(path): Path<String>,
	headers: HeaderMap,
	body: Bytes,
) -> Result<impl IntoResponse, StatusCode> {
	let EvidenceStore::Local(local) = &*state.backend.0.evidence_store else {
		return Err(StatusCode::NOT_FOUND);
	};
	let mime = headers
		.get("content-type")
		.and_then(|v| v.to_str().ok())
		.unwrap_or("application/octet-stream");
	let (version_id, inspection) = local
		.put_bytes(&path, mime, &body)
		.map_err(|_| StatusCode::BAD_REQUEST)?;
	Ok((
		StatusCode::OK,
		[("x-amz-version-id", version_id)],
		Json(serde_json::json!({
			"versionId": inspection.version_id,
			"sha256": inspection.sha256_digest,
			"byteLength": inspection.byte_length,
		})),
	))
}

async fn get_local_evidence(
	State(state): State<Arc<HttpState>>,
	Path(path): Path<String>,
	Query(query): Query<VersionQuery>,
) -> Result<impl IntoResponse, StatusCode> {
	let EvidenceStore::Local(local) = &*state.backend.0.evidence_store else {
		return Err(StatusCode::NOT_FOUND);
	};
	let version_id = query.version_id.ok_or(StatusCode::BAD_REQUEST)?;
	let (bytes, mime) = local
		.read_bytes(&path, &version_id)
		.map_err(|_| StatusCode::NOT_FOUND)?;
	Ok((StatusCode::OK, [("content-type", mime)], bytes))
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn ssrf_validator_rejects_loopback_private_and_http_urls() {
		assert!(validate_outbound_url("http://example.com/hook").is_err());
		assert!(validate_outbound_url("https://localhost/hook").is_err());
		assert!(validate_outbound_url("https://127.0.0.1/hook").is_err());
		assert!(validate_outbound_url("https://169.254.169.254/latest").is_err());
		assert!(validate_outbound_url("https://10.0.0.1/hook").is_err());
		assert!(validate_outbound_url("https://[::1]/hook").is_err());
		assert!(validate_outbound_url("https://user:pass@partner.example/hook").is_err());
		assert!(validate_outbound_url("https://partner.example/webhooks/verily").is_ok());
	}

	#[test]
	fn receipt_signer_produces_verifiable_eddsa_jws_and_jwks() {
		let signer = ReceiptSigner::development();
		let jwks = signer.jwks();
		let keys = jwks["keys"].as_array().unwrap();
		assert_eq!(keys.len(), 1);
		assert_eq!(keys[0]["crv"], "Ed25519");
		let token = signer.sign_jws(&serde_json::json!({ "status": "verified" }));
		let parts: Vec<&str> = token.split('.').collect();
		assert_eq!(parts.len(), 3);
	}

	#[test]
	fn hmac_webhook_signature_is_deterministic_hex() {
		let sig = sign_webhook_payload("whsec_test", 1_700_000_000, br#"{"ok":true}"#);
		assert!(sig.starts_with("sha256="));
		assert_eq!(sig.len(), 7 + 64);
	}

	#[test]
	fn pull_check_verdict_parser_enforces_strict_schema() {
		assert_eq!(
			parse_pull_check_verdict(br#"{"verdict":"accepted"}"#),
			Some(PullCheckVerdict::Accepted)
		);
		assert_eq!(
			parse_pull_check_verdict(br#"{"verdict":"rejected"}"#),
			Some(PullCheckVerdict::Rejected)
		);
		assert_eq!(
			parse_pull_check_verdict(br#"{"verdict":"pending"}"#),
			Some(PullCheckVerdict::Pending)
		);
		assert_eq!(parse_pull_check_verdict(br#"{"verdict":"approved"}"#), None);
		assert_eq!(parse_pull_check_verdict(b"accepted"), None);
		assert_eq!(parse_pull_check_verdict(b""), None);
		let oversized = vec![b' '; MAX_PULL_CHECK_RESPONSE_BYTES + 1];
		assert_eq!(parse_pull_check_verdict(&oversized), None);
	}
}
