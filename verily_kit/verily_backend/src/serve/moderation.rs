//! Content moderation, appeal resolution, pseudonymized abuse risk scoring,
//! and inference budget reservations.

use chrono::Duration;
use chrono::Utc;
use hmac::Hmac;
use hmac::Mac;
use leptoskit_auth::Account as AuthAccount;
use leptoskit_db::Connection;
use leptoskit_db::Id;
use leptoskit_db::Read;
use leptoskit_rpc as rpc;
use sha2::Sha256;
use verily_api::AppealItem;
use verily_api::AppealStatus;
use verily_api::AttemptStatus;
use verily_api::ModerationCaseRow as ModerationCaseDto;
use verily_rewards::schema::ActionRow;

use super::attempts::status_name;
use super::db;
use super::me;
use super::parse_id;
use super::require_active;
use super::review::is_reviewer;
use crate::schema::AbuseRiskRow;
use crate::schema::Appeal;
use crate::schema::AppealResolutionRow;
use crate::schema::Attempt;
use crate::schema::InferenceReservationRow;
use crate::schema::ModerationCaseRow;
use crate::schema::NewAbuseRiskRow;
use crate::schema::NewAppealResolutionRow;
use crate::schema::NewInferenceReservationRow;
use crate::schema::NewModerationAuditRow;
use crate::schema::NewModerationCaseRow;

type HmacSha256 = Hmac<Sha256>;

/// Default daily inference budget cap in micro-USD (\$25 / day).
const DEFAULT_DAILY_BUDGET_MICRO_USD: i64 = 25_000_000;

/// Checks whether an action is currently hidden by an active moderation hold.
pub async fn is_action_safety_held(
	connection: &impl Read,
	action_id: &str,
) -> Result<bool, rpc::Error> {
	let cases = ModerationCaseRow::query()
		.filter(|row| row.target_kind.eq("action") & row.target_id.eq(action_id))
		.all(connection)
		.await
		.map_err(db)?;
	Ok(cases
		.iter()
		.any(|c| matches!(c.status.as_str(), "held" | "removed")))
}

/// Pseudonymizes an account or device identifier using HMAC-SHA256 keyed by
/// `VERILY_ABUSE_RISK_SALT` so raw identifiers are not stored in risk tables.
///
/// # Panics
///
/// Never panics because HMAC-SHA256 accepts keys of any length.
#[must_use]
pub fn pseudonymize_subject(salt: &[u8], subject: &str) -> String {
	let mut mac = HmacSha256::new_from_slice(salt).expect("HMAC accepts any key length");
	mac.update(subject.as_bytes());
	let bytes = mac.finalize().into_bytes();
	let mut out = String::with_capacity(64);
	for b in bytes {
		use std::fmt::Write;
		let _ = write!(&mut out, "{b:02x}");
	}
	out
}

/// Records an abuse risk signal for a pseudonymized subject.
pub async fn record_abuse_risk(
	connection: &impl Connection,
	salt: &[u8],
	subject: &str,
	tier: &str,
	reason_code: &str,
	ttl_hours: Option<i64>,
) -> Result<(), rpc::Error> {
	let hash = pseudonymize_subject(salt, subject);
	let expires_at = ttl_hours.map(|h| Utc::now() + Duration::hours(h));
	NewAbuseRiskRow {
		subject_hash: hash,
		tier: tier.to_owned(),
		reason_code: reason_code.to_owned(),
		expires_at,
	}
	.insert(connection)
	.await
	.map_err(db)?;
	Ok(())
}

/// Returns whether a subject currently carries an active `blocked` risk tier.
pub async fn is_subject_blocked(
	connection: &impl Read,
	salt: &[u8],
	subject: &str,
) -> Result<bool, rpc::Error> {
	let hash = pseudonymize_subject(salt, subject);
	let now = Utc::now();
	let rows = AbuseRiskRow::query()
		.filter(|row| row.subject_hash.eq(hash))
		.all(connection)
		.await
		.map_err(db)?;
	Ok(rows
		.iter()
		.any(|r| r.tier == "blocked" && r.expires_at.is_none_or(|exp| exp > now)))
}

/// Reserves budget for one outbound AI verification call; returns `false` if
/// the daily inference cap would be exceeded.
pub async fn reserve_inference_call(
	connection: &impl Connection,
	model_id: &str,
	estimated_micro_usd: i64,
	daily_budget_micro_usd: Option<i64>,
) -> Result<bool, rpc::Error> {
	let cap = daily_budget_micro_usd.unwrap_or(DEFAULT_DAILY_BUDGET_MICRO_USD);
	let since = Utc::now() - Duration::hours(24);
	let recent = InferenceReservationRow::query()
		.filter(|row| row.created_at.gte(since))
		.all(connection)
		.await
		.map_err(db)?;
	let spent: i64 = recent
		.iter()
		.map(|r| r.settled_micro_usd.unwrap_or(r.estimated_micro_usd))
		.sum();
	if spent.saturating_add(estimated_micro_usd) > cap {
		return Ok(false);
	}
	NewInferenceReservationRow {
		model_id: model_id.to_owned(),
		estimated_micro_usd,
		settled_micro_usd: None,
	}
	.insert(connection)
	.await
	.map_err(db)?;
	Ok(true)
}

/// Participant's own appeals.
pub async fn list_my_appeals(cx: &rpc::QueryCx) -> rpc::Result<Vec<AppealItem>> {
	let participant = me(cx.context())?;
	let appeals = Appeal::query()
		.filter(|row| row.participant_id.eq(participant))
		.order_by(|row| row.created_at.desc())
		.limit(100)
		.all(cx.db())
		.await
		.map_err(db)?;
	build_appeal_items(cx.db(), appeals).await
}

/// Reviewer queue of open appeals (excluding the reviewer's own attempts).
pub async fn list_review_appeals(cx: &rpc::QueryCx) -> rpc::Result<Vec<AppealItem>> {
	let reviewer = me(cx.context())?;
	if !is_reviewer(cx.db(), reviewer).await? {
		return Ok(Vec::new());
	}
	let appeals = Appeal::query()
		.filter(|row| row.status.eq("open") & row.participant_id.ne(reviewer))
		.order_by(|row| row.created_at.asc())
		.limit(100)
		.all(cx.db())
		.await
		.map_err(db)?;
	build_appeal_items(cx.db(), appeals).await
}

/// Resolves an open appeal (`overturn = true` marks the attempt verified).
pub async fn resolve_appeal(
	cx: &rpc::MutationCx,
	appeal_id: String,
	overturn: bool,
	note: String,
) -> rpc::Result<AppealItem> {
	let reviewer = me(cx.context())?;
	require_active(cx.tx(), reviewer).await?;
	if !is_reviewer(cx.tx(), reviewer).await? {
		return Err(rpc::Error::forbidden("notReviewer"));
	}
	let note = note.trim();
	if note.is_empty() || note.chars().count() > 500 {
		return Err(rpc::Error::invalid("reviewNote"));
	}
	let id = Id::<Appeal>::from_uuid(parse_id(&appeal_id)?);
	let mut appeal = Appeal::query()
		.filter(|row| row.id.eq(id))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	if appeal.participant_id == reviewer {
		return Err(rpc::Error::forbidden("selfReview"));
	}
	if appeal.status != "open" {
		return Err(rpc::Error::conflict("alreadyResolved"));
	}
	let decision = if overturn { "overturned" } else { "upheld" };
	appeal.status = decision.to_owned();
	appeal.save(cx.tx()).await.map_err(db)?;

	NewAppealResolutionRow {
		appeal_id: appeal.id,
		resolved_by: reviewer,
		decision: decision.to_owned(),
		note: note.to_owned(),
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	if overturn
		&& let Some(mut attempt) = Attempt::query()
			.filter(|row| row.id.eq(appeal.attempt_id))
			.first(cx.tx())
			.await
			.map_err(db)?
	{
		status_name(AttemptStatus::Verified).clone_into(&mut attempt.status);
		attempt.verified_at = Some(Utc::now());
		attempt.rejection_code = None;
		attempt.save(cx.tx()).await.map_err(db)?;
		if let Ok(backend) = super::backend(cx.context())
			&& let Some(action) = ActionRow::query()
				.filter(|row| row.id.eq(attempt.action_id))
				.first(cx.tx())
				.await
				.map_err(db)?
		{
			super::notify_attempt_outcome(
				cx.tx(),
				backend,
				&action,
				&attempt,
				AttemptStatus::Verified,
			)
			.await?;
		}
	}

	let items = build_appeal_items(cx.tx(), vec![appeal]).await?;
	items
		.into_iter()
		.next()
		.ok_or_else(|| rpc::Error::not_found("notFound"))
}

/// Reports an action, attempt, account, or app for moderation review.
pub async fn report_content(
	cx: &rpc::MutationCx,
	target_kind: String,
	target_id: String,
	reason: String,
	notes: Option<String>,
) -> rpc::Result<ModerationCaseDto> {
	let reporter = me(cx.context())?;
	require_active(cx.tx(), reporter).await?;
	if !matches!(
		target_kind.as_str(),
		"action" | "attempt" | "account" | "app"
	) {
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	let target_id = target_id.trim().to_owned();
	let reason = reason.trim().to_owned();
	if target_id.is_empty() || target_id.len() > 64 || reason.is_empty() || reason.len() > 128 {
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	let clean_notes = notes
		.map(|n| n.trim().to_owned())
		.filter(|n| !n.is_empty() && n.chars().count() <= 1000);
	let row = NewModerationCaseRow {
		reporter_id: reporter,
		target_kind,
		target_id,
		reason: reason.clone(),
		status: "open".to_owned(),
		notes: clean_notes,
		assigned_moderator_id: None,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	NewModerationAuditRow {
		case_id: row.id,
		actor_id: reporter,
		action: "reported".to_owned(),
		note: reason,
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	Ok(case_dto(row))
}

/// Lists moderation cases filed by the signed-in account.
pub async fn list_my_moderation_cases(cx: &rpc::QueryCx) -> rpc::Result<Vec<ModerationCaseDto>> {
	let account = me(cx.context())?;
	let rows = ModerationCaseRow::query()
		.filter(|row| row.reporter_id.eq(account))
		.order_by(|row| row.created_at.desc())
		.limit(50)
		.all(cx.db())
		.await
		.map_err(db)?;
	Ok(rows.into_iter().map(case_dto).collect())
}

/// Lists open or appealed moderation cases for reviewers/moderators.
pub async fn list_moderation_queue(cx: &rpc::QueryCx) -> rpc::Result<Vec<ModerationCaseDto>> {
	let reviewer = me(cx.context())?;
	if !is_reviewer(cx.db(), reviewer).await? {
		return Ok(Vec::new());
	}
	let rows = ModerationCaseRow::query()
		.order_by(|row| row.created_at.asc())
		.limit(100)
		.all(cx.db())
		.await
		.map_err(db)?;
	Ok(rows
		.into_iter()
		.filter(|r| matches!(r.status.as_str(), "open" | "under_review" | "appealed"))
		.map(case_dto)
		.collect())
}

/// Applies a moderation decision (`held`, `cleared`, `removed`, `under_review`).
pub async fn review_moderation_case(
	cx: &rpc::MutationCx,
	case_id: String,
	new_status: String,
	note: String,
) -> rpc::Result<ModerationCaseDto> {
	let moderator = me(cx.context())?;
	require_active(cx.tx(), moderator).await?;
	if !is_reviewer(cx.tx(), moderator).await? {
		return Err(rpc::Error::forbidden("notReviewer"));
	}
	if !matches!(
		new_status.as_str(),
		"under_review" | "held" | "cleared" | "removed"
	) {
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	let note = note.trim();
	if note.is_empty() || note.chars().count() > 500 {
		return Err(rpc::Error::invalid("reviewNote"));
	}
	let id = Id::<ModerationCaseRow>::from_uuid(parse_id(&case_id)?);
	let mut case_row = ModerationCaseRow::query()
		.filter(|row| row.id.eq(id))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	case_row.status = new_status.clone();
	case_row.assigned_moderator_id = Some(moderator);
	case_row.notes = Some(note.to_owned());
	case_row.save(cx.tx()).await.map_err(db)?;

	NewModerationAuditRow {
		case_id: case_row.id,
		actor_id: moderator,
		action: new_status,
		note: note.to_owned(),
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	Ok(case_dto(case_row))
}

/// Appeals a moderation hold/removal on a case.
pub async fn appeal_moderation(
	cx: &rpc::MutationCx,
	case_id: String,
	reason: String,
) -> rpc::Result<ModerationCaseDto> {
	let account = me(cx.context())?;
	require_active(cx.tx(), account).await?;
	let reason = reason.trim();
	if reason.is_empty() || reason.chars().count() > 500 {
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	let id = Id::<ModerationCaseRow>::from_uuid(parse_id(&case_id)?);
	let mut case_row = ModerationCaseRow::query()
		.filter(|row| row.id.eq(id))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	if !matches!(case_row.status.as_str(), "held" | "removed") {
		return Err(rpc::Error::conflict("cannotAppeal"));
	}
	"appealed".clone_into(&mut case_row.status);
	case_row.save(cx.tx()).await.map_err(db)?;

	NewModerationAuditRow {
		case_id: case_row.id,
		actor_id: account,
		action: "appealed".to_owned(),
		note: reason.to_owned(),
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	Ok(case_dto(case_row))
}

async fn build_appeal_items(
	connection: &impl Read,
	appeals: Vec<Appeal>,
) -> Result<Vec<AppealItem>, rpc::Error> {
	let mut items = Vec::with_capacity(appeals.len());
	for appeal in appeals {
		let action_title = if let Some(attempt) = Attempt::query()
			.filter(|row| row.id.eq(appeal.attempt_id))
			.first(connection)
			.await
			.map_err(db)?
		{
			ActionRow::query()
				.filter(|row| row.id.eq(attempt.action_id))
				.first(connection)
				.await
				.map_err(db)?
				.map(|a| a.title)
				.unwrap_or_default()
		} else {
			String::new()
		};
		let resolution_note = AppealResolutionRow::query()
			.filter(|row| row.appeal_id.eq(appeal.id))
			.first(connection)
			.await
			.map_err(db)?
			.map(|r| r.note);
		let status = match appeal.status.as_str() {
			"open" => AppealStatus::Pending,
			"overturned" => AppealStatus::Accepted,
			"upheld" => AppealStatus::Rejected,
			_ => AppealStatus::Unavailable,
		};
		items.push(AppealItem {
			id: appeal.id.to_string(),
			attempt_id: appeal.attempt_id.to_string(),
			action_title,
			reason: appeal.reason,
			status,
			resolution_note,
		});
	}
	Ok(items)
}

fn case_dto(row: ModerationCaseRow) -> ModerationCaseDto {
	ModerationCaseDto {
		id: row.id.to_string(),
		target_kind: row.target_kind,
		target_id: row.target_id,
		reason: row.reason,
		status: row.status,
		notes: row.notes,
	}
}

#[allow(dead_code)]
fn _account_marker(_: Id<AuthAccount>) {}
