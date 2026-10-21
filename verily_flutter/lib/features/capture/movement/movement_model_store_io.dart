import 'dart:io';

import 'package:mp_core/mp_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/features/capture/movement/movement_models.dart';

/// Opens a GET for [url] and returns the response; replaced in tests.
typedef ModelDownload = Future<HttpClientResponse> Function(Uri url);

/// Downloads pinned models once and serves them from app storage.
///
/// Files are named by digest, written to a partial file, verified, and only
/// then renamed into place. A cached file is re-verified on every load, so a
/// truncated or tampered cache is replaced rather than handed to MediaPipe.
class MovementModelStore {
  MovementModelStore({
    ModelDownload? download,
    Future<Directory> Function()? directory,
  }) : _download = download ?? _httpGet,
       _directory = directory ?? getApplicationSupportDirectory;

  final ModelDownload _download;
  final Future<Directory> Function() _directory;

  static Future<HttpClientResponse> _httpGet(Uri url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      return await request.close();
    } finally {
      // Lets the in-flight response finish, then frees the client.
      client.close();
    }
  }

  Future<ModelAsset> load(MovementModel model) async {
    final root = Directory('${(await _directory()).path}/movement_models');
    final file = File('${root.path}/${model.sha256}');
    if (file.existsSync()) {
      if (await _matches(file, model)) return ModelAsset.path(file.path);
      await file.delete();
    }

    await root.create(recursive: true);
    final partial = File('${file.path}.partial');
    try {
      final response = await _download(Uri.parse(model.url));
      if (response.statusCode != HttpStatus.ok) {
        throw MovementModelException(model, 'HTTP ${response.statusCode}');
      }
      final sink = partial.openWrite();
      var received = 0;
      try {
        await for (final chunk in response) {
          received += chunk.length;
          if (received > model.byteLength) {
            throw MovementModelException(model, 'download is too large');
          }
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      if (!await _matches(partial, model)) {
        throw MovementModelException(model, 'digest mismatch');
      }
      await partial.rename(file.path);
      return ModelAsset.path(file.path);
    } finally {
      if (partial.existsSync()) await partial.delete();
    }
  }

  static Future<bool> _matches(File file, MovementModel model) async {
    return await file.length() == model.byteLength &&
        await sha256Stream(file.openRead()) == model.sha256;
  }
}
