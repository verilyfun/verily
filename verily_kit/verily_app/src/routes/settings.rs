//! Appearance and account, `/settings`.
//!
//! Nothing on this screen is a token, a key, or a chain address.

use leptoskit::appearance::Appearance;
use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::View;
use leptoskit::query::MutateCallbacks;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::view;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::ops::CloseAccount;
use crate::routes::Navigation;
use crate::state::mutation;
use crate::state::remember;
use crate::theme;

/// Appearance and account actions.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let _ = navigation;
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
		<View class="flex flex-col gap-6">
			<View class=theme::STACK.as_str()>
				<chrome::Display text=l10n.settings_title() />
				<chrome::Body text=l10n.settings_subtitle() />
			</View>
			<chrome::Card seed=231>
				<chrome::Title text=l10n.appearance_title() />
				<chrome::Muted text=l10n.appearance_subtitle() />
				<AppearanceChoices />
			</chrome::Card>
			<chrome::Card seed=233>
				<chrome::Title text=l10n.settings_account_title() />
				<chrome::Muted text=l10n.settings_sign_out_subtitle() />
				<chrome::Quiet
					label=l10n.settings_sign_out()
					seed=235
					on_press=sign_out_now
				/>
				<chrome::Muted text=l10n.settings_close_account_subtitle() />
				<chrome::Quiet
					label=l10n.settings_close_account()
					seed=237
					on_press=move || confirm_open.set(true)
				/>
			</chrome::Card>
			{(confirm_open.get()).then(|| {
					view! {
						<chrome::Card seed=239>
							<chrome::Title text=l10n.settings_close_account_dialog_title() />
							<chrome::Body text=l10n.settings_close_account_dialog_body() />
							<chrome::Field
								label=l10n.settings_close_account_confirmation_label()
								value=confirmation.get()
								seed=241
								on_change=move |next: &str| confirmation.set(next.to_owned())
							/>
							<View class=theme::ROW.as_str()>
								<chrome::Choice
									label=l10n.settings_close_account_confirm()
									selected=true
									seed=243
									on_press=move || {
										let phrase = confirmation.get();
										if phrase.trim().is_empty() {
											return;
										}
										close.mutate(CloseAccount {
											confirmation: phrase,
										});
									}
								/>
								<chrome::Quiet
									label=l10n.dialog_cancel()
									seed=245
									on_press=move || confirm_open.set(false)
								/>
							</View>
						</chrome::Card>
					}
				})}
			{(!notice.get().is_empty()).then(|| view! { <chrome::Body text=notice.get() /> })}
		</View>
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
					seed=251 + index as i64 * 2
					on_press=move || leptoskit::appearance::set(appearance)
				/>
			}
		})
		.collect::<Vec<_>>();
	view! {
		<View class=theme::STACK.as_str()>
			<View class=theme::ROW.as_str()>{buttons}</View>
			<chrome::Muted text=current />
		</View>
	}
}
