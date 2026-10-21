import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:verily_server/src/apps/platform_keys.dart';

/// Issuer of every verification receipt.
const receiptIssuer = 'https://verily.fun';

/// Verification receipts: compact JWS (EdDSA over Ed25519) with a `kid`, and
/// the public JWKS that verifies them. See docs/platform.md.
///
/// The `kid` is the RFC 7638 JWK thumbprint of the public key, so it is
/// derived from the key itself and needs no separate configuration. Rotation
/// sets a new `VERILY_RECEIPT_SIGNING_KEY` and moves the old public key into
/// `VERILY_RECEIPT_RETIRED_PUBLIC_KEYS`, where the JWKS keeps publishing it
/// for receipts already issued.
abstract final class ReceiptSigning {
  /// The active signer, or null when this server has no receipt key.
  static ReceiptSigner? get signer {
    final seed = PlatformKeys.current.receiptSigningKey;
    return seed == null ? null : ReceiptSigner.fromSeed(seed);
  }

  /// The JSON Web Key Set served at `/.well-known/jwks.json`: the active key
  /// first, then every retired public key. Empty when no key is configured.
  static Map<String, Object?> jwks() {
    final active = signer;
    final publicKeys = <List<int>>[
      ?active?.publicKey,
      ...PlatformKeys.current.retiredReceiptPublicKeys,
    ];
    final seen = <String>{};
    return {
      'keys': [
        for (final key in publicKeys)
          if (seen.add(receiptKeyId(key))) receiptPublicJwk(key),
      ],
    };
  }
}

/// Signs receipts with one Ed25519 key.
final class ReceiptSigner {
  ReceiptSigner._(this._privateKey, this.publicKey)
    : kid = receiptKeyId(publicKey);

  /// [seed] is the 32-byte Ed25519 private seed.
  factory ReceiptSigner.fromSeed(List<int> seed) {
    if (seed.length != 32) {
      throw ArgumentError.value(seed.length, 'seed', 'Must be 32 bytes.');
    }
    final privateKey = ed.newKeyFromSeed(Uint8List.fromList(seed));
    return ReceiptSigner._(
      privateKey,
      List.unmodifiable(ed.public(privateKey).bytes),
    );
  }

  final ed.PrivateKey _privateKey;
  final List<int> publicKey;
  final String kid;

  /// A compact JWS: `base64url(header).base64url(claims).base64url(sig)`.
  String sign(Map<String, Object?> claims) {
    final header = _base64Url(
      utf8.encode(jsonEncode({'alg': 'EdDSA', 'typ': 'JWT', 'kid': kid})),
    );
    final payload = _base64Url(utf8.encode(jsonEncode(claims)));
    final signature = ed.sign(
      _privateKey,
      Uint8List.fromList(ascii.encode('$header.$payload')),
    );
    return '$header.$payload.${_base64Url(signature)}';
  }

  // Never print key material.
  @override
  String toString() => 'ReceiptSigner($kid)';
}

/// The RFC 7638 thumbprint of an Ed25519 public key:
/// `base64url(SHA-256({"crv":"Ed25519","kty":"OKP","x":"<x>"}))`.
String receiptKeyId(List<int> publicKey) {
  final canonical =
      '{"crv":"Ed25519","kty":"OKP","x":"${_base64Url(publicKey)}"}';
  return _base64Url(sha256.convert(utf8.encode(canonical)).bytes);
}

/// The public JWK for one receipt key.
Map<String, Object?> receiptPublicJwk(List<int> publicKey) => {
  'kty': 'OKP',
  'crv': 'Ed25519',
  'x': _base64Url(publicKey),
  'kid': receiptKeyId(publicKey),
  'use': 'sig',
  'alg': 'EdDSA',
};

/// Verifies a compact receipt JWS against [jwks] (a JWKS document) and
/// returns its claims, or null when the header, key, or signature is wrong.
///
/// This is what an App does with Verily's published JWKS; the server uses it
/// in tests and documentation examples.
Map<String, Object?>? verifyReceipt(String token, Map<String, Object?> jwks) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final header = jsonDecode(utf8.decode(_fromBase64Url(parts[0])));
    if (header is! Map<String, Object?> ||
        header['alg'] != 'EdDSA' ||
        header['kid'] is! String) {
      return null;
    }
    final keys = jwks['keys'];
    if (keys is! List) return null;
    final jwk = keys.whereType<Map<String, Object?>>().where(
      (key) =>
          key['kid'] == header['kid'] &&
          key['kty'] == 'OKP' &&
          key['crv'] == 'Ed25519',
    );
    if (jwk.isEmpty) return null;
    final x = jwk.first['x'];
    if (x is! String) return null;
    final publicKey = _fromBase64Url(x);
    final signature = _fromBase64Url(parts[2]);
    if (publicKey.length != 32 ||
        signature.length != 64 ||
        receiptKeyId(publicKey) != header['kid']) {
      return null;
    }
    final valid = ed.verify(
      ed.PublicKey(publicKey),
      Uint8List.fromList(ascii.encode('${parts[0]}.${parts[1]}')),
      signature,
    );
    if (!valid) return null;
    final claims = jsonDecode(utf8.decode(_fromBase64Url(parts[1])));
    return claims is Map<String, Object?> ? claims : null;
  } on FormatException {
    return null;
  }
}

String _base64Url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

Uint8List _fromBase64Url(String value) {
  if (!RegExp(r'^[A-Za-z0-9_-]*$').hasMatch(value)) {
    throw const FormatException('Not base64url.');
  }
  return base64Url.decode(value.padRight((value.length + 3) ~/ 4 * 4, '='));
}
