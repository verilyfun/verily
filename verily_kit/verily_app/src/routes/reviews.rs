//! The review queue, `/reviews`: proof waiting for a person, plus the open
//! moderation queue for reviewers.
//!
//! The screen says what was checked. It does not say a scene is real, and it
//! does not show a model, a score, or a storage path.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::query_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::sketches;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::ModerationCaseRow;
use crate::model::ProofKind;
use crate::model::ReviewRow;
use crate::ops::ListModerationQueue;
use crate::ops::ListReviewQueue;
use crate::ops::ReviewAttempt;
use crate::ops::ReviewModerationCase;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;

/// The review and moderation queues.
#[component]
pub fn Page() -> Element {
	let l10n = use_l10n();
	let queue = use_rpc_query(|| ListReviewQueue {});
	let moderation = use_rpc_query(|| ListModerationQueue {});
	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.review_title() body=l10n.review_reason_needs_person() />
			{Show(
				move || queue.is_loading(),
				move || view! { <chrome::Loading text=l10n.review_loading() /> },
			)}
			{Show(
				move || queue.is_error(),
				move || {
					view! {
						<chrome::Failed
							title=l10n.review_load_failed_title()
							retry=l10n.dialog_retry()
							on_retry=move || {
								queue.refetch();
							}
						/>
					}
				},
			)}
			{Show(
				move || queue.data().is_some_and(|rows| rows.is_empty()),
				move || {
					view! {
						<chrome::Empty
							title=l10n.review_empty_title()
							body=l10n.review_empty_body()
							picture=sketches::stamp(96.0, 501)
						/>
					}
				},
			)}
			<View class=theme::STACK>
				{For(
					move || queue.data().unwrap_or_default(),
					|row: &ReviewRow| row.id.clone(),
					|row| view! { <ReviewCard row=row /> },
				)}
			</View>
			{Show(
				move || moderation.data().is_some_and(|rows| !rows.is_empty()),
				move || {
					view! {
						<View class=theme::STACK>
							<chrome::Title text=l10n.review_reason_abuse() />
							{For(
								move || moderation.data().unwrap_or_default(),
								|case: &ModerationCaseRow| case.id.clone(),
								|case| view! { <ModerationCard case=case /> },
							)}
						</View>
					}
				},
			)}
		</chrome::Page>
	}
}

/// One proof for a person to decide, with its own note.
#[component]
fn ReviewCard(row: ReviewRow) -> Element {
	let l10n = use_l10n();
	let seed = chrome::seed_for(&row.id);
	let note = remember(&format!("review.{}.note", row.id), String::new);
	let message = remember(&format!("review.{}.message", row.id), String::new);
	let decide = use_mutation(
		mutation_scope::<ReviewAttempt>().with_on_success(move |args| {
			message.set(if args.data.saved {
				l10n.review_saved().to_owned()
			} else {
				l10n.review_save_failed().to_owned()
			});
		}),
	);
	let kind = match row.kind {
		ProofKind::Photo | ProofKind::Note => l10n.review_kind_photo(),
		ProofKind::Video => l10n.review_kind_video(),
		ProofKind::Audio => l10n.review_kind_audio(),
		ProofKind::Presence => l10n.review_kind_location(),
		ProofKind::Movement => l10n.review_kind_motion(),
		ProofKind::VenueCode => l10n.review_kind_qr_code(),
		ProofKind::App => l10n.review_kind_external_app(),
	};
	let reason = if row.needs_person {
		l10n.review_reason_needs_person()
	} else {
		l10n.review_reason_verifier()
	};
	let has_media = row.media_review_url.is_some();
	let accept_id = row.id.clone();
	let reject_id = row.id.clone();
	view! {
		<chrome::RoleCard role=Role::Review seed=seed>
			<chrome::Title text=l10n.review_context(&row.creator, &row.requirement) />
			<chrome::Chip role=Role::Review text=kind seed=seed + 1 />
			<chrome::Muted text=reason />
			{has_media.then(|| view! { <chrome::Muted text=l10n.review_media_expires() /> })}
			<chrome::Field
				label=l10n.review_note_label()
				value=note.get()
				placeholder=l10n.review_note_hint()
				on_change=move |next| note.set(next.to_owned())
				seed=seed + 2
			/>
			<View class=theme::ROW>
				<chrome::Quiet
					label=l10n.review_accept()
					disabled=decide.is_pending()
					on_press=move || {
						decide.mutate(ReviewAttempt {
							review_id: accept_id.clone(),
							accept: true,
							note: note.get(),
						});
					}
					seed=seed + 3
				/>
				<chrome::Quiet
					label=l10n.review_reject()
					disabled=decide.is_pending()
					on_press=move || {
						decide.mutate(ReviewAttempt {
							review_id: reject_id.clone(),
							accept: false,
							note: note.get(),
						});
					}
					seed=seed + 4
				/>
			</View>
			{Show(
				move || !message.get().is_empty(),
				move || view! { <chrome::Body text=message.get() /> },
			)}
		</chrome::RoleCard>
	}
}

/// One open moderation report awaiting reviewer action.
#[component]
fn ModerationCard(case: ModerationCaseRow) -> Element {
	let l10n = use_l10n();
	let seed = chrome::seed_for(&case.id);
	let note = remember(&format!("moderation.{}.note", case.id), String::new);
	let feedback = remember(&format!("moderation.{}.feedback", case.id), String::new);
	let decide = use_mutation(
		mutation_scope::<ReviewModerationCase>()
			.with_on_success_async(move |args| async move {
				feedback.set(l10n.review_saved().to_owned());
				args.client
					.invalidate_scope(&query_scope::<ListModerationQueue>())
					.await;
			})
			.with_on_error(move |_| {
				feedback.set(l10n.review_save_failed().to_owned());
			}),
	);
	let clear_id = case.id.clone();
	let remove_id = case.id.clone();
	let notes = case.notes.clone();
	view! {
		<chrome::RoleCard role=Role::Review seed=seed>
			<chrome::Title text=case.reason />
			<chrome::Chip role=Role::Review text=case.status seed=seed + 1 />
			{notes.map(|text| view! { <chrome::Muted text=text /> })}
			<chrome::Field
				label=l10n.review_note_label()
				value=note.get()
				placeholder=l10n.review_note_hint()
				on_change=move |next| note.set(next.to_owned())
				seed=seed + 2
			/>
			<View class=theme::ROW>
				<chrome::Quiet
					label=l10n.review_accept()
					disabled=decide.is_pending()
					on_press=move || {
						decide.mutate(ReviewModerationCase {
							case_id: clear_id.clone(),
							new_status: "cleared".to_owned(),
							note: note.get(),
						});
					}
					seed=seed + 3
				/>
				<chrome::Quiet
					label=l10n.review_reject()
					disabled=decide.is_pending()
					on_press=move || {
						decide.mutate(ReviewModerationCase {
							case_id: remove_id.clone(),
							new_status: "removed".to_owned(),
							note: note.get(),
						});
					}
					seed=seed + 4
				/>
			</View>
			{Show(
				move || !feedback.get().is_empty(),
				move || view! { <chrome::Body text=feedback.get() /> },
			)}
		</chrome::RoleCard>
	}
}
