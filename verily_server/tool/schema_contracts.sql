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

ALTER TABLE verily_action_capture_challenge ADD CONSTRAINT verily_capture_expiry_check
  CHECK ("expiresAt" > "createdAt" AND "evidenceBindingHash" ~ '^[0-9a-f]{64}$');
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
