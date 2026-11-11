//! The host's routes: the app's operations answer at `/api/<name>`, as the
//! person the session cookie names.

#![allow(
	clippy::assert_is_empty,
	clippy::too_many_lines,
	clippy::similar_names,
	reason = "tests read best as one story per scenario"
)]

use leptoskit_auth::Auth;
use leptoskit_auth::Keys;
use leptoskit_axum::axum::body::Body;
use leptoskit_axum::axum::http::Request;
use leptoskit_axum::axum::http::StatusCode;
use leptoskit_axum::axum::http::header;
use tower::ServiceExt as _;

const LIST: &str = "/api/list_available_actions";

/// A same-origin `fetch` from the page, as the browser sends it.
fn post(path: &str, body: &str, cookie: Option<&str>) -> Request<Body> {
	let mut request = Request::post(path)
		.header(header::CONTENT_TYPE, "application/json")
		.header(header::HOST, "localhost:8184")
		.header(header::ORIGIN, "http://localhost:8184");
	if let Some(cookie) = cookie {
		request = request.header(header::COOKIE, cookie);
	}
	request.body(Body::from(body.to_owned())).unwrap()
}

async fn body(response: leptoskit_axum::axum::response::Response) -> String {
	let bytes = leptoskit_axum::axum::body::to_bytes(response.into_body(), 1 << 20)
		.await
		.unwrap();
	String::from_utf8(bytes.to_vec()).unwrap()
}

#[tokio::test]
async fn the_catalogue_answers_at_api_for_a_signed_in_browser() {
	// Link `verily_app`'s operations, whose bodies call `verily_backend::serve`.
	let _ = verily_app::ops::BACKEND;
	let db = leptoskit_db::testing::sqlite().await;
	let auth = Auth::builder(&db, Keys::single("test", [7; 32]));
	let host = verily_backend::start(&db, auth, None, verily_backend::Options::new(&db)).unwrap();
	verily_backend::seed_development(&db, &host.rewards.0)
		.await
		.unwrap();
	let app = host.router;

	let arguments = r#"{"filter":"all","latitude":null,"longitude":null}"#;
	let anonymous = app
		.clone()
		.oneshot(post(LIST, arguments, None))
		.await
		.unwrap();
	assert_eq!(anonymous.status(), StatusCode::UNAUTHORIZED);

	let signed_in = app
		.clone()
		.oneshot(post(
			"/auth/dev/sign-in",
			r#"{"email":"ada@example.com"}"#,
			None,
		))
		.await
		.unwrap();
	assert!(signed_in.status().is_success(), "{}", signed_in.status());
	let cookie = signed_in
		.headers()
		.get_all(header::SET_COOKIE)
		.iter()
		.filter_map(|value| value.to_str().ok())
		.map(|value| value.split(';').next().unwrap_or_default().to_owned())
		.collect::<Vec<_>>()
		.join("; ");
	assert!(!cookie.is_empty());

	let listed = app
		.clone()
		.oneshot(post(LIST, arguments, Some(&cookie)))
		.await
		.unwrap();
	let status = listed.status();
	let text = body(listed).await;
	assert_eq!(status, StatusCode::OK, "{text}");
	let cards: Vec<verily_api::ActionCard> = serde_json::from_str(&text).unwrap();
	assert_eq!(cards.len(), 4);

	// Another site's page cannot spend the cookie.
	let mut forged = post(LIST, arguments, Some(&cookie));
	forged
		.headers_mut()
		.insert(header::ORIGIN, "https://evil.example".parse().unwrap());
	let forged = app.clone().oneshot(forged).await.unwrap();
	assert_eq!(forged.status(), StatusCode::FORBIDDEN);

	// Arguments that are not the operation's are refused, not guessed at.
	let garbage = app
		.oneshot(post(LIST, r#"{"filter":"everything"}"#, Some(&cookie)))
		.await
		.unwrap();
	assert_eq!(garbage.status(), StatusCode::BAD_REQUEST);
}
