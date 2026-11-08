//! Location decisions. Distance is measured by the database, not the phone.

use std::time::Duration;

use chrono::DateTime;
use chrono::Utc;

use crate::pending_shared::DecisionStatus;

#[derive(Debug, Clone, Copy)]
pub struct LocationPolicy {
	pub maximum_age: Duration,
	pub future_tolerance: Duration,
	pub maximum_plausible_speed_meters_per_second: f64,
	pub minimum_travel_distance_meters: f64,
}

impl Default for LocationPolicy {
	fn default() -> Self {
		Self {
			maximum_age: Duration::from_secs(5 * 60),
			future_tolerance: Duration::from_secs(60),
			maximum_plausible_speed_meters_per_second: 300.0,
			minimum_travel_distance_meters: 50_000.0,
		}
	}
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LocationRisk {
	None,
	Stale,
	FromFuture,
	ImplausibleTravel,
}

#[derive(Debug, Clone, Copy)]
pub struct Observation {
	pub accuracy_meters: f64,
	pub captured_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Copy)]
pub struct PreviousObservation {
	pub distance_meters: f64,
	pub accuracy_meters: f64,
	pub captured_at: DateTime<Utc>,
}

impl LocationPolicy {
	pub fn evaluate(
		self,
		now: DateTime<Utc>,
		current: Observation,
		previous: Option<PreviousObservation>,
	) -> LocationRisk {
		if current.captured_at < now - self.maximum_age {
			return LocationRisk::Stale;
		}
		if current.captured_at > now + self.future_tolerance {
			return LocationRisk::FromFuture;
		}
		let Some(previous) = previous else {
			return LocationRisk::None;
		};
		if current.captured_at < previous.captured_at {
			return LocationRisk::None;
		}
		let elapsed = current
			.captured_at
			.signed_duration_since(previous.captured_at);
		let elapsed_seconds = elapsed.num_milliseconds() as f64 / 1000.0;
		let effective =
			(previous.distance_meters - previous.accuracy_meters - current.accuracy_meters)
				.max(0.0);
		if effective < self.minimum_travel_distance_meters {
			return LocationRisk::None;
		}
		if elapsed_seconds <= 0.0 {
			return LocationRisk::ImplausibleTravel;
		}
		if effective / elapsed_seconds > self.maximum_plausible_speed_meters_per_second {
			LocationRisk::ImplausibleTravel
		} else {
			LocationRisk::None
		}
	}
}

#[derive(Debug, Clone, PartialEq)]
pub struct LocationDecision {
	pub status: DecisionStatus,
	pub verifier_type: &'static str,
	pub reason_code: &'static str,
	pub summary: &'static str,
}

/// `distance_meters` and `previous` come from PostGIS. Coordinates are not returned.
pub fn decide(
	policy: LocationPolicy,
	now: DateTime<Utc>,
	current: Observation,
	max_accuracy_meters: f64,
	distance_meters: f64,
	radius_meters: f64,
	previous: Option<PreviousObservation>,
) -> Result<LocationDecision, ()> {
	if !current.accuracy_meters.is_finite()
		|| current.accuracy_meters < 0.0
		|| !distance_meters.is_finite()
		|| !radius_meters.is_finite()
		|| radius_meters <= 0.0
	{
		return Err(());
	}
	let freshness = policy.evaluate(now, current, None);
	if freshness == LocationRisk::Stale {
		return Ok(decision(
			DecisionStatus::Rejected,
			"location-risk",
			"location_capture_stale",
			"Take a new location check and try again.",
		));
	}
	if freshness == LocationRisk::FromFuture {
		return Ok(decision(
			DecisionStatus::Rejected,
			"location-risk",
			"location_capture_time_invalid",
			"Check the phone clock, then take a new location check.",
		));
	}
	if current.accuracy_meters > max_accuracy_meters {
		return Ok(decision(
			DecisionStatus::Rejected,
			"geofence",
			"location_accuracy_too_low",
			"The location was not precise enough.",
		));
	}
	let inside = distance_meters <= radius_meters;
	if inside && policy.evaluate(now, current, previous) == LocationRisk::ImplausibleTravel {
		return Ok(decision(
			DecisionStatus::ManualReview,
			"location-risk",
			"location_travel_needs_review",
			"A person will check this proof.",
		));
	}
	Ok(if inside {
		decision(
			DecisionStatus::Accepted,
			"geofence",
			"inside_geofence",
			"Location check accepted.",
		)
	} else {
		decision(
			DecisionStatus::Rejected,
			"geofence",
			"outside_geofence",
			"The check-in was outside the place.",
		)
	})
}

fn decision(
	status: DecisionStatus,
	verifier_type: &'static str,
	reason_code: &'static str,
	summary: &'static str,
) -> LocationDecision {
	LocationDecision {
		status,
		verifier_type,
		reason_code,
		summary,
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn the_database_distance_decides_the_geofence() {
		let now = DateTime::from_timestamp(1_700_000_100, 0).unwrap();
		let current = Observation {
			accuracy_meters: 8.0,
			captured_at: now,
		};
		let inside = decide(
			LocationPolicy::default(),
			now,
			current,
			50.0,
			10.0,
			100.0,
			None,
		)
		.unwrap();
		assert_eq!(inside.reason_code, "inside_geofence");
		let outside = decide(
			LocationPolicy::default(),
			now,
			current,
			50.0,
			101.0,
			100.0,
			None,
		)
		.unwrap();
		assert_eq!(outside.reason_code, "outside_geofence");
	}
}
