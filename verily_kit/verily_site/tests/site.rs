//! The landing page as a visitor's browser receives it: one document, its
//! files, its links, and what it promises about privacy and motion.

use std::collections::BTreeSet;

use verily_site::SiteConfig;
use verily_site::brand;

const BRAND_MARK: &str = include_str!("../../../brand/verily-mark.svg");

fn page() -> String {
	verily_site::document(&SiteConfig::default())
}

/// Every value of `attribute` in `html`, in order.
fn attributes<'a>(html: &'a str, attribute: &str) -> Vec<&'a str> {
	let needle = format!(" {attribute}=\"");
	html.match_indices(&needle)
		.map(|(at, _)| {
			let rest = &html[at + needle.len()..];
			&rest[..rest.find('"').expect("attributes are closed")]
		})
		.collect()
}

/// Every element named `tag`, from `<tag` to its `>`.
fn tags<'a>(html: &'a str, tag: &str) -> Vec<&'a str> {
	let open = format!("<{tag}");
	html.match_indices(&open)
		.filter(|(at, _)| {
			html[at + open.len()..]
				.chars()
				.next()
				.is_some_and(|c| c == ' ' || c == '>')
		})
		.map(|(at, _)| {
			let rest = &html[at..];
			&rest[..=rest.find('>').expect("tags are closed")]
		})
		.collect()
}

#[test]
fn the_document_is_complete_html_with_its_metadata() {
	let html = page();
	assert!(html.starts_with("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"));
	assert!(html.ends_with("</body></html>"));
	assert!(html.contains("<title>Verily: do it, prove it, get paid</title>"));
	assert!(html.contains("<meta name=\"description\" content=\"Post an action"));
	assert!(html.contains("<link rel=\"canonical\" href=\"https://verily.fun/\">"));
	assert!(html.contains("<meta property=\"og:url\" content=\"https://verily.fun/\">"));
	assert!(html.contains("<meta property=\"og:title\""));
	assert!(html.contains("<link rel=\"icon\" href=\"/favicon.svg\" type=\"image/svg+xml\">"));
	assert!(html.contains("<link rel=\"manifest\" href=\"/site.webmanifest\">"));
	assert!(html.contains("width=device-width, initial-scale=1"));
}

#[test]
fn there_is_one_main_heading_and_every_section_is_named() {
	let html = page();
	assert_eq!(tags(&html, "h1").len(), 1);
	let labelled = attributes(&html, "aria-labelledby");
	let ids = attributes(&html, "id").into_iter().collect::<BTreeSet<_>>();
	assert!(labelled.len() >= 7, "{labelled:?}");
	for label in labelled {
		assert!(ids.contains(label), "no element has id {label}");
	}
	assert_eq!(tags(&html, "main").len(), 1);
	assert_eq!(tags(&html, "header").len(), 1);
	assert_eq!(tags(&html, "footer").len(), 1);
}

#[test]
fn every_in_page_link_lands_somewhere() {
	let html = page();
	let ids = attributes(&html, "id").into_iter().collect::<BTreeSet<_>>();
	let fragments = attributes(&html, "href")
		.into_iter()
		.filter_map(|href| href.strip_prefix('#'))
		.collect::<BTreeSet<_>>();
	assert!(fragments.contains("main"));
	assert!(fragments.contains("how"));
	for fragment in fragments {
		assert!(ids.contains(fragment), "#{fragment} goes nowhere");
	}
}

#[test]
fn ids_are_unique() {
	let html = page();
	let ids = attributes(&html, "id");
	let unique = ids.iter().collect::<BTreeSet<_>>();
	assert_eq!(ids.len(), unique.len(), "{ids:?}");
}

#[test]
fn the_page_loads_nothing_from_anyone_else() {
	let html = page();
	for src in attributes(&html, "src") {
		assert!(src.starts_with('/'), "{src} is not served by the site");
	}
	let config = SiteConfig::default();
	for href in attributes(&html, "href") {
		let local = href.starts_with('/') || href.starts_with('#');
		let ours = href == config.app_url || href == format!("mailto:{}", config.contact_email);
		let canonical = href.starts_with(&config.origin);
		assert!(local || ours || canonical, "{href} leaves the site");
	}
	assert!(!html.contains("fonts.googleapis.com"));
	assert!(!html.contains("<script"));
}

#[test]
fn links_go_where_the_config_says() {
	let config = SiteConfig {
		origin: "https://example.test".to_owned(),
		app_url: "https://app.example.test".to_owned(),
		contact_email: "hi@example.test".to_owned(),
	};
	let html = verily_site::document(&config);
	assert!(html.contains("href=\"https://app.example.test\""));
	assert!(html.contains("href=\"mailto:hi@example.test\""));
	assert!(html.contains(">hi@example.test<"));
	assert!(html.contains("<link rel=\"canonical\" href=\"https://example.test/\">"));
	assert!(!html.contains("verily.fun"));
}

#[test]
fn every_picture_is_named_or_hidden() {
	let html = page();
	let svgs = tags(&html, "svg");
	assert!(!svgs.is_empty());
	for svg in svgs {
		let named = svg.contains("role=\"img\"") && svg.contains("aria-label=\"");
		let hidden = svg.contains("aria-hidden=\"true\"");
		assert!(named || hidden, "{svg}");
	}
	assert!(html.contains("aria-label=\"An action in Verily"));
}

#[test]
fn motion_stops_for_people_who_ask_for_less() {
	let html = page();
	assert!(html.contains("@media (prefers-reduced-motion:reduce)"));
	assert!(html.contains("animation:none!important"));
	// leptoskit's motion respects the same preference on its own elements.
	assert!(html.contains("prefers-reduced-motion"));
}

#[test]
fn the_page_has_a_night_appearance() {
	let html = page();
	assert!(html.contains("@media (prefers-color-scheme:dark){:root{--paper:#292331;"));
	assert!(html.contains("color-scheme:light dark"));
}

#[test]
fn the_page_says_what_proof_does_and_never_that_a_clip_is_real() {
	let html = page();
	for outcome in [
		"Filmed live in Verily",
		"Signed by this phone",
		"Inside the place",
		"Challenge spoken",
		"Checked by Verily",
		"With a reviewer",
	] {
		assert!(html.contains(outcome), "{outcome}");
	}
	let lower = html.to_lowercase();
	for claim in [
		"proves it’s real",
		"proves it is real",
		"100% real",
		"deepfake-proof",
		"confidence score",
	] {
		assert!(!lower.contains(claim), "{claim}");
	}
}

#[test]
fn the_site_mark_is_the_exported_brand_mark() {
	assert!(BRAND_MARK.contains(&format!("d=\"{}\"", brand::MARK_PIN)));
	assert!(BRAND_MARK.contains(&format!("d=\"{}\"", brand::MARK_CHECK)));
	assert!(BRAND_MARK.contains(&format!("d=\"{}\"", brand::MARK_FLICK)));
	assert!(BRAND_MARK.contains(&format!("stroke-width=\"{}\"", brand::MARK_PEN)));
}

#[test]
fn a_mark_is_labelled_or_decorative_and_masks_by_its_own_id() {
	let labelled = brand::mark_svg("a", Some("Verily"), false);
	assert!(labelled.contains("role=\"img\" aria-label=\"Verily\""));
	assert!(labelled.contains("<title>Verily</title>"));
	assert!(labelled.contains("<mask id=\"a\""));
	assert!(labelled.contains("mask=\"url(#a)\""));
	assert!(labelled.contains("class=\"mark\""));

	let drawn = brand::mark_svg("b", None, true);
	assert!(drawn.contains("aria-hidden=\"true\""));
	assert!(!drawn.contains("<title>"));
	assert!(drawn.contains("class=\"mark mark-draw\""));
}

#[test]
fn the_favicon_is_the_heavy_mark_in_both_appearances() {
	let favicon = brand::favicon_svg();
	assert!(favicon.starts_with("<svg xmlns=\"http://www.w3.org/2000/svg\""));
	assert!(favicon.contains(brand::MARK_PIN));
	assert!(favicon.contains("stroke-width=\"54\""));
	assert!(favicon.contains("#D13F22"));
	assert!(favicon.contains("@media (prefers-color-scheme:dark){path{color:#F2856A}}"));
}

#[test]
fn the_stylesheet_names_colours_only_by_token() {
	let css = include_str!("../src/site.css");
	let raw = css
		.match_indices('#')
		.filter(|(at, _)| {
			let hex = &css[at + 1..];
			hex.len() >= 3 && hex[..3].chars().all(|c| c.is_ascii_hexdigit())
		})
		.map(|(at, _)| &css[at..(at + 7).min(css.len())])
		.collect::<Vec<_>>();
	assert!(raw.is_empty(), "raw colours in site.css: {raw:?}");
}

#[test]
fn every_token_is_declared_for_paper_and_night() {
	let css = brand::tokens_css();
	for token in brand::TOKENS {
		assert_eq!(
			css.matches(&format!("--{}:", token.name)).count(),
			2,
			"{}",
			token.name
		);
		assert!(css.contains(&format!("--{}:{};", token.name, token.paper)));
		assert!(css.contains(&format!("--{}:{};", token.name, token.night)));
	}
}

#[test]
fn the_site_is_its_page_fonts_and_crawler_files() {
	let config = SiteConfig::default();
	let files = verily_site::files(&config);
	let names = files
		.iter()
		.map(|(name, _)| name.as_str())
		.collect::<BTreeSet<_>>();
	for expected in [
		"index.html",
		"favicon.svg",
		"robots.txt",
		"sitemap.xml",
		"site.webmanifest",
		"fonts/SkribblePlayful-ExtraBold.woff2",
		"fonts/SkribbleLinearPlayful-Medium.woff2",
		"fonts/SkribbleLinearPlayful-Bold.woff2",
		"fonts/SkribbleMonoPlayful-SemiBold.woff2",
	] {
		assert!(names.contains(expected), "{expected}");
	}
	for (name, bytes) in &files {
		assert!(!bytes.is_empty(), "{name} is empty");
		if name.ends_with(".woff2") {
			assert_eq!(&bytes[..4], b"wOF2", "{name} is not woff2");
		}
	}
	let text = |name: &str| {
		String::from_utf8(
			files
				.iter()
				.find(|(file, _)| file == name)
				.unwrap()
				.1
				.clone(),
		)
		.unwrap()
	};
	assert!(text("robots.txt").contains("Sitemap: https://verily.fun/sitemap.xml"));
	assert!(text("sitemap.xml").contains("<loc>https://verily.fun/</loc>"));
	let manifest: serde_json::Value = serde_json::from_str(&text("site.webmanifest")).unwrap();
	assert_eq!(manifest["name"], "Verily");
	assert_eq!(manifest["icons"][0]["src"], "/favicon.svg");
}

#[test]
fn the_page_preloads_the_faces_it_shows_first() {
	let html = page();
	let preloads = tags(&html, "link")
		.into_iter()
		.filter(|link| link.contains("rel=\"preload\""))
		.collect::<Vec<_>>();
	assert_eq!(preloads.len(), 2, "{preloads:?}");
	assert!(preloads.iter().all(|link| link.contains("crossorigin")));
}

#[test]
fn writing_the_site_creates_every_file() {
	let out = std::env::temp_dir().join(format!("verily-site-{}", std::process::id()));
	let _ = std::fs::remove_dir_all(&out);
	let written = verily_site::write(&out, &SiteConfig::default()).unwrap();
	assert_eq!(
		written.len(),
		verily_site::files(&SiteConfig::default()).len()
	);
	for name in &written {
		assert!(out.join(name).is_file(), "{name}");
	}
	assert_eq!(
		std::fs::read_to_string(out.join("index.html")).unwrap(),
		page()
	);
	std::fs::remove_dir_all(&out).unwrap();
}

#[test]
fn writing_fails_when_the_folder_is_a_file() {
	let out = std::env::temp_dir().join(format!("verily-site-file-{}", std::process::id()));
	std::fs::write(&out, "not a folder").unwrap();
	assert!(verily_site::write(&out, &SiteConfig::default()).is_err());
	std::fs::remove_file(&out).unwrap();
}

#[test]
fn the_environment_overrides_each_link() {
	let config = SiteConfig::from_lookup(|name| match name {
		"VERILY_SITE_ORIGIN" => Some(" https://staging.verily.fun/ ".to_owned()),
		"VERILY_APP_URL" => Some(String::new()),
		"VERILY_CONTACT_EMAIL" => Some("team@verily.fun".to_owned()),
		_ => None,
	});
	assert_eq!(config.origin, "https://staging.verily.fun");
	assert_eq!(config.app_url, SiteConfig::default().app_url);
	assert_eq!(config.contact_email, "team@verily.fun");
	assert_eq!(SiteConfig::from_lookup(|_| None), SiteConfig::default());
	// The real environment never names a broken link.
	assert!(!SiteConfig::from_env().origin.is_empty());
}

#[test]
fn the_page_stays_small() {
	let html = page();
	assert!(html.len() < 450_000, "the page is {} bytes", html.len());
}
