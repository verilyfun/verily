//! Copies the macOS registrant into this crate's build.
//!
//! `lk native prepare macos` writes `.leptoskit/macos/registrant.rs`.
//! Workspace checks such as `lk lint` compile this host before that file
//! exists, so a missing registrant becomes an empty one.

use std::path::PathBuf;

fn main() {
	let manifest = PathBuf::from(std::env::var_os("CARGO_MANIFEST_DIR").expect("cargo sets it"));
	let generated = manifest.join("../.leptoskit/macos/registrant.rs");
	let out = PathBuf::from(std::env::var_os("OUT_DIR").expect("cargo sets it"));
	println!("cargo:rerun-if-changed={}", generated.display());
	let registrant = std::fs::read_to_string(&generated).unwrap_or_default();
	std::fs::write(out.join("registrant.rs"), registrant).expect("OUT_DIR is writable");
}
