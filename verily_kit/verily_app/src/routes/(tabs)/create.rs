//! The creator's list, `/create`.

use leptoskit::component;
use leptoskit::prelude::Button;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Show;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;

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
		<View class="flex flex-col gap-4">
			<chrome::Title text=l10n.hub_title() />
			<chrome::Muted text=l10n.hub_subtitle() />
			<Button
				class=theme::PRIMARY
				on:press=move || {
					open_editor.navigate(Editor {
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
				on:press=move || navigation.navigate(Editor { draft: id.clone() })
			>
				{l10n.hub_edit()}
			</Button>
		</View>
	}
}
