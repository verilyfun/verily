//! The route the address bar opens, on the server and in the browser.

use verily_app::Route;
use verily_app::initial_route;

#[test]
fn the_root_opens_do() {
	for path in ["", "/", "//", "/?ref=landing", "/#top"] {
		assert_eq!(initial_route(path), Route::Do, "{path:?}");
	}
}

#[test]
fn each_screen_opens_at_its_own_path() {
	assert_eq!(initial_route("/do"), Route::Do);
	assert_eq!(initial_route("/create"), Route::Create);
	assert_eq!(initial_route("/me"), Route::Me);
	assert_eq!(initial_route("/settings"), Route::Settings);
	assert_eq!(initial_route("/review?tab=open"), Route::Review);
	assert!(matches!(initial_route("/do/act_123"), Route::Action(_)));
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
