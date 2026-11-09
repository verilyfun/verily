//! The editor, `/create/:draft`. `new` starts a blank draft.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::RwSignal;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::view;
use leptoskit_router::Route;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::DraftInput;
use crate::model::ProofKind;
use crate::ops::PublishAction;
use crate::ops::SaveAction;
use crate::routes::Navigation;
use crate::state::remember;
use crate::theme;

#[derive(Route, Clone, Debug, PartialEq)]
pub struct Editor {
	pub draft: String,
}

/// Title, summary, place name, radius, reward, and one live proof.
#[component]
pub fn Page(route: &Editor, navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let draft_id = route.draft.clone();
	let key = format!("create.{draft_id}");
	let title = remember(&format!("{key}.title"), String::new);
	let summary = remember(&format!("{key}.summary"), String::new);
	let place = remember(&format!("{key}.place"), String::new);
	let reward = remember(&format!("{key}.reward"), String::new);
	let notice = remember(&format!("{key}.notice"), String::new);
	let saved_id = remember(&format!("{key}.saved"), || {
		(draft_id != "new").then(|| draft_id.clone())
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
		<View class="flex flex-col gap-6">
			<View class=theme::STACK.as_str()>
				<chrome::Display text=l10n.editor_new_title() />
				<chrome::Body text=l10n.editor_new_subtitle() />
			</View>
			<chrome::Card seed=141>
				<Field label=l10n.editor_title_label() value=title seed=143 />
				<Field label=l10n.editor_description_label() value=summary seed=145 />
			</chrome::Card>
			<chrome::Card seed=147>
				<Field label=l10n.editor_place_pin() value=place seed=149 />
				<chrome::PlaceChip
					name=place.get()
					detail=l10n.editor_radius(100)
					seed=151
				/>
			</chrome::Card>
			<chrome::Card seed=153>
				<Field label=l10n.editor_reward_amount_label() value=reward seed=155 />
				<chrome::Muted text=l10n.editor_fund_first() />
			</chrome::Card>
			<chrome::Card seed=157>
				<chrome::Title text=l10n.editor_proof_heading() />
				<chrome::ProofRow
					text=l10n.do_proof_photo()
					detail=l10n.editor_kind_photo_help()
					seed=159
				/>
			</chrome::Card>
			{Show(
				move || !notice.get().is_empty(),
				move || {
					let text = notice.get();
					view! { <chrome::Body text=text /> }
				},
			)}
			<chrome::Primary
				label=l10n.editor_save()
				seed=161
				on_press=move || {
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
			/>
			<View class=theme::ROW.as_str()>
				<chrome::Quiet
					label=l10n.editor_publish()
					seed=163
					on_press=move || {
						let Some(action_id) = saved_for_publish.get() else {
							notice.set(l10n.editor_fund_first().to_owned());
							return;
						};
						publish.mutate(PublishAction { action_id });
					}
				/>
				<chrome::Quiet label=l10n.action_back() seed=165 on_press=move || { back.back(); } />
			</View>
		</View>
	}
}

#[component]
fn Field(label: impl Into<String>, value: RwSignal<String>, seed: i64) -> Element {
	view! {
		<chrome::Field
			label=label.into()
			value=value.get()
			seed=seed
			on_change=move |next: &str| value.set(next.to_owned())
		/>
	}
}
