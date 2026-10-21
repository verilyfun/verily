import 'dart:convert';
import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed25519;
import 'package:test/test.dart';
import 'package:verily_server/src/auth/solana_auth_verify.dart';

void main() {
  group('Solana auth verification', () {
    test('verifies a valid Ed25519 signature', () {
      final keyPair = ed25519.generateKey();
      final messageBytes = Uint8List.fromList(utf8.encode('sign into verily'));
      final signatureBytes = ed25519.sign(keyPair.privateKey, messageBytes);

      expect(
        verifySolanaSignature(
          publicKeyBytes: Uint8List.fromList(keyPair.publicKey.bytes),
          messageBytes: messageBytes,
          signatureBytes: signatureBytes,
        ),
        isTrue,
      );
    });

    test('rejects a tampered message', () {
      final keyPair = ed25519.generateKey();
      final messageBytes = Uint8List.fromList(utf8.encode('sign into verily'));
      final signatureBytes = ed25519.sign(keyPair.privateKey, messageBytes);

      expect(
        verifySolanaSignature(
          publicKeyBytes: Uint8List.fromList(keyPair.publicKey.bytes),
          messageBytes: Uint8List.fromList(utf8.encode('different message')),
          signatureBytes: signatureBytes,
        ),
        isFalse,
      );
    });

    test('decodes base58 public keys and signatures with length checks', () {
      final keyPair = ed25519.generateKey();
      final messageBytes = Uint8List.fromList(utf8.encode('sign into verily'));
      final signatureBytes = ed25519.sign(keyPair.privateKey, messageBytes);

      final publicKey = base58.encoder.convert(
        Uint8List.fromList(keyPair.publicKey.bytes),
      );
      final signature = base58.encoder.convert(signatureBytes);

      expect(decodeBase58PublicKey(publicKey), hasLength(32));
      expect(decodeBase58Signature(signature), hasLength(64));
      expect(() => decodeBase58PublicKey(signature), throwsFormatException);
      expect(() => decodeBase58Signature(publicKey), throwsFormatException);
    });
  });
}
