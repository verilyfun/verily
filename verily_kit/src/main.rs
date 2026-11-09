//! Verily's process entry.
//!
//! The server is [`verily_backend`]. It serves the built client from `dist/`,
//! which renders [`verily_app::App`] in the browser. Start this process with
//! `lk dev`.

use leptoskit::server::GracefulShutdown;
use leptoskit::server::Readiness;
use leptoskit::server::tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
	let (config, _) = leptoskit::config::LeptoskitConfig::load()?;
	let secrets = verily_backend::load_host_secrets()?;
	let db = leptoskit::db::Db::connect(secrets.database_url()?).await?;
	db.migrate(verily_backend::POSTGRES_MIGRATIONS).await?;
	let auth = verily_backend::build_auth(&db, &secrets, Some(&config))?;
	let host = verily_backend::start(&db, auth, Some(&config), verily_backend::Options::new(&db))?;

	// The app renders in the browser: `dist/` holds `index.html`, the Wasm
	// client under `pkg/`, and `assets/`. A path no file matches, such as
	// `/do/act_123`, gets `index.html`, and the client routes it.
	let site_root = std::env::var_os("LEPTOS_SITE_ROOT")
		.map_or_else(|| std::path::PathBuf::from("dist"), std::path::PathBuf::from);
	let readiness = Readiness::new();
	// The catalogue's RPC stubs register from `verily_app`; link them.
	let _ = verily_app::ops::BACKEND;
	let app = host
		.router
		.fallback_service(leptoskit::server::static_files(&site_root))
		.merge(readiness.routes());
	let address: std::net::SocketAddr =
		format!("{}:{}", config.serve.address, config.serve.port).parse()?;
	let listener = tokio::net::TcpListener::bind(address).await?;

	println!("listening on http://{address}");
	let shutdown = GracefulShutdown::new().readiness(&readiness);
	leptoskit::server::serve_listener_with(listener, app, shutdown).await?;
	Ok(())
}
