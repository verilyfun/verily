//! Your page, `/me`: the payout wallet, attempts, payouts, appeals, and the
//! way into reviewing and settings.
//!
//! The wallet card does not show an address, a key, or a signature.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::QueryHandle;
use leptoskit::query::use_mutation;
use leptoskit::rpc::FnError;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::sketches;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::AttemptRow;
use crate::model::AttemptStatus;
use crate::model::PayoutRow;
use crate::model::PayoutStatus;
use crate::model::WalletLink;
use crate::ops::ListMyAttempts;
use crate::ops::ListMyPayouts;
use crate::ops::SubmitAppeal;
use crate::ops::WalletStatus;
use crate::routes::Navigation;
use crate::routes::Route;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;

/// Attempts, payouts, the wallet card, and the links out.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let attempts = use_rpc_query(|| ListMyAttempts {});
	let payouts = use_rpc_query(|| ListMyPayouts {});
	let wallet = use_rpc_query(|| WalletStatus {});
	let review = navigation.clone();
	let settings = navigation.clone();
	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.me_title() body=l10n.me_subtitle() />
			<WalletCard wallet=wallet />
			<View class=theme::STACK>
				<chrome::Title text=l10n.me_attempts_title() />
				{Show(
					move || attempts.is_loading(),
					move || view! { <chrome::Loading text=l10n.me_loading_attempts() /> },
				)}
				{Show(
					move || attempts.is_error(),
					move || {
						view! {
							<chrome::Failed
								title=l10n.me_load_failed_title()
								retry=l10n.dialog_retry()
								on_retry=move || {
									attempts.refetch();
								}
							/>
						}
					},
				)}
				{Show(
					move || attempts.data().is_some_and(|rows| rows.is_empty()),
					move || view! { <chrome::Muted text=l10n.me_attempts_empty() /> },
				)}
				{For(
					move || attempts.data().unwrap_or_default(),
					|row: &AttemptRow| row.id.clone(),
					|row| view! { <AttemptCard row=row /> },
				)}
			</View>
			<View class=theme::STACK>
				<chrome::Title text=l10n.me_payouts_title() />
				{Show(
					move || payouts.is_loading(),
					move || view! { <chrome::Loading text=l10n.me_loading_payouts() /> },
				)}
				{Show(
					move || payouts.data().is_some_and(|rows| rows.is_empty()),
					move || view! { <chrome::Muted text=l10n.me_payouts_empty() /> },
				)}
				{For(
					move || payouts.data().unwrap_or_default(),
					|row: &PayoutRow| row.id.clone(),
					|row| view! { <PayoutCard row=row /> },
				)}
			</View>
			<AppealForm />
			<View class=theme::ROW>
				<chrome::Quiet
					label=l10n.me_link_review()
					on_press=move || review.navigate(Route::Reviews)
					seed=401
				/>
				<chrome::Quiet
					label=l10n.settings_title()
					on_press=move || settings.navigate(Route::Settings)
					seed=403
				/>
			</View>
		</chrome::Page>
	}
}

/// Where rewards go: linked or not, in plain words.
#[component]
fn WalletCard(wallet: QueryHandle<WalletLink, FnError>) -> Element {
	let l10n = use_l10n();
	view! {
		<chrome::RoleCard role=Role::Reward seed=405>
			<View class="flex flex-row items-center gap-3">
				{sketches::coin(32.0, 407)} <chrome::Title text=l10n.me_wallet_title() />
			</View>
			{Show(
				move || wallet.data().is_some_and(|link| link.linked),
				move || {
					view! {
						<View class=theme::STACK>
							<chrome::Body text=l10n.me_wallet_linked() />
							<chrome::Muted text=l10n.me_wallet_linked_body() />
						</View>
					}
				},
			)}
			{Show(
				move || wallet.data().is_none_or(|link| !link.linked),
				move || {
					view! {
						<View class=theme::STACK>
							<chrome::Body text=l10n.me_wallet_unlinked_title() />
							<chrome::Muted text=l10n.me_wallet_unlinked_body() />
						</View>
					}
				},
			)}
		</chrome::RoleCard>
	}
}

/// One attempt. A verified one gets the stamp; one with a person says so in
/// violet; the rest say where they are in words.
#[component]
fn AttemptCard(row: AttemptRow) -> Element {
	let l10n = use_l10n();
	let seed = chrome::seed_for(&row.id);
	let words = match row.status {
		AttemptStatus::CollectingEvidence => l10n.attempt_status_collecting_evidence(),
		AttemptStatus::Verifying => l10n.attempt_status_verifying(),
		AttemptStatus::PendingReview => l10n.attempt_status_pending_review(),
		AttemptStatus::Verified => l10n.attempt_status_verified(),
		AttemptStatus::Rejected => l10n.attempt_status_rejected(),
		AttemptStatus::CapacityReached => l10n.attempt_status_capacity_reached(),
	};
	let status = match row.status {
		AttemptStatus::Verified => {
			view! {
				<View class="flex flex-row items-center gap-3">
					<View class="-rotate-[8deg]">{sketches::stamp(56.0, seed + 1)}</View>
					<chrome::Label text=words />
				</View>
			}
		}
		AttemptStatus::PendingReview => {
			view! { <chrome::Chip role=Role::Review text=words seed=seed + 1 /> }
		}
		_ => view! { <chrome::Muted text=l10n.do_your_attempt(words) /> },
	};
	view! {
		<chrome::Card seed=seed>
			<chrome::Title text=row.action_title />
			{status}
		</chrome::Card>
	}
}

/// One payout, with its amount next to a coin.
#[component]
fn PayoutCard(row: PayoutRow) -> Element {
	let l10n = use_l10n();
	let seed = chrome::seed_for(&row.id);
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
		<chrome::Card seed=seed>
			<chrome::Title text=row.action_title />
			<View class="flex flex-row items-center gap-3">
				{sketches::coin(28.0, seed + 1)}
				<chrome::Chip role=Role::Reward text=amount seed=seed + 2 />
			</View>
			<chrome::Muted text=status />
		</chrome::Card>
	}
}

/// Contest a decision: which attempt, and why.
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
		<chrome::RoleCard role=Role::Review seed=411>
			<chrome::Title text=l10n.me_appeal_title() />
			<chrome::Muted text=l10n.me_appeal_body() />
			<chrome::Field
				label=l10n.me_appeal_reason_hint()
				value=attempt_id.get()
				on_change=move |next| attempt_id.set(next.to_owned())
				seed=413
			/>
			<chrome::Field
				label=l10n.me_appeal_reason_label()
				value=reason.get()
				on_change=move |next| reason.set(next.to_owned())
				seed=415
			/>
			<chrome::Quiet
				label=l10n.me_appeal_send()
				disabled=submit.is_pending()
				on_press=move || {
					if attempt_id.get().trim().is_empty() || reason.get().trim().is_empty() {
						return;
					}
					submit.mutate(SubmitAppeal {
						attempt_id: attempt_id.get(),
						reason: reason.get(),
					});
				}
				seed=417
			/>
			{Show(
				move || sent.get(),
				move || view! { <chrome::Body text=l10n.me_appeal_sent() /> },
			)}
		</chrome::RoleCard>
	}
}
