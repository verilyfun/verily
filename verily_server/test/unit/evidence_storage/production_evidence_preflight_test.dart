import 'package:test/test.dart';
import 'package:verily_server/src/evidence_storage/backblaze_evidence_storage.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/production_evidence_preflight.dart';

void main() {
  group('ProductionEvidenceStorageConfiguration', () {
    test('accepts exact HTTPS origins and a bounded attestation age', () {
      final configuration = _configuration();

      expect(configuration.allowedWebOrigins, {
        Uri.parse('https://verily.example'),
        Uri.parse('https://admin.verily.example'),
      });
      expect(configuration.maximumAttestationAge, const Duration(minutes: 5));
    });

    test(
      'rejects wildcard, insecure, duplicate, and unpinned configuration',
      () {
        for (final origins in <String>[
          'https://*.verily.example',
          'http://verily.example',
          'https://verily.example,https://verily.example',
        ]) {
          expect(
            () => _configuration(origins: origins),
            throwsStateError,
          );
        }
        expect(
          () => _configuration(policyVersion: 'draft-policy'),
          throwsStateError,
        );
      },
    );
  });

  group('ProductionEvidenceStoragePreflight', () {
    final now = DateTime.utc(2026, 9, 4, 12);
    late ProductionEvidenceStorageConfiguration configuration;

    setUp(() {
      configuration = _configuration();
    });

    test(
      'returns a non-secret readiness snapshot for matching live controls',
      () async {
        final preflight = _preflight(
          configuration,
          now: now,
          builder: (challenge) => _attestation(
            configuration,
            challenge: challenge,
            observedAt: now,
          ),
        );

        final result = await preflight.verify();

        expect(result.bucket, 'verily-evidence-production');
        expect(result.region, 'us-west-002');
        expect(result.policyVersion, productionEvidenceStoragePolicyVersion);
        expect(result.attestationId, 'attestation:storage:0001');
      },
    );

    test('fails closed without a control-plane adapter', () async {
      final preflight = ProductionEvidenceStoragePreflight(
        configuration: configuration,
        controlPlane: const UnavailableEvidenceStorageControlPlane(),
        clock: () => now,
        challengeFactory: () => 'a' * 43,
      );

      await expectLater(preflight.verify(), throwsStateError);
    });

    test('rejects replayed challenge and stale attestations', () async {
      final replay = _preflight(
        configuration,
        now: now,
        builder: (_) => _attestation(
          configuration,
          challenge: 'r' * 43,
          observedAt: now,
        ),
      );
      final stale = _preflight(
        configuration,
        now: now,
        builder: (challenge) => _attestation(
          configuration,
          challenge: challenge,
          observedAt: now.subtract(const Duration(minutes: 6)),
        ),
      );

      await expectLater(replay.verify(), throwsStateError);
      await expectLater(stale.verify(), throwsStateError);
    });

    test('rejects spoofed bucket and endpoint provenance', () async {
      for (final attestation in <EvidenceStorageAttestation>[
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          bucket: 'attacker-bucket',
        ),
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          endpoint: Uri.parse('https://s3.eu.example.invalid'),
        ),
      ]) {
        final preflight = _preflight(
          configuration,
          now: now,
          builder: (_) => attestation,
        );
        await expectLater(preflight.verify(), throwsStateError);
      }
    });

    test('rejects public, unversioned, or over-privileged storage', () async {
      final cases = <EvidenceStorageAttestation>[
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          bucketPrivate: false,
        ),
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          versioningEnabled: false,
        ),
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          capabilities: const {
            'deleteFiles',
            'listBuckets',
            'listFiles',
            'readFiles',
            'writeBuckets',
            'writeFiles',
          },
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
    });

    test('rejects broad CORS and retention beyond the hard ceiling', () async {
      final cases = <EvidenceStorageAttestation>[
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          corsOrigins: {Uri.parse('https://other.example')},
        ),
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          maximumVersionAgeDays: 31,
        ),
        _attestation(
          configuration,
          challenge: 'a' * 43,
          observedAt: now,
          corsAllowedHeaders: const {
            'authorization',
            'content-length',
            'content-type',
          },
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
    });
  });
}

ProductionEvidenceStorageConfiguration _configuration({
  String origins = 'https://verily.example,https://admin.verily.example',
  String policyVersion = productionEvidenceStoragePolicyVersion,
}) {
  return ProductionEvidenceStorageConfiguration.fromEnvironment(
    {
      'VERILY_EVIDENCE_STORAGE_POLICY_VERSION': policyVersion,
      'VERILY_EVIDENCE_ALLOWED_WEB_ORIGINS': origins,
      'VERILY_EVIDENCE_ATTESTATION_MAX_AGE_SECONDS': '300',
    },
    storage: BackblazeEvidenceStorageConfiguration(
      endpoint: Uri.parse('https://s3.us-west-002.backblazeb2.com'),
      region: 'us-west-002',
      bucket: 'verily-evidence-production',
      keyId: 'not-exposed-by-preflight',
      applicationKey: 'not-exposed-by-preflight',
    ),
  );
}

ProductionEvidenceStoragePreflight _preflight(
  ProductionEvidenceStorageConfiguration configuration, {
  required DateTime now,
  required EvidenceStorageAttestation Function(String challenge) builder,
}) {
  return ProductionEvidenceStoragePreflight(
    configuration: configuration,
    controlPlane: _FakeEvidenceStorageControlPlane(builder),
    clock: () => now,
    challengeFactory: () => 'a' * 43,
  );
}

EvidenceStorageAttestation _attestation(
  ProductionEvidenceStorageConfiguration configuration, {
  required String challenge,
  required DateTime observedAt,
  Uri? endpoint,
  String? bucket,
  bool bucketPrivate = true,
  bool versioningEnabled = true,
  Set<String> capabilities = const {
    'deleteFiles',
    'listBuckets',
    'listFiles',
    'readFiles',
    'writeFiles',
  },
  Set<Uri>? corsOrigins,
  Set<String> corsAllowedHeaders = const {'content-length', 'content-type'},
  int maximumVersionAgeDays = 30,
}) {
  return EvidenceStorageAttestation(
    attestationId: 'attestation:storage:0001',
    challenge: challenge,
    observedAt: observedAt,
    policyVersion: productionEvidenceStoragePolicyVersion,
    endpoint: endpoint ?? configuration.endpoint,
    region: configuration.region,
    bucket: bucket ?? configuration.bucket,
    bucketPrivate: bucketPrivate,
    defaultEncryptionEnabled: true,
    versioningEnabled: versioningEnabled,
    versionIdReadsEnabled: true,
    applicationKeyPrefix: evidenceObjectPrefix,
    applicationKeyCapabilities: capabilities,
    corsOrigins: corsOrigins ?? configuration.allowedWebOrigins,
    corsMethods: const {'GET', 'HEAD', 'PUT'},
    corsAllowedHeaders: corsAllowedHeaders,
    corsExposedHeaders: const {'etag', 'x-amz-version-id'},
    corsMaximumAgeSeconds: 300,
    lifecyclePrefix: evidenceObjectPrefix,
    maximumVersionAgeDays: maximumVersionAgeDays,
    unfinishedMultipartAgeDays: 1,
  );
}

class _FakeEvidenceStorageControlPlane implements EvidenceStorageControlPlane {
  const _FakeEvidenceStorageControlPlane(this.builder);

  final EvidenceStorageAttestation Function(String challenge) builder;

  @override
  Future<EvidenceStorageAttestation> inspect({
    required ProductionEvidenceStorageConfiguration configuration,
    required String challenge,
  }) async {
    return builder(challenge);
  }
}
