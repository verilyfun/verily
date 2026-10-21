import 'package:verily_flutter/l10n/l10n.dart';

/// The reason codes the server shows participants
/// (`EvidenceSubmissionResult.reasonCode`, `ActionAttemptView.rejectionCode`).
///
/// They are a small, documented set (docs/serverpod-api.md, "Reason codes the
/// app sees"): internal verifier codes never reach the phone, so the app only
/// ever switches on these.
abstract final class ProofReason {
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
}

/// What a public proof reason means for the person, in their words. A code
/// this build does not know reads as a plain "not accepted", never as the
/// code itself.
String proofReasonMessage(AppLocalizations l10n, String code) => switch (code) {
  ProofReason.proofAccepted => l10n.proofReasonProofAccepted,
  ProofReason.checking => l10n.proofReasonChecking,
  ProofReason.needsReview => l10n.proofReasonNeedsReview,
  ProofReason.proofNotAccepted => l10n.proofReasonNotAccepted,
  ProofReason.proofMissing => l10n.proofReasonMissing,
  ProofReason.actionFull => l10n.proofReasonActionFull,
  ProofReason.outsideArea => l10n.proofReasonOutsideArea,
  ProofReason.locationNotPrecise => l10n.proofReasonLocationNotPrecise,
  ProofReason.locationTooOld => l10n.proofReasonLocationTooOld,
  ProofReason.phoneClock => l10n.proofReasonPhoneClock,
  ProofReason.recordingLength => l10n.proofReasonRecordingLength,
  ProofReason.challengeWordMissing => l10n.proofReasonChallengeWordMissing,
  ProofReason.challengeWordTooEarly => l10n.proofReasonChallengeWordTooEarly,
  ProofReason.challengeWordNotHeard => l10n.proofReasonChallengeWordNotHeard,
  ProofReason.codeNotMatched => l10n.proofReasonCodeNotMatched,
  ProofReason.motionNotMatched => l10n.proofReasonMotionNotMatched,
  ProofReason.captureNotVerified => l10n.proofReasonCaptureNotVerified,
  ProofReason.payoutReview => l10n.proofReasonPayoutReview,
  ProofReason.appConfirmed => l10n.proofReasonAppConfirmed,
  ProofReason.appNotConfirmed => l10n.proofReasonAppNotConfirmed,
  ProofReason.appChecking => l10n.proofReasonAppChecking,
  ProofReason.appUnreachable => l10n.proofReasonAppUnreachable,
  ProofReason.appNoAnswer => l10n.proofReasonAppNoAnswer,
  _ => l10n.proofReasonOther,
};

/// Why a proof is in the review queue, for reviewers: one of the server's
/// nine categories (`EvidenceReviewQueueItem.reviewReasonCode`).
String reviewReasonLabel(AppLocalizations l10n, String code) => switch (code) {
  'payout_review' => l10n.reviewReasonPayout,
  'security_review' => l10n.reviewReasonSecurity,
  'challenge_word_unclear' => l10n.reviewReasonChallengeWord,
  'location_review' => l10n.reviewReasonLocation,
  'abuse_review' => l10n.reviewReasonAbuse,
  'local_check_unavailable' => l10n.reviewReasonLocalCheck,
  'verifier_unavailable' => l10n.reviewReasonVerifier,
  'low_confidence' => l10n.reviewReasonLowConfidence,
  _ => l10n.reviewReasonNeedsPerson,
};
