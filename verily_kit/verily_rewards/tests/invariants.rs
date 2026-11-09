//! Funding, index, and review invariants against an in-memory database.

use chrono::{Duration, Utc};
use solana_kit_associated_token_account::{AssociatedTokenSeeds, TOKEN_PROGRAM};
use solana_kit_core::Address;
use solana_kit_core::crypto::Keypair;
use uuid::Uuid;
use verily_rewards::config::DEVNET_USDC_MINT;
use verily_rewards::decide::{DecodedEscrow, encode_escrow, escrow_address};
use verily_rewards::gateway::{PlantedGateway, RawAccount};
use verily_rewards::store::{
	confirm_funding, create_action, create_wallet_challenge, link_payout_wallet, prepare_funding,
	publish_action, release_payout, reserve_payout, reward_pool,
};
use verily_rewards::{Gateway, ReleaseCode, ReleaseOutcome, Rewards, RunMode};
use verily_shared::{
	ActionDefinitionStatus, ActionRecurrence, ActionRequirementDraft, ActionRequirementKind,
	CreateActionDefinitionRequest, RewardPayoutStatus, RewardPoolStatus, RewardTermsDraft,
};

fn request(key: &str) -> CreateActionDefinitionRequest {
	CreateActionDefinitionRequest {
		action_key: key.to_owned(),
		title: "Plant a tree".to_owned(),
		description: "Plant it.".to_owned(),
		recurrence: ActionRecurrence::Once,
		time_zone: "UTC".to_owned(),
		max_verified_completions: None,
		opens_at: None,
		closes_at: None,
		requirements: vec![ActionRequirementDraft::new(
			"photo",
			ActionRequirementKind::Photo,
			"Photo",
			"Take the photo in the app.",
			true,
		)],
		reward: Some(RewardTermsDraft {
			amount_per_payout: 1_000,
			max_payouts: 2,
			max_wins_per_account: 2,
			expires_at: Utc::now() + Duration::days(2),
			refund_delay_days: 3,
		}),
	}
}

fn rewards() -> Rewards {
	let secrets = verily_rewards::config::secrets_from_pairs([(
		"VERILY_REWARD_REVIEW_THRESHOLD_ATOMS",
		"25",
	)]);
	Rewards::from_secrets(&secrets, RunMode::Test)
		.unwrap()
		.with_arbiter(Address::from_bytes([4; 32]))
		.with_planted(PlantedGateway::new())
		.unwrap()
}

#[tokio::test]
async fn publish_waits_for_chain_state_and_an_index_is_assigned_once() {
	let db = leptoskit_db::testing::sqlite().await;
	let creator = Uuid::new_v4();
	let rewards = rewards();
	let created = create_action(&db, &rewards, creator, "Ada", &request("plant"))
		.await
		.unwrap();
	let summary = created.reward.unwrap();
	assert_eq!(summary.mint, DEVNET_USDC_MINT);
	assert!(
		publish_action(&db, &rewards, creator, created.id, created.revision)
			.await
			.is_err()
	);

	let creator_wallet = Address::from_bytes([3; 32]);
	let plan = prepare_funding(
		&db,
		&rewards,
		creator,
		created.id,
		&creator_wallet.to_string(),
	)
	.await
	.unwrap();
	assert!(
		confirm_funding(&db, &rewards, creator, created.id, "local-dev-1")
			.await
			.is_err()
	);
	let waiting = reward_pool(&db, creator, created.id).await.unwrap();
	assert_eq!(waiting.status, RewardPoolStatus::AwaitingFunding);
	assert!(waiting.funding_signature.is_none());

	plant(&rewards, &waiting, creator_wallet);
	let funded = confirm_funding(&db, &rewards, creator, created.id, "local-dev-1")
		.await
		.unwrap();
	assert_eq!(funded.status, RewardPoolStatus::Funded);
	assert!(funded.funding_signature.is_none());
	assert!(funded.escrow_verified());

	let published = publish_action(&db, &rewards, creator, created.id, created.revision)
		.await
		.unwrap();
	assert_eq!(published.status, ActionDefinitionStatus::Active);

	let attempt = Uuid::new_v4();
	let first = reserve_payout(&db, &rewards, plan.pool_id, attempt, creator)
		.await
		.unwrap();
	let again = reserve_payout(&db, &rewards, plan.pool_id, attempt, creator)
		.await
		.unwrap();
	assert_eq!(first.payout_index, 0);
	assert_eq!(again.payout_index, first.payout_index);
	assert_eq!(again.view.id, first.view.id);
	let second = reserve_payout(&db, &rewards, plan.pool_id, Uuid::new_v4(), creator)
		.await
		.unwrap();
	assert_eq!(second.payout_index, 1);

	let release = release_payout(&db, &rewards, first.view.id).await.unwrap();
	assert_ne!(release.payout.status, RewardPayoutStatus::Released);
	assert!(matches!(
		release.outcome,
		ReleaseOutcome::Failed {
			code: ReleaseCode::ReleaseRejected,
			retryable: false,
		}
	));
}

#[tokio::test]
async fn production_refuses_the_planted_gateway() {
	let secrets = verily_rewards::config::secrets_from_pairs(std::iter::empty::<(&str, &str)>());
	let rewards = Rewards::from_secrets(&secrets, RunMode::Production).unwrap();
	assert!(rewards.with_planted(PlantedGateway::new()).is_err());
	let mode = verily_rewards::config::secrets_from_pairs([(
		"VERILY_REWARD_ESCROW_MODE",
		"local-development",
	)]);
	assert!(Rewards::from_secrets(&mode, RunMode::Production).is_err());
}

#[tokio::test]
async fn linking_a_wallet_checks_the_signature_and_does_not_fund_anything() {
	let db = leptoskit_db::testing::sqlite().await;
	let account = Uuid::new_v4();
	let key = Keypair::from_seed(&[9; 32]);
	let challenge = create_wallet_challenge(&db, account, &key.address().to_string())
		.await
		.unwrap();
	let signature = key.sign(challenge.message.as_bytes());
	let linked = link_payout_wallet(
		&db,
		account,
		&key.address().to_string(),
		&signature.to_string(),
	)
	.await
	.unwrap();
	assert_eq!(linked.wallet_address, key.address().to_string());
	assert!(
		link_payout_wallet(
			&db,
			account,
			&key.address().to_string(),
			&key.sign(b"other").to_string()
		)
		.await
		.is_err()
	);
}

fn plant(rewards: &Rewards, pool: &verily_shared::RewardPoolView, creator: Address) {
	let Gateway::Planted(planted) = &rewards.gateway else {
		panic!("the test gateway is planted");
	};
	let program = rewards.program_id();
	let mint = rewards.mint_address();
	let arbiter = rewards.arbiter_address().unwrap();
	let escrow: Address = pool.escrow_address.clone().unwrap().parse().unwrap();
	let pool_id = *pool.pool_id.as_bytes();
	let (derived, bump) = escrow_address(&program, &creator, &pool_id).unwrap();
	assert_eq!(derived, escrow);
	let vault = AssociatedTokenSeeds {
		owner: escrow,
		token_program: TOKEN_PROGRAM,
		mint,
	}
	.find()
	.unwrap()
	.address();
	let delay = u32::try_from((pool.refund_after - pool.expires_at).num_seconds()).unwrap();
	let decoded = DecodedEscrow {
		creator,
		arbiter,
		mint,
		vault,
		pool_id,
		amount_per_payout: u64::try_from(pool.amount_per_payout).unwrap(),
		max_payouts: u16::try_from(pool.max_payouts).unwrap(),
		released_count: 0,
		expires_at: pool.expires_at.timestamp(),
		refund_delay: delay,
		refund_after: pool.refund_after.timestamp(),
		bump,
		released: [0; 256],
	};
	let mut vault_data = vec![0u8; 165];
	vault_data[0..32].copy_from_slice(mint.as_bytes());
	vault_data[32..64].copy_from_slice(escrow.as_bytes());
	vault_data[64..72].copy_from_slice(
		&(decoded.amount_per_payout * u64::from(decoded.max_payouts)).to_le_bytes(),
	);
	vault_data[108] = 1;
	planted.insert(
		escrow,
		RawAccount {
			owner: program,
			data: encode_escrow(&decoded).to_vec(),
			executable: false,
		},
	);
	planted.insert(
		vault,
		RawAccount {
			owner: TOKEN_PROGRAM,
			data: vault_data,
			executable: false,
		},
	);
}

#[tokio::test]
async fn requirement_ids_survive_a_save_and_an_unfunded_reward_is_the_creators_alone() {
	let db = leptoskit_db::testing::sqlite().await;
	let creator = Uuid::new_v4();
	let rewards = rewards();
	let created = create_action(&db, &rewards, creator, "Ada", &request("ids"))
		.await
		.unwrap();
	let action = verily_rewards::schema::ActionRow::query()
		.one(&db)
		.await
		.unwrap();
	let before = verily_rewards::store::requirements(&action).unwrap();
	assert_eq!(before.len(), 1);
	assert_eq!(before[0].id, created.requirements[0].id);

	let saved = verily_rewards::save_action(
		&db,
		&rewards,
		creator,
		created.id,
		created.revision,
		&request("ids"),
	)
	.await
	.unwrap();
	assert_eq!(saved.requirements[0].id, before[0].id);

	let action = verily_rewards::schema::ActionRow::query()
		.one(&db)
		.await
		.unwrap();
	let mine = verily_rewards::store::opportunity(&db, &rewards, &action, creator)
		.await
		.unwrap();
	assert!(mine.viewer_is_creator && mine.reward.is_some());
	let theirs = verily_rewards::store::opportunity(&db, &rewards, &action, Uuid::new_v4())
		.await
		.unwrap();
	assert!(!theirs.viewer_is_creator);
	assert!(
		theirs.reward.is_none(),
		"a pool nobody funded is not advertised"
	);
}
