# Verily for other apps

Verily is useful to people and to software. Other software uses it in three
ways, all through one concept, a **Verily App**:

1. **Third-party actions.** An App creates its own actions and verifies them
   itself, through webhooks.
2. **Verify with Verily.** An App sends a person into the Verily phone app to
   capture verified evidence (a video, a photo, audio, or a location check)
   and gets a signed receipt back.
3. **The phone-only catalog.** Verily's own action kinds, verified on the phone
   and replayed on the server. No App can fake these; they are the core of
   the product.

## Verily Apps

Any creator can register an App from the Create tab or the API.

| Field          | Notes                                                                                      |
| -------------- | ------------------------------------------------------------------------------------------ |
| Name, website  | Shown to participants wherever the App appears                                             |
| API keys       | `vly_<16 hex keyId>.<43 base64url secret>`, shown once, SHA-256 stored, at most two active |
| Webhook URL    | HTTPS only; receives signed events and verification calls                                  |
| Webhook secret | `whsec_…`, used to sign outbound requests; rotatable, shown once                           |
| Redirect URIs  | Exact-match list for deep-link returns (`https://…` or a registered custom scheme)         |
| Status         | `active` or `revoked`; revoking an App revokes its keys and pauses its actions             |

An App belongs to one creator account. Everything it does is attributed to
that creator, including rewards it attaches to actions.

## Trust tiers

Participants always see who vouches for an action.

| Tier                      | Label on the card          | What Verily vouches for                                                                   |
| ------------------------- | -------------------------- | ----------------------------------------------------------------------------------------- |
| Phone-verified (built-in) | **Verified on your phone** | The proof was captured live in Verily, signed by the device, and checked by Verily        |
| Third-party               | **Confirmed by \<App\>**   | The App, authenticated by its key, said it happened. Verily does not check the act itself |

A v1 action is one or the other, never both. A third-party action can still
carry an escrowed reward: the creator is trusting their own App.

## 1. Third-party actions

### Creating actions through the API

`POST /api/v1/actions` with an App key creates a draft action owned by the
App's creator, using the same validation as the app's designer. Publishing,
pausing, and reward funding work as they do for any action. A third-party
action's requirements are `external` requirements bound to the App.

### Linking participants

Verily never shares account ids. Each participant gets a pairwise **subject**
per App: `vls_` plus 22 base64url characters (128 random bits), stable, and
different for every App so two Apps cannot correlate people.

- **Link code.** The participant copies their subject from the action sheet
  into the App, as KickJump's providers did.
- **Deep link.** The App opens `https://verily.fun/link?app=<appId>&state=…`.
  Verily asks the participant to confirm, then returns to the App's redirect
  URI with a one-time `code`. The App's backend exchanges the code for the
  subject with `POST /api/v1/links/exchange`. Codes expire after 5 minutes and
  work once.

### Verification: push or pull

Each `external` requirement chooses how its App verifies it.

**Push (confirmations).** The App tells Verily something happened. This is
the KickJump provider contract, renamed:

```http
POST /api/v1/confirmations
Authorization: Bearer vly_0123456789abcdef.<secret>
Verily-Timestamp: 1791820800
Content-Type: application/json

{"eventId":"evt_123","action":"daily-situps","subject":"vls_ABCDEFGHIJKLMNOPQRSTUV","occurredAt":"2026-10-12T08:30:00Z"}
```

Strict body, `eventId` idempotency with an append-only receipt, a ±300 s
timestamp window, per-App rate limits, and the same typed responses as the
KickJump contract.

**Pull (verification webhook).** When a participant taps **I did it** on a
pull action, Verily asks the App:

```http
POST <webhook URL>
Verily-Event: attempt.verify
Verily-Signature: t=1791820800,v1=<hex HMAC-SHA256(secret, t + "." + body)>
Content-Type: application/json

{"id":"vev_…","type":"attempt.verify","attempt":"<attempt id>","action":"daily-situps","subject":"vls_…","reference":"order-1234","requestedAt":"2026-10-12T08:31:00Z"}
```

- `reference` is an optional, bounded string the participant typed (for
  example a username or order number), validated server-side.
- The App answers within 10 seconds with
  `{"verdict":"accepted"|"rejected"|"pending","reason":"<short code>"}`.
- `pending` leaves the attempt waiting; the App later pushes a confirmation for
  the same attempt. Verily retries a failed call with backoff and expires the
  attempt after 24 hours without an answer.
- Responses are strictly parsed. Anything else counts as a failed call, never
  as acceptance.

### Outbound events

Every App webhook receives signed events with the same signature scheme:
`attempt.verified`, `attempt.rejected`, `payout.released`, and
`verification_request.completed`. Deliveries are durable, retried with
backoff, and logged on the App's page with their outcomes.

## 2. Verify with Verily (deep links)

Any App can ask a person to prove something with the Verily phone app, the way
apps ask a wallet to sign. The flow is OAuth-shaped so nothing in a URL is
trusted:

```mermaid
sequenceDiagram
  participant AppServer as App backend
  participant AppUI as App on the phone
  participant V as Verily app
  participant API as Verily server

  AppServer->>API: POST /api/v1/verification-requests (kind, instructions, place, redirect, state)
  API-->>AppServer: requestId, url
  AppServer-->>AppUI: url
  AppUI->>V: open https://verily.fun/r/<requestId>
  V->>API: load request (who is asking, for what)
  V-->>V: consent, sign in, live capture with full provenance
  V->>API: upload and verify
  V->>AppUI: redirect_uri?request_id=…&state=…&code=…
  AppUI->>AppServer: code
  AppServer->>API: POST /api/v1/verification-requests/<id>/receipt (code)
  API-->>AppServer: signed receipt
```

### Request

| Field              | Notes                                                                                         |
| ------------------ | --------------------------------------------------------------------------------------------- |
| `kind`             | `video`, `photo`, `audio`, or `location`                                                      |
| `instructions`     | Optional, at most 280 characters, shown to the person; passes `ModelInputSecurity`            |
| `check`            | `captureOnly` (provenance only) or `content` (Verily also checks the instructions were met)   |
| `place`            | Optional `{latitude, longitude, radiusMeters}`; the receipt says inside or outside, not where |
| `liveChallenge`    | `spokenWord` (default for video and audio) or `none`                                          |
| `shareEvidence`    | Whether the App may download the capture; the person sees this before consenting              |
| `redirectUri`      | Must exactly match one of the App's registered redirect URIs                                  |
| `state`            | Opaque, at most 256 characters, returned unchanged                                            |
| `expiresInSeconds` | 60 to 3600                                                                                    |

The deep link carries only the request id. The Verily app loads everything
else from the server, so a forged link can only point at a real request.

### Consent

Before anything is captured, Verily shows who is asking, what they want, and
exactly what will be shared, for example: "Slopper wants a live video of:
'show your finished sourdough'. Verily will share whether it passed, when it
was captured, and whether you were inside their place. Slopper will not see
your location." The person can decline, which returns `status=declined`.

### Receipt

A JWS signed with Verily's receipt key (EdDSA), verifiable against
`https://verily.fun/.well-known/jwks.json`:

```json
{
  "iss": "https://verily.fun",
  "aud": "<appId>",
  "sub": "vls_…",
  "jti": "<requestId>",
  "iat": 1791820900,
  "kind": "video",
  "status": "verified",
  "checks": {
    "liveCapture": "passed",
    "deviceIntegrity": "passed",
    "captureSignature": "passed",
    "place": "inside",
    "liveChallenge": "passed",
    "content": "passed"
  },
  "capturedAt": "2026-10-12T08:30:12Z",
  "evidence": { "sha256": "…", "mimeType": "video/mp4", "durationSeconds": 14 }
}
```

- `status` is `verified`, `rejected`, `pendingReview`, `declined`, or
  `expired`. A pending receipt can be fetched again; the final one is also
  delivered as a `verification_request.completed` event.
- With `shareEvidence` and consent, the receipt endpoint also returns a
  5-minute download URL for the pinned original. It is never in the JWS.
- Codes work once and expire after 5 minutes; receipts can always be fetched
  again with the App's key.

Under the hood a verification request is a private, single-use action with one
attempt, so it uses exactly the same capture, upload, provenance, and
verification pipeline as everything else. It never appears in any feed and
carries no reward in v1.

## 3. The phone-only catalog

These action kinds can only be verified by Verily on a phone. They are the
heart of the product and the reason Apps send people here.

| Kind                  | Proof                                                    | How it is checked                                      |
| --------------------- | -------------------------------------------------------- | ------------------------------------------------------ |
| Place check-in        | A fresh, accurate location fix                           | PostGIS radius, freshness, travel plausibility         |
| Venue or event code   | A QR code that only exists at the place, rotating        | Server-issued, single-use, short-lived codes           |
| Show a gesture        | Photo or short video: thumbs up, victory, open palm, …   | MP gesture recognizer on the phone, replayed on server |
| Show a thing          | Photo or short video of an object (bicycle, dog, cup, …) | MP object detector, replayed on server                 |
| Make a sound          | Audio: clapping, whistling, a bell, a dog barking, …     | MP audio classifier, replayed on server                |
| Do the reps           | Video of squats, press-ups, kick-ups, and nine more      | MP pose (and ball) tracking live, AI or person checks  |
| Move the phone        | Toss and catch, spins, shakes, a steady hand             | Sensor trace recomputed on the server                  |
| Describe it on camera | Video or photo with free-form instructions               | AI verifier or council, people for the hard cases      |

Every media proof can add the **spoken challenge**: a word from Verily's own
list that the person says while recording, so a pre-recorded or generated clip
cannot contain it.

## Local verification with MP

Simple actions are checked by MediaPipe models running through
[MP](https://github.com/ifiokjr/mediapipe) (`mp_vision`, `mp_audio`,
`mp_camera`), following MP's own rule that a local result is guidance, never
authorization:

1. **On the phone,** the pinned model runs live while the person captures.
   It guides ("we can't see your thumb yet") and finishes the capture the
   moment the gesture, object, sound, or rep is detected.
2. **The device result is advisory.** It is submitted with the evidence, the
   model id, and the model's SHA-256, kept for calibration, and never used to
   decide anything.
3. **On the server,** Verily replays the same digest-pinned model over the
   evidence it pinned in storage (frames sampled from the video, the photo, or
   the decoded audio). That replay is the decision, recorded with
   `verifierType = mp-replay` and the model digest.
4. **No runtime, no shortcut.** Where the server cannot run the model, the
   requirement falls back to its AI policy or to a person. It never trusts the
   phone's result alone.

Models are pinned by URL, byte length, and SHA-256, downloaded once, and
verified on every load, on the phone and on the server.

## Security notes

- App keys, webhook secrets, link codes, and receipt codes are high-entropy,
  shown once where applicable, compared in constant time, and never logged.
- Webhook calls carry no evidence bytes and no precise location. Apps learn
  what the participant consented to share, and nothing about other Apps.
- A verification request can be completed once, by one account, before it
  expires. Apps are rate-limited per key and per subject.
- An App's word is trusted only for its own `external` requirements. It can
  never satisfy a phone-only requirement, release a reward on a phone-verified
  action, or read another creator's actions.
