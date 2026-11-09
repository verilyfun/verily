//! Verily's palette for ink: the Skribble theme and the role tones from
//! `DESIGN.md`, and the pin-check mark.
//!
//! These are the only raw colours outside the site's stylesheet tokens. Every
//! tone carries its night twin, so ink recolours itself on night paper.

use leptoskit::native::Color;
use skribble_leptoskit::Palette;
use skribble_leptoskit::Theme;
use skribble_leptoskit::Tone;

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

/// The app's pen: the same paper and ink, with ink as the accent, so the one
/// filled button on a screen is ink on paper (paper on night) and vermilion
/// stays for "verified" and the brand.
pub const APP: Theme = Theme {
	light: Palette {
		accent: hex(0x34_28_3F),
		on_accent: hex(0xFF_FA_F0),
		..INK.light
	},
	dark: Palette {
		accent: hex(0xFF_FA_F0),
		on_accent: hex(0x29_23_31),
		..INK.dark
	},
	stroke_width: 2.6,
	roughness: 1.0,
};

/// Plum ink, or paper on night: text and outlines.
pub const INK_TONE: Tone = Tone {
	light: hex(0x34_28_3F),
	dark: hex(0xFF_FA_F0),
};
/// The page: floral paper, or night paper.
pub const PAPER: Tone = Tone {
	light: hex(0xFF_FA_F0),
	dark: hex(0x29_23_31),
};
/// Secondary text: muted ink, or muted paper on night.
pub const MUTED_INK: Tone = Tone {
	light: hex(0x73_66_78),
	dark: hex(0xB9_AC_BF),
};
/// Dusk: fills and selections on night paper, and the camera's HUD.
pub const DUSK: Tone = Tone::fixed(hex(0x4A_3B_5E));
/// Paper-coloured ink in both appearances: words on the camera, which stays
/// dark.
pub const CHALK: Tone = Tone::fixed(hex(0xFF_FA_F0));
/// Plum ink in both appearances: words on a paper bubble over the camera.
pub const CHALK_INK: Tone = Tone::fixed(hex(0x34_28_3F));
/// Night paper in both appearances: the camera's viewfinder.
pub const NIGHT: Tone = Tone::fixed(hex(0x29_23_31));
/// The surface behind place content.
pub const PLACE_WASH: Tone = Tone {
	light: hex(0xDD_EA_D9),
	dark: hex(0x24_38_2F),
};
/// The surface behind a reward. Text on it is ink, never gold.
pub const REWARD_WASH: Tone = Tone {
	light: hex(0xF6_E8_AF),
	dark: hex(0x3B_32_20),
};
/// The surface behind anything a person decides.
pub const REVIEW_WASH: Tone = Tone {
	light: hex(0xE5_DD_F4),
	dark: hex(0x35_2B_4B),
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

/// A Tailwind utility for `tone` in both appearances, such as
/// `text-[#34283f] dark:text-[#fffaf0]`.
#[must_use]
pub fn tone_class(utility: &str, tone: Tone) -> String {
	let light = format!("{utility}-[{}]", hex_of(tone.light));
	if tone.light == tone.dark {
		light
	} else {
		format!("{light} dark:{utility}-[{}]", hex_of(tone.dark))
	}
}

fn hex_of(color: Color) -> String {
	format!(
		"#{:02x}{:02x}{:02x}",
		color.red(),
		color.green(),
		color.blue()
	)
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn the_app_never_fills_with_vermilion() {
		assert_ne!(APP.light.accent, STAMP.light);
		assert_ne!(APP.dark.accent, STAMP.dark);
		assert_eq!(APP.light.accent, INK_TONE.light);
		assert_eq!(APP.dark.accent, INK_TONE.dark);
	}

	#[test]
	fn tones_write_both_appearances() {
		assert_eq!(
			tone_class("text", INK_TONE),
			"text-[#34283f] dark:text-[#fffaf0]"
		);
		assert_eq!(tone_class("bg", DUSK), "bg-[#4a3b5e]");
	}
}
