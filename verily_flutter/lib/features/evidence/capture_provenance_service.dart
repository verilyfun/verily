import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A device signature over one capture's manifest, with the attestation of
/// the key that made it.
@immutable
class CaptureProvenanceProof {
  const CaptureProvenanceProof({
    required this.manifest,
    required this.signature,
    required this.certificateChain,
  });

  /// The signed manifest bytes, base64.
  final String manifest;

  /// The P-256 signature in IEEE P1363 form, base64.
  final String signature;

  /// The key's Android Key Attestation chain: base64 DER, leaf first. The
  /// server reads the key, and where it lives, only from here.
  final List<String> certificateChain;
}

/// Fresh, hardware-attested capture keys: one per capture window.
///
/// A key is generated when the server opens a window, before anything is
/// recorded, with that window's attestation challenge. Where device signing
/// is unavailable (iOS, web, or a device without the key store) the store
/// says so, and the server decides whether that is acceptable
/// (`VERILY_CAPTURE_SIGNATURE_MODE`).
abstract interface class CaptureKeyStore {
  /// Generates the key for [captureId], attesting [attestationChallenge].
  /// Returns false when this device cannot.
  Future<bool> prepare({
    required String captureId,
    required List<int> attestationChallenge,
  });

  /// Signs [manifest] with the key prepared for [captureId]. Returns null
  /// when there is no such key.
  Future<CaptureProvenanceProof?> sign({
    required String captureId,
    required List<int> manifest,
  });
}

/// Keys in the Android Keystore, in StrongBox when the device has it and
/// the Trusted Execution Environment otherwise.
class AndroidCaptureKeyStore implements CaptureKeyStore {
  const AndroidCaptureKeyStore();

  static const _channel = MethodChannel('app.verily/capture_provenance');

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> prepare({
    required String captureId,
    required List<int> attestationChallenge,
  }) async {
    if (!_supported) return false;
    try {
      await _channel.invokeMethod<void>('prepareCaptureKey', {
        'captureId': captureId,
        'attestationChallenge': Uint8List.fromList(attestationChallenge),
      });
      return true;
    } on PlatformException catch (error) {
      debugPrint('Capture key unavailable: ${error.code}');
      return false;
    }
  }

  @override
  Future<CaptureProvenanceProof?> sign({
    required String captureId,
    required List<int> manifest,
  }) async {
    if (!_supported) return null;
    try {
      final response = await _channel.invokeMethod<Map<Object?, Object?>>(
        'signCaptureManifest',
        {'captureId': captureId, 'manifest': Uint8List.fromList(manifest)},
      );
      final signature = response?['signature'];
      final chain = response?['certificateChain'];
      if (signature is! Uint8List ||
          signature.isEmpty ||
          chain is! List<Object?> ||
          chain.isEmpty ||
          chain.any((certificate) => certificate is! Uint8List)) {
        debugPrint('Capture signing returned an incomplete response.');
        return null;
      }
      return CaptureProvenanceProof(
        manifest: base64Encode(manifest),
        signature: base64Encode(signature),
        certificateChain: [
          for (final certificate in chain.cast<Uint8List>())
            base64Encode(certificate),
        ],
      );
    } on PlatformException catch (error) {
      debugPrint('Capture signing unavailable: ${error.code}');
      return null;
    }
  }
}
