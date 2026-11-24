//! Resend HTTP mailer implementing `leptoskit_auth::Mailer`.
//!
//! Used in staging/production when `VERILY_RESEND_API_KEY` is configured via
//! Monosecret. Local development defaults to `LeptosKit`'s in-app mailbox so
//! development needs zero cloud secrets.

use std::time::Duration;

use leptoskit_auth::Mail;
use leptoskit_auth::MailError;
use leptoskit_auth::MailFuture;
use leptoskit_auth::Mailer;

const RESEND_ENDPOINT: &str = "https://api.resend.com/emails";

/// Sends transactional auth emails through Resend's HTTPS API.
#[derive(Clone)]
pub struct ResendMailer {
	api_key: String,
	from: String,
	endpoint: String,
	client: reqwest::Client,
}

impl ResendMailer {
	/// Build a Resend mailer from resolved secret values.
	///
	/// # Panics
	///
	/// Panics if the underlying TLS HTTP client cannot be initialized.
	#[must_use]
	pub fn new(api_key: String, from: String) -> Self {
		let client = reqwest::Client::builder()
			.timeout(Duration::from_secs(10))
			.redirect(reqwest::redirect::Policy::none())
			.build()
			.expect("reqwest client builds");
		Self {
			api_key,
			from,
			endpoint: RESEND_ENDPOINT.to_owned(),
			client,
		}
	}

	/// Resolve from environment if `VERILY_RESEND_API_KEY` is present and non-empty.
	#[must_use]
	pub fn from_env() -> Option<Self> {
		let api_key = std::env::var("VERILY_RESEND_API_KEY").ok()?;
		let api_key = api_key.trim().to_owned();
		if api_key.is_empty() {
			return None;
		}
		let from = std::env::var("VERILY_AUTH_EMAIL_FROM")
			.ok()
			.map(|v| v.trim().to_owned())
			.filter(|v| !v.is_empty())
			.unwrap_or_else(|| "Verily <no-reply@verily.fun>".to_owned());
		Some(Self::new(api_key, from))
	}
}

impl Mailer for ResendMailer {
	fn send(&self, mail: Mail) -> MailFuture<'_> {
		let client = self.client.clone();
		let endpoint = self.endpoint.clone();
		let api_key = self.api_key.clone();
		let from = self.from.clone();
		Box::pin(async move {
			let payload = serde_json::json!({
				"from": from,
				"to": [mail.to],
				"subject": mail.subject,
				"text": mail.text,
			});
			let response = client
				.post(endpoint)
				.bearer_auth(api_key)
				.json(&payload)
				.send()
				.await
				.map_err(|_| MailError("email delivery failed".to_owned()))?;
			if !response.status().is_success() {
				return Err(MailError(format!(
					"email provider rejected message ({})",
					response.status().as_u16()
				)));
			}
			Ok(())
		})
	}
}
