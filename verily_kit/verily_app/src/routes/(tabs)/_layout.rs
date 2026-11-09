//! The tab bar under Do, Create, and Me.

use leptoskit::component;
use leptoskit::prelude::Children;
use leptoskit::prelude::Element;
use leptoskit::prelude::View;
use leptoskit::view;
use skribble_leptoskit::WiredDivider;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::routes::Navigation;
use crate::routes::Route;
use crate::theme;

/// The three roots, with the selected one filled.
#[component]
pub fn Layout(children: Children, navigation: &Navigation, route: &Route) -> Element {
	let l10n = use_l10n();
	view! {
		<View class="flex flex-col gap-6">
			{children}
			<View class="flex flex-col gap-2">
				<WiredDivider seed=111 theme=theme::INK />
				<View class=theme::TABS.as_str()>
					<Tab navigation=navigation route=Route::Do label=l10n.tab_do() current=route seed=113 />
					<Tab
						navigation=navigation
						route=Route::Create
						label=l10n.tab_create()
						current=route
						seed=115
					/>
					<Tab navigation=navigation route=Route::Me label=l10n.tab_me() current=route seed=117 />
				</View>
			</View>
		</View>
	}
}

#[component]
fn Tab(
	navigation: &Navigation,
	route: Route,
	label: impl Into<String>,
	current: &Route,
	seed: i64,
) -> Element {
	let navigation = navigation.clone();
	let selected = *current == route;
	view! {
		<chrome::Choice
			label=label.into()
			selected=selected
			seed=seed
			class="flex-1"
			on_press=move || navigation.navigate(route.clone())
		/>
	}
}
