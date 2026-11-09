//! The frame around every screen: the notebook's paper, the mark, and a back
//! control off the tabs.

use leptoskit::component;
use leptoskit::prelude::Children;
use leptoskit::prelude::Element;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::view;
use skribble_leptoskit::SkribblePage;
use verily_ink::draw;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::routes::Navigation;
use crate::routes::Route;
use crate::theme;

/// Tabs stay on Do, Create, and Me. Every other screen can go back.
#[component]
pub fn Layout(children: Children, navigation: &Navigation, route: &Route) -> Element {
	let l10n = use_l10n();
	let shows_tabs = matches!(route, Route::Do | Route::Create | Route::Me);
	let back = if shows_tabs {
		None
	} else {
		let back = navigation.clone();
		Some(view! {
			<chrome::Quiet label=l10n.action_back() on_press=move || { back.back(); } seed=101 />
		})
	};
	view! {
		<SkribblePage theme=theme::INK class=theme::PAGE.as_str()>
			<View class="flex flex-row items-center justify-between gap-3">
				<View class=theme::LINE.as_str()>
					{draw::mark(32.0, 97, Some("Verily"))}
					<Text class=theme::TITLE.as_str()>"Verily"</Text>
				</View>
				{back}
			</View>
			{children}
		</SkribblePage>
	}
}
