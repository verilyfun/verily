//! Domain records shared by the Verily app, backend, verification, and rewards.
//!
//! Crypto appears only as the unit a reward is paid in. There are no NFTs,
//! projects, token launches, trading pairs, or achievements stored as assets.
//! A model verdict does not release a reward, and a watermark is not proof a
//! scene is real. This crate holds no secrets and no transport.

#![deny(unsafe_code)]

pub mod account;
pub mod evidence;
pub mod id;
pub mod records;

pub use account::{Account, AccountClosure, AccountClosureStatus};
pub use evidence::{
	CAPTURE_MANIFEST_DOMAIN, CAPTURE_REQUEST_DOMAIN, CaptureChallenge, EVIDENCE_BINDING_DOMAIN,
	EvidenceBinding, EvidenceError, MediaEvidenceKind, app_attest_assertion_client_data_hash,
	app_attest_device_client_data, app_attest_registration_client_data_hash,
	capture_integrity_request_hash, capture_integrity_request_nonce,
	capture_key_attestation_challenge, capture_provenance_manifest, capture_public_key_id,
	location_evidence_binding_hash, media_evidence_binding_hash, motion_evidence_binding_hash,
	normalize_capture_challenge, normalize_evidence_binding_hash, qr_evidence_binding_hash,
	sha256_hex,
};
pub use id::{AccountId, ActionId, AttemptId, EvidenceId, PayoutId, PoolId, RequirementId};
pub use records::{
	ActionAttemptStatus, ActionAttemptView, ActionAuthoringProblem, ActionCaptureChallengeView,
	ActionDefinitionStatus, ActionDraftProposal, ActionEvidenceInput, ActionLocalCheck,
	ActionMotionAxis, ActionMotionSample, ActionMotionType, ActionMovementKind, ActionOpportunity,
	ActionQrChallengeView, ActionRecurrence, ActionRequirementDraft, ActionRequirementKind,
	ActionRequirementView, ActionSpokenChallengeView, ActionTemplate, ActionVerificationPolicy,
	ActionVisibility, AppAttestChallengeView, AppVerificationMode, CreateActionDefinitionRequest,
	DeviceCheckBits, DeviceLocalCheckResult, EvidenceAppealStatus, EvidenceAppealView,
	EvidenceDecisionStatus, EvidenceProvenanceLevel, EvidenceReviewQueueItem,
	EvidenceSubmissionResult, LocalCheckModelView, LocalCheckTask, MediaUploadConfirmation,
	MissingResource, PayoutReviewView, PayoutWalletLinkChallengeView, PayoutWalletView,
	RewardCluster, RewardEndPlan, RewardFundingPlan, RewardOutcome, RewardPayoutStatus,
	RewardPayoutView, RewardPoolStatus, RewardPoolView, RewardProblem, RewardSummary,
	RewardTermsDraft, Timestamp, payout_needs_person,
};
