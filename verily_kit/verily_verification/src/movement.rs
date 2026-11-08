//! Movement prompts are written by the server from the kind and the count.

use crate::model_input;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MovementKind {
	Squats,
	PressUps,
	SitUps,
	Lunges,
	StarJumps,
	Burpees,
	HighKnees,
	LateralRaises,
	BicepsCurls,
	SideBends,
	FootballKickUps,
	TableTennisBounces,
}

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum MovementError {
	#[error("the movement target cannot be published")]
	Invalid,
	#[error("the generated prompt was refused")]
	Unsafe,
}

struct Movement {
	singular: &'static str,
	plural: &'static str,
	definition: &'static str,
	minimum_milliseconds: u32,
	consecutive: bool,
}

pub fn verification_prompt(
	kind: MovementKind,
	target_repetitions: u32,
) -> Result<String, MovementError> {
	let movement = movement(kind);
	let sequence = if movement.consecutive {
		format!(
			" The {target_repetitions} {} must be consecutive, without the ball being caught or landing in between.",
			movement.plural
		)
	} else {
		String::new()
	};
	let ball = if movement.consecutive {
		" and the ball"
	} else {
		""
	};
	let prompt = format!(
		"Movement challenge: {target_repetitions} complete {}. One complete {} is {} The video must show one person performing at least {target_repetitions} complete {} in a single continuous recording, with the body parts{ball} needed to judge each one visible.{sequence} Count only clearly complete repetitions. Partial, obstructed, sped-up, edited, or looped footage does not count.",
		movement.plural, movement.singular, movement.definition, movement.plural
	);
	model_input::validate_verification_policy(&prompt).map_err(|_| MovementError::Unsafe)
}

pub fn validate_target(
	kind: MovementKind,
	target_repetitions: Option<u32>,
	max_duration_seconds: u32,
) -> Result<(), MovementError> {
	let Some(target) = target_repetitions.filter(|target| (1..=1000).contains(target)) else {
		return Err(MovementError::Invalid);
	};
	let minimum_seconds = target
		.saturating_mul(movement(kind).minimum_milliseconds)
		.div_ceil(1000);
	if minimum_seconds > max_duration_seconds {
		Err(MovementError::Invalid)
	} else {
		Ok(())
	}
}

fn movement(kind: MovementKind) -> Movement {
	match kind {
		MovementKind::Squats => Movement {
			singular: "squat",
			plural: "squats",
			definition: "standing tall, bending both knees until the hips lower to about knee height, then returning to standing with the knees straight.",
			minimum_milliseconds: 1000,
			consecutive: false,
		},
		MovementKind::PressUps => Movement {
			singular: "press-up",
			plural: "press-ups",
			definition: "from a straight-body plank with hands on the floor, bending both elbows to lower the chest toward the floor, then pressing back up until the arms are straight.",
			minimum_milliseconds: 1000,
			consecutive: false,
		},
		MovementKind::SitUps => Movement {
			singular: "sit-up",
			plural: "sit-ups",
			definition: "lying on the back with knees bent, lifting the torso from the floor toward the knees, then lowering the shoulders back to the floor.",
			minimum_milliseconds: 1200,
			consecutive: false,
		},
		MovementKind::Lunges => Movement {
			singular: "lunge",
			plural: "lunges",
			definition: "from a split stance, bending both knees until the back knee nears the floor, then rising until the front knee is straight.",
			minimum_milliseconds: 1200,
			consecutive: false,
		},
		MovementKind::StarJumps => Movement {
			singular: "star jump",
			plural: "star jumps",
			definition: "jumping from feet together with arms down to feet wide apart with both arms raised overhead, then jumping back to the start.",
			minimum_milliseconds: 700,
			consecutive: false,
		},
		MovementKind::Burpees => Movement {
			singular: "burpee",
			plural: "burpees",
			definition: "from standing, crouching with hands on the floor, kicking the feet back into a plank, returning the feet to a crouch, then jumping up and landing standing.",
			minimum_milliseconds: 2500,
			consecutive: false,
		},
		MovementKind::HighKnees => Movement {
			singular: "high knee",
			plural: "high knees",
			definition: "standing upright and lifting one knee to at least hip height, then lowering it; each knee raise counts once.",
			minimum_milliseconds: 400,
			consecutive: false,
		},
		MovementKind::LateralRaises => Movement {
			singular: "lateral raise",
			plural: "lateral raises",
			definition: "from arms at the sides, raising both straight arms sideways to about shoulder height, then lowering them back to the sides.",
			minimum_milliseconds: 1200,
			consecutive: false,
		},
		MovementKind::BicepsCurls => Movement {
			singular: "biceps curl",
			plural: "biceps curls",
			definition: "with the upper arms still and close to the body, bending both elbows to bring the hands toward the shoulders, then lowering them until the arms are straight.",
			minimum_milliseconds: 1200,
			consecutive: false,
		},
		MovementKind::SideBends => Movement {
			singular: "side bend",
			plural: "side bends",
			definition: "standing with the hips still, leaning the torso clearly to one side, then returning upright.",
			minimum_milliseconds: 1200,
			consecutive: false,
		},
		MovementKind::FootballKickUps => Movement {
			singular: "kick-up",
			plural: "kick-ups",
			definition: "one touch that sends a football back up using a foot, knee, thigh, chest, or head, never the hands or arms.",
			minimum_milliseconds: 350,
			consecutive: true,
		},
		MovementKind::TableTennisBounces => Movement {
			singular: "bat bounce",
			plural: "bat bounces",
			definition: "one hit that sends a table tennis ball back up off a table tennis bat held in one hand, without the ball touching anything else.",
			minimum_milliseconds: 250,
			consecutive: true,
		},
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn the_prompt_comes_from_the_kind_and_passes_the_model_boundary() {
		let prompt = verification_prompt(MovementKind::Squats, 5).unwrap();
		assert!(prompt.contains("5 complete squats"));
		assert!(validate_target(MovementKind::Burpees, Some(1000), 10).is_err());
	}
}
