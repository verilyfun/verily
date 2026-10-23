import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/app_attest/apple_device_client.dart';
import 'package:verily_server/src/action_verification/key_attestation/der.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';

import 'der_writer.dart';

/// Synthetic G3-like receipt authority. Never trusted by production.
final class TestReceiptAuthority {
  final _rootKey = TestEcKey('receipt-root');
  final _signer = TestEcKey('receipt-signer');
  final List<int> _rootName = derDistinguishedName([
    ('2.5.4.3', 'Test receipt root'),
  ]);
  final List<int> _name = derDistinguishedName([
    ('2.5.4.3', 'Test receipt signer'),
  ]);

  late final root = X509Certificate.parse(
    derCertificate(
      serial: BigInt.one,
      issuer: _rootName,
      subject: _rootName,
      subjectKey: _rootKey,
      signer: _rootKey,
      notBefore: DateTime.utc(2026),
      notAfter: DateTime.utc(2036),
    ),
  );

  Uint8List issue({
    required List<int> credential,
    required String appId,
    required DateTime now,
    int? metric,
    DateTime? notBefore,
    DateTime? expires,
    bool signedAttributes = false,
    bool corruptDigest = false,
    bool duplicateAppId = false,
    bool receiptPurpose = true,
  }) {
    List<int> attribute(int id, List<int> value) => derSequence([
      derInteger(BigInt.from(id)),
      derInteger(BigInt.one),
      derOctets(value),
    ]);
    final payload = derSet([
      attribute(2, utf8.encode(appId)),
      if (duplicateAppId) attribute(2, utf8.encode(appId)),
      attribute(3, credential),
      attribute(6, utf8.encode(metric == null ? 'ATTEST' : 'RECEIPT')),
      attribute(12, utf8.encode(now.toIso8601String())),
      if (metric != null) attribute(17, utf8.encode('$metric')),
      if (notBefore != null || metric != null)
        attribute(
          19,
          utf8.encode(
            (notBefore ?? now.add(const Duration(days: 1))).toIso8601String(),
          ),
        ),
      attribute(
        21,
        utf8.encode(
          (expires ?? now.add(const Duration(days: 30))).toIso8601String(),
        ),
      ),
    ]);
    final certificate = derCertificate(
      serial: BigInt.two,
      issuer: _rootName,
      subject: _name,
      subjectKey: _signer,
      signer: _rootKey,
      notBefore: DateTime.utc(2026),
      notAfter: DateTime.utc(2036),
      extensions: {
        if (receiptPurpose) '1.2.840.113635.100.12.15': derTlv([0x05], []),
      },
    );
    final attrs = derSet([
      derSequence([
        derOid('1.2.840.113549.1.9.3'),
        derSet([derOid('1.2.840.113549.1.7.1')]),
      ]),
      derSequence([
        derOid('1.2.840.113549.1.9.4'),
        derSet([
          derOctets(
            corruptDigest
                ? List.filled(32, 0)
                : SHA256Digest().process(Uint8List.fromList(payload)),
          ),
        ]),
      ]),
    ]);
    final implicitAttrs = [...attrs]..[0] = 0xa0;
    return Uint8List.fromList(
      derSequence([
        derOid('1.2.840.113549.1.7.2'),
        derExplicit(
          0,
          derSequence([
            derInteger(BigInt.one),
            derSet([
              derSequence([derOid('2.16.840.1.101.3.4.2.1')]),
            ]),
            derSequence([
              derOid('1.2.840.113549.1.7.1'),
              derExplicit(0, derOctets(payload)),
            ]),
            derTlv([0xa0], certificate),
            derSet([
              derSequence([
                derInteger(BigInt.one),
                derSequence([_rootName, derInteger(BigInt.two)]),
                derSequence([derOid('2.16.840.1.101.3.4.2.1')]),
                if (signedAttributes) implicitAttrs,
                derSequence([derOid(X509Oid.ecdsaWithSha256)]),
                derOctets(_signer.signDer(signedAttributes ? attrs : payload)),
              ]),
            ]),
          ]),
        ),
      ]),
    );
  }

  String refresh(String encoded, {required int metric, required DateTime now}) {
    final content = parseDer(base64Decode(encoded))
        .sequence[1]
        .explicit
        .sequence;
    final payload = content[2].sequence[1].explicit.octets;
    final fields = {
      for (final entry in parseDer(payload).set)
        entry.sequence[0].smallInteger: entry.sequence[2].octets,
    };
    return base64Encode(
      issue(
        credential: fields[3]!,
        appId: utf8.decode(fields[2]!),
        now: now,
        metric: metric,
      ),
    );
  }
}

/// Fake Apple HTTP boundary for integration tests; never needs a cloud key.
final class TestAppleDeviceClient implements AppleDeviceClient {
  TestAppleDeviceClient(this.receipts);
  final TestReceiptAuthority receipts;
  AppleDeviceBits bits = const AppleDeviceBits(
    banned: false,
    reviewRequired: false,
  );
  int metric = 2;
  bool unavailable = false;
  bool invalidReceipt = false;
  int refreshes = 0;

  @override
  Future<AppleDeviceBits> queryBits(Session session, String deviceToken) async {
    if (unavailable) throw const AppleDeviceUnavailable();
    return bits;
  }

  @override
  Future<String> refreshReceipt(Session session, String receipt) async {
    refreshes++;
    if (unavailable) throw const AppleDeviceUnavailable();
    if (invalidReceipt) return base64Encode([0]);
    return receipts.refresh(
      receipt,
      metric: metric,
      now: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> updateBits(
    Session session,
    String deviceToken,
    AppleDeviceBits bits,
  ) async {
    if (unavailable) throw const AppleDeviceUnavailable();
    this.bits = bits;
  }
}
