import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';

// A minimal DER writer and deterministic P-256 keys: just what the synthetic
// attestation authorities need to issue certificates.

/// A P-256 key derived from a seed, so certificates are reproducible across
/// runs.
final class TestEcKey {
  TestEcKey(String seed)
    : _private =
          BigInt.parse(
                sha256.convert(utf8.encode(seed)).toString(),
                radix: 16,
              ) %
              (_curve.n - BigInt.one) +
          BigInt.one;

  static final _curve = ECCurve_secp256r1();
  final BigInt _private;

  /// `0x04 ‖ X ‖ Y`.
  Uint8List get publicPoint => (_curve.G * _private)!.getEncoded(false);

  /// Deterministic ECDSA over SHA-256 of [message].
  ECSignature sign(List<int> message) {
    final signer = Signer('SHA-256/DET-ECDSA')
      ..init(
        true,
        PrivateKeyParameter<ECPrivateKey>(ECPrivateKey(_private, _curve)),
      );
    return signer.generateSignature(Uint8List.fromList(message)) as ECSignature;
  }

  /// [sign] as an ASN.1 DER `SEQUENCE { r, s }`.
  List<int> signDer(List<int> message) {
    final signature = sign(message);
    return derSequence([derInteger(signature.r), derInteger(signature.s)]);
  }

  /// [sign] as IEEE P1363 `r ‖ s`.
  List<int> signP1363(List<int> message) {
    final signature = sign(message);
    return [...fixedWidth32(signature.r), ...fixedWidth32(signature.s)];
  }
}

/// An X.509 v3 certificate for [subjectKey], signed by [signer] with
/// ECDSA-SHA256. [extensions] maps object identifiers to `extnValue`
/// contents.
List<int> derCertificate({
  required BigInt serial,
  required List<int> issuer,
  required List<int> subject,
  required TestEcKey subjectKey,
  required TestEcKey signer,
  required DateTime notBefore,
  required DateTime notAfter,
  Map<String, List<int>> extensions = const {},
}) {
  final tbs = derSequence([
    derExplicit(0, derInteger(BigInt.two)),
    derInteger(serial),
    derSequence([derOid(X509Oid.ecdsaWithSha256)]),
    issuer,
    derSequence([derGeneralizedTime(notBefore), derGeneralizedTime(notAfter)]),
    subject,
    derSequence([
      derSequence([derOid(X509Oid.ecPublicKey), derOid(X509Oid.secp256r1)]),
      derBitString(subjectKey.publicPoint),
    ]),
    if (extensions.isNotEmpty)
      derExplicit(
        3,
        derSequence([
          for (final MapEntry(key: oid, :value) in extensions.entries)
            derSequence([derOid(oid), derOctets(value)]),
        ]),
      ),
  ]);
  return derSequence([
    tbs,
    derSequence([derOid(X509Oid.ecdsaWithSha256)]),
    derBitString(signer.signDer(tbs)),
  ]);
}

List<int> derTlv(List<int> identifier, List<int> value) => [
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

List<int> derSequence(List<List<int>> items) =>
    derTlv(const [0x30], [for (final item in items) ...item]);

List<int> derSet(List<List<int>> items) =>
    derTlv(const [0x31], [for (final item in items) ...item]);

List<int> derInteger(BigInt value) {
  final bytes = <int>[];
  var remaining = value;
  do {
    bytes.insert(0, (remaining & BigInt.from(0xff)).toInt());
    remaining >>= 8;
  } while (remaining > BigInt.zero);
  if (bytes.first & 0x80 != 0) bytes.insert(0, 0);
  return derTlv(const [0x02], bytes);
}

List<int> derEnumerated(int value) => derTlv(const [0x0a], [value]);

List<int> derBoolean({required bool value}) =>
    derTlv(const [0x01], [if (value) 0xff else 0]);

List<int> derOctets(List<int> value) => derTlv(const [0x04], value);

List<int> derBitString(List<int> value) => derTlv(const [0x03], [0, ...value]);

List<int> derGeneralizedTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  final utc = value.toUtc();
  return derTlv(
    const [0x18],
    ascii.encode(
      '${utc.year.toString().padLeft(4, '0')}${two(utc.month)}${two(utc.day)}'
      '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z',
    ),
  );
}

List<int> derOid(String dotted) {
  final arcs = dotted.split('.').map(int.parse).toList();
  final body = <int>[40 * arcs[0] + arcs[1]];
  for (final arc in arcs.skip(2)) {
    final chunk = <int>[arc & 0x7f];
    for (var remaining = arc >> 7; remaining > 0; remaining >>= 7) {
      chunk.insert(0, 0x80 | (remaining & 0x7f));
    }
    body.addAll(chunk);
  }
  return derTlv(const [0x06], body);
}

/// A context-specific constructed tag, in high-tag-number form above 30.
List<int> derExplicit(int tagNumber, List<int> inner) {
  if (tagNumber < 31) return derTlv([0xa0 | tagNumber], inner);
  final number = <int>[tagNumber & 0x7f];
  for (var remaining = tagNumber >> 7; remaining > 0; remaining >>= 7) {
    number.insert(0, 0x80 | (remaining & 0x7f));
  }
  return derTlv([0xbf, ...number], inner);
}

/// A distinguished name: SEQUENCE OF SET OF {type, UTF8String value}.
List<int> derDistinguishedName(List<(String, String)> attributes) =>
    derSequence([
      for (final (oid, value) in attributes)
        derSet([
          derSequence([
            derOid(oid),
            derTlv(const [0x0c], utf8.encode(value)),
          ]),
        ]),
    ]);

/// [value] as exactly 32 big-endian bytes.
List<int> fixedWidth32(BigInt value) {
  final hex = value.toRadixString(16).padLeft(64, '0');
  return [
    for (var index = 0; index < hex.length; index += 2)
      int.parse(hex.substring(index, index + 2), radix: 16),
  ];
}
