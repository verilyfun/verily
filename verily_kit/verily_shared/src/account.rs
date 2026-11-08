//! Accounts. Verification raises the cost of faking; it never claims the
//! account is a unique human.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::id::AccountId;

/// What the app shows for a signed-in account.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Account {
	/// The signed-in account.
	pub id: AccountId,
	/// The name other people see on an action. Not a legal identity.
	pub display_name: String,
}

/// The only closure state the server records. Sign-in is blocked afterwards.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum AccountClosureStatus {
	/// Identity purge has been retained and sign-in is blocked.
	Closed,
}

/// The receipt retained after sign-in is blocked. It is not a public profile.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AccountClosure {
	/// The account that was closed.
	pub account_id: AccountId,
	/// Always [`AccountClosureStatus::Closed`] on the running server.
	pub status: AccountClosureStatus,
	/// When closure was requested.
	pub requested_at: DateTime<Utc>,
	/// When the identity purge was recorded.
	pub identity_purged_at: DateTime<Utc>,
}

impl Account {
	/// A closure for this account blocks publish and new attempts.
	#[must_use]
	pub fn is_active(&self, closure: Option<&AccountClosure>) -> bool {
		closure.is_none_or(|closure| closure.account_id != self.id)
	}
}
