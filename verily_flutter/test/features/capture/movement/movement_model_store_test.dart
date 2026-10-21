import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/features/capture/movement/movement_model_store_io.dart';
import 'package:verily_flutter/features/capture/movement/movement_models.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('verily-models-');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  MovementModelStore store(_Response Function() respond) => MovementModelStore(
    download: (_) async => respond(),
    directory: () async => root,
  );

  File cached(MovementModel model) =>
      File('${root.path}/movement_models/${model.sha256}');

  test('bytes that do not match the pinned digest are never kept', () async {
    final models = store(() => _Response(HttpStatus.ok, [List.filled(64, 7)]));

    await expectLater(
      models.load(MovementModel.pose),
      throwsA(
        isA<MovementModelException>().having(
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
        isA<MovementModelException>().having(
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
      throwsA(isA<MovementModelException>()),
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
      throwsA(isA<MovementModelException>()),
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
