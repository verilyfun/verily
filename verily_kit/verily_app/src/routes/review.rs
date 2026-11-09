//! The review queue, `/review`.
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
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::draw;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::ProofKind;
use crate::model::ReviewRow;
use crate::ops::ListReviewQueue;
use crate::ops::ReviewAttempt;
use crate::routes::Navigation;
use crate::state::remember;
use crate::theme;

/// The queue.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let _ = navigation;
	let l10n = use_l10n();
	let queue = use_rpc_query(|| ListReviewQueue {});
	view! {
		<View class="flex flex-col gap-6">
			<View class=theme::STACK.as_str()>
				<chrome::Display text=l10n.review_title() />
				<chrome::Body text=l10n.review_reason_needs_person() />
			</View>
			{Show(
				move || queue.is_loading(),
				move || view! { <chrome::Muted text=l10n.review_loading() /> },
			)}
			{Show(
				move || queue.is_error(),
				move || {
					view! {
						<chrome::Card seed=211>
							<chrome::Title text=l10n.review_load_failed_title() />
						</chrome::Card>
					}
				},
			)}
			{Show(
				move || queue.data().is_some_and(|rows| rows.is_empty()),
				move || {
					view! {
						<chrome::Empty
							picture=draw::stamp(96.0, 213)
							title=l10n.review_empty_title()
							body=l10n.review_empty_body()
						/>
					}
				},
			)}
			{For(
				move || queue.data().unwrap_or_default(),
				|row: &ReviewRow| row.id.clone(),
				|row| view! { <ReviewCard row=row /> },
			)}
		</View>
	}
}

#[component]
fn ReviewCard(row: ReviewRow) -> Element {
	let l10n = use_l10n();
	let note = remember(&format!("review.{}.note", row.id), String::new);
	let message = remember(&format!("review.{}.message", row.id), String::new);
	let id = row.id.clone();
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
		ProofKind::Photo => l10n.review_kind_photo(),
		ProofKind::Video => l10n.review_kind_video(),
		ProofKind::Audio => l10n.review_kind_audio(),
		ProofKind::Note => l10n.review_kind_photo(),
		ProofKind::Presence => l10n.review_kind_location(),
		ProofKind::Movement => l10n.review_kind_motion(),
		ProofKind::VenueCode => l10n.review_kind_qr_code(),
		ProofKind::App => l10n.review_kind_external_app(),
	};
	let context = l10n.review_context(&row.creator, &row.requirement);
	let reason = if row.needs_person {
		l10n.review_reason_needs_person()
	} else {
		l10n.review_reason_verifier()
	};
	let accept_id = id.clone();
	let seed = 221 + row.id.len() as i64;
	view! {
		<chrome::Card seed=seed>
			<chrome::Title text=context />
			<chrome::Muted text=kind />
			<chrome::ReviewChip text=reason seed=seed + 1 />
			<chrome::Field
				label=l10n.review_note_label()
				value=note.get()
				placeholder=l10n.review_note_hint()
				seed=seed + 3
				on_change=move |next: &str| note.set(next.to_owned())
			/>
			<View class=theme::ROW.as_str()>
				<chrome::Choice
					label=l10n.review_accept()
					selected=true
					seed=seed + 5
					on_press=move || {
						decide.mutate(ReviewAttempt {
							review_id: accept_id.clone(),
							accept: true,
							note: note.get(),
						});
					}
				/>
				<chrome::Quiet
					label=l10n.review_reject()
					seed=seed + 7
					on_press=move || {
						decide.mutate(ReviewAttempt {
							review_id: id.clone(),
							accept: false,
							note: note.get(),
						});
					}
				/>
			</View>
			{Show(move || !message.get().is_empty(), move || {
				let text = message.get();
				view! { <chrome::Body text=text /> }
			})}
		</chrome::Card>
	}
}
