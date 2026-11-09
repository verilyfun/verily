//! The creator's list, `/create`.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::View;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::draw;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::DraftRow;
use crate::ops::ListMyActions;
use crate::routes::Editor;
use crate::routes::Navigation;
use crate::theme;

/// Drafts and live actions.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let rows = use_rpc_query(|| ListMyActions {});
	let open_editor = navigation.clone();
	let navigation = navigation.clone();
	view! {
		<View class="flex flex-col gap-6">
			<View class=theme::STACK.as_str()>
				<chrome::Display text=l10n.hub_title() />
				<chrome::Body text=l10n.hub_subtitle() />
			</View>
			<chrome::Primary
				label=l10n.hub_post_action()
				seed=121
				on_press=move || {
					open_editor.navigate(Editor {
						draft: "new".into(),
					});
				}
			/>
			{(rows.is_loading()).then(|| view! { <chrome::Muted text=l10n.hub_loading() /> })}
			{(rows.is_error()).then(|| {
					view! {
						<chrome::Card seed=123>
							<chrome::Title text=l10n.hub_load_failed_title() />
						</chrome::Card>
					}
				})}
			{(rows.data().is_some_and(|list| list.is_empty())).then(|| {
					view! {
						<chrome::Empty
							picture=draw::escrow_jar(125)
							title=l10n.hub_empty_title()
							body=l10n.hub_empty_body()
						/>
					}
				})}
			<View class=theme::LIST.as_str()>{rows.data().unwrap_or_default().into_iter().map(|row| view! { <DraftCard navigation=navigation.clone() row=row /> }).collect::<Vec<_>>()}</View>
		</View>
	}
}

#[component]
fn DraftCard(navigation: Navigation, row: DraftRow) -> Element {
	let l10n = use_l10n();
	let id = row.id.clone();
	let seed = 131 + row.id.len() as i64;
	let state = if row.live {
		l10n.hub_status_live()
	} else {
		l10n.hub_status_draft()
	};
	// A reward is shown only when there is one: funded in escrow, or still
	// waiting for its escrow before it can go live.
	let reward = match (row.rewarded, row.funded) {
		(true, true) => {
			Some(view! { <chrome::RewardChip label=l10n.hub_reward_funded() seed=seed + 1 /> })
		}
		(true, false) => Some(view! { <chrome::Muted text=l10n.hub_reward_needs_funding() /> }),
		(false, _) => None,
	};
	view! {
		<chrome::Card seed=seed>
			<chrome::Title text=row.title />
			<chrome::Muted text=state />
			{reward}
			<chrome::Quiet
				label=l10n.hub_edit()
				seed=seed + 3
				on_press=move || navigation.navigate(Editor { draft: id.clone() })
			/>
		</chrome::Card>
	}
}
