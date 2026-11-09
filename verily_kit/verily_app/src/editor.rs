//! The action editor, shared by `/actions/new` and `/actions/:action/edit`:
//! the page a creator writes, with the place and the reward drawn as they
//! will appear.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::view;
use verily_ink::sketches;

use crate::chrome;
use crate::chrome::Outcome;
use crate::l10n::use_l10n;
use crate::model::DraftInput;
use crate::model::ProofKind;
use crate::ops::PublishAction;
use crate::ops::SaveAction;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;

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
	let reward = remember(&format!("{key}.reward"), String::new);
	let notice = remember(&format!("{key}.notice"), String::new);
	let saved_id = remember(&format!("{key}.saved"), move || draft);

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

	let heading = if saved_id.get().is_some() {
		l10n.editor_edit_title()
	} else {
		l10n.editor_new_title()
	};
	view! {
		<chrome::Page>
			<chrome::Heading text=heading body=l10n.editor_new_subtitle() />
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
				<chrome::Muted text=l10n.editor_radius(RADIUS_METERS) />
			</chrome::RoleCard>
			<chrome::Card seed=213>
				<chrome::Title text=l10n.editor_proof_heading() />
				<chrome::ProofRow text=l10n.do_proof_photo() outcome=Outcome::Open seed=215 />
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
			</chrome::RoleCard>
			{Show(
				move || !notice.get().is_empty(),
				move || view! { <chrome::Body text=notice.get() /> },
			)}
			<View class=theme::STACK>
				<chrome::Primary
					label=l10n.editor_save()
					disabled=save.is_pending()
					on_press=move || {
						let draft = DraftInput {
							id: saved_id.get(),
							title: title.get(),
							summary: summary.get(),
							place_name: place.get(),
							radius_meters: RADIUS_METERS,
							reward_amount: reward.get(),
							proofs: vec![ProofKind::Photo],
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
			</View>
		</chrome::Page>
	}
}
