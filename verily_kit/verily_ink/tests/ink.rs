//! The brand's tones and drawings.

use leptoskit::prelude::Tailwind;
use verily_ink::draw;

#[test]
fn controls_never_fill_with_vermilion() {
	assert_eq!(verily_ink::ACTION.light.accent, verily_ink::INK.light.ink);
	assert_eq!(verily_ink::ACTION.dark.accent, verily_ink::INK.dark.ink);
	assert_ne!(verily_ink::ACTION.light.accent, verily_ink::STAMP.light);
	assert_ne!(verily_ink::ACTION.dark.accent, verily_ink::STAMP.dark);
	assert_eq!(verily_ink::INK.light.accent, verily_ink::STAMP.light);
}

#[test]
fn classes_follow_the_appearance() {
	assert_eq!(
		verily_ink::class("text", verily_ink::TEXT),
		"text-[#34283f] dark:text-[#fffaf0]"
	);
	assert_eq!(
		verily_ink::class("bg", verily_ink::NIGHT_PAGE),
		"bg-[#292331]"
	);
	for tone in [
		verily_ink::TEXT,
		verily_ink::MUTED_TEXT,
		verily_ink::STAMP,
		verily_ink::PLACE,
		verily_ink::PLACE_WASH,
		verily_ink::REWARD,
		verily_ink::REWARD_WASH,
		verily_ink::REVIEW,
		verily_ink::REVIEW_WASH,
		verily_ink::PAGE,
		verily_ink::HUD,
	] {
		let classes = verily_ink::class("text", tone);
		Tailwind::parse(&classes).unwrap_or_else(|error| panic!("{classes}: {error}"));
	}
}

#[test]
fn every_drawing_builds() {
	let drawings = [
		draw::mark(48.0, 1, Some("Verily")),
		draw::mark(24.0, 1, None),
		draw::pin(20.0, 3),
		draw::coin(20.0, 5),
		draw::place_map(7),
		draw::escrow_jar(9),
		draw::viewfinder(200.0, 160.0, 11),
		draw::stamp(96.0, 13),
		draw::arrow_up(60.0, 40.0, 15),
		draw::underline(120.0, 17, verily_ink::STAMP),
		draw::tick(19),
		draw::bubble(160.0, 60.0, 21),
		draw::step_number(1, 23),
	];
	for drawing in drawings {
		assert!(!drawing.children.is_empty());
	}
}
