# Android Key Attestation test vectors

These certificate chains and their recorded key descriptions come unchanged
from Google's [`android/keyattestation`](https://github.com/android/keyattestation)
verifier, `testdata/` at commit `621149c4ebaeeea844d6f43098687c73c4d370a3`
(13 October 2026). They are © Google LLC and licensed under the
[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

Files are renamed `<device>-sdk<level>_<variant>`; `invalid_` files come from
`testdata/invalid/`. Keep them byte-identical so they can be compared with
upstream: `dprint` skips their JSON.

| Vector                                | What it exercises                                     |
| ------------------------------------- | ----------------------------------------------------- |
| `caiman-sdk36_SB_EC_RKP`              | StrongBox, remotely provisioned, legacy RSA root      |
| `caiman-sdk36_TEE_EC_RKP`             | TEE, remotely provisioned, legacy RSA root            |
| `tegu-sdk36_SB_EC_2026_ROOT`          | StrongBox under the 2026 ECDSA P-384 root             |
| `frankel-sdk37_TEE_EC_2026`           | TEE under the 2026 ECDSA P-384 root                   |
| `sony-xperia10-iii-sdk33_TEE_EC`      | Factory provisioned, expired intermediates, old patch |
| `akita-sdk34_TEE_EC_NONE`             | Unlocked bootloader, unverified boot                  |
| `akita-sdk34_TEE_RSA_NONE`            | RSA capture key                                       |
| `tokay-sdk37_TEE_MLDSA_RKP`           | ML-DSA capture key                                    |
| `marlin-sdk29_TEE_EC_NONE`            | Software attestation root                             |
| `invalid_malformed_rot_device_locked` | BER-encoded `deviceLocked` boolean                    |
