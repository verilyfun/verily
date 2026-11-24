//! Live football kick-up and table-tennis bounce tracking over MediaPipe pose +
//! EfficientDet-Lite0 ball detections.

use mediapipe::NormalizedLandmark;
use mediapipe::tasks::PoseJoint;
use verily_shared::ActionMovementKind;

use super::exercise_tracking::MovementCue;
use super::exercise_tracking::MovementObservation;
use super::exercise_tracking::MovementProgress;
use super::exercise_tracking::MovementTracker;
use super::exercise_tracking::POSE_MODEL_VERSION;

/// Ball detector identity included in ball-skill tracker versions.
pub const BALL_MODEL_VERSION: &str = "effdet0-v1";

/// A detected ball in upright, unmirrored, normalized image coordinates.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct BallObservation {
	pub x: f64,
	pub y: f64,
	/// Half the larger box side, as a fraction of the image height.
	pub radius: f64,
	pub score: f64,
}

/// The body part that sent the ball back up.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MovementLimb {
	LeftLeg,
	RightLeg,
	LeftArm,
	RightArm,
	Head,
	Chest,
}

/// One counted touch, used to drive live HUD feedback.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct BallTouch {
	pub timestamp_ms: i64,
	pub x: f64,
	pub y: f64,
	pub limb: MovementLimb,
}

#[derive(Clone, Debug)]
struct Reversal {
	x: f64,
	y: f64,
	radius: f64,
	timestamp_ms: i64,
	pose: Vec<NormalizedLandmark>,
	aspect_ratio: f64,
}

#[derive(Clone, Copy)]
struct LegDef {
	limb: MovementLimb,
	hip: PoseJoint,
	knee: PoseJoint,
	ankle: PoseJoint,
	toe: PoseJoint,
	other_ankle: PoseJoint,
}

const LEGS: [LegDef; 2] = [
	LegDef {
		limb: MovementLimb::LeftLeg,
		hip: PoseJoint::LeftHip,
		knee: PoseJoint::LeftKnee,
		ankle: PoseJoint::LeftAnkle,
		toe: PoseJoint::LeftFootIndex,
		other_ankle: PoseJoint::RightAnkle,
	},
	LegDef {
		limb: MovementLimb::RightLeg,
		hip: PoseJoint::RightHip,
		knee: PoseJoint::RightKnee,
		ankle: PoseJoint::RightAnkle,
		toe: PoseJoint::RightFootIndex,
		other_ankle: PoseJoint::LeftAnkle,
	},
];

/// Counts consecutive touches that keep a ball in the air.
#[derive(Clone, Debug)]
pub struct BallTouchTracker {
	kind: ActionMovementKind,
	run: u32,
	best: u32,
	last_seen_ms: Option<i64>,
	last_reversal_ms: Option<i64>,
	last_timestamp: Option<i64>,
	previous_y: Option<f64>,
	falling: bool,
	lowest: Option<Reversal>,
	touch: Option<BallTouch>,
	dropped: bool,
	progress: MovementProgress,
}

impl BallTouchTracker {
	pub const LOST_AFTER_MS: i64 = 900;
	pub const STALLED_AFTER_MS: i64 = 2000;

	#[must_use]
	pub const fn new(kind: ActionMovementKind) -> Self {
		Self {
			kind,
			run: 0,
			best: 0,
			last_seen_ms: None,
			last_reversal_ms: None,
			last_timestamp: None,
			previous_y: None,
			falling: false,
			lowest: None,
			touch: None,
			dropped: false,
			progress: MovementProgress::INITIAL,
		}
	}

	const fn is_football(&self) -> bool {
		matches!(self.kind, ActionMovementKind::FootballKickUps)
	}

	const fn minimum_touch_gap_ms(&self) -> i64 {
		if self.is_football() { 250 } else { 150 }
	}

	fn end_run(&mut self) {
		if self.run > 0 {
			self.dropped = true;
		}
		self.run = 0;
	}

	fn publish(&mut self, has_pose: bool, has_ball: bool) -> MovementProgress {
		let cue = if !has_pose {
			MovementCue::StepIntoFrame
		} else if !has_ball {
			MovementCue::ShowBall
		} else if self.dropped && self.run == 0 {
			MovementCue::Dropped
		} else {
			MovementCue::Perform
		};
		self.progress = MovementProgress {
			count: self.run,
			best: self.best,
			depth: 0.0,
			tracking: has_pose && has_ball,
			cue,
			touch: self.touch,
		};
		self.progress.clone()
	}

	fn contact(&self, ball: &Reversal) -> Option<MovementLimb> {
		let pose = &ball.pose;
		let aspect = ball.aspect_ratio;
		let visible = |j: PoseJoint| {
			pose.get(j.index())
				.is_some_and(|lm| lm.visibility.unwrap_or(0.0) >= 0.5)
		};
		let at = |j: PoseJoint| (pose[j.index()].x * aspect, pose[j.index()].y);
		let point = (ball.x * aspect, ball.y);
		let scale = body_scale(visible, at)?;

		let mut nearest: Option<MovementLimb> = None;
		let mut nearest_dist = f64::INFINITY;
		let mut consider = |limb: MovementLimb, a: (f64, f64), b: (f64, f64)| {
			let d = segment_distance(point, a, b);
			if d < nearest_dist {
				nearest_dist = d;
				nearest = Some(limb);
			}
		};

		if self.is_football() {
			for leg in LEGS {
				if visible(leg.hip) && visible(leg.knee) {
					consider(leg.limb, at(leg.hip), at(leg.knee));
				}
				let lifted = visible(leg.ankle)
					&& visible(leg.other_ankle)
					&& pose[leg.ankle.index()].y < pose[leg.other_ankle.index()].y - scale * 0.15;
				if !lifted || !visible(leg.knee) {
					continue;
				}
				consider(leg.limb, at(leg.knee), at(leg.ankle));
				if visible(leg.toe) {
					consider(leg.limb, at(leg.ankle), at(leg.toe));
				}
			}
			if visible(PoseJoint::LeftShoulder) && visible(PoseJoint::RightShoulder) {
				consider(
					MovementLimb::Chest,
					at(PoseJoint::LeftShoulder),
					at(PoseJoint::RightShoulder),
				);
			}
			if visible(PoseJoint::Nose) {
				let n = at(PoseJoint::Nose);
				consider(MovementLimb::Head, n, n);
			}
		} else {
			for (limb, wrist, index) in [
				(
					MovementLimb::LeftArm,
					PoseJoint::LeftWrist,
					PoseJoint::LeftIndex,
				),
				(
					MovementLimb::RightArm,
					PoseJoint::RightWrist,
					PoseJoint::RightIndex,
				),
			] {
				if !visible(wrist) || !visible(index) {
					continue;
				}
				let w = at(wrist);
				let idx = at(index);
				let hand = (idx.0 - w.0, idx.1 - w.1);
				let paddle_tip = (idx.0 + hand.0 * 2.5, idx.1 + hand.1 * 2.5);
				consider(limb, w, paddle_tip);
			}
		}

		let reach = ball.radius + scale * if self.is_football() { 0.35 } else { 0.30 };
		(nearest_dist <= reach).then_some(nearest).flatten()
	}
}

impl MovementTracker for BallTouchTracker {
	fn version(&self) -> String {
		let slug = if self.is_football() {
			"football-kick-ups"
		} else {
			"table-tennis-bounces"
		};
		format!("{POSE_MODEL_VERSION}.{BALL_MODEL_VERSION}.{slug}-v1")
	}

	fn progress(&self) -> &MovementProgress {
		&self.progress
	}

	fn update(&mut self, observation: &MovementObservation) -> MovementProgress {
		let timestamp = observation.timestamp_ms;
		if self.last_timestamp.is_some_and(|p| timestamp <= p) {
			return self.progress.clone();
		}
		self.last_timestamp = Some(timestamp);

		let has_pose = observation.pose.len() >= PoseJoint::COUNT;
		let Some(ball) = observation.ball else {
			if self
				.last_seen_ms
				.is_some_and(|seen| timestamp - seen > Self::LOST_AFTER_MS)
			{
				self.end_run();
				self.previous_y = None;
				self.falling = false;
				self.lowest = None;
			}
			return self.publish(has_pose, false);
		};

		self.last_seen_ms = Some(timestamp);
		let last_rev = *self.last_reversal_ms.get_or_insert(timestamp);
		if timestamp - last_rev > Self::STALLED_AFTER_MS {
			self.end_run();
			self.last_reversal_ms = Some(timestamp);
		}

		let rise = (ball.radius * 0.6).max(0.012);
		let prev_y = self.previous_y;
		self.previous_y = Some(ball.y);
		if prev_y.is_some_and(|py| ball.y > py + 0.002) {
			self.falling = true;
		}

		if self.falling && self.lowest.as_ref().is_none_or(|low| ball.y >= low.y) {
			self.lowest = Some(Reversal {
				x: ball.x,
				y: ball.y,
				radius: ball.radius,
				timestamp_ms: timestamp,
				pose: observation.pose.clone(),
				aspect_ratio: observation.aspect_ratio,
			});
		} else if self.falling
			&& self
				.lowest
				.as_ref()
				.is_some_and(|low| ball.y < low.y - rise)
		{
			self.falling = false;
			let lowest = self.lowest.take().expect("lowest present");
			self.last_reversal_ms = Some(timestamp);
			let limb = if lowest.pose.len() >= PoseJoint::COUNT {
				self.contact(&lowest)
			} else {
				None
			};
			if let Some(limb) = limb {
				let gap_ok = self.touch.is_none_or(|t| {
					lowest.timestamp_ms - t.timestamp_ms >= self.minimum_touch_gap_ms()
				});
				if gap_ok {
					self.run += 1;
					self.best = self.best.max(self.run);
					self.dropped = false;
					self.touch = Some(BallTouch {
						timestamp_ms: lowest.timestamp_ms,
						x: lowest.x,
						y: lowest.y,
						limb,
					});
				}
			} else {
				self.end_run();
			}
		}

		self.publish(has_pose, true)
	}

	fn interrupt(&mut self) {
		self.end_run();
		self.previous_y = None;
		self.falling = false;
		self.lowest = None;
		self.last_seen_ms = None;
		self.last_reversal_ms = None;
		self.publish(false, false);
	}
}

fn body_scale<V, A>(visible: V, at: A) -> Option<f64>
where
	V: Fn(PoseJoint) -> bool,
	A: Fn(PoseJoint) -> (f64, f64),
{
	for (shoulder, hip) in [
		(PoseJoint::LeftShoulder, PoseJoint::LeftHip),
		(PoseJoint::RightShoulder, PoseJoint::RightHip),
	] {
		if visible(shoulder) && visible(hip) {
			return Some(dist(at(shoulder), at(hip)));
		}
	}
	None
}

fn dist(a: (f64, f64), b: (f64, f64)) -> f64 {
	((a.0 - b.0).powi(2) + (a.1 - b.1).powi(2)).sqrt()
}

fn segment_distance(point: (f64, f64), start: (f64, f64), end: (f64, f64)) -> f64 {
	let sx = end.0 - start.0;
	let sy = end.1 - start.1;
	let len_sq = sx * sx + sy * sy;
	if len_sq == 0.0 {
		return dist(point, start);
	}
	let t = (((point.0 - start.0) * sx + (point.1 - start.1) * sy) / len_sq).clamp(0.0, 1.0);
	dist(point, (start.0 + sx * t, start.1 + sy * t))
}

#[cfg(test)]
mod tests {
	use super::*;

	fn kicker_pose() -> Vec<NormalizedLandmark> {
		let mut p = vec![
			NormalizedLandmark::new(0.5, 0.5, 0.0)
				.with_confidence(Some(0.9), Some(0.9));
			PoseJoint::COUNT
		];
		let set = |p: &mut [NormalizedLandmark], j: PoseJoint, x: f64, y: f64| {
			p[j.index()] =
				NormalizedLandmark::new(x, y, 0.0).with_confidence(Some(0.95), Some(0.95));
		};
		set(&mut p, PoseJoint::LeftShoulder, 0.45, 0.30);
		set(&mut p, PoseJoint::RightShoulder, 0.55, 0.30);
		set(&mut p, PoseJoint::LeftHip, 0.45, 0.50);
		set(&mut p, PoseJoint::RightHip, 0.55, 0.50);
		set(&mut p, PoseJoint::LeftKnee, 0.45, 0.70);
		set(&mut p, PoseJoint::RightKnee, 0.55, 0.62);
		set(&mut p, PoseJoint::LeftAnkle, 0.45, 0.90); // planted foot
		set(&mut p, PoseJoint::RightAnkle, 0.58, 0.75); // lifted kicking foot
		set(&mut p, PoseJoint::RightFootIndex, 0.62, 0.75);
		p
	}

	#[test]
	fn football_kick_up_counts_lifted_foot_touch_and_drops_floor_bounce() {
		let mut tracker = BallTouchTracker::new(ActionMovementKind::FootballKickUps);
		let pose = kicker_pose();

		// Ball falls to lifted right foot (y = 0.74) then rises.
		for (t, y) in [(100, 0.55), (150, 0.65), (200, 0.74), (250, 0.68)] {
			tracker.update(&MovementObservation {
				pose: pose.clone(),
				ball: Some(BallObservation {
					x: 0.60,
					y,
					radius: 0.04,
					score: 0.9,
				}),
				aspect_ratio: 1.0,
				timestamp_ms: t,
			});
		}
		assert_eq!(tracker.progress().count, 1);
		assert_eq!(tracker.progress().best, 1);

		// Ball bounces far away on the floor (y = 0.96, x = 0.10) -> drops run!
		for (t, y) in [(500, 0.80), (550, 0.96), (600, 0.85)] {
			tracker.update(&MovementObservation {
				pose: pose.clone(),
				ball: Some(BallObservation {
					x: 0.10,
					y,
					radius: 0.04,
					score: 0.9,
				}),
				aspect_ratio: 1.0,
				timestamp_ms: t,
			});
		}
		assert_eq!(tracker.progress().count, 0);
		assert_eq!(tracker.progress().best, 1);
		assert_eq!(tracker.progress().cue, MovementCue::Dropped);
	}
}
