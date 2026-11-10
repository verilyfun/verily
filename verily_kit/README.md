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

## Sign-in

Every app route waits for the session before starting private queries. Sign in with an emailed code, followed by an authenticator or recovery code when the account has two-step verification. Signing out clears the session's queries and form values; a different account starts with an empty cache.

In a debug build, emails stay in LeptosKit's development mailbox at `http://localhost:8184/_leptoskit/mail`. Request a code in the app, then open or reload the mailbox to read it. The mailbox route is absent from release builds.

The browser uses its own origin and session cookie. Native builds use `VERILY_API_ORIGIN` at compile time; debug builds default to `127.0.0.1:8184` on iOS and `10.0.2.2:8184` on Android. A native release needs both an HTTPS `VERILY_API_ORIGIN` and the same origin in `[native.plugin-options.http].origins`. The checked-in allowlist grants only local development servers.

## The app's operations

`verily_app/src/ops.rs` declares every operation the screens call, with `service = "verily-backend"`. The wire records they send and return live in `verily_api`, which the backend names too. The browser posts each one to `/_leptoskit/services/verily-backend/api/<name>` on the app's own origin, and this process answers there: the root crate turns on `verily_app`'s `service` feature, which keeps each body, and each body is one call into `verily_backend::serve`, where the rules are. The browser and the native guest never build that feature.

Every operation runs as the signed-in person: attempts, drafts, capture windows, and appeals are read through that identity, so someone else's row is not found. Only accounts granted review (`verily_backend::serve::grant_reviewer`, server code only) see the review queue, and never their own proof in it.

A debug build seeds four live actions in central London (`verily_backend::DEFAULT_LOCATION`) on start, once, with no secrets. Rewards in a debug build use the planted development gateway: the seed plants its own escrows there and `verily_rewards` reads them back before those actions publish. A creator's reward is never found on that gateway, so it does not publish. Release builds mount rewards closed.
