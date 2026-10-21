import 'dart:typed_data';

import 'package:solana_kit/solana_kit.dart';
import 'package:verily_server/src/auth/solana_auth_verify.dart';
import 'package:verily_server/src/rewards/custody/kms_api_client.dart';

/// A Solana transaction signer backed by one Cloud KMS Ed25519 key version.
///
/// The private key never exists in this process. The signer binds itself to
/// the public key reported by KMS, refuses a deployment whose pinned address
/// differs from that key, and verifies every returned signature locally
/// before it is attached to a transaction.
final class KmsTransactionSigner implements TransactionPartialSigner {
  KmsTransactionSigner._({
    required KmsApiClient apiClient,
    required String resourceName,
    required this.address,
    required Uint8List publicKeyBytes,
  }) : client = apiClient,
       keyVersionName = resourceName,
       publicKeyBytes = Uint8List.fromList(publicKeyBytes);

  /// Loads the KMS public key and constructs the signer.
  ///
  /// A mismatch with [expectedAddress], the deployment-pinned key, fails
  /// closed instead of signing with an unregistered key.
  static Future<KmsTransactionSigner> create({
    required KmsApiClient client,
    required String keyVersionName,
    Address? expectedAddress,
  }) async {
    final key = await client.readEd25519Key(keyVersionName);
    if (key.algorithm != kmsEd25519Algorithm) {
      throw StateError('The Cloud KMS key is not an Ed25519 signing key.');
    }
    final address = getAddressDecoder().decode(key.publicKeyBytes);
    if (expectedAddress != null && address != expectedAddress) {
      throw StateError(
        'The Cloud KMS signer does not match its pinned address.',
      );
    }
    return KmsTransactionSigner._(
      apiClient: client,
      resourceName: keyVersionName,
      address: address,
      publicKeyBytes: key.publicKeyBytes,
    );
  }

  final KmsApiClient client;
  final String keyVersionName;
  final Uint8List publicKeyBytes;

  @override
  final Address address;

  /// Proves current signing power over this KMS key using [challenge].
  ///
  /// Run at startup so a disabled, mispointed, or read-only key fails before
  /// any gateway is exposed.
  Future<void> proveSigningPower(Uint8List challenge) async {
    if (challenge.length < 32) {
      throw ArgumentError.value(
        challenge.length,
        'challenge',
        'A challenge of at least 32 bytes is required.',
      );
    }
    final signature = await client.sign(keyVersionName, challenge);
    if (!verifySolanaSignature(
      publicKeyBytes: publicKeyBytes,
      messageBytes: challenge,
      signatureBytes: signature,
    )) {
      throw StateError('Cloud KMS could not prove control of the signing key.');
    }
  }

  @override
  Future<List<Map<Address, SignatureBytes>>> signTransactions(
    List<Transaction> transactions, [
    TransactionSignerConfig? config,
  ]) async {
    if (config?.aborted ?? false) {
      throw StateError('The Cloud KMS signing request was aborted.');
    }
    return [
      for (final transaction in transactions) await _signOne(transaction),
    ];
  }

  Future<Map<Address, SignatureBytes>> _signOne(
    Transaction transaction,
  ) async {
    final signature = await client.sign(
      keyVersionName,
      transaction.messageBytes,
    );
    if (!verifySolanaSignature(
      publicKeyBytes: publicKeyBytes,
      messageBytes: transaction.messageBytes,
      signatureBytes: signature,
    )) {
      throw StateError(
        'Cloud KMS returned a signature that failed local verification.',
      );
    }
    return {address: SignatureBytes(Uint8List.fromList(signature))};
  }
}
