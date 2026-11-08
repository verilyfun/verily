//! Account activity and typed identifiers.

use chrono::TimeZone;
use chrono::Utc;
use uuid::Uuid;
use verily_shared::Account;
use verily_shared::AccountClosure;
use verily_shared::AccountClosureStatus;
use verily_shared::AccountId;
use verily_shared::ActionId;
use verily_shared::AttemptId;
use verily_shared::EvidenceId;
use verily_shared::PayoutId;
use verily_shared::PoolId;
use verily_shared::RequirementId;

fn stamp() -> chrono::DateTime<Utc> {
	Utc.with_ymd_and_hms(2026, 11, 8, 12, 0, 0).unwrap()
}

#[test]
fn a_closure_blocks_only_that_account() {
	let id = AccountId::from_uuid(Uuid::from_u128(1));
	let other = AccountId::from_uuid(Uuid::from_u128(2));
	let account = Account {
		id,
		display_name: "Ada".into(),
	};
	assert!(account.is_active(None));

	let closure = AccountClosure {
		account_id: id,
		status: AccountClosureStatus::Closed,
		requested_at: stamp(),
		identity_purged_at: stamp(),
	};
	assert!(!account.is_active(Some(&closure)));

	let other_closure = AccountClosure {
		account_id: other,
		status: AccountClosureStatus::Closed,
		requested_at: stamp(),
		identity_purged_at: stamp(),
	};
	assert!(account.is_active(Some(&other_closure)));
}

#[test]
fn typed_ids_wrap_and_display_their_uuid() {
	let raw = Uuid::parse_str("018f4a3e-7c21-7a4e-9c3a-6b1d2e0f4a50").expect("uuid");
	let account = AccountId::from_uuid(raw);
	let action = ActionId::from_uuid(raw);
	let attempt = AttemptId::from_uuid(raw);
	let requirement = RequirementId::from_uuid(raw);
	let evidence = EvidenceId::from_uuid(raw);
	let pool = PoolId::from_uuid(raw);
	let payout = PayoutId::from_uuid(raw);

	assert_eq!(account.as_uuid(), raw);
	assert_eq!(action.as_uuid(), raw);
	assert_eq!(attempt.as_uuid(), raw);
	assert_eq!(requirement.as_uuid(), raw);
	assert_eq!(evidence.as_uuid(), raw);
	assert_eq!(pool.as_uuid(), raw);
	assert_eq!(payout.as_uuid(), raw);

	let text = raw.to_string();
	assert_eq!(account.to_string(), text);
	assert_eq!(action.to_string(), text);
	assert_eq!(attempt.to_string(), text);
	assert_eq!(requirement.to_string(), text);
	assert_eq!(evidence.to_string(), text);
	assert_eq!(pool.to_string(), text);
	assert_eq!(payout.to_string(), text);
}
