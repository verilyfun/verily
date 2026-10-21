# Evidence storage

Video, photo, and audio proof is stored privately, read once end to end to be
hashed and identified, pinned to an immutable version, and deleted after a
short retention window. Two storage modes share one flow:

| Mode    | Where bytes live                                      | Allowed in                                             |
| ------- | ----------------------------------------------------- | ------------------------------------------------------ |
| `local` | Serverpod's database storage (`LocalEvidenceStorage`) | `development`, `test` only                             |
| `b2`    | A private, versioned Backblaze B2 bucket (S3 API)     | Every run mode; the only one in staging and production |

`VERILY_EVIDENCE_STORAGE` may be `b2` or `local`. When it is unset,
development and test use B2 if any `VERILY_EVIDENCE_B2_*` value is present and
local storage otherwise, so a fresh checkout runs end to end with no object
storage and no secret. Staging and production always build B2 and refuse to
start without all five values; a missing secret can never fall back to the
database. Startup prints a `[development-only]` line whenever local storage is
active.

## Flow

```mermaid
sequenceDiagram
  participant App
  participant API as Serverpod
  participant DB as Postgres
  participant Store as Evidence storage
  participant Worker as Verification worker

  App->>API: requestMediaUpload(attempt, requirement, contentType, byteLength)
  API->>DB: lock or create the upload reservation (binds the spoken word)
  API-->>App: upload description, 5 minutes, exact size and type
  App->>Store: upload the bytes (FileUploader)
  App->>API: confirmMediaUpload(capturedAt, durationSeconds, integrity)
  API->>Store: read end to end
  API->>API: SHA-256, container sniff, size and type match
  API->>DB: evidence row + pinned version + verification job (one transaction)
  API-->>App: status null, attempt verifying
  Worker->>Store: short-lived link to the pinned version only
  Worker->>DB: decision, votes, then attempt completion
```

- **Paths are server-derived:**
  `action-evidence/<authUserId>/<attemptId>/<requirementId>.<ext>`. Clients
  never choose a path, bucket, or storage id.
- **Version pinning.** B2 versions every PUT and does not support
  `If-None-Match`, so confirmation stores the exact `x-amz-version-id` it read
  and every later reader (models, reviewers) requests that version. Local
  storage issues a synthetic `local-sha256-<digest>` version and every review
  link re-hashes the stored bytes before it is issued. Serverpod's upload route
  deletes each upload description after one use, and a confirmed reservation
  never issues another, so confirmed bytes cannot change.
- **Integrity seal.** `EvidenceIntegrityPolicy`
  (`verily.evidence-integrity.v1`) checks the storage response against the
  reservation and refuses any later path, version, checksum, size, or type
  substitution. The device's binding hash commits to the same digest for
  every media kind.

## Accepted media

The allow-list in `evidence_media_types.dart` is the only source of truth; a
type absent from it can never be reserved, confirmed, verified, or reviewed.

| Kind  | Content types                                | Largest upload | Duration                  |
| ----- | -------------------------------------------- | -------------- | ------------------------- |
| video | `video/mp4`, `video/quicktime`, `video/webm` | 150 MiB        | Required, within the rule |
| photo | `image/jpeg`, `image/png`, `image/heic`      | 20 MiB         | Never                     |
| audio | `audio/mp4` (m4a), `audio/webm`              | 50 MiB         | Required, within the rule |

Confirmation sniffs the first 4 KiB: JPEG and PNG signatures, the EBML WebM
doctype, and ISO base media `ftyp` brands (HEIF brands, QuickTime `qt`,
audio-only `M4A`/`M4B`/`M4P`, MP4 and 3GP brands). The type the upload was
signed for, the type storage recorded, and the detected container must all
agree, or the object is deleted and the confirmation refused. Sniffing
identifies the container, not the content: the verifier still judges what the
media shows.

## Quotas and leases

| Limit                                   | Value                                 |
| --------------------------------------- | ------------------------------------- |
| Reservations per account per 24 hours   | 12                                    |
| Bytes reserved per account per 24 hours | 500 MiB                               |
| Upload URLs per proof                   | 3                                     |
| Confirmation attempts per proof         | 5                                     |
| Confirmation lease                      | 10 minutes (one inspection at a time) |
| Upload URL lifetime                     | 5 minutes                             |
| Review link lifetime                    | at most 10 minutes (5 by default)     |

One reservation exists per attempt and requirement. A row-locked `reserved` →
`confirming` lease lets only one inspection run at a time; an abandoned lease
recovers after ten minutes.

## Retention

Evidence is kept for 7 days (`evidenceRetention`); an open appeal extends it to
at most 30 days. A daily cleanup future call deletes expired objects and their
reservations in bounded batches. Decisions, digests, and audit rows outlive the
bytes.

## Backblaze setup (staging and production)

- One private (`allPrivate`) bucket per environment, with versioning on.
- A bucket-scoped application key restricted to the `action-evidence/`
  prefix, with exactly `deleteFiles`, `listBuckets`, `listFiles`,
  `readFiles`, and `writeFiles`. Never reuse an account-wide key.
- CORS allowing only the exact web origins in
  `VERILY_EVIDENCE_ALLOWED_WEB_ORIGINS`, methods `GET`, `HEAD`, `PUT`, request
  headers `content-length` and `content-type`, exposing `etag` and
  `x-amz-version-id`.
- Secrets: `VERILY_EVIDENCE_B2_S3_ENDPOINT`, `VERILY_EVIDENCE_B2_REGION`,
  `VERILY_EVIDENCE_B2_BUCKET_NAME`, `VERILY_EVIDENCE_B2_KEY_ID`,
  `VERILY_EVIDENCE_B2_APPLICATION_KEY`, resolved through Monosecret
  (optional in development, required in staging and production).
- Pin `VERILY_EVIDENCE_STORAGE_POLICY_VERSION=verily.evidence-storage.production.v1`.
  `ProductionEvidencePreflight` checks the live bucket against these
  expectations through a read-only control-plane adapter; environment claims
  alone never make storage production ready, and the readiness gate
  (`bin/check_verily_production_readiness.dart`) refuses a release without a
  reviewed preflight artifact.
