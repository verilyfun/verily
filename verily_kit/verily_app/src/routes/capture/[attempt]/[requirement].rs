//! Live capture, `/capture/:attempt/:requirement`.
//!
//! The frame is a `Vector` drawing: this rev has no viewfinder widget, and a
//! camera surface belongs in LeptosKit. The sensor opens only after
//! `beginCapture` returns, through the shell plugin. A missing plugin shows
//! the integrity failure. It does not open a gallery or a file picker.

use leptoskit::component;
use leptoskit::prelude::Button;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::PathData;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::Stroke;
use leptoskit::prelude::Vector;
use leptoskit::prelude::VectorPath;
use leptoskit::prelude::View;
use leptoskit::prelude::ViewBox;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;

use crate::chrome;
use crate::host;
use crate::host::HostFault;
use crate::l10n::use_l10n;
use crate::state::remember;
use crate::ops::BeginCapture;
use crate::ops::CompleteAttempt;
use crate::ops::IssueSpokenChallenge;
use crate::ops::SubmitAttestation;
use crate::ops::SubmitLiveProof;
use leptoskit_router::Route;

use crate::routes::Navigation;
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
	view! {
		<View class="flex flex-col gap-4">
			<chrome::Title text=l10n.capture_review_title() />
			<Viewfinder label=live />
			{Show(
				move || spoken.data().is_some(),
				move || {
					let word = spoken.data().map(|item| item.word).unwrap_or_default();
					let said = l10n.capture_challenge_say(&word);
					view! { <chrome::Title text=said /> }
				},
			)}
			<chrome::Muted text=l10n.capture_challenge_intro() />
			{Show(
				move || phase.get() == Phase::PluginMissing,
				move || {
					view! {
						<View class=theme::CARD>
							<chrome::Title text=l10n.capture_integrity_title() />
							<chrome::Muted text=l10n.capture_integrity_body() />
						</View>
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
						<View class="flex flex-col gap-2">
							<chrome::Muted text=l10n.capture_review_preview_unavailable() />
							<Button
								class=theme::PRIMARY
								on:press=move || {
									phase.set(Phase::Working);
									submit.mutate(SubmitLiveProof {
										attempt_id: attempt_id.clone(),
										requirement_id: requirement_id.clone(),
										digest_hex: digest.get(),
									});
								}
							>
								{l10n.capture_review_send()}
							</Button>
							<Button
								class=theme::QUIET
								on:press=move || {
									digest.set(String::new());
									phase.set(Phase::Ready);
								}
							>
								{l10n.capture_review_retake()}
							</Button>
						</View>
					}
				}
			})}
			{Show(
				move || phase.get() == Phase::Finished,
				move || {
					view! {
						<View class=theme::CARD>
							<chrome::Title text=l10n.action_verified_title() />
							<chrome::Muted text=l10n.action_verified_body() />
						</View>
					}
				},
			)}
			<Button
				class=theme::PRIMARY
				enabled={!begin.is_pending()}
				on:press=move || {
					phase.set(Phase::Working);
					begin.mutate(BeginCapture {
						attempt_id: attempt_for_begin.clone(),
						requirement_id: requirement_for_begin.clone(),
					});
				}
			>
				{l10n.capture_record_start()}
			</Button>
		</View>
	}
}

/// Hatched frame. It describes the capture area. It is not a camera image.
#[component]
fn Viewfinder(label: impl Into<String>) -> Element {
	let label = label.into();
	let ink = theme::stamp_on_night();
	let frame = ViewBox::new(0.0, 0.0, 120.0, 120.0).expect("viewfinder box");
	let border = VectorPath::new(PathData::parse("M16 16 H104 V104 H16 Z").expect("frame"))
		.stroke(Stroke::new(ink, 2.0).expect("stroke").round());
	let hatch = VectorPath::new(
		PathData::parse("M28 92 L92 28 M40 92 L92 40 M28 80 L80 28").expect("hatch"),
	)
	.stroke(Stroke::new(ink, 1.0).expect("stroke"));
	view! {
		<View class=theme::FINDER>
			<Vector
				view_box=frame
				class="absolute inset-0"
				aria_label=label
				path=border
				path=hatch
			/>
		</View>
	}
}
