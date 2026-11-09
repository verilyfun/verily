//! The landing page's pictures. The drawings themselves live in
//! [`verily_ink::draw`], which the app shares; this module adds the page's
//! motion: the slammed stamp and pictures rising into view.

use leptoskit::prelude::*;
pub use verily_ink::draw::*;

use crate::brand;

/// "Prove it." circled by hand in vermilion.
pub fn prove_it() -> Element {
	view! {
		<skribble_leptoskit::WiredHighlight
			kind=skribble_leptoskit::HighlightKind::Circle
			seed=7
			color=brand::STAMP
			theme=brand::INK
		>
			<Text class="px-2">"Prove it."</Text>
		</skribble_leptoskit::WiredHighlight>
	}
}

/// The stamp, slammed down once with a bounce, `delay` after it's seen.
pub fn slammed_stamp(size: f32, seed: i64, delay_ms: u64, when_seen: bool) -> Element {
	let motion = Motion::enter(Pose::new().scale(2.2).rotate(-24.0).opacity(0.0))
		.spring(Spring::BOUNCY)
		.delay(std::time::Duration::from_millis(delay_ms));
	let motion = if when_seen {
		motion.in_view(ViewRange::entry())
	} else {
		motion
	};
	view! { <View motion=motion>{stamp(size, seed)}</View> }
}

/// A picture that rises into place, tilting the way `seed` says, as it
/// scrolls into view.
pub fn rising(element: Element, seed: i64) -> Element {
	let tilt = if seed % 2 == 0 { 2.0 } else { -2.0 };
	let motion = Motion::enter(Pose::new().y(28.0).rotate(tilt).opacity(0.0))
		.spring(Spring::GENTLE)
		.in_view(ViewRange::entry());
	view! { <View motion=motion>{element}</View> }
}
