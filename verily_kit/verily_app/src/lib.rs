//! Verily's screens.
//!
//! The shell mounts [`App`] and nothing else from this crate. Screens are
//! files under `src/routes/`; [`routes::Route`] parses those paths. Copy
//! comes from `l10n/en.arb`. Colours and the pen come from [`theme`],
//! which builds on `verily_ink`.

mod chrome;
mod host;
#[allow(dead_code)]
mod l10n;
mod routes;
mod sign_in;
mod state;

use std::sync::Arc;
use std::sync::Mutex;
use std::sync::PoisonError;

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
	cache: Arc<Mutex<SessionCache>>,
	l10n: l10n::L10n,
}

/// Queries and form values belong to one session. Replacing the whole cache
/// also isolates late answers and callbacks from the previous session.
struct SessionCache {
	identity: Option<String>,
	query: leptoskit::query::QueryClient,
	state: state::Store,
}

impl SessionCache {
	fn new() -> Self {
		let query = leptoskit::query::QueryClient::new().with_defaults(
			leptoskit::query::QueryDefaults::new()
				.with_stale_time(std::time::Duration::from_secs(30))
				.with_retry_on_mount(false),
		);
		Self {
			identity: None,
			query,
			state: state::Store::default(),
		}
	}
}

impl Shared {
	/// Starts an empty cache with English messages.
	#[must_use]
	pub fn new() -> Self {
		Self {
			cache: Arc::new(Mutex::new(SessionCache::new())),
			l10n: l10n::L10n::new(&[]),
		}
	}

	/// Makes the cache and messages available to every component below.
	pub fn provide(&self) {
		let cache = self.cache.lock().unwrap_or_else(PoisonError::into_inner);
		cache.query.provide();
		self.l10n.provide();
		reactive_graph::owner::provide_context(cache.state.clone());
	}

	fn synchronize_session(&self, session: Option<leptoskit::auth::PublicSession>) {
		let identity = session.as_ref().map(|session| session.id.to_string());
		let mut cache = self.cache.lock().unwrap_or_else(PoisonError::into_inner);
		if cache.identity != identity {
			cache
				.query
				.cancel_queries(leptoskit::query::QueryFilter::all());
			*cache = SessionCache::new();
			cache.identity = identity;
			cache
				.query
				.set_query_data(&leptoskit::auth::client::session(), (), session);
		}
		drop(cache);
		self.provide();
		// Subscribe to the replacement's session query as well. Its next
		// sign-out or expiry must rebuild the gate, too.
		let _ = leptoskit::auth::client::use_auth().data();
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
	// Every screen is someone's: their attempts, drafts, and payouts. Until
	// the session query says who, nothing below asks the server anything.
	let session = leptoskit::auth::client::use_auth();
	match session.data() {
		Some(current) => {
			let signed_in = current.is_some();
			shared.synchronize_session(current);
			if signed_in {
				route(shared, navigation)
			} else {
				sign_in::page()
			}
		}
		None if session.is_error() => {
			shared.synchronize_session(None);
			sign_in::page()
		}
		None => sign_in::checking(),
	}
}

/// The current route's screen without the sign-in gate, for tests and
/// previews. It shows nothing private by itself: every operation a screen
/// calls runs as the signed-in person, and the server refuses it otherwise.
#[must_use]
pub fn route(shared: &Shared, navigation: &Navigation) -> Element {
	shared.provide();
	navigation.render()
}

/// Points sign-in, and the operations that run as the signed-in person, at
/// the server: the page's own origin in the browser, and in a native app the
/// origin `VERILY_API_ORIGIN` named at build time. A debug build falls back
/// to the kit server as the iOS Simulator and the Android emulator reach it.
/// A release build without one says sign-in isn't available.
pub fn connect() {
	let config = leptoskit::auth::client::ClientConfig::new();
	let config = match native_origin() {
		Some(origin) => config.origin(origin),
		None => config,
	};
	leptoskit::auth::client::configure(config);
}

/// The server a native build talks to, if any.
#[must_use]
pub fn native_origin() -> Option<&'static str> {
	if !cfg!(feature = "native") {
		return None;
	}
	option_env!("VERILY_API_ORIGIN").or(if !cfg!(debug_assertions) {
		None
	} else if cfg!(feature = "android") {
		Some("http://10.0.2.2:8184")
	} else {
		Some("http://127.0.0.1:8184")
	})
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
	connect();
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
	connect();
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

#[cfg(test)]
mod session_tests {
	use leptoskit::auth::PublicSession;
	use leptoskit::auth::client::session;
	use leptoskit::prelude::Get;
	use leptoskit::prelude::Set;
	use leptoskit::query::QueryScope;
	use reactive_graph::owner::Owner;

	use super::*;

	fn signed_in(id: &str) -> PublicSession {
		serde_json::from_value(serde_json::json!({
			"id": id,
			"account_id": id,
			"aal": "aal1",
			"authenticated_at": "2026-11-10T00:00:00Z",
			"mfa_at": null,
			"last_seen_at": "2026-11-10T00:00:00Z",
			"idle_expires_at": "2026-12-10T00:00:00Z",
			"expires_at": "2026-12-10T00:00:00Z",
			"device": "Test browser",
			"revoked_at": null,
			"created_at": "2026-11-10T00:00:00Z"
		}))
		.expect("public session")
	}

	#[test]
	fn account_changes_discard_private_queries_and_form_state() {
		let _ = any_spawner::Executor::init_futures_executor();
		Owner::new().with(|| {
			let shared = Shared::new();
			let navigation = Navigation::new(Route::Settings);
			let first = signed_in("00000000-0000-4000-8000-000000000001");
			let second = signed_in("00000000-0000-4000-8000-000000000002");
			let private = QueryScope::new(|()| async { Ok::<_, ()>(String::new()) });

			shared
				.cache
				.lock()
				.unwrap()
				.query
				.set_query_data(&session(), (), Some(first.clone()));
			let _ = screen(&shared, &navigation);
			let old_queries = shared.cache.lock().unwrap().query.clone();
			old_queries.set_query_data(&private, (), "First person's private draft".to_owned());
			state::remember("editor.title", String::new).set("First person's title".to_owned());
			// Rebuilding within a session retains its data and form.
			let _ = screen(&shared, &navigation);
			assert_eq!(
				state::remember("editor.title", String::new).get(),
				"First person's title"
			);

			old_queries.set_query_data(&session(), (), Some(second.clone()));
			let _ = screen(&shared, &navigation);
			let second_queries = shared.cache.lock().unwrap().query.clone();
			assert_eq!(second_queries.get_query_data(&private, &()), None);
			assert_eq!(state::remember("editor.title", String::new).get(), "");
			assert_eq!(
				second_queries.get_query_data(&session(), &()),
				Some(Some(second))
			);
			// An old request or mutation cannot populate the new session.
			old_queries.set_query_data(&private, (), "Late private answer".to_owned());
			assert_eq!(second_queries.get_query_data(&private, &()), None);

			state::remember("settings.confirmation", String::new).set("DELETE".to_owned());
			second_queries.set_query_data(&session(), (), None);
			let _ = screen(&shared, &navigation);
			assert_eq!(
				state::remember("settings.confirmation", String::new).get(),
				""
			);
			assert_eq!(
				shared
					.cache
					.lock()
					.unwrap()
					.query
					.get_query_data(&session(), &()),
				Some(None)
			);
		});
	}
}
