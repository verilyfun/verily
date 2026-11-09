//! Verily's hand-drawn brand for leptoskit.
//!
//! The landing page and the app draw with the same pen: the Skribble themes,
//! the role tones from `DESIGN.md`, the mark's geometry, and the pictures in
//! [`draw`]. These are the only raw colours either of them draws with.
//!
//! Two themes share one page. [`INK`] is the brand's: its accent is the
//! verified vermilion, so highlights and stamps drawn with it mean
//! "verified". [`ACTION`] is for controls: its accent is ink, so a primary
//! button is ink on paper (paper on night), and vermilion never marks
//! anything that is not verified.

pub mod draw;

use leptoskit::native::Color;
use skribble_leptoskit::Palette;
use skribble_leptoskit::Theme;
use skribble_leptoskit::Tone;

const fn hex(rgb: u32) -> Color {
	Color::rgba((rgb >> 16) as u8, (rgb >> 8) as u8, rgb as u8, 0xff)
}

const PAPER: Color = hex(0xFF_FA_F0);
const NIGHT: Color = hex(0x29_23_31);
const PLUM: Color = hex(0x34_28_3F);

/// Plum ink on floral paper, with the night page in dark mode. The accent is
/// the verified vermilion.
pub const INK: Theme = Theme {
	light: Palette {
		ink: PLUM,
		paper: PAPER,
		accent: hex(0xD1_3F_22),
		on_accent: PAPER,
	},
	dark: Palette {
		ink: PAPER,
		paper: NIGHT,
		accent: hex(0xF2_85_6A),
		on_accent: NIGHT,
	},
	stroke_width: 2.2,
	roughness: 1.1,
};

/// The theme controls draw with: the same paper and pen as [`INK`], with ink
/// as the accent, so a primary button is filled with ink rather than
/// vermilion.
pub const ACTION: Theme = Theme {
	light: Palette {
		accent: PLUM,
		on_accent: PAPER,
		..INK.light
	},
	dark: Palette {
		accent: PAPER,
		on_accent: NIGHT,
		..INK.dark
	},
	..INK
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
/// The wash behind a place.
pub const PLACE_WASH: Tone = Tone {
	light: hex(0xDD_EA_D9),
	dark: hex(0x2F_6B_4F),
};
/// Reward gold: coins and the escrow jar.
pub const REWARD: Tone = Tone {
	light: hex(0x9A_6A_12),
	dark: hex(0xE6_BC_5C),
};
/// The butter wash behind a reward.
pub const REWARD_WASH: Tone = Tone {
	light: hex(0xF6_E8_AF),
	dark: hex(0x9A_6A_12),
};
/// Review violet: anything a person decides.
pub const REVIEW: Tone = Tone {
	light: hex(0x6B_4F_A0),
	dark: hex(0xBB_A6_EC),
};
/// The wash behind something a person decides.
pub const REVIEW_WASH: Tone = Tone {
	light: hex(0xE5_DD_F4),
	dark: hex(0x6B_4F_A0),
};
/// Muted ink: streets and quiet doodles.
pub const MUTED: Tone = Tone {
	light: hex(0xB9_AC_BF),
	dark: hex(0x73_66_78),
};
/// The page itself, for marks cut out of ink.
pub const PAGE: Tone = Tone {
	light: PAPER,
	dark: NIGHT,
};
/// Paper in both appearances, for the HUD over the night viewfinder.
pub const HUD: Tone = Tone::fixed(PAPER);

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

/// Text and outlines: plum on paper, paper on night.
pub const TEXT: Tone = INK.ink();
/// Secondary text: 5.17:1 on paper and 7.05:1 on night.
pub const MUTED_TEXT: Tone = Tone {
	light: hex(0x73_66_78),
	dark: hex(0xB9_AC_BF),
};
/// The viewfinder's night page, in both appearances.
pub const NIGHT_PAGE: Tone = Tone::fixed(NIGHT);

/// A Tailwind utility painting with `tone` in both appearances, such as
/// `text-[#34283f] dark:text-[#fffaf0]`.
#[must_use]
pub fn class(utility: &str, tone: Tone) -> String {
	let light = format!("{utility}-[{}]", css_hex(tone.light));
	if tone.light == tone.dark {
		light
	} else {
		format!("{light} dark:{utility}-[{}]", css_hex(tone.dark))
	}
}

fn css_hex(color: Color) -> String {
	format!(
		"#{:02x}{:02x}{:02x}",
		color.red(),
		color.green(),
		color.blue()
	)
}
