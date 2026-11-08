//! Create: the creator's list, and an editor that does not treat a draft as funded.

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
use crate::model::DraftInput;
use crate::model::DraftRow;
use crate::model::ProofKind;
use crate::ops::ListMyActions;
use crate::ops::PublishAction;
use crate::ops::SaveAction;
use crate::route::EditorPage;
use crate::route::Navigation;
use crate::theme;

/// Drafts and live actions.
pub fn create_hub(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let rows = use_rpc_query(|| ListMyActions {});
	let open_editor = navigation.clone();
	let navigation = navigation.clone();
	View()
		.class("flex flex-col gap-4")
		.child(chrome::title(l10n.hub_title()))
		.child(chrome::muted(l10n.hub_subtitle()))
		.child(
			Button(l10n.hub_post_action().to_owned())
				.class(theme::PRIMARY)
				.on_press(move || {
					open_editor.navigate(EditorPage {
						draft: "new".into(),
					});
				}),
		)
		.child(Show(
			move || rows.is_loading(),
			move || chrome::muted(l10n.hub_loading()),
		))
		.child(Show(
			move || rows.is_error(),
			move || chrome::title(l10n.hub_load_failed_title()),
		))
		.child(Show(
			move || rows.data().is_some_and(|list| list.is_empty()),
			move || {
				View()
					.class(theme::CARD)
					.child(chrome::title(l10n.hub_empty_title()))
					.child(chrome::muted(l10n.hub_empty_body()))
			},
		))
		.child(For(
			move || rows.data().unwrap_or_default(),
			|row: &DraftRow| row.id.clone(),
			move |row| draft_row(navigation.clone(), row),
		))
}

fn draft_row(navigation: Navigation, row: DraftRow) -> Element {
	let l10n = use_l10n();
	let id = row.id.clone();
	let status = if row.live && row.funded {
		l10n.hub_status_live()
	} else if row.funded {
		l10n.hub_reward_funded()
	} else {
		l10n.hub_reward_needs_funding()
	};
	View()
		.class(theme::CARD)
		.child(Text(row.title).class("font-semibold"))
		.child(chrome::muted(status))
		.child(
			Button(l10n.hub_edit().to_owned())
				.class(theme::QUIET)
				.on_press(move || navigation.navigate(EditorPage { draft: id.clone() })),
		)
}

/// Title, summary, place name, radius, reward, and one live proof.
pub fn editor(navigation: &Navigation, page: &EditorPage) -> Element {
	let l10n = use_l10n();
	let title = RwSignal::new(String::new());
	let summary = RwSignal::new(String::new());
	let place = RwSignal::new(String::new());
	let reward = RwSignal::new(String::new());
	let notice = RwSignal::new(String::new());
	let draft_id = page.draft.clone();
	let saved_id = RwSignal::new(if draft_id == "new" {
		None
	} else {
		Some(draft_id)
	});

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

	let saved_for_publish = saved_id;
	View()
		.class("flex flex-col gap-4")
		.child(chrome::title(l10n.editor_new_title()))
		.child(chrome::muted(l10n.editor_new_subtitle()))
		.child(field(l10n.editor_title_label(), title))
		.child(field(l10n.editor_description_label(), summary))
		.child(field(l10n.editor_place_pin(), place))
		.child(chrome::muted(l10n.editor_radius(100)))
		.child(field(l10n.editor_reward_amount_label(), reward))
		.child(chrome::muted(l10n.editor_proof_heading()))
		.child(chrome::muted(l10n.do_proof_photo()))
		.child(chrome::muted(l10n.editor_fund_first()))
		.child(Show(
			move || !notice.get().is_empty(),
			move || chrome::muted(notice.get()),
		))
		.child(
			Button(l10n.editor_save().to_owned())
				.class(theme::PRIMARY)
				.on_press(move || {
					let draft = DraftInput {
						id: saved_id.get(),
						title: title.get(),
						summary: summary.get(),
						place_name: place.get(),
						radius_meters: 100,
						reward_amount: reward.get(),
						proofs: vec![ProofKind::Photo],
					};
					if !draft.ready_to_save() {
						notice.set(l10n.editor_field_required().to_owned());
						return;
					}
					save.mutate(SaveAction { draft });
				}),
		)
		.child(
			Button(l10n.editor_publish().to_owned())
				.class(theme::QUIET)
				.on_press(move || {
					let Some(action_id) = saved_for_publish.get() else {
						notice.set(l10n.editor_fund_first().to_owned());
						return;
					};
					publish.mutate(PublishAction { action_id });
				}),
		)
		.child({
			let navigation = navigation.clone();
			Button(l10n.action_back().to_owned())
				.class(theme::QUIET)
				.on_press(move || {
					navigation.back();
				})
		})
}

fn field(label: &str, value: RwSignal<String>) -> Element {
	View()
		.class("flex flex-col gap-2")
		.child(chrome::muted(label))
		.child(
			TextInput()
				.class(theme::FIELD)
				.on_change(move |next| value.set(next.to_owned())),
		)
}
