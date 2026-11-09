//! The catalogue, `/do`: actions to do, each with its place and reward in
//! view before anyone starts.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Get;
use leptoskit::prelude::RwSignal;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use skribble_leptoskit::FillStyle;
use skribble_leptoskit::WiredBadge;
use verily_ink::sketches;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::ActionCard;
use crate::model::ActionFilter;
use crate::ops::ListAvailableActions;
use crate::routes::Action;
use crate::routes::Navigation;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;

/// The catalogue.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let filter = remember("do.filter", ActionFilter::all);
	let actions = use_rpc_query(move || ListAvailableActions {
		filter: filter.get(),
		latitude: None,
		longitude: None,
	});
	let navigation = navigation.clone();
	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.do_title() body=l10n.do_subtitle() />
			<Filters filter=filter />
			{Show(
				move || actions.is_loading(),
				move || view! { <chrome::Loading text=l10n.do_loading() /> },
			)}
			{Show(
				move || actions.is_error(),
				move || {
					view! {
						<chrome::Failed
							title=l10n.do_load_failed_title()
							retry=l10n.dialog_retry()
							on_retry=move || {
								actions.refetch();
							}
						/>
					}
				},
			)}
			{Show(
				move || actions.data().is_some_and(|rows| rows.is_empty()),
				move || {
					view! {
						<chrome::Empty
							title=l10n.do_empty_title()
							body=l10n.do_empty_body()
							picture=sketches::arrow_up(96.0, 84.0, 31)
						/>
					}
				},
			)}
			<View class=theme::STACK>
				{For(
					move || actions.data().unwrap_or_default(),
					|card: &ActionCard| card.id.clone(),
					move |card| view! { <CatalogueCard navigation=navigation.clone() card=card /> },
				)}
			</View>
		</chrome::Page>
	}
}

#[component]
fn Filters(filter: RwSignal<ActionFilter>) -> Element {
	let l10n = use_l10n();
	let chips = [
		(ActionFilter::All, l10n.do_filter_all()),
		(ActionFilter::Nearby, l10n.do_filter_nearby()),
		(ActionFilter::Place, l10n.do_filter_place()),
		(ActionFilter::Movement, l10n.do_filter_movement()),
		(ActionFilter::VenueCode, l10n.do_filter_venue_code()),
		(ActionFilter::Apps, l10n.do_filter_apps()),
	]
	.into_iter()
	.enumerate()
	.map(|(index, (value, label))| {
		view! { <FilterChip filter=filter value=value label=label seed=101 + index as i64 /> }
	})
	.collect::<Vec<_>>();
	view! { <View class=theme::ROW>{chips}</View> }
}

/// A filter as a hand-drawn capsule: ink-filled when chosen.
#[component]
fn FilterChip(
	filter: RwSignal<ActionFilter>,
	value: ActionFilter,
	label: impl Into<String>,
	seed: i64,
) -> Element {
	let selected = filter.get() == value;
	let label = label.into();
	let (fill_style, text) = if selected {
		(
			FillStyle::Solid,
			verily_ink::tone_class("text", verily_ink::PAPER),
		)
	} else {
		(FillStyle::None, theme::ink())
	};
	let chip = view! {
		<WiredBadge seed=seed theme=theme::PEN fill_style=fill_style class=text>
			<Text class=theme::LABEL>{label.clone()}</Text>
		</WiredBadge>
	};
	leptoskit::prelude::Pressable(label)
		.class("min-h-11 justify-center")
		.on_press(move || filter.set(value.clone()))
		.child(chip)
}

/// One action: its name, where, and what it pays. The whole card opens it.
#[component]
fn CatalogueCard(navigation: Navigation, card: ActionCard) -> Element {
	let l10n = use_l10n();
	let seed = chrome::seed_for(&card.id);
	let radius = (card.radius_meters > 0).then(|| l10n.action_place_radius(card.radius_meters));
	let creator = l10n.do_creator_by(&card.creator);
	let reward = (!card.reward_label.is_empty()).then(|| {
		let label = l10n.reward_in_escrow(&card.reward_label);
		view! {
			<View class="flex flex-row items-center gap-2">
				{sketches::coin(28.0, seed + 5)}
				<chrome::Chip role=Role::Reward text=label seed=seed + 7 />
			</View>
		}
	});
	let body = view! {
		<chrome::Card seed=seed>
			<chrome::Title text=card.title.clone() />
			<chrome::Muted text=creator />
			<View class="flex flex-row items-center gap-2">
				{sketches::pin(24.0, seed + 3)}
				<Text class=format!("{} {}", theme::LABEL, theme::role_text(Role::Place))>
					{card.place_name.clone()}
				</Text>
			</View>
			{radius.map(|radius| view! { <chrome::Muted text=radius /> })}
			{reward}
		</chrome::Card>
	};
	navigation
		.link(
			Action {
				action: card.id.clone(),
			},
			card.title,
		)
		.child(body)
}
