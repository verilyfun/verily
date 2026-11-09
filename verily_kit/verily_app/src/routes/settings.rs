//! Appearance and account, `/settings`.
//!
//! Nothing on this screen is a token, a key, or a chain address.

use leptoskit::component;
use leptoskit::prelude::Button;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::RwSignal;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::TextInput;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::view;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::ops::CloseAccount;
use crate::ops::SignOut;
use crate::routes::Navigation;
use crate::theme;

/// Appearance and account actions.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let _ = navigation;
	let l10n = use_l10n();
	let notice = RwSignal::new(String::new());
	let confirmation = RwSignal::new(String::new());
	let confirm_open = RwSignal::new(false);
	let sign_out = use_mutation(
		mutation_scope::<SignOut>()
			.with_on_success(move |_| {
				notice.set(l10n.settings_sign_out_subtitle().to_owned());
			})
			.with_on_error(move |_| {
				notice.set(l10n.settings_sign_out_failed().to_owned());
			}),
	);
	let close = use_mutation(
		mutation_scope::<CloseAccount>()
			.with_on_success(move |_| {
				notice.set(l10n.settings_close_account_subtitle().to_owned());
				confirm_open.set(false);
			})
			.with_on_error(move |_| {
				notice.set(l10n.settings_close_account_failed().to_owned());
			}),
	);

	view! {
		<View class="flex flex-col gap-4">
			<chrome::Title text=l10n.settings_title() />
			<chrome::Muted text=l10n.settings_subtitle() />
			<chrome::Title text=l10n.appearance_title() />
			<chrome::Muted text=l10n.appearance_subtitle() />
			<View class=theme::ROW>
				<Button class=theme::QUIET on:press=theme::install_paper>
					{l10n.appearance_system()}
				</Button>
				<Button class=theme::QUIET on:press=theme::install_paper>
					{l10n.appearance_light()}
				</Button>
				<Button class=theme::QUIET on:press=theme::install_night>
					{l10n.appearance_dark()}
				</Button>
			</View>
			<chrome::Title text=l10n.settings_account_title() />
			<chrome::Muted text=l10n.settings_sign_out_subtitle() />
			<Button class=theme::QUIET on:press=move || sign_out.mutate(SignOut {})>
				{l10n.settings_sign_out()}
			</Button>
			<chrome::Muted text=l10n.settings_close_account_subtitle() />
			<Button class=theme::PRIMARY on:press=move || confirm_open.set(true)>
				{l10n.settings_close_account()}
			</Button>
			{Show(
				move || confirm_open.get(),
				move || {
					view! {
						<View class=theme::CARD>
							<chrome::Title text=l10n.settings_close_account_dialog_title() />
							<chrome::Muted text=l10n.settings_close_account_dialog_body() />
							<chrome::Muted text=l10n.settings_close_account_confirmation_label() />
							<TextInput
								class=theme::FIELD
								on:change=move |next| confirmation.set(next.to_owned())
							/>
							<View class=theme::ROW>
								<Button
									class=theme::PRIMARY
									on:press=move || {
										let phrase = confirmation.get();
										if phrase.trim().is_empty() {
											return;
										}
										close.mutate(CloseAccount {
											confirmation: phrase,
										});
									}
								>
									{l10n.settings_close_account_confirm()}
								</Button>
								<Button class=theme::QUIET on:press=move || confirm_open.set(false)>
									{l10n.dialog_cancel()}
								</Button>
							</View>
						</View>
					}
				},
			)}
			{Show(move || !notice.get().is_empty(), move || {
				let text = notice.get();
				view! { <chrome::Muted text=text /> }
			})}
		</View>
	}
}
