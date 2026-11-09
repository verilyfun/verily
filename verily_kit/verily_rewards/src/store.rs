//! Action, funding, and payout writes.
//!
//! Payout indexes are assigned in the same transaction that updates the pool
//! row. The same attempt returns the row it already has.

use std::str::FromStr;

use chrono::{DateTime, Duration, Utc};
use leptoskit_db::Connection;
use leptoskit_db::DbError;
use leptoskit_db::Read;
use serde::{Deserialize, Serialize};
use solana_kit_client::methods::Commitment;
use solana_kit_core::crypto::verify;
use solana_kit_core::{Address, Signature};
use uuid::Uuid;
use verily_shared::{
	ActionAuthoringProblem, ActionDefinitionStatus, ActionOpportunity, ActionRecurrence,
	ActionRequirementDraft, ActionRequirementView, CreateActionDefinitionRequest,
	PayoutWalletLinkChallengeView, PayoutWalletView, RewardCluster, RewardEndPlan,
	RewardFundingPlan, RewardPayoutStatus, RewardPayoutView, RewardPoolStatus, RewardPoolView,
	RewardProblem, RewardSummary, RewardTermsDraft, Timestamp,
};

use crate::config::Rewards;
use crate::decide::{
	self, ExpectedEscrow, ReleaseOutcome, confirmed_release_signature, inspect_funding,
	publish_block, review_blocks_release,
};
use crate::gateway::read_escrow_parts;
use crate::schema::{
	ActionRow, NewActionRow, NewPayoutWalletRow, NewRewardPayoutRow, NewRewardPoolRow,
	NewWalletLinkChallengeRow, PayoutWalletRow, RewardPayoutRow, RewardPoolRow,
	WalletLinkChallengeRow,
};

/// A payout index that will not be replaced on retry.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ReservedPayout {
	/// What the caller sees.
	pub view: RewardPayoutView,
	/// Index stored for this attempt.
	pub payout_index: u16,
	/// On-chain pool id.
	pub chain_pool_id: Uuid,
}

/// Why a rewards operation stopped.
#[derive(Debug)]
pub enum RewardsError {
	/// The caller is not signed in.
	Unauthorized,
	/// The row is not theirs, or it is not there.
	NotFound,
	/// The draft was refused.
	Authoring(ActionAuthoringProblem),
	/// The reward was refused.
	Reward(RewardProblem),
	/// A stale revision or a taken key.
	Conflict(&'static str),
	/// Rewards are not configured, or the chain is not ready.
	Unavailable,
	/// The database rejected the write. The details stay off the wire.
	Store,
}

impl From<DbError> for RewardsError {
	fn from(error: DbError) -> Self {
		match error {
			DbError::NotFound { .. } => Self::NotFound,
			DbError::Conflict { .. } => Self::Conflict("conflict"),
			_ => Self::Store,
		}
	}
}

/// Result of a release attempt. The index on the payout does not change.
#[derive(Clone, Debug)]
pub struct ReleaseReport {
	/// Payout after the attempt.
	pub payout: RewardPayoutView,
	/// Why it paid or did not.
	pub outcome: ReleaseOutcome,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct StoredRequirement {
	id: Uuid,
	draft: ActionRequirementDraft,
}

/// Creates a draft. Reward terms do not choose the mint, cluster, or arbiter.
pub async fn create_action(
	connection: &impl Connection,
	rewards: &Rewards,
	creator_id: Uuid,
	display_name: &str,
	request: &CreateActionDefinitionRequest,
) -> Result<ActionOpportunity, RewardsError> {
	validate_request(request)?;
	if request.reward.is_some() && rewards.gateway.is_disabled() {
		return Err(RewardsError::Reward(RewardProblem::RewardsUnavailable));
	}
	if ActionRow::query()
		.filter(|row| row.creator_id.eq(creator_id) & row.action_key.eq(request.action_key.clone()))
		.first(connection)
		.await?
		.is_some()
	{
		return Err(RewardsError::Authoring(
			ActionAuthoringProblem::ActionKeyTaken,
		));
	}
	let now = Utc::now();
	let action = NewActionRow {
		creator_id,
		action_key: request.action_key.clone(),
		revision: 1,
		status: name(&ActionDefinitionStatus::Draft),
		title: request.title.clone(),
		description: request.description.clone(),
		recurrence: name(&request.recurrence),
		time_zone: request.time_zone.clone(),
		max_verified_completions: request.max_verified_completions,
		verified_completions: 0,
		opens_at: request.opens_at,
		closes_at: request.closes_at,
		published_at: None,
		creator_display_name: display_name.chars().take(80).collect(),
		requirements_json: store_requirements(&request.requirements, &[])?,
		created_at: now,
		updated_at: now,
	}
	.insert(connection)
	.await?;
	if let Some(terms) = &request.reward {
		insert_pool(connection, rewards, &action, terms, now).await?;
	}
	opportunity(connection, rewards, &action, creator_id).await
}

/// Replaces a draft. Reward terms lock once funding has been prepared.
pub async fn save_action(
	connection: &impl Connection,
	rewards: &Rewards,
	creator_id: Uuid,
	action_id: Uuid,
	expected_revision: i64,
	request: &CreateActionDefinitionRequest,
) -> Result<ActionOpportunity, RewardsError> {
	validate_request(request)?;
	let mut action = owned_action(connection, creator_id, action_id).await?;
	if action.revision != expected_revision {
		return Err(RewardsError::Conflict("revisionConflict"));
	}
	if action.status != name(&ActionDefinitionStatus::Draft) {
		return Err(RewardsError::Authoring(
			ActionAuthoringProblem::RewardTermsLocked,
		));
	}
	let existing = pool_for_action(connection, action.id).await?;
	if existing
		.as_ref()
		.is_some_and(|pool| pool.status != name(&RewardPoolStatus::Draft))
	{
		return Err(RewardsError::Authoring(
			ActionAuthoringProblem::RewardTermsLocked,
		));
	}
	let previous = load_requirements(&action)?;
	action.action_key = request.action_key.clone();
	action.title = request.title.clone();
	action.description = request.description.clone();
	action.recurrence = name(&request.recurrence);
	action.time_zone = request.time_zone.clone();
	action.max_verified_completions = request.max_verified_completions;
	action.opens_at = request.opens_at;
	action.closes_at = request.closes_at;
	action.requirements_json = store_requirements(&request.requirements, &previous)?;
	action.revision += 1;
	action.updated_at = Utc::now();
	action.save(connection).await?;
	match (&request.reward, existing) {
		(Some(terms), Some(mut pool)) if pool.status == name(&RewardPoolStatus::Draft) => {
			apply_terms(&mut pool, rewards, terms)?;
			pool.updated_at = Utc::now();
			pool.save(connection).await?;
		}
		(Some(terms), None) => {
			if rewards.gateway.is_disabled() {
				return Err(RewardsError::Reward(RewardProblem::RewardsUnavailable));
			}
			insert_pool(connection, rewards, &action, terms, Utc::now()).await?;
		}
		(None, Some(pool)) => {
			pool.destroy(connection).await?;
		}
		_ => {}
	}
	opportunity(connection, rewards, &action, creator_id).await
}

/// Publishes a draft. A reward pool must already be funded from chain state.
pub async fn publish_action(
	connection: &impl Connection,
	rewards: &Rewards,
	creator_id: Uuid,
	action_id: Uuid,
	expected_revision: i64,
) -> Result<ActionOpportunity, RewardsError> {
	let mut action = owned_action(connection, creator_id, action_id).await?;
	if action.revision != expected_revision {
		return Err(RewardsError::Conflict("revisionConflict"));
	}
	let pool = pool_for_action(connection, action.id).await?;
	if let Some(problem) = publish_block(pool.as_ref().and_then(|pool| parse_status(&pool.status)))
	{
		return Err(RewardsError::Authoring(problem));
	}
	let now = Utc::now();
	action.status = name(&ActionDefinitionStatus::Active);
	action.published_at = Some(now);
	action.revision += 1;
	action.updated_at = now;
	action.save(connection).await?;
	opportunity(connection, rewards, &action, creator_id).await
}

/// Derives the escrow and returns the unsigned instruction payload.
///
/// The pool stays `awaitingFunding`. This plan is not a funding result.
pub async fn prepare_funding(
	connection: &impl Connection,
	rewards: &Rewards,
	creator_id: Uuid,
	action_id: Uuid,
	creator_wallet: &str,
) -> Result<RewardFundingPlan, RewardsError> {
	let action = owned_action(connection, creator_id, action_id).await?;
	let mut pool = pool_for_action(connection, action.id)
		.await?
		.ok_or(RewardsError::Authoring(
			ActionAuthoringProblem::RewardNeedsDraft,
		))?;
	if !matches!(
		parse_status(&pool.status),
		Some(RewardPoolStatus::Draft | RewardPoolStatus::AwaitingFunding)
	) {
		return Err(RewardsError::Authoring(
			ActionAuthoringProblem::RewardTermsLocked,
		));
	}
	let creator = parse_address(creator_wallet)?;
	let (escrow, _bump) = derived_escrow(rewards, &creator, pool.chain_pool_id)?;
	pool.status = name(&RewardPoolStatus::AwaitingFunding);
	pool.creator_wallet = Some(creator.to_string());
	pool.escrow_address = Some(escrow.to_string());
	pool.funding_signature = None;
	pool.funded_at = None;
	pool.updated_at = Utc::now();
	pool.save(connection).await?;
	Ok(RewardFundingPlan {
		pool_id: pool.chain_pool_id,
		cluster: rewards.cluster,
		escrow_address: escrow.to_string(),
		creator_wallet: creator.to_string(),
		arbiter_address: pool.arbiter_address.clone(),
		mint: pool.mint.clone(),
		token_symbol: pool.token_symbol.clone(),
		decimals: pool.decimals,
		total_atoms: pool.amount_per_payout.saturating_mul(pool.max_payouts),
		expires_at: pool.expires_at,
		refund_after: pool.refund_after,
		unsigned_transaction: hex(&open_escrow_data(&pool, &creator)),
	})
}

/// Funds the pool only when the finalized escrow matches the row.
///
/// `signature` is stored for audit after the match, and a `local-dev-`
/// prefix is not stored. A signature without a matching account leaves the
/// pool awaiting funding.
pub async fn confirm_funding(
	connection: &impl Connection,
	rewards: &Rewards,
	creator_id: Uuid,
	action_id: Uuid,
	signature: &str,
) -> Result<RewardPoolView, RewardsError> {
	let action = owned_action(connection, creator_id, action_id).await?;
	let mut pool = pool_for_action(connection, action.id)
		.await?
		.ok_or(RewardsError::Reward(RewardProblem::PoolNotFound))?;
	if parse_status(&pool.status) != Some(RewardPoolStatus::AwaitingFunding) {
		return Err(RewardsError::Reward(RewardProblem::PoolNotAwaitingFunding));
	}
	if !rewards.chain_ready() {
		return Err(RewardsError::Unavailable);
	}
	let expected = expected_from_pool(rewards, &pool)?;
	let escrow_address = expected_address(&pool)?;
	let (account, vault) = read_escrow_parts(
		&rewards.gateway,
		&expected,
		escrow_address,
		Commitment::Finalized,
	)
	.await
	.map_err(|_| RewardsError::Reward(RewardProblem::EscrowNotFound))?;
	if inspect_funding(&expected, escrow_address, account.as_ref(), vault.as_ref()).is_err() {
		return Err(RewardsError::Reward(RewardProblem::EscrowMismatch));
	}
	let now = Utc::now();
	pool.status = name(&RewardPoolStatus::Funded);
	pool.funded_at = Some(now);
	pool.funding_signature = confirmed_release_signature(signature, true).map(str::to_owned);
	pool.updated_at = now;
	pool.save(connection).await?;
	Ok(pool_view(&pool))
}

/// Stops new reservations. The returned plan does not move the chain expiry.
pub async fn end_early(
	connection: &impl Connection,
	_rewards: &Rewards,
	creator_id: Uuid,
	action_id: Uuid,
) -> Result<RewardEndPlan, RewardsError> {
	let action = owned_action(connection, creator_id, action_id).await?;
	let mut pool = pool_for_action(connection, action.id)
		.await?
		.ok_or(RewardsError::Reward(RewardProblem::PoolNotFound))?;
	if parse_status(&pool.status) != Some(RewardPoolStatus::Funded) {
		return Err(RewardsError::Reward(RewardProblem::PoolEnded));
	}
	let now = Utc::now();
	pool.status = name(&RewardPoolStatus::Ended);
	pool.expires_at = now;
	pool.updated_at = now;
	pool.save(connection).await?;
	Ok(RewardEndPlan {
		pool_id: pool.chain_pool_id,
		expires_at: pool.expires_at,
		refund_after: pool.refund_after,
		unsigned_transaction: hex(&[2]),
	})
}

/// Assigns the next payout index, or returns the index this attempt already has.
pub async fn reserve_payout(
	connection: &impl Connection,
	rewards: &Rewards,
	chain_pool_id: Uuid,
	attempt_id: Uuid,
	account_id: Uuid,
) -> Result<ReservedPayout, RewardsError> {
	if let Some(existing) = RewardPayoutRow::query()
		.filter(|row| row.attempt_id.eq(attempt_id))
		.first(connection)
		.await?
	{
		let pool = RewardPoolRow::get(connection, existing.pool_id).await?;
		return Ok(reserved(&existing, pool.chain_pool_id));
	}
	let mut pool = RewardPoolRow::query()
		.filter(|row| row.chain_pool_id.eq(chain_pool_id))
		.first(connection)
		.await?
		.ok_or(RewardsError::Reward(RewardProblem::PoolNotFound))?;
	if parse_status(&pool.status) != Some(RewardPoolStatus::Funded) {
		return Err(RewardsError::Reward(RewardProblem::PoolEnded));
	}
	let wins = RewardPayoutRow::query()
		.filter(|row| row.pool_id.eq(pool.id) & row.account_id.eq(account_id))
		.all(connection)
		.await?
		.len();
	if i64::try_from(wins).unwrap_or(i64::MAX) >= pool.max_wins_per_account {
		return Err(RewardsError::Conflict("accountLimitReached"));
	}
	let index = u16::try_from(pool.payouts_reserved).unwrap_or(u16::MAX);
	if i64::from(index) >= pool.max_payouts {
		return Err(RewardsError::Conflict("poolEmpty"));
	}
	let wallet = PayoutWalletRow::query()
		.filter(|row| row.account_id.eq(account_id))
		.first(connection)
		.await?;
	let accepted = false;
	let status = if review_blocks_release(
		pool.amount_per_payout,
		Some(rewards.review_threshold_atoms),
		accepted,
	) {
		RewardPayoutStatus::HeldForReview
	} else if wallet.is_none() {
		RewardPayoutStatus::AwaitingWallet
	} else {
		RewardPayoutStatus::Reserved
	};
	let now = Utc::now();
	let action = ActionRow::get(connection, pool.action_id).await?;
	pool.payouts_reserved = i64::from(index) + 1;
	pool.updated_at = now;
	pool.save(connection).await?;
	let payout = NewRewardPayoutRow {
		pool_id: pool.id,
		attempt_id,
		account_id,
		payout_index: i64::from(index),
		amount: pool.amount_per_payout,
		status: name(&status),
		action_title: action.title,
		recipient_wallet: wallet.map(|wallet| wallet.wallet_address),
		release_signature: None,
		person_accepted_at: None,
		person_accepted_by: None,
		payable_until: pool.refund_after,
		created_at: now,
		updated_at: now,
	}
	.insert(connection)
	.await?;
	Ok(reserved(&payout, pool.chain_pool_id))
}

/// Records that a different person accepted a held payout. This does not release it.
pub async fn accept_review(
	connection: &impl Connection,
	reviewer_id: Uuid,
	payout_id: Uuid,
) -> Result<RewardPayoutView, RewardsError> {
	let mut payout =
		RewardPayoutRow::get(connection, leptoskit_db::Id::from_uuid(payout_id)).await?;
	if payout.account_id == reviewer_id {
		return Err(RewardsError::Reward(RewardProblem::RewardsUnavailable));
	}
	let now = Utc::now();
	payout.person_accepted_at = Some(now);
	payout.person_accepted_by = Some(reviewer_id);
	payout.updated_at = now;
	payout.save(connection).await?;
	let pool = RewardPoolRow::get(connection, payout.pool_id).await?;
	Ok(payout_view(&payout, &pool))
}

/// Tries to settle `payout_id` from finalized chain state.
///
/// The stored index is reused. A missing signer, a review hold, or a chain
/// mismatch does not mark the payout released.
pub async fn release_payout(
	connection: &impl Connection,
	rewards: &Rewards,
	payout_id: Uuid,
) -> Result<ReleaseReport, RewardsError> {
	let mut payout =
		RewardPayoutRow::get(connection, leptoskit_db::Id::from_uuid(payout_id)).await?;
	let mut pool = RewardPoolRow::get(connection, payout.pool_id).await?;
	if parse_payout(&payout.status) == Some(RewardPayoutStatus::Released) {
		return Ok(ReleaseReport {
			payout: payout_view(&payout, &pool),
			outcome: ReleaseOutcome::AlreadyReleased,
		});
	}
	let accepted = payout.person_accepted_at.is_some();
	if review_blocks_release(
		pool.amount_per_payout,
		Some(rewards.review_threshold_atoms),
		accepted,
	) {
		return hold(connection, &mut payout, &pool, ReleaseCodeHold::Review).await;
	}
	let Some(recipient) = payout.recipient_wallet.clone() else {
		return hold(connection, &mut payout, &pool, ReleaseCodeHold::Wallet).await;
	};
	if Address::from_str(&recipient).is_err() {
		return finish(
			connection,
			&mut payout,
			&pool,
			ReleaseOutcome::Failed {
				code: decide::ReleaseCode::InvalidRecipient,
				retryable: false,
			},
		)
		.await;
	}
	if !rewards.chain_ready() {
		return Err(RewardsError::Unavailable);
	}
	let expected = expected_from_pool(rewards, &pool)?;
	let escrow_address = expected_address(&pool)?;
	let (finalized, vault) = read_escrow_parts(
		&rewards.gateway,
		&expected,
		escrow_address,
		Commitment::Finalized,
	)
	.await
	.map_err(RewardsError::from)?;
	let (confirmed, _) = read_escrow_parts(
		&rewards.gateway,
		&expected,
		escrow_address,
		Commitment::Confirmed,
	)
	.await
	.map_err(RewardsError::from)?;
	let outcome = decide::decide_release(&decide::ReleaseInput {
		expected,
		finalized,
		confirmed,
		vault,
		escrow_address,
		index: u16::try_from(payout.payout_index).unwrap_or(u16::MAX),
		recorded_released: u16::try_from(pool.payouts_released).unwrap_or(0),
		now_unix: Utc::now().timestamp(),
		signer_available: false,
	});
	if matches!(outcome, ReleaseOutcome::AlreadyReleased) {
		pool.payouts_released += 1;
		pool.updated_at = Utc::now();
		pool.save(connection).await?;
	}
	finish(connection, &mut payout, &pool, outcome).await
}

/// Issues the text a wallet signs to link a payout address.
///
/// The signature does not fund an escrow and does not move tokens.
pub async fn create_wallet_challenge(
	connection: &impl Connection,
	account_id: Uuid,
	wallet_address: &str,
) -> Result<PayoutWalletLinkChallengeView, RewardsError> {
	let address = parse_address(wallet_address)?;
	let nonce = Uuid::new_v4().to_string();
	let message = wallet_message(&address.to_string(), &nonce);
	let now = Utc::now();
	NewWalletLinkChallengeRow {
		account_id,
		wallet_address: address.to_string(),
		nonce: nonce.clone(),
		message: message.clone(),
		expires_at: now + Duration::minutes(10),
		created_at: now,
	}
	.insert(connection)
	.await?;
	Ok(PayoutWalletLinkChallengeView {
		wallet_address: address.to_string(),
		message,
		nonce,
		expires_at: now + Duration::minutes(10),
	})
}

/// Links the wallet when the signature matches the stored challenge.
pub async fn link_payout_wallet(
	connection: &impl Connection,
	account_id: Uuid,
	wallet_address: &str,
	signature: &str,
) -> Result<PayoutWalletView, RewardsError> {
	let address = parse_address(wallet_address)?;
	let signature = signature
		.parse::<Signature>()
		.map_err(|_| RewardsError::Conflict("invalidRequest"))?;
	let challenge = WalletLinkChallengeRow::query()
		.filter(|row| row.account_id.eq(account_id) & row.wallet_address.eq(address.to_string()))
		.order_by(|row| row.created_at.desc())
		.first(connection)
		.await?
		.ok_or(RewardsError::NotFound)?;
	if challenge.expires_at < Utc::now() {
		return Err(RewardsError::Conflict("invalidRequest"));
	}
	verify(&address, challenge.message.as_bytes(), &signature)
		.map_err(|_| RewardsError::Conflict("invalidRequest"))?;
	let now = Utc::now();
	if let Some(mut existing) = PayoutWalletRow::query()
		.filter(|row| row.account_id.eq(account_id))
		.first(connection)
		.await?
	{
		existing.wallet_address = address.to_string();
		existing.linked_at = now;
		existing.save(connection).await?;
		return Ok(wallet_view(&existing));
	}
	let row = NewPayoutWalletRow {
		account_id,
		wallet_address: address.to_string(),
		label: "Payout wallet".to_owned(),
		linked_at: now,
	}
	.insert(connection)
	.await?;
	Ok(wallet_view(&row))
}

/// The creator's pool view.
pub async fn reward_pool(
	connection: &impl Read,
	creator_id: Uuid,
	action_id: Uuid,
) -> Result<RewardPoolView, RewardsError> {
	let action = owned_action(connection, creator_id, action_id).await?;
	let pool = pool_for_action(connection, action.id)
		.await?
		.ok_or(RewardsError::Reward(RewardProblem::PoolNotFound))?;
	Ok(pool_view(&pool))
}

/// Payouts reserved for `account_id`.
pub async fn list_payouts(
	connection: &impl Read,
	account_id: Uuid,
) -> Result<Vec<RewardPayoutView>, RewardsError> {
	let payouts = RewardPayoutRow::query()
		.filter(|row| row.account_id.eq(account_id))
		.order_by(|row| row.created_at.desc())
		.all(connection)
		.await?;
	let mut views = Vec::with_capacity(payouts.len());
	for payout in payouts {
		let pool = RewardPoolRow::get(connection, payout.pool_id).await?;
		views.push(payout_view(&payout, &pool));
	}
	Ok(views)
}

fn wallet_message(address: &str, nonce: &str) -> String {
	format!("Verily payout wallet\nAddress: {address}\nNonce: {nonce}\n")
}

fn wallet_view(row: &PayoutWalletRow) -> PayoutWalletView {
	PayoutWalletView {
		wallet_address: row.wallet_address.clone(),
		label: row.label.clone(),
		linked_at: row.linked_at,
	}
}

enum ReleaseCodeHold {
	Review,
	Wallet,
}

async fn hold(
	connection: &impl Connection,
	payout: &mut RewardPayoutRow,
	pool: &RewardPoolRow,
	hold: ReleaseCodeHold,
) -> Result<ReleaseReport, RewardsError> {
	let (status, code) = match hold {
		ReleaseCodeHold::Review => (
			RewardPayoutStatus::HeldForReview,
			decide::ReleaseCode::ReleaseRejected,
		),
		ReleaseCodeHold::Wallet => (
			RewardPayoutStatus::AwaitingWallet,
			decide::ReleaseCode::InvalidRecipient,
		),
	};
	payout.status = name(&status);
	payout.updated_at = Utc::now();
	payout.save(connection).await?;
	Ok(ReleaseReport {
		payout: payout_view(payout, pool),
		outcome: ReleaseOutcome::Failed {
			code,
			retryable: false,
		},
	})
}

async fn finish(
	connection: &impl Connection,
	payout: &mut RewardPayoutRow,
	pool: &RewardPoolRow,
	outcome: ReleaseOutcome,
) -> Result<ReleaseReport, RewardsError> {
	payout.status = match &outcome {
		ReleaseOutcome::AlreadyReleased => name(&RewardPayoutStatus::Released),
		ReleaseOutcome::Failed {
			retryable: true, ..
		} => name(&RewardPayoutStatus::Releasing),
		ReleaseOutcome::Failed {
			retryable: false, ..
		} => name(&RewardPayoutStatus::Failed),
	};
	payout.release_signature = None;
	payout.updated_at = Utc::now();
	payout.save(connection).await?;
	Ok(ReleaseReport {
		payout: payout_view(payout, pool),
		outcome,
	})
}

impl From<crate::chain::ChainFailure> for RewardsError {
	fn from(failure: crate::chain::ChainFailure) -> Self {
		match failure {
			crate::chain::ChainFailure::Unavailable => Self::Unavailable,
			_ => Self::Reward(RewardProblem::EscrowNotFound),
		}
	}
}

fn reserved(payout: &RewardPayoutRow, chain_pool_id: Uuid) -> ReservedPayout {
	ReservedPayout {
		payout_index: u16::try_from(payout.payout_index).unwrap_or(u16::MAX),
		chain_pool_id,
		view: RewardPayoutView {
			id: payout.id.uuid(),
			attempt_id: payout.attempt_id,
			action_title: payout.action_title.clone(),
			cluster: RewardCluster::Devnet,
			token_symbol: "USDC".to_owned(),
			decimals: 6,
			amount: payout.amount,
			status: parse_payout(&payout.status).unwrap_or(RewardPayoutStatus::Failed),
			recipient_wallet: payout.recipient_wallet.clone(),
			release_signature: payout.release_signature.clone(),
			created_at: payout.created_at,
			updated_at: payout.updated_at,
			payable_until: payout.payable_until,
		},
	}
}

fn payout_view(payout: &RewardPayoutRow, pool: &RewardPoolRow) -> RewardPayoutView {
	let mut view = reserved(payout, pool.chain_pool_id).view;
	view.cluster = parse_cluster(&pool.cluster).unwrap_or(RewardCluster::Devnet);
	view.token_symbol = pool.token_symbol.clone();
	view.decimals = pool.decimals;
	view
}

fn pool_view(pool: &RewardPoolRow) -> RewardPoolView {
	RewardPoolView {
		pool_id: pool.chain_pool_id,
		status: parse_status(&pool.status).unwrap_or(RewardPoolStatus::Draft),
		cluster: parse_cluster(&pool.cluster).unwrap_or(RewardCluster::Devnet),
		mint: pool.mint.clone(),
		token_symbol: pool.token_symbol.clone(),
		decimals: pool.decimals,
		amount_per_payout: pool.amount_per_payout,
		max_payouts: pool.max_payouts,
		max_wins_per_account: pool.max_wins_per_account,
		payouts_reserved: pool.payouts_reserved,
		payouts_released: pool.payouts_released,
		expires_at: pool.expires_at,
		refund_after: pool.refund_after,
		creator_wallet: pool.creator_wallet.clone(),
		escrow_address: pool.escrow_address.clone(),
		funding_signature: pool.funding_signature.clone(),
		funded_at: pool.funded_at,
	}
}

async fn opportunity(
	connection: &impl Read,
	rewards: &Rewards,
	action: &ActionRow,
	viewer: Uuid,
) -> Result<ActionOpportunity, RewardsError> {
	let pool = pool_for_action(connection, action.id).await?;
	let creator = viewer == action.creator_id;
	let reward = match &pool {
		Some(pool) if creator || pool_is_public(pool) => {
			Some(summary(connection, rewards, pool, viewer).await?)
		}
		_ => None,
	};
	Ok(ActionOpportunity {
		id: action.id.uuid(),
		creator_display_name: action.creator_display_name.clone(),
		viewer_is_creator: creator,
		action_key: action.action_key.clone(),
		revision: action.revision,
		status: parse_action(&action.status).unwrap_or(ActionDefinitionStatus::Draft),
		title: action.title.clone(),
		description: action.description.clone(),
		recurrence: parse_recurrence(&action.recurrence).unwrap_or(ActionRecurrence::Once),
		time_zone: action.time_zone.clone(),
		max_verified_completions: action.max_verified_completions,
		verified_completions: action.verified_completions,
		opens_at: action.opens_at,
		closes_at: action.closes_at,
		published_at: action.published_at,
		updated_at: action.updated_at,
		requirements: requirement_views(&load_requirements(action)?),
		my_attempt: None,
		reward,
	})
}

async fn summary(
	connection: &impl Read,
	_rewards: &Rewards,
	pool: &RewardPoolRow,
	viewer: Uuid,
) -> Result<RewardSummary, RewardsError> {
	let mine = RewardPayoutRow::query()
		.filter(|row| row.pool_id.eq(pool.id) & row.account_id.eq(viewer))
		.all(connection)
		.await?
		.len();
	Ok(RewardSummary {
		cluster: parse_cluster(&pool.cluster).unwrap_or(RewardCluster::Devnet),
		mint: pool.mint.clone(),
		token_symbol: pool.token_symbol.clone(),
		decimals: pool.decimals,
		amount_per_payout: pool.amount_per_payout,
		max_payouts: pool.max_payouts,
		payouts_remaining: pool.max_payouts.saturating_sub(pool.payouts_reserved),
		max_wins_per_account: pool.max_wins_per_account,
		my_wins: i64::try_from(mine).unwrap_or(i64::MAX),
		status: parse_status(&pool.status).unwrap_or(RewardPoolStatus::Draft),
		expires_at: pool.expires_at,
		refund_delay_days: pool.refund_delay_days,
		escrow_address: pool.escrow_address.clone(),
	})
}

fn pool_is_public(pool: &RewardPoolRow) -> bool {
	matches!(
		parse_status(&pool.status),
		Some(RewardPoolStatus::Funded | RewardPoolStatus::Ended | RewardPoolStatus::Closed)
	)
}

fn requirement_views(stored: &[StoredRequirement]) -> Vec<ActionRequirementView> {
	stored
		.iter()
		.enumerate()
		.map(|(position, stored)| requirement_view(stored, i64::try_from(position).unwrap_or(0)))
		.collect()
}

fn requirement_view(stored: &StoredRequirement, position: i64) -> ActionRequirementView {
	let draft = &stored.draft;
	ActionRequirementView {
		id: stored.id,
		requirement_key: draft.requirement_key.clone(),
		kind: draft.kind,
		title: draft.title.clone(),
		instructions: draft.instructions.clone(),
		position,
		is_required: draft.is_required,
		latitude: draft.latitude,
		longitude: draft.longitude,
		radius_meters: draft.radius_meters,
		max_accuracy_meters: draft.max_accuracy_meters,
		min_duration_seconds: draft.min_duration_seconds,
		max_duration_seconds: draft.max_duration_seconds,
		verification_policy: draft.verification_policy,
		verification_prompt: draft.verification_prompt.clone(),
		min_confidence: draft.min_confidence,
		venue_code_configured: draft.qr_code.as_ref().map(|code| !code.is_empty()),
		spoken_challenge_required: draft.spoken_challenge_required.unwrap_or(false),
		accepted_content_types: None,
		max_byte_length: None,
		movement_kind: draft.movement_kind,
		motion_type: draft.motion_type,
		motion_axis: draft.motion_axis,
		target_repetitions: draft.target_repetitions,
		min_angular_speed_radians_per_second: draft.min_angular_speed_radians_per_second,
		max_angular_speed_radians_per_second: draft.max_angular_speed_radians_per_second,
		min_axis_dominance: draft.min_axis_dominance,
		min_free_fall_milliseconds: draft.min_free_fall_milliseconds,
		max_free_fall_milliseconds: draft.max_free_fall_milliseconds,
		min_peak_acceleration_meters_per_second_squared: draft
			.min_peak_acceleration_meters_per_second_squared,
		max_peak_acceleration_meters_per_second_squared: draft
			.max_peak_acceleration_meters_per_second_squared,
		app_id: draft.app_id,
		app_name: None,
		app_available: None,
		app_verification_mode: draft.app_verification_mode,
		local_check: draft.local_check.clone(),
		local_check_model: None,
	}
}

async fn insert_pool(
	connection: &impl Connection,
	rewards: &Rewards,
	action: &ActionRow,
	terms: &RewardTermsDraft,
	now: DateTime<Utc>,
) -> Result<RewardPoolRow, RewardsError> {
	let mut pool = blank_pool(rewards, action, terms, now)?;
	pool.chain_pool_id = Uuid::new_v4();
	Ok(pool.insert(connection).await?)
}

fn blank_pool(
	rewards: &Rewards,
	action: &ActionRow,
	terms: &RewardTermsDraft,
	now: DateTime<Utc>,
) -> Result<NewRewardPoolRow, RewardsError> {
	let refund_after = terms
		.expires_at
		.checked_add_signed(Duration::days(terms.refund_delay_days))
		.ok_or(RewardsError::Authoring(
			ActionAuthoringProblem::InvalidRequest,
		))?;
	Ok(NewRewardPoolRow {
		action_id: action.id,
		creator_id: action.creator_id,
		chain_pool_id: Uuid::nil(),
		status: name(&RewardPoolStatus::Draft),
		cluster: name(&rewards.cluster),
		mint: rewards.mint.clone(),
		token_symbol: rewards.token_symbol.to_owned(),
		decimals: rewards.decimals,
		amount_per_payout: terms.amount_per_payout,
		max_payouts: terms.max_payouts,
		max_wins_per_account: terms.max_wins_per_account,
		payouts_reserved: 0,
		payouts_released: 0,
		expires_at: terms.expires_at,
		refund_after,
		refund_delay_days: terms.refund_delay_days,
		creator_wallet: None,
		escrow_address: None,
		funding_signature: None,
		funded_at: None,
		arbiter_address: rewards.arbiter.clone(),
		created_at: now,
		updated_at: now,
	})
}

fn apply_terms(
	pool: &mut RewardPoolRow,
	rewards: &Rewards,
	terms: &RewardTermsDraft,
) -> Result<(), RewardsError> {
	let refund_after = terms
		.expires_at
		.checked_add_signed(Duration::days(terms.refund_delay_days))
		.ok_or(RewardsError::Authoring(
			ActionAuthoringProblem::InvalidRequest,
		))?;
	pool.amount_per_payout = terms.amount_per_payout;
	pool.max_payouts = terms.max_payouts;
	pool.max_wins_per_account = terms.max_wins_per_account;
	pool.expires_at = terms.expires_at;
	pool.refund_after = refund_after;
	pool.refund_delay_days = terms.refund_delay_days;
	pool.mint = rewards.mint.clone();
	pool.cluster = name(&rewards.cluster);
	pool.arbiter_address = rewards.arbiter.clone();
	Ok(())
}

fn validate_request(request: &CreateActionDefinitionRequest) -> Result<(), RewardsError> {
	if request.action_key.is_empty()
		|| request.action_key.len() > 80
		|| request.title.is_empty()
		|| request.title.len() > 160
		|| request.description.len() > 4000
		|| request.requirements.is_empty()
	{
		return Err(RewardsError::Authoring(
			ActionAuthoringProblem::InvalidRequest,
		));
	}
	if let Some(terms) = &request.reward {
		validate_terms(terms, Utc::now())?;
	}
	Ok(())
}

fn validate_terms(terms: &RewardTermsDraft, now: Timestamp) -> Result<(), RewardsError> {
	let amount = u64::try_from(terms.amount_per_payout).ok();
	let count = u16::try_from(terms.max_payouts).ok();
	let budget_ok = amount
		.zip(count)
		.and_then(|(amount, count)| amount.checked_mul(u64::from(count)))
		.is_some();
	let lifetime_ok = terms.expires_at >= now + Duration::hours(1)
		&& terms.expires_at <= now + Duration::days(365);
	if !budget_ok
		|| terms.amount_per_payout < 1
		|| terms.amount_per_payout > decide::MAX_AMOUNT_PER_PAYOUT_ATOMS
		|| terms.max_payouts < 1
		|| terms.max_payouts > i64::from(decide::MAX_PAYOUTS)
		|| terms.max_wins_per_account < 1
		|| terms.max_wins_per_account > decide::MAX_WINS_PER_ACCOUNT
		|| terms.refund_delay_days < decide::MIN_REFUND_DELAY_DAYS
		|| terms.refund_delay_days > decide::MAX_REFUND_DELAY_DAYS
		|| !lifetime_ok
	{
		return Err(RewardsError::Authoring(
			ActionAuthoringProblem::InvalidRequest,
		));
	}
	Ok(())
}

fn expected_from_pool(
	rewards: &Rewards,
	pool: &RewardPoolRow,
) -> Result<ExpectedEscrow, RewardsError> {
	let creator = pool
		.creator_wallet
		.as_deref()
		.and_then(|wallet| wallet.parse().ok())
		.ok_or(RewardsError::Reward(RewardProblem::EscrowMismatch))?;
	Ok(ExpectedEscrow {
		program: rewards.program_id(),
		creator,
		arbiter: rewards
			.arbiter_address()
			.or_else(|| pool.arbiter_address.parse().ok())
			.ok_or(RewardsError::Unavailable)?,
		mint: rewards.mint_address(),
		pool_id: *pool.chain_pool_id.as_bytes(),
		amount_per_payout: u64::try_from(pool.amount_per_payout).unwrap_or(0),
		max_payouts: u16::try_from(pool.max_payouts).unwrap_or(0),
		expires_at: pool.expires_at.timestamp(),
		refund_after: pool.refund_after.timestamp(),
		refund_delay: u32::try_from(pool.refund_delay_days.saturating_mul(86_400)).unwrap_or(0),
	})
}

fn expected_address(pool: &RewardPoolRow) -> Result<Address, RewardsError> {
	pool.escrow_address
		.as_deref()
		.and_then(|address| address.parse().ok())
		.ok_or(RewardsError::Reward(RewardProblem::EscrowNotFound))
}

fn derived_escrow(
	rewards: &Rewards,
	creator: &Address,
	pool_id: Uuid,
) -> Result<(Address, u8), RewardsError> {
	decide::escrow_address(&rewards.program_id(), creator, pool_id.as_bytes())
		.ok_or(RewardsError::Unavailable)
}

fn open_escrow_data(pool: &RewardPoolRow, creator: &Address) -> Vec<u8> {
	let _ = creator;
	let mut data = Vec::with_capacity(71);
	data.push(0);
	data.extend_from_slice(pool.chain_pool_id.as_bytes());
	if let Ok(arbiter) = pool.arbiter_address.parse::<Address>() {
		data.extend_from_slice(arbiter.as_bytes());
	}
	data.extend_from_slice(
		&u64::try_from(pool.amount_per_payout)
			.unwrap_or(0)
			.to_le_bytes(),
	);
	data.extend_from_slice(&u16::try_from(pool.max_payouts).unwrap_or(0).to_le_bytes());
	data.extend_from_slice(&pool.expires_at.timestamp().to_le_bytes());
	let delay = u32::try_from(pool.refund_delay_days.saturating_mul(86_400)).unwrap_or(0);
	data.extend_from_slice(&delay.to_le_bytes());
	data
}

fn parse_address(value: &str) -> Result<Address, RewardsError> {
	value
		.parse()
		.map_err(|_| RewardsError::Authoring(ActionAuthoringProblem::InvalidRequest))
}

async fn owned_action(
	connection: &impl Read,
	creator_id: Uuid,
	action_id: Uuid,
) -> Result<ActionRow, RewardsError> {
	let action = ActionRow::get(connection, leptoskit_db::Id::from_uuid(action_id)).await?;
	if action.creator_id != creator_id {
		return Err(RewardsError::NotFound);
	}
	Ok(action)
}

async fn pool_for_action(
	connection: &impl Read,
	action_id: leptoskit_db::Id<ActionRow>,
) -> Result<Option<RewardPoolRow>, RewardsError> {
	Ok(RewardPoolRow::query()
		.filter(|row| row.action_id.eq(action_id))
		.first(connection)
		.await?)
}

fn store_requirements(
	drafts: &[ActionRequirementDraft],
	previous: &[StoredRequirement],
) -> Result<String, RewardsError> {
	let stored: Vec<StoredRequirement> = drafts
		.iter()
		.map(|draft| StoredRequirement {
			id: previous
				.iter()
				.find(|stored| stored.draft.requirement_key == draft.requirement_key)
				.map(|stored| stored.id)
				.unwrap_or_else(Uuid::new_v4),
			draft: draft.clone(),
		})
		.collect();
	serde_json::to_string(&stored)
		.map_err(|_| RewardsError::Authoring(ActionAuthoringProblem::InvalidRequest))
}

fn load_requirements(action: &ActionRow) -> Result<Vec<StoredRequirement>, RewardsError> {
	serde_json::from_str(&action.requirements_json).map_err(|_| RewardsError::Store)
}

fn name<T: Serialize>(value: &T) -> String {
	serde_json::to_value(value)
		.ok()
		.and_then(|value| value.as_str().map(str::to_owned))
		.unwrap_or_default()
}

fn parse_status(value: &str) -> Option<RewardPoolStatus> {
	serde_json::from_value(serde_json::Value::String(value.to_owned())).ok()
}

fn parse_payout(value: &str) -> Option<RewardPayoutStatus> {
	serde_json::from_value(serde_json::Value::String(value.to_owned())).ok()
}

fn parse_action(value: &str) -> Option<ActionDefinitionStatus> {
	serde_json::from_value(serde_json::Value::String(value.to_owned())).ok()
}

fn parse_cluster(value: &str) -> Option<RewardCluster> {
	serde_json::from_value(serde_json::Value::String(value.to_owned())).ok()
}

fn parse_recurrence(value: &str) -> Option<ActionRecurrence> {
	serde_json::from_value(serde_json::Value::String(value.to_owned())).ok()
}

fn hex(bytes: &[u8]) -> String {
	const HEX: &[u8; 16] = b"0123456789abcdef";
	let mut out = String::with_capacity(bytes.len() * 2);
	for byte in bytes {
		out.push(HEX[(byte >> 4) as usize] as char);
		out.push(HEX[(byte & 0xf) as usize] as char);
	}
	out
}
