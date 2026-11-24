//! Creator reward pool funding & lifecycle operations on `verily-backend`.
//!
//! All escrow verification stays in `verily_rewards::store` — never trusting
//! client claims of funding and never faking chain confirmation.

use chrono::Utc;
use leptoskit_db::Id;
use leptoskit_rpc as rpc;
use solana_kit_associated_token_account::AssociatedTokenSeeds;
use solana_kit_associated_token_account::TOKEN_PROGRAM;
use verily_api::FundingPlanView;
use verily_api::RewardPoolStatusView;
use verily_rewards::ops::into_rpc;
use verily_rewards::schema::ActionRow;
use verily_rewards::schema::RewardPoolRow;
use verily_rewards::store;
use verily_shared::RewardPoolStatus;

use super::amount_label;
use super::backend;
use super::db;
use super::me;
use super::name;
use super::parse_id;
use super::require_active;

/// Reads the creator's reward pool summary for an action.
pub async fn get_reward_pool(
	cx: &rpc::QueryCx,
	action_id: String,
) -> rpc::Result<RewardPoolStatusView> {
	let creator = me(cx.context())?;
	let action_uuid = parse_id(&action_id)?;
	let pool = store::reward_pool(cx.db(), creator.uuid(), action_uuid)
		.await
		.map_err(into_rpc)?;
	Ok(RewardPoolStatusView {
		pool_id: pool.pool_id.to_string(),
		status: name(&pool.status),
		amount_label: amount_label(pool.amount_per_payout, pool.decimals, &pool.token_symbol),
		max_payouts: pool.max_payouts,
		payouts_released: pool.payouts_released,
		escrow_address: pool.escrow_address,
		funding_signature: pool.funding_signature,
		funded: pool.status == RewardPoolStatus::Funded,
	})
}

/// Derives the escrow and vault addresses a creator wallet signs `OpenEscrow` for.
pub async fn prepare_reward_funding(
	cx: &rpc::MutationCx,
	action_id: String,
	creator_wallet: String,
) -> rpc::Result<FundingPlanView> {
	let creator = me(cx.context())?;
	require_active(cx.tx(), creator).await?;
	let backend = backend(cx.context())?;
	let action_uuid = parse_id(&action_id)?;
	let plan = store::prepare_funding(
		cx.tx(),
		&backend.rewards,
		creator.uuid(),
		action_uuid,
		&creator_wallet,
	)
	.await
	.map_err(into_rpc)?;

	let escrow_addr: solana_kit_core::Address = plan
		.escrow_address
		.parse()
		.map_err(|_| rpc::Error::invalid("invalidRequest"))?;
	let vault_addr = AssociatedTokenSeeds {
		owner: escrow_addr,
		token_program: TOKEN_PROGRAM,
		mint: backend.rewards.mint_address(),
	}
	.find()
	.map_err(|_| rpc::Error::invalid("invalidRequest"))?
	.address();

	let pool = store::reward_pool(cx.tx(), creator.uuid(), action_uuid)
		.await
		.map_err(into_rpc)?;

	Ok(FundingPlanView {
		pool_id: plan.pool_id.to_string(),
		escrow_address: plan.escrow_address,
		vault_address: vault_addr.to_string(),
		mint: plan.mint,
		arbiter: plan.arbiter_address,
		amount_per_payout: pool.amount_per_payout,
		max_payouts: pool.max_payouts,
		expires_at_unix: plan.expires_at.timestamp(),
		refund_delay_seconds: (plan.refund_after - plan.expires_at).num_seconds(),
		unsigned_transaction: plan.unsigned_transaction,
	})
}

/// Verifies on-chain finalized escrow + vault state before marking the pool funded.
pub async fn confirm_reward_funding(
	cx: &rpc::MutationCx,
	action_id: String,
	funding_signature: String,
) -> rpc::Result<RewardPoolStatusView> {
	let creator = me(cx.context())?;
	require_active(cx.tx(), creator).await?;
	let backend = backend(cx.context())?;
	let action_uuid = parse_id(&action_id)?;
	let pool = store::confirm_funding(
		cx.tx(),
		&backend.rewards,
		creator.uuid(),
		action_uuid,
		&funding_signature,
	)
	.await
	.map_err(into_rpc)?;
	Ok(RewardPoolStatusView {
		pool_id: pool.pool_id.to_string(),
		status: name(&pool.status),
		amount_label: amount_label(pool.amount_per_payout, pool.decimals, &pool.token_symbol),
		max_payouts: pool.max_payouts,
		payouts_released: pool.payouts_released,
		escrow_address: pool.escrow_address,
		funding_signature: pool.funding_signature,
		funded: pool.status == RewardPoolStatus::Funded,
	})
}

/// Ends a creator's active reward pool early (closing new reservations).
pub async fn end_reward_early(
	cx: &rpc::MutationCx,
	action_id: String,
) -> rpc::Result<RewardPoolStatusView> {
	let creator = me(cx.context())?;
	require_active(cx.tx(), creator).await?;
	let action_uuid = parse_id(&action_id)?;
	let action = ActionRow::query()
		.filter(|row| {
			row.id.eq(Id::<ActionRow>::from_uuid(action_uuid)) & row.creator_id.eq(creator.uuid())
		})
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	let mut pool = RewardPoolRow::query()
		.filter(|row| row.action_id.eq(action.id))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	let now = Utc::now();
	if pool.expires_at > now {
		pool.expires_at = now;
	}
	pool.status = name(&RewardPoolStatus::Ended);
	pool.updated_at = now;
	pool.save(cx.tx()).await.map_err(db)?;

	Ok(RewardPoolStatusView {
		pool_id: pool.chain_pool_id.to_string(),
		status: pool.status,
		amount_label: amount_label(pool.amount_per_payout, pool.decimals, &pool.token_symbol),
		max_payouts: pool.max_payouts,
		payouts_released: pool.payouts_released,
		escrow_address: pool.escrow_address,
		funding_signature: pool.funding_signature,
		funded: false,
	})
}
