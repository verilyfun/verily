//! verily.fun: the landing page, deployed apart from the app.
//!
//! The page is leptos HTML for its structure and leptoskit for its ink: the
//! hand-drawn pictures, highlights, and scroll motion are leptoskit and
//! Skribble elements rendered by leptoskit's web renderer. Everything is
//! rendered ahead of time to static files, so the site is a folder a CDN can
//! serve with no server and no JavaScript.
//!
//! ```sh
//! cargo run -p verily_site -- dist
//! ```

pub mod brand;
mod ink;
mod page;

use std::path::Path;

pub use page::document;

/// Where the site lives and where it sends people.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SiteConfig {
	/// The site's own origin, for canonical and social links, without a
	/// trailing slash.
	pub origin: String,
	/// Where "Open Verily" goes: the web app.
	pub app_url: String,
	/// The address people write to.
	pub contact_email: String,
}

impl Default for SiteConfig {
	fn default() -> Self {
		Self {
			origin: "https://verily.fun".to_owned(),
			app_url: "https://app.verily.fun".to_owned(),
			contact_email: "hello@verily.fun".to_owned(),
		}
	}
}

impl SiteConfig {
	/// The defaults, overridden by `VERILY_SITE_ORIGIN`, `VERILY_APP_URL`, and
	/// `VERILY_CONTACT_EMAIL` when they are set and not empty.
	pub fn from_env() -> Self {
		Self::from_lookup(|name| std::env::var(name).ok())
	}

	/// The defaults, overridden by whatever `lookup` finds.
	pub fn from_lookup(lookup: impl Fn(&str) -> Option<String>) -> Self {
		let defaults = Self::default();
		let pick = |name: &str, fallback: String| {
			lookup(name)
				.map(|value| value.trim().trim_end_matches('/').to_owned())
				.filter(|value| !value.is_empty())
				.unwrap_or(fallback)
		};
		Self {
			origin: pick("VERILY_SITE_ORIGIN", defaults.origin),
			app_url: pick("VERILY_APP_URL", defaults.app_url),
			contact_email: pick("VERILY_CONTACT_EMAIL", defaults.contact_email),
		}
	}
}

/// The fonts the page loads, by file name. They are Skribble's Recursive
/// faces, subset to Latin.
pub const FONTS: &[(&str, &[u8])] = &[
	(
		"SkribblePlayful-ExtraBold.woff2",
		include_bytes!("../assets/fonts/SkribblePlayful-ExtraBold.woff2"),
	),
	(
		"SkribbleLinearPlayful-Medium.woff2",
		include_bytes!("../assets/fonts/SkribbleLinearPlayful-Medium.woff2"),
	),
	(
		"SkribbleLinearPlayful-Bold.woff2",
		include_bytes!("../assets/fonts/SkribbleLinearPlayful-Bold.woff2"),
	),
	(
		"SkribbleMonoPlayful-SemiBold.woff2",
		include_bytes!("../assets/fonts/SkribbleMonoPlayful-SemiBold.woff2"),
	),
];

/// Every file the site is made of, by path relative to the site root.
pub fn files(config: &SiteConfig) -> Vec<(String, Vec<u8>)> {
	let mut files = vec![
		("index.html".to_owned(), document(config).into_bytes()),
		("favicon.svg".to_owned(), brand::favicon_svg().into_bytes()),
		(
			"robots.txt".to_owned(),
			format!("User-agent: *\nAllow: /\nSitemap: {}/sitemap.xml\n", config.origin)
				.into_bytes(),
		),
		(
			"sitemap.xml".to_owned(),
			format!(
				"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset \
				 xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"><url><loc>{}/</loc></url></\
				 urlset>\n",
				config.origin
			)
			.into_bytes(),
		),
		(
			"site.webmanifest".to_owned(),
			"{\"name\":\"Verily\",\"short_name\":\"Verily\",\"icons\":[{\"src\":\"/favicon.svg\",\"\
			 sizes\":\"any\",\"type\":\"image/svg+xml\"}],\"theme_color\":\"#D13F22\",\"\
			 background_color\":\"#FFFAF0\",\"display\":\"browser\"}\n"
				.to_owned()
				.into_bytes(),
		),
	];
	for (name, bytes) in FONTS {
		files.push((format!("fonts/{name}"), bytes.to_vec()));
	}
	files
}

/// Writes every file under `out`, creating folders as needed.
///
/// # Errors
///
/// Fails when a folder or file can't be written.
pub fn write(out: &Path, config: &SiteConfig) -> std::io::Result<Vec<String>> {
	let mut written = Vec::new();
	for (path, bytes) in files(config) {
		let target = out.join(&path);
		if let Some(parent) = target.parent() {
			std::fs::create_dir_all(parent)?;
		}
		std::fs::write(&target, bytes)?;
		written.push(path);
	}
	Ok(written)
}
