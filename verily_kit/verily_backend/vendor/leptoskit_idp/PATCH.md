# Patched leptoskit_idp

Pinned against leptoskit rev `365e2a2341ba4c675048e2a05e4caf946d4c623b`.

Upstream `idp.grants` has `unique(account_id, client_id)` but no
`on_account_merge`, so `lk db check` fails when the auth pack is linked.

This vendor copy adds `on_account_merge = reassign_skip_conflicts` to
`Grant`. Drop this directory and switch back to the git dependency once
upstream ships the same attribute.
