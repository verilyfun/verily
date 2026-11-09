//! A URL that matches no screen.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::View;
use leptoskit::view;
use verily_ink::draw;

use crate::chrome;
use crate::l10n::use_l10n;

/// Shown when the path is not one of the screens.
#[component]
pub fn Page() -> Element {
	let l10n = use_l10n();
	view! {
		<View class="flex flex-col gap-6">
			<chrome::Empty picture=draw::place_map(251) title=l10n.action_not_found_title() body="" />
		</View>
	}
}
