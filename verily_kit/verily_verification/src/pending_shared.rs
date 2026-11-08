//! Domain records the verification crate needs before they move to `verily_shared`.
//!
//! Nothing here is a Serverpod type. Names match the product vocabulary in
//! `docs/verification.md`.

/// Photo, video, or audio proof. Deterministic proof is not a media kind.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MediaKind {
	Video,
	Photo,
	Audio,
}

/// How a media rule is judged. The deployment, not the caller, chooses it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VerificationPolicy {
	SingleModel,
	ModelCouncil,
}

/// A verifier outcome. A model value here is a signal, not a payout.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DecisionStatus {
	Accepted,
	Rejected,
	ManualReview,
}

/// The strongest provenance the server actually checked.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Provenance {
	/// Bound to a capture window only.
	Basic,
	/// Play Integrity vouched for the app and device.
	AppAttested,
	/// A key signed the capture and its attestation was not trusted.
	DeviceSigned,
	/// The account's App Attest key asserted the manifest. No boot signal.
	SecureEnclaveAttested,
	/// A fresh TEE or StrongBox key, created for this window, signed it.
	HardwareAttested,
}

/// Where an attested Android key lives. Only the chain may say so.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KeyStorage {
	StrongBox,
	TrustedEnvironment,
}
