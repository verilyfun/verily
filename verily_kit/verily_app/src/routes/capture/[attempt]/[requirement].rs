//! Live capture, `/capture/:attempt/:requirement`.
//!
//! The frame is night paper with sketched corner brackets: no face boxes,
//! no grids, no scores. The camera surface itself arrives with the capture
//! plugin. The sensor opens only after
//! `beginCapture` returns, through the shell plugin. A missing plugin shows
//! the integrity failure. It does not open a gallery or a file picker.

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

use crate::chrome;
use crate::host;
use crate::host::HostFault;
use crate::l10n::use_l10n;
use crate::ops::BeginCapture;
use crate::ops::CompleteAttempt;
use crate::ops::IssueSpokenChallenge;
use crate::ops::SubmitAttestation;
use crate::ops::SubmitLiveProof;
use crate::state::remember;
use leptoskit_router::Route;

use crate::routes::Navigation;
use crate::theme;
use crate::theme::Role;
use verily_ink::sketches;

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
	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.capture_review_title() body=l10n.capture_challenge_intro() />
			<View class="relative w-full h-[440px] overflow-hidden rounded-xl">
				<View class=format!(
					"absolute inset-0 {}",
					verily_ink::tone_class("bg", verily_ink::NIGHT)
				) />
				{sketches::viewfinder(328.0, 440.0, 71)}
				<View class="absolute left-4 top-4 flex flex-row items-center gap-2">
					<Text class=format!(
						"{} {}",
						theme::LABEL,
						verily_ink::tone_class("text", verily_ink::CHALK),
					)>
						{live}
					</Text>
				</View>
				{Show(
					move || spoken.data().is_some(),
					move || {
						let word = spoken.data().map(|item| item.word).unwrap_or_default();
						let said = l10n.capture_challenge_say(&word);
						view! {
							<View class="absolute left-6 bottom-8 w-[190px] h-[74px]">
								{sketches::bubble(190.0, 74.0, 73)}
								<Text class=format!(
									"absolute left-4 top-3 {} {}",
									theme::LABEL,
									verily_ink::tone_class("text", verily_ink::CHALK_INK),
								)>
									{said}
								</Text>
							</View>
						}
					},
				)}
			</View>
			{Show(
				move || phase.get() == Phase::PluginMissing,
				move || {
					view! {
						<chrome::RoleCard role=Role::Review seed=801>
							<chrome::Title text=l10n.capture_integrity_title() />
							<chrome::Body text=l10n.capture_integrity_body() />
						</chrome::RoleCard>
					}
				},
			)}
			{Show(
				move || phase.get() == Phase::Failed,
				move || view! { <chrome::Title text=l10n.capture_problem_title() /> },
			)}
			{Show(move || phase.get() == Phase::Review, {
				let attempt_id = attempt_id.clone();
				let requirement_id = requirement_id.clone();
				move || {
					let attempt_id = attempt_id.clone();
					let requirement_id = requirement_id.clone();
					view! {
						<View class=theme::STACK>
							<chrome::Muted text=l10n.capture_review_preview_unavailable() />
							<chrome::Primary
								label=l10n.capture_review_send()
								on_press=move || {
									phase.set(Phase::Working);
									submit.mutate(SubmitLiveProof {
										attempt_id: attempt_id.clone(),
										requirement_id: requirement_id.clone(),
										digest_hex: digest.get(),
									});
								}
								seed=803
							/>
							<chrome::Quiet
								label=l10n.capture_review_retake()
								on_press=move || {
									digest.set(String::new());
									phase.set(Phase::Ready);
								}
								seed=805
							/>
						</View>
					}
				}
			})}
			{Show(
				move || phase.get() == Phase::Finished,
				move || {
					view! {
						<chrome::Card seed=807>
							<View class="items-center -rotate-[8deg]">
								{sketches::slammed_stamp(132.0, 41, 0, false)}
							</View>
							<chrome::Title text=l10n.action_verified_title() />
							<chrome::Body text=l10n.action_verified_body() />
						</chrome::Card>
					}
				},
			)}
			{Show(
				move || phase.get() != Phase::Review && phase.get() != Phase::Finished,
				move || {
					let attempt_id = attempt_for_begin.clone();
					let requirement_id = requirement_for_begin.clone();
					view! {
						<chrome::Primary
							label=l10n.capture_record_start()
							disabled=begin.is_pending()
							on_press=move || {
								phase.set(Phase::Working);
								begin.mutate(BeginCapture {
									attempt_id: attempt_id.clone(),
									requirement_id: requirement_id.clone(),
								});
							}
							seed=809
						/>
					}
				},
			)}
		</chrome::Page>
	}
}
