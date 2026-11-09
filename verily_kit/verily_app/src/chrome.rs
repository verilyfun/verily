//! Shared type for titles and secondary copy.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Text;
use leptoskit::view;

use crate::theme;

/// A section title.
#[component]
pub fn Title(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=theme::TITLE>{text}</Text> }
}

/// Secondary copy.
#[component]
pub fn Muted(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=theme::MUTED>{text}</Text> }
}
