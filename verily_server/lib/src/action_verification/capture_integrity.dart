import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_service.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_verifier.dart';
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

  /// An iPhone's registered App Attest key asserted the capture's manifest.
  static const appAttest = 'apple-app-attest';

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
    this.captureAppAttestKeyId,
    this.captureDeviceCheckToken,
  });

  final UuidValue? captureChallengeId;
  final String? deviceIntegrityToken;
  final String? captureManifest;

  /// An Android key's P1363 signature, or an iPhone's App Attest assertion.
  final String? captureSignature;

  /// The Android key's attestation: base64 DER certificates, leaf first.
  final List<String>? captureCertificateChain;

  /// The iPhone's registered App Attest key identifier, base64.
  final String? captureAppAttestKeyId;
  final String? captureDeviceCheckToken;

  bool get hasSignatureMaterial =>
      [
        captureManifest,
        captureSignature,
        captureAppAttestKeyId,
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
/// device signature (an attested Android capture key, or an iPhone's App
/// Attest assertion) that commit to the exact evidence fingerprint the server
/// recomputed.
class CaptureIntegrityEvaluator {
  CaptureIntegrityEvaluator({
    DeviceIntegrityVerifier? deviceIntegrityVerifier,
    bool? deviceIntegrityRequired,
    KeyAttestationVerifier? keyAttestationVerifier,
    AppAttestService? appAttest,
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
       appAttest = appAttest ?? AppAttestService.fromEnvironment(),
       captureSignatureRequired =
           captureSignatureRequired ??
           captureSignatureRequiredFromEnvironment(),
       clock = clock ?? (() => DateTime.now().toUtc());

  final DeviceIntegrityVerifier deviceIntegrityVerifier;
  final bool deviceIntegrityRequired;
  final KeyAttestationVerifier keyAttestationVerifier;
  final AppAttestService appAttest;

  /// When true, every proof needs a manifest signed by a key whose
  /// attestation verifies: an attested Android key or a registered App
  /// Attest key. When false, an unattested Android signature is recorded as
  /// `deviceSigned`, so emulators and debug builds still work.
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
    final appAttestKeyId = material.captureAppAttestKeyId?.trim();
    if (manifest != null && manifest.length > 4096) {
      throw ArgumentError('Capture manifest is too large.');
    }
    if (signature != null && signature.length > 4096) {
      throw ArgumentError('Capture signature is too large.');
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

    final hasChain = chain?.isNotEmpty ?? false;
    final hasAppAttestKey = appAttestKeyId?.isNotEmpty ?? false;
    final signatureProvider = hasAppAttestKey
        ? CaptureIntegrityProvider.appAttest
        : CaptureIntegrityProvider.keyAttestation;
    // A signature names its key one way: an Android chain or an App Attest
    // key, never both.
    if (hasChain && hasAppAttestKey) {
      return failure('capture_signature_ambiguous', signatureProvider);
    }
    final hasCompleteSignature =
        (manifest?.isNotEmpty ?? false) &&
        (signature?.isNotEmpty ?? false) &&
        (hasChain || hasAppAttestKey);
    if (hasSignatureMaterial && !hasCompleteSignature) {
      return failure('capture_signature_incomplete', signatureProvider);
    }
    if (!hasCompleteSignature && captureSignatureRequired) {
      return failure(
        'capture_signature_required',
        CaptureIntegrityProvider.keyAttestation,
      );
    }

    _SignedCapture? signed;
    if (hasCompleteSignature) {
      final expectedManifest = captureProvenanceManifest(
        attemptId: attemptId.toString(),
        requirementId: requirementId.toString(),
        requestHash: requestHash,
        evidenceBindingHash: bindingHash,
      );
      if (!constantTimeEquals(base64Encode(expectedManifest), manifest!)) {
        return failure('capture_manifest_mismatch', signatureProvider);
      }
      final outcome = hasAppAttestKey
          ? await _verifyAppAttestCapture(
              session,
              authUserId: authUserId,
              manifest: expectedManifest,
              assertion: signature!,
              keyId: appAttestKeyId!,
              deviceCheckToken: material.captureDeviceCheckToken,
              now: now,
            )
          : await _verifyAttestedKeyCapture(
              session,
              attemptId: attemptId,
              nonce: challenge.nonce,
              manifest: expectedManifest,
              signature: signature!,
              chain: chain!,
              now: now,
            );
      switch (outcome) {
        case _SignatureRefused(:final reasonCode):
          return failure(reasonCode, signatureProvider);
        case final _SignedCapture capture:
          signed = capture;
      }
    }

    final integrityTrusted = integrityVerdict?.trusted ?? false;
    final provenanceLevel =
        signed?.provenanceLevel ??
        (integrityTrusted
            ? EvidenceProvenanceLevel.appAttested
            : EvidenceProvenanceLevel.basic);
    final providers = [
      if (integrityTrusted) integrityVerdict!.provider,
      ?signed?.provider,
    ];
    final reasonCode =
        signed?.reasonCode ??
        (integrityTrusted
            ? integrityVerdict!.reasonCode
            : 'capture_challenge_bound');
    final publicKey = signed?.publicKey;
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
      reviewReasonCode:
          signed?.reviewReasonCode ?? integrityVerdict?.reviewReasonCode,
      captureManifest: signed == null ? null : manifest,
      captureSignature: signed == null ? null : signature,
      capturePublicKey: publicKey == null ? null : base64Encode(publicKey),
      captureKeyId: publicKey == null ? null : capturePublicKeyId(publicKey),
      captureKeyStorage: signed?.keyStorage,
      captureCertificateChain: signed?.certificateChain,
      captureDeviceKeyId: signed?.deviceKeyId,
    );
  }

  /// Checks the attestation of the Android key that signed [manifest], and
  /// the signature itself.
  Future<_SignatureOutcome> _verifyAttestedKeyCapture(
    Session session, {
    required UuidValue attemptId,
    required String nonce,
    required List<int> manifest,
    required String signature,
    required List<String> chain,
    required DateTime now,
  }) async {
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
      manifest: manifest,
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
      return _SignedCapture(
        provenanceLevel: EvidenceProvenanceLevel.deviceSigned,
        provider: CaptureIntegrityProvider.unattestedSignature,
        reasonCode: 'capture_signature_valid',
        publicKey: publicKey,
      );
    }
    return _SignedCapture(
      provenanceLevel: EvidenceProvenanceLevel.hardwareAttested,
      provider: CaptureIntegrityProvider.keyAttestation,
      reasonCode: KeyAttestationReason.valid,
      publicKey: publicKey,
      keyStorage: switch (attestation.securityLevel) {
        KeySecurityLevel.strongBox => 'strongBox',
        KeySecurityLevel.trustedEnvironment => 'trustedEnvironment',
        KeySecurityLevel.software || null => null,
      },
      certificateChain: chain,
      deviceKeyId: attestation.deviceKeyId,
    );
  }

  /// Checks the App Attest assertion the caller's registered key made over
  /// [manifest]. A registered key was attested in full, so there is no
  /// untrusted App Attest signature: anything short of a verified assertion
  /// is refused.
  Future<_SignatureOutcome> _verifyAppAttestCapture(
    Session session, {
    required UuidValue authUserId,
    required List<int> manifest,
    required String assertion,
    required String keyId,
    required DateTime now,
    required String? deviceCheckToken,
  }) async {
    final verdict = await appAttest.verifyCaptureAssertion(
      session,
      authUserId: authUserId,
      keyId: keyId,
      assertion: assertion,
      clientData: manifest,
      deviceCheckToken: deviceCheckToken,
      now: now,
    );
    final publicKey = verdict.publicKey;
    if (publicKey == null) return _SignatureRefused(verdict.reasonCode);
    return _SignedCapture(
      provenanceLevel: EvidenceProvenanceLevel.secureEnclaveAttested,
      provider: CaptureIntegrityProvider.appAttest,
      reasonCode: AppAttestReason.valid,
      publicKey: publicKey,
      keyStorage: 'secureEnclave',
      reviewReasonCode: verdict.reviewReasonCode,
    );
  }
}

sealed class _SignatureOutcome {
  const _SignatureOutcome();
}

final class _SignatureRefused extends _SignatureOutcome {
  const _SignatureRefused(this.reasonCode);

  final String reasonCode;
}

/// A verified device signature and what its key proved.
final class _SignedCapture extends _SignatureOutcome {
  const _SignedCapture({
    required this.provenanceLevel,
    required this.provider,
    required this.reasonCode,
    required this.publicKey,
    this.keyStorage,
    this.certificateChain,
    this.deviceKeyId,
    this.reviewReasonCode,
  });

  final EvidenceProvenanceLevel provenanceLevel;
  final String provider;
  final String reasonCode;

  /// `0x04 ‖ X ‖ Y`.
  final Uint8List publicKey;
  final String? keyStorage;

  /// The Android chain as submitted; App Attest keeps its chain on the key.
  final List<String>? certificateChain;
  final String? deviceKeyId;
  final String? reviewReasonCode;
}

// A chain is a handful of certificates of one to two kilobytes each.
const _maxChainCertificates = 10;
const _maxEncodedCertificate = 22000;

/// Rejects capture configuration that is malformed or would refuse every
/// proof: both modes must parse, the signing-certificate digests must be
/// SHA-256 hex, required signatures need at least one digest, and the App
/// Attest team, bundle, and environment must parse.
///
/// Apple's sandbox environment is a development aid: only a server running
/// in development or test ([developmentRunMode]) may accept its keys.
void validateCaptureIntegrityConfiguration(
  Map<String, String> environment, {
  bool developmentRunMode = false,
}) {
  deviceIntegrityRequiredFromEnvironment(environment);
  final policy = KeyAttestationPolicy.fromEnvironment(environment);
  if (captureSignatureRequiredFromEnvironment(environment) &&
      policy.signingCertificateDigests.isEmpty) {
    throw StateError(
      'VERILY_CAPTURE_SIGNATURE_MODE=required needs '
      'VERILY_ANDROID_SIGNING_CERT_SHA256.',
    );
  }
  final appAttest = AppAttestPolicy.fromEnvironment(environment);
  if (appAttest?.environment == AppAttestEnvironment.development &&
      !developmentRunMode) {
    throw StateError(
      'VERILY_APP_ATTEST_ENVIRONMENT=development is only for development '
      'and test servers.',
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
/// `VERILY_ANDROID_SIGNING_CERT_SHA256`, or asserted by an App Attest key
/// registered under `VERILY_APPLE_TEAM_ID`.
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
