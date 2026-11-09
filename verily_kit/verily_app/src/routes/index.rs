//! The front door, `/`: the mark, one promise, and what an action is made of.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::view;
use verily_ink::sketches;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::routes::Navigation;
use crate::routes::Route;
use crate::theme;

/// The welcome page.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let start = navigation.clone();
	let returning = navigation.clone();
	view! {
		<chrome::Page>
			<View class="flex flex-row items-center gap-3">
				{verily_ink::mark(48.0, Some("Verily"))}
				<Text class=format!("{} {}", theme::HEADLINE, theme::ink())>"Verily"</Text>
			</View>
			<chrome::Display text=l10n.welcome_title() />
			<chrome::Body text=l10n.welcome_body() />
			<View class="items-center">{sketches::place_map(11)}</View>
			<chrome::Title text=l10n.welcome_promise_heading() />
			<Promise
				number=1
				title=l10n.welcome_promise_place_title()
				body=l10n.welcome_promise_place_body()
			/>
			<Promise
				number=2
				title=l10n.welcome_promise_proof_title()
				body=l10n.welcome_promise_proof_body()
			/>
			<Promise
				number=3
				title=l10n.welcome_promise_reward_title()
				body=l10n.welcome_promise_reward_body()
			/>
			<chrome::Primary
				label=l10n.welcome_get_started()
				on_press=move || start.replace(Route::Do)
				seed=21
			/>
			<chrome::Quiet
				label=l10n.welcome_have_account()
				on_press=move || returning.replace(Route::Do)
				seed=23
			/>
		</chrome::Page>
	}
}

/// One part of every action, with its number circled by hand.
#[component]
fn Promise(number: usize, title: impl Into<String>, body: impl Into<String>) -> Element {
	view! {
		<View class="flex flex-row items-start gap-4">
			{sketches::step_number(number, 80 + number as i64)}
			<View class="flex flex-col flex-1 gap-1">
				<chrome::Title text=title.into() />
				<chrome::Muted text=body.into() />
			</View>
		</View>
	}
}
