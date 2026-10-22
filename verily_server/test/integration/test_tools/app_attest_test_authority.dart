import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_verifier.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'cbor_writer.dart';
import 'der_writer.dart';

/// The Apple team id test policies trust.
const testAppleTeamId = 'TEAMID1234';

/// The App ID test keys belong to unless a test says otherwise.
const testAppleAppId = '$testAppleTeamId.$verilyIosBundleId';

/// Verily's bundle under [testAppleTeamId].
AppAttestPolicy testAppAttestPolicy({
  AppAttestEnvironment environment = AppAttestEnvironment.production,
}) => AppAttestPolicy(teamId: testAppleTeamId, environment: environment);

/// A synthetic App Attest service shaped like Apple's: test root → "Test App
/// Attestation CA 1" → a credential certificate per key. Its root is a trust
/// anchor only where a test passes it.
///
/// Keys are deterministic, so attestations are reproducible across runs.
final class TestAppAttestAuthority {
  TestAppAttestAuthority({String name = 'apple'})
    : _rootKey = TestEcKey('$name-app-attest-root'),
      _caKey = TestEcKey('$name-app-attest-ca'),
      _name = name {
    root = X509Certificate.parse(_rootCertificate);
  }

  final TestEcKey _rootKey;
  final TestEcKey _caKey;
  final String _name;

  /// The anchor a verifier under test should trust.
  late final X509Certificate root;

  static final _validFrom = DateTime.utc(2026);
  static final _validUntil = DateTime.utc(2036);

  List<int> get _rootName =>
      derDistinguishedName([('2.5.4.3', 'Test App Attestation Root CA')]);
  List<int> get _caName =>
      derDistinguishedName([('2.5.4.3', 'Test App Attestation CA 1')]);

  late final List<int> _rootCertificate = derCertificate(
    serial: BigInt.one,
    issuer: _rootName,
    subject: _rootName,
    subjectKey: _rootKey,
    signer: _rootKey,
    notBefore: _validFrom,
    notAfter: _validUntil,
  );

  /// Generates and attests a key as an iPhone would, with every field
  /// Verily's policy reads under the test's control.
  TestAppAttestKey attest({
    required List<int> clientDataHash,
    String keySeed = 'install',
    String appId = testAppleAppId,
    AppAttestEnvironment environment = AppAttestEnvironment.production,
    int counter = 0,
    int? validationCategory = AppleValidationCategory.appStore,
    String? bundleVersion = '42',
    List<int>? credentialId,
    String? coseKeySeed,
    List<int>? nonce,
    bool nonceOnCa = false,
    DateTime? notAfter,
  }) {
    final key = TestEcKey('$_name-$keySeed');
    final keyId = sha256.convert(key.publicPoint).bytes;
    final cosePoint = TestEcKey(
      '$_name-${coseKeySeed ?? keySeed}',
    ).publicPoint;
    final authData = _authenticatorData(
      appId: appId,
      flags: 0x40,
      counter: counter,
      attestedCredential: [
        ...switch (environment) {
          AppAttestEnvironment.production => [
            ...ascii.encode('appattest'),
            ...List.filled(7, 0),
          ],
          AppAttestEnvironment.development => ascii.encode('appattestdevelop'),
        },
        0,
        32,
        ...credentialId ?? keyId,
        ...encodeCbor({
          1: 2,
          3: -7,
          -1: 1,
          -2: Uint8List.sublistView(cosePoint, 1, 33),
          -3: Uint8List.sublistView(cosePoint, 33),
        }),
      ],
      validationCategory: validationCategory,
      bundleVersion: bundleVersion,
    );
    final certifiedNonce =
        nonce ?? sha256.convert([...authData, ...clientDataHash]).bytes;
    final nonceExtension = derSequence([
      derExplicit(1, derOctets(certifiedNonce)),
    ]);
    final ca = derCertificate(
      serial: BigInt.two,
      issuer: _rootName,
      subject: _caName,
      subjectKey: _caKey,
      signer: _rootKey,
      notBefore: _validFrom,
      notAfter: _validUntil,
      extensions: {if (nonceOnCa) appAttestNonceExtensionOid: nonceExtension},
    );
    final credentialCertificate = derCertificate(
      serial: BigInt.from(3),
      issuer: _caName,
      subject: derDistinguishedName([
        ('2.5.4.3', sha256.convert(key.publicPoint).toString()),
      ]),
      subjectKey: key,
      signer: _caKey,
      notBefore: _validFrom,
      notAfter: notAfter ?? _validUntil,
      extensions: {appAttestNonceExtensionOid: nonceExtension},
    );
    return TestAppAttestKey._(
      key: key,
      keyId: base64Encode(keyId),
      attestationObject: encodeCbor({
        'fmt': 'apple-appattest',
        'attStmt': {
          'x5c': [
            Uint8List.fromList(credentialCertificate),
            Uint8List.fromList(ca),
          ],
          'receipt': Uint8List.fromList(utf8.encode('test receipt')),
        },
        'authData': authData,
      }),
    );
  }
}

/// A key a [TestAppAttestAuthority] attested.
final class TestAppAttestKey {
  TestAppAttestKey._({
    required this._key,
    required this.keyId,
    required this.attestationObject,
  });

  final TestEcKey _key;

  /// Apple's key identifier: SHA-256 of the public key, base64.
  final String keyId;
  final Uint8List attestationObject;

  /// `0x04 ‖ X ‖ Y`.
  Uint8List get publicKey => _key.publicPoint;

  /// The attestation object as the app sends it, base64.
  String get encodedAttestation => base64Encode(attestationObject);

  /// An assertion over [clientData] with [counter], as `generateAssertion`
  /// returns it: the key signs `SHA-256(authenticatorData ‖
  /// SHA-256(clientData))`.
  Uint8List assertion(
    List<int> clientData, {
    required int counter,
    String appId = testAppleAppId,
    int? validationCategory = AppleValidationCategory.appStore,
  }) {
    final authenticatorData = _authenticatorData(
      appId: appId,
      flags: 0xc0,
      counter: counter,
      validationCategory: validationCategory,
      bundleVersion: '42',
    );
    final nonce = sha256.convert([
      ...authenticatorData,
      ...sha256.convert(clientData).bytes,
    ]).bytes;
    return encodeCbor({
      'signature': Uint8List.fromList(_key.signDer(nonce)),
      'authenticatorData': authenticatorData,
    });
  }

  /// [assertion], base64, as the app sends it.
  String encodedAssertion(List<int> clientData, {required int counter}) =>
      base64Encode(assertion(clientData, counter: counter));
}

/// WebAuthn authenticator data the way App Attest writes it: relying party
/// hash, flags, big-endian counter, the attested credential when there is
/// one, and Apple's extension map.
Uint8List _authenticatorData({
  required String appId,
  required int flags,
  required int counter,
  List<int>? attestedCredential,
  int? validationCategory,
  String? bundleVersion,
}) {
  final counterBytes = ByteData(4)..setUint32(0, counter);
  return Uint8List.fromList([
    ...sha256.convert(utf8.encode(appId)).bytes,
    flags,
    ...counterBytes.buffer.asUint8List(),
    ...?attestedCredential,
    if (validationCategory != null || bundleVersion != null)
      ...encodeCbor({
        'apple_bundle_version_01': ?bundleVersion,
        if (validationCategory != null)
          'apple_validation_category_01': Uint8List.fromList(
            (ByteData(4)..setUint32(0, validationCategory, Endian.little))
                .buffer
                .asUint8List(),
          ),
      }),
  ]);
}
