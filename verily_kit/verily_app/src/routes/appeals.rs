//! Appeals management, `/appeals`: participant appeals and the creator/reviewer
//! appeals queue.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::query_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use verily_ink::sketches;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::AppealItem;
use crate::model::AppealStatus;
use crate::ops::ListMyAppeals;
use crate::ops::ListReviewAppeals;
use crate::ops::ResolveAppeal;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;

/// Participant appeals and open appeals waiting for review.
#[component]
pub fn Page() -> Element {
	let l10n = use_l10n();
	let review_appeals = use_rpc_query(|| ListReviewAppeals {});
	let my_appeals = use_rpc_query(|| ListMyAppeals {});
	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.appeals_title() body=l10n.hub_appeals_body() />
			{Show(
				move || review_appeals.is_loading() || my_appeals.is_loading(),
				move || view! { <chrome::Loading text=l10n.appeals_loading() /> },
			)}
			{Show(
				move || review_appeals.is_error(),
				move || {
					view! {
						<chrome::Failed
							title=l10n.appeals_load_failed_title()
							retry=l10n.dialog_retry()
							on_retry=move || {
								review_appeals.refetch();
								my_appeals.refetch();
							}
						/>
					}
				},
			)}
			<View class=theme::STACK>
				{Show(
					move || review_appeals.data().is_some_and(|rows| rows.is_empty()),
					move || {
						view! {
							<chrome::Empty
								title=l10n.appeals_empty_title()
								body=l10n.appeals_empty_body()
								picture=sketches::stamp(88.0, 601)
							/>
						}
					},
				)}
				{For(
					move || review_appeals.data().unwrap_or_default(),
					|item: &AppealItem| item.id.clone(),
					|item| view! { <ReviewAppealCard item=item /> },
				)}
			</View>
			{Show(
				move || my_appeals.data().is_some_and(|rows| !rows.is_empty()),
				move || {
					view! {
						<View class=theme::STACK>
							<chrome::Title text=l10n.me_link_appeals() />
							{For(
								move || my_appeals.data().unwrap_or_default(),
								|item: &AppealItem| item.id.clone(),
								|item| view! { <MyAppealCard item=item /> },
							)}
						</View>
					}
				},
			)}
		</chrome::Page>
	}
}

/// One open appeal waiting for a reviewer or creator decision.
#[component]
fn ReviewAppealCard(item: AppealItem) -> Element {
	let l10n = use_l10n();
	let seed = chrome::seed_for(&item.id);
	let note = remember(&format!("appeal.{}.note", item.id), String::new);
	let feedback = remember(&format!("appeal.{}.feedback", item.id), String::new);
	let resolve = use_mutation(
		mutation_scope::<ResolveAppeal>()
			.with_on_success_async(move |args| async move {
				feedback.set(l10n.appeals_saved().to_owned());
				args.client
					.invalidate_scope(&query_scope::<ListReviewAppeals>())
					.await;
				args.client
					.invalidate_scope(&query_scope::<ListMyAppeals>())
					.await;
			})
			.with_on_error(move |_| {
				feedback.set(l10n.appeals_save_failed().to_owned());
			}),
	);
	let accept_id = item.id.clone();
	let reject_id = item.id.clone();
	view! {
		<chrome::RoleCard role=Role::Review seed=seed>
			<chrome::Title text=item.action_title />
			<chrome::Chip role=Role::Review text=l10n.appeals_status_pending() seed=seed + 1 />
			<chrome::Label text=l10n.appeals_reason_heading() />
			<chrome::Body text=item.reason />
			<chrome::Field
				label=l10n.appeals_note_label()
				placeholder=l10n.appeals_note_hint()
				value=note.get()
				on_change=move |next| note.set(next.to_owned())
				seed=seed + 2
			/>
			<View class=theme::ROW>
				<chrome::Quiet
					label=l10n.appeals_accept()
					disabled=resolve.is_pending()
					on_press=move || {
						resolve.mutate(ResolveAppeal {
							appeal_id: accept_id.clone(),
							overturn: true,
							note: note.get(),
						});
					}
					seed=seed + 3
				/>
				<chrome::Quiet
					label=l10n.appeals_reject()
					disabled=resolve.is_pending()
					on_press=move || {
						resolve.mutate(ResolveAppeal {
							appeal_id: reject_id.clone(),
							overturn: false,
							note: note.get(),
						});
					}
					seed=seed + 4
				/>
			</View>
			{Show(
				move || !feedback.get().is_empty(),
				move || view! { <chrome::Body text=feedback.get() /> },
			)}
		</chrome::RoleCard>
	}
}

/// One appeal the signed-in participant filed.
#[component]
fn MyAppealCard(item: AppealItem) -> Element {
	let l10n = use_l10n();
	let seed = chrome::seed_for(&item.id);
	let status_text = match item.status {
		AppealStatus::Pending => l10n.action_appeal_pending(),
		AppealStatus::Accepted => l10n.action_appeal_accepted(),
		AppealStatus::Rejected => l10n.action_appeal_rejected(),
		AppealStatus::Available | AppealStatus::Unavailable => l10n.appeals_status_pending(),
	};
	let note = item.resolution_note.clone();
	view! {
		<chrome::Card seed=seed>
			<chrome::Title text=item.action_title />
			<chrome::Chip role=Role::Review text=status_text seed=seed + 1 />
			<chrome::Body text=item.reason />
			{note.map(|text| view! { <chrome::Muted text=text /> })}
		</chrome::Card>
	}
}
