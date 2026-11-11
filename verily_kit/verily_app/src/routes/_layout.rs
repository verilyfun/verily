//! The paper under every page.
//!
//! The router keeps history. This layout adds a written "Back" above every
//! page that is not a tab root or the front door. LeptosKit 0.3.0 has no
//! stack navigator, so there is no edge-swipe gesture here.

use leptoskit::component;
use leptoskit::prelude::Children;
use leptoskit::prelude::Element;
use leptoskit::prelude::View;
use leptoskit::view;
use skribble_leptoskit::SkribblePage;
use verily_ink::sketches;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::routes::Navigation;
use crate::routes::Route;
use crate::theme;

/// Paper and ink behind every route, and a way back off the tab roots.
#[component]
pub fn Layout(children: Children, navigation: &Navigation, route: &Route) -> Element {
	let roots = matches!(route, Route::Index | Route::Do | Route::Create | Route::Me);
	let back = (!roots && navigation.can_go_back()).then(|| {
		let l10n = use_l10n();
		let back = navigation.clone();
		view! {
			<View class="flex flex-row items-center gap-2 px-4 pt-4">
				{sketches::arrow_back(28.0, 41)}
				<chrome::Quiet
					label=l10n.action_back()
					on_press=move || {
						back.back();
					}
					seed=43
				/>
			</View>
		}
	});
	view! {
		<SkribblePage theme=theme::PEN class="flex flex-col flex-1">
			{back} <View class="flex flex-col flex-1">{children}</View>
		</SkribblePage>
	}
}
