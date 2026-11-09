//! Writes verily.fun to a folder: `cargo run -p verily_site -- dist`.

use std::path::PathBuf;

fn main() -> std::io::Result<()> {
	let out = std::env::args_os()
		.nth(1)
		.map_or_else(|| PathBuf::from("dist/site"), PathBuf::from);
	let config = verily_site::SiteConfig::from_env();
	let written = verily_site::write(&out, &config)?;
	println!("wrote {} files to {}", written.len(), out.display());
	Ok(())
}
