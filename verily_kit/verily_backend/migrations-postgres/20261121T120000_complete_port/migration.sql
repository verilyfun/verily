-- Complete LeptosKit port tables (Postgres + PostGIS dialect).
-- dialect: postgres

CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE "action_places" ADD COLUMN IF NOT EXISTS "location" geography(Point, 4326);
CREATE INDEX IF NOT EXISTS "action_places_location_gist_idx" ON "action_places" USING GIST ("location");

CREATE TABLE "evidence_upload_reservations" (
	"id" uuid NOT NULL,
	"attempt_id" uuid NOT NULL,
	"participant_id" uuid NOT NULL,
	"requirement_id" text NOT NULL,
	"object_key" text NOT NULL,
	"mime_type" text NOT NULL,
	"max_byte_length" bigint NOT NULL,
	"expires_at" timestamptz NOT NULL,
	"confirmed_at" timestamptz,
	"version_id" text,
	"sha256_digest" text,
	"byte_length" bigint,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "evidence_upload_reservations_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "evidence_upload_reservations_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "attempts" ("id") ON DELETE CASCADE
);
CREATE INDEX "evidence_upload_reservations_attempt_id_idx" ON "evidence_upload_reservations" ("attempt_id");
CREATE INDEX "evidence_upload_reservations_participant_id_idx" ON "evidence_upload_reservations" ("participant_id");

CREATE TABLE "evidence_verification_jobs" (
	"id" uuid NOT NULL,
	"evidence_id" uuid NOT NULL,
	"attempt_id" uuid NOT NULL,
	"status" text NOT NULL DEFAULT 'queued',
	"attempt_count" bigint NOT NULL,
	"last_error_code" text,
	"created_at" timestamptz NOT NULL,
	"updated_at" timestamptz NOT NULL,
	CONSTRAINT "evidence_verification_jobs_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "evidence_verification_jobs_status_values" CHECK ("status" IN ('queued', 'running', 'completed', 'failed')),
	CONSTRAINT "evidence_verification_jobs_evidence_id_fkey" FOREIGN KEY ("evidence_id") REFERENCES "evidence" ("id") ON DELETE CASCADE,
	CONSTRAINT "evidence_verification_jobs_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "attempts" ("id") ON DELETE CASCADE
);
CREATE UNIQUE INDEX "evidence_verification_jobs_evidence_id_key" ON "evidence_verification_jobs" ("evidence_id");
CREATE INDEX "evidence_verification_jobs_status_idx" ON "evidence_verification_jobs" ("status");

CREATE TABLE "evidence_verification_votes" (
	"id" uuid NOT NULL,
	"evidence_id" uuid NOT NULL,
	"model_id" text NOT NULL,
	"verdict" text NOT NULL,
	"confidence" double precision,
	"prompt_injection_detected" boolean NOT NULL,
	"latency_ms" bigint NOT NULL,
	"error_code" text,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "evidence_verification_votes_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "evidence_verification_votes_verdict_values" CHECK ("verdict" IN ('fulfilled', 'not_fulfilled', 'uncertain', 'failed')),
	CONSTRAINT "evidence_verification_votes_evidence_id_fkey" FOREIGN KEY ("evidence_id") REFERENCES "evidence" ("id") ON DELETE CASCADE
);
CREATE INDEX "evidence_verification_votes_evidence_id_idx" ON "evidence_verification_votes" ("evidence_id");

CREATE TABLE "action_qr_challenges" (
	"id" uuid NOT NULL,
	"action_id" uuid NOT NULL,
	"creator_id" uuid NOT NULL,
	"code_hash" text NOT NULL,
	"expires_at" timestamptz NOT NULL,
	"consumed_at" timestamptz,
	"consumed_by_attempt_id" uuid,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "action_qr_challenges_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "action_qr_challenges_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "actions" ("id") ON DELETE CASCADE
);
CREATE UNIQUE INDEX "action_qr_challenges_code_hash_key" ON "action_qr_challenges" ("code_hash");
CREATE INDEX "action_qr_challenges_action_id_idx" ON "action_qr_challenges" ("action_id");

CREATE TABLE "app_attest_challenges" (
	"id" uuid NOT NULL,
	"account_id" uuid NOT NULL,
	"nonce" text NOT NULL,
	"expires_at" timestamptz NOT NULL,
	"consumed_at" timestamptz,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "app_attest_challenges_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "app_attest_challenges_account_id_idx" ON "app_attest_challenges" ("account_id");

CREATE TABLE "app_attest_keys" (
	"id" uuid NOT NULL,
	"account_id" uuid NOT NULL,
	"key_id_hash" text NOT NULL,
	"public_key_b64" text NOT NULL,
	"sign_count" bigint NOT NULL,
	"receipt_b64" text,
	"receipt_expires_at" timestamptz,
	"risk_metric" bigint,
	"revoked_at" timestamptz,
	"created_at" timestamptz NOT NULL,
	"updated_at" timestamptz NOT NULL,
	CONSTRAINT "app_attest_keys_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "app_attest_keys_key_id_hash_key" ON "app_attest_keys" ("key_id_hash");
CREATE INDEX "app_attest_keys_account_id_idx" ON "app_attest_keys" ("account_id");

CREATE TABLE "device_check_audits" (
	"id" uuid NOT NULL,
	"operator_id" uuid NOT NULL,
	"operation" text NOT NULL,
	"banned" boolean NOT NULL,
	"review_required" boolean NOT NULL,
	"note" text NOT NULL,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "device_check_audits_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "device_check_audits_operation_values" CHECK ("operation" IN ('query', 'update'))
);
CREATE INDEX "device_check_audits_operator_id_idx" ON "device_check_audits" ("operator_id");

CREATE TABLE "appeal_resolutions" (
	"id" uuid NOT NULL,
	"appeal_id" uuid NOT NULL,
	"resolved_by" uuid NOT NULL,
	"decision" text NOT NULL,
	"note" text NOT NULL,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "appeal_resolutions_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "appeal_resolutions_decision_values" CHECK ("decision" IN ('upheld', 'overturned')),
	CONSTRAINT "appeal_resolutions_appeal_id_fkey" FOREIGN KEY ("appeal_id") REFERENCES "appeals" ("id") ON DELETE CASCADE
);
CREATE UNIQUE INDEX "appeal_resolutions_appeal_id_key" ON "appeal_resolutions" ("appeal_id");

CREATE TABLE "moderation_cases" (
	"id" uuid NOT NULL,
	"reporter_id" uuid NOT NULL,
	"target_kind" text NOT NULL,
	"target_id" text NOT NULL,
	"reason" text NOT NULL,
	"status" text NOT NULL DEFAULT 'open',
	"notes" text,
	"assigned_moderator_id" uuid,
	"created_at" timestamptz NOT NULL,
	"updated_at" timestamptz NOT NULL,
	CONSTRAINT "moderation_cases_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "moderation_cases_target_kind_values" CHECK ("target_kind" IN ('action', 'attempt', 'account', 'app')),
	CONSTRAINT "moderation_cases_status_values" CHECK ("status" IN ('open', 'under_review', 'held', 'cleared', 'removed', 'appealed'))
);
CREATE INDEX "moderation_cases_target_id_idx" ON "moderation_cases" ("target_id");
CREATE INDEX "moderation_cases_status_idx" ON "moderation_cases" ("status");

CREATE TABLE "moderation_audit_entries" (
	"id" uuid NOT NULL,
	"case_id" uuid NOT NULL,
	"actor_id" uuid NOT NULL,
	"action" text NOT NULL,
	"note" text NOT NULL,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "moderation_audit_entries_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "moderation_audit_entries_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "moderation_cases" ("id") ON DELETE CASCADE
);
CREATE INDEX "moderation_audit_entries_case_id_idx" ON "moderation_audit_entries" ("case_id");

CREATE TABLE "abuse_risk_assessments" (
	"id" uuid NOT NULL,
	"subject_hash" text NOT NULL,
	"tier" text NOT NULL,
	"reason_code" text NOT NULL,
	"expires_at" timestamptz,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "abuse_risk_assessments_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "abuse_risk_assessments_tier_values" CHECK ("tier" IN ('low', 'elevated', 'high', 'blocked'))
);
CREATE INDEX "abuse_risk_assessments_subject_hash_idx" ON "abuse_risk_assessments" ("subject_hash");

CREATE TABLE "ai_usage_requests" (
	"id" uuid NOT NULL,
	"account_id" uuid NOT NULL,
	"feature" text NOT NULL,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "ai_usage_requests_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "ai_usage_requests_account_id_idx" ON "ai_usage_requests" ("account_id");

CREATE TABLE "inference_cost_reservations" (
	"id" uuid NOT NULL,
	"model_id" text NOT NULL,
	"estimated_micro_usd" bigint NOT NULL,
	"settled_micro_usd" bigint,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "inference_cost_reservations_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "inference_cost_reservations_created_at_idx" ON "inference_cost_reservations" ("created_at");

CREATE TABLE "verily_apps" (
	"id" uuid NOT NULL,
	"owner_id" uuid NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"webhook_url" text,
	"webhook_secret" text NOT NULL,
	"active" boolean NOT NULL,
	"created_at" timestamptz NOT NULL,
	"updated_at" timestamptz NOT NULL,
	CONSTRAINT "verily_apps_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "verily_apps_slug_key" ON "verily_apps" ("slug");
CREATE INDEX "verily_apps_owner_id_idx" ON "verily_apps" ("owner_id");

CREATE TABLE "verily_app_keys" (
	"id" uuid NOT NULL,
	"app_id" uuid NOT NULL,
	"key_prefix" text NOT NULL,
	"key_hash" text NOT NULL,
	"revoked_at" timestamptz,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "verily_app_keys_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_keys_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE
);
CREATE UNIQUE INDEX "verily_app_keys_key_hash_key" ON "verily_app_keys" ("key_hash");
CREATE INDEX "verily_app_keys_app_id_idx" ON "verily_app_keys" ("app_id");

CREATE TABLE "verily_app_redirect_uris" (
	"id" uuid NOT NULL,
	"app_id" uuid NOT NULL,
	"uri" text NOT NULL,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "verily_app_redirect_uris_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_redirect_uris_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE
);
CREATE INDEX "verily_app_redirect_uris_app_id_idx" ON "verily_app_redirect_uris" ("app_id");

CREATE TABLE "verily_app_links" (
	"id" uuid NOT NULL,
	"app_id" uuid NOT NULL,
	"account_id" uuid NOT NULL,
	"external_user_id" text NOT NULL,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "verily_app_links_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_links_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE
);
CREATE INDEX "verily_app_links_app_id_idx" ON "verily_app_links" ("app_id");
CREATE INDEX "verily_app_links_account_id_idx" ON "verily_app_links" ("account_id");

CREATE TABLE "verily_app_link_codes" (
	"id" uuid NOT NULL,
	"app_id" uuid NOT NULL,
	"account_id" uuid NOT NULL,
	"code_hash" text NOT NULL,
	"redirect_uri" text NOT NULL,
	"expires_at" timestamptz NOT NULL,
	"exchanged_at" timestamptz,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "verily_app_link_codes_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_link_codes_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE
);
CREATE UNIQUE INDEX "verily_app_link_codes_code_hash_key" ON "verily_app_link_codes" ("code_hash");
CREATE INDEX "verily_app_link_codes_app_id_idx" ON "verily_app_link_codes" ("app_id");

CREATE TABLE "verily_app_confirmations" (
	"id" uuid NOT NULL,
	"app_id" uuid NOT NULL,
	"action_id" uuid NOT NULL,
	"external_user_id" text NOT NULL,
	"idempotency_key" text NOT NULL,
	"verified" boolean NOT NULL,
	"created_at" timestamptz NOT NULL,
	CONSTRAINT "verily_app_confirmations_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_confirmations_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE,
	CONSTRAINT "verily_app_confirmations_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "actions" ("id") ON DELETE CASCADE
);
CREATE INDEX "verily_app_confirmations_app_id_idx" ON "verily_app_confirmations" ("app_id");
CREATE INDEX "verily_app_confirmations_action_id_idx" ON "verily_app_confirmations" ("action_id");

CREATE TABLE "verily_app_pull_checks" (
	"id" uuid NOT NULL,
	"app_id" uuid NOT NULL,
	"attempt_id" uuid NOT NULL,
	"requirement_id" text NOT NULL,
	"status" text NOT NULL DEFAULT 'pending',
	"attempts" bigint NOT NULL,
	"created_at" timestamptz NOT NULL,
	"updated_at" timestamptz NOT NULL,
	CONSTRAINT "verily_app_pull_checks_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_pull_checks_status_values" CHECK ("status" IN ('pending', 'verified', 'rejected', 'failed')),
	CONSTRAINT "verily_app_pull_checks_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE,
	CONSTRAINT "verily_app_pull_checks_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "attempts" ("id") ON DELETE CASCADE
);
CREATE INDEX "verily_app_pull_checks_attempt_id_idx" ON "verily_app_pull_checks" ("attempt_id");
CREATE INDEX "verily_app_pull_checks_status_idx" ON "verily_app_pull_checks" ("status");

CREATE TABLE "verily_app_webhook_deliveries" (
	"id" uuid NOT NULL,
	"app_id" uuid NOT NULL,
	"event_type" text NOT NULL,
	"payload_json" text NOT NULL,
	"status" text NOT NULL DEFAULT 'pending',
	"attempts" bigint NOT NULL,
	"last_status_code" bigint,
	"next_attempt_at" timestamptz NOT NULL,
	"created_at" timestamptz NOT NULL,
	"updated_at" timestamptz NOT NULL,
	CONSTRAINT "verily_app_webhook_deliveries_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verily_app_webhook_deliveries_status_values" CHECK ("status" IN ('pending', 'delivered', 'failed')),
	CONSTRAINT "verily_app_webhook_deliveries_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE
);
CREATE INDEX "verily_app_webhook_deliveries_app_id_idx" ON "verily_app_webhook_deliveries" ("app_id");
CREATE INDEX "verily_app_webhook_deliveries_status_idx" ON "verily_app_webhook_deliveries" ("status");

CREATE TABLE "verification_requests" (
	"id" uuid NOT NULL,
	"app_id" uuid NOT NULL,
	"action_id" uuid NOT NULL,
	"participant_id" uuid,
	"attempt_id" uuid,
	"external_subject" text,
	"callback_url" text,
	"status" text NOT NULL DEFAULT 'open',
	"receipt_jws" text,
	"expires_at" timestamptz NOT NULL,
	"created_at" timestamptz NOT NULL,
	"updated_at" timestamptz NOT NULL,
	CONSTRAINT "verification_requests_pkey" PRIMARY KEY ("id"),
	CONSTRAINT "verification_requests_status_values" CHECK ("status" IN ('open', 'in_progress', 'verified', 'rejected', 'expired', 'cancelled')),
	CONSTRAINT "verification_requests_app_id_fkey" FOREIGN KEY ("app_id") REFERENCES "verily_apps" ("id") ON DELETE CASCADE,
	CONSTRAINT "verification_requests_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "actions" ("id") ON DELETE CASCADE
);
CREATE INDEX "verification_requests_app_id_idx" ON "verification_requests" ("app_id");
CREATE INDEX "verification_requests_status_idx" ON "verification_requests" ("status");
