//! The action editor, shared by `/actions/new` and `/actions/:action/edit`:
//! starter templates, plain-language AI draft helper, multi-proof picker,
//! place radius + optional coordinates, reward escrow funding, pause/resume,
//! and rotating venue code generation.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::sketches;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::ActionTemplateItem;
use crate::model::DraftInput;
use crate::model::ProofKind;
use crate::ops::CreateQrChallenge;
use crate::ops::DraftActionFromPrompt;
use crate::ops::GetDraft;
use crate::ops::ListTemplates;
use crate::ops::PauseAction;
use crate::ops::PublishAction;
use crate::ops::SaveAction;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;
use crate::wallet;

/// The radius every new action starts with, in metres.
const RADIUS_METERS: i64 = 100;

/// Writes a new draft, or edits `draft` when there is one.
#[component]
pub fn Editor(draft: Option<String>) -> Element {
	let l10n = use_l10n();
	let key = format!("editor.{}", draft.as_deref().unwrap_or("new"));
	let title = remember(&format!("{key}.title"), String::new);
	let summary = remember(&format!("{key}.summary"), String::new);
	let place = remember(&format!("{key}.place"), String::new);
	let radius = remember(&format!("{key}.radius"), || RADIUS_METERS);
	let lat_input = remember(&format!("{key}.lat"), String::new);
	let lon_input = remember(&format!("{key}.lon"), String::new);
	let reward = remember(&format!("{key}.reward"), String::new);
	let proofs = remember(&format!("{key}.proofs"), || vec![ProofKind::Photo]);
	let prompt_text = remember(&format!("{key}.prompt"), String::new);
	let venue_code = remember(&format!("{key}.venue_code"), String::new);
	let paused = remember(&format!("{key}.paused"), || false);
	let notice = remember(&format!("{key}.notice"), String::new);
	let hydrated = remember(&format!("{key}.hydrated"), || false);
	let is_new = draft.is_none();
	let saved_id = remember(&format!("{key}.saved"), move || draft.clone());

	let existing = use_rpc_query(move || GetDraft {
		action_id: saved_id.get().unwrap_or_default(),
	});
	if !is_new
		&& !hydrated.get()
		&& let Some(loaded) = existing.data()
	{
		title.set(loaded.title);
		summary.set(loaded.summary);
		place.set(loaded.place_name);
		radius.set(loaded.radius_meters.max(10));
		lat_input.set(
			loaded
				.latitude
				.map(|v| format!("{v:.6}"))
				.unwrap_or_default(),
		);
		lon_input.set(
			loaded
				.longitude
				.map(|v| format!("{v:.6}"))
				.unwrap_or_default(),
		);
		reward.set(loaded.reward_amount);
		if !loaded.proofs.is_empty() {
			proofs.set(loaded.proofs);
		}
		hydrated.set(true);
	}

	let templates = use_rpc_query(|| ListTemplates {});

	let ai_draft = use_mutation(
		mutation_scope::<DraftActionFromPrompt>()
			.with_on_success(move |args| {
				let suggested = args.data.draft;
				title.set(suggested.title);
				summary.set(suggested.summary);
				place.set(suggested.place_name);
				radius.set(suggested.radius_meters.max(10));
				if !suggested.proofs.is_empty() {
					proofs.set(suggested.proofs);
				}
				notice.set(l10n.editor_draft_ready().to_owned());
			})
			.with_on_error(move |_| {
				notice.set(l10n.editor_prompt_too_short().to_owned());
			}),
	);

	let publish = use_mutation(
		mutation_scope::<PublishAction>().with_on_success(move |args| {
			notice.set(if args.data.is_live() {
				l10n.editor_published().to_owned()
			} else {
				l10n.editor_fund_first().to_owned()
			});
		}),
	);
	let save = use_mutation(mutation_scope::<SaveAction>().with_on_success(move |args| {
		saved_id.set(Some(args.data.id));
		notice.set(l10n.editor_saved().to_owned());
	}));
	let pause = use_mutation(
		mutation_scope::<PauseAction>().with_on_success(move |args| {
			paused.set(args.data.paused);
			notice.set(if args.data.paused {
				l10n.editor_status_paused().to_owned()
			} else {
				l10n.editor_status_live().to_owned()
			});
		}),
	);
	let qr = use_mutation(
		mutation_scope::<CreateQrChallenge>()
			.with_on_success(move |args| {
				venue_code.set(args.data.code);
			})
			.with_on_error(move |_| {
				notice.set(l10n.venue_code_failed().to_owned());
			}),
	);

	let heading = if saved_id.get().is_some() {
		l10n.editor_edit_title()
	} else {
		l10n.editor_new_title()
	};

	let all_kinds = [
		(ProofKind::Photo, l10n.do_proof_photo()),
		(ProofKind::Video, l10n.do_proof_video()),
		(ProofKind::Audio, l10n.do_proof_audio()),
		(ProofKind::Presence, l10n.do_proof_place()),
		(ProofKind::Movement, l10n.do_proof_movement()),
		(ProofKind::VenueCode, l10n.do_proof_venue_code()),
	];
	let proof_choices = all_kinds
		.into_iter()
		.enumerate()
		.map(|(idx, (kind, label))| {
			let selected = proofs.get().contains(&kind);
			view! {
				<chrome::Choice
					label=label
					selected=selected
					seed=240 + idx as i64
					on_press=move || {
						let mut current = proofs.get();
						if let Some(pos) = current.iter().position(|k| *k == kind) {
							if current.len() > 1 {
								current.remove(pos);
							}
						} else {
							current.push(kind);
						}
						proofs.set(current);
					}
				/>
			}
		})
		.collect::<Vec<_>>();

	let radius_choices = [50_i64, 100, 250, 500]
		.into_iter()
		.enumerate()
		.map(|(idx, meters)| {
			view! {
				<chrome::Choice
					label=format!("{meters} m")
					selected=radius.get() == meters
					seed=260 + idx as i64
					on_press=move || radius.set(meters)
				/>
			}
		})
		.collect::<Vec<_>>();

	view! {
		<chrome::Page>
			<chrome::Heading text=heading body=l10n.editor_new_subtitle() />
			{Show(
				move || is_new,
				move || {
					view! {
						<View class=theme::STACK>
							<chrome::Card seed=195>
								<chrome::Title text=l10n.editor_templates_heading() />
								{Show(
									move || templates.is_loading(),
									move || view! { <chrome::Loading text=l10n.editor_templates_loading() /> },
								)}
								<View class=theme::ROW>
									{For(
										move || templates.data().unwrap_or_default(),
										|tpl: &ActionTemplateItem| tpl.id.clone(),
										move |tpl| {
											let label = tpl.title.clone();
											let seed = chrome::seed_for(&tpl.id);
											view! {
												<chrome::Quiet
													label=label
													seed=seed
													on_press=move || {
														title.set(tpl.title.clone());
														summary.set(tpl.summary.clone());
														place.set(tpl.place_name.clone());
														radius.set(tpl.radius_meters.max(10));
														if !tpl.proofs.is_empty() {
															proofs.set(tpl.proofs.clone());
														}
														notice.set(l10n.editor_draft_ready().to_owned());
													}
												/>
											}
										},
									)}
								</View>
							</chrome::Card>
							<chrome::Card seed=197>
								<chrome::Field
									label=l10n.editor_prompt_label()
									placeholder=l10n.editor_prompt_hint()
									value=prompt_text.get()
									on_change=move |next| prompt_text.set(next.to_owned())
									seed=198
								/>
								<chrome::Muted text=l10n.editor_prompt_help() />
								<chrome::Quiet
									label=l10n.editor_prompt_action()
									disabled=ai_draft.is_pending()
									on_press=move || {
										let p = prompt_text.get();
										if p.trim().len() < 8 {
											notice.set(l10n.editor_prompt_too_short().to_owned());
											return;
										}
										ai_draft.mutate(DraftActionFromPrompt { prompt: p });
									}
									seed=199
								/>
							</chrome::Card>
						</View>
					}
				},
			)}
			<chrome::Card seed=201>
				<chrome::Field
					label=l10n.editor_title_label()
					value=title.get()
					on_change=move |next| title.set(next.to_owned())
					seed=203
				/>
				<chrome::Field
					label=l10n.editor_description_label()
					value=summary.get()
					on_change=move |next| summary.set(next.to_owned())
					seed=205
				/>
			</chrome::Card>
			<chrome::RoleCard role=Role::Place seed=207>
				<View class="items-center">{sketches::place_map(209)}</View>
				<chrome::Field
					label=l10n.editor_place_pin()
					value=place.get()
					on_change=move |next| place.set(next.to_owned())
					seed=211
				/>
				<chrome::Muted text=l10n.editor_radius(radius.get()) />
				<View class=theme::ROW>{radius_choices}</View>
				<View class=theme::ROW>
					<chrome::Field
						label=l10n.editor_latitude_label()
						value=lat_input.get()
						on_change=move |next| lat_input.set(next.trim().to_owned())
						seed=212
					/>
					<chrome::Field
						label=l10n.editor_longitude_label()
						value=lon_input.get()
						on_change=move |next| lon_input.set(next.trim().to_owned())
						seed=214
					/>
				</View>
			</chrome::RoleCard>
			<chrome::Card seed=213>
				<chrome::Title text=l10n.editor_proof_heading() />
				<chrome::Muted text=l10n.editor_proof_help() />
				<View class=theme::ROW>{proof_choices}</View>
			</chrome::Card>
			<chrome::RoleCard role=Role::Reward seed=217>
				<View class="flex flex-row items-center gap-3">
					{sketches::coin(32.0, 219)} <chrome::Title text=l10n.editor_reward_heading() />
				</View>
				<chrome::Field
					label=l10n.editor_reward_amount_label()
					value=reward.get()
					on_change=move |next| reward.set(next.to_owned())
					seed=221
				/>
				<chrome::Muted text=l10n.editor_fund_first() />
				{Show(
					move || saved_id.get().is_some() && !reward.get().trim().is_empty(),
					move || {
						view! {
							<chrome::Quiet
								label=l10n.hub_fund()
								on_press=move || {
									if let Some(action_id) = saved_id.get() {
										wallet::begin_fund_escrow(action_id, move |res| {
											match res {
												Ok(()) => notice.set(l10n.hub_reward_funded().to_owned()),
												Err(wallet::LinkFault::Unsupported) => {
													notice.set(l10n.me_wallet_unsupported().to_owned());
												}
												Err(_) => {
													notice.set(l10n.me_wallet_failure_failed().to_owned());
												}
											}
										});
									}
								}
								seed=222
							/>
						}
					},
				)}
			</chrome::RoleCard>
			{Show(
				move || saved_id.get().is_some(),
				move || {
					view! {
						<chrome::Card seed=227>
							<chrome::Title text=l10n.venue_code_title() />
							<chrome::Muted text=l10n.venue_code_body() />
							<chrome::Quiet
								label=l10n.venue_code_new()
								disabled=qr.is_pending()
								on_press=move || {
									if let Some(action_id) = saved_id.get() {
										qr.mutate(CreateQrChallenge {
											action_id,
											ttl_seconds: Some(300),
										});
									}
								}
								seed=229
							/>
							{Show(
								move || !venue_code.get().is_empty(),
								move || view! { <chrome::Title text=venue_code.get() /> },
							)}
						</chrome::Card>
					}
				},
			)}
			{Show(
				move || !notice.get().is_empty(),
				move || view! { <chrome::Body text=notice.get() /> },
			)}
			<View class=theme::STACK>
				<chrome::Primary
					label=l10n.editor_save()
					disabled=save.is_pending()
					on_press=move || {
						let latitude = lat_input.get().trim().parse::<f64>().ok();
						let longitude = lon_input.get().trim().parse::<f64>().ok();
						let draft = DraftInput {
							id: saved_id.get(),
							title: title.get(),
							summary: summary.get(),
							place_name: place.get(),
							radius_meters: radius.get(),
							reward_amount: reward.get(),
							proofs: proofs.get(),
							latitude,
							longitude,
						};
						if !draft.ready_to_save() {
							notice.set(l10n.editor_field_required().to_owned());
							return;
						}
						save.mutate(SaveAction { draft });
					}
					seed=223
				/>
				<chrome::Quiet
					label=l10n.editor_publish()
					disabled=publish.is_pending()
					on_press=move || {
						let Some(action_id) = saved_id.get() else {
							notice.set(l10n.editor_fund_first().to_owned());
							return;
						};
						publish.mutate(PublishAction { action_id });
					}
					seed=225
				/>
				{Show(
					move || saved_id.get().is_some(),
					move || {
						let label = if paused.get() {
							l10n.hub_publish()
						} else {
							l10n.hub_pause()
						};
						view! {
							<chrome::Quiet
								label=label
								disabled=pause.is_pending()
								on_press=move || {
									if let Some(action_id) = saved_id.get() {
										pause.mutate(PauseAction {
											action_id,
											paused: !paused.get(),
										});
									}
								}
								seed=231
							/>
						}
					},
				)}
			</View>
		</chrome::Page>
	}
}
