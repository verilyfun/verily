//! The hand-drawn pictures: the mark, maps, jars, viewfinders, stamps, and
//! arrows.
//!
//! Each is a leptoskit element drawn with Skribble's seeded pen, so the same
//! seed always wobbles the same way, on the web and on every native backend.
//! They are decorative unless they carry a label, and they recolour
//! themselves on night paper.

use leptoskit::prelude::*;
use skribble_leptoskit::FillStyle;
use skribble_leptoskit::RoughPen;
use skribble_leptoskit::Shape;
use skribble_leptoskit::Sketch;
use skribble_leptoskit::Tone;

fn sketch(width: f32, height: f32, seed: i64, shapes: Vec<Shape>) -> Element {
	view! { <Sketch width=width height=height shapes=shapes seed=seed theme=crate::INK /> }
}

fn tinted(width: f32, height: f32, seed: i64, stroke: Tone, shapes: Vec<Shape>) -> Element {
	view! { <Sketch width=width height=height shapes=shapes seed=seed theme=crate::INK stroke=stroke /> }
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
			theme=crate::INK
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
	let radius = vec![Shape::Circle {
		x: 150.0,
		y: 110.0,
		diameter: 132.0,
	}];
	let pin = vec![
		Shape::curve([(150.0, 112.0), (134.0, 92.0), (128.0, 80.0), (132.0, 70.0)]),
		Shape::curve([(132.0, 70.0), (140.0, 54.0), (160.0, 54.0), (168.0, 70.0)]),
		Shape::curve([(168.0, 70.0), (172.0, 80.0), (166.0, 92.0), (150.0, 112.0)]),
		Shape::Circle {
			x: 150.0,
			y: 74.0,
			diameter: 12.0,
		},
	];
	view! {
		<View class="relative w-[300px] h-[220px]" aria_hidden=true>
			{layer("left-0 top-0", tinted(300.0, 220.0, seed, crate::MUTED, streets))}
			{layer(
				"left-0 top-0",
				filled(300.0, 220.0, seed + 1, crate::PLACE, crate::PLACE, FillStyle::Hachure, radius),
			)}
			{layer(
				"left-0 top-0",
				filled(300.0, 220.0, seed + 2, crate::PLACE, crate::PLACE, FillStyle::Solid, pin),
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
		Shape::RoundedRectangle {
			x: 50.0,
			y: 34.0,
			width: 100.0,
			height: 16.0,
			radii: [6.0; 4],
		},
	];
	let coins = vec![
		Shape::Ellipse {
			x: 80.0,
			y: 146.0,
			width: 46.0,
			height: 22.0,
		},
		Shape::Ellipse {
			x: 120.0,
			y: 140.0,
			width: 46.0,
			height: 22.0,
		},
		Shape::Ellipse {
			x: 100.0,
			y: 122.0,
			width: 46.0,
			height: 22.0,
		},
		Shape::Ellipse {
			x: 86.0,
			y: 102.0,
			width: 46.0,
			height: 22.0,
		},
	];
	let lock = vec![
		Shape::RoundedRectangle {
			x: 84.0,
			y: 30.0,
			width: 32.0,
			height: 26.0,
			radii: [5.0; 4],
		},
		Shape::curve([(90.0, 30.0), (89.0, 12.0), (111.0, 12.0), (110.0, 30.0)]),
		Shape::Circle {
			x: 100.0,
			y: 42.0,
			diameter: 6.0,
		},
	];
	view! {
		<View class="relative w-[200px] h-[180px]" aria_hidden=true>
			{layer(
				"left-0 top-0",
				filled(200.0, 180.0, seed, crate::REWARD, crate::REWARD, FillStyle::Hachure, coins),
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
		Shape::linear_path([
			(w - inset - arm, inset),
			(w - inset, inset),
			(w - inset, inset + arm),
		]),
		Shape::linear_path([
			(inset, h - inset - arm),
			(inset, h - inset),
			(inset + arm, h - inset),
		]),
		Shape::linear_path([
			(w - inset - arm, h - inset),
			(w - inset, h - inset),
			(w - inset, h - inset - arm),
		]),
	];
	let paper = Tone::fixed(crate::INK.light.paper);
	view! {
		<View class="absolute left-0 top-0" aria_hidden=true>
			<Sketch
				width=width
				height=height
				shapes=corners
				seed=seed
				theme=crate::INK
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
		Shape::Circle {
			x: c,
			y: c,
			diameter: s * 0.94,
		},
		Shape::Circle {
			x: c,
			y: c,
			diameter: s * 0.78,
		},
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
			{layer("left-0 top-0", tinted(size, size, seed, crate::STAMP, rings))}
			<View class="absolute left-0 top-0">
				<Sketch
					width=size
					height=size
					shapes=check
					seed=seed + 1
					theme=crate::INK
					stroke=crate::STAMP
					pen=RoughPen::BRUSH
				/>
			</View>
		</View>
	}
}

/// A doodled arrow that rises from the bottom left and points up and to the
/// right, curling as it goes.
pub fn arrow_up(width: f32, height: f32, seed: i64) -> Element {
	let (w, h) = (f64::from(width), f64::from(height));
	let shapes = vec![
		Shape::curve([
			(6.0, h - 6.0),
			(w * 0.15, h * 0.35),
			(w * 0.55, h * 0.2),
			(w - 6.0, 8.0),
		])
		.with_arrowhead(),
	];
	view! {
		<View aria_hidden=true>
			<Sketch width=width height=height shapes=shapes seed=seed theme=crate::INK />
		</View>
	}
}

/// A hand-drawn underline, as wide as the words it sits under.
pub fn underline(width: f32, seed: i64, tone: Tone) -> Element {
	let w = f64::from(width);
	let shapes = vec![Shape::curve([
		(2.0, 10.0),
		(w * 0.3, 4.0),
		(w * 0.7, 12.0),
		(w - 2.0, 5.0),
	])];
	view! {
		<View aria_hidden=true>
			<Sketch
				width=width
				height=16.0
				shapes=shapes
				seed=seed
				theme=crate::INK
				stroke=tone
				pen=RoughPen::BRUSH
			/>
		</View>
	}
}

/// A ticked checkbox in ink with the check in vermilion, as the proof
/// checklist draws it.
pub fn tick(seed: i64) -> Element {
	let boxed = vec![Shape::RoundedRectangle {
		x: 3.0,
		y: 5.0,
		width: 24.0,
		height: 24.0,
		radii: [5.0; 4],
	}];
	let check = vec![Shape::curve([
		(8.0, 17.0),
		(12.0, 22.0),
		(15.0, 25.0),
		(22.0, 12.0),
		(32.0, 2.0),
	])];
	view! {
		<View class="relative w-[34px] h-[32px]" aria_hidden=true>
			{layer("left-0 top-0", sketch(34.0, 32.0, seed, boxed))}
			<View class="absolute left-0 top-0">
				<Sketch
					width=34.0
					height=32.0
					shapes=check
					seed=seed + 1
					theme=crate::INK
					stroke=crate::STAMP
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
	let paper = Tone::fixed(crate::INK.light.paper);
	view! {
		<View class="absolute left-0 top-0" aria_hidden=true>
			<Sketch
				width=width
				height=height
				shapes=shapes
				seed=seed
				theme=crate::INK
				stroke=paper
				fill=paper
				fill_style=FillStyle::Solid
			/>
		</View>
	}
}

/// A step's number, circled by hand.
pub fn step_number(number: usize, seed: i64) -> Element {
	view! {
		<skribble_leptoskit::WiredCircle seed=seed theme=crate::INK class="size-14">
			<Text class="text-xl font-bold">{number.to_string()}</Text>
		</skribble_leptoskit::WiredCircle>
	}
}

/// The pin's outline on the 512 artboard, as the cubic segments of
/// [`crate::MARK_PIN`]: tip, left shoulder, crown, right shoulder, tip.
const PIN_SEGMENTS: [[(f64, f64); 4]; 4] = [
	[
		(240.0, 486.0),
		(240.0, 486.0),
		(90.0, 330.56),
		(90.0, 218.0),
	],
	[(90.0, 218.0), (90.0, 135.15), (157.15, 68.0), (240.0, 68.0)],
	[
		(240.0, 68.0),
		(322.85, 68.0),
		(390.0, 135.15),
		(390.0, 218.0),
	],
	[
		(390.0, 218.0),
		(390.0, 330.56),
		(240.0, 486.0),
		(240.0, 486.0),
	],
];

/// The pin's outline as points `scale` times the artboard, `steps` to a
/// segment.
fn pin_outline(scale: f64, steps: usize) -> Vec<(f64, f64)> {
	let mut points = Vec::with_capacity(PIN_SEGMENTS.len() * steps);
	for [p0, p1, p2, p3] in PIN_SEGMENTS {
		for step in 0..steps {
			let t = step as f64 / steps as f64;
			let u = 1.0 - t;
			let (a, b, c, d) = (u * u * u, 3.0 * u * u * t, 3.0 * u * t * t, t * t * t);
			points.push((
				(a * p0.0 + b * p1.0 + c * p2.0 + d * p3.0) * scale,
				(a * p0.1 + b * p1.1 + c * p2.1 + d * p3.1) * scale,
			));
		}
	}
	points
}

/// The pin-check mark inked by hand: a solid vermilion pin with the check cut
/// out of its head in the page's colour, and the flick past the rim.
///
/// `label` names it for assistive technology; without one it is decorative.
/// Draw it on the page, not on a wash: the cut is the page showing through.
pub fn mark(size: f32, seed: i64, label: Option<&str>) -> Element {
	let scale = f64::from(size) / 512.0;
	let at = |x: f64, y: f64| (x * scale, y * scale);
	// The cut and the flick keep their optical weight at small sizes.
	let pen = if size <= 32.0 { 54.0 } else { crate::MARK_PEN };
	let cut_theme = skribble_leptoskit::Theme {
		stroke_width: (pen * scale) as f32,
		roughness: 0.6,
		..crate::INK
	};
	let pin = vec![Shape::polygon(pin_outline(scale, 10))];
	let cut = vec![Shape::linear_path([
		at(162.0, 230.0),
		at(220.0, 292.0),
		at(392.0, 82.0),
	])];
	let flick = vec![Shape::line(at(380.7, 95.9), at(420.0, 48.0))];
	let solid = skribble_leptoskit::Theme {
		roughness: 0.6,
		..crate::INK
	};
	let pin = view! {
		<Sketch
			width=size
			height=size
			shapes=pin
			seed=seed
			theme=solid
			stroke=crate::STAMP
			fill=crate::STAMP
			fill_style=FillStyle::Solid
		/>
	};
	let cut = view! {
		<Sketch
			width=size
			height=size
			shapes=cut
			seed=seed + 1
			theme=cut_theme
			stroke=crate::PAGE
			pen=RoughPen::UNIFORM
		/>
	};
	let flick = view! {
		<Sketch
			width=size
			height=size
			shapes=flick
			seed=seed + 2
			theme=cut_theme
			stroke=crate::STAMP
			pen=RoughPen::UNIFORM
		/>
	};
	let frame = format!("relative w-[{size}px] h-[{size}px] shrink-0");
	let body = view! {
		<View class=frame>
			{layer("left-0 top-0", pin)}
			{layer("left-0 top-0", cut)}
			{layer("left-0 top-0", flick)}
		</View>
	};
	match label {
		Some(label) => view! { <View aria_label=label.to_owned()>{body}</View> },
		None => view! { <View aria_hidden=true>{body}</View> },
	}
}

/// A small place pin in place green, for chips and rows.
pub fn pin(size: f32, seed: i64) -> Element {
	let scale = f64::from(size) / 512.0;
	let head = vec![Shape::polygon(pin_outline(scale, 6))];
	let hole = vec![Shape::Circle {
		x: 240.0 * scale,
		y: 218.0 * scale,
		diameter: 120.0 * scale,
	}];
	view! {
		<View class=format!("relative w-[{size}px] h-[{size}px] shrink-0") aria_hidden=true>
			{layer(
				"left-0 top-0",
				filled(size, size, seed, crate::PLACE, crate::PLACE, FillStyle::Solid, head),
			)}
			{layer(
				"left-0 top-0",
				filled(size, size, seed + 1, crate::PAGE, crate::PAGE, FillStyle::Solid, hole),
			)}
		</View>
	}
}

/// A gold coin, hatched, for reward chips.
pub fn coin(size: f32, seed: i64) -> Element {
	let s = f64::from(size);
	let rim = vec![Shape::Circle {
		x: s / 2.0,
		y: s / 2.0,
		diameter: s * 0.86,
	}];
	let face = vec![Shape::Circle {
		x: s / 2.0,
		y: s / 2.0,
		diameter: s * 0.5,
	}];
	view! {
		<View class=format!("relative w-[{size}px] h-[{size}px] shrink-0") aria_hidden=true>
			{layer(
				"left-0 top-0",
				filled(size, size, seed, crate::REWARD, crate::REWARD, FillStyle::Hachure, rim),
			)}
			{layer("left-0 top-0", tinted(size, size, seed + 1, crate::REWARD, face))}
		</View>
	}
}
