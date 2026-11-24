//! Partner-initiated verification request handoff, `/r/:request`.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::For;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::rpc::client::query_scope;
use leptoskit::rpc::client::use_rpc_query;
use leptoskit::view;
use leptoskit_router::Route as DeriveRoute;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::VerificationRequestView;
use crate::ops::CancelVerificationRequest;
use crate::ops::GetVerificationRequest;
use crate::ops::StartVerificationRequest;
use crate::routes::Action;
use crate::routes::Navigation;
use crate::routes::Route;
use crate::theme;
use crate::theme::Role;

/// `/r/:request`.
#[derive(DeriveRoute, Clone, Debug, PartialEq)]
pub struct VerifyRequest {
	pub request: String,
}

/// Shows a partner verification request so the participant can accept or decline.
#[component]
pub fn Page(route: &VerifyRequest, navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let request_id = route.request.clone();
	let request = use_rpc_query({
		let request_id = request_id.clone();
		move || GetVerificationRequest {
			request_id: request_id.clone(),
		}
	});
	let nav_accept = navigation.clone();
	let start = use_mutation(
		mutation_scope::<StartVerificationRequest>().with_on_success(move |args| {
			nav_accept.navigate(Action {
				action: args.data.action_id,
			});
		}),
	);
	let cancel = use_mutation(
		mutation_scope::<CancelVerificationRequest>().with_on_success_async(
			move |args| async move {
				args.client
					.invalidate_scope(&query_scope::<GetVerificationRequest>())
					.await;
			},
		),
	);
	let nav_home = navigation.clone();
	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.verify_request_header_title() />
			{Show(
				move || request.is_loading(),
				move || view! { <chrome::Loading text=l10n.verify_request_loading() /> },
			)}
			{Show(
				move || request.is_error(),
				move || {
					view! {
						<chrome::Failed
							title=l10n.verify_request_load_failed_title()
							retry=l10n.dialog_retry()
							on_retry=move || {
								request.refetch();
							}
						/>
					}
				},
			)}
			{For(
				move || request.data().into_iter().collect::<Vec<_>>(),
				|item: &VerificationRequestView| item.id.clone(),
				move |item| {
					let l10n = use_l10n();
					let seed = chrome::seed_for(&item.id);
					let accept_id = item.id.clone();
					let decline_id = item.id.clone();
					let open = item.status == "open" || item.status == "started";
					let back = nav_home.clone();
					view! {
						<chrome::Card seed=seed>
							<chrome::Muted text=l10n.verify_request_from(&item.app_name) />
							<chrome::Title text=item.action_title.clone() />
							<chrome::Chip role=Role::Place text=item.status.clone() seed=seed + 1 />
							<chrome::Muted text=l10n.verify_request_shares_subject(&item.app_name) />
							{if open {
								view! {
									<View class=theme::STACK>
										<chrome::Primary
											label=l10n.verify_request_accept()
											disabled=start.is_pending()
											on_press=move || {
												start.mutate(StartVerificationRequest {
													request_id: accept_id.clone(),
												});
											}
											seed=seed + 2
										/>
										<chrome::Quiet
											label=l10n.verify_request_decline()
											disabled=cancel.is_pending()
											on_press=move || {
												cancel.mutate(CancelVerificationRequest {
													request_id: decline_id.clone(),
												});
											}
											seed=seed + 3
										/>
									</View>
								}
							} else {
								let title = if item.status == "cancelled" {
									l10n.verify_request_declined_title()
								} else {
									l10n.verify_request_closed_title()
								};
								let body = if item.status == "cancelled" {
									l10n.verify_request_declined_body(&item.app_name)
								} else {
									l10n.verify_request_closed_body(&item.app_name)
								};
								view! {
									<View class=theme::STACK>
										<chrome::Title text=title />
										<chrome::Muted text=body />
										<chrome::Quiet
											label=l10n.verify_request_back_to_verily()
											on_press=move || back.replace(Route::Do)
											seed=seed + 4
										/>
									</View>
								}
							}}
						</chrome::Card>
					}
				},
			)}
		</chrome::Page>
	}
}
