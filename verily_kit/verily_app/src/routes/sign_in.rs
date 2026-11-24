//! The dedicated sign-in screen, `/sign-in`.

use leptoskit::component;
use leptoskit::prelude::Element;
use leptoskit::view;

use crate::chrome;
use crate::sign_in::SignIn;

/// Sign-in page wrapped in the notebook scroll container.
#[component]
pub fn Page() -> Element {
	view! {
		<chrome::Page>
			<SignIn />
		</chrome::Page>
	}
}
