//! The tab bar under Do, Create, and Me.

use leptoskit::component;
use leptoskit::prelude::Button;
use leptoskit::prelude::Children;
use leptoskit::prelude::Element;
use leptoskit::prelude::View;
use leptoskit::view;

use crate::l10n::use_l10n;
use crate::routes::Navigation;
use crate::routes::Route;
use crate::theme;

/// The three roots, with the selected one marked.
#[component]
pub fn Layout(children: Children, navigation: &Navigation, route: &Route) -> Element {
	let l10n = use_l10n();
	let on_do = matches!(route, Route::Do);
	let on_create = matches!(route, Route::Create);
	let on_me = matches!(route, Route::Me);
	view! {
		<View class="flex flex-col gap-4">
			{children}
			<View class=theme::ROW>
				<Tab navigation=navigation route=Route::Do label=l10n.tab_do() selected=on_do />
				<Tab
					navigation=navigation
					route=Route::Create
					label=l10n.tab_create()
					selected=on_create
				/>
				<Tab navigation=navigation route=Route::Me label=l10n.tab_me() selected=on_me />
			</View>
		</View>
	}
}

#[component]
fn Tab(navigation: &Navigation, route: Route, label: impl Into<String>, selected: bool) -> Element {
	let navigation = navigation.clone();
	let label = label.into();
	let class = if selected {
		theme::PRIMARY
	} else {
		theme::QUIET
	};
	view! {
		<Button class=class on:press=move || navigation.navigate(route.clone())>{label}</Button>
	}
}
