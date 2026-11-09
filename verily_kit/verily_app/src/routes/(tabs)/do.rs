//! The catalogue, `/do`.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Get;
use leptoskit::prelude::RwSignal;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::draw;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::ActionCard;
use crate::model::ActionFilter;
use crate::ops::ListAvailableActions;
use crate::routes::Action;
use crate::routes::Navigation;
use crate::state::remember;
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
		<View class="flex flex-col gap-6">
			<View class=theme::STACK.as_str()>
				<chrome::Display text=l10n.do_title() />
				<chrome::Body text=l10n.do_subtitle() />
			</View>
			<Filters filter=filter />
			{Show(
				move || actions.is_loading(),
				move || view! { <chrome::Muted text=l10n.do_loading() /> },
			)}
			{Show(
				move || actions.is_error(),
				move || {
					view! {
						<chrome::Card seed=21>
							<chrome::Title text=l10n.do_load_failed_title() />
							<chrome::Quiet
								label=l10n.dialog_retry()
								on_press=move || {
									actions.refetch();
								}
							/>
						</chrome::Card>
					}
				},
			)}
			{Show(
				move || actions.data().is_some_and(|rows| rows.is_empty()),
				move || {
					view! {
						<chrome::Empty
							picture=draw::place_map(23)
							title=l10n.do_empty_title()
							body=l10n.do_empty_body()
						/>
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
	let choices = [
		(ActionFilter::All, l10n.do_filter_all()),
		(ActionFilter::Nearby, l10n.do_filter_nearby()),
		(ActionFilter::Place, l10n.do_filter_place()),
		(ActionFilter::Movement, l10n.do_filter_movement()),
		(ActionFilter::VenueCode, l10n.do_filter_venue_code()),
		(ActionFilter::Apps, l10n.do_filter_apps()),
	];
	let chosen = filter.get();
	let buttons = choices
		.into_iter()
		.enumerate()
		.map(|(index, (value, label))| {
			let selected = chosen == value;
			view! {
				<chrome::Choice
					label=label
					selected=selected
					seed=31 + index as i64 * 2
					on_press=move || filter.set(value.clone())
				/>
			}
		})
		.collect::<Vec<_>>();
	view! { <View class=theme::ROW.as_str()>{buttons}</View> }
}

/// Stable per-card seeds, so a card wobbles the same way on every rebuild.
fn seed_for(id: &str) -> i64 {
	id.bytes()
		.fold(17_i64, |seed, byte| {
			seed.wrapping_mul(31).wrapping_add(i64::from(byte))
		})
		.rem_euclid(10_000)
}

#[component]
fn CatalogueCard(navigation: Navigation, card: ActionCard) -> Element {
	let l10n = use_l10n();
	let id = card.id.clone();
	let seed = seed_for(&card.id);
	let radius = if card.radius_meters > 0 {
		l10n.action_place_radius(card.radius_meters)
	} else {
		l10n.do_map_empty_title().to_owned()
	};
	let creator = l10n.do_creator_by(&card.creator);
	let reward = (!card.reward_label.is_empty()).then(|| {
		let label = l10n.reward_in_escrow(&card.reward_label);
		view! { <chrome::RewardChip label=label seed=seed + 5 /> }
	});
	view! {
		<chrome::Card seed=seed>
			<chrome::Title text=card.title />
			<chrome::Muted text=creator />
			<View class=theme::ROW.as_str()>
				<chrome::PlaceChip name=card.place_name detail=radius seed=seed + 3 />
				{reward}
			</View>
			<chrome::Primary
				label=l10n.action_start()
				seed=seed + 7
				on_press=move || {
					navigation.navigate(Action { action: id.clone() });
				}
			/>
		</chrome::Card>
	}
}
