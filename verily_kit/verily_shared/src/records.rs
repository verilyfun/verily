//! Domain records for actions, attempts, evidence, rewards, and accounts.
//!
//! Field names match the existing product records (`camelCase` in JSON).
//! Nothing here is an escrow account, a payout index, a secret, or a
//! transport. A signature does not fund a pool.
#![allow(missing_docs)]

use chrono::DateTime;
use chrono::Utc;
use serde::Deserialize;
use serde::Serialize;
use uuid::Uuid;

/// An instant in UTC.
pub type Timestamp = DateTime<Utc>;

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ActionRecurrence {
	Once,
	Daily,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ActionDefinitionStatus {
	Draft,
	Active,
	Paused,
	Completed,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ActionRequirementKind {
	Video,
	Photo,
	Audio,
	Location,
	QrCode,
	Motion,
	ExternalApp,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ActionVerificationPolicy {
	SingleModel,
	ModelCouncil,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ActionMovementKind {
	Squats,
	PressUps,
	SitUps,
	Lunges,
	StarJumps,
	Burpees,
	HighKnees,
	LateralRaises,
	BicepsCurls,
	SideBends,
	FootballKickUps,
	TableTennisBounces,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ActionMotionType {
	PhoneToss,
	Rotation,
	Shake,
	Stillness,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ActionMotionAxis {
	Yaw,
	Pitch,
	Roll,
	Any,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum AppVerificationMode {
	Push,
	Pull,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum LocalCheckTask {
	Gesture,
	Object,
	Sound,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ActionAttemptStatus {
	CollectingEvidence,
	Verifying,
	PendingReview,
	Verified,
	Rejected,
	CapacityReached,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ActionAuthoringProblem {
	ActionKeyTaken,
	AppUnavailable,
	ExternalProofMixed,
	RewardNeedsDraft,
	RewardNotFunded,
	RewardTermsLocked,
	InvalidRequest,
	UnsafeText,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum MissingResource {
	Action,
	App,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum RewardCluster {
	Devnet,
	Mainnet,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum RewardPoolStatus {
	Draft,
	AwaitingFunding,
	Funded,
	Ended,
	Closed,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum RewardPayoutStatus {
	Reserved,
	AwaitingWallet,
	HeldForReview,
	Releasing,
	Released,
	Failed,
	Expired,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum RewardOutcome {
	Won,
	PoolEmpty,
	AccountLimitReached,
	PoolEnded,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum RewardProblem {
	RewardsUnavailable,
	PoolNotFound,
	PayoutWalletRequired,
	PoolNotAwaitingFunding,
	EscrowNotFound,
	EscrowMismatch,
	PoolEnded,
}

/// What a local check looks for. The label and thresholds come from the server.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionLocalCheck {
	pub task: LocalCheckTask,
	pub label: String,
	pub min_score: f64,
	pub min_frames: i64,
}

/// The pinned model the phone downloads before a local check.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LocalCheckModelView {
	pub model_id: String,
	pub url: String,
	pub byte_length: i64,
	pub sha256: String,
}

/// One proof the creator is asking for, on a create or save.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionRequirementDraft {
	pub requirement_key: String,
	pub kind: ActionRequirementKind,
	pub title: String,
	pub instructions: String,
	pub is_required: bool,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub latitude: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub longitude: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub radius_meters: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_accuracy_meters: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub verification_prompt: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_duration_seconds: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_duration_seconds: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_confidence: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub verification_policy: Option<ActionVerificationPolicy>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub spoken_challenge_required: Option<bool>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub movement_kind: Option<ActionMovementKind>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub motion_type: Option<ActionMotionType>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub motion_axis: Option<ActionMotionAxis>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub target_repetitions: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_angular_speed_radians_per_second: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_angular_speed_radians_per_second: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_axis_dominance: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_free_fall_milliseconds: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_free_fall_milliseconds: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_peak_acceleration_meters_per_second_squared: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_peak_acceleration_meters_per_second_squared: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub qr_code: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub app_id: Option<Uuid>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub app_verification_mode: Option<AppVerificationMode>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub local_check: Option<ActionLocalCheck>,
}

impl ActionRequirementDraft {
	pub fn new(
		requirement_key: impl Into<String>,
		kind: ActionRequirementKind,
		title: impl Into<String>,
		instructions: impl Into<String>,
		is_required: bool,
	) -> Self {
		Self {
			requirement_key: requirement_key.into(),
			kind,
			title: title.into(),
			instructions: instructions.into(),
			is_required,
			latitude: None,
			longitude: None,
			radius_meters: None,
			max_accuracy_meters: None,
			verification_prompt: None,
			min_duration_seconds: None,
			max_duration_seconds: None,
			min_confidence: None,
			verification_policy: None,
			spoken_challenge_required: None,
			movement_kind: None,
			motion_type: None,
			motion_axis: None,
			target_repetitions: None,
			min_angular_speed_radians_per_second: None,
			max_angular_speed_radians_per_second: None,
			min_axis_dominance: None,
			min_free_fall_milliseconds: None,
			max_free_fall_milliseconds: None,
			min_peak_acceleration_meters_per_second_squared: None,
			max_peak_acceleration_meters_per_second_squared: None,
			qr_code: None,
			app_id: None,
			app_verification_mode: None,
			local_check: None,
		}
	}
}

/// The creator's reward terms. The token, decimals, cluster, and arbiter
/// come from the server, never from this draft.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RewardTermsDraft {
	pub amount_per_payout: i64,
	pub max_payouts: i64,
	#[serde(default = "one")]
	pub max_wins_per_account: i64,
	pub expires_at: Timestamp,
	#[serde(default = "seven_days")]
	pub refund_delay_days: i64,
}

/// Create or save a draft. An optional [`RewardTermsDraft`] is stored by
/// the server and stays editable only until funding starts.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateActionDefinitionRequest {
	pub action_key: String,
	pub title: String,
	pub description: String,
	pub recurrence: ActionRecurrence,
	pub time_zone: String,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_verified_completions: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub opens_at: Option<Timestamp>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub closes_at: Option<Timestamp>,
	pub requirements: Vec<ActionRequirementDraft>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub reward: Option<RewardTermsDraft>,
}

/// A value-free starting point from the server's template list.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionTemplate {
	pub template_key: String,
	pub title: String,
	pub description: String,
	pub suggested_recurrence: ActionRecurrence,
	pub requirements: Vec<ActionRequirementDraft>,
}

/// An AI draft. It never carries a reward: money terms are the creator's.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionDraftProposal {
	pub action: CreateActionDefinitionRequest,
	pub safety_notes: Vec<String>,
	pub assumptions: Vec<String>,
}

/// One proof as a participant or the creator sees it.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionRequirementView {
	pub id: Uuid,
	pub requirement_key: String,
	pub kind: ActionRequirementKind,
	pub title: String,
	pub instructions: String,
	pub position: i64,
	pub is_required: bool,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub latitude: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub longitude: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub radius_meters: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_accuracy_meters: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_duration_seconds: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_duration_seconds: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub verification_policy: Option<ActionVerificationPolicy>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub verification_prompt: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_confidence: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub venue_code_configured: Option<bool>,
	#[serde(default)]
	pub spoken_challenge_required: bool,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub accepted_content_types: Option<Vec<String>>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_byte_length: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub movement_kind: Option<ActionMovementKind>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub motion_type: Option<ActionMotionType>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub motion_axis: Option<ActionMotionAxis>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub target_repetitions: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_angular_speed_radians_per_second: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_angular_speed_radians_per_second: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_axis_dominance: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_free_fall_milliseconds: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_free_fall_milliseconds: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub min_peak_acceleration_meters_per_second_squared: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_peak_acceleration_meters_per_second_squared: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub app_id: Option<Uuid>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub app_name: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub app_available: Option<bool>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub app_verification_mode: Option<AppVerificationMode>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub local_check: Option<ActionLocalCheck>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub local_check_model: Option<LocalCheckModelView>,
}

/// The caller's attempt, when the action view includes one.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionAttemptView {
	pub id: Uuid,
	pub action_definition_id: Uuid,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub action_title: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub action_key: Option<String>,
	pub period_key: String,
	pub status: ActionAttemptStatus,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub verification_score: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub verified_rank: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub rejection_code: Option<String>,
	pub started_at: Timestamp,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub submitted_at: Option<Timestamp>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub verified_at: Option<Timestamp>,
	pub updated_at: Timestamp,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub reward_outcome: Option<RewardOutcome>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub payout_status: Option<RewardPayoutStatus>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub accepted_requirement_ids: Option<Vec<Uuid>>,
	#[serde(default)]
	pub reward_value_review: bool,
}

/// Public facts about an action's reward. Unfunded drafts are omitted for
/// everyone but the creator, which the server decides.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RewardSummary {
	pub cluster: RewardCluster,
	pub mint: String,
	pub token_symbol: String,
	pub decimals: i64,
	pub amount_per_payout: i64,
	pub max_payouts: i64,
	pub payouts_remaining: i64,
	pub max_wins_per_account: i64,
	pub my_wins: i64,
	pub status: RewardPoolStatus,
	pub expires_at: Timestamp,
	#[serde(default = "seven_days")]
	pub refund_delay_days: i64,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub escrow_address: Option<String>,
}

/// One action, for a creator's list or a participant's page.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionOpportunity {
	pub id: Uuid,
	pub creator_display_name: String,
	pub viewer_is_creator: bool,
	pub action_key: String,
	pub revision: i64,
	pub status: ActionDefinitionStatus,
	pub title: String,
	pub description: String,
	pub recurrence: ActionRecurrence,
	pub time_zone: String,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub max_verified_completions: Option<i64>,
	pub verified_completions: i64,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub opens_at: Option<Timestamp>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub closes_at: Option<Timestamp>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub published_at: Option<Timestamp>,
	pub updated_at: Timestamp,
	pub requirements: Vec<ActionRequirementView>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub my_attempt: Option<ActionAttemptView>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub reward: Option<RewardSummary>,
}

/// A short-lived, single-use venue code. The server mints it.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionQrChallengeView {
	pub code: String,
	pub expires_at: Timestamp,
}

/// The creator's view of one action's reward pool.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RewardPoolView {
	pub pool_id: Uuid,
	pub status: RewardPoolStatus,
	pub cluster: RewardCluster,
	pub mint: String,
	pub token_symbol: String,
	pub decimals: i64,
	pub amount_per_payout: i64,
	pub max_payouts: i64,
	pub max_wins_per_account: i64,
	pub payouts_reserved: i64,
	pub payouts_released: i64,
	pub expires_at: Timestamp,
	pub refund_after: Timestamp,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub creator_wallet: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub escrow_address: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub funding_signature: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub funded_at: Option<Timestamp>,
}

impl RewardPoolView {
	/// Whether the server has verified the escrow from chain state.
	///
	/// `funded`, `ended`, and `closed` are the statuses the server sets
	/// only after that read. A stored signature is not a substitute: the
	/// server keeps it for audit after the read succeeds.
	#[must_use]
	pub fn escrow_verified(&self) -> bool {
		matches!(
			self.status,
			RewardPoolStatus::Funded | RewardPoolStatus::Ended | RewardPoolStatus::Closed
		)
	}
}

/// The unsigned `OpenEscrow` transaction the creator's wallet signs.
///
/// Receiving this plan does not fund the reward. The wallet sends the
/// transaction itself, then `confirmRewardFunding` asks the server to read
/// the escrow. The pool view that comes back is the only funding result.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RewardFundingPlan {
	pub pool_id: Uuid,
	pub cluster: RewardCluster,
	pub escrow_address: String,
	pub creator_wallet: String,
	pub arbiter_address: String,
	pub mint: String,
	pub token_symbol: String,
	pub decimals: i64,
	pub total_atoms: i64,
	pub expires_at: Timestamp,
	pub refund_after: Timestamp,
	pub unsigned_transaction: String,
}

/// The unsigned `EndEarly` transaction. The server has already stopped
/// reserving new payouts; the wallet moves the on-chain expiry to match.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RewardEndPlan {
	pub pool_id: Uuid,
	pub expires_at: Timestamp,
	pub refund_after: Timestamp,
	pub unsigned_transaction: String,
}

/// One of the caller's payouts, as the server recorded it.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RewardPayoutView {
	pub id: Uuid,
	pub attempt_id: Uuid,
	pub action_title: String,
	pub cluster: RewardCluster,
	pub token_symbol: String,
	pub decimals: i64,
	pub amount: i64,
	pub status: RewardPayoutStatus,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub recipient_wallet: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub release_signature: Option<String>,
	pub created_at: Timestamp,
	pub updated_at: Timestamp,
	pub payable_until: Timestamp,
}

/// The wallet the account is paid to and funds rewards from.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PayoutWalletView {
	pub wallet_address: String,
	pub label: String,
	pub linked_at: Timestamp,
}

/// The exact text the wallet must sign. Signing does not move funds and
/// does not fund an escrow.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PayoutWalletLinkChallengeView {
	pub wallet_address: String,
	pub message: String,
	pub nonce: String,
	pub expires_at: Timestamp,
}

/// Where an action may appear. A verification request is private and has no reward.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ActionVisibility {
	Public,
	VerificationRequest,
}

/// The strongest capture provenance the server verified. App Attest never
/// claims a verified boot.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum EvidenceProvenanceLevel {
	#[default]
	Basic,
	AppAttested,
	DeviceSigned,
	SecureEnclaveAttested,
	HardwareAttested,
}

/// A decision on one proof. A model vote is not this value, and it does not
/// release a reward.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum EvidenceDecisionStatus {
	Accepted,
	Rejected,
	ManualReview,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum EvidenceAppealStatus {
	Pending,
	Accepted,
	Rejected,
}

/// One bounded motion sample. The server recomputes the trace digest.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionMotionSample {
	pub elapsed_microseconds: i64,
	pub gyroscope_x: f64,
	pub gyroscope_y: f64,
	pub gyroscope_z: f64,
	pub acceleration_x: f64,
	pub acceleration_y: f64,
	pub acceleration_z: f64,
}

/// The phone's local-check result. Advisory only: it never decides the proof.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceLocalCheckResult {
	pub model_id: String,
	pub model_sha256: String,
	pub label: String,
	pub score: f64,
	pub matched_frames: i64,
}

/// Location, venue code, or motion submitted directly. Media never uses this path.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionEvidenceInput {
	pub attempt_id: Uuid,
	pub requirement_id: Uuid,
	pub captured_at: Timestamp,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub latitude: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub longitude: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub accuracy_meters: Option<f64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub qr_code: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub motion_samples: Option<Vec<ActionMotionSample>>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_challenge_id: Option<Uuid>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub device_integrity_token: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_manifest: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_signature: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_certificate_chain: Option<Vec<String>>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_app_attest_key_id: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_device_check_token: Option<String>,
}

/// What the app reports after a private upload. The server remeasures the bytes.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MediaUploadConfirmation {
	pub attempt_id: Uuid,
	pub requirement_id: Uuid,
	pub content_type: String,
	pub byte_length: i64,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub duration_seconds: Option<i64>,
	pub captured_at: Timestamp,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub device_repetition_count: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub device_tracker_version: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub device_local_check: Option<DeviceLocalCheckResult>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_challenge_id: Option<Uuid>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub device_integrity_token: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_manifest: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_signature: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_certificate_chain: Option<Vec<String>>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_app_attest_key_id: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub capture_device_check_token: Option<String>,
}

/// The result of submitting one proof. `confidence` is not shown as truth.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EvidenceSubmissionResult {
	pub attempt: ActionAttemptView,
	pub requirement_id: Uuid,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub status: Option<EvidenceDecisionStatus>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub confidence: Option<f64>,
	pub reason_code: String,
	pub summary: String,
	#[serde(default)]
	pub provenance_level: EvidenceProvenanceLevel,
}

/// Opens a capture window before the camera, microphone, or sensors start.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionCaptureChallengeView {
	pub id: Uuid,
	pub capture_challenge: String,
	pub issued_at: Timestamp,
	pub expires_at: Timestamp,
	pub integrity_required: bool,
	#[serde(default)]
	pub signature_required: bool,
}

/// The live word the server issued. A creator does not choose it.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActionSpokenChallengeView {
	pub id: Uuid,
	pub word: String,
	pub expires_at: Timestamp,
}

/// What a reviewer sees when a payout needs a person.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PayoutReviewView {
	pub amount_per_payout: i64,
	pub token_symbol: String,
	pub decimals: i64,
	pub threshold_atoms: i64,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EvidenceReviewQueueItem {
	pub evidence_id: Uuid,
	pub attempt_id: Uuid,
	pub action_definition_id: Uuid,
	pub creator_display_name: String,
	pub action_title: String,
	pub requirement_title: String,
	pub requirement_kind: ActionRequirementKind,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub mime_type: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub byte_length: Option<i64>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub duration_seconds: Option<i64>,
	pub captured_at: Timestamp,
	pub submitted_at: Timestamp,
	pub review_reason_code: String,
	pub review_summary: String,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub media_url: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub spoken_challenge_word: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub payout_review: Option<PayoutReviewView>,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EvidenceAppealView {
	pub id: Uuid,
	pub evidence_id: Uuid,
	pub attempt_id: Uuid,
	pub action_title: String,
	pub requirement_title: String,
	pub requirement_kind: ActionRequirementKind,
	pub reason: String,
	pub status: EvidenceAppealStatus,
	pub created_at: Timestamp,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub resolution_note: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub resolved_at: Option<Timestamp>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub media_url: Option<String>,
	#[serde(default, skip_serializing_if = "Option::is_none")]
	pub spoken_challenge_word: Option<String>,
}

/// The challenge an iPhone attests its registered App Attest key against.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AppAttestChallengeView {
	pub id: Uuid,
	pub challenge: String,
	pub expires_at: Timestamp,
}

/// Staff-facing device restrictions. Raw DeviceCheck tokens are never stored.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceCheckBits {
	pub banned: bool,
	pub review_required: bool,
}

/// A payout above the review threshold needs a person. Missing configuration
/// fails closed: it does not become an automatic release.
#[must_use]
pub fn payout_needs_person(amount_atoms: i64, threshold_atoms: Option<i64>) -> Option<bool> {
	let threshold = threshold_atoms?;
	if amount_atoms < 0 || threshold < 0 {
		return None;
	}
	Some(amount_atoms > threshold)
}

const fn one() -> i64 {
	1
}

const fn seven_days() -> i64 {
	7
}
