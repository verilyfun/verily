import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';

/// A local check could not run. [code] is stable and safe to persist.
final class LocalCheckUnavailableException implements Exception {
  const LocalCheckUnavailableException(this.code);

  /// One of the codes in `LocalCheckUnavailableCode`.
  final String code;

  @override
  String toString() => 'LocalCheckUnavailableException($code)';
}

/// Stable reasons a replay could not run.
abstract final class LocalCheckUnavailableCode {
  static const runtimeUnavailable = 'mp_runtime_unavailable';
  static const modelDownloadFailed = 'mp_model_download_failed';
  static const modelDigestMismatch = 'mp_model_digest_mismatch';
  static const evidenceUnreadable = 'mp_evidence_unreadable';
  static const evidenceDigestMismatch = 'mp_evidence_digest_mismatch';
  static const decoderUnavailable = 'mp_decoder_unavailable';
  static const mediaDecodeFailed = 'mp_media_decode_failed';
  static const replayFailed = 'mp_replay_failed';
}

/// Supplies the verified bytes of a pinned model; injectable for tests.
// ignore: one_member_abstracts
abstract interface class LocalCheckModelSource {
  /// The model file, verified against its pinned byte length and SHA-256 on
  /// this call. Throws [LocalCheckUnavailableException] when the model
  /// cannot be fetched or does not match.
  Future<File> load(LocalCheckModel model);
}

/// Whether [bytes] are exactly the pinned [model].
bool matchesPinnedModel(LocalCheckModel model, List<int> bytes) =>
    bytes.length == model.byteLength &&
    sha256.convert(bytes).toString() == model.sha256;

/// Downloads each pinned model once into [cacheDirectory] and verifies the
/// byte length and SHA-256 on every load. A cached file that no longer
/// matches is deleted and fetched again; a download that does not match is
/// refused and never written under the model's name.
class PinnedLocalCheckModelStore implements LocalCheckModelSource {
  PinnedLocalCheckModelStore({
    required this.cacheDirectory,
    http.Client Function()? clientFactory,
    this.downloadTimeout = const Duration(seconds: 60),
  }) : _clientFactory = clientFactory ?? http.Client.new;

  /// The default cache: `VERILY_LOCAL_CHECK_MODEL_CACHE`, or a directory in
  /// the system temp folder.
  factory PinnedLocalCheckModelStore.fromEnvironment(
    Map<String, String> environment,
  ) {
    final configured = environment['VERILY_LOCAL_CHECK_MODEL_CACHE']?.trim();
    return PinnedLocalCheckModelStore(
      cacheDirectory: Directory(
        configured == null || configured.isEmpty
            ? '${Directory.systemTemp.path}/verily-local-check-models'
            : configured,
      ),
    );
  }

  final Directory cacheDirectory;
  final http.Client Function() _clientFactory;
  final Duration downloadTimeout;

  @override
  Future<File> load(LocalCheckModel model) async {
    final file = File('${cacheDirectory.path}/${model.sha256}');
    if (file.existsSync()) {
      if (matchesPinnedModel(model, await file.readAsBytes())) return file;
      await file.delete();
    }
    final bytes = await _download(model);
    if (!matchesPinnedModel(model, bytes)) {
      throw const LocalCheckUnavailableException(
        LocalCheckUnavailableCode.modelDigestMismatch,
      );
    }
    await cacheDirectory.create(recursive: true);
    // Write beside the target, then rename, so a reader never sees a
    // partial file under the pinned name.
    final partial = File('${file.path}.$pid.partial');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
    return file;
  }

  Future<Uint8List> _download(LocalCheckModel model) async {
    final client = _clientFactory();
    try {
      final request = http.Request('GET', Uri.parse(model.url))
        ..followRedirects = false;
      final response = await client.send(request).timeout(downloadTimeout);
      if (response.statusCode != 200) {
        throw const LocalCheckUnavailableException(
          LocalCheckUnavailableCode.modelDownloadFailed,
        );
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.stream.timeout(downloadTimeout)) {
        if (builder.length + chunk.length > model.byteLength) {
          throw const LocalCheckUnavailableException(
            LocalCheckUnavailableCode.modelDigestMismatch,
          );
        }
        builder.add(chunk);
      }
      return builder.takeBytes();
    } on LocalCheckUnavailableException {
      rethrow;
    } on Object {
      throw const LocalCheckUnavailableException(
        LocalCheckUnavailableCode.modelDownloadFailed,
      );
    } finally {
      client.close();
    }
  }
}
