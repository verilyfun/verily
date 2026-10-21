import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:verily_server/src/action_verification/key_attestation/attestation_status_list.dart';
import 'package:verily_server/src/action_verification/key_attestation/google_attestation_roots.dart';
import 'package:verily_server/src/action_verification/key_attestation/key_description.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';

/// The Android application id Play and the keystore attest.
const verilyAndroidPackageName = 'fun.verily.app';

/// Reason codes a key attestation verdict carries. Every code starts with
/// `capture_`, so participants see the public `capture_not_verified`.
abstract final class KeyAttestationReason {
  static const valid = 'capture_attestation_valid';
  static const chainInvalid = 'capture_attestation_chain_invalid';
  static const untrustedRoot = 'capture_attestation_untrusted_root';
  static const expired = 'capture_attestation_expired';
  static const revoked = 'capture_attestation_revoked';
  static const statusUnavailable = 'capture_attestation_status_unavailable';
  static const extensionInvalid = 'capture_attestation_extension_invalid';
  static const challengeMismatch = 'capture_attestation_challenge_mismatch';
  static const securityLevel = 'capture_attestation_security_level';
  static const bootUntrusted = 'capture_attestation_boot_untrusted';
  static const keyInvalid = 'capture_attestation_key_invalid';
  static const appMismatch = 'capture_attestation_app_mismatch';
  static const patchOutdated = 'capture_attestation_patch_outdated';
  static const unconfigured = 'capture_attestation_unconfigured';
}

/// What an attested capture key must prove about the device and the app.
final class KeyAttestationPolicy {
  const KeyAttestationPolicy({
    required this.signingCertificateDigests,
    this.packageName = verilyAndroidPackageName,
    this.maxPatchAgeMonths = 12,
  });

  /// Reads `VERILY_ANDROID_SIGNING_CERT_SHA256`: the release signing
  /// certificate's SHA-256 as hex (colons allowed), comma-separated when a
  /// rotation means more than one is live. Unset means no attestation can be
  /// trusted; an invalid value stops startup.
  factory KeyAttestationPolicy.fromEnvironment([Map<String, String>? values]) {
    final raw =
        (values ??
            Platform.environment)['VERILY_ANDROID_SIGNING_CERT_SHA256'] ??
        '';
    final digests = parseSigningCertificateDigests(raw);
    if (digests == null) throw StateError(signingCertificateDigestError);
    return KeyAttestationPolicy(signingCertificateDigests: digests);
  }

  final String packageName;

  /// Lowercase hex SHA-256 digests of the app's signing certificates.
  final Set<String> signingCertificateDigests;

  /// How old the OS security patch may be, in calendar months.
  final int maxPatchAgeMonths;
}

/// Parses `VERILY_ANDROID_SIGNING_CERT_SHA256`, or returns null when any
/// entry is not a SHA-256 digest. An empty value is an empty set.
Set<String>? parseSigningCertificateDigests(String raw) {
  final digests = <String>{};
  for (final entry in raw.split(',')) {
    final normalized = entry.trim().replaceAll(':', '').toLowerCase();
    if (normalized.isEmpty) continue;
    if (!_sha256Hex.hasMatch(normalized)) return null;
    digests.add(normalized);
  }
  return digests;
}

const signingCertificateDigestError =
    'VERILY_ANDROID_SIGNING_CERT_SHA256 must list SHA-256 digests of the '
    'release signing certificate as hex, separated by commas.';

final _sha256Hex = RegExp(r'^[0-9a-f]{64}$');

/// The outcome of verifying one Android Key Attestation chain.
final class KeyAttestationVerdict {
  const KeyAttestationVerdict.trusted({
    required Uint8List this.publicKey,
    required KeySecurityLevel this.securityLevel,
    this.deviceKeyId,
  }) : trusted = true,
       reasonCode = KeyAttestationReason.valid;

  const KeyAttestationVerdict.untrusted(this.reasonCode, {this.publicKey})
    : trusted = false,
      securityLevel = null,
      deviceKeyId = null;

  final bool trusted;
  final String reasonCode;

  /// The leaf's P-256 key, `0x04 ‖ X ‖ Y`, whenever the leaf parsed as one,
  /// so a signature can be checked even when the chain is not trusted.
  final Uint8List? publicKey;

  /// Where the attested key lives; set only when [trusted].
  final KeySecurityLevel? securityLevel;

  /// SHA-256 (hex) of the remotely provisioned attestation key that
  /// certified the capture key: hardware-bound, rotated by Google every few
  /// weeks, and the same for every capture from one device meanwhile.
  /// Factory-provisioned keys are shared by a batch of devices, so they give
  /// none.
  final String? deviceKeyId;
}

/// Verifies Android Key Attestation certificate chains.
// An injectable seam so tests can supply a deterministic verifier.
// ignore: one_member_abstracts
abstract interface class KeyAttestationVerifier {
  /// [chain] is DER certificates, leaf first, as `KeyStore.getCertificateChain`
  /// returns them. [challenge] is the attestation challenge the server
  /// expects in the leaf.
  Future<KeyAttestationVerdict> verify({
    required List<List<int>> chain,
    required List<int> challenge,
    required DateTime now,
  });
}

/// A port of the checks in Google's `android/keyattestation` verifier, with
/// Verily's policy on top.
///
/// Path validation follows that library: certificates chain by name and
/// signature up to a pinned root key; every certificate but the leaf must be
/// within its validity, except that expiry is ignored on factory-provisioned
/// chains whose keys cannot be rotated; no listed serial may appear; and
/// only the leaf may carry the attestation extension. Accepting the extension
/// solely on the leaf is the strict form of "parse it from the certificate
/// closest to the root": a key the device attested cannot extend the chain
/// with a certificate of its own.
final class AndroidKeyAttestationVerifier implements KeyAttestationVerifier {
  AndroidKeyAttestationVerifier({
    required this.policy,
    List<X509Certificate>? trustAnchors,
    AttestationStatusSource? statusSource,
  }) : trustAnchors = trustAnchors ?? googleAttestationRoots,
       statusSource = statusSource ?? GoogleAttestationStatusSource.shared;

  final KeyAttestationPolicy policy;
  final List<X509Certificate> trustAnchors;
  final AttestationStatusSource statusSource;

  @override
  Future<KeyAttestationVerdict> verify({
    required List<List<int>> chain,
    required List<int> challenge,
    required DateTime now,
  }) async {
    if (chain.length < 3 || chain.length > _maxChainLength) {
      return const KeyAttestationVerdict.untrusted(
        KeyAttestationReason.chainInvalid,
      );
    }
    final certificates = <X509Certificate>[];
    try {
      for (final der in chain) {
        if (der.length > _maxCertificateBytes) {
          return const KeyAttestationVerdict.untrusted(
            KeyAttestationReason.chainInvalid,
          );
        }
        certificates.add(X509Certificate.parse(der));
      }
    } on FormatException {
      return const KeyAttestationVerdict.untrusted(
        KeyAttestationReason.chainInvalid,
      );
    }

    final leafKey = certificates.first.publicKey;
    final publicKey = leafKey is EcPublicKeyInfo && leafKey.isP256
        ? leafKey.point
        : null;
    KeyAttestationVerdict untrusted(String reasonCode) =>
        KeyAttestationVerdict.untrusted(reasonCode, publicKey: publicKey);

    final pathFailure = await _validatePath(certificates, now);
    if (pathFailure != null) return untrusted(pathFailure);

    final path = certificates.sublist(0, certificates.length - 1);
    final KeyDescription description;
    final AttestationApplicationId? application;
    try {
      final extension = path.first.extensions[keyAttestationExtensionOid];
      if (extension == null) {
        return untrusted(KeyAttestationReason.extensionInvalid);
      }
      description = KeyDescription.parse(extension);
      application = description.attestationApplicationId;
    } on FormatException {
      return untrusted(KeyAttestationReason.extensionInvalid);
    }

    if (!_constantTimeEquals(description.attestationChallenge, challenge)) {
      return untrusted(KeyAttestationReason.challengeMismatch);
    }

    final securityLevel = description.keyMintSecurityLevel;
    if (description.attestationSecurityLevel != securityLevel ||
        securityLevel == KeySecurityLevel.software ||
        !_chainSupportsSecurityLevel(path, securityLevel)) {
      return untrusted(KeyAttestationReason.securityLevel);
    }

    final hardware = description.hardwareEnforced;
    final rootOfTrust = hardware.rootOfTrust;
    if (rootOfTrust == null ||
        rootOfTrust.verifiedBootState != VerifiedBootState.verified ||
        !rootOfTrust.deviceLocked) {
      return untrusted(KeyAttestationReason.bootUntrusted);
    }

    final p256 =
        hardware.ecCurve == KeyMintTag.ecCurveP256 ||
        (hardware.ecCurve == null && hardware.keySize == 256);
    if (publicKey == null ||
        hardware.origin != KeyMintTag.originGenerated ||
        hardware.algorithm != KeyMintTag.algorithmEc ||
        !p256 ||
        !(hardware.purposes?.contains(KeyMintTag.purposeSign) ?? false)) {
      return untrusted(KeyAttestationReason.keyInvalid);
    }

    if (policy.signingCertificateDigests.isEmpty) {
      return untrusted(KeyAttestationReason.unconfigured);
    }
    if (application == null ||
        !application.packageNames.contains(policy.packageName) ||
        !application.signatureDigests.any(
          policy.signingCertificateDigests.contains,
        )) {
      return untrusted(KeyAttestationReason.appMismatch);
    }

    if (!_patchWithinPolicy(hardware.osPatchLevel, now)) {
      return untrusted(KeyAttestationReason.patchOutdated);
    }

    return KeyAttestationVerdict.trusted(
      publicKey: publicKey,
      securityLevel: securityLevel,
      deviceKeyId: _provisioning(path) == _Provisioning.remote
          ? sha256.convert(path[1].subjectPublicKeyInfo).toString()
          : null,
    );
  }

  /// Returns a reason code when the chain does not validate, else null.
  Future<String?> _validatePath(
    List<X509Certificate> certificates,
    DateTime now,
  ) async {
    // The device's root is only a pointer: the pinned anchor's key is what
    // verifies the top of the path.
    final root = certificates.last;
    final path = certificates.sublist(0, certificates.length - 1);
    if (!root.isSelfIssued) return KeyAttestationReason.untrustedRoot;
    final top = path.last;
    final anchor = trustAnchors
        .where(
          (anchor) =>
              anchor.subject.matches(top.issuer) &&
              top.isSignedBy(anchor.publicKey),
        )
        .firstOrNull;
    if (anchor == null) return KeyAttestationReason.untrustedRoot;

    final factory = _provisioning(path) == _Provisioning.factory;
    for (var index = path.length - 1; index >= 0; index -= 1) {
      final certificate = path[index];
      final issuer = index == path.length - 1 ? anchor : path[index + 1];
      if (index != path.length - 1 &&
          (!certificate.issuer.matches(issuer.subject) ||
              !certificate.isSignedBy(issuer.publicKey))) {
        return KeyAttestationReason.chainInvalid;
      }
      if (index > 0 &&
          certificate.extensions.containsKey(keyAttestationExtensionOid)) {
        return KeyAttestationReason.chainInvalid;
      }
      // The leaf's validity is written by the device, so it proves nothing.
      if (index == 0) continue;
      if (now.isBefore(certificate.notBefore)) {
        return KeyAttestationReason.expired;
      }
      if (now.isAfter(certificate.notAfter) && !factory) {
        return KeyAttestationReason.expired;
      }
    }

    final AttestationStatusList status;
    try {
      status = await statusSource.statusAt(now);
    } on AttestationStatusUnavailable {
      return KeyAttestationReason.statusUnavailable;
    }
    if (path.any((certificate) => status.lists(certificate.serialHex))) {
      return KeyAttestationReason.revoked;
    }
    return null;
  }

  bool _patchWithinPolicy(int? patchLevel, DateTime now) {
    if (patchLevel == null) return false;
    final year = patchLevel ~/ 100;
    final month = patchLevel % 100;
    if (year < 2000 || month < 1 || month > 12) return false;
    final current = now.toUtc();
    final age = (current.year * 12 + current.month) - (year * 12 + month);
    // A patch newer than today (a beta build) is not stale.
    return age <= policy.maxPatchAgeMonths;
  }
}

enum _Provisioning { factory, remote, unknown }

/// Factory chains name their batch intermediate by serial number; remotely
/// provisioned chains run through Google's "Droid CA2".
_Provisioning _provisioning(List<X509Certificate> path) {
  final intermediate = path.last.subject;
  if (intermediate.attribute(X509Oid.serialNumber) != null) {
    return _Provisioning.factory;
  }
  if (intermediate.attribute(X509Oid.commonName) == 'Droid CA2' &&
      intermediate.attribute(X509Oid.organization) == 'Google LLC') {
    return _Provisioning.remote;
  }
  return _Provisioning.unknown;
}

/// A StrongBox key must come from a chain that says StrongBox, so a TEE
/// chain can never claim the stronger level. Older TEE chains make no
/// claim at all, which is allowed.
bool _chainSupportsSecurityLevel(
  List<X509Certificate> path,
  KeySecurityLevel level,
) {
  if (path.length < 2) return false;
  final attestation = path[1].subject;
  final claim = switch (_provisioning(path)) {
    _Provisioning.remote => switch (attestation.attribute(
      X509Oid.organization,
    )) {
      'StrongBox' => KeySecurityLevel.strongBox,
      'TEE' => KeySecurityLevel.trustedEnvironment,
      _ => KeySecurityLevel.software,
    },
    _Provisioning.factory =>
      [attestation, path.last.subject].any(
            (name) => name.mentions('strongbox'),
          )
          ? KeySecurityLevel.strongBox
          : null,
    _Provisioning.unknown => null,
  };
  return switch (level) {
    KeySecurityLevel.strongBox => claim == KeySecurityLevel.strongBox,
    KeySecurityLevel.trustedEnvironment =>
      claim == null || claim == KeySecurityLevel.trustedEnvironment,
    KeySecurityLevel.software => false,
  };
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}

const _maxChainLength = 10;
const int _maxCertificateBytes = 16 * 1024;
