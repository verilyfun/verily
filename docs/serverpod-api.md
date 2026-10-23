# Serverpod API

The Verily backend is a Serverpod 4.0.4 server in `verily_server`, with the
generated client in `verily_client`. Every endpoint below requires sign-in and
derives the caller from the session; no method takes an account id. Creator
methods re-check ownership on every call. Methods are named as the generated
client calls them (`client.<endpoint>.<method>`).

Local ports (see `devenv.nix`): API 8180, Insights 8181, web 8182, Postgres
8191 (databases `verily` and `verily_test`).

## Endpoints

### `actionVerification`

| Method                                                                      | Purpose                                                                                                       |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `listTemplates()`                                                           | The twelve value-free templates                                                                               |
| `draftActionFromPrompt(prompt:)`                                            | AI draft proposal; throws `ActionDraftingUnavailableException` when AI is off or the daily allowance is spent |
| `createAction(request)` / `saveActionDraft(request)`                        | Create or update the caller's draft (optional `reward` terms)                                                 |
| `previewAction(actionId:)`                                                  | The creator's full view, including creator-only rule fields; typed not-found                                  |
| `listOwnedActions(limit:)`                                                  | The caller's own actions                                                                                      |
| `publishAction(actionId:, expectedRevision:)`                               | Publish; a rewarded action needs a funded pool                                                                |
| `pauseAction(actionId:, expectedRevision:)`                                 | Stop new attempts                                                                                             |
| `createQrChallenge(requirementId:, validitySeconds:)`                       | A short-lived, single-use venue code (`verily:v1:`)                                                           |
| `getAction(actionId:)`                                                      | One action for a deep-linked page (published, or the caller's own); typed not-found                           |
| `listAvailableActions(limit:)`                                              | Live actions for the caller                                                                                   |
| `listNearbyActions(latitude:, longitude:, radiusKm:, limit:)`               | Live actions with a place within 0.1 to 50 km, nearest first                                                  |
| `beginAttempt(actionId:, idempotencyKey:)`                                  | Open (or return) the caller's attempt for this period                                                         |
| `issueSpokenChallenge(attemptId:, requirementId:)`                          | The word to say while recording                                                                               |
| `beginCapture(attemptId:, requirementId:)`                                  | Open a capture window before recording: the nonce the phone's fresh capture key attests                       |
| `submitEvidence(input)`                                                     | Location, venue code, or motion proof                                                                         |
| `requestMediaUpload(attemptId:, requirementId:, contentType:, byteLength:)` | Upload description for `FileUploader`                                                                         |
| `confirmMediaUpload(confirmation)`                                          | Inspect the upload and queue verification                                                                     |
| `requestAppVerification(attemptId:, requirementId:, reference:)`            | "I did it" on a pull-verified `externalApp` requirement: Verily asks the App (`status` null while waiting)    |
| `getAppVerification(attemptId:, requirementId:)`                            | Where that "I did it" stands, in the same shape; null before the caller asks. Calls nobody                    |
| `completeAttempt(attemptId)`                                                | Finish an attempt whose proof is accepted                                                                     |
| `listMyAttempts(limit:)`                                                    | The caller's attempts                                                                                         |

### `appAttest`

How an iPhone registers the App Attest key it signs captures with (see
[Apple App Attest](verification.md#apple-app-attest)).

| Method                                                  | Purpose                                                                                 |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `beginRegistration()`                                   | A single-use, five-minute challenge (`AppAttestChallengeView`); ten an hour per account |
| `registerKey(challengeId:, keyId:, attestationObject:)` | Verify Apple's attestation over `SHA-256(challenge)` and register the key to the caller |

Both throw `AppAttestException` with an `AppAttestProblem`: `unavailable`
(this server has no Apple team configured; do not retry), `rateLimited`,
`challengeInvalid` (ask for a new challenge), or `keyRejected` (make a new
key before trying again).

### `rewards` and `payoutWallet`

| Method                                                              | Purpose                                                                          |
| ------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `rewards.getRewardPool(actionId:)`                                  | The creator's pool state                                                         |
| `rewards.prepareRewardFunding(actionId:)`                           | Freeze terms; return the escrow address and an unsigned `OpenEscrow` transaction |
| `rewards.confirmRewardFunding(actionId:, signature:)`               | Verify the escrow from chain state and mark the pool funded                      |
| `rewards.endRewardEarly(actionId:)`                                 | Stop new payouts; return an unsigned `EndEarly` transaction                      |
| `rewards.listMyPayouts(limit:)`                                     | The caller's payouts                                                             |
| `payoutWallet.getMine()`                                            | The caller's linked payout wallet                                                |
| `payoutWallet.createWalletLinkChallenge(walletAddress:)`            | Text for the wallet to sign (5 minutes)                                          |
| `payoutWallet.linkPayoutWallet(walletAddress:, nonce:, signature:)` | Verify the ed25519 signature and link; wakes payouts waiting for a wallet        |

See [reward escrow](reward-escrow.md).

### `verilyApp`

| Method                                              | Purpose                                                                                 |
| --------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `listApps()`                                        | The caller's Apps                                                                       |
| `getApp(appId:)`                                    | One of the caller's Apps, for its detail page; typed not-found                          |
| `createApp(name:, websiteUrl:)`                     | Register an App; returns its first key once                                             |
| `createKey(appId:)`                                 | A new `vly_<keyId>.<secret>` key, shown once (at most two active)                       |
| `revokeKey(appId:, keyId:)`                         | Revoke one key                                                                          |
| `revokeApp(appId:)`                                 | Revoke the App and its keys; pauses its actions                                         |
| `listConfirmations(appId:, limit:, beforeId:)`      | Append-only receipts, newest first                                                      |
| `linkApp(appId:)`                                   | The caller's pairwise `vls_` subject for an App with a live action                      |
| `setWebhookUrl(appId:, webhookUrl:)`                | Set (or clear with null) the https URL for events and pull calls; private hosts refused |
| `rotateWebhookSecret(appId:)`                       | The next `whsec_` secret, shown once; the previous one keeps signing for 24 h           |
| `setRedirectUris(appId:, redirectUris:)`            | Replace the exact-match deep-link return addresses (at most ten)                        |
| `listWebhookDeliveries(appId:, limit:, beforeId:)`  | The append-only outbound call log, newest first, with each event's state                |
| `describeLinkRequest(appId:, redirectUri:, state:)` | What to show before linking to an App that opened `/link`                               |
| `approveLink(appId:, redirectUri:, state:)`         | Link and return the App's redirect with a one-time, five-minute code                    |
| `declineLink(appId:, redirectUri:, state:)`         | Return the App's redirect with `error=access_denied`                                    |

See [platform](platform.md).

### `verificationRequest`

The Verily app's side of `https://verily.fun/r/<id>` and `verily://r/<id>`.

| Method                   | Purpose                                                                                                                            |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `getRequest(requestId:)` | Who is asking, for what, and what will be shared (`VerificationRequestView`; `declinedByViewer` when the caller turned it down)    |
| `accept(requestId:)`     | Accept; the view carries the private single-use action to capture against                                                          |
| `decline(requestId:)`    | The App's redirect with `status=declined`                                                                                          |
| `finish(requestId:)`     | After the proof is submitted: the App's redirect with a one-time receipt code; `verificationRequestProofMissing` before it arrives |

After `accept`, the app runs the normal flow on `view.action`: `beginAttempt`,
then location (first, when the request has a place) and media proof, then
`finish`. The private action never appears in any list.

### Review, appeals, moderation, account

| Method                                                                      | Access                    | Purpose                                                              |
| --------------------------------------------------------------------------- | ------------------------- | -------------------------------------------------------------------- |
| `evidenceReview.listQueue(limit:)`                                          | scope `evidence.review`   | Proof waiting for a person, with private links to the pinned version |
| `evidenceReview.review(evidenceId:, decision:, note:)`                      | scope `evidence.review`   | Accept or reject; accepting completes the attempt                    |
| `evidenceAppeal.submit(attemptId:, reason:)` / `getMine(attemptId:)`        | participant               | Contest a rejection                                                  |
| `evidenceAppeal.listOwned(limit:)` / `resolve(appealId:, decision:, note:)` | action creator            | Appeals on the caller's actions                                      |
| `moderation.report` / `getStatus` / `listMine` / `appeal`                   | any account               | Report an action and follow the case                                 |
| `moderationReview.listQueue` / `getCase` / `review` / `resolveAppeal`       | scope `moderation.review` | Decide cases and appeals                                             |
| `accountLifecycle.closeAccount(confirmation:)`                              | account owner             | Close the account, revoke sessions, pause the caller's live actions  |

Authentication uses Serverpod's identity providers: `emailIdp`, `googleIdp`
(when configured), and `jwtRefresh`.

### Errors

Typed, product-safe exceptions reach the client: `ResourceNotFoundException`
(with a `MissingResource`: `action` or `app`; the message never says whether
the thing is missing or hidden), `ActionAuthoringException`
(with an `ActionAuthoringProblem`), `ActionDraftingUnavailableException`,
`AppUnavailableException`, `AppAttestException` (with an `AppAttestProblem`),
`AppPlatformException` (with an
`AppPlatformProblem`: `invalidWebhookUrl`, `webhooksUnavailable`,
`invalidRedirectUri`, `tooManyRedirectUris`, `linkRequestInvalid`,
`linkCodeInvalid`, `pullVerificationUnavailable`, `invalidReference`,
`verificationRequestNotFound`, `verificationRequestExpired`,
`verificationRequestTaken`, `verificationRequestClosed`,
`verificationRequestProofMissing`, `rateLimited`), and
`RewardException` (with a `RewardProblem`).
Anything else becomes a generic error; provider names, routes, and stack traces
stay in server logs.

`createAction` and `saveActionDraft` refuse a request that breaks an authoring
rule with `ActionAuthoringProblem.invalidRequest`, and refuse unsafe wording
with `unsafeText`. These are the RPC counterparts of the App API's
`invalid_request` and `unsafe_text`. The `invalidRequest` message names the
broken rule for developers, so the app shows its own copy instead. Only
authoring validation produces these two; a server bug in the same call stays a
generic error.

## Web routes

| Route                                                   | Purpose                                                         |
| ------------------------------------------------------- | --------------------------------------------------------------- |
| `GET /`, `/index.html`                                  | Landing page                                                    |
| `GET /healthz`                                          | Liveness and database check                                     |
| `GET /app/assets/assets/config.json`                    | Public API URL for the web app                                  |
| `POST /api/v1/confirmations`                            | App confirmations, optionally naming a pull-checked `attempt`   |
| `POST /api/v1/actions`                                  | Create or update a draft action owned by the App's creator      |
| `POST /api/v1/actions/:actionId/publish`, `/pause`      | Publish or pause it (`{"expectedRevision": n}`)                 |
| `POST /api/v1/links/exchange`                           | Trade a deep-link code for the pairwise `vls_` subject          |
| `POST /api/v1/verification-requests`                    | Ask one person to prove something with the Verily app           |
| `POST /api/v1/verification-requests/:requestId/receipt` | The signed receipt (with the code, or the key alone to refetch) |
| `GET /.well-known/jwks.json`                            | Public keys that verify receipts                                |
| `/app`                                                  | The built Flutter web app, when `web/app` exists                |

## Background work

All recurring calls are durable Serverpod future calls, re-registered once at
startup:

| Call                                                                    | Interval  |
| ----------------------------------------------------------------------- | --------- |
| Evidence upload cleanup                                                 | daily     |
| QR, capture, and spoken challenge cleanup                               | daily     |
| Payout wallet challenge cleanup                                         | daily     |
| Evidence verification recovery (stranded jobs and `verifying` attempts) | 5 minutes |
| Reward payout recovery (missed releases, expired pools)                 | 5 minutes |
| Deep-link code cleanup                                                  | daily     |
| App event recovery (due retries, expired delivery leases)               | 1 minute  |
| Pull check recovery (due retries, 24-hour expiry)                       | 1 minute  |
| Verification request expiry (and its final event)                       | 1 minute  |

One-off calls: `evidenceVerification.verify` per uploaded proof,
`rewardPayout.release` per reserved payout, `appEventDelivery.deliver` per
event attempt, and `appPullCheck.check` per pull retry. All are idempotent.

## Running

```bash
devenv shell server:start   # development, applies migrations, resolves secrets via Monosecret
devenv shell test:server    # unit + integration (Postgres 8191) + packages/verily_evidence
```

`bin/main.dart` resolves secrets through Monosecret in a parent process and
starts the server as a child with `VERILY_MONOSECRET_LOADED=1`. Startup refuses
any partial or unsafe configuration (verifier mode, AI deployment, capture
integrity, static QR codes outside development, evidence storage, reward
escrow, review threshold). `bin/check_verily_production_readiness.dart` and
`bin/check_release_secrets.dart` evaluate release gates without reading
secrets from 1Password.

## App API contracts

Every `/api/v1` call takes `Authorization: Bearer vly_…` and
`Verily-Timestamp` (±300 s) and answers typed JSON errors. Request and
response bodies, limits, signatures, and event payloads are specified in
[platform](platform.md); the signed receipt claims are in
[platform](platform.md#receipt).

Platform keys come from Monosecret: `VERILY_WEBHOOK_SIGNING_MASTER_KEY`
(webhook secrets are derived from it), `VERILY_RECEIPT_SIGNING_KEY` (the
Ed25519 receipt seed), and `VERILY_RECEIPT_RETIRED_PUBLIC_KEYS` (still
published after a rotation). Development generates the first two; staging and
production require them. A missing key disables only webhooks or receipts,
with typed errors; a malformed one stops startup.

## Reason codes the app sees

`EvidenceSubmissionResult.reasonCode` and `ActionAttemptView.rejectionCode`
are always one of these public codes. Internal verifier codes, model and
provider details, and reasons an App sent are kept on the decision for audit
and never returned. `summary` is short product copy.

| Code                                                                             | Meaning                                                                         |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `proof_accepted`                                                                 | The proof passed                                                                |
| `checking`                                                                       | Verification is running                                                         |
| `needs_review`                                                                   | A person will check it                                                          |
| `proof_not_accepted`                                                             | It did not show what the action asks for                                        |
| `proof_missing`                                                                  | Required proof is still missing                                                 |
| `action_full`                                                                    | The action reached its completion limit                                         |
| `outside_area`, `location_not_precise`, `location_too_old`                       | The location check failed for that reason                                       |
| `phone_clock`                                                                    | The capture time does not match the phone clock                                 |
| `recording_length`                                                               | The recording was too short or too long                                         |
| `challenge_word_missing`, `challenge_word_too_early`, `challenge_word_not_heard` | The spoken word was not fetched, came after recording started, or was not heard |
| `code_not_matched`                                                               | The venue code did not match                                                    |
| `motion_not_matched`                                                             | The phone movement did not match                                                |
| `capture_not_verified`                                                           | The phone could not verify the capture                                          |
| `payout_review`                                                                  | A person checks it because the reward is large                                  |
| `app_confirmed`, `app_not_confirmed`                                             | The App confirmed, or did not                                                   |
| `app_checking`, `app_unreachable`, `app_no_answer`                               | Asking the App; it could not be reached; it never answered                      |

Reviewers see `EvidenceReviewQueueItem.reviewReasonCode` as one of
`payout_review`, `security_review`, `challenge_word_unclear`,
`location_review`, `abuse_review`, `local_check_unavailable`,
`verifier_unavailable`, `low_confidence`, or `needs_review`.

## Client-visible changes since the platform phase

All additive: new fields are nullable or defaulted, and no field or method was
removed or renamed.

- `actionVerification.getAction(actionId:)` (new) returns the participant view
  of one action: any published public action, including paused and completed
  ones, or the caller's own drafts. Other drafts, private verification-request
  actions, actions under a safety hold, and unknown ids throw
  `ResourceNotFoundException(resource: action)`.
- `actionVerification.previewAction` now throws
  `ResourceNotFoundException(resource: action)` instead of a generic error.
- `verilyApp.getApp(appId:)` (new) returns one `VerilyAppView`; unknown or
  someone else's App throws `ResourceNotFoundException(resource: app)`.
- `ActionAttemptView.actionTitle` and `actionKey` (new, nullable) are filled on
  every attempt the endpoints return, including `listMyAttempts`.
- `ActionRequirementView.verificationPrompt`, `minConfidence`, and
  `venueCodeConfigured` (new, nullable) are filled only in the creator's own
  views (`previewAction`, `listOwnedActions`, creator `getAction`), so the
  editor can save a loaded draft back without losing anything.
  `verificationPrompt` is null when the server writes it (tracked movements,
  and local checks saved without creator text); send it back as null.
- Venue codes: saving a draft with `qrCode: null` keeps the secret already
  stored for that requirement key, including when editing a published action
  creates its next revision. To rotate a static code, save the draft with a
  new `qrCode` and publish it. Live, single-use codes from `createQrChallenge`
  rotate on their own. A venue-code requirement with no stored secret still
  needs a code.
- `RewardSummary.refundDelayDays` (new, defaults to 7 in older payloads)
  mirrors the terms draft; the pool stores seconds.
- `ResourceNotFoundException` and the `MissingResource` enum (new).
- `EvidenceSubmissionResult.reasonCode`, `ActionAttemptView.rejectionCode`, and
  `EvidenceReviewQueueItem.reviewReasonCode` now carry only the public codes
  above.
- The participant pull trigger is `actionVerification.requestAppVerification`
  ("I did it", with an optional `reference` of at most 120 characters).
- `actionVerification.getAppVerification(attemptId:, requirementId:)` (new)
  reads where that "I did it" stands, in the `requestAppVerification` shape,
  so a reopened page shows waiting, confirmed, or rejected; it returns null
  before the participant asks and never calls the App. A push-verified
  requirement throws `AppPlatformException(pullVerificationUnavailable)`.
- `verificationRequest.finish` before the proof arrives now throws
  `AppPlatformException(verificationRequestProofMissing)` (new problem)
  instead of a generic error.
- `VerificationRequestView.declinedByViewer` (new, defaults to false) is true
  only for the account that declined the request.

## Capture attestation changes (not additive)

Verily is unreleased, so attested capture replaced the old capture challenge
outright. See [capture integrity](verification.md#capture-integrity).

- `actionVerification.createCaptureChallenge(attemptId:, requirementId:,
  evidenceBindingHash:)` is gone. `beginCapture(attemptId:, requirementId:)`
  opens the window before anything is captured.
- `ActionCaptureChallengeView` drops `requestHash` and adds
  `captureChallenge` (32 bytes, unpadded base64url) and `issuedAt`. The app
  derives the Play Integrity request hash itself with
  `captureIntegrityRequestHash` from `packages/verily_evidence` (domain
  `verily-capture-request-v2`), and the capture key's attestation challenge
  with `captureKeyAttestationChallenge`.
- `ActionEvidenceInput` and `MediaUploadConfirmation` drop
  `capturePublicKey`, `captureKeyId`, and `captureKeyStorage`, and add
  `captureCertificateChain` (base64 DER, leaf first). The server reads the
  key, its id, and its storage level from the attested leaf only.
- `EvidenceProvenanceLevel.hardwareAttested` (new) is the level of a proof
  signed by a key whose attestation verified.
- New internal reason codes (`capture_predates_challenge`,
  `capture_attestation_*`, `device_integrity_not_strong`) reach participants
  as `capture_not_verified`; the review reasons `device_capture_risk` and
  `device_activity_risk` reach reviewers as `security_review`.

## App Attest changes

iPhone capture signing (Phase 2) is additive.

- `appAttest.beginRegistration()` and `appAttest.registerKey(challengeId:,
  keyId:, attestationObject:)` (new), with `AppAttestChallengeView`,
  `AppAttestException`, and `AppAttestProblem`.
- `ActionEvidenceInput.captureAppAttestKeyId` and
  `MediaUploadConfirmation.captureAppAttestKeyId` (new, nullable): the
  registered key id. An iPhone sends it with the manifest and its App Attest
  assertion in `captureSignature`, and no `captureCertificateChain`; sending
  both is refused.
- `EvidenceProvenanceLevel.secureEnclaveAttested` (new): a registered App
  Attest key asserted the capture. Exhaustive switches over the enum need the
  new case.
- `packages/verily_evidence` adds `appAttestRegistrationClientDataHash` and
  `appAttestAssertionClientDataHash`, the two `clientDataHash` values both
  sides compute.
- New internal reason codes (`capture_app_attest_*`,
  `capture_signature_ambiguous`) reach participants as
  `capture_not_verified`.

### Apple device risk and durable restrictions

- `ActionEvidenceInput.captureDeviceCheckToken` and
  `MediaUploadConfirmation.captureDeviceCheckToken` carry an ephemeral base64
  DeviceCheck token. It is bound to the manifest through
  `appAttestDeviceClientData` before `appAttestAssertionClientDataHash`; it is
  never stored. Older assertions without a token can verify their signature
  but always require manual review.
- Initial registration now verifies the fraud receipt as well as the
  attestation. An invalid receipt returns `AppAttestProblem.keyRejected`.
  Verified refreshed metrics at least 10 require `device_activity_risk`
  review. Unavailable/stale risk checks use
  `apple_device_risk_unavailable`; bit 1 uses `apple_device_review`. All map
  to the public `security_review`. Bit 0 refuses proof with
  `capture_device_banned`, exposed as `capture_not_verified`.
- `deviceCheck.query(deviceToken:)` returns `DeviceCheckBits(banned,
  reviewRequired)`. `deviceCheck.update(deviceToken:, banned:,
  reviewRequired:, note:)` explicitly sets both bits, with a nonempty audit
  note of at most 1000 characters. Both require login, an active account and
  the dedicated `device-check.manage` scope; ordinary participants and
  evidence reviewers cannot update flags. Apple/configuration failures throw
  `AppAttestException(unavailable)` and never return simulated success.
- Internal `AppAttestReceiptRefreshTask` maintains receipts before expiration;
  `DeviceCheckAudit` records update intent before HTTP and completion after
  Apple's success. A missing completion can mean Apple applied the update:
  query the bits before retrying. No raw token is retained.
