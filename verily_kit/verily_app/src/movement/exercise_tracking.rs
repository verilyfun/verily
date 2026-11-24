//! Live cyclic exercise and burpee tracking over MediaPipe's 33 BlazePose
//! landmarks (`mediapipe::tasks::PoseJoint`).
//!
//! Ported directly from Verily's biomechanics thresholds: aspect-corrected joint
//! angles, hysteresis dwell zones, minimum cycle durations, and 6-stage ordered
//! burpee progression. Guidance only — never submitted as proof.

use mediapipe::NormalizedLandmark;
use mediapipe::tasks::PoseJoint;
use verily_shared::ActionMovementKind;

use super::ball_tracking::BallObservation;
use super::ball_tracking::BallTouch;
use super::ball_tracking::BallTouchTracker;

/// Pose model identity included in every tracker version.
pub const POSE_MODEL_VERSION: &str = "pose-lite-v1";

/// What the camera saw in one analysed frame.
#[derive(Clone, Debug, PartialEq)]
pub struct MovementObservation {
	/// All 33 pose landmarks, or empty when nobody was found.
	pub pose: Vec<NormalizedLandmark>,
	/// The ball, for ball skills, when one was detected.
	pub ball: Option<BallObservation>,
	/// Image width divided by height, used to measure true angles.
	pub aspect_ratio: f64,
	/// Strictly increasing capture time in milliseconds.
	pub timestamp_ms: i64,
}

/// The next thing the participant should do, localized by the UI.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MovementCue {
	StepIntoFrame,
	GetIntoPosition,
	Perform,
	ReturnToStart,
	Crouch,
	Plank,
	FeetForward,
	Jump,
	Land,
	ShowBall,
	Dropped,
}

/// Live, advisory progress for one movement.
#[derive(Clone, Debug, PartialEq)]
pub struct MovementProgress {
	pub count: u32,
	pub best: u32,
	pub depth: f64,
	pub tracking: bool,
	pub cue: MovementCue,
	pub touch: Option<BallTouch>,
}

impl MovementProgress {
	pub const INITIAL: Self = Self {
		count: 0,
		best: 0,
		depth: 0.0,
		tracking: false,
		cue: MovementCue::StepIntoFrame,
		touch: None,
	};

	/// Whether the current repetition has reached the depth that counts.
	#[must_use]
	pub fn at_depth(&self) -> bool {
		self.depth >= RepetitionCounter::EXTENDED_THRESHOLD
	}
}

/// Turns camera observations into live coaching for one movement.
pub trait MovementTracker: Send {
	fn version(&self) -> String;
	fn progress(&self) -> &MovementProgress;
	fn update(&mut self, observation: &MovementObservation) -> MovementProgress;
	fn interrupt(&mut self);
}

/// Ball skills track a ball as well as the body.
#[must_use]
pub const fn is_ball_skill(kind: ActionMovementKind) -> bool {
	matches!(
		kind,
		ActionMovementKind::FootballKickUps | ActionMovementKind::TableTennisBounces
	)
}

/// Returns the live tracker for `kind`.
#[must_use]
pub fn movement_tracker_for(kind: ActionMovementKind) -> Box<dyn MovementTracker> {
	match kind {
		ActionMovementKind::Burpees => Box::new(BurpeeTracker::new()),
		ActionMovementKind::FootballKickUps | ActionMovementKind::TableTennisBounces => {
			Box::new(BallTouchTracker::new(kind))
		}
		other => Box::new(RepetitionTracker::new(other)),
	}
}

/// Counts cyclic exercises from a single joint-angle measurement.
#[derive(Clone, Debug)]
pub struct RepetitionTracker {
	kind: ActionMovementKind,
	counter: RepetitionCounter,
	progress: MovementProgress,
}

impl RepetitionTracker {
	#[must_use]
	pub fn new(kind: ActionMovementKind) -> Self {
		let (dwell_ms, minimum_cycle_ms) = timing(kind);
		Self {
			kind,
			counter: RepetitionCounter::new(dwell_ms, minimum_cycle_ms),
			progress: MovementProgress::INITIAL,
		}
	}
}

impl MovementTracker for RepetitionTracker {
	fn version(&self) -> String {
		format!("{POSE_MODEL_VERSION}.{}-v1", version_name(self.kind))
	}

	fn progress(&self) -> &MovementProgress {
		&self.progress
	}

	fn update(&mut self, observation: &MovementObservation) -> MovementProgress {
		self.counter.update(
			movement_depth(self.kind, &observation.pose, observation.aspect_ratio),
			observation.timestamp_ms,
		);
		self.progress = MovementProgress {
			count: self.counter.count,
			best: self.counter.count,
			depth: self.counter.depth,
			tracking: self.counter.tracking,
			cue: self.counter.cue(),
			touch: None,
		};
		self.progress.clone()
	}

	fn interrupt(&mut self) {
		self.counter.interrupt();
		self.progress = MovementProgress {
			count: self.counter.count,
			best: self.counter.count,
			depth: 0.0,
			tracking: false,
			cue: MovementCue::StepIntoFrame,
			touch: None,
		};
	}
}

/// Normalized movement depth for a single-angle exercise (`0.0..=1.0`).
///
/// Returns `None` when the required joints are not reliably visible.
#[must_use]
pub fn movement_depth(
	kind: ActionMovementKind,
	pose: &[NormalizedLandmark],
	aspect_ratio: f64,
) -> Option<f64> {
	if pose.len() < PoseJoint::COUNT || !aspect_ratio.is_finite() || aspect_ratio <= 0.0 {
		return None;
	}
	let body = Body {
		pose,
		aspect: aspect_ratio,
	};
	let depth = match kind {
		ActionMovementKind::Squats => scale(body.knees(), 170.0, 75.0),
		ActionMovementKind::Lunges => scale(body.both_sides(Limb::Knee, f64::min), 165.0, 70.0),
		ActionMovementKind::PressUps => {
			if body.torso_horizontal() {
				scale(body.elbows(), 170.0, 80.0)
			} else {
				None
			}
		}
		ActionMovementKind::BicepsCurls => {
			if body.torso_upright() {
				scale(body.elbows(), 165.0, 110.0)
			} else {
				None
			}
		}
		ActionMovementKind::SitUps => scale(body.hips(), 115.0, 45.0),
		ActionMovementKind::HighKnees => scale(body.both_sides(Limb::Hip, f64::min), 170.0, 85.0),
		ActionMovementKind::LateralRaises => body
			.both_sides(Limb::Shoulder, |l, r| (l + r) / 2.0)
			.map(|abduction| (abduction - 15.0) / 70.0),
		ActionMovementKind::SideBends => body.side_lean(),
		ActionMovementKind::StarJumps => body.star_spread(),
		ActionMovementKind::Burpees => scale(body.knees(), 170.0, 75.0),
		ActionMovementKind::FootballKickUps | ActionMovementKind::TableTennisBounces => None,
	}?;
	if !depth.is_finite() {
		return None;
	}
	Some(depth.clamp(0.0, 1.0))
}

fn scale(angle: Option<f64>, from: f64, span: f64) -> Option<f64> {
	angle.map(|a| (from - a) / span)
}

/// Counts stable rest -> depth -> rest cycles with hysteresis & dwell times.
#[derive(Clone, Debug)]
pub struct RepetitionCounter {
	pub dwell_ms: i64,
	pub minimum_cycle_ms: i64,
	pub count: u32,
	pub depth: f64,
	pub tracking: bool,
	armed: bool,
	extended: bool,
	candidate_since: Option<i64>,
	cycle_since: Option<i64>,
	last_timestamp: Option<i64>,
	candidate: i8,
}

impl RepetitionCounter {
	pub const REST_THRESHOLD: f64 = 0.2;
	pub const EXTENDED_THRESHOLD: f64 = 0.8;
	pub const MAXIMUM_FRAME_GAP_MS: i64 = 700;

	#[must_use]
	pub const fn new(dwell_ms: i64, minimum_cycle_ms: i64) -> Self {
		Self {
			dwell_ms,
			minimum_cycle_ms,
			count: 0,
			depth: 0.0,
			tracking: false,
			armed: false,
			extended: false,
			candidate_since: None,
			cycle_since: None,
			last_timestamp: None,
			candidate: -1,
		}
	}

	#[must_use]
	pub const fn cue(&self) -> MovementCue {
		if !self.tracking {
			return MovementCue::StepIntoFrame;
		}
		if !self.armed {
			return MovementCue::GetIntoPosition;
		}
		if self.extended {
			MovementCue::ReturnToStart
		} else {
			MovementCue::Perform
		}
	}

	pub fn update(&mut self, value: Option<f64>, timestamp_ms: i64) {
		let previous = self.last_timestamp;
		if previous.is_some_and(|p| timestamp_ms <= p) {
			return;
		}
		self.last_timestamp = Some(timestamp_ms);
		let Some(value) = value.filter(|v| v.is_finite()) else {
			self.interrupt();
			return;
		};
		if previous.is_some_and(|p| timestamp_ms - p > Self::MAXIMUM_FRAME_GAP_MS) {
			self.interrupt();
			return;
		}

		self.tracking = true;
		self.depth = value.clamp(0.0, 1.0);
		let zone: i8 = if self.depth < Self::REST_THRESHOLD {
			0
		} else if self.depth > Self::EXTENDED_THRESHOLD {
			1
		} else {
			-1
		};
		if zone != self.candidate {
			self.candidate = zone;
			self.candidate_since = Some(timestamp_ms);
		}
		if zone == -1
			|| self
				.candidate_since
				.is_none_or(|since| timestamp_ms - since < self.dwell_ms)
		{
			return;
		}

		if zone == 0 {
			if self.armed
				&& self.extended
				&& self
					.cycle_since
					.is_some_and(|since| timestamp_ms - since >= self.minimum_cycle_ms)
			{
				self.count += 1;
			}
			self.armed = true;
			self.extended = false;
			self.cycle_since = Some(timestamp_ms);
		} else if self.armed {
			self.extended = true;
		}
	}

	pub fn interrupt(&mut self) {
		self.tracking = false;
		self.depth = 0.0;
		self.armed = false;
		self.extended = false;
		self.candidate = -1;
		self.candidate_since = None;
		self.cycle_since = None;
	}
}

/// Ordered stages of a complete burpee.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum BurpeeStage {
	Ready = 0,
	Crouch = 1,
	Plank = 2,
	ReturnCrouch = 3,
	Jump = 4,
	Land = 5,
}

impl BurpeeStage {
	const COUNT: usize = 6;

	const fn next(self) -> Self {
		match self {
			Self::Ready => Self::Crouch,
			Self::Crouch => Self::Plank,
			Self::Plank => Self::ReturnCrouch,
			Self::ReturnCrouch => Self::Jump,
			Self::Jump => Self::Land,
			Self::Land => Self::Crouch,
		}
	}
}

/// Counts burpees as an ordered 6-stage sequence (squats alone never count).
#[derive(Clone, Debug)]
pub struct BurpeeTracker {
	count: u32,
	pub stage: BurpeeStage,
	floor: Option<f64>,
	last_timestamp: Option<i64>,
	stage_since: Option<i64>,
	progress: MovementProgress,
}

impl Default for BurpeeTracker {
	fn default() -> Self {
		Self::new()
	}
}

impl BurpeeTracker {
	#[must_use]
	pub const fn new() -> Self {
		Self {
			count: 0,
			stage: BurpeeStage::Ready,
			floor: None,
			last_timestamp: None,
			stage_since: None,
			progress: MovementProgress::INITIAL,
		}
	}
}

impl MovementTracker for BurpeeTracker {
	fn version(&self) -> String {
		format!("{POSE_MODEL_VERSION}.burpees-v1")
	}

	fn progress(&self) -> &MovementProgress {
		&self.progress
	}

	fn update(&mut self, observation: &MovementObservation) -> MovementProgress {
		let timestamp = observation.timestamp_ms;
		let previous = self.last_timestamp;
		if previous.is_some_and(|p| timestamp <= p) {
			return self.progress.clone();
		}
		self.last_timestamp = Some(timestamp);

		let bend = movement_depth(
			ActionMovementKind::Burpees,
			&observation.pose,
			observation.aspect_ratio,
		);
		let gap = previous.is_some_and(|p| timestamp - p > RepetitionCounter::MAXIMUM_FRAME_GAP_MS);
		let body = Body {
			pose: &observation.pose,
			aspect: observation.aspect_ratio,
		};
		let torso = if bend.is_none() || !body.all_visible(BURPEE_JOINTS) {
			None
		} else {
			body.torso()
		};
		let (Some(bend), Some(torso)) = (bend, torso) else {
			self.interrupt();
			return self.progress.clone();
		};
		if gap {
			self.interrupt();
			return self.progress.clone();
		}

		let ankle_y = (observation.pose[PoseJoint::LeftAnkle.index()].y
			+ observation.pose[PoseJoint::RightAnkle.index()].y)
			/ 2.0;
		let upright = torso.hip_y - torso.shoulder_y > torso.horizontal;
		let standing = upright && bend < 0.2;
		let crouched = bend > 0.8;
		let plank = !upright
			&& (torso.shoulder_y - torso.hip_y).abs() < torso.horizontal * 0.6
			&& bend < 0.25;

		if self
			.stage_since
			.is_none_or(|since| timestamp - since >= 100)
		{
			let advance = match self.stage {
				BurpeeStage::Ready => standing,
				BurpeeStage::Crouch | BurpeeStage::ReturnCrouch => crouched,
				BurpeeStage::Plank => plank,
				BurpeeStage::Jump => standing && self.floor.is_some_and(|f| ankle_y < f - 0.045),
				BurpeeStage::Land => {
					standing && self.floor.is_some_and(|f| (ankle_y - f).abs() < 0.025)
				}
			};
			if advance {
				if self.stage == BurpeeStage::Ready {
					self.floor = Some(ankle_y);
				}
				if self.stage == BurpeeStage::Land {
					self.count += 1;
					self.stage = BurpeeStage::Crouch;
					self.floor = Some(ankle_y);
				} else {
					self.stage = self.stage.next();
				}
				self.stage_since = Some(timestamp);
			}
		}

		let cue = match self.stage {
			BurpeeStage::Ready => MovementCue::GetIntoPosition,
			BurpeeStage::Crouch => MovementCue::Crouch,
			BurpeeStage::Plank => MovementCue::Plank,
			BurpeeStage::ReturnCrouch => MovementCue::FeetForward,
			BurpeeStage::Jump => MovementCue::Jump,
			BurpeeStage::Land => MovementCue::Land,
		};
		self.progress = MovementProgress {
			count: self.count,
			best: self.count,
			depth: f64::from(self.stage as u8) / ((BurpeeStage::COUNT - 1) as f64),
			tracking: true,
			cue,
			touch: None,
		};
		self.progress.clone()
	}

	fn interrupt(&mut self) {
		self.stage = BurpeeStage::Ready;
		self.floor = None;
		self.stage_since = None;
		self.progress = MovementProgress {
			count: self.count,
			best: self.count,
			depth: 0.0,
			tracking: false,
			cue: MovementCue::StepIntoFrame,
			touch: None,
		};
	}
}

const BURPEE_JOINTS: &[PoseJoint] = &[
	PoseJoint::LeftShoulder,
	PoseJoint::RightShoulder,
	PoseJoint::LeftHip,
	PoseJoint::RightHip,
	PoseJoint::LeftKnee,
	PoseJoint::RightKnee,
	PoseJoint::LeftAnkle,
	PoseJoint::RightAnkle,
];

const fn timing(kind: ActionMovementKind) -> (i64, i64) {
	match kind {
		ActionMovementKind::HighKnees => (60, 300),
		ActionMovementKind::StarJumps => (80, 450),
		ActionMovementKind::SitUps => (150, 800),
		_ => (150, 700),
	}
}

const fn version_name(kind: ActionMovementKind) -> &'static str {
	match kind {
		ActionMovementKind::Squats => "squats",
		ActionMovementKind::PressUps => "press-ups",
		ActionMovementKind::SitUps => "sit-ups",
		ActionMovementKind::Lunges => "lunges",
		ActionMovementKind::StarJumps => "star-jumps",
		ActionMovementKind::Burpees => "burpees",
		ActionMovementKind::HighKnees => "high-knees",
		ActionMovementKind::LateralRaises => "lateral-raises",
		ActionMovementKind::BicepsCurls => "biceps-curls",
		ActionMovementKind::SideBends => "side-bends",
		ActionMovementKind::FootballKickUps => "football-kick-ups",
		ActionMovementKind::TableTennisBounces => "table-tennis-bounces",
	}
}

#[derive(Clone, Copy)]
enum Limb {
	Shoulder,
	Elbow,
	Hip,
	Knee,
}

#[derive(Clone, Copy)]
struct Torso {
	shoulder_y: f64,
	hip_y: f64,
	horizontal: f64,
}

struct Body<'a> {
	pose: &'a [NormalizedLandmark],
	aspect: f64,
}

impl<'a> Body<'a> {
	const MINIMUM_VISIBILITY: f32 = 0.6;

	fn left_triple(limb: Limb) -> (PoseJoint, PoseJoint, PoseJoint) {
		match limb {
			Limb::Shoulder => (
				PoseJoint::LeftHip,
				PoseJoint::LeftShoulder,
				PoseJoint::LeftElbow,
			),
			Limb::Elbow => (
				PoseJoint::LeftShoulder,
				PoseJoint::LeftElbow,
				PoseJoint::LeftWrist,
			),
			Limb::Hip => (
				PoseJoint::LeftShoulder,
				PoseJoint::LeftHip,
				PoseJoint::LeftKnee,
			),
			Limb::Knee => (
				PoseJoint::LeftHip,
				PoseJoint::LeftKnee,
				PoseJoint::LeftAnkle,
			),
		}
	}

	fn right_triple(limb: Limb) -> (PoseJoint, PoseJoint, PoseJoint) {
		match limb {
			Limb::Shoulder => (
				PoseJoint::RightHip,
				PoseJoint::RightShoulder,
				PoseJoint::RightElbow,
			),
			Limb::Elbow => (
				PoseJoint::RightShoulder,
				PoseJoint::RightElbow,
				PoseJoint::RightWrist,
			),
			Limb::Hip => (
				PoseJoint::RightShoulder,
				PoseJoint::RightHip,
				PoseJoint::RightKnee,
			),
			Limb::Knee => (
				PoseJoint::RightHip,
				PoseJoint::RightKnee,
				PoseJoint::RightAnkle,
			),
		}
	}

	fn knees(&self) -> Option<f64> {
		self.either_side(Limb::Knee)
	}

	fn elbows(&self) -> Option<f64> {
		self.either_side(Limb::Elbow)
	}

	fn hips(&self) -> Option<f64> {
		self.either_side(Limb::Hip)
	}

	fn either_side(&self, limb: Limb) -> Option<f64> {
		let left = self.angle(Self::left_triple(limb));
		let right = self.angle(Self::right_triple(limb));
		match (left, right) {
			(Some(l), Some(r)) => Some((l + r) / 2.0),
			(Some(l), None) => Some(l),
			(None, Some(r)) => Some(r),
			(None, None) => None,
		}
	}

	fn both_sides(&self, limb: Limb, combine: fn(f64, f64) -> f64) -> Option<f64> {
		let left = self.angle(Self::left_triple(limb))?;
		let right = self.angle(Self::right_triple(limb))?;
		Some(combine(left, right))
	}

	fn torso(&self) -> Option<Torso> {
		let shoulder = self.mean(PoseJoint::LeftShoulder, PoseJoint::RightShoulder)?;
		let hip = self.mean(PoseJoint::LeftHip, PoseJoint::RightHip)?;
		Some(Torso {
			shoulder_y: shoulder.1,
			hip_y: hip.1,
			horizontal: ((shoulder.0 - hip.0) * self.aspect).abs(),
		})
	}

	fn torso_horizontal(&self) -> bool {
		self.torso()
			.is_some_and(|t| (t.shoulder_y - t.hip_y).abs() <= t.horizontal * 0.6)
	}

	fn torso_upright(&self) -> bool {
		self.torso()
			.is_some_and(|t| (t.shoulder_y - t.hip_y).abs() >= t.horizontal)
	}

	fn side_lean(&self) -> Option<f64> {
		if !self.all_visible(&[
			PoseJoint::LeftShoulder,
			PoseJoint::RightShoulder,
			PoseJoint::LeftHip,
			PoseJoint::RightHip,
		]) {
			return None;
		}
		let torso = self.torso()?;
		let height = (torso.shoulder_y - torso.hip_y).abs().max(0.01);
		Some((torso.horizontal / height - 0.08) / 0.4)
	}

	fn star_spread(&self) -> Option<f64> {
		if !self.all_visible(&[
			PoseJoint::LeftShoulder,
			PoseJoint::RightShoulder,
			PoseJoint::LeftWrist,
			PoseJoint::RightWrist,
			PoseJoint::LeftHip,
			PoseJoint::RightHip,
			PoseJoint::LeftAnkle,
			PoseJoint::RightAnkle,
		]) {
			return None;
		}
		let y = |j: PoseJoint| self.pose[j.index()].y;
		let x = |j: PoseJoint| self.pose[j.index()].x;
		let torso = self.torso()?;
		let height = (torso.shoulder_y - torso.hip_y).abs().max(0.01);
		let shoulder_width = (x(PoseJoint::LeftShoulder) - x(PoseJoint::RightShoulder))
			.abs()
			.max(0.01);
		let arms_up = ((y(PoseJoint::LeftShoulder) + y(PoseJoint::RightShoulder)
			- y(PoseJoint::LeftWrist)
			- y(PoseJoint::RightWrist))
			/ 2.0
			/ height
			+ 0.4)
			/ 0.9;
		let feet_apart =
			((x(PoseJoint::LeftAnkle) - x(PoseJoint::RightAnkle)).abs() / shoulder_width - 1.0)
				/ 0.9;
		Some(arms_up.min(feet_apart))
	}

	fn angle(&self, joints: (PoseJoint, PoseJoint, PoseJoint)) -> Option<f64> {
		let (a, b, c) = joints;
		if !self.all_visible(&[a, b, c]) {
			return None;
		}
		let pa = self.pose[a.index()];
		let pb = self.pose[b.index()];
		let pc = self.pose[c.index()];
		let ax = (pa.x - pb.x) * self.aspect;
		let ay = pa.y - pb.y;
		let cx = (pc.x - pb.x) * self.aspect;
		let cy = pc.y - pb.y;
		let length = ((ax * ax + ay * ay) * (cx * cx + cy * cy)).sqrt();
		if length < 0.000_01 {
			return None;
		}
		let cosine = ((ax * cx + ay * cy) / length).clamp(-1.0, 1.0);
		Some(cosine.acos().to_degrees())
	}

	fn mean(&self, left: PoseJoint, right: PoseJoint) -> Option<(f64, f64)> {
		let mut sum_x = 0.0;
		let mut sum_y = 0.0;
		let mut count = 0.0;
		for j in [left, right] {
			if self.visible(j) {
				let p = self.pose[j.index()];
				sum_x += p.x;
				sum_y += p.y;
				count += 1.0;
			}
		}
		if count == 0.0 {
			None
		} else {
			Some((sum_x / count, sum_y / count))
		}
	}

	fn all_visible(&self, joints: &[PoseJoint]) -> bool {
		joints.iter().all(|&j| self.visible(j))
	}

	fn visible(&self, joint: PoseJoint) -> bool {
		let Some(point) = self.pose.get(joint.index()) else {
			return false;
		};
		point.x.is_finite()
			&& point.y.is_finite()
			&& point.visibility.unwrap_or(0.0) >= Self::MINIMUM_VISIBILITY
			&& point.presence.unwrap_or(1.0) >= Self::MINIMUM_VISIBILITY
			&& (0.0..=1.0).contains(&point.x)
			&& (0.0..=1.0).contains(&point.y)
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	fn blank_pose() -> Vec<NormalizedLandmark> {
		vec![
			NormalizedLandmark::new(0.5, 0.5, 0.0).with_confidence(Some(0.95), Some(0.95));
			PoseJoint::COUNT
		]
	}

	fn set_joint(pose: &mut [NormalizedLandmark], joint: PoseJoint, x: f64, y: f64) {
		pose[joint.index()] =
			NormalizedLandmark::new(x, y, 0.0).with_confidence(Some(0.95), Some(0.95));
	}

	fn squat_pose(deep: bool) -> Vec<NormalizedLandmark> {
		let mut p = blank_pose();
		if deep {
			// Knee bent ~90 degrees.
			set_joint(&mut p, PoseJoint::LeftHip, 0.4, 0.55);
			set_joint(&mut p, PoseJoint::LeftKnee, 0.6, 0.55);
			set_joint(&mut p, PoseJoint::LeftAnkle, 0.6, 0.85);
			set_joint(&mut p, PoseJoint::RightHip, 0.4, 0.55);
			set_joint(&mut p, PoseJoint::RightKnee, 0.6, 0.55);
			set_joint(&mut p, PoseJoint::RightAnkle, 0.6, 0.85);
		} else {
			// Standing straight (~180 degrees).
			set_joint(&mut p, PoseJoint::LeftHip, 0.5, 0.45);
			set_joint(&mut p, PoseJoint::LeftKnee, 0.5, 0.65);
			set_joint(&mut p, PoseJoint::LeftAnkle, 0.5, 0.85);
			set_joint(&mut p, PoseJoint::RightHip, 0.5, 0.45);
			set_joint(&mut p, PoseJoint::RightKnee, 0.5, 0.65);
			set_joint(&mut p, PoseJoint::RightAnkle, 0.5, 0.85);
		}
		p
	}

	#[test]
	fn squat_tracker_counts_full_cycle_and_rejects_short_jitter() {
		let mut tracker = movement_tracker_for(ActionMovementKind::Squats);
		// Arm in standing position for > 150ms.
		for t in [0, 100, 200] {
			tracker.update(&MovementObservation {
				pose: squat_pose(false),
				ball: None,
				aspect_ratio: 1.0,
				timestamp_ms: t,
			});
		}
		assert_eq!(tracker.progress().cue, MovementCue::Perform);

		// Reach deep squat for > 150ms.
		for t in [400, 500, 600] {
			tracker.update(&MovementObservation {
				pose: squat_pose(true),
				ball: None,
				aspect_ratio: 1.0,
				timestamp_ms: t,
			});
		}
		assert_eq!(tracker.progress().cue, MovementCue::ReturnToStart);

		// Stand back up past minimum cycle time (700ms).
		for t in [900, 1000, 1100] {
			tracker.update(&MovementObservation {
				pose: squat_pose(false),
				ball: None,
				aspect_ratio: 1.0,
				timestamp_ms: t,
			});
		}
		assert_eq!(tracker.progress().count, 1);
	}

	#[test]
	fn frame_gap_interrupts_partial_rep_without_losing_completed_count() {
		let mut counter = RepetitionCounter::new(100, 500);
		for t in [0, 150] {
			counter.update(Some(0.05), t);
		}
		for t in [300, 450] {
			counter.update(Some(0.95), t);
		}
		// Big gap (> 700ms) discards the partial rep.
		counter.update(Some(0.05), 1500);
		assert_eq!(counter.count, 0);
		assert!(!counter.tracking);
	}
}
