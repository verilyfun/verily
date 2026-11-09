//! Payouts, the payout wallet, signing out, and closing the account.

#![allow(
	clippy::assert_is_empty,
	clippy::too_many_lines,
	clippy::similar_names,
	reason = "tests read best as one story per scenario"
)]

mod support;

use support::*;
use verily_api::ActionFilter;
use verily_api::DraftInput;
use verily_api::ProofKind;
use verily_app::ops::BeginAttempt;
use verily_app::ops::CloseAccount;
use verily_app::ops::ListAvailableActions;
use verily_app::ops::ListMyPayouts;
use verily_app::ops::PublishAction;
use verily_app::ops::SaveAction;
use verily_app::ops::SignOut;
use verily_app::ops::WalletStatus;

#[tokio::test]
async fn nobody_signed_out_reads_payouts_or_leaves() {
	let world = world().await;
	let nobody = world.anonymous();
	assert_unauthorized(world.call(&nobody, ListMyPayouts {}).await);
	assert_unauthorized(world.call(&nobody, WalletStatus {}).await);
	assert_unauthorized(world.call(&nobody, SignOut {}).await);
	assert_unauthorized(
		world
			.call(
				&nobody,
				CloseAccount {
					confirmation: "DELETE".to_owned(),
				},
			)
			.await,
	);
}

#[tokio::test]
async fn a_new_account_has_no_payouts_and_no_wallet() {
	let world = world().await;
	let ada = world.person("ada@example.com").await;
	assert!(
		world
			.call(&ada.identity, ListMyPayouts {})
			.await
			.unwrap()
			.is_empty()
	);
	assert!(
		!world
			.call(&ada.identity, WalletStatus {})
			.await
			.unwrap()
			.linked
	);
}

#[tokio::test]
async fn signing_out_ends_this_session_only() {
	let world = world().await;
	let ada = world.person("ada@example.com").await;
	let phone = world.person("ada@example.com").await;
	world.call(&ada.identity, SignOut {}).await.unwrap();
	let system = world.db.system("read sessions in a test");
	let ended = eventually(|| async {
		leptoskit_auth::Session::query()
			.filter(|row| row.id.eq(ada.signed_in.session) & row.revoked_at.is_not_null())
			.exists(&system)
			.await
			.unwrap()
	})
	.await;
	assert!(ended, "the session ends once the call commits");
	let other = leptoskit_auth::Session::query()
		.filter(|row| row.id.eq(phone.signed_in.session) & row.revoked_at.is_null())
		.exists(&system)
		.await
		.unwrap();
	assert!(other, "the other device stays signed in");
}

#[tokio::test]
async fn closing_needs_the_phrase_then_stops_everything_and_keeps_history() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let bea = world.person("bea@example.com").await;
	let saved = world
		.call(
			&ada.identity,
			SaveAction {
				draft: DraftInput {
					id: None,
					title: "Find the oak".to_owned(),
					summary: String::new(),
					place_name: "The old oak".to_owned(),
					radius_meters: 0,
					reward_amount: String::new(),
					proofs: vec![ProofKind::Photo],
				},
			},
		)
		.await
		.unwrap();
	world
		.call(
			&ada.identity,
			PublishAction {
				action_id: saved.id.clone(),
			},
		)
		.await
		.unwrap();
	let all = ListAvailableActions {
		filter: ActionFilter::All,
		latitude: None,
		longitude: None,
	};
	let river = world
		.call(&ada.identity, all.clone())
		.await
		.unwrap()
		.into_iter()
		.find(|card| card.title.contains("Westminster"))
		.unwrap();
	world
		.call(
			&ada.identity,
			BeginAttempt {
				action_id: river.id.clone(),
			},
		)
		.await
		.unwrap();

	for wrong in ["", "delete", "DELETE ME", "yes"] {
		assert_invalid(
			world
				.call(
					&ada.identity,
					CloseAccount {
						confirmation: wrong.to_owned(),
					},
				)
				.await,
			"confirmationMismatch",
		);
	}
	assert_eq!(
		world.call(&bea.identity, all.clone()).await.unwrap().len(),
		5
	);

	world
		.call(
			&ada.identity,
			CloseAccount {
				confirmation: " DELETE ".to_owned(),
			},
		)
		.await
		.unwrap();

	// The live action paused, so nobody starts what nobody will answer.
	assert_eq!(world.call(&bea.identity, all).await.unwrap().len(), 4);
	// Nothing new starts, even on a session that has not ended yet.
	assert_forbidden(
		world
			.call(
				&ada.identity,
				BeginAttempt {
					action_id: river.id,
				},
			)
			.await,
		"accountClosed",
	);

	// Sign-in methods go and the account is disabled once the call commits.
	let system = world.db.system("read accounts in a test");
	let disabled = eventually(|| async {
		leptoskit_auth::Account::query()
			.filter(|row| row.id.eq(ada.account()) & row.disabled_at.is_not_null())
			.exists(&system)
			.await
			.unwrap()
	})
	.await;
	assert!(disabled);
	let emails = leptoskit_auth::EmailAddress::query()
		.filter(|row| row.account_id.eq(ada.account()))
		.count(&system)
		.await
		.unwrap();
	assert_eq!(emails, 0);
	let profile = verily_backend::schema::Account::query()
		.filter(|row| row.id.eq(ada.account()))
		.one(&system)
		.await
		.unwrap();
	assert_eq!(profile.display_name, "Closed account");
	// The attempt stays for audit.
	let attempts = verily_backend::schema::Attempt::query()
		.filter(|row| row.participant_id.eq(ada.account()))
		.count(&system)
		.await
		.unwrap();
	assert_eq!(attempts, 1);

	// Closing again is fine.
	world
		.call(
			&ada.identity,
			CloseAccount {
				confirmation: "DELETE".to_owned(),
			},
		)
		.await
		.unwrap();
}
