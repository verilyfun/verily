//! Your page, `/me`: the payout wallet, attempts, payouts, and the way into
//! reviewing and settings.
//!
//! The wallet card does not show an address, a key, or a signature. An appeal
//! belongs to one attempt, and the form never prints that attempt's id.

use std::sync::Arc;

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Get;
use leptoskit::prelude::RwSignal;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::QueryHandle;
use leptoskit::rpc::FnError;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::query_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::sketches;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::AppealReceipt;
use crate::model::AppealStatus;
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
use crate::state::mutation;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;
use crate::wallet::LinkFault;
use crate::wallet::begin_link;
use crate::wallet::mobile_link_supported;

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
					|row| view! { <AttemptTile row=row /> },
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
					|row| view! { <PayoutTile row=row /> },
				)}
			</View>
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

/// Where rewards go: linked or not, in plain words, with the way to link one
/// on a phone that can talk to a wallet.
#[component]
fn WalletCard(wallet: QueryHandle<WalletLink, FnError>) -> Element {
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
	let button = if can_link && linked {
		view! {
			<chrome::Quiet
				label=label
				disabled=busy
				on_press=move || press_wallet_link(linking, fault, linked_here, wallet)
				seed=407
			/>
		}
	} else if can_link {
		view! {
			<chrome::Primary
				label=label
				disabled=busy
				on_press=move || press_wallet_link(linking, fault, linked_here, wallet)
				seed=407
			/>
		}
	} else {
		view! { <chrome::Muted text=l10n.me_wallet_unsupported() /> }
	};
	view! {
		<chrome::RoleCard role=Role::Reward seed=405>
			<View class="flex flex-row items-center gap-3">
				{sketches::coin(32.0, 407)}
				<chrome::Title text=l10n.me_wallet_title() />
			</View>
			<chrome::Body text=title />
			<chrome::Muted text=body />
			{button}
			{fault_line.map(|text| view! { <chrome::Muted text=text /> })}
		</chrome::RoleCard>
	}
}

fn press_wallet_link(
	linking: RwSignal<bool>,
	fault: RwSignal<Option<LinkFault>>,
	linked_here: RwSignal<bool>,
	wallet: QueryHandle<WalletLink, FnError>,
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

/// One attempt. A verified one gets the stamp; one with a person says so in
/// violet; an appeal, when the server allows it, stays on this card.
#[component]
fn AttemptTile(row: AttemptRow) -> Element {
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
			view! { <chrome::Chip role=Role::Review text=l10n.do_your_attempt(words) seed=seed + 1 /> }
		}
		_ => view! { <chrome::Muted text=l10n.do_your_attempt(words) /> },
	};
	let appeal = match row.appeal {
		AppealStatus::Available => Some(view! { <AppealForm attempt_id=row.id.clone() /> }),
		AppealStatus::Pending => Some(
			view! { <chrome::Chip role=Role::Review text=l10n.me_appeal_pending() seed=seed + 5 /> },
		),
		AppealStatus::Accepted => Some(view! { <chrome::Muted text=l10n.me_appeal_accepted() /> }),
		AppealStatus::Rejected => Some(view! { <chrome::Muted text=l10n.me_appeal_rejected() /> }),
		AppealStatus::Unavailable => None,
	};
	view! {
		<chrome::Card seed=seed>
			<chrome::Title text=row.action_title />
			{status}
			{appeal}
		</chrome::Card>
	}
}

/// One payout, with its amount next to a coin.
#[component]
fn PayoutTile(row: PayoutRow) -> Element {
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

/// Contest one decision: the reason stays on this attempt.
#[component]
fn AppealForm(attempt_id: String) -> Element {
	appeal_form(attempt_id, mutation_scope::<SubmitAppeal>())
}

fn appeal_form(
	attempt_id: String,
	scope: leptoskit::query::MutationScope<SubmitAppeal, AppealReceipt, FnError>,
) -> Element {
	let l10n = use_l10n();
	let key = format!("me.appeal.{attempt_id}");
	let reason = remember(&format!("{key}.reason"), String::new);
	let open = remember(&format!("{key}.open"), || false);
	// An atomic, not the signal: the success task runs outside the arena that
	// owns the signal when sandboxed arenas are enabled, and a signal write
	// there does not show up on the next paint.
	let sent = remember(&format!("{key}.sent"), || {
		Arc::new(std::sync::atomic::AtomicBool::new(false))
	});
	let sent_flag = sent.get();
	let submit = mutation(
		&format!("{key}.submit"),
		scope.with_on_success_async(move |args| {
			let sent_flag = Arc::clone(&sent_flag);
			async move {
				sent_flag.store(true, std::sync::atomic::Ordering::SeqCst);
				args.client
					.invalidate_scope(&query_scope::<ListMyAttempts>())
					.await;
			}
		}),
	);
	if sent.get().load(std::sync::atomic::Ordering::SeqCst) {
		return view! { <chrome::Chip role=Role::Review text=l10n.me_appeal_pending() seed=209 /> };
	}
	if !open.get() {
		return view! {
			<chrome::Quiet label=l10n.me_appeal() seed=201 on_press=move || open.set(true) />
		};
	}
	let disabled = submit.is_pending() || !crate::model::valid_appeal_reason(&reason.get());
	view! {
		<View class=theme::STACK>
			<chrome::Title text=l10n.me_appeal_title() />
			<chrome::Muted text=l10n.me_appeal_body() />
			<chrome::Field
				label=l10n.me_appeal_reason_label()
				placeholder=l10n.me_appeal_reason_hint()
				value=reason.get()
				seed=205
				disabled=submit.is_pending()
				on_change=move |next: &str| {
					if !submit.is_pending() {
						reason.set(next.to_owned());
					}
				}
			/>
			<chrome::Muted text=l10n.me_appeal_reason_helper() />
			<View class=theme::ROW>
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
				<chrome::Quiet
					label=l10n.me_appeal_cancel()
					seed=211
					disabled=submit.is_pending()
					on_press=move || open.set(false)
				/>
			</View>
			{Show(
				move || submit.is_error(),
				move || view! { <chrome::Muted text=l10n.me_appeal_failed() /> },
			)}
		</View>
	}
}

#[cfg(test)]
mod tests {
	use super::*;
	use leptoskit::native::Role as AriaRole;
	use leptoskit::query::{MutationScope, QueryClient};
	use leptoskit::view;
	use leptoskit_testing::{Finder, WidgetTester};
	use reactive_graph::owner::{Owner, provide_context};
	use std::sync::{Arc, Mutex};

	fn button(name: &str) -> Finder {
		Finder::aria_role(AriaRole::Button, name)
	}

	fn tester(mut render: impl FnMut() -> Element + 'static) -> WidgetTester {
		crate::state::install_test_executor();
		// One root so the store, the render owner, and l10n share an arena
		// when sandboxed arenas are on (the server feature turns them on).
		let root = Owner::new();
		let (owner, store, client) = root.with(|| {
			(
				Owner::new(),
				crate::state::Store::default(),
				QueryClient::new(),
			)
		});
		WidgetTester::new(
			move || {
				let _root = &root;
				// Do not clean the render owner here. LeptosKit 0.3.0 cancels
				// a mutation's success task with that owner, so a rebuild
				// would drop the appeal's "sent" update before it is painted.
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
			let tester = tester(move || view! { <AttemptTile row=row(status) /> });
			assert!(tester.find_all(&button("Appeal")).is_empty());
			assert!(
				tester
					.find_all(&Finder::label("What should they know?"))
					.is_empty()
			);
		}
		let mut tester = tester(|| view! { <AttemptTile row=row(AppealStatus::Available) /> });
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
			view! { <Page navigation=&navigation /> }
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
