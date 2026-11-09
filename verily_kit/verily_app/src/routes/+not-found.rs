//! A URL that matches no screen.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::View;
use leptoskit::view;

use crate::chrome;
use crate::l10n::use_l10n;

/// Shown when the path is not one of the screens.
#[component]
pub fn Page() -> Element {
	let l10n = use_l10n();
	view! {
		<View class="flex flex-col gap-4">
			<chrome::Title text=l10n.action_not_found_title() />
		</View>
	}
}
