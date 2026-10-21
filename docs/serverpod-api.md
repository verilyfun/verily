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
| `previewAction(actionId:)`                                                  | The creator's view of a draft                                                                                 |
| `listOwnedActions(limit:)`                                                  | The caller's own actions                                                                                      |
| `publishAction(actionId:, expectedRevision:)`                               | Publish; a rewarded action needs a funded pool                                                                |
| `pauseAction(actionId:, expectedRevision:)`                                 | Stop new attempts                                                                                             |
| `createQrChallenge(requirementId:, validitySeconds:)`                       | A short-lived, single-use venue code (`verily:v1:`)                                                           |
| `listAvailableActions(limit:)`                                              | Live actions for the caller                                                                                   |
| `listNearbyActions(latitude:, longitude:, radiusKm:, limit:)`               | Live actions with a place within 0.1 to 50 km, nearest first                                                  |
| `beginAttempt(actionId:, idempotencyKey:)`                                  | Open (or return) the caller's attempt for this period                                                         |
| `issueSpokenChallenge(attemptId:, requirementId:)`                          | The word to say while recording                                                                               |
| `createCaptureChallenge(attemptId:, requirementId:, evidenceBindingHash:)`  | Device-integrity nonce bound to one capture                                                                   |
| `submitEvidence(input)`                                                     | Location, venue code, or motion proof                                                                         |
| `requestMediaUpload(attemptId:, requirementId:, contentType:, byteLength:)` | Upload description for `FileUploader`                                                                         |
| `confirmMediaUpload(confirmation)`                                          | Inspect the upload and queue verification                                                                     |
| `completeAttempt(attemptId)`                                                | Finish an attempt whose proof is accepted                                                                     |
| `listMyAttempts(limit:)`                                                    | The caller's attempts                                                                                         |

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

| Method                                         | Purpose                                                            |
| ---------------------------------------------- | ------------------------------------------------------------------ |
| `listApps()`                                   | The caller's Apps                                                  |
| `createApp(name:, websiteUrl:)`                | Register an App; returns its first key once                        |
| `createKey(appId:)`                            | A new `vly_<keyId>.<secret>` key, shown once (at most two active)  |
| `revokeKey(appId:, keyId:)`                    | Revoke one key                                                     |
| `revokeApp(appId:)`                            | Revoke the App and its keys; pauses its actions                    |
| `listConfirmations(appId:, limit:, beforeId:)` | Append-only receipts, newest first                                 |
| `linkApp(appId:)`                              | The caller's pairwise `vls_` subject for an App with a live action |

See [platform](platform.md).

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

Typed, product-safe exceptions reach the client: `ActionAuthoringException`
(with an `ActionAuthoringProblem`), `ActionDraftingUnavailableException`,
`AppUnavailableException`, and `RewardException` (with a `RewardProblem`).
Anything else becomes a generic error; provider names, routes, and stack traces
stay in server logs.

## Web routes

| Route                                | Purpose                                                          |
| ------------------------------------ | ---------------------------------------------------------------- |
| `GET /`, `/index.html`               | Landing page                                                     |
| `GET /healthz`                       | Liveness and database check                                      |
| `GET /app/assets/assets/config.json` | Public API URL for the web app                                   |
| `POST /api/v1/confirmations`         | Verily App confirmations (Bearer `vly_` key, `Verily-Timestamp`) |
| `/app`                               | The built Flutter web app, when `web/app` exists                 |

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

One-off calls: `evidenceVerification.verify` per uploaded proof and
`rewardPayout.release` per reserved payout. Both are idempotent.

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

## Not in this API yet

From [platform](platform.md): `POST /api/v1/actions`, deep-link linking
(`/link`, `POST /api/v1/links/exchange`), the pull verification webhook and
outbound signed events, verification requests with signed receipts and JWKS,
and on-device model replay (`mp-replay`). See
[adding a kind or verifier](verification.md#adding-a-kind-or-verifier) for the
extension points.
