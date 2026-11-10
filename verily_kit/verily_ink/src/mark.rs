//! The pin-check mark as native vectors.

use leptoskit::native::Element;
use leptoskit::native::Paint;
use leptoskit::native::PathData;
use leptoskit::native::Stroke;
use leptoskit::native::VectorPath;
use leptoskit::native::VectorScaling;
use leptoskit::native::ViewBox;
use leptoskit::prelude::Vector;
use leptoskit::prelude::View;
use leptoskit::view;
use skribble_leptoskit::Tone;

use crate::brand::MARK_CHECK;
use crate::brand::MARK_FLICK;
use crate::brand::MARK_PEN;
use crate::brand::MARK_PIN;
use crate::brand::PAPER;
use crate::brand::STAMP;
use crate::brand::tone_class;

/// The pin-check, `size` pixels square, in vermilion on the page.
///
/// Native vectors have no masks, so the check is drawn in the page's own
/// colour over the pin: on paper or night paper it reads as the knockout.
/// Pass a `label` when the mark stands for Verily; without one it is
/// decorative and hidden from assistive technology.
#[must_use]
pub fn mark(size: f32, label: Option<&str>) -> Element {
	let pin = layer(
		STAMP,
		vec![
			VectorPath::new(path(MARK_PIN)).fill(Paint::CurrentColor),
			pen(MARK_FLICK),
		],
	);
	let knockout = layer(PAPER, vec![pen(MARK_CHECK)]);
	let class = format!("relative w-[{size}px] h-[{size}px]");
	let frame = view! {
		<View class=class>
			{pin}
			{knockout}
		</View>
	};
	match label {
		Some(label) => frame.aria_label(label.to_owned()),
		None => frame.aria_hidden(true),
	}
}

fn layer(tone: Tone, paths: Vec<VectorPath>) -> Element {
	let view_box = ViewBox::new(0.0, 0.0, 512.0, 512.0).expect("the mark's artboard is 512 square");
	let class = format!(
		"absolute top-0 left-0 w-full h-full {}",
		tone_class("text", tone)
	);
	let drawn = view! {
		<Vector view_box=view_box scaling=VectorScaling::Fit class=class aria_hidden=true />
	};
	paths.into_iter().fold(drawn, Element::path)
}

fn pen(data: &str) -> VectorPath {
	VectorPath::new(path(data)).stroke(
		Stroke::new(Paint::CurrentColor, MARK_PEN as f32)
			.expect("the mark's pen is positive")
			.round(),
	)
}

fn path(data: &str) -> PathData {
	PathData::parse(data).expect("the mark's paths are valid path data")
}
