import 'dart:convert';
import 'dart:typed_data';

import 'package:solana_kit/solana_kit.dart';
import 'package:verily_server/src/rewards/custody/kms_api_client.dart';
import 'package:verily_server/src/rewards/custody/kms_ed25519_public_key.dart';

/// An in-memory Cloud KMS key backed by a real Ed25519 key pair, so tests
/// exercise the same signature verification and address derivation as
/// production without any network or Google account.
final class FakeKmsKey {
  FakeKmsKey({this.algorithm = 'EC_SIGN_ED25519'})
    : keyPair = generateKeyPair();

  final KeyPair keyPair;
  String algorithm;

  /// Return a well-formed but incorrect signature instead of throwing.
  bool corruptSignatures = false;

  /// Refuse signing entirely, like an IAM or disabled-key rejection.
  bool rejectSigning = false;
}

/// [KmsApiClient] stand-in serving [FakeKmsKey] entries.
final class FakeKmsApiClient implements KmsApiClient {
  FakeKmsApiClient();

  final Map<String, FakeKmsKey> keys = <String, FakeKmsKey>{};
  final List<String> signedKeyVersions = <String>[];
  bool closed = false;

  void register(String keyVersionName, FakeKmsKey key) =>
      keys[keyVersionName] = key;

  @override
  Future<KmsEd25519KeyView> readEd25519Key(String keyVersionName) async {
    final key = keys[keyVersionName];
    if (key == null) {
      throw StateError('Cloud KMS rejected the public key request.');
    }
    return KmsEd25519KeyView(
      keyVersionName: keyVersionName,
      algorithm: key.algorithm,
      protectionLevel: 'SOFTWARE',
      publicKeyBytes: Uint8List.fromList(key.keyPair.publicKey),
    );
  }

  @override
  Future<Uint8List> sign(String keyVersionName, Uint8List messageBytes) async {
    final key = keys[keyVersionName];
    if (key == null || key.rejectSigning) {
      throw StateError('Cloud KMS rejected the signing request.');
    }
    signedKeyVersions.add(keyVersionName);
    if (key.corruptSignatures) {
      return Uint8List(64);
    }
    return signBytes(key.keyPair.privateKey, messageBytes).value;
  }

  @override
  void close() => closed = true;
}

/// Encodes raw Ed25519 public key bytes as a single-line Cloud KMS PEM.
String encodeEd25519PublicKeyPem(Uint8List publicKeyBytes) {
  final body = base64Encode(
    Uint8List.fromList([
      ...ed25519SubjectPublicKeyInfoPrefix,
      ...publicKeyBytes,
    ]),
  );
  return '-----BEGIN PUBLIC KEY-----\n$body\n-----END PUBLIC KEY-----';
}
