//! The notebook's parts: pages, type, cards, chips, buttons, fields, and the
//! proof checklist, all drawn with Verily's Skribble pen.
//!
//! Screens build from these, so the look lives in one place: rough seeded
//! outlines, washes behind the colour roles, ink for the one filled button,
//! and vermilion only on a verified tick or stamp.

use leptoskit::component;
use leptoskit::prelude::Children;
use leptoskit::prelude::Element;
use leptoskit::prelude::ScrollView;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::view;
use skribble_leptoskit::ButtonVariant;
use skribble_leptoskit::FillStyle;
use skribble_leptoskit::WiredBadge;
use skribble_leptoskit::WiredButton;
use skribble_leptoskit::WiredCard;
use skribble_leptoskit::WiredInput;
use verily_ink::sketches;

use crate::theme;
use crate::theme::Role;

/// One page of the notebook: it scrolls, keeps the gutter, and spaces its
/// groups. The paper itself is the root layout's.
#[component]
pub fn Page(children: Children) -> Element {
	view! {
		<ScrollView class="flex-1 w-full">
			<View class=theme::PAGE>{children}</View>
		</ScrollView>
	}
}

/// The display line at the top of a page, with its explanation under it.
#[component]
pub fn Heading(text: impl Into<String>, #[prop(optional, into)] body: Option<String>) -> Element {
	let text = text.into();
	view! {
		<View class=theme::STACK>
			<Text class=format!("{} {}", theme::HEADLINE, theme::ink())>{text}</Text>
			{body.map(|body| view! { <Muted text=body /> })}
		</View>
	}
}

/// A plain promise in display type.
#[component]
pub fn Display(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=format!("{} {}", theme::DISPLAY, theme::ink())>{text}</Text> }
}

/// A section or card title.
#[component]
pub fn Title(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=format!("{} {}", theme::TITLE, theme::ink())>{text}</Text> }
}

/// Body copy in ink.
#[component]
pub fn Body(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=format!("{} {}", theme::BODY, theme::ink())>{text}</Text> }
}

/// Secondary copy.
#[component]
pub fn Muted(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=format!("{} {}", theme::BODY, theme::muted())>{text}</Text> }
}

/// A short status word or place name.
#[component]
pub fn Label(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=format!("{} {}", theme::LABEL, theme::ink())>{text}</Text> }
}

/// A rough ink card on the page.
#[component]
pub fn Card(#[prop(default = 1)] seed: i64, children: Children) -> Element {
	view! { <WiredCard seed=seed theme=theme::PEN class="w-full">{children}</WiredCard> }
}

/// A card for one colour role: outlined in the role's colour over its wash.
/// Text on it stays ink.
#[component]
pub fn RoleCard(role: Role, #[prop(default = 1)] seed: i64, children: Children) -> Element {
	view! {
		<WiredCard
			seed=seed
			theme=role.pen()
			fill=role.wash()
			fill_style=FillStyle::Solid
			class=format!("w-full {}", theme::ink())
		>
			{children}
		</WiredCard>
	}
}

/// A status chip in a role's colours, always with its word.
#[component]
pub fn Chip(role: Role, text: impl Into<String>, #[prop(default = 1)] seed: i64) -> Element {
	let text = text.into();
	view! {
		<WiredBadge seed=seed theme=role.pen() fill=role.wash() class=theme::ink()>
			<Text class=theme::LABEL>{text}</Text>
		</WiredBadge>
	}
}

/// The screen's one primary action: ink on paper, full width.
#[component]
pub fn Primary(
	label: impl Into<String>,
	on_press: impl Fn() + Send + Sync + 'static,
	#[prop(optional)] disabled: bool,
	#[prop(default = 1)] seed: i64,
) -> Element {
	view! {
		<WiredButton
			label=label.into()
			on_press=on_press
			disabled=disabled
			seed=seed
			theme=theme::PEN
			class="w-full min-h-14"
		/>
	}
}

/// Every other action: an ink outline.
#[component]
pub fn Quiet(
	label: impl Into<String>,
	on_press: impl Fn() + Send + Sync + 'static,
	#[prop(optional)] disabled: bool,
	#[prop(default = 2)] seed: i64,
) -> Element {
	view! {
		<WiredButton
			label=label.into()
			on_press=on_press
			disabled=disabled
			seed=seed
			variant=ButtonVariant::Secondary
			theme=theme::PEN
		/>
	}
}

/// A choice among several, filled when it is the chosen one.
///
/// Appearance no longer offers a pinned light or dark choice, so nothing
/// on screen selects this yet.
#[allow(dead_code)]
#[component]
pub fn Choice(
	label: impl Into<String>,
	selected: bool,
	on_press: impl Fn() + Send + Sync + 'static,
	#[prop(default = 5)] seed: i64,
) -> Element {
	let variant = if selected {
		ButtonVariant::Primary
	} else {
		ButtonVariant::Secondary
	};
	view! {
		<WiredButton
			label=label.into()
			on_press=on_press
			variant=variant
			seed=seed
			theme=theme::PEN
		/>
	}
}

/// A labelled text field in a rough frame.
#[component]
pub fn Field(
	label: impl Into<String>,
	value: impl Into<String>,
	on_change: impl Fn(&str) + Send + Sync + 'static,
	#[prop(optional, into)] placeholder: Option<String>,
	#[prop(optional)] disabled: bool,
	#[prop(default = 1)] seed: i64,
) -> Element {
	view! {
		<View class="flex flex-col gap-1" enabled=!disabled>
			<WiredInput
				label=label.into()
				value=value.into()
				on_change=on_change
				placeholder=placeholder.unwrap_or_default()
				seed=seed
				theme=theme::PEN
				class="w-full"
			/>
		</View>
	}
}

/// What a checklist row says happened to one plain outcome.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Outcome {
	/// Still to do: an empty box.
	Open,
	/// Passed: the box gets the vermilion check. Screens pass this once a
	/// proof is in; until then only `Open` is constructed.
	#[allow(dead_code)]
	Done,
}

/// One row of the proof checklist.
#[component]
pub fn ProofRow(
	text: impl Into<String>,
	outcome: Outcome,
	#[prop(optional, into)] detail: Option<String>,
	#[prop(default = 1)] seed: i64,
) -> Element {
	let text = text.into();
	let mark = match outcome {
		Outcome::Done => sketches::tick(seed),
		Outcome::Open => sketches::open_box(seed),
	};
	view! {
		<View class="flex flex-row items-center gap-3 min-h-11">
			{mark}
			<View class="flex flex-col flex-1 gap-1">
				<Body text=text />
				{detail.map(|detail| view! { <Muted text=detail /> })}
			</View>
		</View>
	}
}

/// A page that is still loading.
#[component]
pub fn Loading(text: impl Into<String>) -> Element {
	view! { <Muted text=text.into() /> }
}

/// A load that failed, with the way to try again.
#[component]
pub fn Failed(
	title: impl Into<String>,
	retry: impl Into<String>,
	on_retry: impl Fn() + Send + Sync + 'static,
) -> Element {
	view! {
		<Card seed=91>
			<Title text=title.into() />
			<Quiet label=retry.into() on_press=on_retry />
		</Card>
	}
}

/// Nothing here yet: a picture, what that means, and what to do.
#[component]
pub fn Empty(
	title: impl Into<String>,
	body: impl Into<String>,
	#[prop(optional)] picture: Option<Element>,
) -> Element {
	view! {
		<Card seed=93>
			<View class="items-center">{picture}</View>
			<Title text=title.into() />
			<Muted text=body.into() />
		</Card>
	}
}

/// A stable seed for a record, so its card wobbles the same way every time
/// it is drawn.
#[must_use]
pub fn seed_for(id: &str) -> i64 {
	id.bytes()
		.fold(7_i64, |seed, byte| (seed * 31 + i64::from(byte)) % 10_007)
}
