//! Editing an action, `/actions/:action/edit`.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::view;
use leptoskit_router::Route;

use crate::editor::Editor;

/// `/actions/:action/edit`.
#[derive(Route, Clone, Debug, PartialEq)]
pub struct EditAction {
	pub action: String,
}

/// The saved draft.
#[component]
pub fn Page(route: &EditAction) -> Element {
	view! { <Editor draft=Some(route.action.clone()) /> }
}
