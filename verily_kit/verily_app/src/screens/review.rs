//! Review: a person accepts or rejects proof.
//!
//! The screen says what was checked. It does not say a scene is real, and it
//! does not show a model, a score, or a storage path.

use leptoskit::prelude::Button;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Get;
use leptoskit::prelude::RwSignal;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::Text;
use leptoskit::prelude::TextInput;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::ProofKind;
use crate::model::ReviewRow;
use crate::ops::ListReviewQueue;
use crate::ops::ReviewAttempt;
use crate::route::Navigation;
use crate::theme;

/// The queue.
pub fn review(_navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let queue = use_rpc_query(|| ListReviewQueue {});
	View()
		.class("flex flex-col gap-4")
		.child(chrome::title(l10n.review_title()))
		.child(chrome::muted(l10n.review_reason_needs_person()))
		.child(Show(
			move || queue.is_loading(),
			move || chrome::muted(l10n.review_loading()),
		))
		.child(Show(
			move || queue.is_error(),
			move || chrome::title(l10n.review_load_failed_title()),
		))
		.child(Show(
			move || queue.data().is_some_and(|rows| rows.is_empty()),
			move || {
				View()
					.class(theme::CARD)
					.child(chrome::title(l10n.review_empty_title()))
					.child(chrome::muted(l10n.review_empty_body()))
			},
		))
		.child(For(
			move || queue.data().unwrap_or_default(),
			|row: &ReviewRow| row.id.clone(),
			|row| review_card(row),
		))
}

fn review_card(row: ReviewRow) -> Element {
	let l10n = use_l10n();
	let note = RwSignal::new(String::new());
	let message = RwSignal::new(String::new());
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
	View()
		.class(theme::REVIEW)
		.child(Text(l10n.review_context(&row.creator, &row.requirement)).class("font-semibold"))
		.child(chrome::muted(kind))
		.child(chrome::muted(if row.needs_person {
			l10n.review_reason_needs_person()
		} else {
			l10n.review_reason_verifier()
		}))
		.child(chrome::muted(l10n.review_note_label()))
		.child(
			TextInput()
				.class(theme::FIELD)
				.placeholder(l10n.review_note_hint())
				.on_change(move |next| note.set(next.to_owned())),
		)
		.child(
			View()
				.class(theme::ROW)
				.child(
					Button(l10n.review_accept().to_owned())
						.class(theme::PRIMARY)
						.on_press({
							let id = id.clone();
							move || {
								decide.mutate(ReviewAttempt {
									review_id: id.clone(),
									accept: true,
									note: note.get(),
								});
							}
						}),
				)
				.child(
					Button(l10n.review_reject().to_owned())
						.class(theme::QUIET)
						.on_press(move || {
							decide.mutate(ReviewAttempt {
								review_id: id.clone(),
								accept: false,
								note: note.get(),
							});
						}),
				),
		)
		.child(Show(
			move || !message.get().is_empty(),
			move || chrome::muted(message.get()),
		))
}
