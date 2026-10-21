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

**Webhook URL.** `https` on the standard port, a public host name or public IP
literal, no credentials and no fragment. Names such as `localhost`, `.local`,
`.internal`, and single-label hosts are refused, and the host must resolve only
to public addresses (no loopback, private, link-local, shared, documentation,
multicast, or reserved ranges, including IPv4 embedded in IPv6). The check runs
when the URL is saved and again on every call, and each connection is pinned to
the address that passed, so a DNS change cannot redirect a call into a private
network. Redirects are never followed.

**Webhook secret.** Each secret is derived from a server master key and a
per-App version, so Verily stores no secret: `rotateWebhookSecret` bumps the
version and returns the new `whsec_` value once. For 24 hours after a rotation
every request carries signatures from both the new and the previous secret.

**Redirect URIs.** At most ten. Each is an `https://host/path?query` URL or a
custom scheme such as `com.example.app://callback`; wildcards, fragments,
whitespace, `http`, script and file schemes, and `verily:` are refused.
Matching is exact string equality.

**Calling the API.** Every App request carries `Authorization: Bearer vly_…`
and `Verily-Timestamp` (current unix seconds, ±300 s). Errors are JSON
`{"error": "<code>", "message": "…"}` with stable codes: 401
`invalid_credentials` or `invalid_timestamp`, 404 `not_found`, 409 conflicts,
413 `payload_too_large`, 422 `invalid_json`, `unknown_field`, `missing_field`,
or `invalid_field` (the message names the field, never the value), and 429
`rate_limited` with `Retry-After`.

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

```http
POST /api/v1/actions
Authorization: Bearer vly_0123456789abcdef.<secret>
Verily-Timestamp: 1791820800
Content-Type: application/json

{"actionKey":"daily-situps","title":"Daily sit-ups","description":"Twenty sit-ups, every day.","recurrence":"daily","timeZone":"Europe/London","requirements":[{"requirementKey":"situps","title":"Do the sit-ups","instructions":"Log them in the app.","verification":"push"}]}
```

- The body is strict: `actionKey`, `title` (≤ 120), `description` (≤ 1000),
  `recurrence` (`once` or `daily`), `timeZone`, optional
  `maxVerifiedCompletions` (1 to 1,000,000), `opensAt`, and `closesAt`, and
  exactly one requirement with `requirementKey`, `title`, `instructions`,
  optional `isRequired` (default true), and `verification` (`push`, the
  default, or `pull`). The App never names an app id; the requirement is bound
  to the calling App.
- 201 creates a new revision; 200 updates the current draft. Posting the key of
  a published action drafts its next revision. The response is
  `{"action":{"id","actionKey","revision","status","title","recurrence","timeZone","maxVerifiedCompletions","opensAt","closesAt","publishedAt","requirements":[{"id","requirementKey","verification"}]}}`.
- `POST /api/v1/actions/<id>/publish` and `/pause` take
  `{"expectedRevision": n}` and return the same shape.
- Rewards are not attached through the API in v1: the creator adds and funds
  them in the Verily app, then publishes with `expectedRevision`.
- Codes: 403 `creator_inactive`; 404 for an action that is not this App's;
  409 `action_key_taken`, `revision_conflict`, `not_live`,
  `revision_completed`, or `invalid_state`; 422 authoring refusals in
  snake_case (`app_unavailable`, `external_proof_mixed`, `reward_not_funded`,
  `unsafe_text`, `invalid_request`, …). At most 60 writes per minute per App.

### Linking participants

Verily never shares account ids. Each participant gets a pairwise **subject**
per App: `vls_` plus 22 base64url characters (128 random bits), stable, and
different for every App so two Apps cannot correlate people.

- **Link code.** The participant copies their subject from the action sheet
  into the App, as KickJump's providers did.
- **Deep link.** The App opens
  `https://verily.fun/link?app=<appId>&redirect_uri=<registered URI>&state=…`.
  Verily checks that the redirect URI exactly matches one the App registered,
  asks the participant to confirm, then returns to
  `<redirect_uri>?code=<one-time code>&state=…`, or
  `<redirect_uri>?error=access_denied&state=…` when they decline. The App's
  backend exchanges the code for the subject:

  ```http
  POST /api/v1/links/exchange
  Authorization: Bearer vly_0123456789abcdef.<secret>
  Verily-Timestamp: 1791820800

  {"code":"<code>","redirectUri":"<the same registered URI>"}
  ```

  The answer is `{"subject":"vls_…"}`. Codes expire after 5 minutes, work
  once, and are bound to the App, the account, the redirect URI, and the state.
  Any failed check returns the same 400 `invalid_grant` and does not use the
  code up. `state` is optional, 1 to 256 printable characters.

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

An optional `"attempt": "<attempt id>"` answers a pull check that is waiting on
`pending` (below). A pull requirement accepts a push only in that form: a push
without `attempt` returns 422 `pull_requires_attempt`, an unknown attempt 404
`unknown_attempt`, and an attempt with no open check 409 `no_open_pull_check`.

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
  example a username or order number): at most 120 letters, digits, spaces,
  and `._@#:/+-`, validated server-side. It is `null` when absent; the body
  always has all seven keys.
- The App answers within 10 seconds with HTTP 200 and exactly
  `{"verdict":"accepted"|"rejected"|"pending"}`, optionally with
  `"reason":"<short code>"` matching `^[a-z0-9_]{1,64}$`. At most 4 KB is read.
- `pending` leaves the attempt waiting; the App later pushes a confirmation for
  the same attempt. Verily retries a failed call with backoff (30 s doubling,
  capped at 1 hour, at most 12 calls) and expires the check after 24 hours
  without a decisive answer, which rejects the requirement with
  `app_verification_expired`. A check that ran out of calls records no
  decision; the participant can tap again to start a new one.
- Responses are strictly parsed. Anything else (another status, extra or
  missing fields, a timeout, a blocked host) counts as a failed call, never as
  acceptance. Decisions are recorded as `verily-app-pull` with the App's reason.
- A participant can ask at most 20 times per hour per App.

### Outbound events

Every App webhook receives signed events with the same signature scheme:
`attempt.verified`, `attempt.rejected`, `payout.released`, and
`verification_request.completed`. Deliveries are durable, retried with
backoff, and logged on the App's page with their outcomes.

```http
POST <webhook URL>
Verily-Event: attempt.verified
Verily-Event-Id: vev_…
Verily-Delivery-Attempt: 1
Verily-Signature: t=1791820900,v1=<hex HMAC-SHA256(secret, t + "." + body)>
Content-Type: application/json

{"id":"vev_…","type":"attempt.verified","createdAt":"2026-10-12T08:31:40Z","data":{"attempt":"<attempt id>","action":"daily-situps","revision":1,"subject":"vls_…","period":"2026-10-12","status":"verified","settledAt":"2026-10-12T08:31:40Z"}}
```

- The HMAC key is the UTF-8 bytes of the whole `whsec_…` string. During a
  rotation's 24-hour overlap the header carries two `v1` entries; accept the
  request when either matches, and reject a `t` too far from your clock.
- `data` by type: `attempt.verified` and `attempt.rejected` as above
  (`rejected` adds `reason`); `payout.released`
  `{"payout","attempt","action","subject","amountAtoms","mint","releasedAt"}`,
  never the recipient wallet or the release signature, either of which would
  tie a subject to an on-chain identity; `verification_request.completed`
  `{"request","status","receipt"}` with the signed receipt.
- Events are queued only once the App has a webhook URL and an issued secret,
  and never carry evidence bytes, storage paths, coordinates, or account ids.
- A 2xx answer within 10 seconds delivers the event; response bodies are
  ignored. Anything else is retried with the same body and id, 30 s doubling
  to at most 2 hours, up to 12 attempts. Deduplicate on `id`. A revoked App
  receives nothing further.

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

- Combinations are checked: `place` is required for `location`; `content`,
  `shareEvidence`, and `spokenWord` are refused for `location`, and
  `spokenWord` for `photo`. Unknown fields, nulls, and wrong types return 422
  with the field named; an unregistered redirect returns 422
  `redirect_uri_not_registered`.
- The answer is 201
  `{"requestId","url":"https://verily.fun/r/<id>","appUrl":"verily://r/<id>","status":"open","expiresAt"}`.
- At most 60 requests per minute per App, and 20 acceptances per hour per App
  and person. One account accepts a request, once; anyone else is refused.
- `captureOnly` still runs through the media verifier, with a server-written
  prompt that only checks for a genuine live capture, so under manual review it
  waits for a person. `content` uses the instructions as the verification
  prompt.
- For a media request with a place, the Verily app submits the location
  first; otherwise the attempt can finish before the place is known and the
  receipt says `notChecked`.
- Expiry applies to open requests and to accepted ones with no proof yet.
  Proof that arrived in time settles through verification.

### Consent

Before anything is captured, Verily shows who is asking, what they want, and
exactly what will be shared, for example: "Slopper wants a live video of:
'show your finished sourdough'. Verily will share whether it passed, when it
was captured, and whether you were inside their place. Slopper will not see
your location." The person can decline, which returns `status=declined`.
If they open the link again, Verily tells them they declined it; anyone else
who opens it is told someone already answered.

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
- The header is `{"alg":"EdDSA","typ":"JWT","kid":"<RFC 7638 thumbprint>"}`.
  The JWKS publishes the active key and every retired key, so receipts signed
  before a rotation keep verifying.
- Each check is `passed`, `failed`, or `notChecked`; `place` is `inside`,
  `outside`, or `notChecked`. `sub` is omitted when nobody accepted or the
  person declined, and `evidence` appears only for media. The receipt never
  contains coordinates, storage paths, account ids, or the download URL.
- The receipt call is `POST /api/v1/verification-requests/<id>/receipt` with
  `{"code":"…"}` to redeem the code or `{}` to refetch with the key alone. It
  answers `{"requestId","status","receipt","evidence"?:{"url","expiresAt"}}`;
  a bad, used, or expired code is 400 `invalid_grant`, a request that is still
  open is 409 `not_ready`, and a server without a receipt key is 503
  `receipts_unavailable`. Finishing again issues a new code and invalidates
  the old one.

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

A media requirement declares its check as
`localCheck: {task: gesture|object|sound, label, minScore 0.3–0.99, minFrames 1–30}`
(always one frame for a photo). Labels come from server allow-lists: the
gesture recognizer's seven canned gestures, the 80 COCO classes, and a
reviewed subset of YAMNet sounds. The phone receives the pinned model in
`localCheckModel`. Because a model cannot hear a spoken word, the spoken
challenge is off by default for a local check; when a creator turns it on, the
replay is recorded as a vote and the AI policy or a person decides. See
[verification](verification.md#on-device-checks-replayed-on-the-server-mp-replay).

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
