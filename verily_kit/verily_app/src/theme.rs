//! Verily's look for the screens: the Skribble themes and the class strings,
//! all built from the tones in [`verily_ink`].
//!
//! Screens paint with these and with Skribble's `Wired` components. They
//! write no colour of their own, and every colour follows the phone's light
//! or dark appearance, the same switch Skribble's ink follows.

use std::sync::LazyLock;

pub use verily_ink::ACTION;
pub use verily_ink::INK;
use verily_ink::class;

macro_rules! classes {
	($($(#[$doc:meta])* $name:ident = $build:expr;)*) => {
		$(
			$(#[$doc])*
			pub static $name: LazyLock<String> = LazyLock::new(|| $build);
		)*

		/// Every shared class string, so a test can reject one the renderer
		/// does not know.
		#[must_use]
		pub fn class_sheet() -> Vec<&'static str> {
			vec![$($name.as_str()),*]
		}
	};
}

classes! {
	/// The page: a 16dp gutter and room between groups.
	PAGE = "flex flex-col gap-6 px-4 pt-4 pb-8".to_owned();
	/// One plain promise at the top of a screen.
	DISPLAY = format!("text-4xl font-bold {}", class("text", verily_ink::TEXT));
	/// An action's name or a section's title.
	TITLE = format!("text-xl font-bold {}", class("text", verily_ink::TEXT));
	/// Explanations, kept short.
	BODY = format!("text-base {}", class("text", verily_ink::TEXT));
	/// Secondary copy.
	MUTED = format!("text-sm {}", class("text", verily_ink::MUTED_TEXT));
	/// Chips, place names, and status words.
	LABEL = format!("text-sm font-bold {}", class("text", verily_ink::TEXT));
	/// A place's name, in place green.
	PLACE_LABEL = format!("text-sm font-bold {}", class("text", verily_ink::PLACE));
	/// Related items, 12dp apart.
	STACK = "flex flex-col gap-3".to_owned();
	/// Items side by side that wrap rather than clip.
	ROW = "flex flex-row flex-wrap items-center gap-2".to_owned();
	/// A row that keeps its drawing beside its words.
	LINE = "flex flex-row items-center gap-3".to_owned();
	/// The camera's night page.
	FINDER = format!(
		"relative h-72 w-full overflow-hidden rounded-3xl {}",
		class("bg", verily_ink::NIGHT_PAGE)
	);
	/// Words on the viewfinder.
	HUD = format!("text-sm font-bold {}", class("text", verily_ink::HUD));
	/// The dot beside "Live".
	HUD_DOT = format!("size-2 rounded-full {}", class("bg", verily_ink::HUD));
	/// The live challenge, large, over the viewfinder.
	HUD_WORD = format!("text-2xl font-bold {}", class("text", verily_ink::INK.light.ink.into()));
	/// The tab bar under the roots.
	TABS = "flex flex-row items-center justify-between gap-2 pt-2".to_owned();
}
