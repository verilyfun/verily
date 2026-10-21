import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/verification_requests/receipt_signing.dart';

/// A receipt check outcome.
abstract final class ReceiptCheck {
  static const passed = 'passed';
  static const failed = 'failed';
  static const notChecked = 'notChecked';
  static const inside = 'inside';
  static const outside = 'outside';
}

/// Receipt `status` values.
abstract final class ReceiptStatus {
  static const verified = 'verified';
  static const rejected = 'rejected';
  static const pendingReview = 'pendingReview';
  static const declined = 'declined';
  static const expired = 'expired';
}

/// Integrity providers that are not Play Integrity: a device signature only,
/// or a capture challenge with neither attestation.
const _signatureOnlyProvider = 'android-keystore';
const _challengeOnlyProvider = 'capture-challenge';

/// Verifier types that judge what the capture shows.
const _contentVerifierPrefixes = [
  'openrouter',
  'cloud-ai-media',
  'human-review',
  'appeal-review',
  'mp-replay',
];

/// What the server knows about one proof, for receipt checks.
final class ReceiptProof {
  const ReceiptProof({
    required this.evidence,
    this.decision,
    this.captureChallenge,
  });

  final ActionEvidence evidence;

  /// The latest decision on [evidence].
  final EvidenceDecision? decision;

  /// The consumed capture challenge that bound [evidence], if any.
  final ActionCaptureChallenge? captureChallenge;

  /// Whether the capture-integrity evaluation itself refused the proof.
  bool get integrityFailed {
    final challenge = captureChallenge;
    final latest = decision;
    return challenge != null &&
        latest != null &&
        latest.status == EvidenceDecisionStatus.rejected &&
        latest.verifierType == challenge.provider &&
        latest.reasonCode == challenge.verdict;
  }
}

/// The receipt's `checks` object.
///
/// - `liveCapture`: the proof was bound to a fresh server capture challenge
///   (passed), the binding or attestation was refused (failed), or no
///   challenge was used (notChecked).
/// - `deviceIntegrity`: Play Integrity attested the capture (passed), its
///   verdict was refused (failed), or none was sent (notChecked).
/// - `captureSignature`: a hardware-backed device key signed the capture
///   (passed), the signature was refused (failed), or none was sent.
/// - `place`: inside or outside the App's radius from the location proof's
///   geofence decision; notChecked when no place was asked for, no location
///   proof arrived, or it was refused for another reason (accuracy, age).
/// - `liveChallenge`: the spoken word was confirmed (passed, the proof was
///   accepted with a word bound), not heard (failed), or not asked for or
///   not yet decided (notChecked).
/// - `content`: a content check whose proof was accepted (passed) or refused
///   by a content verifier or a person (failed); notChecked for captureOnly
///   and location requests, and while undecided.
Map<String, String> receiptChecks({
  required VerificationRequest request,
  ReceiptProof? primary,
  ReceiptProof? place,
}) {
  String liveCapture() {
    final proof = primary;
    if (proof == null || proof.captureChallenge == null) {
      return ReceiptCheck.notChecked;
    }
    return proof.integrityFailed ? ReceiptCheck.failed : ReceiptCheck.passed;
  }

  String deviceIntegrity() {
    final proof = primary;
    final provider = proof?.captureChallenge?.provider;
    if (proof == null ||
        provider == null ||
        provider == _signatureOnlyProvider ||
        provider == _challengeOnlyProvider) {
      return ReceiptCheck.notChecked;
    }
    if (proof.integrityFailed) return ReceiptCheck.failed;
    return proof.evidence.provenanceLevel == EvidenceProvenanceLevel.basic
        ? ReceiptCheck.notChecked
        : ReceiptCheck.passed;
  }

  String captureSignature() {
    final proof = primary;
    if (proof == null) return ReceiptCheck.notChecked;
    if (proof.evidence.provenanceLevel ==
        EvidenceProvenanceLevel.deviceSigned) {
      return ReceiptCheck.passed;
    }
    if (proof.integrityFailed &&
        proof.captureChallenge?.provider == _signatureOnlyProvider) {
      return ReceiptCheck.failed;
    }
    return ReceiptCheck.notChecked;
  }

  String placeCheck() {
    if (request.placeLatitude == null) return ReceiptCheck.notChecked;
    return switch (place?.decision?.reasonCode) {
      'inside_geofence' => ReceiptCheck.inside,
      'outside_geofence' => ReceiptCheck.outside,
      _ => ReceiptCheck.notChecked,
    };
  }

  final media = request.kind == VerificationRequestKind.location
      ? null
      : primary;
  String liveChallenge() {
    if (!request.spokenChallenge ||
        media == null ||
        media.evidence.spokenChallengeWord == null) {
      return ReceiptCheck.notChecked;
    }
    return switch (media.decision) {
      EvidenceDecision(status: EvidenceDecisionStatus.accepted) =>
        ReceiptCheck.passed,
      EvidenceDecision(reasonCode: 'spoken_challenge_not_heard') =>
        ReceiptCheck.failed,
      _ => ReceiptCheck.notChecked,
    };
  }

  String content() {
    if (request.check != VerificationRequestCheck.content || media == null) {
      return ReceiptCheck.notChecked;
    }
    final decision = media.decision;
    if (decision == null) return ReceiptCheck.notChecked;
    if (decision.status == EvidenceDecisionStatus.accepted) {
      return ReceiptCheck.passed;
    }
    if (decision.status == EvidenceDecisionStatus.rejected &&
        decision.reasonCode != 'spoken_challenge_not_heard' &&
        _contentVerifierPrefixes.any(decision.verifierType.startsWith)) {
      return ReceiptCheck.failed;
    }
    return ReceiptCheck.notChecked;
  }

  return {
    'liveCapture': liveCapture(),
    'deviceIntegrity': deviceIntegrity(),
    'captureSignature': captureSignature(),
    'place': placeCheck(),
    'liveChallenge': liveChallenge(),
    'content': content(),
  };
}

/// The receipt status for a request and its attempt.
String receiptStatusFor(VerificationRequest request, ActionAttempt? attempt) {
  if (request.status == VerificationRequestStatus.declined) {
    return ReceiptStatus.declined;
  }
  if (request.status == VerificationRequestStatus.expired) {
    return ReceiptStatus.expired;
  }
  return switch (attempt?.status) {
    ActionAttemptStatus.verified => ReceiptStatus.verified,
    ActionAttemptStatus.rejected ||
    ActionAttemptStatus.capacityReached => ReceiptStatus.rejected,
    _ => ReceiptStatus.pendingReview,
  };
}

/// Whether a receipt status will never change.
bool receiptStatusIsFinal(String status) =>
    status != ReceiptStatus.pendingReview;

/// The receipt claims, exactly as docs/platform.md lists them. Never
/// coordinates, storage paths, account ids, or the evidence link.
Map<String, Object?> receiptClaims({
  required VerificationRequest request,
  required String status,
  required DateTime issuedAt,
  ReceiptProof? primary,
  ReceiptProof? place,
}) {
  final evidence = primary?.evidence;
  final media =
      request.kind != VerificationRequestKind.location &&
          evidence?.sha256Digest != null
      ? evidence
      : null;
  return {
    'iss': receiptIssuer,
    'aud': request.appId.toString(),
    // A person who declined, or nobody, is never identified to the App.
    if (request.subject != null && status != ReceiptStatus.declined)
      'sub': request.subject,
    'jti': request.id.toString(),
    'iat': issuedAt.toUtc().millisecondsSinceEpoch ~/ 1000,
    'kind': request.kind.name,
    'status': status,
    'checks': receiptChecks(request: request, primary: primary, place: place),
    if (evidence != null) 'capturedAt': receiptTimestamp(evidence.capturedAt),
    if (media != null)
      'evidence': {
        'sha256': media.sha256Digest,
        'mimeType': media.mimeType,
        'durationSeconds': media.durationSeconds,
      },
  };
}

/// Loads the proofs behind a request's attempt: the required proof and the
/// optional place proof.
Future<({ReceiptProof? primary, ReceiptProof? place})> loadReceiptProofs(
  Session session, {
  required VerificationRequest request,
  Transaction? transaction,
}) async {
  final attemptId = request.attemptId;
  final actionId = request.actionDefinitionId;
  if (attemptId == null || actionId == null) {
    return (primary: null, place: null);
  }
  final requirements = await ActionRequirement.db.find(
    session,
    where: (table) => table.actionDefinitionId.equals(actionId),
    orderBy: (table) => table.position,
    transaction: transaction,
  );
  Future<ReceiptProof?> proofFor(ActionRequirement? requirement) async {
    if (requirement == null) return null;
    final evidence = await ActionEvidence.db.findFirstRow(
      session,
      where: (table) =>
          table.attemptId.equals(attemptId) &
          table.requirementId.equals(requirement.id),
      transaction: transaction,
    );
    if (evidence == null) return null;
    final decision = await latestDecision(
      session,
      evidenceId: evidence.id!,
      transaction: transaction,
    );
    final challenge = await ActionCaptureChallenge.db.findFirstRow(
      session,
      where: (table) =>
          table.attemptId.equals(attemptId) &
          table.requirementId.equals(requirement.id) &
          table.usedAt.notEquals(null),
      orderBy: (table) => table.usedAt.desc(),
      transaction: transaction,
    );
    return ReceiptProof(
      evidence: evidence,
      decision: decision,
      captureChallenge: challenge,
    );
  }

  final primaryRequirement = requirements
      .where((requirement) => requirement.isRequired)
      .firstOrNull;
  final placeRequirement = requirements
      .where(
        (requirement) => requirement.kind == ActionRequirementKind.location,
      )
      .firstOrNull;
  final primary = await proofFor(primaryRequirement);
  final place = placeRequirement?.id == primaryRequirement?.id
      ? primary
      : await proofFor(placeRequirement);
  return (primary: primary, place: place);
}

/// Builds and signs the current receipt. Returns null when no signing key is
/// configured.
Future<({String status, String? token})> issueReceipt(
  Session session, {
  required VerificationRequest request,
  required DateTime now,
  ActionAttempt? attempt,
  Transaction? transaction,
}) async {
  final status = receiptStatusFor(request, attempt);
  final signer = ReceiptSigning.signer;
  if (signer == null) return (status: status, token: null);
  final proofs = await loadReceiptProofs(
    session,
    request: request,
    transaction: transaction,
  );
  return (
    status: status,
    token: signer.sign(
      receiptClaims(
        request: request,
        status: status,
        issuedAt: now,
        primary: proofs.primary,
        place: proofs.place,
      ),
    ),
  );
}

/// RFC 3339 in UTC to the whole second (`2026-10-12T08:30:12Z`), so a
/// receipt never carries sub-second capture timing.
String receiptTimestamp(DateTime value) {
  final iso = value.toUtc().toIso8601String();
  return '${iso.substring(0, 19)}Z';
}
