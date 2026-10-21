import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/action_verification/capture_signature_verifier.dart';
import 'package:verily_server/src/action_verification/device_integrity_verifier.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/security/secret_digest.dart';

/// Device-side provenance material submitted with one proof.
final class CaptureIntegrityMaterial {
  const CaptureIntegrityMaterial({
    this.captureChallengeId,
    this.deviceIntegrityToken,
    this.captureManifest,
    this.captureSignature,
    this.capturePublicKey,
    this.captureKeyId,
    this.captureKeyStorage,
  });

  final UuidValue? captureChallengeId;
  final String? deviceIntegrityToken;
  final String? captureManifest;
  final String? captureSignature;
  final String? capturePublicKey;
  final String? captureKeyId;
  final String? captureKeyStorage;

  bool get hasSignatureMaterial => [
    captureManifest,
    captureSignature,
    capturePublicKey,
    captureKeyId,
  ].any((value) => value?.trim().isNotEmpty ?? false);
}

/// The outcome of checking capture provenance for one proof.
final class CaptureIntegrityResult {
  const CaptureIntegrityResult({
    required this.trusted,
    required this.reasonCode,
    required this.provider,
    this.challengeId,
    this.tokenHash,
    this.provenanceLevel = EvidenceProvenanceLevel.basic,
    this.captureManifest,
    this.captureSignature,
    this.capturePublicKey,
    this.captureKeyId,
    this.captureKeyStorage,
  });

  final bool trusted;
  final String reasonCode;
  final String provider;
  final UuidValue? challengeId;
  final String? tokenHash;
  final EvidenceProvenanceLevel provenanceLevel;
  final String? captureManifest;
  final String? captureSignature;
  final String? capturePublicKey;
  final String? captureKeyId;
  final String? captureKeyStorage;
}

/// Checks that a proof is bound to one fresh server challenge, and verifies
/// the Play Integrity verdict and the hardware-backed capture signature that
/// commit to the exact evidence fingerprint the server recomputed.
class CaptureIntegrityEvaluator {
  CaptureIntegrityEvaluator({
    DeviceIntegrityVerifier? deviceIntegrityVerifier,
    bool? deviceIntegrityRequired,
    CaptureSignatureVerifier? captureSignatureVerifier,
    bool? captureSignatureRequired,
    DateTime Function()? clock,
  }) : deviceIntegrityVerifier =
           deviceIntegrityVerifier ?? const GooglePlayIntegrityVerifier(),
       deviceIntegrityRequired =
           deviceIntegrityRequired ?? deviceIntegrityRequiredFromEnvironment(),
       captureSignatureVerifier =
           captureSignatureVerifier ?? const P256CaptureSignatureVerifier(),
       captureSignatureRequired =
           captureSignatureRequired ??
           captureSignatureRequiredFromEnvironment(),
       clock = clock ?? (() => DateTime.now().toUtc());

  final DeviceIntegrityVerifier deviceIntegrityVerifier;
  final bool deviceIntegrityRequired;
  final CaptureSignatureVerifier captureSignatureVerifier;
  final bool captureSignatureRequired;
  final DateTime Function() clock;

  /// Returns null when no provenance is required and none was sent.
  ///
  /// [evidenceBindingHash] is the fingerprint the server computed from the
  /// evidence it accepted, never one the client claims.
  Future<CaptureIntegrityResult?> evaluate(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required UuidValue requirementId,
    required CaptureIntegrityMaterial material,
    required String Function() evidenceBindingHash,
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
            : 'android-keystore',
      );
    }
    if (token != null && token.length > 32768) {
      throw ArgumentError('Device integrity proof is too large.');
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
    final submittedBindingHash = evidenceBindingHash();
    if (!constantTimeEquals(
      challenge.evidenceBindingHash,
      submittedBindingHash,
    )) {
      return CaptureIntegrityResult(
        trusted: false,
        reasonCode: 'evidence_binding_mismatch',
        provider: deviceIntegrityVerifier.providerName,
        challengeId: challenge.id,
        tokenHash: tokenHash,
      );
    }

    DeviceIntegrityVerdict? integrityVerdict;
    if (token == null || token.isEmpty) {
      if (deviceIntegrityRequired) {
        return CaptureIntegrityResult(
          trusted: false,
          reasonCode: 'device_integrity_required',
          provider: deviceIntegrityVerifier.providerName,
          challengeId: challenge.id,
        );
      }
    } else {
      integrityVerdict = await deviceIntegrityVerifier.verify(
        session,
        token: token,
        requestHash: challenge.requestHash,
        now: now,
      );
      if (!integrityVerdict.trusted) {
        return CaptureIntegrityResult(
          trusted: false,
          reasonCode: integrityVerdict.reasonCode,
          provider: integrityVerdict.provider,
          challengeId: challenge.id,
          tokenHash: tokenHash,
        );
      }
    }

    final manifest = material.captureManifest?.trim();
    final signature = material.captureSignature?.trim();
    final publicKey = material.capturePublicKey?.trim();
    final keyId = material.captureKeyId?.trim().toLowerCase();
    final keyStorage = material.captureKeyStorage?.trim();
    if (manifest != null && manifest.length > 4096) {
      throw ArgumentError('Capture manifest is too large.');
    }
    CaptureIntegrityResult keystoreFailure(String reasonCode) =>
        CaptureIntegrityResult(
          trusted: false,
          reasonCode: reasonCode,
          provider: 'android-keystore',
          challengeId: challenge.id,
          tokenHash: tokenHash,
        );
    if (keyStorage != null &&
        !const {
          'strongBox',
          'trustedEnvironment',
          'software',
          'unknown',
        }.contains(keyStorage)) {
      return keystoreFailure('capture_key_storage_invalid');
    }
    final hasCompleteSignature = [
      manifest,
      signature,
      publicKey,
      keyId,
    ].every((value) => value != null && value.isNotEmpty);
    if (hasSignatureMaterial && !hasCompleteSignature) {
      return keystoreFailure('capture_signature_incomplete');
    }
    if (!hasCompleteSignature && captureSignatureRequired) {
      return keystoreFailure('capture_signature_required');
    }

    var signatureTrusted = false;
    if (hasCompleteSignature) {
      final expectedManifest = captureProvenanceManifest(
        attemptId: attemptId.toString(),
        requirementId: requirementId.toString(),
        requestHash: challenge.requestHash,
        evidenceBindingHash: submittedBindingHash,
      );
      if (!constantTimeEquals(base64Encode(expectedManifest), manifest!)) {
        return keystoreFailure('capture_manifest_mismatch');
      }
      final signatureVerdict = captureSignatureVerifier.verify(
        manifest: expectedManifest,
        encodedSignature: signature!,
        encodedPublicKey: publicKey!,
        keyId: keyId!,
      );
      if (!signatureVerdict.trusted) {
        return keystoreFailure(signatureVerdict.reasonCode);
      }
      signatureTrusted = true;
    }

    final integrityTrusted = integrityVerdict?.trusted ?? false;
    final provenanceLevel = signatureTrusted
        ? EvidenceProvenanceLevel.deviceSigned
        : integrityTrusted
        ? EvidenceProvenanceLevel.appAttested
        : EvidenceProvenanceLevel.basic;
    final provider = switch ((integrityTrusted, signatureTrusted)) {
      (true, true) => '${integrityVerdict!.provider}+android-keystore',
      (true, false) => integrityVerdict!.provider,
      (false, true) => 'android-keystore',
      (false, false) => 'capture-challenge',
    };
    final reasonCode = switch (provenanceLevel) {
      EvidenceProvenanceLevel.deviceSigned => 'capture_signature_valid',
      EvidenceProvenanceLevel.appAttested => integrityVerdict!.reasonCode,
      EvidenceProvenanceLevel.basic => 'capture_challenge_bound',
    };
    return CaptureIntegrityResult(
      trusted: true,
      reasonCode: reasonCode,
      provider: provider,
      challengeId: challenge.id,
      tokenHash: tokenHash,
      provenanceLevel: provenanceLevel,
      captureManifest: manifest,
      captureSignature: signature,
      capturePublicKey: publicKey,
      captureKeyId: keyId,
      captureKeyStorage: signatureTrusted ? keyStorage : null,
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
