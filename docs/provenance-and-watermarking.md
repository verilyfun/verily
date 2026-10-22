# Verily media provenance: signatures, watermarks, and proof of live capture

Research date: 21 October 2026. Audience: founder and engineering. Status: decision-ready recommendation, with open uncertainties called out.

## Bottom line

The founder's question is "how do AI companies sign their content, and can we watermark ours the same way?" The answer is that they use two layers. A **signed C2PA manifest** carries rich, verifiable context but is stripped by most uploads and screenshots. An **invisible watermark** (SynthID, Video Seal, TrustMark) survives re-encoding but carries only a short ID or a "this came from us" bit. OpenAI now ships both on its images: C2PA plus Google's SynthID.

For Verily, push back on one part of the framing. A watermark proves that media **passed through our pipeline**. It does not prove that media was **captured live on a real phone**. Open-source watermark models can embed any payload into any video, so a watermark added on the device adds nothing against an attacker who controls the device. The things that prove live capture are a **hardware-attested key**, a **server nonce issued before recording**, and **content-level live challenges**. Watermarks and fingerprints are what make provenance survive _after_ verification, and they catch re-submission of previously verified media.

Recommended scheme:

1. **Capture (device):** a per-attempt hardware key whose Android Key Attestation (or iOS App Attest) is bound to a server challenge issued before recording starts. The device signs a manifest of chunk hashes, sensor trace digest, and timing. A randomized live prompt makes the scene itself prove when it was recorded.
2. **Intake (server):** verify the attestation chain, Play Integrity strong verdict and capture-risk signals, and the manifest. Check the upload against our watermark detector and a perceptual-fingerprint registry to reject replays. Then run the AI council.
3. **After verification (server):** keep the original byte-identical and hash-pinned. Publish derived renditions carrying an invisible watermark (Video Seal / TrustMark / AudioSeal, all MIT) whose payload is a random 64-bit evidence handle. Attach a Verily-signed C2PA manifest with a soft-binding assertion, and register the handle and fingerprints so a stripped copy can still be resolved.

This is the same "durable Content Credentials" pattern (manifest + watermark + fingerprint) that Adobe, Digimarc and the C2PA soft-binding API describe, applied to capture instead of generation.

## 1. How AI companies sign and watermark today

| Company / tech                                 | Mechanism                                                                                                                                                                                                                                                       | Robustness                                                                                                                                                                                                                                 | Openness                                                                                                                                                                 | Detection                                                                                                                   |
| ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| **Google SynthID** (image, video, audio, text) | Invisible watermark woven into pixels/audio; text uses tournament sampling during generation. Paired with C2PA on Google products.                                                                                                                              | Google reports it survives compression and common edits; the image system has watermarked over 10 billion images and frames (SynthID-Image paper). Text is weaker under paraphrase. Independent red-teaming across all modalities is thin. | Image/audio/video embedding is proprietary, licensed to partners (OpenAI, NVIDIA, Kakao; Apple "soon"). SynthID Text is open-sourced in Hugging Face Transformers 4.46+. | SynthID Detector portal opened to everyone on 7 Oct 2026 (English, reported ~10 checks/day). No public detection API found. |
| **OpenAI**                                     | C2PA on images since DALL·E 3 (2024). On 19 May 2026 it announced C2PA conformance plus SynthID watermarks on images from ChatGPT, the API and Codex, and previewed a public verify tool. Sora videos carry visible marks plus C2PA, with disputed consistency. | C2PA is stripped by uploads and screenshots, which OpenAI acknowledges. SynthID is the durable layer.                                                                                                                                      | Uses standards plus a licensed watermark.                                                                                                                                | openai.com/verify (preview). A negative result proves nothing.                                                              |
| **Meta**                                       | Video Seal (Dec 2024), PixelSeal and ChunkySeal (Dec 2025), AudioSeal, Watermark Anything; "AI info" labels driven by C2PA/IPTC metadata plus watermarks.                                                                                                       | Video Seal survives H.264/H.265 compression, crops and blur, with lower bit accuracy under combined attacks (details in §4).                                                                                                               | **MIT for code and weights**, the most usable open stack. "Meta Seal" appears to be an umbrella name, not a separate model. Omni Seal Bench is a leaderboard.            | Open-source extractors. Meta also published WmForger, a black-box forging attack on watermarks.                             |
| **Adobe**                                      | Content Credentials (C2PA) across Firefly and Creative Cloud; **TrustMark** watermark for durable credentials; research FlowMark (video, 128-bit) and HierMark (audio) are on the C2PA soft-binding list.                                                       | TrustMark: 100-bit raw payload (about 61–70 usable bits after BCH), designed to survive resharing, screenshots, printing and JPEG; images only.                                                                                            | TrustMark is MIT, with Python, Rust (ONNX via `ort`) and JS ports. FlowMark/HierMark code release not found.                                                             | Open decoder. The Adobe/Digimarc browser extension resolves watermark to manifest.                                          |
| **Microsoft**                                  | C2PA manifests on Designer/Bing Image Creator (secondhand report); InvisMark research watermark; registered soft-binding algorithms `com.microsoft.invismark.1` and `com.microsoft.wavmark.1`.                                                                  | InvisMark reports about 51 dB PSNR and over 97% bit accuracy at 256 bits (released weights are 100-bit).                                                                                                                                   | InvisMark repo is MIT; weights are on OneDrive.                                                                                                                          | Research code.                                                                                                              |
| **Stability AI**                               | No primary 2025–26 source found. Historically, Stable Diffusion reference code applied the `invisible-watermark` DWT-DCT mark.                                                                                                                                  | DWT-DCT is fragile to resize and crop.                                                                                                                                                                                                     | —                                                                                                                                                                        | Treat as unknown.                                                                                                           |
| **Digimarc**                                   | Commercial watermark (image, video, audio, text). First C2PA 2.1 soft-binding implementation (`com.digimarc.validate.1`).                                                                                                                                       | Vendor claims only.                                                                                                                                                                                                                        | Licensed and paid.                                                                                                                                                       | Digimarc Validate.                                                                                                          |
| **Steg.AI**                                    | Deep-learning forensic watermark for image, video and documents; API or on-prem; optional C2PA.                                                                                                                                                                 | Vendor claims survival of cropping, compression, screenshots and screen-to-camera capture.                                                                                                                                                 | Paid.                                                                                                                                                                    | API.                                                                                                                        |
| **IMATAG**                                     | LAMARK watermark (`com.imatag.lamark.v1`); images and video up to 5 GB.                                                                                                                                                                                         | Vendor claims.                                                                                                                                                                                                                             | Paid; one review lists €299/month entry.                                                                                                                                 | API.                                                                                                                        |

Takeaways for Verily:

- Everyone credible now does **both** a manifest and a watermark, because each fails differently.
- Every watermark detector is **issuer-specific**. A missing watermark never proves authenticity, and open-source generators (Wan, Hunyuan and similar) carry no watermark at all.

## 2. C2PA / Content Credentials in depth

**Structure:**

- A _manifest store_ (JUMBF boxes) holds one or more manifests. Each manifest contains an _assertion store_, a _claim_ and a _claim signature_.
- The claim (`c2pa.claim.v2`, deterministic CBOR) lists hashed references to `created_assertions` (attributed to the signer) and `gathered_assertions`, plus `claim_generator_info`.
- The signature is `COSE_Sign1` over the claim, with the X.509 chain. An RFC 3161 timestamp goes in `sigTst2`.
- Every manifest needs a `c2pa.actions` assertion. Capture uses `c2pa.created` with IPTC `digitalSourceType` = `digitalCapture`. AI output uses `trainedAlgorithmicMedia`. Edits reference _ingredients_, which are earlier manifests.

**Hard binding** is a cryptographic hash of the asset. Exactly one is allowed per manifest:

- `c2pa.hash.data`: byte ranges.
- `c2pa.hash.boxes`: JPEG and PNG boxes.
- `c2pa.hash.bmff.v3`: MP4/MOV. It supports chunked, Merkle-style hashing for fragmented MP4.

Any transcode breaks a hard binding. That is the gap Verily has today with its SHA-256.

**Soft binding** (`c2pa.soft-binding`) records a watermark or fingerprint produced by an algorithm on the C2PA-approved list (54 entries as of this research, including TrustMark, Digimarc, Steg.AI, IMATAG, Microsoft InvisMark, and Meta's Video/Pixel/AudioSeal via third-party "AIWatermark"). The **Soft Binding Resolution API** defines repository endpoints:

- `/matches/byBinding` and `/matches/byContent` look up a manifest from a watermark or fingerprint.
- `/manifests/{id}` fetches the manifest.
- `/bindings` registers a binding.

The spec itself warns about **watermark transfer**, where a real watermark is copied onto a fake asset. It recommends storing a fingerprint in the manifest and comparing it against the queried asset. **Durable Content Credentials** means exactly this triad: manifest + watermark + fingerprint.

**Trust and conformance:**

- The C2PA Conformance Program issues claim-signing certificates from trust-listed CAs, with an assurance-level OID. Level 2 is the top level and needs hardware-protected keys.
- The early phase relied on self-assertion. Validators did not check revocation well, which the Nikon Z6III incident exposed: signed AI images forced Nikon to revoke every certificate in September 2025, and the service was still suspended in early 2026.
- Lesson for Verily: signing quality depends on what you sign, not on the signature.

**Devices that sign natively:**

- **Google Pixel 10**: Pixel Camera signs every JPEG. Keys are generated in StrongBox on Titan M2, one key and certificate per image. Google's C2PA CA issues certificates only after Android Key Attestation proves a genuine, locked, patched device and the app's package and signing certificate. An offline trusted-time TSA runs on Tensor. It is rated **Assurance Level 2**. Google says AL2 is currently possible for a mobile app only on Android, and its blog presents this as a blueprint that third-party apps can follow using the same Key Attestation primitives.
- **Pixel video**: at I/O 2026 (19 May), video credentials were announced for Pixel 8/9/10 (secondary sources only).
- **No public Android SDK found**: credentials name a "Google C2PA SDK for Android", but no public Jetpack/AndroidX API surfaced.
- **Samsung Galaxy S25 / One UI 7**: credentials only on AI-generated or AI-edited images, not ordinary captures.
- **Cameras**: Leica (SL3-S, M11-P), Sony (PXW-Z300 camcorder signs video; Camera Verify), Canon, Fujifilm and Panasonic are C2PA-capable. Nikon is suspended.
- **Apple**: not C2PA. Secondary sources describe "Apple Reference Image" (iPhone 18 Pro, iOS 27, Sept 2026): stills only, Apple's own signatures, verification via Apple, and a developer API. Treat as unconfirmed until Apple's docs are read.

**SDKs usable from Flutter:**

| SDK                            | What                                                                                                                               | License                 | Notes                                                                                                                              |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `c2pa-rs`                      | Reference Rust implementation; reads, writes, validates; JPEG/PNG/HEIC/WebP, MP4/MOV (fragmented MP4 file-based), WAV/MP3/M4A/FLAC | MIT / Apache-2.0        | Still 0.x with a breaking "release train" about every two months. A natural fit for a Rust server worker or `flutter_rust_bridge`. |
| `c2pa-android`                 | AAR wrapping c2pa-rs C FFI; Keystore/StrongBox signer (ES256), callback/remote signers                                             | MIT / Apache-2.0        | Young (v1.0.0, few stars).                                                                                                         |
| `c2pa-swift` (was c2pa-ios)    | Swift bindings; Secure Enclave signing on iOS 16+                                                                                  | Check repo              | Example app uses test keys.                                                                                                        |
| `c2pa_flutter` (pub.dev)       | FFI to c2pa-rs 0.75; Keystore/Keychain signing; images only                                                                        | MIT                     | Unverified uploader. Do not depend on it in production.                                                                            |
| `c2pa_view` / `c2pa` (pub.dev) | Viewer via flutter_rust_bridge / pure-Dart reader                                                                                  | —                       | Reading only.                                                                                                                      |
| Truepic Lens                   | Commercial controlled-capture SDK (iOS/Android): device checks, on-device C2PA, Truepic CA + TSA                                   | Paid, no public pricing | The "buy" option.                                                                                                                  |
| ProofMode (Guardian Project)   | Sidecar proof bundle: hashes, PGP signatures, sensor metadata; C2PA via SimpleC2PA                                                 | App is GPL-3.0          | Copyleft. Use it as reference design, not as code to embed.                                                                        |

## 3. Device-bound proof of capture

### Android Key Attestation (closes the "is the key hardware-backed?" gap)

How it works:

- Generate the key with `KeyGenParameterSpec.Builder.setAttestationChallenge(serverChallenge)`, using StrongBox when available.
- Send `KeyStore.getCertificateChain(alias)` to the server.

Server checks:

1. The chain validates to a **Google root**. Load roots from `https://android.googleapis.com/attestation/root`. A new ECDSA P-384 root began signing on 1 Feb 2026, and RKP devices use it exclusively from 10 Apr 2026, so accept both old and new roots. Keep accepting the legacy root by subject even when expired.
2. No serial in the chain is listed in the status list at `https://android.googleapis.com/attestation/status`. Honour its `Cache-Control`.
3. Parse the attestation extension from the certificate **closest to the root** that carries it, normally the leaf, and ignore later occurrences. Then require all of:
   - `attestationChallenge` equals the issued challenge.
   - `attestationSecurityLevel` is `TrustedEnvironment` or `StrongBox`. Record which one and prefer StrongBox.
   - `RootOfTrust.verifiedBootState` is `Verified` and `deviceLocked` is true.
   - `attestationApplicationId` has package `fun.verily.app` and the release signing-cert SHA-256.
   - `osPatchLevel` is within policy, for example 12 months.
   - Key purpose is SIGN and the algorithm is EC P-256.

Google recommends its Kotlin verifier (`github.com/android/keyattestation`, Apache-2.0), which handles revocation and edge cases. The server is Dart, so either port the checks and reuse that library's test vectors, or run the Kotlin verifier as a small JVM sidecar. Writing a fresh ASN.1 parser without those vectors is the risky path.

Known bypasses (Guardsquare, Jan 2026):

- Leaked OEM **keyboxes** replayed through TrickyStore/TEESimulator.
- **Remote key attestation relays** to a host device.

Remote Key Provisioning (mandatory for devices launching on Android 16) shrinks the keybox problem. Defenses beyond the revocation list:

- Same attestation key seen across different device models.
- Spikes in usage per attestation certificate.
- Patch-level and model consistency.

### Play Integrity (already integrated; tighten it)

Verily's verifier (`verily_server/lib/src/action_verification/device_integrity_verifier.dart`, ported from KickJump) accepts `MEETS_DEVICE_INTEGRITY`. Since May 2025 that already implies a hardware-backed verified boot on Android 13+. Add:

- **`MEETS_STRONG_INTEGRITY`**: a security patch within the last year on Android 13+. Use it as the bar for high-value rewards.
- **`environmentDetails.appAccessRiskVerdict`**: reject or flag `UNKNOWN_CAPTURING`, `UNKNOWN_CONTROLLING` and `UNKNOWN_OVERLAYS` during capture.
- **`recentDeviceActivity`** (`LEVEL_3`/`LEVEL_4` indicates farming).
- **`appIntegrity.certificateSha256Digest`**.
- **`accountDetails.appLicensingVerdict`**.
- **`deviceRecall`** (beta): flags a banned device across reinstalls.

### Apple App Attest + DeviceCheck (iOS)

Setup:

- `DCAppAttestService.generateKey()` creates a Secure Enclave key.
- `attestKey(keyId, clientDataHash: SHA256(serverChallenge))` returns a CBOR attestation.

Server verification:

- The chain validates to the Apple App Attestation Root CA.
- The nonce equals `SHA256(authData ‖ clientDataHash)` in OID `1.2.840.113635.100.8.2`.
- `rpIdHash` equals `SHA256(TeamID.BundleID)`.
- The counter is 0.
- `aaguid` is `appattest` in production.
- The new validation-category and bundle-version extensions are checked.

Per capture:

- Call `generateAssertion(keyId, clientDataHash: SHA256(canonicalManifest))`. This signs the manifest digest with the attested key, so a separate CryptoKit key is unnecessary.
- The server verifies the signature and requires a strictly increasing counter.

Limits:

- There is no verified-boot or jailbreak signal. Apple says App Attest makes abuse harder, not impossible.
- Keys don't survive reinstall, restore or migration.
- `isSupported` can be false, so the server must decide policy for unsupported devices.
- Use the **fraud-risk receipt** (attested keys per device).
- Use **DeviceCheck's two per-device bits** to persist bans across reinstalls.

### Binding attestation to a _live_ capture (protocol)

1. **Before the camera opens:** the app requests `beginCapture(attemptId, requirementId)`. The server returns a 32-byte `captureChallenge`, its expiry, and a **randomized live prompt** (see §6), and records the issue time `T0`.
2. The app generates a **fresh per-attempt key** with `setAttestationChallenge(SHA256(captureChallenge ‖ attemptId))`, following Pixel's "one-and-done" pattern. It does this in parallel with camera warm-up, because StrongBox key generation can be slow. (The capture code ported from KickJump reused one long-lived key alias with no attestation and reported `keyStorage` from the client, which is not evidence; Phase 1 replaced it, see [capture integrity](verification.md#capture-integrity).)
3. **While recording:** fragment the MP4 (or roll segments every 1–2 s) and keep a hash chain: `h_i = SHA256(h_{i-1} ‖ SHA256(segment_i) ‖ SHA256(imuWindow_i) ‖ t_i)`, where `t_i` is the camera sensor timestamp. In Phase 3, sign `h_i` every few seconds and post it to the server. The server then sees the recording grow in real time, which defeats "file ready before the challenge" attacks.
4. **On stop:** build a canonical manifest with these fields:
   - `attemptId`, `requirementId` and the challenge hash
   - the chain head and segment hashes
   - the final file SHA-256
   - the IMU trace digest, capture start/stop times, and camera ID/lens metadata
   - the app version

   Sign it with the attested key. Request a Play Integrity standard token whose `requestHash` is the manifest digest; this is already done.
5. **Server:** verify the attestation chain, the Play Integrity verdict, the signature, the chain against the uploaded bytes (the server recomputes SHA-256 today), and `T1 − T0 ≤ requirement duration + slack`. Then run the AI council, including a check that the live prompt was performed.

## 4. Invisible watermarking we can run ourselves

| Library                           | Media                      | Payload                                                 | Robustness (self-reported)                                                                                                                                                                                            | Cost                                                                                                                                                             | License                                |
| --------------------------------- | -------------------------- | ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| **Meta Video Seal v1.0**          | Video and images           | 256 bits (legacy v0: 96)                                | Trained through H.264/H.265 (CRF 9–27), crop, resize. Paper: about 0.85 bit accuracy average under compression and geometric attacks, 0.73 under combined attacks; PSNR about 48 dB. Accuracy rises with more frames. | Embed about 1.14 s CPU / 0.42 s GPU per second of video; extract 0.69 s / 0.11 s. 16M-parameter embedder, 24M extractor. TorchScript provided; no official ONNX. | **MIT** (code + weights)               |
| **Meta PixelSeal / ChunkySeal**   | Images (+video)            | 256 / 1024 bits                                         | PixelSeal claims best robustness-quality trade-off (Dec 2025)                                                                                                                                                         | GPU recommended                                                                                                                                                  | **MIT**                                |
| **Adobe TrustMark** (Q/P/C)       | Images, ≥150 px short side | 100 bits raw, about 61–70 after BCH                     | Screenshots, JPEG, printing, crops up to about 20% area                                                                                                                                                               | Decoders 20–35 MB; ms on GPU; Rust crate uses ONNX                                                                                                               | **MIT**                                |
| **Meta AudioSeal**                | Speech/audio, 16–48 kHz    | 16 bits + presence detection, sample-level localization | Compression, re-encoding, noise; streaming mode (v0.2)                                                                                                                                                                | Fast single-pass detector                                                                                                                                        | **MIT** (incl. weights since Apr 2024) |
| **Sony SilentCipher**             | Audio 16/44.1 kHz          | 40 bits                                                 | Claims SOTA; crop robustness needs slow phase-shift decoding                                                                                                                                                          | Moderate                                                                                                                                                         | Code MIT; weight terms not stated      |
| **WavMark**                       | Audio                      | 32 bits per second                                      | Common audio edits                                                                                                                                                                                                    | Light                                                                                                                                                            | Unclear (a mirror says MIT)            |
| **Microsoft InvisMark**           | Images                     | 100 bits released (256 in paper)                        | Over 97% bit accuracy, about 51 dB                                                                                                                                                                                    | GPU                                                                                                                                                              | MIT                                    |
| **invisible-watermark** (DWT-DCT) | Images                     | 32–64 bits                                              | Survives JPEG; **fails resize, crop, rotation**                                                                                                                                                                       | 300 ms CPU at 1080p                                                                                                                                              | MIT                                    |
| **StegaStamp**                    | Images                     | 100 bits (56 after ECC)                                 | Print and photograph                                                                                                                                                                                                  | TF 1.13, unmaintained                                                                                                                                            | MIT                                    |

**Universal caveats:**

- **Regeneration attacks remove watermarks.** WAVES and later work show diffusion "rinsing" defeats most pixel watermarks.
- **Watermarks can be forged or transferred.** Meta's own WmForger shows this.
- No method is robust to everything. Treat a decoded watermark as a lookup key, never as proof.

**On-device vs server-side embedding.** Embed on the **server**, after verification:

- An attacker who controls the device can feed fake frames into an on-device embedder, and the models are public anyway. On-device embedding therefore adds no authenticity.
- It costs battery and latency: Video Seal is about 42 GFLOPs per second of video, and porting to TFLite or ExecuTorch is unproven.
- The only gain would be marking files that leak before upload. Verily uploads straight to private storage, so that gain is negligible.

**Concrete scheme:**

1. **Never modify the evidence original.** It stays hash-pinned for audit and disputes.
2. After a decision, generate **renditions** (for public feeds, shares, and creator downloads) and embed the watermark:
   - **Video**: Video Seal, 256 bits = 8-bit version + 64-bit random `handle` + error-correcting redundancy. Accept a match by Hamming distance to the registered codeword, with a computed false-match p-value.
   - **Images/thumbnails**: TrustMark Q with a 56-bit handle + version under BCH.
   - **Audio**: AudioSeal presence bit + 16-bit key epoch. The handle comes from the video track or the fingerprint.

   The handle is a random database key, not a signature. Forging a valid one means guessing about 2^64 values, so no HMAC is needed in the payload.
3. **Register** `handle → evidenceId, rendition hash`, plus perceptual fingerprints:
   - PDQ per keyframe (Meta ThreatExchange; C++/Python/Java plus a Rust crate; confirm the license headers per file).
   - vPDQ or TMK+PDQF for video.
   - An audio fingerprint (not researched here; check Chromaprint's LGPL terms).
4. **Attach a Verily-signed C2PA manifest** to each rendition:
   - `c2pa.actions`: `c2pa.created/digitalCapture` as an ingredient, then `c2pa.watermarked`.
   - `c2pa.soft-binding` for the watermark.
   - A custom `app.verily.verification` assertion: verdict, requirement, attempt time.
   - The original's hash as the ingredient hard binding.

   Sign with the server's KMS key using `c2pa-rs`. Viewers will show "unrecognized signer" until Verily obtains a trust-list certificate, which is fine for our own resolver.
5. **At intake, run the detectors on every new upload.** A Verily handle or a fingerprint near-match to existing evidence means a replay of already-verified media, so reject or route to manual review. Fingerprint matches also catch copies whose watermark was stripped.
6. Exposing a C2PA-style `/matches/byBinding` resolver is optional. It lets anyone paste a re-shared clip and see "Verified on Verily, 12 Oct 2026."

Implementation home: a **Rust provenance worker**, not Python.

- It hosts `c2pa-rs`, the `trustmark` crate (ONNX via `ort`), and a PDQ crate.
- Video Seal and AudioSeal run as TorchScript through `tch` (libtorch bindings), or as an ONNX export.
- **Uncertainty**: neither runtime path is officially supported by Meta. Spike it first.

## 5. AI-generated media detection (complementary signal)

- **Watermark/manifest checks** (high precision, low recall):
  - Parse any C2PA manifest with `c2pa-rs` and flag `trainedAlgorithmicMedia` or `compositeWithTrainedAlgorithmicMedia`.
  - SynthID would catch injected Veo, Gemini or OpenAI imagery even after re-encoding. Google exposes it only as a rate-limited portal today, so watch for an API.
  - For in-app capture these checks matter mostly against **injected** content. Attackers strip metadata, but pixel watermarks persist.
- **Classifier vendors**:
  - **Hive**: image, video, audio and text APIs; names the likely source model.
  - **Reality Defender**: public API, free tier of 50/month at launch; video was coming later.
  - **Sensity**: forensic platform, sales-led.
  - Vendors quote 96–99%, but **Deepfake-Eval-2024** found open-source detectors lose about 45–50% AUC on in-the-wild 2024 deepfakes (best open-source AUC 0.58). Commercial tools did better, but still below human analysts.
- **Use**: one vote in the council or a manual-review trigger, never an automatic pass. Under the AGENTS.md rules, a provider result is an untrusted signal.

## 6. Threat model: what each control proves

| Control                                              | Proves                                                                                                     | Does **not** prove                                       | Main bypass                                                                         |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| SHA-256 + pinned object version (today)              | Bytes unchanged since upload                                                                               | Where bytes came from                                    | Any substituted file                                                                |
| Device signature, no attestation (today)             | Some key on some device signed it                                                                          | That the key is hardware-backed, or that the app is ours | Emulator or hooked app with a software key                                          |
| **Key Attestation** (+ verified boot, app id, patch) | Key lives in TEE/StrongBox of a locked, genuine device running our signed APK; created after our challenge | That the camera produced the frames                      | Leaked keybox, attestation relay, TEE/boot-chain exploits                           |
| Play Integrity strong + env verdicts                 | Google's risk view of device, app and install; capture/control apps present                                | Frame origin                                             | Same keybox ecosystem; verdict spoofing on rooted devices                           |
| App Attest                                           | Genuine Apple device running our App Store build                                                           | Jailbreak absence; frame origin                          | Jailbroken device serving assertions                                                |
| Chunk hash chain + live checkpoints                  | Recording grew in real time after the challenge                                                            | Real scene                                               | Real-time injection on a compromised device                                         |
| **Randomized live challenge**                        | Scene content was produced after `T0`                                                                      | Scene not on a screen                                    | Real-time deepfake that responds to the prompt (costly)                             |
| IMU ↔ optical-flow correlation                       | Phone physically moved as the video moved                                                                  | Absence of a screen                                      | Filming a screen while moving it consistently; EIS/OIS and timestamp skew add noise |
| Invisible watermark (ours)                           | Media passed through Verily's pipeline (lookup key)                                                        | Anything about capture                                   | Removal by regeneration; transfer, mitigated by fingerprint check                   |
| Perceptual fingerprint registry                      | Media resembles previously seen evidence                                                                   | Novel fakes                                              | Heavy edits                                                                         |
| AI detectors                                         | Statistical likelihood of synthesis                                                                        | Authenticity                                             | Unseen generators; false positives                                                  |

**Specific attacks:**

- **Gallery upload / pre-made file.** Defeated by the challenge before recording, the per-attempt attested key, the timing window and (later) live checkpoints.
- **Virtual camera / Camera2 hook (Xposed/LSPosed, Frida) on a rooted device.**
  - Verified boot, locked bootloader and Play Integrity strong push this toward keybox abuse, which is rare and revocable.
  - The Camera2 metadata (sensor timestamps, exposure, ISO, focal length) should be internally consistent and match the device model.
  - MITRE ATLAS documented iProov's camera-injection KYC bypass in Dec 2025. iProov claims some variants need no root, so do not assume attestation alone closes this.
- **Screen replay (filming a monitor).** No cryptography stops it. Mitigations:
  - Live prompts tied to the physical scene.
  - Moiré, flicker and recapture cues in the council prompt.
  - IMU/flow consistency.
  - Optional depth or parallax checks (multi-camera or ToF where available).
  - This stays a residual risk; size rewards accordingly.
- **Account farming and relays.** Use `recentDeviceActivity`, the App Attest fraud receipt, DeviceCheck/`deviceRecall` bits, and attestation-key reuse analytics.

**Make the live challenge part of the product.** It is the most effective anti-replay control and can be a playful, visible ritual rather than friction. Examples: "start by tracing today's glyph in the air", "say the two words on screen", "tilt to reveal the colour". The council then checks it. This fits Verily's "do things differently" brief and doubles as security, since the prompt is unpredictable before `T0`.

## 7. Phased plan

### Phase 1: prove the key, the device, and the moment (about 2–3 engineer-weeks)

| Work                                                                                                                                                                                           | Libraries                                                                 | Effort   |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- | -------- |
| Server `beginCapture` challenge issued **before** recording; `T0`/`T1` window                                                                                                                  | Serverpod                                                                 | 2 days   |
| Per-attempt StrongBox/TEE key with `setAttestationChallenge`; send the chain; Dart verifier (roots JSON, status list, extension parse, policy) with test vectors from `android/keyattestation` | Kotlin platform channel; Dart `pointycastle` + ASN.1, or a Kotlin sidecar | 6–8 days |
| Tighten Play Integrity: strong label for high-value rewards; `appAccessRiskVerdict`, `recentDeviceActivity`, cert digest                                                                       | Existing verifier                                                         | 1–2 days |
| Randomized live prompt + council check for it                                                                                                                                                  | Existing council                                                          | 3–4 days |
| Perceptual fingerprint registry for duplicate and replay detection (PDQ on sampled keyframes)                                                                                                  | Rust PDQ crate via worker or `dart:ffi`                                   | 3–5 days |

Outcome: the server can state "a hardware key on a locked, genuine device running our app, created after our nonce, signed this exact recording, the scene responded to an unpredictable prompt, and we have not seen this media before." That closes the stated attestation gap and the gallery-upload gap.

**Status (21 October 2026).** The first three rows are built; [capture integrity](verification.md#capture-integrity) describes them as shipped.

- `beginCapture` opens a capture window before recording and records `T0`; proof captured before it is refused. `T1` is bounded by the window's 30-minute life rather than by the requirement's duration.
- The app generates a fresh StrongBox/TEE key per window with `setAttestationChallenge(SHA-256(captureChallenge ‖ attemptId))` and sends its chain. The Dart verifier in `verily_server/lib/src/action_verification/key_attestation/` is a port, not a sidecar, tested against nine `android/keyattestation` device chains plus a synthetic authority. It treats `SUSPENDED` serials as revoked, which is stricter than upstream. Signature mode `required` now means "attested".
- Play Integrity requires `MEETS_STRONG_INTEGRITY` above the review threshold, sends unknown capture, control, and overlay apps and `LEVEL_3`/`LEVEL_4` activity to a person, and checks the signing-certificate digest. `appLicensingVerdict` and `deviceRecall` are not read yet.

The randomized live prompt (beyond today's spoken word) and the PDQ registry are still to do.

### Phase 2: iOS parity and durable provenance (about 4–6 weeks)

| Work                                                                                                                  | Libraries                                              | Effort                                     |
| --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------ |
| iOS App Attest (attest once per install; assertion over manifest digest per capture), DeviceCheck bits, fraud receipt | DeviceCheck, Swift platform channel; Dart CBOR + X.509 | 1–1.5 weeks                                |
| Rust provenance worker: Video Seal / TrustMark / AudioSeal embed + detect; handle registry; intake replay detection   | `tch` or `ort`, `trustmark` crate                      | 2–3 weeks (includes a 3-day runtime spike) |
| C2PA manifests on published renditions, KMS-signed, soft-binding + custom verification assertion                      | `c2pa-rs`                                              | 1 week                                     |
| Hash-chained fragmented MP4 + IMU trace capture; run IMU/flow correlation in **shadow mode** to measure false rejects | CameraX/Camera2, `sensors_plus`, OpenCV flow in worker | 1–2 weeks                                  |

**Status (22 October 2026).** The App Attest part of the first row is built; [Apple App Attest](verification.md#apple-app-attest) describes it as shipped.

- An iPhone registers one App Attest key per account and install through `appAttest.registerKey`, attested against a single-use server challenge. The Dart verifier in `verily_server/lib/src/action_verification/app_attest/` checks the CBOR object, the chain to the pinned Apple App Attestation Root CA, the nonce, `rpIdHash`, the zero counter, the environment's `aaguid`, and Apple's validation category. It is tested against Apple's two published sample attestations, a recorded iOS 27 attestation with two assertions, and a synthetic authority.
- Each capture is signed with an assertion over the window's `verily-capture-manifest-v1`; the server requires a strictly increasing counter per key. A valid assertion records the new `secureEnclaveAttested` level, below `hardwareAttested`, because App Attest gives no verified-boot or jailbreak signal and its key is per install rather than per capture.
- Not built yet: DeviceCheck's two per-device bits, verifying and refreshing the fraud-risk receipt (it is stored), and a run on a physical iPhone.

### Phase 3: standards-grade capture credentials (quarter-scale, higher uncertainty)

- On-device C2PA signing at capture, following the Pixel blueprint. Verily runs a small CA that issues short-lived certificates only to keys whose attestation verifies, then signs `c2pa.hash.bmff.v3` manifests with Merkle chunks. This uses `c2pa-rs` via `flutter_rust_bridge` or `c2pa-android`/`c2pa-swift`. Then pursue C2PA Conformance (AL2 on Android) so any C2PA verifier recognizes Verily captures. Estimate 6–10 weeks plus program lead time.
- Live signed checkpoints streamed during recording. The C2PA 2.3 live/segment signing is a reference.
- Optional ingestion path: accept media carrying native AL2 credentials (Pixel photos now, Pixel video since mid-2026).
- Evaluate Apple's reported Reference Image API, which covers stills only.
- Buy-versus-build check, when screen-recapture robustness or enterprise sponsors demand it: commercial watermarks (Steg.AI, Digimarc, IMATAG) or Truepic Lens.
- Add an AI-detector vendor as one council vote, if measured lift justifies the cost.

## 8. Open uncertainties

- No public Android SDK for C2PA capture exists beyond the C2PA community libraries. The Pixel I/O 2026 video announcement and the Apple Reference Image details come from secondary sources.
- SynthID detection has no public API. OpenAI's verify tool is in preview.
- Video Seal and AudioSeal from Rust (TorchScript or ONNX), and their latency on our clip lengths, need a spike. The robustness figures are self-reported.
- Licenses to confirm before shipping: PDQ/vPDQ file headers, SilentCipher weights, WavMark, `c2pa-swift`.
- IMU/flow correlation is research-grade. Movee reported about 8% EER with constrained pans. Start in shadow mode.
- A determined attacker with a fresh leaked keybox, or a real-time deepfake filmed off a screen, can still pass. Reward sizing, manual review and post-hoc revocation remain essential.

## References

- Google Pixel/Android C2PA blueprint: https://blog.google/security/pixel-android-trusted-images-c2pa-content-credentials/
- Pixel C2PA SDK label in credentials: https://lucaberton.com/blog/google-c2pa-sdk-android-issued-by-google-content-credentials/
- I/O 2026 Pixel video credentials: https://jetstream.blog/?p=216445 ; https://securitybrief.co.uk/story/google-expands-ai-content-checks-across-search-chrome
- SynthID-Image paper: https://huggingface.co/papers/2510.09263
- SynthID Detector launch / public: https://www.gigazine.net/gsc_news/en/20250521-google-synthid-detector/ ; https://itdaily.com/news/software/google-makes-synthid-detector-available-worldwide/ ; https://pasqualepillitteri.it/en/news/21499/google-synthid-detector-openai-nvidia-kakao
- SynthID Text: https://ai.google.dev/responsible/docs/safeguards/synthid
- OpenAI provenance: https://openai.com/index/advancing-content-provenance ; https://help.openai.com/en/articles/8912793 ; https://openai.com/index/understanding-the-source-of-what-we-see-and-hear-online ; https://forum.effectivealtruism.org/posts/oMJzXc79CexLqi52F/openai-does-not-appear-to-be-applying-watermarks-honestly
- Meta Video Seal: https://github.com/facebookresearch/videoseal ; https://arxiv.org/abs/2412.09492 ; https://arxiv.org/html/2412.09492
- Meta AudioSeal: https://github.com/facebookresearch/audioseal ; https://arxiv.org/abs/2401.17264v2
- Meta watermarking release coverage: https://the-decoder.com/meta-releases-ai-video-watermarking-model-that-survives-common-edits ; https://www.siliconrepublic.com/machines/meta-watermarking-ai-tool-research-data-social-media
- Adobe TrustMark: https://raw.githubusercontent.com/adobe/trustmark/main/FAQ.md ; https://opensource.contentauthenticity.org/docs/trustmark/FAQ ; https://docs.rs/crate/trustmark/latest
- Durable Content Credentials: https://contentauthenticity.org/blog/digital-watermarking-interoperable-durable-content-credentials
- Digimarc C2PA 2.1: https://www.digimarc.com/press-releases/2024/10/08/digimarc-brings-digital-watermarking-c2pa-21-standard
- Steg.AI / IMATAG: https://siliconangle.com/2024/11/20/steg-ai-launches-web-app-simplify-digital-content-protection-enterprises/ ; https://www.stork.ai/ru/imatag
- Microsoft InvisMark: https://github.com/microsoft/InvisMark ; https://arxiv.org/abs/2411.07795v2
- C2PA spec 2.2: https://spec.c2pa.org/specifications/specifications/2.2/specs/C2PA_Specification.html
- C2PA soft binding API: https://spec.c2pa.org/specifications/specifications/2.4/softbinding/Decoupled.html
- C2PA soft-binding algorithm list: https://github.com/c2pa-org/softbinding-algorithm-list/blob/main/softbinding-algorithm-list.json
- C2PA implementation guidance: https://spec.c2pa.org/specifications/specifications/2.3/guidance/Guidance.html
- C2PA conformance: https://opensource.contentauthenticity.org/docs/conformance/ ; https://www.trustoverip.org/blog/2025/05/20/egwg-2025-05-15-the-c2pa-conformance-program-scott-perry/
- c2pa-rs and formats: https://github.com/contentauth/c2pa-rs ; https://github.com/contentauth/c2pa-rs/blob/main/docs/supported-formats.md
- c2pa-android / c2pa-swift: https://github.com/contentauth/c2pa-android ; https://opensource.contentauthenticity.org/docs/c2pa-swift/ ; https://opensource.contentauthenticity.org/docs/c2pa-android-example/
- Flutter packages: https://pub.dev/packages/c2pa_flutter ; https://pub.dev/packages/c2pa_view
- Samsung S25 credentials: https://www.androidauthority.com/galaxy-s25-content-credentials-3523256 ; https://www.phonearena.com/news/ai-edited-photos-about-to-expose-themselves-as-samsung-expands-this-galaxy-s25-feature-to-millions-older-phones_id173556
- Nikon revocation: https://petapixel.com/2025/09/22/nikon-cant-fully-solve-the-z6-iiis-c2pa-problems-alone/ ; https://c2paviewer.com/articles/nikon-cameras-c2pa
- Adoption 2026: https://softwareseni.com/c2pa-adoption-in-2026-hardware-platforms-and-verification-reality
- Apple Reference Image (secondary): https://c2paviewer.com/articles/apple-reference-image-vs-c2pa ; https://petapixel.com/reel/2026/08/11/apple-seems-to-be-making-an-iphone-photo-authentication-feature/
- Truepic Lens: https://truepic.com/c2pa/capture
- ProofMode: https://guardianproject.info/code/c2pa ; https://apt.izzysoft.de/fdroid/index/apk/org.witness.proofmode?repo=wind
- Android Key Attestation: https://developer.android.com/privacy-and-security/security-key-attestation ; https://source.android.com/docs/security/features/keystore/attestation ; https://github.com/android/keyattestation
- Root rotation: https://bayton.org/android/android-enterprise-faq/key-attestation-root-certificate-change/ ; https://newreleases.io/project/github/GrapheneOS/Auditor/release/92
- Attestation bypasses: https://www.guardsquare.com/blog/bypassing-key-attestation-api
- Play Integrity: https://developer.android.com/google/play/integrity/verdicts ; https://developer.android.com/google/play/integrity/improvements
- Apple App Attest: https://developer.apple.com/tutorials/data/documentation/devicecheck/validating-apps-that-connect-to-your-server.md ; https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity.md ; https://swiftrocks.com/app-attest-apple-protect-ios-jailbreak
- invisible-watermark: https://github.com/ShieldMnt/invisible-watermark
- StegaStamp: https://github.com/tancik/StegaStamp
- SilentCipher: https://github.com/sony/silentcipher
- WavMark: https://arxiv.org/abs/2308.12770
- Watermark attacks: https://arxiv.org/pdf/2401.08573 ; https://arxiv.org/pdf/2412.12511
- PDQ: https://github.com/facebook/ThreatExchange/tree/main/pdq ; https://arxiv.org/pdf/1912.07745
- Deepfake detection limits: https://arxiv.org/abs/2503.02857v1 ; https://arxiv.org/pdf/2510.16556
- Hive: https://docs.thehive.ai/docs/ai-generated-content-detection
- Reality Defender: https://www.securitysystemsnews.com/article/reality-defender-launches-public-api-and-free-tier
- Camera injection: https://www.mobileidworld.com/mitre-atlas-adds-iproov-camera-injection-scenario-targeting-mobile-kyc/
- Movee sensor-motion liveness: https://users.cs.fiu.edu/~carbunar/caspr.lab/liveness.html
- Recapture detection patents: https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/11544835
