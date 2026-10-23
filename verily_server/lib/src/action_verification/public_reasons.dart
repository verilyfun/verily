import 'package:verily_server/src/action_verification/device_integrity_verifier.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// The reason codes the app may show or switch on. They are a small, stable,
/// documented set (docs/serverpod-api.md): internal verifier codes, model and
/// provider details, and anything an App wrote itself never leave the server.
/// Decisions keep their internal codes for audit and review.
abstract final class PublicReason {
  static const proofAccepted = 'proof_accepted';
  static const checking = 'checking';
  static const needsReview = 'needs_review';
  static const proofNotAccepted = 'proof_not_accepted';
  static const proofMissing = 'proof_missing';
  static const actionFull = 'action_full';
  static const outsideArea = 'outside_area';
  static const locationNotPrecise = 'location_not_precise';
  static const locationTooOld = 'location_too_old';
  static const phoneClock = 'phone_clock';
  static const recordingLength = 'recording_length';
  static const challengeWordMissing = 'challenge_word_missing';
  static const challengeWordTooEarly = 'challenge_word_too_early';
  static const challengeWordNotHeard = 'challenge_word_not_heard';
  static const codeNotMatched = 'code_not_matched';
  static const motionNotMatched = 'motion_not_matched';
  static const captureNotVerified = 'capture_not_verified';
  static const payoutReview = 'payout_review';
  static const appConfirmed = 'app_confirmed';
  static const appNotConfirmed = 'app_not_confirmed';
  static const appChecking = 'app_checking';
  static const appUnreachable = 'app_unreachable';
  static const appNoAnswer = 'app_no_answer';

  static const Set<String> all = {
    proofAccepted,
    checking,
    needsReview,
    proofNotAccepted,
    proofMissing,
    actionFull,
    outsideArea,
    locationNotPrecise,
    locationTooOld,
    phoneClock,
    recordingLength,
    challengeWordMissing,
    challengeWordTooEarly,
    challengeWordNotHeard,
    codeNotMatched,
    motionNotMatched,
    captureNotVerified,
    payoutReview,
    appConfirmed,
    appNotConfirmed,
    appChecking,
    appUnreachable,
    appNoAnswer,
  };
}

/// Internal codes with a specific public meaning, whatever the status.
const _exact = <String, String>{
  'inside_geofence': PublicReason.proofAccepted,
  'outside_geofence': PublicReason.outsideArea,
  'location_accuracy_too_low': PublicReason.locationNotPrecise,
  'location_capture_stale': PublicReason.locationTooOld,
  'location_capture_time_invalid': PublicReason.phoneClock,
  'location_travel_needs_review': PublicReason.needsReview,
  'media_capture_time_invalid': PublicReason.phoneClock,
  'media_duration_out_of_range': PublicReason.recordingLength,
  'media_verification_queued': PublicReason.checking,
  'spoken_challenge_missing': PublicReason.challengeWordMissing,
  'spoken_challenge_predates_capture': PublicReason.challengeWordTooEarly,
  'spoken_challenge_not_heard': PublicReason.challengeWordNotHeard,
  'qr_code_matched': PublicReason.proofAccepted,
  'qr_code_mismatch': PublicReason.codeNotMatched,
  'motion_verified': PublicReason.proofAccepted,
  'missing_required_evidence': PublicReason.proofMissing,
  'action_capacity_reached': PublicReason.actionFull,
  'high_value_payout_review': PublicReason.payoutReview,
  'app_confirmed': PublicReason.appConfirmed,
  'app_not_confirmed': PublicReason.appNotConfirmed,
  'app_verification_calling': PublicReason.appChecking,
  'app_verification_waiting': PublicReason.appChecking,
  'app_verification_retrying': PublicReason.appChecking,
  'app_verification_failed': PublicReason.appUnreachable,
  'app_verification_expired': PublicReason.appNoAnswer,
};

/// The public code for one decision's internal [code] and [status]. A null
/// status means the proof is still being checked.
String publicDecisionReason(String? code, EvidenceDecisionStatus? status) {
  if (code != null) {
    final exact = _exact[code];
    if (exact != null) return exact;
  }
  switch (status) {
    case null:
      return PublicReason.checking;
    case EvidenceDecisionStatus.accepted:
      return PublicReason.proofAccepted;
    case EvidenceDecisionStatus.manualReview:
      return PublicReason.needsReview;
    case EvidenceDecisionStatus.rejected:
      return _rejectedFamily(code) ?? PublicReason.proofNotAccepted;
  }
}

/// The public code for why an attempt is where it is, or null when it has
/// no reason to give.
String? publicAttemptReason(ActionAttempt attempt) {
  final code = attempt.rejectionCode;
  if (code == null) return null;
  final exact = _exact[code];
  if (exact != null) return exact;
  return switch (attempt.status) {
    ActionAttemptStatus.pendingReview ||
    ActionAttemptStatus.verifying => PublicReason.needsReview,
    ActionAttemptStatus.capacityReached => PublicReason.actionFull,
    ActionAttemptStatus.collectingEvidence => PublicReason.proofMissing,
    ActionAttemptStatus.verified => null,
    ActionAttemptStatus.rejected =>
      _rejectedFamily(code) ?? PublicReason.proofNotAccepted,
  };
}

String? _rejectedFamily(String? code) {
  if (code == null) return null;
  if (code.startsWith('motion_')) return PublicReason.motionNotMatched;
  if (code.startsWith('capture_') ||
      code.startsWith('device_integrity_') ||
      code == 'app_integrity_not_recognised') {
    return PublicReason.captureNotVerified;
  }
  return null;
}

/// Why a proof is in the review queue, for reviewers: a stable code from a
/// documented set rather than the verifier's internal one.
String publicReviewReason(String code) => switch (code) {
  'high_value_payout_review' => 'payout_review',
  'media_security_review_required' ||
  'media_prompt_injection_detected' ||
  deviceCaptureRiskReviewCode ||
  deviceActivityRiskReviewCode ||
  appleDeviceRiskUnavailableReviewCode ||
  appleDeviceReviewCode => 'security_review',
  'spoken_challenge_unverified' => 'challenge_word_unclear',
  'location_travel_needs_review' => 'location_review',
  'abuse_review_required' => 'abuse_review',
  'mp_replay_unavailable' => 'local_check_unavailable',
  'media_verifier_unavailable' ||
  'media_council_quorum_unavailable' ||
  'verification_budget_unavailable' ||
  'media_verifier_retry_exhausted' => 'verifier_unavailable',
  'media_confidence_below_threshold' ||
  'media_verifier_uncertain' ||
  'media_council_no_consensus' => 'low_confidence',
  _ => 'needs_review',
};
