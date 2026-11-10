//! Doing an action: attempts, capture windows, spoken words, proof, and the
//! server's decision, called the way the capture screen calls them.

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
use verily_api::ProofKind;
use verily_app::ops::BeginAttempt;
use verily_app::ops::BeginCapture;
use verily_app::ops::CompleteAttempt;
use verily_app::ops::GetAction;
use verily_app::ops::IssueSpokenChallenge;
use verily_app::ops::ListAvailableActions;
use verily_app::ops::ListMyAttempts;
use verily_app::ops::SubmitAttestation;
use verily_app::ops::SubmitLiveProof;
use verily_verification::spoken::SPOKEN_CHALLENGE_WORDS;

/// The seeded action whose title contains `needle`, and its proofs.
async fn seeded(world: &World, who: &Person, needle: &str) -> verily_api::ActionDetail {
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
	world
		.call(&who.identity, GetAction { action_id: card.id })
		.await
		.unwrap()
}

fn proof_of(detail: &verily_api::ActionDetail, kind: ProofKind) -> String {
	detail
		.proofs
		.iter()
		.find(|proof| proof.kind == kind)
		.unwrap()
		.id
		.clone()
}

async fn capture(world: &World, who: &Person, attempt: &str, requirement: &str, byte: u8) {
	world
		.call(
			&who.identity,
			BeginCapture {
				attempt_id: attempt.to_owned(),
				requirement_id: requirement.to_owned(),
			},
		)
		.await
		.unwrap();
	let receipt = world
		.call(
			&who.identity,
			SubmitLiveProof {
				attempt_id: attempt.to_owned(),
				requirement_id: requirement.to_owned(),
				digest_hex: digest(byte),
			},
		)
		.await
		.unwrap();
	assert!(receipt.stored);
}

#[tokio::test]
async fn nobody_signed_out_starts_or_sends_anything() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let river = seeded(&world, &ada, "Westminster").await;
	let opened = world
		.call(
			&ada.identity,
			BeginAttempt {
				action_id: river.id.clone(),
			},
		)
		.await
		.unwrap();
	let nobody = world.anonymous();
	let attempt_id = opened.attempt_id.clone();
	let requirement_id = opened.requirement_id.clone();
	assert_unauthorized(world.call(&nobody, ListMyAttempts {}).await);
	assert_unauthorized(
		world
			.call(
				&nobody,
				BeginAttempt {
					action_id: river.id.clone(),
				},
			)
			.await,
	);
	assert_unauthorized(
		world
			.call(
				&nobody,
				BeginCapture {
					attempt_id: attempt_id.clone(),
					requirement_id: requirement_id.clone(),
				},
			)
			.await,
	);
	assert_unauthorized(
		world
			.call(
				&nobody,
				IssueSpokenChallenge {
					attempt_id: attempt_id.clone(),
					requirement_id: requirement_id.clone(),
				},
			)
			.await,
	);
	assert_unauthorized(
		world
			.call(
				&nobody,
				SubmitLiveProof {
					attempt_id: attempt_id.clone(),
					requirement_id,
					digest_hex: digest(1),
				},
			)
			.await,
	);
	assert_unauthorized(
		world
			.call(
				&nobody,
				SubmitAttestation {
					attempt_id: attempt_id.clone(),
					digest_hex: digest(1),
				},
			)
			.await,
	);
	assert_unauthorized(world.call(&nobody, CompleteAttempt { attempt_id }).await);
}

#[tokio::test]
async fn an_attempt_is_opened_once_per_period() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let river = seeded(&world, &ada, "Westminster").await;
	let first = world
		.call(
			&ada.identity,
			BeginAttempt {
				action_id: river.id.clone(),
			},
		)
		.await
		.unwrap();
	let again = world
		.call(
			&ada.identity,
			BeginAttempt {
				action_id: river.id.clone(),
			},
		)
		.await
		.unwrap();
	assert_eq!(first, again);
	assert!(
		river
			.proofs
			.iter()
			.any(|proof| proof.id == first.requirement_id)
	);
	let mine = world.call(&ada.identity, ListMyAttempts {}).await.unwrap();
	assert_eq!(mine.len(), 1);
	assert_eq!(mine[0].status, AttemptStatus::CollectingEvidence);
	assert_eq!(mine[0].action_title, river.title);

	assert_not_found(
		world
			.call(
				&ada.identity,
				BeginAttempt {
					action_id: uuid::Uuid::new_v4().to_string(),
				},
			)
			.await,
	);
}

#[tokio::test]
async fn someone_elses_attempt_is_not_found() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let eve = world.person("eve@example.com").await;
	let river = seeded(&world, &ada, "Westminster").await;
	let photo = proof_of(&river, ProofKind::Photo);
	let opened = world
		.call(
			&ada.identity,
			BeginAttempt {
				action_id: river.id.clone(),
			},
		)
		.await
		.unwrap();
	capture(&world, &ada, &opened.attempt_id, &photo, 1).await;

	let attempt_id = opened.attempt_id.clone();
	assert_not_found(
		world
			.call(
				&eve.identity,
				BeginCapture {
					attempt_id: attempt_id.clone(),
					requirement_id: photo.clone(),
				},
			)
			.await,
	);
	assert_not_found(
		world
			.call(
				&eve.identity,
				SubmitLiveProof {
					attempt_id: attempt_id.clone(),
					requirement_id: photo.clone(),
					digest_hex: digest(2),
				},
			)
			.await,
	);
	assert_not_found(
		world
			.call(
				&eve.identity,
				SubmitAttestation {
					attempt_id: attempt_id.clone(),
					digest_hex: digest(1),
				},
			)
			.await,
	);
	assert_not_found(
		world
			.call(
				&eve.identity,
				CompleteAttempt {
					attempt_id: attempt_id.clone(),
				},
			)
			.await,
	);
	assert!(
		world
			.call(&eve.identity, ListMyAttempts {})
			.await
			.unwrap()
			.is_empty()
	);
}

#[tokio::test]
async fn proof_needs_an_open_window_and_is_pinned_to_its_digest() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let river = seeded(&world, &ada, "Westminster").await;
	let photo = proof_of(&river, ProofKind::Photo);
	let opened = world
		.call(
			&ada.identity,
			BeginAttempt {
				action_id: river.id.clone(),
			},
		)
		.await
		.unwrap();
	let attempt_id = opened.attempt_id.clone();
	let submit = |byte: u8| SubmitLiveProof {
		attempt_id: attempt_id.clone(),
		requirement_id: photo.clone(),
		digest_hex: digest(byte),
	};

	// No window, no proof: a capture the server did not open is refused.
	assert_invalid(
		world.call(&ada.identity, submit(1)).await,
		"captureWindowClosed",
	);

	let window = world
		.call(
			&ada.identity,
			BeginCapture {
				attempt_id: attempt_id.clone(),
				requirement_id: photo.clone(),
			},
		)
		.await
		.unwrap();
	assert_eq!(window.attempt_id, attempt_id);
	assert_eq!(window.requirement_id, photo);
	assert_eq!(window.challenge.len(), 43, "32 bytes, unpadded base64url");
	assert!(window.spoken_word.is_none(), "a photo has no spoken word");
	assert_eq!(window.kind, ProofKind::Photo);

	for bad in ["", "zz", &"g".repeat(64), &digest(1)[..63]] {
		assert_invalid(
			world
				.call(
					&ada.identity,
					SubmitLiveProof {
						attempt_id: attempt_id.clone(),
						requirement_id: photo.clone(),
						digest_hex: bad.to_owned(),
					},
				)
				.await,
			"invalidDigest",
		);
	}

	let stored = world.call(&ada.identity, submit(1)).await.unwrap();
	assert_eq!(stored.digest_hex, digest(1));
	// The same capture again is the same proof.
	assert!(world.call(&ada.identity, submit(1)).await.unwrap().stored);
	// Uppercase and padding do not make it another digest.
	let same = world
		.call(
			&ada.identity,
			SubmitLiveProof {
				attempt_id: attempt_id.clone(),
				requirement_id: photo.clone(),
				digest_hex: format!(" {} ", digest(1).to_uppercase()),
			},
		)
		.await
		.unwrap();
	assert_eq!(same.digest_hex, digest(1));
	// Another capture never replaces the pinned one, even through a new window.
	world
		.call(
			&ada.identity,
			BeginCapture {
				attempt_id: attempt_id.clone(),
				requirement_id: photo.clone(),
			},
		)
		.await
		.unwrap();
	assert_conflict(
		world.call(&ada.identity, submit(2)).await,
		"proofAlreadySubmitted",
	);

	// The attested digest is checked against the pinned one.
	let bound = world
		.call(
			&ada.identity,
			SubmitAttestation {
				attempt_id: attempt_id.clone(),
				digest_hex: digest(1),
			},
		)
		.await
		.unwrap();
	assert!(bound.bound);
	for other in [digest(2), "not hex".to_owned()] {
		let unbound = world
			.call(
				&ada.identity,
				SubmitAttestation {
					attempt_id: attempt_id.clone(),
					digest_hex: other,
				},
			)
			.await
			.unwrap();
		assert!(!unbound.bound);
	}

	// A requirement of another action is not this attempt's.
	let squats = seeded(&world, &ada, "squats").await;
	assert_not_found(
		world
			.call(
				&ada.identity,
				BeginCapture {
					attempt_id: attempt_id.clone(),
					requirement_id: squats.proofs[0].id.clone(),
				},
			)
			.await,
	);
}

#[tokio::test]
async fn capture_windows_are_rationed() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let river = seeded(&world, &ada, "Westminster").await;
	let photo = proof_of(&river, ProofKind::Photo);
	let opened = world
		.call(
			&ada.identity,
			BeginAttempt {
				action_id: river.id.clone(),
			},
		)
		.await
		.unwrap();
	let open = || BeginCapture {
		attempt_id: opened.attempt_id.clone(),
		requirement_id: photo.clone(),
	};
	let mut challenges = std::collections::HashSet::new();
	for _ in 0..10 {
		challenges.insert(world.call(&ada.identity, open()).await.unwrap().challenge);
	}
	assert_eq!(challenges.len(), 10, "every window gets a fresh challenge");
	assert_conflict(world.call(&ada.identity, open()).await, "tooManyCaptures");
}

#[tokio::test]
async fn the_spoken_word_comes_from_the_server_list_and_stays_put() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let squats = seeded(&world, &ada, "squats").await;
	let video = proof_of(&squats, ProofKind::Video);
	let opened = world
		.call(
			&ada.identity,
			BeginAttempt {
				action_id: squats.id.clone(),
			},
		)
		.await
		.unwrap();
	let ask = || IssueSpokenChallenge {
		attempt_id: opened.attempt_id.clone(),
		requirement_id: video.clone(),
	};

	// The screen reads it as it opens, and again on a refetch: one word.
	let word = world.call(&ada.identity, ask()).await.unwrap().word;
	assert!(SPOKEN_CHALLENGE_WORDS.contains(&word.as_str()));
	assert_eq!(world.call(&ada.identity, ask()).await.unwrap().word, word);

	// Proof without a window is still refused; the window carries the word.
	let window = world
		.call(
			&ada.identity,
			BeginCapture {
				attempt_id: opened.attempt_id.clone(),
				requirement_id: video.clone(),
			},
		)
		.await
		.unwrap();
	assert_eq!(window.spoken_word.as_deref(), Some(word.as_str()));
	world
		.call(
			&ada.identity,
			SubmitLiveProof {
				attempt_id: opened.attempt_id.clone(),
				requirement_id: video.clone(),
				digest_hex: digest(7),
			},
		)
		.await
		.unwrap();
	// Bound to the proof, the word does not change.
	assert_eq!(world.call(&ada.identity, ask()).await.unwrap().word, word);

	// A photo has no word, and someone else's attempt has none for them.
	let river = seeded(&world, &ada, "Westminster").await;
	let river_attempt = world
		.call(
			&ada.identity,
			BeginAttempt {
				action_id: river.id.clone(),
			},
		)
		.await
		.unwrap();
	assert_invalid(
		world
			.call(
				&ada.identity,
				IssueSpokenChallenge {
					attempt_id: river_attempt.attempt_id,
					requirement_id: proof_of(&river, ProofKind::Photo),
				},
			)
			.await,
		"noSpokenChallenge",
	);
	let eve = world.person("eve@example.com").await;
	assert_not_found(world.call(&eve.identity, ask()).await);
}

#[tokio::test]
async fn completing_never_passes_proof_a_person_has_not_seen() {
	let world = world().await;
	world.seed().await;
	let ada = world.person("ada@example.com").await;
	let river = seeded(&world, &ada, "Westminster").await;
	let opened = world
		.call(
			&ada.identity,
			BeginAttempt {
				action_id: river.id.clone(),
			},
		)
		.await
		.unwrap();
	let complete = || CompleteAttempt {
		attempt_id: opened.attempt_id.clone(),
	};

	// Missing proof: still collecting.
	assert_eq!(
		world.call(&ada.identity, complete()).await.unwrap().status,
		AttemptStatus::CollectingEvidence
	);
	capture(
		&world,
		&ada,
		&opened.attempt_id,
		&proof_of(&river, ProofKind::Photo),
		1,
	)
	.await;
	assert_eq!(
		world.call(&ada.identity, complete()).await.unwrap().status,
		AttemptStatus::CollectingEvidence
	);
	capture(
		&world,
		&ada,
		&opened.attempt_id,
		&proof_of(&river, ProofKind::Presence),
		2,
	)
	.await;

	// Every proof is in. The manual-review verifier sends it to a person.
	let outcome = world.call(&ada.identity, complete()).await.unwrap();
	assert_eq!(outcome.status, AttemptStatus::PendingReview);
	assert_eq!(
		world.call(&ada.identity, complete()).await.unwrap(),
		outcome
	);
	let mine = world.call(&ada.identity, ListMyAttempts {}).await.unwrap();
	assert_eq!(mine[0].status, AttemptStatus::PendingReview);

	// The attempt takes no more proof once it is decided.
	assert_invalid(
		world
			.call(
				&ada.identity,
				BeginCapture {
					attempt_id: opened.attempt_id.clone(),
					requirement_id: proof_of(&river, ProofKind::Photo),
				},
			)
			.await,
		"attemptClosed",
	);
}
