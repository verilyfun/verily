# App Attest test vectors

These files come unchanged from
[`jewei/app-attest-php`](https://github.com/jewei/app-attest-php), `spec/` at
commit `6aacdf120677e00419abfe88bbefb9ffb67fe07a` (12 October 2026), whose
`spec/provenance.json` records their sources and hashes. Keep them
byte-identical so they can be compared with upstream: `dprint` skips their
JSON.

| Vector                               | What it is                                                                                                                                                                                                                       | What it exercises                                                                                          |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `apple-sample-attestation.json`      | The sample in Apple's [Attestation Object Validation Guide](https://developer.apple.com/documentation/devicecheck/attestation-object-validation-guide) (production, validation category 1, bundle version `1`). © Apple Inc.     | A production attestation with Apple's authenticator data extensions, checked against the pinned root       |
| `apple-sample-attestation-2024.json` | The same guide's 2024 sample: iOS 18.0, no authenticator data extensions. © Apple Inc.                                                                                                                                           | An attestation from an iOS version that reports no validation category                                     |
| `termakan-ios27-attestation.json`    | A real attestation and two assertions (counters 1 and 2) from a development-signed build on iOS 27.0.1, recorded by Jewei Mak for that package. Production environment, validation category 3 (development), bundle version `1`. | Assertions over known client data with the attested key, counters, and the refusal of a development binary |

Apple's 2026 sample was also compared with Apple's page on 22 October 2026 and
is identical. The guide's own prose differs from its data in two places, as
the upstream `notes` record: the app passed the raw challenge text as
`clientDataHash`, and the "expected public key SHA256 hash" it prints is not
the SHA-256 of the key (the key identifier is). The verifier follows the
data.

Apple publishes no sample assertion, so assertions come from the termakan
recording and from the synthetic authority in
`test/integration/test_tools/app_attest_test_authority.dart`.

`termakan-ios27-attestation.json` is licensed under the MIT License:

> Copyright (c) 2026 Jewei Mak
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to
> deal in the Software without restriction, including without limitation the
> rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
> sell copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
> FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
> IN THE SOFTWARE.
