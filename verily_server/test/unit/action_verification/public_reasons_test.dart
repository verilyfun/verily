import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/action_verification/public_reasons.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Every internal decision or attempt code the server writes today.
const List<String> _internalCodes = [
  'abuse_proof_rejected',
  'abuse_review_required',
  'action_capacity_reached',
  'app_confirmed',
  'app_integrity_not_recognised',
  'app_not_confirmed',
  'app_verification_calling',
  'app_verification_expired',
  'app_verification_failed',
  'app_verification_retrying',
  'app_verification_waiting',
  'appeal_accepted',
  'capture_attestation_app_mismatch',
  'capture_attestation_boot_untrusted',
  'capture_attestation_chain_invalid',
  'capture_attestation_challenge_mismatch',
  'capture_attestation_expired',
  'capture_attestation_extension_invalid',
  'capture_attestation_key_invalid',
  'capture_attestation_patch_outdated',
  'capture_attestation_revoked',
  'capture_attestation_security_level',
  'capture_attestation_status_unavailable',
  'capture_attestation_unconfigured',
  'capture_attestation_untrusted_root',
  'capture_attestation_valid',
  'capture_challenge_invalid',
  'capture_manifest_mismatch',
  'capture_predates_challenge',
  'capture_signature_incomplete',
  'capture_signature_invalid',
  'capture_signature_required',
  'device_activity_risk',
  'device_capture_risk',
  'device_integrity_invalid',
  'device_integrity_not_met',
  'device_integrity_not_strong',
  'device_integrity_required',
  'device_integrity_strong',
  'high_value_payout_review',
  'inside_geofence',
  'local_check_matched',
  'local_check_not_matched',
  'location_accuracy_too_low',
  'location_capture_stale',
  'location_capture_time_invalid',
  'location_travel_needs_review',
  'media_capture_time_invalid',
  'media_duration_out_of_range',
  'media_verification_queued',
  'missing_required_evidence',
  'motion_not_steady',
  'motion_rotation_count_not_met',
  'motion_verified',
  'mp_replay_unavailable',
  'outside_geofence',
  'qr_code_matched',
  'qr_code_mismatch',
  'spoken_challenge_missing',
  'spoken_challenge_predates_capture',
  'spoken_challenge_unverified',
  MediaVerificationReason.verified,
  MediaVerificationReason.notMet,
  MediaVerificationReason.belowThreshold,
  MediaVerificationReason.uncertain,
  MediaVerificationReason.unavailable,
  MediaVerificationReason.securityReview,
  MediaVerificationReason.councilVerified,
  MediaVerificationReason.councilNotMet,
  MediaVerificationReason.councilNoConsensus,
  MediaVerificationReason.councilQuorumUnavailable,
  MediaVerificationReason.spokenNotHeard,
  MediaVerificationReason.spokenUnverified,
  MediaVerificationReason.budgetUnavailable,
  MediaVerificationReason.retryExhausted,
];

ActionAttempt _attempt(ActionAttemptStatus status, String? code) =>
    ActionAttempt(
      actionDefinitionId: UuidValue.withValidation(
        '0198bc26-4be5-7ca0-94d2-000000000b01',
      ),
      participantAuthUserId: UuidValue.withValidation(
        '0198bc26-4be5-7ca0-94d2-000000000b02',
      ),
      periodKey: 'once',
      idempotencyKey: 'attempt',
      status: status,
      rejectionCode: code,
      startedAt: DateTime.utc(2026, 10, 21),
      updatedAt: DateTime.utc(2026, 10, 21),
    );

void main() {
  group('Given internal decision codes', () {
    test('when mapped under any status then only public codes come out', () {
      for (final code in [..._internalCodes, 'partner_secret_reason', null]) {
        for (final status in [null, ...EvidenceDecisionStatus.values]) {
          expect(
            PublicReason.all,
            contains(publicDecisionReason(code, status)),
            reason: '$code / $status',
          );
        }
      }
    });

    test('when a code has a specific meaning then it keeps it', () {
      expect(
        publicDecisionReason(
          'outside_geofence',
          EvidenceDecisionStatus.rejected,
        ),
        PublicReason.outsideArea,
      );
      expect(
        publicDecisionReason(
          'location_accuracy_too_low',
          EvidenceDecisionStatus.rejected,
        ),
        PublicReason.locationNotPrecise,
      );
      expect(
        publicDecisionReason(
          MediaVerificationReason.spokenNotHeard,
          EvidenceDecisionStatus.rejected,
        ),
        PublicReason.challengeWordNotHeard,
      );
      expect(
        publicDecisionReason(
          'qr_code_mismatch',
          EvidenceDecisionStatus.rejected,
        ),
        PublicReason.codeNotMatched,
      );
      expect(
        publicDecisionReason('media_verification_queued', null),
        PublicReason.checking,
      );
    });

    test('when only the status says something then the status decides', () {
      expect(
        publicDecisionReason(
          MediaVerificationReason.councilVerified,
          EvidenceDecisionStatus.accepted,
        ),
        PublicReason.proofAccepted,
      );
      expect(
        publicDecisionReason(
          MediaVerificationReason.councilNoConsensus,
          EvidenceDecisionStatus.manualReview,
        ),
        PublicReason.needsReview,
      );
      expect(
        publicDecisionReason(
          MediaVerificationReason.notMet,
          EvidenceDecisionStatus.rejected,
        ),
        PublicReason.proofNotAccepted,
      );
    });

    test('when a family of codes is rejected then the family is named', () {
      expect(
        publicDecisionReason(
          'capture_signature_invalid',
          EvidenceDecisionStatus.rejected,
        ),
        PublicReason.captureNotVerified,
      );
      expect(
        publicDecisionReason(
          'device_integrity_not_met',
          EvidenceDecisionStatus.rejected,
        ),
        PublicReason.captureNotVerified,
      );
      expect(
        publicDecisionReason(
          'motion_rotation_too_fast',
          EvidenceDecisionStatus.rejected,
        ),
        PublicReason.motionNotMatched,
      );
      expect(
        publicDecisionReason(
          'capture_signature_valid',
          EvidenceDecisionStatus.accepted,
        ),
        PublicReason.proofAccepted,
      );
    });

    test('when an App wrote its own reason then it never reaches the app', () {
      for (final status in EvidenceDecisionStatus.values) {
        expect(
          publicDecisionReason('partner_secret_reason', status),
          isNot('partner_secret_reason'),
        );
      }
    });
  });

  group('Given an attempt with a stored reason', () {
    test('when mapped then the public code fits the attempt status', () {
      expect(
        publicAttemptReason(
          _attempt(ActionAttemptStatus.rejected, 'outside_geofence'),
        ),
        PublicReason.outsideArea,
      );
      expect(
        publicAttemptReason(
          _attempt(ActionAttemptStatus.rejected, 'partner_secret_reason'),
        ),
        PublicReason.proofNotAccepted,
      );
      expect(
        publicAttemptReason(
          _attempt(
            ActionAttemptStatus.collectingEvidence,
            'missing_required_evidence',
          ),
        ),
        PublicReason.proofMissing,
      );
      expect(
        publicAttemptReason(
          _attempt(
            ActionAttemptStatus.pendingReview,
            'high_value_payout_review',
          ),
        ),
        PublicReason.payoutReview,
      );
      expect(
        publicAttemptReason(
          _attempt(
            ActionAttemptStatus.capacityReached,
            'action_capacity_reached',
          ),
        ),
        PublicReason.actionFull,
      );
      expect(
        publicAttemptReason(_attempt(ActionAttemptStatus.verified, null)),
        isNull,
      );
    });

    test(
      'when any internal code is stored then only public codes come out',
      () {
        for (final code in [..._internalCodes, 'partner_secret_reason']) {
          for (final status in ActionAttemptStatus.values) {
            final mapped = publicAttemptReason(_attempt(status, code));
            expect(
              mapped == null || PublicReason.all.contains(mapped),
              isTrue,
              reason: '$code / $status -> $mapped',
            );
          }
        }
      },
    );
  });

  group('Given a proof waiting for a reviewer', () {
    test('when its reason is mapped then reviewers see a stable category', () {
      const categories = {
        'payout_review',
        'security_review',
        'challenge_word_unclear',
        'location_review',
        'abuse_review',
        'local_check_unavailable',
        'verifier_unavailable',
        'low_confidence',
        'needs_review',
      };
      for (final code in [..._internalCodes, 'partner_secret_reason']) {
        expect(categories, contains(publicReviewReason(code)), reason: code);
      }
      expect(
        publicReviewReason(MediaVerificationReason.securityReview),
        'security_review',
      );
      expect(
        publicReviewReason(MediaVerificationReason.councilNoConsensus),
        'low_confidence',
      );
      // Device risks Play reports are a security review, not a verdict.
      expect(publicReviewReason('device_capture_risk'), 'security_review');
      expect(publicReviewReason('device_activity_risk'), 'security_review');
    });
  });
}
