import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:verily_server/src/action_verification/key_attestation/key_description.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';

/// The release signing certificate digest test policies trust.
final String testSigningCertificateDigest = 'ab' * 32;

/// A synthetic attestation authority shaped like Google's remote key
/// provisioning: test root → "Droid CA2" → per-device attestation key →
/// capture key. Its root is a trust anchor only where a test passes it.
///
/// Keys are deterministic, so chains are reproducible across runs.
final class TestAttestationAuthority {
  TestAttestationAuthority({String name = 'test'})
    : _rootKey = _TestKey('$name-root'),
      _intermediateKey = _TestKey('$name-intermediate'),
      _attestationKey = _TestKey('$name-attestation'),
      _name = name {
    root = X509Certificate.parse(_rootCertificate);
  }

  final _TestKey _rootKey;
  final _TestKey _intermediateKey;
  final _TestKey _attestationKey;
  final String _name;

  /// The anchor a verifier under test should trust.
  late final X509Certificate root;

  static final _validFrom = DateTime.utc(2026);
  static final _validUntil = DateTime.utc(2027, 12, 31);

  List<int> get _rootName =>
      _distinguishedName([('2.5.4.3', 'Test Attestation Root')]);
  List<int> get _intermediateName => _distinguishedName([
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
    final leafKey = _TestKey('$_name-$keySeed');
    final attestationName = _distinguishedName([
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
      subject: _distinguishedName([('2.5.4.3', 'Android Keystore Key')]),
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
        issuer: _distinguishedName([('2.5.4.3', 'Android Keystore Key')]),
        subject: _distinguishedName([('2.5.4.3', 'Forged Key')]),
        subjectKey: _TestKey('$_name-forged'),
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
    required _TestKey subjectKey,
    required _TestKey signer,
    DateTime? notBefore,
    DateTime? notAfter,
    List<int>? attestationExtension,
  }) {
    final tbs = _sequence([
      _explicit(0, _integer(BigInt.two)),
      _integer(serial),
      _sequence([_oid(X509Oid.ecdsaWithSha256)]),
      issuer,
      _sequence([
        _generalizedTime(notBefore ?? _validFrom),
        _generalizedTime(notAfter ?? _validUntil),
      ]),
      subject,
      _sequence([
        _sequence([_oid(X509Oid.ecPublicKey), _oid(X509Oid.secp256r1)]),
        _bitString(subjectKey.publicPoint),
      ]),
      if (attestationExtension != null)
        _explicit(
          3,
          _sequence([
            _sequence([
              _oid(keyAttestationExtensionOid),
              _octets(attestationExtension),
            ]),
          ]),
        ),
    ]);
    final signature = signer.sign(tbs);
    return _sequence([
      tbs,
      _sequence([_oid(X509Oid.ecdsaWithSha256)]),
      _bitString(
        _sequence([_integer(signature.r), _integer(signature.s)]),
      ),
    ]);
  }
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
  final _TestKey _key;
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
  String signP1363(List<int> message) {
    final signature = _key.sign(message);
    return base64Encode([
      ..._fixedWidth(signature.r),
      ..._fixedWidth(signature.s),
    ]);
  }
}

final class _TestKey {
  _TestKey(String seed)
    : _private =
          BigInt.parse(
                sha256.convert(utf8.encode(seed)).toString(),
                radix: 16,
              ) %
              (_curve.n - BigInt.one) +
          BigInt.one;

  static final _curve = ECCurve_secp256r1();
  final BigInt _private;

  Uint8List get publicPoint => (_curve.G * _private)!.getEncoded(false);

  ECSignature sign(List<int> message) {
    final signer = Signer('SHA-256/DET-ECDSA')
      ..init(
        true,
        PrivateKeyParameter<ECPrivateKey>(ECPrivateKey(_private, _curve)),
      );
    return signer.generateSignature(Uint8List.fromList(message)) as ECSignature;
  }
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
  final applicationId = _sequence([
    _set([
      _sequence([_octets(utf8.encode(packageName)), _integer(BigInt.one)]),
    ]),
    _set([_octets(_hexBytes(signingCertificateDigest))]),
  ]);
  return _sequence([
    _integer(BigInt.from(300)),
    _enumerated(securityLevel.value),
    _integer(BigInt.from(300)),
    _enumerated(securityLevel.value),
    _octets(challenge),
    _octets(const []),
    _sequence([
      _explicit(KeyMintTag.attestationApplicationId, _octets(applicationId)),
    ]),
    _sequence([
      _explicit(
        KeyMintTag.purpose,
        _set([for (final purpose in purposes) _integer(BigInt.from(purpose))]),
      ),
      _explicit(KeyMintTag.algorithm, _integer(BigInt.from(algorithm))),
      _explicit(KeyMintTag.keySize, _integer(BigInt.from(256))),
      _explicit(KeyMintTag.ecCurve, _integer(BigInt.from(ecCurve))),
      _explicit(KeyMintTag.origin, _integer(BigInt.from(origin))),
      _explicit(
        KeyMintTag.rootOfTrust,
        _sequence([
          _octets(List.filled(32, 7)),
          _boolean(deviceLocked),
          _enumerated(bootState.value),
          _octets(List.filled(32, 9)),
        ]),
      ),
      _explicit(KeyMintTag.osVersion, _integer(BigInt.from(160000))),
      _explicit(KeyMintTag.osPatchLevel, _integer(BigInt.from(osPatchLevel))),
    ]),
  ]);
}

// A minimal DER writer: just what certificates and KeyDescription need.

List<int> _tlv(List<int> identifier, List<int> value) => [
  ...identifier,
  ..._length(value.length),
  ...value,
];

List<int> _length(int length) {
  if (length < 0x80) return [length];
  final bytes = <int>[];
  for (var remaining = length; remaining > 0; remaining >>= 8) {
    bytes.insert(0, remaining & 0xff);
  }
  return [0x80 | bytes.length, ...bytes];
}

List<int> _sequence(List<List<int>> items) =>
    _tlv(const [0x30], [for (final item in items) ...item]);

List<int> _set(List<List<int>> items) =>
    _tlv(const [0x31], [for (final item in items) ...item]);

List<int> _integer(BigInt value) {
  final bytes = <int>[];
  var remaining = value;
  do {
    bytes.insert(0, (remaining & BigInt.from(0xff)).toInt());
    remaining >>= 8;
  } while (remaining > BigInt.zero);
  if (bytes.first & 0x80 != 0) bytes.insert(0, 0);
  return _tlv(const [0x02], bytes);
}

List<int> _enumerated(int value) => _tlv(const [0x0a], [value]);

List<int> _boolean(bool value) => _tlv(const [0x01], [if (value) 0xff else 0]);

List<int> _octets(List<int> value) => _tlv(const [0x04], value);

List<int> _bitString(List<int> value) => _tlv(const [0x03], [0, ...value]);

List<int> _generalizedTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  final utc = value.toUtc();
  return _tlv(
    const [0x18],
    ascii.encode(
      '${utc.year.toString().padLeft(4, '0')}${two(utc.month)}${two(utc.day)}'
      '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z',
    ),
  );
}

List<int> _oid(String dotted) {
  final arcs = dotted.split('.').map(int.parse).toList();
  final body = <int>[40 * arcs[0] + arcs[1]];
  for (final arc in arcs.skip(2)) {
    final chunk = <int>[arc & 0x7f];
    for (var remaining = arc >> 7; remaining > 0; remaining >>= 7) {
      chunk.insert(0, 0x80 | (remaining & 0x7f));
    }
    body.addAll(chunk);
  }
  return _tlv(const [0x06], body);
}

/// A context-specific constructed tag, in high-tag-number form above 30.
List<int> _explicit(int tagNumber, List<int> inner) {
  if (tagNumber < 31) return _tlv([0xa0 | tagNumber], inner);
  final number = <int>[tagNumber & 0x7f];
  for (var remaining = tagNumber >> 7; remaining > 0; remaining >>= 7) {
    number.insert(0, 0x80 | (remaining & 0x7f));
  }
  return _tlv([0xbf, ...number], inner);
}

// Distinguished names are SEQUENCE OF SET OF {type, UTF8String value}.
List<int> _distinguishedName(List<(String, String)> attributes) => _sequence([
  for (final (oid, value) in attributes)
    _set([
      _sequence([
        _oid(oid),
        _tlv(const [0x0c], utf8.encode(value)),
      ]),
    ]),
]);

List<int> _fixedWidth(BigInt value) {
  final hex = value.toRadixString(16).padLeft(64, '0');
  return [
    for (var index = 0; index < hex.length; index += 2)
      int.parse(hex.substring(index, index + 2), radix: 16),
  ];
}

List<int> _hexBytes(String hex) => [
  for (var index = 0; index < hex.length; index += 2)
    int.parse(hex.substring(index, index + 2), radix: 16),
];
