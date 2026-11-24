//! End-to-end integration tests covering the complete `LeptosKit` port:
//! - `/healthz`, `/.well-known/jwks.json`, `/_verily/local-evidence/*`
//! - 12 templates, `get_draft`, `pause_action`, spatial nearby search
//! - Presigned local upload -> `confirm_media_upload` -> `submit_media_proof` -> job sweep
//! - Rotating venue QR code issue + single-use redemption
//! - Appeals resolution (`resolve_appeal`), moderation report + safety hold hiding action
//! - Verily Apps partner API (`/api/v1/*`, Bearer auth, link exchange, Ed25519 JWS receipt)
//! - Background cleanup & verification sweeps

#![allow(
	clippy::too_many_lines,
	clippy::similar_names,
	clippy::large_futures,
	reason = "end-to-end port integration scenarios"
)]

mod support;

use leptoskit_auth::Auth;
use leptoskit_auth::Keys;
use leptoskit_axum::axum::body::Body;
use leptoskit_axum::axum::http::Request;
use leptoskit_axum::axum::http::StatusCode;
use leptoskit_axum::axum::http::header;
use sha2::Digest;
use sha2::Sha256;
use support::*;
use tower::ServiceExt as _;
use verily_api::ActionFilter;
use verily_api::AppealStatus;
use verily_api::AttemptStatus;
use verily_api::DraftInput;
use verily_api::ProofKind;
use verily_app::ops::AddAppRedirectUri;
use verily_app::ops::ApproveAppLink;
use verily_app::ops::BeginAttempt;
use verily_app::ops::BeginCapture;
use verily_app::ops::CompleteAttempt;
use verily_app::ops::ConfirmMediaUpload;
use verily_app::ops::CreateApp;
use verily_app::ops::CreateQrChallenge;
use verily_app::ops::GetAction;
use verily_app::ops::GetDraft;
use verily_app::ops::ListAvailableActions;
use verily_app::ops::ListMyAppeals;
use verily_app::ops::ListReviewAppeals;
use verily_app::ops::ListTemplates;
use verily_app::ops::PauseAction;
use verily_app::ops::PublishAction;
use verily_app::ops::ReportContent;
use verily_app::ops::RequestMediaUpload;
use verily_app::ops::ResolveAppeal;
use verily_app::ops::ReviewModerationCase;
use verily_app::ops::SaveAction;
use verily_app::ops::SubmitAppeal;
use verily_app::ops::SubmitLiveProof;
use verily_app::ops::SubmitLocationProof;
use verily_app::ops::SubmitMediaProof;
use verily_app::ops::SubmitQrProof;
use verily_verification::asn1::hex_lower;

async fn read_json(response: leptoskit_axum::axum::response::Response) -> serde_json::Value {
	let bytes = leptoskit_axum::axum::body::to_bytes(response.into_body(), 1 << 20)
		.await
		.unwrap();
	serde_json::from_slice(&bytes).unwrap()
}

#[tokio::test]
async fn templates_draft_edit_pause_and_spatial_nearby_work() {
	let world = world().await;
	let ada = world.person("ada@example.com").await;

	let templates = world.call(&ada.identity, ListTemplates {}).await.unwrap();
	assert_eq!(templates.len(), 12);

	let saved = world
		.call(
			&ada.identity,
			SaveAction {
				draft: DraftInput {
					id: None,
					title: "Spot the lighthouse".into(),
					summary: "Take a live photo from the promenade.".into(),
					place_name: "Brighton Pier".into(),
					radius_meters: 250,
					reward_amount: String::new(),
					proofs: vec![ProofKind::Photo, ProofKind::Presence],
					latitude: Some(50.8169),
					longitude: Some(-0.1367),
				},
			},
		)
		.await
		.unwrap();

	let loaded = world
		.call(
			&ada.identity,
			GetDraft {
				action_id: saved.id.clone(),
			},
		)
		.await
		.unwrap();
	assert_eq!(loaded.title, "Spot the lighthouse");
	assert_eq!(loaded.latitude, Some(50.8169));
	assert_eq!(loaded.longitude, Some(-0.1367));

	let published = world
		.call(
			&ada.identity,
			PublishAction {
				action_id: saved.id.clone(),
			},
		)
		.await
		.unwrap();
	assert!(published.is_live());

	// Spatial nearby search finds Brighton Pier from nearby coordinates and skips far coordinates.
	let nearby = world
		.call(
			&ada.identity,
			ListAvailableActions {
				filter: ActionFilter::Nearby,
				latitude: Some(50.82),
				longitude: Some(-0.14),
			},
		)
		.await
		.unwrap();
	assert!(nearby.iter().any(|c| c.id == saved.id));

	let far = world
		.call(
			&ada.identity,
			ListAvailableActions {
				filter: ActionFilter::Nearby,
				latitude: Some(35.6762),
				longitude: Some(139.6503),
			},
		)
		.await
		.unwrap();
	assert_eq!(far, []);

	// Pause hides the action from catalogue; resume brings it back.
	let paused = world
		.call(
			&ada.identity,
			PauseAction {
				action_id: saved.id.clone(),
				paused: true,
			},
		)
		.await
		.unwrap();
	assert!(paused.paused);
	assert!(!paused.live);

	let active_after_pause = world
		.call(
			&ada.identity,
			ListAvailableActions {
				filter: ActionFilter::All,
				latitude: None,
				longitude: None,
			},
		)
		.await
		.unwrap();
	assert!(!active_after_pause.iter().any(|c| c.id == saved.id));

	let resumed = world
		.call(
			&ada.identity,
			PauseAction {
				action_id: saved.id.clone(),
				paused: false,
			},
		)
		.await
		.unwrap();
	assert!(resumed.live);
	assert!(!resumed.paused);
}

#[tokio::test]
async fn venue_qr_challenge_redeems_once_and_verifies_attempt() {
	let world = world().await;
	let creator = world.person("creator@example.com").await;
	let player = world.person("player@example.com").await;

	let saved = world
		.call(
			&creator.identity,
			SaveAction {
				draft: DraftInput {
					id: None,
					title: "Scan the gallery QR".into(),
					summary: "Scan the rotating code at the desk.".into(),
					place_name: "Gallery Desk".into(),
					radius_meters: 50,
					reward_amount: String::new(),
					proofs: vec![ProofKind::VenueCode],
					latitude: None,
					longitude: None,
				},
			},
		)
		.await
		.unwrap();
	world
		.call(
			&creator.identity,
			PublishAction {
				action_id: saved.id.clone(),
			},
		)
		.await
		.unwrap();

	let qr = world
		.call(
			&creator.identity,
			CreateQrChallenge {
				action_id: saved.id.clone(),
				ttl_seconds: Some(600),
			},
		)
		.await
		.unwrap();
	assert!(qr.code.starts_with("vqr_"));

	let opened = world
		.call(
			&player.identity,
			BeginAttempt {
				action_id: saved.id.clone(),
			},
		)
		.await
		.unwrap();
	world
		.call(
			&player.identity,
			BeginCapture {
				attempt_id: opened.attempt_id.clone(),
				requirement_id: opened.requirement_id.clone(),
			},
		)
		.await
		.unwrap();

	let receipt = world
		.call(
			&player.identity,
			SubmitQrProof {
				attempt_id: opened.attempt_id.clone(),
				requirement_id: opened.requirement_id.clone(),
				code: qr.code.clone(),
			},
		)
		.await
		.unwrap();
	assert!(receipt.stored);

	// Reusing the same single-use venue code fails with conflict.
	let other = world.person("other@example.com").await;
	let other_opened = world
		.call(
			&other.identity,
			BeginAttempt {
				action_id: saved.id.clone(),
			},
		)
		.await
		.unwrap();
	assert_conflict(
		world
			.call(
				&other.identity,
				SubmitQrProof {
					attempt_id: other_opened.attempt_id,
					requirement_id: other_opened.requirement_id,
					code: qr.code,
				},
			)
			.await,
		"venueCodeUsed",
	);

	let outcome = world
		.call(
			&player.identity,
			CompleteAttempt {
				attempt_id: opened.attempt_id,
			},
		)
		.await
		.unwrap();
	assert_eq!(outcome.status, AttemptStatus::Verified);
}

#[tokio::test]
async fn moderation_hold_hides_action_and_appeal_resolution_overturns_rejection() {
	let world = world().await;
	let creator = world.person("creator@example.com").await;
	let participant = world.person("participant@example.com").await;
	let reviewer = world.person("reviewer@example.com").await;
	world.grant_reviewer(&reviewer).await;

	let saved = world
		.call(
			&creator.identity,
			SaveAction {
				draft: DraftInput {
					id: None,
					title: "Park bench photo".into(),
					summary: "Take a photo of the oak bench.".into(),
					place_name: "Oak Park".into(),
					radius_meters: 100,
					reward_amount: String::new(),
					proofs: vec![ProofKind::Photo],
					latitude: None,
					longitude: None,
				},
			},
		)
		.await
		.unwrap();
	world
		.call(
			&creator.identity,
			PublishAction {
				action_id: saved.id.clone(),
			},
		)
		.await
		.unwrap();

	// Participant submits proof -> manual review -> rejected -> appeals -> reviewer overturns!
	let opened = world
		.call(
			&participant.identity,
			BeginAttempt {
				action_id: saved.id.clone(),
			},
		)
		.await
		.unwrap();
	world
		.call(
			&participant.identity,
			BeginCapture {
				attempt_id: opened.attempt_id.clone(),
				requirement_id: opened.requirement_id.clone(),
			},
		)
		.await
		.unwrap();
	world
		.call(
			&participant.identity,
			SubmitLiveProof {
				attempt_id: opened.attempt_id.clone(),
				requirement_id: opened.requirement_id.clone(),
				digest_hex: digest(0x42),
			},
		)
		.await
		.unwrap();
	let pending = world
		.call(
			&participant.identity,
			CompleteAttempt {
				attempt_id: opened.attempt_id.clone(),
			},
		)
		.await
		.unwrap();
	assert_eq!(pending.status, AttemptStatus::PendingReview);

	let queue = world
		.call(&reviewer.identity, verily_app::ops::ListReviewQueue {})
		.await
		.unwrap();
	assert_eq!(queue.len(), 1);
	world
		.call(
			&reviewer.identity,
			verily_app::ops::ReviewAttempt {
				review_id: queue[0].id.clone(),
				accept: false,
				note: "Too blurry".into(),
			},
		)
		.await
		.unwrap();

	let appeal = world
		.call(
			&participant.identity,
			SubmitAppeal {
				attempt_id: opened.attempt_id.clone(),
				reason: "The plaque is readable in the top left corner.".into(),
			},
		)
		.await
		.unwrap();
	let my_appeals = world
		.call(&participant.identity, ListMyAppeals {})
		.await
		.unwrap();
	assert_eq!(my_appeals.len(), 1);
	assert_eq!(my_appeals[0].status, AppealStatus::Pending);

	let review_appeals = world
		.call(&reviewer.identity, ListReviewAppeals {})
		.await
		.unwrap();
	assert_eq!(review_appeals.len(), 1);

	let resolved = world
		.call(
			&reviewer.identity,
			ResolveAppeal {
				appeal_id: appeal.id,
				overturn: true,
				note: "Checked again, plaque is visible.".into(),
			},
		)
		.await
		.unwrap();
	assert_eq!(resolved.status, AppealStatus::Accepted);

	// Moderation report + safety hold hides the action from non-creators.
	let report = world
		.call(
			&participant.identity,
			ReportContent {
				target_kind: "action".into(),
				target_id: saved.id.clone(),
				reason: "unsafe_location".into(),
				notes: Some("Construction zone".into()),
			},
		)
		.await
		.unwrap();
	world
		.call(
			&reviewer.identity,
			ReviewModerationCase {
				case_id: report.id,
				new_status: "held".into(),
				note: "Holding pending review.".into(),
			},
		)
		.await
		.unwrap();

	assert_not_found(
		world
			.call(
				&participant.identity,
				GetAction {
					action_id: saved.id.clone(),
				},
			)
			.await,
	);
	let visible_list = world
		.call(
			&participant.identity,
			ListAvailableActions {
				filter: ActionFilter::All,
				latitude: None,
				longitude: None,
			},
		)
		.await
		.unwrap();
	assert!(!visible_list.iter().any(|c| c.id == saved.id));
}

#[tokio::test]
async fn partner_http_api_jwks_healthz_local_upload_and_jobs_work_end_to_end() {
	let _ = verily_app::ops::BACKEND;
	let db = leptoskit_db::testing::sqlite().await;
	let auth = Auth::builder(&db, Keys::single("test", [7; 32]));
	let host = verily_backend::start(&db, auth, None, verily_backend::Options::new(&db)).unwrap();
	let router = host.router.clone();

	// 1. /api/v1/health and /.well-known/jwks.json
	let health = router
		.clone()
		.oneshot(Request::get("/api/v1/health").body(Body::empty()).unwrap())
		.await
		.unwrap();
	assert_eq!(health.status(), StatusCode::OK);

	let jwks_resp = router
		.clone()
		.oneshot(
			Request::get("/.well-known/jwks.json")
				.body(Body::empty())
				.unwrap(),
		)
		.await
		.unwrap();
	assert_eq!(jwks_resp.status(), StatusCode::OK);
	let jwks = read_json(jwks_resp).await;
	assert_eq!(jwks["keys"][0]["crv"], "Ed25519");

	// 2. Sign in a creator and register a Verily App.
	let sign_in = host
		.auth
		.dev_sign_in(
			"partner@example.com",
			&leptoskit_auth::RequestInfo::default(),
		)
		.await
		.unwrap();
	let signed_in = sign_in.signed_in();
	let identity = leptoskit_rpc::Identity::new(
		leptoskit_auth::context(Some(signed_in.clone()))
			.with(host.rewards.clone())
			.with(host.backend.clone()),
	)
	.with_caller(signed_in.session.to_string());

	let created_app = leptoskit_rpc::server::call_as(
		&db,
		identity.clone(),
		None,
		CreateApp {
			name: "FitQuest".into(),
			slug: "fitquest".into(),
			webhook_url: Some("https://partner.example/hooks/verily".into()),
		},
	)
	.await
	.unwrap();
	assert!(created_app.api_key_once.starts_with("vk_"));

	leptoskit_rpc::server::call_as(
		&db,
		identity.clone(),
		None,
		AddAppRedirectUri {
			app_id: created_app.app.id.clone(),
			uri: "fitquest://linked".into(),
		},
	)
	.await
	.unwrap();

	// 3. Approve link -> partner exchanges code over HTTP Bearer API!
	let exchange_view = leptoskit_rpc::server::call_as(
		&db,
		identity.clone(),
		None,
		ApproveAppLink {
			app_slug: "fitquest".into(),
			redirect_uri: "fitquest://linked".into(),
			state: Some("xyz".into()),
		},
	)
	.await
	.unwrap();

	let link_resp = router
		.clone()
		.oneshot(
			Request::post("/api/v1/links/exchange")
				.header(
					header::AUTHORIZATION,
					format!("Bearer {}", created_app.api_key_once),
				)
				.header(header::CONTENT_TYPE, "application/json")
				.body(Body::from(
					serde_json::json!({
						"code": exchange_view.code,
						"redirectUri": "fitquest://linked",
						"externalUserId": "ext_user_42"
					})
					.to_string(),
				))
				.unwrap(),
		)
		.await
		.unwrap();
	assert_eq!(link_resp.status(), StatusCode::OK);
	let link_json = read_json(link_resp).await;
	assert_eq!(link_json["externalUserId"], "ext_user_42");

	// 4. Local evidence upload -> confirm -> submit_media_proof -> verification job sweep!
	let saved = leptoskit_rpc::server::call_as(
		&db,
		identity.clone(),
		None,
		SaveAction {
			draft: DraftInput {
				id: None,
				title: "Upload test photo".into(),
				summary: "Take one photo.".into(),
				place_name: "Studio".into(),
				radius_meters: 0,
				reward_amount: String::new(),
				proofs: vec![ProofKind::Photo],
				latitude: None,
				longitude: None,
			},
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		identity.clone(),
		None,
		PublishAction {
			action_id: saved.id.clone(),
		},
	)
	.await
	.unwrap();

	let opened = leptoskit_rpc::server::call_as(
		&db,
		identity.clone(),
		None,
		BeginAttempt {
			action_id: saved.id.clone(),
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		identity.clone(),
		None,
		BeginCapture {
			attempt_id: opened.attempt_id.clone(),
			requirement_id: opened.requirement_id.clone(),
		},
	)
	.await
	.unwrap();

	let bytes = b"verily-live-jpeg-payload";
	let sha_hex = hex_lower(&Sha256::digest(bytes));
	let plan = leptoskit_rpc::server::call_as(
		&db,
		identity.clone(),
		None,
		RequestMediaUpload {
			attempt_id: opened.attempt_id.clone(),
			requirement_id: opened.requirement_id.clone(),
			mime_type: "image/jpeg".into(),
			byte_length: i64::try_from(bytes.len()).unwrap(),
		},
	)
	.await
	.unwrap();

	let put_path = format!("/_verily/local-evidence/{}", plan.object_key);
	let put_resp = router
		.clone()
		.oneshot(
			Request::put(&put_path)
				.header(header::CONTENT_TYPE, "image/jpeg")
				.body(Body::from(bytes.as_slice()))
				.unwrap(),
		)
		.await
		.unwrap();
	assert_eq!(put_resp.status(), StatusCode::OK);
	let put_json = read_json(put_resp).await;
	let version_id = put_json["versionId"].as_str().unwrap().to_owned();

	let confirmed = leptoskit_rpc::server::call_as(
		&db,
		identity.clone(),
		None,
		ConfirmMediaUpload {
			reservation_id: plan.reservation_id.clone(),
			version_id,
			expected_sha256_hex: sha_hex.clone(),
		},
	)
	.await
	.unwrap();
	assert_eq!(confirmed.sha256_hex, sha_hex);

	let submitted = leptoskit_rpc::server::call_as(
		&db,
		identity.clone(),
		None,
		SubmitMediaProof {
			attempt_id: opened.attempt_id.clone(),
			requirement_id: opened.requirement_id,
			reservation_id: plan.reservation_id,
		},
	)
	.await
	.unwrap();
	assert!(submitted.stored);

	// Run background verification & cleanup sweeps directly.
	let verified_jobs = verily_backend::jobs::run_evidence_verification_sweep(&db, &host.backend)
		.await
		.unwrap();
	assert_eq!(verified_jobs, 1);

	// Worker settled the attempt into `pending_review` (manual-review default without secrets).
	let sys = db.system("check settled attempt");
	let attempt_uuid: uuid::Uuid = opened.attempt_id.parse().unwrap();
	let settled_attempt = verily_backend::Attempt::query()
		.filter(|a| a.id.eq(leptoskit_db::Id::from_uuid(attempt_uuid)))
		.first(&sys)
		.await
		.unwrap()
		.unwrap();
	assert_eq!(settled_attempt.status, "pending_review");

	let summary = verily_backend::jobs::run_cleanup_sweeps(&db).await.unwrap();
	assert_eq!(summary.expired_verification_requests, 0);
}

#[tokio::test]
async fn production_backend_fails_closed_on_local_storage_and_unset_receipt_key() {
	use base64::Engine as _;

	let rewards = std::sync::Arc::new(verily_backend::rewards::mount().unwrap());
	let verification = std::sync::Arc::new(verily_backend::verification::mount().unwrap());

	// Empty env in production defaults to Local storage -> must fail closed!
	let empty = std::collections::HashMap::new();
	assert!(
		verily_backend::Backend::from_env_map(
			rewards.clone(),
			verification.clone(),
			None,
			None,
			&empty,
			true,
		)
		.is_err()
	);

	// Valid B2 config in production succeeds; receipt_signer stays None without a real key.
	let mut b2_env = std::collections::HashMap::new();
	b2_env.insert("VERILY_EVIDENCE_STORAGE_MODE".into(), "b2".into());
	b2_env.insert("VERILY_B2_BUCKET".into(), "verily-prod".into());
	b2_env.insert("VERILY_B2_REGION".into(), "us-west-004".into());
	b2_env.insert(
		"VERILY_B2_ENDPOINT".into(),
		"https://s3.us-west-004.backblazeb2.com".into(),
	);
	b2_env.insert("VERILY_B2_KEY_ID".into(), "key-id".into());
	b2_env.insert("VERILY_B2_APPLICATION_KEY".into(), "app-key".into());
	let prod_no_signer = verily_backend::Backend::from_env_map(
		rewards.clone(),
		verification.clone(),
		None,
		None,
		&b2_env,
		true,
	)
	.unwrap();
	assert!(prod_no_signer.receipt_signer.is_none());

	// Providing a real 32-byte base64url Ed25519 seed enables receipt signing.
	let key_b64 = base64::engine::general_purpose::URL_SAFE_NO_PAD.encode([0x2a_u8; 32]);
	b2_env.insert("VERILY_RECEIPT_SIGNING_PRIVATE_KEY".into(), key_b64);
	let prod_with_signer =
		verily_backend::Backend::from_env_map(rewards, verification, None, None, &b2_env, true)
			.unwrap();
	assert!(prod_with_signer.receipt_signer.is_some());
}

#[tokio::test]
async fn attempt_verification_stamps_partner_receipt_and_queues_webhook_and_retention_respects_appeals()
 {
	let _ = verily_app::ops::BACKEND;
	let db = leptoskit_db::testing::sqlite().await;
	let auth = Auth::builder(&db, Keys::single("test", [9; 32]));
	let host = verily_backend::start(&db, auth, None, verily_backend::Options::new(&db)).unwrap();
	let router = host.router.clone();

	let creator_in = host
		.auth
		.dev_sign_in(
			"partner-creator@example.com",
			&leptoskit_auth::RequestInfo::default(),
		)
		.await
		.unwrap()
		.signed_in();
	let creator_id = leptoskit_rpc::Identity::new(
		leptoskit_auth::context(Some(creator_in.clone()))
			.with(host.rewards.clone())
			.with(host.backend.clone()),
	)
	.with_caller(creator_in.session.to_string());

	let player_in = host
		.auth
		.dev_sign_in(
			"partner-player@example.com",
			&leptoskit_auth::RequestInfo::default(),
		)
		.await
		.unwrap()
		.signed_in();
	let player_id = leptoskit_rpc::Identity::new(
		leptoskit_auth::context(Some(player_in.clone()))
			.with(host.rewards.clone())
			.with(host.backend.clone()),
	)
	.with_caller(player_in.session.to_string());

	// Creator registers a partner app + publishes a venue QR action.
	let created_app = leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		CreateApp {
			name: "StepClub".into(),
			slug: "stepclub".into(),
			webhook_url: Some("https://stepclub.example/webhooks/verily".into()),
		},
	)
	.await
	.unwrap();

	let saved = leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		SaveAction {
			draft: DraftInput {
				id: None,
				title: "Check in at kiosk".into(),
				summary: "Scan the venue kiosk QR.".into(),
				place_name: "Lobby".into(),
				radius_meters: 50,
				reward_amount: String::new(),
				proofs: vec![ProofKind::VenueCode],
				latitude: None,
				longitude: None,
			},
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		PublishAction {
			action_id: saved.id.clone(),
		},
	)
	.await
	.unwrap();

	// Partner creates a verification request via HTTP API.
	let req_resp = router
		.clone()
		.oneshot(
			Request::post("/api/v1/verification-requests")
				.header(
					header::AUTHORIZATION,
					format!("Bearer {}", created_app.api_key_once),
				)
				.header(header::CONTENT_TYPE, "application/json")
				.body(Body::from(
					serde_json::json!({
						"actionId": saved.id,
						"externalSubject": "member_99"
					})
					.to_string(),
				))
				.unwrap(),
		)
		.await
		.unwrap();
	assert_eq!(req_resp.status(), StatusCode::OK);
	let req_json = read_json(req_resp).await;
	let request_id = req_json["id"].as_str().unwrap().to_owned();

	// Player starts the verification request and completes the QR proof.
	leptoskit_rpc::server::call_as(
		&db,
		player_id.clone(),
		None,
		verily_app::ops::StartVerificationRequest {
			request_id: request_id.clone(),
		},
	)
	.await
	.unwrap();

	let qr = leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		CreateQrChallenge {
			action_id: saved.id.clone(),
			ttl_seconds: Some(300),
		},
	)
	.await
	.unwrap();

	let opened = leptoskit_rpc::server::call_as(
		&db,
		player_id.clone(),
		None,
		BeginAttempt {
			action_id: saved.id.clone(),
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		player_id.clone(),
		None,
		BeginCapture {
			attempt_id: opened.attempt_id.clone(),
			requirement_id: opened.requirement_id.clone(),
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		player_id.clone(),
		None,
		SubmitQrProof {
			attempt_id: opened.attempt_id.clone(),
			requirement_id: opened.requirement_id.clone(),
			code: qr.code,
		},
	)
	.await
	.unwrap();

	let outcome = leptoskit_rpc::server::call_as(
		&db,
		player_id.clone(),
		None,
		CompleteAttempt {
			attempt_id: opened.attempt_id.clone(),
		},
	)
	.await
	.unwrap();
	assert_eq!(outcome.status, AttemptStatus::Verified);

	// Verification request was automatically stamped with a signed Ed25519 JWS receipt!
	let receipt_resp = router
		.clone()
		.oneshot(
			Request::get(format!(
				"/api/v1/verification-requests/{request_id}/receipt"
			))
			.header(
				header::AUTHORIZATION,
				format!("Bearer {}", created_app.api_key_once),
			)
			.body(Body::empty())
			.unwrap(),
		)
		.await
		.unwrap();
	assert_eq!(receipt_resp.status(), StatusCode::OK);
	let receipt_json = read_json(receipt_resp).await;
	assert_eq!(receipt_json["status"], "verified");
	assert_eq!(
		receipt_json["receipt"].as_str().unwrap().split('.').count(),
		3
	);

	// Webhook delivery (`attempt.verified`) was automatically queued for StepClub!
	let deliveries = leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		verily_app::ops::ListAppDeliveries {
			app_id: created_app.app.id.clone(),
		},
	)
	.await
	.unwrap();
	assert_eq!(deliveries.len(), 1);
	assert_eq!(deliveries[0].event_type, "attempt.verified");
	assert_eq!(deliveries[0].status, "pending");

	// Test pull-check sweep fails cleanly when an app has no webhook URL.
	let no_hook_app = leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		CreateApp {
			name: "NoHook".into(),
			slug: "nohook".into(),
			webhook_url: None,
		},
	)
	.await
	.unwrap();
	let sys = db.system("seed pull check and retention");
	let app_uuid: uuid::Uuid = no_hook_app.app.id.parse().unwrap();
	let attempt_uuid: uuid::Uuid = opened.attempt_id.parse().unwrap();
	let pull = verily_backend::schema::NewVerilyAppPullCheckRow {
		app_id: leptoskit_db::Id::from_uuid(app_uuid),
		attempt_id: leptoskit_db::Id::from_uuid(attempt_uuid),
		requirement_id: opened.requirement_id.clone(),
		status: "pending".to_owned(),
		attempts: 0,
	}
	.insert(&sys)
	.await
	.unwrap();
	let checked = verily_backend::jobs::run_pull_check_sweep(&db, &host.backend)
		.await
		.unwrap();
	assert_eq!(checked, 1);
	let pull_after = verily_backend::schema::VerilyAppPullCheckRow::query()
		.filter(|r| r.id.eq(pull.id))
		.first(&sys)
		.await
		.unwrap()
		.unwrap();
	assert_eq!(pull_after.status, "failed");

	// Test evidence retention sweep:
	// - Day 3: still within 7-day window -> retained.
	// - Day 10 with an open appeal: held under 30-day appeal policy -> retained.
	// - Day 10 after appeal closes: purged from storage while sha256_digest stays!
	let verily_verification::storage::EvidenceStore::Local(local) = &*host.backend.0.evidence_store
	else {
		panic!("expected local store in test");
	};
	let (vid, inspection) = local
		.put_bytes("evidence/retention-test.jpg", "image/jpeg", b"old-bytes")
		.unwrap();
	let mut ev = verily_backend::Evidence::query()
		.filter(|e| e.attempt_id.eq(leptoskit_db::Id::from_uuid(attempt_uuid)))
		.first(&sys)
		.await
		.unwrap()
		.unwrap();
	ev.storage_path = Some("evidence/retention-test.jpg".to_owned());
	ev.storage_version_id = Some(vid.clone());
	ev.sha256_digest = Some(inspection.sha256_digest.clone());
	ev.save(&sys).await.unwrap();

	let day_3 = chrono::Utc::now() + chrono::Duration::days(3);
	let day_10 = chrono::Utc::now() + chrono::Duration::days(10);

	// Day 3 (within 7-day window) must NOT purge.
	let purged_day_3 =
		verily_backend::jobs::run_evidence_retention_sweep_at(&db, &host.backend, day_3)
			.await
			.unwrap();
	assert_eq!(purged_day_3, 0);

	// Open appeal holds evidence between 7 and 30 days.
	let mut open_appeal = verily_backend::schema::NewAppeal {
		attempt_id: leptoskit_db::Id::from_uuid(attempt_uuid),
		participant_id: player_in.account,
		reason: "Review retention hold test".to_owned(),
		status: "open".to_owned(),
	}
	.insert(&sys)
	.await
	.unwrap();
	let purged_while_appealed =
		verily_backend::jobs::run_evidence_retention_sweep_at(&db, &host.backend, day_10)
			.await
			.unwrap();
	assert_eq!(purged_while_appealed, 0);
	assert!(
		host.backend
			.0
			.evidence_store
			.read_version_bytes("evidence/retention-test.jpg", &vid)
			.await
			.is_ok()
	);

	// Closing the appeal allows the 10-day-old storage object to be purged while digest stays!
	open_appeal.status = "upheld".to_owned();
	open_appeal.save(&sys).await.unwrap();
	let purged_after_close =
		verily_backend::jobs::run_evidence_retention_sweep_at(&db, &host.backend, day_10)
			.await
			.unwrap();
	assert_eq!(purged_after_close, 1);
	assert!(
		host.backend
			.0
			.evidence_store
			.read_version_bytes("evidence/retention-test.jpg", &vid)
			.await
			.is_err()
	);
	let ev_after = verily_backend::Evidence::query()
		.filter(|e| e.id.eq(ev.id))
		.first(&sys)
		.await
		.unwrap()
		.unwrap();
	assert!(ev_after.storage_path.is_none());
	assert!(ev_after.storage_version_id.is_none());
	assert_eq!(ev_after.sha256_digest, Some(inspection.sha256_digest));
}

async fn dev_identity(host: &verily_backend::Host, email: &str) -> leptoskit_rpc::Identity {
	let signed = host
		.auth
		.dev_sign_in(email, &leptoskit_auth::RequestInfo::default())
		.await
		.unwrap()
		.signed_in();
	leptoskit_rpc::Identity::new(
		leptoskit_auth::context(Some(signed.clone()))
			.with(host.rewards.clone())
			.with(host.backend.clone()),
	)
	.with_caller(signed.session.to_string())
}

#[tokio::test]
async fn submit_location_proof_enforces_geofence_mock_and_travel_rules() {
	let _ = verily_app::ops::BACKEND;
	let db = leptoskit_db::testing::sqlite().await;
	let auth = Auth::builder(&db, Keys::single("test", [11; 32]));
	let host = verily_backend::start(&db, auth, None, verily_backend::Options::new(&db)).unwrap();

	let creator_id = dev_identity(&host, "loc-creator@example.com").await;
	let alice_id = dev_identity(&host, "loc-alice@example.com").await;
	let bob_id = dev_identity(&host, "loc-bob@example.com").await;

	// Action 1: Central London (51.5074, -0.1278), radius 150 m.
	let london = leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		SaveAction {
			draft: DraftInput {
				id: None,
				title: "London check-in".into(),
				summary: "Confirm your presence in Trafalgar Square.".into(),
				place_name: "Trafalgar Square".into(),
				radius_meters: 150,
				reward_amount: String::new(),
				proofs: vec![ProofKind::Presence],
				latitude: Some(51.5074),
				longitude: Some(-0.1278),
			},
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		PublishAction {
			action_id: london.id.clone(),
		},
	)
	.await
	.unwrap();

	// Action 2: New York (40.7128, -74.0060), radius 150 m (for implausible travel check).
	let nyc = leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		SaveAction {
			draft: DraftInput {
				id: None,
				title: "NYC check-in".into(),
				summary: "Confirm your presence in Lower Manhattan.".into(),
				place_name: "Lower Manhattan".into(),
				radius_meters: 150,
				reward_amount: String::new(),
				proofs: vec![ProofKind::Presence],
				latitude: Some(40.7128),
				longitude: Some(-74.0060),
			},
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		creator_id,
		None,
		PublishAction {
			action_id: nyc.id.clone(),
		},
	)
	.await
	.unwrap();

	let now_ms = chrono::Utc::now().timestamp_millis();

	// 1. Mock location is rejected before consuming the capture window.
	let alice_london = leptoskit_rpc::server::call_as(
		&db,
		alice_id.clone(),
		None,
		BeginAttempt {
			action_id: london.id.clone(),
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		alice_id.clone(),
		None,
		BeginCapture {
			attempt_id: alice_london.attempt_id.clone(),
			requirement_id: alice_london.requirement_id.clone(),
		},
	)
	.await
	.unwrap();
	let mock_err = leptoskit_rpc::server::call_as(
		&db,
		alice_id.clone(),
		None,
		SubmitLocationProof {
			attempt_id: alice_london.attempt_id.clone(),
			requirement_id: alice_london.requirement_id.clone(),
			latitude: 51.5074,
			longitude: -0.1278,
			accuracy_meters: 10.0,
			captured_at_ms: now_ms,
			is_mock: true,
		},
	)
	.await
	.unwrap_err();
	assert!(
		mock_err.to_string().contains("mockLocationRejected"),
		"unexpected mock error: {mock_err}"
	);

	// 2. Real fix inside London geofence -> Verified!
	let receipt = leptoskit_rpc::server::call_as(
		&db,
		alice_id.clone(),
		None,
		SubmitLocationProof {
			attempt_id: alice_london.attempt_id.clone(),
			requirement_id: alice_london.requirement_id.clone(),
			latitude: 51.5075,
			longitude: -0.1279,
			accuracy_meters: 12.0,
			captured_at_ms: now_ms,
			is_mock: false,
		},
	)
	.await
	.unwrap();
	assert!(receipt.stored);
	let london_outcome = leptoskit_rpc::server::call_as(
		&db,
		alice_id.clone(),
		None,
		CompleteAttempt {
			attempt_id: alice_london.attempt_id,
		},
	)
	.await
	.unwrap();
	assert_eq!(london_outcome.status, AttemptStatus::Verified);

	// 3. Alice immediately checks in at NYC 5 seconds later (>5500 km in 5 s) -> held for PendingReview!
	let alice_nyc = leptoskit_rpc::server::call_as(
		&db,
		alice_id.clone(),
		None,
		BeginAttempt { action_id: nyc.id },
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		alice_id.clone(),
		None,
		BeginCapture {
			attempt_id: alice_nyc.attempt_id.clone(),
			requirement_id: alice_nyc.requirement_id.clone(),
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		alice_id.clone(),
		None,
		SubmitLocationProof {
			attempt_id: alice_nyc.attempt_id.clone(),
			requirement_id: alice_nyc.requirement_id.clone(),
			latitude: 40.7128,
			longitude: -74.0060,
			accuracy_meters: 10.0,
			captured_at_ms: now_ms + 5_000,
			is_mock: false,
		},
	)
	.await
	.unwrap();
	let nyc_outcome = leptoskit_rpc::server::call_as(
		&db,
		alice_id,
		None,
		CompleteAttempt {
			attempt_id: alice_nyc.attempt_id,
		},
	)
	.await
	.unwrap();
	assert_eq!(nyc_outcome.status, AttemptStatus::PendingReview);

	// 4. Bob checks in 2 km outside London geofence -> Rejected!
	let bob_london = leptoskit_rpc::server::call_as(
		&db,
		bob_id.clone(),
		None,
		BeginAttempt {
			action_id: london.id,
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		bob_id.clone(),
		None,
		BeginCapture {
			attempt_id: bob_london.attempt_id.clone(),
			requirement_id: bob_london.requirement_id.clone(),
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		bob_id.clone(),
		None,
		SubmitLocationProof {
			attempt_id: bob_london.attempt_id.clone(),
			requirement_id: bob_london.requirement_id.clone(),
			latitude: 51.5250,
			longitude: -0.1278,
			accuracy_meters: 10.0,
			captured_at_ms: now_ms,
			is_mock: false,
		},
	)
	.await
	.unwrap();
	let bob_outcome = leptoskit_rpc::server::call_as(
		&db,
		bob_id,
		None,
		CompleteAttempt {
			attempt_id: bob_london.attempt_id,
		},
	)
	.await
	.unwrap();
	assert_eq!(bob_outcome.status, AttemptStatus::Rejected);
}

#[tokio::test]
async fn venue_code_is_single_use_across_participants_with_fresh_windows() {
	let _ = verily_app::ops::BACKEND;
	let db = leptoskit_db::testing::sqlite().await;
	let auth = Auth::builder(&db, Keys::single("test", [12; 32]));
	let host = verily_backend::start(&db, auth, None, verily_backend::Options::new(&db)).unwrap();

	let creator_id = dev_identity(&host, "qr-creator@example.com").await;
	let first_id = dev_identity(&host, "qr-first@example.com").await;
	let second_id = dev_identity(&host, "qr-second@example.com").await;

	let saved = leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		SaveAction {
			draft: DraftInput {
				id: None,
				title: "Coffee counter scan".into(),
				summary: "Scan the rotating venue QR at the counter.".into(),
				place_name: "Corner Coffee".into(),
				radius_meters: 0,
				reward_amount: String::new(),
				proofs: vec![ProofKind::VenueCode],
				latitude: None,
				longitude: None,
			},
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		creator_id.clone(),
		None,
		PublishAction {
			action_id: saved.id.clone(),
		},
	)
	.await
	.unwrap();

	let qr = leptoskit_rpc::server::call_as(
		&db,
		creator_id,
		None,
		CreateQrChallenge {
			action_id: saved.id.clone(),
			ttl_seconds: Some(600),
		},
	)
	.await
	.unwrap();

	// First participant opens an attempt + capture window and redeems the code.
	let first_attempt = leptoskit_rpc::server::call_as(
		&db,
		first_id.clone(),
		None,
		BeginAttempt {
			action_id: saved.id.clone(),
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		first_id.clone(),
		None,
		BeginCapture {
			attempt_id: first_attempt.attempt_id.clone(),
			requirement_id: first_attempt.requirement_id.clone(),
		},
	)
	.await
	.unwrap();
	let redeemed = leptoskit_rpc::server::call_as(
		&db,
		first_id.clone(),
		None,
		SubmitQrProof {
			attempt_id: first_attempt.attempt_id.clone(),
			requirement_id: first_attempt.requirement_id.clone(),
			code: qr.code.clone(),
		},
	)
	.await
	.unwrap();
	assert!(redeemed.stored);
	let first_outcome = leptoskit_rpc::server::call_as(
		&db,
		first_id,
		None,
		CompleteAttempt {
			attempt_id: first_attempt.attempt_id,
		},
	)
	.await
	.unwrap();
	assert_eq!(first_outcome.status, AttemptStatus::Verified);

	// Second participant opens a fresh attempt + fresh capture window and tries to replay the code.
	let second_attempt = leptoskit_rpc::server::call_as(
		&db,
		second_id.clone(),
		None,
		BeginAttempt {
			action_id: saved.id,
		},
	)
	.await
	.unwrap();
	leptoskit_rpc::server::call_as(
		&db,
		second_id.clone(),
		None,
		BeginCapture {
			attempt_id: second_attempt.attempt_id.clone(),
			requirement_id: second_attempt.requirement_id.clone(),
		},
	)
	.await
	.unwrap();
	let replay_err = leptoskit_rpc::server::call_as(
		&db,
		second_id,
		None,
		SubmitQrProof {
			attempt_id: second_attempt.attempt_id,
			requirement_id: second_attempt.requirement_id,
			code: qr.code,
		},
	)
	.await
	.unwrap_err();
	assert!(
		replay_err.to_string().contains("venueCodeUsed"),
		"expected venueCodeUsed on replay, got: {replay_err}"
	);
}
