//! The frame around every screen: page padding, and a back control off the tabs.

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

/// Tabs stay on Do, Create, and Me. Every other screen can go back.
#[component]
pub fn Layout(children: Children, navigation: &Navigation, route: &Route) -> Element {
	let l10n = use_l10n();
	let shows_tabs = matches!(route, Route::Do | Route::Create | Route::Me);
	let back = if shows_tabs {
		None
	} else {
		let back = navigation.clone();
		let label = l10n.action_back();
		Some(view! {
			<Button class=theme::QUIET on:press=move || { back.back(); }>{label}</Button>
		})
	};
	view! {
		<View class=theme::PAGE>
			{back}
			{children}
		</View>
	}
}
