# Patched leptoskit_idp

Pinned against leptoskit rev `284fd8831fbc6ae5e085c4270152e74863c2965c`.

Upstream `idp.grants` has `unique(account_id, client_id)` but no
`on_account_merge`, so `lk db check` fails when the auth pack is linked.

This vendor copy adds `on_account_merge = reassign_skip_conflicts` to
`Grant`. Drop this directory and switch back to the git dependency once
upstream ships the same attribute.

`tests/fixtures/test-only-rsa-key.pem` and the `[dev-dependencies]` block
are kept so `lk lint` / `cargo clippy --workspace --all-targets` can
compile the unit tests that came with the crate. Upstream integration
tests under `tests/*.rs` are not vendored.
