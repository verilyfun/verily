//! The route the address bar opens, on the server and in the browser.
//!
//! Paths match the links the Flutter app published, so App Links and shared
//! URLs keep opening the same pages.

use verily_app::Action;
use verily_app::EditAction;
use verily_app::Route;
use verily_app::initial_route;

#[test]
fn the_root_opens_the_front_door() {
	for path in ["", "/", "/?ref=landing", "/#top"] {
		assert_eq!(initial_route(path), Route::Index, "{path:?}");
	}
}

#[test]
fn each_page_opens_at_its_own_path() {
	assert_eq!(initial_route("/do"), Route::Do);
	assert_eq!(initial_route("/create"), Route::Create);
	assert_eq!(initial_route("/me"), Route::Me);
	assert_eq!(initial_route("/settings"), Route::Settings);
	assert_eq!(initial_route("/reviews?tab=open"), Route::Reviews);
	assert_eq!(
		initial_route("/actions/act_123"),
		Route::Action(Action {
			action: "act_123".to_owned()
		})
	);
	assert_eq!(
		initial_route("/actions/act_123/edit"),
		Route::EditAction(EditAction {
			action: "act_123".to_owned()
		})
	);
	assert_eq!(initial_route("/actions/new"), Route::NewAction);
}

#[test]
fn an_unknown_path_opens_the_not_found_screen() {
	assert!(matches!(
		initial_route("/nowhere/at/all"),
		Route::NotFound(_)
	));
}

#[test]
fn the_browser_build_signs_in_on_its_own_origin() {
	assert_eq!(verily_app::native_origin(), None);
}
