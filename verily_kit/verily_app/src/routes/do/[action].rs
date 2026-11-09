//! One action, `/do/:action`.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use leptoskit_router::Route;
use verily_ink::draw;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::ProofKind;
use crate::model::ProofNeed;
use crate::ops::BeginAttempt;
use crate::ops::GetAction;
use crate::routes::Capture;
use crate::routes::Navigation;
use crate::theme;

#[derive(Route, Clone, Debug, PartialEq)]
pub struct Action {
	pub action: String,
}

/// One action: place, proof list, reward, and the start of an attempt.
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
	// One state at a time, so no hidden placeholder takes a gap.
	if detail.is_loading() {
		return view! { <chrome::Muted text=l10n.action_loading() /> };
	}
	if detail.is_error() {
		return view! {
			<chrome::Empty
				picture=draw::place_map(41)
				title=l10n.action_load_failed_title()
				body=""
			/>
		};
	}
	let Some(item) = detail.data() else {
		return view! {
			<chrome::Empty
				picture=draw::place_map(43)
				title=l10n.action_not_found_title()
				body=""
			/>
		};
	};
	let id = item.id.clone();
	let creator = l10n.do_creator_by(&item.creator);
	let radius = if item.radius_meters > 0 {
		l10n.action_place_radius(item.radius_meters)
	} else {
		l10n.editor_place_tap_hint().to_owned()
	};
	// Only a rewarded action shows a reward: its amount once the escrow is
	// verified, or that it still needs funding.
	let reward = match (item.rewarded, item.funded) {
		(true, true) => Some(view! {
			<chrome::RewardChip label=l10n.reward_in_escrow(&item.reward_label) seed=51 />
		}),
		(true, false) => Some(view! { <chrome::Muted text=l10n.hub_reward_needs_funding() /> }),
		(false, _) => None,
	};
	let proofs = item
		.proofs
		.into_iter()
		.map(|proof| view! { <ProofLine proof=proof /> })
		.collect::<Vec<_>>();
	view! {
		<View class="flex flex-col gap-6">
			<View class=theme::STACK.as_str()>
				<chrome::Display text=item.title />
				<chrome::Muted text=creator />
				<chrome::Body text=item.summary />
			</View>
			<View class="flex flex-col items-center gap-3">
				{draw::place_map(45)}
				<chrome::PlaceChip name=item.place_name detail=radius seed=47 />
			</View>
			<chrome::Card seed=49>
				<chrome::Title text=l10n.action_proof_heading() />
				<chrome::Muted text=l10n.action_proof_intro() />
				<View class=theme::STACK.as_str()>{proofs}</View>
			</chrome::Card>
			{reward}
			<chrome::Primary
				label=l10n.action_start()
				disabled=begin.is_pending()
				seed=53
				on_press=move || {
					begin.mutate(BeginAttempt {
						action_id: id.clone(),
					});
				}
			/>
		</View>
	}
}

/// One thing the proof has to show, in plain words. Nothing is ticked yet:
/// the ticks come with the proof.
#[component]
fn ProofLine(proof: ProofNeed) -> Element {
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
	let seed = 61 + proof.id.len() as i64;
	// A requirement named for its kind ("Photo") doesn't say it twice.
	if proof.title == kind {
		view! { <chrome::ProofRow text=proof.title seed=seed /> }
	} else {
		view! { <chrome::ProofRow text=proof.title detail=kind.to_owned() seed=seed /> }
	}
}
