//! Twelve built-in starter templates and rate-limited AI action drafting.

use chrono::Duration;
use chrono::Utc;
use leptoskit_rpc as rpc;
use verily_api::ActionDraftSuggestion;
use verily_api::ActionTemplateItem;
use verily_api::DraftInput;
use verily_api::ProofKind;

use super::backend;
use super::db;
use super::me;
use super::require_active;
use crate::schema::AiUsageRow;
use crate::schema::NewAiUsageRow;

const MAX_DRAFTS_PER_HOUR: usize = 10;

/// Built-in starter templates creators can customize without AI keys.
#[allow(
	clippy::too_many_lines,
	reason = "static catalog of twelve built-in starter templates"
)]
#[must_use]
pub fn list_templates() -> Vec<ActionTemplateItem> {
	vec![
		ActionTemplateItem {
			id: "visit-a-place".into(),
			title: "Visit a neighbourhood spot".into(),
			summary: "Check in on site and snap a live photo of the landmark.".into(),
			category: "place".into(),
			place_name: "Town Square".into(),
			radius_meters: 150,
			proofs: vec![ProofKind::Presence, ProofKind::Photo],
		},
		ActionTemplateItem {
			id: "ten-squats".into(),
			title: "Ten squats in one take".into(),
			summary: "Record ten full bodyweight squats in a single continuous take.".into(),
			category: "movement".into(),
			place_name: "Anywhere".into(),
			radius_meters: 0,
			proofs: vec![ProofKind::Movement, ProofKind::Video],
		},
		ActionTemplateItem {
			id: "ten-push-ups".into(),
			title: "Ten push-ups".into(),
			summary: "Keep your whole body in frame and complete ten clean push-ups.".into(),
			category: "movement".into(),
			place_name: "Anywhere".into(),
			radius_meters: 0,
			proofs: vec![ProofKind::Movement, ProofKind::Video],
		},
		ActionTemplateItem {
			id: "event-check-in".into(),
			title: "Check in at a live venue".into(),
			summary: "Scan the host's rotating QR code while standing inside the venue.".into(),
			category: "venue".into(),
			place_name: "Community Hall".into(),
			radius_meters: 100,
			proofs: vec![ProofKind::Presence, ProofKind::VenueCode],
		},
		ActionTemplateItem {
			id: "clean-up-a-park".into(),
			title: "Pick up a bag of litter".into(),
			summary: "Show the filled bag at the park bin with a short video clip.".into(),
			category: "community".into(),
			place_name: "River Park".into(),
			radius_meters: 250,
			proofs: vec![ProofKind::Presence, ProofKind::Video],
		},
		ActionTemplateItem {
			id: "spoken-pledge".into(),
			title: "Read a live audio note".into(),
			summary: "Record a short voice clip speaking the challenge word clearly.".into(),
			category: "audio".into(),
			place_name: "Anywhere".into(),
			radius_meters: 0,
			proofs: vec![ProofKind::Audio],
		},
		ActionTemplateItem {
			id: "football-kick-ups".into(),
			title: "Ten football kick-ups".into(),
			summary: "Keep the ball off the ground for ten touches in one continuous clip.".into(),
			category: "movement".into(),
			place_name: "Pitch".into(),
			radius_meters: 0,
			proofs: vec![ProofKind::Movement, ProofKind::Video],
		},
		ActionTemplateItem {
			id: "phone-spin".into(),
			title: "Three full phone turns".into(),
			summary: "Hold the phone flat and rotate smoothly through three full circles.".into(),
			category: "motion".into(),
			place_name: "Anywhere".into(),
			radius_meters: 0,
			proofs: vec![ProofKind::Movement],
		},
		ActionTemplateItem {
			id: "still-minute".into(),
			title: "Hold still for twenty seconds".into(),
			summary: "Rest your phone steadily in hand with minimal shake for twenty seconds."
				.into(),
			category: "motion".into(),
			place_name: "Anywhere".into(),
			radius_meters: 0,
			proofs: vec![ProofKind::Movement],
		},
		ActionTemplateItem {
			id: "coffee-shop-stamp".into(),
			title: "Local cafe visit".into(),
			summary: "Visit the cafe and scan the counter code for a verified visit.".into(),
			category: "venue".into(),
			place_name: "Corner Roasters".into(),
			radius_meters: 80,
			proofs: vec![ProofKind::Presence, ProofKind::VenueCode],
		},
		ActionTemplateItem {
			id: "app-milestone".into(),
			title: "Complete a partner app milestone".into(),
			summary: "Link your partner app account and verify the completed milestone.".into(),
			category: "app".into(),
			place_name: "Online".into(),
			radius_meters: 0,
			proofs: vec![ProofKind::App],
		},
		ActionTemplateItem {
			id: "morning-run-check".into(),
			title: "Morning trail arrival".into(),
			summary: "Arrive at the trailhead and snap a live photo at the marker post.".into(),
			category: "place".into(),
			place_name: "North Trailhead".into(),
			radius_meters: 200,
			proofs: vec![ProofKind::Presence, ProofKind::Photo],
		},
	]
}

/// Drafts an editable action proposal from a plain-language creator idea,
/// enforcing per-account hourly quotas and `ModelInputSecurity`.
pub async fn draft_action_from_prompt(
	cx: &rpc::MutationCx,
	prompt: String,
) -> rpc::Result<ActionDraftSuggestion> {
	let creator = me(cx.context())?;
	require_active(cx.tx(), creator).await?;
	let backend = backend(cx.context())?;

	let cutoff = Utc::now() - Duration::hours(1);
	let recent = AiUsageRow::query()
		.filter(|row| row.account_id.eq(creator) & row.created_at.gte(cutoff))
		.all(cx.tx())
		.await
		.map_err(db)?;
	if recent.len() >= MAX_DRAFTS_PER_HOUR {
		return Err(rpc::Error::invalid("rateLimited"));
	}

	NewAiUsageRow {
		account_id: creator,
		feature: "action_draft".to_owned(),
	}
	.insert(cx.tx())
	.await
	.map_err(db)?;

	let generated = backend
		.draft_generator
		.generate(&prompt)
		.await
		.map_err(|err| match err {
			verily_verification::openrouter_http::DraftError::Rejected(_) => {
				rpc::Error::invalid("promptRefused")
			}
			verily_verification::openrouter_http::DraftError::Unavailable(_) => {
				rpc::Error::retry("draftingUnavailable")
			}
		})?;

	let mut proofs = Vec::new();
	let mut radius_meters = 0_i64;
	let mut latitude = None;
	let mut longitude = None;
	for req in &generated.requirements {
		let kind = match req.kind.as_str() {
			"video" => ProofKind::Video,
			"audio" => ProofKind::Audio,
			"location" => {
				if let Some(r) = req.radius_meters {
					#[allow(
						clippy::cast_possible_truncation,
						reason = "clamped into 10.0..=50_000.0 before rounding to i64"
					)]
					{
						radius_meters = r.clamp(10.0, 50_000.0).round() as i64;
					}
				}
				latitude = req.latitude;
				longitude = req.longitude;
				ProofKind::Presence
			}
			"motion" => ProofKind::Movement,
			_ => ProofKind::Photo,
		};
		if !proofs.contains(&kind) {
			proofs.push(kind);
		}
	}
	if proofs.is_empty() {
		proofs.push(ProofKind::Photo);
	}

	Ok(ActionDraftSuggestion {
		draft: DraftInput {
			id: None,
			title: generated.title,
			summary: generated.description,
			place_name: if radius_meters > 0 {
				"Choose a place".to_owned()
			} else {
				"Anywhere".to_owned()
			},
			radius_meters,
			reward_amount: String::new(), // AI drafts never propose money terms.
			proofs,
			latitude,
			longitude,
		},
		safety_notes: generated.safety_notes,
		assumptions: generated.assumptions,
	})
}
