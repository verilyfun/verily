//! The notebook's furniture: type, buttons, cards, chips, fields, and the
//! proof checklist, drawn with Skribble's seeded pen.
//!
//! Seeds are fixed per use so a control always wobbles the same way when the
//! screen is rebuilt.

use leptoskit::component;
use leptoskit::prelude::Children;
use leptoskit::prelude::Element;
use leptoskit::prelude::Text;
use leptoskit::prelude::View;
use leptoskit::view;
use skribble_leptoskit::ButtonVariant;
use skribble_leptoskit::FillStyle;
use skribble_leptoskit::WiredBox;
use skribble_leptoskit::WiredButton;
use skribble_leptoskit::WiredCard;
use skribble_leptoskit::WiredInput;
use verily_ink::draw;

use crate::theme;

/// The one promise at the top of a screen.
#[component]
pub fn Display(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=theme::DISPLAY.as_str()>{text}</Text> }
}

/// A section or card title.
#[component]
pub fn Title(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=theme::TITLE.as_str()>{text}</Text> }
}

/// Body copy.
#[component]
pub fn Body(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=theme::BODY.as_str()>{text}</Text> }
}

/// Secondary copy.
#[component]
pub fn Muted(text: impl Into<String>) -> Element {
	let text = text.into();
	view! { <Text class=theme::MUTED.as_str()>{text}</Text> }
}

/// The one action a screen is about: ink on paper, full width.
#[component]
pub fn Primary(
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
			theme=theme::ACTION
			class="w-full"
		/>
	}
}

/// Every other action: an outline.
#[component]
pub fn Quiet(
	label: impl Into<String>,
	on_press: impl Fn() + Send + Sync + 'static,
	#[prop(default = 3)] seed: i64,
) -> Element {
	view! {
		<WiredButton
			label=label.into()
			on_press=on_press
			variant=ButtonVariant::Secondary
			seed=seed
			theme=theme::ACTION
		/>
	}
}

/// A choice among several, filled when it is the chosen one.
#[component]
pub fn Choice(
	label: impl Into<String>,
	selected: bool,
	on_press: impl Fn() + Send + Sync + 'static,
	#[prop(default = 5)] seed: i64,
	#[prop(optional, into)] class: Option<String>,
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
			theme=theme::ACTION
			class=class.unwrap_or_default()
		/>
	}
}

/// A page of the notebook: a rough ink outline on the same paper.
#[component]
pub fn Card(#[prop(default = 7)] seed: i64, children: Children) -> Element {
	view! {
		<WiredCard seed=seed theme=theme::INK class="flex flex-col gap-3 p-4">
			{children}
		</WiredCard>
	}
}

/// Where: a pin and the place's name, on the sage wash.
#[component]
pub fn PlaceChip(
	name: impl Into<String>,
	detail: impl Into<String>,
	#[prop(default = 11)] seed: i64,
) -> Element {
	let name = name.into();
	let detail = detail.into();
	view! {
		<WiredBox
			seed=seed
			theme=theme::INK
			fill=verily_ink::PLACE_WASH
			fill_style=FillStyle::Solid
			class="flex flex-row items-center gap-3 px-3 py-2"
		>
			{draw::pin(22.0, seed + 1)}
			<View class="flex flex-col">
				<Text class=theme::PLACE_LABEL.as_str()>{name}</Text>
				<Text class=theme::MUTED.as_str()>{detail}</Text>
			</View>
		</WiredBox>
	}
}

/// What it pays: a coin and the amount, on butter, before the work.
#[component]
pub fn RewardChip(
	label: impl Into<String>,
	#[prop(optional, into)] detail: Option<String>,
	#[prop(default = 13)] seed: i64,
) -> Element {
	let label = label.into();
	let detail = detail.map(|detail| view! { <Text class=theme::MUTED.as_str()>{detail}</Text> });
	view! {
		<WiredBox
			seed=seed
			theme=theme::INK
			fill=verily_ink::REWARD_WASH
			fill_style=FillStyle::Solid
			class="flex flex-row items-center gap-3 px-3 py-2"
		>
			{draw::coin(22.0, seed + 1)}
			<View class="flex flex-col">
				<Text class=theme::LABEL.as_str()>{label}</Text>
				{detail}
			</View>
		</WiredBox>
	}
}

/// Something a person decides, on the violet wash.
#[component]
pub fn ReviewChip(text: impl Into<String>, #[prop(default = 17)] seed: i64) -> Element {
	let text = text.into();
	view! {
		<WiredBox
			seed=seed
			theme=theme::INK
			fill=verily_ink::REVIEW_WASH
			fill_style=FillStyle::Solid
			class="self-start px-3 py-1"
		>
			<Text class=theme::LABEL.as_str()>{text}</Text>
		</WiredBox>
	}
}

/// One row of the proof checklist: an empty box until the proof is in.
#[component]
pub fn ProofRow(
	text: impl Into<String>,
	#[prop(optional, into)] detail: Option<String>,
	#[prop(default = 19)] seed: i64,
) -> Element {
	let text = text.into();
	let detail = detail.map(|detail| view! { <Text class=theme::MUTED.as_str()>{detail}</Text> });
	view! {
		<View class=theme::LINE.as_str()>
			<WiredBox seed=seed theme=theme::INK class="size-7 shrink-0">
				<View />
			</WiredBox>
			<View class="flex flex-1 flex-col gap-1">
				<Text class=theme::LABEL.as_str()>{text}</Text>
				{detail}
			</View>
		</View>
	}
}

/// A labelled text field in a rough frame.
#[component]
pub fn Field(
	label: impl Into<String>,
	value: String,
	on_change: impl Fn(&str) + Send + Sync + 'static,
	#[prop(optional, into)] placeholder: Option<String>,
	#[prop(default = 23)] seed: i64,
) -> Element {
	let label = label.into();
	view! {
		<View class="flex flex-col gap-1">
			<Text class=theme::LABEL.as_str()>{label.clone()}</Text>
			<WiredInput
				label=label
				value=value
				on_change=on_change
				placeholder=placeholder.unwrap_or_default()
				seed=seed
				theme=theme::INK
				class="w-full"
			/>
		</View>
	}
}

/// An empty or waiting page: a drawing, a title, and a line of help.
#[component]
pub fn Empty(picture: Element, title: impl Into<String>, body: impl Into<String>) -> Element {
	let title = title.into();
	let body = body.into();
	view! {
		<View class="flex flex-col items-center gap-3 py-6">
			{picture}
			<Title text=title />
			<Text class=format!("{} text-center", theme::MUTED.as_str())>{body}</Text>
		</View>
	}
}

#[cfg(test)]
mod tests {
	use leptoskit::view;

	use super::*;

	/// Every piece, with every optional part, builds: a class the renderer
	/// does not know panics here rather than on a phone.
	#[test]
	fn every_piece_builds() {
		let pieces = vec![
			view! { <Display text="Prove it." /> },
			view! { <Title text="Plant a tree" /> },
			view! { <Body text="Do it, live." /> },
			view! { <Muted text="by Ada" /> },
			view! { <Primary label="Start" on_press=|| {} /> },
			view! { <Primary label="Start" on_press=|| {} disabled=true /> },
			view! { <Quiet label="Back" on_press=|| {} /> },
			view! { <Choice label="Nearby" selected=true on_press=|| {} /> },
			view! { <Choice label="All" selected=false on_press=|| {} /> },
			view! { <Choice label="Do" selected=true on_press=|| {} class="flex-1" /> },
			view! { <Card><Title text="Inside" /></Card> },
			view! { <PlaceChip name="Hackney Marshes" detail="Within 100 m" /> },
			view! { <RewardChip label="5 USDC · in escrow" /> },
			view! { <RewardChip label="5 USDC" detail="On its way" /> },
			view! { <ReviewChip text="With a reviewer" /> },
			view! { <ProofRow text="Photo" /> },
			view! { <ProofRow text="Be there" detail="Inside the place" /> },
			view! { <Field label="Title" value=String::new() on_change=|_: &str| {} /> },
			view! {
				<Field
					label="Title"
					value="Plant a tree".to_owned()
					placeholder="What to do"
					on_change=|_: &str| {}
				/>
			},
			view! { <Empty picture=draw::escrow_jar(1) title="Nothing yet" body="Post one." /> },
		];
		assert_eq!(pieces.len(), 20);
	}
}
