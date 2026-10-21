import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/capture_signature_verifier.dart';

void main() {
  final manifest = utf8.encode('verily-capture-manifest-v1\nproof=test');
  final fixture = _signedFixture(manifest);

  test('accepts a valid P-256 capture signature', () {
    expect(
      verifyCaptureSignature(
        manifest: manifest,
        encodedSignature: fixture.signature,
        publicKey: fixture.publicKey,
      ),
      isTrue,
    );
  });

  test('rejects a signature replayed over another manifest', () {
    expect(
      verifyCaptureSignature(
        manifest: utf8.encode('verily-capture-manifest-v1\nproof=other'),
        encodedSignature: fixture.signature,
        publicKey: fixture.publicKey,
      ),
      isFalse,
    );
  });

  test('rejects a signature checked against another key', () {
    final other = _signedFixture(manifest, privateKey: BigInt.two);

    expect(
      verifyCaptureSignature(
        manifest: manifest,
        encodedSignature: fixture.signature,
        publicKey: other.publicKey,
      ),
      isFalse,
    );
  });

  test('rejects malformed signatures and points off the curve', () {
    final offCurve = Uint8List.fromList(fixture.publicKey)..[64] ^= 0x01;

    for (final signature in [
      '',
      'not base64!',
      base64Encode([1, 2, 3]),
    ]) {
      expect(
        verifyCaptureSignature(
          manifest: manifest,
          encodedSignature: signature,
          publicKey: fixture.publicKey,
        ),
        isFalse,
        reason: signature,
      );
    }
    expect(
      verifyCaptureSignature(
        manifest: manifest,
        encodedSignature: fixture.signature,
        publicKey: offCurve,
      ),
      isFalse,
    );
  });
}

({String signature, Uint8List publicKey}) _signedFixture(
  List<int> manifest, {
  BigInt? privateKey,
}) {
  final parameters = ECCurve_secp256r1();
  final secret = privateKey ?? BigInt.one;
  final signer = Signer('SHA-256/DET-ECDSA')
    ..init(
      true,
      PrivateKeyParameter<ECPrivateKey>(ECPrivateKey(secret, parameters)),
    );
  final signature =
      signer.generateSignature(Uint8List.fromList(manifest)) as ECSignature;
  final encodedSignature = Uint8List(64)
    ..setRange(0, 32, _fixedWidth(signature.r, 32))
    ..setRange(32, 64, _fixedWidth(signature.s, 32));
  return (
    signature: base64Encode(encodedSignature),
    publicKey: (parameters.G * secret)!.getEncoded(false),
  );
}

List<int> _fixedWidth(BigInt value, int width) {
  final hex = value.toRadixString(16).padLeft(width * 2, '0');
  return [
    for (var index = 0; index < hex.length; index += 2)
      int.parse(hex.substring(index, index + 2), radix: 16),
  ];
}
