//! Verily's screens.
//!
//! The shell mounts [`App`] and nothing else from this crate. Screens are
//! files under `src/routes/`; [`routes::Route`] parses those paths. Copy
//! comes from `l10n/app_en.arb`. Colours and the pen come from [`theme`],
//! which builds on `verily_ink`.

mod chrome;
mod host;
#[allow(dead_code)]
mod l10n;
mod routes;
mod state;

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

/// What every screen reads: one query cache, the messages, and the state
/// that outlives a rebuild. Create it once where the app starts; [`screen`]
/// provides it to each rebuild, so a rebuild never drops the cache.
#[derive(Clone)]
pub struct Shared {
	query: leptoskit::query::QueryClient,
	l10n: l10n::L10n,
	state: state::Store,
}

impl Shared {
	/// Starts an empty cache with English messages.
	#[must_use]
	pub fn new() -> Self {
		Self {
			// leptoskit rebuilds a screen when its data arrives, which mounts
			// its queries again: half a minute of freshness keeps a rebuild
			// from fetching what it just fetched, and a failed query waits
			// for "Try again" instead of retrying on every redraw.
			query: leptoskit::query::QueryClient::new().with_defaults(
				leptoskit::query::QueryDefaults::new()
					.with_stale_time(std::time::Duration::from_secs(30))
					.with_retry_on_mount(false),
			),
			l10n: l10n::L10n::new(&[]),
			state: state::Store::default(),
		}
	}

	/// Makes the cache and messages available to every component below.
	pub fn provide(&self) {
		self.query.provide();
		self.l10n.provide();
		reactive_graph::owner::provide_context(self.state.clone());
	}
}

impl Default for Shared {
	fn default() -> Self {
		Self::new()
	}
}

/// The screen for the current route. Hosts call this from the closure that
/// rebuilds the screen, so every signal it reads, the route included, is
/// tracked there; the browser and the native runtime rebuild it when one
/// changes.
#[must_use]
pub fn screen(shared: &Shared, navigation: &Navigation) -> Element {
	shared.provide();
	navigation.render()
}

/// The root a test or a single render mounts, inside a reactive owner:
/// fresh [`Shared`] state and the current route's screen.
///
/// Native is Android first; the same tree is the web target. Live capture
/// calls the shell plugins and does not offer a gallery.
#[component]
pub fn App(navigation: Navigation) -> Element {
	screen(&Shared::new(), &navigation)
}

/// The route a path on this site opens. The site's root opens Do; a path no
/// screen claims opens the not-found screen.
#[must_use]
pub fn initial_route(path: &str) -> Route {
	use leptoskit_router::Routable as _;

	let bare = path.split(['?', '#']).next().unwrap_or_default();
	if bare.trim_matches('/').is_empty() {
		return Route::Do;
	}
	Route::parse(path).unwrap_or(Route::Do)
}

/// The browser and server adapter: the same [`App`], with the route the
/// address bar names. The server passes the request's `path`; the browser
/// reads its own location and keeps history in step.
#[cfg(feature = "web")]
#[leptos::component]
pub fn WebApp(#[prop(optional, into)] path: String) -> impl leptos::prelude::IntoView {
	#[cfg(target_arch = "wasm32")]
	let navigation = {
		let _ = path;
		let navigation = Navigation::from_browser().unwrap_or_else(|_| Navigation::new(Route::Do));
		if web_root() {
			navigation.replace(Route::Do);
		}
		navigation
	};
	#[cfg(not(target_arch = "wasm32"))]
	let navigation = Navigation::new(initial_route(&path));
	let shared = Shared::new();
	move || leptoskit::web::render(screen(&shared, &navigation))
}

/// Whether the browser is at the site's root, which opens Do.
#[cfg(all(feature = "web", target_arch = "wasm32"))]
fn web_root() -> bool {
	leptos::prelude::window()
		.location()
		.pathname()
		.is_ok_and(|path| path.trim_matches('/').is_empty())
}

/// Hydrates the server's markup when the document's hydration script calls it.
#[cfg(all(target_arch = "wasm32", feature = "hydrate"))]
#[wasm_bindgen::prelude::wasm_bindgen]
pub fn hydrate() {
	#[cfg(feature = "devtools")]
	leptoskit::devtools::install(env!("CARGO_PKG_NAME"));
	leptos::mount::hydrate_body(|| leptos::prelude::view! { <WebApp /> });
}

/// Mounts the client-rendered app when the browser loads its Wasm module.
#[cfg(all(target_arch = "wasm32", feature = "web", not(feature = "hydrate")))]
#[wasm_bindgen::prelude::wasm_bindgen(start)]
pub fn start() {
	#[cfg(feature = "devtools")]
	leptoskit::devtools::install(env!("CARGO_PKG_NAME"));
	leptos::mount::mount_to_body(|| leptos::prelude::view! { <WebApp /> });
}

/// Mounts the same app in the native Wasm runtime, on Do.
#[cfg(all(target_arch = "wasm32", feature = "native"))]
#[unsafe(no_mangle)]
pub extern "C" fn leptoskit_main() {
	let navigation = Navigation::new(Route::Do);
	navigation.bind_system_back();
	let shared = Shared::new();
	leptoskit::guest::mount(move || screen(&shared, &navigation));
}

/// Android system Back and similar host signals: 1 when the router popped a
/// route, 0 when the host should leave the app.
#[cfg(all(target_arch = "wasm32", feature = "native"))]
#[unsafe(no_mangle)]
pub extern "C" fn leptoskit_system_back() -> i32 {
	match leptoskit_router::dispatch_system_back() {
		leptoskit_router::SystemBack::Consumed => 1,
		leptoskit_router::SystemBack::Propagate => 0,
	}
}

/// Forwards platform-neutral events to the tree's handlers.
#[cfg(all(target_arch = "wasm32", feature = "native"))]
#[unsafe(no_mangle)]
pub extern "C" fn leptoskit_event(node: i64, kind: i32, ptr: i32, len: i32) -> i32 {
	leptoskit::guest::dispatch(node, kind, ptr, len)
}

/// Settles the values application state bound, after a turn.
#[cfg(all(target_arch = "wasm32", feature = "native"))]
#[unsafe(no_mangle)]
pub extern "C" fn leptoskit_flush() {
	leptoskit::guest::flush();
}

/// Runs tasks the runtime queued, then settles what they wrote. The host
/// calls this after a plugin reply.
#[cfg(all(target_arch = "wasm32", feature = "native"))]
#[unsafe(no_mangle)]
pub extern "C" fn leptoskit_poll() {
	leptoskit::guest::poll();
}

/// Allocates the native runtime's event payload buffer.
#[cfg(all(target_arch = "wasm32", feature = "native"))]
#[unsafe(no_mangle)]
pub extern "C" fn leptoskit_alloc(len: i32) -> i32 {
	leptoskit::guest::alloc(len)
}

/// Reports the native UI bridge ABI this app implements.
#[cfg(all(target_arch = "wasm32", feature = "native"))]
#[unsafe(no_mangle)]
pub extern "C" fn leptoskit_abi_version() -> i32 {
	leptoskit::guest::ABI_VERSION as i32
}
