//! Live capture, `/capture/:attempt/:requirement`.
//!
//! The frame is night paper with sketched corner brackets: no face boxes,
//! no grids, no scores. The camera surface itself arrives with the capture
//! plugin. The sensor opens only after `beginCapture` returns, through the
//! shell plugin, after `verily-attest` prepares the per-window attested key.
//! Photo, video, and audio captures stay on host storage and stream directly
//! to the server's presigned upload reservation before binding and attestation.
//! A missing plugin shows the integrity failure. It NEVER opens a gallery or
//! a file picker.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::query::MutationScope;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use leptoskit_router::Route;
use verily_ink::sketches;

use crate::chrome;
use crate::host;
use crate::host::CapturedMediaInfo;
use crate::host::HostFault;
use crate::l10n::use_l10n;
use crate::model::CaptureWindow;
use crate::model::ProofKind;
use crate::ops::BeginCapture;
use crate::ops::CompleteAttempt;
use crate::ops::ConfirmMediaUpload;
use crate::ops::IssueSpokenChallenge;
use crate::ops::RequestMediaUpload;
use crate::ops::SubmitDeviceAttestation;
use crate::ops::SubmitLocationProof;
use crate::ops::SubmitMediaProof;
use crate::ops::SubmitMotionProof;
use crate::ops::SubmitQrProof;
use crate::routes::Navigation;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;

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
	Recording,
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
	let captured = remember(&format!("{key}.media"), || None::<CapturedMediaInfo>);
	let active_window = remember(&format!("{key}.window"), || None::<CaptureWindow>);
	let qr_code = remember(&format!("{key}.qr_code"), String::new);
	let spoken = use_rpc_query({
		let attempt_id = attempt_id.clone();
		let requirement_id = requirement_id.clone();
		move || IssueSpokenChallenge {
			attempt_id: attempt_id.clone(),
			requirement_id: requirement_id.clone(),
		}
	});

	let discard_media = use_mutation(MutationScope::new(|file_id: String| async move {
		host::discard_captured_file(&file_id).await;
		Ok::<(), ()>(())
	}));

	let finish = use_mutation(
		mutation_scope::<CompleteAttempt>()
			.with_on_success(move |_| {
				if let Some(media) = captured.get() {
					discard_media.mutate(media.capture_file_id);
					captured.set(None);
				}
				phase.set(Phase::Finished);
			})
			.with_on_error(move |_| {
				phase.set(Phase::Failed);
			}),
	);

	let attempt_for_attest = attempt_id.clone();
	let attest = use_mutation(
		mutation_scope::<SubmitDeviceAttestation>()
			.with_on_success(move |args| {
				if args.data.bound {
					finish.mutate(CompleteAttempt {
						attempt_id: attempt_for_attest.clone(),
					});
				} else {
					phase.set(Phase::Failed);
				}
			})
			.with_on_error(move |_| {
				phase.set(Phase::Failed);
			}),
	);

	let attempt_for_media_submit = attempt_id.clone();
	let submit_media = use_mutation(
		mutation_scope::<SubmitMediaProof>()
			.with_on_success_async(move |args| {
				let attest = attest;
				let phase = phase;
				let active_window = active_window;
				let attempt_id = attempt_for_media_submit.clone();
				async move {
					if !args.data.stored {
						phase.set(Phase::Failed);
						return;
					}
					let stored = args.data.digest_hex.clone();
					let Some(window) = active_window.get() else {
						phase.set(Phase::Failed);
						return;
					};
					match host::attest_captured_digest(&window, &stored).await {
						Ok(bundle) => attest.mutate(SubmitDeviceAttestation {
							attempt_id,
							digest_hex: stored,
							platform: bundle.platform.to_owned(),
							payload_b64: bundle.payload_b64,
							key_id_b64: bundle.key_id_b64,
							integrity_token: bundle.integrity_token,
						}),
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

	let attempt_for_confirm = attempt_id.clone();
	let requirement_for_confirm = requirement_id.clone();
	let confirm_upload = use_mutation(
		mutation_scope::<ConfirmMediaUpload>()
			.with_on_success(move |args| {
				submit_media.mutate(SubmitMediaProof {
					attempt_id: attempt_for_confirm.clone(),
					requirement_id: requirement_for_confirm.clone(),
					reservation_id: args.data.reservation_id,
				});
			})
			.with_on_error(move |_| {
				phase.set(Phase::Failed);
			}),
	);

	let request_upload = use_mutation(
		mutation_scope::<RequestMediaUpload>()
			.with_on_success_async(move |args| {
				let confirm_upload = confirm_upload;
				let captured = captured;
				let phase = phase;
				let plan = args.data;
				async move {
					let Some(media) = captured.get() else {
						phase.set(Phase::Failed);
						return;
					};
					match host::upload_captured_file(
						&media.capture_file_id,
						&plan.upload_url,
						&media.mime_type,
						&media.sha256_hex,
					)
					.await
					{
						Ok(version_id) => confirm_upload.mutate(ConfirmMediaUpload {
							reservation_id: plan.reservation_id,
							version_id,
							expected_sha256_hex: media.sha256_hex,
						}),
						Err(HostFault::PluginMissing) => phase.set(Phase::PluginMissing),
						Err(HostFault::Rejected) => phase.set(Phase::Failed),
					}
				}
			})
			.with_on_error(move |_| {
				phase.set(Phase::Failed);
			}),
	);

	let stop_rec = use_mutation(
		MutationScope::new(
			|window: CaptureWindow| async move { host::stop_recording(&window).await },
		)
		.with_on_success(move |args| {
			captured.set(Some(args.data));
			phase.set(Phase::Review);
		})
		.with_on_error(move |args| match args.error {
			HostFault::PluginMissing => phase.set(Phase::PluginMissing),
			HostFault::Rejected => phase.set(Phase::Failed),
		}),
	);

	let attempt_for_qr = attempt_id.clone();
	let submit_qr = use_mutation(
		mutation_scope::<SubmitQrProof>()
			.with_on_success(move |args| {
				if args.data.stored {
					finish.mutate(CompleteAttempt {
						attempt_id: attempt_for_qr.clone(),
					});
				} else {
					phase.set(Phase::Failed);
				}
			})
			.with_on_error(move |_| {
				phase.set(Phase::Failed);
			}),
	);

	let attempt_for_motion = attempt_id.clone();
	let submit_motion = use_mutation(
		mutation_scope::<SubmitMotionProof>()
			.with_on_success(move |args| {
				if args.data.stored {
					finish.mutate(CompleteAttempt {
						attempt_id: attempt_for_motion.clone(),
					});
				} else {
					phase.set(Phase::Failed);
				}
			})
			.with_on_error(move |_| {
				phase.set(Phase::Failed);
			}),
	);

	let attempt_for_location = attempt_id.clone();
	let submit_location = use_mutation(
		mutation_scope::<SubmitLocationProof>()
			.with_on_success(move |args| {
				if args.data.stored {
					finish.mutate(CompleteAttempt {
						attempt_id: attempt_for_location.clone(),
					});
				} else {
					phase.set(Phase::Failed);
				}
			})
			.with_on_error(move |_| {
				phase.set(Phase::Failed);
			}),
	);

	let attempt_for_begin = attempt_id.clone();
	let requirement_for_begin = requirement_id.clone();
	let begin = use_mutation(
		mutation_scope::<BeginCapture>()
			.with_on_success_async(move |args| {
				let phase = phase;
				let captured = captured;
				let active_window = active_window;
				let submit_qr = submit_qr;
				let submit_motion = submit_motion;
				let submit_location = submit_location;
				let window = args.data;
				async move {
					active_window.set(Some(window.clone()));
					match window.kind {
						ProofKind::VenueCode => match host::scan_venue_qr(&window).await {
							Ok(code) => {
								submit_qr.mutate(SubmitQrProof {
									attempt_id: window.attempt_id,
									requirement_id: window.requirement_id,
									code,
								});
							}
							Err(HostFault::PluginMissing) | Err(HostFault::Rejected) => {
								phase.set(Phase::PluginMissing);
							}
						},
						ProofKind::Movement => {
							match host::capture_motion_trace(&window, 10_000).await {
								Ok(trace_json) => {
									submit_motion.mutate(SubmitMotionProof {
										attempt_id: window.attempt_id,
										requirement_id: window.requirement_id,
										trace_json,
									});
								}
								Err(HostFault::PluginMissing) | Err(HostFault::Rejected) => {
									phase.set(Phase::PluginMissing);
								}
							}
						}
						ProofKind::Presence => match host::capture_location_fix(&window).await {
							Ok(fix) => {
								submit_location.mutate(SubmitLocationProof {
									attempt_id: window.attempt_id,
									requirement_id: window.requirement_id,
									latitude: fix.latitude,
									longitude: fix.longitude,
									accuracy_meters: fix.accuracy_meters,
									captured_at_ms: fix.captured_at_ms,
									is_mock: fix.is_mock,
								});
							}
							Err(HostFault::PluginMissing) => phase.set(Phase::PluginMissing),
							Err(HostFault::Rejected) => phase.set(Phase::Failed),
						},
						ProofKind::Video | ProofKind::Audio => {
							match host::start_recording(&window).await {
								Ok(()) => phase.set(Phase::Recording),
								Err(HostFault::PluginMissing) => phase.set(Phase::PluginMissing),
								Err(HostFault::Rejected) => phase.set(Phase::Failed),
							}
						}
						ProofKind::Photo => match host::capture_photo(&window).await {
							Ok(media) => {
								captured.set(Some(media));
								phase.set(Phase::Review);
							}
							Err(HostFault::PluginMissing) => phase.set(Phase::PluginMissing),
							Err(HostFault::Rejected) => phase.set(Phase::Failed),
						},
						ProofKind::Note | ProofKind::App => phase.set(Phase::Failed),
					}
				}
			})
			.with_on_error(move |_| {
				phase.set(Phase::Failed);
			}),
	);

	let live = l10n.capture_live();
	let is_venue_code = active_window
		.get()
		.is_some_and(|w| w.kind == ProofKind::VenueCode);
	let qr_attempt = attempt_id.clone();
	let qr_requirement = requirement_id.clone();

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
				move || is_venue_code,
				move || {
					let attempt_id = qr_attempt.clone();
					let requirement_id = qr_requirement.clone();
					view! {
						<chrome::Card seed=811>
							<chrome::Title text=l10n.action_scan_title() />
							<chrome::Muted text=l10n.action_scan_hint() />
							<chrome::Field
								label=l10n.venue_code_title()
								value=qr_code.get()
								on_change=move |next| qr_code.set(next.trim().to_owned())
								seed=813
							/>
							<chrome::Quiet
								label=l10n.capture_review_send()
								disabled=submit_qr.is_pending() || qr_code.get().is_empty()
								on_press=move || {
									phase.set(Phase::Working);
									submit_qr.mutate(SubmitQrProof {
										attempt_id: attempt_id.clone(),
										requirement_id: requirement_id.clone(),
										code: qr_code.get(),
									});
								}
								seed=815
							/>
						</chrome::Card>
					}
				},
			)}
			{Show(
				move || phase.get() == Phase::Recording,
				move || {
					view! {
						<chrome::Primary
							label=l10n.capture_record_stop()
							disabled=stop_rec.is_pending()
							on_press=move || {
								if let Some(window) = active_window.get() {
									phase.set(Phase::Working);
									stop_rec.mutate(window);
								}
							}
							seed=817
						/>
					}
				},
			)}
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
					let duration_note = captured.get().and_then(|media| {
						(media.duration_ms > 0)
							.then(|| l10n.capture_review_duration(i64::from(media.duration_ms.div_ceil(1000))))
					});
					view! {
						<View class=theme::STACK>
							<chrome::Muted text=l10n.capture_review_preview_unavailable() />
							{duration_note.map(|text| view! { <chrome::Muted text=text /> })}
							<chrome::Primary
								label=l10n.capture_review_send()
								disabled=request_upload.is_pending()
									|| confirm_upload.is_pending()
									|| submit_media.is_pending()
								on_press=move || {
									if let Some(media) = captured.get() {
										let byte_length =
											i64::try_from(media.byte_length).unwrap_or(i64::MAX);
										phase.set(Phase::Working);
										request_upload.mutate(RequestMediaUpload {
											attempt_id: attempt_id.clone(),
											requirement_id: requirement_id.clone(),
											mime_type: media.mime_type,
											byte_length,
										});
									}
								}
								seed=803
							/>
							<chrome::Quiet
								label=l10n.capture_review_retake()
								on_press=move || {
									if let Some(media) = captured.get() {
										discard_media.mutate(media.capture_file_id);
									}
									captured.set(None);
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
				move || {
					!matches!(
						phase.get(),
						Phase::Recording | Phase::Review | Phase::Finished
					)
				},
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
