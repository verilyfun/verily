//! The creator's notebook, `/create`: drafts and live actions, and the way
//! to post a new one.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::sketches;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::DraftRow;
use crate::ops::ListMyActions;
use crate::routes::EditAction;
use crate::routes::Navigation;
use crate::routes::NewAction;
use crate::theme;
use crate::theme::Role;

/// Drafts and live actions.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let rows = use_rpc_query(|| ListMyActions {});
	let post = navigation.clone();
	let navigation = navigation.clone();
	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.hub_title() body=l10n.hub_subtitle() />
			<chrome::Primary
				label=l10n.hub_post_action()
				on_press=move || post.navigate(NewAction)
				seed=301
			/>
			{Show(
				move || rows.is_loading(),
				move || view! { <chrome::Loading text=l10n.hub_loading() /> },
			)}
			{Show(
				move || rows.is_error(),
				move || {
					view! {
						<chrome::Failed
							title=l10n.hub_load_failed_title()
							retry=l10n.dialog_retry()
							on_retry=move || {
								rows.refetch();
							}
						/>
					}
				},
			)}
			{Show(
				move || rows.data().is_some_and(|list| list.is_empty()),
				move || {
					view! {
						<chrome::Empty
							title=l10n.hub_empty_title()
							body=l10n.hub_empty_body()
							picture=sketches::escrow_jar(303)
						/>
					}
				},
			)}
			<View class=theme::STACK>
				{For(
					move || rows.data().unwrap_or_default(),
					|row: &DraftRow| row.id.clone(),
					move |row| view! { <DraftCard navigation=navigation.clone() row=row /> },
				)}
			</View>
		</chrome::Page>
	}
}

/// One of the creator's actions, with what it needs next.
#[component]
fn DraftCard(navigation: Navigation, row: DraftRow) -> Element {
	let l10n = use_l10n();
	let seed = chrome::seed_for(&row.id);
	let id = row.id.clone();
	let (role, status) = if row.live && row.funded {
		(Role::Place, l10n.hub_status_live())
	} else if row.funded {
		(Role::Reward, l10n.hub_reward_funded())
	} else {
		(Role::Review, l10n.hub_reward_needs_funding())
	};
	view! {
		<chrome::Card seed=seed>
			<chrome::Title text=row.title />
			<chrome::Chip role=role text=status seed=seed + 1 />
			<chrome::Quiet
				label=l10n.hub_edit()
				on_press=move || navigation.navigate(EditAction { action: id.clone() })
				seed=seed + 2
			/>
		</chrome::Card>
	}
}
