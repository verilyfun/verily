//! Settings: appearance, sign-out, and closing the account.
//!
//! Nothing on this screen is a token, a key, or a chain address.

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

use crate::chrome;
use crate::l10n::use_l10n;
use crate::ops::CloseAccount;
use crate::ops::SignOut;
use crate::route::Navigation;
use crate::theme;

/// Appearance and account actions.
pub fn settings(_navigation: &Navigation) -> Element {
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

	View()
		.class("flex flex-col gap-4")
		.child(chrome::title(l10n.settings_title()))
		.child(chrome::muted(l10n.settings_subtitle()))
		.child(chrome::title(l10n.appearance_title()))
		.child(chrome::muted(l10n.appearance_subtitle()))
		.child(
			View()
				.class(theme::ROW)
				.child(
					Button(l10n.appearance_system().to_owned())
						.class(theme::QUIET)
						.on_press(|| theme::install_paper()),
				)
				.child(
					Button(l10n.appearance_light().to_owned())
						.class(theme::QUIET)
						.on_press(|| theme::install_paper()),
				)
				.child(
					Button(l10n.appearance_dark().to_owned())
						.class(theme::QUIET)
						.on_press(|| theme::install_night()),
				),
		)
		.child(chrome::title(l10n.settings_account_title()))
		.child(chrome::muted(l10n.settings_sign_out_subtitle()))
		.child(
			Button(l10n.settings_sign_out().to_owned())
				.class(theme::QUIET)
				.on_press(move || {
					sign_out.mutate(SignOut {});
				}),
		)
		.child(chrome::muted(l10n.settings_close_account_subtitle()))
		.child(
			Button(l10n.settings_close_account().to_owned())
				.class(theme::PRIMARY)
				.on_press(move || confirm_open.set(true)),
		)
		.child(Show(
			move || confirm_open.get(),
			move || {
				View()
					.class(theme::CARD)
					.child(chrome::title(l10n.settings_close_account_dialog_title()))
					.child(chrome::muted(l10n.settings_close_account_dialog_body()))
					.child(chrome::muted(
						l10n.settings_close_account_confirmation_label(),
					))
					.child(
						TextInput()
							.class(theme::FIELD)
							.on_change(move |next| confirmation.set(next.to_owned())),
					)
					.child(
						View()
							.class(theme::ROW)
							.child(
								Button(l10n.settings_close_account_confirm().to_owned())
									.class(theme::PRIMARY)
									.on_press(move || {
										let phrase = confirmation.get();
										if phrase.trim().is_empty() {
											return;
										}
										close.mutate(CloseAccount {
											confirmation: phrase,
										});
									}),
							)
							.child(
								Button(l10n.dialog_cancel().to_owned())
									.class(theme::QUIET)
									.on_press(move || confirm_open.set(false)),
							),
					)
			},
		))
		.child(Show(
			move || !notice.get().is_empty(),
			move || chrome::muted(notice.get()),
		))
}
