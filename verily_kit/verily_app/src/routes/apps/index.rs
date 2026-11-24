//! Partner Verily Apps list and registration, `/apps`.

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

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::VerilyAppCreated;
use crate::model::VerilyAppRow;
use crate::ops::CreateApp;
use crate::ops::ListMyApps;
use crate::routes::AppDetail;
use crate::routes::Navigation;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;

/// Derives a URL-safe slug from an app display name.
fn slug_from_name(name: &str) -> String {
	let mut out = String::new();
	let mut prev_dash = false;
	for ch in name.trim().chars() {
		if ch.is_ascii_alphanumeric() {
			out.push(ch.to_ascii_lowercase());
			prev_dash = false;
		} else if !prev_dash && !out.is_empty() {
			out.push('-');
			prev_dash = true;
		}
	}
	out.trim_matches('-').to_owned()
}

/// Registered Verily Apps and new-app registration.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let apps = use_rpc_query(|| ListMyApps {});
	let name = remember("apps.create.name", String::new);
	let webhook = remember("apps.create.webhook", String::new);
	let error_line = remember("apps.create.error", String::new);
	let created = remember("apps.create.once", || None::<VerilyAppCreated>);
	let register = use_mutation(
		mutation_scope::<CreateApp>()
			.with_on_success_async(move |args| async move {
				name.set(String::new());
				webhook.set(String::new());
				error_line.set(String::new());
				created.set(Some(args.data));
				args.client
					.invalidate_scope(&query_scope::<ListMyApps>())
					.await;
			})
			.with_on_error(move |_| {
				error_line.set(l10n.apps_register_failed().to_owned());
			}),
	);
	let navigation = navigation.clone();
	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.apps_title() body=l10n.apps_subtitle() />
			<chrome::Card seed=701>
				<chrome::Title text=l10n.apps_intro_title() />
				<chrome::Muted text=l10n.apps_intro_body() />
			</chrome::Card>
			{Show(
				move || created.get().is_some(),
				move || {
					let bundle = created.get();
					let api_key = bundle
						.as_ref()
						.map(|c| c.api_key_once.clone())
						.unwrap_or_default();
					let secret = bundle
						.as_ref()
						.map(|c| c.webhook_secret_once.clone())
						.unwrap_or_default();
					view! {
						<chrome::RoleCard role=Role::Reward seed=703>
							<chrome::Title text=l10n.apps_key_title() />
							<chrome::Muted text=l10n.apps_key_warning() />
							<chrome::Label text=l10n.apps_key_label() />
							<chrome::Body text=api_key />
							<chrome::Title text=l10n.apps_secret_title() />
							<chrome::Muted text=l10n.apps_secret_warning() />
							<chrome::Body text=secret />
							<chrome::Quiet
								label=l10n.apps_key_saved()
								on_press=move || created.set(None)
								seed=705
							/>
						</chrome::RoleCard>
					}
				},
			)}
			<chrome::Card seed=707>
				<chrome::Title text=l10n.apps_register_heading() />
				<chrome::Field
					label=l10n.apps_name_label()
					placeholder=l10n.apps_name_hint()
					value=name.get()
					on_change=move |next| name.set(next.to_owned())
					seed=709
				/>
				<chrome::Field
					label=l10n.apps_webhook_label()
					placeholder=l10n.apps_webhook_hint()
					value=webhook.get()
					on_change=move |next| webhook.set(next.to_owned())
					seed=711
				/>
				<chrome::Primary
					label=l10n.apps_register()
					disabled=register.is_pending()
					on_press=move || {
						let trimmed = name.get().trim().to_owned();
						if trimmed.is_empty() {
							error_line.set(l10n.apps_name_required().to_owned());
							return;
						}
						let slug = slug_from_name(&trimmed);
						let webhook_url = {
							let raw = webhook.get();
							let t = raw.trim();
							(!t.is_empty()).then(|| t.to_owned())
						};
						error_line.set(String::new());
						register.mutate(CreateApp {
							name: trimmed,
							slug,
							webhook_url,
						});
					}
					seed=713
				/>
				{Show(
					move || !error_line.get().is_empty(),
					move || view! { <chrome::Body text=error_line.get() /> },
				)}
			</chrome::Card>
			<View class=theme::STACK>
				<chrome::Title text=l10n.apps_list_heading() />
				{Show(
					move || apps.is_loading(),
					move || view! { <chrome::Loading text=l10n.apps_loading() /> },
				)}
				{Show(
					move || apps.is_error(),
					move || {
						view! {
							<chrome::Failed
								title=l10n.apps_load_failed_title()
								retry=l10n.dialog_retry()
								on_retry=move || {
									apps.refetch();
								}
							/>
						}
					},
				)}
				{Show(
					move || apps.data().is_some_and(|rows| rows.is_empty()),
					move || {
						view! {
							<chrome::Empty
								title=l10n.apps_empty_title()
								body=l10n.apps_empty_body()
							/>
						}
					},
				)}
				{For(
					move || apps.data().unwrap_or_default(),
					|row: &VerilyAppRow| row.id.clone(),
					move |row| view! { <AppCard navigation=navigation.clone() row=row /> },
				)}
			</View>
		</chrome::Page>
	}
}

#[component]
fn AppCard(navigation: Navigation, row: VerilyAppRow) -> Element {
	let l10n = use_l10n();
	let seed = chrome::seed_for(&row.id);
	let id = row.id.clone();
	let (role, status) = if row.active {
		(Role::Place, l10n.apps_status_active())
	} else {
		(Role::Review, l10n.apps_status_revoked())
	};
	view! {
		<chrome::Card seed=seed>
			<chrome::Title text=row.name />
			<chrome::Muted text=row.slug />
			<chrome::Chip role=role text=status seed=seed + 1 />
			<chrome::Quiet
				label=l10n.hub_view()
				on_press=move || navigation.navigate(AppDetail { app: id.clone() })
				seed=seed + 2
			/>
		</chrome::Card>
	}
}
