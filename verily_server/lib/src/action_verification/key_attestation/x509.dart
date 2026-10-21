import 'dart:typed_data';

import 'package:pointycastle/ecc/ecc_fp.dart' as fp;
import 'package:pointycastle/export.dart';
import 'package:verily_server/src/action_verification/key_attestation/der.dart';

/// Object identifiers the attestation verifier reads.
abstract final class X509Oid {
  static const commonName = '2.5.4.3';
  static const serialNumber = '2.5.4.5';
  static const organization = '2.5.4.10';
  static const ecPublicKey = '1.2.840.10045.2.1';
  static const rsaEncryption = '1.2.840.113549.1.1.1';
  static const secp256r1 = '1.2.840.10045.3.1.7';
  static const secp384r1 = '1.3.132.0.34';
  static const ecdsaWithSha256 = '1.2.840.10045.4.3.2';
  static const ecdsaWithSha384 = '1.2.840.10045.4.3.3';
  static const ecdsaWithSha512 = '1.2.840.10045.4.3.4';
  static const sha256WithRsa = '1.2.840.113549.1.1.11';
  static const sha384WithRsa = '1.2.840.113549.1.1.12';
  static const sha512WithRsa = '1.2.840.113549.1.1.13';
}

/// An X.509 certificate, parsed only as far as chain validation needs.
///
/// [tbs] keeps the exact signed bytes: a signature is always checked over
/// what the issuer signed, never over a re-encoding.
final class X509Certificate {
  X509Certificate._({
    required this.encoded,
    required this.tbs,
    required this.signatureAlgorithm,
    required this.signature,
    required this.serialNumber,
    required this.issuer,
    required this.subject,
    required this.notBefore,
    required this.notAfter,
    required this.subjectPublicKeyInfo,
    required this.publicKey,
    required this.extensions,
  });

  /// Parses one DER certificate. Throws [DerFormatException] when it is not
  /// a well-formed v1 to v3 certificate.
  factory X509Certificate.parse(List<int> der) {
    final certificate = parseDer(der).sequence;
    if (certificate.length != 3) {
      throw const DerFormatException('A certificate has three parts.');
    }
    final tbs = certificate[0];
    final fields = tbs.sequence;
    var index = 0;
    DerElement field() {
      if (index >= fields.length) {
        throw const DerFormatException('Truncated certificate.');
      }
      return fields[index++];
    }

    if (fields.isNotEmpty && fields.first.isContext(0)) {
      final version = field().explicit.smallInteger;
      if (version < 0 || version > 2) {
        throw const DerFormatException('Unknown certificate version.');
      }
    }
    final serialNumber = field().integer;
    final innerAlgorithm = _algorithm(field());
    final issuer = X509Name._(field());
    final validity = field().sequence;
    if (validity.length != 2) {
      throw const DerFormatException('Validity has two times.');
    }
    final subject = X509Name._(field());
    final subjectPublicKeyInfo = field();

    final extensions = <String, Uint8List>{};
    var lastTag = 0;
    while (index < fields.length) {
      final optional = field();
      if (optional.tagClass != DerTagClass.contextSpecific ||
          optional.tagNumber <= lastTag ||
          optional.tagNumber > 3) {
        throw const DerFormatException('Unexpected certificate field.');
      }
      lastTag = optional.tagNumber;
      if (optional.tagNumber != 3) continue;
      for (final extension in optional.explicit.sequence) {
        final parts = extension.sequence;
        if (parts.length < 2 || parts.length > 3) {
          throw const DerFormatException('Malformed extension.');
        }
        final id = parts.first.objectIdentifier;
        if (parts.length == 3 && !parts[1].isUniversal(DerTag.boolean)) {
          throw const DerFormatException('Malformed extension criticality.');
        }
        if (extensions.containsKey(id)) {
          throw const DerFormatException('Duplicate extension.');
        }
        extensions[id] = parts.last.octets;
      }
    }

    final outerAlgorithm = _algorithm(certificate[1]);
    if (outerAlgorithm != innerAlgorithm) {
      throw const DerFormatException('Signature algorithms disagree.');
    }
    return X509Certificate._(
      encoded: Uint8List.fromList(der),
      tbs: Uint8List.fromList(tbs.encoded),
      signatureAlgorithm: outerAlgorithm,
      signature: Uint8List.fromList(certificate[2].bitStringBytes),
      serialNumber: serialNumber,
      issuer: issuer,
      subject: subject,
      notBefore: validity[0].time,
      notAfter: validity[1].time,
      subjectPublicKeyInfo: Uint8List.fromList(subjectPublicKeyInfo.encoded),
      publicKey: CertificatePublicKey._parse(subjectPublicKeyInfo),
      extensions: Map.unmodifiable(extensions),
    );
  }

  final Uint8List encoded;
  final Uint8List tbs;
  final String signatureAlgorithm;
  final Uint8List signature;
  final BigInt serialNumber;
  final X509Name issuer;
  final X509Name subject;
  final DateTime notBefore;
  final DateTime notAfter;
  final Uint8List subjectPublicKeyInfo;
  final CertificatePublicKey publicKey;

  /// Extension values by object identifier: the contents of each
  /// `extnValue` OCTET STRING.
  final Map<String, Uint8List> extensions;

  /// The serial as Google's revocation list writes it: lowercase hex
  /// without leading zeros.
  String get serialHex => serialNumber.toRadixString(16);

  bool get isSelfIssued => issuer.matches(subject);

  /// Whether [issuerKey] signed this certificate.
  bool isSignedBy(CertificatePublicKey issuerKey) =>
      issuerKey.verifies(tbs, signatureAlgorithm, signature);

  bool isValidAt(DateTime instant) =>
      !instant.isBefore(notBefore) && !instant.isAfter(notAfter);
}

/// A distinguished name, compared the way certificate path validation does.
final class X509Name {
  X509Name._(DerElement element)
    : encoded = Uint8List.fromList(element.encoded),
      _attributes = [
        for (final rdn in element.sequence)
          [
            for (final attribute in rdn.set)
              _NameAttribute.parse(attribute.sequence),
          ],
      ] {
    if (_attributes.any((rdn) => rdn.isEmpty)) {
      throw const DerFormatException('Empty relative distinguished name.');
    }
  }

  final Uint8List encoded;
  final List<List<_NameAttribute>> _attributes;

  /// The first value of [oid] in this name, if any.
  String? attribute(String oid) {
    for (final rdn in _attributes) {
      for (final attribute in rdn) {
        if (attribute.oid == oid) return attribute.text;
      }
    }
    return null;
  }

  /// Whether any attribute value contains [word], ignoring case.
  bool mentions(String word) => _attributes.any(
    (rdn) => rdn.any(
      (attribute) =>
          attribute.text?.toLowerCase().contains(word.toLowerCase()) ?? false,
    ),
  );

  /// Exact DER equality, or equality after RFC 5280's caseless comparison of
  /// string values (trimmed, internal whitespace collapsed).
  bool matches(X509Name other) {
    if (_bytesEqual(encoded, other.encoded)) return true;
    return _canonical == other._canonical;
  }

  late final String _canonical = [
    for (final rdn in _attributes)
      ([for (final attribute in rdn) attribute.canonical]..sort()).join('+'),
  ].join(',');
}

final class _NameAttribute {
  _NameAttribute._(this.oid, this.text, this.canonical);

  factory _NameAttribute.parse(List<DerElement> parts) {
    if (parts.length != 2) {
      throw const DerFormatException('Malformed name attribute.');
    }
    final oid = parts[0].objectIdentifier;
    String? text;
    try {
      text = parts[1].text;
    } on FormatException {
      text = null;
    }
    final canonical = text == null
        ? '$oid=#${_hex(parts[1].encoded)}'
        : '$oid=${text.trim().toLowerCase().replaceAll(_whitespace, ' ')}';
    return _NameAttribute._(oid, text, canonical);
  }

  final String oid;
  final String? text;
  final String canonical;
}

final _whitespace = RegExp(r'\s+');

/// A certificate's subject public key.
sealed class CertificatePublicKey {
  const CertificatePublicKey();

  factory CertificatePublicKey._parse(DerElement subjectPublicKeyInfo) {
    final parts = subjectPublicKeyInfo.sequence;
    if (parts.length != 2) {
      throw const DerFormatException('Malformed public key info.');
    }
    final algorithm = parts[0].sequence;
    if (algorithm.isEmpty) {
      throw const DerFormatException('Malformed key algorithm.');
    }
    final algorithmOid = algorithm.first.objectIdentifier;
    final keyBytes = parts[1].bitStringBytes;
    switch (algorithmOid) {
      case X509Oid.ecPublicKey:
        if (algorithm.length != 2) {
          throw const DerFormatException('EC keys name their curve.');
        }
        final curveOid = algorithm[1].objectIdentifier;
        final coordinateBytes = switch (curveOid) {
          X509Oid.secp256r1 => 32,
          X509Oid.secp384r1 => 48,
          _ => null,
        };
        if (coordinateBytes == null) {
          return UnsupportedPublicKey('$algorithmOid/$curveOid');
        }
        if (keyBytes.length != 1 + 2 * coordinateBytes ||
            keyBytes.first != 0x04) {
          throw const DerFormatException('Expected an uncompressed EC point.');
        }
        return EcPublicKeyInfo(curveOid, Uint8List.fromList(keyBytes));
      case X509Oid.rsaEncryption:
        final rsa = parseDer(keyBytes).sequence;
        if (rsa.length != 2) {
          throw const DerFormatException('Malformed RSA key.');
        }
        final modulus = rsa[0].integer;
        final exponent = rsa[1].integer;
        if (modulus <= BigInt.zero || exponent <= BigInt.one) {
          throw const DerFormatException('Malformed RSA key.');
        }
        return RsaPublicKeyInfo(modulus, exponent);
      default:
        return UnsupportedPublicKey(algorithmOid);
    }
  }

  /// Whether [signature] over [message] verifies under this key with
  /// [signatureAlgorithm]. A key/algorithm mismatch never verifies.
  bool verifies(
    Uint8List message,
    String signatureAlgorithm,
    Uint8List signature,
  );
}

/// An elliptic-curve key on P-256 or P-384 with its uncompressed point.
final class EcPublicKeyInfo extends CertificatePublicKey {
  const EcPublicKeyInfo(this.curveOid, this.point);

  final String curveOid;

  /// `0x04 ‖ X ‖ Y`.
  final Uint8List point;

  bool get isP256 => curveOid == X509Oid.secp256r1;

  @override
  bool verifies(
    Uint8List message,
    String signatureAlgorithm,
    Uint8List signature,
  ) {
    final digest = switch (signatureAlgorithm) {
      X509Oid.ecdsaWithSha256 => SHA256Digest(),
      X509Oid.ecdsaWithSha384 => SHA384Digest(),
      X509Oid.ecdsaWithSha512 => SHA512Digest(),
      _ => null,
    };
    if (digest == null) return false;
    try {
      final values = parseDer(signature).sequence;
      if (values.length != 2) return false;
      return verifyEcdsa(
        curve: _curve,
        point: point,
        digest: digest,
        message: message,
        r: values[0].integer,
        s: values[1].integer,
      );
    } on FormatException {
      return false;
    }
  }

  ECDomainParameters get _curve =>
      curveOid == X509Oid.secp256r1 ? ECCurve_secp256r1() : ECCurve_secp384r1();
}

/// An RSA key, which signs Google's legacy attestation root and its
/// factory intermediates.
final class RsaPublicKeyInfo extends CertificatePublicKey {
  const RsaPublicKeyInfo(this.modulus, this.exponent);

  final BigInt modulus;
  final BigInt exponent;

  /// RSASSA-PKCS1-v1_5 (RFC 8017 §8.2.2): rebuild the whole expected
  /// encoding and compare it, rather than parsing the decrypted block.
  @override
  bool verifies(
    Uint8List message,
    String signatureAlgorithm,
    Uint8List signature,
  ) {
    final (digest, digestInfoPrefix) = switch (signatureAlgorithm) {
      X509Oid.sha256WithRsa => (SHA256Digest(), _sha256DigestInfo),
      X509Oid.sha384WithRsa => (SHA384Digest(), _sha384DigestInfo),
      X509Oid.sha512WithRsa => (SHA512Digest(), _sha512DigestInfo),
      _ => (null, null),
    };
    if (digest == null || digestInfoPrefix == null) return false;
    final length = (modulus.bitLength + 7) ~/ 8;
    if (signature.length != length) return false;
    final value = unsignedBigInt(signature);
    if (value >= modulus) return false;
    final digestInfo = [...digestInfoPrefix, ...digest.process(message)];
    if (length < digestInfo.length + 11) return false;
    final expected = Uint8List.fromList([
      0x00,
      0x01,
      ...List.filled(length - digestInfo.length - 3, 0xff),
      0x00,
      ...digestInfo,
    ]);
    return _bytesEqual(
      _fixedLengthBytes(value.modPow(exponent, modulus), length),
      expected,
    );
  }
}

// DER DigestInfo headers (algorithm with NULL parameters, then the digest's
// OCTET STRING header) from RFC 8017 §9.2, note 1.
const _sha256DigestInfo = [
  0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, //
  0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20,
];
const _sha384DigestInfo = [
  0x30, 0x41, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, //
  0x03, 0x04, 0x02, 0x02, 0x05, 0x00, 0x04, 0x30,
];
const _sha512DigestInfo = [
  0x30, 0x51, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, //
  0x03, 0x04, 0x02, 0x03, 0x05, 0x00, 0x04, 0x40,
];

/// A key this verifier cannot check signatures with, such as ML-DSA. It may
/// appear on a leaf, never on a certificate that signs another.
final class UnsupportedPublicKey extends CertificatePublicKey {
  const UnsupportedPublicKey(this.algorithm);

  final String algorithm;

  @override
  bool verifies(
    Uint8List message,
    String signatureAlgorithm,
    Uint8List signature,
  ) => false;
}

/// Verifies an ECDSA signature `(r, s)` over [message] with the uncompressed
/// [point] on [curve], truncating the digest to the curve order as FIPS 186
/// requires. A point off the curve never verifies.
bool verifyEcdsa({
  required ECDomainParameters curve,
  required Uint8List point,
  required Digest digest,
  required Uint8List message,
  required BigInt r,
  required BigInt s,
}) {
  if (r <= BigInt.zero || s <= BigInt.zero || r >= curve.n || s >= curve.n) {
    return false;
  }
  final decoded = _curvePoint(curve, point);
  if (decoded == null) return false;
  final signer = ECDSASigner(digest)
    ..init(false, PublicKeyParameter<ECPublicKey>(ECPublicKey(decoded, curve)));
  return signer.verifySignature(message, ECSignature(r, s));
}

/// Decodes `0x04 ‖ X ‖ Y` only when both coordinates are field elements and
/// the point satisfies `y² = x³ + ax + b`.
ECPoint? _curvePoint(ECDomainParameters domain, Uint8List encoded) {
  final curve = domain.curve;
  if (curve is! fp.ECCurve) return null;
  final coordinateBytes = (curve.fieldSize + 7) ~/ 8;
  if (encoded.length != 1 + 2 * coordinateBytes || encoded.first != 0x04) {
    return null;
  }
  final prime = curve.q!;
  final x = unsignedBigInt(encoded.sublist(1, 1 + coordinateBytes));
  final y = unsignedBigInt(encoded.sublist(1 + coordinateBytes));
  if (x >= prime || y >= prime) return null;
  final a = curve.a!.toBigInteger()!;
  final b = curve.b!.toBigInteger()!;
  if ((y * y - (x * x * x + a * x + b)) % prime != BigInt.zero) return null;
  return curve.createPoint(x, y);
}

/// Reads big-endian [bytes] as a non-negative integer.
BigInt unsignedBigInt(List<int> bytes) => bytes.fold<BigInt>(
  BigInt.zero,
  (value, byte) => (value << 8) | BigInt.from(byte),
);

Uint8List _fixedLengthBytes(BigInt value, int length) {
  final bytes = Uint8List(length);
  var remaining = value;
  for (var index = length - 1; index >= 0; index -= 1) {
    bytes[index] = (remaining & BigInt.from(0xff)).toInt();
    remaining >>= 8;
  }
  return bytes;
}

String _algorithm(DerElement element) {
  final parts = element.sequence;
  if (parts.isEmpty || parts.length > 2) {
    throw const DerFormatException('Malformed algorithm identifier.');
  }
  return parts.first.objectIdentifier;
}

bool _bytesEqual(Uint8List left, Uint8List right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
