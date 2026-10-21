import 'package:cross_file/cross_file.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

/// One finished photo, video, or audio capture, fingerprinted for upload.
///
/// The fingerprint is computed from the exact bytes that will be uploaded,
/// so the device signature and Play Integrity token vouch for this file and
/// no other.
@immutable
class CapturedMedia {
  const CapturedMedia({
    required this.kind,
    required this.file,
    required this.byteLength,
    required this.durationSeconds,
    required this.contentType,
    required this.capturedAt,
    required this.sha256Digest,
    this.spokenChallengeWord,
    this.deviceRepetitionCount,
    this.deviceTrackerVersion,
  });

  final MediaEvidenceKind kind;
  final XFile file;
  final int byteLength;

  /// Zero for a photo.
  final int durationSeconds;
  final String contentType;

  /// When the capture ended, in UTC.
  final DateTime capturedAt;
  final String sha256Digest;

  /// The word shown while recording, kept so the review screen can remind
  /// the person what they were asked to say.
  final String? spokenChallengeWord;

  /// What live tracking counted while recording. Advisory only: the server
  /// verifies the recording itself.
  final int? deviceRepetitionCount;
  final String? deviceTrackerVersion;
}

/// Measures and fingerprints [file] as evidence of [kind].
Future<CapturedMedia> describeCapturedMedia(
  XFile file, {
  required MediaEvidenceKind kind,
  required String contentType,
  required DateTime capturedAt,
  required int durationSeconds,
  String? spokenChallengeWord,
  int? deviceRepetitionCount,
  String? deviceTrackerVersion,
}) async {
  final digest = await sha256Stream(file.openRead());
  return CapturedMedia(
    kind: kind,
    file: file,
    byteLength: await file.length(),
    durationSeconds: kind == MediaEvidenceKind.photo ? 0 : durationSeconds,
    contentType: contentType,
    capturedAt: capturedAt.toUtc(),
    sha256Digest: digest,
    spokenChallengeWord: spokenChallengeWord,
    deviceRepetitionCount: deviceRepetitionCount,
    deviceTrackerVersion: deviceTrackerVersion,
  );
}

/// The evidence family a requirement [kind] captures, or null when its proof
/// is not media.
MediaEvidenceKind? mediaKindOf(ActionRequirementKind kind) => switch (kind) {
  ActionRequirementKind.video => MediaEvidenceKind.video,
  ActionRequirementKind.photo => MediaEvidenceKind.photo,
  ActionRequirementKind.audio => MediaEvidenceKind.audio,
  ActionRequirementKind.location ||
  ActionRequirementKind.qrCode ||
  ActionRequirementKind.motion ||
  ActionRequirementKind.externalApp => null,
};
