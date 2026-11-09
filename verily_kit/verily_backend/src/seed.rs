//! Development seed: a few live actions near [`DEFAULT_LOCATION`], so a fresh
//! `lk dev` has something in the Do catalogue. Debug builds only, no
//! secrets, and safe to run on every start.
//!
//! Rewarded seed actions are funded the way any action is: `verily_rewards`
//! prepares the escrow, the seed plants that escrow in the development
//! gateway (the test double, which production refuses), and
//! `confirm_funding` reads it back from that chain state before the action
//! publishes. Nothing here marks a pool funded by itself, and nothing can
//! release a payout: the arbiter is a key nobody holds.

use leptoskit_db::Db;
use leptoskit_db::Id;
use solana_kit_associated_token_account::AssociatedTokenSeeds;
use solana_kit_associated_token_account::TOKEN_PROGRAM;
use solana_kit_core::Address;
use uuid::Uuid;
use verily_api::ProofKind;
use verily_rewards::Gateway;
use verily_rewards::RawAccount;
use verily_rewards::Rewards;
use verily_rewards::decide::DecodedEscrow;
use verily_rewards::decide::encode_escrow;
use verily_rewards::decide::escrow_address;
use verily_rewards::schema::ActionRow;
use verily_rewards::store;
use verily_shared::ActionDefinitionStatus;
use verily_shared::ActionRecurrence;
use verily_shared::CreateActionDefinitionRequest;
use verily_shared::RewardPoolStatus;
use verily_shared::RewardPoolView;
use verily_shared::RewardTermsDraft;

use crate::schema::NewActionPlace;
use crate::serve::catalogue::requirement_for;

/// Central London: where the seeded actions are, for nearby search.
pub const DEFAULT_LOCATION: (f64, f64) = (51.5074, -0.1278);

/// The seed's creator. Not an account anyone signs in as.
const CREATOR: Uuid = Uuid::from_u128(0x7e51_0000_0000_4000_8000_0000_0000_5eed);
const CREATOR_NAME: &str = "Verily Field Notes";
/// The wallet the seed's escrows name as their creator.
const CREATOR_WALLET: [u8; 32] = [0x5e; 32];

/// Why seeding stopped.
#[derive(Debug, thiserror::Error)]
pub enum SeedError {
	/// The database refused a write.
	#[error(transparent)]
	Db(#[from] leptoskit_db::DbError),
	/// `verily_rewards` refused an action or its funding.
	#[error("rewards refused the seed: {0:?}")]
	Rewards(verily_rewards::RewardsError),
}

impl From<verily_rewards::RewardsError> for SeedError {
	fn from(error: verily_rewards::RewardsError) -> Self {
		Self::Rewards(error)
	}
}

struct SeedAction {
	key: &'static str,
	title: &'static str,
	summary: &'static str,
	place: &'static str,
	point: (f64, f64),
	radius_meters: i64,
	proofs: &'static [ProofKind],
	/// USDC atoms per payout.
	reward_atoms: Option<i64>,
}

const ACTIONS: &[SeedAction] = &[
	SeedAction {
		key: "seed-river-photo",
		title: "Photograph the river from Westminster Bridge",
		summary: "Stand on the bridge and take one photo of the river, upstream or down.",
		place: "Westminster Bridge",
		point: (51.5008, -0.1219),
		radius_meters: 150,
		proofs: &[ProofKind::Photo, ProofKind::Presence],
		reward_atoms: Some(2_000_000),
	},
	SeedAction {
		key: "seed-hyde-park-squats",
		title: "Ten squats at Speakers' Corner",
		summary: "Film ten squats in Hyde Park and say the word on screen.",
		place: "Speakers' Corner, Hyde Park",
		point: (51.5129, -0.1590),
		radius_meters: 200,
		proofs: &[ProofKind::Video],
		reward_atoms: None,
	},
	SeedAction {
		key: "seed-book-market-hello",
		title: "Say hello at the Southbank book market",
		summary: "Record a short hello under Waterloo Bridge, with the word on screen.",
		place: "Southbank Centre Book Market",
		point: (51.5065, -0.1167),
		radius_meters: 100,
		proofs: &[ProofKind::Audio],
		reward_atoms: Some(1_000_000),
	},
	SeedAction {
		key: "seed-barbican-code",
		title: "Find the venue code at the Barbican",
		summary: "Scan the code by the conservatory entrance, then take a photo of the lake.",
		place: "Barbican Centre",
		point: (51.5202, -0.0938),
		radius_meters: 120,
		proofs: &[ProofKind::VenueCode, ProofKind::Photo],
		reward_atoms: None,
	},
];

/// Creates any seed action that is missing, publishes it, and plants the
/// escrows of rewarded ones again (the development gateway forgets them on
/// restart). Returns how many actions it created.
///
/// # Errors
///
/// When the database or `verily_rewards` refuses a write.
pub async fn seed_development(db: &Db, rewards: &Rewards) -> Result<usize, SeedError> {
	let db = db.system("seed development actions");
	let mut created = 0;
	for seed in ACTIONS {
		let existing = ActionRow::query()
			.filter(|row| row.creator_id.eq(CREATOR) & row.action_key.eq(seed.key))
			.first(&db)
			.await?;
		let action = if let Some(action) = existing {
			action
		} else {
			create(&db, rewards, seed).await?;
			created += 1;
			ActionRow::query()
				.filter(|row| row.creator_id.eq(CREATOR) & row.action_key.eq(seed.key))
				.one(&db)
				.await?
		};
		if seed.reward_atoms.is_some()
			&& let Ok(pool) = store::reward_pool(&db, CREATOR, action.id.uuid()).await
		{
			plant_funded_escrow(rewards, &pool, Address::from_bytes(CREATOR_WALLET));
		}
	}
	Ok(created)
}

async fn create(db: &Db, rewards: &Rewards, seed: &SeedAction) -> Result<(), SeedError> {
	let requirements = seed
		.proofs
		.iter()
		.filter_map(|kind| requirement_for(*kind, seed.radius_meters).ok())
		.map(|mut requirement| {
			if requirement.radius_meters.is_some() {
				requirement.latitude = Some(seed.point.0);
				requirement.longitude = Some(seed.point.1);
			}
			requirement
		})
		.collect();
	let planted = matches!(rewards.gateway, Gateway::Planted(_));
	let reward = seed
		.reward_atoms
		.filter(|_| planted)
		.map(|amount_per_payout| RewardTermsDraft {
			amount_per_payout,
			max_payouts: 20,
			max_wins_per_account: 1,
			expires_at: chrono::Utc::now() + chrono::Duration::days(300),
			refund_delay_days: verily_rewards::decide::MIN_REFUND_DELAY_DAYS,
		});
	let request = CreateActionDefinitionRequest {
		action_key: seed.key.to_owned(),
		title: seed.title.to_owned(),
		description: seed.summary.to_owned(),
		recurrence: ActionRecurrence::Once,
		time_zone: "UTC".to_owned(),
		max_verified_completions: None,
		opens_at: None,
		closes_at: None,
		requirements,
		reward,
	};
	let tx = db.begin().await?;
	let draft = store::create_action(&tx, rewards, CREATOR, CREATOR_NAME, &request).await?;
	NewActionPlace {
		action_id: Id::from_uuid(draft.id),
		place_name: seed.place.to_owned(),
		radius_meters: seed.radius_meters,
		latitude: Some(seed.point.0),
		longitude: Some(seed.point.1),
	}
	.insert(&tx)
	.await?;
	if draft.reward.is_some() {
		let wallet = Address::from_bytes(CREATOR_WALLET);
		store::prepare_funding(&tx, rewards, CREATOR, draft.id, &wallet.to_string()).await?;
		let pool = store::reward_pool(&tx, CREATOR, draft.id).await?;
		plant_funded_escrow(rewards, &pool, wallet);
		let funded = store::confirm_funding(&tx, rewards, CREATOR, draft.id, "seed").await?;
		debug_assert_eq!(funded.status, RewardPoolStatus::Funded);
	}
	let published = store::publish_action(&tx, rewards, CREATOR, draft.id, draft.revision).await?;
	debug_assert_eq!(published.status, ActionDefinitionStatus::Active);
	tx.commit().await?;
	Ok(())
}

/// Plants, in the development gateway, the escrow `pool` describes and a
/// vault holding its whole budget: the chain state a creator's funding
/// transaction would leave. Does nothing for any other gateway.
pub fn plant_funded_escrow(rewards: &Rewards, pool: &RewardPoolView, creator: Address) {
	let Gateway::Planted(planted) = &rewards.gateway else {
		return;
	};
	let (Some(arbiter), Some(escrow)) = (
		rewards.arbiter_address(),
		pool.escrow_address
			.as_deref()
			.and_then(|address| address.parse::<Address>().ok()),
	) else {
		return;
	};
	let program = rewards.program_id();
	let mint = rewards.mint_address();
	let pool_id = *pool.pool_id.as_bytes();
	let Some((derived, bump)) = escrow_address(&program, &creator, &pool_id) else {
		return;
	};
	if derived != escrow {
		return;
	}
	let Ok(vault) = AssociatedTokenSeeds {
		owner: escrow,
		token_program: TOKEN_PROGRAM,
		mint,
	}
	.find()
	.map(|found| found.address()) else {
		return;
	};
	let (Ok(amount_per_payout), Ok(max_payouts), Ok(refund_delay)) = (
		u64::try_from(pool.amount_per_payout),
		u16::try_from(pool.max_payouts),
		u32::try_from((pool.refund_after - pool.expires_at).num_seconds()),
	) else {
		return;
	};
	let decoded = DecodedEscrow {
		creator,
		arbiter,
		mint,
		vault,
		pool_id,
		amount_per_payout,
		max_payouts,
		released_count: 0,
		expires_at: pool.expires_at.timestamp(),
		refund_delay,
		refund_after: pool.refund_after.timestamp(),
		bump,
		released: [0; 256],
	};
	let mut vault_data = vec![0_u8; 165];
	vault_data[0..32].copy_from_slice(mint.as_bytes());
	vault_data[32..64].copy_from_slice(escrow.as_bytes());
	vault_data[64..72].copy_from_slice(&(amount_per_payout * u64::from(max_payouts)).to_le_bytes());
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
