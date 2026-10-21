import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_media.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_models.dart';

/// Generates media with ffmpeg's built-in sources, so no fixture is stored.
Future<Uint8List?> _generate(List<String> arguments, String extension) async {
  final directory = await Directory.systemTemp.createTemp('verily-gen-');
  try {
    final output = '${directory.path}/out.$extension';
    final result = await Process.run('ffmpeg', [
      '-nostdin',
      '-v',
      'error',
      ...arguments,
      output,
    ]);
    if (result.exitCode != 0) return null;
    return File(output).readAsBytesSync();
  } on ProcessException {
    return null;
  } finally {
    await directory.delete(recursive: true);
  }
}

bool _hasFfmpeg() {
  try {
    return Process.runSync('ffmpeg', ['-version']).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

void main() {
  group('Given the frame sampling plan', () {
    test(
      'when a recording is sampled then frames are evenly spaced inside it',
      () {
        final times = frameSampleTimes(durationSeconds: 3, maxFrames: 30);

        expect(times, hasLength(30));
        expect(times.first, closeTo(0.05, 1e-9));
        expect(times.last, closeTo(2.95, 1e-9));
        for (var index = 1; index < times.length; index += 1) {
          expect(times[index] - times[index - 1], closeTo(0.1, 1e-9));
        }
      },
    );

    test(
      'when the duration is unknown then one frame at the start is used',
      () {
        expect(frameSampleTimes(durationSeconds: 0, maxFrames: 30), [0]);
        expect(frameSampleTimes(durationSeconds: double.nan, maxFrames: 5), [
          0,
        ]);
      },
    );

    test('when no frames are asked for then the plan is refused', () {
      expect(
        () => frameSampleTimes(durationSeconds: 3, maxFrames: 0),
        throwsArgumentError,
      );
    });

    test(
      'when frames are scaled then the long side fits and sides stay even',
      () {
        expect(scaledFrameSize(1920, 1080), (width: 640, height: 360));
        expect(scaledFrameSize(1080, 1920), (width: 360, height: 640));
        expect(scaledFrameSize(419, 419), (width: 418, height: 418));
        expect(scaledFrameSize(1, 1), (width: 2, height: 2));
        expect(() => scaledFrameSize(0, 10), throwsArgumentError);
      },
    );
  });

  group('Given the ffmpeg decoder', () {
    final skip = _hasFfmpeg() ? null : 'ffmpeg is not installed on this host';
    const decoder = FfmpegLocalCheckMediaDecoder();

    test(
      'when the decoder binary is missing then the decoder is unavailable',
      () async {
        const missing = FfmpegLocalCheckMediaDecoder(
          ffmpeg: '/nonexistent/ffmpeg',
          ffprobe: '/nonexistent/ffprobe',
        );

        await expectLater(
          missing.frames(Uint8List(8), mimeType: 'image/png', maxFrames: 1),
          throwsA(
            isA<LocalCheckUnavailableException>().having(
              (error) => error.code,
              'code',
              LocalCheckUnavailableCode.decoderUnavailable,
            ),
          ),
        );
      },
    );

    test('when a photo is decoded then one RGB frame comes back', () async {
      final png = await _generate([
        '-f',
        'lavfi',
        '-i',
        'color=c=red:s=64x48',
        '-frames:v',
        '1',
      ], 'png');
      final frames = await decoder.frames(
        png!,
        mimeType: 'image/png',
        maxFrames: 30,
      );

      final frame = frames.single;
      expect((frame.width, frame.height), (64, 48));
      expect(frame.rgb, hasLength(64 * 48 * 3));
      // Pure red, within codec rounding.
      expect(frame.rgb[0], greaterThan(240));
      expect(frame.rgb[1], lessThan(15));
      expect(frame.rgb[2], lessThan(15));
    }, skip: skip);

    test('when a video is decoded then the planned frames come back', () async {
      final mp4 = await _generate([
        '-f',
        'lavfi',
        '-i',
        'testsrc=size=320x240:rate=30:duration=2',
        '-pix_fmt',
        'yuv420p',
      ], 'mp4');
      final frames = await decoder.frames(
        mp4!,
        mimeType: 'video/mp4',
        maxFrames: 10,
      );

      expect(frames.length, inInclusiveRange(9, 10));
      expect(frames.every((frame) => frame.width == 320), isTrue);
    }, skip: skip);

    test('when audio is decoded then 16 kHz mono samples come back', () async {
      final m4a = await _generate([
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440:duration=1',
      ], 'm4a');
      final audio = await decoder.audio(
        m4a!,
        mimeType: 'audio/mp4',
        maxSeconds: 300,
      );

      expect(audio.sampleRateHz, 16000);
      expect(audio.samples.length, inInclusiveRange(15000, 17500));
      expect(audio.samples.any((sample) => sample.abs() > 0.1), isTrue);
    }, skip: skip);

    test(
      'when audio is longer than allowed then it is cut to the limit',
      () async {
        final m4a = await _generate([
          '-f',
          'lavfi',
          '-i',
          'sine=frequency=440:duration=3',
        ], 'm4a');
        final audio = await decoder.audio(
          m4a!,
          mimeType: 'audio/mp4',
          maxSeconds: 1,
        );

        expect(audio.samples.length, lessThanOrEqualTo(16000));
      },
      skip: skip,
    );

    test(
      'when the bytes are not media then decoding fails with a code',
      () async {
        await expectLater(
          decoder.frames(
            Uint8List.fromList(List.filled(512, 7)),
            mimeType: 'image/jpeg',
            maxFrames: 1,
          ),
          throwsA(
            isA<LocalCheckUnavailableException>().having(
              (error) => error.code,
              'code',
              LocalCheckUnavailableCode.mediaDecodeFailed,
            ),
          ),
        );
      },
      skip: skip,
    );
  });
}
