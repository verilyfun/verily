// The one-operation interface is an injectable production control-plane seam.
// ignore_for_file: one_member_abstracts

import 'dart:convert';
import 'dart:math';

import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/inference/inference_cost_policy.dart';

const productionAiDeploymentPolicyVersion =
    'verily.ai-deployment.production.v1';

final _deploymentIdentifierPattern = RegExp(
  r'^[A-Za-z0-9][A-Za-z0-9._:-]{7,159}$',
);
final _deploymentDigestPattern = RegExp(r'^[0-9a-f]{64}$');
final _deploymentChallengePattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// Builds the existing durable reservation policy from measured, bounded
/// production values. Missing enablement returns the fail-closed policy.
InferenceCostPolicy productionInferenceCostPolicyFromEnvironment(
  Map<String, String> environment,
) {
  final enabled = _strictBoolean(
    environment['VERILY_AI_DEPLOYMENT_ENABLED'] ?? 'false',
    'VERILY_AI_DEPLOYMENT_ENABLED',
  );
  if (!enabled) return const InferenceCostPolicy.disabled();

  return InferenceCostPolicy(
    version: _requiredIdentifier(environment, 'VERILY_AI_COST_POLICY_VERSION'),
    maxMicrosPerAttempt: _boundedInteger(
      environment,
      'VERILY_AI_MAX_MICROS_PER_ATTEMPT',
      minimum: 1,
      maximum: maxInferenceMicrosPerAttempt,
    ),
    maxCallsPerAttempt: _boundedInteger(
      environment,
      'VERILY_AI_MAX_CALLS_PER_ATTEMPT',
      minimum: 1,
      maximum: maxInferenceCallsPerAttempt,
    ),
    modelMaxCostMicros: Map<String, int>.unmodifiable(
      _parsePositiveModelMap(
        environment['VERILY_AI_MODEL_MAX_COST_MICROS'] ?? '',
        fieldName: 'VERILY_AI_MODEL_MAX_COST_MICROS',
        maximumValue: maxInferenceMicrosPerAttempt,
      ),
    ),
  );
}

/// Server-owned AI deployment policy. Environment values select a previously
/// approved policy; they cannot replace live provider attestation.
class ProductionAiDeploymentConfiguration {
  const ProductionAiDeploymentConfiguration._({
    required this.enabled,
    required this.deploymentId,
    required this.endpoint,
    required this.guardrailId,
    required this.guardrailPolicyDigest,
    required this.zeroDataRetentionPolicyId,
    required this.rateCardDigest,
    required this.rateCardMeasuredAt,
    required this.modelIds,
    required this.modelRequestsPerMinute,
    required this.modelMaxCostMicros,
    required this.maxMicrosPerAttempt,
    required this.maxCallsPerAttempt,
    required this.maxConcurrentRequests,
    required this.healthWindow,
    required this.maximumAttestationAge,
  });

  factory ProductionAiDeploymentConfiguration.fromEnvironment(
    Map<String, String> environment, {
    required MediaEvidenceVerifierConfiguration verifier,
    required InferenceCostPolicy inferencePolicy,
    DateTime Function()? clock,
  }) {
    final now = (clock ?? (() => DateTime.now().toUtc()))().toUtc();
    final enabled = _strictBoolean(
      environment['VERILY_AI_DEPLOYMENT_ENABLED'] ?? 'false',
      'VERILY_AI_DEPLOYMENT_ENABLED',
    );
    if (!enabled) {
      if (verifier.mode != mediaVerifierManualMode ||
          inferencePolicy.version != 'disabled' ||
          inferencePolicy.modelMaxCostMicros.isNotEmpty) {
        throw StateError(
          'AI deployment is disabled but active verifier or cost policy '
          'configuration was supplied.',
        );
      }
      return const ProductionAiDeploymentConfiguration._(
        enabled: false,
        deploymentId: null,
        endpoint: null,
        guardrailId: null,
        guardrailPolicyDigest: null,
        zeroDataRetentionPolicyId: null,
        rateCardDigest: null,
        rateCardMeasuredAt: null,
        modelIds: <String>{},
        modelRequestsPerMinute: <String, int>{},
        modelMaxCostMicros: <String, int>{},
        maxMicrosPerAttempt: 0,
        maxCallsPerAttempt: 0,
        maxConcurrentRequests: 0,
        healthWindow: Duration(minutes: 15),
        maximumAttestationAge: Duration(minutes: 5),
      );
    }

    if (environment['VERILY_AI_DEPLOYMENT_POLICY_VERSION']?.trim() !=
        productionAiDeploymentPolicyVersion) {
      throw StateError('The production AI deployment policy is not pinned.');
    }
    if (!verifier.usesOpenRouterVerifier ||
        verifier.endpoint?.scheme != 'https' ||
        verifier.endpoint?.host != 'openrouter.ai' ||
        verifier.endpoint?.path != '/api/v1/chat/completions' ||
        !verifier.requireZeroDataRetention ||
        !verifier.promptInjectionGuardEnabled) {
      throw StateError(
        'Production AI requires the pinned OpenRouter endpoint, ZDR, and a '
        'blocking injection guard.',
      );
    }

    final deploymentId = _requiredIdentifier(
      environment,
      'VERILY_AI_DEPLOYMENT_ID',
    );
    final guardrailId = _requiredIdentifier(
      environment,
      'VERILY_AI_GUARDRAIL_ID',
    );
    final zeroDataRetentionPolicyId = _requiredIdentifier(
      environment,
      'VERILY_AI_ZDR_POLICY_ID',
    );
    final guardrailPolicyDigest = _requiredDigest(
      environment,
      'VERILY_AI_GUARDRAIL_POLICY_DIGEST',
    );
    final rateCardDigest = _requiredDigest(
      environment,
      'VERILY_AI_RATE_CARD_DIGEST',
    );
    final measuredAt = _requiredUtcTimestamp(
      environment,
      'VERILY_AI_RATE_CARD_MEASURED_AT',
    );
    final measurementAge = now.difference(measuredAt);
    if (measurementAge < const Duration(minutes: -5) ||
        measurementAge > const Duration(days: 30)) {
      throw StateError('The measured AI rate card is stale or future-dated.');
    }

    final modelIds = <String>{
      verifier.primaryModelId!,
      ...verifier.councilModelIds,
    };
    final requestsPerMinute = _parsePositiveModelMap(
      environment['VERILY_AI_MODEL_REQUESTS_PER_MINUTE'] ?? '',
      fieldName: 'VERILY_AI_MODEL_REQUESTS_PER_MINUTE',
      maximumValue: 120,
    );
    if (!_sameStringSet(requestsPerMinute.keys.toSet(), modelIds)) {
      throw StateError('Every pinned model needs one measured request limit.');
    }
    if (!_sameStringSet(
      inferencePolicy.modelMaxCostMicros.keys.toSet(),
      modelIds,
    )) {
      throw StateError('Every pinned model needs one approved maximum cost.');
    }
    final expectedCostPolicyVersion = _requiredIdentifier(
      environment,
      'VERILY_AI_COST_POLICY_VERSION',
    );
    if (inferencePolicy.version != expectedCostPolicyVersion ||
        inferencePolicy.maxCallsPerAttempt < verifier.councilModelIds.length ||
        inferencePolicy.maxCallsPerAttempt > maxInferenceCallsPerAttempt ||
        inferencePolicy.maxMicrosPerAttempt <= 0 ||
        inferencePolicy.maxMicrosPerAttempt > maxInferenceMicrosPerAttempt) {
      throw StateError('The AI cost policy is inconsistent.');
    }
    modelIds.forEach(inferencePolicy.costFor);
    final councilMaximumCost = verifier.councilModelIds.fold<int>(
      0,
      (total, modelId) => total + inferencePolicy.modelMaxCostMicros[modelId]!,
    );
    if (councilMaximumCost > inferencePolicy.maxMicrosPerAttempt) {
      throw StateError('The council can exceed its per-attempt ceiling.');
    }

    final maxConcurrentRequests = _boundedInteger(
      environment,
      'VERILY_AI_MAX_CONCURRENT_REQUESTS',
      minimum: 1,
      maximum: 64,
    );
    final healthWindowMinutes = _boundedInteger(
      environment,
      'VERILY_AI_HEALTH_WINDOW_MINUTES',
      minimum: 5,
      maximum: 60,
    );
    final maximumAttestationAgeSeconds = _boundedInteger(
      environment,
      'VERILY_AI_ATTESTATION_MAX_AGE_SECONDS',
      minimum: 60,
      maximum: 600,
      defaultValue: 300,
    );

    return ProductionAiDeploymentConfiguration._(
      enabled: true,
      deploymentId: deploymentId,
      endpoint: verifier.endpoint,
      guardrailId: guardrailId,
      guardrailPolicyDigest: guardrailPolicyDigest,
      zeroDataRetentionPolicyId: zeroDataRetentionPolicyId,
      rateCardDigest: rateCardDigest,
      rateCardMeasuredAt: measuredAt,
      modelIds: Set<String>.unmodifiable(modelIds),
      modelRequestsPerMinute: Map<String, int>.unmodifiable(requestsPerMinute),
      modelMaxCostMicros: Map<String, int>.unmodifiable(
        inferencePolicy.modelMaxCostMicros,
      ),
      maxMicrosPerAttempt: inferencePolicy.maxMicrosPerAttempt,
      maxCallsPerAttempt: inferencePolicy.maxCallsPerAttempt,
      maxConcurrentRequests: maxConcurrentRequests,
      healthWindow: Duration(minutes: healthWindowMinutes),
      maximumAttestationAge: Duration(
        seconds: maximumAttestationAgeSeconds,
      ),
    );
  }

  final bool enabled;
  final String? deploymentId;
  final Uri? endpoint;
  final String? guardrailId;
  final String? guardrailPolicyDigest;
  final String? zeroDataRetentionPolicyId;
  final String? rateCardDigest;
  final DateTime? rateCardMeasuredAt;
  final Set<String> modelIds;
  final Map<String, int> modelRequestsPerMinute;
  final Map<String, int> modelMaxCostMicros;
  final int maxMicrosPerAttempt;
  final int maxCallsPerAttempt;
  final int maxConcurrentRequests;
  final Duration healthWindow;
  final Duration maximumAttestationAge;
}

class AiDeploymentAttestation {
  const AiDeploymentAttestation({
    required this.attestationId,
    required this.challenge,
    required this.observedAt,
    required this.policyVersion,
    required this.deploymentId,
    required this.endpoint,
    required this.guardrailId,
    required this.guardrailPolicyDigest,
    required this.promptInjectionAction,
    required this.promptInjectionCanaryBlocked,
    required this.zeroDataRetentionPolicyId,
    required this.zeroDataRetentionEnabled,
    required this.dataCollectionDisabled,
    required this.providerFallbacksDisabled,
    required this.toolsDisabled,
    required this.remoteMediaRestricted,
    required this.strictResponseSchemaEnabled,
    required this.modelIds,
    required this.modelRequestsPerMinute,
    required this.rateCardDigest,
  });

  final String attestationId;
  final String challenge;
  final DateTime observedAt;
  final String policyVersion;
  final String deploymentId;
  final Uri endpoint;
  final String guardrailId;
  final String guardrailPolicyDigest;
  final String promptInjectionAction;
  final bool promptInjectionCanaryBlocked;
  final String zeroDataRetentionPolicyId;
  final bool zeroDataRetentionEnabled;
  final bool dataCollectionDisabled;
  final bool providerFallbacksDisabled;
  final bool toolsDisabled;
  final bool remoteMediaRestricted;
  final bool strictResponseSchemaEnabled;
  final Set<String> modelIds;
  final Map<String, int> modelRequestsPerMinute;
  final String rateCardDigest;
}

abstract interface class AiDeploymentControlPlane {
  Future<AiDeploymentAttestation> inspect({
    required ProductionAiDeploymentConfiguration configuration,
    required String challenge,
  });
}

class UnavailableAiDeploymentControlPlane implements AiDeploymentControlPlane {
  const UnavailableAiDeploymentControlPlane();

  @override
  Future<AiDeploymentAttestation> inspect({
    required ProductionAiDeploymentConfiguration configuration,
    required String challenge,
  }) {
    throw StateError('AI deployment control-plane verification is absent.');
  }
}

class AiDeploymentReadinessSnapshot {
  const AiDeploymentReadinessSnapshot({
    required this.enabled,
    required this.verifiedAt,
    required this.attestationId,
    required this.deploymentId,
    required this.policyVersion,
    required this.modelCount,
  });

  const AiDeploymentReadinessSnapshot.disabled()
    : enabled = false,
      verifiedAt = null,
      attestationId = null,
      deploymentId = null,
      policyVersion = productionAiDeploymentPolicyVersion,
      modelCount = 0;

  final bool enabled;
  final DateTime? verifiedAt;
  final String? attestationId;
  final String? deploymentId;
  final String policyVersion;
  final int modelCount;
}

class ProductionAiDeploymentPreflight {
  ProductionAiDeploymentPreflight({
    required this.configuration,
    required this.controlPlane,
    DateTime Function()? clock,
    String Function()? challengeFactory,
  }) : clock = clock ?? (() => DateTime.now().toUtc()),
       challengeFactory = challengeFactory ?? _secureDeploymentChallenge;

  final ProductionAiDeploymentConfiguration configuration;
  final AiDeploymentControlPlane controlPlane;
  final DateTime Function() clock;
  final String Function() challengeFactory;

  Future<AiDeploymentReadinessSnapshot> verify() async {
    if (!configuration.enabled) {
      return const AiDeploymentReadinessSnapshot.disabled();
    }
    final challenge = challengeFactory();
    if (!_deploymentChallengePattern.hasMatch(challenge)) {
      throw StateError('AI deployment attestation challenge was invalid.');
    }
    final attestation = await controlPlane.inspect(
      configuration: configuration,
      challenge: challenge,
    );
    final now = clock().toUtc();
    final age = now.difference(attestation.observedAt.toUtc());

    if (!_deploymentIdentifierPattern.hasMatch(attestation.attestationId) ||
        attestation.challenge != challenge ||
        attestation.policyVersion != productionAiDeploymentPolicyVersion ||
        age < const Duration(seconds: -30) ||
        age > configuration.maximumAttestationAge) {
      throw StateError('AI deployment attestation was stale or untrusted.');
    }
    if (attestation.deploymentId != configuration.deploymentId ||
        attestation.endpoint != configuration.endpoint ||
        attestation.guardrailId != configuration.guardrailId ||
        attestation.guardrailPolicyDigest !=
            configuration.guardrailPolicyDigest ||
        attestation.zeroDataRetentionPolicyId !=
            configuration.zeroDataRetentionPolicyId ||
        attestation.rateCardDigest != configuration.rateCardDigest) {
      throw StateError('AI deployment provenance did not match configuration.');
    }
    if (attestation.promptInjectionAction != 'block' ||
        !attestation.promptInjectionCanaryBlocked ||
        !attestation.zeroDataRetentionEnabled ||
        !attestation.dataCollectionDisabled ||
        !attestation.providerFallbacksDisabled ||
        !attestation.toolsDisabled ||
        !attestation.remoteMediaRestricted ||
        !attestation.strictResponseSchemaEnabled) {
      throw StateError('AI deployment security controls were not enforced.');
    }
    if (!_sameStringSet(attestation.modelIds, configuration.modelIds) ||
        !_sameModelMap(
          attestation.modelRequestsPerMinute,
          configuration.modelRequestsPerMinute,
        )) {
      throw StateError('AI deployment model or rate allowlist changed.');
    }

    return AiDeploymentReadinessSnapshot(
      enabled: true,
      verifiedAt: now,
      attestationId: attestation.attestationId,
      deploymentId: attestation.deploymentId,
      policyVersion: attestation.policyVersion,
      modelCount: attestation.modelIds.length,
    );
  }
}

bool _strictBoolean(String value, String name) {
  return switch (value.trim().toLowerCase()) {
    'true' => true,
    'false' => false,
    _ => throw StateError('$name must be true or false.'),
  };
}

String _requiredIdentifier(Map<String, String> environment, String name) {
  final value = environment[name]?.trim() ?? '';
  if (!_deploymentIdentifierPattern.hasMatch(value)) {
    throw StateError('$name must contain a pinned deployment identifier.');
  }
  return value;
}

String _requiredDigest(Map<String, String> environment, String name) {
  final value = environment[name]?.trim() ?? '';
  if (!_deploymentDigestPattern.hasMatch(value)) {
    throw StateError('$name must contain a lowercase SHA-256 digest.');
  }
  return value;
}

DateTime _requiredUtcTimestamp(Map<String, String> environment, String name) {
  final value = environment[name]?.trim() ?? '';
  final timestamp = DateTime.tryParse(value);
  if (timestamp == null || !value.endsWith('Z')) {
    throw StateError('$name must be an ISO-8601 UTC timestamp.');
  }
  return timestamp.toUtc();
}

Map<String, int> _parsePositiveModelMap(
  String value, {
  required String fieldName,
  required int maximumValue,
}) {
  final result = <String, int>{};
  final entries = value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty);
  for (final entry in entries) {
    final separator = entry.lastIndexOf('=');
    if (separator <= 0 || separator == entry.length - 1) {
      throw StateError('$fieldName contains an invalid model limit.');
    }
    final modelId = entry.substring(0, separator).trim();
    final limit = int.tryParse(entry.substring(separator + 1).trim());
    if (modelId.isEmpty ||
        result.containsKey(modelId) ||
        limit == null ||
        limit < 1 ||
        limit > maximumValue) {
      throw StateError('$fieldName contains an invalid model limit.');
    }
    result[modelId] = limit;
  }
  if (result.isEmpty || result.length > 8) {
    throw StateError('$fieldName must contain one to eight model limits.');
  }
  return result;
}

int _boundedInteger(
  Map<String, String> environment,
  String name, {
  required int minimum,
  required int maximum,
  int? defaultValue,
}) {
  final raw = environment[name]?.trim();
  final value = int.tryParse(raw?.isNotEmpty == true ? raw! : '$defaultValue');
  if (value == null || value < minimum || value > maximum) {
    throw StateError('$name must be between $minimum and $maximum.');
  }
  return value;
}

bool _sameStringSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _sameModelMap(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  return left.entries.every((entry) => right[entry.key] == entry.value);
}

String _secureDeploymentChallenge() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}
