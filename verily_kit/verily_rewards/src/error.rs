//! Failures from the action and reward calls.
//!
//! Typed server exceptions keep the reason the app localizes. Anything else
//! stays a transport or decode failure. A failed call is never turned into
//! a funded pool or a released payout.

use serde::Deserialize;
use serde_json::Value;
use thiserror::Error;

use crate::types::ActionAuthoringProblem;
use crate::types::MissingResource;
use crate::types::RewardProblem;

/// Why one catalogue or reward call did not return its value.
#[derive(Debug, Error)]
pub enum ApiError {
	/// The creator can fix the draft or the publication.
	#[error("{message}")]
	Authoring {
		reason: ActionAuthoringProblem,
		message: String,
	},

	/// AI drafting is off, paused, or out of allowance. Templates still work.
	#[error("{message}")]
	DraftingUnavailable { message: String },

	/// The reward step was refused. Missing escrow configuration arrives
	/// here as [`RewardProblem::RewardsUnavailable`], and the call stops.
	#[error("{message}")]
	Reward {
		problem: RewardProblem,
		message: String,
	},

	/// The action is missing or not visible. The message does not say which.
	#[error("{message}")]
	NotFound {
		resource: MissingResource,
		message: String,
	},

	/// The endpoint did not answer with a value this client understands.
	#[error("could not read the response from {method}: {message}")]
	Decode {
		method: &'static str,
		message: String,
	},

	/// The call failed before a typed result was available.
	#[error("{error}")]
	Call { error: EndpointError },
}

/// A Serverpod call that did not return the method's value.
#[derive(Debug, Clone, Error)]
#[error("{message}")]
pub struct EndpointError {
	pub message: String,
	/// The serialized exception, when the server sent one.
	pub exception: Option<Value>,
}

impl EndpointError {
	pub fn new(message: impl Into<String>) -> Self {
		Self {
			message: message.into(),
			exception: None,
		}
	}

	pub fn exception(message: impl Into<String>, exception: Value) -> Self {
		Self {
			message: message.into(),
			exception: Some(exception),
		}
	}
}

impl ApiError {
	pub(crate) fn from_endpoint(error: EndpointError) -> Self {
		if let Some(typed) = error.exception.as_ref().and_then(typed_exception) {
			return typed;
		}
		Self::Call { error }
	}
}

fn typed_exception(value: &Value) -> Option<ApiError> {
	let class = value
		.get("__className__")
		.or_else(|| value.get("className"))
		.and_then(Value::as_str)?;
	let message = string_field(value, "message").unwrap_or_default();
	match class {
		"ActionAuthoringException" => {
			let reason = enum_field(value, "reason")?;
			Some(ApiError::Authoring { reason, message })
		}
		"ActionDraftingUnavailableException" => Some(ApiError::DraftingUnavailable { message }),
		"RewardException" => {
			let problem = enum_field(value, "problem")?;
			Some(ApiError::Reward { problem, message })
		}
		"ResourceNotFoundException" => {
			let resource = enum_field(value, "resource")?;
			Some(ApiError::NotFound { resource, message })
		}
		_ => None,
	}
}

fn string_field(value: &Value, name: &str) -> Option<String> {
	value.get(name).and_then(Value::as_str).map(str::to_owned)
}

fn enum_field<T: for<'de> Deserialize<'de>>(value: &Value, name: &str) -> Option<T> {
	serde_json::from_value(value.get(name)?.clone()).ok()
}
