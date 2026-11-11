# Moving Verily to LeptosKit

Verily is moving to one Rust stack: the server, the app, and the tooling all
run on [LeptosKit](https://github.com/leptoskit/leptoskit) 0.3.0 in `verily_kit/`.
Serverpod (`verily_server/`, `verily_client/`), the Flutter app
(`verily_flutter/`), and the Dart packages are removed once the kit does
everything they do. Until then both stacks stay, and the Dart side keeps
passing its checks.

This page tracks what is left. Each phase lands as its own pull request.

## Phases

| Phase | What lands                                                                                                                                                                                                                                               | State       |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| 1     | The app's frame and look: file-router navigators (root stack, Skribble tab bar), routes at the Flutter URLs, the front door, and every screen drawn with Skribble from `verily_ink`                                                                      | In review   |
| 2     | Sign-in: email codes and Google through `leptoskit_auth`, the `/sign-in` page, and a guard that sends a signed-out person there                                                                                                                          | Not started |
| 3     | Core server operations behind the existing client stubs: actions, attempts, evidence, nearby search (PostGIS), templates, account closure; the host loads the verification and rewards configuration instead of mounting them closed                     | Not started |
| 4     | Evidence storage (Backblaze B2 and local), upload reservations, and the background jobs (cleanup, recovery, expiry) on `rpc.jobs`                                                                                                                        | Not started |
| 5     | Device proof on the server: Android Key Attestation (pinned roots, revocation list, the vectors byte-identical), App Attest and DeviceCheck, Play Integrity                                                                                              | Not started |
| 6     | Device proof in the app: Verily's own `verily_capture` plugin (camera stills and video, microphone, QR scanning, motion, location binding) and `verily_attest` plugin (per-window attested keys, Play Integrity, App Attest), on Android first, then iOS | Not started |
| 7     | AI verification: the OpenRouter council transport behind `ModelInputSecurity`, the verification worker, and the adversarial tests                                                                                                                        | Not started |
| 8     | Rewards end to end: payout signing and custody, recovery, and the wallet link through the Solana mobile wallet adapter                                                                                                                                   | Not started |
| 9     | Moderation, appeals, abuse risk, and AI usage metering                                                                                                                                                                                                   | Not started |
| 10    | Verily Apps: partner apps, keys, webhooks, receipts and JWKS, verification requests, the `/api/v1` routes, and the `/r/:request` and `/link` deep links                                                                                                  | Not started |
| 11    | Tooling: devenv scripts, local CI lanes, the server image, and Monosecret entries for the kit only                                                                                                                                                       | Not started |
| 12    | Remove Serverpod, Flutter, the Dart packages, and their docs                                                                                                                                                                                             | Not started |

## Gaps in LeptosKit itself

These have no LeptosKit equivalent yet. Phase 6 builds them as Verily plugins
unless LeptosKit gains them first:

- Video, microphone, and still capture. LeptosKit 0.3.0 does not publish a
  camera plugin. `permissions` can ask for the camera and the microphone; it
  does not record.
- QR scanning.
- On-device pose and object detection (Flutter uses MediaPipe).
- Android Key Attestation, Play Integrity, and App Attest.
  `leptoskit_plugin_app_integrity` is not in the 0.3.0 release.
- Motion samples. 0.3.0 replaces the combined sensors plugin with
  accelerometer, gyroscope, magnetometer, barometer, light sensor, and
  pedometer. The capture guest does not call them yet.
- The Solana mobile wallet adapter on Android (LeptosKit has browser Wallet
  Standard only).
- Enter and scroll motion. LeptosKit 0.3.0 does not export `Motion`, `Pose`,
  `Spring`, or `ViewRange`. Stamps and rising pictures render in place.
- Custom fonts on native hosts, so native screens use the system face rather
  than the Skribble typefaces. The rough ink, colours, and layout still
  follow [`DESIGN.md`](../DESIGN.md).
- Pinning light or dark from inside the app. The kit follows the device's
  appearance.
- A hardware Back key. 0.3.0 does not export the router system-back binding.
  The in-app Back control still walks history.
