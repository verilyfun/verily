import 'dart:convert';
import 'dart:typed_data';

import 'package:verily_server/src/action_verification/key_attestation/key_description.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';

import 'der_writer.dart';

/// The release signing certificate digest test policies trust.
final String testSigningCertificateDigest = 'ab' * 32;

/// A synthetic attestation authority shaped like Google's remote key
/// provisioning: test root → "Droid CA2" → per-device attestation key →
/// capture key. Its root is a trust anchor only where a test passes it.
///
/// Keys are deterministic, so chains are reproducible across runs.
final class TestAttestationAuthority {
  TestAttestationAuthority({String name = 'test'})
    : _rootKey = TestEcKey('$name-root'),
      _intermediateKey = TestEcKey('$name-intermediate'),
      _attestationKey = TestEcKey('$name-attestation'),
      _name = name {
    root = X509Certificate.parse(_rootCertificate);
  }

  final TestEcKey _rootKey;
  final TestEcKey _intermediateKey;
  final TestEcKey _attestationKey;
  final String _name;

  /// The anchor a verifier under test should trust.
  late final X509Certificate root;

  static final _validFrom = DateTime.utc(2026);
  static final _validUntil = DateTime.utc(2027, 12, 31);

  List<int> get _rootName =>
      derDistinguishedName([('2.5.4.3', 'Test Attestation Root')]);
  List<int> get _intermediateName => derDistinguishedName([
    ('2.5.4.10', 'Google LLC'),
    ('2.5.4.3', 'Droid CA2'),
  ]);

  late final List<int> _rootCertificate = _certificate(
    serial: BigInt.one,
    issuer: _rootName,
    subject: _rootName,
    subjectKey: _rootKey,
    signer: _rootKey,
  );

  /// Issues a capture key and its chain, leaf first, with every property
  /// Verily's policy reads under the test's control.
  TestAttestedKey issue({
    required List<int> challenge,
    String keySeed = 'capture',
    KeySecurityLevel securityLevel = KeySecurityLevel.trustedEnvironment,
    String chainSecurityClaim = 'TEE',
    VerifiedBootState bootState = VerifiedBootState.verified,
    bool deviceLocked = true,
    String packageName = 'fun.verily.app',
    String? signingCertificateDigest,
    int osPatchLevel = 202609,
    int algorithm = KeyMintTag.algorithmEc,
    int ecCurve = KeyMintTag.ecCurveP256,
    int origin = KeyMintTag.originGenerated,
    Set<int> purposes = const {KeyMintTag.purposeSign},
    bool attestationExtensionOnAttestationKey = false,
    DateTime? attestationNotAfter,
    BigInt? attestationSerial,
  }) {
    final leafKey = TestEcKey('$_name-$keySeed');
    final attestationName = derDistinguishedName([
      ('2.5.4.10', chainSecurityClaim),
      ('2.5.4.3', 'device-$_name'),
    ]);
    final description = _keyDescription(
      challenge: challenge,
      securityLevel: securityLevel,
      bootState: bootState,
      deviceLocked: deviceLocked,
      packageName: packageName,
      signingCertificateDigest:
          signingCertificateDigest ?? testSigningCertificateDigest,
      osPatchLevel: osPatchLevel,
      algorithm: algorithm,
      ecCurve: ecCurve,
      origin: origin,
      purposes: purposes,
    );
    final intermediate = _certificate(
      serial: BigInt.two,
      issuer: _rootName,
      subject: _intermediateName,
      subjectKey: _intermediateKey,
      signer: _rootKey,
    );
    final attestation = _certificate(
      serial: attestationSerial ?? BigInt.from(3),
      issuer: _intermediateName,
      subject: attestationName,
      subjectKey: _attestationKey,
      signer: _intermediateKey,
      notAfter: attestationNotAfter,
      attestationExtension: attestationExtensionOnAttestationKey
          ? description
          : null,
    );
    final leaf = _certificate(
      serial: BigInt.one,
      issuer: attestationName,
      subject: derDistinguishedName([('2.5.4.3', 'Android Keystore Key')]),
      subjectKey: leafKey,
      signer: _attestationKey,
      notBefore: DateTime.utc(1970),
      notAfter: DateTime.utc(2048),
      attestationExtension: description,
    );
    return TestAttestedKey._(
      chain: [
        for (final der in [leaf, attestation, intermediate, _rootCertificate])
          Uint8List.fromList(der),
      ],
      key: leafKey,
      forgeLeaf: (challenge) => _certificate(
        serial: BigInt.one,
        issuer: derDistinguishedName([('2.5.4.3', 'Android Keystore Key')]),
        subject: derDistinguishedName([('2.5.4.3', 'Forged Key')]),
        subjectKey: TestEcKey('$_name-forged'),
        signer: leafKey,
        attestationExtension: _keyDescription(
          challenge: challenge,
          securityLevel: KeySecurityLevel.strongBox,
          bootState: VerifiedBootState.verified,
          deviceLocked: true,
          packageName: packageName,
          signingCertificateDigest:
              signingCertificateDigest ?? testSigningCertificateDigest,
          osPatchLevel: osPatchLevel,
          algorithm: KeyMintTag.algorithmEc,
          ecCurve: KeyMintTag.ecCurveP256,
          origin: KeyMintTag.originGenerated,
          purposes: const {KeyMintTag.purposeSign},
        ),
      ),
    );
  }

  List<int> _certificate({
    required BigInt serial,
    required List<int> issuer,
    required List<int> subject,
    required TestEcKey subjectKey,
    required TestEcKey signer,
    DateTime? notBefore,
    DateTime? notAfter,
    List<int>? attestationExtension,
  }) => derCertificate(
    serial: serial,
    issuer: issuer,
    subject: subject,
    subjectKey: subjectKey,
    signer: signer,
    notBefore: notBefore ?? _validFrom,
    notAfter: notAfter ?? _validUntil,
    extensions: {keyAttestationExtensionOid: ?attestationExtension},
  );
}

/// A capture key whose chain a [TestAttestationAuthority] issued.
final class TestAttestedKey {
  TestAttestedKey._({
    required this.chain,
    required this._key,
    required this._forgeLeaf,
  });

  /// DER certificates, leaf first.
  final List<Uint8List> chain;
  final TestEcKey _key;
  final List<int> Function(List<int> challenge) _forgeLeaf;

  /// The chain with one more certificate below the leaf: a key this key
  /// certified itself, claiming [challenge] in a description it wrote.
  List<Uint8List> extendedWithForgedLeaf(List<int> challenge) => [
    Uint8List.fromList(_forgeLeaf(challenge)),
    ...chain,
  ];

  /// The chain as the app sends it: base64 DER, leaf first.
  List<String> get encodedChain => [for (final der in chain) base64Encode(der)];

  /// `0x04 ‖ X ‖ Y`.
  Uint8List get publicKey => _key.publicPoint;

  /// Signs [message] the way the app does: SHA-256 ECDSA, IEEE P1363
  /// `r ‖ s`, base64.
  String signP1363(List<int> message) => base64Encode(_key.signP1363(message));
}

List<int> _keyDescription({
  required List<int> challenge,
  required KeySecurityLevel securityLevel,
  required VerifiedBootState bootState,
  required bool deviceLocked,
  required String packageName,
  required String signingCertificateDigest,
  required int osPatchLevel,
  required int algorithm,
  required int ecCurve,
  required int origin,
  required Set<int> purposes,
}) {
  final applicationId = derSequence([
    derSet([
      derSequence([
        derOctets(utf8.encode(packageName)),
        derInteger(BigInt.one),
      ]),
    ]),
    derSet([derOctets(_hexBytes(signingCertificateDigest))]),
  ]);
  return derSequence([
    derInteger(BigInt.from(300)),
    derEnumerated(securityLevel.value),
    derInteger(BigInt.from(300)),
    derEnumerated(securityLevel.value),
    derOctets(challenge),
    derOctets(const []),
    derSequence([
      derExplicit(
        KeyMintTag.attestationApplicationId,
        derOctets(applicationId),
      ),
    ]),
    derSequence([
      derExplicit(
        KeyMintTag.purpose,
        derSet([
          for (final purpose in purposes) derInteger(BigInt.from(purpose)),
        ]),
      ),
      derExplicit(KeyMintTag.algorithm, derInteger(BigInt.from(algorithm))),
      derExplicit(KeyMintTag.keySize, derInteger(BigInt.from(256))),
      derExplicit(KeyMintTag.ecCurve, derInteger(BigInt.from(ecCurve))),
      derExplicit(KeyMintTag.origin, derInteger(BigInt.from(origin))),
      derExplicit(
        KeyMintTag.rootOfTrust,
        derSequence([
          derOctets(List.filled(32, 7)),
          derBoolean(value: deviceLocked),
          derEnumerated(bootState.value),
          derOctets(List.filled(32, 9)),
        ]),
      ),
      derExplicit(KeyMintTag.osVersion, derInteger(BigInt.from(160000))),
      derExplicit(
        KeyMintTag.osPatchLevel,
        derInteger(BigInt.from(osPatchLevel)),
      ),
    ]),
  ]);
}

List<int> _hexBytes(String hex) => [
  for (var index = 0; index < hex.length; index += 2)
    int.parse(hex.substring(index, index + 2), radix: 16),
];
