//! On-device MediaPipe movement tracking, ball-touch tracking, advisory
//! local-check tallies, and `OverlayTransform` skeleton projection.
//!
//! Counts and tallies produced here are live coaching only: the server
//! independently verifies uploaded recordings and never trusts client counts.

pub mod ball_tracking;
pub mod exercise_tracking;
pub mod local_check_tally;
pub mod overlay;

pub use ball_tracking::BALL_MODEL_VERSION;
pub use ball_tracking::BallObservation;
pub use ball_tracking::BallTouch;
pub use ball_tracking::BallTouchTracker;
pub use ball_tracking::MovementLimb;
pub use exercise_tracking::BurpeeStage;
pub use exercise_tracking::BurpeeTracker;
pub use exercise_tracking::MovementCue;
pub use exercise_tracking::MovementObservation;
pub use exercise_tracking::MovementProgress;
pub use exercise_tracking::MovementTracker;
pub use exercise_tracking::POSE_MODEL_VERSION;
pub use exercise_tracking::RepetitionCounter;
pub use exercise_tracking::RepetitionTracker;
pub use exercise_tracking::is_ball_skill;
pub use exercise_tracking::movement_depth;
pub use exercise_tracking::movement_tracker_for;
pub use local_check_tally::LOCAL_CHECK_PHOTO_HOLD_FRAMES;
pub use local_check_tally::LocalCheckFrame;
pub use local_check_tally::LocalCheckGuidance;
pub use local_check_tally::LocalCheckTally;
pub use overlay::OverlayCircle;
pub use overlay::OverlayLine;
pub use overlay::PoseSkeletonOverlay;
pub use overlay::project_pose_overlay;
