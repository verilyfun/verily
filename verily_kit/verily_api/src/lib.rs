//! Records `verily_app`'s screens send to `verily_backend` and get back.
//!
//! The app declares each operation; `verily_backend` serves it. Both name
//! these types, so they live below both. Public place rows carry a name and a
//! radius. They do not carry precise coordinates. Wallet state is whether a
//! payout destination is linked, never an address or a key. Review rows name
//! what a person should look at. They do not carry a model name, a score, or
//! a storage path.

use schemars::JsonSchema;
use serde::Deserialize;
use serde::Serialize;

/// Which catalogue a person is browsing.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum ActionFilter {
	All,
	Nearby,
	Place,
	Movement,
	VenueCode,
	Apps,
}

impl ActionFilter {
	/// The filter the Do screen opens on.
	#[must_use]
	pub const fn all() -> Self {
		Self::All
	}
}

/// One live action in the catalogue.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ActionCard {
	pub id: String,
	pub title: String,
	pub creator: String,
	pub place_name: String,
	/// Radius in metres. Zero means the action is not tied to a circle on a map.
	pub radius_meters: i64,
	pub proof_count: i64,
	pub reward_label: String,
}

/// A live action opened from the catalogue.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ActionDetail {
	pub id: String,
	pub title: String,
	pub summary: String,
	pub creator: String,
	pub place_name: String,
	pub radius_meters: i64,
	pub proofs: Vec<ProofNeed>,
	pub reward_label: String,
	/// The action pays a reward. Without one there is nothing to fund.
	pub rewarded: bool,
	pub funded: bool,
	#[serde(default)]
	pub paused: bool,
}

/// One proof the action asks for.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ProofNeed {
	pub id: String,
	pub kind: ProofKind,
	pub title: String,
	/// Fresh capture. The screen opens the shell plugin and never a library.
	pub live: bool,
}

/// Kinds of proof an action can ask for.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum ProofKind {
	Photo,
	Video,
	Audio,
	Note,
	Presence,
	Movement,
	VenueCode,
	App,
}

impl ProofKind {
	/// Photo, video, audio, presence, movement, and a venue code are captured
	/// live. A note is typed. An app confirmation is not a camera roll.
	#[must_use]
	pub const fn needs_live_capture(self) -> bool {
		matches!(
			self,
			Self::Photo
				| Self::Video
				| Self::Audio
				| Self::Presence
				| Self::Movement
				| Self::VenueCode
		)
	}
}

/// An attempt on the Me list.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct AttemptRow {
	pub id: String,
	pub action_title: String,
	pub status: AttemptStatus,
	/// Server-owned eligibility and the outcome of any existing appeal.
	#[serde(default)]
	pub appeal: AppealStatus,
}

/// An attempt's appeal, as the server permits it. Missing data fails closed.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum AppealStatus {
	#[default]
	Unavailable,
	Available,
	Pending,
	Accepted,
	Rejected,
}

/// The shared limit for a participant's appeal, counted in characters.
pub const MAX_APPEAL_REASON_CHARS: usize = 1000;

/// Whether an appeal contains a bounded, nonblank explanation.
#[must_use]
pub fn valid_appeal_reason(reason: &str) -> bool {
	let reason = reason.trim();
	!reason.is_empty()
		&& reason.chars().count() <= MAX_APPEAL_REASON_CHARS
		&& !reason
			.chars()
			.any(|c| c.is_control() && c != '\n' && c != '\t')
}

/// What the server says about an attempt. The words on screen come from translations.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum AttemptStatus {
	CollectingEvidence,
	Verifying,
	PendingReview,
	Verified,
	Rejected,
	CapacityReached,
}

/// A payout row. Amounts are display text the server formatted.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct PayoutRow {
	pub id: String,
	pub action_title: String,
	pub amount_label: String,
	pub status: PayoutStatus,
}

/// Payout state. The screen never invents a successful release.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum PayoutStatus {
	AwaitingWallet,
	OnItsWay,
	Released,
	HeldForReview,
	Failed,
	Expired,
}

/// Whether a payout destination is linked. No address, key, or signature.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct WalletLink {
	pub linked: bool,
}

/// The text a payout wallet signs. Signing does not move funds and does not
/// fund an escrow. The text names the address; this record has no key.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct WalletChallenge {
	pub message: String,
}

/// One item in the review queue.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ReviewRow {
	pub id: String,
	pub creator: String,
	pub requirement: String,
	pub kind: ProofKind,
	/// Server-owned reason key, shown with a translated sentence.
	pub needs_person: bool,
	/// Short-lived version-pinned URL minted by the server for reviewers only.
	#[serde(default)]
	pub media_review_url: Option<String>,
}

/// A creator's draft or live action.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct DraftRow {
	pub id: String,
	pub title: String,
	/// The draft pays a reward, so it must be funded before it goes live.
	pub rewarded: bool,
	pub funded: bool,
	pub live: bool,
	#[serde(default)]
	pub paused: bool,
}

/// What the editor saves. Public views never expose exact coordinates.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct DraftInput {
	pub id: Option<String>,
	pub title: String,
	pub summary: String,
	pub place_name: String,
	pub radius_meters: i64,
	pub reward_amount: String,
	pub proofs: Vec<ProofKind>,
	#[serde(default)]
	pub latitude: Option<f64>,
	#[serde(default)]
	pub longitude: Option<f64>,
}

impl DraftInput {
	/// A blank draft the editor starts from.
	#[must_use]
	pub fn blank() -> Self {
		Self {
			id: None,
			title: String::new(),
			summary: String::new(),
			place_name: String::new(),
			radius_meters: 100,
			reward_amount: String::new(),
			proofs: vec![ProofKind::Photo],
			latitude: None,
			longitude: None,
		}
	}

	/// A title and a place name are the minimum the editor will send.
	#[must_use]
	pub fn ready_to_save(&self) -> bool {
		!self.title.trim().is_empty() && !self.place_name.trim().is_empty()
	}
}

/// The server's answer after a save.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct DraftSaved {
	pub id: String,
}

/// Publish is live only when the server says the escrow was funded on chain.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct PublishOutcome {
	pub published: bool,
	/// The action pays a reward, so `funded` decides whether it is live.
	pub rewarded: bool,
	pub funded: bool,
}

impl PublishOutcome {
	/// The screen may say the action is live only when it published and, if
	/// it pays a reward, the escrow was verified from chain state.
	#[must_use]
	pub const fn is_live(&self) -> bool {
		self.published && (self.funded || !self.rewarded)
	}
}

/// An attempt the server opened.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct AttemptOpened {
	pub attempt_id: String,
	pub requirement_id: String,
}

/// The capture window `beginCapture` returns. `challenge` binds the signature.
/// The screen shows `spoken_word` and does not show `challenge`.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct CaptureWindow {
	pub attempt_id: String,
	pub requirement_id: String,
	pub challenge: String,
	pub spoken_word: Option<String>,
	/// Which sensor may open. A library is not one of them.
	pub kind: ProofKind,
}

/// The spoken word for this window, from the server's list.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct SpokenWord {
	pub word: String,
}

/// The server's receipt for a submitted digest.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ProofReceipt {
	pub digest_hex: String,
	pub stored: bool,
}

/// Attestation the shell produced for the digest the server stored.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct AttestationReceipt {
	pub bound: bool,
}

/// The server's decision on the finished attempt.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct AttemptOutcome {
	pub status: AttemptStatus,
}

/// A review decision the server stored.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ReviewDecision {
	pub saved: bool,
}

/// An appeal the server stored.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct AppealReceipt {
	pub id: String,
}

/// One built-in starter template in the creator catalogue.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ActionTemplateItem {
	pub id: String,
	pub title: String,
	pub summary: String,
	pub category: String,
	pub place_name: String,
	pub radius_meters: i64,
	pub proofs: Vec<ProofKind>,
}

/// Structured draft returned from AI authoring (never carries rewards).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct ActionDraftSuggestion {
	pub draft: DraftInput,
	pub safety_notes: Vec<String>,
	pub assumptions: Vec<String>,
}

/// A short-lived QR venue challenge issued to the action's creator.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct QrChallengeView {
	pub code: String,
	pub expires_at_unix: i64,
}

/// Presigned private upload target returned by `request_media_upload`.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct MediaUploadPlan {
	pub reservation_id: String,
	pub object_key: String,
	pub upload_url: String,
	pub headers: Vec<(String, String)>,
	pub expires_at_unix: i64,
}

/// Immutable storage seal returned by `confirm_media_upload`.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct MediaUploadConfirmed {
	pub reservation_id: String,
	pub version_id: String,
	pub sha256_hex: String,
	pub byte_length: u64,
}

/// One-time App Attest registration challenge for an iPhone.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct AppAttestChallengeView {
	pub challenge_id: String,
	pub nonce: String,
}

/// Confirmation that an Apple App Attest key was verified and stored.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct AppAttestKeyRegistered {
	pub key_id: String,
	pub registered: bool,
}

/// Apple DeviceCheck durable two-bit state (operator / moderation only).
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct DeviceCheckBitsView {
	pub banned: bool,
	pub review_required: bool,
}

/// Creator reward pool summary.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct RewardPoolStatusView {
	pub pool_id: String,
	pub status: String,
	pub amount_label: String,
	pub max_payouts: i64,
	pub payouts_released: i64,
	pub escrow_address: Option<String>,
	pub funding_signature: Option<String>,
	pub funded: bool,
}

/// Chain funding parameters returned for wallet signing.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct FundingPlanView {
	pub pool_id: String,
	pub escrow_address: String,
	pub vault_address: String,
	pub mint: String,
	pub arbiter: String,
	pub amount_per_payout: i64,
	pub max_payouts: i64,
	pub expires_at_unix: i64,
	pub refund_delay_seconds: i64,
	#[serde(default)]
	pub unsigned_transaction: String,
}

/// An appeal visible to its participant or the reviewer queue.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct AppealItem {
	pub id: String,
	pub attempt_id: String,
	pub action_title: String,
	pub reason: String,
	pub status: AppealStatus,
	pub resolution_note: Option<String>,
}

/// Content report or moderation case row.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ModerationCaseRow {
	pub id: String,
	pub target_kind: String,
	pub target_id: String,
	pub reason: String,
	pub status: String,
	pub notes: Option<String>,
}

/// Partner integration app owned by a creator.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct VerilyAppRow {
	pub id: String,
	pub name: String,
	pub slug: String,
	pub webhook_url: Option<String>,
	pub active: bool,
	pub key_prefix: String,
	pub redirect_uris: Vec<String>,
}

/// Created partner app with one-time API key and webhook HMAC secret.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct VerilyAppCreated {
	pub app: VerilyAppRow,
	pub api_key_once: String,
	pub webhook_secret_once: String,
}

/// Newly rotated partner API key (shown once).
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct VerilyAppKeyRotated {
	pub key_id: String,
	pub api_key_once: String,
	pub key_prefix: String,
}

/// Webhook delivery audit row for a partner app.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct VerilyAppDeliveryRow {
	pub id: String,
	pub event_type: String,
	pub status: String,
	pub attempts: i64,
	pub last_status_code: Option<i64>,
}

/// Partner-initiated verification request shown at `/r/:request`.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct VerificationRequestView {
	pub id: String,
	pub app_name: String,
	pub action_id: String,
	pub action_title: String,
	pub status: String,
	pub expires_at_unix: i64,
	pub callback_url: Option<String>,
	pub receipt_jws: Option<String>,
}

/// Deep-link account linking authorization code issued at `/link`.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct AppLinkExchangeView {
	pub app_name: String,
	pub redirect_uri: String,
	pub code: String,
	pub state: Option<String>,
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn older_attempt_records_do_not_offer_an_appeal() {
		let row: AttemptRow = serde_json::from_value(serde_json::json!({
			"id": "attempt", "action_title": "Visit the market", "status": "rejected"
		}))
		.unwrap();
		assert_eq!(row.appeal, AppealStatus::Unavailable);
	}

	#[test]
	fn appeal_reasons_are_bounded_by_characters_and_allow_paragraphs() {
		assert!(valid_appeal_reason(
			"  Please check the last ten seconds.\nThank you.  "
		));
		assert!(valid_appeal_reason(&"é".repeat(MAX_APPEAL_REASON_CHARS)));
		assert!(!valid_appeal_reason(
			&"é".repeat(MAX_APPEAL_REASON_CHARS + 1)
		));
		for reason in [
			"",
			" \n\t ",
			"please\0look",
			"please\rlook",
			"please\u{7f}look",
		] {
			assert!(!valid_appeal_reason(reason), "{reason:?}");
		}
	}
}
