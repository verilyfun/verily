import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// A microphone recorder for audio proof.
///
/// The interface keeps the audio screen testable without a microphone.
abstract interface class CaptureRecorder {
  /// Asks for microphone access when needed; true when it is granted.
  Future<bool> requestPermission();

  /// Starts recording AAC audio in an MP4 container (`.m4a`).
  Future<void> start();

  /// The input level from 0 (silence) to 1 (loud), while recording.
  Stream<double> levels();

  /// Stops and returns the recording, or null when nothing was recorded.
  Future<XFile?> stop();

  /// Stops and discards the recording.
  Future<void> cancel();

  Future<void> dispose();
}

typedef CaptureRecorderFactory = CaptureRecorder Function();

/// The production recorder, backed by `package:record`.
final class RecordCaptureRecorder implements CaptureRecorder {
  RecordCaptureRecorder() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;

  /// The level a whisper reaches, in dBFS; quieter reads as silence.
  static const _floorDb = -50.0;

  @override
  Future<bool> requestPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final path = kIsWeb
        // The browser recorder keeps the clip in memory and ignores the path.
        ? 'verily-audio.m4a'
        : '${(await getTemporaryDirectory()).path}/'
              'verily-audio-${DateTime.now().microsecondsSinceEpoch}.m4a';
    // The default encoder is AAC-LC, which Android writes as `.m4a`
    // (`audio/mp4`); mono is enough for a voice.
    await _recorder.start(const RecordConfig(numChannels: 1), path: path);
  }

  @override
  Stream<double> levels() => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 120))
      .map(
        (amplitude) =>
            ((amplitude.current - _floorDb) / -_floorDb).clamp(0.0, 1.0),
      );

  @override
  Future<XFile?> stop() async {
    final path = await _recorder.stop();
    if (path == null || path.isEmpty) return null;
    return XFile(path, mimeType: 'audio/mp4');
  }

  @override
  Future<void> cancel() => _recorder.cancel();

  /// Discards a recording still in progress, so leaving never strands a
  /// clip in temporary storage, then releases the microphone.
  @override
  Future<void> dispose() async {
    if (await _recorder.isRecording() || await _recorder.isPaused()) {
      await _recorder.cancel();
    }
    await _recorder.dispose();
  }
}
