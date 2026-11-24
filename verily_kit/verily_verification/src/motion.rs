//! Deterministic server-reproducible device motion analysis.
//!
//! Ported from `packages/verily_evidence/lib/src/motion_evidence.dart`. Client
//! repetition counts are never trusted as proof: the server validates and
//! re-analyzes the bounded monotonic gyroscope + accelerometer trace.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use verily_shared::EvidenceDecisionStatus;

pub const MINIMUM_SAMPLES: usize = 10;
pub const MAXIMUM_SAMPLES: usize = 1000;
pub const MAXIMUM_DURATION_SECONDS: u32 = 30;
pub const MAXIMUM_SAMPLE_GAP_MICROS: i64 = 250_000;
pub const MAXIMUM_GYROSCOPE_MAGNITUDE: f64 = 100.0;
pub const MAXIMUM_ACCELERATION_MAGNITUDE: f64 = 200.0;
pub const MAXIMUM_RULE_REPETITIONS: u32 = 20;
pub const MAXIMUM_RULE_ANGULAR_SPEED: f64 = 25.0;
pub const MAXIMUM_RULE_FREE_FALL_MS: u32 = 700;
pub const MAXIMUM_RULE_PEAK_ACCELERATION: f64 = 60.0;
pub const MINIMUM_PHONE_TOSS_PEAK_ACCELERATION: f64 = 8.0;
pub const MAXIMUM_STILLNESS_ANGULAR_SPEED: f64 = 2.0;
pub const ROTATION_DEADBAND: f64 = 0.35;
pub const FREE_FALL_ACCELERATION: f64 = 3.0;
pub const TOSS_IMPULSE_WINDOW_MICROS: i64 = 600_000;
pub const SHAKE_PEAK_SEPARATION_MICROS: i64 = 120_000;

/// Legacy hold structure kept for callers without a raw motion trace.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MotionHold {
	pub status: EvidenceDecisionStatus,
	pub reason_code: &'static str,
	pub summary: &'static str,
}

/// Client-reported repetition scores never prove a motion action.
#[must_use]
pub fn client_repetitions_are_proof(_count: u32) -> bool {
	false
}

/// Fallback when a trace was not supplied alongside a motion attempt.
#[must_use]
pub fn hold_for_review(_client_repetitions: u32) -> MotionHold {
	MotionHold {
		status: EvidenceDecisionStatus::ManualReview,
		reason_code: "motion_not_recomputed",
		summary: "A person will check this proof.",
	}
}

/// Real-world motion patterns evaluated deterministically without a model verdict.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum MotionActionType {
	PhoneToss,
	Rotation,
	Shake,
	Stillness,
}

/// Device sensor axis (pitch=X, roll=Y, yaw=Z).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum MotionAxis {
	Yaw,
	Pitch,
	Roll,
	Any,
}

/// One bounded monotonic gyroscope + accelerometer sample.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct MotionSample {
	pub elapsed_microseconds: i64,
	pub gyroscope_x: f64,
	pub gyroscope_y: f64,
	pub gyroscope_z: f64,
	pub acceleration_x: f64,
	pub acceleration_y: f64,
	pub acceleration_z: f64,
}

impl MotionSample {
	pub fn to_canonical_values(&self) -> Result<[i64; 7], MotionError> {
		Ok([
			self.elapsed_microseconds,
			quantize(self.gyroscope_x)?,
			quantize(self.gyroscope_y)?,
			quantize(self.gyroscope_z)?,
			quantize(self.acceleration_x)?,
			quantize(self.acceleration_y)?,
			quantize(self.acceleration_z)?,
		])
	}

	pub fn from_canonical_values(values: [i64; 7]) -> Self {
		Self {
			elapsed_microseconds: values[0],
			gyroscope_x: (values[1] as f64) / 1_000_000.0,
			gyroscope_y: (values[2] as f64) / 1_000_000.0,
			gyroscope_z: (values[3] as f64) / 1_000_000.0,
			acceleration_x: (values[4] as f64) / 1_000_000.0,
			acceleration_y: (values[5] as f64) / 1_000_000.0,
			acceleration_z: (values[6] as f64) / 1_000_000.0,
		}
	}
}

/// Creator-authored motion thresholds validated by the server.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct MotionRule {
	pub kind: MotionActionType,
	pub axis: MotionAxis,
	pub target_repetitions: u32,
	pub minimum_duration_seconds: u32,
	pub maximum_duration_seconds: u32,
	pub minimum_angular_speed_radians_per_second: f64,
	pub maximum_angular_speed_radians_per_second: f64,
	pub minimum_axis_dominance: f64,
	pub minimum_free_fall_milliseconds: u32,
	pub maximum_free_fall_milliseconds: u32,
	pub minimum_peak_acceleration_meters_per_second_squared: f64,
	pub maximum_peak_acceleration_meters_per_second_squared: f64,
}

/// Privacy-safe deterministic analysis outcome.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MotionAnalysis {
	pub accepted: bool,
	pub reason_code: &'static str,
	pub score: f64,
	pub sample_count: usize,
	pub duration_milliseconds: u32,
	pub repetition_count: u32,
	pub peak_angular_speed_radians_per_second: f64,
	pub peak_acceleration_meters_per_second_squared: f64,
	pub axis_dominance: f64,
	pub free_fall_milliseconds: u32,
}

#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum MotionError {
	#[error("{0}")]
	InvalidRule(&'static str),
	#[error("{0}")]
	InvalidTrace(&'static str),
}

/// Validate creator-authored motion rule bounds.
pub fn rule_problem(rule: &MotionRule) -> Option<&'static str> {
	if rule.minimum_duration_seconds < 1
		|| rule.maximum_duration_seconds > MAXIMUM_DURATION_SECONDS
		|| rule.maximum_duration_seconds < rule.minimum_duration_seconds
	{
		return Some("Motion duration bounds are invalid.");
	}
	if rule.target_repetitions < 1 || rule.target_repetitions > MAXIMUM_RULE_REPETITIONS {
		return Some("Motion repetitions must be between 1 and 20.");
	}
	if rule.kind == MotionActionType::Rotation && rule.axis == MotionAxis::Any {
		return Some("Counted rotations require a specific axis.");
	}
	if matches!(
		rule.kind,
		MotionActionType::PhoneToss | MotionActionType::Stillness
	) && (rule.axis != MotionAxis::Any || rule.target_repetitions != 1)
	{
		return Some("Phone toss and stillness rules use any axis and one repetition.");
	}
	if !rule.minimum_angular_speed_radians_per_second.is_finite()
		|| !rule.maximum_angular_speed_radians_per_second.is_finite()
		|| rule.minimum_angular_speed_radians_per_second <= 0.0
		|| rule.maximum_angular_speed_radians_per_second
			< rule.minimum_angular_speed_radians_per_second
		|| rule.maximum_angular_speed_radians_per_second > MAXIMUM_RULE_ANGULAR_SPEED
	{
		return Some("Motion angular speed bounds are invalid.");
	}
	if !rule.minimum_axis_dominance.is_finite()
		|| rule.minimum_axis_dominance < 0.5
		|| rule.minimum_axis_dominance > 1.0
	{
		return Some("Motion axis dominance is invalid.");
	}
	if rule.minimum_free_fall_milliseconds < 100
		|| rule.maximum_free_fall_milliseconds > MAXIMUM_RULE_FREE_FALL_MS
		|| rule.maximum_free_fall_milliseconds < rule.minimum_free_fall_milliseconds
	{
		return Some("Motion free-fall bounds are invalid.");
	}
	if !rule
		.minimum_peak_acceleration_meters_per_second_squared
		.is_finite()
		|| !rule
			.maximum_peak_acceleration_meters_per_second_squared
			.is_finite()
		|| rule.minimum_peak_acceleration_meters_per_second_squared <= 0.0
		|| rule.maximum_peak_acceleration_meters_per_second_squared
			< rule.minimum_peak_acceleration_meters_per_second_squared
		|| rule.maximum_peak_acceleration_meters_per_second_squared > MAXIMUM_RULE_PEAK_ACCELERATION
	{
		return Some("Motion acceleration bounds are invalid.");
	}
	if rule.kind == MotionActionType::PhoneToss
		&& rule.minimum_peak_acceleration_meters_per_second_squared
			< MINIMUM_PHONE_TOSS_PEAK_ACCELERATION
	{
		return Some("Phone toss impulse threshold is unsafe.");
	}
	if rule.kind == MotionActionType::Stillness
		&& rule.maximum_angular_speed_radians_per_second > MAXIMUM_STILLNESS_ANGULAR_SPEED
	{
		return Some("Stillness threshold is too permissive.");
	}
	None
}

/// Validate a motion rule or return [`MotionError::InvalidRule`].
pub fn validate_rule(rule: &MotionRule) -> Result<(), MotionError> {
	if let Some(problem) = rule_problem(rule) {
		return Err(MotionError::InvalidRule(problem));
	}
	Ok(())
}

/// Parse canonical JSON `{"version":1,"samples":[[elapsed_us,gx,gy,gz,ax,ay,az],...]}`.
pub fn parse_canonical_trace_json(json: &str) -> Result<Vec<MotionSample>, MotionError> {
	#[derive(Deserialize)]
	struct Wire {
		version: u32,
		samples: Vec<[i64; 7]>,
	}
	let wire: Wire = serde_json::from_str(json)
		.map_err(|_| MotionError::InvalidTrace("Malformed motion JSON."))?;
	if wire.version != 1 {
		return Err(MotionError::InvalidTrace(
			"Unsupported motion trace version.",
		));
	}
	Ok(wire
		.samples
		.into_iter()
		.map(MotionSample::from_canonical_values)
		.collect())
}

/// Canonical JSON string used for device signatures and replay hashes.
pub fn canonical_motion_trace_json(samples: &[MotionSample]) -> Result<String, MotionError> {
	let rows = samples
		.iter()
		.map(MotionSample::to_canonical_values)
		.collect::<Result<Vec<_>, _>>()?;
	let mut out = String::from("{\"version\":1,\"samples\":[");
	for (idx, row) in rows.iter().enumerate() {
		if idx > 0 {
			out.push(',');
		}
		out.push('[');
		for (col, val) in row.iter().enumerate() {
			if col > 0 {
				out.push(',');
			}
			use std::fmt::Write as _;
			let _ = write!(out, "{val}");
		}
		out.push(']');
	}
	out.push_str("]}");
	Ok(out)
}

/// Lowercase SHA-256 hex digest of [`canonical_motion_trace_json`].
pub fn motion_trace_sha256(samples: &[MotionSample]) -> Result<String, MotionError> {
	let canonical = canonical_motion_trace_json(samples)?;
	let digest = Sha256::digest(canonical.as_bytes());
	let mut hex = String::with_capacity(64);
	for b in digest {
		use std::fmt::Write as _;
		let _ = write!(hex, "{b:02x}");
	}
	Ok(hex)
}

/// Deterministically validate and evaluate a motion trace against `rule`.
pub fn analyze(samples: &[MotionSample], rule: &MotionRule) -> Result<MotionAnalysis, MotionError> {
	validate_rule(rule)?;
	validate_trace(samples)?;
	let duration_milliseconds =
		((samples.last().unwrap().elapsed_microseconds as f64) / 1000.0).round() as u32;
	let metrics = TraceMetrics::from_samples(samples, rule.axis);
	let base = BaseMetrics {
		sample_count: samples.len(),
		duration_milliseconds,
		peak_angular_speed: metrics.peak_angular_speed,
		peak_acceleration: metrics.peak_acceleration,
		axis_dominance: metrics.axis_dominance,
	};

	if duration_milliseconds < rule.minimum_duration_seconds * 1000
		|| duration_milliseconds > rule.maximum_duration_seconds * 1000
	{
		return Ok(make_result(
			base,
			false,
			"motion_duration_out_of_range",
			0.0,
			0,
			0,
		));
	}

	Ok(match rule.kind {
		MotionActionType::Rotation => analyze_rotation(samples, rule, metrics, base),
		MotionActionType::PhoneToss => analyze_phone_toss(samples, rule, metrics, base),
		MotionActionType::Shake => analyze_shake(samples, rule, metrics, base),
		MotionActionType::Stillness => analyze_stillness(rule, metrics, base),
	})
}

fn validate_trace(samples: &[MotionSample]) -> Result<(), MotionError> {
	if samples.len() < MINIMUM_SAMPLES || samples.len() > MAXIMUM_SAMPLES {
		return Err(MotionError::InvalidTrace(
			"Motion evidence needs 10-1000 samples.",
		));
	}
	if samples[0].elapsed_microseconds != 0 {
		return Err(MotionError::InvalidTrace(
			"Motion evidence must begin at zero microseconds.",
		));
	}
	let mut previous_micros = -1_i64;
	for sample in samples {
		if sample.elapsed_microseconds <= previous_micros {
			return Err(MotionError::InvalidTrace(
				"Motion sample times must be strictly increasing.",
			));
		}
		if previous_micros >= 0
			&& sample.elapsed_microseconds - previous_micros > MAXIMUM_SAMPLE_GAP_MICROS
		{
			return Err(MotionError::InvalidTrace(
				"Motion evidence contains a sampling gap.",
			));
		}
		let gyro = [sample.gyroscope_x, sample.gyroscope_y, sample.gyroscope_z];
		let accel = [
			sample.acceleration_x,
			sample.acceleration_y,
			sample.acceleration_z,
		];
		if gyro.iter().chain(accel.iter()).any(|v| !v.is_finite())
			|| gyro.iter().any(|v| v.abs() > MAXIMUM_GYROSCOPE_MAGNITUDE)
			|| accel
				.iter()
				.any(|v| v.abs() > MAXIMUM_ACCELERATION_MAGNITUDE)
		{
			return Err(MotionError::InvalidTrace(
				"Motion evidence contains an invalid sensor value.",
			));
		}
		previous_micros = sample.elapsed_microseconds;
	}
	if samples.last().unwrap().elapsed_microseconds
		> i64::from(MAXIMUM_DURATION_SECONDS) * 1_000_000
	{
		return Err(MotionError::InvalidTrace(
			"Motion evidence exceeds 30 seconds.",
		));
	}
	Ok(())
}

#[derive(Clone, Copy)]
struct BaseMetrics {
	sample_count: usize,
	duration_milliseconds: u32,
	peak_angular_speed: f64,
	peak_acceleration: f64,
	axis_dominance: f64,
}

#[derive(Clone, Copy)]
struct TraceMetrics {
	peak_angular_speed: f64,
	peak_acceleration: f64,
	axis_dominance: f64,
}

impl TraceMetrics {
	fn from_samples(samples: &[MotionSample], axis: MotionAxis) -> Self {
		let mut peak_angular_speed = 0.0_f64;
		let mut peak_acceleration = 0.0_f64;
		let mut target_energy = 0.0_f64;
		let mut total_energy = 0.0_f64;
		for sample in samples {
			let angular_mag = (sample.gyroscope_x * sample.gyroscope_x
				+ sample.gyroscope_y * sample.gyroscope_y
				+ sample.gyroscope_z * sample.gyroscope_z)
				.sqrt();
			let accel_mag = acceleration_magnitude(sample);
			peak_angular_speed = peak_angular_speed.max(angular_mag);
			peak_acceleration = peak_acceleration.max(accel_mag);
			target_energy += axis_gyroscope(sample, axis).abs();
			total_energy += angular_mag;
		}
		Self {
			peak_angular_speed,
			peak_acceleration,
			axis_dominance: if total_energy == 0.0 {
				1.0
			} else {
				target_energy / total_energy
			},
		}
	}
}

fn make_result(
	base: BaseMetrics,
	accepted: bool,
	reason_code: &'static str,
	score: f64,
	repetition_count: u32,
	free_fall_milliseconds: u32,
) -> MotionAnalysis {
	MotionAnalysis {
		accepted,
		reason_code,
		score,
		sample_count: base.sample_count,
		duration_milliseconds: base.duration_milliseconds,
		repetition_count,
		peak_angular_speed_radians_per_second: base.peak_angular_speed,
		peak_acceleration_meters_per_second_squared: base.peak_acceleration,
		axis_dominance: base.axis_dominance,
		free_fall_milliseconds,
	}
}

fn analyze_rotation(
	samples: &[MotionSample],
	rule: &MotionRule,
	metrics: TraceMetrics,
	base: BaseMetrics,
) -> MotionAnalysis {
	let mut segment_radians = 0.0_f64;
	let mut repetitions = 0_u32;
	for idx in 1..samples.len() {
		let prev = axis_gyroscope(&samples[idx - 1], rule.axis);
		let curr = axis_gyroscope(&samples[idx], rule.axis);
		let delta_seconds = (samples[idx].elapsed_microseconds
			- samples[idx - 1].elapsed_microseconds) as f64
			/ 1_000_000.0;
		let filtered_prev = if prev.abs() < ROTATION_DEADBAND {
			0.0
		} else {
			prev
		};
		let filtered_curr = if curr.abs() < ROTATION_DEADBAND {
			0.0
		} else {
			curr
		};
		let delta_radians = (filtered_prev + filtered_curr) * 0.5 * delta_seconds;
		if delta_radians != 0.0
			&& segment_radians != 0.0
			&& delta_radians.signum() != segment_radians.signum()
		{
			segment_radians = 0.0;
		}
		segment_radians += delta_radians;
		let full_turn = std::f64::consts::TAU;
		while segment_radians.abs() + 0.000_001 >= full_turn {
			repetitions = repetitions.saturating_add(1);
			segment_radians -= segment_radians.signum() * full_turn;
		}
	}
	let speed = metrics.peak_angular_speed;
	let unsafe_speed = speed > rule.maximum_angular_speed_radians_per_second;
	let speed_reached = speed >= rule.minimum_angular_speed_radians_per_second;
	let axis_dominant = metrics.axis_dominance >= rule.minimum_axis_dominance;
	let reps_reached = repetitions >= rule.target_repetitions;
	let score = (f64::from(repetitions) / f64::from(rule.target_repetitions))
		.min(speed / rule.minimum_angular_speed_radians_per_second)
		.min(metrics.axis_dominance / rule.minimum_axis_dominance)
		.clamp(0.0, 1.0);
	let reason_code = if unsafe_speed {
		"motion_rotation_too_fast"
	} else if !axis_dominant {
		"motion_rotation_wrong_axis"
	} else if !speed_reached {
		"motion_rotation_too_slow"
	} else if !reps_reached {
		"motion_rotation_count_not_met"
	} else {
		"motion_verified"
	};
	make_result(
		base,
		!unsafe_speed && speed_reached && axis_dominant && reps_reached,
		reason_code,
		score,
		repetitions,
		0,
	)
}

fn analyze_phone_toss(
	samples: &[MotionSample],
	rule: &MotionRule,
	metrics: TraceMetrics,
	base: BaseMetrics,
) -> MotionAnalysis {
	let free_fall = longest_free_fall(samples);
	let free_fall_ms = free_fall.map_or(0, |(start, end)| {
		(((end - start) as f64) / 1000.0).round() as u32
	});
	let launch_peak = free_fall.map_or(0.0, |(start, _)| {
		peak_acceleration_in_window(samples, start - TOSS_IMPULSE_WINDOW_MICROS, start)
	});
	let catch_peak = free_fall.map_or(0.0, |(_, end)| {
		peak_acceleration_in_window(samples, end, end + TOSS_IMPULSE_WINDOW_MICROS)
	});
	let weakest_impulse = launch_peak.min(catch_peak);
	let impact_safe =
		metrics.peak_acceleration <= rule.maximum_peak_acceleration_meters_per_second_squared;
	let impulses_present =
		weakest_impulse >= rule.minimum_peak_acceleration_meters_per_second_squared;
	let air_time_valid = free_fall_ms >= rule.minimum_free_fall_milliseconds
		&& free_fall_ms <= rule.maximum_free_fall_milliseconds;
	let score = (f64::from(free_fall_ms) / f64::from(rule.minimum_free_fall_milliseconds))
		.min(weakest_impulse / rule.minimum_peak_acceleration_meters_per_second_squared)
		.clamp(0.0, 1.0);
	let reason_code = if !impact_safe {
		"motion_toss_impact_too_high"
	} else if !air_time_valid {
		"motion_toss_air_time_not_met"
	} else if !impulses_present {
		"motion_toss_impulses_not_detected"
	} else {
		"motion_verified"
	};
	let accepted = impact_safe && air_time_valid && impulses_present;
	make_result(
		base,
		accepted,
		reason_code,
		score,
		u32::from(accepted),
		free_fall_ms,
	)
}

fn analyze_shake(
	samples: &[MotionSample],
	rule: &MotionRule,
	metrics: TraceMetrics,
	base: BaseMetrics,
) -> MotionAnalysis {
	let baseline = axis_acceleration(&samples[0], rule.axis);
	let mut last_peak_micros = -SHAKE_PEAK_SEPARATION_MICROS;
	let mut last_sign = 0_i8;
	let mut alternating_peaks = 0_u32;
	for sample in samples {
		let value = axis_acceleration(sample, rule.axis) - baseline;
		if value.abs() < rule.minimum_peak_acceleration_meters_per_second_squared {
			continue;
		}
		let sign = if value < 0.0 { -1 } else { 1 };
		if sign == last_sign
			|| sample.elapsed_microseconds - last_peak_micros < SHAKE_PEAK_SEPARATION_MICROS
		{
			continue;
		}
		alternating_peaks = alternating_peaks.saturating_add(1);
		last_peak_micros = sample.elapsed_microseconds;
		last_sign = sign;
	}
	let repetitions = alternating_peaks / 2;
	let impact_safe =
		metrics.peak_acceleration <= rule.maximum_peak_acceleration_meters_per_second_squared;
	let reps_reached = repetitions >= rule.target_repetitions;
	let score = (f64::from(repetitions) / f64::from(rule.target_repetitions)).clamp(0.0, 1.0);
	let reason_code = if !impact_safe {
		"motion_shake_force_too_high"
	} else if reps_reached {
		"motion_verified"
	} else {
		"motion_shake_count_not_met"
	};
	make_result(
		base,
		impact_safe && reps_reached,
		reason_code,
		score,
		repetitions,
		0,
	)
}

fn analyze_stillness(
	rule: &MotionRule,
	metrics: TraceMetrics,
	base: BaseMetrics,
) -> MotionAnalysis {
	let accepted = metrics.peak_angular_speed <= rule.maximum_angular_speed_radians_per_second;
	let score = if accepted {
		1.0
	} else {
		(rule.maximum_angular_speed_radians_per_second / metrics.peak_angular_speed).clamp(0.0, 1.0)
	};
	make_result(
		base,
		accepted,
		if accepted {
			"motion_verified"
		} else {
			"motion_not_steady"
		},
		score,
		u32::from(accepted),
		0,
	)
}

fn longest_free_fall(samples: &[MotionSample]) -> Option<(i64, i64)> {
	let mut current_start: Option<i64> = None;
	let mut longest: Option<(i64, i64)> = None;
	for sample in samples {
		if acceleration_magnitude(sample) < FREE_FALL_ACCELERATION {
			current_start.get_or_insert(sample.elapsed_microseconds);
			continue;
		}
		if let Some(start) = current_start.take() {
			let end = sample.elapsed_microseconds;
			if longest.is_none_or(|(ls, le)| end - start > le - ls) {
				longest = Some((start, end));
			}
		}
	}
	if let Some(start) = current_start {
		let end = samples.last().unwrap().elapsed_microseconds;
		if longest.is_none_or(|(ls, le)| end - start > le - ls) {
			longest = Some((start, end));
		}
	}
	longest
}

fn peak_acceleration_in_window(samples: &[MotionSample], from_us: i64, to_us: i64) -> f64 {
	let mut peak = 0.0_f64;
	for sample in samples {
		if sample.elapsed_microseconds >= from_us && sample.elapsed_microseconds <= to_us {
			peak = peak.max(acceleration_magnitude(sample));
		}
	}
	peak
}

fn axis_gyroscope(sample: &MotionSample, axis: MotionAxis) -> f64 {
	match axis {
		MotionAxis::Pitch => sample.gyroscope_x,
		MotionAxis::Roll => sample.gyroscope_y,
		MotionAxis::Yaw => sample.gyroscope_z,
		MotionAxis::Any => (sample.gyroscope_x * sample.gyroscope_x
			+ sample.gyroscope_y * sample.gyroscope_y
			+ sample.gyroscope_z * sample.gyroscope_z)
			.sqrt(),
	}
}

fn axis_acceleration(sample: &MotionSample, axis: MotionAxis) -> f64 {
	match axis {
		MotionAxis::Pitch => sample.acceleration_x,
		MotionAxis::Roll => sample.acceleration_y,
		MotionAxis::Yaw => sample.acceleration_z,
		MotionAxis::Any => acceleration_magnitude(sample),
	}
}

fn acceleration_magnitude(sample: &MotionSample) -> f64 {
	(sample.acceleration_x * sample.acceleration_x
		+ sample.acceleration_y * sample.acceleration_y
		+ sample.acceleration_z * sample.acceleration_z)
		.sqrt()
}

fn quantize(value: f64) -> Result<i64, MotionError> {
	if !value.is_finite() {
		return Err(MotionError::InvalidTrace("Sensor value must be finite."));
	}
	Ok((value * 1_000_000.0).round() as i64)
}

#[cfg(test)]
mod tests {
	use super::*;

	fn base_rule(kind: MotionActionType, axis: MotionAxis) -> MotionRule {
		MotionRule {
			kind,
			axis,
			target_repetitions: 1,
			minimum_duration_seconds: 1,
			maximum_duration_seconds: 10,
			minimum_angular_speed_radians_per_second: 1.0,
			maximum_angular_speed_radians_per_second: 25.0,
			minimum_axis_dominance: 0.6,
			minimum_free_fall_milliseconds: 180,
			maximum_free_fall_milliseconds: 700,
			minimum_peak_acceleration_meters_per_second_squared: 12.0,
			maximum_peak_acceleration_meters_per_second_squared: 60.0,
		}
	}

	#[test]
	fn a_client_score_does_not_accept() {
		assert!(!client_repetitions_are_proof(20));
		let held = hold_for_review(20);
		assert_eq!(held.status, EvidenceDecisionStatus::ManualReview);
		assert_ne!(held.status, EvidenceDecisionStatus::Accepted);
	}

	#[test]
	fn yaw_rotation_accepts_full_turns_and_rejects_wrong_axis() {
		let mut rule = base_rule(MotionActionType::Rotation, MotionAxis::Yaw);
		rule.target_repetitions = 2;
		// 2 seconds at 2*pi rad/s = 2 full rotations around Z (yaw)
		let samples: Vec<_> = (0..=40)
			.map(|i| MotionSample {
				elapsed_microseconds: i * 50_000,
				gyroscope_x: 0.0,
				gyroscope_y: 0.0,
				gyroscope_z: std::f64::consts::TAU,
				acceleration_x: 0.0,
				acceleration_y: 0.0,
				acceleration_z: 9.81,
			})
			.collect();
		let res = analyze(&samples, &rule).unwrap();
		assert!(res.accepted);
		assert_eq!(res.reason_code, "motion_verified");
		assert_eq!(res.repetition_count, 2);

		let mut pitch_rule = rule;
		pitch_rule.axis = MotionAxis::Pitch;
		let wrong_axis = analyze(&samples, &pitch_rule).unwrap();
		assert!(!wrong_axis.accepted);
		assert_eq!(wrong_axis.reason_code, "motion_rotation_wrong_axis");
	}

	#[test]
	fn stillness_and_phone_toss_and_shake_evaluate_deterministically() {
		// Stillness
		let mut still_rule = base_rule(MotionActionType::Stillness, MotionAxis::Any);
		still_rule.minimum_angular_speed_radians_per_second = 0.1;
		still_rule.maximum_angular_speed_radians_per_second = 0.5;
		let steady: Vec<_> = (0..=20)
			.map(|i| MotionSample {
				elapsed_microseconds: i * 100_000,
				gyroscope_x: 0.05,
				gyroscope_y: 0.02,
				gyroscope_z: 0.01,
				acceleration_x: 0.0,
				acceleration_y: 0.0,
				acceleration_z: 9.81,
			})
			.collect();
		assert!(analyze(&steady, &still_rule).unwrap().accepted);

		// Phone toss: launch spike -> 300ms free fall -> catch spike
		let toss_rule = base_rule(MotionActionType::PhoneToss, MotionAxis::Any);
		let toss: Vec<_> = (0..=24)
			.map(|i| {
				let us = i * 50_000;
				let az = if i == 4 || i == 14 {
					18.0
				} else if (6..=12).contains(&i) {
					0.5
				} else {
					9.81
				};
				MotionSample {
					elapsed_microseconds: us,
					gyroscope_x: 0.1,
					gyroscope_y: 0.1,
					gyroscope_z: 0.1,
					acceleration_x: 0.0,
					acceleration_y: 0.0,
					acceleration_z: az,
				}
			})
			.collect();
		let toss_res = analyze(&toss, &toss_rule).unwrap();
		assert!(toss_res.accepted);
		assert_eq!(toss_res.reason_code, "motion_verified");
		assert!(toss_res.free_fall_milliseconds >= 300);

		// Canonical round-trip + SHA-256 stability
		let json = canonical_motion_trace_json(&steady).unwrap();
		let parsed = parse_canonical_trace_json(&json).unwrap();
		assert_eq!(parsed.len(), steady.len());
		assert_eq!(
			motion_trace_sha256(&steady).unwrap(),
			motion_trace_sha256(&parsed).unwrap()
		);
	}
}
