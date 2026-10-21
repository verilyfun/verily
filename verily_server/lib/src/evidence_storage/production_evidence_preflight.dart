// The one-operation interface is an injectable production control-plane seam.
// ignore_for_file: one_member_abstracts

import 'dart:convert';
import 'dart:math';

import 'package:verily_server/src/evidence_storage/backblaze_evidence_storage.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';

const productionEvidenceStoragePolicyVersion =
    'verily.evidence-storage.production.v1';

const _requiredKeyCapabilities = <String>{
  'deleteFiles',
  'listBuckets',
  'listFiles',
  'readFiles',
  'writeFiles',
};
const _requiredCorsMethods = <String>{'GET', 'HEAD', 'PUT'};
const _requiredCorsAllowedHeaders = <String>{
  'content-length',
  'content-type',
};
const _requiredCorsExposedHeaders = <String>{
  'etag',
  'x-amz-version-id',
};
final _challengePattern = RegExp(r'^[A-Za-z0-9_-]{43}$');
final _identifierPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{7,159}$');

/// Non-secret expectations used to verify the live evidence bucket before it
/// is exposed to upload or verification code.
class ProductionEvidenceStorageConfiguration {
  ProductionEvidenceStorageConfiguration._({
    required this.endpoint,
    required this.region,
    required this.bucket,
    required this.allowedWebOrigins,
    required this.maximumAttestationAge,
  });

  factory ProductionEvidenceStorageConfiguration.fromEnvironment(
    Map<String, String> environment, {
    required BackblazeEvidenceStorageConfiguration storage,
  }) {
    if (environment['VERILY_EVIDENCE_STORAGE_POLICY_VERSION']?.trim() !=
        productionEvidenceStoragePolicyVersion) {
      throw StateError('The production evidence storage policy is not pinned.');
    }

    final origins = _parseOrigins(
      environment['VERILY_EVIDENCE_ALLOWED_WEB_ORIGINS'] ?? '',
    );
    final maximumAgeSeconds = int.tryParse(
      (environment['VERILY_EVIDENCE_ATTESTATION_MAX_AGE_SECONDS'] ?? '300')
          .trim(),
    );
    if (maximumAgeSeconds == null ||
        maximumAgeSeconds < 60 ||
        maximumAgeSeconds > 600) {
      throw StateError(
        'Evidence storage attestations must expire within 60 to 600 seconds.',
      );
    }

    return ProductionEvidenceStorageConfiguration._(
      endpoint: storage.endpoint,
      region: storage.region,
      bucket: storage.bucket,
      allowedWebOrigins: origins,
      maximumAttestationAge: Duration(seconds: maximumAgeSeconds),
    );
  }

  final Uri endpoint;
  final String region;
  final String bucket;
  final Set<Uri> allowedWebOrigins;
  final Duration maximumAttestationAge;
}

/// Control-plane facts returned through an authenticated, read-only adapter.
/// The adapter is responsible for talking to the storage provider; this model
/// deliberately contains no application key or media URL.
class EvidenceStorageAttestation {
  const EvidenceStorageAttestation({
    required this.attestationId,
    required this.challenge,
    required this.observedAt,
    required this.policyVersion,
    required this.endpoint,
    required this.region,
    required this.bucket,
    required this.bucketPrivate,
    required this.defaultEncryptionEnabled,
    required this.versioningEnabled,
    required this.versionIdReadsEnabled,
    required this.applicationKeyPrefix,
    required this.applicationKeyCapabilities,
    required this.corsOrigins,
    required this.corsMethods,
    required this.corsAllowedHeaders,
    required this.corsExposedHeaders,
    required this.corsMaximumAgeSeconds,
    required this.lifecyclePrefix,
    required this.maximumVersionAgeDays,
    required this.unfinishedMultipartAgeDays,
  });

  final String attestationId;
  final String challenge;
  final DateTime observedAt;
  final String policyVersion;
  final Uri endpoint;
  final String region;
  final String bucket;
  final bool bucketPrivate;
  final bool defaultEncryptionEnabled;
  final bool versioningEnabled;
  final bool versionIdReadsEnabled;
  final String applicationKeyPrefix;
  final Set<String> applicationKeyCapabilities;
  final Set<Uri> corsOrigins;
  final Set<String> corsMethods;
  final Set<String> corsAllowedHeaders;
  final Set<String> corsExposedHeaders;
  final int corsMaximumAgeSeconds;
  final String lifecyclePrefix;
  final int maximumVersionAgeDays;
  final int unfinishedMultipartAgeDays;
}

abstract interface class EvidenceStorageControlPlane {
  Future<EvidenceStorageAttestation> inspect({
    required ProductionEvidenceStorageConfiguration configuration,
    required String challenge,
  });
}

/// Safe default for deployments that have not installed a real control-plane
/// adapter. Environment claims alone never make evidence storage production
/// ready.
class UnavailableEvidenceStorageControlPlane
    implements EvidenceStorageControlPlane {
  const UnavailableEvidenceStorageControlPlane();

  @override
  Future<EvidenceStorageAttestation> inspect({
    required ProductionEvidenceStorageConfiguration configuration,
    required String challenge,
  }) {
    throw StateError('Evidence storage control-plane verification is absent.');
  }
}

class EvidenceStorageReadinessSnapshot {
  const EvidenceStorageReadinessSnapshot({
    required this.attestationId,
    required this.verifiedAt,
    required this.bucket,
    required this.region,
    required this.policyVersion,
    required this.maximumVersionAgeDays,
  });

  final String attestationId;
  final DateTime verifiedAt;
  final String bucket;
  final String region;
  final String policyVersion;
  final int maximumVersionAgeDays;
}

class ProductionEvidenceStoragePreflight {
  ProductionEvidenceStoragePreflight({
    required this.configuration,
    required this.controlPlane,
    DateTime Function()? clock,
    String Function()? challengeFactory,
  }) : clock = clock ?? (() => DateTime.now().toUtc()),
       challengeFactory = challengeFactory ?? _secureChallenge;

  final ProductionEvidenceStorageConfiguration configuration;
  final EvidenceStorageControlPlane controlPlane;
  final DateTime Function() clock;
  final String Function() challengeFactory;

  Future<EvidenceStorageReadinessSnapshot> verify() async {
    final challenge = challengeFactory();
    if (!_challengePattern.hasMatch(challenge)) {
      throw StateError('Evidence storage attestation challenge was invalid.');
    }
    final attestation = await controlPlane.inspect(
      configuration: configuration,
      challenge: challenge,
    );
    final now = clock().toUtc();
    final observedAt = attestation.observedAt.toUtc();
    final age = now.difference(observedAt);

    if (!_identifierPattern.hasMatch(attestation.attestationId) ||
        attestation.challenge != challenge ||
        attestation.policyVersion != productionEvidenceStoragePolicyVersion ||
        age < const Duration(seconds: -30) ||
        age > configuration.maximumAttestationAge) {
      throw StateError('Evidence storage attestation was stale or untrusted.');
    }
    if (attestation.endpoint != configuration.endpoint ||
        attestation.region != configuration.region ||
        attestation.bucket != configuration.bucket) {
      throw StateError('Evidence storage provenance did not match deployment.');
    }
    if (!attestation.bucketPrivate ||
        !attestation.defaultEncryptionEnabled ||
        !attestation.versioningEnabled ||
        !attestation.versionIdReadsEnabled) {
      throw StateError('Evidence storage privacy or versioning is incomplete.');
    }
    if (attestation.applicationKeyPrefix != evidenceObjectPrefix ||
        !_sameStrings(
          attestation.applicationKeyCapabilities,
          _requiredKeyCapabilities,
        )) {
      throw StateError('Evidence storage application key is over-privileged.');
    }
    if (!_sameUris(attestation.corsOrigins, configuration.allowedWebOrigins) ||
        !_sameStrings(attestation.corsMethods, _requiredCorsMethods) ||
        !_sameStrings(
          attestation.corsAllowedHeaders,
          _requiredCorsAllowedHeaders,
        ) ||
        !_sameStrings(
          attestation.corsExposedHeaders,
          _requiredCorsExposedHeaders,
        ) ||
        attestation.corsMaximumAgeSeconds != 300) {
      throw StateError(
        'Evidence storage CORS policy did not match deployment.',
      );
    }
    if (attestation.lifecyclePrefix != evidenceObjectPrefix ||
        attestation.maximumVersionAgeDays < 7 ||
        attestation.maximumVersionAgeDays > 30 ||
        attestation.unfinishedMultipartAgeDays != 1) {
      throw StateError('Evidence storage lifecycle is outside policy.');
    }

    return EvidenceStorageReadinessSnapshot(
      attestationId: attestation.attestationId,
      verifiedAt: now,
      bucket: attestation.bucket,
      region: attestation.region,
      policyVersion: attestation.policyVersion,
      maximumVersionAgeDays: attestation.maximumVersionAgeDays,
    );
  }
}

Set<Uri> _parseOrigins(String value) {
  final parts = value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty || parts.length > 8) {
    throw StateError('One to eight evidence web origins must be configured.');
  }

  final origins = <Uri>{};
  for (final part in parts) {
    final uri = Uri.tryParse(part);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        part.contains('*')) {
      throw StateError('Evidence web origins must be exact HTTPS origins.');
    }
    origins.add(Uri(scheme: 'https', host: uri.host, port: uri.port));
  }
  if (origins.length != parts.length) {
    throw StateError('Evidence web origins must be unique.');
  }
  return Set<Uri>.unmodifiable(origins);
}

bool _sameStrings(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _sameUris(Set<Uri> left, Set<Uri> right) {
  final leftValues = left.map((uri) => uri.toString()).toSet();
  final rightValues = right.map((uri) => uri.toString()).toSet();
  return _sameStrings(leftValues, rightValues);
}

String _secureChallenge() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}
