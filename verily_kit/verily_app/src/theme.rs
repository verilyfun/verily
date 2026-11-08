//! Verily colour tokens from `DESIGN.md` and `packages/verily_brand`.
//!
//! Screens use `var(--paper)` and the other names. They do not use LeptosKit's
//! ember and mint theme, and they do not write raw colours of their own.

use leptoskit::prelude::Color;
use leptoskit::prelude::Theme;
use std::collections::BTreeMap;

/// Class strings the screens share. Tests parse every one.
pub const PAGE: &str = "flex flex-col gap-4 bg-[var(--paper)] p-4 text-[var(--ink)]";
pub const TITLE: &str = "text-2xl font-bold text-[var(--ink)]";
pub const MUTED: &str = "text-sm text-[var(--muted-ink)]";
pub const CARD: &str =
	"flex flex-col gap-2 rounded-lg border border-[var(--dusk)] bg-[var(--paper)] p-4";
pub const PRIMARY: &str = "rounded-lg bg-[var(--stamp)] px-4 py-2 text-[var(--paper)]";
pub const QUIET: &str = "rounded-lg border border-[var(--dusk)] px-4 py-2 text-[var(--ink)]";
pub const PLACE: &str = "rounded-lg bg-[var(--place-wash)] p-4 text-[var(--place)]";
pub const REWARD: &str = "rounded-lg bg-[var(--reward-wash)] p-4 text-[var(--reward)]";
pub const REVIEW: &str = "rounded-lg bg-[var(--review-wash)] p-4 text-[var(--review)]";
pub const ROW: &str = "flex flex-row flex-wrap items-center gap-2";
pub const FINDER: &str = "relative h-64 w-full overflow-hidden rounded-lg bg-[var(--night)]";
pub const FIELD: &str =
	"rounded-lg border border-[var(--dusk)] bg-[var(--paper)] px-3 py-2 text-[var(--ink)]";

/// Every shared class string, so a test can reject one the renderer does not know.
#[must_use]
pub fn class_sheet() -> &'static [&'static str] {
	&[
		PAGE, TITLE, MUTED, CARD, PRIMARY, QUIET, PLACE, REWARD, REVIEW, ROW, FINDER, FIELD,
	]
}

/// Paper appearance: floral white page, ink text, vermilion stamp.
pub fn install_paper() {
	install(PAPER);
}

/// Night appearance: the same roles, with the night ground and the lighter stamp.
pub fn install_night() {
	install(NIGHT);
}

fn install(tokens: &[(&str, &str)]) {
	let colors = tokens
		.iter()
		.map(|(name, value)| ((*name).to_owned(), (*value).to_owned()))
		.collect::<BTreeMap<_, _>>();
	Theme::install_maps(&colors, &BTreeMap::new()).expect("Verily colour tokens are hex colours");
}

const PAPER: &[(&str, &str)] = &[
	("paper", "#FFFAF0"),
	("night", "#292331"),
	("ink", "#34283F"),
	("muted-ink", "#736678"),
	("muted-paper", "#B9ACBF"),
	("dusk", "#4A3B5E"),
	("stamp", "#D13F22"),
	("stamp-on-night", "#F2856A"),
	("place", "#2F6B4F"),
	("place-wash", "#DDEAD9"),
	("reward", "#9A6A12"),
	("reward-wash", "#F6E8AF"),
	("review", "#6B4FA0"),
	("review-wash", "#E5DDF4"),
	("fire", "#2F6FD6"),
];

const NIGHT: &[(&str, &str)] = &[
	("paper", "#292331"),
	("night", "#292331"),
	("ink", "#FFFAF0"),
	("muted-ink", "#B9ACBF"),
	("muted-paper", "#736678"),
	("dusk", "#4A3B5E"),
	("stamp", "#F2856A"),
	("stamp-on-night", "#F2856A"),
	("place", "#DDEAD9"),
	("place-wash", "#2F6B4F"),
	("reward", "#F6E8AF"),
	("reward-wash", "#9A6A12"),
	("review", "#E5DDF4"),
	("review-wash", "#6B4FA0"),
	("fire", "#2F6FD6"),
];

/// Stamp vermilion, for the vector frame. The screen still paints with tokens.
#[must_use]
pub fn stamp_ink() -> Color {
	Color::hex("#D13F22").expect("stamp vermilion")
}

/// The lighter stamp used on the night viewfinder.
#[must_use]
pub fn stamp_on_night() -> Color {
	Color::hex("#F2856A").expect("stamp on night")
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn paper_tokens_match_the_brand() {
		install_paper();
		assert_eq!(Theme::color("paper"), Color::hex("#FFFAF0"));
		assert_eq!(Theme::color("ink"), Color::hex("#34283F"));
		assert_eq!(Theme::color("stamp"), Color::hex("#D13F22"));
		assert_eq!(Theme::color("place"), Color::hex("#2F6B4F"));
		assert_eq!(Theme::color("reward"), Color::hex("#9A6A12"));
		assert_eq!(Theme::color("review"), Color::hex("#6B4FA0"));
		assert_eq!(Theme::color("fire"), Color::hex("#2F6FD6"));
	}

	#[test]
	fn night_keeps_the_stamp_readable() {
		install_night();
		assert_eq!(Theme::color("paper"), Color::hex("#292331"));
		assert_eq!(Theme::color("ink"), Color::hex("#FFFAF0"));
		assert_eq!(Theme::color("stamp"), Color::hex("#F2856A"));
	}
}
