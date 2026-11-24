//! Advisory on-device local-check tally mirroring the server's frame replay.
//!
//! Guides the participant during live capture; the server independently replays
//! the pinned MediaPipe model over uploaded media and makes the real decision.

use verily_shared::ActionLocalCheck;

/// Consecutive frames required before a still photo check reports passed.
pub const LOCAL_CHECK_PHOTO_HOLD_FRAMES: usize = 3;
/// Grace frames kept in `Holding` before flipping guidance back down.
const HOLDING_GRACE_FRAMES: usize = 2;
/// Maximum sampled frames in server video replay (mirrors `verily_verification::local_check`).
const SERVER_REPLAY_MAX_FRAMES: usize = 12;

/// What one analysed camera frame showed for a check's label.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct LocalCheckFrame {
	pub score: f64,
	pub subject_seen: bool,
}

/// What the live guide tells the participant.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LocalCheckGuidance {
	NotSeen,
	SubjectSeen,
	Almost,
	Holding,
	Passed,
}

/// Counts live frame matches against an [`ActionLocalCheck`].
#[derive(Clone, Debug)]
pub struct LocalCheckTally {
	pub check: ActionLocalCheck,
	pub photo: bool,
	analysed: usize,
	matched: usize,
	consecutive: usize,
	since_match: usize,
	best: f64,
	last: Option<LocalCheckFrame>,
}

impl LocalCheckTally {
	#[must_use]
	pub const fn new(check: ActionLocalCheck, photo: bool) -> Self {
		Self {
			check,
			photo,
			analysed: 0,
			matched: 0,
			consecutive: 0,
			since_match: HOLDING_GRACE_FRAMES + 1,
			best: 0.0,
			last: None,
		}
	}

	#[must_use]
	pub const fn analysed(&self) -> usize {
		self.analysed
	}

	#[must_use]
	pub const fn matched(&self) -> usize {
		self.matched
	}

	#[must_use]
	pub const fn best_score(&self) -> f64 {
		self.best
	}

	pub fn add(&mut self, frame: LocalCheckFrame) {
		self.analysed += 1;
		self.last = Some(frame);
		if frame.score > self.best {
			self.best = frame.score;
		}
		if frame.score >= self.check.min_score {
			self.matched += 1;
			self.consecutive += 1;
			self.since_match = 0;
		} else {
			self.consecutive = 0;
			self.since_match += 1;
		}
	}

	#[must_use]
	pub fn passed(&self) -> bool {
		if self.photo {
			return self.consecutive >= LOCAL_CHECK_PHOTO_HOLD_FRAMES;
		}
		let min_frames = usize::try_from(self.check.min_frames.max(1)).unwrap_or(1);
		self.matched >= min_frames
			&& self.matched * SERVER_REPLAY_MAX_FRAMES >= min_frames * self.analysed
	}

	#[must_use]
	pub fn guidance(&self) -> LocalCheckGuidance {
		if self.passed() {
			return LocalCheckGuidance::Passed;
		}
		if self.since_match <= HOLDING_GRACE_FRAMES {
			return LocalCheckGuidance::Holding;
		}
		let Some(last) = self.last else {
			return LocalCheckGuidance::NotSeen;
		};
		if last.score > 0.0 {
			LocalCheckGuidance::Almost
		} else if last.subject_seen {
			LocalCheckGuidance::SubjectSeen
		} else {
			LocalCheckGuidance::NotSeen
		}
	}
}

#[cfg(test)]
mod tests {
	use verily_shared::LocalCheckTask;

	use super::*;

	fn gesture_check() -> ActionLocalCheck {
		ActionLocalCheck {
			task: LocalCheckTask::Gesture,
			label: "Thumb_Up".into(),
			min_score: 0.7,
			min_frames: 3,
		}
	}

	#[test]
	fn photo_requires_three_consecutive_frames() {
		let mut tally = LocalCheckTally::new(gesture_check(), true);
		tally.add(LocalCheckFrame {
			score: 0.85,
			subject_seen: true,
		});
		assert_eq!(tally.guidance(), LocalCheckGuidance::Holding);
		tally.add(LocalCheckFrame {
			score: 0.85,
			subject_seen: true,
		});
		assert!(!tally.passed());
		tally.add(LocalCheckFrame {
			score: 0.85,
			subject_seen: true,
		});
		assert!(tally.passed());
		assert_eq!(tally.guidance(), LocalCheckGuidance::Passed);
	}
}
