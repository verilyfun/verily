//! Verily's look in the app, from `DESIGN.md`: the Skribble pen, the type
//! scale, and the colour roles as Tailwind classes.
//!
//! Every colour comes from [`verily_ink`], which the site shares, and carries
//! its night twin as a `dark:` class, so the app follows the device's
//! appearance on every platform. Screens never write a colour of their own.

use skribble_leptoskit::Palette;
use skribble_leptoskit::Theme;
use skribble_leptoskit::Tone;
use verily_ink::tone_class;

/// The app's pen: plum ink on paper, ink as the filled accent, so the one
/// primary button on a screen is ink on paper and vermilion stays for
/// "verified" and the brand.
pub const PEN: Theme = verily_ink::APP;

/// Display: one plain promise per screen.
pub const DISPLAY: &str = "text-[40px] font-bold";
/// Headline: screen titles and big amounts.
pub const HEADLINE: &str = "text-[28px] font-bold";
/// Title: action names on cards.
pub const TITLE: &str = "text-[20px] font-bold";
/// Body: explanations, kept short.
pub const BODY: &str = "text-base";
/// Label: chips, place names, status words.
pub const LABEL: &str = "text-[14px] font-bold";

/// The page: a 16 point gutter and 24 points between groups.
pub const PAGE: &str = "flex flex-col gap-6 px-4 pt-6 pb-12";
/// Related items: 12 points apart.
pub const STACK: &str = "flex flex-col gap-3";
/// A row that wraps instead of clipping.
pub const ROW: &str = "flex flex-row flex-wrap items-center gap-3";

/// A colour role: its pen colour and the wash behind it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Role {
	/// Pins, radii, and "inside the place".
	Place,
	/// Escrowed rewards and payouts. Text on its wash stays ink.
	Reward,
	/// Anything a person decides.
	Review,
}

impl Role {
	/// The role's pen colour, for outlines and marks.
	#[must_use]
	pub const fn tone(self) -> Tone {
		match self {
			Self::Place => verily_ink::PLACE,
			Self::Reward => verily_ink::REWARD,
			Self::Review => verily_ink::REVIEW,
		}
	}

	/// The surface behind the role's content.
	#[must_use]
	pub const fn wash(self) -> Tone {
		match self {
			Self::Place => verily_ink::PLACE_WASH,
			Self::Reward => verily_ink::REWARD_WASH,
			Self::Review => verily_ink::REVIEW_WASH,
		}
	}

	/// [`PEN`] outlining in the role's colour.
	#[must_use]
	pub const fn pen(self) -> Theme {
		outlined(self.tone())
	}
}

/// [`PEN`] with its outlines in `tone`.
#[must_use]
pub const fn outlined(tone: Tone) -> Theme {
	Theme {
		light: Palette {
			ink: tone.light,
			..PEN.light
		},
		dark: Palette {
			ink: tone.dark,
			..PEN.dark
		},
		..PEN
	}
}

/// Ink text: plum on paper, paper on night.
#[must_use]
pub fn ink() -> String {
	tone_class("text", verily_ink::INK_TONE)
}

/// Secondary text: muted ink, or muted paper on night.
#[must_use]
pub fn muted() -> String {
	tone_class("text", verily_ink::MUTED_INK)
}

/// Text in a role's colour, for labels large enough to carry it.
#[must_use]
pub fn role_text(role: Role) -> String {
	tone_class("text", role.tone())
}

/// The page colour behind everything.
#[must_use]
pub fn paper() -> String {
	tone_class("bg", verily_ink::PAPER)
}

/// Every fixed class string, so a test can reject one the renderer does not
/// know.
#[must_use]
pub fn class_sheet() -> Vec<String> {
	let mut sheet = [DISPLAY, HEADLINE, TITLE, BODY, LABEL, PAGE, STACK, ROW]
		.map(str::to_owned)
		.to_vec();
	sheet.extend([ink(), muted(), paper()]);
	sheet.extend([Role::Place, Role::Reward, Role::Review].map(role_text));
	sheet
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn primary_fills_are_ink_not_vermilion() {
		assert_eq!(PEN.light.accent, verily_ink::INK_TONE.light);
		assert_eq!(PEN.dark.accent, verily_ink::INK_TONE.dark);
		for role in [Role::Place, Role::Reward, Role::Review] {
			assert_ne!(role.pen().light.accent, verily_ink::STAMP.light);
		}
	}

	#[test]
	fn roles_outline_in_their_colour_and_keep_the_paper() {
		let place = Role::Place.pen();
		assert_eq!(place.light.ink, verily_ink::PLACE.light);
		assert_eq!(place.dark.ink, verily_ink::PLACE.dark);
		assert_eq!(place.light.paper, PEN.light.paper);
	}

	#[test]
	fn colours_follow_the_device_appearance() {
		assert_eq!(ink(), "text-[#34283f] dark:text-[#fffaf0]");
		assert_eq!(paper(), "bg-[#fffaf0] dark:bg-[#292331]");
	}
}
