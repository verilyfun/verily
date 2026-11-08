//! The page frame: a back control on nested screens, and tabs on Do, Create, and Me.

use leptoskit::prelude::Button;
use leptoskit::prelude::Element;
use leptoskit::prelude::Show;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;

use crate::l10n::use_l10n;
use crate::route::AppRoute;
use crate::route::Navigation;
use crate::screens;
use crate::theme;

/// The shell mounts this once, inside a reactive owner, after [`crate::app`]
/// has provided translations and the query client.
pub fn shell(navigation: Navigation) -> Element {
	let watch = navigation.clone();
	let build = navigation.clone();
	Show(
		move || {
			let _ = watch.current();
			true
		},
		move || frame(build.clone()),
	)
}

fn frame(navigation: Navigation) -> Element {
	let l10n = use_l10n();
	let route = navigation.current();
	let body = match &route {
		AppRoute::Do => screens::browse(&navigation),
		AppRoute::Action(page) => screens::action(&navigation, page),
		AppRoute::Capture(page) => screens::capture(&navigation, page),
		AppRoute::Create => screens::create_hub(&navigation),
		AppRoute::Editor(page) => screens::editor(&navigation, page),
		AppRoute::Me => screens::me(&navigation),
		AppRoute::Review => screens::review(&navigation),
		AppRoute::Settings => screens::settings(&navigation),
	};
	let mut page = View().class(theme::PAGE);
	if !route.shows_tabs() {
		let back = navigation.clone();
		page = page.child(
			Button(l10n.action_back().to_owned())
				.class(theme::QUIET)
				.on_press(move || {
					back.back();
				}),
		);
	}
	page = page.child(body);
	if route.shows_tabs() {
		page = page.child(tabs(&navigation));
	}
	page
}

fn tabs(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let current = navigation.current();
	View()
		.class(theme::ROW)
		.child(tab(
			navigation,
			AppRoute::Do,
			l10n.tab_do(),
			matches!(current, AppRoute::Do),
		))
		.child(tab(
			navigation,
			AppRoute::Create,
			l10n.tab_create(),
			matches!(current, AppRoute::Create),
		))
		.child(tab(
			navigation,
			AppRoute::Me,
			l10n.tab_me(),
			matches!(current, AppRoute::Me),
		))
}

fn tab(navigation: &Navigation, route: AppRoute, label: &str, selected: bool) -> Element {
	let navigation = navigation.clone();
	let class = if selected {
		theme::PRIMARY
	} else {
		theme::QUIET
	};
	Button(label.to_owned())
		.class(class)
		.on_press(move || navigation.navigate(route.clone()))
}

/// A section title.
pub fn title(text: impl Into<String>) -> Element {
	Text(text.into()).class(theme::TITLE)
}

/// Secondary copy.
pub fn muted(text: impl Into<String>) -> Element {
	Text(text.into()).class(theme::MUTED)
}
