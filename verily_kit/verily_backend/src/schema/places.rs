//! Where an action happens.
//!
//! The name and radius are what people see. The point is private: it feeds
//! nearby search, coarsened first, and never leaves the server.

use leptoskit_db::Id;
use leptoskit_db::Timestamp;
use leptoskit_db::table;
use verily_rewards::schema::ActionRow;

/// One action's place.
#[table(name = "action_places", unique(action_id))]
pub struct ActionPlace {
	pub id: Id<ActionPlace>,
	#[db(on_delete = cascade)]
	pub action_id: Id<ActionRow>,
	#[db(min_len = 1, max_len = 128)]
	pub place_name: String,
	/// Metres. Zero means the action is not tied to a circle on a map.
	#[db(min = 0, max = 50000)]
	pub radius_meters: i64,
	#[db(private)]
	pub latitude: Option<f64>,
	#[db(private)]
	pub longitude: Option<f64>,
	#[db(created_at)]
	pub created_at: Timestamp,
	#[db(updated_at)]
	pub updated_at: Timestamp,
}
