//! The review queue, `/review`.
//!
//! The screen says what was checked. It does not say a scene is real, and it
//! does not show a model, a score, or a storage path.

use leptoskit::component;
use leptoskit::prelude::Button;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::Text;
use leptoskit::prelude::TextInput;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::state::remember;
use crate::model::ProofKind;
use crate::model::ReviewRow;
use crate::ops::ListReviewQueue;
use crate::ops::ReviewAttempt;
use crate::routes::Navigation;
use crate::theme;

/// The queue.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let _ = navigation;
	let l10n = use_l10n();
	let queue = use_rpc_query(|| ListReviewQueue {});
	view! {
		<View class="flex flex-col gap-4">
			<chrome::Title text=l10n.review_title() />
			<chrome::Muted text=l10n.review_reason_needs_person() />
			{Show(
				move || queue.is_loading(),
				move || view! { <chrome::Muted text=l10n.review_loading() /> },
			)}
			{Show(
				move || queue.is_error(),
				move || view! { <chrome::Title text=l10n.review_load_failed_title() /> },
			)}
			{Show(
				move || queue.data().is_some_and(|rows| rows.is_empty()),
				move || {
					view! {
						<View class=theme::CARD>
							<chrome::Title text=l10n.review_empty_title() />
							<chrome::Muted text=l10n.review_empty_body() />
						</View>
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
	let note = remember("review.note", String::new);
	let message = remember("review.message", String::new);
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
	view! {
		<View class=theme::REVIEW>
			<Text class="font-semibold">{context}</Text>
			<chrome::Muted text=kind />
			<chrome::Muted text=reason />
			<chrome::Muted text=l10n.review_note_label() />
			<TextInput
				class=theme::FIELD
				placeholder=l10n.review_note_hint()
				on:change=move |next| note.set(next.to_owned())
			/>
			<View class=theme::ROW>
				<Button
					class=theme::PRIMARY
					on:press=move || {
						decide.mutate(ReviewAttempt {
							review_id: accept_id.clone(),
							accept: true,
							note: note.get(),
						});
					}
				>
					{l10n.review_accept()}
				</Button>
				<Button
					class=theme::QUIET
					on:press=move || {
						decide.mutate(ReviewAttempt {
							review_id: id.clone(),
							accept: false,
							note: note.get(),
						});
					}
				>
					{l10n.review_reject()}
				</Button>
			</View>
			{Show(move || !message.get().is_empty(), move || {
				let text = message.get();
				view! { <chrome::Muted text=text /> }
			})}
		</View>
	}
}
