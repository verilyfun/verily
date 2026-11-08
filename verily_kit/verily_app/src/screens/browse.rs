//! Do: the catalogue, and one action's place, proof, and reward.

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
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::ActionCard;
use crate::model::ActionFilter;
use crate::model::ProofKind;
use crate::ops::BeginAttempt;
use crate::ops::GetAction;
use crate::ops::ListAvailableActions;
use crate::route::ActionPage;
use crate::route::CapturePage;
use crate::route::Navigation;
use crate::theme;

/// The catalogue.
#[component]
pub fn Browse(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let filter = RwSignal::new(ActionFilter::all());
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
					navigation.navigate(ActionPage { action: id.clone() });
				}
			>
				{l10n.action_start()}
			</Button>
		</View>
	}
}

/// One action: place, proof list, reward, and the start of an attempt.
#[component]
pub fn ActionScreen(navigation: &Navigation, page: &crate::route::ActionPage) -> Element {
	let l10n = use_l10n();
	let action_id = page.action.clone();
	let detail = use_rpc_query(move || GetAction {
		action_id: action_id.clone(),
	});
	let navigation = navigation.clone();
	let begin = use_mutation(
		mutation_scope::<BeginAttempt>().with_on_success(move |args| {
			navigation.navigate(CapturePage {
				attempt: args.data.attempt_id,
				requirement: args.data.requirement_id,
			});
		}),
	);
	view! {
		<View class="flex flex-col gap-4">
			{Show(
				move || detail.is_loading(),
				move || view! { <chrome::Muted text=l10n.action_loading() /> },
			)}
			{Show(
				move || detail.is_error(),
				move || view! { <chrome::Title text=l10n.action_load_failed_title() /> },
			)}
			{Show(
				move || detail.data().is_none() && !detail.is_loading() && !detail.is_error(),
				move || view! { <chrome::Title text=l10n.action_not_found_title() /> },
			)}
			{For(
				move || detail.data().into_iter().collect::<Vec<_>>(),
				|item: &crate::model::ActionDetail| item.id.clone(),
				move |item| {
					let l10n = use_l10n();
					let id = item.id.clone();
					let proofs = item.proofs.clone();
					let creator = l10n.do_creator_by(&item.creator);
					view! {
						<View class="flex flex-col gap-4">
							<chrome::Title text=item.title.clone() />
							<chrome::Muted text=item.summary.clone() />
							<chrome::Muted text=creator />
							<PlaceCard name=item.place_name.clone() radius_meters=item.radius_meters />
							<chrome::Title text=l10n.action_proof_heading() />
							<chrome::Muted text=l10n.action_proof_intro() />
							{For(
								move || proofs.clone(),
								|proof: &crate::model::ProofNeed| proof.id.clone(),
								|proof| view! { <ProofRow proof=proof /> },
							)}
							<RewardCard label=item.reward_label.clone() funded=item.funded />
							<Button
								class=theme::PRIMARY
								enabled={!begin.is_pending()}
								on:press=move || {
									begin.mutate(BeginAttempt {
										action_id: id.clone(),
									});
								}
							>
								{l10n.action_start()}
							</Button>
						</View>
					}
				},
			)}
		</View>
	}
}

#[component]
fn PlaceCard(name: impl Into<String>, radius_meters: i64) -> Element {
	let l10n = use_l10n();
	let name = l10n.action_place_map_label(&name.into());
	let radius = if radius_meters > 0 {
		l10n.action_place_radius(radius_meters)
	} else {
		l10n.editor_place_tap_hint().to_owned()
	};
	view! {
		<View class=theme::PLACE>
			<Text class="font-semibold">{name}</Text>
			<chrome::Muted text=radius />
		</View>
	}
}

#[component]
fn ProofRow(proof: crate::model::ProofNeed) -> Element {
	let l10n = use_l10n();
	let kind = match proof.kind {
		ProofKind::Photo => l10n.do_proof_photo(),
		ProofKind::Video => l10n.do_proof_video(),
		ProofKind::Audio => l10n.do_proof_audio(),
		ProofKind::Note => l10n.editor_proof_instructions_label(),
		ProofKind::Presence => l10n.do_proof_place(),
		ProofKind::Movement => l10n.do_proof_movement(),
		ProofKind::VenueCode => l10n.do_proof_venue_code(),
		ProofKind::App => l10n.do_proof_app(),
	};
	view! {
		<View class=theme::CARD>
			<Text class="font-semibold">{proof.title}</Text>
			<chrome::Muted text=kind />
		</View>
	}
}

#[component]
fn RewardCard(label: impl Into<String>, funded: bool) -> Element {
	let l10n = use_l10n();
	let label = l10n.reward_in_escrow(&label.into());
	let funded = if funded {
		l10n.hub_reward_funded()
	} else {
		l10n.hub_reward_needs_funding()
	};
	view! {
		<View class=theme::REWARD>
			<Text class="font-semibold">{l10n.editor_reward_heading()}</Text>
			<chrome::Muted text=label />
			<chrome::Muted text=funded />
		</View>
	}
}
