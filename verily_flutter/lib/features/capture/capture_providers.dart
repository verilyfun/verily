import 'package:cross_file/cross_file.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/features/capture/audio/capture_recorder.dart';
import 'package:verily_flutter/features/capture/camera/capture_camera.dart';
import 'package:verily_flutter/features/capture/review/captured_media_preview.dart';
import 'package:verily_flutter/features/capture/review/media_duration_probe.dart';
import 'package:verily_flutter/features/evidence/captured_media.dart';
import 'package:verily_flutter/features/evidence/motion_capture_service.dart';

/// Opens the camera for one capture.
final captureCameraFactoryProvider = Provider<CaptureCameraFactory>(
  (ref) =>
      ({required recordAudio, required initialLens, required analyseFrames}) =>
          PluginCaptureCamera(
            recordAudio: recordAudio,
            analyseFrames: analyseFrames,
            lens: initialLens,
          ),
);

/// Opens the microphone for one capture.
final captureRecorderFactoryProvider = Provider<CaptureRecorderFactory>(
  (ref) => RecordCaptureRecorder.new,
);

/// Reads a recording's length from its container.
typedef MediaDurationProbe = Future<Duration> Function(XFile file);

final mediaDurationProbeProvider = Provider<MediaDurationProbe>(
  (ref) => probeMediaDuration,
);

/// Draws a capture for review: the photo, or a player for a recording.
typedef CapturePreviewBuilder = Widget Function(
  BuildContext context,
  CapturedMedia media,
);

final capturePreviewBuilderProvider = Provider<CapturePreviewBuilder>(
  (ref) =>
      (context, media) => CapturedMediaPreview(media: media),
);

/// Records a phone-motion trace for a `motion` requirement.
final motionCaptureCallbackProvider = Provider<MotionCaptureCallback>(
  (ref) => MotionCaptureService().capture,
);

/// Opens this app's page in the system settings, where camera and
/// microphone access can be turned back on.
final openAppSettingsProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await Geolocator.openAppSettings();
  },
);
