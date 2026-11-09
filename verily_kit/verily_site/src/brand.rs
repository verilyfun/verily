//! Verily's brand for the site: the colour tokens from `DESIGN.md` as CSS
//! custom properties, and the mark as inline SVG. The Skribble theme and the
//! tones come from [`verily_ink`], which the app shares.
//!
//! These are the only raw colours in the site. The page and its stylesheet
//! use the CSS custom properties [`TOKENS_CSS`] declares.

pub use verily_ink::INK;
pub use verily_ink::MARK_CHECK;
pub use verily_ink::MARK_FLICK;
pub use verily_ink::MARK_PEN;
pub use verily_ink::MARK_PIN;
pub use verily_ink::MUTED;
pub use verily_ink::PLACE;
pub use verily_ink::REVIEW;
pub use verily_ink::REWARD;
pub use verily_ink::STAMP;

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
