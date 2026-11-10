//! Signing in: an emailed code, and the authenticator code when the account
//! has two-step verification.
//!
//! The behaviour is `leptoskit::auth::client`'s; this is only the page. A
//! successful step updates the session query, and the root layout swaps this
//! page for the app.

use leptoskit::auth::ErrorResponse;
use leptoskit::auth::PublicSession;
use leptoskit::auth::client::EmailCode;
use leptoskit::auth::client::SignInStep;
use leptoskit::auth::client::complete_sign_in;
use leptoskit::auth::client::send_code;
use leptoskit::auth::client::verify_code;
use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::View;
use leptoskit::query::MutateCallbacks;
use leptoskit::view;
use skribble_leptoskit::SkribblePage;

use crate::chrome;
use crate::l10n::L10n;
use crate::l10n::use_l10n;
use crate::state::mutation;
use crate::state::remember;
use crate::theme;

/// Where signing in has got to.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum Step {
	/// Asking for the address.
	Email,
	/// A code was emailed; asking for it.
	Code,
	/// The account has two-step verification; asking for that code.
	SecondFactor,
}

/// What to say about a failed step, in product language.
pub(crate) fn problem(l10n: &L10n, error: &ErrorResponse) -> String {
	match error.error.as_str() {
		"invalid_email" => l10n.sign_in_email_invalid().to_owned(),
		"invalid_code" | "sign_in_expired" => l10n.sign_in_code_invalid().to_owned(),
		"rate_limited" => l10n.sign_in_rate_limited().to_owned(),
		"config" | "unsupported" => l10n.sign_in_unavailable().to_owned(),
		_ => l10n.sign_in_failed().to_owned(),
	}
}

/// The sign-in page on the notebook's paper.
pub(crate) fn page() -> Element {
	view! {
		<SkribblePage theme=theme::PEN class=theme::PAGE>
			<SignIn />
		</SkribblePage>
	}
}

/// While the session query answers: the mark and one quiet line.
pub(crate) fn checking() -> Element {
	let l10n = use_l10n();
	view! {
		<SkribblePage theme=theme::PEN class=theme::PAGE>
			<View class="flex flex-col items-center gap-4 pt-24">
				{verily_ink::mark(64.0, Some("Verily"))}
				<chrome::Muted text=l10n.sign_in_checking() />
			</View>
		</SkribblePage>
	}
}

/// The sign-in page.
#[component]
pub fn SignIn() -> Element {
	let l10n = use_l10n();
	let step = remember("sign_in.step", || Step::Email);
	let email = remember("sign_in.email", String::new);
	let code = remember("sign_in.code", String::new);
	let notice = remember("sign_in.notice", String::new);
	let send = mutation("sign_in.send", send_code());
	let verify = mutation("sign_in.verify", verify_code());
	let finish = mutation("sign_in.finish", complete_sign_in());
	let working = send.is_pending() || verify.is_pending() || finish.is_pending();

	let form = match step.get() {
		Step::Email => view! {
			<View class=theme::STACK>
				<chrome::Title text=l10n.sign_in_email_title() />
				<chrome::Field
					label=l10n.sign_in_email_label()
					value=email.get()
					placeholder=l10n.sign_in_email_hint()
					seed=303
					on_change=move |next: &str| {
						if !working {
							email.set(next.trim().to_owned());
						}
					}
				/>
				<chrome::Primary
					label=l10n.sign_in_send_code()
					disabled=working || email.get().is_empty()
					seed=305
					on_press=move || {
						let address = email.get();
						if address.is_empty() {
							return;
						}
						notice.set(String::new());
						send.mutate_with(
							address,
							MutateCallbacks::new()
								.on_success(move |_| {
									code.set(String::new());
									step.set(Step::Code);
								})
								.on_error(move |args| notice.set(problem(&l10n, &args.error))),
						);
					}
				/>
			</View>
		},
		Step::Code => view! {
			<View class=theme::STACK>
				<chrome::Title text=l10n.sign_in_email_title() />
				<chrome::Body text=l10n.sign_in_code_sent(&email.get()) />
				<chrome::Field
					label=l10n.sign_in_code_label()
					value=code.get()
					seed=307
					on_change=move |next: &str| code.set(next.trim().to_owned())
				/>
				<chrome::Primary
					label=l10n.sign_in_verify()
					disabled=working || code.get().is_empty()
					seed=309
					on_press=move || {
						let typed = code.get();
						if typed.is_empty() {
							return;
						}
						notice.set(String::new());
						verify.mutate_with(
							EmailCode {
								email: email.get(),
								code: typed,
							},
							MutateCallbacks::new()
								.on_success(move |args| {
									if let SignInStep::SecondFactor(_) = args.data {
										code.set(String::new());
										step.set(Step::SecondFactor);
									}
								})
								.on_error(move |args| notice.set(problem(&l10n, &args.error))),
						);
					}
				/>
				<chrome::Quiet
					label=l10n.sign_in_other_email()
					disabled=working
					seed=311
					on_press=move || {
						notice.set(String::new());
						step.set(Step::Email);
					}
				/>
			</View>
		},
		Step::SecondFactor => view! {
			<View class=theme::STACK>
				<chrome::Title text=l10n.sign_in_email_title() />
				<chrome::Body text=l10n.sign_in_second_factor_prompt() />
				<chrome::Field
					label=l10n.sign_in_second_factor_label()
					value=code.get()
					seed=313
					on_change=move |next: &str| code.set(next.trim().to_owned())
				/>
				<chrome::Primary
					label=l10n.sign_in_verify()
					disabled=working || code.get().is_empty()
					seed=315
					on_press=move || {
						let typed = code.get();
						if typed.is_empty() {
							return;
						}
						notice.set(String::new());
						finish.mutate_with(
							typed,
							MutateCallbacks::<String, PublicSession, ErrorResponse>::new().on_error(move |args| {
								if args.error.error == "sign_in_expired" {
									step.set(Step::Email);
								}
								notice.set(problem(&l10n, &args.error));
							}),
						);
					}
				/>
			</View>
		},
	};

	view! {
		<View class="w-full max-w-md self-center flex flex-col gap-6 pt-6">
			<View class="flex flex-col items-center gap-4">
				{verily_ink::mark(88.0, Some("Verily"))}
				<chrome::Display text=l10n.welcome_title() />
				<chrome::Body text=l10n.sign_in_subtitle() />
			</View>
			<chrome::Card seed=317>
				{form}
				{(!notice.get().is_empty()).then(|| view! { <chrome::Body text=notice.get() /> })}
			</chrome::Card>
		</View>
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	fn error(code: &str) -> ErrorResponse {
		serde_json::from_value(serde_json::json!({ "error": code, "message": "" }))
			.expect("an error response")
	}

	#[test]
	fn problems_are_said_in_product_language() {
		let l10n = L10n::new(&[]);
		assert_eq!(
			problem(&l10n, &error("invalid_email")),
			l10n.sign_in_email_invalid()
		);
		assert_eq!(
			problem(&l10n, &error("invalid_code")),
			l10n.sign_in_code_invalid()
		);
		assert_eq!(
			problem(&l10n, &error("sign_in_expired")),
			l10n.sign_in_code_invalid()
		);
		assert_eq!(
			problem(&l10n, &error("rate_limited")),
			l10n.sign_in_rate_limited()
		);
		assert_eq!(problem(&l10n, &error("config")), l10n.sign_in_unavailable());
		assert_eq!(problem(&l10n, &error("server")), l10n.sign_in_failed());
	}
}
