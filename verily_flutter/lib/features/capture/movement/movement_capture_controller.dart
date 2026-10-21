import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mp_camera/mp_camera.dart';
import 'package:mp_core/mp_core.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/capture/movement/ball_tracking.dart';
import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';
import 'package:verily_flutter/features/capture/movement/movement_vision.dart';
import 'package:verily_flutter/features/capture/movement/recording_files.dart';

/// Where the capture is in its lifecycle.
enum MovementCapturePhase { opening, ready, recording, saving, failed }

/// Whether the phone is counting live alongside the recording.
enum MovementLiveCounting { loading, active, unavailable }

/// Why the camera could not be used.
enum MovementCaptureFailure {
  permissionDenied,
  microphonePermissionDenied,
  noCamera,
  cameraUnavailable,
  recordingFailed,
}

/// A finished recording plus what live tracking counted while it ran.
final class MovementRecording {
  const MovementRecording({
    required this.file,
    required this.capturedAt,
    this.repetitions,
    this.trackerVersion,
  });

  final XFile file;
  final DateTime capturedAt;

  /// The advisory on-device count, or null when live counting was off.
  final int? repetitions;
  final String? trackerVersion;
}

/// Everything the capture screen renders.
@immutable
final class MovementCaptureState {
  const MovementCaptureState({
    required this.phase,
    this.liveCounting = MovementLiveCounting.loading,
    this.progress = MovementProgress.initial,
    this.pose = const [],
    this.ball,
    this.aspectRatio = 3 / 4,
    this.previewAspectRatio,
    this.mirrored = false,
    this.canFlip = false,
    this.failure,
  });

  final MovementCapturePhase phase;
  final MovementLiveCounting liveCounting;
  final MovementProgress progress;

  /// Upright, unmirrored landmarks from the latest analysed frame.
  final List<NormalizedLandmark> pose;

  /// The ball in the latest analysed frame, for ball skills.
  final BallObservation? ball;

  /// Upright analysed-frame width divided by height.
  final double aspectRatio;

  /// Upright preview width divided by height, once the camera is open. The
  /// outline lines up only when this matches [aspectRatio].
  final double? previewAspectRatio;

  /// Whether the preview is mirrored, as it is for the front camera.
  final bool mirrored;
  final bool canFlip;
  final MovementCaptureFailure? failure;

  MovementCaptureState copyWith({
    MovementCapturePhase? phase,
    MovementLiveCounting? liveCounting,
    MovementProgress? progress,
    List<NormalizedLandmark>? pose,
    BallObservation? ball,
    bool clearBall = false,
    double? aspectRatio,
    double? previewAspectRatio,
    bool? mirrored,
    bool? canFlip,
    MovementCaptureFailure? failure,
  }) {
    return MovementCaptureState(
      phase: phase ?? this.phase,
      liveCounting: liveCounting ?? this.liveCounting,
      progress: progress ?? this.progress,
      pose: pose ?? this.pose,
      ball: clearBall ? null : ball ?? this.ball,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      previewAspectRatio: previewAspectRatio ?? this.previewAspectRatio,
      mirrored: mirrored ?? this.mirrored,
      canFlip: canFlip ?? this.canFlip,
      failure: failure,
    );
  }
}

/// Camera, recording, and live tracking for one movement capture.
///
/// The interface keeps the screen testable without camera hardware.
abstract interface class MovementCaptureController implements Listenable {
  MovementCaptureState get state;

  /// The live camera preview, or null until the camera is open.
  Widget? buildPreview();

  /// Opens the camera and starts live framing feedback.
  Future<void> open();

  /// Starts a fresh set: the count resets and recording begins.
  Future<void> startRecording();

  /// Stops recording and returns the clip, or null if it could not be saved.
  Future<MovementRecording?> stopRecording();

  Future<void> flipCamera();

  /// Releases the camera, discarding any recording in progress.
  Future<void> close();

  void dispose();
}

/// Builds a controller for one requirement; replaced in widget tests.
///
/// [recordAudio] is set when the recording must carry sound, such as a
/// spoken challenge word.
typedef MovementCaptureControllerFactory = MovementCaptureController Function(
  ActionMovementKind kind, {
  required bool recordAudio,
});

/// The production controller, backed by `package:camera` and MediaPipe.
///
/// Opening, flipping, and closing run one at a time, so a slow model
/// download cannot resurrect a camera that was already closed. Frames that
/// arrive while a frame is still being analysed are dropped before they are
/// converted, so analysis never queues and stale poses are never drawn.
final class CameraMovementCaptureController extends ChangeNotifier
    implements MovementCaptureController {
  CameraMovementCaptureController({
    required this.kind,
    required MovementVisionFactory vision,
    this.recordAudio = false,
  }) : _visionFactory = vision;

  final ActionMovementKind kind;

  /// Whether the clip records sound, needed for a spoken challenge.
  final bool recordAudio;
  final MovementVisionFactory _visionFactory;

  MovementCaptureState _state = const MovementCaptureState(
    phase: MovementCapturePhase.opening,
  );
  CameraController? _camera;
  CameraLensDirection _lens = CameraLensDirection.front;
  List<CameraDescription> _cameras = const [];
  MovementVision? _vision;
  MovementTracker? _tracker;
  final MpCameraClock _clock = MpCameraClock();
  Future<void> _operation = Future<void>.value();
  int _generation = 0;
  bool _analysing = false;
  int _consecutiveFailures = 0;
  DateTime? _recordingStartedAt;
  bool _disposed = false;

  static const _maximumConsecutiveFailures = 5;

  @override
  MovementCaptureState get state => _state;

  @override
  Widget? buildPreview() {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return null;
    return CameraPreview(camera);
  }

  @override
  Future<void> open() => _serialized(() async {
    final generation = ++_generation;
    _emit(
      _state.copyWith(
        phase: MovementCapturePhase.opening,
        pose: const [],
        progress: MovementProgress.initial,
      ),
    );
    await _releaseCamera();
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _fail(MovementCaptureFailure.noCamera);
        return;
      }
      final description = _cameras.firstWhere(
        (camera) => camera.lensDirection == _lens,
        orElse: () => _cameras.first,
      );
      final camera = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: recordAudio,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      _camera = camera;
      await camera.initialize();
      await camera.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (_disposed || generation != _generation) return;
      _emit(
        _state.copyWith(
          phase: MovementCapturePhase.ready,
          // The capture orientation is locked to portrait.
          previewAspectRatio: 1 / camera.value.aspectRatio,
          mirrored: MpCameraRotation.isPreviewMirrored(description),
          canFlip: _cameras
              .map((camera) => camera.lensDirection)
              .toSet()
              .containsAll({
                CameraLensDirection.front,
                CameraLensDirection.back,
              }),
        ),
      );
      await _ensureVision(generation);
      if (_disposed || generation != _generation) return;
      if (_vision != null) {
        _tracker = movementTrackerFor(kind);
        await camera.startImageStream(
          (image) => _analyse(image, description, generation),
        );
      }
    } on CameraException catch (error) {
      if (_disposed || generation != _generation) return;
      await _releaseCamera();
      _fail(switch (error.code) {
        'CameraAccessDenied' ||
        'CameraAccessDeniedWithoutPrompt' ||
        'CameraAccessRestricted' => MovementCaptureFailure.permissionDenied,
        'AudioAccessDenied' ||
        'AudioAccessDeniedWithoutPrompt' ||
        'AudioAccessRestricted' =>
          MovementCaptureFailure.microphonePermissionDenied,
        _ => MovementCaptureFailure.cameraUnavailable,
      });
    } on PlatformException catch (error, stack) {
      if (_disposed || generation != _generation) return;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'movement tracking',
          context: ErrorDescription('while opening the camera'),
        ),
      );
      await _releaseCamera();
      _fail(MovementCaptureFailure.cameraUnavailable);
    }
  });

  @override
  Future<void> startRecording() => _serialized(() async {
    final camera = _camera;
    if (camera == null || _state.phase != MovementCapturePhase.ready) return;
    final generation = ++_generation;
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
      // Every recording is a new set, counted from zero.
      _tracker = _vision == null ? null : movementTrackerFor(kind);
      final description = camera.description;
      await camera.startVideoRecording(
        onAvailable: _vision == null
            ? null
            : (image) => _analyse(image, description, generation),
      );
      _recordingStartedAt = DateTime.now().toUtc();
      _emit(
        _state.copyWith(
          phase: MovementCapturePhase.recording,
          progress: _tracker?.progress ?? MovementProgress.initial,
        ),
      );
    } on CameraException {
      _fail(MovementCaptureFailure.recordingFailed);
    }
  });

  @override
  Future<MovementRecording?> stopRecording() async {
    MovementRecording? recording;
    await _serialized(() async {
      final camera = _camera;
      final startedAt = _recordingStartedAt;
      if (camera == null ||
          startedAt == null ||
          !camera.value.isRecordingVideo) {
        return;
      }
      ++_generation;
      _recordingStartedAt = null;
      _emit(_state.copyWith(phase: MovementCapturePhase.saving));
      try {
        final file = await camera.stopVideoRecording();
        final tracker = _tracker;
        recording = MovementRecording(
          file: file,
          capturedAt: startedAt,
          repetitions: tracker?.progress.best,
          trackerVersion: tracker?.version,
        );
        _emit(_state.copyWith(phase: MovementCapturePhase.ready));
      } on CameraException {
        _fail(MovementCaptureFailure.recordingFailed);
      }
    });
    return recording;
  }

  @override
  Future<void> flipCamera() async {
    if (!_state.canFlip || _state.phase != MovementCapturePhase.ready) return;
    _lens = _lens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await open();
  }

  @override
  Future<void> close() => _serialized(() async {
    ++_generation;
    _recordingStartedAt = null;
    await _releaseCamera();
  });

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    unawaited(
      _serialized(() async {
        await _releaseCamera();
        final vision = _vision;
        _vision = null;
        await vision?.close();
      }).catchError((Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'movement tracking',
            context: ErrorDescription('while closing a movement capture'),
          ),
        );
      }),
    );
    super.dispose();
  }

  /// Loads the models once per controller. Failure leaves recording
  /// available without live counting, because the server still verifies.
  Future<void> _ensureVision(int generation) async {
    if (_vision != null) {
      _emit(_state.copyWith(liveCounting: MovementLiveCounting.active));
      return;
    }
    if (_state.liveCounting == MovementLiveCounting.unavailable) {
      _emit(_state.copyWith(liveCounting: MovementLiveCounting.unavailable));
      return;
    }
    try {
      final vision = await _visionFactory();
      if (_disposed || generation != _generation) {
        await vision.close();
        return;
      }
      _vision = vision;
      _emit(_state.copyWith(liveCounting: MovementLiveCounting.active));
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'movement tracking',
          context: ErrorDescription('while loading the pose model'),
        ),
      );
      _emit(_state.copyWith(liveCounting: MovementLiveCounting.unavailable));
    }
  }

  void _analyse(
    CameraImage image,
    CameraDescription description,
    int generation,
  ) {
    final vision = _vision;
    if (_analysing || vision == null || generation != _generation) return;
    _analysing = true;
    final MpCameraFrame frame;
    try {
      frame = MpCameraFrameConverter.convert(
        image,
        timestampMs: _clock.nextTimestampMs(),
        rotationDegrees: MpCameraRotation.degrees(
          description,
          DeviceOrientation.portraitUp,
        ),
        mirroredPreview: MpCameraRotation.isPreviewMirrored(description),
      );
    } on Object catch (error, stack) {
      _analysing = false;
      _frameFailed(error, stack);
      return;
    }
    unawaited(
      vision
          .observe(frame)
          .then(
            (observation) {
              if (_disposed || generation != _generation) return;
              _consecutiveFailures = 0;
              final progress =
                  _tracker?.update(observation) ?? MovementProgress.initial;
              _emit(
                _state.copyWith(
                  pose: observation.pose,
                  ball: observation.ball,
                  clearBall: observation.ball == null,
                  aspectRatio: observation.aspectRatio,
                  progress: progress,
                ),
              );
            },
            onError: (Object error, StackTrace stack) {
              if (!_disposed && generation == _generation) {
                _frameFailed(error, stack);
              }
            },
          )
          .whenComplete(() => _analysing = false),
    );
  }

  void _frameFailed(Object error, StackTrace stack) {
    _tracker?.interrupt();
    if (++_consecutiveFailures < _maximumConsecutiveFailures) return;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'movement tracking',
        context: ErrorDescription('while analysing camera frames'),
      ),
    );
    // Repeated failures stop live counting; recording carries on.
    ++_generation;
    _emit(
      _state.copyWith(
        liveCounting: MovementLiveCounting.unavailable,
        pose: const [],
        progress: MovementProgress.initial,
      ),
    );
  }

  Future<void> _releaseCamera() async {
    final camera = _camera;
    _camera = null;
    if (camera == null) return;
    try {
      if (camera.value.isRecordingVideo) {
        // A discarded attempt never leaves a clip behind.
        final file = await camera.stopVideoRecording();
        await deleteRecording(file);
      }
      if (camera.value.isStreamingImages) await camera.stopImageStream();
    } on CameraException {
      // The camera is being torn down; disposal below still releases it.
    } finally {
      await camera.dispose();
    }
  }

  void _fail(MovementCaptureFailure failure) {
    _emit(
      _state.copyWith(
        phase: MovementCapturePhase.failed,
        failure: failure,
        pose: const [],
      ),
    );
  }

  /// Runs [action] after every earlier operation, even ones that failed, so
  /// one camera error never blocks a later retry or close.
  Future<void> _serialized(Future<void> Function() action) {
    final next = _operation.catchError((Object _) {}).then((_) => action());
    _operation = next;
    return next;
  }

  void _emit(MovementCaptureState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }
}
