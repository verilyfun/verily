//! The records the app, backend, verification, and rewards share.

use chrono::TimeZone;
use chrono::Utc;
use serde_json::json;
use verily_shared::ActionRecurrence;
use verily_shared::ActionRequirementDraft;
use verily_shared::ActionRequirementKind;
use verily_shared::CreateActionDefinitionRequest;
use verily_shared::RewardCluster;
use verily_shared::RewardPoolStatus;
use verily_shared::RewardPoolView;
use verily_shared::RewardTermsDraft;
use verily_shared::payout_needs_person;

fn stamp() -> chrono::DateTime<Utc> {
	Utc.with_ymd_and_hms(2026, 11, 8, 12, 0, 0).unwrap()
}

#[test]
fn reward_terms_name_no_mint_and_a_signature_does_not_fund() {
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
	let value = serde_json::to_value(&request).expect("json");
	let reward = &value["reward"];
	assert_eq!(reward["amountPerPayout"], 1_000_000);
	assert_eq!(reward["refundDelayDays"], 3);
	assert!(reward.get("mint").is_none());
	assert!(reward.get("cluster").is_none());

	let awaiting = json!({
		"poolId": "018f4a3e-7c21-7a4e-9c3a-6b1d2e0f4a50",
		"status": "awaitingFunding",
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
		"fundingSignature": "5signedtransactionthattheclientmustnottrust",
	});
	let pool: RewardPoolView = serde_json::from_value(awaiting).expect("pool");
	assert_eq!(pool.status, RewardPoolStatus::AwaitingFunding);
	assert_eq!(pool.cluster, RewardCluster::Devnet);
	assert!(!pool.escrow_verified());
}

#[test]
fn a_missing_review_threshold_does_not_auto_release() {
	assert_eq!(payout_needs_person(1_000_000, None), None);
	assert_eq!(payout_needs_person(1_000_000, Some(1_000_000)), Some(false));
	assert_eq!(payout_needs_person(1_000_001, Some(1_000_000)), Some(true));
}
