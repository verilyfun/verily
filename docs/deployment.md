# Deployment

This is the production plan for Verily's LeptosKit app (`verily_kit/`). It
follows [LeptosKit's deploy guide](https://github.com/leptoskit/leptoskit/blob/1f7f1462a17a9a33eccb933909f6cdae20d03052/docs/src/guide/24-deploying.md)
at commit `1f7f1462a17a9a33eccb933909f6cdae20d03052` (`feat: adopt Exact's performance budgets (#770)`). Nothing in
this document has been provisioned. Do not run `lk infra apply`, `lk deploy`,
or a store submit until the go-live checklist below is clear.

The Flutter and Serverpod tree (`verily_flutter/`, `verily_server/`) is still
the only stack that can capture proof. Its image, hosts, and env names are
listed where an operator still needs them. The kit does not replace that
stack in this plan.

## Hosting target

**One Hetzner x86 VM, Cloudflare Tunnel, Kamal, and Postgres, provisioned by
`lk infra`.** That is the path the guide puts first for an app whose
`[db] dialect` is `postgres`: the website, the API, and live connections on
the same host, TLS at the tunnel, origin HTTP ports closed, Postgres on the
primary, a public bucket for signed code-push artifacts, and encrypted
backups in a separate private bucket. Backups are on unless `[infra.backups]
enabled` is false.

Verily matches that shape:

- `[db]` in `verily_kit/leptoskit.toml` is Postgres. `url_env` is
  `DATABASE_URL`. Migrations live in `verily_backend/migrations-postgres` and
  `verily_kit/src/main.rs` applies them before it listens.
- The app is client-rendered (`render = "csr"`). The server binary serves
  `dist/` (the Wasm client and its precompressed assets) and the Axum API.
  It does not server-render the signed-in app, and it does not hydrate server
  HTML. `verily_app` still declares `csr`, `hydrate`, and `ssr` features so
  the CLI can select them; the committed mode is `csr`.
- `verily.fun` itself is `verily_site`, a static document built with
  `devenv shell site:build`. It has no Wasm. Publish that directory on its
  own hostname. Deep links (`https://verily.fun/link`, `https://verily.fun/r/`)
  are still Serverpod routes. Leave those DNS records on the Serverpod
  origin until the kit serves them.
- `main.rs` merges LeptosKit's readiness routes and stops with
  `GracefulShutdown`, which fails `/readyz` before it drains.

monochange's running site is a different shape: one DigitalOcean Droplet,
Docker Compose, Caddy, and SQLite (`app/DEPLOY.md` in monochange). Its
LeptosKit migration notes keep that runtime on purpose, because managed
`lk infra` requires Postgres and their CI image still builds with
cargo-leptos. Verily's kit is already Postgres, so the SQLite exporters are
the wrong default. DigitalOcean remains a supported `compute` value if the
Hetzner account is not the one in use. Fly, Compose, Kubernetes, and systemd
files from `lk generate deploy` are the escape hatch when the managed preset
does not fit. They are not the recommended path for this app.

Use one app host until a second one is required. Postgres, and any NATS relay
or Valkey cache, stay on the primary. Extra app hosts do not fail the database
over. Do not enable `[infra.services] relay` until the server is built with
`rpc-relay` and `[rpc.live] relay_url_env` is set. Verily does not use that
today.

Pick the size with `lk infra offers --min-memory-gb 2` after the provider
token is in the environment, and set `[infra.budget]` before `plan`. The
guide's `cx23` example is a starting point for a small app, not a commitment.
The kit process serves the Wasm client and the API together, and a later
PostGIS or evidence workload needs headroom the offers list will show.

## What a release build produces

From `verily_kit/`, with binaryen (`wasm-opt`) on `PATH`:

```sh
lk build --release --platform web --out dist
```

`lk` is `leptoskit_cli` built from the same git revision as the crates in
`verily_kit/Cargo.toml`:

```sh
cargo install --git https://github.com/leptoskit/leptoskit --rev 1f7f1462a17a9a33eccb933909f6cdae20d03052 leptoskit_cli --locked
```

`devenv shell lint:kit` installs that binary at `.devenv/leptoskit-cli/bin/lk`.
Use that binary. A generated image installs the published CLI from crates.io
unless the Dockerfile is pointed at this revision. This commit is not the
published `0.3.0` release, so the image must install this git revision.
A release build fails closed when `wasm-opt` is missing.

The client crate is `verily_app` (`[build] client_package`). Cargo compiles
the server and the `wasm32-unknown-unknown` client. wasm-bindgen runs in
process at 0.2.129, which `verily_app` pins. `wasm-opt` runs because this is
a release build. Precompressed `.br` and `.gz` copies land next to
compressible files. Output:

| Path                        | What                            |
| --------------------------- | ------------------------------- |
| `dist/pkg/`                 | Wasm glue and the client module |
| `dist/assets/`              | Shared assets                   |
| `target/release/verily-kit` | The server binary               |

`LEPTOS_ENV=PROD` is what a generated image sets, together with
`LEPTOS_SITE_ADDR`, `LEPTOS_SITE_ROOT`, and `LEPTOS_OUTPUT_NAME`. `main.rs`
reads `LEPTOS_SITE_ROOT` and otherwise uses `dist/`. A path with no file
receives `index.html`; the Wasm client routes it. There is no hydration step
in this mode.

Phone, desktop, and Linux hosts are listed in `leptoskit.toml` and are not
part of this web release. This revision includes a camera plugin for stills
and an app-integrity plugin that is still a stub, and it does not record
video, audio, or QR codes. A kit phone build is not proof capture. Store
submission stays on `verily_kit/.github/workflows/release.yml`, which
installs `leptoskit_cli` from this same git revision. That workflow has no
`[publish]` table to upload until one is added on purpose.

The static site is a second artifact:

```sh
devenv shell site:build
```

The default output is `verily_kit/dist/site`. Put it on `verily.fun` with
long-cache headers for hashed files and a short cache for `index.html`.

## Environment names

Values stay in the production Monosecret profile (`providers = ["injected"]`)
or in the host secret store. Never commit them, never pass them on a command
line, and never reuse a development token. The kit's production profile is
`verily_kit/monosecret.toml`.

The process requires these two before it listens in a release build:

| Name                   | Role                                                                    |
| ---------------------- | ----------------------------------------------------------------------- |
| `DATABASE_URL`         | App database URL. The app role is not a superuser.                      |
| `AUTH_ENCRYPTION_KEYS` | `leptoskit_auth` key ring. A release build refuses to start without it. |

`lk infra` also asks the operator for these names when the managed runtime is
used. They initialise a new data directory. Changing them does not rotate an
existing role.

| Name                                 | Role                                                                                  |
| ------------------------------------ | ------------------------------------------------------------------------------------- |
| `HCLOUD_TOKEN`                       | Hetzner API. Use `DIGITALOCEAN_TOKEN` when `compute` is DigitalOcean.                 |
| `CLOUDFLARE_API_TOKEN`               | Tunnel and DNS in an existing zone.                                                   |
| `POSTGRES_PASSWORD`                  | Postgres administrator, used to create the data directory.                            |
| `DATABASE_PASSWORD`                  | Application database owner. Distinct from the administrator.                          |
| `KAMAL_REGISTRY_PASSWORD`            | Registry credential that can pull the image. It must match `infra.registry_username`. |
| `LEPTOSKIT_BACKUP_PASSWORD`          | Restic encryption password. Keep a copy off the VM.                                   |
| `LEPTOSKIT_BACKUP_ACCESS_KEY_ID`     | S3 key scoped to the private backup bucket.                                           |
| `LEPTOSKIT_BACKUP_SECRET_ACCESS_KEY` | Secret for that key.                                                                  |

Optional later, still names only:

| Name                                          | When                                     |
| --------------------------------------------- | ---------------------------------------- |
| `NATS_TOKEN`                                  | `[infra.services] relay = true`          |
| `VALKEY_PASSWORD`                             | `[infra.services] cache = true`          |
| `B2_APPLICATION_KEY_ID`, `B2_APPLICATION_KEY` | Backup bucket in Backblaze instead of R2 |

The image sets `LEPTOS_SITE_ADDR`, `LEPTOS_SITE_ROOT`, `LEPTOS_OUTPUT_NAME`,
and `LEPTOS_ENV`. Those are not secrets.

Reward and verifier names exist in the kit and are unused while release
builds mount rewards and verification closed. When those mounts open, the
names are the ones `verily_rewards` and `verily_verification` already read:

`VERILY_REWARD_ESCROW_MODE`, `VERILY_REWARD_REVIEW_THRESHOLD_ATOMS`,
`VERILY_REWARD_CLUSTER`, `VERILY_REWARD_MAINNET_ENABLED`,
`VERILY_REWARD_SOLANA_RPC_URL`, `VERILY_REWARD_ARBITER_ADDRESS`,
`VERILY_REWARD_ESCROW_PROGRAM_ID`, `VERILY_REWARD_SOLANA_GENESIS_HASH`,
`VERILY_REWARD_KMS_CREDENTIALS_JSON`, `VERILY_MEDIA_VERIFIER_MODE`,
`VERILY_MEDIA_VERIFIER_URL`, `VERILY_OPENROUTER_URL`,
`VERILY_OPENROUTER_PRIMARY_MODEL`, `VERILY_OPENROUTER_COUNCIL_MODELS`,
`VERILY_OPENROUTER_REQUIRE_ZDR`, `VERILY_OPENROUTER_PROMPT_INJECTION_GUARD`,
`VERILY_MEDIA_VERIFIER_TIMEOUT_SECONDS`.

`VERILY_API_ORIGIN` is a compile-time value for native shells, not a server
secret. A native release needs an `https` origin, and that exact origin in
`[native.plugin-options.http].origins`. The committed allowlist is local only.

The static site reads `VERILY_SITE_ORIGIN`, `VERILY_APP_URL`, and
`VERILY_CONTACT_EMAIL` at build time.

The Serverpod image, for as long as it is the capture API, reads the names in
the root `.env.example` and `monosecret.toml`. Production must set
`VERILY_EVIDENCE_STORAGE` to B2 (local database storage is development only),
device-integrity and capture-signature modes to their attested settings, and
`VERILY_REWARD_ESCROW_MODE` only after the program and custody review. The
RPC URL is a secret because it may carry a provider key.

## Steps

Do these on a trusted Linux machine with Docker, Rust, `lk` built from
commit `1f7f1462a17a9a33eccb933909f6cdae20d03052`, OpenTofu 1.10 or newer
and older than 2, Kamal 2, and an SSH agent. Verify each new host key from
the provider console before the first SSH session.

1. Confirm `cargo metadata --locked` in `verily_kit/` resolves every direct
   `leptoskit*` crate to
   `git+https://github.com/leptoskit/leptoskit?rev=1f7f1462a17a9a33eccb933909f6cdae20d03052`.
   `lk` is `leptoskit_cli` installed from that same revision.
2. Build the web release and the static site. Boot the server against a
   throwaway Postgres with `DATABASE_URL` and `AUTH_ENCRYPTION_KEYS` set.
   `GET /healthz` returns 200 while the process is up. `GET /readyz` returns
   200 when the process can take traffic and 503 while it is draining.
   `GET /api/health` returns `ok`.
3. Add `[infra]` to `verily_kit/leptoskit.toml` only when an operator is ready
   to provision. Replace every placeholder. The zone and the SSH key already
   exist. Credentials stay in the environment.

   ```toml
   [infra]
   name = "verily-production"
   domain = "app.verily.fun"
   compute = "hetzner"
   location = "hel1"
   server_type = "cx23"
   instances = 1
   ssh_key_ids = [0]
   ssh_cidrs = ["192.0.2.1/32"]
   account_id = "cloudflare-account-id"
   zone_id = "cloudflare-zone-id"
   image = "ghcr.io/verilyfun/verily"
   registry = "ghcr.io"
   registry_username = "verilyfun"
   updates_domain = "updates.verily.fun"
   updates_bucket = "verily-releases"
   backup_bucket = "verily-backups"
   secrets = []

   [infra.backups]
   enabled = true
   schedule = "daily"
   daily = 7
   weekly = 4
   monthly = 3
   max_age_hours = 36

   [infra.budget]
   currency = "EUR"
   monthly_compute = 10.0
   ```

   `secrets = []` until reward or mail variables are actually injected. Add
   `[infra.state]` (an independently created, versioned S3 bucket) before CI
   shares state. Local state is the default and is not a shared backend.
4. Generate and review. Commit the TOML, the generated `infra/` config, the
   Dockerfile, and `.terraform.lock.hcl`. Do not commit plans or state.

   ```sh
   lk infra generate
   lk infra plan
   ```

   `plan` prints the resources. Read it. `lk infra apply` is a separate,
   explicit act. It accepts only the saved plan whose fingerprints still
   match. A failed apply consumes the plan. Plan again before a retry.
   Protected resources (the primary host, the network, the buckets) cannot be
   destroyed by removing a block.
5. Build and push a unique image tag from a trusted builder, then set up the
   host once:

   ```sh
   lk infra build --version release-001 --push
   lk deploy --setup --version release-001
   ```

   `--setup` waits for cloud-init, starts accessories, installs the backup
   schedule, and takes a first backup with a restore check. Later releases
   are `lk infra build --version release-00N --push` and
   `lk deploy --version release-00N`.
6. Point `app.verily.fun` through the tunnel the apply created. Publish
   `verily_kit/dist/site` at `verily.fun` without moving `/link` or `/r/`.
7. Run `lk infra ci` only after the state backend and the GitHub environment
   exist. It writes `.github/workflows/leptoskit-deploy.yml` for pushes to
   `main` and for manual runs. Review that file in a pull request. It does
   not exist yet, and this plan does not add it.

## CI

Verily has no hosted CI. `tool/local_ci.dart` runs devenv lanes and posts
commit statuses. Keep those lanes. Add the kit to them once `lint:kit` and
the kit tests are part of the gate.

LeptosKit's own CI at this revision is red. The failures are upstream, on
the commit the kit is pinned to. They are listed in the pull request that
introduces the pin. Do not treat a green Verily kit build as a green
LeptosKit `main`.

The generated deploy workflow, when you choose to commit it:

- Runs on a Linux runner labelled `leptoskit`, with Docker, Rust, `lk` from
  commit `1f7f1462a17a9a33eccb933909f6cdae20d03052`,
  OpenTofu, Kamal, and an SSH agent whose host keys were verified.
- Builds an amd64 image tagged with the Git commit and pushes it to GHCR.
  The build job uses the GitHub package token. Grant that token permission
  to publish the package.
- Deploys that digest and checks status. Schema-changing releases are a
  manual maintenance option. The first `--setup` is a separate manual option.
  `lk infra apply` stays an explicit saved-plan operation. The workflow must
  not apply infrastructure on every push.
- The deployment environment needs a required reviewer. The registry
  credential stored there matches `infra.registry_username` and can pull.

`verily_kit/.github/workflows/release.yml` is store publishing, not this
server deploy. It installs the CLI with
`cargo install --git https://github.com/leptoskit/leptoskit --rev 1f7f1462a17a9a33eccb933909f6cdae20d03052 leptoskit_cli --locked`.
It does not run on a server release.

The Serverpod image stays the opt-in `test:server-image` lane
(`verily_server/Dockerfile`, `linux/amd64`, PostGIS, `/healthz`) until the
kit serves capture. Do not point production DNS at the kit and the Serverpod
image for the same routes.

## Rollback

`lk deploy` records the image digest and the migration history on the
primary. Keep old GHCR tags.

- An image-only rollback, when the database schema still matches the target:

  ```sh
  lk deploy --rollback release-001
  ```

- A schema change ships with `lk deploy --maintenance --version <tag>`. That
  stops writers, takes a verified backup, and starts the new image, which
  applies its embedded migrations. Review both SQL directions first. Kit
  migrations include `down.sql`. A down migration that is missing, whose
  checksum does not match, or that cannot rebuild deleted rows blocks
  reversal.
- A schema rollback keeps the newer migration files in the checkout and runs:

  ```sh
  lk deploy --rollback release-001 --rollback-schema --yes
  ```

  Successful reverses stay committed if a later reverse fails. The app stays
  stopped. LeptosKit does not reverse migrations automatically when a deploy
  fails. It returns to the previous image only when the schema still matches.
- After a data repair, `lk deploy --recover --version <recorded-tag>` starts
  a compatible recorded image.
- Restore a backup with `lk infra restore --snapshot <id> --yes`, then
  recover a compatible release. Losing `LEPTOSKIT_BACKUP_PASSWORD` makes the
  archives unreadable. The previous database name is printed and left on
  disk. Remove it after review. It holds private data.

`lk infra unlock` is only for a dead runner whose reservation is still held,
after that runner is confirmed stopped.

## Go-live checklist

Severity is how badly a real participant is hurt if this ships as production.
The kit deploy above is safe to rehearse. It is not a launch.

### Blocker

- **Proof cannot be captured in the kit.** This revision's camera plugin
  takes stills. It does not record video or audio, and it does not scan QR
  codes. `app_integrity` is a stub, not Play Integrity, Key Attestation, or
  App Attest. Phase 6 of `docs/leptoskit-port.md` is not started. Phone proof
  still depends on the Flutter app. Those production modes are off unless
  the Serverpod environment sets them.
- **The kit is not the product yet.** Sign-in pages, evidence storage,
  device proof, the verifier worker, payout custody, moderation, and the
  public API are the unfinished port in `docs/leptoskit-port.md`. A release
  build mounts verification and rewards closed. Closed means fail, not a
  pretend pass.
- **Rewards cannot pay.** The escrow program is not deployed from this
  repository. `VERILY_REWARD_MAINNET_ENABLED` must be exactly `true` in
  production or mainnet is refused, and the program has not been reviewed
  for real money. The release host does not open a Solana gateway. A
  `local-development` mode is rejected outside development and test. Do not
  simulate a production payout.
- **There is no production pipeline.** No hosted CI, no committed `lk infra`
  config, no image in a registry, no tunnel, no backup password stored off
  the VM. `local_ci` statuses are not a deploy.
- **Legal pages are missing.** The site footer says evidence stays private.
  There is no privacy policy, no terms, and no cookie page on `verily_site`
  or in the Flutter app. The product collects location, device attestation,
  and images of people, and it can move money.

### High

- **Serverpod places need PostGIS.** The baseline migration creates the
  extension. The kit stores a coarsened latitude and longitude and ranks
  nearby in process, so the stock Postgres accessory matches the kit schema.
  Moving the Serverpod place model onto that accessory needs PostGIS in the
  image.
- **Evidence in production is B2 or it does not start.** An empty
  `VERILY_EVIDENCE_STORAGE` stores bytes in Postgres and is refused outside
  development. Originals stay private and unmodified.
- **OpenRouter stays manual review until the guardrail is confirmed.** The
  production key needs a guardrail whose prompt-injection action is block,
  with pinned models and zero data retention. A model does not release a
  reward. Someone has to staff the manual queue.
- **Sign-in mail is a debug mailbox.** Release builds have no development
  mailbox route. Production needs a real mail transport before emailed codes
  work. `AUTH_ENCRYPTION_KEYS` must be a production ring, not the debug key.
- **DNS is designed and not delegated.** `verily_server/config/production.yaml`
  names `api.verily.fun`, `app.verily.fun`, `insights.verily.fun`, and
  `database.private-production.verily.fun`, with TLS terminated in front of
  the container. Nothing in the repo obtains certificates. Kit traffic would
  use the tunnel for `app.verily.fun` only. Do not cut `verily.fun` over
  while `/link` and `/r/` still belong to Serverpod.
- **No operator-facing monitoring.** Production Serverpod config turns
  console session logs off. There is no metrics scrape, no error tracker,
  and no alert path. `lk infra status` and backup age are the kit signals
  once the host exists. Add an alert when backups are older than
  `max_age_hours` or `/readyz` fails.

### Follow-up

- **Wasm release builds need binaryen.** Without `wasm-opt`, `lk build
  --release` fails. The generated image installs it. Local and CI builds
  must too.
- **Hydration and SSR are unused on purpose.** Turning `render` to `ssr`
  or `islands` is a product change, not a deploy fix. The static landing
  page stays a separate build.
- **Native and extension targets.** Android links the Solana mobile wallet
  host. iOS, desktop, and Linux shells build as kit hosts. There is no
  browser extension. None of them are a store release.
- **Serverpod remains on its own image** (`verily_server/Dockerfile`,
  `linux/amd64`, `VERILY_APPLY_MIGRATIONS`) until capture, evidence, and
  escrow run on the kit. Retire it in the port's last phase, not during
  the first kit deploy.
