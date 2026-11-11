//! Screen state that outlives a rebuild.
//!
//! leptoskit rebuilds a screen whenever a signal it read changes: the
//! browser re-renders it from one closure, and the native runtime calls the
//! screen function again. A signal created with `RwSignal::new` inside a
//! screen is created again on every rebuild, so typing into a field or
//! choosing a filter would be forgotten the moment the screen redraws.
//! [`remember`] hands back the same value each time instead, keyed by the
//! screen and what it is about.

use std::any::Any;
use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;
use std::sync::PoisonError;

use leptoskit::prelude::Get;
use leptoskit::prelude::RwSignal;
use leptoskit::query::MutationHandle;
use leptoskit::query::MutationScope;
use leptoskit::query::QueryData;
use leptoskit::query::QueryError;
use leptoskit::query::use_mutation_in;
use leptoskit::query::use_query_client;
use reactive_graph::owner::Owner;
use reactive_graph::owner::use_context;

/// Values that live as long as the app, by key.
#[derive(Clone)]
pub struct Store {
	values: Arc<Mutex<HashMap<String, Box<dyn Any + Send + Sync>>>>,
	// A child of the owner that built the store, so it shares that arena
	// when sandboxed arenas are on. A derived `Owner::default()` would be a
	// disconnected arena, and a later render could not read the signal.
	owner: Owner,
}

impl Default for Store {
	fn default() -> Self {
		Self {
			values: Arc::new(Mutex::new(HashMap::new())),
			owner: Owner::new(),
		}
	}
}

/// Polls spawned tasks on the calling thread.
///
/// LeptosKit's mutation tasks write signals. With sandboxed arenas those
/// writes have to happen on the thread whose arena is current. The futures
/// thread pool is a different thread, so a success callback there cannot
/// mark an appeal sent.
#[cfg(test)]
pub(crate) fn install_test_executor() {
	struct Inline;

	fn drive(mut fut: impl std::future::Future<Output = ()> + Unpin) {
		let waker = std::task::Waker::noop();
		let mut context = std::task::Context::from_waker(waker);
		// A mutation's success callback is a nested task. Polling a few
		// times lets the outer task observe a future that was already ready
		// without a thread-pool wake, which would miss this thread's arena.
		for _ in 0..16 {
			if std::pin::Pin::new(&mut fut).poll(&mut context).is_ready() {
				break;
			}
		}
	}

	impl any_spawner::CustomExecutor for Inline {
		fn spawn(&self, fut: any_spawner::PinnedFuture<()>) {
			drive(fut);
		}

		fn spawn_local(&self, fut: any_spawner::PinnedLocalFuture<()>) {
			drive(fut);
		}

		fn poll_local(&self) {}
	}

	let _ = any_spawner::Executor::init_custom_executor(Inline);
}

impl Store {
	/// The signal stored under `key`, created from `init` the first time.
	///
	/// # Panics
	///
	/// When `key` already holds a value of another type: two screens chose
	/// the same key.
	pub fn signal<T>(&self, key: &str, init: impl FnOnce() -> T) -> RwSignal<T>
	where
		T: Send + Sync + 'static,
	{
		let mut values = self.values.lock().unwrap_or_else(PoisonError::into_inner);
		let value = values
			.entry(key.to_owned())
			.or_insert_with(|| Box::new(self.owner.with(|| RwSignal::new(init()))))
			.downcast_ref::<RwSignal<T>>()
			.unwrap_or_else(|| panic!("`{key}` holds a different type: keys must be unique"));
		*value
	}
}

/// The signal stored under `key` in the provided [`Store`], created from
/// `init` the first time. Without a store, as in a one-off render, it is a
/// fresh signal.
pub fn remember<T>(key: &str, init: impl FnOnce() -> T) -> RwSignal<T>
where
	T: Send + Sync + 'static,
{
	match use_context::<Store>() {
		Some(store) => store.signal(key, init),
		None => RwSignal::new(init()),
	}
}

/// A mutation observer that survives screen rebuilds, including its pending
/// state. The explicit client comes from the screen, before entering the
/// store's independent owner.
pub fn mutation<V, T, E, C>(
	key: &str,
	scope: MutationScope<V, T, E, C>,
) -> MutationHandle<V, T, E, C>
where
	V: QueryData,
	T: QueryData,
	E: QueryError,
	C: QueryData,
{
	let client = use_query_client();
	remember(key, || use_mutation_in(client, scope)).get()
}

#[cfg(test)]
mod tests {
	use leptoskit::prelude::Get;
	use leptoskit::prelude::Set;
	use reactive_graph::owner::Owner;
	use reactive_graph::owner::provide_context;

	use super::*;

	#[test]
	fn a_remembered_signal_survives_a_rebuild() {
		// Sandboxed arenas are shared from the root owner down. The store and
		// both renders have to be children of one root, or each render looks
		// in an arena that does not hold the remembered signal.
		let root = Owner::new();
		root.with(|| {
			let store = Store::default();
			let first = Owner::new();
			let chosen = first.with(|| {
				provide_context(store.clone());
				let filter = remember("do.filter", || 0);
				filter.set(3);
				filter.get()
			});
			drop(first);
			let second = Owner::new();
			let again = second.with(|| {
				provide_context(store.clone());
				remember("do.filter", || 0).get()
			});
			assert_eq!((chosen, again), (3, 3));
		});
	}

	#[test]
	fn a_callback_can_write_through_its_original_handle_after_render_cleanup() {
		let root = Owner::new();
		root.with(|| {
			let store = Store::default();
			let render = Owner::new();
			let original = render.with(|| {
				provide_context(store.clone());
				remember("sign_in.notice", String::new)
			});
			render.cleanup();
			original.set("Please check your code".to_owned());
			render.with(|| {
				provide_context(store);
				assert_eq!(
					remember("sign_in.notice", String::new).get(),
					"Please check your code"
				);
			});
		});
	}

	#[test]
	fn a_pending_mutation_stays_pending_after_render_cleanup() {
		install_test_executor();
		let root = Owner::new();
		root.with(|| {
			let store = Store::default();
			let client = leptoskit::query::QueryClient::new();
			let scope = MutationScope::new(|()| std::future::pending::<Result<(), ()>>());
			let render = Owner::new();
			let start = render.with(|| {
				provide_context(store.clone());
				client.provide();
				mutation("sign_in.send", scope.clone())
			});
			start.mutate(());
			render.cleanup();
			render.with(|| {
				provide_context(store);
				client.provide();
				assert!(mutation("sign_in.send", scope).is_pending());
			});
		});
	}

	#[test]
	fn without_a_store_each_call_is_fresh() {
		Owner::new().with(|| {
			remember("do.filter", || 0).set(5);
			assert_eq!(remember("do.filter", || 0).get(), 0);
		});
	}

	#[test]
	#[should_panic(expected = "keys must be unique")]
	fn one_key_holds_one_type() {
		let root = Owner::new();
		root.with(|| {
			let store = Store::default();
			Owner::new().with(|| {
				let _ = store.signal("shared", || 0_u8);
				let _ = store.signal("shared", String::new);
			});
		});
	}
}
