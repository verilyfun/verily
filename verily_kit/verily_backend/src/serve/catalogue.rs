//! The Do catalogue, one action, and the creator's drafts.

use chrono::Duration;
use chrono::Utc;
use leptoskit_auth::Account as AuthAccount;
use leptoskit_db::Connection;
use leptoskit_db::Id;
use leptoskit_db::Read;
use leptoskit_rpc as rpc;
use uuid::Uuid;
use verily_api::ActionCard;
use verily_api::ActionDetail;
use verily_api::ActionFilter;
use verily_api::DraftInput;
use verily_api::DraftRow;
use verily_api::DraftSaved;
use verily_api::ProofKind;
use verily_api::ProofNeed;
use verily_api::PublishOutcome;
use verily_rewards::RewardsError;
use verily_rewards::ops::into_rpc;
use verily_rewards::schema::ActionRow;
use verily_rewards::store;
use verily_shared::ActionAuthoringProblem;
use verily_shared::ActionDefinitionStatus;
use verily_shared::ActionOpportunity;
use verily_shared::ActionRecurrence;
use verily_shared::ActionRequirementDraft;
use verily_shared::ActionRequirementKind;
use verily_shared::ActionRequirementView;
use verily_shared::CreateActionDefinitionRequest;
use verily_shared::RewardPoolStatus;
use verily_shared::RewardTermsDraft;
use verily_verification::model_input;

use super::amount_label;
use super::backend;
use super::db;
use super::me;
use super::name;
use super::parse_id;
use super::proof_kind;
use super::require_active;
use super::requirements;
use crate::schema::Account;
use crate::schema::ActionPlace;
use crate::schema::NewActionPlace;

/// The most actions one catalogue page shows.
const PAGE: usize = 50;
/// How many live actions a catalogue read looks at before filtering.
const SCAN: u64 = 500;
/// Nearby search looks this far from the coarsened point.
const NEARBY_METERS: f64 = 25_000.0;
/// The most proofs one action asks for.
const MAX_PROOFS: usize = 5;
/// The widest circle an action's place may draw.
const MAX_RADIUS_METERS: i64 = 50_000;
/// Reward terms the editor does not ask for yet.
const DRAFT_PAYOUTS: i64 = 10;
const DRAFT_WINS_PER_ACCOUNT: i64 = 1;
const DRAFT_REWARD_DAYS: i64 = 30;

/// Live, open actions, newest first; nearby search nearest first.
///
/// The coordinates are only an input: they are coarsened to about 100 m,
/// used to rank, and dropped. A card carries a place name and a radius,
/// never a point.
pub async fn list_available_actions(
	cx: &rpc::QueryCx,
	filter: ActionFilter,
	latitude: Option<f64>,
	longitude: Option<f64>,
) -> rpc::Result<Vec<ActionCard>> {
	let viewer = me(cx.context())?;
	let backend = backend(cx.context())?;
	let origin = match filter {
		ActionFilter::Nearby => Some(coarse_point(latitude, longitude)?),
		_ => None,
	};
	let now = Utc::now();
	let active = name(&ActionDefinitionStatus::Active);
	let actions = ActionRow::query()
		.filter(|row| row.status.eq(active))
		.order_by(|row| row.created_at.desc())
		.limit(SCAN)
		.all(cx.db())
		.await
		.map_err(db)?;

	let mut ranked = Vec::new();
	for action in actions {
		if !is_open(&action, now) {
			continue;
		}
		let requirements = requirements(&action)?;
		if !matches_filter(&filter, &requirements) {
			continue;
		}
		let place = place_for(cx.db(), action.id).await?;
		let distance = match origin {
			Some(origin) => match place_point(place.as_ref()) {
				Some(point) => {
					let meters = haversine_meters(origin, point);
					if meters > NEARBY_METERS {
						continue;
					}
					meters
				}
				None => continue,
			},
			None => 0.0,
		};
		let opportunity = store::opportunity(cx.db(), &backend.rewards, &action, viewer.uuid())
			.await
			.map_err(into_rpc)?;
		ranked.push((
			distance,
			card(&action, place.as_ref(), &requirements, &opportunity),
		));
	}
	if origin.is_some() {
		ranked.sort_by(|a, b| a.0.total_cmp(&b.0));
	}
	Ok(ranked
		.into_iter()
		.take(PAGE)
		.map(|(_, card)| card)
		.collect())
}

/// One action. Published actions are visible to everyone signed in; a draft
/// only to its creator. Anything else is not found, the same way, so the
/// answer never says which.
pub async fn get_action(cx: &rpc::QueryCx, action_id: String) -> rpc::Result<ActionDetail> {
	let viewer = me(cx.context())?;
	let backend = backend(cx.context())?;
	let id = parse_id(&action_id)?;
	let action = ActionRow::query()
		.filter(|row| row.id.eq(Id::<ActionRow>::from_uuid(id)))
		.first(cx.db())
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))?;
	let is_creator = action.creator_id == viewer.uuid();
	if !is_creator && action.status == name(&ActionDefinitionStatus::Draft) {
		return Err(rpc::Error::not_found("notFound"));
	}
	let requirements = requirements(&action)?;
	let place = place_for(cx.db(), action.id).await?;
	let opportunity = store::opportunity(cx.db(), &backend.rewards, &action, viewer.uuid())
		.await
		.map_err(into_rpc)?;
	Ok(ActionDetail {
		id: action.id.to_string(),
		title: action.title.clone(),
		summary: action.description.clone(),
		creator: action.creator_display_name.clone(),
		place_name: place
			.as_ref()
			.map(|place| place.place_name.clone())
			.unwrap_or_default(),
		radius_meters: place.as_ref().map_or(0, |place| place.radius_meters),
		proofs: requirements
			.iter()
			.map(|requirement| {
				let kind = proof_kind(requirement.kind);
				ProofNeed {
					id: requirement.id.to_string(),
					kind,
					title: requirement.title.clone(),
					live: kind.needs_live_capture(),
				}
			})
			.collect(),
		reward_label: reward_label(&opportunity),
		rewarded: opportunity.reward.is_some(),
		funded: escrow_funded(&opportunity),
	})
}

/// The signed-in creator's drafts and live actions, most recently changed first.
pub async fn list_my_actions(cx: &rpc::QueryCx) -> rpc::Result<Vec<DraftRow>> {
	let creator = me(cx.context())?;
	let backend = backend(cx.context())?;
	let actions = ActionRow::query()
		.filter(|row| row.creator_id.eq(creator.uuid()))
		.order_by(|row| row.updated_at.desc())
		.limit(200)
		.all(cx.db())
		.await
		.map_err(db)?;
	let mut rows = Vec::with_capacity(actions.len());
	for action in actions {
		let opportunity = store::opportunity(cx.db(), &backend.rewards, &action, creator.uuid())
			.await
			.map_err(into_rpc)?;
		rows.push(DraftRow {
			id: action.id.to_string(),
			title: action.title.clone(),
			rewarded: opportunity.reward.is_some(),
			funded: escrow_funded(&opportunity),
			live: action.status == name(&ActionDefinitionStatus::Active),
		});
	}
	Ok(rows)
}

/// Saves a new draft, or replaces one of the creator's own. Saving never
/// funds anything: a reward becomes a draft pool that still has to be
/// escrowed and read back from chain state.
pub async fn save_action(cx: &rpc::MutationCx, draft: DraftInput) -> rpc::Result<DraftSaved> {
	let creator = me(cx.context())?;
	let backend = backend(cx.context())?;
	require_active(cx.tx(), creator).await?;
	let content = DraftContent::parse(&draft, backend.rewards.decimals)?;

	let existing = draft
		.id
		.as_deref()
		.map(str::trim)
		.filter(|id| !id.is_empty());
	let saved = match existing {
		None => {
			let display_name = display_name(cx.tx(), creator).await?;
			let request = content.request(action_key(&content.title));
			store::create_action(
				cx.tx(),
				&backend.rewards,
				creator.uuid(),
				&display_name,
				&request,
			)
			.await
			.map_err(into_rpc)?
		}
		Some(id) => {
			let action = owned_action(cx.tx(), creator, parse_id(id)?).await?;
			let request = content.request(action.action_key.clone());
			store::save_action(
				cx.tx(),
				&backend.rewards,
				creator.uuid(),
				action.id.uuid(),
				action.revision,
				&request,
			)
			.await
			.map_err(into_rpc)?
		}
	};

	let action_id = Id::<ActionRow>::from_uuid(saved.id);
	match place_for(cx.tx(), action_id).await? {
		Some(mut place) => {
			place.place_name = content.place_name;
			place.radius_meters = content.radius_meters;
			place.save(cx.tx()).await.map_err(db)?;
		}
		None => {
			NewActionPlace {
				action_id,
				place_name: content.place_name,
				radius_meters: content.radius_meters,
				latitude: None,
				longitude: None,
			}
			.insert(cx.tx())
			.await
			.map_err(db)?;
		}
	}
	Ok(DraftSaved {
		id: saved.id.to_string(),
	})
}

/// Publishes one of the creator's drafts. A rewarded draft publishes only
/// once `verily_rewards` has read its escrow from chain state; until then the
/// answer is "not published, not funded", and nothing changes.
pub async fn publish_action(
	cx: &rpc::MutationCx,
	action_id: String,
) -> rpc::Result<PublishOutcome> {
	let creator = me(cx.context())?;
	let backend = backend(cx.context())?;
	require_active(cx.tx(), creator).await?;
	let action = owned_action(cx.tx(), creator, parse_id(&action_id)?).await?;
	match store::publish_action(
		cx.tx(),
		&backend.rewards,
		creator.uuid(),
		action.id.uuid(),
		action.revision,
	)
	.await
	{
		Ok(published) => Ok(PublishOutcome {
			published: published.status == ActionDefinitionStatus::Active,
			rewarded: published.reward.is_some(),
			funded: escrow_funded(&published),
		}),
		Err(RewardsError::Authoring(ActionAuthoringProblem::RewardNotFunded)) => {
			Ok(PublishOutcome {
				published: false,
				rewarded: true,
				funded: false,
			})
		}
		Err(error) => Err(into_rpc(error)),
	}
}

/// What the editor sent, checked: the text crosses no model unchecked.
struct DraftContent {
	title: String,
	summary: String,
	place_name: String,
	radius_meters: i64,
	requirements: Vec<ActionRequirementDraft>,
	reward: Option<RewardTermsDraft>,
}

impl DraftContent {
	fn parse(draft: &DraftInput, decimals: i64) -> Result<Self, rpc::Error> {
		let title =
			model_input::validate_short_copy(&draft.title).map_err(|error| unsafe_text(&error))?;
		let place_name = model_input::validate_short_copy(&draft.place_name)
			.map_err(|error| unsafe_text(&error))?;
		let summary = model_input::validate_description(&draft.summary)
			.map_err(|error| unsafe_text(&error))?;
		if !(0..=MAX_RADIUS_METERS).contains(&draft.radius_meters) {
			return Err(rpc::Error::invalid("invalidRequest"));
		}
		if draft.proofs.is_empty() || draft.proofs.len() > MAX_PROOFS {
			return Err(rpc::Error::invalid("invalidRequest"));
		}
		let mut requirements: Vec<ActionRequirementDraft> = Vec::new();
		for kind in &draft.proofs {
			let requirement = requirement_for(*kind, draft.radius_meters)?;
			if requirements
				.iter()
				.any(|existing| existing.requirement_key == requirement.requirement_key)
			{
				return Err(rpc::Error::invalid("invalidRequest"));
			}
			requirements.push(requirement);
		}
		let reward = match draft.reward_amount.trim() {
			"" => None,
			amount => Some(RewardTermsDraft {
				amount_per_payout: parse_amount(amount, decimals)?,
				max_payouts: DRAFT_PAYOUTS,
				max_wins_per_account: DRAFT_WINS_PER_ACCOUNT,
				expires_at: Utc::now() + Duration::days(DRAFT_REWARD_DAYS),
				refund_delay_days: verily_rewards::decide::MIN_REFUND_DELAY_DAYS,
			}),
		};
		Ok(Self {
			title,
			summary,
			place_name,
			radius_meters: draft.radius_meters,
			requirements,
			reward,
		})
	}

	fn request(&self, action_key: String) -> CreateActionDefinitionRequest {
		CreateActionDefinitionRequest {
			action_key,
			title: self.title.clone(),
			description: self.summary.clone(),
			recurrence: ActionRecurrence::Once,
			time_zone: "UTC".to_owned(),
			max_verified_completions: None,
			opens_at: None,
			closes_at: None,
			requirements: self.requirements.clone(),
			reward: self.reward.clone(),
		}
	}
}

fn unsafe_text(error: &model_input::ModelInputError) -> rpc::Error {
	match error {
		model_input::ModelInputError::Length => rpc::Error::invalid("invalidRequest"),
		model_input::ModelInputError::Unsafe => rpc::Error::invalid("unsafeText"),
	}
}

/// The server-owned requirement for one kind of proof. Copy, durations, and
/// whether a spoken word is needed come from here, never from the editor.
pub(crate) fn requirement_for(
	kind: ProofKind,
	radius_meters: i64,
) -> Result<ActionRequirementDraft, rpc::Error> {
	let draft = match kind {
		ProofKind::Photo => ActionRequirementDraft::new(
			"photo",
			ActionRequirementKind::Photo,
			"Photo",
			"Take the photo in the app.",
			true,
		),
		ProofKind::Video | ProofKind::Audio => {
			let (key, requirement_kind, title, instructions) = if kind == ProofKind::Video {
				(
					"video",
					ActionRequirementKind::Video,
					"Video",
					"Record the video in the app and say the word on screen.",
				)
			} else {
				(
					"audio",
					ActionRequirementKind::Audio,
					"Audio",
					"Record the audio in the app and say the word on screen.",
				)
			};
			let mut draft =
				ActionRequirementDraft::new(key, requirement_kind, title, instructions, true);
			draft.min_duration_seconds = Some(3);
			draft.max_duration_seconds = Some(300);
			draft.spoken_challenge_required = Some(true);
			draft
		}
		ProofKind::Presence => {
			let mut draft = ActionRequirementDraft::new(
				"presence",
				ActionRequirementKind::Location,
				"Be there",
				"Check in from the place.",
				true,
			);
			#[allow(clippy::cast_precision_loss, reason = "a radius is at most 50 km")]
			let radius = radius_meters as f64;
			draft.radius_meters = (radius_meters > 0).then_some(radius);
			draft
		}
		ProofKind::Movement => ActionRequirementDraft::new(
			"movement",
			ActionRequirementKind::Motion,
			"Movement",
			"Do the movement with your phone.",
			true,
		),
		ProofKind::VenueCode => ActionRequirementDraft::new(
			"venue-code",
			ActionRequirementKind::QrCode,
			"Venue code",
			"Scan the code at the venue.",
			true,
		),
		// A note is typed, not captured, and an App needs one of the
		// creator's registered Apps; neither is a requirement here yet.
		ProofKind::Note | ProofKind::App => {
			return Err(rpc::Error::invalid("unsupportedProof"));
		}
	};
	Ok(draft)
}

/// A token amount as typed, `2.5`, in atoms. No sign, no exponent, and no
/// more places than the token has.
fn parse_amount(text: &str, decimals: i64) -> Result<i64, rpc::Error> {
	let invalid = || rpc::Error::invalid("invalidRequest");
	let places = usize::try_from(decimals).map_err(|_| invalid())?;
	let (whole, fraction) = text.split_once('.').unwrap_or((text, ""));
	let digits = |part: &str| part.chars().all(|character| character.is_ascii_digit());
	if whole.is_empty() || !digits(whole) || !digits(fraction) || fraction.len() > places {
		return Err(invalid());
	}
	let padded = format!("{whole}{fraction:0<places$}");
	let atoms: i64 = padded.parse().map_err(|_| invalid())?;
	if atoms < 1 {
		return Err(invalid());
	}
	Ok(atoms)
}

/// A key the creator never sees: the title's letters and a random suffix.
fn action_key(title: &str) -> String {
	let mut slug = String::new();
	for character in title.chars().flat_map(char::to_lowercase) {
		if character.is_ascii_alphanumeric() {
			slug.push(character);
		} else if !slug.ends_with('-') && !slug.is_empty() {
			slug.push('-');
		}
		if slug.len() >= 40 {
			break;
		}
	}
	let slug = slug.trim_matches('-');
	let suffix = &Uuid::new_v4().simple().to_string()[..8];
	if slug.is_empty() {
		format!("action-{suffix}")
	} else {
		format!("{slug}-{suffix}")
	}
}

/// The creator's own action, or not found: someone else's draft looks the
/// same as no draft.
pub(super) async fn owned_action(
	connection: &impl Read,
	creator: Id<AuthAccount>,
	action_id: Uuid,
) -> Result<ActionRow, rpc::Error> {
	ActionRow::query()
		.filter(|row| {
			row.id.eq(Id::<ActionRow>::from_uuid(action_id)) & row.creator_id.eq(creator.uuid())
		})
		.first(connection)
		.await
		.map_err(db)?
		.ok_or_else(|| rpc::Error::not_found("notFound"))
}

async fn display_name(
	connection: &impl Connection,
	account: Id<AuthAccount>,
) -> Result<String, rpc::Error> {
	Ok(Account::query()
		.filter(|row| row.id.eq(account))
		.first(connection)
		.await
		.map_err(db)?
		.map_or_else(
			|| "Verily member".to_owned(),
			|account| account.display_name,
		))
}

pub(super) async fn place_for(
	connection: &impl Read,
	action_id: Id<ActionRow>,
) -> Result<Option<ActionPlace>, rpc::Error> {
	ActionPlace::query()
		.filter(|row| row.action_id.eq(action_id))
		.first(connection)
		.await
		.map_err(db)
}

/// Published, inside its open and close times, and not yet full.
pub(super) fn is_open(action: &ActionRow, now: chrono::DateTime<Utc>) -> bool {
	action.status == name(&ActionDefinitionStatus::Active)
		&& action.opens_at.is_none_or(|opens| opens <= now)
		&& action.closes_at.is_none_or(|closes| closes > now)
		&& action
			.max_verified_completions
			.is_none_or(|limit| action.verified_completions < limit)
}

fn matches_filter(filter: &ActionFilter, requirements: &[ActionRequirementView]) -> bool {
	let has = |kind: ActionRequirementKind| {
		requirements
			.iter()
			.any(|requirement| requirement.kind == kind)
	};
	match filter {
		ActionFilter::All | ActionFilter::Nearby => true,
		ActionFilter::Place => has(ActionRequirementKind::Location),
		ActionFilter::Movement => has(ActionRequirementKind::Motion),
		ActionFilter::VenueCode => has(ActionRequirementKind::QrCode),
		ActionFilter::Apps => has(ActionRequirementKind::ExternalApp),
	}
}

fn card(
	action: &ActionRow,
	place: Option<&ActionPlace>,
	requirements: &[ActionRequirementView],
	opportunity: &ActionOpportunity,
) -> ActionCard {
	ActionCard {
		id: action.id.to_string(),
		title: action.title.clone(),
		creator: action.creator_display_name.clone(),
		place_name: place
			.map(|place| place.place_name.clone())
			.unwrap_or_default(),
		radius_meters: place.map_or(0, |place| place.radius_meters),
		proof_count: i64::try_from(requirements.len()).unwrap_or(i64::MAX),
		reward_label: reward_label(opportunity),
	}
}

/// The reward a viewer may see, or nothing: a pool that is not funded from
/// chain state is shown only to its creator, and is not advertised here.
fn reward_label(opportunity: &ActionOpportunity) -> String {
	opportunity
		.reward
		.as_ref()
		.filter(|reward| reward.status == RewardPoolStatus::Funded)
		.map(|reward| {
			amount_label(
				reward.amount_per_payout,
				reward.decimals,
				&reward.token_symbol,
			)
		})
		.unwrap_or_default()
}

/// Whether the action's reward sits in an escrow the server read from chain
/// state. An action without a reward has no escrow and is not "funded".
fn escrow_funded(opportunity: &ActionOpportunity) -> bool {
	opportunity
		.reward
		.as_ref()
		.is_some_and(|reward| reward.status == RewardPoolStatus::Funded)
}

/// The search point, coarsened to three decimal places (about 100 m).
fn coarse_point(latitude: Option<f64>, longitude: Option<f64>) -> Result<(f64, f64), rpc::Error> {
	let (Some(latitude), Some(longitude)) = (latitude, longitude) else {
		return Err(rpc::Error::invalid("locationNeeded"));
	};
	if !latitude.is_finite()
		|| !longitude.is_finite()
		|| !(-90.0..=90.0).contains(&latitude)
		|| !(-180.0..=180.0).contains(&longitude)
	{
		return Err(rpc::Error::invalid("invalidRequest"));
	}
	let coarse = |value: f64| (value * 1000.0).round() / 1000.0;
	Ok((coarse(latitude), coarse(longitude)))
}

fn place_point(place: Option<&ActionPlace>) -> Option<(f64, f64)> {
	let place = place?;
	Some((place.latitude?, place.longitude?))
}

/// Great-circle distance in metres on a sphere the size of the Earth.
fn haversine_meters(from: (f64, f64), to: (f64, f64)) -> f64 {
	const EARTH_RADIUS_METERS: f64 = 6_371_008.8;
	let (lat1, lon1) = (from.0.to_radians(), from.1.to_radians());
	let (lat2, lon2) = (to.0.to_radians(), to.1.to_radians());
	let a = ((lat2 - lat1) / 2.0).sin().powi(2)
		+ lat1.cos() * lat2.cos() * ((lon2 - lon1) / 2.0).sin().powi(2);
	2.0 * EARTH_RADIUS_METERS * a.sqrt().asin()
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn amounts_parse_to_atoms_and_refuse_anything_else() {
		assert_eq!(parse_amount("2", 6).unwrap(), 2_000_000);
		assert_eq!(parse_amount("2.5", 6).unwrap(), 2_500_000);
		assert_eq!(parse_amount("0.000001", 6).unwrap(), 1);
		for bad in [
			"",
			"-1",
			"1e3",
			"0",
			"0.0000001",
			"1.2.3",
			".5",
			"two",
			" 1",
		] {
			assert!(parse_amount(bad, 6).is_err(), "{bad:?}");
		}
	}

	#[test]
	fn a_search_point_is_coarsened_and_checked() {
		assert_eq!(
			coarse_point(Some(51.507_44), Some(-0.127_76)).unwrap(),
			(51.507, -0.128)
		);
		assert!(coarse_point(None, Some(1.0)).is_err());
		assert!(coarse_point(Some(91.0), Some(0.0)).is_err());
		assert!(coarse_point(Some(f64::NAN), Some(0.0)).is_err());
	}

	#[test]
	fn distances_are_great_circle_metres() {
		let london = (51.5074, -0.1278);
		let greenwich = (51.4769, -0.0005);
		let meters = haversine_meters(london, greenwich);
		assert!((9_000.0..10_000.0).contains(&meters), "{meters}");
		assert!(haversine_meters(london, london) < 1e-6);
	}

	#[test]
	fn action_keys_are_slugs_with_a_random_suffix() {
		let key = action_key("Find the Oak!  By the gate");
		assert!(key.starts_with("find-the-oak-by-the-gate-"), "{key}");
		assert_ne!(action_key("same"), action_key("same"));
		assert!(action_key("!!!").starts_with("action-"));
	}

	#[test]
	fn proofs_map_to_server_owned_requirements() {
		let video = requirement_for(ProofKind::Video, 0).unwrap();
		assert_eq!(video.spoken_challenge_required, Some(true));
		let presence = requirement_for(ProofKind::Presence, 120).unwrap();
		assert_eq!(presence.kind, ActionRequirementKind::Location);
		assert_eq!(presence.radius_meters, Some(120.0));
		assert!(presence.latitude.is_none());
		assert!(requirement_for(ProofKind::Note, 0).is_err());
		assert!(requirement_for(ProofKind::App, 0).is_err());
	}
}
