//! MediaPipe local-check catalog and server-side replay.
//!
//! Shares the exact SHA-256-pinned model definitions from `leptoskit/mediapipe`
//! (`mediapipe::models`) and replays gesture, object, and sound checks via
//! `mediapipe::native` + `ffmpeg` when the native runtime is installed, failing
//! cleanly to `Unavailable` (AI/manual fallback) when it is not.

use std::path::Path;
use std::process::Command;

use mediapipe::models::{
	ModelCache, ModelPin, efficientdet_lite0_pin, gesture_recognizer_pin, yamnet_pin,
};
use mediapipe::native::NativeRuntime;
use mediapipe::{
	AudioBuffer, AudioClassifierOptions, ClassifierOptions, GestureRecognizerOptions, MpImage,
	ObjectDetectorOptions, RunningMode,
};
use verily_shared::{ActionLocalCheck, LocalCheckModelView, LocalCheckTask};

pub const MIN_SCORE: f64 = 0.3;
pub const MAX_SCORE: f64 = 0.99;
pub const MIN_FRAMES: i64 = 1;
pub const MAX_FRAMES: i64 = 30;

pub const GESTURE_LABELS: &[&str] = &[
	"Closed_Fist",
	"Open_Palm",
	"Pointing_Up",
	"Thumb_Down",
	"Thumb_Up",
	"Victory",
	"ILoveYou",
];

pub const OBJECT_LABELS: &[&str] = &[
	"person",
	"bicycle",
	"car",
	"motorcycle",
	"airplane",
	"bus",
	"train",
	"truck",
	"boat",
	"traffic light",
	"fire hydrant",
	"stop sign",
	"parking meter",
	"bench",
	"bird",
	"cat",
	"dog",
	"horse",
	"sheep",
	"cow",
	"elephant",
	"bear",
	"zebra",
	"giraffe",
	"backpack",
	"umbrella",
	"handbag",
	"tie",
	"suitcase",
	"frisbee",
	"skis",
	"snowboard",
	"sports ball",
	"kite",
	"baseball bat",
	"baseball glove",
	"skateboard",
	"surfboard",
	"tennis racket",
	"bottle",
	"wine glass",
	"cup",
	"fork",
	"knife",
	"spoon",
	"bowl",
	"banana",
	"apple",
	"sandwich",
	"orange",
	"broccoli",
	"carrot",
	"hot dog",
	"pizza",
	"donut",
	"cake",
	"chair",
	"couch",
	"potted plant",
	"bed",
	"dining table",
	"toilet",
	"tv",
	"laptop",
	"mouse",
	"remote",
	"keyboard",
	"cell phone",
	"microwave",
	"oven",
	"toaster",
	"sink",
	"refrigerator",
	"book",
	"clock",
	"vase",
	"scissors",
	"teddy bear",
	"hair drier",
	"toothbrush",
];

pub const SOUND_LABELS: &[&str] = &[
	"Clapping",
	"Finger snapping",
	"Whistling",
	"Applause",
	"Laughter",
	"Cough",
	"Sneeze",
	"Bell",
	"Doorbell",
	"Knock",
	"Dog",
	"Bark",
	"Cat",
	"Meow",
	"Bird",
	"Chirp, tweet",
	"Crowing, cock-a-doodle-doo",
	"Siren",
	"Alarm clock",
	"Typing",
	"Water tap, faucet",
	"Guitar",
	"Piano",
	"Drum",
	"Whistle",
];

/// Pinned MediaPipe model metadata for a [`LocalCheckTask`].
#[must_use]
pub fn model_pin_for(task: LocalCheckTask) -> ModelPin {
	match task {
		LocalCheckTask::Gesture => gesture_recognizer_pin(),
		LocalCheckTask::Object => efficientdet_lite0_pin(),
		LocalCheckTask::Sound => yamnet_pin(),
	}
}

/// Allowed category labels for a [`LocalCheckTask`].
#[must_use]
pub const fn allowed_labels_for(task: LocalCheckTask) -> &'static [&'static str] {
	match task {
		LocalCheckTask::Gesture => GESTURE_LABELS,
		LocalCheckTask::Object => OBJECT_LABELS,
		LocalCheckTask::Sound => SOUND_LABELS,
	}
}

/// Server-published model descriptor sent to phones for on-device guidance.
#[must_use]
pub fn model_view_for(task: LocalCheckTask) -> LocalCheckModelView {
	let pin = model_pin_for(task);
	LocalCheckModelView {
		model_id: pin.id,
		url: pin.url,
		sha256: pin.sha256,
		byte_length: pin.byte_length as i64,
	}
}

/// Validate a creator-configured local check against bounds and allowlisted labels.
pub fn validate_local_check(check: &ActionLocalCheck) -> Result<(), &'static str> {
	if !allowed_labels_for(check.task).contains(&check.label.as_str()) {
		return Err("local_check_label_not_allowed");
	}
	if !check.min_score.is_finite() || check.min_score < MIN_SCORE || check.min_score > MAX_SCORE {
		return Err("local_check_score_out_of_bounds");
	}
	if check.min_frames < MIN_FRAMES || check.min_frames > MAX_FRAMES {
		return Err("local_check_frames_out_of_bounds");
	}
	Ok(())
}

/// Outcome of server-side MediaPipe replay on immutable evidence bytes.
#[derive(Debug, Clone, PartialEq)]
pub enum LocalCheckReplayOutcome {
	Matched {
		matched_frames: i32,
		best_score: f32,
		reason_code: &'static str,
	},
	NotMatched {
		matched_frames: i32,
		best_score: f32,
		reason_code: &'static str,
	},
	Unavailable {
		reason_code: &'static str,
	},
}

/// Server-side MediaPipe replayer using `leptoskit/mediapipe` native C runtime + `ffmpeg`.
#[derive(Debug, Clone)]
pub struct MediaPipeLocalCheckReplayer {
	cache: ModelCache,
	runtime: Option<NativeRuntime>,
}

impl MediaPipeLocalCheckReplayer {
	/// Build a replayer backed by `model_dir`, probing `libmediapipe`.
	#[must_use]
	pub fn new(model_dir: impl Into<std::path::PathBuf>) -> Self {
		Self {
			cache: ModelCache::new(model_dir),
			runtime: NativeRuntime::load_default().ok(),
		}
	}

	/// Whether `libmediapipe` is loaded on this host.
	#[must_use]
	pub fn is_runtime_available(&self) -> bool {
		self.runtime.is_some()
	}

	/// Replay `check` against a local evidence file path.
	///
	/// Always fails honestly to [`LocalCheckReplayOutcome::Unavailable`] when
	/// `libmediapipe`, the verified model file, or `ffmpeg` is absent.
	#[must_use]
	pub fn replay_file(
		&self,
		check: &ActionLocalCheck,
		media_path: &Path,
	) -> LocalCheckReplayOutcome {
		if validate_local_check(check).is_err() {
			return LocalCheckReplayOutcome::NotMatched {
				matched_frames: 0,
				best_score: 0.0,
				reason_code: "local_check_invalid_rule",
			};
		}
		let Some(runtime) = &self.runtime else {
			return LocalCheckReplayOutcome::Unavailable {
				reason_code: "mp_replay_unavailable",
			};
		};
		let pin = model_pin_for(check.task);
		let Ok((model_path, _)) = self.cache.load_verified(&pin) else {
			return LocalCheckReplayOutcome::Unavailable {
				reason_code: "mp_replay_model_unavailable",
			};
		};
		match check.task {
			LocalCheckTask::Sound => replay_audio(runtime, &model_path, check, media_path),
			LocalCheckTask::Gesture => replay_gesture(runtime, &model_path, check, media_path),
			LocalCheckTask::Object => replay_object(runtime, &model_path, check, media_path),
		}
	}
}

fn replay_audio(
	runtime: &NativeRuntime,
	model_path: &Path,
	check: &ActionLocalCheck,
	media_path: &Path,
) -> LocalCheckReplayOutcome {
	let Some(pcm) = decode_audio_pcm_16k(media_path) else {
		return LocalCheckReplayOutcome::Unavailable {
			reason_code: "mp_replay_decode_unavailable",
		};
	};
	let opts = AudioClassifierOptions {
		classifier: ClassifierOptions {
			max_results: 5,
			score_threshold: check.min_score as f32,
			category_allowlist: vec![check.label.clone()],
			category_denylist: Vec::new(),
		},
	};
	let Ok(mut classifier) = runtime.create_audio_classifier(model_path, &opts) else {
		return LocalCheckReplayOutcome::Unavailable {
			reason_code: "mp_replay_unavailable",
		};
	};
	let buf = AudioBuffer {
		sample_rate_hz: 16_000.0,
		channels: 1,
		samples: pcm,
	};
	let Ok(result) = classifier.classify(&buf) else {
		return LocalCheckReplayOutcome::Unavailable {
			reason_code: "mp_replay_unavailable",
		};
	};
	let mut matched = 0_i32;
	let mut best = 0.0_f32;
	for chunk in result.results {
		let chunk_best = chunk
			.heads
			.into_iter()
			.flat_map(|h| h.categories)
			.filter(|c| c.category_name.as_deref() == Some(check.label.as_str()))
			.map(|c| c.score)
			.fold(0.0_f32, f32::max);
		best = best.max(chunk_best);
		if f64::from(chunk_best) >= check.min_score {
			matched += 1;
		}
	}
	outcome(matched, best, check.min_frames)
}

fn replay_gesture(
	runtime: &NativeRuntime,
	model_path: &Path,
	check: &ActionLocalCheck,
	media_path: &Path,
) -> LocalCheckReplayOutcome {
	let Some(frames) = decode_rgb_frames(media_path, MAX_FRAMES as usize) else {
		return LocalCheckReplayOutcome::Unavailable {
			reason_code: "mp_replay_decode_unavailable",
		};
	};
	let opts = GestureRecognizerOptions {
		running_mode: RunningMode::Image,
		num_hands: 2,
		canned_gestures: ClassifierOptions {
			max_results: 3,
			score_threshold: check.min_score as f32,
			category_allowlist: vec![check.label.clone()],
			category_denylist: Vec::new(),
		},
		..GestureRecognizerOptions::default()
	};
	let Ok(mut recognizer) = runtime.create_gesture_recognizer(model_path, &opts) else {
		return LocalCheckReplayOutcome::Unavailable {
			reason_code: "mp_replay_unavailable",
		};
	};
	let mut matched = 0_i32;
	let mut best = 0.0_f32;
	for frame in &frames {
		let Ok(res) = recognizer.recognize_image(frame, 0) else {
			continue;
		};
		let frame_best = res
			.gestures
			.into_iter()
			.flatten()
			.filter(|c| c.category_name.as_deref() == Some(check.label.as_str()))
			.map(|c| c.score)
			.fold(0.0_f32, f32::max);
		best = best.max(frame_best);
		if f64::from(frame_best) >= check.min_score {
			matched += 1;
		}
	}
	outcome(matched, best, check.min_frames)
}

fn replay_object(
	runtime: &NativeRuntime,
	model_path: &Path,
	check: &ActionLocalCheck,
	media_path: &Path,
) -> LocalCheckReplayOutcome {
	let Some(frames) = decode_rgb_frames(media_path, MAX_FRAMES as usize) else {
		return LocalCheckReplayOutcome::Unavailable {
			reason_code: "mp_replay_decode_unavailable",
		};
	};
	let opts = ObjectDetectorOptions {
		running_mode: RunningMode::Image,
		classifier: ClassifierOptions {
			max_results: 5,
			score_threshold: check.min_score as f32,
			category_allowlist: vec![check.label.clone()],
			category_denylist: Vec::new(),
		},
	};
	let Ok(mut detector) = runtime.create_object_detector(model_path, &opts) else {
		return LocalCheckReplayOutcome::Unavailable {
			reason_code: "mp_replay_unavailable",
		};
	};
	let mut matched = 0_i32;
	let mut best = 0.0_f32;
	for frame in &frames {
		let Ok(res) = detector.detect_image(frame, 0) else {
			continue;
		};
		let frame_best = res
			.detections
			.into_iter()
			.flat_map(|d| d.categories)
			.filter(|c| c.category_name.as_deref() == Some(check.label.as_str()))
			.map(|c| c.score)
			.fold(0.0_f32, f32::max);
		best = best.max(frame_best);
		if f64::from(frame_best) >= check.min_score {
			matched += 1;
		}
	}
	outcome(matched, best, check.min_frames)
}

fn outcome(matched_frames: i32, best_score: f32, min_frames: i64) -> LocalCheckReplayOutcome {
	if i64::from(matched_frames) >= min_frames {
		LocalCheckReplayOutcome::Matched {
			matched_frames,
			best_score,
			reason_code: "local_check_matched",
		}
	} else {
		LocalCheckReplayOutcome::NotMatched {
			matched_frames,
			best_score,
			reason_code: "local_check_not_matched",
		}
	}
}

fn decode_audio_pcm_16k(path: &Path) -> Option<Vec<f32>> {
	let output = Command::new("ffmpeg")
		.args(["-v", "error", "-i"])
		.arg(path)
		.args(["-ac", "1", "-ar", "16000", "-f", "f32le", "-"])
		.output()
		.ok()?;
	if !output.status.success() || output.stdout.len() < 4 {
		return None;
	}
	let (chunks, _) = output.stdout.as_chunks::<4>();
	Some(chunks.iter().map(|b| f32::from_le_bytes(*b)).collect())
}

fn decode_rgb_frames(path: &Path, max_frames: usize) -> Option<Vec<MpImage>> {
	const W: u32 = 320;
	const H: u32 = 240;
	let output = Command::new("ffmpeg")
		.args(["-v", "error", "-i"])
		.arg(path)
		.args([
			"-vf",
			&format!("fps=2,scale={W}:{H}"),
			"-frames:v",
			&max_frames.to_string(),
			"-pix_fmt",
			"rgb24",
			"-f",
			"rawvideo",
			"-",
		])
		.output()
		.ok()?;
	if !output.status.success() {
		return None;
	}
	let frame_bytes = (W as usize) * (H as usize) * 3;
	if output.stdout.len() < frame_bytes {
		return None;
	}
	let mut frames = Vec::new();
	for chunk in output.stdout.chunks_exact(frame_bytes) {
		if let Ok(img) = MpImage::from_srgb(W, H, chunk.to_vec()) {
			frames.push(img);
		}
	}
	(!frames.is_empty()).then_some(frames)
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn catalog_pins_and_label_counts_match_verily_evidence() {
		assert_eq!(GESTURE_LABELS.len(), 7);
		assert_eq!(OBJECT_LABELS.len(), 80);
		assert_eq!(SOUND_LABELS.len(), 25);
		for task in [
			LocalCheckTask::Gesture,
			LocalCheckTask::Object,
			LocalCheckTask::Sound,
		] {
			model_pin_for(task).validate().expect("valid pin");
		}
	}

	#[test]
	fn validation_rejects_unlisted_labels_and_out_of_range_bounds() {
		let ok = ActionLocalCheck {
			task: LocalCheckTask::Object,
			label: "sports ball".to_owned(),
			min_score: 0.5,
			min_frames: 3,
		};
		assert!(validate_local_check(&ok).is_ok());

		let bad_label = ActionLocalCheck {
			label: "unicorn".to_owned(),
			..ok.clone()
		};
		assert_eq!(
			validate_local_check(&bad_label),
			Err("local_check_label_not_allowed")
		);

		let bad_score = ActionLocalCheck {
			min_score: 0.1,
			..ok.clone()
		};
		assert_eq!(
			validate_local_check(&bad_score),
			Err("local_check_score_out_of_bounds")
		);
	}

	#[test]
	fn replayer_fails_honestly_when_native_library_absent() {
		let replayer = MediaPipeLocalCheckReplayer::new("/tmp/verily-nonexistent-models");
		let check = ActionLocalCheck {
			task: LocalCheckTask::Gesture,
			label: "Thumb_Up".to_owned(),
			min_score: 0.6,
			min_frames: 1,
		};
		if !replayer.is_runtime_available() {
			assert_eq!(
				replayer.replay_file(&check, Path::new("/tmp/none.jpg")),
				LocalCheckReplayOutcome::Unavailable {
					reason_code: "mp_replay_unavailable",
				}
			);
		}
	}
}
