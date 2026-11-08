# Physical iPhone acceptance checklist

Use this checklist to accept the App Attest fraud-risk receipt and DeviceCheck
implementation from [the iOS device-risk PR](https://github.com/verilyfun/verily/pull/9).
Read [Apple App Attest](verification.md#apple-app-attest) for the verification
contract and [the operator API](serverpod-api.md#apple-device-risk-and-durable-restrictions)
for endpoint permissions.

**Status: not run.** No physical iPhone or live Apple risk API was used to prepare
this checklist. Automated tests and a simulator build do not satisfy these cases.
Leave every box unchecked until its expected result has been observed. Record
`PASS`, `FAIL`, `BLOCKED`, or `NOT RUN` for each case and each environment.

## Record the run

Keep the detailed run record private. Use aliases such as `phone-A`, `phone-B`,
`participant-A`, and `operator-A` in any public summary.

| Item                          | Record                                                                             |
| ----------------------------- | ---------------------------------------------------------------------------------- |
| Date and tester               | Private run record                                                                 |
| Server commit and deployment  | Exact SHA and environment alias                                                    |
| App commit, version and build | Exact SHA, version, build and signing channel                                      |
| Devices                       | Model and iOS version; no serial number or UDID in public evidence                 |
| Apple configuration           | Team/App ID match confirmed, key identifier alias, entitlement and profile checked |
| Environment                   | Development sandbox or production TestFlight                                       |
| Initial DeviceCheck flags     | Both original flags for each phone in this environment                             |
| Receipt deadlines             | Creation, not-before, expiration and next scheduled refresh in UTC                 |
| Results                       | Case ID, expected/actual outcome, UTC time, sanitized evidence reference           |
| Cleanup                       | Original flags restored and queried, temporary access removed                      |

Never publish `.p8` material, JWTs, DeviceCheck tokens, receipts, assertions,
authentication tokens, account identifiers, private media, or environment dumps.
Inspect sensitive rows locally with authorized access. Record receipt comparisons
as booleans and key comparisons as `same` or `different`. Do not commit screenshots,
videos, or other binary evidence.

## 1. Prepare the devices and test client

- [ ] **SETUP-1.** Reserve a physical iPhone that reports App Attest and
      DeviceCheck support, plus a second iPhone as a control. Obtain permission to
      change durable restrictions on these test devices. Do not clear an existing
      genuine restriction to make a case pass.
- [ ] **SETUP-2.** Use an isolated acceptance server and database on the current
      baseline. Use controlled accounts and an unrewarded action with deterministic
      proof, such as a live venue QR scan. Confirm ordinary proof acceptance first;
      unrelated location, freshness, abuse or verifier failures must not mask these
      results. Do not fund a real-money reward for this test.
      Record passing `devenv shell lint:analyze`, `devenv shell lint:format`,
      `devenv shell lint:native`, `devenv shell test:server` and
      `devenv shell test:flutter` results for the commits being tested.
- [ ] **SETUP-3.** Prepare an authenticated staff test client with
      `device-check.manage`. Prepare separate participant and `evidence.review`
      accounts without that scope. Use the generated Serverpod client for operator
      calls, not direct Apple requests from the phone.
- [ ] **SETUP-4.** Confirm the test client can call
      `generateDeviceCheckToken` on `app.verily/capture_provenance` on the affected
      iPhone and base64-encode its returned bytes. Transfer a fresh token only through
      the controlled authenticated test session, keep it in memory, and discard it
      after use. It must not appear in logs, clipboard history or command arguments.
      An App Attest key ID cannot replace a DeviceCheck token.

There is no shipped operator screen or acceptance command for SETUP-4. Arrange a
private staff test client before the run. If it is unavailable, mark the operator
and reinstall cases `BLOCKED`. Debugger-only access is insufficient for a
TestFlight run. Any diagnostic build must preserve the bundle ID, signing channel
and entitlements being tested; record that build separately.

## 2. Configure Apple and Monosecret

- [ ] **CRED-1.** In the Apple Developer account for the app, confirm the explicit
      App ID, App Attest capability, signing team and provisioning profile. Confirm
      the App ID prefix equals the Team ID used by this verifier. A transferred app
      with a different prefix needs investigation before proceeding.
- [ ] **CRED-2.** Create or select an Apple DeviceCheck-enabled P-256 signing key.
      Store the downloaded PKCS#8 `.p8` through Monosecret's approved provider. Keep
      the original in approved private storage, outside the repository. Do not put
      its contents in a command argument, issue, PR, or mobile build.
- [ ] **CRED-3.** Provision `VERILY_DEVICE_CHECK_PRIVATE_KEY` and
      `VERILY_DEVICE_CHECK_KEY_ID` together through Monosecret. For development,
      their configured routes are `dotenv` then `injected`, with no 1Password
      fallback. The local dotenv store is the ignored root `.env`, mode `0600`.
      The resolved value must contain PKCS#8 PEM, with real line breaks rather than
      literal `\n` text or an extra layer of base64 encoding. Staging and production
      use the `injected` provider and environment-scoped credentials.
- [ ] **CRED-4.** Set the nonsecret server configuration below. Team ID and key
      ID must belong to the same Apple team. Do not assume that adding arbitrary
      nonsecret fields to `.env` exports them; supply them in the server's launch
      environment.

| Setting                              | Acceptance value                                                                                                      |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `VERILY_APPLE_TEAM_ID`               | The app's ten-character Apple Team ID                                                                                 |
| `VERILY_IOS_BUNDLE_ID`               | The signed app's bundle ID, normally `fun.verily.app`                                                                 |
| `VERILY_APP_ATTEST_ENVIRONMENT`      | `development` for sandbox, `production` for TestFlight                                                                |
| `VERILY_CAPTURE_SIGNATURE_MODE`      | `required`                                                                                                            |
| `VERILY_ANDROID_SIGNING_CERT_SHA256` | The project's valid Android signing digest allowlist; current startup validation requires it even for this iPhone run |
| `VERILY_DEVICE_CHECK_KEY_ID`         | Identifier of the DeviceCheck-enabled signing key, resolved through Monosecret                                        |
| `VERILY_DEVICE_CHECK_PRIVATE_KEY`    | The matching backend-only PEM value, resolved through Monosecret                                                      |

For local provisioning, run these from the repository root only when preparing
the acceptance environment. Replace the `.p8` path with its private location.
The second command prompts for the key ID. Neither command sends a value to
1Password, because the provider is explicitly `dotenv`.

```bash
devenv shell -- monosecret set VERILY_DEVICE_CHECK_PRIVATE_KEY \
  --profile development --provider dotenv \
  --from-file /secure/path/AuthKey.p8 \
  --reason "Provision Apple key for iPhone acceptance"

devenv shell -- monosecret set VERILY_DEVICE_CHECK_KEY_ID \
  --profile development --provider dotenv \
  --reason "Provision Apple key identifier for iPhone acceptance"
```

Check `.env` permissions without printing its contents and set mode `0600` if
needed. Stop after a failed write; do not retry it in a loop. The `--from-file`
option reads the key bytes without exposing them in the command line.

- [ ] **CRED-5.** Resolve credentials once at server bootstrap through Monosecret.
      For a local development server, use `devenv shell server:start` after the
      database is ready. The bootstrap loads the private key as the Serverpod password
      `deviceCheckPrivateKey`. Do not resolve secrets in capture handlers or a test
      loop. Do not use `op` directly. Stop on a missing, throttled, or unauthorized
      secret read and fix the cause before another attempt.
- [ ] **CRED-6.** Confirm clock synchronization, outbound HTTPS access to the
      selected Apple hosts and successful server startup. Check credential presence
      without printing values. Monosecret permits these optional fields to be absent,
      so a successful general secret check alone does not prove Apple readiness.

Apple's [receipt guidance](https://developer.apple.com/documentation/devicecheck/assessing-fraud-risk)
requires a DeviceCheck-enabled key for the server JWT. Credential provisioning is
a prerequisite here; this checklist does not provision or read any credentials.

## 3. Run both signing environments

| Run          | iPhone build                                                          | Server policy                                         | Receipt host                           | DeviceCheck host                        |
| ------------ | --------------------------------------------------------------------- | ----------------------------------------------------- | -------------------------------------- | --------------------------------------- |
| Sandbox      | Development-signed build using the development App Attest environment | `development`, Serverpod development or test run mode | `data-development.appattest.apple.com` | `api.development.devicecheck.apple.com` |
| Distribution | Installed through TestFlight                                          | `production`                                          | `data.appattest.apple.com`             | `api.devicecheck.apple.com`             |

- [ ] **ENV-1.** Inspect the signed build's effective App Attest entitlement and
      provisioning profile. `Runner.entitlements` currently has no explicit App
      Attest environment entry, so the source file alone is not proof of the build's
      environment. TestFlight uses production regardless of a development setting.
- [ ] **ENV-2.** Point the app's `SERVER_URL` at the acceptance API reachable from
      the phone. A Mac's `localhost` is not the phone's server. Confirm authenticated
      requests reach the intended isolated server before opening a capture window.
- [ ] **ENV-3.** Run the cases below separately for sandbox and TestFlight. Keep
      their key rows, receipts, tokens and original-bit records separate. Do not
      send a sandbox receipt to the production endpoint. Do not reuse one key across
      environments or repeatedly attest keys to manufacture a high risk metric.

See Apple's [environment guidance](https://developer.apple.com/documentation/devicecheck/preparing-to-use-the-app-attest-service).
A sandbox pass does not establish that distribution provisioning works. Enterprise
distribution is outside this checklist; Verily's production validation-category
allowlist currently accepts TestFlight and App Store builds.

## 4. Register and sign on the real phone

Enable the sanitized receipt-request observation required by RISK-2 before
registration. Record the initial row before submitting any capture; a capture or
the scheduled job can obtain the first refreshed receipt immediately when due.

- [ ] **KEY-1.** On phone-A, sign in as participant-A and open the first capture
      window. Observe registration through `appAttest.beginRegistration` and
      `appAttest.registerKey`. The server stores one new key with counter zero and a
      verified initial receipt. Its environment, App ID and attested public key must
      match the signed app and registration. Receipt creation must be within the
      verifier's five-minute freshness limit. An initial `ATTEST` is not a risk metric.
      Before the first capture, save the initial receipt deadlines and null
      `riskMetric` for RISK-1. If the scheduler refreshes it first, collect this
      snapshot at the registration write boundary without logging the receipt.
- [ ] **KEY-2.** Submit two otherwise-valid captures in separate windows. Observe
      a fresh DeviceCheck token from the Swift channel on each capture, assertions
      accepted under the same registered key, and a strictly increasing persisted
      `signCount`. Provenance must be `secureEnclaveAttested`. Reopening the app and
      opening another window must reuse the key, without a new attestation each time.
- [ ] **KEY-3.** Use two separate unrewarded actions with active attempts for the
      same participant and key. With the controlled test client, sign proof in
      window A and withhold its submission. Sign and submit proof in window B,
      then submit A while its window is still valid. The lower counter must be
      refused as `capture_app_attest_replayed`. In separate unused windows, change a
      proof's bound token or manifest after signing; neither may verify. A reused
      window may fail its own replay check first, so it does not establish that the
      assertion-counter or token-binding check ran.
- [ ] **KEY-4.** Confirm ordinary app UI uses localized product messages. Internal
      Apple reasons, JWTs, provider details and signing diagnostics must not appear
      in the participant's flow.

## 5. Obtain and refresh a live fraud-risk receipt

- [ ] **RISK-1.** Use the initial snapshot from KEY-1 to record `receiptCreatedAt`,
      `receiptNotBefore`, `receiptRefreshAfter`, `receiptExpiresAt` and null
      `riskMetric`. Accept a first refresh already observed during KEY-2; do not
      register another key just to restart this section. Otherwise wait until
      `receiptRefreshAfter` is due and the receipt is still unexpired, then use a
      normal signed capture or the scheduled task to obtain the first live
      `RECEIPT`. Until a current metric exists, otherwise-valid signed proof must
      remain in review as `apple_device_risk_unavailable`.
- [ ] **RISK-2.** Confirm the backend makes a real HTTPS POST to
      `/v1/attestationData` on the selected host, using the latest stored base64
      receipt as the body and a JWT in `Authorization` without `Bearer`. Observe
      status and timing through instrumentation that excludes headers and bodies.
      The test must use the production HTTP client and pinned Apple root, with no
      fake client or test certificate authority.
- [ ] **RISK-3.** After Apple's 200 response, confirm the server replaces the
      stored receipt only after signature and chain verification to Apple Root CA -
      G3, App ID and public-key matching, and creation-time validation. Observe a
      nonnegative `riskMetric` from field 17, new receipt timestamps, and
      `receiptRefreshAfter == receiptNotBefore`. A 200 response alone is not a pass.
- [ ] **RISK-4.** With both DeviceCheck bits false and a current metric below 10,
      submit otherwise-valid proof. The Apple risk gate must permit automatic
      verification. If the real metric is at least 10, expect manual review with
      internal `device_activity_risk`, public `needs_review`, and reviewer
      `security_review`. Do not rewrite a signed field or generate keys in a loop
      to force the threshold. Record an unobserved live threshold branch as
      `NOT RUN`; automated threshold tests remain separate evidence.
- [ ] **RISK-5.** Before the new signed not-before date, submit another valid
      capture. DeviceCheck must still be queried, but the current receipt must be
      reused without another receipt POST. The original creation timestamp becoming
      five minutes old must not invalidate an already-verified cached receipt.
- [ ] **RISK-6.** Keep the server running and leave the app closed through the
      next signed not-before date. Observe `app-attest-receipt-refresh` obtain and
      persist a second real receipt before expiration, without a capture. The job
      runs every ten minutes in batches of at most 100. With one due test row and a
      healthy worker, inspect the next scheduled sweep. Record any scheduling delay
      or Apple error rather than silently extending the result to `PASS`.

RISK-6 may require a later session. Use the signed deadlines, not an assumed
interval. Do not alter database deadlines, the server clock or signed receipt
bytes to claim live refresh acceptance. Apple documents field 19 as the earliest
refresh time and field 21 as expiration in
[Assessing fraud risk](https://developer.apple.com/documentation/devicecheck/assessing-fraud-risk).

## 6. Exercise the operator permissions and durable bits

Use a new token from the affected iPhone for each query or update. The generated
client calls are `deviceCheck.query(deviceToken: ...)` and
`deviceCheck.update(deviceToken: ..., banned: ..., reviewRequired: ..., note: ...)`.
Set both flags explicitly and use a bounded, nonempty audit note with the test
case alias. Read back the result after every update.

- [ ] **BITS-1.** Query both phones and save their original flags privately before
      changing anything. Apple's `Bit State Not Found` maps to `false, false`.
      A transport error or malformed response must not map to clean bits.
- [ ] **BITS-2.** Try query and update as an unauthenticated client, an ordinary
      participant, and a reviewer with only `evidence.review`. Each must be denied.
      Confirm the authorized active operator succeeds. Check denial independently
      of token validity so a malformed token cannot mask a permissions failure.
- [ ] **BITS-3.** On the dedicated test phone, exercise every row below. Use new
      otherwise-valid proof after each successful readback. Keep its receipt current
      and record any additional risk hold separately.

| `banned` / bit 0 | `reviewRequired` / bit 1 | Expected capture result                                 |
| ---------------- | ------------------------ | ------------------------------------------------------- |
| `false`          | `false`                  | No DeviceCheck restriction; all other gates still apply |
| `false`          | `true`                   | Manual review, internal `apple_device_review`           |
| `true`           | `false`                  | Refused, internal `capture_device_banned`               |
| `true`           | `true`                   | Refused, with the ban taking precedence                 |

- [ ] **BITS-4.** From `true, true`, explicitly set `false, true`. Verify capture
      now requires review. Clearing the ban must not clear review unless the operator
      explicitly sets that flag false too. Participants see `needs_review` for a
      review hold and `capture_not_verified` for a ban. Reviewers see `security_review`
      for the review hold.
- [ ] **BITS-5.** Inspect `verily_device_check_audit` privately. Each successful
      update must have the operator, requested flags, note, token hash, creation time
      and completion time. No raw token may appear in the audit or server logs.

Apple describes the query/update protocol in
[Accessing and modifying per-device data](https://developer.apple.com/documentation/devicecheck/accessing-and-modifying-per-device-data).

## 7. Prove restrictions survive a reinstall

- [ ] **REINSTALL-1.** Set phone-A to `true, true` and query it successfully.
      Delete the app with iOS **Delete App**, not Offload App. Reinstall the same
      bundle through the same signing channel. Sign back in as participant-A. Do
      not reset the phone, change environment or restore a backup during this case.
- [ ] **REINSTALL-2.** Obtain a fresh token after reinstall and query the flags.
      Both must still be true. Observe a newly registered App Attest key when the
      old installation's key is unavailable. A stale Keychain ID may cause an initial
      `invalid_key`; the app should discard it and register on the next window.
      Once there is a valid assertion from the new installation, capture must still
      be refused for `capture_device_banned`. An unsigned-proof rejection alone
      does not establish persistence of the ban.
- [ ] **REINSTALL-3.** Sign in as a second controlled participant on phone-A.
      Query with a fresh token and submit valid signed proof under that account's
      own key. The device ban must remain. Confirm a clean phone-B using the first
      participant is not device-banned, after accounting for independent account
      restrictions. This distinguishes device state from account or key state.
- [ ] **REINSTALL-4.** Set phone-A to `false, true`, read it back, then delete and
      reinstall again. With fresh registration, a current receipt and otherwise-valid
      proof, query must still return `false, true` and capture must require
      `apple_device_review`. This proves the review bit survives independently.

## 8. Check failures without weakening policy

Run these on the isolated acceptance server only. Resolve secrets once per
deliberate configuration change. Do not revoke a shared signing key or retry a
failed secret operation to create a failure case.

- [ ] **FAIL-1.** Omit the DeviceCheck key ID or private key from the acceptance
      server's resolved configuration. A signed capture with a token must hold for
      `apple_device_risk_unavailable`, even with a previously low metric. The staff
      API must report unavailable, with no simulated successful update. Restore the
      configured server before continuing.
- [ ] **FAIL-2.** Block server egress to the selected DeviceCheck host while the
      phone can still reach Verily. A signed capture must hold for review. For a
      failed update after audit insertion, `completedAt` must remain null. A timeout
      can mean Apple applied the update: restore connectivity, obtain a fresh token
      and query before deciding whether another update is necessary.
- [ ] **FAIL-3.** When a receipt is naturally due, block only the receipt host.
      With DeviceCheck healthy, submit proof. The server must retain the prior
      verified receipt and metric, persist a one-hour refresh backoff, and hold
      automatic verification as `apple_device_risk_unavailable`. Repeated captures
      during backoff must not repeat the receipt POST or trust the stale low metric.
      Restore egress and observe recovery after backoff while the receipt is valid.
- [ ] **FAIL-4.** On an isolated deployment with a deliberately mismatched app
      environment, use a controlled account that has no registered key in that
      installation. A real registration must fail closed. Restore the matching
      deployment before another deliberate attempt. Do not transplant receipts
      between environments or hammer Apple's API until registration succeeds.
- [ ] **FAIL-5.** If a naturally expired test receipt is available, confirm it
      cannot grant automatic verification or refresh through the expired receipt.
      Record this case as `NOT RUN` if waiting is impractical. Recovery needs a
      newly attested key; there is no dedicated expired-receipt recovery UI or
      operator endpoint today. Record that gap instead of claiming seamless recovery.

Malformed signatures, untrusted roots, wrong App IDs/keys, forged receipt fields,
counter races, and response limits belong in the automated adversarial suite.
Synthetic fault tests may supplement this run, but must not be reported as
responses observed from Apple. DeviceCheck does not prove its token and the App
Attest key came from the same phone; a successful run does not eliminate a
compromised phone relaying a clean phone's token.

Keep automated evidence separate, especially
[`app_attest_receipt_test.dart`](../verily_server/test/unit/action_verification/app_attest/app_attest_receipt_test.dart),
[`apple_device_client_test.dart`](../verily_server/test/unit/action_verification/app_attest/apple_device_client_test.dart)
and [`device_check_test.dart`](../verily_server/test/integration/device_check_test.dart).

## 9. Restore state and sign off

- [ ] **CLEANUP-1.** Restore each device's original flags in each tested
      environment through the authorized operator API. Query with fresh tokens to
      confirm restoration and completed audit entries. If the original state was
      clean, both flags must be false. Do not clear unrelated restrictions.
- [ ] **CLEANUP-2.** Remove temporary operator scopes, test sessions and
      diagnostic access. Remove temporary local key copies and diagnostic captures
      according to the secret/evidence retention policy. Retain the approved key
      through Monosecret; revoke it only if it was dedicated to this run and is no
      longer needed. A shared credential requires coordination before revocation.
- [ ] **SIGNOFF-1.** Complete the result table below with sanitized references.
      A blocked staff client, missing TestFlight run, unobserved scheduled refresh,
      or incomplete cleanup prevents full acceptance. Unobserved high-metric and
      natural-expiration branches must remain explicit limitations with their
      separate automated evidence.

| Cases                           | Sandbox | TestFlight | Evidence / remaining work                                         |
| ------------------------------- | ------- | ---------- | ----------------------------------------------------------------- |
| SETUP-1 through SETUP-4         | NOT RUN | NOT RUN    |                                                                   |
| CRED-1 through CRED-6           | NOT RUN | NOT RUN    |                                                                   |
| ENV-1 through ENV-3             | NOT RUN | NOT RUN    |                                                                   |
| KEY-1 through KEY-4             | NOT RUN | NOT RUN    |                                                                   |
| RISK-1 through RISK-6           | NOT RUN | NOT RUN    | Record both live receipt exchanges and scheduled refresh deadline |
| BITS-1 through BITS-5           | NOT RUN | NOT RUN    |                                                                   |
| REINSTALL-1 through REINSTALL-4 | NOT RUN | NOT RUN    | Require valid signed captures after reinstall                     |
| FAIL-1 through FAIL-5           | NOT RUN | NOT RUN    | Separate natural-expiration and synthetic evidence                |
| CLEANUP-1 and CLEANUP-2         | NOT RUN | NOT RUN    |                                                                   |
| Final acceptance                | NOT RUN | NOT RUN    | Tester and date in private record                                 |

Until a completed run record says otherwise, **nothing has run on a physical
iPhone and live Apple acceptance remains outstanding**.
