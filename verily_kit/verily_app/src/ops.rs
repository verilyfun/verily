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
use crate::model::ActionFilter;
use crate::model::AppealReceipt;
use crate::model::AttemptOpened;
use crate::model::AttemptOutcome;
use crate::model::AttemptRow;
use crate::model::AttestationReceipt;
use crate::model::CaptureWindow;
use crate::model::DraftInput;
use crate::model::DraftRow;
use crate::model::DraftSaved;
use crate::model::PayoutRow;
use crate::model::ProofReceipt;
use crate::model::PublishOutcome;
use crate::model::ReviewDecision;
use crate::model::ReviewRow;
use crate::model::SpokenWord;
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

/// Sends the shell attestation that commits to the stored digest.
#[leptoskit::rpc::mutation(service = "verily-backend", crate = "leptoskit::rpc")]
pub async fn submit_attestation(
	cx: &leptoskit::rpc::MutationCx,
	attempt_id: String,
	digest_hex: String,
) -> leptoskit::rpc::Result<AttestationReceipt> {
	verily_backend::serve::submit_attestation(cx, attempt_id, digest_hex).await
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
