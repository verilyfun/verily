//! Verily's screens.
//!
//! The shell mounts [`App`] and nothing else from this crate. Screens read
//! and write through `leptoskit_rpc` operations served by `verily_backend`.
//! Copy comes from `l10n/app_en.arb`. Colours come from [`theme`].

mod chrome;
mod host;
#[allow(dead_code)]
mod l10n;
mod route;
mod screens;

pub mod model;
pub mod ops;
pub mod theme;

pub use route::ActionPage;
pub use route::AppRoute;
pub use route::CapturePage;
pub use route::EditorPage;
pub use route::Navigation;

use leptoskit::component;
use leptoskit::view;

/// The root the shell mounts, inside a reactive owner.
///
/// Provides Verily's paper tokens, the query cache, and English messages,
/// then draws the current route. Android is the first native target; the same
/// tree is the web target. Live capture calls the shell plugins and does not
/// offer a gallery.
#[component]
pub fn App(navigation: Navigation) -> leptoskit::prelude::Element {
	theme::install_paper();
	leptoskit::query::QueryClient::new().provide();
	l10n::L10n::new(&[]).provide();
	view! { <chrome::Shell navigation=navigation /> }
}
