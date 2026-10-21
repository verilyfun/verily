import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:test/test.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/action_verification/capture_signature_verifier.dart';

void main() {
  const verifier = P256CaptureSignatureVerifier();
  final manifest = utf8.encode('verily-capture-manifest-v1\nproof=test');
  final fixture = _signedFixture(manifest);

  test('accepts a valid P-256 capture signature', () {
    final verdict = verifier.verify(
      manifest: manifest,
      encodedSignature: fixture.signature,
      encodedPublicKey: fixture.publicKey,
      keyId: fixture.keyId,
    );

    expect(verdict.trusted, isTrue);
    expect(verdict.reasonCode, 'capture_signature_valid');
  });

  test('rejects a signature replayed over another manifest', () {
    final verdict = verifier.verify(
      manifest: utf8.encode('verily-capture-manifest-v1\nproof=other'),
      encodedSignature: fixture.signature,
      encodedPublicKey: fixture.publicKey,
      keyId: fixture.keyId,
    );

    expect(verdict.trusted, isFalse);
    expect(verdict.reasonCode, 'capture_signature_invalid');
  });

  test('rejects a public key with a mismatched identifier', () {
    final verdict = verifier.verify(
      manifest: manifest,
      encodedSignature: fixture.signature,
      encodedPublicKey: fixture.publicKey,
      keyId: '0' * 64,
    );

    expect(verdict.trusted, isFalse);
    expect(verdict.reasonCode, 'capture_key_mismatch');
  });
}

({String signature, String publicKey, String keyId}) _signedFixture(
  List<int> manifest,
) {
  final parameters = ECDomainParameters('secp256r1');
  final privateKey = ECPrivateKey(BigInt.one, parameters);
  final publicPoint = parameters.G * BigInt.one;
  final signer = Signer('SHA-256/DET-ECDSA')
    ..init(true, PrivateKeyParameter<ECPrivateKey>(privateKey));
  final signature = signer.generateSignature(
    Uint8List.fromList(manifest),
  ) as ECSignature;
  final publicKey = publicPoint!.getEncoded(false);
  final encodedSignature = Uint8List(64)
    ..setRange(0, 32, _fixedWidth(signature.r, 32))
    ..setRange(32, 64, _fixedWidth(signature.s, 32));
  return (
    signature: base64Encode(encodedSignature),
    publicKey: base64Encode(publicKey),
    keyId: capturePublicKeyId(publicKey),
  );
}

List<int> _fixedWidth(BigInt value, int width) {
  final hex = value.toRadixString(16).padLeft(width * 2, '0');
  return [
    for (var index = 0; index < hex.length; index += 2)
      int.parse(hex.substring(index, index + 2), radix: 16),
  ];
}
