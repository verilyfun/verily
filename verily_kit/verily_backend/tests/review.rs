//! A person deciding proof, the payout that follows, and appeals.

#![allow(
	clippy::assert_is_empty,
	clippy::too_many_lines,
	clippy::similar_names,
	reason = "tests read best as one story per scenario"
)]

mod support;

use support::*;
use verily_api::ActionFilter;
use verily_api::AttemptStatus;
use verily_api::PayoutStatus;
use verily_api::ProofKind;
use verily_app::ops::BeginAttempt;
use verily_app::ops::BeginCapture;
use verily_app::ops::CompleteAttempt;
use verily_app::ops::GetAction;
use verily_app::ops::ListAvailableActions;
use verily_app::ops::ListMyAttempts;
use verily_app::ops::ListMyPayouts;
use verily_app::ops::ListReviewQueue;
use verily_app::ops::ReviewAttempt;
use verily_app::ops::SubmitAppeal;
use verily_app::ops::SubmitLiveProof;

/// `who` does the seeded action titled with `needle` and sends every proof,
/// so it waits for a person. Returns the attempt id.
async fn pending_attempt(world: &World, who: &Person, needle: &str) -> String {
	let cards = world
		.call(
			&who.identity,
			ListAvailableActions {
				filter: ActionFilter::All,
				latitude: None,
				longitude: None,
			},
		)
		.await
		.unwrap();
	let card = cards
		.into_iter()
		.find(|card| card.title.contains(needle))
		.unwrap();
	let detail = world
		.call(
			&who.identity,
			GetAction {
				action_id: card.id.clone(),
			},
		)
		.await
		.unwrap();
	let opened = world
		.call(&who.identity, BeginAttempt { action_id: card.id })
		.await
		.unwrap();
	for (index, proof) in detail.proofs.iter().enumerate() {
		world
			.call(
				&who.identity,
				BeginCapture {
					attempt_id: opened.attempt_id.clone(),
					requirement_id: proof.id.clone(),
				},
			)
			.await
			.unwrap();
		world
			.call(
				&who.identity,
				SubmitLiveProof {
					attempt_id: opened.attempt_id.clone(),
					requirement_id: proof.id.clone(),
					digest_hex: digest(u8::try_from(index).unwrap() + 1),
				},
			)
			.await
			.unwrap();
	}
	let outcome = world
		.call(
			&who.identity,
			CompleteAttempt {
				attempt_id: opened.attempt_id.clone(),
			},
		)
		.await
		.unwrap();
	assert_eq!(outcome.status, AttemptStatus::PendingReview);
	opened.attempt_id
}

fn review(id: &str, accept: bool, note: &str) -> ReviewAttempt {
	ReviewAttempt {
		review_id: id.to_owned(),
		accept,
		note: note.to_owned(),
	}
}

async fn status(world: &World, who: &Person) -> AttemptStatus {
	world.call(&who.identity, ListMyAttempts {}).await.unwrap()[0].status
}

#[tokio::test]
async fn nobody_signed_out_reviews_or_appeals() {
	let world = world().await;
	let nobody = world.anonymous();
	assert_unauthorized(world.call(&nobody, ListReviewQueue {}).await);
	assert_unauthorized(
		world
			.call(
				&nobody,
				review(&uuid::Uuid::new_v4().to_string(), true, "looks right"),
			)
			.await,
	);
	assert_unauthorized(
		world
			.call(
				&nobody,
				SubmitAppeal {
					attempt_id: uuid::Uuid::new_v4().to_string(),
					reason: "please look again".to_owned(),
				},
			)
			.await,
	);
}

#[tokio::test]
async fn only_reviewers_see_the_queue_and_never_their_own_proof() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let rex = world.person("rex@example.com").await;
	pending_attempt(&world, &ada, "Westminster").await;

	// Not a reviewer: nothing to decide, and deciding is refused.
	assert!(
		world
			.call(&rex.identity, ListReviewQueue {})
			.await
			.unwrap()
			.is_empty()
	);
	let probe = uuid::Uuid::new_v4().to_string();
	assert_forbidden(
		world
			.call(&rex.identity, review(&probe, true, "fine"))
			.await,
		"notReviewer",
	);

	world.grant_reviewer(&rex).await;
	let queue = world.call(&rex.identity, ListReviewQueue {}).await.unwrap();
	assert_eq!(queue.len(), 2, "both proofs wait for a person");
	assert!(queue.iter().all(|row| row.needs_person));
	assert!(queue.iter().any(|row| row.kind == ProofKind::Photo));
	assert!(queue.iter().any(|row| row.kind == ProofKind::Presence));
	assert_eq!(queue[0].creator, "Verily Field Notes");
	let json = serde_json::to_string(&queue).unwrap();
	for leak in ["manual-review", "media_verifier", "sha", &digest(1)] {
		assert!(!json.contains(leak), "{leak} in {json}");
	}

	// A reviewer's own proof is not theirs to decide.
	world.grant_reviewer(&ada).await;
	assert!(
		world
			.call(&ada.identity, ListReviewQueue {})
			.await
			.unwrap()
			.is_empty()
	);
	assert_forbidden(
		world
			.call(&ada.identity, review(&queue[0].id, true, "mine is fine"))
			.await,
		"ownProof",
	);
	assert_eq!(status(&world, &ada).await, AttemptStatus::PendingReview);
}

#[tokio::test]
async fn a_person_accepting_every_proof_verifies_and_reserves_the_payout() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let rex = world.person("rex@example.com").await;
	world.grant_reviewer(&rex).await;
	pending_attempt(&world, &ada, "Westminster").await;
	let queue = world.call(&rex.identity, ListReviewQueue {}).await.unwrap();

	for bad in ["", "   ", &"a".repeat(501)] {
		assert_invalid(
			world
				.call(&rex.identity, review(&queue[0].id, true, bad))
				.await,
			"reviewNote",
		);
	}
	assert_not_found(
		world
			.call(
				&rex.identity,
				review(&uuid::Uuid::new_v4().to_string(), true, "fine"),
			)
			.await,
	);

	assert!(
		world
			.call(
				&rex.identity,
				review(&queue[0].id, true, "The river is in frame.")
			)
			.await
			.unwrap()
			.saved
	);
	assert_eq!(
		status(&world, &ada).await,
		AttemptStatus::PendingReview,
		"one proof still waits"
	);
	assert_conflict(
		world
			.call(
				&rex.identity,
				review(&queue[0].id, false, "changed my mind"),
			)
			.await,
		"reviewClosed",
	);
	world
		.call(&rex.identity, review(&queue[1].id, true, "On the bridge."))
		.await
		.unwrap();
	assert_eq!(status(&world, &ada).await, AttemptStatus::Verified);
	assert!(
		world
			.call(&rex.identity, ListReviewQueue {})
			.await
			.unwrap()
			.is_empty()
	);

	// The 2 USDC pool reserved a payout. Nothing marks it released: there is
	// no wallet, and a release only ever comes from chain state.
	let payouts = world.call(&ada.identity, ListMyPayouts {}).await.unwrap();
	assert_eq!(payouts.len(), 1);
	assert_eq!(payouts[0].amount_label, "2 USDC");
	assert_eq!(payouts[0].status, PayoutStatus::AwaitingWallet);
	assert!(
		world
			.call(&rex.identity, ListMyPayouts {})
			.await
			.unwrap()
			.is_empty()
	);
}

#[tokio::test]
async fn a_rejection_can_be_appealed_once_by_its_participant() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let rex = world.person("rex@example.com").await;
	let eve = world.person("eve@example.com").await;
	world.grant_reviewer(&rex).await;
	let attempt = pending_attempt(&world, &ada, "book market").await;
	let appeal = |reason: &str| SubmitAppeal {
		attempt_id: attempt.clone(),
		reason: reason.to_owned(),
	};

	assert_invalid(
		world.call(&ada.identity, appeal("not yet rejected")).await,
		"notRejected",
	);

	let queue = world.call(&rex.identity, ListReviewQueue {}).await.unwrap();
	assert_eq!(queue.len(), 1);
	world
		.call(
			&rex.identity,
			review(&queue[0].id, false, "The word is not audible."),
		)
		.await
		.unwrap();
	assert_eq!(status(&world, &ada).await, AttemptStatus::Rejected);
	assert!(
		world
			.call(&ada.identity, ListMyPayouts {})
			.await
			.unwrap()
			.is_empty()
	);

	assert_not_found(world.call(&eve.identity, appeal("let me appeal it")).await);
	for bad in ["", "  ", &"a".repeat(1001), "please\u{0}look"] {
		assert_invalid(world.call(&ada.identity, appeal(bad)).await, "appealReason");
	}
	let receipt = world
		.call(
			&ada.identity,
			appeal("I said it clearly; please listen again."),
		)
		.await
		.unwrap();
	assert!(!receipt.id.is_empty());
	assert_conflict(
		world.call(&ada.identity, appeal("once more")).await,
		"alreadyAppealed",
	);
}

#[tokio::test]
async fn a_payout_above_the_review_threshold_holds_and_records_the_person_who_accepted() {
	let secrets =
		verily_rewards::config::secrets_from_pairs([("VERILY_REWARD_REVIEW_THRESHOLD_ATOMS", "1")]);
	let rewards = verily_rewards::Rewards::from_secrets(&secrets, verily_rewards::RunMode::Test)
		.unwrap()
		.with_arbiter(solana_kit_core::Address::from_bytes([0xa1; 32]))
		.with_planted(verily_rewards::PlantedGateway::new())
		.unwrap();
	let world = world_with(rewards).await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let rex = world.person("rex@example.com").await;
	world.grant_reviewer(&rex).await;
	pending_attempt(&world, &ada, "book market").await;
	let queue = world.call(&rex.identity, ListReviewQueue {}).await.unwrap();
	world
		.call(&rex.identity, review(&queue[0].id, true, "Heard the word."))
		.await
		.unwrap();
	assert_eq!(status(&world, &ada).await, AttemptStatus::Verified);
	let payouts = world.call(&ada.identity, ListMyPayouts {}).await.unwrap();
	assert_eq!(payouts[0].status, PayoutStatus::HeldForReview);
	let row = verily_rewards::schema::RewardPayoutRow::query()
		.first(&world.db.system("read a payout in a test"))
		.await
		.unwrap()
		.unwrap();
	assert_eq!(row.person_accepted_by, Some(rex.account().uuid()));
	assert!(row.release_signature.is_none());
}
