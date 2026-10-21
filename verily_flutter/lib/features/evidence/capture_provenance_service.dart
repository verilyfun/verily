import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:verily_evidence/verily_evidence.dart';

/// A device signature over one capture's manifest.
@immutable
class CaptureProvenanceProof {
  const CaptureProvenanceProof({
    required this.manifest,
    required this.signature,
    required this.publicKey,
    required this.keyId,
    required this.keyStorage,
  });

  /// The signed manifest bytes, base64.
  final String manifest;

  /// The P-256 signature in IEEE P1363 form, base64.
  final String signature;

  /// The 65-byte uncompressed public key, base64.
  final String publicKey;
  final String keyId;

  /// Where the key lives: `strongBox`, `trustedEnvironment`, or `software`.
  final String keyStorage;
}

/// Signs one capture's manifest with the device's hardware-backed key.
///
/// Returns null where device signing is unavailable (iOS, web, or a device
/// without the key store); the server decides whether that is acceptable
/// (`VERILY_CAPTURE_SIGNATURE_MODE`).
typedef CaptureSigner = Future<CaptureProvenanceProof?> Function({
  required String attemptId,
  required String requirementId,
  required String requestHash,
  required String evidenceBindingHash,
});

const _channel = MethodChannel('app.verily/capture_provenance');

/// Signs with the Android Keystore key (`verily_capture_provenance_v1`),
/// StrongBox when the device has it.
Future<CaptureProvenanceProof?> signWithAndroidKeystore({
  required String attemptId,
  required String requirementId,
  required String requestHash,
  required String evidenceBindingHash,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  final manifest = captureProvenanceManifest(
    attemptId: attemptId,
    requirementId: requirementId,
    requestHash: requestHash,
    evidenceBindingHash: evidenceBindingHash,
  );
  try {
    final response = await _channel.invokeMethod<Map<Object?, Object?>>(
      'signManifest',
      {'manifest': Uint8List.fromList(manifest)},
    );
    final signature = response?['signature'];
    final publicKey = response?['publicKey'];
    final keyStorage = response?['keyStorage'];
    if (signature is! Uint8List ||
        publicKey is! Uint8List ||
        keyStorage is! String ||
        signature.isEmpty ||
        publicKey.isEmpty) {
      debugPrint('Capture signing returned an incomplete response.');
      return null;
    }
    return CaptureProvenanceProof(
      manifest: base64Encode(manifest),
      signature: base64Encode(signature),
      publicKey: base64Encode(publicKey),
      keyId: capturePublicKeyId(publicKey),
      keyStorage: keyStorage,
    );
  } on PlatformException catch (error) {
    debugPrint('Capture signing unavailable: ${error.code}');
    return null;
  }
}
