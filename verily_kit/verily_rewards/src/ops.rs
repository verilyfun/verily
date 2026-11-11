//! RPC operations `verily_backend` serves.
//!
//! Each operation is named `rewards.<function>` so it does not collide with
//! an app operation on the shared `POST /api/<name>` router. The caller is
//! the actor on the database context. Reward settings are the
//! [`RewardsHandle`] the backend installs on that context. Arguments that
//! are domain records are [`verily_shared`] values carried as JSON.

use leptoskit_db::Context;
use leptoskit_rpc as rpc;
use uuid::Uuid;
use verily_shared::{
	ActionOpportunity, ActionRecurrence, ActionRequirementDraft, ActionRequirementKind,
	ActionTemplate, CreateActionDefinitionRequest, PayoutWalletLinkChallengeView, PayoutWalletView,
	RewardEndPlan, RewardFundingPlan, RewardPayoutView, RewardPoolView,
};

use crate::config::Rewards;
use crate::store::{self, ReleaseReport, RewardsError};

/// Reward settings for the signed-in request.
#[derive(Clone)]
pub struct RewardsHandle(pub std::sync::Arc<Rewards>);

/// Server-owned starting points. None of them include a reward or a spoken word.
#[must_use]
pub fn templates() -> Vec<ActionTemplate> {
	vec![ActionTemplate {
		template_key: "photo".to_owned(),
		title: "Take a photo".to_owned(),
		description: "A photo taken in the app.".to_owned(),
		suggested_recurrence: ActionRecurrence::Once,
		requirements: vec![ActionRequirementDraft::new(
			"photo",
			ActionRequirementKind::Photo,
			"Photo",
			"Take the photo in the app.",
			true,
		)],
	}]
}

/// Lists the server-owned templates.
#[rpc::query(name = "rewards.list_templates")]
pub async fn list_templates(_cx: &rpc::QueryCx) -> rpc::Result<Vec<ActionTemplate>> {
	Ok(templates())
}

/// Creates a draft for the signed-in account.
#[rpc::mutation(name = "rewards.create_action")]
pub async fn create_action(
	cx: &rpc::MutationCx,
	request: serde_json::Value,
) -> rpc::Result<ActionOpportunity> {
	let request: CreateActionDefinitionRequest =
		serde_json::from_value(request).map_err(|_| rpc::Error::invalid("invalidRequest"))?;
	let (creator, name) = caller(cx.context())?;
	let rewards = rewards(cx)?;
	store::create_action(cx.tx(), &rewards, creator, &name, &request)
		.await
		.map_err(into_rpc)
}

/// Saves a draft.
#[rpc::mutation(name = "rewards.save_action_draft")]
pub async fn save_action_draft(
	cx: &rpc::MutationCx,
	action_id: String,
	expected_revision: i64,
	request: serde_json::Value,
) -> rpc::Result<ActionOpportunity> {
	let request: CreateActionDefinitionRequest =
		serde_json::from_value(request).map_err(|_| rpc::Error::invalid("invalidRequest"))?;
	let (creator, _) = caller(cx.context())?;
	let rewards = rewards(cx)?;
	store::save_action(
		cx.tx(),
		&rewards,
		creator,
		parse_uuid(&action_id)?,
		expected_revision,
		&request,
	)
	.await
	.map_err(into_rpc)
}

/// Publishes a draft. The arguments are the action and the revision the
/// caller read. No signature and no funded flag are accepted here.
#[rpc::mutation(name = "rewards.publish_action")]
pub async fn publish_action(
	cx: &rpc::MutationCx,
	action_id: String,
	expected_revision: i64,
) -> rpc::Result<ActionOpportunity> {
	let (creator, _) = caller(cx.context())?;
	let rewards = rewards(cx)?;
	store::publish_action(
		cx.tx(),
		&rewards,
		creator,
		parse_uuid(&action_id)?,
		expected_revision,
	)
	.await
	.map_err(into_rpc)
}

/// Prepares funding. The returned plan does not mark the pool funded.
#[rpc::mutation(name = "rewards.prepare_reward_funding")]
pub async fn prepare_reward_funding(
	cx: &rpc::MutationCx,
	action_id: String,
	creator_wallet: String,
) -> rpc::Result<RewardFundingPlan> {
	let (creator, _) = caller(cx.context())?;
	let rewards = rewards(cx)?;
	store::prepare_funding(
		cx.tx(),
		&rewards,
		creator,
		parse_uuid(&action_id)?,
		&creator_wallet,
	)
	.await
	.map_err(into_rpc)
}

/// Reads the escrow from chain state and funds the pool only on a match.
#[rpc::mutation(name = "rewards.confirm_reward_funding")]
pub async fn confirm_reward_funding(
	cx: &rpc::MutationCx,
	action_id: String,
	signature: String,
) -> rpc::Result<RewardPoolView> {
	let (creator, _) = caller(cx.context())?;
	let rewards = rewards(cx)?;
	store::confirm_funding(
		cx.tx(),
		&rewards,
		creator,
		parse_uuid(&action_id)?,
		&signature,
	)
	.await
	.map_err(into_rpc)
}

/// Stops new reservations and returns the end instruction payload.
#[rpc::mutation(name = "rewards.end_reward_early")]
pub async fn end_reward_early(
	cx: &rpc::MutationCx,
	action_id: String,
) -> rpc::Result<RewardEndPlan> {
	let (creator, _) = caller(cx.context())?;
	let rewards = rewards(cx)?;
	store::end_early(cx.tx(), &rewards, creator, parse_uuid(&action_id)?)
		.await
		.map_err(into_rpc)
}

/// The creator's pool.
#[rpc::query(name = "rewards.get_reward_pool")]
pub async fn get_reward_pool(cx: &rpc::QueryCx, action_id: String) -> rpc::Result<RewardPoolView> {
	let (creator, _) = caller(cx.context())?;
	store::reward_pool(cx.db(), creator, parse_uuid(&action_id)?)
		.await
		.map_err(into_rpc)
}

/// The caller's payouts.
#[rpc::query(name = "rewards.list_my_payouts")]
pub async fn list_my_payouts(cx: &rpc::QueryCx) -> rpc::Result<Vec<RewardPayoutView>> {
	let (account, _) = caller(cx.context())?;
	store::list_payouts(cx.db(), account)
		.await
		.map_err(into_rpc)
}

/// Settles one payout from chain state. The stored index is reused.
#[rpc::mutation(name = "rewards.release_payout")]
pub async fn release_payout(
	cx: &rpc::MutationCx,
	payout_id: String,
) -> rpc::Result<ReleaseReportWire> {
	let rewards = rewards(cx)?;
	let report = store::release_payout(cx.tx(), &rewards, parse_uuid(&payout_id)?)
		.await
		.map_err(into_rpc)?;
	Ok(ReleaseReportWire::from(report))
}

/// Records a reviewer's acceptance. The reviewer cannot be the participant.
#[rpc::mutation(name = "rewards.accept_payout_review")]
pub async fn accept_payout_review(
	cx: &rpc::MutationCx,
	payout_id: String,
) -> rpc::Result<RewardPayoutView> {
	let (reviewer, _) = caller(cx.context())?;
	store::accept_review(cx.tx(), reviewer, parse_uuid(&payout_id)?)
		.await
		.map_err(into_rpc)
}

/// The text a wallet signs. Signing does not move funds.
#[rpc::mutation(name = "rewards.create_wallet_link_challenge")]
pub async fn create_wallet_link_challenge(
	cx: &rpc::MutationCx,
	wallet_address: String,
) -> rpc::Result<PayoutWalletLinkChallengeView> {
	let (account, _) = caller(cx.context())?;
	store::create_wallet_challenge(cx.tx(), account, &wallet_address)
		.await
		.map_err(into_rpc)
}

/// Links a wallet after the stored challenge signature verifies.
#[rpc::mutation(name = "rewards.link_payout_wallet")]
pub async fn link_payout_wallet(
	cx: &rpc::MutationCx,
	wallet_address: String,
	signature: String,
) -> rpc::Result<PayoutWalletView> {
	let (account, _) = caller(cx.context())?;
	store::link_payout_wallet(cx.tx(), account, &wallet_address, &signature)
		.await
		.map_err(into_rpc)
}

/// A release result without RPC text.
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ReleaseReportWire {
	/// Payout row after the attempt.
	pub payout: RewardPayoutView,
	/// `alreadyReleased`, or a stable failure code.
	pub code: String,
	/// Whether the same index may be tried again.
	pub retryable: bool,
}

impl From<ReleaseReport> for ReleaseReportWire {
	fn from(report: ReleaseReport) -> Self {
		let (code, retryable) = match report.outcome {
			crate::ReleaseOutcome::AlreadyReleased => ("alreadyReleased".to_owned(), false),
			crate::ReleaseOutcome::Failed { code, retryable } => (store_code(&code), retryable),
		};
		Self {
			payout: report.payout,
			code,
			retryable,
		}
	}
}

fn store_code(code: &crate::ReleaseCode) -> String {
	serde_json::to_value(code)
		.ok()
		.and_then(|value| value.as_str().map(str::to_owned))
		.unwrap_or_else(|| "release_rejected".to_owned())
}

fn rewards(cx: &rpc::MutationCx) -> Result<std::sync::Arc<Rewards>, rpc::Error> {
	cx.get::<RewardsHandle>()
		.map(|handle| handle.0.clone())
		.ok_or_else(|| rpc::Error::retry("rewardsUnavailable"))
}

fn caller(context: &Context) -> Result<(Uuid, String), rpc::Error> {
	let actor = context
		.actor()
		.map(|actor| actor.uuid())
		.ok_or_else(|| rpc::Error::unauthorized("sign in"))?;
	let name = context
		.get::<CallerName>()
		.map(|name| name.0.clone())
		.unwrap_or_else(|| "Member".to_owned());
	Ok((actor, name))
}

/// Display name the backend puts on the request context.
#[derive(Clone, Debug)]
pub struct CallerName(pub String);

fn parse_uuid(value: &str) -> Result<Uuid, rpc::Error> {
	value
		.parse()
		.map_err(|_| rpc::Error::invalid("invalidRequest"))
}

/// A rewards failure as the caller hears it: a stable code, no store details.
pub fn into_rpc(error: RewardsError) -> rpc::Error {
	match error {
		RewardsError::Unauthorized => rpc::Error::unauthorized("sign in"),
		RewardsError::NotFound => rpc::Error::not_found("notFound"),
		RewardsError::Authoring(problem) => rpc::Error::invalid(enum_name(&problem)),
		RewardsError::Reward(problem) => {
			let name = enum_name(&problem);
			if name == "rewardsUnavailable" {
				rpc::Error::retry(name)
			} else {
				rpc::Error::invalid(name)
			}
		}
		RewardsError::Conflict(code) => rpc::Error::conflict(code),
		RewardsError::Unavailable => rpc::Error::retry("rewardsUnavailable"),
		RewardsError::Store => rpc::Error::server("something went wrong"),
	}
}

fn enum_name<T: serde::Serialize>(value: &T) -> String {
	serde_json::to_value(value)
		.ok()
		.and_then(|value| value.as_str().map(str::to_owned))
		.unwrap_or_else(|| "invalidRequest".to_owned())
}
