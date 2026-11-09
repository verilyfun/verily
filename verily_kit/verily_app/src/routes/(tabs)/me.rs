//! Attempts and payouts, `/me`.
//!
//! The wallet card does not show an address, a key, or a signature.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::draw;

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
use crate::routes::Navigation;
use crate::routes::Route;
use crate::state::remember;
use crate::theme;

/// Attempts, payouts, the wallet card, and the way into review and settings.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let attempts = use_rpc_query(|| ListMyAttempts {});
	let payouts = use_rpc_query(|| ListMyPayouts {});
	let wallet = use_rpc_query(|| WalletStatus {});
	let review = navigation.clone();
	let settings = navigation.clone();
	view! {
		<View class="flex flex-col gap-6">
			<View class=theme::STACK.as_str()>
				<chrome::Display text=l10n.me_title() />
				<chrome::Body text=l10n.me_subtitle() />
			</View>
			<WalletCard wallet=wallet />
			<View class=theme::STACK.as_str()>
				<chrome::Title text=l10n.me_attempts_title() />
				{(attempts.is_loading()).then(|| view! { <chrome::Muted text=l10n.me_loading_attempts() /> })}
				{(attempts.is_error()).then(|| view! { <chrome::Muted text=l10n.me_load_failed_title() /> })}
				{(attempts.data().is_some_and(|rows| rows.is_empty())).then(|| view! { <chrome::Muted text=l10n.me_attempts_empty() /> })}
				<View class=theme::LIST.as_str()>{attempts.data().unwrap_or_default().into_iter().map(|row| view! { <AttemptTile row=row /> }).collect::<Vec<_>>()}</View>
			</View>
			<View class=theme::STACK.as_str()>
				<chrome::Title text=l10n.me_payouts_title() />
				{(payouts.is_loading()).then(|| view! { <chrome::Muted text=l10n.me_loading_payouts() /> })}
				{(payouts.data().is_some_and(|rows| rows.is_empty())).then(|| view! { <chrome::Muted text=l10n.me_payouts_empty() /> })}
				<View class=theme::LIST.as_str()>{payouts.data().unwrap_or_default().into_iter().map(|row| view! { <PayoutTile row=row /> }).collect::<Vec<_>>()}</View>
			</View>
			<AppealForm />
			<View class=theme::ROW.as_str()>
				<chrome::Quiet
					label=l10n.me_link_review()
					seed=171
					on_press=move || review.navigate(Route::Review)
				/>
				<chrome::Quiet
					label=l10n.settings_title()
					seed=173
					on_press=move || settings.navigate(Route::Settings)
				/>
			</View>
		</View>
	}
}

#[component]
fn WalletCard(
	wallet: leptoskit::query::QueryHandle<crate::model::WalletLink, leptoskit::rpc::FnError>,
) -> Element {
	let l10n = use_l10n();
	let linked = wallet.data().is_some_and(|link| link.linked);
	let (title, body) = if linked {
		(l10n.me_wallet_linked(), l10n.me_wallet_linked_body())
	} else {
		(
			l10n.me_wallet_unlinked_title(),
			l10n.me_wallet_unlinked_body(),
		)
	};
	view! {
		<chrome::Card seed=175>
			<View class=theme::LINE.as_str()>
				{draw::coin(28.0, 177)}
				<chrome::Title text=l10n.me_wallet_title() />
			</View>
			<chrome::Body text=title />
			<chrome::Muted text=body />
		</chrome::Card>
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
	let verified = matches!(row.status, AttemptStatus::Verified);
	let with_person = matches!(row.status, AttemptStatus::PendingReview);
	let status = l10n.do_your_attempt(status);
	let seed = 181 + row.id.len() as i64;
	let badge = if verified {
		Some(draw::stamp(56.0, seed + 1))
	} else {
		None
	};
	let status = if with_person {
		view! { <chrome::ReviewChip text=status seed=seed + 3 /> }
	} else {
		view! { <chrome::Muted text=status /> }
	};
	view! {
		<chrome::Card seed=seed>
			<View class="flex flex-row items-center justify-between gap-3">
				<View class="flex flex-1 flex-col gap-2">
					<chrome::Title text=row.action_title />
					{status}
				</View>
				{badge}
			</View>
		</chrome::Card>
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
	let seed = 191 + row.id.len() as i64;
	view! {
		<chrome::Card seed=seed>
			<chrome::Title text=row.action_title />
			<chrome::RewardChip label=amount detail=status seed=seed + 1 />
		</chrome::Card>
	}
}

#[component]
fn AppealForm() -> Element {
	let l10n = use_l10n();
	let attempt_id = remember("me.appeal.attempt", String::new);
	let reason = remember("me.appeal.reason", String::new);
	let sent = remember("me.appeal.sent", || false);
	let submit = use_mutation(mutation_scope::<SubmitAppeal>().with_on_success(move |_| {
		sent.set(true);
	}));
	view! {
		<chrome::Card seed=201>
			<chrome::Title text=l10n.me_appeal_title() />
			<chrome::Muted text=l10n.me_appeal_body() />
			<chrome::Field
				label=l10n.me_appeal_reason_hint()
				value=attempt_id.get()
				seed=203
				on_change=move |next: &str| attempt_id.set(next.to_owned())
			/>
			<chrome::Field
				label=l10n.me_appeal_reason_label()
				value=reason.get()
				seed=205
				on_change=move |next: &str| reason.set(next.to_owned())
			/>
			<chrome::Quiet
				label=l10n.me_appeal_send()
				seed=207
				on_press=move || {
					if attempt_id.get().trim().is_empty() || reason.get().trim().is_empty() {
						return;
					}
					submit.mutate(SubmitAppeal {
						attempt_id: attempt_id.get(),
						reason: reason.get(),
					});
				}
			/>
			{(sent.get()).then(|| view! { <chrome::ReviewChip text=l10n.me_appeal_sent() seed=209 /> })}
		</chrome::Card>
	}
}
