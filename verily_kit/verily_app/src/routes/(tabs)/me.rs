//! Attempts and payouts, `/me`.
//!
//! The wallet card does not show an address, a key, or a signature.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::View;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::query_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::draw;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::AppealReceipt;
use crate::model::AppealStatus;
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
use crate::state::mutation;
use crate::state::remember;
use crate::theme;
use crate::wallet::LinkFault;
use crate::wallet::begin_link;
use crate::wallet::mobile_link_supported;

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
	let linking = remember("me.wallet.linking", || false);
	let fault = remember("me.wallet.fault", || None::<LinkFault>);
	let linked_here = remember("me.wallet.linked_here", || false);
	let linked = wallet.data().is_some_and(|link| link.linked) || linked_here.get();
	let busy = linking.get();
	let can_link = mobile_link_supported();
	let fault_line = fault.get().map(|fault| wallet_fault(&l10n, fault));
	let (title, body) = if linked {
		(l10n.me_wallet_linked(), l10n.me_wallet_linked_body())
	} else {
		(
			l10n.me_wallet_unlinked_title(),
			l10n.me_wallet_unlinked_body(),
		)
	};
	let label = if busy {
		l10n.me_wallet_linking()
	} else if linked {
		l10n.me_wallet_change()
	} else {
		l10n.me_wallet_link()
	};
	view! {
		<chrome::Card seed=175>
			<View class=theme::LINE.as_str()>
				{draw::coin(28.0, 177)}
				<chrome::Title text=l10n.me_wallet_title() />
			</View>
			<chrome::Body text=title />
			<chrome::Muted text=body />
			{(!can_link).then(|| view! { <chrome::Muted text=l10n.me_wallet_unsupported() /> })}
			{(can_link && !linked).then(move || view! {
				<chrome::Primary
					label=label
					seed=179
					disabled=busy
					on_press=move || press_wallet_link(linking, fault, linked_here, wallet)
				/>
			})}
			{(can_link && linked).then(move || view! {
				<chrome::Quiet
					label=label
					seed=179
					disabled=busy
					on_press=move || press_wallet_link(linking, fault, linked_here, wallet)
				/>
			})}
			{fault_line.map(|text| view! { <chrome::Muted text=text /> })}
		</chrome::Card>
	}
}

fn press_wallet_link(
	linking: leptoskit::prelude::RwSignal<bool>,
	fault: leptoskit::prelude::RwSignal<Option<LinkFault>>,
	linked_here: leptoskit::prelude::RwSignal<bool>,
	wallet: leptoskit::query::QueryHandle<crate::model::WalletLink, leptoskit::rpc::FnError>,
) {
	if linking.get() {
		return;
	}
	linking.set(true);
	fault.set(None);
	begin_link(move |result| {
		linking.set(false);
		match result {
			Ok(()) => {
				fault.set(None);
				linked_here.set(true);
				wallet.invalidate();
			}
			Err(error) => fault.set(Some(error)),
		}
	});
}

fn wallet_fault(l10n: &crate::l10n::L10n, fault: LinkFault) -> &'static str {
	match fault {
		LinkFault::Unsupported => l10n.me_wallet_unsupported(),
		LinkFault::Unavailable => l10n.me_wallet_failure_unavailable(),
		LinkFault::Cancelled => l10n.me_wallet_failure_cancelled(),
		LinkFault::TimedOut => l10n.me_wallet_failure_timed_out(),
		LinkFault::Invalid => l10n.me_wallet_failure_invalid_response(),
		LinkFault::WrongAccount => l10n.me_wallet_failure_wrong_account(),
		LinkFault::Failed => l10n.me_wallet_failure_failed(),
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
	let appeal = match row.appeal {
		AppealStatus::Available => Some(view! { <AppealForm attempt_id=row.id.clone() /> }),
		AppealStatus::Pending => {
			Some(view! { <chrome::ReviewChip text=l10n.me_appeal_pending() seed=seed + 5 /> })
		}
		AppealStatus::Accepted => Some(view! { <chrome::Muted text=l10n.me_appeal_accepted() /> }),
		AppealStatus::Rejected => Some(view! { <chrome::Muted text=l10n.me_appeal_rejected() /> }),
		AppealStatus::Unavailable => None,
	};
	view! {
		<chrome::Card seed=seed>
			<View class=theme::STACK.as_str()>
				<View class="flex flex-row items-center justify-between gap-3">
					<View class="flex flex-1 flex-col gap-2">
						<chrome::Title text=row.action_title />
						{status}
					</View>
					{badge}
				</View>
				{appeal}
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
fn AppealForm(attempt_id: String) -> Element {
	appeal_form(attempt_id, mutation_scope::<SubmitAppeal>())
}

fn appeal_form(
	attempt_id: String,
	scope: leptoskit::query::MutationScope<SubmitAppeal, AppealReceipt, leptoskit::rpc::FnError>,
) -> Element {
	let l10n = use_l10n();
	let key = format!("me.appeal.{attempt_id}");
	let reason = remember(&format!("{key}.reason"), String::new);
	let open = remember(&format!("{key}.open"), || false);
	let sent = remember(&format!("{key}.sent"), || false);
	let submit = mutation(
		&format!("{key}.submit"),
		scope.with_on_success_async(move |args| async move {
			sent.set(true);
			open.set(false);
			reason.set(String::new());
			args.client
				.invalidate_scope(&query_scope::<ListMyAttempts>())
				.await;
		}),
	);
	if sent.get() {
		return view! { <chrome::ReviewChip text=l10n.me_appeal_pending() seed=209 /> };
	}
	if !open.get() {
		return view! { <chrome::Quiet label=l10n.me_appeal() seed=201 on_press=move || open.set(true) /> };
	}
	let disabled = submit.is_pending() || !crate::model::valid_appeal_reason(&reason.get());
	view! {
		<View class=theme::STACK.as_str()>
			<chrome::Title text=l10n.me_appeal_title() />
			<chrome::Muted text=l10n.me_appeal_body() />
			<chrome::Field
				label=l10n.me_appeal_reason_label()
				placeholder=l10n.me_appeal_reason_hint()
				value=reason.get()
				seed=205
				disabled=submit.is_pending()
				on_change=move |next: &str| { if !submit.is_pending() { reason.set(next.to_owned()); } }
			/>
			<chrome::Muted text=l10n.me_appeal_reason_helper() />
			<View class=theme::ROW.as_str()>
				<chrome::Quiet
					label=l10n.me_appeal_send()
					seed=207
					disabled=disabled
					on_press=move || {
						if submit.is_pending() || !crate::model::valid_appeal_reason(&reason.get()) {
							return;
						}
						submit.mutate(SubmitAppeal {
							attempt_id: attempt_id.clone(),
							reason: reason.get().trim().to_owned(),
						});
					}
				/>
				<chrome::Quiet label=l10n.me_appeal_cancel() seed=211 disabled=submit.is_pending() on_press=move || open.set(false) />
			</View>
			{submit.is_error().then(|| view! { <chrome::Muted text=l10n.me_appeal_failed() /> })}
		</View>
	}
}

#[cfg(test)]
mod tests {
	use super::*;
	use leptoskit::native::Role;
	use leptoskit::query::{MutationScope, QueryClient};
	use leptoskit_testing::{Finder, WidgetTester};
	use reactive_graph::owner::{Owner, provide_context};
	use std::sync::{Arc, Mutex};

	fn button(name: &str) -> Finder {
		Finder::aria_role(Role::Button, name)
	}

	fn tester(mut render: impl FnMut() -> Element + 'static) -> WidgetTester {
		let _ = any_spawner::Executor::init_futures_executor();
		let owner = Owner::new();
		let store = crate::state::Store::default();
		let client = QueryClient::new();
		WidgetTester::new(
			move || {
				owner.cleanup();
				owner.with(|| {
					provide_context(store.clone());
					crate::l10n::L10n::new(&[]).provide();
					client.provide();
					render()
				})
			},
			390.0,
			844.0,
		)
		.unwrap()
	}

	fn row(appeal: AppealStatus) -> AttemptRow {
		AttemptRow {
			id: "private-attempt-id".into(),
			action_title: "Visit the market".into(),
			status: AttemptStatus::Rejected,
			appeal,
		}
	}

	fn settle(tester: &mut WidgetTester, text: &str) {
		let until = std::time::Instant::now() + std::time::Duration::from_secs(3);
		loop {
			tester.pump();
			if !tester.find_all(&Finder::text(text)).is_empty() {
				return;
			}
			assert!(
				std::time::Instant::now() < until,
				"waiting for {text}: {}",
				tester.tree()
			);
			std::thread::sleep(std::time::Duration::from_millis(1));
		}
	}

	#[test]
	fn only_an_available_attempt_offers_an_appeal() {
		for status in [
			AppealStatus::Unavailable,
			AppealStatus::Pending,
			AppealStatus::Accepted,
			AppealStatus::Rejected,
		] {
			let tester = tester(move || AttemptTile(row(status)));
			assert!(tester.find_all(&button("Appeal")).is_empty());
			assert!(
				tester
					.find_all(&Finder::label("What should they know?"))
					.is_empty()
			);
		}
		let mut tester = tester(|| AttemptTile(row(AppealStatus::Available)));
		assert!(tester.find(&button("Appeal")).is_ok());
		assert!(
			tester
				.find_all(&Finder::label("What should they know?"))
				.is_empty()
		);
		tester.tap(&button("Appeal")).unwrap();
		tester.pump();
		assert!(
			tester
				.find(&Finder::label("What should they know?"))
				.is_ok()
		);
		assert!(!tester.tree().contains("private-attempt-id"));
		assert!(
			tester.tap(&button("Send appeal")).is_err(),
			"blank appeal is disabled"
		);
	}

	#[test]
	fn an_empty_attempt_list_has_no_appeal_form() {
		let navigation = Navigation::new(Route::Me);
		let tester = tester(move || {
			leptoskit::query::use_query_client().set_query_data(
				&query_scope::<ListMyAttempts>(),
				ListMyAttempts {}.into(),
				Vec::new(),
			);
			Page(&navigation)
		});
		assert!(
			tester
				.find(&Finder::text(
					"You haven't tried an action yet. Find one in Do."
				))
				.is_ok()
		);
		assert!(tester.find_all(&button("Appeal")).is_empty());
		assert!(
			tester
				.find_all(&Finder::label("What should they know?"))
				.is_empty()
		);
	}

	#[test]
	fn drafts_belong_to_their_attempt_and_submit_uses_the_selected_id() {
		let active = Arc::new(Mutex::new("first".to_owned()));
		let selected = active.clone();
		let submitted = Arc::new(Mutex::new(Vec::new()));
		let requests = submitted.clone();
		let scope = MutationScope::new(move |input: SubmitAppeal| {
			requests
				.lock()
				.unwrap()
				.push((input.attempt_id, input.reason));
			std::future::ready(Ok(AppealReceipt {
				id: "stored".into(),
			}))
		});
		let mut tester =
			tester(move || appeal_form(selected.lock().unwrap().clone(), scope.clone()));
		tester.tap(&button("Appeal")).unwrap();
		tester.pump();
		tester
			.enter_text(&Finder::label("What should they know?"), "First draft")
			.unwrap();
		tester.pump();
		tester.tap(&button("Cancel")).unwrap();
		tester.pump();
		assert!(
			tester
				.find_all(&Finder::label("What should they know?"))
				.is_empty()
		);
		tester.tap(&button("Appeal")).unwrap();
		tester.pump();
		assert_eq!(
			tester
				.find(&Finder::label("What should they know?"))
				.unwrap()
				.props
				.value
				.as_deref(),
			Some("First draft")
		);
		*active.lock().unwrap() = "second".into();
		tester.pump();
		tester.tap(&button("Appeal")).unwrap();
		tester.pump();
		assert!(tester.tree().contains("What should they know?"));
		assert_eq!(
			tester
				.find(&Finder::label("What should they know?"))
				.unwrap()
				.props
				.value
				.as_deref(),
			Some("")
		);
		tester
			.enter_text(
				&Finder::label("What should they know?"),
				" Second explanation ",
			)
			.unwrap();
		tester.pump();
		tester.tap(&button("Send appeal")).unwrap();
		settle(&mut tester, "Appeal sent · waiting for the creator");
		assert_eq!(
			*submitted.lock().unwrap(),
			[("second".to_owned(), "Second explanation".to_owned())]
		);
		*active.lock().unwrap() = "first".into();
		tester.pump();
		assert_eq!(
			tester
				.find(&Finder::label("What should they know?"))
				.unwrap()
				.props
				.value
				.as_deref(),
			Some("First draft")
		);
	}

	#[test]
	fn a_failed_send_keeps_the_draft_and_can_be_retried() {
		let fail = Arc::new(std::sync::atomic::AtomicBool::new(true));
		let offline = fail.clone();
		let scope = MutationScope::new(move |_input: SubmitAppeal| {
			std::future::ready(if offline.load(std::sync::atomic::Ordering::SeqCst) {
				Err(leptoskit::rpc::FnError::Server("unavailable".into()))
			} else {
				Ok(AppealReceipt {
					id: "stored".into(),
				})
			})
		});
		let mut tester = tester(move || appeal_form("attempt".into(), scope.clone()));
		tester.tap(&button("Appeal")).unwrap();
		tester.pump();
		tester
			.enter_text(
				&Finder::label("What should they know?"),
				"Please check the ending.",
			)
			.unwrap();
		tester.pump();
		tester.tap(&button("Send appeal")).unwrap();
		settle(
			&mut tester,
			"We couldn't send your appeal. Please try again.",
		);
		assert_eq!(
			tester
				.find(&Finder::label("What should they know?"))
				.unwrap()
				.props
				.value
				.as_deref(),
			Some("Please check the ending.")
		);
		fail.store(false, std::sync::atomic::Ordering::SeqCst);
		tester.tap(&button("Send appeal")).unwrap();
		settle(&mut tester, "Appeal sent · waiting for the creator");
		assert!(tester.find_all(&button("Send appeal")).is_empty());
	}

	#[test]
	fn pending_send_disables_repeated_submission_and_cancel() {
		let scope = MutationScope::new(|_: SubmitAppeal| {
			std::future::pending::<Result<AppealReceipt, leptoskit::rpc::FnError>>()
		});
		let mut tester = tester(move || appeal_form("attempt".into(), scope.clone()));
		tester.tap(&button("Appeal")).unwrap();
		tester.pump();
		tester
			.enter_text(&Finder::label("What should they know?"), "Please check it.")
			.unwrap();
		tester.pump();
		tester.tap(&button("Send appeal")).unwrap();
		tester.pump();
		assert!(tester.tap(&button("Send appeal")).is_err());
		assert!(tester.tap(&button("Cancel")).is_err());
		assert!(
			tester
				.enter_text(
					&Finder::label("What should they know?"),
					"Changed while sending"
				)
				.is_err()
		);
	}
}
