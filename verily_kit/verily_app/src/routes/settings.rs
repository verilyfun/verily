//! Appearance and account, `/settings`.
//!
//! Nothing on this screen is a token, a key, or a chain address.

use leptoskit::appearance::Appearance;
use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::MutateCallbacks;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::view;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::ops::CloseAccount;
use crate::state::mutation;
use crate::state::remember;
use crate::theme;

/// Appearance and account actions.
#[component]
pub fn Page() -> Element {
	let l10n = use_l10n();
	let notice = remember("settings.notice", String::new);
	let confirmation = remember("settings.confirmation", String::new);
	let confirm_open = remember("settings.confirm_open", || false);
	// Signing out empties the session query, so the app shows sign-in.
	let sign_out = mutation(
		"settings.sign_out",
		leptoskit::auth::client::sign_out_mutation(),
	);
	let sign_out_now = move || {
		sign_out.mutate_with(
			(),
			MutateCallbacks::new().on_error(move |_| {
				notice.set(l10n.settings_sign_out_failed().to_owned());
			}),
		);
	};
	let close = mutation(
		"settings.close",
		mutation_scope::<CloseAccount>()
			.with_on_success(move |_| {
				// The server ended every session; forget this one too.
				confirm_open.set(false);
				sign_out_now();
			})
			.with_on_error(move |_| {
				notice.set(l10n.settings_close_account_failed().to_owned());
			}),
	);

	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.settings_title() body=l10n.settings_subtitle() />
			<chrome::Card seed=601>
				<chrome::Title text=l10n.appearance_title() />
				<chrome::Muted text=l10n.appearance_subtitle() />
				<AppearanceChoices />
			</chrome::Card>
			<chrome::Card seed=605>
				<chrome::Title text=l10n.settings_account_title() />
				<chrome::Muted text=l10n.settings_sign_out_subtitle() />
				<chrome::Quiet
					label=l10n.settings_sign_out()
					disabled=sign_out.is_pending()
					on_press=sign_out_now
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

/// Match device, Light, or Dark. Every `dark:` class, Skribble's ink
/// included, follows the choice.
#[component]
fn AppearanceChoices() -> Element {
	let l10n = use_l10n();
	let chosen = leptoskit::appearance::get();
	let choices = [
		(
			Appearance::System,
			l10n.appearance_system(),
			l10n.appearance_system_subtitle(),
		),
		(
			Appearance::Light,
			l10n.appearance_light(),
			l10n.appearance_light_subtitle(),
		),
		(
			Appearance::Dark,
			l10n.appearance_dark(),
			l10n.appearance_dark_subtitle(),
		),
	];
	let current = choices
		.iter()
		.find(|(appearance, _, _)| *appearance == chosen)
		.map_or_else(String::new, |(_, _, about)| (*about).to_owned());
	let buttons = choices
		.into_iter()
		.enumerate()
		.map(|(index, (appearance, label, _))| {
			view! {
				<chrome::Choice
					label=label
					selected=appearance == chosen
					seed=651 + index as i64 * 2
					on_press=move || leptoskit::appearance::set(appearance)
				/>
			}
		})
		.collect::<Vec<_>>();
	view! {
		<View class=theme::STACK>
			<View class=theme::ROW>{buttons}</View>
			<chrome::Muted text=current />
		</View>
	}
}
