# Verily

**Do it. Prove it. Get paid.** [verily.fun](https://verily.fun)

Verily is an actions database where every action happens somewhere real.

- **Creators post actions** with a place (a pin and a radius, or a code that
  only exists at the venue), the proof they need (video, photo, audio, a motion
  pattern, or reps counted by the camera), and an optional reward.
- **Participants do them** with proof captured live in the app. There is no
  upload button: the camera is the only way in, each attempt gets a fresh
  spoken challenge, and every capture is signed on the device.
- **Verily verifies the proof** with deterministic rules (place, venue codes,
  motion traces), device integrity (Android Key Attestation, Play Integrity,
  Apple App Attest / DeviceCheck), MediaPipe local-check replay, an OpenRouter
  AI verifier or council behind `ModelInputSecurity`, and people for the hard
  cases. Every rejection can be appealed once.
- **Rewards are escrowed** on Solana before the action goes live, and pay out
  one fixed amount per verified completion.

See [`PRODUCT.md`](PRODUCT.md) for the product, [`DESIGN.md`](DESIGN.md) for
the design system (built with `leptoskit_skribble` and `verily_ink`), and
[`docs/`](docs) for how verification, evidence storage, escrow, provenance, and
the LeptosKit architecture work.

## Stack

| Piece        | Choice                                                                                                  |
| ------------ | ------------------------------------------------------------------------------------------------------- |
| App & Web    | [LeptosKit](https://github.com/leptoskit/leptoskit) (`verily_kit/verily_app`), `leptoskit_skribble`     |
| Server       | LeptosKit Axum + RPC + Auth + Jobs (`verily_kit/verily_backend`), PostgreSQL 19 + PostGIS 3.7           |
| MediaPipe    | [`leptoskit/mediapipe`](https://github.com/leptoskit/mediapipe) (on-device HUD + server replay)         |
| Evidence     | Private Backblaze B2 (S3v4), version-pinned, short retention                                            |
| Verification | Rules + Key Attestation / App Attest / Play Integrity + OpenRouter council + manual review              |
| Rewards      | `verily_escrow` ([Pina](https://github.com/pina-rs/pina)) + [`pina-rs/solana_kit`](https://github.com/pina-rs/solana_kit) + Cloud KMS |
| Toolchain    | devenv (Nix), Rust, Monosecret, Docker                                                                  |

## Getting started

```bash
devenv up -d
```

```bash
devenv shell dev:kit
```

Or on a connected Seeker Android device:

```bash
devenv shell dev:seeker
```

Development needs no cloud secrets: evidence is stored locally, media proof
goes to manual review, and reward escrow stays disabled or simulated until
configured. Add `VERILY_OPENROUTER_API_KEY` to the ignored `.env` to try AI
verification.

## Checks

```bash
devenv shell lint:all
```

```bash
devenv shell test:all
```

## Production container

```bash
docker build --platform linux/amd64 -f verily_kit/Dockerfile -t verily-kit .
```

## Licence

All rights reserved, Ifiok Jr.
