//! Appearance and account, `/settings`.
//!
//! Nothing on this screen is a token, a key, or a chain address.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::view;

use crate::chrome;
use crate::chrome::Outcome;
use crate::l10n::use_l10n;
use crate::ops::CloseAccount;
use crate::ops::SignOut;
use crate::state::remember;
use crate::theme;

/// Appearance and account actions.
#[component]
pub fn Page() -> Element {
	let l10n = use_l10n();
	let notice = remember("settings.notice", String::new);
	let confirmation = remember("settings.confirmation", String::new);
	let confirm_open = remember("settings.confirm_open", || false);
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
		<chrome::Page>
			<chrome::Heading text=l10n.settings_title() body=l10n.settings_subtitle() />
			// The app follows the device's light or dark setting on every
			// platform; LeptosKit has no way yet to pin one from the app.
			<chrome::Card seed=601>
				<chrome::Title text=l10n.appearance_title() />
				<chrome::ProofRow
					text=l10n.appearance_system()
					outcome=Outcome::Done
					detail=l10n.appearance_system_subtitle()
					seed=603
				/>
			</chrome::Card>
			<chrome::Card seed=605>
				<chrome::Title text=l10n.settings_account_title() />
				<chrome::Muted text=l10n.settings_sign_out_subtitle() />
				<chrome::Quiet
					label=l10n.settings_sign_out()
					disabled=sign_out.is_pending()
					on_press=move || sign_out.mutate(SignOut {})
					seed=607
				/>
				<chrome::Muted text=l10n.settings_close_account_subtitle() />
				<chrome::Quiet
					label=l10n.settings_close_account()
					on_press=move || confirm_open.set(true)
					seed=609
				/>
			</chrome::Card>
			{Show(
				move || confirm_open.get(),
				move || {
					view! {
						<chrome::Card seed=611>
							<chrome::Title text=l10n.settings_close_account_dialog_title() />
							<chrome::Body text=l10n.settings_close_account_dialog_body() />
							<chrome::Field
								label=l10n.settings_close_account_confirmation_label()
								value=confirmation.get()
								on_change=move |next| confirmation.set(next.to_owned())
								seed=613
							/>
							<View class=theme::ROW>
								<chrome::Quiet
									label=l10n.settings_close_account_confirm()
									disabled=close.is_pending()
									on_press=move || {
										let phrase = confirmation.get();
										if phrase.trim().is_empty() {
											return;
										}
										close.mutate(CloseAccount {
											confirmation: phrase,
										});
									}
									seed=615
								/>
								<chrome::Quiet
									label=l10n.dialog_cancel()
									on_press=move || confirm_open.set(false)
									seed=617
								/>
							</View>
						</chrome::Card>
					}
				},
			)}
			{Show(
				move || !notice.get().is_empty(),
				move || view! { <chrome::Body text=notice.get() /> },
			)}
		</chrome::Page>
	}
}
