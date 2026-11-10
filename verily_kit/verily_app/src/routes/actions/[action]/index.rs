//! One action, `/actions/:action`: what to do, where, the proof checklist,
//! and the reward already in escrow, then the way to start.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Show;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use leptoskit_router::Route;
use verily_ink::sketches;

use crate::chrome;
use crate::chrome::Outcome;
use crate::l10n::use_l10n;
use crate::model::ActionDetail;
use crate::model::ProofKind;
use crate::model::ProofNeed;
use crate::ops::BeginAttempt;
use crate::ops::GetAction;
use crate::routes::Capture;
use crate::routes::Navigation;
use crate::theme;
use crate::theme::Role;

#[derive(Route, Clone, Debug, PartialEq)]
pub struct Action {
	pub action: String,
}

/// One action.
#[component]
pub fn Page(route: &Action, navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let action_id = route.action.clone();
	let detail = use_rpc_query(move || GetAction {
		action_id: action_id.clone(),
	});
	let navigation = navigation.clone();
	let begin = use_mutation(
		mutation_scope::<BeginAttempt>().with_on_success(move |args| {
			navigation.navigate(Capture {
				attempt: args.data.attempt_id,
				requirement: args.data.requirement_id,
			});
		}),
	);
	view! {
		<chrome::Page>
			{Show(
				move || detail.is_loading(),
				move || view! { <chrome::Loading text=l10n.action_loading() /> },
			)}
			{Show(
				move || detail.is_error(),
				move || {
					view! {
						<chrome::Failed
							title=l10n.action_load_failed_title()
							retry=l10n.dialog_retry()
							on_retry=move || {
								detail.refetch();
							}
						/>
					}
				},
			)}
			{Show(
				move || detail.data().is_none() && !detail.is_loading() && !detail.is_error(),
				move || view! { <chrome::Heading text=l10n.action_not_found_title() /> },
			)}
			{For(
				move || detail.data().into_iter().collect::<Vec<_>>(),
				|item: &ActionDetail| item.id.clone(),
				move |item| {
					let l10n = use_l10n();
					let id = item.id.clone();
					let seed = chrome::seed_for(&item.id);
					let proofs = item
						.proofs
						.iter()
						.enumerate()
						.map(|(index, proof)| {
							view! {
								<Proof proof=proof.clone() seed=seed + 20 + index as i64 * 2 />
							}
						})
						.collect::<Vec<_>>();
					view! {
						<View class="flex flex-col gap-6">
							<chrome::Heading text=item.title.clone() body=item.summary.clone() />
							<chrome::Muted text=l10n.do_creator_by(&item.creator) />
							<Place
								name=item.place_name.clone()
								radius_meters=item.radius_meters
								seed=seed
							/>
							<chrome::Card seed=seed + 11>
								<chrome::Title text=l10n.action_proof_heading() />
								<chrome::Muted text=l10n.action_proof_intro() />
								{proofs}
							</chrome::Card>
							<Reward
								label=item.reward_label.clone()
								funded=item.funded
								seed=seed + 13
							/>
							<chrome::Primary
								label=l10n.action_start()
								disabled=begin.is_pending()
								on_press=move || {
									begin.mutate(BeginAttempt {
										action_id: id.clone(),
									});
								}
								seed=seed + 17
							/>
						</View>
					}
				},
			)}
		</chrome::Page>
	}
}

/// The place: a sketched map with the pin and the hatched radius, its name,
/// and how close to be. Coordinates are never shown.
#[component]
fn Place(name: String, radius_meters: i64, seed: i64) -> Element {
	let l10n = use_l10n();
	let radius = if radius_meters > 0 {
		l10n.action_place_radius(radius_meters)
	} else {
		l10n.editor_place_tap_hint().to_owned()
	};
	let label = l10n.action_place_map_label(&name);
	let map = view! {
		<View class="items-center" aria_label=label>
			{sketches::place_map(seed)}
		</View>
	};
	view! {
		<chrome::RoleCard role=Role::Place seed=seed + 1>
			{map}
			<View class="flex flex-row items-center gap-2">
				{sketches::pin(24.0, seed + 3)}
				<Text class=format!("{} {}", theme::TITLE, theme::ink())>{name}</Text>
			</View>
			<chrome::Body text=radius />
		</chrome::RoleCard>
	}
}

/// One proof step as a checklist row.
#[component]
fn Proof(proof: ProofNeed, seed: i64) -> Element {
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
	view! { <chrome::ProofRow text=proof.title outcome=Outcome::Open detail=kind seed=seed /> }
}

/// The reward, shown before the work: the jar is full first.
#[component]
fn Reward(label: String, funded: bool, seed: i64) -> Element {
	let l10n = use_l10n();
	let status = if funded {
		l10n.hub_reward_funded()
	} else {
		l10n.hub_reward_needs_funding()
	};
	view! {
		<chrome::RoleCard role=Role::Reward seed=seed>
			<View class="flex flex-row items-center gap-4">{sketches::escrow_jar(seed + 1)}</View>
			<chrome::Title text=l10n.editor_reward_heading() />
			<chrome::Body text=l10n.reward_in_escrow(&label) />
			<chrome::Muted text=status />
		</chrome::RoleCard>
	}
}
