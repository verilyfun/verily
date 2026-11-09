//! Private proof facts bound to one attempt. Originals are hash-pinned and
//! never modified; watermarks are lookup keys, not proof.

use leptoskit_auth::AuthContext as _;
use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::policy;
use leptoskit_db::table;

use crate::schema::Attempt;
use crate::schema::Reviewer;

/// Private evidence for one requirement on one attempt.
///
/// Almost every column is private: evidence originals stay off public feeds.
/// The participant reads and adds proof for their own attempt; a Verily
/// reviewer reads proof on someone else's. Nobody changes a row once written.
#[table(
	name = "evidence",
	index(attempt_id),
	unique(attempt_id, requirement_key)
)]
#[policy(select, |evidence, cx| {
	cx.signed_in(|me| {
		cx.exists(Attempt::query().filter(|attempt| {
			attempt.id.eq(evidence.attempt_id) & attempt.participant_id.eq(me.account)
		})) | (cx.exists(Reviewer::query().filter(|reviewer| reviewer.account_id.eq(me.account)))
			& cx.exists(Attempt::query().filter(|attempt| {
				attempt.id.eq(evidence.attempt_id) & attempt.participant_id.ne(me.account)
			})))
	})
})]
#[policy(insert, |evidence, cx| {
	cx.signed_in(|me| {
		cx.exists(Attempt::query().filter(|attempt| {
			attempt.id.eq(evidence.attempt_id) & attempt.participant_id.eq(me.account)
		}))
	})
})]
pub struct Evidence {
	pub id: Id<Evidence>,
	#[db(on_delete = cascade)]
	pub attempt_id: Id<Attempt>,
	/// Stable key of the requirement this proof satisfies.
	#[db(min_len = 1, max_len = 64)]
	pub requirement_key: String,
	/// Requirement kind: `photo`, `video`, `location`, `motion`, `qr`,
	/// `spoken`, `external`, …
	#[db(min_len = 1, max_len = 32)]
	pub kind: String,
	#[db(private, max_len = 1024)]
	pub storage_path: Option<String>,
	#[db(private, max_len = 128)]
	pub storage_version_id: Option<String>,
	#[db(private, max_len = 128)]
	pub mime_type: Option<String>,
	/// SHA-256 hex of the exact evidence bytes the server accepted.
	#[db(private, max_len = 64)]
	pub sha256_digest: Option<String>,
	#[db(private, min = 0)]
	pub byte_length: Option<i64>,
	/// Capture integrity / provenance level label (for example `basic`).
	#[db(max_len = 32, default = "basic")]
	pub provenance_level: String,
	#[db(private)]
	pub capture_manifest: Option<String>,
	#[db(private)]
	pub capture_signature: Option<String>,
	#[db(private, max_len = 256)]
	pub capture_public_key: Option<String>,
	#[db(private, max_len = 128)]
	pub capture_key_id: Option<String>,
	/// `strongBox`, `trustedEnvironment`, or `secureEnclave` when attested.
	#[db(private, max_len = 64)]
	pub capture_key_storage: Option<String>,
	pub captured_at: Timestamp,
	#[db(created_at)]
	pub submitted_at: Timestamp,
}
