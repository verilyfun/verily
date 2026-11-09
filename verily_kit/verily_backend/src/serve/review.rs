//! A person deciding proof, and a participant asking for another look.
//!
//! Only accounts Verily granted review see the queue, and never their own
//! proof in it. A model verdict is not this: a decision here is a person's,
//! and it is the only path that accepts proof the verifier sent to review.

use leptoskit_auth::Account as AuthAccount;
use leptoskit_db::Connection;
use leptoskit_db::Id;
use leptoskit_db::Read;
use leptoskit_rpc as rpc;
use verily_api::AppealReceipt;
use verily_api::AttemptStatus;
use verily_api::ReviewDecision;
use verily_api::ReviewRow;
use verily_rewards::ops::into_rpc;
use verily_rewards::schema::ActionRow;
use verily_rewards::schema::RewardPayoutRow;
use verily_shared::EvidenceDecisionStatus;
use verily_shared::RewardPayoutStatus;

use super::attempts::latest_decision;
use super::attempts::owned_attempt;
use super::attempts::record_decision;
use super::attempts::settle;
use super::attempts::status_name;
use super::attempts::status_of;
use super::backend;
use super::db;
use super::me;
use super::name;
use super::parse_id;
use super::proof_kind;
use super::requirements;
use crate::schema::Appeal;
use crate::schema::Attempt;
use crate::schema::Evidence;
use crate::schema::NewAppeal;
use crate::schema::NewReviewer;
use crate::schema::Reviewer;

/// Longest appeal a participant may write.
const APPEAL_LENGTH: usize = 1000;

/// Lets `account` decide proof sent to a person. Server code only, such as
/// an administrator's tool; no operation grants it. Granting twice is fine.
///
/// # Errors
///
/// When the database refuses the row.
pub async fn grant_reviewer(
	connection: &impl Connection,
	account: Id<AuthAccount>,
) -> Result<(), leptoskit_db::DbError> {
	let granted = Reviewer::query()
		.filter(|row| row.account_id.eq(account))
		.exists(connection)
		.await?;
	if !granted {
		NewReviewer {
			account_id: account,
		}
		.insert(connection)
		.await?;
	}
	Ok(())
}

/// Proof waiting for a person, oldest first, for a reviewer. Anyone else
/// gets an empty queue: there is nothing here they may decide.
pub async fn list_review_queue(cx: &rpc::QueryCx) -> rpc::Result<Vec<ReviewRow>> {
	let reviewer = me(cx.context())?;
	if !is_reviewer(cx.db(), reviewer).await? {
		return Ok(Vec::new());
	}
	let pending = status_name(AttemptStatus::PendingReview);
	let attempts = Attempt::query()
		.filter(|row| row.status.eq(pending) & row.participant_id.ne(reviewer))
		.order_by(|row| row.submitted_at.asc())
		.limit(100)
		.all(cx.db())
		.await
		.map_err(db)?;
	let mut queue = Vec::new();
	for attempt in attempts {
		let Some(action) = ActionRow::query()
			.filter(|row| row.id.eq(attempt.action_id))
			.first(cx.db())
			.await
			.map_err(db)?
		else {
			continue;
		};
		let requirements = requirements(&action)?;
		let evidence = Evidence::query()
			.filter(|row| row.attempt_id.eq(attempt.id))
			.order_by(|row| row.submitted_at.asc())
			.all(cx.db())
			.await
			.map_err(db)?;
		for evidence in evidence {
			if latest_decision(cx.db(), evidence.id).await?
				!= Some(EvidenceDecisionStatus::ManualReview)
			{
				continue;
			}
			let Some(requirement) = requirements
				.iter()
				.find(|requirement| requirement.id.to_string() == evidence.requirement_key)
			else {
				continue;
			};
			queue.push(ReviewRow {
				id: evidence.id.to_string(),
				creator: action.creator_display_name.clone(),
				requirement: requirement.title.clone(),
				kind: proof_kind(requirement.kind),
				needs_person: true,
			});
		}
	}
	Ok(queue)
}

/// A reviewer's accept or reject of one piece of proof, with a note.
///
/// The reviewer must hold review, may not decide their own proof, and may
/// decide only proof that is still waiting for a person. The attempt then
/// moves on from the decision; an accepted proof that earns a payout above
/// the review threshold counts as a person's acceptance of that payout.
pub async fn review_attempt(
	cx: &rpc::MutationCx,
	review_id: String,
	accept: bool,
	note: String,
) -> rpc::Result<ReviewDecision> {
	let reviewer = me(cx.context())?;
	let backend = backend(cx.context())?;
	if !is_reviewer(cx.tx(), reviewer).await? {
		return Err(rpc::Error::forbidden("notReviewer"));
	}
	let decision = if accept {
		EvidenceDecisionStatus::Accepted
	} else {
		EvidenceDecisionStatus::Rejected
	};
	let note = backend
		.verification
		.resolve_review(decision, &note)
		.map_err(|_| rpc::Error::invalid("reviewNote"))?
		.to_owned();

	let evidence_id = Id::<Evidence>::from_uuid(parse_id(&review_id)?);
	let evidence = Evidence::query()
		.filter(|row| row.id.eq(evidence_id))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	let mut attempt = Attempt::query()
		.filter(|row| row.id.eq(evidence.attempt_id))
		.first(cx.tx())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	if attempt.participant_id == reviewer {
		return Err(rpc::Error::forbidden("ownProof"));
	}
	if status_of(&attempt.status) != AttemptStatus::PendingReview
		|| latest_decision(cx.tx(), evidence.id).await?
			!= Some(EvidenceDecisionStatus::ManualReview)
	{
		return Err(rpc::Error::conflict("reviewClosed"));
	}

	let reason = if accept {
		"manual_review_accepted"
	} else {
		"manual_review_rejected"
	};
	record_decision(
		cx.tx(),
		evidence.id,
		decision,
		"human-review",
		reason,
		Some(reviewer),
		&note,
	)
	.await?;
	let status = settle(cx.tx(), backend, &mut attempt).await?;

	if status == AttemptStatus::Verified
		&& let Some(payout) = RewardPayoutRow::query()
			.filter(|row| row.attempt_id.eq(attempt.id.uuid()))
			.first(cx.tx())
			.await
			.map_err(db)?
		&& payout.status == name(&RewardPayoutStatus::HeldForReview)
	{
		verily_rewards::store::accept_review(cx.tx(), reviewer.uuid(), payout.id.uuid())
			.await
			.map_err(into_rpc)?;
	}
	Ok(ReviewDecision { saved: true })
}

/// Asks for another look at one of the participant's own rejected attempts.
/// Each attempt may be appealed once.
pub async fn submit_appeal(
	cx: &rpc::MutationCx,
	attempt_id: String,
	reason: String,
) -> rpc::Result<AppealReceipt> {
	let participant = me(cx.context())?;
	let attempt = owned_attempt(cx.tx(), participant, &attempt_id).await?;
	if status_of(&attempt.status) != AttemptStatus::Rejected {
		return Err(rpc::Error::invalid("notRejected"));
	}
	let reason = reason.trim();
	let length = reason.chars().count();
	let control = reason
		.chars()
		.any(|character| character.is_control() && character != '\n' && character != '\t');
	if length == 0 || length > APPEAL_LENGTH || control {
		return Err(rpc::Error::invalid("appealReason"));
	}
	let already = Appeal::query()
		.filter(|row| row.attempt_id.eq(attempt.id))
		.exists(cx.tx())
		.await
		.map_err(db)?;
	if already {
		return Err(rpc::Error::conflict("alreadyAppealed"));
	}
	let appeal = NewAppeal {
		attempt_id: attempt.id,
		participant_id: participant,
		reason: reason.to_owned(),
		status: "open".to_owned(),
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;
	Ok(AppealReceipt {
		id: appeal.id.to_string(),
	})
}

async fn is_reviewer(connection: &impl Read, account: Id<AuthAccount>) -> Result<bool, rpc::Error> {
	Reviewer::query()
		.filter(|row| row.account_id.eq(account))
		.exists(connection)
		.await
		.map_err(db)
}
