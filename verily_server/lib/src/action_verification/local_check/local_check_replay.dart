import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_models.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// `verifierType` of every decision the server replay makes.
const mpReplayVerifierType = 'mp-replay';

/// Stable reason codes for local-check decisions.
abstract final class LocalCheckReason {
  static const matched = 'local_check_matched';
  static const notMatched = 'local_check_not_matched';

  /// The replay could not run and the AI policy fell back to a person.
  static const replayUnavailable = 'mp_replay_unavailable';
}

const _matchedSummary = 'Proof verified.';
const _notMatchedSummary = 'This proof did not show what the action asks for.';

/// What one replay produced.
sealed class LocalCheckReplay {
  const LocalCheckReplay();
}

/// The label's score in each sampled frame or audio window, in order.
final class LocalCheckReplayScores extends LocalCheckReplay {
  LocalCheckReplayScores(Iterable<double> scores, {required this.latency})
    : scores = List.unmodifiable(scores);

  final List<double> scores;
  final Duration latency;

  /// Frames or windows at or above [minScore].
  int matching(double minScore) =>
      scores.where((score) => score >= minScore).length;

  /// The highest score, clamped to 0..1; 0 when nothing was scored.
  double get best => scores.isEmpty
      ? 0
      : scores.reduce((a, b) => a > b ? a : b).clamp(0, 1).toDouble();
}

/// The replay could not run; [code] is a `LocalCheckUnavailableCode`.
final class LocalCheckReplayUnavailable extends LocalCheckReplay {
  const LocalCheckReplayUnavailable(this.code);

  final String code;
}

/// Runs a pinned MediaPipe model over pinned evidence bytes. An interface so
/// tests can script results and hosts without the runtime can fall back.
// ignore: one_member_abstracts
abstract interface class LocalCheckReplayer {
  /// Scores [check]'s label in every sampled frame (photo, video) or window
  /// (audio) of [media]. Never throws for an unavailable runtime, model, or
  /// decoder: those return [LocalCheckReplayUnavailable].
  Future<LocalCheckReplay> replay({
    required ActionLocalCheck check,
    required LocalCheckModel model,
    required Uint8List media,
    required String mimeType,
  });
}

/// The rule's local check, or null when it has none.
ActionLocalCheck? localCheckOf(ActionMediaRule rule) => switch (rule) {
  ActionMediaRule(
    localCheckTask: final task?,
    localCheckLabel: final label?,
    localCheckMinScore: final minScore?,
    localCheckMinFrames: final minFrames?,
  ) =>
    ActionLocalCheck(
      task: task,
      label: label,
      minScore: minScore,
      minFrames: minFrames,
    ),
  _ => null,
};

/// The replay's vote, recorded with whatever decides the proof.
MediaEvidenceModelVote localCheckVote(
  LocalCheckModel model,
  ActionLocalCheck check,
  LocalCheckReplay replay,
) => switch (replay) {
  LocalCheckReplayScores() => MediaEvidenceModelVote(
    modelId: model.modelId,
    resolvedModelId: model.sha256,
    providerName: mpReplayVerifierType,
    verdict: replay.matching(check.minScore) >= check.minFrames
        ? MediaEvidenceModelVerdict.fulfilled
        : MediaEvidenceModelVerdict.notFulfilled,
    confidence: replay.best,
    latencyMilliseconds: replay.latency.inMilliseconds,
  ),
  LocalCheckReplayUnavailable(:final code) => MediaEvidenceModelVote(
    modelId: model.modelId,
    resolvedModelId: model.sha256,
    providerName: mpReplayVerifierType,
    verdict: MediaEvidenceModelVerdict.failed,
    latencyMilliseconds: 0,
    errorCode: code,
  ),
};

/// The decision a replay makes on its own, or null when it cannot decide:
/// the replay was unavailable, or the proof also needs a spoken word that
/// only the AI policy or a person can hear.
///
/// A match needs at least `minFrames` frames or windows at or above
/// `minScore` for the label. The device's own result is never an input.
MediaEvidenceVerification? decideLocalCheck({
  required LocalCheckModel model,
  required ActionLocalCheck check,
  required LocalCheckReplay replay,
  required bool spokenChallengeRequired,
}) {
  if (replay is! LocalCheckReplayScores || spokenChallengeRequired) {
    return null;
  }
  final matched = replay.matching(check.minScore) >= check.minFrames;
  return MediaEvidenceVerification(
    status: matched
        ? EvidenceDecisionStatus.accepted
        : EvidenceDecisionStatus.rejected,
    verifierType: mpReplayVerifierType,
    reasonCode: matched
        ? LocalCheckReason.matched
        : LocalCheckReason.notMatched,
    summary: matched ? _matchedSummary : _notMatchedSummary,
    confidence: replay.best,
    modelName: model.modelId,
    modelVersion: model.sha256,
    votes: [localCheckVote(model, check, replay)],
  );
}

/// Folds the replay into the AI policy's decision: its vote is always
/// recorded, and when the replay was unavailable and the policy is a person,
/// the reason says so.
MediaEvidenceVerification withLocalCheckReplay(
  MediaEvidenceVerification aiDecision, {
  required LocalCheckModel model,
  required ActionLocalCheck check,
  required LocalCheckReplay replay,
}) {
  final fellBackToPerson =
      replay is LocalCheckReplayUnavailable &&
      aiDecision.status == EvidenceDecisionStatus.manualReview &&
      aiDecision.votes.isEmpty;
  return MediaEvidenceVerification(
    status: aiDecision.status,
    verifierType: aiDecision.verifierType,
    reasonCode: fellBackToPerson
        ? LocalCheckReason.replayUnavailable
        : aiDecision.reasonCode,
    summary: aiDecision.summary,
    confidence: aiDecision.confidence,
    modelName: aiDecision.modelName,
    modelVersion: aiDecision.modelVersion,
    votes: [localCheckVote(model, check, replay), ...aiDecision.votes],
  );
}

/// Reads the pinned evidence bytes for a replay and checks them against the
/// sealed digest and length, so the replay judges exactly what was
/// confirmed. Throws [LocalCheckUnavailableException] when the bytes cannot
/// be read or do not match.
typedef LocalCheckEvidenceReader = Future<Uint8List> Function(
  Session session, {
  required String storagePath,
  required String sha256Digest,
  required int byteLength,
});

/// The production [LocalCheckEvidenceReader]. Upload confirmation never
/// issues another upload for a confirmed proof, so the stored object is the
/// pinned version; the digest check proves it, and a mismatch makes the
/// replay unavailable (the AI policy then reads the pinned version itself).
Future<Uint8List> readPinnedEvidence(
  Session session, {
  required String storagePath,
  required String sha256Digest,
  required int byteLength,
}) async {
  final ByteData data;
  try {
    data = await session.storage.retrieveFile(
      storageId: evidenceStorageId,
      path: storagePath,
    );
  } on Object {
    throw const LocalCheckUnavailableException(
      LocalCheckUnavailableCode.evidenceUnreadable,
    );
  }
  final bytes = Uint8List.sublistView(data);
  if (bytes.length != byteLength ||
      sha256.convert(bytes).toString() != sha256Digest) {
    throw const LocalCheckUnavailableException(
      LocalCheckUnavailableCode.evidenceDigestMismatch,
    );
  }
  return bytes;
}
