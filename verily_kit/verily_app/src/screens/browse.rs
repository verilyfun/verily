//! Do: the catalogue, and one action's place, proof, and reward.

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
pub fn browse(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let filter = RwSignal::new(ActionFilter::all());
	let actions = use_rpc_query(move || ListAvailableActions {
		filter: filter.get(),
		latitude: None,
		longitude: None,
	});
	let navigation = navigation.clone();
	View()
		.class("flex flex-col gap-4")
		.child(chrome::title(l10n.do_title()))
		.child(chrome::muted(l10n.do_subtitle()))
		.child(filters(filter))
		.child(Show(
			move || actions.is_loading(),
			move || chrome::muted(l10n.do_loading()),
		))
		.child(Show(
			move || actions.is_error(),
			move || {
				let actions = actions;
				View()
					.class("flex flex-col gap-2")
					.child(chrome::title(l10n.do_load_failed_title()))
					.child(
						Button(l10n.dialog_retry().to_owned())
							.class(theme::QUIET)
							.on_press(move || {
								actions.refetch();
							}),
					)
			},
		))
		.child(Show(
			move || actions.data().is_some_and(|rows| rows.is_empty()),
			move || {
				View()
					.class(theme::CARD)
					.child(chrome::title(l10n.do_empty_title()))
					.child(chrome::muted(l10n.do_empty_body()))
			},
		))
		.child(For(
			move || actions.data().unwrap_or_default(),
			|card: &ActionCard| card.id.clone(),
			move |card| card_button(navigation.clone(), card),
		))
}

fn filters(filter: RwSignal<ActionFilter>) -> Element {
	let l10n = use_l10n();
	View()
		.class(theme::ROW)
		.child(filter_button(
			filter,
			ActionFilter::All,
			l10n.do_filter_all(),
		))
		.child(filter_button(
			filter,
			ActionFilter::Nearby,
			l10n.do_filter_nearby(),
		))
		.child(filter_button(
			filter,
			ActionFilter::Place,
			l10n.do_filter_place(),
		))
		.child(filter_button(
			filter,
			ActionFilter::Movement,
			l10n.do_filter_movement(),
		))
		.child(filter_button(
			filter,
			ActionFilter::VenueCode,
			l10n.do_filter_venue_code(),
		))
		.child(filter_button(
			filter,
			ActionFilter::Apps,
			l10n.do_filter_apps(),
		))
}

fn filter_button(filter: RwSignal<ActionFilter>, value: ActionFilter, label: &str) -> Element {
	let selected = filter.get() == value;
	let class = if selected {
		theme::PRIMARY
	} else {
		theme::QUIET
	};
	Button(label.to_owned())
		.class(class)
		.on_press(move || filter.set(value.clone()))
}

fn card_button(navigation: Navigation, card: ActionCard) -> Element {
	let l10n = use_l10n();
	let id = card.id.clone();
	View()
		.class(theme::CARD)
		.child(Text(card.title).class(theme::TITLE))
		.child(chrome::muted(l10n.do_creator_by(&card.creator)))
		.child(chrome::muted(card.place_name))
		.child(chrome::muted(if card.radius_meters > 0 {
			l10n.action_place_radius(card.radius_meters)
		} else {
			l10n.do_map_empty_title().to_owned()
		}))
		.child(chrome::muted(card.reward_label))
		.child(
			Button(l10n.action_start().to_owned())
				.class(theme::PRIMARY)
				.on_press(move || {
					navigation.navigate(ActionPage { action: id.clone() });
				}),
		)
}

/// One action: place, proof list, reward, and the start of an attempt.
pub fn action(navigation: &Navigation, page: &crate::route::ActionPage) -> Element {
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
	View()
		.class("flex flex-col gap-4")
		.child(Show(
			move || detail.is_loading(),
			move || chrome::muted(l10n.action_loading()),
		))
		.child(Show(
			move || detail.is_error(),
			move || chrome::title(l10n.action_load_failed_title()),
		))
		.child(Show(
			move || detail.data().is_none() && !detail.is_loading() && !detail.is_error(),
			move || chrome::title(l10n.action_not_found_title()),
		))
		.child(For(
			move || detail.data().into_iter().collect::<Vec<_>>(),
			|item: &crate::model::ActionDetail| item.id.clone(),
			move |item| {
				let l10n = use_l10n();
				let id = item.id.clone();
				View()
					.class("flex flex-col gap-4")
					.child(chrome::title(item.title.clone()))
					.child(chrome::muted(item.summary.clone()))
					.child(chrome::muted(l10n.do_creator_by(&item.creator)))
					.child(place_card(&item.place_name, item.radius_meters))
					.child(chrome::title(l10n.action_proof_heading()))
					.child(chrome::muted(l10n.action_proof_intro()))
					.child(For(
						{
							let proofs = item.proofs.clone();
							move || proofs.clone()
						},
						|proof: &crate::model::ProofNeed| proof.id.clone(),
						|proof| proof_row(proof),
					))
					.child(reward_card(&item.reward_label, item.funded))
					.child(
						Button(l10n.action_start().to_owned())
							.class(theme::PRIMARY)
							.enabled(!begin.is_pending())
							.on_press(move || {
								begin.mutate(BeginAttempt {
									action_id: id.clone(),
								});
							}),
					)
			},
		))
}

fn place_card(name: &str, radius_meters: i64) -> Element {
	let l10n = use_l10n();
	View()
		.class(theme::PLACE)
		.child(Text(l10n.action_place_map_label(name)).class("font-semibold"))
		.child(chrome::muted(if radius_meters > 0 {
			l10n.action_place_radius(radius_meters)
		} else {
			l10n.editor_place_tap_hint().to_owned()
		}))
}

fn proof_row(proof: crate::model::ProofNeed) -> Element {
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
	View()
		.class(theme::CARD)
		.child(Text(proof.title).class("font-semibold"))
		.child(chrome::muted(kind))
}

fn reward_card(label: &str, funded: bool) -> Element {
	let l10n = use_l10n();
	View()
		.class(theme::REWARD)
		.child(Text(l10n.editor_reward_heading()).class("font-semibold"))
		.child(chrome::muted(l10n.reward_in_escrow(label)))
		.child(chrome::muted(if funded {
			l10n.hub_reward_funded()
		} else {
			l10n.hub_reward_needs_funding()
		}))
}
