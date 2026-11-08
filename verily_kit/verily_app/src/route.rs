//! Screens and the paths the shell can open.
//!
//! Do, Create, and Me are the tabs. Capture, review, settings, and an action
//! sit on top of them.

use leptoskit_router::Pattern;
use leptoskit_router::Routable;
use leptoskit_router::Route;
use leptoskit_router::Router;
use leptoskit_router::Segment;

/// The router the shell keeps, and that screens navigate.
pub type Navigation = Router<AppRoute>;

/// One action, `/do/:action`.
#[derive(Clone, Debug, PartialEq, Eq, Route)]
pub struct ActionPage {
	pub action: String,
}

/// Live capture, `/capture/:attempt/:requirement`.
#[derive(Clone, Debug, PartialEq, Eq, Route)]
pub struct CapturePage {
	pub attempt: String,
	pub requirement: String,
}

/// A draft, `/create/:draft`. `new` starts a blank editor.
#[derive(Clone, Debug, PartialEq, Eq, Route)]
pub struct EditorPage {
	pub draft: String,
}

/// Every screen.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AppRoute {
	/// The catalogue.
	Do,
	/// One action.
	Action(ActionPage),
	/// Live proof.
	Capture(CapturePage),
	/// The creator's list.
	Create,
	/// The editor.
	Editor(EditorPage),
	/// Attempts, payouts, and the wallet card.
	Me,
	/// The review queue.
	Review,
	/// Appearance, sign-out, and closing the account.
	Settings,
}

impl From<ActionPage> for AppRoute {
	fn from(page: ActionPage) -> Self {
		Self::Action(page)
	}
}

impl From<CapturePage> for AppRoute {
	fn from(page: CapturePage) -> Self {
		Self::Capture(page)
	}
}

impl From<EditorPage> for AppRoute {
	fn from(page: EditorPage) -> Self {
		Self::Editor(page)
	}
}

const DO: Pattern = Pattern::new(&[Segment::Static("do")]);
const ACTION: Pattern = Pattern::new(&[Segment::Static("do"), Segment::Param("action")]);
const CAPTURE: Pattern = Pattern::new(&[
	Segment::Static("capture"),
	Segment::Param("attempt"),
	Segment::Param("requirement"),
]);
const CREATE: Pattern = Pattern::new(&[Segment::Static("create")]);
const EDITOR: Pattern = Pattern::new(&[Segment::Static("create"), Segment::Param("draft")]);
const ME: Pattern = Pattern::new(&[Segment::Static("me")]);
const REVIEW: Pattern = Pattern::new(&[Segment::Static("review")]);
const SETTINGS: Pattern = Pattern::new(&[Segment::Static("settings")]);

impl Routable for AppRoute {
	fn from_url(url: &leptoskit_router::RouteUrl) -> Result<Self, leptoskit_router::NoMatch> {
		let segments = url
			.segments()
			.iter()
			.map(String::as_str)
			.collect::<Vec<_>>();
		match segments.as_slice() {
			["do"] => Ok(Self::Do),
			["do", action] => Ok(Self::Action(ActionPage {
				action: (*action).to_owned(),
			})),
			["capture", attempt, requirement] => Ok(Self::Capture(CapturePage {
				attempt: (*attempt).to_owned(),
				requirement: (*requirement).to_owned(),
			})),
			["create"] => Ok(Self::Create),
			["create", draft] => Ok(Self::Editor(EditorPage {
				draft: (*draft).to_owned(),
			})),
			["me"] => Ok(Self::Me),
			["review"] => Ok(Self::Review),
			["settings"] => Ok(Self::Settings),
			_ => Err(leptoskit_router::NoMatch),
		}
	}

	fn href(&self) -> leptoskit_router::Href {
		match self {
			Self::Do => DO.static_href(),
			Self::Action(page) => ACTION.href(page),
			Self::Capture(page) => CAPTURE.href(page),
			Self::Create => CREATE.static_href(),
			Self::Editor(page) => EDITOR.href(page),
			Self::Me => ME.static_href(),
			Self::Review => REVIEW.static_href(),
			Self::Settings => SETTINGS.static_href(),
		}
	}
}

impl AppRoute {
	/// Tabs stay visible on the three roots. The other screens have a back control.
	#[must_use]
	pub const fn shows_tabs(&self) -> bool {
		matches!(self, Self::Do | Self::Create | Self::Me)
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn routes_round_trip() {
		let routes = [
			AppRoute::Do,
			AppRoute::Action(ActionPage {
				action: "plant-a-tree".into(),
			}),
			AppRoute::Capture(CapturePage {
				attempt: "attempt-1".into(),
				requirement: "photo".into(),
			}),
			AppRoute::Create,
			AppRoute::Editor(EditorPage {
				draft: "new".into(),
			}),
			AppRoute::Me,
			AppRoute::Review,
			AppRoute::Settings,
		];
		for route in routes {
			let parsed = AppRoute::parse(route.href().as_str()).expect("href parses");
			assert_eq!(parsed, route);
		}
	}
}
