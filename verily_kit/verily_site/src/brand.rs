//! Verily's brand for the site: the colour tokens from `DESIGN.md`, the
//! Skribble theme the ink draws with, and the mark.
//!
//! These are the only raw colours in the site. The page and its stylesheet
//! use the CSS custom properties [`TOKENS_CSS`] declares.

use leptoskit::native::Color;
use skribble_leptoskit::Palette;
use skribble_leptoskit::Theme;
use skribble_leptoskit::Tone;

/// A brand colour by its `DESIGN.md` name, with its night-paper twin.
pub struct Token {
	/// The custom property name, without the leading `--`.
	pub name: &'static str,
	/// The value on paper.
	pub paper: &'static str,
	/// The value on night paper.
	pub night: &'static str,
}

/// Every colour the site uses. Night values follow the `-on-night` roles.
pub const TOKENS: &[Token] = &[
	Token {
		name: "paper",
		paper: "#FFFAF0",
		night: "#292331",
	},
	Token {
		name: "paper-deep",
		paper: "#F6EEDC",
		night: "#211C28",
	},
	Token {
		name: "night",
		paper: "#292331",
		night: "#1E1925",
	},
	Token {
		name: "ink",
		paper: "#34283F",
		night: "#FFFAF0",
	},
	Token {
		name: "muted-ink",
		paper: "#736678",
		night: "#B9ACBF",
	},
	Token {
		name: "muted-paper",
		paper: "#B9ACBF",
		night: "#736678",
	},
	Token {
		name: "dot",
		paper: "#E4D9C6",
		night: "#3A3145",
	},
	Token {
		name: "dusk",
		paper: "#4A3B5E",
		night: "#4A3B5E",
	},
	Token {
		name: "stamp",
		paper: "#D13F22",
		night: "#F2856A",
	},
	Token {
		name: "on-stamp",
		paper: "#FFFAF0",
		night: "#292331",
	},
	Token {
		name: "place",
		paper: "#2F6B4F",
		night: "#86C7A0",
	},
	Token {
		name: "place-wash",
		paper: "#DDEAD9",
		night: "#24382F",
	},
	Token {
		name: "reward",
		paper: "#9A6A12",
		night: "#E6BC5C",
	},
	Token {
		name: "reward-wash",
		paper: "#F6E8AF",
		night: "#3B3220",
	},
	Token {
		name: "review",
		paper: "#6B4FA0",
		night: "#BBA6EC",
	},
	Token {
		name: "review-wash",
		paper: "#E5DDF4",
		night: "#352B4B",
	},
	Token {
		name: "phone",
		paper: "#34283F",
		night: "#141017",
	},
	// Ink on the night band and the camera, which stay dark in both
	// appearances.
	Token {
		name: "chalk",
		paper: "#FFFAF0",
		night: "#FFFAF0",
	},
	Token {
		name: "chalk-muted",
		paper: "#B9ACBF",
		night: "#B9ACBF",
	},
	Token {
		name: "chalk-place",
		paper: "#86C7A0",
		night: "#86C7A0",
	},
	Token {
		name: "chalk-stamp",
		paper: "#F2856A",
		night: "#F2856A",
	},
	Token {
		name: "chalk-ink",
		paper: "#34283F",
		night: "#34283F",
	},
];

/// The `:root` rules that declare [`TOKENS`], with the night values under
/// `prefers-color-scheme: dark`.
pub fn tokens_css() -> String {
	let declare = |night: bool| {
		TOKENS
			.iter()
			.map(|token| {
				format!(
					"--{}:{};",
					token.name,
					if night { token.night } else { token.paper }
				)
			})
			.collect::<String>()
	};
	format!(
		":root{{color-scheme:light dark;{}}}@media (prefers-color-scheme:dark){{:root{{{}}}}}",
		declare(false),
		declare(true)
	)
}

const fn hex(rgb: u32) -> Color {
	Color::rgba((rgb >> 16) as u8, (rgb >> 8) as u8, rgb as u8, 0xff)
}

/// Plum ink on floral paper, with the night page in dark mode.
pub const INK: Theme = Theme {
	light: Palette {
		ink: hex(0x34_28_3F),
		paper: hex(0xFF_FA_F0),
		accent: hex(0xD1_3F_22),
		on_accent: hex(0xFF_FA_F0),
	},
	dark: Palette {
		ink: hex(0xFF_FA_F0),
		paper: hex(0x29_23_31),
		accent: hex(0xF2_85_6A),
		on_accent: hex(0x29_23_31),
	},
	stroke_width: 2.2,
	roughness: 1.1,
};

/// The verified vermilion: the brand and "verified", nothing else.
pub const STAMP: Tone = Tone {
	light: hex(0xD1_3F_22),
	dark: hex(0xF2_85_6A),
};
/// Place green: pins and radii.
pub const PLACE: Tone = Tone {
	light: hex(0x2F_6B_4F),
	dark: hex(0x86_C7_A0),
};
/// Reward gold: coins and the escrow jar.
pub const REWARD: Tone = Tone {
	light: hex(0x9A_6A_12),
	dark: hex(0xE6_BC_5C),
};
/// Review violet: anything a person decides.
pub const REVIEW: Tone = Tone {
	light: hex(0x6B_4F_A0),
	dark: hex(0xBB_A6_EC),
};
/// Muted ink: streets and quiet doodles.
pub const MUTED: Tone = Tone {
	light: hex(0xB9_AC_BF),
	dark: hex(0x73_66_78),
};

/// The pin's silhouette on the 512 artboard.
pub const MARK_PIN: &str = "M 240 486 C 240 486 90 330.56 90 218 C 90 135.15 157.15 68 240 68 C \
                            322.85 68 390 135.15 390 218 C 390 330.56 240 486 240 486 Z";
/// The check knocked out of the pin's head. It runs past the rim on purpose,
/// so the long arm cuts the rim open.
pub const MARK_CHECK: &str = "M 162 230 L 220 292 L 457.3 2.5";
/// The long arm's flick outside the rim.
pub const MARK_FLICK: &str = "M 380.7 95.9 L 420 48";
/// The pen width of the check and the flick.
pub const MARK_PEN: f64 = 42.0;

/// The mark as inline SVG in `currentColor`, with `id` naming its knockout
/// mask so several marks can share a page.
///
/// With `draw` set, the check is written on and the flick lands after it;
/// `site.css` runs that motion and skips it under reduced motion.
pub fn mark_svg(id: &str, label: Option<&str>, draw: bool) -> String {
	let pen = MARK_PEN;
	let (role, title) = match label {
		Some(label) => (
			format!("role=\"img\" aria-label=\"{label}\""),
			format!("<title>{label}</title>"),
		),
		None => (
			"aria-hidden=\"true\" focusable=\"false\"".to_owned(),
			String::new(),
		),
	};
	let class = if draw { "mark mark-draw" } else { "mark" };
	format!(
		"<svg class=\"{class}\" viewBox=\"0 0 512 512\" {role}>{title}<defs><mask id=\"{id}\" \
		 maskUnits=\"userSpaceOnUse\" x=\"-64\" y=\"-64\" width=\"640\" height=\"640\"><rect \
		 x=\"-64\" y=\"-64\" width=\"640\" height=\"640\" fill=\"#fff\"/><path class=\"mark-check\" \
		 pathLength=\"1\" d=\"{MARK_CHECK}\" fill=\"none\" stroke=\"#000\" stroke-width=\"{pen}\" \
		 stroke-linecap=\"round\" stroke-linejoin=\"round\"/></mask></defs><path \
		 class=\"mark-pin\" d=\"{MARK_PIN}\" fill=\"currentColor\" mask=\"url(#{id})\"/><path \
		 class=\"mark-flick\" pathLength=\"1\" d=\"{MARK_FLICK}\" fill=\"none\" \
		 stroke=\"currentColor\" stroke-width=\"{pen}\" stroke-linecap=\"round\"/></svg>"
	)
}

/// The mark as a standalone favicon: vermilion on transparent, or the night
/// vermilion in a dark browser.
pub fn favicon_svg() -> String {
	format!(
		"<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 512 512\"><style>path{{color:#D13F22}}\
		 @media (prefers-color-scheme:dark){{path{{color:#F2856A}}}}</style><defs><mask id=\"k\" \
		 maskUnits=\"userSpaceOnUse\" x=\"-64\" y=\"-64\" width=\"640\" height=\"640\"><rect x=\"-64\" \
		 y=\"-64\" width=\"640\" height=\"640\" fill=\"#fff\"/><path d=\"{MARK_CHECK}\" fill=\"none\" \
		 stroke=\"#000\" stroke-width=\"54\" stroke-linecap=\"round\" \
		 stroke-linejoin=\"round\"/></mask></defs><path d=\"{MARK_PIN}\" fill=\"currentColor\" \
		 mask=\"url(#k)\"/><path d=\"{MARK_FLICK}\" fill=\"none\" stroke=\"currentColor\" \
		 stroke-width=\"54\" stroke-linecap=\"round\"/></svg>"
	)
}
