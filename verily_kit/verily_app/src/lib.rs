//! Verily's screens.
//!
//! The shell mounts [`App`] and nothing else from this crate. Screens are
//! files under `src/routes/`; [`routes::Route`] parses those paths. Copy
//! comes from `l10n/app_en.arb`. Colours come from [`theme`].

mod chrome;
mod host;
#[allow(dead_code)]
mod l10n;
mod routes;

pub mod model;
pub mod ops;
pub mod theme;

pub use routes::Action;
pub use routes::Capture;
pub use routes::Editor;
pub use routes::Navigation;
pub use routes::Route;

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Show;

/// The root the shell mounts, inside a reactive owner.
///
/// Provides Verily's paper tokens, the query cache, and English messages,
/// then draws the current route inside its layouts. Android is the first
/// native target; the same tree is the web target. Live capture calls the
/// shell plugins and does not offer a gallery.
#[component]
pub fn App(navigation: Navigation) -> Element {
	theme::install_paper();
	leptoskit::query::QueryClient::new().provide();
	l10n::L10n::new(&[]).provide();
	let watch = navigation.clone();
	let build = navigation.clone();
	Show(
		move || {
			let _ = watch.current();
			true
		},
		move || build.render(),
	)
}
