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

use leptoskit::prelude::RwSignal;
use reactive_graph::owner::use_context;
use reactive_graph::signal::ArcRwSignal;

/// Values that live as long as the app, by key.
#[derive(Clone, Default)]
pub struct Store {
	values: Arc<Mutex<HashMap<String, Box<dyn Any + Send + Sync>>>>,
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
			.or_insert_with(|| Box::new(ArcRwSignal::new(init())))
			.downcast_ref::<ArcRwSignal<T>>()
			.unwrap_or_else(|| panic!("`{key}` holds a different type: keys must be unique"))
			.clone();
		RwSignal::from(value)
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

#[cfg(test)]
mod tests {
	use leptoskit::prelude::Get;
	use leptoskit::prelude::Set;
	use reactive_graph::owner::Owner;
	use reactive_graph::owner::provide_context;

	use super::*;

	#[test]
	fn a_remembered_signal_survives_a_rebuild() {
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
		let store = Store::default();
		Owner::new().with(|| {
			let _ = store.signal("shared", || 0_u8);
			let _ = store.signal("shared", String::new);
		});
	}
}
