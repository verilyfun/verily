//! The Serverpod call this crate needs and does not implement.
//!
//! `verily_shared` owns the one transport. Until that crate is in the tree,
//! the app (or a test) implements [`ServerpodEndpoint`] and hands it to
//! [`crate::RewardsClient`].

use std::future::Future;

use serde_json::Value;

use crate::error::EndpointError;

/// One authenticated call to a Serverpod endpoint method.
///
/// `args` is the method's named arguments, already in Serverpod's JSON
/// shape (camelCase fields, no account id). The future resolves to the
/// method's return value, including JSON `null`. A typed server exception
/// is [`Err`](EndpointError), with the exception object attached when the
/// transport has it. This trait does not connect, sign in, or retry.
pub trait ServerpodEndpoint: Send + Sync {
	fn call(
		&self,
		endpoint: &str,
		method: &str,
		args: Value,
	) -> impl Future<Output = Result<Value, EndpointError>> + Send;
}
