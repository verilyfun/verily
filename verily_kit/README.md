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

`verily_backend` owns the database tables. `[db]` in `leptoskit.toml` points `lk db` at that crate and its Postgres migrations. The binary mounts `verily_backend` and `verily_app::app`. `lk dev` resolves `monosecret.toml` before it starts. Keep secret values out of Git. An ignored `.env` is mode `0600`.
