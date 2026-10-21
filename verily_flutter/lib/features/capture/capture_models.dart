import 'dart:math' as math;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/features/capture/capture_providers.dart';
import 'package:verily_flutter/features/evidence/captured_media.dart';

/// A capture straight off the camera or microphone, before it is measured
/// and fingerprinted.
@immutable
final class RawCapture {
  const RawCapture({
    required this.file,
    required this.capturedAt,
    this.measuredDuration,
    this.repetitions,
    this.trackerVersion,
    this.localCheck,
  });

  final XFile file;

  /// When the capture ended.
  final DateTime capturedAt;

  /// How long the recording ran by the app's own clock; used when the
  /// container's duration cannot be read.
  final Duration? measuredDuration;

  /// What live tracking counted, for movement recordings. Advisory only.
  final int? repetitions;
  final String? trackerVersion;

  /// What the phone's quick check saw, when one ran. Advisory only: the
  /// server replays the same model over the evidence and decides.
  final DeviceLocalCheckResult? localCheck;
}

/// Why a capture cannot be sent as it is.
enum CaptureProblem {
  /// The phone produced a format this requirement does not accept.
  unsupportedFormat,

  /// The file is larger than this requirement accepts.
  tooLarge,
}

class CaptureProblemException implements Exception {
  const CaptureProblemException(this.problem);

  final CaptureProblem problem;

  @override
  String toString() => 'CaptureProblemException(${problem.name})';
}

/// The shortest recording a requirement accepts. Recordings are never
/// shorter than a second, because a zero-length clip cannot be bound.
Duration minimumRecording(ActionRequirementView requirement) =>
    Duration(seconds: math.max(1, requirement.minDurationSeconds ?? 1));

/// The longest recording a requirement accepts. The server never accepts
/// more than five minutes.
Duration maximumRecording(ActionRequirementView requirement) =>
    Duration(seconds: requirement.maxDurationSeconds ?? 300);

/// How early a recording stops before its limit, so the clip the container
/// reports never runs past it.
const recordingLimitMargin = Duration(milliseconds: 700);

/// Whole seconds as the server counts them: rounded, never zero.
int recordedSeconds(Duration duration) =>
    math.max(1, (duration.inMilliseconds / 1000).round());

/// The content type a captured [file] of [kind] is sent as, from its
/// extension or reported type, or null when it is not one Verily takes.
String? capturedContentType(MediaEvidenceKind kind, XFile file) {
  final reported = file.mimeType?.toLowerCase();
  final name = (file.name.isEmpty ? file.path : file.name).toLowerCase();
  final extension = name.contains('.') ? name.split('.').last : '';
  return switch (kind) {
    MediaEvidenceKind.video => switch (extension) {
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      _ => _reportedIfKnown(reported, const {
        'video/mp4',
        'video/quicktime',
        'video/webm',
      }),
    },
    MediaEvidenceKind.photo => switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      _ => _reportedIfKnown(reported, const {
        'image/jpeg',
        'image/png',
        'image/heic',
      }),
    },
    MediaEvidenceKind.audio => switch (extension) {
      'm4a' || 'mp4' || 'aac' => 'audio/mp4',
      'webm' => 'audio/webm',
      _ => _reportedIfKnown(reported, const {'audio/mp4', 'audio/webm'}),
    },
  };
}

String? _reportedIfKnown(String? reported, Set<String> known) =>
    reported != null && known.contains(reported) ? reported : null;

/// Measures, checks, and fingerprints [raw] for [requirement].
///
/// Throws [CaptureProblemException] when the requirement cannot take it.
/// The fingerprint covers the exact bytes that will be uploaded.
Future<CapturedMedia> prepareCapture(
  RawCapture raw, {
  required ActionRequirementView requirement,
  required MediaDurationProbe probe,
  String? spokenChallengeWord,
}) async {
  final kind = mediaKindOf(requirement.kind);
  if (kind == null) {
    throw ArgumentError.value(requirement.kind, 'requirement', 'Not media.');
  }
  final contentType = capturedContentType(kind, raw.file);
  final accepted = requirement.acceptedContentTypes;
  if (contentType == null ||
      (accepted != null &&
          accepted.isNotEmpty &&
          !accepted.contains(contentType))) {
    debugPrint(
      'Capture format not accepted: ${contentType ?? raw.file.mimeType} '
      'for ${accepted ?? const []}.',
    );
    throw const CaptureProblemException(CaptureProblem.unsupportedFormat);
  }
  final byteLength = await raw.file.length();
  final limit = requirement.maxByteLength;
  if (limit != null && byteLength > limit) {
    throw const CaptureProblemException(CaptureProblem.tooLarge);
  }

  var durationSeconds = 0;
  if (kind != MediaEvidenceKind.photo) {
    Duration? duration;
    try {
      duration = await probe(raw.file);
    } on Object catch (error) {
      // The container could not be read here; the app's own clock still
      // measured the recording, and the server checks the file itself.
      debugPrint('Could not read the recording length: $error');
    }
    if (duration == null || duration <= Duration.zero) {
      duration = raw.measuredDuration;
    }
    durationSeconds = recordedSeconds(duration ?? Duration.zero);
  }

  return describeCapturedMedia(
    raw.file,
    kind: kind,
    contentType: contentType,
    capturedAt: raw.capturedAt,
    durationSeconds: durationSeconds,
    spokenChallengeWord: spokenChallengeWord,
    deviceRepetitionCount: raw.repetitions,
    deviceTrackerVersion: raw.trackerVersion,
    // Sent only for a proof whose rule has a quick check.
    deviceLocalCheck: requirement.localCheck == null ? null : raw.localCheck,
  );
}
