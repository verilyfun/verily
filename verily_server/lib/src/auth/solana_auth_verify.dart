import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed25519;

const solanaPublicKeyLength = 32;
const solanaSignatureLength = 64;

Uint8List decodeBase58PublicKey(String value) {
  final bytes = base58.decoder.convert(value.trim());
  if (bytes.length != solanaPublicKeyLength) {
    throw const FormatException(
      'Solana wallet address must decode to $solanaPublicKeyLength bytes.',
    );
  }
  return bytes;
}

Uint8List decodeBase58Signature(String value) {
  final bytes = base58.decoder.convert(value.trim());
  if (bytes.length != solanaSignatureLength) {
    throw const FormatException(
      'Solana signature must decode to $solanaSignatureLength bytes.',
    );
  }
  return bytes;
}

bool verifySolanaSignature({
  required Uint8List publicKeyBytes,
  required Uint8List messageBytes,
  required Uint8List signatureBytes,
}) {
  if (publicKeyBytes.length != solanaPublicKeyLength ||
      signatureBytes.length != solanaSignatureLength) {
    return false;
  }

  try {
    return ed25519.verify(
      ed25519.PublicKey(publicKeyBytes),
      messageBytes,
      signatureBytes,
    );
  } on Object {
    return false;
  }
}
