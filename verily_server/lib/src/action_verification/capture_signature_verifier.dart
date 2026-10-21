import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';

const _p256SignatureLength = 64;

/// Whether [encodedSignature] signs [manifest] under [publicKey].
///
/// The signature is P-256 ECDSA over SHA-256 in IEEE P1363 form (`r ‖ s`,
/// base64), as the app's capture key produces it; [publicKey] is the
/// uncompressed point `0x04 ‖ X ‖ Y` from the attested leaf certificate.
bool verifyCaptureSignature({
  required List<int> manifest,
  required String encodedSignature,
  required Uint8List publicKey,
}) {
  if (encodedSignature.length > 128) return false;
  final Uint8List signature;
  try {
    signature = base64Decode(encodedSignature);
  } on FormatException {
    return false;
  }
  if (signature.length != _p256SignatureLength) return false;
  return verifyEcdsa(
    curve: ECCurve_secp256r1(),
    point: publicKey,
    digest: SHA256Digest(),
    message: Uint8List.fromList(manifest),
    r: unsignedBigInt(signature.sublist(0, 32)),
    s: unsignedBigInt(signature.sublist(32)),
  );
}
