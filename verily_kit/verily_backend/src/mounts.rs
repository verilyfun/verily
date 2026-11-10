//! Domain mounts for `verily_verification` and `verily_rewards`.
//!
//! Verification is mounted from [`verily_verification::Verification`] — this
//! host does not reimplement capture, council, evidence sealing, or payout
//! authorization. Rewards are mounted from [`verily_rewards::Rewards`] the
//! same way: fail closed, no chain client, RPC ops linked from that crate.
//! The Solana / chain gateway is owned by `verily_rewards`; this host only
//! mounts what rewards exports and installs [`RewardsHandle`] on each RPC
//! identity so those ops can reach the service, beside the
//! [`BackendHandle`] the app's operations in [`crate::serve`] read.

use std::sync::Arc;

use leptoskit_auth::Auth;
use leptoskit_axum::axum::Router;
use leptoskit_axum::axum::routing::get;
use leptoskit_rpc::server::Identify;
use leptoskit_rpc::server::Server;
use verily_rewards::Rewards;
use verily_rewards::RewardsHandle;
use verily_verification::Verification;
use verily_verification::capture::AttestationUnavailable;

use crate::serve::BackendHandle;

/// Contract a domain crate satisfies when mounting HTTP routes into the host.
pub trait DomainMount {
	/// Axum routes this domain owns (nested under its prefix).
	fn router<S>() -> Router<S>
	where
		S: Clone + Send + Sync + 'static;

	/// Register RPC operations onto the host's server.
	#[must_use]
	fn mount_ops(server: Server) -> Server {
		server
	}
}

/// Puts the rewards service and the app's backend on every caller's context,
/// after [`Auth`] says who they are.
#[must_use]
pub fn identify(auth: Auth, rewards: RewardsHandle, backend: BackendHandle) -> HostIdentify {
	HostIdentify {
		auth,
		rewards,
		backend,
	}
}

/// [`Identify`] that forwards to [`Auth`] and installs [`RewardsHandle`] and
/// [`BackendHandle`].
#[derive(Clone)]
pub struct HostIdentify {
	auth: Auth,
	rewards: RewardsHandle,
	backend: BackendHandle,
}

impl HostIdentify {
	fn install(&self, mut identity: leptoskit_rpc::Identity) -> leptoskit_rpc::Identity {
		identity.context = identity
			.context
			.with(self.rewards.clone())
			.with(self.backend.clone());
		identity
	}
}

impl Identify for HostIdentify {
	fn identify<'a>(
		&'a self,
		request: &'a leptoskit_axum::axum::http::request::Parts,
	) -> leptoskit_rpc::__private::BoxFuture<
		'a,
		Result<leptoskit_rpc::Identity, leptoskit_rpc::Error>,
	> {
		Box::pin(async move {
			let identity = Identify::identify(&self.auth, request).await?;
			Ok(self.install(identity))
		})
	}

	fn identify_token<'a>(
		&'a self,
		token: &'a str,
	) -> leptoskit_rpc::__private::BoxFuture<
		'a,
		Result<leptoskit_rpc::Identity, leptoskit_rpc::Error>,
	> {
		Box::pin(async move {
			let identity = Identify::identify_token(&self.auth, token).await?;
			Ok(self.install(identity))
		})
	}

	fn lease<'a>(
		&'a self,
		identity: &'a leptoskit_rpc::Identity,
	) -> leptoskit_rpc::__private::BoxFuture<
		'a,
		Result<leptoskit_rpc::server::IdentityLease, leptoskit_rpc::Error>,
	> {
		Identify::lease(&self.auth, identity)
	}
}

/// Merge a domain's router into the host router.
pub fn mount_router<S, M>(router: Router<S>) -> Router<S>
where
	S: Clone + Send + Sync + 'static,
	M: DomainMount,
{
	router.merge(M::router())
}

/// Proof verification, capture, evidence, review, and council.
///
/// Mounts [`verily_verification::Verification`]. Routes stay on the backend;
/// the service object is what handlers call.
pub mod verification {
	use super::AttestationUnavailable;
	use super::DomainMount;
	use super::Router;
	use super::Server;
	use super::Verification;
	use super::get;

	/// Path prefix reserved for verification HTTP routes.
	pub const PREFIX: &str = "/verification";

	/// Fail-closed verification mount used until a real attestation verifier
	/// and media mode are configured through Monosecret-resolved env.
	pub type Mounted = Verification<AttestationUnavailable>;

	/// Build the verification service in manual-review / unavailable mode.
	///
	/// # Errors
	///
	/// When verifier configuration is invalid (should not happen for the
	/// closed defaults).
	pub fn mount() -> Result<Mounted, verily_verification::config::ConfigError> {
		Verification::closed()
	}

	/// HTTP surface that only reports the mount is present. Domain handlers
	/// call [`Mounted`] methods; they do not live in this crate.
	pub struct Routes;

	impl DomainMount for Routes {
		fn router<S>() -> Router<S>
		where
			S: Clone + Send + Sync + 'static,
		{
			Router::new().route(
				"/verification/ready",
				get(|| async { "verification mounted" }),
			)
		}
	}

	/// Mount verification readiness routes.
	pub fn mount_router<S>(router: Router<S>) -> Router<S>
	where
		S: Clone + Send + Sync + 'static,
	{
		super::mount_router::<S, Routes>(router)
	}

	/// Verification does not register `leptoskit_rpc` inventory yet; no-op.
	#[must_use]
	pub fn mount_ops(server: Server) -> Server {
		Routes::mount_ops(server)
	}
}

/// Actions, escrow funding checks from chain state, and payouts.
///
/// Mounts [`verily_rewards::Rewards`]. This host does not construct a Solana
/// gateway itself — `Rewards::closed()` keeps the gateway disabled until
/// secrets install one.
pub mod rewards {
	use super::Arc;
	use super::DomainMount;
	use super::Rewards;
	use super::RewardsHandle;
	use super::Router;
	use super::Server;
	use super::get;

	/// Path prefix reserved for rewards HTTP routes (from `verily_rewards`).
	pub const PREFIX: &str = verily_rewards::PREFIX;

	/// Fail-closed rewards mount: no chain client, payouts cannot release.
	pub type Mounted = Rewards;

	/// Build the rewards service with a disabled gateway.
	///
	/// # Errors
	///
	/// When configuration is invalid (should not happen for the closed
	/// defaults).
	pub fn mount() -> Result<Mounted, verily_rewards::ConfigError> {
		Rewards::closed()
	}

	/// The arbiter a development escrow names. Nobody holds its key, so
	/// nothing it guards can be released.
	#[cfg(debug_assertions)]
	pub const DEVELOPMENT_ARBITER: [u8; 32] = [0xa1; 32];

	/// Development rewards: the planted test gateway, which holds only the
	/// escrow accounts the development seed plants. Funding is still read
	/// back from that chain state, an unplanted escrow is never found, and
	/// `verily_rewards` refuses the planted gateway outside development and
	/// test.
	///
	/// # Errors
	///
	/// When the run mode refuses the test double.
	#[cfg(debug_assertions)]
	pub fn mount_development() -> Result<Mounted, verily_rewards::ConfigError> {
		let secrets =
			verily_rewards::config::secrets_from_pairs(std::iter::empty::<(&str, &str)>());
		Rewards::from_secrets(&secrets, verily_rewards::RunMode::Development)?
			.with_arbiter(solana_kit_core::Address::from_bytes(DEVELOPMENT_ARBITER))
			.with_planted(verily_rewards::PlantedGateway::new())
	}

	/// HTTP surface that only reports the mount is present.
	pub struct Routes;

	impl DomainMount for Routes {
		fn router<S>() -> Router<S>
		where
			S: Clone + Send + Sync + 'static,
		{
			Router::new().route("/rewards/ready", get(|| async { "rewards mounted" }))
		}

		fn mount_ops(server: Server) -> Server {
			// Link `verily_rewards::ops` so its `#[rpc::*]` inventory entries
			// register on this host. Do not reimplement the ops here.
			let _ = verily_rewards::ops::templates;
			server
		}
	}

	/// Mount rewards readiness routes under [`PREFIX`].
	pub fn mount_router<S>(router: Router<S>) -> Router<S>
	where
		S: Clone + Send + Sync + 'static,
	{
		super::mount_router::<S, Routes>(router)
	}

	/// Mount rewards RPC ops by linking the crate's inventory registrations.
	#[must_use]
	pub fn mount_ops(server: Server) -> Server {
		Routes::mount_ops(server)
	}

	/// Wrap a mounted [`Rewards`] as the handle RPC ops expect.
	#[must_use]
	pub fn handle(mounted: Mounted) -> RewardsHandle {
		RewardsHandle(Arc::new(mounted))
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn prefixes_are_stable() {
		assert_eq!(verification::PREFIX, "/verification");
		assert_eq!(rewards::PREFIX, "/rewards");
		assert_eq!(rewards::PREFIX, verily_rewards::PREFIX);
	}

	#[test]
	fn routers_build() {
		let _: Router = verification::Routes::router();
		let _: Router = rewards::Routes::router();
	}

	#[test]
	fn verification_mounts_closed() {
		let mounted = verification::mount().expect("closed verification mounts");
		let _ = mounted;
	}

	#[test]
	fn rewards_mounts_closed() {
		let mounted = rewards::mount().expect("closed rewards mounts");
		let _ = rewards::handle(mounted);
	}
}
