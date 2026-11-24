//! Projects MediaPipe normalized pose landmarks & ball detections into viewport
//! coordinates via `mediapipe::OverlayTransform` (`PreviewFit::Cover`).

use mediapipe::NormalizedLandmark;
use mediapipe::OverlayTransform;
use mediapipe::Point;
use mediapipe::PreviewFit;
use mediapipe::Size;
use mediapipe::tasks::PoseJoint;

use super::ball_tracking::BallObservation;

/// One bone segment in viewport coordinates.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct OverlayLine {
	pub from: Point,
	pub to: Point,
}

/// One joint or ball circle in viewport coordinates.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct OverlayCircle {
	pub center: Point,
	pub radius: f64,
}

/// Projected body skeleton and optional ball circle ready to paint over a preview.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct PoseSkeletonOverlay {
	pub bones: Vec<OverlayLine>,
	pub joints: Vec<OverlayCircle>,
	pub ball: Option<OverlayCircle>,
}

/// Anatomical bone pairs painted in the movement HUD.
pub const POSE_BONES: &[(PoseJoint, PoseJoint)] = &[
	(PoseJoint::LeftShoulder, PoseJoint::RightShoulder),
	(PoseJoint::LeftShoulder, PoseJoint::LeftElbow),
	(PoseJoint::LeftElbow, PoseJoint::LeftWrist),
	(PoseJoint::RightShoulder, PoseJoint::RightElbow),
	(PoseJoint::RightElbow, PoseJoint::RightWrist),
	(PoseJoint::LeftShoulder, PoseJoint::LeftHip),
	(PoseJoint::RightShoulder, PoseJoint::RightHip),
	(PoseJoint::LeftHip, PoseJoint::RightHip),
	(PoseJoint::LeftHip, PoseJoint::LeftKnee),
	(PoseJoint::LeftKnee, PoseJoint::LeftAnkle),
	(PoseJoint::RightHip, PoseJoint::RightKnee),
	(PoseJoint::RightKnee, PoseJoint::RightAnkle),
];

/// Projects `pose` landmarks and an optional `ball` into a `view_size` canvas
/// matching the native camera preview (`PreviewFit::Cover`).
#[must_use]
pub fn project_pose_overlay(
	pose: &[NormalizedLandmark],
	ball: Option<BallObservation>,
	image_size: Size,
	view_size: Size,
	mirrored: bool,
) -> PoseSkeletonOverlay {
	let Ok(transform) =
		OverlayTransform::new(image_size, 0, view_size, mirrored, PreviewFit::Cover)
	else {
		return PoseSkeletonOverlay::default();
	};
	let mut overlay = PoseSkeletonOverlay::default();
	let min_vis = 0.5_f32;

	if pose.len() >= PoseJoint::COUNT {
		for &(a, b) in POSE_BONES {
			let la = pose[a.index()];
			let lb = pose[b.index()];
			if la.visibility.unwrap_or(0.0) >= min_vis && lb.visibility.unwrap_or(0.0) >= min_vis {
				overlay.bones.push(OverlayLine {
					from: transform.map_landmark(la),
					to: transform.map_landmark(lb),
				});
			}
		}
		for joint in [
			PoseJoint::Nose,
			PoseJoint::LeftShoulder,
			PoseJoint::RightShoulder,
			PoseJoint::LeftElbow,
			PoseJoint::RightElbow,
			PoseJoint::LeftWrist,
			PoseJoint::RightWrist,
			PoseJoint::LeftHip,
			PoseJoint::RightHip,
			PoseJoint::LeftKnee,
			PoseJoint::RightKnee,
			PoseJoint::LeftAnkle,
			PoseJoint::RightAnkle,
		] {
			let lm = pose[joint.index()];
			if lm.visibility.unwrap_or(0.0) >= min_vis {
				overlay.joints.push(OverlayCircle {
					center: transform.map_landmark(lm),
					radius: 5.0,
				});
			}
		}
	}

	if let Some(ball) = ball {
		let center = transform.map_normalized(ball.x, ball.y);
		overlay.ball = Some(OverlayCircle {
			center,
			radius: (ball.radius * view_size.height).max(8.0),
		});
	}

	overlay
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn overlay_projects_bones_and_ball_using_mediapipe_transform() {
		let pose = vec![
			NormalizedLandmark::new(0.5, 0.5, 0.0)
				.with_confidence(Some(0.95), Some(0.95));
			PoseJoint::COUNT
		];
		let overlay = project_pose_overlay(
			&pose,
			Some(BallObservation {
				x: 0.25,
				y: 0.75,
				radius: 0.05,
				score: 0.9,
			}),
			Size::new(720.0, 1280.0),
			Size::new(360.0, 640.0),
			false,
		);
		assert_eq!(overlay.bones.len(), POSE_BONES.len());
		assert!(overlay.ball.is_some());
		let ball = overlay.ball.unwrap();
		assert!((ball.center.x - 90.0).abs() < 1e-6);
		assert!((ball.center.y - 480.0).abs() < 1e-6);
	}
}
