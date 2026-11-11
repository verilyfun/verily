//! Decides whether a live capture may open.
//!
//! `beginCapture` has already succeeded before [`open_live`] runs. The key
//! challenge is computed before any sensor. LeptosKit 0.3.0 publishes no
//! camera, microphone, scanner, or app-integrity plugin, so every live kind
//! stops here. This module does not open an image picker, a document picker,
//! or a file, and it does not record an unavailable attestation as success.

use crate::live;
use crate::live::DeviceAnswer;
use crate::model::CaptureWindow;
use crate::model::LiveProof;

/// What the screen does after `beginCapture` returns.
///
/// The screen calls this once a capture plugin exists. Until then only the
/// tests construct it.
#[cfg_attr(not(test), allow(dead_code))]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CaptureStep {
	/// The shell plugin may open. This is the only success.
	OpenPlugin,
	/// The shell has no capture plugin. The screen shows the failure copy.
	PluginMissing,
}

/// Live capture continues only when the shell plugin is installed.
#[must_use]
#[cfg_attr(not(test), allow(dead_code))]
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
/// The refusal is the honest result on this pin: there is no camera plugin
/// to return bytes, and no app-integrity plugin to return a certificate
/// chain. A missing plugin is not a gallery.
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
	// 0.3.0 has no camera plugin. Do not fall through to a file or a URI.
	let _ = (key, camera_ready());
	Err(HostFault::PluginMissing)
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
	// No app-integrity plugin in LeptosKit 0.3.0. Unavailable is not a token.
	let _ = challenge;
	DeviceAnswer::Unavailable
}

fn camera_ready() -> bool {
	false
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
