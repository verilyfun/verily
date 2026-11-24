//! Evidence object storage backends: Backblaze B2 (S3v4) and local dev store.
//!
//! Evidence originals are private, hash-pinned to an immutable storage version,
//! and never modified. Derived renditions may be watermarked; originals never.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use chrono::{DateTime, Utc};
use hmac::{Hmac, Mac};
use sha2::{Digest, Sha256};

use crate::evidence::Inspection;

type HmacSha256 = Hmac<Sha256>;
const MAX_EVIDENCE_READ_BYTES: usize = 128 * 1024 * 1024;

/// Storage configuration loaded from Monosecret-resolved environment variables.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StorageConfig {
	Local {
		root: PathBuf,
		public_origin: String,
	},
	BackblazeB2 {
		bucket: String,
		region: String,
		endpoint: String,
		access_key_id: String,
		secret_access_key: String,
	},
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PresignedUpload {
	pub object_key: String,
	pub upload_url: String,
	pub headers: BTreeMap<String, String>,
	pub expires_at: DateTime<Utc>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PresignedRead {
	pub url: String,
	pub expires_at: DateTime<Utc>,
}

#[derive(Debug, thiserror::Error)]
pub enum StorageError {
	#[error("invalid storage configuration: {0}")]
	Config(&'static str),
	#[error("invalid object key or version")]
	InvalidKey,
	#[error("evidence object version not found")]
	NotFound,
	#[error("storage transport error: {0}")]
	Transport(String),
	#[error("storage I/O error: {0}")]
	Io(#[from] std::io::Error),
}

impl StorageConfig {
	/// Parse storage configuration from environment pairs.
	///
	/// Defaults to local filesystem storage in development when `VERILY_EVIDENCE_STORAGE_MODE`
	/// is unset or `"local"`, and fails closed when `"b2"` / `"backblaze"` is selected with
	/// missing credentials or insecure endpoints.
	pub fn from_env<'a, I>(
		vars: I,
		default_local_dir: impl Into<PathBuf>,
	) -> Result<Self, StorageError>
	where
		I: IntoIterator<Item = (&'a str, &'a str)>,
	{
		let map: BTreeMap<&str, &str> = vars.into_iter().collect();
		let mode = map
			.get("VERILY_EVIDENCE_STORAGE_MODE")
			.copied()
			.unwrap_or("local")
			.trim()
			.to_ascii_lowercase();
		match mode.as_str() {
			"" | "local" => {
				let root = map
					.get("VERILY_LOCAL_EVIDENCE_DIR")
					.copied()
					.map(str::trim)
					.filter(|s| !s.is_empty())
					.map_or_else(|| default_local_dir.into(), PathBuf::from);
				let public_origin = map
					.get("VERILY_API_ORIGIN")
					.copied()
					.map(str::trim)
					.filter(|s| !s.is_empty())
					.unwrap_or("http://127.0.0.1:8184")
					.trim_end_matches('/')
					.to_owned();
				Ok(Self::Local {
					root,
					public_origin,
				})
			}
			"b2" | "backblaze" | "s3" => {
				let get_req = |k: &str| -> Result<String, StorageError> {
					map.get(k)
						.copied()
						.map(str::trim)
						.filter(|s| !s.is_empty())
						.map(str::to_owned)
						.ok_or(StorageError::Config("missing Backblaze B2 configuration"))
				};
				let bucket = get_req("VERILY_B2_BUCKET")?;
				let region = get_req("VERILY_B2_REGION")?;
				let endpoint = get_req("VERILY_B2_ENDPOINT")?;
				if !endpoint.starts_with("https://") {
					return Err(StorageError::Config("B2 endpoint must use https://"));
				}
				let access_key_id = get_req("VERILY_B2_KEY_ID")?;
				let secret_access_key = get_req("VERILY_B2_APPLICATION_KEY")?;
				Ok(Self::BackblazeB2 {
					bucket,
					region,
					endpoint: endpoint.trim_end_matches('/').to_owned(),
					access_key_id,
					secret_access_key,
				})
			}
			_ => Err(StorageError::Config("unknown VERILY_EVIDENCE_STORAGE_MODE")),
		}
	}
}

/// Active immutable evidence storage backend.
#[derive(Debug, Clone)]
pub enum EvidenceStore {
	Local(LocalEvidenceStorage),
	BackblazeB2(BackblazeB2Storage),
}

impl EvidenceStore {
	#[must_use]
	pub fn from_config(config: StorageConfig) -> Self {
		match config {
			StorageConfig::Local {
				root,
				public_origin,
			} => Self::Local(LocalEvidenceStorage::new(root, public_origin)),
			StorageConfig::BackblazeB2 {
				bucket,
				region,
				endpoint,
				access_key_id,
				secret_access_key,
			} => Self::BackblazeB2(BackblazeB2Storage {
				bucket,
				region,
				endpoint,
				access_key_id,
				secret_access_key,
				http: reqwest::Client::new(),
			}),
		}
	}

	pub fn presign_put(
		&self,
		object_key: &str,
		mime_type: &str,
		now: DateTime<Utc>,
		ttl_seconds: u32,
	) -> Result<PresignedUpload, StorageError> {
		validate_object_key(object_key)?;
		match self {
			Self::Local(local) => local.presign_put(object_key, mime_type, now, ttl_seconds),
			Self::BackblazeB2(b2) => b2.presign_put(object_key, mime_type, now, ttl_seconds),
		}
	}

	pub fn presign_get_version(
		&self,
		object_key: &str,
		version_id: &str,
		now: DateTime<Utc>,
		ttl_seconds: u32,
	) -> Result<PresignedRead, StorageError> {
		validate_object_key(object_key)?;
		validate_version_id(version_id)?;
		match self {
			Self::Local(local) => {
				local.presign_get_version(object_key, version_id, now, ttl_seconds)
			}
			Self::BackblazeB2(b2) => {
				b2.presign_get_version(object_key, version_id, now, ttl_seconds)
			}
		}
	}

	pub async fn inspect_version(
		&self,
		object_key: &str,
		version_id: &str,
	) -> Result<Inspection, StorageError> {
		validate_object_key(object_key)?;
		validate_version_id(version_id)?;
		match self {
			Self::Local(local) => local.inspect_version(object_key, version_id),
			Self::BackblazeB2(b2) => b2.inspect_version(object_key, version_id).await,
		}
	}

	/// Read immutable original bytes and content type for a pinned storage version
	/// (bounded to 128 MiB so background workers cannot OOM).
	pub async fn read_version_bytes(
		&self,
		object_key: &str,
		version_id: &str,
	) -> Result<(Vec<u8>, String), StorageError> {
		validate_object_key(object_key)?;
		validate_version_id(version_id)?;
		match self {
			Self::Local(local) => {
				let (bytes, mime) = local.read_bytes(object_key, version_id)?;
				if bytes.len() > MAX_EVIDENCE_READ_BYTES {
					return Err(StorageError::Transport(
						"evidence object exceeds maximum replay byte limit".to_owned(),
					));
				}
				Ok((bytes, mime))
			}
			Self::BackblazeB2(b2) => b2.read_version_bytes(object_key, version_id).await,
		}
	}

	pub async fn delete_version(
		&self,
		object_key: &str,
		version_id: &str,
	) -> Result<(), StorageError> {
		validate_object_key(object_key)?;
		validate_version_id(version_id)?;
		match self {
			Self::Local(local) => local.delete_version(object_key, version_id),
			Self::BackblazeB2(b2) => b2.delete_version(object_key, version_id).await,
		}
	}

	/// Verify that a production B2 bucket is reachable and configured privately.
	pub async fn production_preflight(&self) -> Result<(), StorageError> {
		match self {
			Self::Local(_) => Err(StorageError::Config(
				"local evidence storage cannot be used in production",
			)),
			Self::BackblazeB2(b2) => b2.preflight().await,
		}
	}
}

/// Development & test immutable versioned filesystem evidence store.
#[derive(Debug, Clone)]
pub struct LocalEvidenceStorage {
	root: PathBuf,
	public_origin: String,
}

impl LocalEvidenceStorage {
	#[must_use]
	pub fn new(root: PathBuf, public_origin: String) -> Self {
		Self {
			root,
			public_origin,
		}
	}

	/// Store immutable original bytes and return the newly minted `version_id` and SHA-256.
	pub fn put_bytes(
		&self,
		object_key: &str,
		mime_type: &str,
		bytes: &[u8],
	) -> Result<(String, Inspection), StorageError> {
		validate_object_key(object_key)?;
		let digest = sha256_hex(bytes);
		let version_id = format!("v1-{}", &digest[..24]);
		let path = self.version_path(object_key, &version_id)?;
		if let Some(parent) = path.parent() {
			fs::create_dir_all(parent)?;
		}
		// Never overwrite an existing immutable version.
		if !path.exists() {
			fs::write(&path, bytes)?;
			fs::write(self.meta_path(&path), mime_type.as_bytes())?;
		}
		Ok((
			version_id.clone(),
			Inspection {
				version_id,
				byte_length: bytes.len() as u64,
				sha256_digest: digest,
				content_type: mime_type.to_owned(),
			},
		))
	}

	pub fn read_bytes(
		&self,
		object_key: &str,
		version_id: &str,
	) -> Result<(Vec<u8>, String), StorageError> {
		let path = self.version_path(object_key, version_id)?;
		if !path.is_file() {
			return Err(StorageError::NotFound);
		}
		let bytes = fs::read(&path)?;
		let mime = fs::read_to_string(self.meta_path(&path))
			.unwrap_or_else(|_| "application/octet-stream".to_owned());
		Ok((bytes, mime))
	}

	pub fn version_file_path(
		&self,
		object_key: &str,
		version_id: &str,
	) -> Result<PathBuf, StorageError> {
		self.version_path(object_key, version_id)
	}

	fn presign_put(
		&self,
		object_key: &str,
		mime_type: &str,
		now: DateTime<Utc>,
		ttl_seconds: u32,
	) -> Result<PresignedUpload, StorageError> {
		let expires_at = now + chrono::Duration::seconds(i64::from(ttl_seconds));
		let mut headers = BTreeMap::new();
		headers.insert("content-type".to_owned(), mime_type.to_owned());
		Ok(PresignedUpload {
			object_key: object_key.to_owned(),
			upload_url: format!(
				"{}/_verily/local-evidence/{}",
				self.public_origin, object_key
			),
			headers,
			expires_at,
		})
	}

	fn presign_get_version(
		&self,
		object_key: &str,
		version_id: &str,
		now: DateTime<Utc>,
		ttl_seconds: u32,
	) -> Result<PresignedRead, StorageError> {
		let expires_at = now + chrono::Duration::seconds(i64::from(ttl_seconds));
		Ok(PresignedRead {
			url: format!(
				"{}/_verily/local-evidence/{}?versionId={}",
				self.public_origin, object_key, version_id
			),
			expires_at,
		})
	}

	fn inspect_version(
		&self,
		object_key: &str,
		version_id: &str,
	) -> Result<Inspection, StorageError> {
		let (bytes, mime) = self.read_bytes(object_key, version_id)?;
		Ok(Inspection {
			version_id: version_id.to_owned(),
			byte_length: bytes.len() as u64,
			sha256_digest: sha256_hex(&bytes),
			content_type: mime,
		})
	}

	fn delete_version(&self, object_key: &str, version_id: &str) -> Result<(), StorageError> {
		let path = self.version_path(object_key, version_id)?;
		let _ = fs::remove_file(&path);
		let _ = fs::remove_file(self.meta_path(&path));
		Ok(())
	}

	fn version_path(&self, object_key: &str, version_id: &str) -> Result<PathBuf, StorageError> {
		validate_object_key(object_key)?;
		validate_version_id(version_id)?;
		let safe_key = object_key.replace('/', "__");
		Ok(self.root.join(format!("{safe_key}__{version_id}.bin")))
	}

	fn meta_path(&self, path: &Path) -> PathBuf {
		path.with_extension("mime")
	}
}

/// Production Backblaze B2 S3-compatible storage using AWS Signature V4.
#[derive(Debug, Clone)]
pub struct BackblazeB2Storage {
	pub bucket: String,
	pub region: String,
	pub endpoint: String,
	pub access_key_id: String,
	pub secret_access_key: String,
	http: reqwest::Client,
}

impl BackblazeB2Storage {
	fn host(&self) -> Result<String, StorageError> {
		let parsed = url::Url::parse(&self.endpoint)
			.map_err(|_| StorageError::Config("invalid B2 endpoint URL"))?;
		let host = parsed
			.host_str()
			.ok_or(StorageError::Config("missing host in B2 endpoint"))?;
		Ok(match parsed.port() {
			Some(port) => format!("{host}:{port}"),
			None => host.to_owned(),
		})
	}

	/// Generate an AWS Signature V4 presigned PUT URL for uploading one original.
	pub fn presign_put(
		&self,
		object_key: &str,
		mime_type: &str,
		now: DateTime<Utc>,
		ttl_seconds: u32,
	) -> Result<PresignedUpload, StorageError> {
		let url = self.presign_s3v4("PUT", object_key, None, now, ttl_seconds)?;
		let mut headers = BTreeMap::new();
		headers.insert("content-type".to_owned(), mime_type.to_owned());
		Ok(PresignedUpload {
			object_key: object_key.to_owned(),
			upload_url: url,
			headers,
			expires_at: now + chrono::Duration::seconds(i64::from(ttl_seconds)),
		})
	}

	/// Generate an AWS Signature V4 presigned GET URL pinned to `versionId`.
	pub fn presign_get_version(
		&self,
		object_key: &str,
		version_id: &str,
		now: DateTime<Utc>,
		ttl_seconds: u32,
	) -> Result<PresignedRead, StorageError> {
		let url = self.presign_s3v4("GET", object_key, Some(version_id), now, ttl_seconds)?;
		Ok(PresignedRead {
			url,
			expires_at: now + chrono::Duration::seconds(i64::from(ttl_seconds)),
		})
	}

	/// Download an immutable object version and return its raw bytes and content type
	/// (bounded to 128 MiB).
	pub async fn read_version_bytes(
		&self,
		object_key: &str,
		version_id: &str,
	) -> Result<(Vec<u8>, String), StorageError> {
		let read = self.presign_get_version(object_key, version_id, Utc::now(), 120)?;
		let resp = self
			.http
			.get(&read.url)
			.send()
			.await
			.map_err(|e| StorageError::Transport(e.to_string()))?;
		if resp.status() == reqwest::StatusCode::NOT_FOUND {
			return Err(StorageError::NotFound);
		}
		if !resp.status().is_success() {
			return Err(StorageError::Transport(format!("HTTP {}", resp.status())));
		}
		if let Some(len) = resp.content_length()
			&& len as usize > MAX_EVIDENCE_READ_BYTES
		{
			return Err(StorageError::Transport(
				"evidence object exceeds maximum replay byte limit".to_owned(),
			));
		}
		let content_type = resp
			.headers()
			.get(reqwest::header::CONTENT_TYPE)
			.and_then(|v| v.to_str().ok())
			.unwrap_or("application/octet-stream")
			.to_owned();
		let bytes = resp
			.bytes()
			.await
			.map_err(|e| StorageError::Transport(e.to_string()))?;
		if bytes.len() > MAX_EVIDENCE_READ_BYTES {
			return Err(StorageError::Transport(
				"evidence object exceeds maximum replay byte limit".to_owned(),
			));
		}
		Ok((bytes.to_vec(), content_type))
	}

	/// Download an immutable object version and compute its exact SHA-256 and byte length.
	pub async fn inspect_version(
		&self,
		object_key: &str,
		version_id: &str,
	) -> Result<Inspection, StorageError> {
		let (bytes, content_type) = self.read_version_bytes(object_key, version_id).await?;
		Ok(Inspection {
			version_id: version_id.to_owned(),
			byte_length: bytes.len() as u64,
			sha256_digest: sha256_hex(&bytes),
			content_type,
		})
	}

	/// Permanently delete a specific immutable version (cleanup / retention expiry).
	pub async fn delete_version(
		&self,
		object_key: &str,
		version_id: &str,
	) -> Result<(), StorageError> {
		let url = self.presign_s3v4("DELETE", object_key, Some(version_id), Utc::now(), 120)?;
		let resp = self
			.http
			.delete(&url)
			.send()
			.await
			.map_err(|e| StorageError::Transport(e.to_string()))?;
		if !resp.status().is_success() && resp.status() != reqwest::StatusCode::NOT_FOUND {
			return Err(StorageError::Transport(format!("HTTP {}", resp.status())));
		}
		Ok(())
	}

	/// Preflight check: verify the bucket exists, is reachable with configured credentials,
	/// and has versioning enabled (`?versioning`).
	pub async fn preflight(&self) -> Result<(), StorageError> {
		let url = self.presign_bucket_query("GET", "versioning", Utc::now(), 60)?;
		let resp = self
			.http
			.get(&url)
			.send()
			.await
			.map_err(|e| StorageError::Transport(e.to_string()))?;
		if !resp.status().is_success() {
			return Err(StorageError::Transport(format!(
				"bucket preflight failed with HTTP {}",
				resp.status()
			)));
		}
		let body = resp
			.text()
			.await
			.map_err(|e| StorageError::Transport(e.to_string()))?;
		if !body.contains("<Status>Enabled</Status>") {
			return Err(StorageError::Config(
				"Backblaze B2 evidence bucket must have object versioning enabled",
			));
		}
		Ok(())
	}

	fn presign_s3v4(
		&self,
		method: &str,
		object_key: &str,
		version_id: Option<&str>,
		now: DateTime<Utc>,
		ttl_seconds: u32,
	) -> Result<String, StorageError> {
		let host = self.host()?;
		let canonical_uri = format!(
			"/{}/{}",
			uri_encode_path(&self.bucket),
			uri_encode_path(object_key)
		);
		let mut extra = Vec::new();
		if let Some(vid) = version_id {
			extra.push(("versionId".to_owned(), vid.to_owned()));
		}
		self.sign_presigned(method, &host, &canonical_uri, extra, now, ttl_seconds)
	}

	fn presign_bucket_query(
		&self,
		method: &str,
		subresource: &str,
		now: DateTime<Utc>,
		ttl_seconds: u32,
	) -> Result<String, StorageError> {
		let host = self.host()?;
		let canonical_uri = format!("/{}", uri_encode_path(&self.bucket));
		self.sign_presigned(
			method,
			&host,
			&canonical_uri,
			vec![(subresource.to_owned(), String::new())],
			now,
			ttl_seconds,
		)
	}

	fn sign_presigned(
		&self,
		method: &str,
		host: &str,
		canonical_uri: &str,
		mut extra_query: Vec<(String, String)>,
		now: DateTime<Utc>,
		ttl_seconds: u32,
	) -> Result<String, StorageError> {
		let amz_date = now.format("%Y%m%dT%H%M%SZ").to_string();
		let date_stamp = now.format("%Y%m%d").to_string();
		let credential_scope = format!("{date_stamp}/{}/s3/aws4_request", self.region);
		let credential = format!("{}/{credential_scope}", self.access_key_id);
		let expires = ttl_seconds.clamp(1, 604_800).to_string();

		extra_query.push(("X-Amz-Algorithm".to_owned(), "AWS4-HMAC-SHA256".to_owned()));
		extra_query.push(("X-Amz-Credential".to_owned(), credential));
		extra_query.push(("X-Amz-Date".to_owned(), amz_date.clone()));
		extra_query.push(("X-Amz-Expires".to_owned(), expires));
		extra_query.push(("X-Amz-SignedHeaders".to_owned(), "host".to_owned()));
		extra_query.sort_by(|a, b| a.0.cmp(&b.0).then(a.1.cmp(&b.1)));

		let canonical_query = extra_query
			.iter()
			.map(|(k, v)| format!("{}={}", uri_encode_component(k), uri_encode_component(v)))
			.collect::<Vec<_>>()
			.join("&");
		let canonical_headers = format!("host:{host}\n");
		let canonical_request = format!(
			"{method}\n{canonical_uri}\n{canonical_query}\n{canonical_headers}\nhost\nUNSIGNED-PAYLOAD"
		);
		let string_to_sign = format!(
			"AWS4-HMAC-SHA256\n{amz_date}\n{credential_scope}\n{}",
			sha256_hex(canonical_request.as_bytes())
		);
		let k_date = hmac_sha256(
			format!("AWS4{}", self.secret_access_key).as_bytes(),
			date_stamp.as_bytes(),
		);
		let k_region = hmac_sha256(&k_date, self.region.as_bytes());
		let k_service = hmac_sha256(&k_region, b"s3");
		let k_signing = hmac_sha256(&k_service, b"aws4_request");
		let signature = hex_encode(&hmac_sha256(&k_signing, string_to_sign.as_bytes()));

		Ok(format!(
			"{}{}?{}&X-Amz-Signature={}",
			self.endpoint, canonical_uri, canonical_query, signature
		))
	}
}

fn validate_object_key(key: &str) -> Result<(), StorageError> {
	if key.is_empty()
		|| key.len() > 256
		|| key.starts_with('/')
		|| key.contains("..")
		|| key.contains('\\')
		|| key
			.bytes()
			.any(|b| b.is_ascii_control() || b == b'?' || b == b'#')
	{
		return Err(StorageError::InvalidKey);
	}
	Ok(())
}

fn validate_version_id(version_id: &str) -> Result<(), StorageError> {
	if version_id.is_empty()
		|| version_id.len() > 128
		|| version_id
			.chars()
			.any(|c| c.is_ascii_control() || matches!(c, '/' | '\\' | '?' | '#' | '&' | '='))
	{
		return Err(StorageError::InvalidKey);
	}
	Ok(())
}

fn hmac_sha256(key: &[u8], data: &[u8]) -> [u8; 32] {
	let mut mac = HmacSha256::new_from_slice(key).expect("HMAC accepts any key length");
	mac.update(data);
	mac.finalize().into_bytes().into()
}

fn sha256_hex(bytes: &[u8]) -> String {
	hex_encode(&Sha256::digest(bytes))
}

fn hex_encode(bytes: &[u8]) -> String {
	let mut out = String::with_capacity(bytes.len() * 2);
	for b in bytes {
		use std::fmt::Write as _;
		let _ = write!(out, "{b:02x}");
	}
	out
}

fn uri_encode_component(input: &str) -> String {
	let mut out = String::with_capacity(input.len());
	for byte in input.bytes() {
		if byte.is_ascii_alphanumeric() || matches!(byte, b'-' | b'_' | b'.' | b'~') {
			out.push(byte as char);
		} else {
			use std::fmt::Write as _;
			let _ = write!(out, "%{byte:02X}");
		}
	}
	out
}

fn uri_encode_path(input: &str) -> String {
	input
		.split('/')
		.map(uri_encode_component)
		.collect::<Vec<_>>()
		.join("/")
}

#[cfg(test)]
mod tests {
	use super::*;

	#[tokio::test]
	async fn local_storage_pins_immutable_versions_and_deletes_cleanly() {
		let dir = std::env::temp_dir().join(format!("verily_store_test_{}", std::process::id()));
		let _ = fs::remove_dir_all(&dir);
		let local = LocalEvidenceStorage::new(dir.clone(), "http://127.0.0.1:8184".to_owned());
		let (vid, info) = local
			.put_bytes("evidence/att-1/req-1.jpg", "image/jpeg", b"hello-proof")
			.unwrap();
		assert_eq!(info.byte_length, 11);
		assert_eq!(info.version_id, vid);

		let store = EvidenceStore::Local(local);
		let (raw_bytes, raw_mime) = store
			.read_version_bytes("evidence/att-1/req-1.jpg", &vid)
			.await
			.unwrap();
		assert_eq!(raw_bytes, b"hello-proof");
		assert_eq!(raw_mime, "image/jpeg");
		let inspected = store
			.inspect_version("evidence/att-1/req-1.jpg", &vid)
			.await
			.unwrap();
		assert_eq!(inspected.sha256_digest, info.sha256_digest);
		let read = store
			.presign_get_version("evidence/att-1/req-1.jpg", &vid, Utc::now(), 120)
			.unwrap();
		assert!(read.url.contains(&format!("versionId={vid}")));

		store
			.delete_version("evidence/att-1/req-1.jpg", &vid)
			.await
			.unwrap();
		assert!(matches!(
			store
				.read_version_bytes("evidence/att-1/req-1.jpg", &vid)
				.await,
			Err(StorageError::NotFound)
		));
		assert!(matches!(
			store
				.inspect_version("evidence/att-1/req-1.jpg", &vid)
				.await,
			Err(StorageError::NotFound)
		));
		let _ = fs::remove_dir_all(&dir);
	}

	#[test]
	fn b2_presign_generates_sigv4_version_pinned_https_url() {
		let cfg = StorageConfig::from_env(
			[
				("VERILY_EVIDENCE_STORAGE_MODE", "b2"),
				("VERILY_B2_BUCKET", "verily-private-evidence"),
				("VERILY_B2_REGION", "us-west-004"),
				(
					"VERILY_B2_ENDPOINT",
					"https://s3.us-west-004.backblazeb2.com",
				),
				("VERILY_B2_KEY_ID", "keyid123"),
				("VERILY_B2_APPLICATION_KEY", "secret456"),
			],
			"/tmp",
		)
		.unwrap();
		let store = EvidenceStore::from_config(cfg);
		let read = store
			.presign_get_version("att/ev.mp4", "ver_abc123", Utc::now(), 300)
			.unwrap();
		assert!(read.url.starts_with(
			"https://s3.us-west-004.backblazeb2.com/verily-private-evidence/att/ev.mp4?"
		));
		assert!(read.url.contains("versionId=ver_abc123"));
		assert!(read.url.contains("X-Amz-Algorithm=AWS4-HMAC-SHA256"));
		assert!(read.url.contains("X-Amz-Signature="));
		// Must be accepted by OpenRouter's IssuedMediaUrl validator!
		assert!(crate::openrouter::IssuedMediaUrl::issue(&read.url, "ver_abc123").is_some());
	}
}
