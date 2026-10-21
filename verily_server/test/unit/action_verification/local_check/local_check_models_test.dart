import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_models.dart';
import 'package:verily_server/src/generated/protocol.dart';

void main() {
  final model = LocalCheckModel.forTask(LocalCheckTask.gesture);
  late Directory cache;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('verily-model-cache-test-');
  });

  tearDown(() async {
    await cache.delete(recursive: true);
  });

  PinnedLocalCheckModelStore store(MockClientHandler handler) =>
      PinnedLocalCheckModelStore(
        cacheDirectory: cache,
        clientFactory: () => MockClient(handler),
      );

  group('Given the pinned model store', () {
    test('when bytes differ from the pin then they are never matched', () {
      expect(matchesPinnedModel(model, Uint8List(model.byteLength)), isFalse);
      expect(matchesPinnedModel(model, Uint8List(10)), isFalse);
    });

    test('when the download does not match the pin then it is refused and '
        'nothing is cached', () async {
      final requested = <Uri>[];
      final source = store((request) async {
        requested.add(request.url);
        return http.Response.bytes(Uint8List(1024), 200);
      });

      await expectLater(
        source.load(model),
        throwsA(
          isA<LocalCheckUnavailableException>().having(
            (error) => error.code,
            'code',
            LocalCheckUnavailableCode.modelDigestMismatch,
          ),
        ),
      );
      expect(requested.single, Uri.parse(model.url));
      expect(cache.listSync(), isEmpty);
    });

    test('when the download is larger than the pin then it is cut off and '
        'refused', () async {
      final source = store(
        (_) async => http.Response.bytes(Uint8List(model.byteLength + 1), 200),
      );

      await expectLater(
        source.load(model),
        throwsA(isA<LocalCheckUnavailableException>()),
      );
      expect(cache.listSync(), isEmpty);
    });

    test(
      'when the host answers with an error then the download failed',
      () async {
        final source = store((_) async => http.Response('gone', 404));

        await expectLater(
          source.load(model),
          throwsA(
            isA<LocalCheckUnavailableException>().having(
              (error) => error.code,
              'code',
              LocalCheckUnavailableCode.modelDownloadFailed,
            ),
          ),
        );
      },
    );

    test('when the network fails then the download failed', () async {
      final source = store((_) async => throw const SocketException('offline'));

      await expectLater(
        source.load(model),
        throwsA(
          isA<LocalCheckUnavailableException>().having(
            (error) => error.code,
            'code',
            LocalCheckUnavailableCode.modelDownloadFailed,
          ),
        ),
      );
    });

    test('when a cached file was tampered with then it is discarded before '
        'any use', () async {
      final cached = File('${cache.path}/${model.sha256}')
        ..writeAsBytesSync(Uint8List(model.byteLength));
      var downloads = 0;
      final source = store((_) async {
        downloads += 1;
        return http.Response.bytes(Uint8List(16), 200);
      });

      await expectLater(
        source.load(model),
        throwsA(isA<LocalCheckUnavailableException>()),
      );
      expect(cached.existsSync(), isFalse);
      expect(downloads, 1);
    });
  });
}
