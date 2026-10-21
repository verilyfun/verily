import 'dart:convert';
import 'dart:typed_data';

/// DER `SubjectPublicKeyInfo` prefix for an Ed25519 public key: twelve bytes
/// followed by the raw 32-byte key.
const List<int> ed25519SubjectPublicKeyInfoPrefix = [
  0x30,
  0x2a,
  0x30,
  0x05,
  0x06,
  0x03,
  0x2b,
  0x65,
  0x70,
  0x03,
  0x21,
  0x00,
];

/// Parses a Cloud KMS Ed25519 public key PEM block into its raw 32 bytes.
///
/// Strict by design: exactly one PEM block, no unexpected body lines, and the
/// decoded key must carry the Ed25519 `SubjectPublicKeyInfo` prefix. Anything
/// else is rejected instead of guessed at, because this value becomes a
/// Solana signing authority address.
Uint8List parseEd25519PublicKeyPem(String pem) {
  final lines = pem.trim().split(RegExp(r'\r?\n'));
  if (lines.length < 3 ||
      lines.first.trim() != '-----BEGIN PUBLIC KEY-----' ||
      lines.last.trim() != '-----END PUBLIC KEY-----') {
    throw const FormatException('A single PUBLIC KEY PEM block is required.');
  }
  final body = lines.sublist(1, lines.length - 1);
  if (body.any(
    (line) =>
        line.isEmpty ||
        line != line.trim() ||
        line.contains('-----') ||
        RegExp('[^A-Za-z0-9+/=]').hasMatch(line),
  )) {
    throw const FormatException('The public key PEM body is malformed.');
  }
  final Uint8List der;
  try {
    der = base64Decode(body.join());
  } on FormatException {
    throw const FormatException('The public key PEM body is not valid base64.');
  }
  if (der.length != ed25519SubjectPublicKeyInfoPrefix.length + 32 ||
      !_hasEd25519Prefix(der)) {
    throw const FormatException('The KMS public key is not an Ed25519 key.');
  }
  return Uint8List.fromList(
    der.sublist(ed25519SubjectPublicKeyInfoPrefix.length),
  );
}

bool _hasEd25519Prefix(Uint8List bytes) {
  for (
    var index = 0;
    index < ed25519SubjectPublicKeyInfoPrefix.length;
    index += 1
  ) {
    if (bytes[index] != ed25519SubjectPublicKeyInfoPrefix[index]) {
      return false;
    }
  }
  return true;
}
