BEGIN;

--
-- CREATE POSTGIS EXTENSION IF AVAILABLE
--
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'postgis') THEN
    EXECUTE 'CREATE EXTENSION IF NOT EXISTS postgis';
  ELSE
    RAISE EXCEPTION 'Required extension "postgis" is not available on this instance. Please install PostGIS. For instructions, see https://docs.serverpod.dev/upgrading/upgrade-to-postgis.';
  END IF;
END
$$;

--
-- Function: gen_random_uuid_v7()
-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74
-- License: MIT (copyright notice included on the generator source code).
--
create or replace function gen_random_uuid_v7()
returns uuid
as $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$
language plpgsql
volatile;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_abuse_risk_assessment" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "actionDefinitionId" uuid NOT NULL,
    "assessmentKey" text NOT NULL,
    "phase" text NOT NULL,
    "policyVersion" text NOT NULL,
    "disposition" text NOT NULL,
    "tier" text NOT NULL,
    "score" bigint NOT NULL,
    "signalCodes" json NOT NULL,
    "correlationWindowStartsAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_abuse_assessment_key_idx" ON "verily_abuse_risk_assessment" USING btree ("assessmentKey");
CREATE INDEX "verily_abuse_assessment_action_time_idx" ON "verily_abuse_risk_assessment" USING btree ("actionDefinitionId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_account_closure" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "status" text NOT NULL DEFAULT 'closed'::text,
    "requestedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "identityPurgedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "verily_account_closure_user_unique_idx" ON "verily_account_closure" USING btree ("authUserId");
CREATE INDEX "verily_account_closure_requested_idx" ON "verily_account_closure" USING btree ("requestedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_attempt" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "actionDefinitionId" uuid NOT NULL,
    "participantAuthUserId" uuid NOT NULL,
    "periodKey" text NOT NULL,
    "idempotencyKey" text NOT NULL,
    "status" text NOT NULL,
    "verificationScore" double precision,
    "verifiedRank" bigint,
    "rejectionCode" text,
    "rewardOutcome" text,
    "startedAt" timestamp without time zone NOT NULL,
    "submittedAt" timestamp without time zone,
    "verifiedAt" timestamp without time zone,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "verily_action_attempt_verified_window_idx" ON "verily_action_attempt" USING btree ("status", "verifiedAt", "actionDefinitionId");
CREATE UNIQUE INDEX "verily_action_attempt_idempotency_idx" ON "verily_action_attempt" USING btree ("participantAuthUserId", "idempotencyKey");
CREATE UNIQUE INDEX "verily_action_attempt_period_idx" ON "verily_action_attempt" USING btree ("actionDefinitionId", "participantAuthUserId", "periodKey");
CREATE INDEX "verily_action_attempt_participant_idx" ON "verily_action_attempt" USING btree ("participantAuthUserId", "updatedAt");
CREATE INDEX "verily_action_attempt_status_idx" ON "verily_action_attempt" USING btree ("actionDefinitionId", "status", "updatedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_capture_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "attemptId" uuid NOT NULL,
    "requirementId" uuid NOT NULL,
    "participantAuthUserId" uuid NOT NULL,
    "nonce" text NOT NULL,
    "requestHash" text,
    "evidenceBindingHash" text,
    "expiresAt" timestamp without time zone NOT NULL,
    "usedAt" timestamp without time zone,
    "provider" text,
    "verdict" text,
    "tokenHash" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_action_capture_challenge_nonce_unique_idx" ON "verily_action_capture_challenge" USING btree ("nonce");
CREATE UNIQUE INDEX "verily_action_capture_challenge_request_hash_unique_idx" ON "verily_action_capture_challenge" USING btree ("requestHash");
CREATE INDEX "verily_action_capture_challenge_attempt_created_idx" ON "verily_action_capture_challenge" USING btree ("attemptId", "createdAt");
CREATE INDEX "verily_action_capture_challenge_requirement_fk_idx" ON "verily_action_capture_challenge" USING btree ("requirementId");
CREATE INDEX "verily_action_capture_challenge_expiry_idx" ON "verily_action_capture_challenge" USING btree ("expiresAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_definition" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "creatorAuthUserId" uuid NOT NULL,
    "actionKey" text NOT NULL,
    "revision" bigint NOT NULL DEFAULT 1,
    "title" text NOT NULL,
    "description" text NOT NULL,
    "status" text NOT NULL,
    "recurrence" text NOT NULL,
    "timeZone" text NOT NULL,
    "maxVerifiedCompletions" bigint,
    "verifiedCompletions" bigint NOT NULL DEFAULT 0,
    "opensAt" timestamp without time zone,
    "closesAt" timestamp without time zone,
    "publishedAt" timestamp without time zone,
    "pausedAt" timestamp without time zone,
    "visibility" text NOT NULL DEFAULT 'public'::text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_action_definition_creator_key_idx" ON "verily_action_definition" USING btree ("creatorAuthUserId", "actionKey", "revision");
CREATE INDEX "verily_action_definition_creator_updated_idx" ON "verily_action_definition" USING btree ("creatorAuthUserId", "updatedAt");
CREATE INDEX "verily_action_definition_status_created_idx" ON "verily_action_definition" USING btree ("status", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_evidence" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "attemptId" uuid NOT NULL,
    "requirementId" uuid NOT NULL,
    "kind" text NOT NULL,
    "storagePath" text,
    "storageVersionId" text,
    "mimeType" text,
    "sha256Digest" text,
    "byteLength" bigint,
    "durationSeconds" bigint,
    "location" geography(Point,4326),
    "accuracyMeters" double precision,
    "motionTraceJson" text,
    "motionTraceSha256" text,
    "motionSampleCount" bigint,
    "motionDurationMilliseconds" bigint,
    "motionAnalysisJson" text,
    "deviceRepetitionCount" bigint,
    "deviceTrackerVersion" text,
    "spokenChallengeId" uuid,
    "spokenChallengeWord" text,
    "deviceLocalCheckModelId" text,
    "deviceLocalCheckModelSha256" text,
    "deviceLocalCheckLabel" text,
    "deviceLocalCheckScore" double precision,
    "deviceLocalCheckMatchedFrames" bigint,
    "provenanceLevel" text NOT NULL DEFAULT 'basic'::text,
    "captureManifest" text,
    "captureSignature" text,
    "capturePublicKey" text,
    "captureKeyId" text,
    "captureKeyStorage" text,
    "captureCertificateChain" json,
    "captureDeviceKeyId" text,
    "capturedAt" timestamp without time zone NOT NULL,
    "submittedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_action_evidence_requirement_idx" ON "verily_action_evidence" USING btree ("attemptId", "requirementId");
CREATE INDEX "verily_action_evidence_submitted_idx" ON "verily_action_evidence" USING btree ("attemptId", "submittedAt");
CREATE INDEX "verily_action_evidence_requirement_fk_idx" ON "verily_action_evidence" USING btree ("requirementId");
CREATE INDEX "verily_action_evidence_spoken_challenge_idx" ON "verily_action_evidence" USING btree ("spokenChallengeId");
CREATE INDEX "verily_action_evidence_location_idx" ON "verily_action_evidence" USING gist ("location");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_external_rule" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "requirementId" uuid NOT NULL,
    "appId" uuid NOT NULL,
    "verificationMode" text NOT NULL DEFAULT 'push'::text
);

-- Indexes
CREATE UNIQUE INDEX "verily_action_external_rule_requirement_idx" ON "verily_action_external_rule" USING btree ("requirementId");
CREATE INDEX "verily_action_external_rule_app_idx" ON "verily_action_external_rule" USING btree ("appId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_location_rule" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "requirementId" uuid NOT NULL,
    "location" geography(Point,4326) NOT NULL,
    "radiusMeters" double precision NOT NULL,
    "maxAccuracyMeters" double precision NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_action_location_rule_requirement_idx" ON "verily_action_location_rule" USING btree ("requirementId");
CREATE INDEX "verily_action_location_rule_location_idx" ON "verily_action_location_rule" USING gist ("location");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_media_rule" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "requirementId" uuid NOT NULL,
    "kind" text NOT NULL,
    "verificationPrompt" text NOT NULL,
    "minDurationSeconds" bigint,
    "maxDurationSeconds" bigint,
    "minConfidence" double precision NOT NULL,
    "verificationPolicy" text NOT NULL DEFAULT 'singleModel'::text,
    "spokenChallengeRequired" boolean NOT NULL DEFAULT false,
    "movementKind" text,
    "targetRepetitions" bigint,
    "localCheckTask" text,
    "localCheckLabel" text,
    "localCheckMinScore" double precision,
    "localCheckMinFrames" bigint
);

-- Indexes
CREATE UNIQUE INDEX "verily_action_media_rule_requirement_idx" ON "verily_action_media_rule" USING btree ("requirementId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_motion_rule" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "requirementId" uuid NOT NULL,
    "motionType" text NOT NULL,
    "axis" text NOT NULL,
    "targetRepetitions" bigint NOT NULL,
    "minDurationSeconds" bigint NOT NULL,
    "maxDurationSeconds" bigint NOT NULL,
    "minAngularSpeedRadiansPerSecond" double precision NOT NULL,
    "maxAngularSpeedRadiansPerSecond" double precision NOT NULL,
    "minAxisDominance" double precision NOT NULL,
    "minFreeFallMilliseconds" bigint NOT NULL,
    "maxFreeFallMilliseconds" bigint NOT NULL,
    "minPeakAccelerationMetersPerSecondSquared" double precision NOT NULL,
    "maxPeakAccelerationMetersPerSecondSquared" double precision NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_action_motion_rule_requirement_idx" ON "verily_action_motion_rule" USING btree ("requirementId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_qr_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "requirementId" uuid NOT NULL,
    "createdByAuthUserId" uuid NOT NULL,
    "secretHash" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "usedAt" timestamp without time zone,
    "usedByAttemptId" uuid,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_action_qr_challenge_secret_unique_idx" ON "verily_action_qr_challenge" USING btree ("secretHash");
CREATE INDEX "verily_action_qr_challenge_requirement_expiry_idx" ON "verily_action_qr_challenge" USING btree ("requirementId", "expiresAt");
CREATE INDEX "verily_action_qr_challenge_used_attempt_idx" ON "verily_action_qr_challenge" USING btree ("usedByAttemptId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_qr_rule" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "requirementId" uuid NOT NULL,
    "secretHash" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_action_qr_rule_requirement_idx" ON "verily_action_qr_rule" USING btree ("requirementId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_requirement" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "actionDefinitionId" uuid NOT NULL,
    "requirementKey" text NOT NULL,
    "kind" text NOT NULL,
    "title" text NOT NULL,
    "instructions" text NOT NULL,
    "position" bigint NOT NULL,
    "isRequired" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_action_requirement_key_idx" ON "verily_action_requirement" USING btree ("actionDefinitionId", "requirementKey");
CREATE UNIQUE INDEX "verily_action_requirement_position_idx" ON "verily_action_requirement" USING btree ("actionDefinitionId", "position");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_action_spoken_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "attemptId" uuid NOT NULL,
    "requirementId" uuid NOT NULL,
    "participantAuthUserId" uuid NOT NULL,
    "word" text NOT NULL,
    "issuedAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "boundAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "verily_action_spoken_challenge_attempt_requirement_idx" ON "verily_action_spoken_challenge" USING btree ("attemptId", "requirementId", "issuedAt");
CREATE INDEX "verily_action_spoken_challenge_expiry_idx" ON "verily_action_spoken_challenge" USING btree ("expiresAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_ai_usage_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "operation" text NOT NULL,
    "status" text NOT NULL DEFAULT 'reserved'::text,
    "costUnits" bigint NOT NULL DEFAULT 1,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "verily_ai_usage_user_operation_created_idx" ON "verily_ai_usage_request" USING btree ("authUserId", "operation", "createdAt");
CREATE INDEX "verily_ai_usage_active_idx" ON "verily_ai_usage_request" USING btree ("authUserId", "operation", "status", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "creatorAuthUserId" uuid NOT NULL,
    "name" text NOT NULL,
    "websiteUrl" text,
    "status" text NOT NULL,
    "rateWindowStartedAt" timestamp without time zone,
    "rateWindowCount" bigint NOT NULL DEFAULT 0,
    "webhookUrl" text,
    "webhookSecretVersion" bigint NOT NULL DEFAULT 0,
    "previousWebhookSecretVersion" bigint,
    "webhookSecretRotatedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "revokedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "verily_app_creator_idx" ON "verily_app" USING btree ("creatorAuthUserId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_attest_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "nonce" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "usedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_app_attest_challenge_nonce_unique_idx" ON "verily_app_attest_challenge" USING btree ("nonce");
CREATE INDEX "verily_app_attest_challenge_owner_created_idx" ON "verily_app_attest_challenge" USING btree ("authUserId", "createdAt");
CREATE INDEX "verily_app_attest_challenge_expiry_idx" ON "verily_app_attest_challenge" USING btree ("expiresAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_attest_key" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "keyId" text NOT NULL,
    "publicKey" text NOT NULL,
    "environment" text NOT NULL,
    "signCount" bigint NOT NULL,
    "certificateChain" json NOT NULL,
    "receipt" text NOT NULL,
    "receiptCreatedAt" timestamp without time zone NOT NULL,
    "receiptRefreshAfter" timestamp without time zone NOT NULL,
    "receiptNotBefore" timestamp without time zone NOT NULL,
    "receiptExpiresAt" timestamp without time zone NOT NULL,
    "riskMetric" bigint,
    "validationCategory" bigint,
    "bundleVersion" text,
    "registeredAt" timestamp without time zone NOT NULL,
    "lastAssertedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "verily_app_attest_key_key_id_unique_idx" ON "verily_app_attest_key" USING btree ("keyId");
CREATE INDEX "verily_app_attest_key_owner_idx" ON "verily_app_attest_key" USING btree ("authUserId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_confirmation" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "appId" uuid NOT NULL,
    "keyId" text NOT NULL,
    "eventId" text NOT NULL,
    "payloadDigest" text NOT NULL,
    "actionKey" text NOT NULL,
    "subject" text NOT NULL,
    "actionDefinitionId" uuid,
    "attemptId" uuid,
    "occurredAt" timestamp without time zone NOT NULL,
    "receivedAt" timestamp without time zone NOT NULL,
    "outcome" text NOT NULL,
    "reasonCode" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_app_confirmation_event_idx" ON "verily_app_confirmation" USING btree ("appId", "eventId");
CREATE INDEX "verily_app_confirmation_received_idx" ON "verily_app_confirmation" USING btree ("appId", "id");
CREATE INDEX "verily_app_confirmation_attempt_idx" ON "verily_app_confirmation" USING btree ("attemptId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_event" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "appId" uuid NOT NULL,
    "eventId" text NOT NULL,
    "type" text NOT NULL,
    "dedupeKey" text NOT NULL,
    "body" text NOT NULL,
    "status" text NOT NULL,
    "attemptCount" bigint NOT NULL DEFAULT 0,
    "nextAttemptAt" timestamp without time zone NOT NULL,
    "leaseExpiresAt" timestamp without time zone,
    "lastStatusCode" bigint,
    "lastErrorCode" text,
    "deliveredAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_app_event_id_idx" ON "verily_app_event" USING btree ("eventId");
CREATE UNIQUE INDEX "verily_app_event_dedupe_idx" ON "verily_app_event" USING btree ("appId", "dedupeKey");
CREATE INDEX "verily_app_event_due_idx" ON "verily_app_event" USING btree ("status", "nextAttemptAt");
CREATE INDEX "verily_app_event_app_idx" ON "verily_app_event" USING btree ("appId", "id");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_key" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "appId" uuid NOT NULL,
    "keyId" text NOT NULL,
    "secretHash" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "lastUsedAt" timestamp without time zone,
    "revokedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "verily_app_key_id_idx" ON "verily_app_key" USING btree ("keyId");
CREATE INDEX "verily_app_key_app_idx" ON "verily_app_key" USING btree ("appId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_link" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "appId" uuid NOT NULL,
    "authUserId" uuid NOT NULL,
    "subject" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_app_link_subject_idx" ON "verily_app_link" USING btree ("appId", "subject");
CREATE UNIQUE INDEX "verily_app_link_account_idx" ON "verily_app_link" USING btree ("appId", "authUserId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_link_code" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "appId" uuid NOT NULL,
    "authUserId" uuid NOT NULL,
    "codeHash" text NOT NULL,
    "redirectUri" text NOT NULL,
    "state" text,
    "expiresAt" timestamp without time zone NOT NULL,
    "usedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_app_link_code_hash_idx" ON "verily_app_link_code" USING btree ("codeHash");
CREATE INDEX "verily_app_link_code_expiry_idx" ON "verily_app_link_code" USING btree ("expiresAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_pull_check" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "attemptId" uuid NOT NULL,
    "requirementId" uuid NOT NULL,
    "appId" uuid NOT NULL,
    "eventId" text NOT NULL,
    "reference" text,
    "status" text NOT NULL,
    "callCount" bigint NOT NULL DEFAULT 0,
    "nextCallAt" timestamp without time zone,
    "leaseExpiresAt" timestamp without time zone,
    "lastErrorCode" text,
    "reasonCode" text,
    "expiresAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_app_pull_check_requirement_idx" ON "verily_app_pull_check" USING btree ("attemptId", "requirementId");
CREATE UNIQUE INDEX "verily_app_pull_check_event_idx" ON "verily_app_pull_check" USING btree ("eventId");
CREATE INDEX "verily_app_pull_check_due_idx" ON "verily_app_pull_check" USING btree ("status", "nextCallAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_rate_window" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "appId" uuid NOT NULL,
    "bucket" text NOT NULL,
    "windowStartedAt" timestamp without time zone NOT NULL,
    "requestCount" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_app_rate_window_bucket_idx" ON "verily_app_rate_window" USING btree ("appId", "bucket");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_redirect_uri" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "appId" uuid NOT NULL,
    "uri" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_app_redirect_uri_idx" ON "verily_app_redirect_uri" USING btree ("appId", "uri");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_app_webhook_delivery" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "appId" uuid NOT NULL,
    "eventId" text NOT NULL,
    "eventType" text NOT NULL,
    "attemptNumber" bigint NOT NULL,
    "requestedAt" timestamp without time zone NOT NULL,
    "durationMilliseconds" bigint NOT NULL,
    "statusCode" bigint,
    "errorCode" text,
    "succeeded" boolean NOT NULL
);

-- Indexes
CREATE INDEX "verily_app_webhook_delivery_app_idx" ON "verily_app_webhook_delivery" USING btree ("appId", "id");
CREATE INDEX "verily_app_webhook_delivery_event_idx" ON "verily_app_webhook_delivery" USING btree ("eventId", "attemptNumber");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_device_check_audit" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "operatorAuthUserId" uuid NOT NULL,
    "tokenHash" text NOT NULL,
    "banned" boolean NOT NULL,
    "reviewRequired" boolean NOT NULL,
    "note" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_evidence_appeal" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "evidenceId" uuid NOT NULL,
    "attemptId" uuid NOT NULL,
    "creatorAuthUserId" uuid NOT NULL,
    "participantAuthUserId" uuid NOT NULL,
    "reason" text NOT NULL,
    "status" text NOT NULL,
    "resolutionNote" text,
    "resolvedByAuthUserId" uuid,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "resolvedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "verily_evidence_appeal_evidence_unique_idx" ON "verily_evidence_appeal" USING btree ("evidenceId");
CREATE INDEX "verily_evidence_appeal_creator_queue_idx" ON "verily_evidence_appeal" USING btree ("creatorAuthUserId", "status", "createdAt");
CREATE INDEX "verily_evidence_appeal_participant_idx" ON "verily_evidence_appeal" USING btree ("participantAuthUserId", "createdAt");
CREATE INDEX "verily_evidence_appeal_attempt_idx" ON "verily_evidence_appeal" USING btree ("attemptId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_evidence_decision" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "evidenceId" uuid NOT NULL,
    "status" text NOT NULL,
    "verifierType" text NOT NULL,
    "modelName" text,
    "modelVersion" text,
    "confidence" double precision,
    "reasonCode" text NOT NULL,
    "summary" text NOT NULL,
    "reviewedByAuthUserId" uuid,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "verily_evidence_decision_created_idx" ON "verily_evidence_decision" USING btree ("evidenceId", "createdAt");
CREATE INDEX "verily_evidence_decision_reviewer_idx" ON "verily_evidence_decision" USING btree ("reviewedByAuthUserId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_evidence_upload_reservation" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "attemptId" uuid NOT NULL,
    "requirementId" uuid NOT NULL,
    "kind" text NOT NULL,
    "storagePath" text NOT NULL,
    "contentType" text NOT NULL,
    "byteLength" bigint NOT NULL,
    "status" text NOT NULL,
    "spokenChallengeId" uuid,
    "requestCount" bigint NOT NULL DEFAULT 1,
    "confirmationAttemptCount" bigint NOT NULL DEFAULT 0,
    "reservedAt" timestamp without time zone NOT NULL,
    "lastSignedAt" timestamp without time zone NOT NULL,
    "uploadExpiresAt" timestamp without time zone NOT NULL,
    "retainUntil" timestamp without time zone NOT NULL,
    "confirmationStartedAt" timestamp without time zone,
    "confirmedAt" timestamp without time zone,
    "storageVersionId" text
);

-- Indexes
CREATE UNIQUE INDEX "verily_evidence_upload_attempt_requirement_idx" ON "verily_evidence_upload_reservation" USING btree ("attemptId", "requirementId");
CREATE UNIQUE INDEX "verily_evidence_upload_storage_path_idx" ON "verily_evidence_upload_reservation" USING btree ("storagePath");
CREATE INDEX "verily_evidence_upload_user_quota_idx" ON "verily_evidence_upload_reservation" USING btree ("authUserId", "reservedAt");
CREATE INDEX "verily_evidence_upload_cleanup_idx" ON "verily_evidence_upload_reservation" USING btree ("status", "retainUntil");
CREATE INDEX "verily_evidence_upload_requirement_fk_idx" ON "verily_evidence_upload_reservation" USING btree ("requirementId");
CREATE INDEX "verily_evidence_upload_spoken_challenge_idx" ON "verily_evidence_upload_reservation" USING btree ("spokenChallengeId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_evidence_verification_job" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "evidenceId" uuid NOT NULL,
    "status" text NOT NULL DEFAULT 'queued'::text,
    "attemptCount" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "startedAt" timestamp without time zone,
    "completedAt" timestamp without time zone,
    "lastErrorCode" text
);

-- Indexes
CREATE UNIQUE INDEX "verily_evidence_verification_evidence_unique_idx" ON "verily_evidence_verification_job" USING btree ("evidenceId");
CREATE INDEX "verily_evidence_verification_queue_idx" ON "verily_evidence_verification_job" USING btree ("status", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_evidence_verification_vote" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "decisionId" uuid NOT NULL,
    "evidenceId" uuid NOT NULL,
    "modelId" text NOT NULL,
    "resolvedModelId" text,
    "providerName" text,
    "responseId" text,
    "verdict" text NOT NULL,
    "spokenChallengeVerdict" text,
    "confidence" double precision,
    "latencyMilliseconds" bigint NOT NULL,
    "inputTokens" bigint,
    "outputTokens" bigint,
    "costCredits" double precision,
    "errorCode" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_evidence_verification_vote_decision_model_idx" ON "verily_evidence_verification_vote" USING btree ("decisionId", "modelId");
CREATE INDEX "verily_evidence_verification_vote_evidence_created_idx" ON "verily_evidence_verification_vote" USING btree ("evidenceId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_inference_cost_reservation" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "actionAttemptId" uuid NOT NULL,
    "callReference" text NOT NULL,
    "modelId" text NOT NULL,
    "policyVersion" text NOT NULL,
    "reservedMicros" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_inference_reservation_reference_idx" ON "verily_inference_cost_reservation" USING btree ("actionAttemptId", "callReference");
CREATE INDEX "verily_inference_reservation_created_idx" ON "verily_inference_cost_reservation" USING btree ("createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_moderation_audit_entry" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "caseId" uuid NOT NULL,
    "actorAuthUserId" uuid,
    "event" text NOT NULL,
    "note" text NOT NULL,
    "pauseActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "verily_moderation_audit_case_time_idx" ON "verily_moderation_audit_entry" USING btree ("caseId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_moderation_case" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "creatorAuthUserId" uuid NOT NULL,
    "actionDefinitionId" uuid NOT NULL,
    "reporterAuthUserId" uuid,
    "idempotencyKey" text NOT NULL,
    "category" text NOT NULL,
    "details" text NOT NULL,
    "status" text NOT NULL,
    "pauseActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "reviewedAt" timestamp without time zone,
    "reviewedByAuthUserId" uuid,
    "appealReason" text,
    "appealedAt" timestamp without time zone,
    "appealResolvedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "verily_moderation_case_report_key_idx" ON "verily_moderation_case" USING btree ("reporterAuthUserId", "idempotencyKey");
CREATE INDEX "verily_moderation_case_creator_pause_idx" ON "verily_moderation_case" USING btree ("creatorAuthUserId", "pauseActive");
CREATE INDEX "verily_moderation_case_action_pause_idx" ON "verily_moderation_case" USING btree ("actionDefinitionId", "pauseActive");
CREATE INDEX "verily_moderation_case_queue_idx" ON "verily_moderation_case" USING btree ("status", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_payout_wallet" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "walletAddress" text NOT NULL,
    "linkedAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_payout_wallet_user_idx" ON "verily_payout_wallet" USING btree ("authUserId");
CREATE UNIQUE INDEX "verily_payout_wallet_address_idx" ON "verily_payout_wallet" USING btree ("walletAddress");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_payout_wallet_link_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "walletAddress" text NOT NULL,
    "nonce" text NOT NULL,
    "message" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "usedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "verily_payout_wallet_link_nonce_idx" ON "verily_payout_wallet_link_challenge" USING btree ("nonce");
CREATE INDEX "verily_payout_wallet_link_user_created_idx" ON "verily_payout_wallet_link_challenge" USING btree ("authUserId", "createdAt");
CREATE INDEX "verily_payout_wallet_link_expiry_idx" ON "verily_payout_wallet_link_challenge" USING btree ("expiresAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_reward_payout" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "poolId" uuid NOT NULL,
    "attemptId" uuid NOT NULL,
    "recipientAuthUserId" uuid NOT NULL,
    "payoutIndex" bigint NOT NULL,
    "amount" bigint NOT NULL,
    "recipientWallet" text,
    "status" text NOT NULL,
    "releaseSignature" text,
    "attemptCount" bigint NOT NULL DEFAULT 0,
    "lastErrorCode" text,
    "releaseStartedAt" timestamp without time zone,
    "releasedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_reward_payout_attempt_idx" ON "verily_reward_payout" USING btree ("attemptId");
CREATE UNIQUE INDEX "verily_reward_payout_pool_index_idx" ON "verily_reward_payout" USING btree ("poolId", "payoutIndex");
CREATE INDEX "verily_reward_payout_pool_recipient_idx" ON "verily_reward_payout" USING btree ("poolId", "recipientAuthUserId");
CREATE INDEX "verily_reward_payout_recipient_idx" ON "verily_reward_payout" USING btree ("recipientAuthUserId", "createdAt");
CREATE INDEX "verily_reward_payout_status_idx" ON "verily_reward_payout" USING btree ("status", "updatedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_reward_pool" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "creatorAuthUserId" uuid NOT NULL,
    "actionKey" text NOT NULL,
    "cluster" text NOT NULL,
    "mint" text NOT NULL,
    "tokenSymbol" text NOT NULL,
    "decimals" bigint NOT NULL,
    "amountPerPayout" bigint NOT NULL,
    "maxPayouts" bigint NOT NULL,
    "maxWinsPerAccount" bigint NOT NULL DEFAULT 1,
    "payoutsReserved" bigint NOT NULL DEFAULT 0,
    "payoutsReleased" bigint NOT NULL DEFAULT 0,
    "creatorWallet" text,
    "escrowAddress" text,
    "arbiterAddress" text,
    "expiresAt" timestamp without time zone NOT NULL,
    "refundDelaySeconds" bigint NOT NULL,
    "refundAfter" timestamp without time zone NOT NULL,
    "status" text NOT NULL,
    "fundingSignature" text,
    "fundedAt" timestamp without time zone,
    "endedAt" timestamp without time zone,
    "closedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "verily_reward_pool_creator_key_idx" ON "verily_reward_pool" USING btree ("creatorAuthUserId", "actionKey");
CREATE UNIQUE INDEX "verily_reward_pool_escrow_idx" ON "verily_reward_pool" USING btree ("escrowAddress");
CREATE INDEX "verily_reward_pool_status_idx" ON "verily_reward_pool" USING btree ("status", "expiresAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "verily_verification_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "appId" uuid NOT NULL,
    "kind" text NOT NULL,
    "instructions" text,
    "check" text NOT NULL,
    "placeLatitude" double precision,
    "placeLongitude" double precision,
    "placeRadiusMeters" double precision,
    "spokenChallenge" boolean NOT NULL,
    "shareEvidence" boolean NOT NULL,
    "redirectUri" text NOT NULL,
    "state" text,
    "status" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "participantAuthUserId" uuid,
    "subject" text,
    "actionDefinitionId" uuid,
    "attemptId" uuid,
    "acceptedAt" timestamp without time zone,
    "evidenceShared" boolean NOT NULL DEFAULT false,
    "codeHash" text,
    "codeExpiresAt" timestamp without time zone,
    "codeUsedAt" timestamp without time zone,
    "completedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "verily_verification_request_app_idx" ON "verily_verification_request" USING btree ("appId", "createdAt");
CREATE INDEX "verily_verification_request_status_idx" ON "verily_verification_request" USING btree ("status", "expiresAt");
CREATE UNIQUE INDEX "verily_verification_request_code_idx" ON "verily_verification_request" USING btree ("codeHash");
CREATE INDEX "verily_verification_request_attempt_idx" ON "verily_verification_request" USING btree ("attemptId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL,
    "contentType" text,
    "cacheControl" text,
    "contentDisposition" text,
    "contentEncoding" text,
    "customMetadata" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_cloud_storage_direct_download" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL,
    "downloadFileName" text,
    "contentType" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_download_auth_key" ON "serverpod_cloud_storage_direct_download" USING btree ("authKey");
CREATE INDEX "serverpod_cloud_storage_direct_download_expiration" ON "serverpod_cloud_storage_direct_download" USING btree ("expiration");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL,
    "maxFileSize" bigint NOT NULL DEFAULT 10485760,
    "contentLength" bigint,
    "preventOverwrite" boolean NOT NULL DEFAULT false,
    "contentType" text,
    "cacheControl" text,
    "contentDisposition" text,
    "contentEncoding" text,
    "customMetadata" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text,
    "scheduling" json
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_future_call_claim" (
    "id" bigserial PRIMARY KEY,
    "futureCallId" bigint,
    "lastHeartbeatTime" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "future_call_unique_idx" ON "serverpod_future_call_claim" USING btree ("futureCallId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId", "order");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_message_log_sessionLogId_idx" ON "serverpod_message_log" USING btree ("sessionLogId", "order");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId", "order");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" USING btree ("time");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_core_jwt_refresh_token" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "extraClaims" text,
    "method" text NOT NULL,
    "fixedSecret" bytea NOT NULL,
    "rotatingSecretHash" text NOT NULL,
    "lastUpdatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "serverpod_auth_core_jwt_refresh_token_last_updated_at" ON "serverpod_auth_core_jwt_refresh_token" USING btree ("lastUpdatedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_core_profile" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userName" text,
    "fullName" text,
    "email" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "imageId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_profile_user_profile_email_auth_user_id" ON "serverpod_auth_core_profile" USING btree ("authUserId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_core_profile_image" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userProfileId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "url" text NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_core_session" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUsedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" timestamp without time zone,
    "expireAfterUnusedFor" bigint,
    "sessionKeyHash" bytea NOT NULL,
    "sessionKeySalt" bytea NOT NULL,
    "method" text NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_core_user" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "scopeNames" json NOT NULL,
    "blocked" boolean NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_anonymous_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_apple_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userIdentifier" text NOT NULL,
    "refreshToken" text NOT NULL,
    "refreshTokenRequestedWithBundleIdentifier" boolean NOT NULL,
    "lastRefreshedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text,
    "isEmailVerified" boolean,
    "isPrivateEmail" boolean,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_apple_account_identifier" ON "serverpod_auth_idp_apple_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_email_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "passwordHash" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_email" ON "serverpod_auth_idp_email_account" USING btree ("email");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_email_account_password_reset_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "emailAccountId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "challengeId" uuid NOT NULL,
    "setPasswordChallengeId" uuid
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_email_account_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "email" text NOT NULL,
    "challengeId" uuid NOT NULL,
    "createAccountChallengeId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_request_email" ON "serverpod_auth_idp_email_account_request" USING btree ("email");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_facebook_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "fullName" text,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_facebook_account_user_identifier" ON "serverpod_auth_idp_facebook_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_firebase_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text,
    "phone" text,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_firebase_account_user_identifier" ON "serverpod_auth_idp_firebase_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_github_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_github_account_user_identifier" ON "serverpod_auth_idp_github_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_google_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_google_account_user_identifier" ON "serverpod_auth_idp_google_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_microsoft_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_microsoft_account_user_identifier" ON "serverpod_auth_idp_microsoft_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_passkey_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "keyId" bytea NOT NULL,
    "keyIdBase64" text NOT NULL,
    "clientDataJSON" bytea NOT NULL,
    "attestationObject" bytea NOT NULL,
    "originalChallenge" bytea NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_passkey_account_key_id_base64" ON "serverpod_auth_idp_passkey_account" USING btree ("keyIdBase64");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_passkey_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "challenge" bytea NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_rate_limited_request_attempt" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "domain" text NOT NULL,
    "source" text NOT NULL,
    "key" text NOT NULL,
    "ipAddress" text,
    "attemptedAt" timestamp without time zone NOT NULL,
    "extraData" json
);

-- Indexes
CREATE INDEX "serverpod_auth_idp_rate_limited_request_attempt_composite" ON "serverpod_auth_idp_rate_limited_request_attempt" USING btree ("domain", "source", "key", "attemptedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_secret_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "challengeCodeHash" text NOT NULL
);

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_abuse_risk_assessment"
    ADD CONSTRAINT "verily_abuse_risk_assessment_fk_0"
    FOREIGN KEY("actionDefinitionId")
    REFERENCES "verily_action_definition"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_account_closure"
    ADD CONSTRAINT "verily_account_closure_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_attempt"
    ADD CONSTRAINT "verily_action_attempt_fk_0"
    FOREIGN KEY("actionDefinitionId")
    REFERENCES "verily_action_definition"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_action_attempt"
    ADD CONSTRAINT "verily_action_attempt_fk_1"
    FOREIGN KEY("participantAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_capture_challenge"
    ADD CONSTRAINT "verily_action_capture_challenge_fk_0"
    FOREIGN KEY("attemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_action_capture_challenge"
    ADD CONSTRAINT "verily_action_capture_challenge_fk_1"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_action_capture_challenge"
    ADD CONSTRAINT "verily_action_capture_challenge_fk_2"
    FOREIGN KEY("participantAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_definition"
    ADD CONSTRAINT "verily_action_definition_fk_0"
    FOREIGN KEY("creatorAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_evidence"
    ADD CONSTRAINT "verily_action_evidence_fk_0"
    FOREIGN KEY("attemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_action_evidence"
    ADD CONSTRAINT "verily_action_evidence_fk_1"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_action_evidence"
    ADD CONSTRAINT "verily_action_evidence_fk_2"
    FOREIGN KEY("spokenChallengeId")
    REFERENCES "verily_action_spoken_challenge"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_external_rule"
    ADD CONSTRAINT "verily_action_external_rule_fk_0"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_action_external_rule"
    ADD CONSTRAINT "verily_action_external_rule_fk_1"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_location_rule"
    ADD CONSTRAINT "verily_action_location_rule_fk_0"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_media_rule"
    ADD CONSTRAINT "verily_action_media_rule_fk_0"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_motion_rule"
    ADD CONSTRAINT "verily_action_motion_rule_fk_0"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_qr_challenge"
    ADD CONSTRAINT "verily_action_qr_challenge_fk_0"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_action_qr_challenge"
    ADD CONSTRAINT "verily_action_qr_challenge_fk_1"
    FOREIGN KEY("createdByAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_action_qr_challenge"
    ADD CONSTRAINT "verily_action_qr_challenge_fk_2"
    FOREIGN KEY("usedByAttemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_qr_rule"
    ADD CONSTRAINT "verily_action_qr_rule_fk_0"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_requirement"
    ADD CONSTRAINT "verily_action_requirement_fk_0"
    FOREIGN KEY("actionDefinitionId")
    REFERENCES "verily_action_definition"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_action_spoken_challenge"
    ADD CONSTRAINT "verily_action_spoken_challenge_fk_0"
    FOREIGN KEY("attemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_action_spoken_challenge"
    ADD CONSTRAINT "verily_action_spoken_challenge_fk_1"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_action_spoken_challenge"
    ADD CONSTRAINT "verily_action_spoken_challenge_fk_2"
    FOREIGN KEY("participantAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_ai_usage_request"
    ADD CONSTRAINT "verily_ai_usage_request_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app"
    ADD CONSTRAINT "verily_app_fk_0"
    FOREIGN KEY("creatorAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_attest_challenge"
    ADD CONSTRAINT "verily_app_attest_challenge_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_attest_key"
    ADD CONSTRAINT "verily_app_attest_key_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_confirmation"
    ADD CONSTRAINT "verily_app_confirmation_fk_0"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_app_confirmation"
    ADD CONSTRAINT "verily_app_confirmation_fk_1"
    FOREIGN KEY("actionDefinitionId")
    REFERENCES "verily_action_definition"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_app_confirmation"
    ADD CONSTRAINT "verily_app_confirmation_fk_2"
    FOREIGN KEY("attemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_event"
    ADD CONSTRAINT "verily_app_event_fk_0"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_key"
    ADD CONSTRAINT "verily_app_key_fk_0"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_link"
    ADD CONSTRAINT "verily_app_link_fk_0"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_app_link"
    ADD CONSTRAINT "verily_app_link_fk_1"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_link_code"
    ADD CONSTRAINT "verily_app_link_code_fk_0"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_app_link_code"
    ADD CONSTRAINT "verily_app_link_code_fk_1"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_pull_check"
    ADD CONSTRAINT "verily_app_pull_check_fk_0"
    FOREIGN KEY("attemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_app_pull_check"
    ADD CONSTRAINT "verily_app_pull_check_fk_1"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_app_pull_check"
    ADD CONSTRAINT "verily_app_pull_check_fk_2"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_rate_window"
    ADD CONSTRAINT "verily_app_rate_window_fk_0"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_redirect_uri"
    ADD CONSTRAINT "verily_app_redirect_uri_fk_0"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_app_webhook_delivery"
    ADD CONSTRAINT "verily_app_webhook_delivery_fk_0"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_evidence_appeal"
    ADD CONSTRAINT "verily_evidence_appeal_fk_0"
    FOREIGN KEY("evidenceId")
    REFERENCES "verily_action_evidence"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_evidence_appeal"
    ADD CONSTRAINT "verily_evidence_appeal_fk_1"
    FOREIGN KEY("attemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_evidence_appeal"
    ADD CONSTRAINT "verily_evidence_appeal_fk_2"
    FOREIGN KEY("creatorAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_evidence_appeal"
    ADD CONSTRAINT "verily_evidence_appeal_fk_3"
    FOREIGN KEY("participantAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_evidence_appeal"
    ADD CONSTRAINT "verily_evidence_appeal_fk_4"
    FOREIGN KEY("resolvedByAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_evidence_decision"
    ADD CONSTRAINT "verily_evidence_decision_fk_0"
    FOREIGN KEY("evidenceId")
    REFERENCES "verily_action_evidence"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_evidence_decision"
    ADD CONSTRAINT "verily_evidence_decision_fk_1"
    FOREIGN KEY("reviewedByAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_evidence_upload_reservation"
    ADD CONSTRAINT "verily_evidence_upload_reservation_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_evidence_upload_reservation"
    ADD CONSTRAINT "verily_evidence_upload_reservation_fk_1"
    FOREIGN KEY("attemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_evidence_upload_reservation"
    ADD CONSTRAINT "verily_evidence_upload_reservation_fk_2"
    FOREIGN KEY("requirementId")
    REFERENCES "verily_action_requirement"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_evidence_upload_reservation"
    ADD CONSTRAINT "verily_evidence_upload_reservation_fk_3"
    FOREIGN KEY("spokenChallengeId")
    REFERENCES "verily_action_spoken_challenge"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_evidence_verification_job"
    ADD CONSTRAINT "verily_evidence_verification_job_fk_0"
    FOREIGN KEY("evidenceId")
    REFERENCES "verily_action_evidence"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_evidence_verification_vote"
    ADD CONSTRAINT "verily_evidence_verification_vote_fk_0"
    FOREIGN KEY("decisionId")
    REFERENCES "verily_evidence_decision"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_evidence_verification_vote"
    ADD CONSTRAINT "verily_evidence_verification_vote_fk_1"
    FOREIGN KEY("evidenceId")
    REFERENCES "verily_action_evidence"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_inference_cost_reservation"
    ADD CONSTRAINT "verily_inference_cost_reservation_fk_0"
    FOREIGN KEY("actionAttemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_moderation_audit_entry"
    ADD CONSTRAINT "verily_moderation_audit_entry_fk_0"
    FOREIGN KEY("caseId")
    REFERENCES "verily_moderation_case"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_moderation_audit_entry"
    ADD CONSTRAINT "verily_moderation_audit_entry_fk_1"
    FOREIGN KEY("actorAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_moderation_case"
    ADD CONSTRAINT "verily_moderation_case_fk_0"
    FOREIGN KEY("creatorAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_moderation_case"
    ADD CONSTRAINT "verily_moderation_case_fk_1"
    FOREIGN KEY("actionDefinitionId")
    REFERENCES "verily_action_definition"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_moderation_case"
    ADD CONSTRAINT "verily_moderation_case_fk_2"
    FOREIGN KEY("reporterAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_moderation_case"
    ADD CONSTRAINT "verily_moderation_case_fk_3"
    FOREIGN KEY("reviewedByAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_payout_wallet"
    ADD CONSTRAINT "verily_payout_wallet_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_payout_wallet_link_challenge"
    ADD CONSTRAINT "verily_payout_wallet_link_challenge_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_reward_payout"
    ADD CONSTRAINT "verily_reward_payout_fk_0"
    FOREIGN KEY("poolId")
    REFERENCES "verily_reward_pool"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_reward_payout"
    ADD CONSTRAINT "verily_reward_payout_fk_1"
    FOREIGN KEY("attemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_reward_payout"
    ADD CONSTRAINT "verily_reward_payout_fk_2"
    FOREIGN KEY("recipientAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_reward_pool"
    ADD CONSTRAINT "verily_reward_pool_fk_0"
    FOREIGN KEY("creatorAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "verily_verification_request"
    ADD CONSTRAINT "verily_verification_request_fk_0"
    FOREIGN KEY("appId")
    REFERENCES "verily_app"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_verification_request"
    ADD CONSTRAINT "verily_verification_request_fk_1"
    FOREIGN KEY("participantAuthUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_verification_request"
    ADD CONSTRAINT "verily_verification_request_fk_2"
    FOREIGN KEY("actionDefinitionId")
    REFERENCES "verily_action_definition"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "verily_verification_request"
    ADD CONSTRAINT "verily_verification_request_fk_3"
    FOREIGN KEY("attemptId")
    REFERENCES "verily_action_attempt"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_future_call_claim"
    ADD CONSTRAINT "serverpod_future_call_claim_fk_0"
    FOREIGN KEY("futureCallId")
    REFERENCES "serverpod_future_call"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_core_jwt_refresh_token"
    ADD CONSTRAINT "serverpod_auth_core_jwt_refresh_token_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_1"
    FOREIGN KEY("imageId")
    REFERENCES "serverpod_auth_core_profile_image"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_core_profile_image"
    ADD CONSTRAINT "serverpod_auth_core_profile_image_fk_0"
    FOREIGN KEY("userProfileId")
    REFERENCES "serverpod_auth_core_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_core_session"
    ADD CONSTRAINT "serverpod_auth_core_session_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_anonymous_account"
    ADD CONSTRAINT "serverpod_auth_idp_anonymous_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_apple_account"
    ADD CONSTRAINT "serverpod_auth_idp_apple_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_0"
    FOREIGN KEY("emailAccountId")
    REFERENCES "serverpod_auth_idp_email_account"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_1"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_2"
    FOREIGN KEY("setPasswordChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_0"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_1"
    FOREIGN KEY("createAccountChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_facebook_account"
    ADD CONSTRAINT "serverpod_auth_idp_facebook_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_firebase_account"
    ADD CONSTRAINT "serverpod_auth_idp_firebase_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_github_account"
    ADD CONSTRAINT "serverpod_auth_idp_github_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_google_account"
    ADD CONSTRAINT "serverpod_auth_idp_google_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_microsoft_account"
    ADD CONSTRAINT "serverpod_auth_idp_microsoft_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_passkey_account"
    ADD CONSTRAINT "serverpod_auth_idp_passkey_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR verily
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('verily', '20261023072045960-verily-baseline', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261023072045960-verily-baseline', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();


-- BEGIN VERILY SCHEMA CONTRACTS
-- Database backstops for invariants the Serverpod model format cannot express.
-- Applied inside the fresh baseline transaction by compose_schema_baseline.dart.
--
-- Only CHECK constraints, functions, and triggers live here. Indexes and
-- foreign keys are model-owned: Serverpod compares them with the live schema
-- and would refuse to start in development mode over an extra one.

ALTER TABLE verily_ai_usage_request ADD CONSTRAINT verily_ai_cost_check
  CHECK ("costUnits" > 0);

ALTER TABLE verily_action_definition ADD CONSTRAINT verily_action_capacity_check
  CHECK (revision > 0 AND "verifiedCompletions" >= 0
    AND "actionKey" ~ '^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$'
    AND length(btrim(title)) BETWEEN 1 AND 120
    AND length(btrim("timeZone")) BETWEEN 1 AND 64
    AND ("maxVerifiedCompletions" IS NULL OR
      ("maxVerifiedCompletions" > 0 AND "verifiedCompletions" <= "maxVerifiedCompletions"))
    AND ("opensAt" IS NULL OR "closesAt" IS NULL OR "closesAt" > "opensAt"));

ALTER TABLE verily_action_requirement ADD CONSTRAINT verily_requirement_position_check
  CHECK (position BETWEEN 0 AND 4 AND length(btrim("requirementKey")) > 0);

-- A reward outcome exists only on a verified completion.
ALTER TABLE verily_action_attempt ADD CONSTRAINT verily_attempt_verification_check
  CHECK (("verificationScore" IS NULL OR "verificationScore" BETWEEN 0 AND 1)
    AND ("verifiedRank" IS NULL OR "verifiedRank" > 0)
    AND (status <> 'verified' OR "verifiedAt" IS NOT NULL)
    AND ("rewardOutcome" IS NULL OR status = 'verified'));

-- PostGIS wraps out-of-range geography input into [-180 -90, 180 90], so the
-- server validates ranges before building a GeographyPoint. These checks are
-- the backstop for what PostGIS does accept unchanged: NaN coordinates.
ALTER TABLE verily_action_location_rule ADD CONSTRAINT verily_location_bounds_check
  CHECK (ST_Y(location::geometry) BETWEEN -90 AND 90
    AND ST_X(location::geometry) BETWEEN -180 AND 180
    AND "radiusMeters" BETWEEN 10 AND 5000
    AND "maxAccuracyMeters" > 0 AND "maxAccuracyMeters" <= 1000);

-- Recordings carry duration bounds and may carry the spoken challenge; a photo
-- carries neither. Tracked movements are video only.
ALTER TABLE verily_action_media_rule ADD CONSTRAINT verily_media_rule_check
  CHECK (kind IN ('video', 'photo', 'audio')
    AND "minConfidence" BETWEEN 0 AND 1
    AND length(btrim("verificationPrompt")) BETWEEN 10 AND 2000
    AND ((kind = 'photo' AND "minDurationSeconds" IS NULL
        AND "maxDurationSeconds" IS NULL AND NOT "spokenChallengeRequired")
      OR (kind <> 'photo' AND "minDurationSeconds" BETWEEN 3 AND 300
        AND "maxDurationSeconds" BETWEEN "minDurationSeconds" AND 300))
    AND (("movementKind" IS NULL AND "targetRepetitions" IS NULL)
      OR (kind = 'video' AND "movementKind" IS NOT NULL
        AND "targetRepetitions" BETWEEN 1 AND 1000)));

ALTER TABLE verily_action_motion_rule ADD CONSTRAINT verily_motion_bounds_check
  CHECK ("targetRepetitions" BETWEEN 1 AND 20
    AND "minDurationSeconds" BETWEEN 1 AND 30
    AND "maxDurationSeconds" BETWEEN "minDurationSeconds" AND 30
    AND "minAngularSpeedRadiansPerSecond" > 0
    AND "maxAngularSpeedRadiansPerSecond" >= "minAngularSpeedRadiansPerSecond"
    AND "maxAngularSpeedRadiansPerSecond" <= 25
    AND "minAxisDominance" BETWEEN 0.5 AND 1
    AND "minFreeFallMilliseconds" BETWEEN 100 AND 1000
    AND "maxFreeFallMilliseconds" BETWEEN "minFreeFallMilliseconds" AND 700
    AND "minPeakAccelerationMetersPerSecondSquared" > 0
    AND "maxPeakAccelerationMetersPerSecondSquared" >= "minPeakAccelerationMetersPerSecondSquared"
    AND "maxPeakAccelerationMetersPerSecondSquared" <= 60
    AND "minAngularSpeedRadiansPerSecond" NOT IN ('NaN'::float8, 'Infinity'::float8, '-Infinity'::float8)
    AND "maxAngularSpeedRadiansPerSecond" NOT IN ('NaN'::float8, 'Infinity'::float8, '-Infinity'::float8)
    AND "minAxisDominance" NOT IN ('NaN'::float8, 'Infinity'::float8, '-Infinity'::float8)
    AND "minPeakAccelerationMetersPerSecondSquared" NOT IN ('NaN'::float8, 'Infinity'::float8, '-Infinity'::float8)
    AND "maxPeakAccelerationMetersPerSecondSquared" NOT IN ('NaN'::float8, 'Infinity'::float8, '-Infinity'::float8)
    AND ("motionType" <> 'rotation' OR axis <> 'any')
    AND ("motionType" NOT IN ('phoneToss', 'stillness') OR
      (axis = 'any' AND "targetRepetitions" = 1))
    AND ("motionType" <> 'phoneToss' OR
      "minPeakAccelerationMetersPerSecondSquared" >= 8)
    AND ("motionType" <> 'stillness' OR
      "maxAngularSpeedRadiansPerSecond" <= 2));

ALTER TABLE verily_action_evidence ADD CONSTRAINT verily_evidence_bounds_check
  CHECK ((location IS NULL OR (ST_Y(location::geometry) BETWEEN -90 AND 90
      AND ST_X(location::geometry) BETWEEN -180 AND 180))
    AND ("accuracyMeters" IS NULL OR
      ("accuracyMeters" >= 0 AND "accuracyMeters" < 'Infinity'::float8))
    AND ("byteLength" IS NULL OR "byteLength" > 0)
    AND ("durationSeconds" IS NULL OR "durationSeconds" > 0)
    AND ("motionSampleCount" IS NULL OR "motionSampleCount" BETWEEN 10 AND 1000)
    AND ("motionDurationMilliseconds" IS NULL OR
      "motionDurationMilliseconds" BETWEEN 1 AND 30000)
    AND ((kind = 'motion'
      AND "motionTraceJson" IS NOT NULL
      AND octet_length("motionTraceJson") BETWEEN 1 AND 200000
      AND "motionTraceSha256" ~ '^[0-9a-f]{64}$'
      AND "sha256Digest" = "motionTraceSha256"
      AND "motionSampleCount" IS NOT NULL
      AND "motionDurationMilliseconds" IS NOT NULL
      AND "motionAnalysisJson" IS NOT NULL
      AND octet_length("motionAnalysisJson") BETWEEN 1 AND 4096)
    OR (kind <> 'motion'
      AND "motionTraceJson" IS NULL
      AND "motionTraceSha256" IS NULL
      AND "motionSampleCount" IS NULL
      AND "motionDurationMilliseconds" IS NULL
      AND "motionAnalysisJson" IS NULL)));

-- Media proof is always a pinned, hashed private object; a photo has no
-- duration and a recording always has one. Only recordings carry a spoken
-- challenge word, and only a word from the server-owned list's alphabet.
ALTER TABLE verily_action_evidence ADD CONSTRAINT verily_media_evidence_check
  CHECK ((kind NOT IN ('video', 'photo', 'audio')
      AND "storagePath" IS NULL AND "storageVersionId" IS NULL
      AND "spokenChallengeWord" IS NULL)
    OR (kind IN ('video', 'photo', 'audio')
      AND "storagePath" LIKE 'action-evidence/%'
      AND "storageVersionId" IS NOT NULL
      AND "mimeType" IS NOT NULL
      AND "sha256Digest" ~ '^[0-9a-f]{64}$'
      AND "byteLength" BETWEEN 1 AND 157286400
      AND location IS NULL
      AND ((kind = 'photo') = ("durationSeconds" IS NULL))
      AND (kind <> 'photo' OR "spokenChallengeWord" IS NULL)
      AND ("spokenChallengeWord" IS NULL OR "spokenChallengeWord" ~ '^[a-z]{2,24}$')));

-- App confirmations carry only the delivery digest: no media, place, or device
-- material can be attached to a server-to-server attestation.
ALTER TABLE verily_action_evidence ADD CONSTRAINT verily_external_evidence_check
  CHECK (kind <> 'externalApp' OR ("sha256Digest" ~ '^[0-9a-f]{64}$'
    AND location IS NULL AND "accuracyMeters" IS NULL
    AND "deviceRepetitionCount" IS NULL AND "deviceTrackerVersion" IS NULL
    AND "captureSignature" IS NULL AND "captureKeyId" IS NULL));

-- A capture window is opened before recording with a 32-byte nonce and lives
-- at most an hour; the hashes it was bound to are filled when proof arrives.
ALTER TABLE verily_action_capture_challenge ADD CONSTRAINT verily_capture_expiry_check
  CHECK ("expiresAt" > "createdAt"
    AND "expiresAt" <= "createdAt" + interval '1 hour'
    AND nonce ~ '^[A-Za-z0-9_-]{43}$'
    AND ("requestHash" IS NULL OR "requestHash" ~ '^[A-Za-z0-9_-]{43}$')
    AND ("evidenceBindingHash" IS NULL
      OR "evidenceBindingHash" ~ '^[0-9a-f]{64}$'));
-- An App Attest key is registered against a single-use, short-lived
-- challenge; the key's id is the SHA-256 of its P-256 point, and its
-- assertion counter only ever grows from zero.
ALTER TABLE verily_app_attest_challenge ADD CONSTRAINT verily_app_attest_challenge_check
  CHECK ("expiresAt" > "createdAt"
    AND "expiresAt" <= "createdAt" + interval '1 hour'
    AND nonce ~ '^[A-Za-z0-9_-]{43}$'
    AND ("usedAt" IS NULL OR "usedAt" >= "createdAt"));
ALTER TABLE verily_app_attest_key ADD CONSTRAINT verily_app_attest_key_check
  CHECK ("keyId" ~ '^[0-9a-f]{64}$'
    AND length("publicKey") = 88
    AND "signCount" >= 0
    AND length(receipt) > 0
    AND ("validationCategory" IS NULL OR "validationCategory" >= 0)
    AND ("lastAssertedAt" IS NULL OR "lastAssertedAt" >= "registeredAt"));
ALTER TABLE verily_action_qr_challenge ADD CONSTRAINT verily_qr_expiry_check
  CHECK ("expiresAt" > "createdAt");
ALTER TABLE verily_action_spoken_challenge ADD CONSTRAINT verily_spoken_challenge_check
  CHECK ("expiresAt" > "issuedAt"
    AND "expiresAt" <= "issuedAt" + interval '1 hour'
    AND word ~ '^[a-z]{2,24}$'
    AND ("boundAt" IS NULL OR "boundAt" >= "issuedAt"));

ALTER TABLE verily_evidence_upload_reservation ADD CONSTRAINT verily_upload_bounds_check
  CHECK (kind IN ('video', 'photo', 'audio')
    AND "byteLength" BETWEEN 1 AND 157286400
    AND "requestCount" > 0 AND "confirmationAttemptCount" >= 0
    AND "uploadExpiresAt" > "reservedAt" AND "retainUntil" >= "uploadExpiresAt"
    AND "storagePath" LIKE 'action-evidence/%');

ALTER TABLE verily_evidence_decision ADD CONSTRAINT verily_decision_confidence_check
  CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1);
ALTER TABLE verily_evidence_verification_vote ADD CONSTRAINT verily_vote_usage_check
  CHECK ((confidence IS NULL OR confidence BETWEEN 0 AND 1)
    AND "latencyMilliseconds" >= 0
    AND ("inputTokens" IS NULL OR "inputTokens" >= 0)
    AND ("outputTokens" IS NULL OR "outputTokens" >= 0)
    AND ("costCredits" IS NULL OR
      ("costCredits" >= 0 AND "costCredits" < 'Infinity'::float8))
    AND ("spokenChallengeVerdict" IS NULL OR
      "spokenChallengeVerdict" IN ('heard', 'notHeard', 'unclear', 'abstained')));
ALTER TABLE verily_evidence_verification_job ADD CONSTRAINT verily_verification_retry_check
  CHECK ("attemptCount" >= 0);

ALTER TABLE verily_inference_cost_reservation ADD CONSTRAINT verily_inference_reservation_check
  CHECK ("reservedMicros" BETWEEN 1 AND 50000
    AND length(btrim("callReference")) BETWEEN 1 AND 240
    AND length(btrim("modelId")) > 0
    AND length(btrim("policyVersion")) > 0);

ALTER TABLE verily_abuse_risk_assessment ADD CONSTRAINT verily_abuse_assessment_check
  CHECK ("assessmentKey" ~ '^[0-9a-f]{64}$'
    AND phase IN ('evidenceSubmission', 'valueAuthorization')
    -- Accepted policy versions. A new version is added here deliberately, in
    -- the same reviewed change that bumps AbuseRiskDecision.policyVersion, so
    -- a rollout cannot persist rows the constraint would reject.
    AND "policyVersion" IN ('verily-abuse-v1')
    AND disposition IN ('allow', 'manualReview', 'reject')
    AND tier IN ('low', 'elevated', 'high', 'critical')
    AND score BETWEEN 0 AND 100
    AND json_typeof("signalCodes") = 'array'
    AND "correlationWindowStartsAt" <= "createdAt");

ALTER TABLE verily_moderation_case ADD CONSTRAINT verily_moderation_case_check
  CHECK (category IN ('spam', 'harassment', 'hate', 'sexualExploitation', 'childSafety',
      'violence', 'selfHarm', 'dangerousActivity', 'privacy', 'fraud', 'other')
    AND status IN ('pendingReview', 'appealPending', 'paused', 'dismissed', 'lifted')
    AND length(btrim("idempotencyKey")) > 0
    AND length(btrim(details)) BETWEEN 10 AND 1000
    AND ("appealResolvedAt" IS NULL OR "appealedAt" IS NOT NULL));
ALTER TABLE verily_moderation_audit_entry ADD CONSTRAINT verily_moderation_audit_check
  CHECK (length(btrim(event)) > 0 AND length(note) <= 1000);

ALTER TABLE verily_app ADD CONSTRAINT verily_app_check
  CHECK (length(btrim(name)) BETWEEN 1 AND 80
    AND status IN ('active', 'revoked')
    AND ((status = 'revoked') = ("revokedAt" IS NOT NULL))
    AND "rateWindowCount" >= 0
    AND ("websiteUrl" IS NULL OR "websiteUrl" LIKE 'https://%'));
ALTER TABLE verily_app_key ADD CONSTRAINT verily_app_key_check
  CHECK ("keyId" ~ '^[0-9a-f]{16}$' AND "secretHash" ~ '^[0-9a-f]{64}$');
ALTER TABLE verily_app_link ADD CONSTRAINT verily_app_link_check
  CHECK (subject ~ '^vls_[A-Za-z0-9_-]{22}$');
ALTER TABLE verily_app_confirmation ADD CONSTRAINT verily_app_confirmation_check
  CHECK ("eventId" ~ '^[A-Za-z0-9._:-]{1,128}$'
    AND "payloadDigest" ~ '^[0-9a-f]{64}$'
    AND outcome IN ('accepted', 'rejected')
    AND ((outcome = 'accepted') = ("attemptId" IS NOT NULL))
    AND length(btrim("reasonCode")) > 0);

ALTER TABLE verily_payout_wallet ADD CONSTRAINT verily_payout_wallet_check
  CHECK ("walletAddress" ~ '^[1-9A-HJ-NP-Za-km-z]{32,44}$'
    AND "updatedAt" >= "linkedAt");
ALTER TABLE verily_payout_wallet_link_challenge ADD CONSTRAINT verily_wallet_link_expiry_check
  CHECK ("expiresAt" > "createdAt"
    AND "walletAddress" ~ '^[1-9A-HJ-NP-Za-km-z]{32,44}$'
    AND length(nonce) BETWEEN 16 AND 64);

-- Counters never overtake their bounds, terms match the escrow program's
-- limits, the refund window always follows expiry by the stored delay, and
-- every state past draft carries the escrow identity funding derived.
ALTER TABLE verily_reward_pool ADD CONSTRAINT verily_reward_pool_check
  CHECK ("actionKey" ~ '^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$'
    AND cluster IN ('devnet', 'mainnet')
    AND "mint" ~ '^[1-9A-HJ-NP-Za-km-z]{32,44}$'
    AND length(btrim("tokenSymbol")) BETWEEN 1 AND 16
    AND decimals BETWEEN 0 AND 18
    AND "amountPerPayout" BETWEEN 1 AND 1000000000000
    AND "maxPayouts" BETWEEN 1 AND 2048
    AND "maxWinsPerAccount" BETWEEN 1 AND 365
    AND "payoutsReserved" BETWEEN 0 AND "maxPayouts"
    AND "payoutsReleased" BETWEEN 0 AND "payoutsReserved"
    AND "refundDelaySeconds" BETWEEN 259200 AND 2592000
    AND "refundAfter" = "expiresAt" + make_interval(secs => "refundDelaySeconds")
    AND status IN ('draft', 'awaitingFunding', 'funded', 'ended', 'closed')
    AND (status = 'draft' OR ("creatorWallet" IS NOT NULL
      AND "escrowAddress" IS NOT NULL AND "arbiterAddress" IS NOT NULL))
    AND (status IN ('draft', 'awaitingFunding')
      OR ("fundingSignature" IS NOT NULL AND "fundedAt" IS NOT NULL))
    AND (status <> 'closed' OR "closedAt" IS NOT NULL)
    AND (status IN ('funded', 'ended', 'closed') OR "payoutsReserved" = 0));

ALTER TABLE verily_reward_payout ADD CONSTRAINT verily_reward_payout_check
  CHECK ("payoutIndex" >= 0 AND amount > 0 AND "attemptCount" >= 0
    AND status IN ('reserved', 'awaitingWallet', 'heldForReview', 'releasing',
      'released', 'failed', 'expired')
    AND (status <> 'releasing' OR
      ("recipientWallet" IS NOT NULL AND "releaseStartedAt" IS NOT NULL))
    AND (status <> 'released' OR
      ("recipientWallet" IS NOT NULL AND "releasedAt" IS NOT NULL))
    AND ("recipientWallet" IS NULL OR
      "recipientWallet" ~ '^[1-9A-HJ-NP-Za-km-z]{32,44}$')
    AND ("lastErrorCode" IS NULL OR "lastErrorCode" ~ '^[a-z0-9_]{1,64}$'));

-- Platform: webhooks, deep links, pull checks, and verification requests.
-- Webhook secrets are derived from the server master key, so only a version
-- is stored. Every outbound URL and redirect is exact and fragment-free.
ALTER TABLE verily_app ADD CONSTRAINT verily_app_webhook_check
  CHECK (("webhookUrl" IS NULL OR ("webhookUrl" LIKE 'https://%'
        AND length("webhookUrl") <= 2048 AND position('#' IN "webhookUrl") = 0))
    AND "webhookSecretVersion" >= 0
    AND (("webhookSecretVersion" = 0) = ("webhookSecretRotatedAt" IS NULL))
    AND ("previousWebhookSecretVersion" IS NULL
      OR "previousWebhookSecretVersion" BETWEEN 1 AND "webhookSecretVersion" - 1));
ALTER TABLE verily_app_redirect_uri ADD CONSTRAINT verily_app_redirect_uri_check
  CHECK (length(uri) BETWEEN 4 AND 512
    AND uri ~ '^[a-z][a-z0-9+.-]*:[^[:space:]#*]+$'
    AND uri NOT LIKE 'http:%');
ALTER TABLE verily_app_rate_window ADD CONSTRAINT verily_app_rate_window_check
  CHECK ("requestCount" >= 0 AND length(bucket) BETWEEN 1 AND 160);
ALTER TABLE verily_app_event ADD CONSTRAINT verily_app_event_check
  CHECK ("eventId" ~ '^vev_[A-Za-z0-9_-]{22}$'
    AND type IN ('attempt.verified', 'attempt.rejected', 'payout.released',
      'verification_request.completed')
    AND status IN ('pending', 'delivering', 'delivered', 'failed')
    AND length("dedupeKey") BETWEEN 1 AND 200
    AND length(body) BETWEEN 2 AND 65536
    AND "attemptCount" >= 0
    AND ((status = 'delivered') = ("deliveredAt" IS NOT NULL))
    AND ("lastStatusCode" IS NULL OR "lastStatusCode" BETWEEN 100 AND 599));
ALTER TABLE verily_app_webhook_delivery ADD CONSTRAINT verily_app_webhook_delivery_check
  CHECK ("eventId" ~ '^vev_[A-Za-z0-9_-]{22}$'
    AND "eventType" IN ('attempt.verify', 'attempt.verified',
      'attempt.rejected', 'payout.released', 'verification_request.completed')
    AND "attemptNumber" >= 1
    AND "durationMilliseconds" >= 0
    AND ("statusCode" IS NULL OR "statusCode" BETWEEN 100 AND 599)
    AND (NOT succeeded OR ("statusCode" BETWEEN 200 AND 299 AND "errorCode" IS NULL))
    AND (succeeded OR "errorCode" IS NOT NULL));
ALTER TABLE verily_app_pull_check ADD CONSTRAINT verily_app_pull_check_check
  CHECK ("eventId" ~ '^vev_[A-Za-z0-9_-]{22}$'
    AND status IN ('calling', 'waiting', 'retrying', 'accepted', 'rejected',
      'failed', 'expired')
    AND (reference IS NULL OR length(reference) BETWEEN 1 AND 120)
    AND ("reasonCode" IS NULL OR "reasonCode" ~ '^[a-z0-9_]{1,64}$')
    AND "callCount" >= 0
    AND "expiresAt" > "createdAt"
    AND "expiresAt" <= "createdAt" + interval '24 hours');
ALTER TABLE verily_app_link_code ADD CONSTRAINT verily_app_link_code_check
  CHECK ("codeHash" ~ '^[0-9a-f]{64}$'
    AND "expiresAt" > "createdAt"
    AND "expiresAt" <= "createdAt" + interval '5 minutes'
    AND length("redirectUri") BETWEEN 4 AND 512
    AND (state IS NULL OR length(state) BETWEEN 1 AND 256)
    AND ("usedAt" IS NULL OR "usedAt" >= "createdAt"));
ALTER TABLE verily_verification_request ADD CONSTRAINT verily_verification_request_check
  CHECK (kind IN ('video', 'photo', 'audio', 'location')
    AND "check" IN ('captureOnly', 'content')
    AND status IN ('open', 'accepted', 'declined', 'completed', 'expired')
    AND (instructions IS NULL OR length(btrim(instructions)) BETWEEN 1 AND 280)
    AND (("placeLatitude" IS NULL AND "placeLongitude" IS NULL
        AND "placeRadiusMeters" IS NULL)
      OR ("placeLatitude" BETWEEN -90 AND 90
        AND "placeLongitude" BETWEEN -180 AND 180
        AND "placeRadiusMeters" BETWEEN 10 AND 5000))
    AND (kind <> 'location' OR "placeLatitude" IS NOT NULL)
    AND (NOT "spokenChallenge" OR kind IN ('video', 'audio'))
    AND (NOT "evidenceShared" OR "shareEvidence")
    AND length("redirectUri") BETWEEN 4 AND 512
    AND (state IS NULL OR length(state) BETWEEN 1 AND 256)
    AND "expiresAt" >= "createdAt" + interval '60 seconds'
    AND "expiresAt" <= "createdAt" + interval '3600 seconds'
    AND (subject IS NULL OR subject ~ '^vls_[A-Za-z0-9_-]{22}$')
    AND ("codeHash" IS NULL OR "codeHash" ~ '^[0-9a-f]{64}$')
    AND (status <> 'open' OR ("attemptId" IS NULL AND "acceptedAt" IS NULL))
    AND (status NOT IN ('accepted', 'completed')
      OR ("attemptId" IS NOT NULL AND "acceptedAt" IS NOT NULL)));
-- A verification request's private action is single-use and never recurs.
ALTER TABLE verily_action_definition ADD CONSTRAINT verily_action_visibility_check
  CHECK (visibility IN ('public', 'verificationRequest')
    AND (visibility = 'public'
      OR ("maxVerifiedCompletions" = 1 AND recurrence = 'once')));
-- A local check is fully specified or absent, and fits its media kind.
ALTER TABLE verily_action_media_rule ADD CONSTRAINT verily_media_local_check
  CHECK (("localCheckTask" IS NULL AND "localCheckLabel" IS NULL
      AND "localCheckMinScore" IS NULL AND "localCheckMinFrames" IS NULL)
    OR ("localCheckTask" IN ('gesture', 'object', 'sound')
      AND length("localCheckLabel") BETWEEN 1 AND 64
      AND "localCheckMinScore" BETWEEN 0.3 AND 0.99
      AND "localCheckMinFrames" BETWEEN 1 AND 30
      AND (kind <> 'photo' OR "localCheckMinFrames" = 1)
      AND (("localCheckTask" = 'sound') = (kind = 'audio'))));
-- The phone's local-check result is advisory and fully attributed to a model.
ALTER TABLE verily_action_evidence ADD CONSTRAINT verily_evidence_local_check
  CHECK (("deviceLocalCheckModelId" IS NULL
      AND "deviceLocalCheckModelSha256" IS NULL
      AND "deviceLocalCheckLabel" IS NULL AND "deviceLocalCheckScore" IS NULL
      AND "deviceLocalCheckMatchedFrames" IS NULL)
    OR (length("deviceLocalCheckModelId") BETWEEN 1 AND 128
      AND "deviceLocalCheckModelSha256" ~ '^[0-9a-f]{64}$'
      AND length("deviceLocalCheckLabel") BETWEEN 1 AND 64
      AND "deviceLocalCheckScore" BETWEEN 0 AND 1
      AND "deviceLocalCheckMatchedFrames" BETWEEN 0 AND 10000));

-- Audit facts are protected independently of application code.
CREATE FUNCTION verily_reject_update_or_delete() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION '% is append-only', TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;

-- v1 limit: App confirmations are never mixed with phone proof in one action,
-- because the two can land in different attempt periods.
CREATE FUNCTION verily_external_requirement_exclusive_guard() RETURNS trigger AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM verily_action_requirement q
    WHERE q."actionDefinitionId" = NEW."actionDefinitionId"
      AND q.id IS DISTINCT FROM NEW.id
      AND ((q.kind = 'externalApp') <> (NEW.kind = 'externalApp'))
  ) THEN
    RAISE EXCEPTION 'app confirmations cannot be combined with phone proof';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- An App may only confirm external requirements of its own creator's actions.
CREATE FUNCTION verily_external_rule_creator_guard() RETURNS trigger AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM verily_action_requirement q
    JOIN verily_action_definition d ON d.id = q."actionDefinitionId"
    JOIN verily_app p ON p."creatorAuthUserId" = d."creatorAuthUserId"
    WHERE q.id = NEW."requirementId" AND q.kind = 'externalApp'
      AND p.id = NEW."appId"
  ) THEN
    RAISE EXCEPTION 'external rule must bind an external requirement of the app creator';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- A media rule describes exactly its requirement's kind.
CREATE FUNCTION verily_media_rule_kind_guard() RETURNS trigger AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM verily_action_requirement q
    WHERE q.id = NEW."requirementId" AND q.kind = NEW.kind
  ) THEN
    RAISE EXCEPTION 'media rule kind must match its requirement';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- A payout pays its pool's fixed amount at an index the escrow can release.
CREATE FUNCTION verily_reward_payout_pool_guard() RETURNS trigger AS $$
DECLARE
  pool verily_reward_pool%ROWTYPE;
BEGIN
  SELECT * INTO pool FROM verily_reward_pool WHERE id = NEW."poolId";
  IF NOT FOUND OR NEW."payoutIndex" >= pool."maxPayouts"
    OR NEW.amount <> pool."amountPerPayout"
    OR pool.status NOT IN ('funded', 'ended', 'closed') THEN
    RAISE EXCEPTION 'payout does not fit its reward pool';
  END IF;
  IF TG_OP = 'UPDATE' AND (NEW."poolId", NEW."attemptId", NEW."recipientAuthUserId",
      NEW."payoutIndex", NEW.amount) IS DISTINCT FROM
     (OLD."poolId", OLD."attemptId", OLD."recipientAuthUserId",
      OLD."payoutIndex", OLD.amount) THEN
    RAISE EXCEPTION 'payout identity is immutable';
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.status = 'released' AND NEW.status <> 'released' THEN
    RAISE EXCEPTION 'a released payout stays released';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Reward terms are frozen once funding starts.
CREATE FUNCTION verily_reward_pool_terms_guard() RETURNS trigger AS $$
BEGIN
  IF OLD.status <> 'draft' AND (NEW."creatorAuthUserId", NEW."actionKey",
      NEW.cluster, NEW.mint, NEW.decimals, NEW."amountPerPayout",
      NEW."maxPayouts", NEW."maxWinsPerAccount", NEW."refundDelaySeconds",
      NEW."creatorWallet", NEW."escrowAddress", NEW."arbiterAddress")
    IS DISTINCT FROM
     (OLD."creatorAuthUserId", OLD."actionKey", OLD.cluster, OLD.mint,
      OLD.decimals, OLD."amountPerPayout", OLD."maxPayouts",
      OLD."maxWinsPerAccount", OLD."refundDelaySeconds", OLD."creatorWallet",
      OLD."escrowAddress", OLD."arbiterAddress") THEN
    RAISE EXCEPTION 'reward terms are immutable once funding starts';
  END IF;
  IF OLD.status <> 'draft' AND NEW."expiresAt" > OLD."expiresAt" THEN
    RAISE EXCEPTION 'a reward can end early but never be extended';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verily_abuse_assessment_update_guard
  BEFORE UPDATE OR DELETE ON verily_abuse_risk_assessment
  FOR EACH ROW EXECUTE FUNCTION verily_reject_update_or_delete();
CREATE TRIGGER verily_moderation_audit_update_guard
  BEFORE UPDATE OR DELETE ON verily_moderation_audit_entry
  FOR EACH ROW EXECUTE FUNCTION verily_reject_update_or_delete();
CREATE TRIGGER verily_app_confirmation_update_guard
  BEFORE UPDATE OR DELETE ON verily_app_confirmation
  FOR EACH ROW EXECUTE FUNCTION verily_reject_update_or_delete();
CREATE TRIGGER verily_app_webhook_delivery_update_guard
  BEFORE UPDATE OR DELETE ON verily_app_webhook_delivery
  FOR EACH ROW EXECUTE FUNCTION verily_reject_update_or_delete();
CREATE TRIGGER verily_external_requirement_exclusive_guard
  BEFORE INSERT OR UPDATE ON verily_action_requirement
  FOR EACH ROW EXECUTE FUNCTION verily_external_requirement_exclusive_guard();
CREATE TRIGGER verily_external_rule_creator_guard
  BEFORE INSERT OR UPDATE ON verily_action_external_rule
  FOR EACH ROW EXECUTE FUNCTION verily_external_rule_creator_guard();
CREATE TRIGGER verily_media_rule_kind_guard
  BEFORE INSERT OR UPDATE ON verily_action_media_rule
  FOR EACH ROW EXECUTE FUNCTION verily_media_rule_kind_guard();
CREATE TRIGGER verily_reward_payout_pool_guard
  BEFORE INSERT OR UPDATE ON verily_reward_payout
  FOR EACH ROW EXECUTE FUNCTION verily_reward_payout_pool_guard();
CREATE TRIGGER verily_reward_pool_terms_guard
  BEFORE UPDATE ON verily_reward_pool
  FOR EACH ROW EXECUTE FUNCTION verily_reward_pool_terms_guard();
-- END VERILY SCHEMA CONTRACTS

COMMIT;
