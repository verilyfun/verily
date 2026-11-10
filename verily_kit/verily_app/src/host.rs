//! Calls the shell's camera and app-integrity plugins.
//!
//! `beginCapture` has already succeeded before [`open_live`] runs. The key
//! challenge is sent before the camera, microphone, or scanner. A photo uses
//! `camera`. Video, audio, and a venue code have no live plugin on this pin,
//! so they stop. This module does not open an image picker, a document picker,
//! or a file. App integrity returns unavailable, or an opaque token that is
//! not a certificate chain; either way the proof is refused.

use crate::live;
use crate::live::DeviceAnswer;
use crate::model::CaptureWindow;
use crate::model::LiveProof;

/// What the screen does after `beginCapture` returns.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CaptureStep {
	/// The shell plugin may open. This is the only success.
	OpenPlugin,
	/// The shell has no capture plugin. The screen shows the failure copy.
	PluginMissing,
}

/// Live capture continues only when the shell plugin is installed.
#[must_use]
pub const fn next_capture_step(plugin_ready: bool) -> CaptureStep {
	if plugin_ready {
		CaptureStep::OpenPlugin
	} else {
		CaptureStep::PluginMissing
	}
}

/// Why a live capture or attestation did not finish.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HostFault {
	/// The shell did not register the plugin. Not a reason to pick a file.
	PluginMissing,
	/// The plugin answered, and the answer was not a live proof.
	Rejected,
}

/// Opens the live sensor for `window`, then refuses the proof.
///
/// The refusal is the honest result: the camera plugin returns a cache URI
/// rather than the JPEG, and app integrity does not return a certificate
/// chain. A URI is not hashed, and an unavailable attestation is not stored
/// as success.
pub async fn open_live(window: &CaptureWindow) -> Result<LiveProof, HostFault> {
	if !live::plugin_allowed(live::CAMERA)
		|| !live::plugin_allowed(live::APP_INTEGRITY)
		|| !live::plugin_allowed(live::PERMISSIONS)
		|| live::plugin_allowed(live::IMAGE_PICKER)
		|| live::plugin_allowed(live::DOCUMENT_PICKER)
	{
		return Err(HostFault::Rejected);
	}
	let planned = live::run(
		window.kind,
		true,
		false,
		DeviceAnswer::Unavailable,
		DeviceAnswer::Unavailable,
	);
	if planned.fault == live::Fault::WindowClosed || planned.steps.is_empty() {
		return Err(HostFault::Rejected);
	}

	// The key challenge is the first step whenever a sensor is involved.
	let challenge = live::key_challenge(window).map_err(|_| HostFault::Rejected)?;
	let key = attest_key(&challenge).await;
	if planned.fault == live::Fault::PluginMissing {
		let _ = key;
		return Err(HostFault::PluginMissing);
	}

	if live::sensor(window.kind) != live::Sensor::Camera {
		return Err(HostFault::Rejected);
	}
	if next_capture_step(camera_ready()) != CaptureStep::OpenPlugin {
		return Err(HostFault::PluginMissing);
	}

	// Permission, then one still. Both come after the key challenge above.
	let uri = take_still().await?;
	if live::uri_fault(&uri) == live::Fault::Library {
		return Err(HostFault::Rejected);
	}
	// The still is a URI. The bytes were not returned, so there is no digest
	// to bind and no Play Integrity request to make.
	let _ = key;
	Err(HostFault::Rejected)
}

/// Asks the shell to attest `digest_hex`.
///
/// A hex digest is not a signature. App integrity cannot turn it into a
/// trusted chain, so this does not report success.
pub async fn attest(digest_hex: &str) -> Result<(), HostFault> {
	// The stored digest is not a device signature. App integrity cannot
	// turn it into a trusted chain, so a well-formed digest is refused too.
	let _ = digest_hex;
	Err(HostFault::Rejected)
}

async fn attest_key(challenge: &[u8; 32]) -> DeviceAnswer {
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		ask_app_integrity(challenge).await
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = challenge;
		DeviceAnswer::Unavailable
	}
}

/// One still, as a URI. The JPEG itself is not in the reply.
async fn take_still() -> Result<String, HostFault> {
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		camera_uri().await
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		Err(HostFault::PluginMissing)
	}
}

fn camera_ready() -> bool {
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		leptoskit_plugin_camera::guest::Camera::new().is_ok()
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		false
	}
}

#[cfg(all(feature = "native", target_arch = "wasm32"))]
async fn ask_app_integrity(challenge: &[u8; 32]) -> DeviceAnswer {
	use leptoskit_plugin_app_integrity::Attestation;
	use leptoskit_plugin_app_integrity::Challenge;

	let Ok(plugin) = leptoskit_plugin_app_integrity::guest::AppIntegrity::new() else {
		return DeviceAnswer::Unavailable;
	};
	let Ok(challenge) = Challenge::new(challenge.to_vec()) else {
		return DeviceAnswer::Unavailable;
	};
	match plugin.attest(&challenge).await {
		Ok(Attestation::Token(token)) if !token.is_empty() => DeviceAnswer::Opaque,
		_ => DeviceAnswer::Unavailable,
	}
}

#[cfg(all(feature = "native", target_arch = "wasm32"))]
async fn camera_uri() -> Result<String, HostFault> {
	use leptoskit_plugin_camera::Facing;
	use leptoskit_plugin_camera::TakePicture;
	use leptoskit_plugin_permissions::Permission;
	use leptoskit_plugin_permissions::Status;

	let permissions = leptoskit_plugin_permissions::guest::Permissions::new()
		.map_err(|_| HostFault::PluginMissing)?;
	let auth = permissions
		.request(Permission::Camera)
		.await
		.map_err(|_| HostFault::Rejected)?;
	if auth.status != Status::Granted {
		return Err(HostFault::Rejected);
	}
	let camera =
		leptoskit_plugin_camera::guest::Camera::new().map_err(|_| HostFault::PluginMissing)?;
	let session = camera
		.create(Facing::Back)
		.await
		.map_err(|_| HostFault::Rejected)?;
	let shot = camera
		.take_picture(TakePicture::default_budget(session))
		.await;
	let _ = camera.release(session).await;
	let asset = shot.map_err(|_| HostFault::Rejected)?;
	Ok(asset.uri)
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn a_missing_plugin_does_not_become_a_library() {
		assert_eq!(next_capture_step(false), CaptureStep::PluginMissing);
		assert_eq!(next_capture_step(true), CaptureStep::OpenPlugin);
		assert!(!live::plugin_allowed(live::IMAGE_PICKER));
		assert!(!live::plugin_allowed(live::DOCUMENT_PICKER));
	}
}
