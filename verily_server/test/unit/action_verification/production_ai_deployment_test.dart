import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/action_verification/production_ai_deployment.dart';
import 'package:verily_server/src/inference/inference_cost_policy.dart';

void main() {
  group('Given the production AI deployment configuration', () {
    final now = DateTime.utc(2026, 9, 4, 12);

    test('when measured costs are configured then the cost policy parses, and '
        'it is disabled by default', () {
      expect(
        productionInferenceCostPolicyFromEnvironment(const {}).version,
        'disabled',
      );

      final policy = productionInferenceCostPolicyFromEnvironment(
        _environment(now),
      );

      expect(policy.version, 'rates:2026-09-04');
      expect(policy.maxMicrosPerAttempt, 3000);
      expect(policy.maxCallsPerAttempt, 3);
      expect(policy.modelMaxCostMicros, _costPolicy().modelMaxCostMicros);
    });

    test('when nothing is configured then AI is genuinely disabled', () {
      final configuration = ProductionAiDeploymentConfiguration.fromEnvironment(
        const {},
        verifier: MediaEvidenceVerifierConfiguration.fromEnvironment(const {}),
        inferencePolicy: const InferenceCostPolicy.disabled(),
        clock: () => now,
      );

      expect(configuration.enabled, isFalse);
      expect(configuration.modelIds, isEmpty);
      expect(configuration.maxConcurrentRequests, 0);
    });

    test('when active policy hides behind a disabled flag then it refuses', () {
      expect(
        () => ProductionAiDeploymentConfiguration.fromEnvironment(
          const {},
          verifier: _verifier(),
          inferencePolicy: _costPolicy(),
          clock: () => now,
        ),
        throwsStateError,
      );
    });

    test('when models, costs, and rates are pinned then it is enabled', () {
      final configuration = _configuration(now);

      expect(configuration.enabled, isTrue);
      expect(configuration.modelIds, {
        openRouterGeminiFlashLiteModel,
        openRouterGemmaModel,
        openRouterGlmFlashModel,
      });
      expect(configuration.maxMicrosPerAttempt, 3000);
      expect(configuration.maxCallsPerAttempt, 3);
      expect(configuration.maxConcurrentRequests, 8);
    });

    test('when ZDR is off or the endpoint is spoofed then it refuses', () {
      expect(
        () => _configuration(
          now,
          verifier: _verifier(requireZdr: false),
        ),
        throwsStateError,
      );
      expect(
        () => _configuration(
          now,
          verifier: _verifier(
            endpoint:
                'https://openrouter.attacker.example/api/v1/chat/completions',
          ),
        ),
        throwsStateError,
      );
    });

    test(
      'when a model rate is missing or the rate card is stale then it refuses',
      () {
        final missingRate = _environment(now)
          ..['VERILY_AI_MODEL_REQUESTS_PER_MINUTE'] =
              '$openRouterGeminiFlashLiteModel=10,$openRouterGemmaModel=10';
        final stale = _environment(now)
          ..['VERILY_AI_RATE_CARD_MEASURED_AT'] = now
              .subtract(const Duration(days: 31))
              .toIso8601String();

        expect(
          () => _configuration(now, environment: missingRate),
          throwsStateError,
        );
        expect(
          () => _configuration(now, environment: stale),
          throwsStateError,
        );
      },
    );

    test('when a model cost is missing or the council can exceed its ceiling '
        'then it refuses', () {
      const missingCost = InferenceCostPolicy(
        version: 'rates:2026-09-04',
        maxMicrosPerAttempt: 3000,
        maxCallsPerAttempt: 3,
        modelMaxCostMicros: {
          openRouterGeminiFlashLiteModel: 1000,
          openRouterGemmaModel: 1000,
        },
      );
      const underfunded = InferenceCostPolicy(
        version: 'rates:2026-09-04',
        maxMicrosPerAttempt: 3000,
        maxCallsPerAttempt: 3,
        modelMaxCostMicros: {
          openRouterGeminiFlashLiteModel: 1500,
          openRouterGemmaModel: 1500,
          openRouterGlmFlashModel: 1500,
        },
      );

      expect(
        () => _configuration(now, inferencePolicy: missingCost),
        throwsStateError,
      );
      expect(
        () => _configuration(now, inferencePolicy: underfunded),
        throwsStateError,
      );
    });

    test('when measured costs are malformed or above the ceiling then it '
        'refuses', () {
      final malformed = _environment(now)
        ..['VERILY_AI_MODEL_MAX_COST_MICROS'] =
            '$openRouterGeminiFlashLiteModel=not-a-number';
      final excessive = _environment(now)
        ..['VERILY_AI_MAX_MICROS_PER_ATTEMPT'] = '50001';

      expect(
        () => productionInferenceCostPolicyFromEnvironment(malformed),
        throwsStateError,
      );
      expect(
        () => productionInferenceCostPolicyFromEnvironment(excessive),
        throwsStateError,
      );
    });
  });

  group('Given the production AI deployment preflight', () {
    final now = DateTime.utc(2026, 9, 4, 12);
    late ProductionAiDeploymentConfiguration configuration;

    setUp(() {
      configuration = _configuration(now);
    });

    test('when the live deployment matches then it is confirmed', () async {
      final preflight = _preflight(
        configuration,
        now: now,
        builder: (challenge) => _attestation(
          configuration,
          challenge: challenge,
          observedAt: now,
        ),
      );

      final snapshot = await preflight.verify();

      expect(snapshot.enabled, isTrue);
      expect(snapshot.attestationId, 'attestation:ai:0001');
      expect(snapshot.modelCount, 3);
    });

    test(
      'when no provider control plane is installed then it fails closed',
      () async {
        final preflight = ProductionAiDeploymentPreflight(
          configuration: configuration,
          controlPlane: const UnavailableAiDeploymentControlPlane(),
          clock: () => now,
          challengeFactory: () => 'a' * 43,
        );

        await expectLater(preflight.verify(), throwsStateError);
      },
    );

    test(
      'when the guardrail only monitors or the canary passes then it refuses',
      () async {
        for (final attestation in <AiDeploymentAttestation>[
          _attestation(
            configuration,
            challenge: 'a' * 43,
            observedAt: now,
            promptInjectionAction: 'monitor',
          ),
          _attestation(
            configuration,
            challenge: 'a' * 43,
            observedAt: now,
            promptInjectionCanaryBlocked: false,
          ),
        ]) {
          final preflight = _preflight(
            configuration,
            now: now,
            builder: (_) => attestation,
          );
          await expectLater(preflight.verify(), throwsStateError);
        }
      },
    );

    test('when the challenge is replayed or the digest is spoofed then it '
        'refuses', () async {
      final replay = _preflight(
        configuration,
        now: now,
        builder: (_) => _attestation(
          configuration,
          challenge: 'r' * 43,
          observedAt: now,
        ),
      );
      final spoofed = _preflight(
        configuration,
        now: now,
        builder: (challenge) => _attestation(
          configuration,
          challenge: challenge,
          observedAt: now,
          guardrailPolicyDigest: 'f' * 64,
        ),
      );

      await expectLater(replay.verify(), throwsStateError);
      await expectLater(spoofed.verify(), throwsStateError);
    });

    test(
      'when models, rates, or data controls drift then it refuses',
      () async {
        final cases = <AiDeploymentAttestation>[
          _attestation(
            configuration,
            challenge: 'a' * 43,
            observedAt: now,
            modelIds: {...configuration.modelIds, 'attacker/model'},
          ),
          _attestation(
            configuration,
            challenge: 'a' * 43,
            observedAt: now,
            modelRequestsPerMinute: {
              ...configuration.modelRequestsPerMinute,
              openRouterGemmaModel: 120,
            },
          ),
          _attestation(
            configuration,
            challenge: 'a' * 43,
            observedAt: now,
            dataCollectionDisabled: false,
          ),
        ];

        for (final attestation in cases) {
          final preflight = _preflight(
            configuration,
            now: now,
            builder: (_) => attestation,
          );
          await expectLater(preflight.verify(), throwsStateError);
        }
      },
    );

    test('when the attestation is stale or for another policy then it '
        'refuses', () async {
      for (final attestation in <AiDeploymentAttestation>[
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now.subtract(const Duration(minutes: 6)),
        ),
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now.add(const Duration(minutes: 2)),
        ),
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          policyVersion: 'verily.ai-deployment.production.v0',
        ),
      ]) {
        await expectLater(
          _preflight(
            configuration,
            now: now,
            builder: (_) => attestation,
          ).verify(),
          throwsStateError,
        );
      }
    });

    test('when the challenge factory is weak then it refuses before asking '
        'the control plane', () async {
      var inspected = false;
      final preflight = ProductionAiDeploymentPreflight(
        configuration: configuration,
        controlPlane: _FakeAiDeploymentControlPlane((challenge) {
          inspected = true;
          return _attestation(
            configuration,
            challenge: challenge,
            observedAt: now,
          );
        }),
        clock: () => now,
        challengeFactory: () => 'short',
      );

      await expectLater(preflight.verify(), throwsStateError);
      expect(inspected, isFalse);
    });

    test('when tools, fallbacks, or strict schemas are not enforced then it '
        'refuses', () async {
      for (final attestation in <AiDeploymentAttestation>[
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          toolsDisabled: false,
        ),
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          providerFallbacksDisabled: false,
        ),
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          strictResponseSchemaEnabled: false,
        ),
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          zeroDataRetentionEnabled: false,
        ),
      ]) {
        await expectLater(
          _preflight(
            configuration,
            now: now,
            builder: (_) => attestation,
          ).verify(),
          throwsStateError,
        );
      }
    });

    test('when AI is disabled then the preflight reports disabled without '
        'contacting anything', () async {
      final disabled = ProductionAiDeploymentConfiguration.fromEnvironment(
        const {},
        verifier: MediaEvidenceVerifierConfiguration.fromEnvironment(const {}),
        inferencePolicy: const InferenceCostPolicy.disabled(),
        clock: () => now,
      );

      final snapshot = await ProductionAiDeploymentPreflight(
        configuration: disabled,
        controlPlane: const UnavailableAiDeploymentControlPlane(),
        clock: () => now,
      ).verify();

      expect(snapshot.enabled, isFalse);
      expect(snapshot.policyVersion, productionAiDeploymentPolicyVersion);
    });
  });

  group('Given an enabled deployment with partial configuration', () {
    final now = DateTime.utc(2026, 9, 4, 12);

    test('when the deployment policy version is missing or different then '
        'it refuses', () {
      for (final version in [null, 'verily.ai-deployment.production.v0']) {
        final environment = _environment(now);
        if (version == null) {
          environment.remove('VERILY_AI_DEPLOYMENT_POLICY_VERSION');
        } else {
          environment['VERILY_AI_DEPLOYMENT_POLICY_VERSION'] = version;
        }
        expect(
          () => _configuration(now, environment: environment),
          throwsStateError,
          reason: '$version',
        );
      }
    });

    test('when any pinned identifier or digest is missing then it refuses', () {
      for (final name in [
        'VERILY_AI_DEPLOYMENT_ID',
        'VERILY_AI_GUARDRAIL_ID',
        'VERILY_AI_ZDR_POLICY_ID',
        'VERILY_AI_GUARDRAIL_POLICY_DIGEST',
        'VERILY_AI_RATE_CARD_DIGEST',
        'VERILY_AI_RATE_CARD_MEASURED_AT',
        'VERILY_AI_MAX_CONCURRENT_REQUESTS',
        'VERILY_AI_HEALTH_WINDOW_MINUTES',
      ]) {
        final environment = _environment(now)..remove(name);
        expect(
          () => _configuration(now, environment: environment),
          throwsStateError,
          reason: name,
        );
      }
    });

    test('when the enable flag is not a strict boolean then it refuses', () {
      expect(
        () => productionInferenceCostPolicyFromEnvironment(const {
          'VERILY_AI_DEPLOYMENT_ENABLED': 'yes',
        }),
        throwsStateError,
      );
    });

    test('when the rate card is dated in the future then it refuses', () {
      final environment = _environment(now)
        ..['VERILY_AI_RATE_CARD_MEASURED_AT'] = now
            .add(const Duration(hours: 1))
            .toIso8601String();

      expect(
        () => _configuration(now, environment: environment),
        throwsStateError,
      );
    });

    test('when the cost policy version or call cap disagree then it '
        'refuses', () {
      const otherVersion = InferenceCostPolicy(
        version: 'rates:2026-01-01',
        maxMicrosPerAttempt: 3000,
        maxCallsPerAttempt: 3,
        modelMaxCostMicros: {
          openRouterGeminiFlashLiteModel: 1000,
          openRouterGemmaModel: 1000,
          openRouterGlmFlashModel: 1000,
        },
      );
      const tooFewCalls = InferenceCostPolicy(
        version: 'rates:2026-09-04',
        maxMicrosPerAttempt: 3000,
        maxCallsPerAttempt: 2,
        modelMaxCostMicros: {
          openRouterGeminiFlashLiteModel: 1000,
          openRouterGemmaModel: 1000,
          openRouterGlmFlashModel: 1000,
        },
      );

      expect(
        () => _configuration(now, inferencePolicy: otherVersion),
        throwsStateError,
      );
      expect(
        () => _configuration(now, inferencePolicy: tooFewCalls),
        throwsStateError,
      );
    });

    test('when the verifier is not OpenRouter or lacks the blocking guard '
        'then it refuses', () {
      expect(
        () => _configuration(
          now,
          verifier: MediaEvidenceVerifierConfiguration.fromEnvironment(
            const {},
          ),
        ),
        throwsStateError,
      );
    });
  });
}

ProductionAiDeploymentConfiguration _configuration(
  DateTime now, {
  Map<String, String>? environment,
  MediaEvidenceVerifierConfiguration? verifier,
  InferenceCostPolicy? inferencePolicy,
}) {
  final values = environment ?? _environment(now);
  return ProductionAiDeploymentConfiguration.fromEnvironment(
    values,
    verifier: verifier ?? _verifier(),
    inferencePolicy:
        inferencePolicy ?? productionInferenceCostPolicyFromEnvironment(values),
    clock: () => now,
  );
}

MediaEvidenceVerifierConfiguration _verifier({
  bool requireZdr = true,
  String endpoint = 'https://openrouter.ai/api/v1/chat/completions',
}) {
  return MediaEvidenceVerifierConfiguration.fromEnvironment({
    'VERILY_MEDIA_VERIFIER_MODE': mediaVerifierOpenRouterMode,
    'VERILY_OPENROUTER_URL': endpoint,
    'VERILY_OPENROUTER_REQUIRE_ZDR': '$requireZdr',
    'VERILY_OPENROUTER_PROMPT_INJECTION_GUARD': 'block',
  }, openRouterApiKey: 'unit-test-only-key');
}

InferenceCostPolicy _costPolicy() {
  return const InferenceCostPolicy(
    version: 'rates:2026-09-04',
    maxMicrosPerAttempt: 3000,
    maxCallsPerAttempt: 3,
    modelMaxCostMicros: {
      openRouterGeminiFlashLiteModel: 1000,
      openRouterGemmaModel: 1000,
      openRouterGlmFlashModel: 1000,
    },
  );
}

Map<String, String> _environment(DateTime now) => {
  'VERILY_AI_DEPLOYMENT_ENABLED': 'true',
  'VERILY_AI_DEPLOYMENT_POLICY_VERSION': productionAiDeploymentPolicyVersion,
  'VERILY_AI_DEPLOYMENT_ID': 'deployment:production:0001',
  'VERILY_AI_GUARDRAIL_ID': 'guardrail:production:0001',
  'VERILY_AI_GUARDRAIL_POLICY_DIGEST': 'a' * 64,
  'VERILY_AI_ZDR_POLICY_ID': 'zdr-policy:production:0001',
  'VERILY_AI_RATE_CARD_DIGEST': 'b' * 64,
  'VERILY_AI_RATE_CARD_MEASURED_AT': now.toIso8601String(),
  'VERILY_AI_COST_POLICY_VERSION': 'rates:2026-09-04',
  'VERILY_AI_MAX_MICROS_PER_ATTEMPT': '3000',
  'VERILY_AI_MAX_CALLS_PER_ATTEMPT': '3',
  'VERILY_AI_MODEL_MAX_COST_MICROS':
      '$openRouterGeminiFlashLiteModel=1000,'
      '$openRouterGemmaModel=1000,$openRouterGlmFlashModel=1000',
  'VERILY_AI_MODEL_REQUESTS_PER_MINUTE':
      '$openRouterGeminiFlashLiteModel=20,'
      '$openRouterGemmaModel=10,$openRouterGlmFlashModel=10',
  'VERILY_AI_MAX_CONCURRENT_REQUESTS': '8',
  'VERILY_AI_HEALTH_WINDOW_MINUTES': '15',
  'VERILY_AI_ATTESTATION_MAX_AGE_SECONDS': '300',
};

ProductionAiDeploymentPreflight _preflight(
  ProductionAiDeploymentConfiguration configuration, {
  required DateTime now,
  required AiDeploymentAttestation Function(String challenge) builder,
}) {
  return ProductionAiDeploymentPreflight(
    configuration: configuration,
    controlPlane: _FakeAiDeploymentControlPlane(builder),
    clock: () => now,
    challengeFactory: () => 'a' * 43,
  );
}

AiDeploymentAttestation _attestation(
  ProductionAiDeploymentConfiguration configuration, {
  required String challenge,
  required DateTime observedAt,
  String promptInjectionAction = 'block',
  bool promptInjectionCanaryBlocked = true,
  String? guardrailPolicyDigest,
  Set<String>? modelIds,
  Map<String, int>? modelRequestsPerMinute,
  bool dataCollectionDisabled = true,
  bool zeroDataRetentionEnabled = true,
  bool providerFallbacksDisabled = true,
  bool toolsDisabled = true,
  bool strictResponseSchemaEnabled = true,
  String policyVersion = productionAiDeploymentPolicyVersion,
}) {
  return AiDeploymentAttestation(
    attestationId: 'attestation:ai:0001',
    challenge: challenge,
    observedAt: observedAt,
    policyVersion: policyVersion,
    deploymentId: configuration.deploymentId!,
    endpoint: configuration.endpoint!,
    guardrailId: configuration.guardrailId!,
    guardrailPolicyDigest:
        guardrailPolicyDigest ?? configuration.guardrailPolicyDigest!,
    promptInjectionAction: promptInjectionAction,
    promptInjectionCanaryBlocked: promptInjectionCanaryBlocked,
    zeroDataRetentionPolicyId: configuration.zeroDataRetentionPolicyId!,
    zeroDataRetentionEnabled: zeroDataRetentionEnabled,
    dataCollectionDisabled: dataCollectionDisabled,
    providerFallbacksDisabled: providerFallbacksDisabled,
    toolsDisabled: toolsDisabled,
    remoteMediaRestricted: true,
    strictResponseSchemaEnabled: strictResponseSchemaEnabled,
    modelIds: modelIds ?? configuration.modelIds,
    modelRequestsPerMinute:
        modelRequestsPerMinute ?? configuration.modelRequestsPerMinute,
    rateCardDigest: configuration.rateCardDigest!,
  );
}

class _FakeAiDeploymentControlPlane implements AiDeploymentControlPlane {
  const _FakeAiDeploymentControlPlane(this.builder);

  final AiDeploymentAttestation Function(String challenge) builder;

  @override
  Future<AiDeploymentAttestation> inspect({
    required ProductionAiDeploymentConfiguration configuration,
    required String challenge,
  }) async {
    return builder(challenge);
  }
}
