//! Do, Create, and Me: the three roots, under a hand-drawn tab bar.
//!
//! Switching a tab replaces history, so Back never wanders into another tab.
//! The bar is drawn here.

use leptoskit::component;
use leptoskit::prelude::Children;
use leptoskit::prelude::Element;
use leptoskit::prelude::Pressable;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::view;
use skribble_leptoskit::HighlightKind;
use skribble_leptoskit::WiredDivider;
use skribble_leptoskit::WiredHighlight;

use crate::l10n::use_l10n;
use crate::routes::Navigation;
use crate::routes::Route;
use crate::theme;

/// The roots fill the page; the bar sits under them.
#[component]
pub fn Layout(children: Children, navigation: &Navigation, route: &Route) -> Element {
	let l10n = use_l10n();
	let navigation = navigation.clone();
	let route = route.clone();
	view! {
		<View class="flex flex-col flex-1">
			<View class="flex flex-col flex-1">{children}</View>
			<View class=format!("w-full {}", theme::paper())>
				<WiredDivider seed=59 theme=theme::PEN />
				<View class="flex flex-row px-2 pb-2">
					<Tab
						navigation=navigation.clone()
						route=Route::Do
						current=route.clone()
						label=l10n.tab_do()
						seed=61
					/>
					<Tab
						navigation=navigation.clone()
						route=Route::Create
						current=route.clone()
						label=l10n.tab_create()
						seed=63
					/>
					<Tab
						navigation=navigation
						route=Route::Me
						current=route
						label=l10n.tab_me()
						seed=65
					/>
				</View>
			</View>
		</View>
	}
}

/// One written tab. The selected root is ink, underlined by hand.
#[component]
fn Tab(
	navigation: Navigation,
	route: Route,
	current: Route,
	label: impl Into<String>,
	seed: i64,
) -> Element {
	let label = label.into();
	let selected = current == route;
	let word = if selected {
		let text = label.clone();
		view! {
			<WiredHighlight
				kind=HighlightKind::Underline
				seed=seed
				theme=theme::PEN
				class="self-center"
			>
				<Text class=format!("{} {}", theme::LABEL, theme::ink())>{text}</Text>
			</WiredHighlight>
		}
	} else {
		let text = label.clone();
		view! { <Text class=format!("{} {}", theme::LABEL, theme::muted())>{text}</Text> }
	};
	view! {
		<Pressable
			accessibility_label=label
			class="flex-1 items-center justify-center min-h-14 py-2"
			on:press=move || navigation.replace(route.clone())
		>
			{word}
		</Pressable>
	}
}
