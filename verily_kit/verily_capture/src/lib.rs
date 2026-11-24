//! Verily live capture bridge plugin (`"verily-capture"`).
//!
//! Captures fresh photo, video (with concurrent MediaPipe frame streaming),
//! audio, QR venue codes, bounded motion traces, and GPS location observations
//! directly from device sensors. Captured media is hashed on the host and
//! streamed directly to a server-issued upload reservation URL so multi-MB
//! recordings never enter Wasm linear memory.
//!
//! This plugin deliberately exposes **no** gallery, photo library, or document
//! picker methods.

use leptoskit_bridge::codec::{Decoder, Encoder};
use leptoskit_bridge::{Bytes, Error, MethodId};

/// Runtime plugin name in `leptoskit.toml`.
pub const NAME: &str = "verily-capture";

pub const CAPTURE_PHOTO: MethodId = MethodId(0);
pub const START_VIDEO: MethodId = MethodId(1);
pub const STOP_VIDEO: MethodId = MethodId(2);
pub const START_AUDIO: MethodId = MethodId(3);
pub const STOP_AUDIO: MethodId = MethodId(4);
pub const SCAN_QR: MethodId = MethodId(5);
pub const CAPTURE_MOTION: MethodId = MethodId(6);
pub const CAPTURE_LOCATION: MethodId = MethodId(7);
pub const UPLOAD_CAPTURED_FILE: MethodId = MethodId(8);
pub const DISCARD_CAPTURED_FILE: MethodId = MethodId(9);

pub const METHODS: &[MethodId] = &[
	CAPTURE_PHOTO,
	START_VIDEO,
	STOP_VIDEO,
	START_AUDIO,
	STOP_AUDIO,
	SCAN_QR,
	CAPTURE_MOTION,
	CAPTURE_LOCATION,
	UPLOAD_CAPTURED_FILE,
	DISCARD_CAPTURED_FILE,
];

/// Camera lens facing for photo/video capture.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u32)]
pub enum CameraFacing {
	Back = 0,
	Front = 1,
}

impl CameraFacing {
	#[must_use]
	pub const fn from_code(code: u32) -> Option<Self> {
		match code {
			0 => Some(Self::Back),
			1 => Some(Self::Front),
			_ => None,
		}
	}
}

/// Host handle and verified digest of one live media capture (photo, video, or audio).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CapturedMedia {
	/// Opaque host-owned temporary capture identifier (never a user-supplied path).
	pub capture_file_id: String,
	/// Lowercase 64-character hex SHA-256 of the exact captured file bytes.
	pub sha256_hex: String,
	/// Exact byte length of the captured file.
	pub byte_length: u64,
	/// Canonical MIME type (`image/jpeg`, `video/mp4`, `audio/mp4`, etc.).
	pub mime_type: String,
	/// Probed media duration in milliseconds (`0` for still photos).
	pub duration_ms: u32,
}

impl CapturedMedia {
	pub fn encode(&self) -> Result<Bytes, Error> {
		if self.capture_file_id.is_empty()
			|| self.sha256_hex.len() != 64
			|| self.byte_length == 0
			|| self.mime_type.is_empty()
		{
			return Err(Error::InvalidArgument);
		}
		let mut enc = Encoder::with_capacity(128);
		enc.bytes(self.capture_file_id.as_bytes())?;
		enc.bytes(self.sha256_hex.as_bytes())?;
		let len = self.byte_length.to_le_bytes();
		enc.u32(u32::from_le_bytes([len[0], len[1], len[2], len[3]]));
		enc.u32(u32::from_le_bytes([len[4], len[5], len[6], len[7]]));
		enc.bytes(self.mime_type.as_bytes())?;
		enc.u32(self.duration_ms);
		Ok(enc.finish())
	}

	pub fn decode(bytes: &[u8]) -> Result<Self, Error> {
		let mut dec = Decoder::new(bytes);
		let capture_file_id = dec.string()?.to_owned();
		let sha256_hex = dec.string()?.to_owned();
		let lo = dec.u32()?.to_le_bytes();
		let hi = dec.u32()?.to_le_bytes();
		let byte_length =
			u64::from_le_bytes([lo[0], lo[1], lo[2], lo[3], hi[0], hi[1], hi[2], hi[3]]);
		let mime_type = dec.string()?.to_owned();
		let duration_ms = dec.u32()?;
		dec.finish()?;
		if capture_file_id.is_empty()
			|| sha256_hex.len() != 64
			|| byte_length == 0
			|| mime_type.is_empty()
		{
			return Err(Error::InvalidArgument);
		}
		Ok(Self {
			capture_file_id,
			sha256_hex,
			byte_length,
			mime_type,
			duration_ms,
		})
	}
}

/// Request to start video recording with optional MediaPipe camera session binding.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct StartVideoRequest {
	pub facing: CameraFacing,
	pub max_duration_seconds: u32,
	pub camera_session_id: u32,
	pub record_audio: bool,
}

impl StartVideoRequest {
	pub fn encode(&self) -> Bytes {
		let mut enc = Encoder::with_capacity(16);
		enc.u32(self.facing as u32);
		enc.u32(self.max_duration_seconds);
		enc.u32(self.camera_session_id);
		enc.u32(u32::from(self.record_audio));
		enc.finish()
	}

	pub fn decode(bytes: &[u8]) -> Result<Self, Error> {
		let mut dec = Decoder::new(bytes);
		let facing = CameraFacing::from_code(dec.u32()?).ok_or(Error::InvalidArgument)?;
		let max_duration_seconds = dec.u32()?;
		let camera_session_id = dec.u32()?;
		let record_audio = match dec.u32()? {
			0 => false,
			1 => true,
			_ => return Err(Error::InvalidArgument),
		};
		dec.finish()?;
		Ok(Self {
			facing,
			max_duration_seconds,
			camera_session_id,
			record_audio,
		})
	}
}

/// Request to upload a host-owned captured file to a server-issued presigned PUT URL.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UploadCapturedFileRequest {
	pub capture_file_id: String,
	pub upload_url: String,
	pub mime_type: String,
	pub expected_sha256_hex: String,
}

impl UploadCapturedFileRequest {
	pub fn encode(&self) -> Result<Bytes, Error> {
		if self.capture_file_id.is_empty()
			|| self.upload_url.is_empty()
			|| self.mime_type.is_empty()
			|| self.expected_sha256_hex.len() != 64
		{
			return Err(Error::InvalidArgument);
		}
		let mut enc = Encoder::with_capacity(256);
		enc.bytes(self.capture_file_id.as_bytes())?;
		enc.bytes(self.upload_url.as_bytes())?;
		enc.bytes(self.mime_type.as_bytes())?;
		enc.bytes(self.expected_sha256_hex.as_bytes())?;
		Ok(enc.finish())
	}

	pub fn decode(bytes: &[u8]) -> Result<Self, Error> {
		let mut dec = Decoder::new(bytes);
		let capture_file_id = dec.string()?.to_owned();
		let upload_url = dec.string()?.to_owned();
		let mime_type = dec.string()?.to_owned();
		let expected_sha256_hex = dec.string()?.to_owned();
		dec.finish()?;
		if capture_file_id.is_empty()
			|| upload_url.is_empty()
			|| mime_type.is_empty()
			|| expected_sha256_hex.len() != 64
		{
			return Err(Error::InvalidArgument);
		}
		Ok(Self {
			capture_file_id,
			upload_url,
			mime_type,
			expected_sha256_hex,
		})
	}
}

/// Captured live location fix with OS-reported mock/simulation flag.
#[derive(Debug, Clone, PartialEq)]
pub struct CapturedLocation {
	pub latitude: f64,
	pub longitude: f64,
	pub accuracy_meters: f64,
	pub captured_at_ms: i64,
	pub is_mock: bool,
}

impl CapturedLocation {
	pub fn encode(&self) -> Bytes {
		let mut enc = Encoder::with_capacity(36);
		for value in [self.latitude, self.longitude, self.accuracy_meters] {
			let b = value.to_le_bytes();
			enc.u32(u32::from_le_bytes([b[0], b[1], b[2], b[3]]));
			enc.u32(u32::from_le_bytes([b[4], b[5], b[6], b[7]]));
		}
		let ts = self.captured_at_ms.to_le_bytes();
		enc.u32(u32::from_le_bytes([ts[0], ts[1], ts[2], ts[3]]));
		enc.u32(u32::from_le_bytes([ts[4], ts[5], ts[6], ts[7]]));
		enc.u32(u32::from(self.is_mock));
		enc.finish()
	}

	pub fn decode(bytes: &[u8]) -> Result<Self, Error> {
		let mut dec = Decoder::new(bytes);
		let mut read_f64 = || -> Result<f64, Error> {
			let lo = dec.u32()?.to_le_bytes();
			let hi = dec.u32()?.to_le_bytes();
			let v = f64::from_le_bytes([lo[0], lo[1], lo[2], lo[3], hi[0], hi[1], hi[2], hi[3]]);
			if !v.is_finite() {
				return Err(Error::InvalidArgument);
			}
			Ok(v)
		};
		let latitude = read_f64()?;
		let longitude = read_f64()?;
		let accuracy_meters = read_f64()?;
		let ts_lo = dec.u32()?.to_le_bytes();
		let ts_hi = dec.u32()?.to_le_bytes();
		let captured_at_ms = i64::from_le_bytes([
			ts_lo[0], ts_lo[1], ts_lo[2], ts_lo[3], ts_hi[0], ts_hi[1], ts_hi[2], ts_hi[3],
		]);
		let is_mock = match dec.u32()? {
			0 => false,
			1 => true,
			_ => return Err(Error::InvalidArgument),
		};
		dec.finish()?;
		Ok(Self {
			latitude,
			longitude,
			accuracy_meters,
			captured_at_ms,
			is_mock,
		})
	}
}

/// Wasm guest client for calling `"verily-capture"`.
#[cfg(all(feature = "guest", target_arch = "wasm32"))]
pub mod guest {
	use leptoskit_bridge::Error;
	use leptoskit_bridge::codec::{Decoder, Encoder};
	use leptoskit_bridge::guest::Plugin;

	use super::{
		CAPTURE_LOCATION, CAPTURE_MOTION, CAPTURE_PHOTO, CameraFacing, CapturedLocation,
		CapturedMedia, DISCARD_CAPTURED_FILE, SCAN_QR, START_AUDIO, START_VIDEO, STOP_AUDIO,
		STOP_VIDEO, StartVideoRequest, UPLOAD_CAPTURED_FILE, UploadCapturedFileRequest,
	};

	#[derive(Clone, Copy)]
	pub struct VerilyCapture(Plugin);

	impl VerilyCapture {
		pub fn new() -> Result<Self, Error> {
			Plugin::resolve(super::NAME).map(Self)
		}

		pub async fn capture_photo(self, facing: CameraFacing) -> Result<CapturedMedia, Error> {
			let mut enc = Encoder::with_capacity(4);
			enc.u32(facing as u32);
			let reply = self.0.call(CAPTURE_PHOTO, &enc.finish())?.await?;
			CapturedMedia::decode(&reply)
		}

		pub async fn start_video(self, req: StartVideoRequest) -> Result<(), Error> {
			let reply = self.0.call(START_VIDEO, &req.encode())?.await?;
			Decoder::new(&reply).finish()
		}

		pub async fn stop_video(self) -> Result<CapturedMedia, Error> {
			let reply = self.0.call(STOP_VIDEO, &[])?.await?;
			CapturedMedia::decode(&reply)
		}

		pub async fn start_audio(self, max_duration_seconds: u32) -> Result<(), Error> {
			let mut enc = Encoder::with_capacity(4);
			enc.u32(max_duration_seconds);
			let reply = self.0.call(START_AUDIO, &enc.finish())?.await?;
			Decoder::new(&reply).finish()
		}

		pub async fn stop_audio(self) -> Result<CapturedMedia, Error> {
			let reply = self.0.call(STOP_AUDIO, &[])?.await?;
			CapturedMedia::decode(&reply)
		}

		pub async fn scan_qr(self) -> Result<String, Error> {
			let reply = self.0.call(SCAN_QR, &[])?.await?;
			let mut dec = Decoder::new(&reply);
			let payload = dec.string()?.to_owned();
			dec.finish()?;
			Ok(payload)
		}

		pub async fn capture_motion(self, duration_ms: u32) -> Result<String, Error> {
			let mut enc = Encoder::with_capacity(4);
			enc.u32(duration_ms);
			let reply = self.0.call(CAPTURE_MOTION, &enc.finish())?.await?;
			let mut dec = Decoder::new(&reply);
			let canonical_json = dec.string()?.to_owned();
			dec.finish()?;
			Ok(canonical_json)
		}

		pub async fn capture_location(self) -> Result<CapturedLocation, Error> {
			let reply = self.0.call(CAPTURE_LOCATION, &[])?.await?;
			CapturedLocation::decode(&reply)
		}

		pub async fn upload_captured_file(
			self,
			req: &UploadCapturedFileRequest,
		) -> Result<Option<String>, Error> {
			let reply = self.0.call(UPLOAD_CAPTURED_FILE, &req.encode()?)?.await?;
			let mut dec = Decoder::new(&reply);
			let version_id = dec.string()?.to_owned();
			dec.finish()?;
			Ok((!version_id.is_empty()).then_some(version_id))
		}

		pub async fn discard_captured_file(self, capture_file_id: &str) -> Result<(), Error> {
			let mut enc = Encoder::with_capacity(40);
			enc.bytes(capture_file_id.as_bytes())?;
			let reply = self.0.call(DISCARD_CAPTURED_FILE, &enc.finish())?.await?;
			Decoder::new(&reply).finish()
		}
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn capture_codecs_round_trip() {
		let media = CapturedMedia {
			capture_file_id: "cap-001".to_owned(),
			sha256_hex: "b".repeat(64),
			byte_length: 1_234_567,
			mime_type: "video/mp4".to_owned(),
			duration_ms: 8_500,
		};
		assert_eq!(
			CapturedMedia::decode(&media.encode().unwrap()).unwrap(),
			media
		);

		let start = StartVideoRequest {
			facing: CameraFacing::Front,
			max_duration_seconds: 120,
			camera_session_id: 3,
			record_audio: true,
		};
		assert_eq!(StartVideoRequest::decode(&start.encode()).unwrap(), start);

		let upload = UploadCapturedFileRequest {
			capture_file_id: "cap-001".to_owned(),
			upload_url: "https://storage.example.com/upload?sig=1".to_owned(),
			mime_type: "video/mp4".to_owned(),
			expected_sha256_hex: "b".repeat(64),
		};
		assert_eq!(
			UploadCapturedFileRequest::decode(&upload.encode().unwrap()).unwrap(),
			upload
		);

		let loc = CapturedLocation {
			latitude: 51.5074,
			longitude: -0.1278,
			accuracy_meters: 12.5,
			captured_at_ms: 1_760_000_000_000,
			is_mock: false,
		};
		assert_eq!(CapturedLocation::decode(&loc.encode()).unwrap(), loc);
	}
}
