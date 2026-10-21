import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mp_camera/mp_camera.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/local_check/local_check_tally.dart';
import 'package:verily_flutter/features/local_check/local_check_vision.dart';

/// Whether the phone is running the quick check live.
enum LocalCheckAvailability {
  /// The pinned model is downloading or loading.
  loading,

  /// Frames are being checked.
  active,

  /// The check cannot run here; Verily checks the proof after it is sent.
  unavailable,
}

/// One capture's live quick check: loads the pinned model, scores camera
/// frames, and keeps the tally the guide and the auto-finish read.
///
/// The preview and a recording keep separate tallies, so framing the shot
/// never counts towards the recording. Nothing here decides anything: the
/// result travels with the evidence as advice, and the server replays the
/// same model over the evidence it stored.
final class LocalCheckSession extends ChangeNotifier {
  LocalCheckSession({
    required this.check,
    required this.model,
    required this.photo,
    required LocalCheckVisionFactory vision,
  }) : _visionFactory = vision,
       _tally = LocalCheckTally(check, photo: photo);

  final ActionLocalCheck check;
  final LocalCheckModelView model;

  /// Whether the capture is a still photo rather than a recording.
  final bool photo;
  final LocalCheckVisionFactory _visionFactory;

  LocalCheckAvailability _availability = LocalCheckAvailability.loading;
  LocalCheckVision? _vision;
  LocalCheckTally _tally;
  bool _recording = false;
  int _consecutiveFailures = 0;
  bool _closed = false;

  static const _maximumConsecutiveFailures = 5;

  LocalCheckAvailability get availability => _availability;

  /// Whether a recording is being counted, rather than the preview.
  bool get recording => _recording;

  LocalCheckTally get tally => _tally;

  LocalCheckGuidance get guidance => _tally.guidance;

  /// Whether the check is satisfied for what is being captured now.
  bool get passed =>
      _availability == LocalCheckAvailability.active && _tally.passed;

  /// Loads the model once. A failure leaves capture available without the
  /// live check, because the server still checks the proof.
  Future<void> start() async {
    if (_vision != null || _closed) return;
    try {
      final vision = await _visionFactory(check, model);
      if (_closed) {
        await vision.close();
        return;
      }
      _vision = vision;
      _set(LocalCheckAvailability.active);
    } on Object catch (error, stack) {
      _report(error, stack, 'while loading the quick check model');
      _set(LocalCheckAvailability.unavailable);
    }
  }

  /// Scores one frame. The camera drops frames while one is in flight.
  Future<void> analyse(MpCameraFrame frame) async {
    final vision = _vision;
    if (vision == null ||
        _closed ||
        _availability != LocalCheckAvailability.active) {
      return;
    }
    final tally = _tally;
    try {
      final observed = await vision.observe(frame);
      if (_closed || !identical(tally, _tally)) return;
      _consecutiveFailures = 0;
      tally.add(observed);
      notifyListeners();
    } on Object catch (error, stack) {
      if (_closed) return;
      if (++_consecutiveFailures < _maximumConsecutiveFailures) return;
      _report(error, stack, 'while checking camera frames');
      _set(LocalCheckAvailability.unavailable);
    }
  }

  /// Starts counting a fresh recording.
  void startRecording() {
    _recording = true;
    _tally = LocalCheckTally(check, photo: photo);
    notifyListeners();
  }

  /// Goes back to guiding the preview.
  void stopRecording() {
    _recording = false;
    _tally = LocalCheckTally(check, photo: photo);
    notifyListeners();
  }

  /// The phone's own result, sent with the evidence for calibration, or null
  /// when the check did not run on any frame of this capture.
  DeviceLocalCheckResult? advisory() {
    final tally = _tally;
    if (_availability != LocalCheckAvailability.active || tally.analysed == 0) {
      return null;
    }
    return DeviceLocalCheckResult(
      modelId: model.modelId,
      modelSha256: model.sha256,
      label: check.label,
      score: tally.bestScore.clamp(0, 1).toDouble(),
      matchedFrames: tally.matched,
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final vision = _vision;
    _vision = null;
    await vision?.close();
  }

  @override
  void dispose() {
    unawaited(
      close().catchError((Object error, StackTrace stack) {
        _report(error, stack, 'while closing the quick check');
      }),
    );
    super.dispose();
  }

  void _set(LocalCheckAvailability next) {
    if (_closed) return;
    _availability = next;
    notifyListeners();
  }

  void _report(Object error, StackTrace stack, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'quick check',
        context: ErrorDescription(context),
      ),
    );
  }
}
