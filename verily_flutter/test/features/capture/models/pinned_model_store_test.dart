import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mp_core/mp_core.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/features/capture/models/pinned_model.dart';
import 'package:verily_flutter/features/capture/models/pinned_model_store_io.dart';
import 'package:verily_flutter/features/capture/movement/movement_models.dart';

/// A tiny model pinned to bytes the test controls.
final class _TestModel implements PinnedModel {
  _TestModel(this.bytes, this.sha256);

  static Future<_TestModel> of(List<int> bytes) async =>
      _TestModel(bytes, await sha256Stream(Stream.value(bytes)));

  final List<int> bytes;

  @override
  final String sha256;

  @override
  int get byteLength => bytes.length;

  @override
  String get url => 'https://storage.googleapis.com/mediapipe-models/test.task';
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('verily-models-');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  PinnedModelStore store(_Response Function() respond) => PinnedModelStore(
    download: (_) async => respond(),
    directory: () async => root,
  );

  File cached(PinnedModel model) =>
      File('${root.path}/pinned_models/${model.sha256}');

  test(
    'a matching download is kept and served without fetching again',
    () async {
      final model = await _TestModel.of(List.generate(32, (index) => index));
      var downloads = 0;
      final models = store(() {
        downloads++;
        return _Response(HttpStatus.ok, [model.bytes]);
      });

      final first = await models.load(model);
      final second = await models.load(model);

      expect(downloads, 1);
      expect(cached(model).readAsBytesSync(), model.bytes);
      expect((first as ModelAssetPath).path, cached(model).path);
      expect((second as ModelAssetPath).path, cached(model).path);
    },
  );

  test('a cached file is checked on every load', () async {
    final model = await _TestModel.of(
      List.generate(32, (index) => index * 2),
    );
    var downloads = 0;
    final models = store(() {
      downloads++;
      return _Response(HttpStatus.ok, [model.bytes]);
    });
    await models.load(model);

    // Same length, different bytes: only the digest can tell.
    await cached(model).writeAsBytes(List.filled(32, 9));
    await models.load(model);

    expect(downloads, 2);
    expect(cached(model).readAsBytesSync(), model.bytes);
  });

  test('bytes that do not match the pinned digest are never kept', () async {
    final models = store(() => _Response(HttpStatus.ok, [List.filled(64, 7)]));

    await expectLater(
      models.load(MovementModel.pose),
      throwsA(
        isA<PinnedModelException>().having(
          (error) => error.reason,
          'reason',
          'digest mismatch',
        ),
      ),
    );
    expect(cached(MovementModel.pose).existsSync(), isFalse);
    expect(
      File('${cached(MovementModel.pose).path}.partial').existsSync(),
      isFalse,
    );
  });

  test('a download longer than the pinned size is cut off', () async {
    final chunk = List.filled(1024 * 1024, 1);
    final models = store(
      () => _Response(HttpStatus.ok, List.filled(6, chunk)),
    );

    await expectLater(
      models.load(MovementModel.pose),
      throwsA(
        isA<PinnedModelException>().having(
          (error) => error.reason,
          'reason',
          'download is too large',
        ),
      ),
    );
    expect(cached(MovementModel.pose).existsSync(), isFalse);
  });

  test('a failed request is reported, not cached', () async {
    final models = store(() => _Response(HttpStatus.notFound, const []));

    await expectLater(
      models.load(MovementModel.objects),
      throwsA(isA<PinnedModelException>()),
    );
    expect(cached(MovementModel.objects).existsSync(), isFalse);
  });

  test('a tampered cache is discarded and fetched again', () async {
    final file = cached(MovementModel.pose);
    await file.create(recursive: true);
    await file.writeAsBytes(List.filled(16, 3));
    var downloads = 0;
    final models = store(() {
      downloads++;
      return _Response(HttpStatus.ok, [List.filled(16, 3)]);
    });

    await expectLater(
      models.load(MovementModel.pose),
      throwsA(isA<PinnedModelException>()),
    );
    expect(downloads, 1);
    expect(file.existsSync(), isFalse);
  });
}

/// A canned HTTP response body.
final class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.statusCode, this._chunks);

  @override
  final int statusCode;
  final List<List<int>> _chunks;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.fromIterable(_chunks).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
