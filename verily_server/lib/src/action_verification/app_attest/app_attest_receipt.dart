import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:verily_server/src/action_verification/app_attest/apple_receipt_root.dart';
import 'package:verily_server/src/action_verification/app_attest/receipt_ber.dart';
import 'package:verily_server/src/action_verification/key_attestation/der.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';

/// Verified Apple receipt data. Refresh windows control server-to-server calls;
/// creation freshness is checked when a receipt is first received, not on reuse.
final class AppAttestReceipt {
  const AppAttestReceipt({
    required this.createdAt,
    required this.notBefore,
    required this.expiresAt,
    required this.riskMetric,
  });

  final DateTime createdAt;
  final DateTime notBefore;
  final DateTime expiresAt;
  final int? riskMetric;
}

/// Verifies the PKCS#7 signature and a bounded certificate path to Apple G3,
/// then the App ID, creation time and P-256 public key in its signed payload.
///
/// Invalid receipts throw FormatException; no metric is trusted independently
/// of its receipt. Test anchors are injectable and never read from a request.
class AppAttestReceiptVerifier {
  AppAttestReceiptVerifier({X509Certificate? root})
    : root = root ?? appleReceiptRoot;

  final X509Certificate root;

  AppAttestReceipt verify({
    required List<int> receipt,
    required String appId,
    required List<int> publicKey,
    required DateTime now,
    required bool refreshed,
  }) {
    if (receipt.isEmpty || receipt.length > 32 * 1024) _invalid();
    final content = parseDer(normalizeReceiptBer(receipt)).sequence;
    if (content.length != 2 || content[0].objectIdentifier != _signedData) {
      _invalid();
    }
    final signed = content[1].explicit.sequence;
    if (signed.length != 5 || signed[0].smallInteger != 1) _invalid();
    final digests = signed[1].set;
    if (digests.length != 1 || _algorithm(digests.single) != _sha256) {
      _invalid();
    }
    final encapsulated = signed[2].sequence;
    if (encapsulated.length != 2 ||
        encapsulated[0].objectIdentifier != _data ||
        !encapsulated[1].isContext(0)) {
      _invalid();
    }
    final payload = encapsulated[1].explicit.octets;
    if (!signed[3].isContext(0)) _invalid();
    final certificates = signed[3].children
        .map((node) => X509Certificate.parse(node.encoded))
        .toList();
    if (certificates.isEmpty || certificates.length > 5) _invalid();
    final signers = signed[4].set;
    if (signers.length != 1) _invalid();
    final signer = signers.single.sequence;
    if (signer.length < 5 || signer[0].smallInteger != 1) _invalid();
    final issuerAndSerial = signer[1].sequence;
    if (issuerAndSerial.length != 2) _invalid();
    final leaf = certificates
        .where(
          (cert) =>
              _equal(cert.issuer.encoded, issuerAndSerial[0].encoded) &&
              cert.serialNumber == issuerAndSerial[1].integer,
        )
        .singleOrNull;
    if (leaf == null || _algorithm(signer[2]) != _sha256) _invalid();
    // G3 also anchors unrelated Apple services. Only an App Attest receipt
    // signing certificate may authorize a device metric.
    if (!leaf.extensions.containsKey('1.2.840.113635.100.12.15')) _invalid();
    final leafConstraints = leaf.extensions['2.5.29.19'];
    if (leafConstraints != null) {
      final basic = parseDer(leafConstraints).sequence;
      if (basic.isNotEmpty && basic.first.boolean) _invalid();
    }
    final leafUsage = leaf.extensions['2.5.29.15'];
    if (leafUsage != null) {
      final bits = parseDer(leafUsage).content;
      if (bits.length < 2 || bits[1] & 0x80 == 0) _invalid();
    }
    _verifyPath(leaf, certificates, now);

    var index = 3;
    var message = payload;
    if (signer[index].isContext(0)) {
      final attributes = signer[index++];
      final values = <String, DerElement>{};
      for (final attribute in attributes.children) {
        final parts = attribute.sequence;
        if (parts.length != 2) _invalid();
        final oid = parts[0].objectIdentifier;
        final set = parts[1].set;
        if (values.containsKey(oid) || set.length != 1) _invalid();
        values[oid] = set.single;
      }
      if (values[_contentType]?.objectIdentifier != _data ||
          !_equal(
            values[_messageDigest]?.octets ?? [],
            sha256.convert(payload).bytes,
          )) {
        _invalid();
      }
      // CMS signs the DER SET encoding, not its IMPLICIT context [0] tag.
      message = Uint8List.fromList(attributes.encoded)..[0] = 0x31;
    }
    if (signer.length != index + 2) _invalid();
    final algorithm = switch (_algorithm(signer[index])) {
      X509Oid.rsaEncryption => X509Oid.sha256WithRsa,
      X509Oid.sha256WithRsa => X509Oid.sha256WithRsa,
      X509Oid.ecdsaWithSha256 => X509Oid.ecdsaWithSha256,
      _ => throw const FormatException('Unsupported receipt signature.'),
    };
    if (!leaf.publicKey.verifies(
      message,
      algorithm,
      signer[index + 1].octets,
    )) {
      _invalid();
    }

    final fields = <int, Uint8List>{};
    for (final entry in parseDer(payload).set) {
      final parts = entry.sequence;
      if (parts.length != 3 || parts[1].smallInteger != 1) _invalid();
      final id = parts[0].smallInteger;
      if (fields.containsKey(id)) _invalid();
      fields[id] = parts[2].octets;
    }
    String text(int id) => utf8.decode(
      fields[id] ?? (throw const FormatException('Missing receipt field.')),
    );
    if (text(2) != appId || text(6) != (refreshed ? 'RECEIPT' : 'ATTEST')) {
      _invalid();
    }
    // Apple's DER object is the attested credential certificate, including
    // the same public key (the certificate itself expires after three days).
    final key = X509Certificate.parse(fields[3] ?? []).publicKey;
    if (key is! EcPublicKeyInfo ||
        !key.isP256 ||
        !_equal(key.point, publicKey)) {
      _invalid();
    }
    final created = _time(text(12));
    if (created.isAfter(now) ||
        now.difference(created) > const Duration(minutes: 5)) {
      _invalid();
    }
    final notBefore = fields.containsKey(19) ? _time(text(19)) : created;
    final expires = _time(text(21));
    if (!expires.isAfter(now) ||
        !expires.isAfter(notBefore) ||
        notBefore.isBefore(created)) {
      _invalid();
    }
    final metric = refreshed ? int.tryParse(text(17)) : null;
    if (refreshed &&
        (metric == null ||
            metric < 0 ||
            !RegExp(r'^\d{1,9}$').hasMatch(text(17)))) {
      _invalid();
    }
    return AppAttestReceipt(
      createdAt: created,
      notBefore: notBefore,
      expiresAt: expires,
      riskMetric: metric,
    );
  }

  void _verifyPath(
    X509Certificate leaf,
    List<X509Certificate> certificates,
    DateTime now,
  ) {
    var current = leaf;
    final seen = <String>{};
    for (var depth = 0; depth < 5; depth++) {
      _checkCriticalExtensions(current);
      if (!current.isValidAt(now) || !seen.add(base64Encode(current.encoded))) {
        _invalid();
      }
      if (current.issuer.matches(root.subject) &&
          current.isSignedBy(root.publicKey)) {
        if (!root.isValidAt(now)) _invalid();
        return;
      }
      final issuer = certificates
          .where(
            (cert) =>
                current.issuer.matches(cert.subject) &&
                current.isSignedBy(cert.publicKey),
          )
          .singleOrNull;
      if (issuer == null) _invalid();
      final constraints = issuer.extensions['2.5.29.19'];
      final basic = constraints == null
          ? <DerElement>[]
          : parseDer(constraints).sequence;
      if (basic.isEmpty || !basic.first.boolean) _invalid();
      final usage = issuer.extensions['2.5.29.15'];
      if (usage != null) {
        final bits = parseDer(usage).content;
        if (bits.length < 2 || bits[1] & 0x04 == 0) _invalid();
      }
      if (basic.length > 1 && depth > basic[1].smallInteger) _invalid();
      current = issuer;
    }
    _invalid();
  }
}

String _algorithm(DerElement node) {
  final parts = node.sequence;
  if (parts.isEmpty || parts.length > 2) _invalid();
  return parts.first.objectIdentifier;
}

DateTime _time(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$')
      .hasMatch(value)) {
    _invalid();
  }
  final parsed = DateTime.parse(value).toUtc();
  if (parsed.toIso8601String().substring(0, 19) != value.substring(0, 19)) {
    _invalid();
  }
  return parsed;
}

void _checkCriticalExtensions(X509Certificate certificate) {
  for (final field in parseDer(certificate.tbs).sequence) {
    if (!field.isContext(3)) continue;
    for (final extension in field.explicit.sequence) {
      final parts = extension.sequence;
      if (parts.length == 3 &&
          parts[1].boolean &&
          !const {
            '2.5.29.19',
            '2.5.29.15',
          }.contains(parts[0].objectIdentifier)) {
        _invalid();
      }
    }
  }
}

bool _equal(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Never _invalid() => throw const FormatException('Invalid App Attest receipt.');
const _signedData = '1.2.840.113549.1.7.2';
const _data = '1.2.840.113549.1.7.1';
const _sha256 = '2.16.840.1.101.3.4.2.1';
const _contentType = '1.2.840.113549.1.9.3';
const _messageDigest = '1.2.840.113549.1.9.4';
