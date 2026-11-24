//! Verily Apps partner management, account linking, and partner-initiated
//! verification request operations on `verily-backend`.

use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use chrono::Duration;
use chrono::Utc;
use leptoskit_db::Id;
use leptoskit_db::Read;
use leptoskit_rpc as rpc;
use rand::RngCore;
use sha2::Digest;
use sha2::Sha256;
use verily_api::AppLinkExchangeView;
use verily_api::VerificationRequestView;
use verily_api::VerilyAppCreated;
use verily_api::VerilyAppDeliveryRow as VerilyAppDeliveryDto;
use verily_api::VerilyAppKeyRotated;
use verily_api::VerilyAppRow as VerilyAppDto;
use verily_rewards::schema::ActionRow;
use verily_verification::asn1::hex_lower;

use super::db;
use super::me;
use super::parse_id;
use super::require_active;
use crate::partner_http::validate_outbound_url;
use crate::schema::NewVerilyAppKeyRow;
use crate::schema::NewVerilyAppLinkCodeRow;
use crate::schema::NewVerilyAppRedirectUriRow;
use crate::schema::NewVerilyAppRow;
use crate::schema::VerificationRequestRow;
use crate::schema::VerilyAppKeyRow;
use crate::schema::VerilyAppLinkRow;
use crate::schema::VerilyAppRedirectUriRow;
use crate::schema::VerilyAppRow;
use crate::schema::VerilyAppWebhookDeliveryRow;

/// Lists partner apps owned by the signed-in creator.
pub async fn list_my_apps(cx: &rpc::QueryCx) -> rpc::Result<Vec<VerilyAppDto>> {
	let owner = me(cx.context())?;
	let rows = VerilyAppRow::query()
		.filter(|row| row.owner_id.eq(owner))
		.order_by(|row| row.created_at.desc())
		.limit(50)
		.all(cx.db())
		.await
		.map_err(db)?;
	let mut out = Vec::with_capacity(rows.len());
	for row in rows {
		out.push(app_dto(cx.db(), row).await?);
	}
	Ok(out)
}

/// Registers a new Verily App, generating a one-time API key (`vk_...`) and
/// webhook HMAC secret. Only hashes are persisted for the API key.
pub async fn create_app(
	cx: &rpc::MutationCx,
	name: String,
	slug: String,
	webhook_url: Option<String>,
) -> rpc::Result<VerilyAppCreated> {
	let owner = me(cx.context())?;
	require_active(cx.tx(), owner).await?;
	let name = name.trim().to_owned();
	let slug = slug.trim().to_ascii_lowercase();
	if name.is_empty() || name.len() > 80 || slug.is_empty() || slug.len() > 64 {
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	if !slug
		.bytes()
		.all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-')
	{
		return Err(rpc::Error::invalid("invalidSlug"));
	}
	let webhook_url = webhook_url
		.map(|u| u.trim().to_owned())
		.filter(|u| !u.is_empty());
	if let Some(url) = &webhook_url {
		validate_outbound_url(url).map_err(|_| rpc::Error::invalid("invalidWebhookUrl"))?;
	}

	let webhook_secret = format!("whsec_{}", random_token(24));
	let app_row = NewVerilyAppRow {
		owner_id: owner,
		name,
		slug,
		webhook_url,
		webhook_secret: webhook_secret.clone(),
		active: true,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	let (api_key_once, key_prefix, key_hash) = generate_api_key();
	NewVerilyAppKeyRow {
		app_id: app_row.id,
		key_prefix,
		key_hash,
		revoked_at: None,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	let dto = app_dto(cx.tx(), app_row).await?;
	Ok(VerilyAppCreated {
		app: dto,
		api_key_once,
		webhook_secret_once: webhook_secret,
	})
}

/// Updates a partner app's name, webhook URL, or active status.
pub async fn update_app(
	cx: &rpc::MutationCx,
	app_id: String,
	name: String,
	webhook_url: Option<String>,
	active: bool,
) -> rpc::Result<VerilyAppDto> {
	let owner = me(cx.context())?;
	require_active(cx.tx(), owner).await?;
	let id = Id::<VerilyAppRow>::from_uuid(parse_id(&app_id)?);
	let mut row = VerilyAppRow::query()
		.filter(|r| r.id.eq(id) & r.owner_id.eq(owner))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	let name = name.trim().to_owned();
	if name.is_empty() || name.len() > 80 {
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	let webhook_url = webhook_url
		.map(|u| u.trim().to_owned())
		.filter(|u| !u.is_empty());
	if let Some(url) = &webhook_url {
		validate_outbound_url(url).map_err(|_| rpc::Error::invalid("invalidWebhookUrl"))?;
	}
	row.name = name;
	row.webhook_url = webhook_url;
	row.active = active;
	row.save(cx.tx()).await.map_err(db)?;
	app_dto(cx.tx(), row).await
}

/// Rotates a partner app's API key (issuing a fresh key without revoking old keys immediately).
pub async fn rotate_app_key(
	cx: &rpc::MutationCx,
	app_id: String,
) -> rpc::Result<VerilyAppKeyRotated> {
	let owner = me(cx.context())?;
	require_active(cx.tx(), owner).await?;
	let id = Id::<VerilyAppRow>::from_uuid(parse_id(&app_id)?);
	let app = VerilyAppRow::query()
		.filter(|r| r.id.eq(id) & r.owner_id.eq(owner))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;

	let (api_key_once, key_prefix, key_hash) = generate_api_key();
	let row = NewVerilyAppKeyRow {
		app_id: app.id,
		key_prefix: key_prefix.clone(),
		key_hash,
		revoked_at: None,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	Ok(VerilyAppKeyRotated {
		key_id: row.id.to_string(),
		api_key_once,
		key_prefix,
	})
}

/// Revokes a partner API key.
pub async fn revoke_app_key(
	cx: &rpc::MutationCx,
	app_id: String,
	key_id: String,
) -> rpc::Result<bool> {
	let owner = me(cx.context())?;
	require_active(cx.tx(), owner).await?;
	let aid = Id::<VerilyAppRow>::from_uuid(parse_id(&app_id)?);
	let kid = Id::<VerilyAppKeyRow>::from_uuid(parse_id(&key_id)?);
	let Some(app) = VerilyAppRow::query()
		.filter(|r| r.id.eq(aid) & r.owner_id.eq(owner))
		.first(cx.tx())
		.await
		.map_err(db)?
	else {
		return Err(rpc::Error::not_found("notFound"));
	};
	let mut key = VerilyAppKeyRow::query()
		.filter(|r| r.id.eq(kid) & r.app_id.eq(app.id))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	key.revoked_at = Some(Utc::now());
	key.save(cx.tx()).await.map_err(db)?;
	Ok(true)
}

/// Adds an allowlisted redirect URI for deep-link account linking.
pub async fn add_app_redirect_uri(
	cx: &rpc::MutationCx,
	app_id: String,
	uri: String,
) -> rpc::Result<VerilyAppDto> {
	let owner = me(cx.context())?;
	require_active(cx.tx(), owner).await?;
	let aid = Id::<VerilyAppRow>::from_uuid(parse_id(&app_id)?);
	let app = VerilyAppRow::query()
		.filter(|r| r.id.eq(aid) & r.owner_id.eq(owner))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	let uri = uri.trim().to_owned();
	if uri.is_empty() || uri.len() > 512 || url::Url::parse(&uri).is_err() {
		return Err(rpc::Error::invalid("invalidRedirectUri"));
	}
	NewVerilyAppRedirectUriRow {
		app_id: app.id,
		uri,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;
	app_dto(cx.tx(), app).await
}

/// Lists recent webhook deliveries for a partner app.
pub async fn list_app_deliveries(
	cx: &rpc::QueryCx,
	app_id: String,
) -> rpc::Result<Vec<VerilyAppDeliveryDto>> {
	let owner = me(cx.context())?;
	let aid = Id::<VerilyAppRow>::from_uuid(parse_id(&app_id)?);
	let Some(app) = VerilyAppRow::query()
		.filter(|r| r.id.eq(aid) & r.owner_id.eq(owner))
		.first(cx.db())
		.await
		.map_err(db)?
	else {
		return Err(rpc::Error::not_found("notFound"));
	};
	let rows = VerilyAppWebhookDeliveryRow::query()
		.filter(|r| r.app_id.eq(app.id))
		.order_by(|r| r.created_at.desc())
		.limit(50)
		.all(cx.db())
		.await
		.map_err(db)?;
	Ok(rows
		.into_iter()
		.map(|r| VerilyAppDeliveryDto {
			id: r.id.to_string(),
			event_type: r.event_type,
			status: r.status,
			attempts: r.attempts,
			last_status_code: r.last_status_code,
		})
		.collect())
}

/// Approves a partner deep-link consent on `/link` and mints a single-use
/// exchange code bound to an allowlisted redirect URI.
pub async fn approve_app_link(
	cx: &rpc::MutationCx,
	app_slug: String,
	redirect_uri: String,
	state: Option<String>,
) -> rpc::Result<AppLinkExchangeView> {
	let account = me(cx.context())?;
	require_active(cx.tx(), account).await?;
	let app = VerilyAppRow::query()
		.filter(|r| r.slug.eq(app_slug.trim().to_ascii_lowercase()))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	if !app.active {
		return Err(rpc::Error::forbidden("appInactive"));
	}
	let redirect_uri = redirect_uri.trim().to_owned();
	let allowed = VerilyAppRedirectUriRow::query()
		.filter(|r| r.app_id.eq(app.id) & r.uri.eq(redirect_uri.clone()))
		.exists(cx.tx())
		.await
		.map_err(db)?;
	if !allowed {
		return Err(rpc::Error::invalid("redirectUriNotAllowed"));
	}

	let code = format!("vlc_{}", random_token(24));
	let code_hash = hex_lower(&Sha256::digest(code.as_bytes()));
	NewVerilyAppLinkCodeRow {
		app_id: app.id,
		account_id: account,
		code_hash,
		redirect_uri: redirect_uri.clone(),
		expires_at: Utc::now() + Duration::minutes(10),
		exchanged_at: None,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	Ok(AppLinkExchangeView {
		app_name: app.name,
		redirect_uri,
		code,
		state,
	})
}

/// Revokes a user's linked partner app connection.
pub async fn revoke_app_link(cx: &rpc::MutationCx, app_id: String) -> rpc::Result<bool> {
	let account = me(cx.context())?;
	let aid = Id::<VerilyAppRow>::from_uuid(parse_id(&app_id)?);
	let links = VerilyAppLinkRow::query()
		.filter(|r| r.app_id.eq(aid) & r.account_id.eq(account))
		.all(cx.tx())
		.await
		.map_err(db)?;
	for mut link in links {
		link.delete(cx.tx()).await.map_err(db)?;
	}
	Ok(true)
}

/// Loads a partner-initiated verification request for `/r/:request`.
pub async fn get_verification_request(
	cx: &rpc::QueryCx,
	request_id: String,
) -> rpc::Result<VerificationRequestView> {
	let _viewer = me(cx.context())?;
	let id = Id::<VerificationRequestRow>::from_uuid(parse_id(&request_id)?);
	let row = VerificationRequestRow::query()
		.filter(|r| r.id.eq(id))
		.first(cx.db())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	verification_request_dto(cx.db(), row).await
}

/// Binds the signed-in participant to an open verification request and opens
/// an attempt on its action.
pub async fn start_verification_request(
	cx: &rpc::MutationCx,
	request_id: String,
) -> rpc::Result<VerificationRequestView> {
	let participant = me(cx.context())?;
	require_active(cx.tx(), participant).await?;
	let id = Id::<VerificationRequestRow>::from_uuid(parse_id(&request_id)?);
	let mut row = VerificationRequestRow::query()
		.filter(|r| r.id.eq(id))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	if row.expires_at < Utc::now() {
		"expired".clone_into(&mut row.status);
		row.save(cx.tx()).await.map_err(db)?;
		return Err(rpc::Error::invalid("requestExpired"));
	}
	if row.status != "open" && row.participant_id != Some(participant) {
		return Err(rpc::Error::conflict("requestUnavailable"));
	}
	row.participant_id = Some(participant);
	"in_progress".clone_into(&mut row.status);
	row.save(cx.tx()).await.map_err(db)?;
	verification_request_dto(cx.tx(), row).await
}

/// Cancels an open verification request (participant or app owner).
pub async fn cancel_verification_request(
	cx: &rpc::MutationCx,
	request_id: String,
) -> rpc::Result<VerificationRequestView> {
	let caller = me(cx.context())?;
	let id = Id::<VerificationRequestRow>::from_uuid(parse_id(&request_id)?);
	let mut row = VerificationRequestRow::query()
		.filter(|r| r.id.eq(id))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	let is_owner = VerilyAppRow::query()
		.filter(|a| a.id.eq(row.app_id) & a.owner_id.eq(caller))
		.exists(cx.tx())
		.await
		.map_err(db)?;
	if row.participant_id != Some(caller) && !is_owner {
		return Err(rpc::Error::forbidden("forbidden"));
	}
	"cancelled".clone_into(&mut row.status);
	row.save(cx.tx()).await.map_err(db)?;
	verification_request_dto(cx.tx(), row).await
}

async fn app_dto(connection: &impl Read, row: VerilyAppRow) -> Result<VerilyAppDto, rpc::Error> {
	let keys = VerilyAppKeyRow::query()
		.filter(|k| k.app_id.eq(row.id))
		.order_by(|k| k.created_at.desc())
		.all(connection)
		.await
		.map_err(db)?;
	let key_prefix = keys
		.into_iter()
		.find(|k| k.revoked_at.is_none())
		.map(|k| k.key_prefix)
		.unwrap_or_default();
	let uris = VerilyAppRedirectUriRow::query()
		.filter(|u| u.app_id.eq(row.id))
		.all(connection)
		.await
		.map_err(db)?
		.into_iter()
		.map(|u| u.uri)
		.collect();
	Ok(VerilyAppDto {
		id: row.id.to_string(),
		name: row.name,
		slug: row.slug,
		webhook_url: row.webhook_url,
		active: row.active,
		key_prefix,
		redirect_uris: uris,
	})
}

async fn verification_request_dto(
	connection: &impl Read,
	row: VerificationRequestRow,
) -> Result<VerificationRequestView, rpc::Error> {
	let app_name = VerilyAppRow::query()
		.filter(|a| a.id.eq(row.app_id))
		.first(connection)
		.await
		.map_err(db)?
		.map(|a| a.name)
		.unwrap_or_default();
	let action_title = ActionRow::query()
		.filter(|a| a.id.eq(row.action_id))
		.first(connection)
		.await
		.map_err(db)?
		.map(|a| a.title)
		.unwrap_or_default();
	Ok(VerificationRequestView {
		id: row.id.to_string(),
		app_name,
		action_id: row.action_id.to_string(),
		action_title,
		status: row.status,
		expires_at_unix: row.expires_at.timestamp(),
		callback_url: row.callback_url,
		receipt_jws: row.receipt_jws,
	})
}

fn generate_api_key() -> (String, String, String) {
	let raw = format!("vk_{}", random_token(28));
	let prefix = raw.chars().take(12).collect::<String>();
	let hash = hex_lower(&Sha256::digest(raw.as_bytes()));
	(raw, prefix, hash)
}

fn random_token(bytes_len: usize) -> String {
	let mut buf = vec![0u8; bytes_len];
	rand::thread_rng().fill_bytes(&mut buf);
	URL_SAFE_NO_PAD.encode(buf)
}
