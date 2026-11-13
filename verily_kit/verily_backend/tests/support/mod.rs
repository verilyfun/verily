//! A Verily backend on an in-memory database, and people to call it as.

#![allow(
	dead_code,
	clippy::needless_pass_by_value,
	reason = "each test binary uses part of the support, and assertions take results whole"
)]

use std::sync::Arc;
use std::time::Duration;

use leptoskit_auth::Auth;
use leptoskit_auth::Keys;
use leptoskit_auth::RequestInfo;
use leptoskit_auth::SignedIn;
use leptoskit_db::Context;
use leptoskit_db::Db;
use leptoskit_rpc as rpc;
use leptoskit_rpc::Identity;
use verily_backend::Backend;
use verily_backend::BackendHandle;
use verily_backend::schema::Account;
use verily_rewards::PlantedGateway;
use verily_rewards::Rewards;
use verily_rewards::RewardsHandle;
use verily_rewards::RunMode;

/// The backend's pieces on a fresh in-memory database.
pub struct World {
	pub db: Db,
	pub auth: Auth,
	pub rewards: Arc<Rewards>,
	pub backend: BackendHandle,
}

/// One signed-in person.
#[derive(Clone)]
pub struct Person {
	pub signed_in: SignedIn,
	pub identity: Identity,
}

impl Person {
	pub fn account(&self) -> leptoskit_db::Id<leptoskit_auth::Account> {
		self.signed_in.account
	}
}

/// Rewards on the planted test gateway: funding is read back from accounts
/// a test plants, and nothing else.
pub fn planted_rewards() -> Rewards {
	let secrets = verily_rewards::config::secrets_from_pairs(std::iter::empty::<(&str, &str)>());
	Rewards::from_secrets(&secrets, RunMode::Test)
		.unwrap()
		.with_arbiter(solana_kit_core::Address::from_bytes([0xa1; 32]))
		.with_planted(PlantedGateway::new())
		.unwrap()
}

pub async fn world() -> World {
	world_with(planted_rewards()).await
}

pub async fn world_with(rewards: Rewards) -> World {
	let db = leptoskit_db::testing::sqlite().await;
	let auth = Auth::builder(&db, Keys::single("test", [7; 32]))
		.mailer(leptoskit_auth::Mailbox::new())
		.dev_sign_in()
		.on_sign_up::<Account>()
		.build()
		.unwrap();
	let rewards = Arc::new(rewards);
	let backend = BackendHandle::new(Backend {
		rewards: rewards.clone(),
		verification: Arc::new(verily_verification::Verification::closed().unwrap()),
		auth: Some(auth.clone()),
		db: Some(db.clone()),
	});
	World {
		db,
		auth,
		rewards,
		backend,
	}
}

impl World {
	/// Signs `email` in, as the development sign-in does.
	pub async fn person(&self, email: &str) -> Person {
		let sign_in = self
			.auth
			.dev_sign_in(email, &RequestInfo::default())
			.await
			.unwrap();
		let signed_in = sign_in.signed_in();
		let identity =
			Identity::new(self.context(leptoskit_auth::context(Some(signed_in.clone()))))
				.with_caller(signed_in.session.to_string());
		Person {
			signed_in,
			identity,
		}
	}

	/// Nobody signed in, with the backend on the context as the host puts it.
	pub fn anonymous(&self) -> Identity {
		Identity::new(self.context(leptoskit_auth::context(None)))
	}

	fn context(&self, context: Context) -> Context {
		context
			.with(RewardsHandle(self.rewards.clone()))
			.with(self.backend.clone())
	}

	pub fn call<O: rpc::Operation>(
		&self,
		who: &Identity,
		op: O,
	) -> impl Future<Output = rpc::Result<O::Output>> + Send {
		let db = self.db.clone();
		let who = who.clone();
		// Dispatch grew past clippy's large-future limit on this pin.
		Box::pin(async move { rpc::server::call_as(&db, who, None, op).await })
	}

	/// Puts the development seed's actions in the catalogue.
	pub async fn seed(&self) -> usize {
		verily_backend::seed_development(&self.db, &self.rewards)
			.await
			.unwrap()
	}

	pub async fn grant_reviewer(&self, person: &Person) {
		verily_backend::serve::grant_reviewer(
			&self.db.system("grant review in a test"),
			person.account(),
		)
		.await
		.unwrap();
	}
}

/// Waits up to two seconds for `check` to hold: work a mutation runs after
/// it commits.
pub async fn eventually<F, Fut>(mut check: F) -> bool
where
	F: FnMut() -> Fut,
	Fut: Future<Output = bool>,
{
	for _ in 0..200 {
		if check().await {
			return true;
		}
		tokio::time::sleep(Duration::from_millis(10)).await;
	}
	false
}

pub fn assert_unauthorized<T: std::fmt::Debug>(result: rpc::Result<T>) {
	assert!(
		matches!(result, Err(rpc::Error::Unauthorized(_))),
		"expected Unauthorized, got {result:?}"
	);
}

pub fn assert_not_found<T: std::fmt::Debug>(result: rpc::Result<T>) {
	assert!(
		matches!(result, Err(rpc::Error::NotFound(_))),
		"expected NotFound, got {result:?}"
	);
}

pub fn assert_invalid<T: std::fmt::Debug>(result: rpc::Result<T>, code: &str) {
	match result {
		Err(rpc::Error::Invalid(message)) => assert_eq!(message, code),
		other => panic!("expected Invalid({code}), got {other:?}"),
	}
}

pub fn assert_conflict<T: std::fmt::Debug>(result: rpc::Result<T>, code: &str) {
	match result {
		Err(rpc::Error::Conflict(message)) => assert_eq!(message, code),
		other => panic!("expected Conflict({code}), got {other:?}"),
	}
}

pub fn assert_forbidden<T: std::fmt::Debug>(result: rpc::Result<T>, code: &str) {
	match result {
		Err(rpc::Error::Forbidden(message)) => assert_eq!(message, code),
		other => panic!("expected Forbidden({code}), got {other:?}"),
	}
}

/// A SHA-256 hex digest that looks like one the capture plugin reports.
pub fn digest(byte: u8) -> String {
	format!("{byte:02x}").repeat(32)
}
