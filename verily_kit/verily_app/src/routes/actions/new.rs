//! A new action, `/actions/new`.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::view;
use leptoskit_router::Route;

use crate::editor::Editor;

/// `/actions/new`.
#[derive(Route, Clone, Debug, PartialEq)]
pub struct NewAction;

/// A blank draft.
#[component]
pub fn Page() -> Element {
	view! { <Editor draft=None /> }
}
