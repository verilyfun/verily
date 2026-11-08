//! Live words come from the server list. Callers do not supply the word.

use std::time::Duration;

use chrono::DateTime;
use chrono::Utc;

#[path = "spoken_words.rs"]
mod spoken_words;

pub use spoken_words::SPOKEN_CHALLENGE_WORDS;

pub const CHALLENGE_TTL: Duration = Duration::from_secs(15 * 60);
pub const MAX_ISSUED_PER_PROOF: u32 = 5;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpokenChallenge {
	pub word: String,
	pub issued_at: DateTime<Utc>,
	pub expires_at: DateTime<Utc>,
}

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum SpokenError {
	#[error("no further challenge can be issued for this proof")]
	Exhausted,
	#[error("the word list is empty")]
	Unavailable,
}

/// Issues a word chosen by `entropy` modulo the server list.
///
/// A challenge that is still valid is returned unchanged. There is no argument
/// for a caller-chosen word.
/// A recording that starts before the word was issued is not that challenge.
pub fn capture_predates_challenge(captured_at: DateTime<Utc>, issued_at: DateTime<Utc>) -> bool {
	captured_at + crate::capture::CLOCK_TOLERANCE < issued_at
}

pub fn issue(
	existing: Option<&SpokenChallenge>,
	issued_count: u32,
	entropy: u64,
	now: DateTime<Utc>,
) -> Result<SpokenChallenge, SpokenError> {
	if let Some(current) = existing.filter(|challenge| challenge.expires_at > now) {
		return Ok(current.clone());
	}
	if issued_count >= MAX_ISSUED_PER_PROOF {
		return Err(SpokenError::Exhausted);
	}
	let words = SPOKEN_CHALLENGE_WORDS;
	if words.is_empty() {
		return Err(SpokenError::Unavailable);
	}
	let word = words[(entropy as usize) % words.len()].to_string();
	Ok(SpokenChallenge {
		word,
		issued_at: now,
		expires_at: now + CHALLENGE_TTL,
	})
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn the_server_picks_the_word_and_keeps_a_live_one() {
		let now = DateTime::from_timestamp(1_700_000_000, 0).unwrap();
		let first = issue(None, 0, 3, now).unwrap();
		assert_eq!(first.word, SPOKEN_CHALLENGE_WORDS[3]);
		let again = issue(Some(&first), 1, 99, now).unwrap();
		assert_eq!(again.word, first.word);
		assert_eq!(issue(None, 5, 1, now), Err(SpokenError::Exhausted));
	}

	#[test]
	fn a_recording_that_starts_before_the_word_is_not_that_challenge() {
		let issued = DateTime::from_timestamp(1_700_000_000, 0).unwrap();
		assert!(capture_predates_challenge(issued - CHALLENGE_TTL, issued));
		assert!(!capture_predates_challenge(issued, issued));
	}
}
