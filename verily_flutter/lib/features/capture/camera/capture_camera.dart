import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:verily_flutter/features/capture/movement/recording_files.dart';

/// Which way the camera faces.
enum CaptureLens { front, back }

/// Where the camera is in its lifecycle.
enum CaptureCameraPhase { opening, ready, recording, failed }

/// Why the camera could not be used, in terms the screen can explain.
enum CaptureCameraFailure {
  cameraPermissionDenied,
  microphonePermissionDenied,
  noCamera,
  unavailable,
  recordingFailed,
}

/// Everything the capture screen renders about the camera.
@immutable
final class CaptureCameraState {
  const CaptureCameraState({
    required this.phase,
    this.failure,
    this.canFlip = false,
    this.previewAspectRatio,
  });

  final CaptureCameraPhase phase;
  final CaptureCameraFailure? failure;
  final bool canFlip;

  /// Upright preview width divided by height, once the camera is open.
  final double? previewAspectRatio;

  CaptureCameraState copyWith({
    CaptureCameraPhase? phase,
    CaptureCameraFailure? failure,
    bool? canFlip,
    double? previewAspectRatio,
  }) => CaptureCameraState(
    phase: phase ?? this.phase,
    failure: failure,
    canFlip: canFlip ?? this.canFlip,
    previewAspectRatio: previewAspectRatio ?? this.previewAspectRatio,
  );
}

/// A live camera for photo and video proof.
///
/// The interface keeps capture screens testable without camera hardware.
/// There is deliberately no way to pick an existing file: proof is captured
/// here, at the moment it happens.
abstract interface class CaptureCamera implements Listenable {
  CaptureCameraState get state;

  /// The live preview, or null until the camera is open.
  Widget? buildPreview();

  Future<void> open();

  /// Takes a still photo, or returns null when the camera is not ready.
  Future<XFile?> takePhoto();

  Future<void> startRecording();

  /// Stops recording and returns the clip, or null if it could not be saved.
  Future<XFile?> stopRecording();

  Future<void> flip();

  /// Releases the camera, discarding any recording in progress.
  Future<void> close();

  void dispose();
}

/// Builds the camera for one capture; replaced in widget tests.
typedef CaptureCameraFactory = CaptureCamera Function({
  required bool recordAudio,
  required CaptureLens initialLens,
});

/// The production camera, backed by `package:camera`.
///
/// Opening, recording, flipping, and closing run one at a time, so a slow
/// open can never resurrect a camera that was already closed.
final class PluginCaptureCamera extends ChangeNotifier
    implements CaptureCamera {
  PluginCaptureCamera({required this.recordAudio, this._lens = .back});

  /// Whether video records sound, needed for a spoken challenge.
  final bool recordAudio;

  CaptureLens _lens;
  CaptureCameraState _state = const CaptureCameraState(
    phase: CaptureCameraPhase.opening,
  );
  CameraController? _camera;
  Future<void> _operation = Future<void>.value();
  int _generation = 0;
  bool _disposed = false;

  @override
  CaptureCameraState get state => _state;

  @override
  Widget? buildPreview() {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return null;
    return CameraPreview(camera);
  }

  @override
  Future<void> open() => _serialized(() async {
    final generation = ++_generation;
    _emit(_state.copyWith(phase: CaptureCameraPhase.opening));
    await _release();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _fail(CaptureCameraFailure.noCamera);
        return;
      }
      final wanted = _lens == CaptureLens.front
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == wanted,
        orElse: () => cameras.first,
      );
      final camera = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: recordAudio,
      );
      _camera = camera;
      await camera.initialize();
      await camera.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (_disposed || generation != _generation) return;
      final directions = cameras.map((camera) => camera.lensDirection).toSet();
      _emit(
        _state.copyWith(
          phase: CaptureCameraPhase.ready,
          // The capture orientation is locked to portrait.
          previewAspectRatio: 1 / camera.value.aspectRatio,
          canFlip: directions.containsAll({
            CameraLensDirection.front,
            CameraLensDirection.back,
          }),
        ),
      );
    } on CameraException catch (error) {
      if (_disposed || generation != _generation) return;
      await _release();
      _fail(cameraFailureFor(error.code));
    } on PlatformException catch (error, stack) {
      if (_disposed || generation != _generation) return;
      _report(error, stack, 'while opening the camera');
      await _release();
      _fail(CaptureCameraFailure.unavailable);
    }
  });

  @override
  Future<XFile?> takePhoto() async {
    XFile? photo;
    await _serialized(() async {
      final camera = _camera;
      if (camera == null || _state.phase != CaptureCameraPhase.ready) return;
      try {
        photo = await camera.takePicture();
      } on CameraException catch (error, stack) {
        _report(error, stack, 'while taking a photo');
        _fail(CaptureCameraFailure.recordingFailed);
      }
    });
    return photo;
  }

  @override
  Future<void> startRecording() => _serialized(() async {
    final camera = _camera;
    if (camera == null || _state.phase != CaptureCameraPhase.ready) return;
    try {
      await camera.startVideoRecording();
      _emit(_state.copyWith(phase: CaptureCameraPhase.recording));
    } on CameraException catch (error, stack) {
      _report(error, stack, 'while starting a recording');
      _fail(CaptureCameraFailure.recordingFailed);
    }
  });

  @override
  Future<XFile?> stopRecording() async {
    XFile? clip;
    await _serialized(() async {
      final camera = _camera;
      if (camera == null || !camera.value.isRecordingVideo) return;
      try {
        clip = await camera.stopVideoRecording();
        _emit(_state.copyWith(phase: CaptureCameraPhase.ready));
      } on CameraException catch (error, stack) {
        _report(error, stack, 'while saving a recording');
        _fail(CaptureCameraFailure.recordingFailed);
      }
    });
    return clip;
  }

  @override
  Future<void> flip() async {
    if (!_state.canFlip || _state.phase != CaptureCameraPhase.ready) return;
    _lens = _lens == CaptureLens.front ? CaptureLens.back : CaptureLens.front;
    await open();
  }

  @override
  Future<void> close() => _serialized(() async {
    ++_generation;
    await _release();
  });

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    unawaited(
      _serialized(_release).catchError((Object error, StackTrace stack) {
        _report(error, stack, 'while closing the camera');
      }),
    );
    super.dispose();
  }

  Future<void> _release() async {
    final camera = _camera;
    _camera = null;
    if (camera == null) return;
    try {
      if (camera.value.isRecordingVideo) {
        // A discarded capture never leaves a clip behind.
        await deleteRecording(await camera.stopVideoRecording());
      }
    } on CameraException {
      // The camera is being torn down; disposal below still releases it.
    } finally {
      await camera.dispose();
    }
  }

  void _fail(CaptureCameraFailure failure) {
    _emit(_state.copyWith(phase: CaptureCameraPhase.failed, failure: failure));
  }

  void _report(Object error, StackTrace stack, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'capture',
        context: ErrorDescription(context),
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

  void _emit(CaptureCameraState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }
}

/// What a `CameraException` code means for the person.
CaptureCameraFailure cameraFailureFor(String code) => switch (code) {
  'CameraAccessDenied' ||
  'CameraAccessDeniedWithoutPrompt' ||
  'CameraAccessRestricted' => CaptureCameraFailure.cameraPermissionDenied,
  'AudioAccessDenied' ||
  'AudioAccessDeniedWithoutPrompt' ||
  'AudioAccessRestricted' => CaptureCameraFailure.microphonePermissionDenied,
  _ => CaptureCameraFailure.unavailable,
};
