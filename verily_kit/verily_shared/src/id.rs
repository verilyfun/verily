//! Identifiers the running server sends as UUID strings.

use serde::{Deserialize, Serialize};
use uuid::Uuid;

macro_rules! id {
	($name:ident, $doc:literal) => {
		#[doc = $doc]
		#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
		#[serde(transparent)]
		pub struct $name(Uuid);

		impl $name {
			/// Wraps a UUID the server already issued.
			#[must_use]
			pub const fn from_uuid(id: Uuid) -> Self {
				Self(id)
			}

			/// The UUID this identifier wraps.
			#[must_use]
			pub const fn as_uuid(self) -> Uuid {
				self.0
			}
		}

		impl std::fmt::Display for $name {
			fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
				self.0.fmt(formatter)
			}
		}
	};
}

id!(
	AccountId,
	"A sign-in. An account is not a claim that a person is unique."
);
id!(ActionId, "One immutable revision of an action.");
id!(AttemptId, "One account's attempt for one action period.");
id!(
	RequirementId,
	"One proof requirement on an action revision."
);
id!(EvidenceId, "One private proof row.");
id!(
	PoolId,
	"The escrow pool id. The on-chain pool uses this same id."
);
id!(PayoutId, "One payout reserved for one verified attempt.");
