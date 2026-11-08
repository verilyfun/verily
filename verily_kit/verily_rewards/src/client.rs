//! The action catalogue, escrow funding, and payout wallet calls.

use std::future::Future;

use serde::Serialize;
use serde::de::DeserializeOwned;
use serde_json::Value;
use serde_json::json;
use uuid::Uuid;

use crate::ApiError;
use crate::ServerpodEndpoint;
use crate::types::ActionDraftProposal;
use crate::types::ActionOpportunity;
use crate::types::ActionQrChallengeView;
use crate::types::ActionTemplate;
use crate::types::CreateActionDefinitionRequest;
use crate::types::PayoutWalletLinkChallengeView;
use crate::types::PayoutWalletView;
use crate::types::RewardEndPlan;
use crate::types::RewardFundingPlan;
use crate::types::RewardPayoutView;
use crate::types::RewardPoolView;

const ACTIONS: &str = "actionVerification";
const REWARDS: &str = "rewards";
const WALLETS: &str = "payoutWallet";

/// Calls the signed-in account's action and reward methods.
///
/// Every method sends the same arguments as the generated Dart client and
/// returns the server's value. No method takes an account id. No method
/// marks a pool funded, assigns a payout index, or releases a payout.
pub struct RewardsClient<T> {
	transport: T,
}

impl<T> RewardsClient<T> {
	pub fn new(transport: T) -> Self {
		Self { transport }
	}

	pub fn transport(&self) -> &T {
		&self.transport
	}
}

impl<T: ServerpodEndpoint> RewardsClient<T> {
	/// The server's value-free templates.
	pub fn list_templates(
		&self,
	) -> impl Future<Output = Result<Vec<ActionTemplate>, ApiError>> + Send {
		self.call(ACTIONS, "listTemplates", json!({}))
	}

	/// Asks the server to draft an action from a plain-language idea.
	///
	/// The proposal has no reward. The server refuses when drafting is off.
	pub fn draft_action_from_prompt(
		&self,
		prompt: &str,
	) -> impl Future<Output = Result<ActionDraftProposal, ApiError>> + Send {
		self.call(
			ACTIONS,
			"draftActionFromPrompt",
			json!({ "prompt": prompt }),
		)
	}

	/// Creates the caller's draft.
	pub fn create_action(
		&self,
		request: &CreateActionDefinitionRequest,
	) -> impl Future<Output = Result<ActionOpportunity, ApiError>> + Send {
		self.model(ACTIONS, "createAction", "request", request)
	}

	/// Saves the caller's draft again.
	pub fn save_action_draft(
		&self,
		request: &CreateActionDefinitionRequest,
	) -> impl Future<Output = Result<ActionOpportunity, ApiError>> + Send {
		self.model(ACTIONS, "saveActionDraft", "request", request)
	}

	/// The creator's full view of one of their actions.
	pub fn preview_action(
		&self,
		action_id: Uuid,
	) -> impl Future<Output = Result<ActionOpportunity, ApiError>> + Send {
		self.call(ACTIONS, "previewAction", json!({ "actionId": action_id }))
	}

	/// The caller's own actions, newest first, up to `limit`.
	pub fn list_owned_actions(
		&self,
		limit: i64,
	) -> impl Future<Output = Result<Vec<ActionOpportunity>, ApiError>> + Send {
		self.call(ACTIONS, "listOwnedActions", json!({ "limit": limit }))
	}

	/// Live actions for the caller, up to `limit`.
	pub fn list_available_actions(
		&self,
		limit: i64,
	) -> impl Future<Output = Result<Vec<ActionOpportunity>, ApiError>> + Send {
		self.call(ACTIONS, "listAvailableActions", json!({ "limit": limit }))
	}

	/// One action for a deep-linked page. Missing and hidden are the same error.
	pub fn get_action(
		&self,
		action_id: Uuid,
	) -> impl Future<Output = Result<ActionOpportunity, ApiError>> + Send {
		self.call(ACTIONS, "getAction", json!({ "actionId": action_id }))
	}

	/// Publishes the action at `expected_revision`.
	///
	/// The server refuses a rewarded action whose escrow it has not verified
	/// from chain state. This call does not send a signature or a funded flag.
	pub fn publish_action(
		&self,
		action_id: Uuid,
		expected_revision: i64,
	) -> impl Future<Output = Result<ActionOpportunity, ApiError>> + Send {
		self.call(
			ACTIONS,
			"publishAction",
			json!({
				"actionId": action_id,
				"expectedRevision": expected_revision,
			}),
		)
	}

	/// Stops new attempts at `expected_revision`.
	pub fn pause_action(
		&self,
		action_id: Uuid,
		expected_revision: i64,
	) -> impl Future<Output = Result<ActionOpportunity, ApiError>> + Send {
		self.call(
			ACTIONS,
			"pauseAction",
			json!({
				"actionId": action_id,
				"expectedRevision": expected_revision,
			}),
		)
	}

	/// Live actions with a public place inside `radius_km` of the point,
	/// nearest first. The server coarsens the point and does not store it.
	pub fn list_nearby_actions(
		&self,
		latitude: f64,
		longitude: f64,
		radius_km: f64,
		limit: i64,
	) -> impl Future<Output = Result<Vec<ActionOpportunity>, ApiError>> + Send {
		self.call(
			ACTIONS,
			"listNearbyActions",
			json!({
				"latitude": latitude,
				"longitude": longitude,
				"radiusKm": radius_km,
				"limit": limit,
			}),
		)
	}

	/// A short-lived, single-use venue code for a live QR requirement.
	pub fn create_qr_challenge(
		&self,
		requirement_id: Uuid,
		validity_seconds: i64,
	) -> impl Future<Output = Result<ActionQrChallengeView, ApiError>> + Send {
		self.call(
			ACTIONS,
			"createQrChallenge",
			json!({
				"requirementId": requirement_id,
				"validitySeconds": validity_seconds,
			}),
		)
	}

	/// The creator's pool for an action, or `None` when it has no reward.
	pub fn get_reward_pool(
		&self,
		action_id: Uuid,
	) -> impl Future<Output = Result<Option<RewardPoolView>, ApiError>> + Send {
		self.call(REWARDS, "getRewardPool", json!({ "actionId": action_id }))
	}

	/// Freezes the terms and returns the unsigned transaction the creator's
	/// wallet signs to open the escrow.
	///
	/// The plan is not funding. The wallet signs and sends it. Funding is
	/// whatever [`Self::confirm_reward_funding`] gets back from the server.
	pub fn prepare_reward_funding(
		&self,
		action_id: Uuid,
	) -> impl Future<Output = Result<RewardFundingPlan, ApiError>> + Send {
		self.call(
			REWARDS,
			"prepareRewardFunding",
			json!({ "actionId": action_id }),
		)
	}

	/// Asks the server to read the escrow and mark the pool funded.
	///
	/// `signature` is the funding transaction's base58 signature, kept for
	/// audit. It is not the trust anchor. The returned view is funded only
	/// when the server says so after that read. This method never builds a
	/// funded view from the signature.
	pub fn confirm_reward_funding(
		&self,
		action_id: Uuid,
		signature: &str,
	) -> impl Future<Output = Result<RewardPoolView, ApiError>> + Send {
		self.call(
			REWARDS,
			"confirmRewardFunding",
			json!({
				"actionId": action_id,
				"signature": signature,
			}),
		)
	}

	/// Stops new payouts now and returns the unsigned `EndEarly` transaction.
	/// Reserved payouts still release on the server until the refund window.
	pub fn end_reward_early(
		&self,
		action_id: Uuid,
	) -> impl Future<Output = Result<RewardEndPlan, ApiError>> + Send {
		self.call(REWARDS, "endRewardEarly", json!({ "actionId": action_id }))
	}

	/// The caller's payouts, newest first, up to `limit`.
	pub fn list_my_payouts(
		&self,
		limit: i64,
	) -> impl Future<Output = Result<Vec<RewardPayoutView>, ApiError>> + Send {
		self.call(REWARDS, "listMyPayouts", json!({ "limit": limit }))
	}

	/// The caller's linked payout wallet, or `None`.
	pub fn get_payout_wallet(
		&self,
	) -> impl Future<Output = Result<Option<PayoutWalletView>, ApiError>> + Send {
		self.call(WALLETS, "getMine", json!({}))
	}

	/// The exact text `wallet_address` must sign to prove ownership.
	pub fn create_wallet_link_challenge(
		&self,
		wallet_address: &str,
	) -> impl Future<Output = Result<PayoutWalletLinkChallengeView, ApiError>> + Send {
		self.call(
			WALLETS,
			"createWalletLinkChallenge",
			json!({ "walletAddress": wallet_address }),
		)
	}

	/// Links the wallet after the server verifies the signature over its challenge.
	pub fn link_payout_wallet(
		&self,
		wallet_address: &str,
		nonce: &str,
		signature: &str,
	) -> impl Future<Output = Result<PayoutWalletView, ApiError>> + Send {
		self.call(
			WALLETS,
			"linkPayoutWallet",
			json!({
				"walletAddress": wallet_address,
				"nonce": nonce,
				"signature": signature,
			}),
		)
	}

	fn model<B: Serialize + Sync>(
		&self,
		endpoint: &'static str,
		method: &'static str,
		argument: &'static str,
		body: &B,
	) -> impl Future<Output = Result<ActionOpportunity, ApiError>> + Send {
		let args = serde_json::to_value(body).map(|value| json!({ argument: value }));
		async move {
			let args = args.map_err(|error| ApiError::Decode {
				method,
				message: error.to_string(),
			})?;
			self.call(endpoint, method, args).await
		}
	}

	fn call<R: DeserializeOwned>(
		&self,
		endpoint: &'static str,
		method: &'static str,
		args: Value,
	) -> impl Future<Output = Result<R, ApiError>> + Send {
		let response = self.transport.call(endpoint, method, args);
		async move {
			let value = response.await.map_err(ApiError::from_endpoint)?;
			serde_json::from_value(value).map_err(|error| ApiError::Decode {
				method,
				message: error.to_string(),
			})
		}
	}
}

#[cfg(test)]
mod tests {
	use std::sync::Mutex;

	use chrono::TimeZone;
	use chrono::Utc;
	use serde_json::json;
	use uuid::Uuid;

	use super::RewardsClient;
	use crate::ApiError;
	use crate::EndpointError;
	use crate::ServerpodEndpoint;
	use crate::types::ActionDefinitionStatus;
	use crate::types::ActionRecurrence;
	use crate::types::ActionRequirementDraft;
	use crate::types::ActionRequirementKind;
	use crate::types::CreateActionDefinitionRequest;
	use crate::types::RewardCluster;
	use crate::types::RewardPoolStatus;
	use crate::types::RewardProblem;
	use crate::types::RewardTermsDraft;

	struct Script {
		result: Mutex<Result<serde_json::Value, EndpointError>>,
		calls: Mutex<Vec<(String, String, serde_json::Value)>>,
	}

	impl Script {
		fn ok(value: serde_json::Value) -> Self {
			Self {
				result: Mutex::new(Ok(value)),
				calls: Mutex::new(Vec::new()),
			}
		}

		fn err(error: EndpointError) -> Self {
			Self {
				result: Mutex::new(Err(error)),
				calls: Mutex::new(Vec::new()),
			}
		}
	}

	impl ServerpodEndpoint for Script {
		async fn call(
			&self,
			endpoint: &str,
			method: &str,
			args: serde_json::Value,
		) -> Result<serde_json::Value, EndpointError> {
			self.calls.lock().expect("call log").push((
				endpoint.to_owned(),
				method.to_owned(),
				args,
			));
			self.result.lock().expect("script").clone()
		}
	}

	fn action_id() -> Uuid {
		Uuid::from_u128(0x018f4a3e_7c21_7a4e_9c3a_6b1d2e0f4a50)
	}

	fn stamp() -> chrono::DateTime<Utc> {
		Utc.with_ymd_and_hms(2026, 11, 8, 12, 0, 0).unwrap()
	}

	fn pool(status: RewardPoolStatus, signature: Option<&str>) -> serde_json::Value {
		json!({
			"poolId": action_id(),
			"status": status,
			"cluster": "devnet",
			"mint": "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU",
			"tokenSymbol": "USDC",
			"decimals": 6,
			"amountPerPayout": 1_000_000,
			"maxPayouts": 10,
			"maxWinsPerAccount": 1,
			"payoutsReserved": 0,
			"payoutsReleased": 0,
			"expiresAt": "2026-12-08T12:00:00Z",
			"refundAfter": "2026-12-11T12:00:00Z",
			"escrowAddress": "Escrow111111111111111111111111111111111111",
			"fundingSignature": signature,
		})
	}

	#[test]
	fn a_signature_does_not_fund_the_pool() {
		let signature = "5signedtransactionthattheclientmustnottrust";
		let script = Script::ok(pool(RewardPoolStatus::AwaitingFunding, Some(signature)));
		let client = RewardsClient::new(script);
		let view = pollster::block_on(client.confirm_reward_funding(action_id(), signature))
			.expect("server view");

		assert_eq!(view.status, RewardPoolStatus::AwaitingFunding);
		assert!(!view.escrow_verified());
		assert_eq!(view.funding_signature.as_deref(), Some(signature));

		let calls = client.transport().calls.lock().expect("calls");
		assert_eq!(calls.len(), 1);
		assert_eq!(calls[0].0, "rewards");
		assert_eq!(calls[0].1, "confirmRewardFunding");
		assert_eq!(
			calls[0].2,
			json!({
				"actionId": action_id(),
				"signature": signature,
			})
		);
	}

	#[test]
	fn the_server_view_is_the_only_funding_result() {
		let script = Script::ok(pool(RewardPoolStatus::Funded, Some("audited")));
		let view = pollster::block_on(
			RewardsClient::new(script).confirm_reward_funding(action_id(), "audited"),
		)
		.expect("funded by the server");
		assert!(view.escrow_verified());
		assert_eq!(view.status, RewardPoolStatus::Funded);
	}

	#[test]
	fn a_funding_plan_is_not_a_funded_pool() {
		let script = Script::ok(json!({
			"poolId": action_id(),
			"cluster": "devnet",
			"escrowAddress": "Escrow111111111111111111111111111111111111",
			"creatorWallet": "Creator11111111111111111111111111111111111",
			"arbiterAddress": "Arbiter11111111111111111111111111111111111",
			"mint": "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU",
			"tokenSymbol": "USDC",
			"decimals": 6,
			"totalAtoms": 10_000_000,
			"expiresAt": "2026-12-08T12:00:00Z",
			"refundAfter": "2026-12-11T12:00:00Z",
			"unsignedTransaction": "bG9jYWwtZGV2LW9ubHk",
		}));
		let plan =
			pollster::block_on(RewardsClient::new(script).prepare_reward_funding(action_id()))
				.expect("plan");
		assert!(plan.unsigned_transaction.starts_with("bG9j"));
		assert_eq!(plan.cluster, RewardCluster::Devnet);
		let funded = serde_json::from_str::<crate::types::RewardPoolView>(
			&serde_json::to_string(&plan).unwrap(),
		);
		assert!(funded.is_err(), "a plan does not decode as a pool");
	}

	#[test]
	fn publish_sends_the_revision_and_no_funding_claim() {
		let script = Script::ok(json!({
			"id": action_id(),
			"creatorDisplayName": "Ada",
			"viewerIsCreator": true,
			"actionKey": "daily-situps",
			"revision": 2,
			"status": "active",
			"title": "Sit-ups",
			"description": "Twenty sit-ups.",
			"recurrence": "daily",
			"timeZone": "Europe/London",
			"verifiedCompletions": 0,
			"updatedAt": "2026-11-08T12:00:00Z",
			"requirements": [],
		}));
		let client = RewardsClient::new(script);
		let action = pollster::block_on(client.publish_action(action_id(), 2)).expect("published");
		assert_eq!(action.status, ActionDefinitionStatus::Active);
		let calls = client.transport().calls.lock().expect("calls");
		assert_eq!(calls[0].1, "publishAction");
		assert_eq!(
			calls[0].2,
			json!({ "actionId": action_id(), "expectedRevision": 2 })
		);
		assert!(calls[0].2.get("signature").is_none());
		assert!(calls[0].2.get("funded").is_none());
	}

	#[test]
	fn missing_escrow_config_fails_closed() {
		let script = Script::err(EndpointError::exception(
			"Escrowed rewards are not available on this server yet.",
			json!({
				"__className__": "RewardException",
				"problem": "rewardsUnavailable",
				"message": "Escrowed rewards are not available on this server yet.",
			}),
		));
		let error =
			pollster::block_on(RewardsClient::new(script).prepare_reward_funding(action_id()))
				.expect_err("unavailable");
		match error {
			ApiError::Reward {
				problem: RewardProblem::RewardsUnavailable,
				..
			} => {}
			other => panic!("expected rewards unavailable, got {other:?}"),
		}
	}

	#[test]
	fn an_unfunded_publish_stays_an_authoring_refusal() {
		let script = Script::err(EndpointError::exception(
			"Fund and verify the reward escrow before publishing.",
			json!({
				"__className__": "ActionAuthoringException",
				"reason": "rewardNotFunded",
				"message": "Fund and verify the reward escrow before publishing.",
			}),
		));
		let error = pollster::block_on(RewardsClient::new(script).publish_action(action_id(), 1))
			.expect_err("refused");
		assert!(matches!(
			error,
			ApiError::Authoring {
				reason: crate::types::ActionAuthoringProblem::RewardNotFunded,
				..
			}
		));
	}

	#[test]
	fn create_sends_reward_terms_without_a_mint() {
		let request = CreateActionDefinitionRequest {
			action_key: "daily-situps".into(),
			title: "Sit-ups".into(),
			description: "Twenty sit-ups.".into(),
			recurrence: ActionRecurrence::Daily,
			time_zone: "Europe/London".into(),
			max_verified_completions: None,
			opens_at: None,
			closes_at: None,
			requirements: vec![ActionRequirementDraft::new(
				"situps",
				ActionRequirementKind::Video,
				"Sit-ups",
				"Record twenty sit-ups.",
				true,
			)],
			reward: Some(RewardTermsDraft {
				amount_per_payout: 1_000_000,
				max_payouts: 10,
				max_wins_per_account: 1,
				expires_at: stamp(),
				refund_delay_days: 3,
			}),
		};
		let script = Script::ok(json!({
			"id": action_id(),
			"creatorDisplayName": "Ada",
			"viewerIsCreator": true,
			"actionKey": "daily-situps",
			"revision": 1,
			"status": "draft",
			"title": "Sit-ups",
			"description": "Twenty sit-ups.",
			"recurrence": "daily",
			"timeZone": "Europe/London",
			"verifiedCompletions": 0,
			"updatedAt": "2026-11-08T12:00:00Z",
			"requirements": [],
		}));
		let client = RewardsClient::new(script);
		pollster::block_on(client.create_action(&request)).expect("draft");
		let calls = client.transport().calls.lock().expect("calls");
		assert_eq!(calls[0].0, "actionVerification");
		assert_eq!(calls[0].1, "createAction");
		let reward = &calls[0].2["request"]["reward"];
		assert_eq!(reward["amountPerPayout"], 1_000_000);
		assert_eq!(reward["refundDelayDays"], 3);
		assert!(reward.get("mint").is_none());
		assert!(reward.get("cluster").is_none());
		assert!(reward.get("arbiter").is_none());
	}

	#[test]
	fn an_empty_pool_is_null_and_a_wallet_challenge_is_not_funding() {
		let script = Script::ok(serde_json::Value::Null);
		let pool = pollster::block_on(RewardsClient::new(script).get_reward_pool(action_id()))
			.expect("no reward");
		assert!(pool.is_none());

		let script = Script::ok(json!({
			"walletAddress": "Creator11111111111111111111111111111111111",
			"message": "Verily pays your rewards to this wallet.",
			"nonce": "nonce",
			"expiresAt": "2026-11-08T12:05:00Z",
		}));
		let challenge = pollster::block_on(
			RewardsClient::new(script)
				.create_wallet_link_challenge("Creator11111111111111111111111111111111111"),
		)
		.expect("challenge");
		assert!(challenge.message.contains("wallet"));
		assert_ne!(challenge.nonce, "funded");
	}
}
