# Moving Verily to LeptosKit

Verily runs on one Rust stack built on
[LeptosKit](https://github.com/leptoskit/leptoskit) in `verily_kit/`, paired
with [`leptoskit/mediapipe`](https://github.com/leptoskit/mediapipe),
[`pina-rs/solana_kit`](https://github.com/pina-rs/solana_kit), and the Pina
Solana reward escrow program in `programs/verily_escrow/`.

## Phases

| Phase | What landed                                                                                                                                                                                                                                                    | State     |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| 1     | App frame and look: file-router navigators (root stack, Skribble tab bar), routes at canonical URLs, front door, and screens drawn with `leptoskit_skribble` + `verily_ink`                                                                                    | Completed |
| 2     | Sign-in: email codes (Resend) and Google OAuth through `leptoskit_auth`, `/sign-in` route, public `/` front door, and session gate for private routes                                                                                                         | Completed |
| 3     | Core backend operations: actions, drafts, 12 starter templates, AI authoring, attempts, geofenced location proof (`submit_location_proof` + implausible-travel checks), PostGIS nearby search, rotating venue QR challenges, account closure, and full runtime config loading | Completed |
| 4     | Evidence storage (Backblaze B2 S3v4 + local disk), presigned upload reservations, immutable version confirmation, and background maintenance sweeps on `rpc::cron` + `rpc::job`                                                                                | Completed |
| 5     | Server device proof: Android Key Attestation (pinned Google legacy RSA + 2026 CA1 roots, all 10 byte-identical vectors), Apple App Attest (CBOR + CMS receipt + pinned Apple roots, all 3 byte-identical vectors), DeviceCheck, and Play Integrity               | Completed |
| 6     | App device proof & MediaPipe: `verily_capture` (CameraX/AVFoundation stills, start/stop video & audio, direct host presigned upload, QR, motion, location), `verily_attest` (Keystore/Play Integrity, automatic iOS App Attest registration), `leptoskit/mediapipe` native bridge, and pure-Rust exercise/ball/local-check HUD | Completed |
| 7     | AI verification: OpenRouter HTTP council transport behind `ModelInputSecurity`, prompt-injection guard fail-closed checks, deterministic motion analyzer, MediaPipe + `ffmpeg` server replay, and adversarial tests                                            | Completed |
| 8     | Rewards end to end: Google Cloud KMS Ed25519 custody + devnet-only local keypair signer, `pina-rs/solana_kit` transaction construction and submission, recovery sweeps, and Android Mobile Wallet Adapter payout linking + escrow funding                      | Completed |
| 9     | Moderation, appeals (`/appeals`, RLS-protected reviewer resolution), abuse risk pseudonymization, and AI usage metering                                                                                                                                        | Completed |
| 10    | Verily Apps: partner apps (`/apps`, `/apps/:app`), API key hashing & rotation, SSRF-safe HMAC-SHA256 webhooks, Ed25519 JWS receipts + `/.well-known/jwks.json`, `/api/v1/*` routes, `/r/:request`, and `/link`                                                 | Completed |
| 11    | Tooling & deployment: `verily_kit/Dockerfile` (`leptoskit build --release --platform web`, `verily_site`, `ffmpeg`, SHA-256 verified MediaPipe models, unprivileged `app` user), `verily_kit/docker-compose.yaml` (PostgreSQL 19 + PostGIS 3.7), `monosecret.toml`, `devenv.nix`, `tool/local_ci.sh`, and GitHub Actions CI + release workflows pinned to latest LeptosKit | Completed |
| 12    | Removed Serverpod (`verily_server/`, `verily_client/`), Flutter (`verily_flutter/`), Dart packages (`packages/`), and Serverpod docs                                                                                                                           | Completed |

## Remaining hardware-dependent checks before store release

- End-to-end on-device smoke test of `verily_capture`, `verily_attest`,
  `mediapipe`, and Mobile Wallet Adapter on physical Android (Seeker) and iOS
  devices using `devenv shell dev:seeker` and Xcode.
- Provisioning production secrets (PostGIS `DATABASE_URL`,
  `AUTH_ENCRYPTION_KEYS`, Backblaze B2, Resend, Google OAuth, Play Integrity,
  Apple DeviceCheck, OpenRouter guardrail-confirmed key, Cloud KMS reward keys,
  and receipt signing seed) into the deployment environment.
- Running `devenv shell test:server-image` on a host with Docker or Podman.
