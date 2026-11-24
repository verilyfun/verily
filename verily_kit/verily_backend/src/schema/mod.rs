//! Verily's `leptoskit_db` schema: accounts, attempts, evidence, capture
//! windows, review decisions, appeals, and places, plus the
//! action and reward tables linked from `verily_rewards`.
//!
//! Tables are declared with `leptoskit_db` macros from leptoskit `main`. Auth
//! and `IdP` packs sit beside them. After changing a table, use
//! the `LeptosKit` CLI (never ad-hoc SQL scripts) from this package directory:
//!
//! ```sh
//! cd verily_kit/verily_backend
//! monosecret run --profile development -- leptoskit doctor
//! monosecret run --profile development -- leptoskit db migration create <name>
//! monosecret run --profile development -- leptoskit db check
//! monosecret run --profile development -- leptoskit db migrate
//! monosecret run --profile development -- leptoskit db status
//! monosecret run --profile development -- leptoskit dev
//! # `lk` is the same binary as `leptoskit`.
//! ```
//!
//! Domain crates own business logic against these rows. Action and reward
//! pool tables come from `verily_rewards` (path-dep); this host does not
//! redeclare them. `leptoskit_rpc` is packed there too, so this module only
//! packs auth and idp.

use leptoskit_db as _;
use leptoskit_db_macros as _;
use leptoskit_db_schema as _;

mod accounts;
mod apps;
mod attempts;
mod capture;
mod evidence;
mod moderation;
mod places;
mod review;
mod uploads;

pub use accounts::Account;
pub use accounts::AccountClosureRow;
pub use accounts::NewAccountClosureRow;
pub use apps::NewVerificationRequestRow;
pub use apps::NewVerilyAppConfirmationRow;
pub use apps::NewVerilyAppKeyRow;
pub use apps::NewVerilyAppLinkCodeRow;
pub use apps::NewVerilyAppLinkRow;
pub use apps::NewVerilyAppPullCheckRow;
pub use apps::NewVerilyAppRedirectUriRow;
pub use apps::NewVerilyAppRow;
pub use apps::NewVerilyAppWebhookDeliveryRow;
pub use apps::VerificationRequestRow;
pub use apps::VerilyAppConfirmationRow;
pub use apps::VerilyAppKeyRow;
pub use apps::VerilyAppLinkCodeRow;
pub use apps::VerilyAppLinkRow;
pub use apps::VerilyAppPullCheckRow;
pub use apps::VerilyAppRedirectUriRow;
pub use apps::VerilyAppRow;
pub use apps::VerilyAppWebhookDeliveryRow;
pub use attempts::Attempt;
pub use attempts::NewAttempt;
pub use capture::CaptureWindowRow;
pub use capture::NewCaptureWindowRow;
pub use capture::NewSpokenChallengeRow;
pub use capture::SpokenChallengeRow;
pub use evidence::Evidence;
pub use evidence::NewEvidence;
pub use moderation::AbuseRiskRow;
pub use moderation::AiUsageRow;
pub use moderation::AppealResolutionRow;
pub use moderation::InferenceReservationRow;
pub use moderation::ModerationAuditRow;
pub use moderation::ModerationCaseRow;
pub use moderation::NewAbuseRiskRow;
pub use moderation::NewAiUsageRow;
pub use moderation::NewAppealResolutionRow;
pub use moderation::NewInferenceReservationRow;
pub use moderation::NewModerationAuditRow;
pub use moderation::NewModerationCaseRow;
pub use places::ActionPlace;
pub use places::NewActionPlace;
pub use review::Appeal;
pub use review::EvidenceDecision;
pub use review::NewAppeal;
pub use review::NewEvidenceDecision;
pub use review::NewReviewer;
pub use review::Reviewer;
pub use uploads::ActionQrChallengeRow;
pub use uploads::AppAttestChallengeRow;
pub use uploads::AppAttestKeyRow;
pub use uploads::DeviceCheckAuditRow;
pub use uploads::EvidenceUploadReservationRow;
pub use uploads::EvidenceVerificationJobRow;
pub use uploads::EvidenceVerificationVoteRow;
pub use uploads::NewActionQrChallengeRow;
pub use uploads::NewAppAttestChallengeRow;
pub use uploads::NewAppAttestKeyRow;
pub use uploads::NewDeviceCheckAuditRow;
pub use uploads::NewEvidenceUploadReservationRow;
pub use uploads::NewEvidenceVerificationJobRow;
pub use uploads::NewEvidenceVerificationVoteRow;
pub use verily_rewards::schema::ActionRow;
pub use verily_rewards::schema::PayoutWalletRow;
pub use verily_rewards::schema::RewardPayoutRow;
pub use verily_rewards::schema::RewardPoolRow;
pub use verily_rewards::schema::WalletLinkChallengeRow;

// Sign-in tables under `auth`, and the OAuth / OIDC provider under `idp`.
// `leptoskit_rpc` is packed by `verily_rewards` once that crate is linked.
leptoskit_db::packs!(leptoskit_auth, leptoskit_idp);

leptoskit_db::export_schema!();

/// Every migration, embedded for the host to apply at startup.
pub static MIGRATIONS: &[leptoskit_db::Migration] = leptoskit_db::migrations!("migrations");

/// Postgres-shaped migrations for multi-server deploys (`PostGIS` host).
pub static POSTGRES_MIGRATIONS: &[leptoskit_db::Migration] =
	leptoskit_db::migrations!("migrations-postgres");
