//! The catalogue, `/do`.

use leptoskit::component;
use leptoskit::prelude::Button;
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

use crate::chrome;
use crate::l10n::use_l10n;
use crate::state::remember;
use crate::model::ActionCard;
use crate::model::ActionFilter;
use crate::ops::ListAvailableActions;
use crate::routes::Action;
use crate::routes::Navigation;
use crate::theme;

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
		<View class="flex flex-col gap-4">
			<chrome::Title text=l10n.do_title() />
			<chrome::Muted text=l10n.do_subtitle() />
			<Filters filter=filter />
			{Show(
				move || actions.is_loading(),
				move || view! { <chrome::Muted text=l10n.do_loading() /> },
			)}
			{Show(
				move || actions.is_error(),
				move || {
					let actions = actions;
					view! {
						<View class="flex flex-col gap-2">
							<chrome::Title text=l10n.do_load_failed_title() />
							<Button
								class=theme::QUIET
								on:press=move || {
									actions.refetch();
								}
							>
								{l10n.dialog_retry()}
							</Button>
						</View>
					}
				},
			)}
			{Show(
				move || actions.data().is_some_and(|rows| rows.is_empty()),
				move || {
					view! {
						<View class=theme::CARD>
							<chrome::Title text=l10n.do_empty_title() />
							<chrome::Muted text=l10n.do_empty_body() />
						</View>
					}
				},
			)}
			{For(
				move || actions.data().unwrap_or_default(),
				|card: &ActionCard| card.id.clone(),
				move |card| view! { <CatalogueCard navigation=navigation.clone() card=card /> },
			)}
		</View>
	}
}

#[component]
fn Filters(filter: RwSignal<ActionFilter>) -> Element {
	let l10n = use_l10n();
	view! {
		<View class=theme::ROW>
			<FilterButton filter=filter value=ActionFilter::All label=l10n.do_filter_all() />
			<FilterButton filter=filter value=ActionFilter::Nearby label=l10n.do_filter_nearby() />
			<FilterButton filter=filter value=ActionFilter::Place label=l10n.do_filter_place() />
			<FilterButton
				filter=filter
				value=ActionFilter::Movement
				label=l10n.do_filter_movement()
			/>
			<FilterButton
				filter=filter
				value=ActionFilter::VenueCode
				label=l10n.do_filter_venue_code()
			/>
			<FilterButton filter=filter value=ActionFilter::Apps label=l10n.do_filter_apps() />
		</View>
	}
}

#[component]
fn FilterButton(
	filter: RwSignal<ActionFilter>,
	value: ActionFilter,
	label: impl Into<String>,
) -> Element {
	let selected = filter.get() == value;
	let label = label.into();
	let class = if selected {
		theme::PRIMARY
	} else {
		theme::QUIET
	};
	view! {
		<Button class=class on:press=move || filter.set(value.clone())>{label}</Button>
	}
}

#[component]
fn CatalogueCard(navigation: Navigation, card: ActionCard) -> Element {
	let l10n = use_l10n();
	let id = card.id.clone();
	let radius = if card.radius_meters > 0 {
		l10n.action_place_radius(card.radius_meters)
	} else {
		l10n.do_map_empty_title().to_owned()
	};
	let creator = l10n.do_creator_by(&card.creator);
	view! {
		<View class=theme::CARD>
			<Text class=theme::TITLE>{card.title}</Text>
			<chrome::Muted text=creator />
			<chrome::Muted text=card.place_name />
			<chrome::Muted text=radius />
			<chrome::Muted text=card.reward_label />
			<Button
				class=theme::PRIMARY
				on:press=move || {
					navigation.navigate(Action { action: id.clone() });
				}
			>
				{l10n.action_start()}
			</Button>
		</View>
	}
}
