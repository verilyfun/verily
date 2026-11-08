//! Verily's process entry.
//!
//! The server is [`verily_backend`]. The UI is [`verily_app::app`] and nothing
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

	let package_dir = std::path::PathBuf::from("dist/pkg");
	let assets_dir = std::path::PathBuf::from("dist/assets");
	let readiness = Readiness::new();
	let app = host
		.router
		.nest_service("/pkg", leptoskit::server::static_files(&package_dir))
		.nest_service("/assets", leptoskit::server::static_files(&assets_dir))
		.fallback(render_app_to_stream(page))
		.merge(readiness.routes());
	let address: std::net::SocketAddr =
		format!("{}:{}", config.serve.address, config.serve.port).parse()?;
	let listener = tokio::net::TcpListener::bind(address).await?;

	println!("listening on http://{address}");
	let shutdown = GracefulShutdown::new().readiness(&readiness);
	leptoskit::server::serve_listener_with(listener, app, shutdown).await?;
	Ok(())
}

/// The document. It mounts [`verily_app::app`] and nothing else from that crate.
fn page() -> impl IntoView {
	let navigation = verily_app::Navigation::new(verily_app::AppRoute::Do);
	view! {
		<!DOCTYPE html>
		<html lang="en">
			<head>
				<meta charset="utf-8" />
				<meta name="viewport" content="width=device-width, initial-scale=1" />
				<link rel="icon" href="data:," />
				<title>"Verily"</title>
				<style>{include_str!("../assets/app.css")}</style>
			</head>
			<body>{leptoskit::web::render(verily_app::app(navigation))}</body>
		</html>
	}
}
