import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

/// A device signature over one capture's manifest, with what names the key
/// that made it: an Android key's attestation chain, or an iPhone's
/// registered App Attest key.
@immutable
class CaptureProvenanceProof {
  /// An Android Keystore signature and the key's attestation chain.
  const CaptureProvenanceProof.keystore({
    required this.manifest,
    required this.signature,
    required List<String> this.certificateChain,
  }) : appAttestKeyId = null;

  /// An App Attest assertion by the account's registered key.
  const CaptureProvenanceProof.appAttest({
    required this.manifest,
    required String assertion,
    required String this.appAttestKeyId,
  }) : signature = assertion,
       certificateChain = null;

  /// The signed manifest bytes, base64.
  final String manifest;

  /// The P-256 signature in IEEE P1363 form, or the App Attest assertion
  /// object; base64 either way.
  final String signature;

  /// The Android key's attestation chain: base64 DER, leaf first. The
  /// server reads the key, and where it lives, only from here.
  final List<String>? certificateChain;

  /// The App Attest key identifier, as `generateKey` returned it.
  final String? appAttestKeyId;
}

/// Device keys that sign each capture's manifest.
///
/// A key is prepared when the server opens a capture window, before
/// anything is recorded. Where device signing is unavailable (web, a device
/// without a key store, an iPhone without App Attest) the store says so, and
/// the server decides whether that is acceptable
/// (`VERILY_CAPTURE_SIGNATURE_MODE`).
abstract interface class CaptureKeyStore {
  /// Gets the key for [captureId] ready, attesting [attestationChallenge]
  /// where the platform makes a key per window. Returns false when this
  /// device cannot sign; it never throws.
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

/// A device that cannot sign captures, such as the web app.
final class UnavailableCaptureKeyStore implements CaptureKeyStore {
  const UnavailableCaptureKeyStore();

  @override
  Future<bool> prepare({
    required String captureId,
    required List<int> attestationChallenge,
  }) async => false;

  @override
  Future<CaptureProvenanceProof?> sign({
    required String captureId,
    required List<int> manifest,
  }) async => null;
}

const _provenanceChannel = MethodChannel('app.verily/capture_provenance');

/// Fresh, hardware-attested capture keys in the Android Keystore: one per
/// capture window, in StrongBox when the device has it and the Trusted
/// Execution Environment otherwise.
class AndroidCaptureKeyStore implements CaptureKeyStore {
  const AndroidCaptureKeyStore();

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> prepare({
    required String captureId,
    required List<int> attestationChallenge,
  }) async {
    if (!_supported) return false;
    try {
      await _provenanceChannel.invokeMethod<void>('prepareCaptureKey', {
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
      final response = await _provenanceChannel
          .invokeMethod<Map<Object?, Object?>>(
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
      return CaptureProvenanceProof.keystore(
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

/// Registers an iPhone's App Attest key with the server.
abstract interface class AppAttestRegistrar {
  Future<AppAttestChallengeView> beginRegistration();

  Future<void> registerKey({
    required UuidValue challengeId,
    required String keyId,
    required String attestationObject,
  });
}

class ServerpodAppAttestRegistrar implements AppAttestRegistrar {
  const ServerpodAppAttestRegistrar(this._client);

  final Client _client;

  @override
  Future<AppAttestChallengeView> beginRegistration() =>
      _client.appAttest.beginRegistration();

  @override
  Future<void> registerKey({
    required UuidValue challengeId,
    required String keyId,
    required String attestationObject,
  }) => _client.appAttest.registerKey(
    challengeId: challengeId,
    keyId: keyId,
    attestationObject: attestationObject,
  );
}

/// An iPhone's App Attest key, kept in the Secure Enclave: one per Verily
/// account on this install, as Apple's guidance asks, registered once and
/// then reused for every capture.
///
/// The key is not per window: each assertion signs the window's manifest,
/// which commits to the window's challenge and the evidence fingerprint, and
/// carries a counter the server never accepts twice. The platform side keeps
/// each account's key id in the Keychain.
class AppAttestCaptureKeyStore implements CaptureKeyStore {
  const AppAttestCaptureKeyStore({
    required this._registrar,
    required this._currentAccount,
    this._channel = _provenanceChannel,
  });

  final AppAttestRegistrar _registrar;

  /// The signed-in account, which owns the key.
  final UuidValue? Function() _currentAccount;
  final MethodChannel _channel;

  @override
  Future<bool> prepare({
    required String captureId,
    required List<int> attestationChallenge,
  }) async {
    final account = _currentAccount()?.toString();
    if (account == null) return false;
    try {
      if (await _channel.invokeMethod<bool>('appAttestSupported') != true) {
        return false;
      }
      final stored = await _read(account);
      if (stored?.registered ?? false) return true;
      final keyId =
          stored?.keyId ??
          await _channel.invokeMethod<String>('generateAppAttestKey', {
            'account': account,
          });
      if (keyId == null || keyId.isEmpty) return false;
      final challenge = await _registrar.beginRegistration();
      final attestation = await _channel.invokeMethod<Uint8List>(
        'attestAppAttestKey',
        {
          'keyId': keyId,
          'clientDataHash': Uint8List.fromList(
            appAttestRegistrationClientDataHash(challenge.challenge),
          ),
        },
      );
      if (attestation == null || attestation.isEmpty) return false;
      await _registrar.registerKey(
        challengeId: challenge.id,
        keyId: keyId,
        attestationObject: base64Encode(attestation),
      );
      await _channel.invokeMethod<void>('markAppAttestKeyRegistered', {
        'account': account,
        'keyId': keyId,
      });
      return true;
    } on PlatformException catch (error) {
      debugPrint('App Attest unavailable: ${error.code}');
      // Apple: retry later with the same key only when its server was
      // unavailable; after any other App Attest failure, start again with a
      // new key. A Keychain failure says nothing about the key.
      if (!_keepsKey.contains(error.code)) await _discard(account);
      return false;
    } on AppAttestException catch (error) {
      debugPrint('App Attest registration refused: ${error.problem.name}');
      if (error.problem == AppAttestProblem.keyRejected) {
        await _discard(account);
      }
      return false;
    } on Exception catch (error) {
      // Offline, or the server failed: keep the key for the next window.
      // The server decides whether an unsigned capture is acceptable, and
      // the error must not escape: nothing awaits this until the capture is
      // sent.
      debugPrint('App Attest registration failed: ${error.runtimeType}');
      return false;
    }
  }

  @override
  Future<CaptureProvenanceProof?> sign({
    required String captureId,
    required List<int> manifest,
  }) async {
    final account = _currentAccount()?.toString();
    if (account == null) return null;
    try {
      final stored = await _read(account);
      if (stored == null || !stored.registered) return null;
      final assertion = await _channel.invokeMethod<Uint8List>(
        'generateAppAttestAssertion',
        {
          'keyId': stored.keyId,
          'clientDataHash': Uint8List.fromList(
            appAttestAssertionClientDataHash(manifest),
          ),
        },
      );
      if (assertion == null || assertion.isEmpty) return null;
      return CaptureProvenanceProof.appAttest(
        manifest: base64Encode(manifest),
        assertion: base64Encode(assertion),
        appAttestKeyId: stored.keyId,
      );
    } on PlatformException catch (error) {
      debugPrint('App Attest signing unavailable: ${error.code}');
      // The key is gone (a restore or migration); the next window makes
      // and registers a new one.
      if (error.code == 'invalid_key') await _discard(account);
      return null;
    }
  }

  static const _keepsKey = {'server_unavailable', 'keychain_failed'};

  Future<({String keyId, bool registered})?> _read(String account) async {
    final stored = await _channel.invokeMethod<Map<Object?, Object?>>(
      'readAppAttestKey',
      {'account': account},
    );
    return switch (stored) {
      {'keyId': final String keyId, 'registered': final bool registered}
          when keyId.isNotEmpty =>
        (keyId: keyId, registered: registered),
      _ => null,
    };
  }

  Future<void> _discard(String account) async {
    try {
      await _channel.invokeMethod<void>('discardAppAttestKey', {
        'account': account,
      });
    } on PlatformException catch (error) {
      debugPrint('App Attest key could not be discarded: ${error.code}');
    }
  }
}
