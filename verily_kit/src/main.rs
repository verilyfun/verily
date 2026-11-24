//! Verily's process entry.
//!
//! The server is [`verily_backend`]. It serves the built client from `dist/`,
//! which renders [`verily_app::App`] in the browser, and the operations the
//! app declares, at `/_leptoskit/services/verily-backend/api/<name>`. Start
//! this process with `lk dev`.

use leptoskit::server::GracefulShutdown;
use leptoskit::server::Readiness;
use leptoskit::server::tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
	let (config, _) = leptoskit::config::LeptoskitConfig::load()?;
	let secrets = verily_backend::load_host_secrets()?;
	let database_url = secrets.database_url()?;
	let db = leptoskit::db::Db::connect(database_url).await?;
	if database_url.starts_with("sqlite:") {
		db.migrate(verily_backend::MIGRATIONS).await?;
	} else {
		db.migrate(verily_backend::POSTGRES_MIGRATIONS).await?;
	}
	let auth = verily_backend::build_auth(&db, &secrets, Some(&config))?;
	// Use LeptosKit's development mailbox and its debug-only route. The
	// backend's in-memory test mailer alone has no page to read codes from.
	#[cfg(debug_assertions)]
	let auth = auth.dev_mailbox().dev_sign_in();
	let options = verily_backend::Options {
		demo_mail: false,
		..verily_backend::Options::new(&db)
	};
	let host = verily_backend::start(&db, auth, Some(&config), options)?;
	let _jobs = verily_backend::jobs::start_worker(db.clone(), host.backend.clone());
	// A debug build puts a few live actions in the Do catalogue, once.
	#[cfg(debug_assertions)]
	verily_backend::seed_development(&db, &host.rewards.0).await?;

	// The app renders in the browser: `dist/` holds `index.html`, the Wasm
	// client under `pkg/`, and `assets/`. A path no file matches, such as
	// `/do/act_123`, gets `index.html`, and the client routes it.
	let site_root = std::env::var_os("LEPTOS_SITE_ROOT").map_or_else(
		|| std::path::PathBuf::from("dist"),
		std::path::PathBuf::from,
	);
	let readiness = Readiness::new();
	// `verily_app`'s operations, built with its `service` feature, register
	// their bodies here; the host serves them under the backend's prefix.
	let _ = verily_app::ops::BACKEND;
	let app = host
		.router
		.fallback_service(leptoskit::server::static_files(&site_root))
		.merge(readiness.routes());
	let bind_host = std::env::var("VERILY_BIND_ADDRESS")
		.ok()
		.filter(|v| !v.trim().is_empty())
		.unwrap_or_else(|| config.serve.address.clone());
	let bind_port: u16 = std::env::var("VERILY_PORT")
		.ok()
		.and_then(|v| v.parse().ok())
		.unwrap_or(config.serve.port);
	let address: std::net::SocketAddr = format!("{bind_host}:{bind_port}").parse()?;
	let listener = tokio::net::TcpListener::bind(address).await?;

	println!("listening on http://{address}");
	let shutdown = GracefulShutdown::new().readiness(&readiness);
	leptoskit::server::serve_listener_with(listener, app, shutdown).await?;
	Ok(())
}
