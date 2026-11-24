//! Server-owned verifier settings. Callers cannot select a model, prompt, or URL.
//!
//! Values arrive already resolved. Monosecret injects them before the process
//! starts. This crate does not call `op` and does not read a vault.

use std::collections::HashMap;
use std::time::Duration;

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum ConfigError {
	#[error("{0}")]
	Invalid(&'static str),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VerifierMode {
	ManualReview,
	Cloud,
	OpenRouter,
}

/// A secret that debug output does not print.
#[derive(Clone, PartialEq, Eq)]
pub struct Secret(String);

impl Secret {
	pub fn expose(&self) -> &str {
		&self.0
	}
}

impl std::fmt::Debug for Secret {
	fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
		formatter.write_str("Secret([redacted])")
	}
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct VerifierConfig {
	pub mode: VerifierMode,
	pub endpoint: Option<String>,
	pub token: Option<Secret>,
	pub timeout: Duration,
	pub primary_model_id: Option<String>,
	pub council_model_ids: Vec<String>,
	pub require_zero_data_retention: bool,
	pub prompt_injection_guard: bool,
}

pub const GEMINI_FLASH_LITE: &str = "google/gemini-2.5-flash-lite";
pub const GEMINI_FLASH: &str = "google/gemini-2.5-flash";
pub const GEMMA: &str = "google/gemma-4-26b-a4b-it";
pub const GLM_FLASH: &str = "z-ai/glm-5.3-flash";
pub const DEEPSEEK_VISION: &str = "deepseek/deepseek-v4-flash-vision-exp";
pub const OPENROUTER_URL: &str = "https://openrouter.ai/api/v1/chat/completions";

const SUPPORTED: &[&str] = &[
	GEMINI_FLASH_LITE,
	GEMINI_FLASH,
	GEMMA,
	GLM_FLASH,
	DEEPSEEK_VISION,
];
const VIDEO_MODELS: &[&str] = &[GEMINI_FLASH_LITE, GEMINI_FLASH, GEMMA, GLM_FLASH];

impl VerifierConfig {
	pub fn from_resolved(
		environment: &HashMap<String, String>,
		token: Option<&str>,
		openrouter_api_key: Option<&str>,
	) -> Result<Self, ConfigError> {
		let mode = environment
			.get("VERILY_MEDIA_VERIFIER_MODE")
			.map(|value| value.trim().to_ascii_lowercase())
			.filter(|value| !value.is_empty())
			.unwrap_or_else(|| "manual-review".to_string());
		match mode.as_str() {
			"manual-review" => Ok(Self::manual()),
			"cloud" => Self::cloud(environment, token),
			"openrouter" => Self::openrouter(environment, openrouter_api_key),
			_ => Err(ConfigError::Invalid(
				"VERILY_MEDIA_VERIFIER_MODE must be manual-review, cloud, or openrouter",
			)),
		}
	}

	fn manual() -> Self {
		Self {
			mode: VerifierMode::ManualReview,
			endpoint: None,
			token: None,
			timeout: Duration::from_secs(90),
			primary_model_id: None,
			council_model_ids: Vec::new(),
			require_zero_data_retention: true,
			prompt_injection_guard: false,
		}
	}

	fn cloud(
		environment: &HashMap<String, String>,
		token: Option<&str>,
	) -> Result<Self, ConfigError> {
		let endpoint = https_endpoint(
			environment
				.get("VERILY_MEDIA_VERIFIER_URL")
				.map(String::as_str)
				.unwrap_or(""),
			"VERILY_MEDIA_VERIFIER_URL",
		)?;
		let token = token.unwrap_or("").trim();
		if token.is_empty() {
			return Err(ConfigError::Invalid(
				"VERILY_MEDIA_VERIFIER_TOKEN is required in cloud mode",
			));
		}
		Ok(Self {
			mode: VerifierMode::Cloud,
			endpoint: Some(endpoint),
			token: Some(Secret(token.to_string())),
			timeout: timeout(environment)?,
			primary_model_id: None,
			council_model_ids: Vec::new(),
			require_zero_data_retention: true,
			prompt_injection_guard: false,
		})
	}

	fn openrouter(
		environment: &HashMap<String, String>,
		openrouter_api_key: Option<&str>,
	) -> Result<Self, ConfigError> {
		let token = openrouter_api_key.unwrap_or("").trim();
		if token.is_empty() {
			return Err(ConfigError::Invalid(
				"VERILY_OPENROUTER_API_KEY is required in openrouter mode",
			));
		}
		let endpoint = https_endpoint(
			environment
				.get("VERILY_OPENROUTER_URL")
				.map(String::as_str)
				.unwrap_or(OPENROUTER_URL),
			"VERILY_OPENROUTER_URL",
		)?;
		let primary = environment
			.get("VERILY_OPENROUTER_PRIMARY_MODEL")
			.map(|value| value.trim().to_string())
			.filter(|value| !value.is_empty())
			.unwrap_or_else(|| GEMINI_FLASH_LITE.to_string());
		let council = environment
			.get("VERILY_OPENROUTER_COUNCIL_MODELS")
			.map(String::as_str)
			.unwrap_or(&format!("{GEMINI_FLASH_LITE},{GEMMA},{GLM_FLASH}"))
			.split(',')
			.map(str::trim)
			.filter(|value| !value.is_empty())
			.map(str::to_string)
			.collect::<Vec<_>>();
		if !SUPPORTED.contains(&primary.as_str())
			|| council
				.iter()
				.any(|model| !SUPPORTED.contains(&model.as_str()))
		{
			return Err(ConfigError::Invalid(
				"OpenRouter verification models must use the pinned supported model IDs",
			));
		}
		if council.len() != 3
			|| council
				.iter()
				.collect::<std::collections::HashSet<_>>()
				.len()
				!= 3
		{
			return Err(ConfigError::Invalid(
				"VERILY_OPENROUTER_COUNCIL_MODELS must contain three unique models",
			));
		}
		if council
			.iter()
			.any(|model| !VIDEO_MODELS.contains(&model.as_str()))
		{
			return Err(ConfigError::Invalid(
				"Council verification models must support video input",
			));
		}
		let zdr = match environment
			.get("VERILY_OPENROUTER_REQUIRE_ZDR")
			.map(|value| value.trim().to_ascii_lowercase())
			.as_deref()
			.unwrap_or("true")
		{
			"true" => true,
			"false" => false,
			_ => {
				return Err(ConfigError::Invalid(
					"VERILY_OPENROUTER_REQUIRE_ZDR must be true or false",
				));
			}
		};
		let guard = environment
			.get("VERILY_OPENROUTER_PROMPT_INJECTION_GUARD")
			.map(|value| value.trim().to_ascii_lowercase())
			.unwrap_or_default();
		if guard != "block" {
			return Err(ConfigError::Invalid(
				"VERILY_OPENROUTER_PROMPT_INJECTION_GUARD must be block",
			));
		}
		Ok(Self {
			mode: VerifierMode::OpenRouter,
			endpoint: Some(endpoint),
			token: Some(Secret(token.to_string())),
			timeout: timeout(environment)?,
			primary_model_id: Some(primary),
			council_model_ids: council,
			require_zero_data_retention: zdr,
			prompt_injection_guard: true,
		})
	}
}

fn https_endpoint(value: &str, name: &'static str) -> Result<String, ConfigError> {
	let value = value.trim();
	let Some(rest) = value.strip_prefix("https://") else {
		return Err(ConfigError::Invalid(name));
	};
	if rest.is_empty() || rest.contains(['?', '#', '@', ' ']) || rest.starts_with('/') {
		return Err(ConfigError::Invalid(name));
	}
	Ok(value.to_string())
}

fn timeout(environment: &HashMap<String, String>) -> Result<Duration, ConfigError> {
	let seconds = environment
		.get("VERILY_MEDIA_VERIFIER_TIMEOUT_SECONDS")
		.map(|value| value.trim().to_string())
		.unwrap_or_else(|| "90".to_string());
	match seconds.parse::<u64>() {
		Ok(seconds) if (5..=180).contains(&seconds) => Ok(Duration::from_secs(seconds)),
		_ => Err(ConfigError::Invalid(
			"VERILY_MEDIA_VERIFIER_TIMEOUT_SECONDS must be between 5 and 180",
		)),
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn manual_review_needs_no_secret_and_an_unknown_model_is_refused() {
		let config = VerifierConfig::from_resolved(&HashMap::new(), None, None).unwrap();
		assert_eq!(config.mode, VerifierMode::ManualReview);
		assert!(config.token.is_none());
		let mut env = HashMap::new();
		env.insert(
			"VERILY_MEDIA_VERIFIER_MODE".to_string(),
			"openrouter".to_string(),
		);
		env.insert(
			"VERILY_OPENROUTER_PRIMARY_MODEL".to_string(),
			"vendor/unpinned-model".to_string(),
		);
		env.insert(
			"VERILY_OPENROUTER_PROMPT_INJECTION_GUARD".to_string(),
			"block".to_string(),
		);
		assert!(VerifierConfig::from_resolved(&env, None, Some("key")).is_err());
	}

	#[test]
	fn openrouter_without_a_blocking_guard_fails_closed() {
		let mut env = HashMap::new();
		env.insert(
			"VERILY_MEDIA_VERIFIER_MODE".to_string(),
			"openrouter".to_string(),
		);
		env.insert(
			"VERILY_OPENROUTER_PROMPT_INJECTION_GUARD".to_string(),
			"log".to_string(),
		);
		assert!(VerifierConfig::from_resolved(&env, None, Some("key")).is_err());
		assert!(format!("{:?}", Secret("super-secret".to_string())).contains("redacted"));
		assert!(!format!("{:?}", Secret("super-secret".to_string())).contains("super-secret"));
	}
}
