import 'dart:typed_data';

import 'package:solana_kit/solana_kit.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/auth/solana_auth_verify.dart';
import 'package:verily_server/src/rewards/custody/kms_transaction_signer.dart';

import 'fake_kms_api_client.dart';

const _keyVersion =
    'projects/verily-dev/locations/europe-west2/keyRings/escrow/'
    'cryptoKeys/reward-arbiter/cryptoKeyVersions/1';

Address _addressOf(FakeKmsKey key) =>
    getAddressDecoder().decode(Uint8List.fromList(key.keyPair.publicKey));

Transaction _transactionFor(Address feePayer) => compileTransaction(
  createTransactionMessage(version: TransactionVersion.v0)
      .withFeePayer(feePayer)
      .withBlockhashLifetime(
        BlockhashLifetimeConstraint(
          blockhash: '11111111111111111111111111111111',
          lastValidBlockHeight: BigInt.from(5),
        ),
      )
      .appendInstructions([
        Instruction(
          programAddress: const Address('11111111111111111111111111111111'),
          accounts: const [],
          data: Uint8List(0),
        ),
      ]),
);

void main() {
  late FakeKmsApiClient client;
  late FakeKmsKey key;

  setUp(() {
    client = FakeKmsApiClient();
    key = FakeKmsKey();
    client.register(_keyVersion, key);
  });

  test('derives its address from the KMS public key', () async {
    final signer = await KmsTransactionSigner.create(
      client: client,
      keyVersionName: _keyVersion,
    );
    expect(signer.address, _addressOf(key));
  });

  test('accepts a matching pinned authority address', () async {
    final signer = await KmsTransactionSigner.create(
      client: client,
      keyVersionName: _keyVersion,
      expectedAddress: _addressOf(key),
    );
    expect(signer.address, _addressOf(key));
  });

  test('rejects a pinned authority that differs from the KMS key', () async {
    final other = FakeKmsKey();
    await expectLater(
      KmsTransactionSigner.create(
        client: client,
        keyVersionName: _keyVersion,
        expectedAddress: _addressOf(other),
      ),
      throwsStateError,
    );
  });

  test('signs transaction message bytes through KMS', () async {
    final signer = await KmsTransactionSigner.create(
      client: client,
      keyVersionName: _keyVersion,
    );
    final transaction = _transactionFor(signer.address);
    final signatures = await signer.signTransactions([transaction]);
    expect(signatures, hasLength(1));
    final entry = signatures.single;
    expect(entry.keys, contains(signer.address));
    final signature = entry[signer.address]!.value;
    expect(signature, hasLength(64));
    expect(
      verifySolanaSignature(
        publicKeyBytes: Uint8List.fromList(key.keyPair.publicKey),
        messageBytes: transaction.messageBytes,
        signatureBytes: signature,
      ),
      isTrue,
    );
    expect(client.signedKeyVersions, [_keyVersion]);
  });

  test('signs each transaction in a batch independently', () async {
    final signer = await KmsTransactionSigner.create(
      client: client,
      keyVersionName: _keyVersion,
    );
    final transactions = [
      _transactionFor(signer.address),
      _transactionFor(signer.address),
    ];
    final signatures = await signer.signTransactions(transactions);
    expect(signatures, hasLength(2));
    for (var index = 0; index < transactions.length; index += 1) {
      expect(
        verifySolanaSignature(
          publicKeyBytes: Uint8List.fromList(key.keyPair.publicKey),
          messageBytes: transactions[index].messageBytes,
          signatureBytes: signatures[index][signer.address]!.value,
        ),
        isTrue,
      );
    }
    expect(client.signedKeyVersions, hasLength(2));
  });

  test('refuses an aborted signing request', () async {
    final signer = await KmsTransactionSigner.create(
      client: client,
      keyVersionName: _keyVersion,
    );
    final transaction = _transactionFor(signer.address);
    await expectLater(
      signer.signTransactions([
        transaction,
      ], const TransactionSignerConfig(aborted: true)),
      throwsStateError,
    );
    expect(client.signedKeyVersions, isEmpty);
  });

  test('rejects a KMS signature that fails local verification', () async {
    key.corruptSignatures = true;
    final signer = await KmsTransactionSigner.create(
      client: client,
      keyVersionName: _keyVersion,
    );
    final transaction = _transactionFor(signer.address);
    await expectLater(
      signer.signTransactions([transaction]),
      throwsStateError,
    );
  });

  test('propagates a KMS signing rejection without signing', () async {
    key.rejectSigning = true;
    final signer = await KmsTransactionSigner.create(
      client: client,
      keyVersionName: _keyVersion,
    );
    final transaction = _transactionFor(signer.address);
    await expectLater(
      signer.signTransactions([transaction]),
      throwsStateError,
    );
  });

  test('proveSigningPower verifies a fresh challenge signature', () async {
    final signer = await KmsTransactionSigner.create(
      client: client,
      keyVersionName: _keyVersion,
    );
    final callsBefore = client.signedKeyVersions.length;
    await signer.proveSigningPower(Uint8List.fromList(List.filled(32, 9)));
    expect(client.signedKeyVersions.length, callsBefore + 1);
  });

  test('proveSigningPower rejects a short challenge', () async {
    final signer = await KmsTransactionSigner.create(
      client: client,
      keyVersionName: _keyVersion,
    );
    await expectLater(
      signer.proveSigningPower(Uint8List(16)),
      throwsArgumentError,
    );
    expect(client.signedKeyVersions, isEmpty);
  });

  test('proveSigningPower rejects a corrupted proof signature', () async {
    key.corruptSignatures = true;
    final signer = await KmsTransactionSigner.create(
      client: client,
      keyVersionName: _keyVersion,
    );
    await expectLater(
      signer.proveSigningPower(Uint8List.fromList(List.filled(32, 3))),
      throwsStateError,
    );
  });
}
