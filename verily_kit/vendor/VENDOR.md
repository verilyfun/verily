# Vendored Skribble crates

Upstream: https://github.com/openbudgetfun/skribble/tree/feat/leptoskit-main
Snapshotted at: b21093bf9b560bc95ed430a48e75b5e2fc6399c4

Skribble's `feat/leptoskit-main` names leptoskit with `branch = "main"`.
Cargo treats that as a different SourceId from Verily's `rev` pin, so a
screen that mixes both (verily_site) fails to type-check. These path crates
depend on the workspace leptoskit pin instead. Drop the vendor once Skribble
pins leptoskit by rev (or publishes to crates.io).
