//! Partner Verily App detail screen, `/apps/:app`: webhook settings, API key
//! rotation, redirect URIs, and recent webhook delivery logs.

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
use leptoskit_router::Route as DeriveRoute;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::VerilyAppDeliveryRow;
use crate::ops::AddAppRedirectUri;
use crate::ops::ListAppDeliveries;
use crate::ops::ListMyApps;
use crate::ops::RotateAppKey;
use crate::ops::UpdateApp;
use crate::routes::Navigation;
use crate::routes::Route;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;

/// `/apps/:app`.
#[derive(DeriveRoute, Clone, Debug, PartialEq)]
pub struct AppDetail {
	pub app: String,
}

/// Manages one partner Verily App.
#[component]
pub fn Page(route: &AppDetail, navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let app_id = route.app.clone();
	let key_prefix = format!("app_detail.{app_id}");
	let apps = use_rpc_query(|| ListMyApps {});
	let deliveries = use_rpc_query({
		let app_id = app_id.clone();
		move || ListAppDeliveries {
			app_id: app_id.clone(),
		}
	});
	let name_input = remember(&format!("{key_prefix}.name"), String::new);
	let webhook_input = remember(&format!("{key_prefix}.webhook"), String::new);
	let redirect_input = remember(&format!("{key_prefix}.redirect"), String::new);
	let hydrated = remember(&format!("{key_prefix}.hydrated"), || false);
	let notice = remember(&format!("{key_prefix}.notice"), String::new);
	let rotated_key = remember(&format!("{key_prefix}.rotated"), String::new);

	let current = apps
		.data()
		.and_then(|rows| rows.into_iter().find(|r| r.id == app_id));
	if let Some(ref app) = current
		&& !hydrated.get()
	{
		name_input.set(app.name.clone());
		webhook_input.set(app.webhook_url.clone().unwrap_or_default());
		hydrated.set(true);
	}

	let update = use_mutation(mutation_scope::<UpdateApp>().with_on_success_async(
		move |args| async move {
			notice.set(l10n.apps_webhook_saved().to_owned());
			args.client
				.invalidate_scope(&query_scope::<ListMyApps>())
				.await;
		},
	));
	let rotate = use_mutation(mutation_scope::<RotateAppKey>().with_on_success_async(
		move |args| async move {
			rotated_key.set(args.data.api_key_once);
			args.client
				.invalidate_scope(&query_scope::<ListMyApps>())
				.await;
		},
	));
	let add_redirect = use_mutation(mutation_scope::<AddAppRedirectUri>().with_on_success_async(
		move |args| async move {
			redirect_input.set(String::new());
			args.client
				.invalidate_scope(&query_scope::<ListMyApps>())
				.await;
		},
	));

	let back = navigation.clone();
	let save_id = app_id.clone();
	let rotate_id = app_id.clone();
	let redirect_id = app_id.clone();
	let active = current.as_ref().map(|a| a.active).unwrap_or(true);
	let heading = current
		.as_ref()
		.map(|a| a.name.clone())
		.unwrap_or_else(|| l10n.apps_title().to_owned());
	let redirects = current
		.as_ref()
		.map(|a| a.redirect_uris.clone())
		.unwrap_or_default();

	view! {
		<chrome::Page>
			<chrome::Heading text=heading body=l10n.apps_subtitle() />
			<chrome::Quiet
				label=l10n.apps_back_to_apps()
				on_press=move || back.navigate(Route::Apps)
				seed=751
			/>
			<chrome::Card seed=753>
				<chrome::Title text=l10n.apps_webhook_heading() />
				<chrome::Muted text=l10n.apps_webhook_body() />
				<chrome::Field
					label=l10n.apps_name_label()
					value=name_input.get()
					on_change=move |next| name_input.set(next.to_owned())
					seed=755
				/>
				<chrome::Field
					label=l10n.apps_webhook_label()
					placeholder=l10n.apps_webhook_hint()
					value=webhook_input.get()
					on_change=move |next| webhook_input.set(next.to_owned())
					seed=757
				/>
				<chrome::Primary
					label=l10n.apps_webhook_save()
					disabled=update.is_pending()
					on_press=move || {
						let raw = webhook_input.get();
						let url = raw.trim();
						update.mutate(UpdateApp {
							app_id: save_id.clone(),
							name: name_input.get().trim().to_owned(),
							webhook_url: (!url.is_empty()).then(|| url.to_owned()),
							active,
						});
					}
					seed=759
				/>
				{Show(
					move || !notice.get().is_empty(),
					move || view! { <chrome::Body text=notice.get() /> },
				)}
			</chrome::Card>
			<chrome::Card seed=761>
				<chrome::Title text=l10n.apps_keys_heading() />
				<chrome::Quiet
					label=l10n.apps_new_key()
					disabled=rotate.is_pending()
					on_press=move || {
						rotate.mutate(RotateAppKey {
							app_id: rotate_id.clone(),
						});
					}
					seed=763
				/>
				{Show(
					move || !rotated_key.get().is_empty(),
					move || {
						view! {
							<chrome::RoleCard role=Role::Reward seed=765>
								<chrome::Title text=l10n.apps_key_title() />
								<chrome::Muted text=l10n.apps_key_warning() />
								<chrome::Body text=rotated_key.get() />
								<chrome::Quiet
									label=l10n.apps_key_saved()
									on_press=move || rotated_key.set(String::new())
									seed=767
								/>
							</chrome::RoleCard>
						}
					},
				)}
			</chrome::Card>
			<chrome::Card seed=769>
				<chrome::Title text=l10n.apps_redirect_heading() />
				<chrome::Muted text=l10n.apps_redirect_body() />
				{if redirects.is_empty() {
					view! { <chrome::Muted text=l10n.apps_redirect_empty() /> }
				} else {
					let items = redirects
						.into_iter()
						.map(|uri| view! { <chrome::Body text=uri /> })
						.collect::<Vec<_>>();
					view! { <View class=theme::STACK>{items}</View> }
				}}
				<chrome::Field
					label=l10n.apps_redirect_label()
					placeholder=l10n.apps_redirect_hint()
					value=redirect_input.get()
					on_change=move |next| redirect_input.set(next.to_owned())
					seed=771
				/>
				<chrome::Quiet
					label=l10n.apps_redirect_add()
					disabled=add_redirect.is_pending()
					on_press=move || {
						let uri = redirect_input.get().trim().to_owned();
						if !uri.is_empty() {
							add_redirect.mutate(AddAppRedirectUri {
								app_id: redirect_id.clone(),
								uri,
							});
						}
					}
					seed=773
				/>
			</chrome::Card>
			<View class=theme::STACK>
				<chrome::Title text=l10n.apps_deliveries_heading() />
				<chrome::Muted text=l10n.apps_deliveries_body() />
				{Show(
					move || deliveries.is_loading(),
					move || view! { <chrome::Loading text=l10n.apps_deliveries_loading() /> },
				)}
				{Show(
					move || deliveries.is_error(),
					move || {
						view! {
							<chrome::Failed
								title=l10n.apps_deliveries_failed()
								retry=l10n.dialog_retry()
								on_retry=move || {
									deliveries.refetch();
								}
							/>
						}
					},
				)}
				{Show(
					move || deliveries.data().is_some_and(|rows| rows.is_empty()),
					move || view! { <chrome::Muted text=l10n.apps_deliveries_empty() /> },
				)}
				{For(
					move || deliveries.data().unwrap_or_default(),
					|row: &VerilyAppDeliveryRow| row.id.clone(),
					|row| view! { <DeliveryCard row=row /> },
				)}
			</View>
		</chrome::Page>
	}
}

#[component]
fn DeliveryCard(row: VerilyAppDeliveryRow) -> Element {
	let l10n = use_l10n();
	let seed = chrome::seed_for(&row.id);
	let answer = match row.last_status_code {
		Some(code) => l10n.apps_delivery_http(code),
		None => l10n.apps_delivery_no_answer().to_owned(),
	};
	view! {
		<chrome::Card seed=seed>
			<chrome::Body text=l10n.apps_delivery_event(&row.event_type) />
			<chrome::Muted text=l10n.apps_delivery_details(row.attempts, &answer, 0) />
			<chrome::Label text=row.status />
		</chrome::Card>
	}
}
