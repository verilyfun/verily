//! The six product screens, plus the action and editor pages they open.

mod browse;
mod capture;
mod create;
mod me;
mod review;
mod settings;

pub use browse::action;
pub use browse::browse;
pub use capture::capture;
pub use create::create_hub;
pub use create::editor;
pub use me::me;
pub use review::review;
pub use settings::settings;
