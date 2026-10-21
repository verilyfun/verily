import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:verily_evidence/verily_evidence.dart';

const _p256PublicKeyLength = 65;
const _p256SignatureLength = 64;

class CaptureSignatureVerdict {
  const CaptureSignatureVerdict({
    required this.trusted,
    required this.reasonCode,
  });

  final bool trusted;
  final String reasonCode;
}

// An injectable seam so tests can supply a deterministic verifier.
// ignore: one_member_abstracts
abstract interface class CaptureSignatureVerifier {
  CaptureSignatureVerdict verify({
    required List<int> manifest,
    required String encodedSignature,
    required String encodedPublicKey,
    required String keyId,
  });
}

class P256CaptureSignatureVerifier implements CaptureSignatureVerifier {
  const P256CaptureSignatureVerifier();

  @override
  CaptureSignatureVerdict verify({
    required List<int> manifest,
    required String encodedSignature,
    required String encodedPublicKey,
    required String keyId,
  }) {
    try {
      if (encodedPublicKey.length > 128 || encodedSignature.length > 128) {
        return _invalidVerdict;
      }
      final publicKeyBytes = base64Decode(encodedPublicKey);
      final signatureBytes = base64Decode(encodedSignature);
      if (publicKeyBytes.length != _p256PublicKeyLength ||
          publicKeyBytes.first != 0x04 ||
          signatureBytes.length != _p256SignatureLength) {
        return _invalidVerdict;
      }
      if (capturePublicKeyId(publicKeyBytes) != keyId.trim().toLowerCase()) {
        return const CaptureSignatureVerdict(
          trusted: false,
          reasonCode: 'capture_key_mismatch',
        );
      }

      final parameters = ECDomainParameters('secp256r1');
      final point = parameters.curve.decodePoint(publicKeyBytes);
      if (point == null || point.isInfinity) return _invalidVerdict;
      final signer = Signer('SHA-256/ECDSA')
        ..init(
          false,
          PublicKeyParameter<ECPublicKey>(
            ECPublicKey(point, parameters),
          ),
        );
      final signature = ECSignature(
        _unsignedBigInt(signatureBytes.sublist(0, 32)),
        _unsignedBigInt(signatureBytes.sublist(32)),
      );
      final trusted = signer.verifySignature(
        Uint8List.fromList(manifest),
        signature,
      );
      return CaptureSignatureVerdict(
        trusted: trusted,
        reasonCode: trusted
            ? 'capture_signature_valid'
            : 'capture_signature_invalid',
      );
    } on Object {
      return _invalidVerdict;
    }
  }
}

BigInt _unsignedBigInt(List<int> bytes) {
  return bytes.fold<BigInt>(
    BigInt.zero,
    (value, byte) => (value << 8) | BigInt.from(byte),
  );
}

const _invalidVerdict = CaptureSignatureVerdict(
  trusted: false,
  reasonCode: 'capture_signature_invalid',
);
