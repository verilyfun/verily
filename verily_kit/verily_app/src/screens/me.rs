//! Me: attempts, payouts, and whether a wallet is linked.
//!
//! The wallet card does not show an address, a key, or a signature.

use leptoskit::prelude::Button;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Get;
use leptoskit::prelude::RwSignal;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::Text;
use leptoskit::prelude::TextInput;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::AttemptRow;
use crate::model::AttemptStatus;
use crate::model::PayoutRow;
use crate::model::PayoutStatus;
use crate::ops::ListMyAttempts;
use crate::ops::ListMyPayouts;
use crate::ops::SubmitAppeal;
use crate::ops::WalletStatus;
use crate::route::AppRoute;
use crate::route::Navigation;
use crate::theme;

/// Attempts, payouts, the wallet card, and the way into review and settings.
pub fn me(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let attempts = use_rpc_query(|| ListMyAttempts {});
	let payouts = use_rpc_query(|| ListMyPayouts {});
	let wallet = use_rpc_query(|| WalletStatus {});
	let navigation = navigation.clone();
	View()
		.class("flex flex-col gap-4")
		.child(chrome::title(l10n.me_title()))
		.child(chrome::muted(l10n.me_subtitle()))
		.child(wallet_card(wallet))
		.child(chrome::title(l10n.me_attempts_title()))
		.child(Show(
			move || attempts.is_loading(),
			move || chrome::muted(l10n.me_loading_attempts()),
		))
		.child(Show(
			move || attempts.is_error(),
			move || chrome::title(l10n.me_load_failed_title()),
		))
		.child(Show(
			move || attempts.data().is_some_and(|rows| rows.is_empty()),
			move || chrome::muted(l10n.me_attempts_empty()),
		))
		.child(For(
			move || attempts.data().unwrap_or_default(),
			|row: &AttemptRow| row.id.clone(),
			|row| attempt_row(row),
		))
		.child(appeal())
		.child(chrome::title(l10n.me_payouts_title()))
		.child(Show(
			move || payouts.is_loading(),
			move || chrome::muted(l10n.me_loading_payouts()),
		))
		.child(Show(
			move || payouts.data().is_some_and(|rows| rows.is_empty()),
			move || chrome::muted(l10n.me_payouts_empty()),
		))
		.child(For(
			move || payouts.data().unwrap_or_default(),
			|row: &PayoutRow| row.id.clone(),
			|row| payout_row(row),
		))
		.child(
			View()
				.class(theme::ROW)
				.child(
					Button(l10n.me_link_review().to_owned())
						.class(theme::QUIET)
						.on_press({
							let navigation = navigation.clone();
							move || navigation.navigate(AppRoute::Review)
						}),
				)
				.child(
					Button(l10n.settings_title().to_owned())
						.class(theme::QUIET)
						.on_press(move || navigation.navigate(AppRoute::Settings)),
				),
		)
}

fn wallet_card(
	wallet: leptoskit::query::QueryHandle<crate::model::WalletLink, leptoskit::rpc::FnError>,
) -> Element {
	let l10n = use_l10n();
	View()
		.class(theme::REWARD)
		.child(Text(l10n.me_wallet_title()).class("font-semibold"))
		.child(Show(
			move || wallet.data().is_some_and(|link| link.linked),
			move || {
				View()
					.class("flex flex-col gap-2")
					.child(chrome::muted(l10n.me_wallet_linked()))
					.child(chrome::muted(l10n.me_wallet_linked_body()))
			},
		))
		.child(Show(
			move || wallet.data().is_some_and(|link| !link.linked) || wallet.data().is_none(),
			move || {
				View()
					.class("flex flex-col gap-2")
					.child(chrome::muted(l10n.me_wallet_unlinked_title()))
					.child(chrome::muted(l10n.me_wallet_unlinked_body()))
			},
		))
}

fn attempt_row(row: AttemptRow) -> Element {
	let l10n = use_l10n();
	let status = match row.status {
		AttemptStatus::CollectingEvidence => l10n.attempt_status_collecting_evidence(),
		AttemptStatus::Verifying => l10n.attempt_status_verifying(),
		AttemptStatus::PendingReview => l10n.attempt_status_pending_review(),
		AttemptStatus::Verified => l10n.attempt_status_verified(),
		AttemptStatus::Rejected => l10n.attempt_status_rejected(),
		AttemptStatus::CapacityReached => l10n.attempt_status_capacity_reached(),
	};
	View()
		.class(theme::CARD)
		.child(Text(row.action_title).class("font-semibold"))
		.child(chrome::muted(l10n.do_your_attempt(status)))
}

fn payout_row(row: PayoutRow) -> Element {
	let l10n = use_l10n();
	let amount = row.amount_label.as_str();
	let status = match row.status {
		PayoutStatus::AwaitingWallet => l10n.payout_awaiting_wallet(amount),
		PayoutStatus::OnItsWay => l10n.payout_on_its_way(amount),
		PayoutStatus::Released => l10n.payout_released(amount),
		PayoutStatus::HeldForReview => l10n.payout_held_for_review(amount),
		PayoutStatus::Failed => l10n.payout_failed(amount),
		PayoutStatus::Expired => l10n.payout_expired(amount),
	};
	View()
		.class(theme::CARD)
		.child(Text(row.action_title).class("font-semibold"))
		.child(chrome::muted(row.amount_label))
		.child(chrome::muted(status))
}

fn appeal() -> Element {
	let l10n = use_l10n();
	let attempt_id = RwSignal::new(String::new());
	let reason = RwSignal::new(String::new());
	let sent = RwSignal::new(false);
	let submit = use_mutation(mutation_scope::<SubmitAppeal>().with_on_success(move |_| {
		sent.set(true);
	}));
	View()
		.class(theme::CARD)
		.child(chrome::title(l10n.me_appeal_title()))
		.child(chrome::muted(l10n.me_appeal_body()))
		.child(
			TextInput()
				.class(theme::FIELD)
				.placeholder(l10n.me_appeal_reason_hint())
				.on_change(move |next| attempt_id.set(next.to_owned())),
		)
		.child(
			TextInput()
				.class(theme::FIELD)
				.placeholder(l10n.me_appeal_reason_label())
				.on_change(move |next| reason.set(next.to_owned())),
		)
		.child(
			Button(l10n.me_appeal_send().to_owned())
				.class(theme::QUIET)
				.on_press(move || {
					if attempt_id.get().trim().is_empty() || reason.get().trim().is_empty() {
						return;
					}
					submit.mutate(SubmitAppeal {
						attempt_id: attempt_id.get(),
						reason: reason.get(),
					});
				}),
		)
		.child(Show(
			move || sent.get(),
			move || chrome::muted(l10n.me_appeal_sent()),
		))
}
