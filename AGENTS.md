# Agent Notes

Verily is an action verification platform: creators post real-world actions
with a place, a proof, and an optional escrowed reward; participants do them
with proof captured live on their phone; Verily verifies the proof and
releases the reward. Read [`PRODUCT.md`](PRODUCT.md) before changing anything
user-facing and [`DESIGN.md`](DESIGN.md) before changing UI.

Verily was extracted from KickJump (nifty). It deliberately has **no NFTs, no
projects, no token launches, no trading, and no achievements-as-assets**. Do
not port those back. Crypto appears only as the unit a reward is paid in.

## Layout

| Path                             | What                                                              |
| -------------------------------- | ----------------------------------------------------------------- |
| `verily_server/`                 | Serverpod 4 server (PostgreSQL + PostGIS)                         |
| `verily_client/`                 | Generated Serverpod client; never edit by hand                    |
| `verily_flutter/`                | The Flutter app (Android first, then iOS and web)                 |
| `verily_kit/verily_site/`        | verily.fun, the landing page: static, deployed apart from the app |
| `packages/verily_evidence/`      | Pure Dart evidence contract shared by app and server              |
| `packages/verily_brand/`         | Brand tokens, mark, wordmark, stamp, promo reel, launch cover     |
| `packages/verily_lints/`         | Analyzer plugin: colour tokens, pinned app dependencies           |
| `packages/verily_escrow_client/` | Generated Dart client for the escrow program; never edit by hand  |
| `programs/verily_escrow/`        | Pina reward escrow program (`_sbf` is its deploy-only cdylib)     |
| `brand/`                         | Exported logo and icon files                                      |
| `docs/`                          | Verification, storage, escrow, provenance research, brand         |

Run everything through `devenv shell` so local work uses the pinned Flutter,
Rust, Pina, and Serverpod toolchains. Verily's local ports avoid other
Serverpod projects: API `8180`, insights `8181`, web `8182`, landing page `8183`,
the LeptosKit kit `8184`, Postgres `8191`.

## Commits and pull requests

- Every commit is authored by Ifiok alone and GPG-signed with his key. Never
  add AI co-author trailers, never disable or reconfigure signing, and never
  write repo-local identity or signing config.
- Branch names use conventional prefixes (`feat/`, `fix/`, `test/`, `ci/`,
  `build/`, `chore/`, `refactor/`). Work through pull requests.

## Reward escrow and the Pina program

Rewards are escrowed in `programs/verily_escrow`. Read
[`docs/reward-escrow.md`](docs/reward-escrow.md) before touching rewards on
either side of the chain boundary.

- A rewarded action cannot publish until its escrow is verified **from chain
  state** by the server. Never trust a client's claim that funding happened.
- Payout indexes are assigned in the database inside the transaction that
  verifies the attempt, under the reward pool row lock. The program's bitmap
  makes a retried release safe; never "fix" a failed release by assigning a
  new index to the same attempt.
- A payout above the review threshold is released only on proof a person
  accepted. Missing or invalid configuration fails closed.
- Chain access is injectable. Tests use a fake gateway; production must fail
  honestly while no real gateway is configured. Never simulate a successful
  production payout.
- `verily_escrow` is Pina migration-aware. After any ABI change, run
  `pina migrations create --project programs/verily_escrow` inside
  `devenv shell`, resolve every `TODO(pina-manual-migration)`, and gate the
  commit with `pina migrations check`. Never hand-edit `migrations/` files,
  generated transitions, or `tests/abi_layout.rs`.
- Keep the deploy-only `programs/verily_escrow_sbf` package: Agave's
  `cargo-build-sbf --lto` fails when one package builds both `lib` and
  `cdylib`, and the host library is needed for tests and `pina lint`.
- Regenerate the Dart client with `devenv shell clients:generate` and check
  drift with `devenv shell clients:check`. Never edit generated output.
- The program keypair is a deploy secret. It is gitignored; never print it or
  commit it.

## Verification and evidence

Read [`docs/verification.md`](docs/verification.md) and
[`docs/provenance-and-watermarking.md`](docs/provenance-and-watermarking.md)
before changing capture, upload, or verification.

- Proof that demands a fresh capture is captured in the app. Never add a
  gallery or file picker to such a requirement.
- Every device signature and Play Integrity request commits to the digest of
  the exact evidence the server accepted. Never accept a token or signature
  that is not bound to the evidence it vouches for.
- Capture starts with `beginCapture`, before the camera, microphone, sensors,
  or scanner open. The app signs with a fresh key generated for that window
  and attested with `SHA-256(captureChallenge ‖ attemptId)`. A key, key id, or
  storage level is trusted only from its Android Key Attestation chain, never
  from the client.
- Google's attestation roots are pinned in code. The test vectors under
  `verily_server/test/unit/action_verification/key_attestation/vectors` come
  from `android/keyattestation`; keep them byte-identical.
- An iPhone signs with the App Attest key its account registered, never one
  per window, so App Attest proof is `secureEnclaveAttested` and never claims
  a verified boot. Apple's App Attestation root is pinned in code, an
  assertion's counter must exceed the last one accepted for its key, and the
  vectors under `.../app_attest/vectors` stay byte-identical.
- Evidence originals are private, hash-pinned to an immutable storage version,
  and never modified. Derived renditions may be watermarked; originals never.
- A watermark is a lookup key, not proof. Never describe a watermark or a
  model verdict as proving a scene is real.
- Live challenges (such as the spoken word) come only from server-owned lists.
  Never let a client or creator choose them.

## Prompt-injection security boundary

Prompt injection is an untrusted-input problem, not something a system prompt
can eliminate by itself. Every AI integration must preserve these controls:

- Treat creator text, action fields, filenames, metadata, URLs, uploaded media,
  speech, visible text, OCR/transcripts, provider errors, and model output as
  untrusted data. None of them may become system/developer instructions or be
  replayed as privileged prompt content.
- Never expose an endpoint or client method that accepts arbitrary messages,
  roles, system prompts, model IDs, provider options, tools, tool choice,
  response schemas, plugins, or remote evidence URLs. Those values must come
  from server-owned templates, pinned allowlists, and immutable evidence
  storage.
- Validate all text before it crosses a model boundary with the centralized
  `ModelInputSecurity` policy. Validate model-generated verification policies
  again before persistence and again before use. Reject suspicious input; do
  not strip a matched phrase and forward the remainder.
- Media-verification prompts must explicitly treat speech, signs, screens,
  subtitles, encoded content, role labels, and control tokens as evidence, not
  instructions. Any model-reported injection signal forces manual review,
  including when other council members vote to accept.
- Models used for action authoring or verification receive no tools, secrets,
  shell access, arbitrary network access, or write capability. The only media
  reference they may receive is a short-lived URL produced server-side for an
  immutable evidence version.
- Parse only a strict, bounded response schema. Never display or persist raw
  model prose, execute model output, or feed it into another privileged prompt.
- A model verdict is an untrusted signal. Reward release remains a
  deterministic server decision gated by confidence/quorum, capture integrity,
  immutable evidence binding, idempotency, and manual review. A model never
  directly releases a reward.
- OpenRouter production keys must be assigned to a guardrail whose prompt-
  injection action is `block`, with pinned model/provider policy and ZDR. The
  server must remain fail-closed until deployment explicitly confirms this
  configuration.
- Every change to an AI boundary must add adversarial tests for role spoofing,
  instruction override, control-token injection, encoded/obfuscated input,
  malformed output, and provider guardrail rejection. Keep the manual-review
  fallback available because no filter or model provides a zero-bypass proof.

## User-facing vs developer-facing information

Keep implementation details out of normal user flows. Provider names, model
routes, confidence scores, chain addresses beyond what a user needs, debug
ports, stack traces, and raw backend diagnostics belong in logs, tests, or the
debug-only development menu (`lib/dev/`, guarded by `kDebugMode`). User-facing
UI explains outcomes and next actions in product language.

## Secrets

Local development resolves secrets from the ignored root `.env` first, then
the Development vault (item "Verily") through the route in `monosecret.toml`.
The `.env` must stay mode `0600` and is never committed.

- Resolve secrets only through Monosecret. Never call `op` for secrets directly
  and never retry secret access in a loop; a throttled 1Password account breaks
  every project at once.
- Every direct interactive `op` command must pass
  `--account kickjump.1password.com`.
- Development runs without any cloud secret: local evidence storage, the
  manual-review verifier, and the fake escrow gateway are the defaults.
- Production uses injected environment values only. Never reuse a development
  token in production.

## Localization and colour

- All user-facing Flutter text comes from `AppLocalizations`
  (`verily_flutter/lib/l10n/app_en.arb`, lowerCamelCase keys grouped by
  feature). Use ICU placeholders and plurals; never concatenate fragments.
  Run `flutter gen-l10n` after ARB edits and commit the generated files.
- Raw colours live only in `verily_flutter/lib/app/theme/verily_theme.dart`
  (and brand tokens in `packages/verily_brand`). Use
  `Theme.of(context).colorScheme` or `Theme.of(context).verily` everywhere
  else. Never use `Color(...)`, `Colors.*`, or `CupertinoColors.*` in app code,
  including tests and painters. Do not suppress `enforce_theme_palette_colors`.

## Screenshots and binary evidence

Never commit screenshots, screen recordings, rendered videos, or other binary
evidence. Rendered launch media goes to the gitignored `.screenshots/`; attach
captures to pull requests with `gh pr comment <n> --attach 'shot.png#Alt'`.
The only committed binaries are product assets the app ships (launcher icon
source, fonts).

## Seeker Android development workflow

```nu
devenv shell dev:seeker          # Postgres + Serverpod + adb reverse + app on Seeker
devenv shell dev:seeker:reload   # hot reload
devenv shell dev:seeker:stop
devenv shell dev:seeker:mcp      # restart with Flutter Driver text entry for MCP automation
```

Override the device with `SEEKER_DEVICE_ID`. After any Flutter UI change,
verify on the live device with the Flutter MCP tools: connect to DTD, hot
reload with `clearRuntimeErrors`, and confirm zero runtime errors before
committing.
