//! Typed operations the screens send to `verily_backend`.
//!
//! Each function is an `#[rpc::query]` or `#[rpc::mutation]` whose service is
//! `verily-backend`. The screen builds the argument struct and
//! `leptoskit_rpc` posts it to `/_leptoskit/services/verily-backend/api/<name>`
//! on the app's origin. Only a build with this crate's `service` feature, the
//! server's, keeps the bodies, and each body is one call into
//! `verily_backend::serve`, which owns the rules. There is no Serverpod client
//! here.

use crate::model::ActionCard;
use crate::model::ActionDetail;
use crate::model::ActionDraftSuggestion;
use crate::model::ActionFilter;
use crate::model::ActionTemplateItem;
use crate::model::AppAttestChallengeView;
use crate::model::AppAttestKeyRegistered;
use crate::model::AppLinkExchangeView;
use crate::model::AppealItem;
use crate::model::AppealReceipt;
use crate::model::AttemptOpened;
use crate::model::AttemptOutcome;
use crate::model::AttemptRow;
use crate::model::AttestationReceipt;
use crate::model::CaptureWindow;
use crate::model::DeviceCheckBitsView;
use crate::model::DraftInput;
use crate::model::DraftRow;
use crate::model::DraftSaved;
use crate::model::FundingPlanView;
use crate::model::MediaUploadConfirmed;
use crate::model::MediaUploadPlan;
use crate::model::ModerationCaseRow;
use crate::model::PayoutRow;
use crate::model::ProofReceipt;
use crate::model::PublishOutcome;
use crate::model::QrChallengeView;
use crate::model::ReviewDecision;
use crate::model::ReviewRow;
use crate::model::RewardPoolStatusView;
use crate::model::SpokenWord;
use crate::model::VerificationRequestView;
use crate::model::VerilyAppCreated;
use crate::model::VerilyAppDeliveryRow;
use crate::model::VerilyAppKeyRotated;
use crate::model::VerilyAppRow;
use crate::model::WalletChallenge;
use crate::model::WalletLink;

/// Service name `verily_backend` is reached by. Lowercase, as the RPC client requires.
pub const BACKEND: &str = "verily-backend";

/// Live actions for the Do catalogue. Coordinates are an input to nearby
/// search. They are not part of [`ActionCard`].
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_available_actions(
	cx: &leptoskit::rpc::QueryCx,
	filter: ActionFilter,
	latitude: Option<f64>,
	longitude: Option<f64>,
) -> leptoskit::rpc::Result<Vec<ActionCard>> {
	verily_backend::serve::list_available_actions(cx, filter, latitude, longitude).await
}

/// One action, without precise coordinates.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn get_action(
	cx: &leptoskit::rpc::QueryCx,
	action_id: String,
) -> leptoskit::rpc::Result<ActionDetail> {
	verily_backend::serve::get_action(cx, action_id).await
}

/// Loads one of the creator's own actions into the editor.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn get_draft(
	cx: &leptoskit::rpc::QueryCx,
	action_id: String,
) -> leptoskit::rpc::Result<DraftInput> {
	verily_backend::serve::get_draft(cx, action_id).await
}

/// Twelve built-in starter templates creators can customize without AI keys.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_templates(
	_cx: &leptoskit::rpc::QueryCx,
) -> leptoskit::rpc::Result<Vec<ActionTemplateItem>> {
	Ok(verily_backend::serve::list_templates())
}

/// Generates an editable draft suggestion from a creator's plain-language idea.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn draft_action_from_prompt(
	cx: &leptoskit::rpc::MutationCx,
	prompt: String,
) -> leptoskit::rpc::Result<ActionDraftSuggestion> {
	verily_backend::serve::draft_action_from_prompt(cx, prompt).await
}

/// The signed-in person's attempts.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_my_attempts(
	cx: &leptoskit::rpc::QueryCx,
) -> leptoskit::rpc::Result<Vec<AttemptRow>> {
	verily_backend::serve::list_my_attempts(cx).await
}

/// The signed-in person's payouts.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_my_payouts(
	cx: &leptoskit::rpc::QueryCx,
) -> leptoskit::rpc::Result<Vec<PayoutRow>> {
	verily_backend::serve::list_my_payouts(cx).await
}

/// Whether a payout destination is linked.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn wallet_status(cx: &leptoskit::rpc::QueryCx) -> leptoskit::rpc::Result<WalletLink> {
	verily_backend::serve::wallet_status(cx).await
}

/// The text a payout wallet signs. Signing does not move funds.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn create_wallet_link_challenge(
	cx: &leptoskit::rpc::MutationCx,
	wallet_address: String,
) -> leptoskit::rpc::Result<WalletChallenge> {
	verily_backend::serve::create_wallet_link_challenge(cx, wallet_address).await
}

/// Links a payout wallet after the stored challenge signature verifies.
/// Linking does not release a payout.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn link_payout_wallet(
	cx: &leptoskit::rpc::MutationCx,
	wallet_address: String,
	signature: String,
) -> leptoskit::rpc::Result<WalletLink> {
	verily_backend::serve::link_payout_wallet(cx, wallet_address, signature).await
}

/// Proof a person still has to accept.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_review_queue(
	cx: &leptoskit::rpc::QueryCx,
) -> leptoskit::rpc::Result<Vec<ReviewRow>> {
	verily_backend::serve::list_review_queue(cx).await
}

/// The creator's drafts and live actions.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_my_actions(
	cx: &leptoskit::rpc::QueryCx,
) -> leptoskit::rpc::Result<Vec<DraftRow>> {
	verily_backend::serve::list_my_actions(cx).await
}

/// Pauses or resumes one of the creator's published actions.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn pause_action(
	cx: &leptoskit::rpc::MutationCx,
	action_id: String,
	paused: bool,
) -> leptoskit::rpc::Result<DraftRow> {
	verily_backend::serve::pause_action(cx, action_id, paused).await
}

/// The spoken word for this window, from the server's list.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn issue_spoken_challenge(
	cx: &leptoskit::rpc::QueryCx,
	attempt_id: String,
	requirement_id: String,
) -> leptoskit::rpc::Result<SpokenWord> {
	verily_backend::serve::issue_spoken_challenge(cx, attempt_id, requirement_id).await
}

/// Opens an attempt. The capture screen uses the returned ids.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn begin_attempt(
	cx: &leptoskit::rpc::MutationCx,
	action_id: String,
) -> leptoskit::rpc::Result<AttemptOpened> {
	verily_backend::serve::begin_attempt(cx, action_id).await
}

/// Starts the capture window. The plugin opens only after this returns.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn begin_capture(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
) -> leptoskit::rpc::Result<CaptureWindow> {
	verily_backend::serve::begin_capture(cx, attempt_id, requirement_id).await
}

/// Reserves a short-lived private media upload URL for this capture window.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn request_media_upload(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	mime_type: String,
	byte_length: i64,
) -> leptoskit::rpc::Result<MediaUploadPlan> {
	verily_backend::serve::request_media_upload(
		cx,
		attempt_id,
		requirement_id,
		mime_type,
		byte_length,
	)
	.await
}

/// Confirms an uploaded immutable storage version and seals its SHA-256 digest.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn confirm_media_upload(
	cx: &leptoskit::rpc::MutationCx,
	reservation_id: String,
	version_id: String,
	expected_sha256_hex: String,
) -> leptoskit::rpc::Result<MediaUploadConfirmed> {
	verily_backend::serve::confirm_media_upload(cx, reservation_id, version_id, expected_sha256_hex)
		.await
}

/// Submits the digest of the live capture. The original stays on the phone
/// until the shell plugin has handed it to the server's upload for this window.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn submit_live_proof(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	digest_hex: String,
) -> leptoskit::rpc::Result<ProofReceipt> {
	verily_backend::serve::submit_live_proof(cx, attempt_id, requirement_id, digest_hex).await
}

/// Binds a confirmed media upload reservation to an open capture window.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn submit_media_proof(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	reservation_id: String,
) -> leptoskit::rpc::Result<ProofReceipt> {
	verily_backend::serve::submit_media_proof(cx, attempt_id, requirement_id, reservation_id).await
}

/// Evaluates a canonical device motion trace deterministically on the server.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn submit_motion_proof(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	trace_json: String,
) -> leptoskit::rpc::Result<ProofReceipt> {
	verily_backend::serve::submit_motion_proof(cx, attempt_id, requirement_id, trace_json).await
}

/// Evaluates a live device location fix against the action's geofence and travel rules.
#[allow(clippy::too_many_arguments)]
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn submit_location_proof(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	latitude: f64,
	longitude: f64,
	accuracy_meters: f64,
	captured_at_ms: i64,
	is_mock: bool,
) -> leptoskit::rpc::Result<ProofReceipt> {
	verily_backend::serve::submit_location_proof(
		cx,
		attempt_id,
		requirement_id,
		latitude,
		longitude,
		accuracy_meters,
		captured_at_ms,
		is_mock,
	)
	.await
}

/// Redeems a rotating creator-issued venue QR challenge once.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn submit_qr_proof(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	requirement_id: String,
	code: String,
) -> leptoskit::rpc::Result<ProofReceipt> {
	verily_backend::serve::submit_qr_proof(cx, attempt_id, requirement_id, code).await
}

/// Issues a rotating venue QR code for the action's creator.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn create_qr_challenge(
	cx: &leptoskit::rpc::MutationCx,
	action_id: String,
	ttl_seconds: Option<i64>,
) -> leptoskit::rpc::Result<QrChallengeView> {
	verily_backend::serve::create_qr_challenge(cx, action_id, ttl_seconds).await
}

/// Sends the shell attestation that commits to the stored digest.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn submit_attestation(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	digest_hex: String,
) -> leptoskit::rpc::Result<AttestationReceipt> {
	verily_backend::serve::submit_attestation(cx, attempt_id, digest_hex).await
}

/// Verifies Android Key Attestation / Play Integrity or iOS App Attest assertion.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn submit_device_attestation(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	digest_hex: String,
	platform: String,
	payload_b64: String,
	key_id_b64: Option<String>,
	integrity_token: Option<String>,
) -> leptoskit::rpc::Result<AttestationReceipt> {
	verily_backend::serve::submit_device_attestation(
		cx,
		attempt_id,
		digest_hex,
		platform,
		payload_b64,
		key_id_b64,
		integrity_token,
	)
	.await
}

/// Begins Apple App Attest hardware key registration for an iPhone.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn begin_app_attest_registration(
	cx: &leptoskit::rpc::MutationCx,
) -> leptoskit::rpc::Result<AppAttestChallengeView> {
	verily_backend::serve::begin_app_attest_registration(cx).await
}

/// Verifies and registers an Apple App Attest hardware key.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn register_app_attest_key(
	cx: &leptoskit::rpc::MutationCx,
	challenge_id: String,
	key_id_b64: String,
	attestation_object_b64: String,
) -> leptoskit::rpc::Result<AppAttestKeyRegistered> {
	verily_backend::serve::register_app_attest_key(
		cx,
		challenge_id,
		key_id_b64,
		attestation_object_b64,
	)
	.await
}

/// Operator query of an iPhone's Apple DeviceCheck bits.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn query_device_check(
	cx: &leptoskit::rpc::MutationCx,
	device_token: String,
) -> leptoskit::rpc::Result<DeviceCheckBitsView> {
	verily_backend::serve::query_device_check(cx, device_token).await
}

/// Operator mutation of an iPhone's Apple DeviceCheck bits.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn update_device_check(
	cx: &leptoskit::rpc::MutationCx,
	device_token: String,
	banned: bool,
	review_required: bool,
	note: String,
) -> leptoskit::rpc::Result<DeviceCheckBitsView> {
	verily_backend::serve::update_device_check(cx, device_token, banned, review_required, note)
		.await
}

/// Asks the server to verify the attempt.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn complete_attempt(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
) -> leptoskit::rpc::Result<AttemptOutcome> {
	verily_backend::serve::complete_attempt(cx, attempt_id).await
}

/// Saves a draft. Funding is not implied.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn save_action(
	cx: &leptoskit::rpc::MutationCx,
	draft: DraftInput,
) -> leptoskit::rpc::Result<DraftSaved> {
	verily_backend::serve::save_action(cx, draft).await
}

/// Publishes only when `verily_backend` has verified the escrow from chain state.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn publish_action(
	cx: &leptoskit::rpc::MutationCx,
	action_id: String,
) -> leptoskit::rpc::Result<PublishOutcome> {
	verily_backend::serve::publish_action(cx, action_id).await
}

/// Reads the creator's reward pool summary for an action.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn get_reward_pool(
	cx: &leptoskit::rpc::QueryCx,
	action_id: String,
) -> leptoskit::rpc::Result<RewardPoolStatusView> {
	verily_backend::serve::get_reward_pool(cx, action_id).await
}

/// Prepares the unsigned Solana escrow funding transaction for the creator's wallet.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn prepare_reward_funding(
	cx: &leptoskit::rpc::MutationCx,
	action_id: String,
	creator_wallet: String,
) -> leptoskit::rpc::Result<FundingPlanView> {
	verily_backend::serve::prepare_reward_funding(cx, action_id, creator_wallet).await
}

/// Verifies on-chain escrow funding state after wallet submission.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn confirm_reward_funding(
	cx: &leptoskit::rpc::MutationCx,
	action_id: String,
	funding_signature: String,
) -> leptoskit::rpc::Result<RewardPoolStatusView> {
	verily_backend::serve::confirm_reward_funding(cx, action_id, funding_signature).await
}

/// Ends a creator's active reward pool early.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn end_reward_early(
	cx: &leptoskit::rpc::MutationCx,
	action_id: String,
) -> leptoskit::rpc::Result<RewardPoolStatusView> {
	verily_backend::serve::end_reward_early(cx, action_id).await
}

/// A person's accept or reject. A model verdict is not this call.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn review_attempt(
	cx: &leptoskit::rpc::MutationCx,
	review_id: String,
	accept: bool,
	note: String,
) -> leptoskit::rpc::Result<ReviewDecision> {
	verily_backend::serve::review_attempt(cx, review_id, accept, note).await
}

/// Asks for another look at an attempt.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn submit_appeal(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	reason: String,
) -> leptoskit::rpc::Result<AppealReceipt> {
	verily_backend::serve::submit_appeal(cx, attempt_id, reason).await
}

/// Lists the signed-in participant's appeals.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_my_appeals(
	cx: &leptoskit::rpc::QueryCx,
) -> leptoskit::rpc::Result<Vec<AppealItem>> {
	verily_backend::serve::list_my_appeals(cx).await
}

/// Lists open appeals awaiting a reviewer decision.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_review_appeals(
	cx: &leptoskit::rpc::QueryCx,
) -> leptoskit::rpc::Result<Vec<AppealItem>> {
	verily_backend::serve::list_review_appeals(cx).await
}

/// Resolves an open appeal (`overturn = true` verifies the attempt).
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn resolve_appeal(
	cx: &leptoskit::rpc::MutationCx,
	appeal_id: String,
	overturn: bool,
	note: String,
) -> leptoskit::rpc::Result<AppealItem> {
	verily_backend::serve::resolve_appeal(cx, appeal_id, overturn, note).await
}

/// Reports an action, attempt, account, or app for moderation review.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn report_content(
	cx: &leptoskit::rpc::MutationCx,
	target_kind: String,
	target_id: String,
	reason: String,
	notes: Option<String>,
) -> leptoskit::rpc::Result<ModerationCaseRow> {
	verily_backend::serve::report_content(cx, target_kind, target_id, reason, notes).await
}

/// Lists moderation reports filed by the signed-in account.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_my_moderation_cases(
	cx: &leptoskit::rpc::QueryCx,
) -> leptoskit::rpc::Result<Vec<ModerationCaseRow>> {
	verily_backend::serve::list_my_moderation_cases(cx).await
}

/// Lists open moderation cases for reviewers/moderators.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_moderation_queue(
	cx: &leptoskit::rpc::QueryCx,
) -> leptoskit::rpc::Result<Vec<ModerationCaseRow>> {
	verily_backend::serve::list_moderation_queue(cx).await
}

/// Applies a moderation decision (`under_review`, `held`, `cleared`, `removed`).
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn review_moderation_case(
	cx: &leptoskit::rpc::MutationCx,
	case_id: String,
	new_status: String,
	note: String,
) -> leptoskit::rpc::Result<ModerationCaseRow> {
	verily_backend::serve::review_moderation_case(cx, case_id, new_status, note).await
}

/// Appeals a moderation hold or removal.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn appeal_moderation(
	cx: &leptoskit::rpc::MutationCx,
	case_id: String,
	reason: String,
) -> leptoskit::rpc::Result<ModerationCaseRow> {
	verily_backend::serve::appeal_moderation(cx, case_id, reason).await
}

/// Lists partner apps owned by the signed-in creator.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_my_apps(
	cx: &leptoskit::rpc::QueryCx,
) -> leptoskit::rpc::Result<Vec<VerilyAppRow>> {
	verily_backend::serve::list_my_apps(cx).await
}

/// Registers a new partner Verily App and returns its one-time API key.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn create_app(
	cx: &leptoskit::rpc::MutationCx,
	name: String,
	slug: String,
	webhook_url: Option<String>,
) -> leptoskit::rpc::Result<VerilyAppCreated> {
	verily_backend::serve::create_app(cx, name, slug, webhook_url).await
}

/// Updates a partner app's settings.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn update_app(
	cx: &leptoskit::rpc::MutationCx,
	app_id: String,
	name: String,
	webhook_url: Option<String>,
	active: bool,
) -> leptoskit::rpc::Result<VerilyAppRow> {
	verily_backend::serve::update_app(cx, app_id, name, webhook_url, active).await
}

/// Rotates a partner app's API key.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn rotate_app_key(
	cx: &leptoskit::rpc::MutationCx,
	app_id: String,
) -> leptoskit::rpc::Result<VerilyAppKeyRotated> {
	verily_backend::serve::rotate_app_key(cx, app_id).await
}

/// Revokes a partner app API key.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn revoke_app_key(
	cx: &leptoskit::rpc::MutationCx,
	app_id: String,
	key_id: String,
) -> leptoskit::rpc::Result<bool> {
	verily_backend::serve::revoke_app_key(cx, app_id, key_id).await
}

/// Adds an allowlisted deep-link redirect URI to a partner app.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn add_app_redirect_uri(
	cx: &leptoskit::rpc::MutationCx,
	app_id: String,
	uri: String,
) -> leptoskit::rpc::Result<VerilyAppRow> {
	verily_backend::serve::add_app_redirect_uri(cx, app_id, uri).await
}

/// Lists recent webhook deliveries for a partner app.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn list_app_deliveries(
	cx: &leptoskit::rpc::QueryCx,
	app_id: String,
) -> leptoskit::rpc::Result<Vec<VerilyAppDeliveryRow>> {
	verily_backend::serve::list_app_deliveries(cx, app_id).await
}

/// Approves a partner deep-link consent on `/link`.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn approve_app_link(
	cx: &leptoskit::rpc::MutationCx,
	app_slug: String,
	redirect_uri: String,
	state: Option<String>,
) -> leptoskit::rpc::Result<AppLinkExchangeView> {
	verily_backend::serve::approve_app_link(cx, app_slug, redirect_uri, state).await
}

/// Revokes a user's linked partner app connection.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn revoke_app_link(
	cx: &leptoskit::rpc::MutationCx,
	app_id: String,
) -> leptoskit::rpc::Result<bool> {
	verily_backend::serve::revoke_app_link(cx, app_id).await
}

/// Loads a partner-initiated verification request for `/r/:request`.
#[leptoskit::rpc::query(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn get_verification_request(
	cx: &leptoskit::rpc::QueryCx,
	request_id: String,
) -> leptoskit::rpc::Result<VerificationRequestView> {
	verily_backend::serve::get_verification_request(cx, request_id).await
}

/// Claims an open partner verification request for the signed-in participant.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn start_verification_request(
	cx: &leptoskit::rpc::MutationCx,
	request_id: String,
) -> leptoskit::rpc::Result<VerificationRequestView> {
	verily_backend::serve::start_verification_request(cx, request_id).await
}

/// Cancels a partner verification request.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn cancel_verification_request(
	cx: &leptoskit::rpc::MutationCx,
	request_id: String,
) -> leptoskit::rpc::Result<VerificationRequestView> {
	verily_backend::serve::cancel_verification_request(cx, request_id).await
}

/// Ends the session. The shell owns the sign-in UI; this is the signed-in person's action.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn sign_out(cx: &leptoskit::rpc::MutationCx) -> leptoskit::rpc::Result<()> {
	verily_backend::serve::sign_out(cx).await
}

/// Closes the account after the person confirms with the phrase the screen asked for.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn close_account(
	cx: &leptoskit::rpc::MutationCx,
	confirmation: String,
) -> leptoskit::rpc::Result<()> {
	verily_backend::serve::close_account(cx, confirmation).await
}
