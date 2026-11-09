//! Any URL no page claims.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::view;
use verily_ink::sketches;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::routes::Navigation;
use crate::routes::Route;

/// A lost page, and the way back to the catalogue.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let home = navigation.clone();
	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.action_not_found_title() />
			{sketches::place_map(701)}
			<chrome::Primary
				label=l10n.tab_do()
				on_press=move || home.replace(Route::Do)
				seed=703
			/>
		</chrome::Page>
	}
}
