//! Capture windows and the spoken words issued inside them.
//!
//! `begin_capture` opens a window before the camera, microphone, sensors, or
//! scanner start; proof is accepted only inside an open window, once. Words
//! come from the server's list in `verily_verification`, never from a client
//! or a creator.

use leptoskit_auth::Account as AuthAccount;
use leptoskit_auth::AuthContext as _;
use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::policy;
use leptoskit_db::table;

use crate::schema::Attempt;

/// One capture window for one requirement of an attempt.
#[table(name = "capture_windows", index(attempt_id))]
#[policy(select, insert, update, |window, cx| {
	cx.signed_in(|me| window.participant_id.eq(me.account))
})]
pub struct CaptureWindowRow {
	pub id: Id<CaptureWindowRow>,
	#[db(on_delete = cascade)]
	pub attempt_id: Id<Attempt>,
	#[db(on_delete = cascade)]
	pub participant_id: Id<AuthAccount>,
	/// The requirement's id on the attempt's action revision.
	#[db(min_len = 1, max_len = 64)]
	pub requirement_id: String,
	/// 32 random bytes, unpadded base64url. The device's key attests to it.
	#[db(private, min_len = 1, max_len = 64)]
	pub challenge: String,
	pub opened_at: Timestamp,
	pub expires_at: Timestamp,
	/// When proof captured in this window was accepted. A window is used once.
	pub consumed_at: Option<Timestamp>,
	/// SHA-256 hex of the proof accepted in this window.
	#[db(private, max_len = 64)]
	pub sha256_digest: Option<String>,
}

/// A word the participant says while recording one proof.
#[table(name = "spoken_challenges", index(attempt_id))]
#[policy(select, insert, update, |challenge, cx| {
	cx.signed_in(|me| challenge.participant_id.eq(me.account))
})]
pub struct SpokenChallengeRow {
	pub id: Id<SpokenChallengeRow>,
	#[db(on_delete = cascade)]
	pub attempt_id: Id<Attempt>,
	#[db(on_delete = cascade)]
	pub participant_id: Id<AuthAccount>,
	#[db(min_len = 1, max_len = 64)]
	pub requirement_id: String,
	#[db(private, min_len = 1, max_len = 32)]
	pub word: String,
	pub issued_at: Timestamp,
	pub expires_at: Timestamp,
	/// When proof was bound to this word. A bound word is not issued again.
	pub bound_at: Option<Timestamp>,
}
