//! Do, Create, and Me: the three roots, under a hand-drawn tab bar.

use leptoskit::component;
use leptoskit::prelude::Children;
use leptoskit::prelude::Element;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::view;
use leptoskit_router::navigators::Tab;
use leptoskit_router::navigators::TabBar;
use leptoskit_router::navigators::Tabs;
use skribble_leptoskit::HighlightKind;
use skribble_leptoskit::WiredDivider;
use skribble_leptoskit::WiredHighlight;

use crate::l10n::use_l10n;
use crate::routes::Route;
use crate::theme;

/// The tab bar. Switching tabs replaces history, so Back never wanders into
/// another tab.
pub fn navigator() -> Tabs<Route> {
	let l10n = use_l10n();
	Tabs::new([
		Tab::root(Route::Do).title(l10n.tab_do()),
		Tab::root(Route::Create).title(l10n.tab_create()),
		Tab::root(Route::Me).title(l10n.tab_me()),
	])
	.bar(bar)
}

/// The roots fill the page; the bar sits under them.
#[component]
pub fn Layout(children: Children) -> Element {
	view! { <View class="flex flex-col flex-1">{children}</View> }
}

/// A rough rule over three written tabs. The selected one is ink, underlined
/// by hand; the others are muted.
fn bar(bar: &TabBar<'_, Route>) -> Element {
	let tabs = bar
		.items()
		.enumerate()
		.map(|(index, (tab, selected))| {
			let label = tab.label().to_owned();
			let seed = 61 + index as i64 * 2;
			let word = if selected {
				view! {
					<WiredHighlight
						kind=HighlightKind::Underline
						seed=seed
						theme=theme::PEN
						class="self-center"
					>
						<Text class=format!("{} {}", theme::LABEL, theme::ink())>{label}</Text>
					</WiredHighlight>
				}
			} else {
				view! { <Text class=format!("{} {}", theme::LABEL, theme::muted())>{label}</Text> }
			};
			bar.link(
				tab,
				view! {
					<View class="flex-1 items-center justify-center min-h-14 py-2">{word}</View>
				},
			)
			.class("flex-1")
		})
		.collect::<Vec<_>>();
	view! {
		<View class=format!("w-full {}", theme::paper())>
			<WiredDivider seed=59 theme=theme::PEN />
			<View class="flex flex-row px-2 pb-2">{tabs}</View>
		</View>
	}
}
