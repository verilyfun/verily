//! The hand-drawn pictures: maps, jars, viewfinders, stamps, and arrows.
//!
//! Each is a leptoskit element drawn with Skribble's seeded pen, so the same
//! seed always wobbles the same way. They are decorative unless they carry a
//! label, and they recolour themselves on night paper.

use leptoskit::prelude::*;
use skribble_leptoskit::FillStyle;
use skribble_leptoskit::RoughPen;
use skribble_leptoskit::Shape;
use skribble_leptoskit::Sketch;
use skribble_leptoskit::Tone;

use crate::brand;

fn sketch(width: f32, height: f32, seed: i64, shapes: Vec<Shape>) -> Element {
	view! { <Sketch width=width height=height shapes=shapes seed=seed theme=brand::INK /> }
}

fn tinted(width: f32, height: f32, seed: i64, stroke: Tone, shapes: Vec<Shape>) -> Element {
	view! { <Sketch width=width height=height shapes=shapes seed=seed theme=brand::INK stroke=stroke /> }
}

fn filled(
	width: f32,
	height: f32,
	seed: i64,
	stroke: Tone,
	fill: Tone,
	fill_style: FillStyle,
	shapes: Vec<Shape>,
) -> Element {
	view! {
		<Sketch
			width=width
			height=height
			shapes=shapes
			seed=seed
			theme=brand::INK
			stroke=stroke
			fill=fill
			fill_style=fill_style
		/>
	}
}

/// Pins a sketch at its own size inside a positioned parent.
fn layer(at: &str, element: Element) -> Element {
	view! { <View class=format!("absolute {at}")>{element}</View> }
}

/// A sketched street map with the place's hatched radius and a pin in the
/// middle: where the action happens.
pub fn place_map(seed: i64) -> Element {
	let streets = vec![
		Shape::curve([(0.0, 52.0), (90.0, 64.0), (180.0, 46.0), (300.0, 70.0)]),
		Shape::curve([(0.0, 168.0), (110.0, 150.0), (200.0, 178.0), (300.0, 160.0)]),
		Shape::curve([(64.0, 0.0), (74.0, 90.0), (58.0, 150.0), (70.0, 220.0)]),
		Shape::curve([(232.0, 0.0), (222.0, 80.0), (240.0, 150.0), (226.0, 220.0)]),
		Shape::line((0.0, 214.0), (120.0, 120.0)),
	];
	let radius = vec![Shape::Circle { x: 150.0, y: 110.0, diameter: 132.0 }];
	let pin = vec![
		Shape::curve([(150.0, 112.0), (134.0, 92.0), (128.0, 80.0), (132.0, 70.0)]),
		Shape::curve([(132.0, 70.0), (140.0, 54.0), (160.0, 54.0), (168.0, 70.0)]),
		Shape::curve([(168.0, 70.0), (172.0, 80.0), (166.0, 92.0), (150.0, 112.0)]),
		Shape::Circle { x: 150.0, y: 74.0, diameter: 12.0 },
	];
	view! {
		<View class="relative w-[300px] h-[220px]" aria_hidden=true>
			{layer("left-0 top-0", tinted(300.0, 220.0, seed, brand::MUTED, streets))}
			{layer(
				"left-0 top-0",
				filled(300.0, 220.0, seed + 1, brand::PLACE, brand::PLACE, FillStyle::Hachure, radius),
			)}
			{layer(
				"left-0 top-0",
				filled(300.0, 220.0, seed + 2, brand::PLACE, brand::PLACE, FillStyle::Solid, pin),
			)}
		</View>
	}
}

/// A jar with coins in it and a padlock on the lid: the reward, already in
/// escrow.
pub fn escrow_jar(seed: i64) -> Element {
	let jar = vec![
		Shape::RoundedRectangle {
			x: 40.0,
			y: 46.0,
			width: 120.0,
			height: 124.0,
			radii: [22.0, 22.0, 30.0, 30.0],
		},
		Shape::RoundedRectangle { x: 50.0, y: 34.0, width: 100.0, height: 16.0, radii: [6.0; 4] },
	];
	let coins = vec![
		Shape::Ellipse { x: 80.0, y: 146.0, width: 46.0, height: 22.0 },
		Shape::Ellipse { x: 120.0, y: 140.0, width: 46.0, height: 22.0 },
		Shape::Ellipse { x: 100.0, y: 122.0, width: 46.0, height: 22.0 },
		Shape::Ellipse { x: 86.0, y: 102.0, width: 46.0, height: 22.0 },
	];
	let lock = vec![
		Shape::RoundedRectangle { x: 84.0, y: 30.0, width: 32.0, height: 26.0, radii: [5.0; 4] },
		Shape::curve([(90.0, 30.0), (89.0, 12.0), (111.0, 12.0), (110.0, 30.0)]),
		Shape::Circle { x: 100.0, y: 42.0, diameter: 6.0 },
	];
	view! {
		<View class="relative w-[200px] h-[180px]" aria_hidden=true>
			{layer(
				"left-0 top-0",
				filled(200.0, 180.0, seed, brand::REWARD, brand::REWARD, FillStyle::Hachure, coins),
			)}
			{layer("left-0 top-0", sketch(200.0, 180.0, seed + 1, jar))}
			{layer("left-0 top-0", sketch(200.0, 180.0, seed + 2, lock))}
		</View>
	}
}

/// The camera's corner brackets on night paper, with nothing in the middle:
/// no face boxes, no grids.
pub fn viewfinder(width: f32, height: f32, seed: i64) -> Element {
	let arm = 34.0_f64;
	let (w, h) = (f64::from(width), f64::from(height));
	let inset = 14.0;
	let corners = vec![
		Shape::linear_path([(inset, inset + arm), (inset, inset), (inset + arm, inset)]),
		Shape::linear_path([(w - inset - arm, inset), (w - inset, inset), (w - inset, inset + arm)]),
		Shape::linear_path([(inset, h - inset - arm), (inset, h - inset), (inset + arm, h - inset)]),
		Shape::linear_path([
			(w - inset - arm, h - inset),
			(w - inset, h - inset),
			(w - inset, h - inset - arm),
		]),
	];
	let paper = Tone::fixed(brand::INK.light.paper);
	view! {
		<View class="absolute left-0 top-0" aria_hidden=true>
			<Sketch
				width=width
				height=height
				shapes=corners
				seed=seed
				theme=brand::INK
				stroke=paper
				pen=RoughPen::FINELINER
			/>
		</View>
	}
}

/// The verified stamp: a double ring and the brand check, pressed at an
/// angle. Only ever pressed onto proof that passed.
pub fn stamp(size: f32, seed: i64) -> Element {
	let s = f64::from(size);
	let c = s / 2.0;
	let rings = vec![
		Shape::Circle { x: c, y: c, diameter: s * 0.94 },
		Shape::Circle { x: c, y: c, diameter: s * 0.78 },
	];
	let check = vec![Shape::curve([
		(s * 0.3, s * 0.5),
		(s * 0.38, s * 0.58),
		(s * 0.45, s * 0.66),
		(s * 0.56, s * 0.52),
		(s * 0.72, s * 0.3),
	])];
	view! {
		<View class=format!("relative w-[{size}px] h-[{size}px]")>
			{layer("left-0 top-0", tinted(size, size, seed, brand::STAMP, rings))}
			<View class="absolute left-0 top-0">
				<Sketch
					width=size
					height=size
					shapes=check
					seed=seed + 1
					theme=brand::INK
					stroke=brand::STAMP
					pen=RoughPen::BRUSH
				/>
			</View>
		</View>
	}
}

/// A doodled arrow from left to right that curls down at the end.
pub fn arrow(width: f32, height: f32, seed: i64) -> Element {
	let (w, h) = (f64::from(width), f64::from(height));
	let shapes = vec![
		Shape::curve([(4.0, h * 0.3), (w * 0.35, h * 0.05), (w * 0.7, h * 0.2), (w - 6.0, h - 6.0)])
			.with_arrowhead(),
	];
	view! {
		<View aria_hidden=true>
			<Sketch width=width height=height shapes=shapes seed=seed theme=brand::INK />
		</View>
	}
}

/// A doodled arrow that rises from the bottom left and points up and to the
/// right, curling as it goes.
pub fn arrow_up(width: f32, height: f32, seed: i64) -> Element {
	let (w, h) = (f64::from(width), f64::from(height));
	let shapes = vec![
		Shape::curve([(6.0, h - 6.0), (w * 0.15, h * 0.35), (w * 0.55, h * 0.2), (w - 6.0, 8.0)])
			.with_arrowhead(),
	];
	view! {
		<View aria_hidden=true>
			<Sketch width=width height=height shapes=shapes seed=seed theme=brand::INK />
		</View>
	}
}

/// A hand-drawn underline, as wide as the words it sits under.
pub fn underline(width: f32, seed: i64, tone: Tone) -> Element {
	let w = f64::from(width);
	let shapes = vec![Shape::curve([(2.0, 10.0), (w * 0.3, 4.0), (w * 0.7, 12.0), (w - 2.0, 5.0)])];
	view! {
		<View aria_hidden=true>
			<Sketch
				width=width
				height=16.0
				shapes=shapes
				seed=seed
				theme=brand::INK
				stroke=tone
				pen=RoughPen::BRUSH
			/>
		</View>
	}
}

/// A ticked checkbox in ink with the check in vermilion, as the proof
/// checklist draws it.
pub fn tick(seed: i64) -> Element {
	let boxed = vec![Shape::RoundedRectangle { x: 3.0, y: 5.0, width: 24.0, height: 24.0, radii: [5.0; 4] }];
	let check = vec![Shape::curve([(8.0, 17.0), (12.0, 22.0), (15.0, 25.0), (22.0, 12.0), (32.0, 2.0)])];
	view! {
		<View class="relative w-[34px] h-[32px]" aria_hidden=true>
			{layer("left-0 top-0", sketch(34.0, 32.0, seed, boxed))}
			<View class="absolute left-0 top-0">
				<Sketch
					width=34.0
					height=32.0
					shapes=check
					seed=seed + 1
					theme=brand::INK
					stroke=brand::STAMP
					pen=RoughPen::BRUSH
				/>
			</View>
		</View>
	}
}

/// A speech bubble's outline, for the live challenge.
pub fn bubble(width: f32, height: f32, seed: i64) -> Element {
	let (w, h) = (f64::from(width), f64::from(height));
	let shapes = vec![Shape::polygon([
		(10.0, 6.0),
		(w - 8.0, 4.0),
		(w - 4.0, h - 18.0),
		(42.0, h - 16.0),
		(22.0, h - 2.0),
		(26.0, h - 17.0),
		(6.0, h - 18.0),
	])];
	let paper = Tone::fixed(brand::INK.light.paper);
	view! {
		<View class="absolute left-0 top-0" aria_hidden=true>
			<Sketch
				width=width
				height=height
				shapes=shapes
				seed=seed
				theme=brand::INK
				stroke=paper
				fill=paper
				fill_style=FillStyle::Solid
			/>
		</View>
	}
}

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
	let motion = if when_seen { motion.in_view(ViewRange::entry()) } else { motion };
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

/// A step's number, circled by hand.
pub fn step_number(number: usize, seed: i64) -> Element {
	view! {
		<skribble_leptoskit::WiredCircle seed=seed theme=brand::INK class="size-14">
			<Text class="text-xl font-bold">{number.to_string()}</Text>
		</skribble_leptoskit::WiredCircle>
	}
}
