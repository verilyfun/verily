//! Route, token, capture, and publish invariants the screens rely on.

use leptoskit::prelude::Tailwind;
use leptoskit::rpc::Kind;
use leptoskit::rpc::Operation;
use leptoskit::view;
use leptoskit_router::Routable;
use verily_app::model::ActionFilter;
use verily_app::model::EvidenceSource;
use verily_app::model::ProofKind;
use verily_app::model::PublishOutcome;
use verily_app::model::WalletLink;
use verily_app::ops::BACKEND;
use verily_app::ops::ListAvailableActions;

#[test]
fn catalogue_query_names_the_backend_service() {
	assert_eq!(ListAvailableActions::NAME, "list_available_actions");
	assert_eq!(ListAvailableActions::KIND, Kind::Query);
	assert_eq!(ListAvailableActions::SERVICE, Some(BACKEND));
	let _ = ListAvailableActions {
		filter: ActionFilter::Nearby,
		latitude: None,
		longitude: None,
	};
}

#[test]
fn live_proof_never_comes_from_a_library() {
	for kind in [
		ProofKind::Photo,
		ProofKind::Video,
		ProofKind::Audio,
		ProofKind::Presence,
		ProofKind::Movement,
		ProofKind::VenueCode,
		ProofKind::Note,
		ProofKind::App,
	] {
		assert_eq!(
			verily_app::model::evidence_source(kind),
			EvidenceSource::LivePlugin
		);
	}
	assert!(ProofKind::Photo.needs_live_capture());
	assert!(!ProofKind::Note.needs_live_capture());
}

#[test]
fn an_unfunded_publish_is_not_live() {
	let outcome = |published, rewarded, funded| PublishOutcome {
		published,
		rewarded,
		funded,
	};
	assert!(!outcome(true, true, false).is_live());
	assert!(outcome(true, true, true).is_live());
	assert!(outcome(true, false, false).is_live());
	assert!(!outcome(false, false, false).is_live());
	assert!(!outcome(false, true, true).is_live());
}

#[test]
fn the_wallet_record_has_no_address() {
	let json = serde_json::to_value(WalletLink { linked: true }).expect("json");
	let object = json.as_object().expect("object");
	assert!(object.contains_key("linked"));
	assert!(!object.contains_key("address"));
	assert!(!object.contains_key("secret"));
	assert!(!object.contains_key("token"));
}

#[test]
fn routes_round_trip() {
	let routes = [
		verily_app::Route::Do,
		verily_app::Route::Action(verily_app::Action {
			action: "plant-a-tree".into(),
		}),
		verily_app::Route::Capture(verily_app::Capture {
			attempt: "attempt-1".into(),
			requirement: "photo".into(),
		}),
		verily_app::Route::Create,
		verily_app::Route::Editor(verily_app::Editor {
			draft: "new".into(),
		}),
		verily_app::Route::Me,
		verily_app::Route::Review,
		verily_app::Route::Settings,
	];
	for route in routes {
		let parsed = verily_app::Route::parse(route.href().as_str()).expect("href parses");
		assert_eq!(parsed, route);
	}
}

#[test]
fn the_do_screen_builds() {
	let _ = any_spawner::Executor::init_futures_executor();
	let owner = leptoskit::leptos::prelude::Owner::new();
	owner.with(|| {
		let routes = [
			verily_app::Route::Do,
			verily_app::Route::Action(verily_app::Action {
				action: "plant-a-tree".into(),
			}),
			verily_app::Route::Capture(verily_app::Capture {
				attempt: "attempt".into(),
				requirement: "photo".into(),
			}),
			verily_app::Route::Create,
			verily_app::Route::Editor(verily_app::Editor {
				draft: "new".into(),
			}),
			verily_app::Route::Me,
			verily_app::Route::Review,
			verily_app::Route::Settings,
		];
		for route in routes {
			let navigation = verily_app::Navigation::new(route);
			let screen = verily_app::route(&verily_app::Shared::new(), &navigation);
			assert!(!screen.children.is_empty());
		}
	});
}

#[test]
fn nothing_shows_before_the_session_answers() {
	let _ = any_spawner::Executor::init_futures_executor();
	let owner = leptoskit::leptos::prelude::Owner::new();
	owner.with(|| {
		let navigation = verily_app::Navigation::new(verily_app::Route::Me);
		let gated = view! { <verily_app::App navigation=navigation.clone() /> };
		let open = verily_app::route(&verily_app::Shared::new(), &navigation);
		assert!(!gated.children.is_empty());
		assert_ne!(
			format!("{gated:?}"),
			format!("{open:?}"),
			"the gate shows the checking page, not the screen"
		);
	});
}

#[test]
fn screen_classes_parse() {
	for classes in verily_app::theme::class_sheet() {
		Tailwind::parse(classes).unwrap_or_else(|error| {
			panic!("{classes} failed to parse: {error}");
		});
	}
}
