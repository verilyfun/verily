//! What may open after `beginCapture`, and what may not.
//!
//! The server window is already open before [`run`] records a step. A photo
//! asks for a key challenge, then the camera. Video, audio, and a venue code
//! stop: this pin has no microphone, barcode, or video-recording plugin, and a
//! missing plugin is not a photo library or a file picker. An attestation
//! answer of unavailable, and an opaque token that is not a certificate
//! chain, both refuse the proof. Neither one is a successful attestation.

use verily_shared::EvidenceError;
use verily_shared::capture_integrity_request_nonce;
use verily_shared::capture_key_attestation_challenge;
use verily_shared::sha256_hex;

use crate::model::CaptureWindow;
use crate::model::ProofKind;

/// Real LeptosKit runtime name for a live still.
pub const CAMERA: &str = "camera";
/// Real LeptosKit runtime name. This revision returns unavailable.
pub const APP_INTEGRITY: &str = "app-integrity";
/// Camera permission. A grant is not a capture.
pub const PERMISSIONS: &str = "permissions";

/// Not a live capture. The host must not call it for proof.
pub const IMAGE_PICKER: &str = "image-picker";
/// Not a live capture. The host must not call it for proof.
pub const DOCUMENT_PICKER: &str = "document-picker";

/// Which sensor a proof kind may use.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Sensor {
	/// `leptoskit_plugin_camera`, after the key challenge.
	Camera,
	/// No live plugin for this kind on the pinned LeptosKit.
	Missing,
	/// A note or an app confirmation. Not a capture.
	NotLive,
}

/// What the pinned plugins can honestly say.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DeviceAnswer {
	/// The plugin is missing or returned unavailable. Not a token.
	Unavailable,
	/// Opaque bytes. Not a certificate chain, and not a verified boot.
	///
	/// Only the native guest constructs this, when app integrity returns a
	/// token. That token is still not a chain.
	#[cfg_attr(not(all(feature = "native", target_arch = "wasm32")), allow(dead_code))]
	Opaque,
}

/// Why this capture does not become proof.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Fault {
	/// `beginCapture` has not returned. No sensor opens.
	WindowClosed,
	/// This kind is not captured on the phone.
	NotLiveCapture,
	/// The live plugin is not in this LeptosKit pin.
	PluginMissing,
	/// The camera named a cache file and did not return the bytes.
	BytesWithheld,
	/// A path or a library URI was offered instead of captured bytes.
	Library,
	/// Attestation did not run. Not recorded as device-signed.
	Unavailable,
	/// A token arrived without a chain the server can trust.
	Unverified,
}

/// One host call, in the only legal order.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Step {
	/// `SHA-256(captureChallenge ‖ attemptId)` to app integrity, before a sensor.
	KeyChallenge,
	/// Camera permission. Not the shutter.
	CameraPermission,
	/// One still from the camera plugin.
	CameraStill,
	/// Play Integrity nonce over the evidence binding, only once bytes exist.
	DigestChallenge,
}

/// The steps that ran, and why the proof was refused.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Run {
	/// Host calls in order. Empty when the window is still closed.
	pub steps: Vec<Step>,
	/// Always set. This pin has no path that admits a proof.
	pub fault: Fault,
}

/// The sensor for `kind`. A gallery is not a sensor.
#[must_use]
pub const fn sensor(kind: ProofKind) -> Sensor {
	match kind {
		ProofKind::Photo => Sensor::Camera,
		ProofKind::Video | ProofKind::Audio | ProofKind::VenueCode => Sensor::Missing,
		ProofKind::Presence | ProofKind::Movement => Sensor::Missing,
		ProofKind::Note | ProofKind::App => Sensor::NotLive,
	}
}

/// Plugins the capture screen may call. A picker is not among them.
#[must_use]
pub fn plugin_allowed(name: &str) -> bool {
	name == CAMERA || name == APP_INTEGRITY || name == PERMISSIONS
}

/// Android key-attestation challenge for this window.
pub fn key_challenge(window: &CaptureWindow) -> Result<[u8; 32], EvidenceError> {
	capture_key_attestation_challenge(&window.challenge, &window.attempt_id)
}

/// Play Integrity nonce for the exact bytes the server would store.
///
/// Unused until the camera plugin returns the JPEG rather than a cache URI.
#[allow(dead_code)]
pub fn digest_nonce(
	window: &CaptureWindow,
	evidence_binding_hash: &str,
) -> Result<[u8; 32], EvidenceError> {
	capture_integrity_request_nonce(
		&window.attempt_id,
		&window.requirement_id,
		&window.challenge,
		evidence_binding_hash,
	)
}

/// SHA-256 of captured bytes. A URI is not bytes, so it is not hashed here.
///
/// The camera plugin returns a cache URI, not the JPEG, so the host cannot
/// call this yet.
#[must_use]
#[cfg_attr(not(test), allow(dead_code))]
pub fn evidence_digest(bytes: &[u8]) -> String {
	sha256_hex(bytes)
}

/// A library path or a file URI is not a live capture.
#[must_use]
pub fn is_library_resource(value: &str) -> bool {
	let lower = value.trim().to_ascii_lowercase();
	lower.is_empty()
		|| lower.contains(IMAGE_PICKER)
		|| lower.contains(DOCUMENT_PICKER)
		|| lower.starts_with("file:")
		|| lower.starts_with("content:")
		|| lower.starts_with("ph://")
		|| lower.starts_with("assets-library:")
		|| lower.contains("dcim")
		|| lower.contains("gallery")
}

/// A cache URI from the camera is not a gallery pick, and it is still not
/// the evidence bytes.
#[must_use]
pub fn uri_fault(uri: &str) -> Fault {
	if is_library_resource(uri) {
		Fault::Library
	} else {
		Fault::BytesWithheld
	}
}

/// Decides the capture. The camera step never precedes the key challenge,
/// and the result is always a refusal on this pin.
#[must_use]
pub fn run(
	kind: ProofKind,
	window_open: bool,
	got_bytes: bool,
	key: DeviceAnswer,
	play: DeviceAnswer,
) -> Run {
	if !window_open {
		return Run {
			steps: Vec::new(),
			fault: Fault::WindowClosed,
		};
	}
	match sensor(kind) {
		Sensor::NotLive => Run {
			steps: Vec::new(),
			fault: Fault::NotLiveCapture,
		},
		Sensor::Missing => Run {
			steps: vec![Step::KeyChallenge],
			fault: Fault::PluginMissing,
		},
		Sensor::Camera => {
			let mut steps = vec![
				Step::KeyChallenge,
				Step::CameraPermission,
				Step::CameraStill,
			];
			if !got_bytes {
				return Run {
					steps,
					fault: Fault::BytesWithheld,
				};
			}
			steps.push(Step::DigestChallenge);
			let fault = match (key, play) {
				(DeviceAnswer::Unavailable, _) | (_, DeviceAnswer::Unavailable) => {
					Fault::Unavailable
				}
				(DeviceAnswer::Opaque, DeviceAnswer::Opaque) => Fault::Unverified,
			};
			Run { steps, fault }
		}
	}
}

#[cfg(test)]
mod tests {
	use verily_shared::sha256_hex;

	use super::*;

	fn window() -> CaptureWindow {
		CaptureWindow {
			attempt_id: "attempt".into(),
			requirement_id: "requirement".into(),
			challenge: "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8".into(),
			spoken_word: None,
			kind: ProofKind::Photo,
		}
	}

	#[test]
	fn the_camera_never_precedes_the_key_challenge() {
		for kind in [
			ProofKind::Photo,
			ProofKind::Video,
			ProofKind::Audio,
			ProofKind::VenueCode,
		] {
			let closed = run(
				kind,
				false,
				true,
				DeviceAnswer::Opaque,
				DeviceAnswer::Opaque,
			);
			assert_eq!(closed.fault, Fault::WindowClosed);
			assert!(closed.steps.is_empty());
		}
		let photo = run(
			ProofKind::Photo,
			true,
			true,
			DeviceAnswer::Opaque,
			DeviceAnswer::Opaque,
		);
		let key = photo
			.steps
			.iter()
			.position(|step| *step == Step::KeyChallenge);
		let camera = photo
			.steps
			.iter()
			.position(|step| *step == Step::CameraStill);
		assert!(key.unwrap() < camera.unwrap());
		assert_eq!(photo.fault, Fault::Unverified);
	}

	#[test]
	fn a_missing_sensor_is_not_a_library() {
		for kind in [
			ProofKind::Video,
			ProofKind::Audio,
			ProofKind::VenueCode,
			ProofKind::Presence,
			ProofKind::Movement,
		] {
			let run = run(kind, true, true, DeviceAnswer::Opaque, DeviceAnswer::Opaque);
			assert_eq!(run.fault, Fault::PluginMissing);
			assert_eq!(run.steps, vec![Step::KeyChallenge]);
		}
		assert_eq!(
			run(
				ProofKind::Note,
				true,
				false,
				DeviceAnswer::Unavailable,
				DeviceAnswer::Unavailable
			)
			.fault,
			Fault::NotLiveCapture
		);
		assert!(!plugin_allowed(IMAGE_PICKER));
		assert!(!plugin_allowed(DOCUMENT_PICKER));
		assert!(plugin_allowed(CAMERA));
		assert!(is_library_resource("file:///tmp/photo.jpg"));
		assert!(is_library_resource("content://media/external/images/1"));
		assert!(is_library_resource("ph://asset"));
		assert!(is_library_resource("image-picker"));
	}

	#[test]
	fn unavailable_attestation_and_a_uri_do_not_become_proof() {
		let withheld = run(
			ProofKind::Photo,
			true,
			false,
			DeviceAnswer::Unavailable,
			DeviceAnswer::Unavailable,
		);
		assert_eq!(withheld.fault, Fault::BytesWithheld);
		assert!(!withheld.steps.contains(&Step::DigestChallenge));

		let unavailable = run(
			ProofKind::Photo,
			true,
			true,
			DeviceAnswer::Unavailable,
			DeviceAnswer::Opaque,
		);
		assert_eq!(unavailable.fault, Fault::Unavailable);
		let opaque = run(
			ProofKind::Photo,
			true,
			true,
			DeviceAnswer::Opaque,
			DeviceAnswer::Unavailable,
		);
		assert_eq!(opaque.fault, Fault::Unavailable);
	}

	#[test]
	fn the_digest_is_the_bytes_and_the_nonce_is_that_binding() {
		let window = window();
		let bytes = b"jpeg-bytes";
		assert_eq!(evidence_digest(bytes), sha256_hex(bytes));
		let binding = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
		let nonce = digest_nonce(&window, binding).expect("nonce");
		assert_eq!(nonce.len(), 32);
		let challenge = key_challenge(&window).expect("challenge");
		assert_eq!(
			challenge
				.iter()
				.map(|byte| format!("{byte:02x}"))
				.collect::<String>(),
			"35daff575b9ca0b1be213cecb524dbb945126335ce86668d80d0a8c01f565b2c"
		);
		assert_ne!(nonce, challenge);
	}
}
