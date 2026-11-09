//! Calls the shell's capture and attestation plugins.
//!
//! `beginCapture` has already succeeded before [`open_live`] runs. The camera,
//! microphone, sensors, and scanner stay closed until then. This module does
//! not open a gallery, a file picker, or an upload. A missing plugin is a
//! failed live capture. The viewfinder widget this rev does not ship is drawn
//! with `Vector` in the capture screen; a real camera surface belongs in
//! LeptosKit, not in a library fallback here.

use crate::model::CaptureWindow;
use crate::model::LiveProof;

/// Plugin the shell registers for live capture.
pub const CAPTURE_PLUGIN: &str = "verily_capture";
/// Plugin the shell registers for Play Integrity, Key Attestation, and App Attest.
pub const ATTEST_PLUGIN: &str = "verily_attest";

/// Opens the sensor named in the payload. The payload is `OpenLive` JSON.
pub const OPEN_LIVE: u32 = 1;
/// Signs `Attest` JSON, binding the signature to the digest the server stored.
pub const ATTEST: u32 = 1;

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

/// Opens the live sensor for `window`. The challenge nonce goes to the plugin
/// and is not returned for display.
pub async fn open_live(window: &CaptureWindow) -> Result<LiveProof, HostFault> {
	if next_capture_step(plugin_installed(CAPTURE_PLUGIN)) != CaptureStep::OpenPlugin {
		return Err(HostFault::PluginMissing);
	}

	let payload = serde_json::json!({
		"attempt_id": window.attempt_id,
		"requirement_id": window.requirement_id,
		"challenge": window.challenge,
	});
	let bytes = call_plugin(CAPTURE_PLUGIN, OPEN_LIVE, &payload).await?;
	let reply: PluginDigest = serde_json::from_slice(&bytes).map_err(|_| HostFault::Rejected)?;
	if reply.digest_hex.is_empty() {
		return Err(HostFault::Rejected);
	}
	Ok(LiveProof {
		digest_hex: reply.digest_hex,
	})
}

/// Asks the shell to attest `digest_hex`, the digest the server stored.
pub async fn attest(digest_hex: &str) -> Result<(), HostFault> {
	if !plugin_installed(ATTEST_PLUGIN) {
		return Err(HostFault::PluginMissing);
	}
	let payload = serde_json::json!({ "digest_hex": digest_hex });
	let bytes = call_plugin(ATTEST_PLUGIN, ATTEST, &payload).await?;
	let reply: PluginBound = serde_json::from_slice(&bytes).map_err(|_| HostFault::Rejected)?;
	if reply.bound {
		Ok(())
	} else {
		Err(HostFault::Rejected)
	}
}

#[derive(serde::Deserialize)]
struct PluginDigest {
	digest_hex: String,
}

#[derive(serde::Deserialize)]
struct PluginBound {
	bound: bool,
}

fn plugin_installed(name: &str) -> bool {
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		leptoskit_bridge::guest::Client::new(name).is_ok()
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = name;
		false
	}
}

async fn call_plugin(
	name: &str,
	method: u32,
	payload: &serde_json::Value,
) -> Result<Vec<u8>, HostFault> {
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		let client =
			leptoskit_bridge::guest::Client::new(name).map_err(|_| HostFault::PluginMissing)?;
		let body = serde_json::to_vec(payload).map_err(|_| HostFault::Rejected)?;
		let call = client
			.call(leptoskit_bridge::MethodId(method), &body)
			.map_err(|_| HostFault::PluginMissing)?;
		let bytes = call.await.map_err(|_| HostFault::Rejected)?;
		Ok(bytes.to_vec())
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = (name, method, payload);
		Err(HostFault::PluginMissing)
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn a_missing_plugin_does_not_become_a_library() {
		assert_eq!(next_capture_step(false), CaptureStep::PluginMissing);
		assert_eq!(next_capture_step(true), CaptureStep::OpenPlugin);
	}
}
