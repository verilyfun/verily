//! Me: attempts, payouts, and whether a wallet is linked.
//!
//! The wallet card does not show an address, a key, or a signature.

use leptoskit::component;
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
use leptoskit::view;

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
#[component]
pub fn Me(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let attempts = use_rpc_query(|| ListMyAttempts {});
	let payouts = use_rpc_query(|| ListMyPayouts {});
	let wallet = use_rpc_query(|| WalletStatus {});
	let review = navigation.clone();
	let settings = navigation.clone();
	view! {
		<View class="flex flex-col gap-4">
			<chrome::Title text=l10n.me_title() />
			<chrome::Muted text=l10n.me_subtitle() />
			<WalletCard wallet=wallet />
			<chrome::Title text=l10n.me_attempts_title() />
			{Show(
				move || attempts.is_loading(),
				move || view! { <chrome::Muted text=l10n.me_loading_attempts() /> },
			)}
			{Show(
				move || attempts.is_error(),
				move || view! { <chrome::Title text=l10n.me_load_failed_title() /> },
			)}
			{Show(
				move || attempts.data().is_some_and(|rows| rows.is_empty()),
				move || view! { <chrome::Muted text=l10n.me_attempts_empty() /> },
			)}
			{For(
				move || attempts.data().unwrap_or_default(),
				|row: &AttemptRow| row.id.clone(),
				|row| view! { <AttemptTile row=row /> },
			)}
			<AppealForm />
			<chrome::Title text=l10n.me_payouts_title() />
			{Show(
				move || payouts.is_loading(),
				move || view! { <chrome::Muted text=l10n.me_loading_payouts() /> },
			)}
			{Show(
				move || payouts.data().is_some_and(|rows| rows.is_empty()),
				move || view! { <chrome::Muted text=l10n.me_payouts_empty() /> },
			)}
			{For(
				move || payouts.data().unwrap_or_default(),
				|row: &PayoutRow| row.id.clone(),
				|row| view! { <PayoutTile row=row /> },
			)}
			<View class=theme::ROW>
				<Button class=theme::QUIET on:press=move || review.navigate(AppRoute::Review)>
					{l10n.me_link_review()}
				</Button>
				<Button class=theme::QUIET on:press=move || settings.navigate(AppRoute::Settings)>
					{l10n.settings_title()}
				</Button>
			</View>
		</View>
	}
}

#[component]
fn WalletCard(
	wallet: leptoskit::query::QueryHandle<crate::model::WalletLink, leptoskit::rpc::FnError>,
) -> Element {
	let l10n = use_l10n();
	view! {
		<View class=theme::REWARD>
			<Text class="font-semibold">{l10n.me_wallet_title()}</Text>
			{Show(
				move || wallet.data().is_some_and(|link| link.linked),
				move || {
					view! {
						<View class="flex flex-col gap-2">
							<chrome::Muted text=l10n.me_wallet_linked() />
							<chrome::Muted text=l10n.me_wallet_linked_body() />
						</View>
					}
				},
			)}
			{Show(
				move || wallet.data().is_some_and(|link| !link.linked) || wallet.data().is_none(),
				move || {
					view! {
						<View class="flex flex-col gap-2">
							<chrome::Muted text=l10n.me_wallet_unlinked_title() />
							<chrome::Muted text=l10n.me_wallet_unlinked_body() />
						</View>
					}
				},
			)}
		</View>
	}
}

#[component]
fn AttemptTile(row: AttemptRow) -> Element {
	let l10n = use_l10n();
	let status = match row.status {
		AttemptStatus::CollectingEvidence => l10n.attempt_status_collecting_evidence(),
		AttemptStatus::Verifying => l10n.attempt_status_verifying(),
		AttemptStatus::PendingReview => l10n.attempt_status_pending_review(),
		AttemptStatus::Verified => l10n.attempt_status_verified(),
		AttemptStatus::Rejected => l10n.attempt_status_rejected(),
		AttemptStatus::CapacityReached => l10n.attempt_status_capacity_reached(),
	};
	let status = l10n.do_your_attempt(status);
	view! {
		<View class=theme::CARD>
			<Text class="font-semibold">{row.action_title}</Text>
			<chrome::Muted text=status />
		</View>
	}
}

#[component]
fn PayoutTile(row: PayoutRow) -> Element {
	let l10n = use_l10n();
	let amount = row.amount_label.clone();
	let status = match row.status {
		PayoutStatus::AwaitingWallet => l10n.payout_awaiting_wallet(&amount),
		PayoutStatus::OnItsWay => l10n.payout_on_its_way(&amount),
		PayoutStatus::Released => l10n.payout_released(&amount),
		PayoutStatus::HeldForReview => l10n.payout_held_for_review(&amount),
		PayoutStatus::Failed => l10n.payout_failed(&amount),
		PayoutStatus::Expired => l10n.payout_expired(&amount),
	};
	view! {
		<View class=theme::CARD>
			<Text class="font-semibold">{row.action_title}</Text>
			<chrome::Muted text=amount />
			<chrome::Muted text=status />
		</View>
	}
}

#[component]
fn AppealForm() -> Element {
	let l10n = use_l10n();
	let attempt_id = RwSignal::new(String::new());
	let reason = RwSignal::new(String::new());
	let sent = RwSignal::new(false);
	let submit = use_mutation(mutation_scope::<SubmitAppeal>().with_on_success(move |_| {
		sent.set(true);
	}));
	view! {
		<View class=theme::CARD>
			<chrome::Title text=l10n.me_appeal_title() />
			<chrome::Muted text=l10n.me_appeal_body() />
			<TextInput
				class=theme::FIELD
				placeholder=l10n.me_appeal_reason_hint()
				on:change=move |next| attempt_id.set(next.to_owned())
			/>
			<TextInput
				class=theme::FIELD
				placeholder=l10n.me_appeal_reason_label()
				on:change=move |next| reason.set(next.to_owned())
			/>
			<Button
				class=theme::QUIET
				on:press=move || {
					if attempt_id.get().trim().is_empty() || reason.get().trim().is_empty() {
						return;
					}
					submit.mutate(SubmitAppeal {
						attempt_id: attempt_id.get(),
						reason: reason.get(),
					});
				}
			>
				{l10n.me_appeal_send()}
			</Button>
			{Show(
				move || sent.get(),
				move || view! { <chrome::Muted text=l10n.me_appeal_sent() /> },
			)}
		</View>
	}
}
