import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/local_check/local_check_catalog.dart';

/// What one analysed camera frame showed for a check's label.
@immutable
final class LocalCheckFrame {
  const LocalCheckFrame({required this.score, this.subjectSeen = false});

  /// The label's best score in the frame, or zero when it is absent.
  final double score;

  /// Whether something to guide toward the label is in view, such as a hand
  /// that is not yet making the gesture.
  final bool subjectSeen;
}

/// What the live guide tells the person, from the latest frames.
enum LocalCheckGuidance {
  /// Nothing like the label is in view.
  notSeen,

  /// A hand is in view, but not making the gesture.
  subjectSeen,

  /// The label may be in view, but below the check's score.
  almost,

  /// The label is in view at the check's score.
  holding,

  /// Enough frames matched for the check to finish.
  passed,
}

/// How many analysed frames in a row must show the label before a photo is
/// taken by itself, so a flicker never fires the shutter.
const localCheckPhotoHoldFrames = 3;

/// A missed frame or two keeps the guide on "hold it there", so a blink of
/// the detector does not flip the message back and forth.
const _holdingGraceFrames = 2;

/// Counts what live frames showed against an [ActionLocalCheck].
///
/// It mirrors the server's replay, which samples [LocalCheckBounds.maxFrames]
/// evenly spaced frames from a video and needs `minFrames` of them to reach
/// `minScore`. A recording passes here only when enough frames matched and
/// the matching share of the recording is large enough that the replay's
/// samples would likely see it too. A photo passes once the label holds for
/// [localCheckPhotoHoldFrames] frames in a row.
///
/// The phone's result is a guide and a calibration signal only; the server
/// replays the pinned model over the evidence itself and decides.
final class LocalCheckTally {
  LocalCheckTally(this.check, {required this.photo});

  final ActionLocalCheck check;

  /// Whether the capture is a still photo rather than a recording.
  final bool photo;

  int _analysed = 0;
  int _matched = 0;
  int _consecutive = 0;
  int _sinceMatch = _holdingGraceFrames + 1;
  double _best = 0;
  LocalCheckFrame? _last;

  /// Frames analysed so far.
  int get analysed => _analysed;

  /// Frames whose score reached the check's minimum.
  int get matched => _matched;

  /// The best score seen for the label.
  double get bestScore => _best;

  void add(LocalCheckFrame frame) {
    _analysed++;
    _last = frame;
    if (frame.score > _best) _best = frame.score;
    if (frame.score >= check.minScore) {
      _matched++;
      _consecutive++;
      _sinceMatch = 0;
    } else {
      _consecutive = 0;
      _sinceMatch++;
    }
  }

  /// Whether the check is satisfied by what the camera has seen.
  bool get passed {
    if (photo) return _consecutive >= localCheckPhotoHoldFrames;
    return _matched >= check.minFrames &&
        _matched * LocalCheckBounds.maxFrames >= check.minFrames * _analysed;
  }

  LocalCheckGuidance get guidance {
    if (passed) return LocalCheckGuidance.passed;
    if (_sinceMatch <= _holdingGraceFrames) return LocalCheckGuidance.holding;
    final last = _last;
    if (last == null) return LocalCheckGuidance.notSeen;
    if (last.score > 0) return LocalCheckGuidance.almost;
    if (last.subjectSeen) return LocalCheckGuidance.subjectSeen;
    return LocalCheckGuidance.notSeen;
  }
}
