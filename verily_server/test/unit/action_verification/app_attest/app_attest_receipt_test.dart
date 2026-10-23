import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_receipt.dart';
import 'package:verily_server/src/action_verification/app_attest/cbor.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';

import '../../../integration/test_tools/app_attest_test_authority.dart';
import '../../../integration/test_tools/apple_device_test_authority.dart';

void main() {
  test(
    'Apple published BER receipt verifies against pinned G3, key and App ID',
    () {
      final json = jsonDecode(
        File(
          'test/unit/action_verification/app_attest/vectors/apple-sample-attestation.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final attestation =
          decodeCbor(base64Decode(json['attestation'] as String)) as Map;
      final statement = attestation['attStmt'] as Map;
      final key =
          X509Certificate.parse((statement['x5c'] as List).first as List<int>)
                  .publicKey
              as EcPublicKeyInfo;
      final verifier = AppAttestReceiptVerifier();
      AppAttestReceipt verify({
        String? appId,
        List<int>? publicKey,
        DateTime? now,
        List<int>? receipt,
      }) => verifier.verify(
        receipt: receipt ?? statement['receipt'] as List<int>,
        appId: appId ?? '${json['appIdPrefix']}.${json['bundleId']}',
        publicKey: publicKey ?? key.point,
        now: now ?? DateTime.parse('2026-04-21T18:13:13Z'),
        refreshed: false,
      );
      expect(verify().riskMetric, isNull);
      expect(verify().createdAt, DateTime.parse('2026-04-21T18:13:12.153Z'));
      expect(() => verify(appId: 'another.app'), throwsFormatException);
      expect(
        () => verify(publicKey: List.filled(65, 0)),
        throwsFormatException,
      );
      expect(
        () => verify(now: DateTime.parse('2026-04-21T18:18:13Z')),
        throwsFormatException,
      );
      expect(
        () => verify(now: DateTime.parse('2026-04-21T18:13:11Z')),
        throwsFormatException,
      );
      final tampered = List<int>.from(statement['receipt'] as List<int>);
      tampered[tampered.length - 12] ^= 1;
      expect(() => verify(receipt: tampered), throwsFormatException);
      expect(
        () => verify(receipt: [...statement['receipt'] as List<int>, 0]),
        throwsFormatException,
      );
      expect(() => verify(receipt: [0x30, 0x80]), throwsFormatException);
    },
  );

  final authority = TestAppAttestAuthority();
  final receipts = authority.receipts;
  final key = authority.attest(clientDataHash: List.filled(32, 0));
  final att = decodeCbor(key.attestationObject) as Map;
  final certificate =
      ((att['attStmt'] as Map)['x5c'] as List).first as List<int>;
  final now = DateTime.utc(2026, 10, 23);
  final verifier = AppAttestReceiptVerifier(root: receipts.root);
  AppAttestReceipt verify(List<int> receipt, {bool refreshed = true}) =>
      verifier.verify(
        receipt: receipt,
        appId: testAppleAppId,
        publicKey: key.publicKey,
        now: now,
        refreshed: refreshed,
      );

  test(
    'direct and signed-attribute receipts expose only a verified metric',
    () {
      for (final attrs in [false, true]) {
        final receipt = receipts.issue(
          credential: certificate,
          appId: testAppleAppId,
          now: now,
          metric: 11,
          signedAttributes: attrs,
        );
        expect(verify(receipt).riskMetric, 11);
        expect(verify(receipt).notBefore, now.add(const Duration(days: 1)));
      }
    },
  );

  test(
    'wrong signer, digest, duplicate fields, type, key or times fail closed',
    () {
      final valid = receipts.issue(
        credential: certificate,
        appId: testAppleAppId,
        now: now,
        metric: 2,
      );
      expect(
        () =>
            AppAttestReceiptVerifier(root: TestReceiptAuthority().root).verify(
              receipt: valid,
              appId: testAppleAppId,
              publicKey: key.publicKey,
              now: now,
              refreshed: false,
            ),
        throwsFormatException,
      );
      for (final receipt in [
        receipts.issue(
          credential: certificate,
          appId: testAppleAppId,
          now: now,
          metric: 2,
          receiptPurpose: false,
        ),
        receipts.issue(
          credential: certificate,
          appId: testAppleAppId,
          now: now,
          metric: 2,
          signedAttributes: true,
          corruptDigest: true,
        ),
        receipts.issue(
          credential: certificate,
          appId: testAppleAppId,
          now: now,
          metric: 2,
          duplicateAppId: true,
        ),
        receipts.issue(
          credential: certificate,
          appId: testAppleAppId,
          now: now,
        ),
        receipts.issue(
          credential: certificate,
          appId: testAppleAppId,
          now: now.subtract(const Duration(minutes: 6)),
          metric: 2,
        ),
        receipts.issue(
          credential: certificate,
          appId: testAppleAppId,
          now: now.add(const Duration(seconds: 1)),
          metric: 2,
        ),
        receipts.issue(
          credential: certificate,
          appId: testAppleAppId,
          now: now,
          metric: -1,
        ),
        receipts.issue(
          credential: certificate,
          appId: testAppleAppId,
          now: now,
          metric: 2,
          expires: now,
        ),
        receipts.issue(
          credential: certificate,
          appId: testAppleAppId,
          now: now,
          metric: 2,
          notBefore: now.add(const Duration(days: 31)),
        ),
        Uint8List(32769),
      ]) {
        expect(() => verify(receipt), throwsFormatException);
      }
      expect(
        () => AppAttestReceiptVerifier(root: authority.root).verify(
          receipt: valid,
          appId: testAppleAppId,
          publicKey: key.publicKey,
          now: now,
          refreshed: true,
        ),
        throwsFormatException,
      );
    },
  );
}
