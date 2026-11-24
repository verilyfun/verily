//! Partner account-link consent screen, `/link`.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::prelude::Get;
use leptoskit::prelude::Set;
use leptoskit::prelude::Show;
use leptoskit::prelude::View;
use leptoskit::query::use_mutation;
use leptoskit::rpc::client::mutation_scope;
use leptoskit::view;

use crate::chrome;
use crate::l10n::use_l10n;
use crate::model::AppLinkExchangeView;
use crate::ops::ApproveAppLink;
use crate::routes::Navigation;
use crate::routes::Route;
use crate::state::remember;
use crate::theme;
use crate::theme::Role;

/// Consent screen where the signed-in user approves or declines linking a
/// pairwise pseudonymous ID to a partner Verily App.
#[component]
pub fn Page(navigation: &Navigation) -> Element {
	let l10n = use_l10n();
	let app_slug = remember("link.app_slug", String::new);
	let redirect_uri = remember("link.redirect_uri", String::new);
	let state_token = remember("link.state", String::new);
	let approved = remember("link.approved", || None::<AppLinkExchangeView>);
	let declined = remember("link.declined", || false);
	let failed = remember("link.failed", || false);

	let approve = use_mutation(
		mutation_scope::<ApproveAppLink>()
			.with_on_success(move |args| {
				failed.set(false);
				declined.set(false);
				approved.set(Some(args.data));
			})
			.with_on_error(move |_| {
				failed.set(true);
			}),
	);

	let display_app = {
		let slug = app_slug.get();
		if slug.trim().is_empty() {
			l10n.action_app_unnamed().to_owned()
		} else {
			slug
		}
	};
	let back = navigation.clone();

	view! {
		<chrome::Page>
			<chrome::Heading text=l10n.app_link_header_title() body=l10n.app_link_asks(&display_app) />
			<chrome::Card seed=851>
				<chrome::Body text=l10n.app_link_how(&display_app) />
				<chrome::Muted text=l10n.app_link_shares_subject(&display_app) />
				<chrome::Muted text=l10n.app_link_shares_nothing_else() />
				<chrome::Field
					label=l10n.apps_name_label()
					placeholder=l10n.apps_name_hint()
					value=app_slug.get()
					on_change=move |next| app_slug.set(next.trim().to_owned())
					seed=853
				/>
				<chrome::Field
					label=l10n.apps_redirect_label()
					placeholder=l10n.apps_redirect_hint()
					value=redirect_uri.get()
					on_change=move |next| redirect_uri.set(next.trim().to_owned())
					seed=855
				/>
			</chrome::Card>
			{Show(
				move || failed.get(),
				move || {
					view! {
						<chrome::RoleCard role=Role::Review seed=857>
							<chrome::Title text=l10n.app_link_invalid_title() />
							<chrome::Body text=l10n.app_link_invalid_body() />
						</chrome::RoleCard>
					}
				},
			)}
			{Show(
				move || approved.get().is_some(),
				move || {
					let exchange = approved.get();
					let app_name = exchange
						.as_ref()
						.map(|e| e.app_name.clone())
						.unwrap_or_else(|| l10n.action_app_unnamed().to_owned());
					let code = exchange
						.as_ref()
						.map(|e| e.code.clone())
						.unwrap_or_default();
					view! {
						<chrome::RoleCard role=Role::Place seed=859>
							<chrome::Title text=l10n.app_link_linked_body(&app_name) />
							<chrome::Body text=code />
						</chrome::RoleCard>
					}
				},
			)}
			{Show(
				move || declined.get(),
				{
					let display_app = display_app.clone();
					move || {
						view! {
							<chrome::Card seed=861>
								<chrome::Title text=l10n.app_link_declined_title() />
								<chrome::Muted text=l10n.app_link_declined_body(&display_app) />
							</chrome::Card>
						}
					}
				},
			)}
			<View class=theme::STACK>
				<chrome::Primary
					label=l10n.app_link_approve(&display_app)
					disabled=approve.is_pending()
						|| app_slug.get().trim().is_empty()
						|| redirect_uri.get().trim().is_empty()
					on_press=move || {
						let state = {
							let raw = state_token.get();
							(!raw.trim().is_empty()).then_some(raw)
						};
						approve.mutate(ApproveAppLink {
							app_slug: app_slug.get().trim().to_owned(),
							redirect_uri: redirect_uri.get().trim().to_owned(),
							state,
						});
					}
					seed=863
				/>
				<chrome::Quiet
					label=l10n.app_link_decline()
					on_press=move || {
						declined.set(true);
						approved.set(None);
					}
					seed=865
				/>
				<chrome::Quiet
					label=l10n.verify_request_back_to_verily()
					on_press=move || back.replace(Route::Do)
					seed=867
				/>
			</View>
		</chrome::Page>
	}
}
