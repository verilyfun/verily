//! Calls the shell's native live-capture, attestation, MediaPipe, and location
//! plugins (`verily-capture`, `verily-attest`, `mediapipe`, `location`).
//!
//! `beginCapture` must have already succeeded before any capture function runs.
//! On Android, the key attestation challenge (`SHA-256(captureChallenge || attemptId)`)
//! is always prepared on `verily-attest` BEFORE any camera, microphone, sensor,
//! or QR scanner opens. On iOS, a single account-bound Secure Enclave App Attest
//! key is registered on first use and reused for assertions. This module NEVER
//! opens an image picker, document picker, or photo gallery.

use crate::live;
use crate::model::CaptureWindow;

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

/// Why a live capture, upload, or attestation did not finish.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HostFault {
	/// The shell did not register the plugin. Not a reason to pick a file.
	PluginMissing,
	/// The plugin answered, and the answer was not a valid live proof.
	Rejected,
}

/// Metadata and host handle for one captured photo, video, or audio file.
///
/// The raw bytes remain in host storage and are streamed directly to the
/// server's upload reservation URL so large media never enters Wasm RAM.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CapturedMediaInfo {
	pub capture_file_id: String,
	pub sha256_hex: String,
	pub byte_length: u64,
	pub mime_type: String,
	pub duration_ms: u32,
}

/// Live device GPS fix returned by `verily-capture`.
#[derive(Clone, Debug, PartialEq)]
pub struct CapturedLocationFix {
	pub latitude: f64,
	pub longitude: f64,
	pub accuracy_meters: f64,
	pub captured_at_ms: i64,
	pub is_mock: bool,
}

/// Signed attestation bundle produced by `verily-attest` after capture.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DeviceAttestationPayload {
	pub platform: &'static str,
	pub payload_b64: String,
	pub key_id_b64: Option<String>,
	pub integrity_token: Option<String>,
}

fn ensure_capture_policy(window: &CaptureWindow) -> Result<[u8; 32], HostFault> {
	if !live::plugin_allowed(live::CAMERA)
		|| !live::plugin_allowed(live::APP_INTEGRITY)
		|| !live::plugin_allowed(live::PERMISSIONS)
		|| live::plugin_allowed(live::IMAGE_PICKER)
		|| live::plugin_allowed(live::DOCUMENT_PICKER)
	{
		return Err(HostFault::Rejected);
	}
	let challenge = live::key_challenge(window).map_err(|_| HostFault::Rejected)?;
	if next_capture_step(capture_ready()) != CaptureStep::OpenPlugin {
		return Err(HostFault::PluginMissing);
	}
	Ok(challenge)
}

/// Prepares the per-window attested hardware key and captures one live photo.
///
/// Never falls back to a photo library or file picker.
pub async fn capture_photo(window: &CaptureWindow) -> Result<CapturedMediaInfo, HostFault> {
	let challenge = ensure_capture_policy(window)?;
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		native_capture::capture_photo(window, &challenge).await
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = challenge;
		Err(HostFault::PluginMissing)
	}
}

/// Prepares the per-window attested hardware key and starts continuous video or
/// audio recording. Call [`stop_recording`] when the participant finishes.
pub async fn start_recording(window: &CaptureWindow) -> Result<(), HostFault> {
	let challenge = ensure_capture_policy(window)?;
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		native_capture::start_recording(window, &challenge).await
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = challenge;
		Err(HostFault::PluginMissing)
	}
}

/// Stops an active video or audio recording and returns its verified digest and
/// host capture file handle.
pub async fn stop_recording(window: &CaptureWindow) -> Result<CapturedMediaInfo, HostFault> {
	if next_capture_step(capture_ready()) != CaptureStep::OpenPlugin {
		return Err(HostFault::PluginMissing);
	}
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		native_capture::stop_recording(window).await
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = window;
		Err(HostFault::PluginMissing)
	}
}

/// Streams a host-owned captured media file directly to a server-issued
/// presigned PUT URL, returning the storage version ID if the server sent one.
pub async fn upload_captured_file(
	capture_file_id: &str,
	upload_url: &str,
	mime_type: &str,
	expected_sha256_hex: &str,
) -> Result<String, HostFault> {
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		let plugin =
			verily_capture::guest::VerilyCapture::new().map_err(|_| HostFault::PluginMissing)?;
		let version_id = plugin
			.upload_captured_file(&verily_capture::UploadCapturedFileRequest {
				capture_file_id: capture_file_id.to_owned(),
				upload_url: upload_url.to_owned(),
				mime_type: mime_type.to_owned(),
				expected_sha256_hex: expected_sha256_hex.to_owned(),
			})
			.await
			.map_err(|_| HostFault::Rejected)?;
		Ok(version_id.unwrap_or_else(|| "local".to_owned()))
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = (capture_file_id, upload_url, mime_type, expected_sha256_hex);
		Err(HostFault::PluginMissing)
	}
}

/// Deletes a temporary host-owned capture file after upload or retake.
pub async fn discard_captured_file(capture_file_id: &str) {
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		if !capture_file_id.is_empty()
			&& let Ok(plugin) = verily_capture::guest::VerilyCapture::new()
		{
			let _ = plugin.discard_captured_file(capture_file_id).await;
		}
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = capture_file_id;
	}
}

/// Signs and attests `digest_hex` using `verily-attest` on native targets.
///
/// On iOS, automatically registers the account's Secure Enclave App Attest key
/// with the backend on first use before generating the assertion.
pub async fn attest_captured_digest(
	window: &CaptureWindow,
	digest_hex: &str,
) -> Result<DeviceAttestationPayload, HostFault> {
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		native_capture::attest_digest(window, digest_hex).await
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = (window, digest_hex);
		Err(HostFault::PluginMissing)
	}
}

/// Prepares the per-window attested key (on Android) and scans a rotating venue
/// QR code through `verily-capture` on native mobile.
pub async fn scan_venue_qr(window: &CaptureWindow) -> Result<String, HostFault> {
	let challenge = ensure_capture_policy(window)?;
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		native_capture::prepare_key(window, &challenge).await?;
		let plugin =
			verily_capture::guest::VerilyCapture::new().map_err(|_| HostFault::PluginMissing)?;
		plugin.scan_qr().await.map_err(|_| HostFault::Rejected)
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = challenge;
		Err(HostFault::PluginMissing)
	}
}

/// Prepares the per-window attested key (on Android) and captures a bounded
/// canonical device motion trace JSON via `verily-capture`.
pub async fn capture_motion_trace(
	window: &CaptureWindow,
	duration_ms: u32,
) -> Result<String, HostFault> {
	let challenge = ensure_capture_policy(window)?;
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		native_capture::prepare_key(window, &challenge).await?;
		let plugin =
			verily_capture::guest::VerilyCapture::new().map_err(|_| HostFault::PluginMissing)?;
		plugin
			.capture_motion(duration_ms.clamp(1_000, 30_000))
			.await
			.map_err(|_| HostFault::Rejected)
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = (challenge, duration_ms);
		Err(HostFault::PluginMissing)
	}
}

/// Prepares the per-window attested key (on Android) and captures one live GPS
/// fix for a location proof requirement. Rejects OS-reported mock locations.
pub async fn capture_location_fix(
	window: &CaptureWindow,
) -> Result<CapturedLocationFix, HostFault> {
	let challenge = ensure_capture_policy(window)?;
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		native_capture::prepare_key(window, &challenge).await?;
		let plugin =
			verily_capture::guest::VerilyCapture::new().map_err(|_| HostFault::PluginMissing)?;
		let fix = plugin
			.capture_location()
			.await
			.map_err(|_| HostFault::Rejected)?;
		if fix.is_mock {
			return Err(HostFault::Rejected);
		}
		Ok(CapturedLocationFix {
			latitude: fix.latitude,
			longitude: fix.longitude,
			accuracy_meters: fix.accuracy_meters,
			captured_at_ms: fix.captured_at_ms,
			is_mock: fix.is_mock,
		})
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		let _ = challenge;
		Err(HostFault::PluginMissing)
	}
}

/// Fetches a one-shot device GPS fix for Nearby catalogue ranking (coordinates
/// are coarsened on the server and never exposed on public cards).
#[cfg_attr(not(all(feature = "native", target_arch = "wasm32")), allow(dead_code))]
pub async fn current_location() -> Option<(f64, f64)> {
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		let plugin = verily_capture::guest::VerilyCapture::new().ok()?;
		let fix = plugin.capture_location().await.ok()?;
		if fix.is_mock {
			return None;
		}
		Some((fix.latitude, fix.longitude))
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		None
	}
}

fn capture_ready() -> bool {
	#[cfg(all(feature = "native", target_arch = "wasm32"))]
	{
		verily_capture::guest::VerilyCapture::new().is_ok()
	}
	#[cfg(not(all(feature = "native", target_arch = "wasm32")))]
	{
		false
	}
}

#[cfg(all(feature = "native", target_arch = "wasm32"))]
mod native_capture {
	use base64::Engine;
	use base64::engine::general_purpose::STANDARD;

	use super::CapturedMediaInfo;
	use super::DeviceAttestationPayload;
	use super::HostFault;
	use crate::model::CaptureWindow;
	use crate::model::ProofKind;
	use crate::ops::BeginAppAttestRegistration;
	use crate::ops::RegisterAppAttestKey;

	fn media_info(media: verily_capture::CapturedMedia) -> CapturedMediaInfo {
		CapturedMediaInfo {
			capture_file_id: media.capture_file_id,
			sha256_hex: media.sha256_hex,
			byte_length: media.byte_length,
			mime_type: media.mime_type,
			duration_ms: media.duration_ms,
		}
	}

	/// Prepares the per-window hardware key on Android BEFORE any sensor opens.
	pub(super) async fn prepare_key(
		window: &CaptureWindow,
		challenge: &[u8; 32],
	) -> Result<(), HostFault> {
		let attest =
			verily_attest::guest::VerilyAttest::new().map_err(|_| HostFault::PluginMissing)?;
		if cfg!(feature = "android") {
			let capture_id = format!("{}:{}", window.attempt_id, window.requirement_id);
			attest
				.prepare_capture_key(&verily_attest::PrepareCaptureKey {
					capture_id,
					attestation_challenge: challenge.to_vec(),
				})
				.await
				.map_err(|_| HostFault::Rejected)?;
		}
		Ok(())
	}

	pub(super) async fn capture_photo(
		window: &CaptureWindow,
		challenge: &[u8; 32],
	) -> Result<CapturedMediaInfo, HostFault> {
		prepare_key(window, challenge).await?;
		let capture =
			verily_capture::guest::VerilyCapture::new().map_err(|_| HostFault::PluginMissing)?;
		let media = capture
			.capture_photo(verily_capture::CameraFacing::Back)
			.await
			.map_err(|_| HostFault::Rejected)?;
		Ok(media_info(media))
	}

	pub(super) async fn start_recording(
		window: &CaptureWindow,
		challenge: &[u8; 32],
	) -> Result<(), HostFault> {
		prepare_key(window, challenge).await?;
		let capture =
			verily_capture::guest::VerilyCapture::new().map_err(|_| HostFault::PluginMissing)?;
		match window.kind {
			ProofKind::Video => {
				// Bind MediaPipe guest bridge if registered for live movement overlays.
				let _mp = mediapipe::bridge::guest::GuestMediaPipe::new().ok();
				capture
					.start_video(verily_capture::StartVideoRequest {
						facing: verily_capture::CameraFacing::Back,
						max_duration_seconds: 60,
						camera_session_id: 1,
						record_audio: true,
					})
					.await
					.map_err(|_| HostFault::Rejected)
			}
			ProofKind::Audio => capture
				.start_audio(60)
				.await
				.map_err(|_| HostFault::Rejected),
			_ => Err(HostFault::Rejected),
		}
	}

	pub(super) async fn stop_recording(
		window: &CaptureWindow,
	) -> Result<CapturedMediaInfo, HostFault> {
		let capture =
			verily_capture::guest::VerilyCapture::new().map_err(|_| HostFault::PluginMissing)?;
		let media = match window.kind {
			ProofKind::Video => capture
				.stop_video()
				.await
				.map_err(|_| HostFault::Rejected)?,
			ProofKind::Audio => capture
				.stop_audio()
				.await
				.map_err(|_| HostFault::Rejected)?,
			_ => return Err(HostFault::Rejected),
		};
		Ok(media_info(media))
	}

	async fn ensure_ios_app_attest_key(
		attest: verily_attest::guest::VerilyAttest,
	) -> Result<String, HostFault> {
		const ACCOUNT_SLOT: &str = "current";
		if let Some(stored) = attest
			.read_app_attest_key(ACCOUNT_SLOT)
			.await
			.map_err(|_| HostFault::Rejected)?
			&& stored.registered
		{
			return Ok(stored.key_id);
		}
		if !attest
			.app_attest_supported()
			.await
			.map_err(|_| HostFault::Rejected)?
		{
			return Err(HostFault::PluginMissing);
		}
		let challenge = leptoskit::rpc::client::call(BeginAppAttestRegistration {})
			.await
			.map_err(|_| HostFault::Rejected)?;
		let key_id = attest
			.generate_app_attest_key(ACCOUNT_SLOT)
			.await
			.map_err(|_| HostFault::Rejected)?;
		let client_data_hash = verily_shared::sha256_bytes(challenge.nonce.as_bytes());
		let attestation_object = attest
			.attest_app_attest_key(&verily_attest::KeyHashRequest {
				key_id: key_id.clone(),
				client_data_hash,
			})
			.await
			.map_err(|_| HostFault::Rejected)?;
		let registered = leptoskit::rpc::client::call(RegisterAppAttestKey {
			challenge_id: challenge.challenge_id,
			key_id_b64: key_id.clone(),
			attestation_object_b64: STANDARD.encode(&attestation_object),
		})
		.await
		.map_err(|_| HostFault::Rejected)?;
		if !registered.registered {
			return Err(HostFault::Rejected);
		}
		attest
			.mark_app_attest_registered(ACCOUNT_SLOT, &key_id)
			.await
			.map_err(|_| HostFault::Rejected)?;
		Ok(key_id)
	}

	pub(super) async fn attest_digest(
		window: &CaptureWindow,
		digest_hex: &str,
	) -> Result<DeviceAttestationPayload, HostFault> {
		let attest =
			verily_attest::guest::VerilyAttest::new().map_err(|_| HostFault::PluginMissing)?;
		if cfg!(feature = "android") {
			let capture_id = format!("{}:{}", window.attempt_id, window.requirement_id);
			let proof = attest
				.sign_capture_manifest(&verily_attest::SignCaptureManifest {
					capture_id,
					manifest: digest_hex.as_bytes().to_vec(),
				})
				.await
				.map_err(|_| HostFault::Rejected)?;
			let chain_b64: Vec<String> = proof
				.certificate_chain_der
				.iter()
				.map(|der| STANDARD.encode(der))
				.collect();
			let chain_json = serde_json::to_vec(&chain_b64).map_err(|_| HostFault::Rejected)?;
			let cloud_project = option_env!("VERILY_PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER")
				.and_then(|s| s.parse::<u64>().ok())
				.unwrap_or(0);
			let integrity_token = if cloud_project > 0 {
				attest
					.request_play_integrity(&verily_attest::PlayIntegrityRequest {
						request_hash: digest_hex.to_owned(),
						cloud_project_number: cloud_project,
					})
					.await
					.ok()
			} else {
				None
			};
			return Ok(DeviceAttestationPayload {
				platform: "android",
				payload_b64: STANDARD.encode(chain_json),
				key_id_b64: None,
				integrity_token,
			});
		}
		if cfg!(feature = "ios") {
			let key_id = ensure_ios_app_attest_key(attest).await?;
			let digest_bytes = verily_shared::sha256_bytes(digest_hex.as_bytes());
			let assertion = attest
				.generate_app_attest_assertion(&verily_attest::KeyHashRequest {
					key_id: key_id.clone(),
					client_data_hash: digest_bytes,
				})
				.await
				.map_err(|_| HostFault::Rejected)?;
			return Ok(DeviceAttestationPayload {
				platform: "ios",
				payload_b64: STANDARD.encode(assertion),
				key_id_b64: Some(key_id),
				integrity_token: None,
			});
		}
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
		assert!(!live::plugin_allowed(live::IMAGE_PICKER));
		assert!(!live::plugin_allowed(live::DOCUMENT_PICKER));
	}
}
