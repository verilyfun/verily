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
	pub funded: bool,
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

/// One item in the review queue.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ReviewRow {
	pub id: String,
	pub creator: String,
	pub requirement: String,
	pub kind: ProofKind,
	/// Server-owned reason key, shown with a translated sentence.
	pub needs_person: bool,
}

/// A creator's draft or live action.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct DraftRow {
	pub id: String,
	pub title: String,
	pub funded: bool,
	pub live: bool,
}

/// What the editor saves. Coordinates stay off this record.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct DraftInput {
	pub id: Option<String>,
	pub title: String,
	pub summary: String,
	pub place_name: String,
	pub radius_meters: i64,
	pub reward_amount: String,
	pub proofs: Vec<ProofKind>,
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
	pub funded: bool,
}

impl PublishOutcome {
	/// The screen may say the action is live only when both are true.
	#[must_use]
	pub const fn is_live(&self) -> bool {
		self.published && self.funded
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
