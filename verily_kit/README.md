# verily_kit

Verily's LeptosKit workspace. The shell serves `verily_backend` and mounts `verily_app::App`. Day-to-day development is the LeptosKit CLI (`leptoskit`, or `lk`):

```sh
lk doctor
lk dev
lk lint
lk db check
lk db migration create <name>
lk build
lk build --platform ios
lk build --platform android
```

`verily_backend` owns the database tables. `[db]` in `leptoskit.toml` points `lk db` at that crate and its Postgres migrations. The binary mounts `verily_backend` and `verily_app::App`. `lk dev` resolves `monosecret.toml` before it starts. Keep secret values out of Git. An ignored `.env` is mode `0600`.

## The app's operations

`verily_app/src/ops.rs` declares every operation the screens call, with `service = "verily-backend"`. The wire records they send and return live in `verily_api`, which the backend names too. The browser posts each one to `/_leptoskit/services/verily-backend/api/<name>` on the app's own origin, and this process answers there: the root crate turns on `verily_app`'s `service` feature, which keeps each body, and each body is one call into `verily_backend::serve`, where the rules are. The browser and the native guest never build that feature.

Every operation runs as the signed-in person: attempts, drafts, capture windows, and appeals are read through that identity, so someone else's row is not found. Only accounts granted review (`verily_backend::serve::grant_reviewer`, server code only) see the review queue, and never their own proof in it.

A debug build seeds four live actions in central London (`verily_backend::DEFAULT_LOCATION`) on start, once, with no secrets. Rewards in a debug build use the planted development gateway: the seed plants its own escrows there and `verily_rewards` reads them back before those actions publish. A creator's reward is never found on that gateway, so it does not publish. Release builds mount rewards closed.
