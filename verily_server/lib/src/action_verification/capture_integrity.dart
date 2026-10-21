import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/action_verification/capture_signature_verifier.dart';
import 'package:verily_server/src/action_verification/device_integrity_verifier.dart';
import 'package:verily_server/src/action_verification/key_attestation/android_key_attestation_verifier.dart';
import 'package:verily_server/src/action_verification/key_attestation/key_description.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/security/secret_digest.dart';

/// Clock skew tolerated between the device and the server.
const captureClockTolerance = Duration(minutes: 2);

/// Integrity providers recorded on capture challenges and decisions.
abstract final class CaptureIntegrityProvider {
  /// A key Google's attestation chain vouches for signed the capture.
  static const keyAttestation = 'android-key-attestation';

  /// A device key signed the capture, but its attestation was not trusted.
  static const unattestedSignature = 'android-keystore';

  /// Only the capture challenge bound the proof.
  static const challengeOnly = 'capture-challenge';
}

/// Device-side provenance material submitted with one proof.
final class CaptureIntegrityMaterial {
  const CaptureIntegrityMaterial({
    this.captureChallengeId,
    this.deviceIntegrityToken,
    this.captureManifest,
    this.captureSignature,
    this.captureCertificateChain,
  });

  final UuidValue? captureChallengeId;
  final String? deviceIntegrityToken;
  final String? captureManifest;
  final String? captureSignature;

  /// Base64 DER certificates, leaf first.
  final List<String>? captureCertificateChain;

  bool get hasSignatureMaterial =>
      [
        captureManifest,
        captureSignature,
      ].any((value) => value?.trim().isNotEmpty ?? false) ||
      (captureCertificateChain?.isNotEmpty ?? false);
}

/// The outcome of checking capture provenance for one proof.
final class CaptureIntegrityResult {
  const CaptureIntegrityResult({
    required this.trusted,
    required this.reasonCode,
    required this.provider,
    this.challengeId,
    this.requestHash,
    this.evidenceBindingHash,
    this.tokenHash,
    this.provenanceLevel = EvidenceProvenanceLevel.basic,
    this.reviewReasonCode,
    this.captureManifest,
    this.captureSignature,
    this.capturePublicKey,
    this.captureKeyId,
    this.captureKeyStorage,
    this.captureCertificateChain,
    this.captureDeviceKeyId,
  });

  final bool trusted;
  final String reasonCode;
  final String provider;
  final UuidValue? challengeId;

  /// The Play Integrity request hash and evidence fingerprint this proof
  /// was bound to, recorded on the challenge when it is consumed.
  final String? requestHash;
  final String? evidenceBindingHash;
  final String? tokenHash;
  final EvidenceProvenanceLevel provenanceLevel;

  /// Set when a trusted capture carries a device risk a person should weigh
  /// before the proof is decided.
  final String? reviewReasonCode;
  final String? captureManifest;
  final String? captureSignature;
  final String? capturePublicKey;
  final String? captureKeyId;
  final String? captureKeyStorage;
  final List<String>? captureCertificateChain;
  final String? captureDeviceKeyId;
}

/// Checks that a proof was captured inside one capture window the server
/// opened before recording, and verifies the Play Integrity verdict and the
/// attested capture-key signature that commit to the exact evidence
/// fingerprint the server recomputed.
class CaptureIntegrityEvaluator {
  CaptureIntegrityEvaluator({
    DeviceIntegrityVerifier? deviceIntegrityVerifier,
    bool? deviceIntegrityRequired,
    KeyAttestationVerifier? keyAttestationVerifier,
    bool? captureSignatureRequired,
    DateTime Function()? clock,
  }) : deviceIntegrityVerifier =
           deviceIntegrityVerifier ??
           GooglePlayIntegrityVerifier(
             signingCertificateDigests: KeyAttestationPolicy.fromEnvironment()
                 .signingCertificateDigests,
           ),
       deviceIntegrityRequired =
           deviceIntegrityRequired ?? deviceIntegrityRequiredFromEnvironment(),
       keyAttestationVerifier =
           keyAttestationVerifier ??
           AndroidKeyAttestationVerifier(
             policy: KeyAttestationPolicy.fromEnvironment(),
           ),
       captureSignatureRequired =
           captureSignatureRequired ??
           captureSignatureRequiredFromEnvironment(),
       clock = clock ?? (() => DateTime.now().toUtc());

  final DeviceIntegrityVerifier deviceIntegrityVerifier;
  final bool deviceIntegrityRequired;
  final KeyAttestationVerifier keyAttestationVerifier;

  /// When true, every proof needs a manifest signed by a key whose
  /// attestation verifies. When false, an unattested signature is recorded
  /// as `deviceSigned`, so emulators and debug builds still work.
  final bool captureSignatureRequired;
  final DateTime Function() clock;

  /// Returns null when no provenance is required and none was sent.
  ///
  /// [evidenceBindingHash] is the fingerprint the server computed from the
  /// evidence it accepted, never one the client claims. [capturedAt] must
  /// not precede the capture window. [requireStrongIntegrity] raises the
  /// Play Integrity bar for proof whose reward is above the review
  /// threshold.
  Future<CaptureIntegrityResult?> evaluate(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required UuidValue requirementId,
    required CaptureIntegrityMaterial material,
    required String Function() evidenceBindingHash,
    required DateTime capturedAt,
    bool requireStrongIntegrity = false,
  }) async {
    final challengeId = material.captureChallengeId;
    final token = material.deviceIntegrityToken?.trim();
    final hasSignatureMaterial = material.hasSignatureMaterial;
    if (challengeId == null) {
      if (!deviceIntegrityRequired &&
          !captureSignatureRequired &&
          token == null &&
          !hasSignatureMaterial) {
        return null;
      }
      return CaptureIntegrityResult(
        trusted: false,
        reasonCode: deviceIntegrityRequired
            ? 'device_integrity_required'
            : 'capture_signature_required',
        provider: deviceIntegrityRequired
            ? deviceIntegrityVerifier.providerName
            : CaptureIntegrityProvider.keyAttestation,
      );
    }
    if (token != null && token.length > 32768) {
      throw ArgumentError('Device integrity proof is too large.');
    }
    final manifest = material.captureManifest?.trim();
    final signature = material.captureSignature?.trim();
    final chain = material.captureCertificateChain;
    if (manifest != null && manifest.length > 4096) {
      throw ArgumentError('Capture manifest is too large.');
    }
    if (chain != null &&
        (chain.length > _maxChainCertificates ||
            chain.any((entry) => entry.length > _maxEncodedCertificate))) {
      throw ArgumentError('Capture attestation is too large.');
    }

    final now = clock().toUtc();
    final challenge = await ActionCaptureChallenge.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(challengeId) &
          table.attemptId.equals(attemptId) &
          table.requirementId.equals(requirementId) &
          table.participantAuthUserId.equals(authUserId) &
          table.usedAt.equals(null) &
          (table.expiresAt > now),
    );
    if (challenge == null) {
      return CaptureIntegrityResult(
        trusted: false,
        reasonCode: 'capture_challenge_invalid',
        provider: deviceIntegrityVerifier.providerName,
      );
    }
    final tokenHash = token == null || token.isEmpty
        ? null
        : secretSha256Hex(token);
    if (capturedAt.toUtc().isBefore(
      challenge.createdAt.subtract(captureClockTolerance),
    )) {
      return CaptureIntegrityResult(
        trusted: false,
        reasonCode: 'capture_predates_challenge',
        provider: CaptureIntegrityProvider.challengeOnly,
        challengeId: challenge.id,
        tokenHash: tokenHash,
      );
    }
    final bindingHash = evidenceBindingHash();
    final requestHash = captureIntegrityRequestHash(
      attemptId: attemptId.toString(),
      requirementId: requirementId.toString(),
      captureChallenge: challenge.nonce,
      evidenceBindingHash: bindingHash,
    );
    CaptureIntegrityResult failure(String reasonCode, String provider) =>
        CaptureIntegrityResult(
          trusted: false,
          reasonCode: reasonCode,
          provider: provider,
          challengeId: challenge.id,
          requestHash: requestHash,
          evidenceBindingHash: bindingHash,
          tokenHash: tokenHash,
        );

    DeviceIntegrityVerdict? integrityVerdict;
    if (token == null || token.isEmpty) {
      if (deviceIntegrityRequired) {
        return failure(
          'device_integrity_required',
          deviceIntegrityVerifier.providerName,
        );
      }
    } else {
      integrityVerdict = await deviceIntegrityVerifier.verify(
        session,
        token: token,
        requestHash: requestHash,
        now: now,
        requireStrongIntegrity: requireStrongIntegrity,
      );
      if (!integrityVerdict.trusted) {
        return failure(integrityVerdict.reasonCode, integrityVerdict.provider);
      }
    }

    final hasCompleteSignature =
        (manifest?.isNotEmpty ?? false) &&
        (signature?.isNotEmpty ?? false) &&
        (chain?.isNotEmpty ?? false);
    if (hasSignatureMaterial && !hasCompleteSignature) {
      return failure(
        'capture_signature_incomplete',
        CaptureIntegrityProvider.keyAttestation,
      );
    }
    if (!hasCompleteSignature && captureSignatureRequired) {
      return failure(
        'capture_signature_required',
        CaptureIntegrityProvider.keyAttestation,
      );
    }

    _SignedCapture? signed;
    if (hasCompleteSignature) {
      final outcome = await _verifySignedCapture(
        session,
        attemptId: attemptId,
        requirementId: requirementId,
        nonce: challenge.nonce,
        requestHash: requestHash,
        bindingHash: bindingHash,
        manifest: manifest!,
        signature: signature!,
        chain: chain!,
        now: now,
      );
      switch (outcome) {
        case _SignatureRefused(:final reasonCode):
          return failure(reasonCode, CaptureIntegrityProvider.keyAttestation);
        case final _SignedCapture capture:
          signed = capture;
      }
    }

    final integrityTrusted = integrityVerdict?.trusted ?? false;
    final attested = signed?.attestation.trusted ?? false;
    final provenanceLevel = attested
        ? EvidenceProvenanceLevel.hardwareAttested
        : signed != null
        ? EvidenceProvenanceLevel.deviceSigned
        : integrityTrusted
        ? EvidenceProvenanceLevel.appAttested
        : EvidenceProvenanceLevel.basic;
    final providers = [
      if (integrityTrusted) integrityVerdict!.provider,
      if (attested)
        CaptureIntegrityProvider.keyAttestation
      else if (signed != null)
        CaptureIntegrityProvider.unattestedSignature,
    ];
    final reasonCode = switch (provenanceLevel) {
      EvidenceProvenanceLevel.hardwareAttested => KeyAttestationReason.valid,
      EvidenceProvenanceLevel.deviceSigned => 'capture_signature_valid',
      EvidenceProvenanceLevel.appAttested => integrityVerdict!.reasonCode,
      EvidenceProvenanceLevel.basic => 'capture_challenge_bound',
    };
    final publicKey = signed?.attestation.publicKey;
    return CaptureIntegrityResult(
      trusted: true,
      reasonCode: reasonCode,
      provider: providers.isEmpty
          ? CaptureIntegrityProvider.challengeOnly
          : providers.join('+'),
      challengeId: challenge.id,
      requestHash: requestHash,
      evidenceBindingHash: bindingHash,
      tokenHash: tokenHash,
      provenanceLevel: provenanceLevel,
      reviewReasonCode: integrityVerdict?.reviewReasonCode,
      captureManifest: signed == null ? null : manifest,
      captureSignature: signed == null ? null : signature,
      capturePublicKey: publicKey == null ? null : base64Encode(publicKey),
      captureKeyId: publicKey == null ? null : capturePublicKeyId(publicKey),
      captureKeyStorage: switch (signed?.attestation.securityLevel) {
        KeySecurityLevel.strongBox => 'strongBox',
        KeySecurityLevel.trustedEnvironment => 'trustedEnvironment',
        KeySecurityLevel.software || null => null,
      },
      captureCertificateChain: signed == null ? null : chain,
      captureDeviceKeyId: signed?.attestation.deviceKeyId,
    );
  }

  /// Checks the manifest, the attestation of the key that signed it, and
  /// the signature itself.
  Future<_SignatureOutcome> _verifySignedCapture(
    Session session, {
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String nonce,
    required String requestHash,
    required String bindingHash,
    required String manifest,
    required String signature,
    required List<String> chain,
    required DateTime now,
  }) async {
    final expectedManifest = captureProvenanceManifest(
      attemptId: attemptId.toString(),
      requirementId: requirementId.toString(),
      requestHash: requestHash,
      evidenceBindingHash: bindingHash,
    );
    if (!constantTimeEquals(base64Encode(expectedManifest), manifest)) {
      return const _SignatureRefused('capture_manifest_mismatch');
    }
    final List<Uint8List> certificates;
    try {
      certificates = [for (final entry in chain) base64Decode(entry.trim())];
    } on FormatException {
      return const _SignatureRefused(KeyAttestationReason.chainInvalid);
    }
    final attestation = await keyAttestationVerifier.verify(
      chain: certificates,
      challenge: captureKeyAttestationChallenge(
        captureChallenge: nonce,
        attemptId: attemptId.toString(),
      ),
      now: now,
    );
    final publicKey = attestation.publicKey;
    if (publicKey == null) {
      // Without a P-256 leaf there is nothing to check the signature with.
      return _SignatureRefused(
        attestation.reasonCode == KeyAttestationReason.chainInvalid
            ? KeyAttestationReason.chainInvalid
            : KeyAttestationReason.keyInvalid,
      );
    }
    if (!verifyCaptureSignature(
      manifest: expectedManifest,
      encodedSignature: signature,
      publicKey: publicKey,
    )) {
      return const _SignatureRefused('capture_signature_invalid');
    }
    if (!attestation.trusted) {
      if (captureSignatureRequired) {
        return _SignatureRefused(attestation.reasonCode);
      }
      session.log(
        'Capture key attestation was not trusted '
        '(${attestation.reasonCode}); recorded as an unattested signature.',
        level: LogLevel.info,
      );
    }
    return _SignedCapture(attestation);
  }
}

sealed class _SignatureOutcome {
  const _SignatureOutcome();
}

final class _SignatureRefused extends _SignatureOutcome {
  const _SignatureRefused(this.reasonCode);

  final String reasonCode;
}

final class _SignedCapture extends _SignatureOutcome {
  const _SignedCapture(this.attestation);

  final KeyAttestationVerdict attestation;
}

// A chain is a handful of certificates of one to two kilobytes each.
const _maxChainCertificates = 10;
const _maxEncodedCertificate = 22000;

/// Rejects capture configuration that is malformed or would refuse every
/// proof: both modes must parse, the signing-certificate digests must be
/// SHA-256 hex, and required signatures need at least one digest.
void validateCaptureIntegrityConfiguration(Map<String, String> environment) {
  deviceIntegrityRequiredFromEnvironment(environment);
  final policy = KeyAttestationPolicy.fromEnvironment(environment);
  if (captureSignatureRequiredFromEnvironment(environment) &&
      policy.signingCertificateDigests.isEmpty) {
    throw StateError(
      'VERILY_CAPTURE_SIGNATURE_MODE=required needs '
      'VERILY_ANDROID_SIGNING_CERT_SHA256.',
    );
  }
}

/// `VERILY_DEVICE_INTEGRITY_MODE`: `disabled` (default) or `required`.
bool deviceIntegrityRequiredFromEnvironment([Map<String, String>? values]) {
  return switch ((values ??
      Platform.environment)['VERILY_DEVICE_INTEGRITY_MODE']) {
    null || '' || 'disabled' => false,
    'required' => true,
    final value => throw StateError(
      'VERILY_DEVICE_INTEGRITY_MODE must be disabled or required, not $value.',
    ),
  };
}

/// `VERILY_CAPTURE_SIGNATURE_MODE`: `optional` (default) or `required`.
///
/// `required` means every proof carries a manifest signed by a fresh key
/// whose Android Key Attestation verifies under
/// `VERILY_ANDROID_SIGNING_CERT_SHA256`.
bool captureSignatureRequiredFromEnvironment([Map<String, String>? values]) {
  return switch ((values ??
      Platform.environment)['VERILY_CAPTURE_SIGNATURE_MODE']) {
    null || '' || 'optional' => false,
    'required' => true,
    final value => throw StateError(
      'VERILY_CAPTURE_SIGNATURE_MODE must be optional or required, not $value.',
    ),
  };
}
