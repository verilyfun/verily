//! Verily's process entry.
//!
//! The server is [`verily_backend`]. The UI is [`verily_app::App`] and nothing
//! else from that crate. Start this process with `lk dev`.

use leptos::prelude::*;
use leptoskit::server::GracefulShutdown;
use leptoskit::server::Readiness;
use leptoskit::server::leptos_axum::render_app_to_stream;
use leptoskit::server::tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
	let (config, _) = leptoskit::config::LeptoskitConfig::load()?;
	let secrets = verily_backend::load_host_secrets()?;
	let db = leptoskit::db::Db::connect(secrets.database_url()?).await?;
	db.migrate(verily_backend::POSTGRES_MIGRATIONS).await?;
	let auth = verily_backend::build_auth(&db, &secrets, Some(&config))?;
	let host = verily_backend::start(&db, auth, Some(&config), verily_backend::Options::new(&db))?;

	// The hydration scripts name the client's Wasm module after its crate.
	let mut options = leptoskit::leptos::config::get_configuration(None)?.leptos_options;
	options.output_name = "verily_app".into();
	if std::env::var_os("LEPTOS_SITE_ROOT").is_none() {
		options.site_root = "dist".into();
	}
	let package_dir = std::path::PathBuf::from(format!("{}/{}", options.site_root, options.site_pkg_dir));
	let assets_dir = std::path::PathBuf::from(format!("{}/assets", options.site_root));
	let readiness = Readiness::new();
	let app = host
		.router
		.nest_service("/pkg", leptoskit::server::static_files(&package_dir))
		.nest_service("/assets", leptoskit::server::static_files(&assets_dir))
		.fallback(render_app_to_stream(move || page(options.clone())))
		.merge(readiness.routes());
	let address: std::net::SocketAddr =
		format!("{}:{}", config.serve.address, config.serve.port).parse()?;
	let listener = tokio::net::TcpListener::bind(address).await?;

	println!("listening on http://{address}");
	let shutdown = GracefulShutdown::new().readiness(&readiness);
	leptoskit::server::serve_listener_with(listener, app, shutdown).await?;
	Ok(())
}

/// The document for the requested path. It mounts [`verily_app::WebApp`] and
/// nothing else from that crate, and loads the Wasm module that hydrates it.
fn page(options: LeptosOptions) -> impl IntoView {
	let path = use_context::<leptoskit::server::axum::http::request::Parts>()
		.map(|parts| parts.uri.path().to_owned())
		.unwrap_or_default();
	view! {
		<!DOCTYPE html>
		<html lang="en">
			<head>
				<meta charset="utf-8" />
				<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
				<meta name="theme-color" content="#FFFAF0" />
				<link rel="icon" href="/assets/favicon.svg" type="image/svg+xml" />
				<title>"Verily"</title>
				<HydrationScripts options />
				<style>{include_str!("../assets/app.css")}</style>
			</head>
			<body>
				<verily_app::WebApp path />
			</body>
		</html>
	}
}
