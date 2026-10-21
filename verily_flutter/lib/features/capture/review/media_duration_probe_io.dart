import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:video_player/video_player.dart';

/// Reads a recording's length from its container, for video and audio.
Future<Duration> probeMediaDuration(XFile file) async {
  final controller = VideoPlayerController.file(File(file.path));
  try {
    await controller.initialize();
    return controller.value.duration;
  } finally {
    await controller.dispose();
  }
}

/// A player for a capture still on this device.
VideoPlayerController capturedMediaController(XFile file) =>
    VideoPlayerController.file(File(file.path));
