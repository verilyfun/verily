//! Verily Apps partner integrations: API keys, redirect URIs, account links,
//! external confirmations, pull checks, signed receipts, webhook deliveries,
//! and partner-initiated verification requests.

use leptoskit_auth::Account as AuthAccount;
use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::table;
use verily_rewards::schema::ActionRow;

use crate::schema::Attempt;

/// A partner application registered by a creator.
#[table(name = "verily_apps", unique(slug), index(owner_id))]
pub struct VerilyAppRow {
	pub id: Id<VerilyAppRow>,
	#[db(on_delete = cascade)]
	pub owner_id: Id<AuthAccount>,
	#[db(min_len = 1, max_len = 80)]
	pub name: String,
	#[db(min_len = 1, max_len = 64)]
	pub slug: String,
	#[db(max_len = 512)]
	pub webhook_url: Option<String>,
	/// HMAC-SHA256 signing secret for outbound webhooks (never returned after create/rotate).
	#[db(private, min_len = 1, max_len = 128)]
	pub webhook_secret: String,
	pub active: bool,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}

/// Hashed partner API key (`vk_...`). Only the prefix and SHA-256 hash are stored.
#[table(name = "verily_app_keys", unique(key_hash), index(app_id))]
pub struct VerilyAppKeyRow {
	pub id: Id<VerilyAppKeyRow>,
	#[db(on_delete = cascade)]
	pub app_id: Id<VerilyAppRow>,
	#[db(min_len = 1, max_len = 24)]
	pub key_prefix: String,
	#[db(private, min_len = 1, max_len = 64)]
	pub key_hash: String,
	pub revoked_at: Option<Timestamp>,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Allowlisted OAuth/deep-link redirect URI for a partner app.
#[table(name = "verily_app_redirect_uris", index(app_id))]
pub struct VerilyAppRedirectUriRow {
	pub id: Id<VerilyAppRedirectUriRow>,
	#[db(on_delete = cascade)]
	pub app_id: Id<VerilyAppRow>,
	#[db(min_len = 1, max_len = 512)]
	pub uri: String,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Durable link between a Verily account and an external partner user id.
#[table(name = "verily_app_links", index(app_id), index(account_id))]
pub struct VerilyAppLinkRow {
	pub id: Id<VerilyAppLinkRow>,
	#[db(on_delete = cascade)]
	pub app_id: Id<VerilyAppRow>,
	#[db(on_delete = cascade)]
	pub account_id: Id<AuthAccount>,
	#[db(min_len = 1, max_len = 128)]
	pub external_user_id: String,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Single-use short-lived code exchanged at `POST /api/v1/links/exchange`.
#[table(name = "verily_app_link_codes", unique(code_hash), index(app_id))]
pub struct VerilyAppLinkCodeRow {
	pub id: Id<VerilyAppLinkCodeRow>,
	#[db(on_delete = cascade)]
	pub app_id: Id<VerilyAppRow>,
	#[db(on_delete = cascade)]
	pub account_id: Id<AuthAccount>,
	#[db(private, min_len = 1, max_len = 64)]
	pub code_hash: String,
	#[db(min_len = 1, max_len = 512)]
	pub redirect_uri: String,
	pub expires_at: Timestamp,
	pub exchanged_at: Option<Timestamp>,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Partner-posted confirmation that an external requirement was met.
#[table(name = "verily_app_confirmations", index(app_id), index(action_id))]
pub struct VerilyAppConfirmationRow {
	pub id: Id<VerilyAppConfirmationRow>,
	#[db(on_delete = cascade)]
	pub app_id: Id<VerilyAppRow>,
	#[db(on_delete = cascade)]
	pub action_id: Id<ActionRow>,
	#[db(min_len = 1, max_len = 128)]
	pub external_user_id: String,
	#[db(min_len = 1, max_len = 128)]
	pub idempotency_key: String,
	pub verified: bool,
	#[db(created_at)]
	pub created_at: Timestamp,
}

/// Outbound pull-check job querying a partner endpoint for an attempt requirement.
#[table(name = "verily_app_pull_checks", index(attempt_id), index(status))]
pub struct VerilyAppPullCheckRow {
	pub id: Id<VerilyAppPullCheckRow>,
	#[db(on_delete = cascade)]
	pub app_id: Id<VerilyAppRow>,
	#[db(on_delete = cascade)]
	pub attempt_id: Id<Attempt>,
	#[db(min_len = 1, max_len = 64)]
	pub requirement_id: String,
	#[db(
		one_of("pending", "verified", "rejected", "failed"),
		default = "pending"
	)]
	pub status: String,
	pub attempts: i64,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}

/// Partner webhook event and delivery attempt tracking.
#[table(name = "verily_app_webhook_deliveries", index(app_id), index(status))]
pub struct VerilyAppWebhookDeliveryRow {
	pub id: Id<VerilyAppWebhookDeliveryRow>,
	#[db(on_delete = cascade)]
	pub app_id: Id<VerilyAppRow>,
	#[db(min_len = 1, max_len = 64)]
	pub event_type: String,
	#[db(private)]
	pub payload_json: String,
	#[db(one_of("pending", "delivered", "failed"), default = "pending")]
	pub status: String,
	pub attempts: i64,
	pub last_status_code: Option<i64>,
	pub next_attempt_at: Timestamp,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}

/// Partner-initiated verification request opened by a user at `/r/:request`.
#[table(name = "verification_requests", index(app_id), index(status))]
pub struct VerificationRequestRow {
	pub id: Id<VerificationRequestRow>,
	#[db(on_delete = cascade)]
	pub app_id: Id<VerilyAppRow>,
	#[db(on_delete = cascade)]
	pub action_id: Id<ActionRow>,
	pub participant_id: Option<Id<AuthAccount>>,
	pub attempt_id: Option<Id<Attempt>>,
	#[db(max_len = 128)]
	pub external_subject: Option<String>,
	#[db(max_len = 512)]
	pub callback_url: Option<String>,
	#[db(
		one_of("open", "in_progress", "verified", "rejected", "expired", "cancelled"),
		default = "open"
	)]
	pub status: String,
	#[db(private)]
	pub receipt_jws: Option<String>,
	pub expires_at: Timestamp,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}
