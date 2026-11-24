//! The creator's notebook, `/create`: drafts, live/paused actions, appeals,
//! and partner Verily Apps.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
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
use crate::model::DraftRow;
use crate::ops::ListMyActions;
use crate::ops::PauseAction;
use crate::routes::EditAction;
use crate::routes::Navigation;
use crate::routes::NewAction;
use crate::routes::Route;
use crate::theme;
use crate::theme::Role;

/// Drafts, live/paused actions, and links to creator tools.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let rows = use_rpc_query(|| ListMyActions {});
	let post = navigation.clone();
	let appeals = navigation.clone();
	let apps = navigation.clone();
	let navigation = navigation.clone();
	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.hub_title() body=l10n.hub_subtitle() />
			<chrome::Primary
				label=l10n.hub_post_action()
				on_press=move || post.navigate(NewAction)
				seed=301
			/>
			<View class=theme::ROW>
				<chrome::Quiet
					label=l10n.hub_appeals_open()
					on_press=move || appeals.navigate(Route::Appeals)
					seed=305
				/>
				<chrome::Quiet
					label=l10n.hub_apps_open()
					on_press=move || apps.navigate(Route::Apps)
					seed=307
				/>
			</View>
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
	let pause_id = row.id.clone();
	let is_paused = row.paused;
	let pause = use_mutation(mutation_scope::<PauseAction>().with_on_success_async(
		move |args| async move {
			args.client
				.invalidate_scope(&query_scope::<ListMyActions>())
				.await;
		},
	));
	let (role, status) = if row.paused {
		(Role::Review, l10n.hub_status_paused())
	} else if row.live && row.funded {
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
			<View class=theme::ROW>
				<chrome::Quiet
					label=l10n.hub_edit()
					on_press=move || navigation.navigate(EditAction { action: id.clone() })
					seed=seed + 2
				/>
				{(row.live || row.paused).then(|| {
					let label = if is_paused {
						l10n.hub_publish()
					} else {
						l10n.hub_pause()
					};
					view! {
						<chrome::Quiet
							label=label
							disabled=pause.is_pending()
							on_press=move || {
								pause.mutate(PauseAction {
									action_id: pause_id.clone(),
									paused: !is_paused,
								});
							}
							seed=seed + 3
						/>
					}
				})}
			</View>
		</chrome::Card>
	}
}
