import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:verily_server/src/action_verification/local_check/local_check_models.dart';

/// One decoded RGB frame: tightly packed 8-bit sRGB, row-major.
final class DecodedFrame {
  const DecodedFrame({
    required this.width,
    required this.height,
    required this.rgb,
  });

  final int width;
  final int height;
  final Uint8List rgb;
}

/// Decoded mono audio at [sampleRateHz].
final class DecodedAudio {
  const DecodedAudio({required this.sampleRateHz, required this.samples});

  final int sampleRateHz;
  final Float32List samples;
}

/// Turns pinned evidence bytes into model input.
abstract interface class LocalCheckMediaDecoder {
  /// Up to [maxFrames] frames: one for a photo, evenly spaced for a video.
  Future<List<DecodedFrame>> frames(
    Uint8List media, {
    required String mimeType,
    required int maxFrames,
  });

  /// 16 kHz mono float PCM, at most [maxSeconds] long.
  Future<DecodedAudio> audio(
    Uint8List media, {
    required String mimeType,
    required int maxSeconds,
  });
}

/// The longest side frames are scaled to before inference.
const localCheckMaxFrameSide = 640;

/// Sample rate the audio classifier receives.
const localCheckAudioSampleRateHz = 16000;

/// Times (seconds) of [maxFrames] samples at the middle of equal segments of
/// a [durationSeconds] recording, so the first and last moments are covered
/// without landing on a black lead-in frame.
List<double> frameSampleTimes({
  required double durationSeconds,
  required int maxFrames,
}) {
  if (maxFrames < 1) throw ArgumentError.value(maxFrames, 'maxFrames');
  if (!durationSeconds.isFinite || durationSeconds <= 0) return const [0];
  final segment = durationSeconds / maxFrames;
  return [
    for (var index = 0; index < maxFrames; index += 1) segment * (index + 0.5),
  ];
}

/// The scaled frame size: the longer side at most [localCheckMaxFrameSide],
/// aspect kept, both sides even (as the RGB scaler requires).
({int width, int height}) scaledFrameSize(int width, int height) {
  if (width < 1 || height < 1) throw ArgumentError('Invalid frame size.');
  final scale = math.min(1, localCheckMaxFrameSide / math.max(width, height));
  int even(num value) => math.max(2, (value * scale).round() & ~1);
  return (width: even(width), height: even(height));
}

/// Decodes with ffmpeg and ffprobe as separate processes: argument lists
/// (never a shell), bounded time and output, on a copy in a private
/// temporary directory that is always removed.
class FfmpegLocalCheckMediaDecoder implements LocalCheckMediaDecoder {
  const FfmpegLocalCheckMediaDecoder({
    this.ffmpeg = 'ffmpeg',
    this.ffprobe = 'ffprobe',
    this.timeout = const Duration(seconds: 20),
  });

  /// `VERILY_FFMPEG_PATH` and `VERILY_FFPROBE_PATH`, else the `PATH`.
  factory FfmpegLocalCheckMediaDecoder.fromEnvironment(
    Map<String, String> environment,
  ) {
    String pick(String name, String fallback) {
      final value = environment[name]?.trim();
      return value == null || value.isEmpty ? fallback : value;
    }

    return FfmpegLocalCheckMediaDecoder(
      ffmpeg: pick('VERILY_FFMPEG_PATH', 'ffmpeg'),
      ffprobe: pick('VERILY_FFPROBE_PATH', 'ffprobe'),
    );
  }

  final String ffmpeg;
  final String ffprobe;
  final Duration timeout;

  @override
  Future<List<DecodedFrame>> frames(
    Uint8List media, {
    required String mimeType,
    required int maxFrames,
  }) {
    return _withInput(media, (input) async {
      final probe = await _probe(input);
      final size = scaledFrameSize(probe.width, probe.height);
      final frameBytes = size.width * size.height * 3;
      final times = mimeType.startsWith('image/')
          ? const <double>[0]
          : frameSampleTimes(
              durationSeconds: probe.durationSeconds,
              maxFrames: maxFrames,
            );
      final frames = <DecodedFrame>[];
      for (final time in times) {
        final rgb = await _run(ffmpeg, [
          '-nostdin',
          '-v',
          'error',
          if (time > 0) ...['-ss', time.toStringAsFixed(3)],
          '-i',
          input.path,
          '-frames:v',
          '1',
          '-vf',
          'scale=${size.width}:${size.height}',
          '-f',
          'rawvideo',
          '-pix_fmt',
          'rgb24',
          'pipe:1',
        ], maxOutputBytes: frameBytes);
        // A seek past the last decodable frame yields nothing; skip it.
        if (rgb.length == frameBytes) {
          frames.add(
            DecodedFrame(width: size.width, height: size.height, rgb: rgb),
          );
        }
      }
      if (frames.isEmpty) {
        throw const LocalCheckUnavailableException(
          LocalCheckUnavailableCode.mediaDecodeFailed,
        );
      }
      return frames;
    });
  }

  @override
  Future<DecodedAudio> audio(
    Uint8List media, {
    required String mimeType,
    required int maxSeconds,
  }) {
    return _withInput(media, (input) async {
      final pcm = await _run(ffmpeg, [
        '-nostdin',
        '-v',
        'error',
        '-i',
        input.path,
        '-t',
        '$maxSeconds',
        '-vn',
        '-ac',
        '1',
        '-ar',
        '$localCheckAudioSampleRateHz',
        '-f',
        'f32le',
        'pipe:1',
      ], maxOutputBytes: maxSeconds * localCheckAudioSampleRateHz * 4);
      if (pcm.length < 4) {
        throw const LocalCheckUnavailableException(
          LocalCheckUnavailableCode.mediaDecodeFailed,
        );
      }
      final copy = Uint8List.fromList(
        pcm.sublist(0, pcm.length - pcm.length % 4),
      );
      return DecodedAudio(
        sampleRateHz: localCheckAudioSampleRateHz,
        samples: copy.buffer.asFloat32List(),
      );
    });
  }

  Future<T> _withInput<T>(
    Uint8List media,
    Future<T> Function(File input) use,
  ) async {
    // createTemp uses mkdtemp, so only this process's user can read it.
    final directory = await Directory.systemTemp.createTemp('verily-replay-');
    try {
      final input = File('${directory.path}/evidence');
      await input.writeAsBytes(media, flush: true);
      return await use(input);
    } finally {
      await directory.delete(recursive: true);
    }
  }

  Future<({int width, int height, double durationSeconds})> _probe(
    File input,
  ) async {
    final output = await _run(ffprobe, [
      '-v',
      'error',
      '-select_streams',
      'v:0',
      '-show_entries',
      'stream=width,height:format=duration',
      '-of',
      'json',
      input.path,
    ], maxOutputBytes: 64 * 1024);
    try {
      final decoded = jsonDecode(utf8.decode(output)) as Map<String, Object?>;
      final stream =
          (decoded['streams']! as List<Object?>).first! as Map<String, Object?>;
      final format = decoded['format'] as Map<String, Object?>?;
      return (
        width: stream['width']! as int,
        height: stream['height']! as int,
        durationSeconds: double.tryParse('${format?['duration'] ?? ''}') ?? 0,
      );
    } on Object {
      throw const LocalCheckUnavailableException(
        LocalCheckUnavailableCode.mediaDecodeFailed,
      );
    }
  }

  Future<Uint8List> _run(
    String executable,
    List<String> arguments, {
    required int maxOutputBytes,
  }) async {
    final Process process;
    try {
      process = await Process.start(executable, arguments);
    } on ProcessException {
      throw const LocalCheckUnavailableException(
        LocalCheckUnavailableCode.decoderUnavailable,
      );
    }
    final stdoutBytes = BytesBuilder(copy: false);
    var overflow = false;
    final stdoutDone = process.stdout.listen((chunk) {
      if (stdoutBytes.length + chunk.length > maxOutputBytes) {
        overflow = true;
        process.kill();
        return;
      }
      stdoutBytes.add(chunk);
    }).asFuture<void>();
    // Diagnostics are discarded: they can echo file metadata.
    final stderrDone = process.stderr.drain<void>();
    final int exitCode;
    try {
      exitCode = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      throw const LocalCheckUnavailableException(
        LocalCheckUnavailableCode.mediaDecodeFailed,
      );
    }
    await Future.wait([stdoutDone, stderrDone]);
    if (overflow || exitCode != 0) {
      throw const LocalCheckUnavailableException(
        LocalCheckUnavailableCode.mediaDecodeFailed,
      );
    }
    return stdoutBytes.takeBytes();
  }
}
