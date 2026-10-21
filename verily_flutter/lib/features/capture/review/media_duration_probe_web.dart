import 'package:cross_file/cross_file.dart';
import 'package:video_player/video_player.dart';

/// Reads a recording's length from the browser's blob URL.
Future<Duration> probeMediaDuration(XFile file) async {
  final controller = VideoPlayerController.networkUrl(Uri.parse(file.path));
  try {
    await controller.initialize();
    return controller.value.duration;
  } finally {
    await controller.dispose();
  }
}

/// A player for a capture held by the browser.
VideoPlayerController capturedMediaController(XFile file) =>
    VideoPlayerController.networkUrl(Uri.parse(file.path));
