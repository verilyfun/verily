//! Verily's ink, shared by the app and the site.
//!
//! [`brand`] holds the palette from `DESIGN.md` as Skribble tones, and the
//! pin-check mark. [`sketches`] holds the hand-drawn pictures: the place map,
//! the escrow jar, the viewfinder, the verified stamp, ticks, arrows, and
//! bubbles. Everything is a leptoskit element drawn with Skribble's seeded
//! pen, so the browser and every native host draw the same wobble.

pub mod brand;
mod mark;
pub mod sketches;

pub use brand::*;
pub use mark::mark;
pub use skribble_leptoskit::Tone;
