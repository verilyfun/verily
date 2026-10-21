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
  motion traces), device integrity, an AI verifier or council, and people for
  the hard cases. Every rejection can be appealed once.
- **Rewards are escrowed** on Solana before the action goes live, and pay out
  one fixed amount per verified completion.

See [`PRODUCT.md`](PRODUCT.md) for the product, [`DESIGN.md`](DESIGN.md) for
the design system (built on [Skribble](https://pub.dev/packages/skribble)),
and [`docs/`](docs) for how verification, evidence storage, escrow, and
provenance work.

## Stack

| Piece         | Choice                                                         |
| ------------- | -------------------------------------------------------------- |
| App           | Flutter (Android first), Riverpod, Flutter Hooks, Skribble     |
| Server        | Serverpod 4, PostgreSQL 16 + PostGIS                           |
| Evidence      | Private Backblaze B2 (S3), version-pinned, short retention     |
| Verification  | Rules + Play Integrity + device signatures + OpenRouter models |
| Rewards       | `verily_escrow`, a [Pina](https://github.com/pina-rs/pina) program on Solana |
| Toolchain     | devenv (Nix), FVM, Monosecret                                  |

## Getting started

```bash
devenv shell install:all
```

```bash
devenv up -d
```

```bash
devenv shell dev:seeker
```

Development needs no cloud secrets: evidence is stored locally, video proof
goes to manual review, and reward escrow uses a fake gateway. Add
`VERILY_OPENROUTER_API_KEY` to the ignored `.env` to try AI verification.

## Checks

```bash
devenv shell lint:all
```

```bash
devenv shell test:all
```

## Launch media

```bash
devenv shell render:promo
```

Renders the promo reel and the launch cover to the gitignored
`.screenshots/promo/`.

## Licence

All rights reserved, Ifiok Jr.
