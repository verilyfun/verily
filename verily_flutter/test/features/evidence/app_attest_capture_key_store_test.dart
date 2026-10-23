import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/features/evidence/capture_provenance_service.dart';

const _channel = MethodChannel('app.verily/capture_provenance');
final _account = UuidValue.fromString('00000000-0000-4000-8000-0000000000a1');
final _challengeId = UuidValue.fromString(
  '00000000-0000-4000-8000-0000000000b1',
);
// 32 bytes, unpadded base64url, as the server issues it.
const _challenge = 'AQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyA';
final String _keyId = base64Encode(List.filled(32, 7));
final _attestation = Uint8List.fromList(utf8.encode('attestation object'));
final _assertion = Uint8List.fromList(utf8.encode('assertion object'));
final _deviceToken = Uint8List.fromList(utf8.encode('device-token'));

/// `DCAppAttestService` and the Keychain, as the Swift side exposes them.
final class _FakeAppAttest {
  bool supported = true;
  final keychain = <String, ({String keyId, bool registered})>{};
  final calls = <String>[];
  final hashes = <String, List<int>>{};
  PlatformException? attestFailure;
  PlatformException? assertionFailure;
  PlatformException? deviceCheckFailure;

  Future<Object?> handle(MethodCall call) async {
    calls.add(call.method);
    final arguments = (call.arguments as Map<Object?, Object?>?) ?? const {};
    final account = arguments['account'] as String?;
    switch (call.method) {
      case 'generateDeviceCheckToken':
        if (deviceCheckFailure case final failure?) throw failure;
        return _deviceToken;
      case 'appAttestSupported':
        return supported;
      case 'readAppAttestKey':
        final stored = keychain[account];
        return stored == null
            ? null
            : {'keyId': stored.keyId, 'registered': stored.registered};
      case 'generateAppAttestKey':
        keychain[account!] = (keyId: _keyId, registered: false);
        return _keyId;
      case 'attestAppAttestKey':
        hashes['attest'] = arguments['clientDataHash']! as Uint8List;
        if (attestFailure case final failure?) throw failure;
        return _attestation;
      case 'markAppAttestKeyRegistered':
        keychain[account!] = (
          keyId: arguments['keyId']! as String,
          registered: true,
        );
        return null;
      case 'generateAppAttestAssertion':
        hashes['assert'] = arguments['clientDataHash']! as Uint8List;
        if (assertionFailure case final failure?) throw failure;
        return _assertion;
      case 'discardAppAttestKey':
        keychain.remove(account);
        return null;
    }
    throw MissingPluginException(call.method);
  }
}

final class _Registrar implements AppAttestRegistrar {
  final registered = <({UuidValue challengeId, String keyId, String object})>[];
  Exception? failure;

  @override
  Future<AppAttestChallengeView> beginRegistration() async =>
      AppAttestChallengeView(
        id: _challengeId,
        challenge: _challenge,
        expiresAt: DateTime.utc(2026, 10, 22, 0, 5),
      );

  @override
  Future<void> registerKey({
    required UuidValue challengeId,
    required String keyId,
    required String attestationObject,
  }) async {
    if (failure case final error?) throw error;
    registered.add((
      challengeId: challengeId,
      keyId: keyId,
      object: attestationObject,
    ));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeAppAttest platform;
  late _Registrar registrar;
  UuidValue? account;

  AppAttestCaptureKeyStore store() => AppAttestCaptureKeyStore(
    registrar: registrar,
    currentAccount: () => account,
  );

  Future<bool> prepare() =>
      store().prepare(captureId: 'window', attestationChallenge: const [1]);

  setUp(() {
    platform = _FakeAppAttest();
    registrar = _Registrar();
    account = _account;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, platform.handle);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('the first window makes a key, attests it against a server challenge, '
      'and registers it', () async {
    expect(await prepare(), isTrue);

    expect(platform.calls, [
      'appAttestSupported',
      'readAppAttestKey',
      'generateAppAttestKey',
      'attestAppAttestKey',
      'markAppAttestKeyRegistered',
    ]);
    expect(
      platform.hashes['attest'],
      appAttestRegistrationClientDataHash(_challenge),
    );
    expect(registrar.registered.single, (
      challengeId: _challengeId,
      keyId: _keyId,
      object: base64Encode(_attestation),
    ));
    expect(platform.keychain[_account.toString()]!.registered, isTrue);
  });

  test(
    'a registered key signs the manifest digest with an assertion',
    () async {
      await prepare();
      final manifest = utf8.encode('verily-capture-manifest-v1\nproof');

      final proof = await store().sign(captureId: 'window', manifest: manifest);

      expect(
        platform.hashes['assert'],
        appAttestAssertionClientDataHash(
          appAttestDeviceClientData(manifest, base64Encode(_deviceToken)),
        ),
      );
      expect(proof!.manifest, base64Encode(manifest));
      expect(proof.signature, base64Encode(_assertion));
      expect(proof.appAttestKeyId, _keyId);
      expect(proof.deviceCheckToken, base64Encode(_deviceToken));
      expect(proof.certificateChain, isNull);
    },
  );

  test('later windows reuse the registered key without asking the '
      'server', () async {
    await prepare();
    platform.calls.clear();

    expect(await prepare(), isTrue);

    expect(platform.calls, ['appAttestSupported', 'readAppAttestKey']);
    expect(registrar.registered, hasLength(1));
  });

  test('DeviceCheck failure cannot produce a capture assertion', () async {
    await prepare();
    platform.deviceCheckFailure = PlatformException(code: 'unavailable');
    expect(
      await store().sign(captureId: 'window', manifest: const [1]),
      isNull,
    );
    expect(platform.hashes['assert'], isNull);
    expect(platform.keychain[_account.toString()]!.registered, isTrue);
  });

  test('a phone without App Attest cannot sign', () async {
    platform.supported = false;

    expect(await prepare(), isFalse);
    expect(
      await store().sign(captureId: 'window', manifest: const [1]),
      isNull,
    );
    expect(registrar.registered, isEmpty);
  });

  test('no one signed in means no key', () async {
    account = null;

    expect(await prepare(), isFalse);
    expect(platform.calls, isEmpty);
  });

  test("when Apple's server is unavailable the key is kept for a "
      'retry', () async {
    platform.attestFailure = PlatformException(code: 'server_unavailable');

    expect(await prepare(), isFalse);
    expect(platform.keychain[_account.toString()]!.keyId, _keyId);

    platform.attestFailure = null;
    expect(await prepare(), isTrue);
    expect(
      platform.calls.where((call) => call == 'generateAppAttestKey'),
      hasLength(1),
    );
  });

  test('any other attestation failure discards the key', () async {
    platform.attestFailure = PlatformException(code: 'app_attest_failed');

    expect(await prepare(), isFalse);
    expect(platform.keychain, isEmpty);
  });

  test('a Keychain failure keeps the key', () async {
    platform.attestFailure = PlatformException(code: 'keychain_failed');

    expect(await prepare(), isFalse);
    expect(platform.keychain[_account.toString()]!.keyId, _keyId);
  });

  test('a key the server rejects is discarded', () async {
    registrar.failure = AppAttestException(
      problem: AppAttestProblem.keyRejected,
      message: 'Rejected.',
    );

    expect(await prepare(), isFalse);
    expect(platform.keychain, isEmpty);
  });

  test('when the server cannot be reached the key is kept', () async {
    registrar.failure = const _Offline();

    expect(await prepare(), isFalse);
    expect(platform.keychain[_account.toString()]!.registered, isFalse);
  });

  test('a key the phone no longer has is discarded when signing', () async {
    await prepare();
    platform.assertionFailure = PlatformException(code: 'invalid_key');

    expect(
      await store().sign(captureId: 'window', manifest: const [1]),
      isNull,
    );
    expect(platform.keychain, isEmpty);
  });
}

/// A transport failure, as the Serverpod client raises when offline.
final class _Offline implements Exception {
  const _Offline();
}
