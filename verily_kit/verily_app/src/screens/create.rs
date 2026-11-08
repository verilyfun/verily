//! Create: the creator's list, and an editor that does not treat a draft as funded.

use leptoskit::component;
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
use leptoskit::view;

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
#[component]
pub fn CreateHub(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let rows = use_rpc_query(|| ListMyActions {});
	let open_editor = navigation.clone();
	let navigation = navigation.clone();
	view! {
		<View class="flex flex-col gap-4">
			<chrome::Title text=l10n.hub_title() />
			<chrome::Muted text=l10n.hub_subtitle() />
			<Button
				class=theme::PRIMARY
				on:press=move || {
					open_editor.navigate(EditorPage {
						draft: "new".into(),
					});
				}
			>
				{l10n.hub_post_action()}
			</Button>
			{Show(
				move || rows.is_loading(),
				move || view! { <chrome::Muted text=l10n.hub_loading() /> },
			)}
			{Show(
				move || rows.is_error(),
				move || view! { <chrome::Title text=l10n.hub_load_failed_title() /> },
			)}
			{Show(
				move || rows.data().is_some_and(|list| list.is_empty()),
				move || {
					view! {
						<View class=theme::CARD>
							<chrome::Title text=l10n.hub_empty_title() />
							<chrome::Muted text=l10n.hub_empty_body() />
						</View>
					}
				},
			)}
			{For(
				move || rows.data().unwrap_or_default(),
				|row: &DraftRow| row.id.clone(),
				move |row| view! { <DraftCard navigation=navigation.clone() row=row /> },
			)}
		</View>
	}
}

#[component]
fn DraftCard(navigation: Navigation, row: DraftRow) -> Element {
	let l10n = use_l10n();
	let id = row.id.clone();
	let status = if row.live && row.funded {
		l10n.hub_status_live()
	} else if row.funded {
		l10n.hub_reward_funded()
	} else {
		l10n.hub_reward_needs_funding()
	};
	view! {
		<View class=theme::CARD>
			<Text class="font-semibold">{row.title}</Text>
			<chrome::Muted text=status />
			<Button
				class=theme::QUIET
				on:press=move || navigation.navigate(EditorPage { draft: id.clone() })
			>
				{l10n.hub_edit()}
			</Button>
		</View>
	}
}

/// Title, summary, place name, radius, reward, and one live proof.
#[component]
pub fn Editor(navigation: &Navigation, page: &EditorPage) -> Element {
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
	let back = navigation.clone();
	view! {
		<View class="flex flex-col gap-4">
			<chrome::Title text=l10n.editor_new_title() />
			<chrome::Muted text=l10n.editor_new_subtitle() />
			<Field label=l10n.editor_title_label() value=title />
			<Field label=l10n.editor_description_label() value=summary />
			<Field label=l10n.editor_place_pin() value=place />
			<chrome::Muted text=l10n.editor_radius(100) />
			<Field label=l10n.editor_reward_amount_label() value=reward />
			<chrome::Muted text=l10n.editor_proof_heading() />
			<chrome::Muted text=l10n.do_proof_photo() />
			<chrome::Muted text=l10n.editor_fund_first() />
			{Show(
				move || !notice.get().is_empty(),
				move || {
					let text = notice.get();
					view! { <chrome::Muted text=text /> }
				},
			)}
			<Button
				class=theme::PRIMARY
				on:press=move || {
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
				}
			>
				{l10n.editor_save()}
			</Button>
			<Button
				class=theme::QUIET
				on:press=move || {
					let Some(action_id) = saved_for_publish.get() else {
						notice.set(l10n.editor_fund_first().to_owned());
						return;
					};
					publish.mutate(PublishAction { action_id });
				}
			>
				{l10n.editor_publish()}
			</Button>
			<Button class=theme::QUIET on:press=move || { back.back(); }>{l10n.action_back()}</Button>
		</View>
	}
}

#[component]
fn Field(label: impl Into<String>, value: RwSignal<String>) -> Element {
	let label = label.into();
	view! {
		<View class="flex flex-col gap-2">
			<chrome::Muted text=label />
			<TextInput class=theme::FIELD on:change=move |next| value.set(next.to_owned()) />
		</View>
	}
}
