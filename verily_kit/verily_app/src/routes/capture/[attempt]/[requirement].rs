//! Live capture, `/capture/:attempt/:requirement`.
//!
//! The viewfinder is night paper with sketched corner brackets, a "Live"
//! label, and the spoken challenge in a speech bubble: no face boxes, no
//! grids, no scores. The sensor opens only after `beginCapture` returns,
//! through the shell plugin. A missing plugin shows the integrity failure.
//! It does not open a gallery or a file picker.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use leptoskit_router::Route;
use verily_ink::draw;

use crate::chrome;
use crate::host;
use crate::host::HostFault;
use crate::l10n::use_l10n;
use crate::ops::BeginCapture;
use crate::ops::CompleteAttempt;
use crate::ops::IssueSpokenChallenge;
use crate::ops::SubmitAttestation;
use crate::ops::SubmitLiveProof;
use crate::routes::Navigation;
use crate::state::remember;
use crate::theme;

#[derive(Route, Clone, Debug, PartialEq)]
pub struct Capture {
	pub attempt: String,
	pub requirement: String,
}

/// What the capture screen is waiting on.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Phase {
	Ready,
	Working,
	Review,
	PluginMissing,
	Failed,
	Finished,
}

/// The capture screen for one requirement.
#[component]
pub fn Page(route: &Capture, navigation: &Navigation) -> Element {
	let _ = navigation;
	let l10n = use_l10n();
	let attempt_id = route.attempt.clone();
	let requirement_id = route.requirement.clone();
	let key = format!("capture.{attempt_id}.{requirement_id}");
	let phase = remember(&format!("{key}.phase"), || Phase::Ready);
	let digest = remember(&format!("{key}.digest"), String::new);
	let spoken = use_rpc_query({
		let attempt_id = attempt_id.clone();
		let requirement_id = requirement_id.clone();
		move || IssueSpokenChallenge {
			attempt_id: attempt_id.clone(),
			requirement_id: requirement_id.clone(),
		}
	});

	let finish = use_mutation(
		mutation_scope::<CompleteAttempt>().with_on_success(move |_| {
			phase.set(Phase::Finished);
		}),
	);
	let attempt_for_attest = attempt_id.clone();
	let attest = use_mutation(
		mutation_scope::<SubmitAttestation>().with_on_success(move |args| {
			if args.data.bound {
				finish.mutate(CompleteAttempt {
					attempt_id: attempt_for_attest.clone(),
				});
			} else {
				phase.set(Phase::Failed);
			}
		}),
	);

	let attempt_for_submit = attempt_id.clone();
	let submit = use_mutation(mutation_scope::<SubmitLiveProof>().with_on_success_async(
		move |args| {
			let attest = attest;
			let phase = phase;
			let attempt_id = attempt_for_submit.clone();
			async move {
				if !args.data.stored {
					phase.set(Phase::Failed);
					return;
				}
				let stored = args.data.digest_hex.clone();
				match host::attest(&stored).await {
					Ok(()) => attest.mutate(SubmitAttestation {
						attempt_id,
						digest_hex: stored,
					}),
					Err(HostFault::PluginMissing) | Err(HostFault::Rejected) => {
						phase.set(Phase::PluginMissing);
					}
				}
			}
		},
	));

	let attempt_for_begin = attempt_id.clone();
	let requirement_for_begin = requirement_id.clone();
	let begin = use_mutation(
		mutation_scope::<BeginCapture>()
			.with_on_success_async(move |args| {
				let phase = phase;
				let digest = digest;
				async move {
					match host::open_live(&args.data).await {
						Ok(proof) => {
							digest.set(proof.digest_hex);
							phase.set(Phase::Review);
						}
						Err(HostFault::PluginMissing) | Err(HostFault::Rejected) => {
							phase.set(Phase::PluginMissing);
						}
					}
				}
			})
			.with_on_error(move |_| {
				phase.set(Phase::Failed);
			}),
	);

	let live = l10n.capture_live();
	let word = move || spoken.data().map(|item| item.word);
	view! {
		<View class="flex flex-col gap-6">
			<chrome::Display text=l10n.capture_review_title() />
			<Viewfinder label=live word=word().map(|word| l10n.capture_challenge_say(&word)) />
			<chrome::Muted text=l10n.capture_challenge_intro() />
			{Show(
				move || phase.get() == Phase::PluginMissing,
				move || {
					view! {
						<chrome::Card seed=71>
							<chrome::Title text=l10n.capture_integrity_title() />
							<chrome::Muted text=l10n.capture_integrity_body() />
						</chrome::Card>
					}
				},
			)}
			{Show(
				move || phase.get() == Phase::Failed,
				move || {
					view! {
						<chrome::Card seed=73>
							<chrome::Title text=l10n.capture_problem_title() />
						</chrome::Card>
					}
				},
			)}
			{Show(move || phase.get() == Phase::Review, {
				let attempt_id = attempt_id.clone();
				let requirement_id = requirement_id.clone();
				move || {
					let attempt_id = attempt_id.clone();
					let requirement_id = requirement_id.clone();
					view! {
						<View class=theme::STACK.as_str()>
							<chrome::Muted text=l10n.capture_review_preview_unavailable() />
							<chrome::Primary
								label=l10n.capture_review_send()
								seed=75
								on_press=move || {
									phase.set(Phase::Working);
									submit.mutate(SubmitLiveProof {
										attempt_id: attempt_id.clone(),
										requirement_id: requirement_id.clone(),
										digest_hex: digest.get(),
									});
								}
							/>
							<chrome::Quiet
								label=l10n.capture_review_retake()
								seed=77
								on_press=move || {
									digest.set(String::new());
									phase.set(Phase::Ready);
								}
							/>
						</View>
					}
				}
			})}
			{Show(
				move || phase.get() == Phase::Finished,
				move || {
					view! {
						<View class="flex flex-col items-center gap-3">
							{draw::stamp(132.0, 79)}
							<chrome::Title text=l10n.action_verified_title() />
							<chrome::Muted text=l10n.action_verified_body() />
						</View>
					}
				},
			)}
			{Show(
				move || matches!(phase.get(), Phase::Ready | Phase::Working),
				move || {
					let attempt_id = attempt_for_begin.clone();
					let requirement_id = requirement_for_begin.clone();
					let working = phase.get() == Phase::Working;
					view! {
						<chrome::Primary
							label=l10n.capture_record_start()
							disabled=working
							seed=81
							on_press=move || {
								phase.set(Phase::Working);
								begin.mutate(BeginCapture {
									attempt_id: attempt_id.clone(),
									requirement_id: requirement_id.clone(),
								});
							}
						/>
					}
				},
			)}
		</View>
	}
}

/// The night page with corner brackets, the "Live" label, and the spoken
/// challenge. It frames the capture; it is not a camera image.
#[component]
fn Viewfinder(label: impl Into<String>, word: Option<String>) -> Element {
	let label = label.into();
	let challenge = word.map(|said| {
		view! {
			<View class="absolute left-6 bottom-6 w-[220px] h-[84px]">
				{draw::bubble(220.0, 84.0, 85)}
				<View class="absolute left-4 top-3 right-4">
					<Text class=theme::HUD_WORD.as_str()>{said}</Text>
				</View>
			</View>
		}
	});
	view! {
		<View class=theme::FINDER.as_str() aria_label=label.clone()>
			{draw::viewfinder(340.0, 288.0, 83)}
			<View class="absolute left-6 top-6 flex flex-row items-center gap-2">
				<View class=theme::HUD_DOT.as_str() />
				<Text class=theme::HUD.as_str()>{label}</Text>
			</View>
			{challenge}
		</View>
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn the_viewfinder_builds_with_and_without_a_challenge() {
		let quiet = view! { <Viewfinder label="Live" word=None /> };
		let spoken = view! { <Viewfinder label="Live" word=Some("Say “pelican”".to_owned()) /> };
		assert!(spoken.children.len() > quiet.children.len());
	}
}
