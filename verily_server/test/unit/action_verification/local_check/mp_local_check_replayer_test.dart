@Timeout(Duration(minutes: 5))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_models.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_replay.dart';
import 'package:verily_server/src/action_verification/local_check/mp_local_check_replayer.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Public MediaPipe sample media, pinned by SHA-256 and fetched at test time
/// into the ignored `.dart_tool` cache. Nothing binary is committed.
enum _Fixture {
  thumbsUp(
    'https://storage.googleapis.com/mediapipe-tasks/gesture_recognizer/'
        'thumbs_up.jpg',
    '2aee0e3a69ba5f0d3287597e61d265f4f3ac2a44ccec198dddd2639b0c8ef7ba',
  ),
  catAndDog(
    'https://storage.googleapis.com/mediapipe-tasks/object_detector/'
        'cat_and_dog.jpg',
    'cfa90c34bb93021165e48bd22cfc20dbbb0440ff638a54878939bf30d362e824',
  ),
  speech(
    'https://storage.googleapis.com/mediapipe-assets/'
        'speech_16000_hz_mono.wav',
    '71caf50b8757d6ab9cad5eae4d36669d3c20c225a51660afd7fe0dc44cdb74f6',
  );

  const _Fixture(this.url, this.sha256);

  final String url;
  final String sha256;
}

final Directory _cache = Directory('.dart_tool/verily_test_cache/local_check');

Future<Uint8List> _fixture(_Fixture fixture) async {
  final file = File('${_cache.path}/${fixture.sha256}');
  if (file.existsSync()) {
    final cached = file.readAsBytesSync();
    if (sha256.convert(cached).toString() == fixture.sha256) return cached;
  }
  final response = await http
      .get(Uri.parse(fixture.url))
      .timeout(const Duration(seconds: 30));
  final bytes = response.bodyBytes;
  if (response.statusCode != 200 ||
      sha256.convert(bytes).toString() != fixture.sha256) {
    throw StateError('Fixture ${fixture.name} did not match its pin.');
  }
  _cache.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
  return bytes;
}

/// Encodes a short video from a still with ffmpeg, so video sampling runs on
/// real decoded frames without a stored clip.
Future<Uint8List> _videoFrom(Uint8List jpeg) async {
  final directory = await Directory.systemTemp.createTemp('verily-video-');
  try {
    final input = File('${directory.path}/in.jpg')..writeAsBytesSync(jpeg);
    final output = '${directory.path}/out.mp4';
    final result = await Process.run('ffmpeg', [
      '-nostdin',
      '-v',
      'error',
      '-loop',
      '1',
      '-i',
      input.path,
      '-t',
      '2',
      '-r',
      '15',
      '-pix_fmt',
      'yuv420p',
      output,
    ]);
    if (result.exitCode != 0) throw StateError('ffmpeg could not encode.');
    return File(output).readAsBytesSync();
  } finally {
    await directory.delete(recursive: true);
  }
}

ActionLocalCheck _check(
  LocalCheckTask task,
  String label, {
  double minScore = 0.5,
  int minFrames = 1,
}) => ActionLocalCheck(
  task: task,
  label: label,
  minScore: minScore,
  minFrames: minFrames,
);

void main() {
  // The MP native runtime ships for macOS arm64 and Linux x64; the pinned
  // models and fixtures are fetched once. Anything missing skips with why.
  String? skipReason;
  final fixtures = <_Fixture, Uint8List>{};
  late MpLocalCheckReplayer replayer;

  setUpAll(() async {
    final supported =
        (Platform.isMacOS || Platform.isLinux) &&
        !Platform.version.contains('ia32');
    if (!supported) {
      skipReason = 'The MP runtime is not published for this host.';
      return;
    }
    try {
      if (Process.runSync('ffmpeg', ['-version']).exitCode != 0) {
        skipReason = 'ffmpeg is not installed on this host.';
        return;
      }
    } on ProcessException {
      skipReason = 'ffmpeg is not installed on this host.';
      return;
    }
    try {
      for (final fixture in _Fixture.values) {
        fixtures[fixture] = await _fixture(fixture);
      }
    } on Object catch (error) {
      skipReason = 'Pinned fixtures are unavailable (offline?): $error';
      return;
    }
    replayer = MpLocalCheckReplayer(
      models: PinnedLocalCheckModelStore(cacheDirectory: _cache),
    );
  });

  Future<LocalCheckReplay?> replay(
    ActionLocalCheck check,
    Uint8List media,
    String mimeType,
  ) async {
    if (skipReason != null) {
      markTestSkipped(skipReason!);
      return null;
    }
    final result = await replayer.replay(
      check: check,
      model: check.task.model,
      media: media,
      mimeType: mimeType,
    );
    if (result case LocalCheckReplayUnavailable(:final code)
        when code == LocalCheckUnavailableCode.modelDownloadFailed) {
      markTestSkipped('The pinned model could not be downloaded (offline?).');
      return null;
    }
    return result;
  }

  group('Given the real MediaPipe runtime on this host', () {
    test('when a thumbs-up photo is replayed then Thumb_Up matches', () async {
      final result = await replay(
        _check(LocalCheckTask.gesture, 'Thumb_Up', minScore: 0.6),
        fixtures[_Fixture.thumbsUp] ?? Uint8List(0),
        'image/jpeg',
      );
      if (result == null) return;

      expect(result, isA<LocalCheckReplayScores>());
      final scores = result as LocalCheckReplayScores;
      expect(scores.scores, hasLength(1));
      expect(scores.best, greaterThan(0.6));
      printOnFailure('Thumb_Up score: ${scores.best}');
    });

    test(
      'when the same photo is asked for Victory then it does not match',
      () async {
        final result = await replay(
          _check(LocalCheckTask.gesture, 'Victory', minScore: 0.6),
          fixtures[_Fixture.thumbsUp] ?? Uint8List(0),
          'image/jpeg',
        );
        if (result == null) return;

        final scores = result as LocalCheckReplayScores;
        expect(scores.matching(0.6), 0);
      },
    );

    test('when a video of the gesture is replayed then most sampled frames '
        'match', () async {
      if (skipReason != null) {
        markTestSkipped(skipReason!);
        return;
      }
      final video = await _videoFrom(fixtures[_Fixture.thumbsUp]!);
      final result = await replay(
        _check(LocalCheckTask.gesture, 'Thumb_Up', minScore: 0.6),
        video,
        'video/mp4',
      );
      if (result == null) return;

      final scores = result as LocalCheckReplayScores;
      // A sample that seeks past the last decodable frame is skipped.
      expect(
        scores.scores.length,
        inInclusiveRange(
          LocalCheckBounds.maxFrames - 2,
          LocalCheckBounds.maxFrames,
        ),
      );
      expect(scores.matching(0.6), greaterThanOrEqualTo(20));
    });

    test('when a cat-and-dog photo is replayed then dog and cat are found '
        'and a bicycle is not', () async {
      final photo = fixtures[_Fixture.catAndDog] ?? Uint8List(0);
      final dog = await replay(
        _check(LocalCheckTask.object, 'dog'),
        photo,
        'image/jpeg',
      );
      if (dog == null) return;
      final cat = await replay(
        _check(LocalCheckTask.object, 'cat'),
        photo,
        'image/jpeg',
      );
      final bicycle = await replay(
        _check(LocalCheckTask.object, 'bicycle'),
        photo,
        'image/jpeg',
      );

      expect((dog as LocalCheckReplayScores).best, greaterThan(0.7));
      expect((cat! as LocalCheckReplayScores).best, greaterThan(0.6));
      expect((bicycle! as LocalCheckReplayScores).best, lessThan(0.3));
    });

    test(
      'when a speech recording is replayed then YAMNet scores each window',
      () async {
        final recording = fixtures[_Fixture.speech] ?? Uint8List(0);
        // Speech is not offered to creators; it proves the audio path runs.
        final speech = await replay(
          _check(LocalCheckTask.sound, 'Speech'),
          recording,
          'audio/wav',
        );
        if (speech == null) return;
        final clapping = await replay(
          _check(LocalCheckTask.sound, 'Clapping'),
          recording,
          'audio/wav',
        );

        final windows = speech as LocalCheckReplayScores;
        expect(windows.scores.length, greaterThanOrEqualTo(3));
        expect(windows.best, greaterThan(0.8));
        expect((clapping! as LocalCheckReplayScores).best, lessThan(0.2));
      },
    );

    test('when the bytes are not decodable then the replay is unavailable, '
        'never a verdict', () async {
      final result = await replay(
        _check(LocalCheckTask.gesture, 'Thumb_Up'),
        Uint8List.fromList(List.filled(256, 3)),
        'image/jpeg',
      );
      if (result == null) return;

      expect(
        result,
        isA<LocalCheckReplayUnavailable>().having(
          (unavailable) => unavailable.code,
          'code',
          LocalCheckUnavailableCode.mediaDecodeFailed,
        ),
      );
    });
  });

  group('Given a model source that refuses the pinned model', () {
    test(
      'when replaying then the replay is unavailable with its code',
      () async {
        final refusing = MpLocalCheckReplayer(models: _RefusingModels());

        final result = await refusing.replay(
          check: _check(LocalCheckTask.gesture, 'Thumb_Up'),
          model: LocalCheckTask.gesture.model,
          media: Uint8List(8),
          mimeType: 'image/jpeg',
        );

        expect(
          result,
          isA<LocalCheckReplayUnavailable>().having(
            (unavailable) => unavailable.code,
            'code',
            LocalCheckUnavailableCode.modelDigestMismatch,
          ),
        );
      },
    );

    test('when the model does not run the check task then it is a bug', () {
      expect(
        () => MpLocalCheckReplayer(models: _RefusingModels()).replay(
          check: _check(LocalCheckTask.sound, 'Clapping'),
          model: LocalCheckTask.gesture.model,
          media: Uint8List(8),
          mimeType: 'audio/mp4',
        ),
        throwsArgumentError,
      );
    });
  });
}

final class _RefusingModels implements LocalCheckModelSource {
  @override
  Future<File> load(LocalCheckModel model) async =>
      throw const LocalCheckUnavailableException(
        LocalCheckUnavailableCode.modelDigestMismatch,
      );
}
