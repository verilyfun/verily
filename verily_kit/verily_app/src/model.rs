//! Screen records the backend operations return.
//!
//! The wire records live in [`verily_api`], which `verily_backend` names
//! too. What only the screens use stays here.

pub use verily_api::*;

/// Where a live proof is allowed to come from.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum EvidenceSource {
	/// The shell capture or attestation plugin.
	LivePlugin,
}

/// Live proof has one source. A gallery or a file picker is not one of them.
#[must_use]
pub const fn evidence_source(kind: ProofKind) -> EvidenceSource {
	let _ = kind.needs_live_capture();
	EvidenceSource::LivePlugin
}

/// What the shell plugin reports after a live capture. The digest is submitted.
/// It is not drawn on the screen.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LiveProof {
	pub digest_hex: String,
}
