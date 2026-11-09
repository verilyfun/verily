//! The page: one document, top to bottom, in the order people read it.

use leptos::prelude::*;
use leptos::view as html;
use leptoskit::prelude::Element;

use crate::SiteConfig;
use crate::brand;
use verily_ink::sketches as ink;

const CSS: &str = include_str!("site.css");

const TITLE: &str = "Verily: do it, prove it, get paid";
const DESCRIPTION: &str = "Post an action that has to happen somewhere real. Anyone can do it, \
                           with proof filmed live on their phone. Verily checks the proof, and \
                           the reward pays out of escrow.";

/// Renders a leptoskit element into the leptos page.
fn ink(element: Element) -> AnyView {
	leptoskit::web::render(element)
}

/// The whole document, from `<!doctype html>` to `</html>`.
pub fn document(config: &SiteConfig) -> String {
	let body = page(config).to_html();
	let origin = &config.origin;
	let tokens = brand::tokens_css();
	let fonts = crate::FONTS
		.iter()
		.filter(|(name, _)| name.starts_with("SkribblePlayful") || name.contains("Medium"))
		.map(|(name, _)| {
			format!(
				"<link rel=\"preload\" href=\"/fonts/{name}\" as=\"font\" type=\"font/woff2\" crossorigin>"
			)
		})
		.collect::<String>();
	format!(
		"<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" \
		 content=\"width=device-width, initial-scale=1, viewport-fit=cover\"><title>{TITLE}</\
		 title><meta name=\"description\" content=\"{DESCRIPTION}\"><link rel=\"canonical\" \
		 href=\"{origin}/\"><meta name=\"theme-color\" content=\"#FFFAF0\" \
		 media=\"(prefers-color-scheme: light)\"><meta name=\"theme-color\" content=\"#292331\" \
		 media=\"(prefers-color-scheme: dark)\"><meta property=\"og:type\" \
		 content=\"website\"><meta property=\"og:site_name\" content=\"Verily\"><meta \
		 property=\"og:title\" content=\"{TITLE}\"><meta property=\"og:description\" \
		 content=\"{DESCRIPTION}\"><meta property=\"og:url\" content=\"{origin}/\"><meta \
		 name=\"twitter:card\" content=\"summary\"><link rel=\"icon\" href=\"/favicon.svg\" \
		 type=\"image/svg+xml\"><link rel=\"manifest\" \
		 href=\"/site.webmanifest\">{fonts}<style>{tokens}{CSS}</style></head><body>{body}</\
		 body></html>"
	)
}

fn page(config: &SiteConfig) -> impl IntoView + use<> {
	html! {
		<a class="skip" href="#main">"Skip to the page"</a>
		{header(config)}
		<main id="main">
			{hero(config)}
			{promise()}
			{no_upload()}
			{how()}
			{proof()}
			{creators()}
			{faq()}
			{closing(config)}
		</main>
		{footer(config)}
	}
}

fn lockup(id: &str) -> impl IntoView + use<> {
	let mark = brand::mark_svg(id, None, false);
	html! {
		<span class="lockup">
			<span class="lockup-mark" inner_html=mark></span>
			<span class="lockup-name">"verily"</span>
		</span>
	}
}

fn header(config: &SiteConfig) -> impl IntoView + use<> {
	let app = config.app_url.clone();
	html! {
		<header class="bar">
			<nav class="bar-inner" aria-label="Main">
				<a class="home" href="/" aria-label="Verily, home">{lockup("mark-bar")}</a>
				<ul class="links">
					<li><a href="#how">"How it works"</a></li>
					<li><a href="#proof">"Proof"</a></li>
					<li><a href="#creators">"Creators"</a></li>
					<li><a href="#faq">"Questions"</a></li>
				</ul>
				<a class="button button-small" href=app>"Open Verily"</a>
			</nav>
		</header>
	}
}

fn hero(config: &SiteConfig) -> impl IntoView + use<> {
	let app = config.app_url.clone();
	let mark = brand::mark_svg("mark-hero", None, true);
	let prove = ink(ink::prove_it());
	html! {
		<section class="hero" aria-labelledby="hero-title">
			<div class="hero-copy">
				<p class="eyebrow">
					<span class="eyebrow-mark" inner_html=mark></span>
					"Actions in the real world, checked"
				</p>
				<h1 id="hero-title" class="display">
					<span class="line">"Do it."</span>
					<span class="line prove">{prove}</span>
					<span class="line">"Get paid."</span>
				</h1>
				<p class="lede">{DESCRIPTION}</p>
				<div class="actions">
					<a class="button" href=app>"Open Verily"</a>
					<a class="button button-quiet" href="#how">"See how it works"</a>
				</div>
				<ul class="promises" aria-label="Three promises">
					<li>"No upload button"</li>
					<li>"Rewards locked before work starts"</li>
					<li>"People decide the hard cases"</li>
				</ul>
			</div>
			<div class="hero-art">
				{phone()}
				<div class="hero-note" aria-hidden="true">
					<span class="note">"filmed live, signed by the phone"</span>
					{ink(ink::arrow_up(96.0, 84.0, 31))}
				</div>
			</div>
		</section>
	}
}

/// The phone in the hero: an action's page, with its place, its reward, and
/// the stamp that lands once the proof passes.
fn phone() -> impl IntoView + use<> {
	let stamp = ink(ink::slammed_stamp(132.0, 41, 900, false));
	html! {
		<figure class="phone" aria-label="An action in Verily: ten squats at Victoria Park, 5 USDC in escrow, verified">
			<div class="phone-screen">
				<div class="phone-top">
					<span class="phone-time">"9:41"</span>
					<span class="phone-live">"Verified"</span>
				</div>
				<div class="map">{ink(ink::place_map(11))}</div>
				<div class="card">
					<p class="card-kicker">"🏋️ Fitness · 10 reps"</p>
					<p class="card-title">"Ten squats at Victoria Park"</p>
					<p class="chip chip-place"><span class="dot"></span>"Inside the place · 120 m"</p>
					<p class="chip chip-reward">"🔒 5 USDC in escrow"</p>
				</div>
				<ul class="checklist" aria-label="Proof">
					<li>{ink(ink::tick(51))}"Filmed live in Verily"</li>
					<li>{ink(ink::tick(53))}"Inside the place"</li>
					<li>{ink(ink::tick(55))}"Challenge spoken"</li>
				</ul>
				<div class="phone-stamp">{stamp}</div>
			</div>
		</figure>
	}
}

fn section_head(id: &str, kicker: &str, title: &str, lede: &str) -> impl IntoView + use<> {
	let id = id.to_owned();
	let kicker = kicker.to_owned();
	let title = title.to_owned();
	let lede = lede.to_owned();
	html! {
		<div class="head reveal">
			<p class="kicker">{kicker}</p>
			<h2 id=id class="headline">{title}</h2>
			<p class="lede">{lede}</p>
		</div>
	}
}

fn promise() -> impl IntoView + use<> {
	let place = ink(ink::rising(ink::place_map(3), 1));
	let jar = ink(ink::rising(ink::escrow_jar(5), 2));
	html! {
		<section class="band" aria-labelledby="promise-title">
			{section_head(
				"promise-title",
				"Every action is a small promise",
				"A place, a proof, and a reward that already exists.",
				"Creators post an action. Anyone can do it. Each one says where it happens, what counts as proof, and what it pays.",
			)}
			<div class="trio">
				<article class="panel panel-place reveal">
					<div class="panel-art">{place}</div>
					<h3>"A place"</h3>
					<p>"A pin and a radius on a map, or a code that only exists at the venue. Being there is part of doing it."</p>
				</article>
				<article class="panel panel-proof reveal">
					<div class="panel-art">{viewfinder_art()}</div>
					<h3>"A proof"</h3>
					<p>"Video, a photo, audio, a motion pattern, or reps counted by the camera, captured in Verily the moment it happens."</p>
				</article>
				<article class="panel panel-reward reveal">
					<div class="panel-art">{jar}</div>
					<h3>"A reward, if you like"</h3>
					<p>"Locked in escrow when the action goes live, so people can see it exists before they start."</p>
				</article>
			</div>
		</section>
	}
}

/// A small night viewfinder with a live label and the spoken challenge.
fn viewfinder_art() -> impl IntoView + use<> {
	html! {
		<div class="finder finder-small" aria-hidden="true">
			{ink(ink::viewfinder(220.0, 160.0, 61))}
			<span class="finder-live">"Live"</span>
			<span class="finder-say">"Say “pelican”"</span>
			<span class="finder-count">"7 / 10"</span>
		</div>
	}
}

fn no_upload() -> impl IntoView + use<> {
	let points = [
		(
			"The camera is the only way in.",
			"Proof that needs a fresh capture can’t come from your gallery. The phone signs the recording with a key in its secure hardware the moment it ends.",
		),
		(
			"A live challenge.",
			"Each attempt gets a fresh challenge from Verily, like a word to say or a gesture to make, so a clip made earlier can’t contain it.",
		),
		(
			"A seal you can’t see.",
			"Verified clips carry an invisible Verily seal and Content Credentials, so a clip that travels can still be looked up.",
		),
		(
			"Money first.",
			"A reward is locked in escrow before the action goes live. Nobody works for a promise.",
		),
	];
	html! {
		<section class="night" aria-labelledby="twist-title">
			<div class="night-inner">
				<div class="night-copy">
					{section_head(
						"twist-title",
						"The twist",
						"There’s no upload button.",
						"Most proof apps take whatever you upload. Verily only takes what the camera sees, as it happens.",
					)}
					<ol class="points">
						{points
							.into_iter()
							.enumerate()
							.map(|(index, (title, body))| {
								html! {
									<li class="point reveal">
										<span class="point-number">{format!("0{}", index + 1)}</span>
										<div>
											<h3>{title}</h3>
											<p>{body}</p>
										</div>
									</li>
								}
							})
							.collect::<Vec<_>>()}
					</ol>
				</div>
				<div class="finder finder-big reveal" aria-hidden="true">
					{ink(ink::viewfinder(320.0, 440.0, 71))}
					<span class="finder-live">"Live"</span>
					<span class="finder-bubble">
						{ink(ink::bubble(190.0, 74.0, 73))}
						<span>"Say “pelican”"</span>
					</span>
					<span class="finder-count">"Rep 7 of 10"</span>
					<span class="finder-place"><span class="dot"></span>"Victoria Park"</span>
				</div>
			</div>
		</section>
	}
}

fn how() -> impl IntoView + use<> {
	let steps = [
		(
			"Post",
			"Say what to do, pin where it happens, and choose what counts as proof.",
		),
		(
			"Fund",
			"Add a reward if you like. It’s locked in escrow before anyone starts.",
		),
		(
			"Do",
			"People go there and capture it live in Verily, with a fresh challenge each time.",
		),
		(
			"Stamped",
			"Verily checks the proof. When it passes, the page is stamped and the reward pays out.",
		),
	];
	html! {
		<section id="how" class="band" aria-labelledby="how-title">
			{section_head(
				"how-title",
				"How it works",
				"Four steps, one stamp.",
				"Writing an action takes a minute. Doing one takes as long as the action itself.",
			)}
			<ol class="steps">
				{steps
					.into_iter()
					.enumerate()
					.map(|(index, (title, body))| {
						let circle = ink(ink::step_number(index + 1, 81 + index as i64));
						html! {
							<li class="step reveal">
								<div class="step-number">{circle}</div>
								<h3>{title}</h3>
								<p>{body}</p>
							</li>
						}
					})
					.collect::<Vec<_>>()}
			</ol>
		</section>
	}
}

fn proof() -> impl IntoView + use<> {
	let rows = [
		"Filmed live in Verily",
		"Signed by this phone",
		"Inside the place",
		"Challenge spoken",
		"Checked by Verily",
	];
	html! {
		<section id="proof" class="band band-split" aria-labelledby="proof-title">
			<div class="split-copy">
				{section_head(
					"proof-title",
					"Honest about proof",
					"What we check, in plain words.",
					"A pass means these checks passed. It never means a model decided a scene is real, and you never see a score.",
				)}
				<ul class="honest reveal">
					<li>"Verily raises the cost of faking. It doesn’t claim to make faking impossible."</li>
					<li>"Uncertain, valuable, or flagged proof goes to a person, and every rejection can be appealed once."</li>
					<li>"An account is not a person. Verification is never a claim that someone is unique."</li>
				</ul>
			</div>
			<div class="sheet reveal">
				<p class="sheet-title">"Proof"</p>
				<ul class="checklist checklist-large">
					{rows
						.into_iter()
						.enumerate()
						.map(|(index, row)| {
							html! { <li>{ink(ink::tick(91 + index as i64 * 2))}{row}</li> }
						})
						.collect::<Vec<_>>()}
					<li class="review-row">
						<span class="chip chip-review">"With a reviewer"</span>
						"When something needs a person"
					</li>
				</ul>
			</div>
		</section>
	}
}

fn creators() -> impl IntoView + use<> {
	let uses = [
		(
			"☕",
			"A café’s opening",
			"Be one of the first fifty through the door this Saturday.",
		),
		(
			"🏋️",
			"A coach’s challenge",
			"Ten squats a day for a week, counted by the camera.",
		),
		(
			"🗺️",
			"A city scavenger hunt",
			"Find six murals and prove each one on the spot.",
		),
		(
			"🚏",
			"Field research",
			"A photo of every bus stop on route 38, taken there.",
		),
		(
			"🎲",
			"A dare between friends",
			"Sing the chorus at the top of the hill. Live.",
		),
	];
	html! {
		<section id="creators" class="band" aria-labelledby="creators-title">
			{section_head(
				"creators-title",
				"For creators",
				"Ask for something real. Pay only when it happens.",
				"Shops, coaches, clubs, researchers, and friends post actions on Verily. Here are a few.",
			)}
			<ul class="uses">
				{uses
					.into_iter()
					.map(|(emoji, title, body)| {
						html! {
							<li class="use reveal">
								<span class="use-emoji" aria-hidden="true">{emoji}</span>
								<h3>{title}</h3>
								<p>{body}</p>
							</li>
						}
					})
					.collect::<Vec<_>>()}
			</ul>
			<p class="never reveal">
				"Verily isn’t a gig marketplace, a feed of likes and follows, or a token to trade. Rewards are paid in a digital currency only because an on-chain escrow is the simplest way to show the money is really there."
			</p>
		</section>
	}
}

fn faq() -> impl IntoView + use<> {
	let questions = [
		(
			"Can I upload a video I already took?",
			"No. Proof that needs a fresh capture is filmed inside Verily, with a challenge you only see once you start. There’s no gallery picker for it.",
		),
		(
			"Does a pass mean the video is real?",
			"A pass means the checks passed: filmed live in Verily, signed by the phone, inside the place, with the challenge. Verily never claims more than that.",
		),
		(
			"Who sees my proof?",
			"Your evidence is private. Only the people who need to, such as the creator for an appeal or a Verily reviewer for flagged proof, can look at it. Exact locations are never public.",
		),
		(
			"What if Verily gets it wrong?",
			"Hard cases go to a person, and every rejection can be appealed once. When something fails on our side, Verily sends it for review instead of guessing.",
		),
		(
			"Do I need crypto?",
			"Not to post or do an action without a reward. Rewards are held in an on-chain escrow so anyone can check they exist. You’ll always see the amount before you start.",
		),
		(
			"Is an account a verified person?",
			"No. Verily checks that an action was done, not who someone is. Accounts are not people, and Verily never claims they are.",
		),
	];
	html! {
		<section id="faq" class="band" aria-labelledby="faq-title">
			{section_head(
				"faq-title",
				"Questions",
				"Asked, and answered plainly.",
				"If yours isn’t here, write to us.",
			)}
			<div class="faq">
				{questions
					.into_iter()
					.map(|(question, answer)| {
						html! {
							<details class="qa reveal">
								<summary>{question}</summary>
								<p>{answer}</p>
							</details>
						}
					})
					.collect::<Vec<_>>()}
			</div>
		</section>
	}
}

fn closing(config: &SiteConfig) -> impl IntoView + use<> {
	let app = config.app_url.clone();
	let stamp = ink(ink::slammed_stamp(180.0, 101, 0, true));
	let underline = ink(ink::underline(250.0, 103, brand::STAMP));
	html! {
		<section class="closing" aria-labelledby="closing-title">
			<div class="closing-stamp">{stamp}</div>
			<h2 id="closing-title" class="display display-small">
				"Go do the thing."
				<span class="closing-underline">{underline}</span>
			</h2>
			<p class="lede">"Verily comes to Android first, then iPhone and the web."</p>
			<div class="actions actions-center">
				<a class="button" href=app>"Open Verily"</a>
				<a class="button button-quiet" href="#how">"How it works"</a>
			</div>
		</section>
	}
}

fn footer(config: &SiteConfig) -> impl IntoView + use<> {
	let mail = format!("mailto:{}", config.contact_email);
	let email = config.contact_email.clone();
	html! {
		<footer class="foot">
			<div class="foot-inner">
				<div class="foot-brand">
					{lockup("mark-foot")}
					<p>"Do it, prove it, get paid."</p>
				</div>
				<nav aria-label="Footer">
					<ul class="foot-links">
						<li><a href="#how">"How it works"</a></li>
						<li><a href="#proof">"Proof"</a></li>
						<li><a href="#faq">"Questions"</a></li>
						<li><a href=mail>{email}</a></li>
					</ul>
				</nav>
				<p class="foot-small">"© 2026 Verily. Evidence stays private. Exact locations are never public."</p>
			</div>
		</footer>
	}
	.into_any()
}
