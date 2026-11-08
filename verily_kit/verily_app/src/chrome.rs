//! The page frame: a back control on nested screens, and tabs on Do, Create, and Me.

use leptoskit::component;
use leptoskit::prelude::Button;
use leptoskit::prelude::Element;
use leptoskit::prelude::Show;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::view;

use crate::l10n::use_l10n;
use crate::route::AppRoute;
use crate::route::Navigation;
use crate::screens;
use crate::theme;

/// The shell mounts this once, inside a reactive owner, after [`crate::App`]
/// has provided translations and the query client.
#[component]
pub fn Shell(navigation: Navigation) -> Element {
	let watch = navigation.clone();
	let build = navigation.clone();
	Show(
		move || {
			let _ = watch.current();
			true
		},
		move || view! { <Frame navigation=build.clone() /> },
	)
}

#[component]
fn Frame(navigation: Navigation) -> Element {
	let l10n = use_l10n();
	let route = navigation.current();
	let body = match &route {
		AppRoute::Do => view! { <screens::Browse navigation=&navigation /> },
		AppRoute::Action(page) => {
			view! { <screens::ActionScreen navigation=&navigation page=page /> }
		}
		AppRoute::Capture(page) => {
			view! { <screens::Capture navigation=&navigation page=page /> }
		}
		AppRoute::Create => view! { <screens::CreateHub navigation=&navigation /> },
		AppRoute::Editor(page) => {
			view! { <screens::Editor navigation=&navigation page=page /> }
		}
		AppRoute::Me => view! { <screens::Me navigation=&navigation /> },
		AppRoute::Review => view! { <screens::ReviewQueue navigation=&navigation /> },
		AppRoute::Settings => view! { <screens::Settings navigation=&navigation /> },
	};
	let back = if route.shows_tabs() {
		None
	} else {
		let back = navigation.clone();
		let label = l10n.action_back();
		Some(view! {
			<Button class=theme::QUIET on:press=move || { back.back(); }>{label}</Button>
		})
	};
	let tabs = route
		.shows_tabs()
		.then(|| view! { <Tabs navigation=&navigation /> });
	view! {
		<View class=theme::PAGE>
			{back}
			{body}
			{tabs}
		</View>
	}
}

#[component]
fn Tabs(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let current = navigation.current();
	let on_do = matches!(current, AppRoute::Do);
	let on_create = matches!(current, AppRoute::Create);
	let on_me = matches!(current, AppRoute::Me);
	view! {
		<View class=theme::ROW>
			<Tab
				navigation=navigation
				route=AppRoute::Do
				label=l10n.tab_do()
				selected=on_do
			/>
			<Tab
				navigation=navigation
				route=AppRoute::Create
				label=l10n.tab_create()
				selected=on_create
			/>
			<Tab navigation=navigation route=AppRoute::Me label=l10n.tab_me() selected=on_me />
		</View>
	}
}

#[component]
fn Tab(
	navigation: &Navigation,
	route: AppRoute,
	label: impl Into<String>,
	selected: bool,
) -> Element {
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
