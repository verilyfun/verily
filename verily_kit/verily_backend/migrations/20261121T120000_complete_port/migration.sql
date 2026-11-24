-- Complete LeptosKit port tables (SQLite dialect):
-- app_backend_ops tables (account_closures, action_places + location, appeals,
-- capture_windows, evidence_decisions, reviewers, spoken_challenges),
-- upload reservations, verification jobs/votes, venue QR challenges,
-- Apple App Attest keys/challenges, DeviceCheck audits, appeal resolutions,
-- moderation cases/audits, abuse risk, AI usage & inference budget,
-- Verily Apps, API keys, redirect URIs, links, confirmations, webhooks,
-- and verification requests.

CREATE TABLE IF NOT EXISTS "account_closures" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"account_id" BLOB NOT NULL CHECK (length("account_id") = 16),
	"closed_at" TEXT NOT NULL,
	CONSTRAINT "account_closures_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "account_closures_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE UNIQUE INDEX IF NOT EXISTS "account_closures_account_id_key" ON "account_closures" ("account_id");

CREATE TABLE IF NOT EXISTS "action_places" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"action_id" BLOB NOT NULL CHECK (length("action_id") = 16),
	"place_name" TEXT NOT NULL CHECK (length("place_name") >= 1 AND length("place_name") <= 128),
	"radius_meters" INTEGER NOT NULL CHECK ("radius_meters" >= 0 AND "radius_meters" <= 50000),
	"latitude" REAL,
	"longitude" REAL,
	"location" BLOB,
	"created_at" TEXT NOT NULL,
	"updated_at" TEXT NOT NULL,
	CONSTRAINT "action_places_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "action_places_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "actions" ("id") ON DELETE CASCADE
) STRICT;
CREATE UNIQUE INDEX IF NOT EXISTS "action_places_action_id_key" ON "action_places" ("action_id");

CREATE TABLE IF NOT EXISTS "appeals" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"attempt_id" BLOB NOT NULL CHECK (length("attempt_id") = 16),
	"participant_id" BLOB NOT NULL CHECK (length("participant_id") = 16),
	"reason" TEXT NOT NULL CHECK (length("reason") >= 1 AND length("reason") <= 1000),
	"status" TEXT NOT NULL DEFAULT 'open' CHECK ("status" IN ('open', 'upheld', 'overturned')),
	"created_at" TEXT NOT NULL,
	CONSTRAINT "appeals_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "appeals_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "attempts" ("id") ON DELETE CASCADE,
	CONSTRAINT "appeals_participant_id_fkey" FOREIGN KEY ("participant_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX IF NOT EXISTS "appeals_participant_id_idx" ON "appeals" ("participant_id");
CREATE UNIQUE INDEX IF NOT EXISTS "appeals_attempt_id_key" ON "appeals" ("attempt_id");

CREATE TABLE IF NOT EXISTS "capture_windows" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"attempt_id" BLOB NOT NULL CHECK (length("attempt_id") = 16),
	"participant_id" BLOB NOT NULL CHECK (length("participant_id") = 16),
	"requirement_id" TEXT NOT NULL CHECK (length("requirement_id") >= 1 AND length("requirement_id") <= 64),
	"challenge" TEXT NOT NULL CHECK (length("challenge") >= 1 AND length("challenge") <= 64),
	"opened_at" TEXT NOT NULL,
	"expires_at" TEXT NOT NULL,
	"consumed_at" TEXT,
	"sha256_digest" TEXT CHECK (length("sha256_digest") <= 64),
	CONSTRAINT "capture_windows_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "capture_windows_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "attempts" ("id") ON DELETE CASCADE,
	CONSTRAINT "capture_windows_participant_id_fkey" FOREIGN KEY ("participant_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX IF NOT EXISTS "capture_windows_attempt_id_idx" ON "capture_windows" ("attempt_id");

CREATE TABLE IF NOT EXISTS "evidence_decisions" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"evidence_id" BLOB NOT NULL CHECK (length("evidence_id") = 16),
	"status" TEXT NOT NULL CHECK ("status" IN ('accepted', 'rejected', 'manual_review')),
	"verifier_type" TEXT NOT NULL CHECK (length("verifier_type") >= 1 AND length("verifier_type") <= 64),
	"reason_code" TEXT NOT NULL CHECK (length("reason_code") >= 1 AND length("reason_code") <= 64),
	"summary" TEXT NOT NULL CHECK (length("summary") <= 500),
	"reviewed_by" BLOB CHECK (length("reviewed_by") = 16),
	"created_at" TEXT NOT NULL,
	CONSTRAINT "evidence_decisions_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "evidence_decisions_evidence_id_fkey" FOREIGN KEY ("evidence_id") REFERENCES "evidence" ("id") ON DELETE CASCADE,
	CONSTRAINT "evidence_decisions_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "auth_accounts" ("id") ON DELETE SET NULL
) STRICT;
CREATE INDEX IF NOT EXISTS "evidence_decisions_evidence_id_idx" ON "evidence_decisions" ("evidence_id");

CREATE TABLE IF NOT EXISTS "reviewers" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"account_id" BLOB NOT NULL CHECK (length("account_id") = 16),
	"granted_at" TEXT NOT NULL,
	CONSTRAINT "reviewers_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "reviewers_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE UNIQUE INDEX IF NOT EXISTS "reviewers_account_id_key" ON "reviewers" ("account_id");

CREATE TABLE IF NOT EXISTS "spoken_challenges" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"attempt_id" BLOB NOT NULL CHECK (length("attempt_id") = 16),
	"participant_id" BLOB NOT NULL CHECK (length("participant_id") = 16),
	"requirement_id" TEXT NOT NULL CHECK (length("requirement_id") >= 1 AND length("requirement_id") <= 64),
	"word" TEXT NOT NULL CHECK (length("word") >= 1 AND length("word") <= 32),
	"issued_at" TEXT NOT NULL,
	"expires_at" TEXT NOT NULL,
	"bound_at" TEXT,
	CONSTRAINT "spoken_challenges_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "spoken_challenges_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "attempts" ("id") ON DELETE CASCADE,
	CONSTRAINT "spoken_challenges_participant_id_fkey" FOREIGN KEY ("participant_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX IF NOT EXISTS "spoken_challenges_attempt_id_idx" ON "spoken_challenges" ("attempt_id");

CREATE TABLE "evidence_upload_reservations" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"attempt_id" BLOB NOT NULL CHECK (length("attempt_id") = 16),
	"participant_id" BLOB NOT NULL CHECK (length("participant_id") = 16),
	"requirement_id" TEXT NOT NULL CHECK (length("requirement_id") >= 1 AND length("requirement_id") <= 64),
	"object_key" TEXT NOT NULL CHECK (length("object_key") >= 1 AND length("object_key") <= 256),
	"mime_type" TEXT NOT NULL CHECK (length("mime_type") >= 1 AND length("mime_type") <= 64),
	"max_byte_length" INTEGER NOT NULL,
	"expires_at" TEXT NOT NULL,
	"confirmed_at" TEXT,
	"version_id" TEXT CHECK (length("version_id") <= 128),
	"sha256_digest" TEXT CHECK (length("sha256_digest") <= 64),
	"byte_length" INTEGER,
	"created_at" TEXT NOT NULL,
	CONSTRAINT "evidence_upload_reservations_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "evidence_upload_reservations_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "attempts" ("id") ON DELETE CASCADE,
	CONSTRAINT "evidence_upload_reservations_participant_id_fkey" FOREIGN KEY ("participant_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "evidence_upload_reservations_attempt_id_idx" ON "evidence_upload_reservations" ("attempt_id");
CREATE INDEX "evidence_upload_reservations_participant_id_idx" ON "evidence_upload_reservations" ("participant_id");

CREATE TABLE "evidence_verification_jobs" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"evidence_id" BLOB NOT NULL CHECK (length("evidence_id") = 16),
	"attempt_id" BLOB NOT NULL CHECK (length("attempt_id") = 16),
	"status" TEXT NOT NULL DEFAULT 'queued' CHECK ("status" IN ('queued', 'running', 'completed', 'failed')),
	"attempt_count" INTEGER NOT NULL,
	"last_error_code" TEXT,
	"created_at" TEXT NOT NULL,
	"updated_at" TEXT NOT NULL,
	CONSTRAINT "evidence_verification_jobs_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "evidence_verification_jobs_evidence_id_fkey" FOREIGN KEY ("evidence_id") REFERENCES "evidence" ("id") ON DELETE CASCADE,
	CONSTRAINT "evidence_verification_jobs_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "attempts" ("id") ON DELETE CASCADE
) STRICT;
CREATE UNIQUE INDEX "evidence_verification_jobs_evidence_id_key" ON "evidence_verification_jobs" ("evidence_id");
CREATE INDEX "evidence_verification_jobs_status_idx" ON "evidence_verification_jobs" ("status");

CREATE TABLE "evidence_verification_votes" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"evidence_id" BLOB NOT NULL CHECK (length("evidence_id") = 16),
	"model_id" TEXT NOT NULL CHECK (length("model_id") >= 1 AND length("model_id") <= 128),
	"verdict" TEXT NOT NULL CHECK ("verdict" IN ('fulfilled', 'not_fulfilled', 'uncertain', 'failed')),
	"confidence" REAL,
	"prompt_injection_detected" INTEGER NOT NULL,
	"latency_ms" INTEGER NOT NULL,
	"error_code" TEXT,
	"created_at" TEXT NOT NULL,
	CONSTRAINT "evidence_verification_votes_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "evidence_verification_votes_evidence_id_fkey" FOREIGN KEY ("evidence_id") REFERENCES "evidence" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "evidence_verification_votes_evidence_id_idx" ON "evidence_verification_votes" ("evidence_id");

CREATE TABLE "action_qr_challenges" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"action_id" BLOB NOT NULL CHECK (length("action_id") = 16),
	"creator_id" BLOB NOT NULL CHECK (length("creator_id") = 16),
	"code_hash" TEXT NOT NULL CHECK (length("code_hash") >= 1 AND length("code_hash") <= 64),
	"expires_at" TEXT NOT NULL,
	"consumed_at" TEXT,
	"consumed_by_attempt_id" BLOB CHECK (length("consumed_by_attempt_id") = 16),
	"created_at" TEXT NOT NULL,
	CONSTRAINT "action_qr_challenges_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "action_qr_challenges_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "actions" ("id") ON DELETE CASCADE,
	CONSTRAINT "action_qr_challenges_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE UNIQUE INDEX "action_qr_challenges_code_hash_key" ON "action_qr_challenges" ("code_hash");
CREATE INDEX "action_qr_challenges_action_id_idx" ON "action_qr_challenges" ("action_id");

CREATE TABLE "app_attest_challenges" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"account_id" BLOB NOT NULL CHECK (length("account_id") = 16),
	"nonce" TEXT NOT NULL CHECK (length("nonce") >= 1 AND length("nonce") <= 128),
	"expires_at" TEXT NOT NULL,
	"consumed_at" TEXT,
	"created_at" TEXT NOT NULL,
	CONSTRAINT "app_attest_challenges_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "app_attest_challenges_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "app_attest_challenges_account_id_idx" ON "app_attest_challenges" ("account_id");

CREATE TABLE "app_attest_keys" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"account_id" BLOB NOT NULL CHECK (length("account_id") = 16),
	"key_id_hash" TEXT NOT NULL CHECK (length("key_id_hash") >= 1 AND length("key_id_hash") <= 64),
	"public_key_b64" TEXT NOT NULL CHECK (length("public_key_b64") >= 1 AND length("public_key_b64") <= 128),
	"sign_count" INTEGER NOT NULL,
	"receipt_b64" TEXT,
	"receipt_expires_at" TEXT,
	"risk_metric" INTEGER,
	"revoked_at" TEXT,
	"created_at" TEXT NOT NULL,
	"updated_at" TEXT NOT NULL,
	CONSTRAINT "app_attest_keys_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "app_attest_keys_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE UNIQUE INDEX "app_attest_keys_key_id_hash_key" ON "app_attest_keys" ("key_id_hash");
CREATE INDEX "app_attest_keys_account_id_idx" ON "app_attest_keys" ("account_id");

CREATE TABLE "device_check_audits" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"operator_id" BLOB NOT NULL CHECK (length("operator_id") = 16),
	"operation" TEXT NOT NULL CHECK ("operation" IN ('query', 'update')),
	"banned" INTEGER NOT NULL,
	"review_required" INTEGER NOT NULL,
	"note" TEXT NOT NULL CHECK (length("note") <= 500),
	"created_at" TEXT NOT NULL,
	CONSTRAINT "device_check_audits_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "device_check_audits_operator_id_fkey" FOREIGN KEY ("operator_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "device_check_audits_operator_id_idx" ON "device_check_audits" ("operator_id");

CREATE TABLE "appeal_resolutions" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"appeal_id" BLOB NOT NULL CHECK (length("appeal_id") = 16),
	"resolved_by" BLOB NOT NULL CHECK (length("resolved_by") = 16),
	"decision" TEXT NOT NULL CHECK ("decision" IN ('upheld', 'overturned')),
	"note" TEXT NOT NULL CHECK (length("note") <= 500),
	"created_at" TEXT NOT NULL,
	CONSTRAINT "appeal_resolutions_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "appeal_resolutions_appeal_id_fkey" FOREIGN KEY ("appeal_id") REFERENCES "appeals" ("id") ON DELETE CASCADE
) STRICT;
CREATE UNIQUE INDEX "appeal_resolutions_appeal_id_key" ON "appeal_resolutions" ("appeal_id");

CREATE TABLE "moderation_cases" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"reporter_id" BLOB NOT NULL CHECK (length("reporter_id") = 16),
	"target_kind" TEXT NOT NULL CHECK ("target_kind" IN ('action', 'attempt', 'account', 'app')),
	"target_id" TEXT NOT NULL CHECK (length("target_id") >= 1 AND length("target_id") <= 64),
	"reason" TEXT NOT NULL CHECK (length("reason") >= 1 AND length("reason") <= 128),
	"status" TEXT NOT NULL DEFAULT 'open' CHECK ("status" IN ('open', 'under_review', 'held', 'cleared', 'removed', 'appealed')),
	"notes" TEXT CHECK (length("notes") <= 1000),
	"assigned_moderator_id" BLOB CHECK (length("assigned_moderator_id") = 16),
	"created_at" TEXT NOT NULL,
	"updated_at" TEXT NOT NULL,
	CONSTRAINT "moderation_cases_pkey" PRIMARY KEY ("id")
) STRICT;
CREATE INDEX "moderation_cases_target_id_idx" ON "moderation_cases" ("target_id");
CREATE INDEX "moderation_cases_status_idx" ON "moderation_cases" ("status");

CREATE TABLE "moderation_audit_entries" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"case_id" BLOB NOT NULL CHECK (length("case_id") = 16),
	"actor_id" BLOB NOT NULL CHECK (length("actor_id") = 16),
	"action" TEXT NOT NULL CHECK (length("action") >= 1 AND length("action") <= 64),
	"note" TEXT NOT NULL CHECK (length("note") <= 500),
	"created_at" TEXT NOT NULL,
	CONSTRAINT "moderation_audit_entries_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "moderation_audit_entries_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "moderation_cases" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "moderation_audit_entries_case_id_idx" ON "moderation_audit_entries" ("case_id");

CREATE TABLE "abuse_risk_assessments" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"subject_hash" TEXT NOT NULL CHECK (length("subject_hash") >= 1 AND length("subject_hash") <= 64),
	"tier" TEXT NOT NULL CHECK ("tier" IN ('low', 'elevated', 'high', 'blocked')),
	"reason_code" TEXT NOT NULL CHECK (length("reason_code") >= 1 AND length("reason_code") <= 128),
	"expires_at" TEXT,
	"created_at" TEXT NOT NULL,
	CONSTRAINT "abuse_risk_assessments_pkey" PRIMARY KEY ("id")
) STRICT;
CREATE INDEX "abuse_risk_assessments_subject_hash_idx" ON "abuse_risk_assessments" ("subject_hash");

CREATE TABLE "ai_usage_requests" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"account_id" BLOB NOT NULL CHECK (length("account_id") = 16),
	"feature" TEXT NOT NULL CHECK (length("feature") >= 1 AND length("feature") <= 64),
	"created_at" TEXT NOT NULL,
	CONSTRAINT "ai_usage_requests_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "ai_usage_requests_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "ai_usage_requests_account_id_idx" ON "ai_usage_requests" ("account_id");

CREATE TABLE "inference_cost_reservations" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"model_id" TEXT NOT NULL CHECK (length("model_id") >= 1 AND length("model_id") <= 128),
	"estimated_micro_usd" INTEGER NOT NULL,
	"settled_micro_usd" INTEGER,
	"created_at" TEXT NOT NULL,
	CONSTRAINT "inference_cost_reservations_pkey" PRIMARY KEY ("id")
) STRICT;
CREATE INDEX "inference_cost_reservations_created_at_idx" ON "inference_cost_reservations" ("created_at");

CREATE TABLE "verily_apps" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"owner_id" BLOB NOT NULL CHECK (length("owner_id") = 16),
	"name" TEXT NOT NULL CHECK (length("name") >= 1 AND length("name") <= 80),
	"slug" TEXT NOT NULL CHECK (length("slug") >= 1 AND length("slug") <= 64),
	"webhook_url" TEXT CHECK (length("webhook_url") <= 512),
	"webhook_secret" TEXT NOT NULL CHECK (length("webhook_secret") >= 1 AND length("webhook_secret") <= 128),
	"active" INTEGER NOT NULL,
	"created_at" TEXT NOT NULL,
	"updated_at" TEXT NOT NULL,
	CONSTRAINT "verily_apps_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_apps_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE UNIQUE INDEX "verily_apps_slug_key" ON "verily_apps" ("slug");
CREATE INDEX "verily_apps_owner_id_idx" ON "verily_apps" ("owner_id");

CREATE TABLE "verily_app_keys" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"app_id" BLOB NOT NULL CHECK (length("app_id") = 16),
	"key_prefix" TEXT NOT NULL CHECK (length("key_prefix") >= 1 AND length("key_prefix") <= 24),
	"key_hash" TEXT NOT NULL CHECK (length("key_hash") >= 1 AND length("key_hash") <= 64),
	"revoked_at" TEXT,
	"created_at" TEXT NOT NULL,
	CONSTRAINT "verily_app_keys_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_keys_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE
) STRICT;
CREATE UNIQUE INDEX "verily_app_keys_key_hash_key" ON "verily_app_keys" ("key_hash");
CREATE INDEX "verily_app_keys_app_id_idx" ON "verily_app_keys" ("app_id");

CREATE TABLE "verily_app_redirect_uris" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"app_id" BLOB NOT NULL CHECK (length("app_id") = 16),
	"uri" TEXT NOT NULL CHECK (length("uri") >= 1 AND length("uri") <= 512),
	"created_at" TEXT NOT NULL,
	CONSTRAINT "verily_app_redirect_uris_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_redirect_uris_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "verily_app_redirect_uris_app_id_idx" ON "verily_app_redirect_uris" ("app_id");

CREATE TABLE "verily_app_links" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"app_id" BLOB NOT NULL CHECK (length("app_id") = 16),
	"account_id" BLOB NOT NULL CHECK (length("account_id") = 16),
	"external_user_id" TEXT NOT NULL CHECK (length("external_user_id") >= 1 AND length("external_user_id") <= 128),
	"created_at" TEXT NOT NULL,
	CONSTRAINT "verily_app_links_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_links_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE,
	CONSTRAINT "verily_app_links_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "verily_app_links_app_id_idx" ON "verily_app_links" ("app_id");
CREATE INDEX "verily_app_links_account_id_idx" ON "verily_app_links" ("account_id");

CREATE TABLE "verily_app_link_codes" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"app_id" BLOB NOT NULL CHECK (length("app_id") = 16),
	"account_id" BLOB NOT NULL CHECK (length("account_id") = 16),
	"code_hash" TEXT NOT NULL CHECK (length("code_hash") >= 1 AND length("code_hash") <= 64),
	"redirect_uri" TEXT NOT NULL CHECK (length("redirect_uri") >= 1 AND length("redirect_uri") <= 512),
	"expires_at" TEXT NOT NULL,
	"exchanged_at" TEXT,
	"created_at" TEXT NOT NULL,
	CONSTRAINT "verily_app_link_codes_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_link_codes_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE,
	CONSTRAINT "verily_app_link_codes_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "auth_accounts" ("id") ON DELETE CASCADE
) STRICT;
CREATE UNIQUE INDEX "verily_app_link_codes_code_hash_key" ON "verily_app_link_codes" ("code_hash");
CREATE INDEX "verily_app_link_codes_app_id_idx" ON "verily_app_link_codes" ("app_id");

CREATE TABLE "verily_app_confirmations" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"app_id" BLOB NOT NULL CHECK (length("app_id") = 16),
	"action_id" BLOB NOT NULL CHECK (length("action_id") = 16),
	"external_user_id" TEXT NOT NULL CHECK (length("external_user_id") >= 1 AND length("external_user_id") <= 128),
	"idempotency_key" TEXT NOT NULL CHECK (length("idempotency_key") >= 1 AND length("idempotency_key") <= 128),
	"verified" INTEGER NOT NULL,
	"created_at" TEXT NOT NULL,
	CONSTRAINT "verily_app_confirmations_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_confirmations_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE,
	CONSTRAINT "verily_app_confirmations_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "actions" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "verily_app_confirmations_app_id_idx" ON "verily_app_confirmations" ("app_id");
CREATE INDEX "verily_app_confirmations_action_id_idx" ON "verily_app_confirmations" ("action_id");

CREATE TABLE "verily_app_pull_checks" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"app_id" BLOB NOT NULL CHECK (length("app_id") = 16),
	"attempt_id" BLOB NOT NULL CHECK (length("attempt_id") = 16),
	"requirement_id" TEXT NOT NULL CHECK (length("requirement_id") >= 1 AND length("requirement_id") <= 64),
	"status" TEXT NOT NULL DEFAULT 'pending' CHECK ("status" IN ('pending', 'verified', 'rejected', 'failed')),
	"attempts" INTEGER NOT NULL,
	"created_at" TEXT NOT NULL,
	"updated_at" TEXT NOT NULL,
	CONSTRAINT "verily_app_pull_checks_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_pull_checks_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE,
	CONSTRAINT "verily_app_pull_checks_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "attempts" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "verily_app_pull_checks_attempt_id_idx" ON "verily_app_pull_checks" ("attempt_id");
CREATE INDEX "verily_app_pull_checks_status_idx" ON "verily_app_pull_checks" ("status");

CREATE TABLE "verily_app_webhook_deliveries" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"app_id" BLOB NOT NULL CHECK (length("app_id") = 16),
	"event_type" TEXT NOT NULL CHECK (length("event_type") >= 1 AND length("event_type") <= 64),
	"payload_json" TEXT NOT NULL,
	"status" TEXT NOT NULL DEFAULT 'pending' CHECK ("status" IN ('pending', 'delivered', 'failed')),
	"attempts" INTEGER NOT NULL,
	"last_status_code" INTEGER,
	"next_attempt_at" TEXT NOT NULL,
	"created_at" TEXT NOT NULL,
	"updated_at" TEXT NOT NULL,
	CONSTRAINT "verily_app_webhook_deliveries_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_webhook_deliveries_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "verily_app_webhook_deliveries_app_id_idx" ON "verily_app_webhook_deliveries" ("app_id");
CREATE INDEX "verily_app_webhook_deliveries_status_idx" ON "verily_app_webhook_deliveries" ("status");

CREATE TABLE "verification_requests" (
	"id" BLOB NOT NULL CHECK (length("id") = 16),
	"app_id" BLOB NOT NULL CHECK (length("app_id") = 16),
	"action_id" BLOB NOT NULL CHECK (length("action_id") = 16),
	"participant_id" BLOB CHECK (length("participant_id") = 16),
	"attempt_id" BLOB CHECK (length("attempt_id") = 16),
	"external_subject" TEXT CHECK (length("external_subject") <= 128),
	"callback_url" TEXT CHECK (length("callback_url") <= 512),
	"status" TEXT NOT NULL DEFAULT 'open' CHECK ("status" IN ('open', 'in_progress', 'verified', 'rejected', 'expired', 'cancelled')),
	"receipt_jws" TEXT,
	"expires_at" TEXT NOT NULL,
	"created_at" TEXT NOT NULL,
	"updated_at" TEXT NOT NULL,
	CONSTRAINT "verification_requests_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verification_requests_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE,
	CONSTRAINT "verification_requests_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "actions" ("id") ON DELETE CASCADE
) STRICT;
CREATE INDEX "verification_requests_app_id_idx" ON "verification_requests" ("app_id");
CREATE INDEX "verification_requests_status_idx" ON "verification_requests" ("status");
